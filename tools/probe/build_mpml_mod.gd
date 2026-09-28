extends SceneTree
# Called by build_mpml_mod.ps1 with a fresh staging directory. This script reads
# the original pack but never starts its scenes or modifies that pack.
var ROOT: String
var ORIG: String
var OUT_DIR: String

func fail(message: String) -> bool:
	printerr("[MP8-BUILD] " + message)
	return false

func manifest() -> Array:
	var result: Array = []
	var stack: Array[String] = [""]
	var basenames: Dictionary = {}
	while not stack.is_empty():
		var rel: String = stack.pop_back()
		var directory := DirAccess.open(ROOT.path_join("patch").path_join(rel))
		if directory == null:
			fail("Cannot read patch directory: " + rel)
			return []
		for file in directory.get_files():
			if not file.ends_with(".gd"):
				continue
			var base := file.trim_suffix(".gd") + ".gdc"
			if basenames.has(base.to_lower()):
				fail("Duplicate bytecode basename: " + base)
				return []
			basenames[base.to_lower()] = true
			result.append([base, "res://" + rel + base])
		for sub in directory.get_directories():
			stack.append(rel + sub + "/")
	result.sort_custom(func(a, b): return a[1] < b[1])
	return result

func write_bytes(path: String, data: PackedByteArray) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return fail("Cannot create " + path)
	file.store_buffer(data)
	var error := file.get_error()
	file.close()
	return error == OK

func build() -> bool:
	var entries := manifest()
	if entries.is_empty():
		return fail("Empty/invalid patch manifest")
	if not DirAccess.dir_exists_absolute(OUT_DIR):
		if DirAccess.make_dir_recursive_absolute(OUT_DIR) != OK:
			return fail("Cannot create staging directory")
	if not DirAccess.get_files_at(OUT_DIR).is_empty() or not DirAccess.get_directories_at(OUT_DIR).is_empty():
		return fail("Output must be an empty staging directory")
	if not ProjectSettings.load_resource_pack(ORIG, false):
		return fail("Cannot read original pack")
	var originals: Dictionary = {}
	for entry in entries:
		if not FileAccess.file_exists(entry[1]):
			return fail("Original pack lacks " + entry[1])
		originals[entry[1]] = FileAccess.get_md5(entry[1])
		if str(originals[entry[1]]).length() != 32:
			return fail("Cannot hash original " + entry[1])
	var tag: String = ""
	var source := FileAccess.get_file_as_string(ROOT.path_join("patch/modules/multiplayer/network_manager.gd"))
	for line in source.split("\n"):
		if line.begins_with("const MP8_VERSION_TAG"):
			tag = line.get_slice("\"", 1)
			break
	if not tag.begins_with("overtime-"):
		return fail("Missing version tag")

	var pack_path := OUT_DIR.path_join("overtime_overlay.zip")
	var pack := ZIPPacker.new()
	if pack.open(pack_path) != OK:
		return fail("Cannot create overlay ZIP")
	for entry in entries:
		var bytes := FileAccess.get_file_as_bytes(ROOT.path_join("patch_gdc").path_join(entry[0]))
		if bytes.is_empty():
			pack.close()
			return fail("Missing/empty bytecode " + entry[0])
		if pack.start_file(String(entry[1]).trim_prefix("res://")) != OK:
			pack.close()
			return fail("Cannot start ZIP entry " + entry[1])
		if pack.write_file(bytes) != OK or pack.close_file() != OK:
			pack.close()
			return fail("Cannot write ZIP entry " + entry[1])
	if pack.close() != OK:
		return fail("Cannot finish overlay ZIP")
	var stream := FileAccess.open(pack_path, FileAccess.READ)
	if stream == null:
		return fail("Cannot reopen ZIP")
	var pack_size := stream.get_length()
	stream.close()
	var digest := FileAccess.get_sha256(pack_path)
	if pack_size <= 0 or digest.length() != 64:
		return fail("Cannot hash ZIP")
	for name in ["mod.json", "main.gd"]:
		var bytes := FileAccess.get_file_as_bytes(ROOT.path_join("mpml/overtime").path_join(name))
		if bytes.is_empty() or not write_bytes(OUT_DIR.path_join(name), bytes):
			return fail("Cannot copy " + name)
	# Manifest is the final file. An interrupted staging build is not mountable.
	var data := {
		"schema": 1, "game_version": tag, "godot": Engine.get_version_info()["string"],
		"files": originals, "overlay_size": pack_size, "overlay_sha256": digest,
	}
	if not write_bytes(OUT_DIR.path_join("vanilla_md5.json"), JSON.stringify(data, "  ").to_utf8_buffer()):
		return fail("Cannot write manifest")
	print("[MP8-BUILD] %d original fingerprints; overlay %d bytes SHA256=%s" % [entries.size(), pack_size, digest])
	return true

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var options: Dictionary = {}
	if args.size() % 2 != 0:
		fail("Expected option/value pairs"); quit(1); return
	for i in range(0, args.size(), 2):
		options[args[i]] = args[i + 1]
	if not options.has("--mp8-root") or not options.has("--mp8-output") or not options.has("--mp8-original"):
		fail("Use build_mpml_mod.ps1 to provide root, original pack and fresh staging output")
		quit(1); return
	ROOT = String(options["--mp8-root"]).simplify_path()
	ORIG = String(options["--mp8-original"]).simplify_path()
	OUT_DIR = String(options["--mp8-output"]).simplify_path()
	quit(0 if build() else 1)
