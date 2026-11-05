extends SceneTree
const Store = preload("res://experiments/layout_strategy/challenge_store.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Notebook = preload("res://experiments/layout_strategy/notebook_store.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")

class FaultStore:
	extends "res://experiments/layout_strategy/challenge_store.gd"
	var blocked_open: String = ""
	var blocked_replace: String = ""
	var external_text: String = ""
	var deny_read: bool = false
	var deny_temporary_read: bool = false
	var temporary_paths: Array[String] = []

	func _temporary_path() -> String:
		var path: String = super._temporary_path()
		temporary_paths.append(path)
		if not external_text.is_empty():
			var file := FileAccess.open(storage_path,FileAccess.WRITE)
			file.store_string(external_text)
			file.flush()
			file.close()
			external_text = ""
		return path if blocked_open.is_empty() else blocked_open

	func _replace_file(temporary: String, target: String) -> Error:
		return DirAccess.rename_absolute(temporary,target if blocked_replace.is_empty() else blocked_replace)

	func _read_disk(path: String = "") -> Dictionary:
		if deny_read or deny_temporary_read and not path.is_empty():
			return {"ok":false,"reason":"read"}
		return super._read_disk(path)

var checks: int = 0
var failures: Array[String] = []
var directory: String = ""
var _codes: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func fixture_path(name: String) -> String:
	return directory.path_join(name+".json")


func store_for(name: String) -> RefCounted:
	var store: RefCounted = Store.new()
	store.storage_path = fixture_path(name)
	return store


func raw_write(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.flush()
	file.close()


func canonical(value: Variant) -> String:
	return JSON.stringify(value,"",true)


func code_for(id: String, objective: String = "cycles") -> String:
	var key: String = id+"/"+objective
	if not _codes.has(key):
		var goal: Dictionary = Goals.default_goal()
		goal.objective = objective
		var created: Dictionary = Code.create(id,Model.starter_plan(),goal)
		check(created.ok,"Real starter recipe creates a target for "+key)
		_codes[key] = str(created.get("code",""))
	return _codes[key]


func snapshot_for(id: String = "scan_batch") -> Dictionary:
	return {"version":2,"targets":{id:code_for(id)}}


func changed_code(code: String, key: String, value: Variant) -> String:
	var envelope: Dictionary = Code.decode(code).envelope.duplicate(true)
	envelope[key] = value
	return Code.PREFIX+canonical(envelope)


func protected_files() -> Dictionary:
	var result: Dictionary = {}
	for name: String in ["layout_strategy_notebook_v1.json","layout_strategy_notebook_v2.json","layout_challenges_v1.json","layout_strategy_challenges_v1.json","layout_strategy_challenges_v2.json"]:
		var path: String = "user://"+name
		result[name] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	return result


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for challenge persistence checks.")
		quit(1)
		return
	directory = "user://layout-strategy-challenge-store-"+Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(directory)
	for frame: int in 3: await process_frame
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	var old_layout: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	var old_files: Dictionary = protected_files()
	_round_trip()
	_supported_stale()
	_normalization_and_bounds()
	_protected_files()
	_external_changes()
	_failed_writes()
	_writer_contention()
	_writer_recovery()
	_interrupted_temporary()
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	before.erase("saved_at_utc")
	after.erase("saved_at_utc")
	check(before == after and root.get_node("LayoutChapter").game_snapshot() == old_layout,"Challenge storage never awards or changes official player state")
	check(protected_files() == old_files,"Isolated store fixtures preserve the default Notebook and both challenge files")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy challenge store %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _round_trip() -> void:
	var empty: RefCounted = store_for("empty")
	var initial: Dictionary = empty.read()
	var blank: Dictionary = {"version":2,"targets":{}}
	check(initial.ok and initial.status == "ready" and initial.snapshot == blank,"Missing file returns a detached empty target map")
	check(not FileAccess.file_exists(empty.storage_path),"Reading absence creates no target file")
	check(empty.write(blank).ok and not FileAccess.file_exists(empty.storage_path),"An unchanged empty write is idempotent")
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(empty._writer_path())),"No-op write releases its lease")
	var snapshot: Dictionary = {"version":2,"targets":{}}
	for id: String in Model.SCENARIO_IDS:
		snapshot.targets[id] = code_for(id,"traffic" if id.ends_with("serial") else "cycles")
	var grouped: Dictionary = Model.starter_plan()
	grouped.query_group = 8
	grouped.record_tile = 1
	var target: Dictionary = Code.create("scan_batch",grouped,Goals.default_goal())
	check(target.ok,"Roundtrip fixture uses a genuinely measured grouped recipe")
	snapshot.targets["scan_batch"] = target.code
	var expected: Dictionary = snapshot.duplicate(true)
	var store: RefCounted = store_for("round-trip")
	var written: Dictionary = store.write(snapshot)
	check(written.ok and written.status == "ready" and written.snapshot == expected,"Six task codes and both goals persist without conversion")
	var raw: String = FileAccess.get_file_as_string(store.storage_path)
	check(raw == canonical(expected),"Persisted targets have one canonical whole-file representation")
	check(not raw.contains("metrics") and not raw.contains("trace_id") and not raw.contains("events"),"Stored target file carries no cached score or Trace")
	written.snapshot.targets.clear()
	snapshot.targets.clear()
	check(store.read().snapshot == expected,"Caller and returned snapshots cannot mutate committed targets")
	var detached: Dictionary = store.read()
	detached.snapshot.targets.erase("mixed_serial")
	check(store.read().snapshot.targets.size() == 6,"Read returns a detached complete target map")
	var restarted: RefCounted = store_for("round-trip")
	var restored: Dictionary = restarted.read()
	check(restored.ok and canonical(restored.snapshot) == raw,"Fresh store restores all exact target codes")
	check(restarted.write(restored.snapshot).ok and FileAccess.get_file_as_string(store.storage_path) == raw,"An identical target retry preserves original bytes")
	var replayed: Dictionary = Code.inspect(restored.snapshot.targets.scan_batch)
	check(replayed.ok and replayed.entry.correct,"Reopened target is activated only through actual codec inspection")
	check(replayed.entry.trace_id == target.entry.trace_id and replayed.entry.events == target.entry.events and replayed.entry.outputs == target.entry.outputs,"Reopened target reproduces complete event/output evidence and Trace identity")
	check(replayed.entry.metrics.first_request_cycles == 531 and replayed.entry.metrics.total_cycles == 552,"Reopened target has the actual grouped response/total result")
	check(store_for("separate-profile").read().snapshot == blank,"Another target path never adopts this collection")
	var cleared: Dictionary = {"version":2,"targets":{}}
	check(restarted.write(cleared).ok and store_for("round-trip").read().snapshot == cleared,"Explicit empty map removes targets without touching other files")


func _supported_stale() -> void:
	var snapshot: Dictionary = {"version":2,"targets":{}}
	var old_model: String = changed_code(code_for("scan_batch"),"model","layout-schedule-experiment-older")
	var old_condition: String = changed_code(code_for("scan_serial"),"condition","0".repeat(64))
	snapshot.targets["scan_batch"] = old_model
	snapshot.targets["scan_serial"] = old_condition
	check(Code.decode(old_model).ok and Code.decode(old_condition).ok,"Structurally supported old identities remain decodable")
	check(not Code.inspect(old_model).ok and not Code.inspect(old_condition).ok,"Stored old identities do not create active target scores")
	check(Store.normalize_snapshot(snapshot) == snapshot,"Store retains supported stale code byte-for-byte")
	var store: RefCounted = store_for("supported-stale")
	check(store.write(snapshot).ok,"Supported stale codes can coexist in a protected target collection")
	var restarted: RefCounted = store_for("supported-stale")
	check(restarted.read().snapshot == snapshot and restarted.storage_status == "ready","Restart retains supported stale inputs without treating them as current results")
	var with_current: Dictionary = snapshot.duplicate(true)
	with_current.targets["mixed_batch"] = code_for("mixed_batch","traffic")
	check(restarted.write(with_current).ok,"Adding a current target does not discard retained old identities")
	check(store_for("supported-stale").read().snapshot.targets.scan_batch == old_model,"Unrelated save preserves the exact original old code")


func _normalization_and_bounds() -> void:
	var snapshot: Dictionary = snapshot_for()
	var numeric: Dictionary = JSON.parse_string(canonical(snapshot))
	numeric.version = 2.0
	check(Store.normalize_snapshot(numeric) == snapshot,"Integral in-memory version normalizes without changing code bytes")
	var normalized: Dictionary = Store.normalize_snapshot(snapshot)
	normalized.targets.clear()
	check(Store.normalize_snapshot(snapshot) == snapshot,"Normalization returns detached target maps")
	var maximal: Dictionary = {"version":2,"targets":{}}
	for id: String in Model.SCENARIO_IDS: maximal.targets[id] = code_for(id)
	check(Store.normalize_snapshot(maximal) == maximal and canonical(maximal).to_utf8_buffer().size() <= Store.MAX_BYTES,"All six current targets fit declared file bounds")
	var store: RefCounted = store_for("maximal")
	check(store.write(maximal).ok and store_for("maximal").read().snapshot == maximal,"Maximum target collection survives restart")
	var over: Dictionary = maximal.duplicate(true)
	over.targets["seventh"] = code_for("scan_batch")
	check(Store.normalize_snapshot(over).is_empty(),"Seventh target is refused without silent eviction")
	var previous: PackedByteArray = FileAccess.get_file_as_bytes(store.storage_path)
	check(not store.write(over).ok and FileAccess.get_file_as_bytes(store.storage_path) == previous,"Oversized proposal preserves original target bytes")
	check(store.read().snapshot == maximal and store.write(maximal).ok,"Capacity failure preserves committed memory and exact valid retry")
	var whitespace: Dictionary = snapshot_for()
	whitespace.targets["scan_batch"] = " "+whitespace.targets.scan_batch+"\n"
	check(Store.normalize_snapshot(whitespace).is_empty(),"Stored codes must already have canonical clipboard-free spelling")


func _protected_files() -> void:
	var base: Dictionary = snapshot_for()
	var code: String = base.targets.scan_batch
	var fixtures: Array[Dictionary] = [
		{"name":"root-array","value":[]},
		{"name":"future-version","value":{"version":99,"targets":{}}},
		{"name":"boolean-version","value":{"version":true,"targets":{}}},
		{"name":"missing-version","value":{"targets":{}}},
		{"name":"missing-targets","value":{"version":2}},
		{"name":"unknown-root","value":{"version":2,"targets":{},"scores":[]}},
		{"name":"targets-array","value":{"version":2,"targets":[]}},
		{"name":"unknown-task","value":{"version":2,"targets":{"future":code}}},
		{"name":"scalar-code","value":{"version":2,"targets":{"scan_batch":42}}},
		{"name":"nested-score","value":{"version":2,"targets":{"scan_batch":{"code":code,"metrics":{"total_cycles":0}}}}},
		{"name":"foreign-task","value":{"version":2,"targets":{"scan_serial":code}}},
		{"name":"empty-code","value":{"version":2,"targets":{"scan_batch":""}}},
		{"name":"padded-code","value":{"version":2,"targets":{"scan_batch":" "+code+"\n"}}},
		{"name":"future-code-version","value":{"version":2,"targets":{"scan_batch":changed_code(code,"v",2)}}},
		{"name":"future-code-prefix","value":{"version":2,"targets":{"scan_batch":code.replace(Code.PREFIX,"VNBSC2:")}}},
		{"name":"claimed-score-code","value":{"version":2,"targets":{"scan_batch":changed_code(code,"score",0)}}},
		{"name":"goal-array","value":{"version":2,"targets":{"scan_batch":changed_code(code,"goal",[])}}},
		{"name":"plan-array","value":{"version":2,"targets":{"scan_batch":changed_code(code,"plan",[])}}},
		{"name":"condition-type","value":{"version":2,"targets":{"scan_batch":changed_code(code,"condition",false)}}},
		{"name":"overlong-code","value":{"version":2,"targets":{"scan_batch":"x".repeat(Code.MAX_BYTES+1)}}},
	]
	var extra: Dictionary = Code.decode(code).envelope
	extra.plan.recipe.groups[0]["future"] = 1
	fixtures.append({"name":"nested-recipe-field","value":{"version":2,"targets":{"scan_batch":Code.PREFIX+canonical(extra)}}})
	var partial: Dictionary = base.duplicate(true)
	partial.targets["mixed_batch"] = "valuable unsupported code"
	fixtures.append({"name":"partial-valid-map","value":partial})
	var too_many: Dictionary = {"version":2,"targets":{}}
	for id: String in Model.SCENARIO_IDS: too_many.targets[id] = code_for(id)
	too_many.targets["seventh"] = code
	fixtures.append({"name":"too-many-targets","value":too_many})
	for fixture: Dictionary in fixtures:
		check(Store.normalize_snapshot(fixture.value).is_empty(),fixture.name+": invalid snapshot cannot normalize")
		_assert_protected(fixture.name,canonical(fixture.value).to_utf8_buffer())
	var raw: String = canonical(base)
	_assert_protected("broken-json","{valuable unfinished".to_utf8_buffer())
	_assert_protected("oversized","x".repeat(Store.MAX_BYTES+1).to_utf8_buffer(),"size")
	_assert_protected("duplicate-root",raw.replace('"version":2','"version":2,"version":2').to_utf8_buffer())
	var duplicate_target: String = '{"targets":{"scan_batch":'+canonical(code)+',"scan_batch":'+canonical(code)+'},"version":2}'
	_assert_protected("duplicate-task",duplicate_target.to_utf8_buffer())
	var duplicate_code: Dictionary = base.duplicate(true)
	duplicate_code.targets["scan_batch"] = code.replace('"v":1','"v":1,"v":1')
	_assert_protected("duplicate-code-key",canonical(duplicate_code).to_utf8_buffer())
	_assert_protected("pretty-json",JSON.stringify(base,"  ",true).to_utf8_buffer())
	_assert_protected("float-spelling",raw.replace('"version":2','"version":2.0').to_utf8_buffer())
	var invalid_encodings: Array[PackedByteArray] = [
		PackedByteArray([255]),PackedByteArray([192,175]),
		PackedByteArray([237,160,128]),PackedByteArray([244,144,128,128]),
		PackedByteArray([226,130]),PackedByteArray([128]),
	]
	for index: int in invalid_encodings.size():
		var bytes: PackedByteArray = raw.to_utf8_buffer()
		bytes.append_array(invalid_encodings[index])
		_assert_protected("invalid-utf8-"+str(index),bytes,"format")
	var directory_store: RefCounted = store_for("directory-path")
	DirAccess.make_dir_recursive_absolute(directory_store.storage_path)
	raw_write(directory_store.storage_path.path_join("keep.txt"),"original directory")
	check(not directory_store.read().ok and directory_store.storage_status == "read_only","Directory target is protected")
	check(not directory_store.write(base).ok and FileAccess.get_file_as_string(directory_store.storage_path.path_join("keep.txt")) == "original directory","Directory cannot be replaced by target storage")
	var denied := FaultStore.new()
	denied.storage_path = fixture_path("injected-read-failure")
	raw_write(denied.storage_path,raw)
	denied.deny_read = true
	check(not denied.read().ok and denied.last_error == "read" and denied.read().snapshot.is_empty(),"Injected read denial adopts no target map")
	denied.deny_read = false
	check(not denied.write(base).ok and FileAccess.get_file_as_string(denied.storage_path) == raw,"Previously unreadable file remains protected in the same store")


func _assert_protected(name: String, bytes: PackedByteArray, reason: String = "") -> void:
	var path: String = fixture_path(name)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(bytes)
	file.flush()
	file.close()
	var store: RefCounted = store_for(name)
	var loaded: Dictionary = store.read()
	check(not loaded.ok and loaded.status == "read_only" and loaded.snapshot.is_empty(),name+": whole file is refused without partial adoption")
	if not reason.is_empty(): check(loaded.reason == reason,name+": precise protected reason")
	check(not store.write(snapshot_for("mixed_serial")).ok and not store.recover_writer().ok,name+": writes and writer recovery cannot bypass invalid data")
	check(FileAccess.get_file_as_bytes(path) == bytes,name+": original bytes survive every rejected action")
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(store._writer_path()).get_base_dir()),name+": protected read creates no writer directory")


func _external_changes() -> void:
	var original: Dictionary = snapshot_for()
	var updated: Dictionary = snapshot_for("mixed_batch")
	var store: RefCounted = store_for("external-replaced")
	check(store.write(original).ok,"External-change fixture starts committed")
	raw_write(store.storage_path,canonical(updated))
	var result: Dictionary = store.write(original)
	check(not result.ok and result.status == "read_only" and result.reason == "changed","Identical save still detects external replacement before no-op")
	check(result.snapshot == original and FileAccess.get_file_as_string(store.storage_path) == canonical(updated),"External bytes and old committed memory remain separate")
	var appeared: RefCounted = store_for("external-appeared")
	var empty: Dictionary = appeared.read().snapshot
	raw_write(appeared.storage_path,canonical(updated))
	check(not appeared.write(empty).ok and appeared.last_error == "changed","An externally appeared file cannot be overwritten by an empty loaded map")
	var deleted: RefCounted = store_for("external-deleted")
	check(deleted.write(original).ok,"Deleted-file fixture starts committed")
	DirAccess.remove_absolute(deleted.storage_path)
	check(not deleted.write(updated).ok and not FileAccess.file_exists(deleted.storage_path),"Externally deleted targets are not silently recreated")
	var redirected: RefCounted = store_for("redirected")
	redirected.read()
	redirected.storage_path = store.storage_path
	check(not redirected.write(updated).ok and redirected.last_error == "changed","Loaded path cannot be redirected to another file")
	var during := FaultStore.new()
	during.storage_path = fixture_path("external-during-write")
	check(during.write(original).ok,"During-write fixture starts committed")
	during.external_text = canonical(updated)
	var proposed: Dictionary = original.duplicate(true)
	proposed.targets["scan_serial"] = code_for("scan_serial")
	result = during.write(proposed)
	check(not result.ok and result.reason == "changed" and result.snapshot == original,"External update during temporary preparation prevents adoption")
	check(FileAccess.get_file_as_string(during.storage_path) == canonical(updated),"Late conflict preserves external bytes")


func _failed_writes() -> void:
	var original: Dictionary = snapshot_for()
	var proposed: Dictionary = original.duplicate(true)
	proposed.targets["scan_serial"] = code_for("scan_serial")
	var store := FaultStore.new()
	store.storage_path = fixture_path("failed-io")
	check(store.write(original).ok,"I/O fixture starts with a committed target")
	var raw: String = FileAccess.get_file_as_string(store.storage_path)
	var blocked: String = directory.path_join("blocked-io-directory")
	DirAccess.make_dir_recursive_absolute(blocked)
	raw_write(blocked.path_join("keep.txt"),"preserve directory")
	store.blocked_open = blocked
	var failed: Dictionary = store.write(proposed)
	check(not failed.ok and failed.status == "write_failed" and failed.reason == "write","Actual temporary-file open on a directory fails visibly")
	check(failed.snapshot == original and FileAccess.get_file_as_string(store.storage_path) == raw,"Open failure keeps original bytes and committed targets")
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(store._writer_path())),"Failed open releases writer ownership")
	store.blocked_open = ""
	check(store.write(proposed).ok,"Exact target addition retries after temporary-open failure")
	original = proposed.duplicate(true)
	raw = FileAccess.get_file_as_string(store.storage_path)
	proposed.targets.erase("scan_serial")
	store.blocked_replace = ProjectSettings.globalize_path(blocked)
	failed = store.write(proposed)
	check(not failed.ok and failed.reason == "replace" and failed.snapshot == original,"Actual rename failure preserves old committed targets during pending clear")
	check(FileAccess.get_file_as_string(store.storage_path) == raw and FileAccess.get_file_as_string(blocked.path_join("keep.txt")) == "preserve directory","Failed replacement preserves both original file and blocked directory")
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(store._writer_path())),"Failed rename releases writer ownership")
	store.blocked_replace = ""
	check(store.write(proposed).ok and store.read().snapshot == proposed,"Exact clear proposal retries after rename failure")
	original = proposed.duplicate(true)
	raw = FileAccess.get_file_as_string(store.storage_path)
	proposed.targets["mixed_serial"] = code_for("mixed_serial")
	store.deny_temporary_read = true
	failed = store.write(proposed)
	check(not failed.ok and failed.reason == "write" and failed.snapshot == original,"Failed temporary readback refuses unverified bytes")
	check(FileAccess.get_file_as_string(store.storage_path) == raw and not DirAccess.dir_exists_absolute(Lease.lock_path(store._writer_path())),"Readback failure preserves main bytes and releases ownership")
	store.deny_temporary_read = false
	check(store.write(proposed).ok,"Exact request retries after readback becomes available")
	var seen: Array[String] = []
	for path: String in store.temporary_paths:
		check(not seen.has(path) and path.begins_with(store.storage_path+".tmp."),"Every attempted commit uses a unique own temporary path")
		check(not FileAccess.file_exists(path),"Finished attempts leave no owned temporary file")
		seen.append(path)


func _writer_contention() -> void:
	var snapshot: Dictionary = snapshot_for()
	var store: RefCounted = store_for("busy")
	check(store.write(snapshot).ok,"Busy fixture starts committed")
	var raw: String = FileAccess.get_file_as_string(store.storage_path)
	var lease: RefCounted = Lease.new(store._writer_path())
	check(lease.owns(store._writer_path()),"Competing writer owns the actual target lease")
	var proposed: Dictionary = snapshot.duplicate(true)
	proposed.targets["scan_serial"] = code_for("scan_serial")
	var result: Dictionary = store.write(proposed)
	check(not result.ok and result.reason == "busy" and result.snapshot == snapshot,"Competing owner refuses adoption of a pending proposal")
	check(not store.recover_writer().ok and lease.owns(store._writer_path()),"Explicit recovery cannot steal a live owner")
	check(FileAccess.get_file_as_string(store.storage_path) == raw,"Contention preserves original target bytes")
	lease.release()
	check(store.write(proposed).ok,"Same proposal retries after ordinary owner release")
	var first: RefCounted = store_for("two-stale-readers")
	var second: RefCounted = store_for("two-stale-readers")
	first.read()
	second.read()
	check(first.write(snapshot).ok,"First of two readers commits normally")
	check(not second.write(proposed).ok and second.last_error == "changed","Second reader cannot silently replace its stale initial state")
	check(FileAccess.get_file_as_string(first.storage_path) == canonical(snapshot),"First writer's targets survive the stale writer")
	var unrelated: RefCounted = Lease.new(directory.path_join("unrelated-candidate.json"))
	check(unrelated.held,"Unrelated candidate holds its profile lock")
	var notebook: RefCounted = Notebook.new()
	notebook.storage_path = fixture_path("independent-notebook")
	var notebook_raw: String = canonical({"version":2,"active":"scan_batch","states":{}})
	raw_write(notebook.storage_path,notebook_raw)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(notebook._writer_path()).get_base_dir())
	var notebook_lease: RefCounted = Lease.new(notebook._writer_path())
	check(notebook_lease.owns(notebook._writer_path()),"Notebook independently holds its dedicated writer lease")
	var isolated: RefCounted = store_for("independent-lock")
	check(isolated.write(snapshot).ok and unrelated.held and notebook_lease.owns(notebook._writer_path()),"Target write does not contend with or remove Notebook/candidate ownership")
	check(FileAccess.get_file_as_string(notebook.storage_path) == notebook_raw,"Target write preserves the independent Notebook transaction")
	notebook_lease.release()
	unrelated.release()
	var gate_store: RefCounted = store_for("recovery-gate")
	check(gate_store.write(snapshot).ok,"Recovery gate fixture starts committed")
	var gate: String = Lease.lock_path(gate_store._writer_path())+".recovering"
	DirAccess.make_dir_absolute(gate)
	check(not gate_store.write(proposed).ok and gate_store.last_error == "busy","Recovery gate prevents another target writer")
	DirAccess.remove_absolute(gate)
	check(gate_store.write(proposed).ok,"Same save retries when recovery gate is released")


func _writer_recovery() -> void:
	var snapshot: Dictionary = snapshot_for()
	var store: RefCounted = store_for("recover-owner")
	check(store.write(snapshot).ok,"Recovery fixture starts committed")
	var raw: String = FileAccess.get_file_as_string(store.storage_path)
	var lock: String = Lease.lock_path(store._writer_path())
	DirAccess.make_dir_absolute(lock)
	var owner_path: String = lock.path_join("owner.json")
	var owner: Dictionary = {"pid":2147483647,"token":"9".repeat(32),"context":"foreign-context"}
	raw_write(owner_path,canonical(owner))
	check(not store.recover_writer().ok and FileAccess.get_file_as_string(owner_path) == canonical(owner),"Unknown boot/process context remains protected")
	owner.context = Lease.local_context()
	owner.pid = OS.get_process_id()
	raw_write(owner_path,canonical(owner))
	check(not store.recover_writer().ok and FileAccess.get_file_as_string(owner_path) == canonical(owner),"Current live process cannot be recovered as stopped")
	owner.pid = 2147483647
	raw_write(owner_path,canonical(owner))
	var stopped: String = Lease.stopped_owner(store._writer_path())
	if stopped == owner.token:
		var result: Dictionary = store.recover_writer()
		check(result.ok and result.status == "ready" and result.snapshot == snapshot,"Explicit native-checked stopped-owner recovery retains committed target map")
		check(FileAccess.get_file_as_string(store.storage_path) == raw,"Recovery changes ownership only, never target bytes")
		check(FileAccess.get_file_as_string((lock+".abandoned-"+owner.token).path_join("owner.json")) == canonical(owner),"Recovery preserves the abandoned owner record")
		check(not DirAccess.dir_exists_absolute(lock),"Recovery releases temporary ownership before a separate write")
		var proposed: Dictionary = snapshot.duplicate(true)
		proposed.targets["scan_serial"] = code_for("scan_serial")
		check(store.write(proposed).ok and FileAccess.get_file_as_string(store.storage_path) != raw,"Separate retry commits genuinely changed target bytes after recovery")
		check(store_for("recover-owner").read().snapshot == proposed,"Fresh reader observes the actual post-recovery target addition")
	else:
		check(not store.recover_writer().ok and FileAccess.get_file_as_string(owner_path) == canonical(owner),"Unavailable native owner check conservatively refuses recovery")
		print("SKIP: native stopped-owner recovery unavailable; conservative refusal verified")
		DirAccess.remove_absolute(owner_path)
		DirAccess.remove_absolute(lock)
	var changed: RefCounted = store_for("recover-changed")
	check(changed.write(snapshot).ok,"Changed recovery fixture starts committed")
	lock = Lease.lock_path(changed._writer_path())
	DirAccess.make_dir_absolute(lock)
	owner_path = lock.path_join("owner.json")
	raw_write(owner_path,canonical(owner))
	var external: Dictionary = snapshot_for("mixed_serial")
	raw_write(changed.storage_path,canonical(external))
	check(not changed.recover_writer().ok and changed.last_error == "changed","Owner recovery cannot bypass external target changes")
	check(FileAccess.get_file_as_string(owner_path) == canonical(owner) and FileAccess.get_file_as_string(changed.storage_path) == canonical(external),"Refused recovery preserves owner and changed target bytes")
	DirAccess.remove_absolute(owner_path)
	DirAccess.remove_absolute(lock)


func _interrupted_temporary() -> void:
	var snapshot: Dictionary = snapshot_for("mixed_batch")
	var path: String = fixture_path("orphan-temporary")
	var orphan: String = path+".tmp."+("a".repeat(32))
	raw_write(orphan,canonical(snapshot))
	var store: RefCounted = store_for("orphan-temporary")
	check(store.read().ok and store.read().snapshot.targets.is_empty(),"Orphan temp is never adopted as committed target state")
	check(FileAccess.get_file_as_string(orphan) == canonical(snapshot),"Reading never deletes or installs an interrupted temp")
	check(store.write(snapshot_for()).ok,"Later explicit write can commit a new target collection")
	check(FileAccess.get_file_as_string(orphan) == canonical(snapshot),"Later commits never reuse or remove someone else's temporary file")
	raw_write(path+".tmp."+("b".repeat(32)),"incomplete")
	check(store_for("orphan-temporary").read().snapshot == snapshot_for(),"Committed main remains authoritative beside interrupted files")
