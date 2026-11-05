extends SceneTree
const Notebook = preload("res://experiments/layout_strategy/notebook_store.gd")
const Targets = preload("res://experiments/layout_strategy/challenge_store.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const KINDS: Array[String] = ["notebook","targets"]
const FROZEN_PATH: String = "res://tests/fixtures/layout_strategy/legacy-scheduling-v1.json"
const FROZEN_BASE: String = "e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8"

class FaultNotebook:
	extends "res://experiments/layout_strategy/notebook_store.gd"
	var blocked_open: String = ""
	var blocked_replace: String = ""
	var denied_path: String = ""
	var deny_readback: bool = false
	var mutate_path: String = ""
	var mutate_text: String = ""
	func _temporary_path() -> String:
		var path: String = super._temporary_path()
		if not mutate_path.is_empty():
			var file := FileAccess.open(mutate_path,FileAccess.WRITE)
			file.store_string(mutate_text)
			file.flush()
			file.close()
			mutate_path = ""
		return path if blocked_open.is_empty() else blocked_open
	func _replace_file(temporary: String, target: String) -> Error:
		return DirAccess.rename_absolute(temporary,target if blocked_replace.is_empty() else blocked_replace)
	func _read_disk(path: String = "") -> Dictionary:
		var actual: String = storage_path if path.is_empty() else path
		if actual == denied_path or deny_readback and actual.begins_with(storage_path+".tmp."):
			return {"ok":false,"reason":"read"}
		return super._read_disk(path)

class FaultTargets:
	extends "res://experiments/layout_strategy/challenge_store.gd"
	var blocked_open: String = ""
	var blocked_replace: String = ""
	var denied_path: String = ""
	var deny_readback: bool = false
	var mutate_path: String = ""
	var mutate_text: String = ""
	func _temporary_path() -> String:
		var path: String = super._temporary_path()
		if not mutate_path.is_empty():
			var file := FileAccess.open(mutate_path,FileAccess.WRITE)
			file.store_string(mutate_text)
			file.flush()
			file.close()
			mutate_path = ""
		return path if blocked_open.is_empty() else blocked_open
	func _replace_file(temporary: String, target: String) -> Error:
		return DirAccess.rename_absolute(temporary,target if blocked_replace.is_empty() else blocked_replace)
	func _read_disk(path: String = "") -> Dictionary:
		var actual: String = storage_path if path.is_empty() else path
		if actual == denied_path or deny_readback and actual.begins_with(storage_path+".tmp."):
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


func canonical(value: Variant) -> String:
	return JSON.stringify(value,"",true)


func same(a: Variant, b: Variant) -> bool:
	# JSON parsing represents integral values as floats. Compare input values
	# independently from the separate canonical-byte assertions below.
	return canonical(JSON.parse_string(canonical(a))) == canonical(JSON.parse_string(canonical(b)))


func raw_write(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.flush()
	file.close()


func bytes_at(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)


func fixture(kind: String, name: String, faults: bool = false) -> RefCounted:
	var folder: String = directory.path_join(kind+"-"+name)
	DirAccess.make_dir_recursive_absolute(folder)
	var store: RefCounted
	if kind == "notebook": store = FaultNotebook.new() if faults else Notebook.new()
	else: store = FaultTargets.new() if faults else Targets.new()
	store.storage_path = folder.path_join("current.json")
	store.legacy_path = folder.path_join("legacy.json")
	return store


func code_for(id: String, objective: String = "cycles") -> String:
	var key: String = id+"/"+objective
	if not _codes.has(key):
		var goal: Dictionary = Goals.default_goal()
		goal.objective = objective
		var result: Dictionary = Code.create(id,Model.starter_plan(),goal)
		check(result.ok,"Upgrade fixture uses an actual valid "+key+" code")
		_codes[key] = str(result.get("code",""))
	return _codes[key]


func state_for(id: String, maximal: bool = false) -> Dictionary:
	var task: Dictionary = Model.scenario(id)
	var draft: Dictionary = Model.starter_plan()
	draft.copy_fields = [3,1]
	draft.recipe = Recipe.field_major()
	draft.record_tile = 4
	# Preserve an intentionally unfinished old serial draft, never a kept score.
	if id == "scan_serial": draft.query_group = 8
	var kept: Array[Dictionary] = []
	for index: int in range(8 if maximal else 1):
		kept.append({
			"name":String.chr(0x1f9ea).repeat(39)+str(index) if maximal else "保留 / Keep",
			"plan":Model.starter_plan(),
		})
	return {
		"model":Model.MODEL_VERSION,"condition":Model.condition_id(task),"task":task,
		"draft":draft,"goal":{"objective":"traffic","first_limit":600,"copy_limit":0},"kept":kept,
	}


func blank(kind: String, version: int = 2) -> Dictionary:
	return {"version":version,"active":"scan_batch","states":{}} if kind == "notebook" else {"version":version,"targets":{}}


func legacy_snapshot(kind: String, maximal: bool = false) -> Dictionary:
	var result: Dictionary = blank(kind,1)
	if kind == "notebook":
		result.active = "mixed_serial"
		for id: String in Model.LEGACY_SCENARIO_IDS: result.states[id] = state_for(id,maximal)
	else:
		for id: String in Model.LEGACY_SCENARIO_IDS: result.targets[id] = code_for(id)
	return result


func lifted(value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	result.version = 2
	return result


func changed(kind: String, value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	if kind == "notebook": result.states.scan_batch.goal.first_limit = 601
	else: result.targets["scan_batch"] = code_for("scan_batch","traffic")
	return result


func normalize_legacy(kind: String, value: Variant) -> Dictionary:
	return Notebook.normalize_legacy_snapshot(value) if kind == "notebook" else Targets.normalize_legacy_snapshot(value)


func normalize_current(kind: String, value: Variant) -> Dictionary:
	return Notebook.normalize_snapshot(value) if kind == "notebook" else Targets.normalize_snapshot(value)


func source_writer(kind: String, store: RefCounted) -> String:
	return store.legacy_path+".writer/"+("notebook.json" if kind == "notebook" else "challenges.json")


func leases_released(kind: String, store: RefCounted) -> bool:
	return not DirAccess.dir_exists_absolute(Lease.lock_path(source_writer(kind,store))) and not DirAccess.dir_exists_absolute(Lease.lock_path(store._writer_path()))


func default_files() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [Notebook.LEGACY_PATH,Notebook.DEFAULT_PATH,Targets.LEGACY_PATH,Targets.DEFAULT_PATH,"user://layout_challenges_v1.json"]:
		result[path] = bytes_at(path) if FileAccess.file_exists(path) else null
	return result


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for store upgrade checks.")
		quit(1)
		return
	directory = "user://layout-strategy-upgrade-"+Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(directory)
	for frame: int in 3: await process_frame
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	var old_files: Dictionary = default_files()
	_path_contract()
	for kind: String in KINDS:
		_frozen_copy(kind)
		_copy_forward(kind)
		_precedence(kind)
		_protected_legacy(kind)
		_source_changes(kind)
		_failures(kind)
		_writers(kind)
		_ownership_changes(kind)
		_recovery(kind)
		_orphans(kind)
	_independent_files()
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	before.erase("saved_at_utc")
	after.erase("saved_at_utc")
	check(before == after and default_files() == old_files,"Upgrade fixtures preserve official progress and every default sidecar")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy store upgrade %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _path_contract() -> void:
	for kind: String in KINDS:
		var store: RefCounted = Notebook.new() if kind == "notebook" else Targets.new()
		var expected: String = Notebook.LEGACY_PATH if kind == "notebook" else Targets.LEGACY_PATH
		check(store._resolved_legacy_path() == expected,"Exact default resolves its matching legacy source: "+kind)
		store.storage_path = directory.path_join(kind+"-custom.json")
		check(store._resolved_legacy_path().is_empty(),"A custom current path disables implicit profile legacy lookup: "+kind)
		store.legacy_path = directory.path_join(kind+"-explicit.json")
		check(store._resolved_legacy_path() == store.legacy_path,"Only explicit custom legacy override is used: "+kind)
		var alias: RefCounted = fixture(kind,"alias")
		alias.legacy_path = alias.storage_path.get_base_dir().path_join("./current.json")
		var refused: Dictionary = alias.read()
		check(not refused.ok and refused.origin == "legacy" and refused.snapshot.is_empty(),"Source and missing destination cannot alias: "+kind)
		check(not alias.write(blank(kind)).ok and not FileAccess.file_exists(alias.storage_path),"Aliased paths cannot create a destructive copy: "+kind)


func _frozen_copy(kind: String) -> void:
	check(FileAccess.file_exists(FROZEN_PATH),"Actual old-runtime fixture is present: "+kind)
	if not FileAccess.file_exists(FROZEN_PATH): return
	var captured: Variant = JSON.parse_string(FileAccess.get_file_as_string(FROZEN_PATH))
	var key: String = "notebook_v1" if kind == "notebook" else "targets_v1"
	var valid_capture: bool = captured is Dictionary and captured.get("base_commit","") == FROZEN_BASE and captured.get(key) is String
	check(valid_capture,"Legacy payload was captured by the frozen pre-upgrade runtime: "+kind)
	if not valid_capture: return
	var original_text: String = captured[key]
	var parsed: Variant = JSON.parse_string(original_text)
	check(parsed is Dictionary,"Frozen old store produced a complete snapshot: "+kind)
	if not parsed is Dictionary: return
	var original: Dictionary = normalize_legacy(kind,parsed)
	check(not original.is_empty() and same(original,parsed) and canonical(original) == original_text,"Strict legacy validator accepts exact actual old-store bytes: "+kind)
	var store: RefCounted = fixture(kind,"frozen-old-runtime")
	raw_write(store.legacy_path,original_text)
	var loaded: Dictionary = store.read()
	var expected: Dictionary = lifted(original)
	check(loaded.ok and loaded.origin == "legacy" and loaded.copy_pending and same(loaded.snapshot,expected),"Actual old snapshot lifts only its root version: "+kind)
	check(not FileAccess.file_exists(store.storage_path) and leases_released(kind,store),"Reading actual old payload has no write or ownership side effect: "+kind)
	var written: Dictionary = store.write(expected)
	check(written.ok and written.origin == "current" and not written.copy_pending,"Actual unchanged old snapshot completes an explicit first copy: "+kind)
	check(FileAccess.get_file_as_string(store.storage_path) == canonical(expected),"Actual old snapshot creates exact version2 payload: "+kind)
	check(bytes_at(store.legacy_path) == original_text.to_utf8_buffer() and leases_released(kind,store),"Actual frozen v1 bytes survive copying unchanged: "+kind)
	var reopened: RefCounted = fixture(kind,"frozen-old-runtime")
	check(same(reopened.read().snapshot,expected) and reopened.origin == "current","A fresh reader uses the actual copied version2 payload: "+kind)


func _copy_forward(kind: String) -> void:
	var original: Dictionary = legacy_snapshot(kind,true)
	check(same(normalize_legacy(kind,original),original),"Strict frozen four-ID v1 remains readable: "+kind)
	check(normalize_current(kind,original).is_empty() and normalize_legacy(kind,lifted(original)).is_empty(),"Version1 and version2 validators remain distinct: "+kind)
	var store: RefCounted = fixture(kind,"copy")
	raw_write(store.legacy_path,canonical(original))
	var source_bytes: PackedByteArray = bytes_at(store.legacy_path)
	var loaded: Dictionary = store.read()
	check(loaded.ok and loaded.origin == "legacy" and loaded.copy_pending and loaded.snapshot.version == 2,"Valid legacy becomes an explicitly pending v2 proposal: "+kind)
	check(same(loaded.snapshot,lifted(original)),"Copy-forward changes only snapshot version and no saved inputs: "+kind)
	check(not FileAccess.file_exists(store.storage_path) and leases_released(kind,store),"Reading creates no current payload or writer lease: "+kind)
	check(not DirAccess.dir_exists_absolute(store.legacy_path+".writer") and not DirAccess.dir_exists_absolute(store.storage_path+".writer"),"Reading creates neither writer parent directory: "+kind)
	var detached: Dictionary = loaded.snapshot.duplicate(true)
	if kind == "notebook": loaded.snapshot.states.clear()
	else: loaded.snapshot.targets.clear()
	check(same(store.read().snapshot,detached),"Pending copy cannot be mutated through returned data: "+kind)
	var written: Dictionary = store.write(detached)
	check(written.ok and written.origin == "current" and not written.copy_pending,"Unchanged first copy completes only after a real commit: "+kind)
	check(FileAccess.file_exists(store.storage_path) and FileAccess.get_file_as_string(store.storage_path) == canonical(detached),"Unchanged first copy creates exact v2 bytes, never a no-op success: "+kind)
	check(bytes_at(store.legacy_path) == source_bytes and leases_released(kind,store),"Successful copy preserves every legacy byte and releases both leases: "+kind)
	var reopened: RefCounted = fixture(kind,"copy")
	check(same(reopened.read().snapshot,detached) and reopened.origin == "current" and not reopened.copy_pending,"Fresh reader selects committed v2: "+kind)
	raw_write(store.legacy_path,"later old-version history")
	var proposal: Dictionary = changed(kind,detached)
	check(store.write(proposal).ok and FileAccess.get_file_as_string(store.legacy_path) == "later old-version history","After commit, old history is independent and never merged or repaired: "+kind)
	var empty: RefCounted = fixture(kind,"empty-copy")
	raw_write(empty.legacy_path,canonical(blank(kind,1)))
	var empty_read: Dictionary = empty.read()
	check(empty_read.ok and empty_read.copy_pending,"An existing empty legacy file still needs explicit copy: "+kind)
	check(empty.write(empty_read.snapshot).ok and FileAccess.file_exists(empty.storage_path),"An unchanged empty legacy copy actually creates v2: "+kind)
	var fresh: RefCounted = fixture(kind,"both-missing")
	var fresh_read: Dictionary = fresh.read()
	check(fresh_read.ok and fresh_read.origin == "empty" and not fresh_read.copy_pending and same(fresh_read.snapshot,blank(kind)),"Both missing means fresh defaults without invented progress: "+kind)
	check(fresh.write(fresh_read.snapshot).ok and not FileAccess.file_exists(fresh.storage_path),"A pristine non-migration no-op still creates no payload: "+kind)
	check(fresh.write(detached).ok and not FileAccess.file_exists(fresh.legacy_path),"First new content writes only the current file: "+kind)
	var sparse: Dictionary = blank(kind,1)
	if kind == "notebook":
		sparse.active = "mixed_serial"
		sparse.states["scan_batch"] = state_for("scan_batch")
	else: sparse.targets["scan_batch"] = code_for("scan_batch")
	var sparse_store: RefCounted = fixture(kind,"sparse")
	raw_write(sparse_store.legacy_path,canonical(sparse))
	check(same(sparse_store.read().snapshot,lifted(sparse)),"Sparse legacy maps stay sparse; no new workload or target is invented: "+kind)
	if kind == "targets":
		var stale: Dictionary = legacy_snapshot(kind)
		var envelope: Dictionary = Code.decode(stale.targets.scan_batch).envelope
		envelope.model = "previous-supported-model"
		stale.targets["scan_batch"] = Code.PREFIX+canonical(envelope)
		var stale_store: RefCounted = fixture(kind,"supported-stale")
		raw_write(stale_store.legacy_path,canonical(stale))
		var seeded: Dictionary = stale_store.read()
		check(seeded.ok and seeded.copy_pending and seeded.snapshot.targets.scan_batch == stale.targets.scan_batch,"Structurally supported stale target remains byte-exact during copy")
		check(not Code.inspect(seeded.snapshot.targets.scan_batch).ok,"Copied stale code never becomes an active score")
		check(stale_store.write(seeded.snapshot).ok and fixture(kind,"supported-stale").read().snapshot.targets.scan_batch == stale.targets.scan_batch,"Supported stale target survives actual v2 persistence")


func _precedence(kind: String) -> void:
	var original: Dictionary = legacy_snapshot(kind)
	var current: Dictionary = lifted(changed(kind,original))
	var store: RefCounted = fixture(kind,"current-wins",true)
	raw_write(store.storage_path,canonical(current))
	raw_write(store.legacy_path,"broken legacy")
	store.denied_path = store.legacy_path
	var loaded: Dictionary = store.read()
	check(loaded.ok and loaded.origin == "current" and not loaded.copy_pending and same(loaded.snapshot,current),"Valid v2 ignores even an unreadable legacy source: "+kind)
	check(store.write(current).ok and FileAccess.get_file_as_string(store.legacy_path) == "broken legacy","Current no-op never touches ignored legacy bytes: "+kind)
	var empty: RefCounted = fixture(kind,"current-empty")
	raw_write(empty.storage_path,canonical(blank(kind)))
	raw_write(empty.legacy_path,canonical(original))
	check(same(empty.read().snapshot,blank(kind)) and empty.origin == "current","An explicit empty v2 never resurrects old entries: "+kind)
	for text: String in [canonical({"version":99}),"{partial current",canonical(original)]:
		var blocked: RefCounted = fixture(kind,"current-protected-"+str(checks))
		raw_write(blocked.storage_path,text)
		raw_write(blocked.legacy_path,canonical(original))
		var result: Dictionary = blocked.read()
		check(not result.ok and result.origin == "current" and not result.copy_pending and result.snapshot.is_empty(),"Protected existing current file has priority over valid legacy: "+kind)
		check(not blocked.write(current).ok and not blocked.recover_writer().ok,"No fallback/write/recovery bypasses protected current file: "+kind)
		check(FileAccess.get_file_as_string(blocked.storage_path) == text and FileAccess.get_file_as_string(blocked.legacy_path) == canonical(original),"Protected current and legacy bytes both survive: "+kind)
	var denied: RefCounted = fixture(kind,"current-unreadable",true)
	raw_write(denied.storage_path,canonical(current))
	raw_write(denied.legacy_path,canonical(original))
	denied.denied_path = denied.storage_path
	check(not denied.read().ok and denied.origin == "current" and denied.last_error == "read","Unreadable v2 never falls back to legacy: "+kind)
	var directory_store: RefCounted = fixture(kind,"current-directory")
	DirAccess.make_dir_recursive_absolute(directory_store.storage_path)
	raw_write(directory_store.legacy_path,canonical(original))
	check(not directory_store.read().ok and directory_store.origin == "current","Directory at v2 path is protected instead of migrated over: "+kind)


func _protected_legacy(kind: String) -> void:
	var original: Dictionary = legacy_snapshot(kind)
	var bad_nested: Dictionary = original.duplicate(true)
	var new_id: Dictionary = original.duplicate(true)
	if kind == "notebook":
		bad_nested.states.mixed_serial.kept[0]["score"] = 0
		new_id.states.erase("mixed_serial")
		new_id.states["scan_pair_serial"] = state_for("scan_pair_serial")
	else:
		bad_nested.targets["mixed_serial"] = "valuable unsupported code"
		new_id.targets.erase("mixed_serial")
		new_id.targets["scan_pair_serial"] = code_for("scan_pair_serial")
	var cases: Array[String] = [
		"{valuable unfinished",canonical(lifted(original)),canonical({"version":99}),
		canonical(bad_nested),canonical(new_id),
		canonical(original).replace('"version":1','"version":1,"version":1'),
		JSON.stringify(original,"  ",true),
	]
	if kind == "notebook":
		for field: String in ["model","condition","task"]:
			var stale: Dictionary = original.duplicate(true)
			if field == "model": stale.states.scan_batch.model = "older-model"
			elif field == "condition": stale.states.scan_batch.condition = "0".repeat(64)
			else: stale.states.scan_batch.task.records[0][0] += 1
			cases.append(canonical(stale))
	for text: String in cases:
		var store: RefCounted = fixture(kind,"legacy-protected-"+str(checks))
		raw_write(store.legacy_path,text)
		_assert_legacy_protected(kind,store,text.to_utf8_buffer())
	var invalid_utf8: RefCounted = fixture(kind,"legacy-utf8")
	var invalid_bytes: PackedByteArray = canonical(original).to_utf8_buffer()
	invalid_bytes.append(255)
	var file := FileAccess.open(invalid_utf8.legacy_path,FileAccess.WRITE)
	file.store_buffer(invalid_bytes)
	file.close()
	_assert_legacy_protected(kind,invalid_utf8,invalid_bytes)
	var oversized: RefCounted = fixture(kind,"legacy-size")
	var long_text: String = "x".repeat(Notebook.MAX_BYTES+1 if kind == "notebook" else Targets.MAX_BYTES+1)
	raw_write(oversized.legacy_path,long_text)
	_assert_legacy_protected(kind,oversized,long_text.to_utf8_buffer())
	var denied: RefCounted = fixture(kind,"legacy-unreadable",true)
	raw_write(denied.legacy_path,canonical(original))
	denied.denied_path = denied.legacy_path
	_assert_legacy_protected(kind,denied,canonical(original).to_utf8_buffer())
	var directory_store: RefCounted = fixture(kind,"legacy-directory")
	DirAccess.make_dir_recursive_absolute(directory_store.legacy_path)
	raw_write(directory_store.legacy_path.path_join("keep.txt"),"old directory")
	check(not directory_store.read().ok and directory_store.origin == "legacy" and not directory_store.copy_pending,"Legacy directory is protected without partial migration: "+kind)
	check(not directory_store.write(lifted(original)).ok and not FileAccess.file_exists(directory_store.storage_path),"Legacy directory cannot be skipped to start a silent new history: "+kind)
	check(FileAccess.get_file_as_string(directory_store.legacy_path.path_join("keep.txt")) == "old directory","Protected legacy directory remains intact: "+kind)


func _assert_legacy_protected(kind: String, store: RefCounted, expected: PackedByteArray) -> void:
	var result: Dictionary = store.read()
	check(not result.ok and result.status == "read_only" and result.origin == "legacy" and not result.copy_pending and result.snapshot.is_empty(),"Bad legacy source adopts no partial map: "+kind)
	check(not store.write(lifted(legacy_snapshot(kind))).ok and not store.recover_writer().ok,"Bad legacy source cannot be bypassed through save/recovery: "+kind)
	check(bytes_at(store.legacy_path) == expected and not FileAccess.file_exists(store.storage_path),"Protected legacy bytes survive without a new payload: "+kind)
	check(not DirAccess.dir_exists_absolute(store.legacy_path+".writer") and not DirAccess.dir_exists_absolute(store.storage_path+".writer"),"Protected legacy read/save creates no writer directories: "+kind)


func _source_changes(kind: String) -> void:
	var original: Dictionary = legacy_snapshot(kind)
	for action: String in ["replace","delete","appear","destination","redirect","unreadable"]:
		var store: RefCounted = fixture(kind,"changed-"+action,true)
		if action != "appear": raw_write(store.legacy_path,canonical(original))
		var loaded: Dictionary = store.read()
		var source_expected: String = canonical(original)
		if action == "replace":
			source_expected = canonical(changed(kind,original))
			raw_write(store.legacy_path,source_expected)
		elif action == "delete":
			check(DirAccess.remove_absolute(store.legacy_path) == OK,"Remove only owned legacy test payload: "+kind)
		elif action == "appear": raw_write(store.legacy_path,source_expected)
		elif action == "destination": raw_write(store.storage_path,canonical(lifted(original)))
		elif action == "redirect": store.legacy_path = store.legacy_path+".other"
		else: store.denied_path = store.legacy_path
		var result: Dictionary = store.write(loaded.snapshot)
		check(not result.ok and result.reason == "changed" and result.status == "read_only","First-copy/no-op detects "+action+" before adoption: "+kind)
		check(same(result.snapshot,loaded.snapshot),"Conflict retains exact originally loaded proposal: "+kind)
		check(not store.recover_writer().ok,"Ownership recovery cannot bypass "+action+" conflict: "+kind)
		if action == "delete": check(not FileAccess.file_exists(store.legacy_path),"Deleted legacy source is never recreated: "+kind)
		elif action != "redirect": check(FileAccess.get_file_as_string(store.legacy_path) == source_expected,"Externally current legacy bytes remain intact: "+kind+"/"+action)
		if action == "destination": check(FileAccess.get_file_as_string(store.storage_path) == canonical(lifted(original)),"Appeared destination is never overwritten: "+kind)
		else: check(not FileAccess.file_exists(store.storage_path),"Conflicting source creates no destination: "+kind+"/"+action)
	for destination: bool in [false,true]:
		var store: RefCounted = fixture(kind,"late-"+str(destination),true)
		raw_write(store.legacy_path,canonical(original))
		var proposal: Dictionary = store.read().snapshot
		var external: String = canonical(lifted(changed(kind,original)) if destination else changed(kind,original))
		var mutated: String = store.storage_path if destination else store.legacy_path
		store.mutate_path = mutated
		store.mutate_text = external
		var result: Dictionary = store.write(proposal)
		check(not result.ok and result.reason == "changed","Digest recheck catches change while a first-copy temporary is prepared: "+kind+"/"+str(destination))
		check(FileAccess.get_file_as_string(mutated) == external and leases_released(kind,store),"Late conflict preserves external bytes and releases both leases: "+kind)
		if not destination: check(not FileAccess.file_exists(store.storage_path),"Late source change prevents destination commit: "+kind)


func _failures(kind: String) -> void:
	var original: Dictionary = legacy_snapshot(kind)
	for failure: String in ["open","replace","readback","clear"]:
		var store: RefCounted = fixture(kind,"failure-"+failure,true)
		raw_write(store.legacy_path,canonical(original))
		var loaded: Dictionary = store.read()
		var proposal: Dictionary = blank(kind) if failure == "clear" else changed(kind,loaded.snapshot)
		var blocked: String = store.storage_path.get_base_dir().path_join("directory")
		DirAccess.make_dir_recursive_absolute(blocked)
		raw_write(blocked.path_join("keep.txt"),"retain blocked directory")
		if failure == "open": store.blocked_open = blocked
		elif failure in ["replace","clear"]: store.blocked_replace = blocked
		else: store.deny_readback = true
		var result: Dictionary = store.write(proposal)
		check(not result.ok and result.status == "write_failed" and result.origin == "legacy" and result.copy_pending,"Failed first copy stays explicitly pending: "+kind+"/"+failure)
		check(same(result.snapshot,loaded.snapshot) and FileAccess.get_file_as_string(store.legacy_path) == canonical(original),"Failed first copy preserves source and committed input: "+kind)
		check(not FileAccess.file_exists(store.storage_path) and leases_released(kind,store),"Failed first copy creates no destination and releases both leases: "+kind)
		store.blocked_open = ""
		store.blocked_replace = ""
		store.deny_readback = false
		check(store.write(proposal).ok and not store.copy_pending and store.origin == "current","Exact current proposal retries after first-copy I/O failure: "+kind+"/"+failure)
		check(FileAccess.get_file_as_string(store.storage_path) == canonical(proposal),"Retry commits exact changed/empty proposal instead of the original source: "+kind)
		check(FileAccess.get_file_as_string(store.legacy_path) == canonical(original) and FileAccess.get_file_as_string(blocked.path_join("keep.txt")) == "retain blocked directory","Successful retry still preserves source and unrelated blocked destination: "+kind)
		check(same(fixture(kind,"failure-"+failure).read().snapshot,proposal),"Reopen observes actual migrated proposal, including explicit empty clear: "+kind)


func _writers(kind: String) -> void:
	var original: Dictionary = legacy_snapshot(kind)
	for source: bool in [true,false]:
		var store: RefCounted = fixture(kind,"busy-"+str(source))
		raw_write(store.legacy_path,canonical(original))
		var proposed: Dictionary = store.read().snapshot
		var path: String = source_writer(kind,store) if source else store._writer_path()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
		var held: RefCounted = Lease.new(path)
		check(held.owns(path),"Live fixture owns exact source/destination writer: "+kind+"/"+str(source))
		var result: Dictionary = store.write(proposed)
		check(not result.ok and result.reason == "busy" and store._blocked_writer_path == path and result.copy_pending,"First copy records exactly the blocked bounded writer: "+kind)
		check(not store.recover_writer().ok and held.owns(path),"Explicit recovery refuses that live source/destination owner: "+kind)
		check(FileAccess.get_file_as_string(store.legacy_path) == canonical(original) and not FileAccess.file_exists(store.storage_path),"Contention preserves source and missing destination: "+kind)
		var other: String = store._writer_path() if source else source_writer(kind,store)
		check(not DirAccess.dir_exists_absolute(Lease.lock_path(other)),"Failed acquisition releases any earlier unblocked lease: "+kind)
		held.release()
		check(store.write(proposed).ok and leases_released(kind,store),"Exact pending copy retries after ordinary owner release: "+kind)


func _ownership_changes(kind: String) -> void:
	for source: bool in [true,false]:
		var store: RefCounted = fixture(kind,"lost-owner-"+str(source),true)
		var original: String = canonical(legacy_snapshot(kind))
		raw_write(store.legacy_path,original)
		var proposal: Dictionary = store.read().snapshot
		var path: String = source_writer(kind,store) if source else store._writer_path()
		var owner_path: String = Lease.lock_path(path).path_join("owner.json")
		var replacement: String = canonical({"pid":OS.get_process_id(),"token":"c".repeat(32),"context":"replacement-owner"})
		store.mutate_path = owner_path
		store.mutate_text = replacement
		var result: Dictionary = store.write(proposal)
		check(not result.ok and result.reason == "busy" and result.copy_pending and store._blocked_writer_path == path,"First copy rechecks the exact source/destination owner after preparing bytes: "+kind+"/"+str(source))
		check(not FileAccess.file_exists(store.storage_path) and FileAccess.get_file_as_string(store.legacy_path) == original,"Lost ownership never replaces either payload: "+kind)
		check(FileAccess.get_file_as_string(owner_path) == replacement,"Failed owner recheck preserves the replacement owner's record: "+kind)
		var other: String = store._writer_path() if source else source_writer(kind,store)
		check(not DirAccess.dir_exists_absolute(Lease.lock_path(other)),"Lost-owner failure releases the other still-owned lease: "+kind)


func _recovery(kind: String) -> void:
	for source: bool in [true,false]:
		var store: RefCounted = fixture(kind,"recover-"+str(source))
		var original: Dictionary = legacy_snapshot(kind)
		raw_write(store.legacy_path,canonical(original))
		var proposed: Dictionary = changed(kind,store.read().snapshot)
		var path: String = source_writer(kind,store) if source else store._writer_path()
		var lock: String = Lease.lock_path(path)
		DirAccess.make_dir_recursive_absolute(lock)
		var owner_path: String = lock.path_join("owner.json")
		var owner: Dictionary = {"pid":2147483647,"token":"8".repeat(32),"context":"foreign-context"}
		raw_write(owner_path,canonical(owner))
		check(not store.write(proposed).ok and store._blocked_writer_path == path,"Record exact blocked path before recovery: "+kind)
		check(not store.recover_writer().ok and FileAccess.get_file_as_string(owner_path) == canonical(owner),"Unknown source/destination owner is not reclaimed: "+kind)
		owner.context = Lease.local_context()
		raw_write(owner_path,canonical(owner))
		if Lease.stopped_owner(path) == owner.token:
			var recovered: Dictionary = store.recover_writer()
			check(recovered.ok and recovered.copy_pending and recovered.origin == "legacy","Stopped-owner recovery preserves pending-copy state: "+kind)
			check(not FileAccess.file_exists(store.storage_path) and FileAccess.get_file_as_string(store.legacy_path) == canonical(original),"Recovery changes ownership only, never either payload: "+kind)
			check(FileAccess.get_file_as_string((lock+".abandoned-"+owner.token).path_join("owner.json")) == canonical(owner),"Recovery archives the exact old bounded owner: "+kind)
			check(store.write(proposed).ok and FileAccess.get_file_as_string(store.storage_path) == canonical(proposed),"Separate retry performs a genuinely changed post-recovery copy: "+kind)
		else:
			check(not store.recover_writer().ok and FileAccess.get_file_as_string(owner_path) == canonical(owner),"Unsupported native owner checks conservatively refuse migration recovery: "+kind)
			print("SKIP: stopped-owner upgrade recovery unavailable; refusal verified for "+kind)
	var changed_store: RefCounted = fixture(kind,"recover-changed")
	var old: Dictionary = legacy_snapshot(kind)
	raw_write(changed_store.legacy_path,canonical(old))
	var copy: Dictionary = changed_store.read().snapshot
	var source_path: String = source_writer(kind,changed_store)
	var source_lock: String = Lease.lock_path(source_path)
	DirAccess.make_dir_recursive_absolute(source_lock)
	var record: Dictionary = {"pid":2147483647,"token":"7".repeat(32),"context":Lease.local_context()}
	raw_write(source_lock.path_join("owner.json"),canonical(record))
	check(not changed_store.write(copy).ok,"Changed-source recovery fixture actually records contention: "+kind)
	raw_write(changed_store.legacy_path,canonical(changed(kind,old)))
	check(not changed_store.recover_writer().ok and changed_store.last_error == "changed","Recovery cannot bypass a changed old-format source: "+kind)
	check(FileAccess.get_file_as_string(source_lock.path_join("owner.json")) == canonical(record) and not FileAccess.file_exists(changed_store.storage_path),"Refused source recovery preserves owner and missing destination: "+kind)


func _orphans(kind: String) -> void:
	var store: RefCounted = fixture(kind,"orphan")
	var old: String = canonical(legacy_snapshot(kind))
	var prior_temp: String = store.legacy_path+".tmp."+("a".repeat(32))
	var current_temp: String = store.storage_path+".tmp."+("b".repeat(32))
	raw_write(prior_temp,old)
	raw_write(current_temp,"unfinished current")
	var loaded: Dictionary = store.read()
	check(loaded.ok and loaded.origin == "empty" and not loaded.copy_pending and same(loaded.snapshot,blank(kind)),"Orphan legacy/current temporaries are never adopted: "+kind)
	check(store.write(lifted(legacy_snapshot(kind))).ok,"Explicit new commit can coexist with both orphan files: "+kind)
	check(FileAccess.get_file_as_string(prior_temp) == old and FileAccess.get_file_as_string(current_temp) == "unfinished current","Own writes never remove or reuse earlier interrupted files: "+kind)


func _independent_files() -> void:
	var book: RefCounted = fixture("notebook","independent")
	var board: RefCounted = fixture("targets","independent")
	raw_write(book.legacy_path,canonical(legacy_snapshot("notebook")))
	raw_write(board.legacy_path,canonical(legacy_snapshot("targets")))
	var book_copy: Dictionary = book.read().snapshot
	var board_copy: Dictionary = board.read().snapshot
	var path: String = source_writer("notebook",book)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var held: RefCounted = Lease.new(path)
	check(held.owns(path),"Independent-fixture holds real old Notebook writer")
	check(board.write(board_copy).ok and held.owns(path),"Target copy-forward is independent of a held old Notebook writer")
	check(not book.write(book_copy).ok and book.copy_pending,"Partial migration preserves unsaved Notebook while targets commit")
	check(fixture("targets","independent").read().origin == "current" and fixture("notebook","independent").read().origin == "legacy","Reopen chooses each sidecar independently during partial migration")
	held.release()
	check(book.write(book_copy).ok and leases_released("notebook",book),"Notebook can copy later without rewriting committed targets")
	check(FileAccess.get_file_as_string(board.storage_path) == canonical(board_copy),"Later Notebook save preserves the already committed target file")
