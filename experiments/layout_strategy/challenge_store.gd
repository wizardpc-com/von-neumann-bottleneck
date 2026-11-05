extends RefCounted
## Retained experiment codes only. Live target scores always require remeasurement.
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const MAX_BYTES: int = 32768
const MAX_TARGETS: int = 6
const DEFAULT_PATH: String = "user://layout_strategy_challenges_v2.json"
const LEGACY_PATH: String = "user://layout_strategy_challenges_v1.json"
const SNAPSHOT_KEYS := ["version","targets"]
var storage_path: String = DEFAULT_PATH
var legacy_path: String = ""
var storage_status: String = "ready"
var last_error: String = ""
var origin: String = "empty"
var copy_pending: bool = false
var _loaded: bool = false
var _loaded_path: String = ""
var _disk_signature: String = ""
var _loaded_legacy_path: String = ""
var _legacy_signature: String = ""
var _watch_legacy: bool = false
var _blocked_writer_path: String = ""
var _committed: Dictionary = {}


func read() -> Dictionary:
	_load()
	return _result(storage_status != "read_only")


func write(snapshot: Dictionary) -> Dictionary:
	_load()
	if storage_status == "read_only": return _result(false)
	if not _disk_unchanged(): return _result(false)
	var validated: Dictionary = _validate_snapshot(snapshot)
	if not validated.ok: return _failed(validated.reason)
	var proposed: Dictionary = validated.snapshot
	var text: String = _canonical(proposed)
	var paths: Array[String] = _writer_paths()
	var leases: Array[RefCounted] = []
	var ownership_error: String = _acquire_writers(paths,leases)
	if not ownership_error.is_empty(): return _failed(ownership_error)
	# A first copy protects the old source and new destination independently.
	# After v2 commits, subsequent writes never reread or lock the old history.
	if not _disk_unchanged():
		_release_writers(leases)
		return _result(false)
	if proposed == _committed and not copy_pending:
		_release_writers(leases)
		_ready()
		return _result(true)
	var temporary: String = _temporary_path()
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		_release_writers(leases)
		return _failed("write")
	file.store_string(text)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		_discard_temporary(temporary)
		_release_writers(leases)
		return _failed("write")
	var written: Dictionary = _read_disk(temporary)
	if not written.ok or not written.present or written.text != text or not _decode_snapshot(written.text).ok:
		_discard_temporary(temporary)
		_release_writers(leases)
		return _failed("write")
	if not _writers_owned(paths,leases):
		_discard_temporary(temporary)
		_release_writers(leases)
		return _failed("busy")
	if not _disk_unchanged():
		_discard_temporary(temporary)
		_release_writers(leases)
		return _result(false)
	if _replace_file(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(storage_path)) != OK:
		_discard_temporary(temporary)
		_release_writers(leases)
		return _failed("replace")
	_committed = proposed.duplicate(true)
	_disk_signature = text.sha256_text()
	_watch_legacy = false
	copy_pending = false
	origin = "current"
	_blocked_writer_path = ""
	_release_writers(leases)
	_ready()
	return _result(true)


func recover_writer() -> Dictionary:
	_load()
	if storage_status == "read_only": return _result(false)
	if not _disk_unchanged(): return _result(false)
	var writer_path: String = _blocked_writer_path if _blocked_writer_path in _writer_paths() else _writer_path()
	_blocked_writer_path = writer_path
	var token: String = Lease.stopped_owner(writer_path)
	if token.is_empty(): return _failed("busy")
	var recovered: Dictionary = Lease.recover_and_acquire(writer_path,token)
	if recovered.get("error",ERR_ALREADY_IN_USE) != OK or not recovered.has("lease"):
		return _failed("busy")
	var lease: RefCounted = recovered.lease
	if not lease.owns(writer_path):
		lease.release()
		return _failed("busy")
	# Recovery changes ownership only. An explicit retry must reacquire the
	# lease and check the disk again before saving the controller's proposal.
	if not _disk_unchanged():
		lease.release()
		return _result(false)
	lease.release()
	_blocked_writer_path = ""
	_ready()
	return _result(true)


static func normalize_snapshot(value: Variant) -> Dictionary:
	var result: Dictionary = _validate_snapshot(value)
	return result.snapshot.duplicate(true) if result.ok else {}


static func normalize_legacy_snapshot(value: Variant) -> Dictionary:
	var result: Dictionary = _validate_snapshot(value,true)
	return result.snapshot.duplicate(true) if result.ok else {}


static func _validate_snapshot(value: Variant, legacy: bool = false) -> Dictionary:
	var version: int = 1 if legacy else 2
	var ids: Array[String] = Model.LEGACY_SCENARIO_IDS if legacy else Model.SCENARIO_IDS
	if not value is Dictionary: return _invalid("format")
	if value.has("version") and not _integer(value.version,version,version): return _invalid("version")
	if not _keys_exact(value,SNAPSHOT_KEYS): return _invalid("format")
	if not value.targets is Dictionary: return _invalid("format")
	if value.targets.size() > (Model.LEGACY_SCENARIO_IDS.size() if legacy else MAX_TARGETS): return _invalid("size")
	var targets: Dictionary = {}
	for id: Variant in value.targets:
		if not id is String or id not in ids: return _invalid("task")
		var code: Variant = value.targets[id]
		if not code is String: return _invalid("format")
		var decoded: Dictionary = Code.decode(code)
		if not decoded.ok: return _invalid(decoded.reason)
		if decoded.envelope.task != id: return _invalid("task")
		if decoded.code != code: return _invalid("format")
		# Decode performs structural validation only. A supported old identity
		# stays byte-exact; the controller must inspect before activating it.
		targets[id] = code
	var snapshot: Dictionary = {"version":version,"targets":targets}
	if _canonical(snapshot).to_utf8_buffer().size() > MAX_BYTES: return _invalid("size")
	return {"ok":true,"reason":"","snapshot":snapshot}


func _load() -> void:
	if _loaded:
		if not _paths_unchanged(): _protect("changed")
		return
	_loaded = true
	_loaded_path = storage_path
	var disk: Dictionary = _read_disk()
	if not disk.ok:
		origin = "current"
		_protect(disk.reason)
		return
	_disk_signature = disk.signature
	if disk.present:
		origin = "current"
		var decoded: Dictionary = _decode_snapshot(disk.text)
		if not decoded.ok:
			_protect(decoded.reason)
			return
		_committed = decoded.snapshot
		return
	_committed = {"version":2,"targets":{}}
	_loaded_legacy_path = _resolved_legacy_path()
	if _loaded_legacy_path.is_empty(): return
	_watch_legacy = true
	if ProjectSettings.globalize_path(_loaded_legacy_path).simplify_path() == ProjectSettings.globalize_path(storage_path).simplify_path():
		origin = "legacy"
		_committed.clear()
		_protect("format")
		return
	var previous: Dictionary = _read_disk(_loaded_legacy_path)
	if not previous.ok:
		origin = "legacy"
		_committed.clear()
		_protect(previous.reason)
		return
	_legacy_signature = previous.signature
	if not previous.present: return
	origin = "legacy"
	var copied: Dictionary = _decode_snapshot(previous.text,true)
	if not copied.ok:
		_committed.clear()
		_protect(copied.reason)
		return
	_committed = copied.snapshot.duplicate(true)
	_committed.version = 2
	copy_pending = true


func _read_disk(path: String = "") -> Dictionary:
	if path.is_empty(): path = storage_path
	if DirAccess.dir_exists_absolute(path): return {"ok":false,"reason":"format"}
	if not FileAccess.file_exists(path):
		return {"ok":true,"present":false,"signature":"missing","text":""}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"ok":false,"reason":"read"}
	var length: int = file.get_length()
	if length > MAX_BYTES:
		file.close()
		return {"ok":false,"reason":"size"}
	var bytes: PackedByteArray = file.get_buffer(length)
	file.close()
	if bytes.size() != length: return {"ok":false,"reason":"read"}
	if not _valid_utf8(bytes): return {"ok":false,"reason":"format"}
	var text: String = bytes.get_string_from_utf8()
	if text.to_utf8_buffer() != bytes: return {"ok":false,"reason":"format"}
	return {"ok":true,"present":true,"signature":text.sha256_text(),"text":text}


func _decode_snapshot(text: String, legacy: bool = false) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK: return _invalid("format")
	var result: Dictionary = _validate_snapshot(parser.data,legacy)
	if not result.ok: return result
	if text != _canonical(result.snapshot): return _invalid("format")
	return result


func _disk_unchanged() -> bool:
	if not _paths_unchanged():
		_protect("changed")
		return false
	var disk: Dictionary = _read_disk()
	if not disk.ok or disk.signature != _disk_signature:
		_protect("changed")
		return false
	if _watch_legacy:
		var previous: Dictionary = _read_disk(_loaded_legacy_path)
		if not previous.ok or previous.signature != _legacy_signature:
			_protect("changed")
			return false
	return true


func _resolved_legacy_path() -> String:
	return legacy_path if not legacy_path.is_empty() else LEGACY_PATH if storage_path == DEFAULT_PATH else ""


func _paths_unchanged() -> bool:
	return storage_path == _loaded_path and (not _watch_legacy or _resolved_legacy_path() == _loaded_legacy_path)


func _writer_path() -> String:
	# Lease.lock_path normally covers an entire candidate profile. Each target
	# sidecar gets a dedicated directory, independent of Notebook/candidate saves.
	return storage_path+".writer/challenges.json"


func _writer_paths() -> Array[String]:
	var paths: Array[String] = []
	if _watch_legacy: paths.append(_loaded_legacy_path+".writer/challenges.json")
	paths.append(_writer_path())
	return paths


func _acquire_writers(paths: Array[String], leases: Array[RefCounted]) -> String:
	_blocked_writer_path = ""
	for path: String in paths:
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir()) != OK:
			_release_writers(leases)
			return "write"
		var lease: RefCounted = Lease.new(path)
		if not lease.owns(path):
			_blocked_writer_path = path
			lease.release()
			_release_writers(leases)
			return "busy"
		leases.append(lease)
	return ""


func _writers_owned(paths: Array[String], leases: Array[RefCounted]) -> bool:
	for index: int in paths.size():
		if not leases[index].owns(paths[index]):
			_blocked_writer_path = paths[index]
			return false
	return true


func _release_writers(leases: Array[RefCounted]) -> void:
	for index: int in range(leases.size()-1,-1,-1): leases[index].release()
	leases.clear()


func _temporary_path() -> String:
	return storage_path+".tmp."+Crypto.new().generate_random_bytes(16).hex_encode()


func _discard_temporary(path: String) -> void:
	var prefix: String = storage_path+".tmp."
	if not path.begins_with(prefix): return
	var token: String = path.trim_prefix(prefix)
	if token.length() == 32 and token.is_valid_hex_number(false) and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _replace_file(temporary: String, target: String) -> Error:
	return DirAccess.rename_absolute(temporary,target)


static func _keys_exact(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size(): return false
	for key: Variant in value:
		if not key is String or key not in keys: return false
	return true


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum


static func _valid_utf8(bytes: PackedByteArray) -> bool:
	# Reject malformed encodings before Godot's decoding/replacement diagnostics.
	var index: int = 0
	while index < bytes.size():
		var first: int = bytes[index]
		if first < 128:
			index += 1
			continue
		var count: int
		if first >= 194 and first <= 223: count = 2
		elif first >= 224 and first <= 239: count = 3
		elif first >= 240 and first <= 244: count = 4
		else: return false
		if index+count > bytes.size(): return false
		var second: int = bytes[index+1]
		if first == 224 and second < 160 or first == 237 and second >= 160: return false
		if first == 240 and second < 144 or first == 244 and second >= 144: return false
		for offset: int in range(1,count):
			if bytes[index+offset] < 128 or bytes[index+offset] > 191: return false
		index += count
	return true


static func _canonical(value: Dictionary) -> String:
	return JSON.stringify(value,"",true)


static func _invalid(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}


func _protect(reason: String) -> void:
	storage_status = "read_only"
	last_error = reason


func _failed(reason: String) -> Dictionary:
	storage_status = "write_failed"
	last_error = reason
	return _result(false)


func _ready() -> void:
	storage_status = "ready"
	last_error = ""


func _result(ok: bool) -> Dictionary:
	return {
		"ok":ok,"snapshot":_committed.duplicate(true),"status":storage_status,"reason":last_error,
		"origin":origin,"copy_pending":copy_pending,
	}
