extends RefCounted
## Retained experiment codes only. Live target scores always require remeasurement.
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const MAX_BYTES: int = 32768
const MAX_TARGETS: int = 4
const SNAPSHOT_KEYS := ["version","targets"]
var storage_path: String = "user://layout_strategy_challenges_v1.json"
var storage_status: String = "ready"
var last_error: String = ""
var _loaded: bool = false
var _loaded_path: String = ""
var _disk_signature: String = ""
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
	var writer_path: String = _writer_path()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(writer_path).get_base_dir()) != OK:
		return _failed("write")
	var lease: RefCounted = Lease.new(writer_path)
	if not lease.owns(writer_path):
		lease.release()
		return _failed("busy")
	# The lease serializes cooperating target writers. The digest also protects
	# changes made before ownership or by an ordinary external editor.
	if not _disk_unchanged():
		lease.release()
		return _result(false)
	if proposed == _committed:
		lease.release()
		_ready()
		return _result(true)
	var temporary: String = _temporary_path()
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		lease.release()
		return _failed("write")
	file.store_string(text)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		_discard_temporary(temporary)
		lease.release()
		return _failed("write")
	var written: Dictionary = _read_disk(temporary)
	if not written.ok or not written.present or written.text != text or not _decode_snapshot(written.text).ok:
		_discard_temporary(temporary)
		lease.release()
		return _failed("write")
	if not lease.owns(writer_path):
		_discard_temporary(temporary)
		lease.release()
		return _failed("busy")
	if not _disk_unchanged():
		_discard_temporary(temporary)
		lease.release()
		return _result(false)
	if _replace_file(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(storage_path)) != OK:
		_discard_temporary(temporary)
		lease.release()
		return _failed("replace")
	_committed = proposed.duplicate(true)
	_disk_signature = text.sha256_text()
	lease.release()
	_ready()
	return _result(true)


func recover_writer() -> Dictionary:
	_load()
	if storage_status == "read_only": return _result(false)
	if not _disk_unchanged(): return _result(false)
	var writer_path: String = _writer_path()
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
	_ready()
	return _result(true)


static func normalize_snapshot(value: Variant) -> Dictionary:
	var result: Dictionary = _validate_snapshot(value)
	return result.snapshot.duplicate(true) if result.ok else {}


static func _validate_snapshot(value: Variant) -> Dictionary:
	if not value is Dictionary: return _invalid("format")
	if value.has("version") and not _integer(value.version,1,1): return _invalid("version")
	if not _keys_exact(value,SNAPSHOT_KEYS): return _invalid("format")
	if not value.targets is Dictionary: return _invalid("format")
	if value.targets.size() > MAX_TARGETS: return _invalid("size")
	var targets: Dictionary = {}
	for id: Variant in value.targets:
		if not id is String or id not in Model.SCENARIO_IDS: return _invalid("task")
		var code: Variant = value.targets[id]
		if not code is String: return _invalid("format")
		var decoded: Dictionary = Code.decode(code)
		if not decoded.ok: return _invalid(decoded.reason)
		if decoded.envelope.task != id: return _invalid("task")
		if decoded.code != code: return _invalid("format")
		# Decode performs structural validation only. A supported old identity
		# stays byte-exact; the controller must inspect before activating it.
		targets[id] = code
	var snapshot: Dictionary = {"version":1,"targets":targets}
	if _canonical(snapshot).to_utf8_buffer().size() > MAX_BYTES: return _invalid("size")
	return {"ok":true,"reason":"","snapshot":snapshot}


func _load() -> void:
	if _loaded:
		if _loaded_path != storage_path: _protect("changed")
		return
	_loaded = true
	_loaded_path = storage_path
	var disk: Dictionary = _read_disk()
	if not disk.ok:
		_protect(disk.reason)
		return
	_disk_signature = disk.signature
	if not disk.present:
		_committed = {"version":1,"targets":{}}
		return
	var decoded: Dictionary = _decode_snapshot(disk.text)
	if not decoded.ok:
		_protect(decoded.reason)
		return
	_committed = decoded.snapshot


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


func _decode_snapshot(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK: return _invalid("format")
	var result: Dictionary = _validate_snapshot(parser.data)
	if not result.ok: return result
	if text != _canonical(result.snapshot): return _invalid("format")
	return result


func _disk_unchanged() -> bool:
	if storage_path != _loaded_path:
		_protect("changed")
		return false
	var disk: Dictionary = _read_disk()
	if not disk.ok or disk.signature != _disk_signature:
		_protect("changed")
		return false
	return true


func _writer_path() -> String:
	# Lease.lock_path normally covers an entire candidate profile. Each target
	# sidecar gets a dedicated directory, independent of Notebook/candidate saves.
	return storage_path+".writer/challenges.json"


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
	return {"ok":ok,"snapshot":_committed.duplicate(true),"status":storage_status,"reason":last_error}
