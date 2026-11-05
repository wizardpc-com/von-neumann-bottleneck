extends RefCounted
## Local target recipes only; separate from player progress and all score authority.
const Code = preload("res://src/layout_chapter/layout_challenge_code.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const MAX_BYTES: int = 32768
const MAX_TARGETS: int = 6
var storage_path: String = "user://layout_challenges_v1.json"
var storage_status: String = "ready"
var last_error: String = ""
var _game_targets: Dictionary = {}
var _test_targets: Dictionary = {}
var _game_loaded: bool = false
var _loaded_path: String = ""
var _disk_signature: String = ""

func read_target(task: String, mode: StringName) -> Dictionary:
	var problem: String = _context_error(task,mode)
	if not problem.is_empty(): return {"entry":{},"status":"ready","reason":problem}
	if mode == &"test": return {"entry":_test_targets.get(task,{}).duplicate(true),"status":"ready","reason":""}
	_load_game()
	return {"entry":_game_targets.get(task,{}).duplicate(true),"status":storage_status,"reason":last_error}

func pin(task: String, mode: StringName, code: String, title: String) -> Dictionary:
	var problem: String = _context_error(task,mode)
	if not problem.is_empty(): return _result(false,problem,{},mode)
	if not _valid_title(title): return _result(false,"title",{},mode)
	var inspected: Dictionary = Code.inspect(code,task)
	if not inspected.ok: return _result(false,inspected.reason,{},mode)
	var entry: Dictionary = {"code":inspected.code,"title":title}
	if mode == &"test":
		_test_targets[task] = entry
		return _result(true,"",entry,mode)
	_load_game()
	if storage_status == "read_only": return _result(false,last_error,_game_targets.get(task,{}),mode)
	var proposed: Dictionary = _game_targets.duplicate(true)
	proposed[task] = entry
	if not _commit(proposed): return _result(false,last_error,_game_targets.get(task,{}),mode)
	return _result(true,"",entry,mode)

func clear(task: String, mode: StringName) -> Dictionary:
	var problem: String = _context_error(task,mode)
	if not problem.is_empty(): return _result(false,problem,{},mode)
	if mode == &"test":
		_test_targets.erase(task)
		return _result(true,"",{},mode)
	_load_game()
	if storage_status == "read_only": return _result(false,last_error,_game_targets.get(task,{}),mode)
	var proposed: Dictionary = _game_targets.duplicate(true)
	proposed.erase(task)
	if not _commit(proposed): return _result(false,last_error,_game_targets.get(task,{}),mode)
	return _result(true,"",{},mode)

func _load_game() -> void:
	if _game_loaded:
		if _loaded_path != storage_path: _protect("changed")
		return
	_game_loaded = true
	_loaded_path = storage_path
	var disk: Dictionary = _read_disk()
	if not disk.ok:
		_protect(disk.reason)
		return
	_disk_signature = disk.signature
	if not disk.present: return
	var decoded: Dictionary = _decode_snapshot(disk.text)
	if not decoded.ok:
		_protect(decoded.reason)
		return
	_game_targets = decoded.targets

func _read_disk() -> Dictionary:
	if DirAccess.dir_exists_absolute(storage_path): return {"ok":false,"reason":"format"}
	if not FileAccess.file_exists(storage_path):
		return {"ok":true,"present":false,"signature":"missing","text":""}
	var file := FileAccess.open(storage_path,FileAccess.READ)
	if file == null: return {"ok":false,"reason":"read"}
	var length: int = file.get_length()
	if length > MAX_BYTES: return {"ok":false,"reason":"size"}
	var bytes: PackedByteArray = file.get_buffer(length)
	if bytes.size() != length: return {"ok":false,"reason":"read"}
	var text: String = bytes.get_string_from_utf8()
	if text.to_utf8_buffer() != bytes: return {"ok":false,"reason":"format"}
	return {"ok":true,"present":true,"signature":text.sha256_text(),"text":text}

func _decode_snapshot(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK or not Code._keys_exact(parser.data,["schema_version","targets"]):
		return {"ok":false,"reason":"format"}
	var snapshot: Dictionary = parser.data
	if not Code._integer(snapshot.schema_version,1,1): return {"ok":false,"reason":"version"}
	if not snapshot.targets is Dictionary or snapshot.targets.size() > MAX_TARGETS:
		return {"ok":false,"reason":"size"}
	var targets: Dictionary = {}
	for task: Variant in snapshot.targets:
		if not task is String or task not in Catalog.IDS: return {"ok":false,"reason":"task"}
		var value: Variant = snapshot.targets[task]
		if not Code._keys_exact(value,["code","title"]) or not value.code is String or not _valid_title(value.title):
			return {"ok":false,"reason":"format"}
		var decoded: Dictionary = Code.decode(value.code)
		if not decoded.ok: return {"ok":false,"reason":decoded.reason}
		if decoded.task != task: return {"ok":false,"reason":"wrong_task"}
		# A supported old identity stays byte-exact and inactive until explicitly replaced.
		targets[task] = {"code":value.code,"title":value.title}
	var canonical: String = _snapshot_text(targets)
	if text != canonical: return {"ok":false,"reason":"format"}
	return {"ok":true,"reason":"","targets":targets}

func _commit(proposed: Dictionary) -> bool:
	if storage_status == "read_only": return false
	if not _disk_unchanged(): return false
	var text: String = _snapshot_text(proposed)
	if text.to_utf8_buffer().size() > MAX_BYTES or not _decode_snapshot(text).ok:
		return _write_failed("format")
	if proposed == _game_targets:
		storage_status = "ready"
		last_error = ""
		return true
	var temporary: String = storage_path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null: return _write_failed("write")
	file.store_string(text)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK: return _write_failed("write")
	# Detect an external writer while the temporary file was being prepared.
	if not _disk_unchanged(): return false
	if _replace_file(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(storage_path)) != OK:
		return _write_failed("replace")
	_game_targets = proposed.duplicate(true)
	_disk_signature = text.sha256_text()
	storage_status = "ready"
	last_error = ""
	return true

func _disk_unchanged() -> bool:
	if _loaded_path != storage_path:
		_protect("changed")
		return false
	var current: Dictionary = _read_disk()
	if not current.ok or current.signature != _disk_signature:
		_protect("changed")
		return false
	return true

func _replace_file(temporary: String, target: String) -> Error:
	return DirAccess.rename_absolute(temporary,target)

func _snapshot_text(targets: Dictionary) -> String:
	return JSON.stringify({"schema_version":1,"targets":targets},"",true)

func _context_error(task: String, mode: StringName) -> String:
	if mode not in [&"game",&"test"]: return "mode"
	return "" if task in Catalog.IDS else "task"

func _valid_title(value: Variant) -> bool:
	if not value is String or value.length() > 40: return false
	for index: int in value.length():
		var character: int = value.unicode_at(index)
		if character < 32 or character >= 127 and character <= 159: return false
	return true

func _protect(reason: String) -> void:
	storage_status = "read_only"
	last_error = reason

func _write_failed(reason: String) -> bool:
	storage_status = "write_failed"
	last_error = reason
	return false

func _result(ok: bool, reason: String, entry: Dictionary, mode: StringName) -> Dictionary:
	return {"ok":ok,"status":"ready" if mode == &"test" else storage_status,
		"reason":reason,"entry":entry.duplicate(true)}
