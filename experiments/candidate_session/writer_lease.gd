extends RefCounted
## Cooperative local-profile writer exclusion. Never silently remove a stale owner.
var path: String
var token: String
var held: bool = false

func _init(save_path: String = "") -> void:
	if save_path.is_empty(): return # Used only by recover_and_acquire under its gate.
	path = lock_path(save_path)
	if DirAccess.dir_exists_absolute(path + ".recovering"): return
	_acquire_directory()
	if DirAccess.dir_exists_absolute(path + ".recovering"): release()

func _acquire_directory() -> void:
	token = Crypto.new().generate_random_bytes(16).hex_encode()
	if DirAccess.make_dir_absolute(path) != OK: return
	var file := FileAccess.open(path.path_join("owner.json"), FileAccess.WRITE)
	if file == null: return # Incomplete lock is deliberately conservative.
	file.store_string(JSON.stringify({"pid":OS.get_process_id(),"token":token,"context":local_context()}))
	file.flush(); var error := file.get_error(); file.close()
	held = error == OK

func owns(save_path: String) -> bool:
	if not held or path != lock_path(save_path): return false
	var owner: Variant = JSON.parse_string(FileAccess.get_file_as_string(path.path_join("owner.json")))
	return owner is Dictionary and owner.get("token") == token and owner.get("pid") == OS.get_process_id()

func release() -> void:
	if not held: return
	var owner: Variant = JSON.parse_string(FileAccess.get_file_as_string(path.path_join("owner.json")))
	if owner is Dictionary and owner.get("token") == token and owner.get("pid") == OS.get_process_id():
		DirAccess.remove_absolute(path.path_join("owner.json"))
		DirAccess.remove_absolute(path)
	held = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and held:
		# RefCounted is already being destroyed: do not call member methods here.
		var owner: Variant = JSON.parse_string(FileAccess.get_file_as_string(path.path_join("owner.json")))
		if owner is Dictionary and owner.get("token") == token:
			DirAccess.remove_absolute(path.path_join("owner.json"))
			DirAccess.remove_absolute(path)

static func lock_path(save_path: String) -> String:
	return ProjectSettings.globalize_path(save_path).simplify_path().get_base_dir().path_join(".candidate-writer")

static func linux_context() -> String:
	if OS.get_name() != "Linux": return ""
	var namespace_dir := DirAccess.open("/proc/self/ns")
	var boot := FileAccess.open("/proc/sys/kernel/random/boot_id",FileAccess.READ)
	var process := FileAccess.open("/proc/self/stat",FileAccess.READ)
	if namespace_dir == null or boot == null or process == null: return ""
	# get_line works for proc pseudo-files whose reported length is zero.
	if process.get_line().get_slice(" ",0).to_int() != OS.get_process_id(): return ""
	var identity: String = namespace_dir.read_link("pid")
	var boot_id: String = boot.get_line().strip_edges()
	if identity.is_empty() or boot_id.is_empty(): return ""
	return boot_id + ":" + identity

static func local_context() -> String:
	if OS.get_name() == "Linux": return linux_context() # Preserve existing owner records.
	if OS.get_name() != "macOS": return ""
	var output: Array = []
	# Use the native binary directly, with no shell, PATH lookup or privilege change.
	if OS.execute("/usr/sbin/sysctl",["-n","kern.bootsessionuuid"],output,true) != 0 or output.size() != 1: return ""
	return _macos_boot_context(str(output[0]))

static func _macos_boot_context(raw: String) -> String:
	var uuid: String = raw.strip_edges().to_lower()
	var parts: PackedStringArray = uuid.split("-",true)
	var sizes: Array[int] = [8,4,4,4,12]
	if parts.size() != sizes.size(): return ""
	for i: int in sizes.size():
		if parts[i].length() != sizes[i] or not parts[i].is_valid_hex_number(false): return ""
	if uuid.replace("-","") == "00000000000000000000000000000000": return ""
	return "macos:" + uuid

static func _macos_snapshot_pids(exit_code: int, raw: String, self_pid: int) -> Array[int]:
	# A failed/empty/malformed query is unknown, never evidence of a stopped PID.
	# Seeing ourselves verifies that the all-process query actually returned a list.
	var pids: Array[int] = []
	if exit_code != 0 or self_pid <= 0: return pids
	var saw_self: bool = false
	for line: String in raw.split("\n",false):
		var value: String = line.strip_edges()
		if not value.is_valid_int() or value.to_int() < 0 or str(value.to_int()) != value: return []
		if value.to_int() == self_pid: saw_self = true
		pids.append(value.to_int())
	if not saw_self: pids.clear()
	return pids

static func _macos_snapshot_stopped(exit_code: int, raw: String, pid: int, self_pid: int) -> bool:
	var pids: Array[int] = _macos_snapshot_pids(exit_code,raw,self_pid)
	return pid > 0 and not pids.is_empty() and not pids.has(pid)

static func _macos_process_pids() -> Array[int]:
	var output: Array = []
	# Unix OS.is_process_running tracks children only. ps -ax includes unrelated
	# writers and reused PIDs, without inspecting command lines or other user data.
	var exit_code: int = OS.execute("/bin/ps",["-axo","pid="],output,true)
	if output.size() != 1: return []
	return _macos_snapshot_pids(exit_code,str(output[0]),OS.get_process_id())

static func stopped_owner(save_path: String) -> String:
	var lock: String = lock_path(save_path)
	if not FileAccess.file_exists(lock.path_join("owner.json")): return ""
	var owner: Variant = JSON.parse_string(FileAccess.get_file_as_string(lock.path_join("owner.json")))
	if not owner is Dictionary or owner.size() != 3 or not owner.get("pid") is float or not owner.get("token") is String: return ""
	if owner.token.length() != 32 or not owner.token.is_valid_hex_number(false): return ""
	var context: String = local_context()
	if context.is_empty() or owner.get("context") != context: return ""
	var pid: int = int(owner.pid)
	if pid <= 0 or float(pid) != owner.pid: return ""
	# Godot OS.is_process_running only tracks child processes on Unix. Do not
	# mistake an unrelated live writer for dead. Unsupported hosts refuse recovery.
	if OS.get_name() == "Linux":
		if not DirAccess.dir_exists_absolute("/proc") or DirAccess.dir_exists_absolute("/proc/" + str(pid)): return ""
	elif OS.get_name() == "macOS":
		var pids: Array[int] = _macos_process_pids()
		if pids.is_empty() or pids.has(pid): return ""
	else: return ""
	return owner.token

static func recover_and_acquire(save_path: String, expected_token: String) -> Dictionary:
	# Keep the gate through acquisition: neither competing reclaimers nor ordinary
	# acquisition can observe a completed recovery with no new owner installed.
	var lock: String = lock_path(save_path)
	var gate: String = lock + ".recovering"
	if expected_token.is_empty() or DirAccess.make_dir_absolute(gate) != OK: return {"error":ERR_ALREADY_IN_USE}
	var result: Dictionary = {"error":ERR_ALREADY_IN_USE}
	if stopped_owner(save_path) == expected_token:
		var error := DirAccess.rename_absolute(lock, lock + ".abandoned-" + expected_token)
		if error == OK:
			var recovered: RefCounted = load("res://experiments/candidate_session/writer_lease.gd").new()
			recovered.path = lock
			recovered._acquire_directory()
			result = {"error":OK,"lease":recovered} if recovered.held else {"error":ERR_CANT_CREATE}
		else: result = {"error":error}
	DirAccess.remove_absolute(gate)
	return result
