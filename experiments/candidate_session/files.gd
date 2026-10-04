extends RefCounted
## Candidate-only transactional files. Filesystem/process-crash recovery, not fsync guarantees.
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const MAX_BYTES := 262144

static func read_one(path: String, decode: Callable) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok":true,"empty":true,"digest":""}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"ok":false,"error":"read"}
	if file.get_length() > MAX_BYTES: return {"ok":false,"error":"size"}
	var raw := file.get_as_text()
	var result: Dictionary = decode.call(raw)
	result["digest"] = raw.sha256_text()
	return result

static func transaction_paths(path: String) -> Array[String]:
	var paths: Array[String] = []
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate): paths.append(candidate)
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		for name: String in directory.get_files():
			if name.begins_with(path.get_file() + ".tmp."): paths.append(path.get_base_dir().path_join(name))
	paths.sort()
	return paths

static func fingerprint(path: String) -> String:
	var parts: Array = []
	for candidate: String in transaction_paths(path):
		parts.append([candidate, FileAccess.get_sha256(candidate)])
	return JSON.stringify(parts).sha256_text()

static func read_session(path: String, decode: Callable) -> Dictionary:
	var main := read_one(path, decode)
	# An unknown/future main is never bypassed with an older backup.
	if not main.ok and main.get("error") in ["version","schema"]: return main
	var paths := transaction_paths(path)
	var interrupted: bool = main.get("empty",false) and not paths.is_empty()
	for candidate: String in paths:
		if candidate != path and candidate != path + ".bak": interrupted = true
	if main.ok and not interrupted: return main
	var choices: Array = []
	for candidate: String in paths:
		var value := read_one(candidate, decode)
		if value.ok and not value.get("empty",false):
			choices.append({"path":candidate,"digest":value.digest,"task":value.task})
	return {"ok":false,"error":"recovery","choices":choices,"fingerprint":fingerprint(path)}

static func preserve(path: String, original: String) -> Error:
	if not FileAccess.file_exists(original): return OK
	var directory: String = path + ".snapshots"
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return error
	var hash: String = FileAccess.get_sha256(original)
	if hash.is_empty(): return ERR_FILE_CANT_READ
	var target := directory.path_join(hash + ".json")
	if FileAccess.file_exists(target):
		if FileAccess.get_sha256(target) == hash: return OK
		# Retain a damaged/partial old archive rather than letting it permanently
		# block recovery of still-valid originals.
		error = DirAccess.rename_absolute(target,target + ".damaged-" + Crypto.new().generate_random_bytes(8).hex_encode())
		if error != OK: return error
	var temporary := target + ".partial-" + Crypto.new().generate_random_bytes(16).hex_encode()
	error = DirAccess.copy_absolute(original, temporary)
	if error != OK: return error
	if FileAccess.get_sha256(temporary) != hash: return ERR_FILE_CORRUPT
	return DirAccess.rename_absolute(temporary,target)

static func write_session(raw: String, path: String, expected_digest: String, decode: Callable, owner: RefCounted = null, stop_after: String = "") -> Error:
	var lease: RefCounted = owner if owner != null else Lease.new(path)
	if not lease.owns(path): return ERR_ALREADY_IN_USE
	if not decode.call(raw).ok: return ERR_INVALID_DATA
	var current := read_session(path, decode)
	if not current.ok: return ERR_INVALID_DATA
	if current.get("digest", "") != expected_digest: return ERR_ALREADY_IN_USE
	return install(raw,path,decode,stop_after)

static func install(raw: String, path: String, decode: Callable, stop_after: String = "") -> Error:
	# Called only with a lease. Unique names avoid sharing a partially written file.
	var temporary := path + ".tmp." + Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(raw); file.flush()
	var error := file.get_error(); file.close()
	if error != OK: return error
	if stop_after == "temporary": return ERR_BUSY
	if not read_one(temporary,decode).ok: return ERR_FILE_CORRUPT
	if stop_after == "validated": return ERR_BUSY
	# Archive all overwritten originals, including schema1 migration and prior bak.
	for previous: String in [path,path + ".bak"]:
		error = preserve(path,previous)
		if error != OK: return error
	if stop_after == "archived": return ERR_BUSY
	if FileAccess.file_exists(path + ".bak"):
		var retained_backup := (path + ".snapshots").path_join("previous-backup-" + Crypto.new().generate_random_bytes(8).hex_encode())
		error = DirAccess.rename_absolute(path + ".bak",retained_backup)
		if error != OK: return error
	if FileAccess.file_exists(path):
		error = DirAccess.rename_absolute(path,path + ".bak")
		if error != OK: return error
	if stop_after == "backed_up": return ERR_BUSY
	error = DirAccess.rename_absolute(temporary,path)
	if error != OK: return error # Leave both candidates for explicit recovery.
	if stop_after == "installed": return ERR_BUSY
	return OK

static func recover_session(path: String, source: String, expected_fingerprint: String, decode: Callable, owner: RefCounted = null) -> Error:
	var lease: RefCounted = owner if owner != null else Lease.new(path)
	if not lease.owns(path): return ERR_ALREADY_IN_USE
	var state := read_session(path,decode)
	if state.get("error") != "recovery" or state.get("fingerprint") != expected_fingerprint: return ERR_ALREADY_IN_USE
	var allowed: bool = false
	for choice: Dictionary in state.choices:
		if choice.path == source: allowed = true
	if not allowed: return ERR_INVALID_DATA
	var raw := FileAccess.get_file_as_string(source)
	if not decode.call(raw).ok: return ERR_INVALID_DATA
	# Preserve every original before touching any transaction member. If interrupted
	# during cleanup, at least one valid transaction candidate remains until install.
	var paths := transaction_paths(path)
	for previous: String in paths:
		var error := preserve(path,previous)
		if error != OK: return error
	# Install via an independent recovery candidate. Keep it through cleanup so a
	# crash cannot make the profile appear empty; snapshots never replace discovery.
	var retained := path + ".tmp.recovery-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(retained,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(raw); file.flush(); var error := file.get_error(); file.close()
	if error != OK or not read_one(retained,decode).ok: return ERR_FILE_CORRUPT
	for previous: String in paths:
		# Move, rather than delete, original names into the archive after copy validation.
		var archive := (path + ".snapshots").path_join(previous.get_file() + "." + Crypto.new().generate_random_bytes(8).hex_encode())
		error = DirAccess.rename_absolute(previous,archive)
		if error != OK: return error
	return DirAccess.rename_absolute(retained,path)
