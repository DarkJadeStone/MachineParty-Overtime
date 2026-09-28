extends SceneTree

# [MP8] 补丁脚本的**运行时解析**自检。
#
# 为什么需要它（2026-08-16 花了一轮 7 分钟空跑换来的教训）：
#   `tools\build.ps1` 只保证 gdre 能把 .gd 编成 .gdc，**它不解析基类标识符**。
#   `Minigame extends Node`（不是 Node3D），而补丁里写了 `self.global_transform` ——
#   编译一路全绿、打进 PCK 全绿，游戏一加载才：
#       Parse Error: Identifier "global_transform" not declared in the current scope
#       Failed to load script ... → 节点没脚本 → @export 接不上 → 小游戏永远起不来
#   表面症状是"卡在 SessionIntro"，跟人数毫无关系，极其误导。
#
# 做法：挂上**打好补丁的 PCK**（这样 Minigame / PlayerManager 这些全局类名都能解析），
# 再把 patch\ 下每个 .gd 的源码喂给 GDScript.reload() 真编一遍。
# 解析错误由引擎自己打到 stderr，退出码非 0 = 有问题。
#
# 用法：  powershell -ExecutionPolicy Bypass -File tools\parsecheck.ps1


# 游戏的 18 个 autoload。解析器靠 ProjectSettings 里的 "autoload/*" 认这些名字，
# 不注册的话 `GameManager` / `PauseMenu` 这些全部报"未声明"，
# 连 17 个已知能跑的脚本都会误报失败。
# （抄自 notes\project_settings.txt，即游戏自己的 project.binary。）
const AUTOLOADS := {
	"AchievementManager": "*res://autoloads/achievement_manager.gd",
	"CursorManager": "*res://autoloads/cursor_manager.tscn",
	"DebugTools": "*res://autoloads/debug_tools.tscn",
	"DecalManager": "*res://autoloads/decal_manager.tscn",
	"EffectManager": "*res://autoloads/effect_manager.tscn",
	"GameManager": "*res://autoloads/game_manager.gd",
	"GlobalOverlay": "*res://modules/global_overlay/global_overlay.tscn",
	"Globals": "*res://autoloads/globals.gd",
	"LocalizationDebugMenu": "*res://scenes/localization_debug_menu.tscn",
	"MultiplayerInput": "*res://addons/multiplayer_input/multiplayer_input.gd",
	"MusicManager": "*res://autoloads/music_manager.tscn",
	"NetworkManager": "*res://modules/multiplayer/network_manager.gd",
	"PauseMenu": "*res://modules/pause_menu/pause_menu.tscn",
	"PlayerManager": "*res://autoloads/player_manager.tscn",
	"PropManager": "*res://autoloads/prop_manager.tscn",
	"Shaker": "*res://addons/shaker/src/Shaker.gd",
	"SoundManager": "*res://autoloads/sound_manager.tscn",
	"Steamworks": "*res://modules/steamworks/steamworks.gd",
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or args.size() > 3:
		printerr("Use tools/parsecheck.ps1 -Pck <path> to provide the PCK and patch directory")
		quit(2)
		return
	if not ProjectSettings.load_resource_pack(args[0], true):
		printerr("挂载 PCK 失败: ", args[0])
		quit(2)
		return

	if args.size() == 3 and not ProjectSettings.load_resource_pack(args[2], true):
		printerr("挂载候选 overlay 失败: ", args[2])
		quit(2)
		return

	# 必须在挂载 PCK **之后**注册：这些路径都在包里，先注册会指向不存在的文件
	for k in AUTOLOADS:
		ProjectSettings.set_setting("autoload/" + k, AUTOLOADS[k])

	# MP8_CHECK_DIR：改成 src\ 就是拿**原版未打补丁**的同一批脚本跑一遍基线。
	# 差分才是判据 —— 只有"补丁版报了、原版不报"的错才是我们引入的。
	var scan_dir := OS.get_environment("MP8_CHECK_DIR")
	if scan_dir.is_empty():
		scan_dir = args[1]

	var files: Array[String] = []
	_collect(scan_dir, files)
	files.sort()
	print("扫描目录：", scan_dir)

	print("== 解析自检：%d 个补丁脚本 ==" % files.size())
	var bad: Array[String] = []

	for f in files:
		var src := FileAccess.get_file_as_string(f)
		if src.is_empty():
			print("  ?? 读不到内容  %s" % f)
			bad.append(f)
			continue

		# 分隔线也打到 stderr，否则引擎报的 Parse Error 混成一坨、认不出是哪个文件的
		printerr("---- ", f.get_file())

		var gd := GDScript.new()
		# 去掉 class_name：PCK 里已经注册过同名全局类，不去掉必报
		# "Class X hides a global script class"。**换成等长的空行**，
		# 这样 stderr 里报的行号仍然对得上真实文件。
		gd.source_code = _blank_class_name(src)
		# reload() 会把 Parse Error 打到 stderr，返回值非 OK 即失败
		var err: int = gd.reload()
		if err != OK:
			print("  ❌ 解析失败(err=%d)  %s" % [err, f.get_file()])
			bad.append(f)
		else:
			print("  ✓  %s" % f.get_file())

	print("")
	if bad.is_empty():
		print("全部通过：%d 个脚本都能解析" % files.size())
		quit(0)
	else:
		print("有 %d 个脚本解析失败，**不要拿这个 PCK 去跑**：" % bad.size())
		for f in bad:
			print("   - %s" % f.get_file())
		quit(1)


func _blank_class_name(src: String) -> String:
	var lines := src.split("\n")
	var inline_base := RegEx.new()
	inline_base.compile("^\\s*class_name\\s+\\w+\\s+extends\\s+(.+)$")
	for i in lines.size():
		if lines[i].strip_edges().begins_with("class_name "):
			# Keep an inline base class; removing the whole line silently changes
			# Node-derived scripts into RefCounted and hides real scope errors.
			var declaration := inline_base.search(lines[i])
			lines[i] = "extends " + declaration.get_string(1) if declaration != null else ""
	return "\n".join(lines)


func _collect(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := dir_path + "/" + name
		if d.current_is_dir():
			if not name.begins_with("."):
				_collect(full, out)
		elif name.ends_with(".gd"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
