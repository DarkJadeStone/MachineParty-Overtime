extends Node

# Use MPML OR the installer. MD5 checks bind to the original game build;
# overlay SHA256 detects damage/mixed files, not a trusted publisher identity.
const MOD_ID := "overtime"
const PACK := "overtime_overlay.zip"
const MANIFEST := "vanilla_md5.json"
const SENTINELS := [
	"res://modules/multiplayer/network_manager.gd",
	"res://scripts/scenes/game/game.gd",
	"res://scenes/lobby/scripts/lobby_scene.gd",
]
const MESSAGES := {
	"LOADER_API": ["Update MachinePartyModLoader; API 2 required.", "请更新加载器，需要 API 2。", "請更新載入器，需要 API 2。"],
	"MOD_DIRECTORY": ["Cannot locate the overtime mod folder.", "找不到 overtime 目录。", "找不到 overtime 目錄。"],
	"LOAD_ORDER": ["Game scripts loaded too early; use priority -1000.", "游戏脚本提前加载，请保留优先级 -1000。", "遊戲腳本提前載入，請保留優先級 -1000。"],
	"MANIFEST_MISSING": ["Missing package manifest. Download the complete package.", "缺少包清单，请重新下载完整安装包。", "缺少套件清單，請重新下載完整安裝包。"],
	"MANIFEST_INVALID": ["Invalid package manifest. Download the complete package.", "包清单无效，请重新下载完整安装包。", "套件清單無效，請重新下載完整安裝包。"],
	"VANILLA_MISMATCH": ["Game scripts differ. Restore vanilla before MPML or use a matching Overtime release.", "游戏脚本不匹配。使用 MPML 前请恢复原版，或下载匹配版本。", "遊戲腳本不匹配。使用 MPML 前請恢復原版，或下載匹配版本。"],
	"OVERLAY_MISSING": ["Missing overlay ZIP. Download the complete package.", "缺少覆盖 ZIP，请重新下载完整安装包。", "缺少覆蓋 ZIP，請重新下載完整安裝包。"],
	"OVERLAY_SIZE": ["Overlay size mismatch. Keep all files from the same package.", "覆盖包大小不符，请使用同一个安装包中的全部文件。", "覆蓋包大小不符，請使用同一個安裝包中的全部檔案。"],
	"OVERLAY_HASH": ["Overlay SHA256 mismatch. Download the complete package.", "覆盖包 SHA256 不符，请重新下载完整安装包。", "覆蓋包 SHA256 不符，請重新下載完整安裝包。"],
	"OVERLAY_LOAD": ["Verified overlay could not be mounted.", "已校验的覆盖包无法挂载。", "已校驗的覆蓋包無法掛載。"],
	"VERSION_MISMATCH": ["Loaded version differs from mod.json. Replace the whole package.", "版本与 mod.json 不符，请替换整个安装包。", "版本與 mod.json 不符，請替換整個安裝包。"],
	"MOUNTED": ["Overlay mounted; original scripts and package digest verified.", "覆盖包已挂载，原版脚本与包指纹已核对。", "覆蓋包已掛載，原版腳本與套件指紋已核對。"],
	"READY": ["Overtime ready.", "Overtime 已就绪。", "Overtime 已就緒。"],
}
var _mounted: bool = false

func _text(code: String, locale: String = "") -> String:
	if locale.is_empty():
		locale = TranslationServer.get_locale()
	var value := locale.to_upper().replace("-", "_")
	var index: int = 0
	if value.begins_with("ZH"):
		index = 2 if value == "ZHT" or value.contains("TW") or value.contains("HK") or value.contains("HANT") else 1
	return str(MESSAGES.get(code, [code, code, code])[index])

func _valid_manifest(parsed) -> bool:
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("schema") != 1:
		return false
	if typeof(parsed.get("files")) != TYPE_DICTIONARY or parsed["files"].is_empty():
		return false
	if typeof(parsed.get("game_version")) != TYPE_STRING or not parsed["game_version"].begins_with("overtime-"):
		return false
	if typeof(parsed.get("overlay_sha256")) != TYPE_STRING:
		return false
	var digest: String = parsed["overlay_sha256"]
	if digest.length() != 64 or not digest.is_valid_hex_number(false):
		return false
	var size = parsed.get("overlay_size")
	if typeof(size) != TYPE_INT and typeof(size) != TYPE_FLOAT:
		return false
	if not is_finite(float(size)) or size <= 0 or size != floor(size):
		return false
	for path in parsed["files"]:
		if typeof(path) != TYPE_STRING or not path.begins_with("res://") or not path.ends_with(".gdc") or path.contains("..") or path.contains("\\"):
			return false
		var md5 = parsed["files"][path]
		if typeof(md5) != TYPE_STRING or md5.length() != 32 or not md5.is_valid_hex_number(false):
			return false
	return true

func _mod_init(loader) -> void:
	_mounted = false
	if loader.has_method("has_api") and not loader.call("has_api", 2):
		_fail(loader, "LOADER_API")
		return
	var directory: String = loader.dir_of(MOD_ID)
	if directory.is_empty():
		_fail(loader, "MOD_DIRECTORY")
		return
	for path in SENTINELS:
		if ResourceLoader.has_cached(path):
			_fail(loader, "LOAD_ORDER", path)
			return
	var manifest_path := directory.path_join(MANIFEST)
	if not FileAccess.file_exists(manifest_path):
		_fail(loader, "MANIFEST_MISSING")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not _valid_manifest(parsed):
		_fail(loader, "MANIFEST_INVALID")
		return
	var mod_path := directory.path_join("mod.json")
	var mod_data = JSON.parse_string(FileAccess.get_file_as_string(mod_path)) if FileAccess.file_exists(mod_path) else null
	if typeof(mod_data) != TYPE_DICTIONARY or mod_data.get("id") != MOD_ID or typeof(mod_data.get("version")) != TYPE_STRING:
		_fail(loader, "VERSION_MISMATCH")
		return
	if _normalized_version(mod_data["version"]) != _normalized_version(parsed["game_version"]):
		_fail(loader, "VERSION_MISMATCH", str(mod_data["version"]) + " / " + str(parsed["game_version"]))
		return
	var pack := directory.path_join(PACK)
	if not FileAccess.file_exists(pack):
		_fail(loader, "OVERLAY_MISSING")
		return
	var file := FileAccess.open(pack, FileAccess.READ)
	if file == null:
		_fail(loader, "OVERLAY_MISSING")
		return
	var size := file.get_length()
	file.close()
	if size != int(parsed["overlay_size"]):
		_fail(loader, "OVERLAY_SIZE")
		return
	if FileAccess.get_sha256(pack).to_lower() != str(parsed["overlay_sha256"]).to_lower():
		_fail(loader, "OVERLAY_HASH")
		return
	# Preserve the original per-script compatibility gate before mounting.
	var bad := PackedStringArray()
	for path in parsed["files"]:
		if not FileAccess.file_exists(path) or FileAccess.get_md5(path).to_lower() != str(parsed["files"][path]).to_lower():
			bad.append(path)
		if bad.size() == 3:
			break
	if not bad.is_empty():
		_fail(loader, "VANILLA_MISMATCH", ", ".join(bad))
		return
	if not ProjectSettings.load_resource_pack(pack, true):
		_fail(loader, "OVERLAY_LOAD")
		return
	_mounted = true
	loader.note("overtime: [MOUNTED] " + _text("MOUNTED") + " " + str(parsed["game_version"]))

func _normalized_version(value: String) -> String:
	value = value.trim_prefix("overtime-")
	var pieces := value.split("-", true, 1)
	var numbers := pieces[0].split(".")
	if numbers.size() == 3 and numbers[2] == "0":
		numbers.remove_at(2)
	return ".".join(numbers) + ("-" + pieces[1] if pieces.size() > 1 else "")

func _mod_ready(loader) -> void:
	if not _mounted:
		return
	var declared: String = "?"
	var data = JSON.parse_string(FileAccess.get_file_as_string(loader.dir_of(MOD_ID).path_join("mod.json")))
	if typeof(data) == TYPE_DICTIONARY:
		declared = str(data.get("version", "?"))
	var nm = get_tree().root.get_node_or_null("NetworkManager")
	var actual: String = str(nm.get("MP8_VERSION_TAG")) if nm != null else "?"
	if not actual.begins_with("overtime-") or declared == "?" or _normalized_version(actual) != _normalized_version(declared):
		_fail(loader, "VERSION_MISMATCH", declared + " / " + actual)
	else:
		loader.note("overtime: [READY] " + _text("READY") + " " + actual)

func _fail(loader, code: String, detail: String = "") -> void:
	var message := "[MP8:" + code + "] " + _text(code)
	if not detail.is_empty():
		message += " " + detail
	loader.note("overtime: " + message)
	printerr(message)
