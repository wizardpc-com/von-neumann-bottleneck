extends SceneTree
const Store = preload("res://experiments/layout_strategy/notebook_store.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")

class FaultStore:
	extends "res://experiments/layout_strategy/notebook_store.gd"
	var blocked_open: String = ""
	var blocked_replace: String = ""
	var external_text: String = ""
	var deny_read: bool = false
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
		return {"ok":false,"reason":"read"} if deny_read else super._read_disk(path)

var checks: int = 0
var failures: Array[String] = []
var directory: String = "user://layout-strategy-notebook-store-tests"


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


func state_for(id: String) -> Dictionary:
	var task: Dictionary = Model.scenario(id)
	return {
		"model":Model.MODEL_VERSION,"condition":Model.condition_id(task),"task":task,
		"draft":Model.starter_plan(),"goal":Goals.default_goal(),
		"kept":[{"name":"原始方案","plan":Model.starter_plan()}],
	}


func snapshot_for(id: String = "scan_batch") -> Dictionary:
	return {"version":2,"active":id,"states":{id:state_for(id)}}


func changed_state(key: String, value: Variant, id: String = "scan_batch") -> Dictionary:
	var snapshot: Dictionary = snapshot_for(id)
	snapshot.states[id][key] = value
	return snapshot


func changed_draft(key: String, value: Variant) -> Dictionary:
	var snapshot: Dictionary = snapshot_for()
	snapshot.states.scan_batch.draft[key] = value
	return snapshot


func changed_goal(key: String, value: Variant) -> Dictionary:
	var snapshot: Dictionary = snapshot_for()
	snapshot.states.scan_batch.goal[key] = value
	return snapshot


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for notebook persistence checks.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	for frame: int in 3: await process_frame
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	var old_layout: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	_round_trip()
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
	check(before == after and root.get_node("LayoutChapter").game_snapshot() == old_layout,"Notebook operations never award or change official player state")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy notebook store %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _round_trip() -> void:
	var empty: RefCounted = store_for("empty")
	var initial: Dictionary = empty.read()
	var blank: Dictionary = {"version":2,"active":"scan_batch","states":{}}
	check(initial.ok and initial.status == "ready" and initial.snapshot == blank,"Missing notebook returns a detached explicit empty snapshot")
	check(not FileAccess.file_exists(empty.storage_path),"Reading absence creates no score or notebook file")
	check(empty.write(blank).ok and not FileAccess.file_exists(empty.storage_path),"Unchanged empty save is idempotent")
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(empty._writer_path())),"No-op write releases its cooperative lease")
	var snapshot: Dictionary = {"version":2,"active":"mixed_serial","states":{}}
	for id: String in Model.SCENARIO_IDS:
		var state: Dictionary = state_for(id)
		state.draft.recipe = Recipe.field_major()
		state.draft.copy_fields = [3,2]
		state.goal = {"objective":"traffic","first_limit":600,"copy_limit":0}
		snapshot.states[id] = state
	var tiled: Dictionary = Model.starter_plan()
	tiled.query_group = 8
	tiled.record_tile = 1
	snapshot.states.scan_batch.kept.append({"name":"分组温度 / grouped","plan":tiled})
	var store: RefCounted = store_for("round-trip")
	var written: Dictionary = store.write(snapshot)
	check(written.ok and written.status == "ready" and written.snapshot == snapshot,"All six workloads and exact dormant choices persist")
	var raw: String = FileAccess.get_file_as_string(store.storage_path)
	check(raw == canonical(snapshot),"Persisted notebook has one deterministic canonical spelling")
	check(not raw.contains('"metrics":') and not raw.contains('"trace_id":') and not raw.contains('"events":'),"Notebook contains inputs, never cached metrics or Trace")
	written.snapshot.states.scan_batch.kept.clear()
	snapshot.states.scan_batch.draft.copy_fields.clear()
	check(store.read().snapshot.states.scan_batch.kept.size() == 2,"Returned committed snapshot cannot mutate the store")
	check(store.read().snapshot.states.scan_batch.draft.copy_fields == [3,2],"Input snapshot cannot mutate committed dormant choices")
	var detached: Dictionary = store.read()
	detached.snapshot.states.clear()
	check(store.read().snapshot.states.size() == 6,"Read returns a detached complete snapshot")
	var restarted: RefCounted = store_for("round-trip")
	var restored: Dictionary = restarted.read()
	check(restored.ok and canonical(restored.snapshot) == raw,"New store restores exact active workload, task, draft, goal and names")
	check(restarted.write(restored.snapshot).ok and FileAccess.get_file_as_string(store.storage_path) == raw,"Identical retry does not rewrite canonical bytes")
	var task: Dictionary = restored.snapshot.states.scan_batch.task
	var plan: Dictionary = restored.snapshot.states.scan_batch.kept[1].plan
	var first: Dictionary = Model.evaluate(Model.scenario("scan_batch"),tiled)
	var replayed: Dictionary = Model.evaluate(task,plan)
	check(first.valid and replayed.valid and first.run.passed and replayed.run.passed,"Restored inputs execute the actual model")
	check(first.run.canonical_signature() == replayed.run.canonical_signature(),"Reopened notebook reproduces full Trace and all metric identities")
	check(replayed.run.metrics.first_request_cycles == 531 and replayed.run.metrics.total_cycles == 552,"Reopened recipe has its measured response/total tradeoff")
	var other: RefCounted = store_for("separate-profile")
	check(other.read().snapshot == blank and not FileAccess.file_exists(other.storage_path),"Independent notebook paths never adopt another profile")


func _normalization_and_bounds() -> void:
	var snapshot: Dictionary = snapshot_for()
	var numeric: Dictionary = JSON.parse_string(canonical(snapshot))
	numeric.version = 2.0
	numeric.states.scan_batch.draft.record_tile = 17.0
	numeric.states.scan_batch.goal.first_limit = -1.0
	check(Store.normalize_snapshot(numeric) == snapshot,"Integral JSON numbers normalize without changing stored meaning")
	var normalized: Dictionary = Store.normalize_snapshot(snapshot)
	normalized.states.scan_batch.task.records[0][0] = 999
	check(Store.normalize_snapshot(snapshot) == snapshot,"Normalization cannot expose caller task references")
	var dormant: Dictionary = snapshot_for("scan_serial")
	dormant.states.scan_serial.draft.query_group = 8
	check(not Store.normalize_snapshot(dormant).is_empty(),"Structurally valid unfinished draft survives even when it cannot run under this condition")
	dormant.states.scan_serial.kept[0].plan.query_group = 8
	check(Store.normalize_snapshot(dormant).is_empty(),"Kept recipe cannot contain illegal serial grouping")
	var maximal: Dictionary = {"version":2,"active":"mixed_serial","states":{}}
	for id: String in Model.SCENARIO_IDS:
		var state: Dictionary = state_for(id)
		state.kept.clear()
		for index: int in Store.MAX_KEPT:
			state.kept.append({"name":String.chr(0x1f9ea).repeat(39)+str(index),"plan":Model.starter_plan()})
		maximal.states[id] = state
	check(Store.normalize_snapshot(maximal) == maximal and canonical(maximal).to_utf8_buffer().size() <= Store.MAX_BYTES,"All48 named plans with40-character Unicode names fit the explicit bounds")
	var max_store: RefCounted = store_for("maximal")
	check(max_store.write(maximal).ok and store_for("maximal").read().snapshot == maximal,"Maximum named collection survives canonical persistence")
	var over: Dictionary = maximal.duplicate(true)
	over.states.scan_batch.kept.append({"name":"Ninth","plan":Model.starter_plan()})
	check(Store.normalize_snapshot(over).is_empty(),"Ninth kept plan is refused without eviction")
	var previous: PackedByteArray = FileAccess.get_file_as_bytes(max_store.storage_path)
	check(not max_store.write(over).ok and FileAccess.get_file_as_bytes(max_store.storage_path) == previous,"Capacity failure preserves all earlier named recipes")
	check(max_store.read().snapshot == maximal and max_store.write(maximal).ok,"Failed capacity proposal preserves committed memory and allows exact valid retry")


func _protected_files() -> void:
	var base: Dictionary = snapshot_for()
	var fixtures: Array[Dictionary] = [
		{"name":"root-array","value":[]},
		{"name":"future-version","value":{"version":99,"active":"scan_batch","states":{}}},
		{"name":"boolean-version","value":{"version":true,"active":"scan_batch","states":{}}},
		{"name":"missing-version","value":{"active":"scan_batch","states":{}}},
		{"name":"unknown-root","value":{"version":2,"active":"scan_batch","states":{},"scores":[]}},
		{"name":"unknown-active","value":{"version":2,"active":"other","states":{}}},
		{"name":"states-array","value":{"version":2,"active":"scan_batch","states":[]}},
		{"name":"unknown-state","value":{"version":2,"active":"scan_batch","states":{"future":state_for("scan_batch")}}},
		{"name":"scalar-state","value":{"version":2,"active":"scan_batch","states":{"scan_batch":42}}},
		{"name":"unknown-state-field","value":changed_state("score",0)},
		{"name":"model-type","value":changed_state("model",true)},
		{"name":"model-control","value":changed_state("model","invalid\nmodel")},
		{"name":"model-too-long","value":changed_state("model","x".repeat(81))},
		{"name":"condition-type","value":changed_state("condition",0)},
		{"name":"condition-case","value":changed_state("condition","A".repeat(64))},
		{"name":"task-type","value":changed_state("task",[])},
		{"name":"draft-type","value":changed_state("draft",[])},
		{"name":"plan-unknown","value":changed_draft("claimed_cycles",0)},
		{"name":"plan-fields","value":changed_draft("copy_fields",[0,0])},
		{"name":"plan-boolean","value":changed_draft("query_group",true)},
		{"name":"goal-type","value":changed_state("goal",[])},
		{"name":"goal-unknown","value":changed_goal("score",0)},
		{"name":"goal-objective","value":changed_goal("objective","first")},
		{"name":"goal-negative","value":changed_goal("first_limit",-2)},
		{"name":"goal-fraction","value":changed_goal("first_limit",0.5)},
		{"name":"goal-boolean","value":changed_goal("copy_limit",false)},
		{"name":"goal-size","value":changed_goal("copy_limit",1000001)},
		{"name":"kept-type","value":changed_state("kept",{})},
		{"name":"kept-scalar","value":changed_state("kept",[42])},
		{"name":"kept-missing","value":changed_state("kept",[{"name":"Keep"}])},
		{"name":"kept-extra","value":changed_state("kept",[{"name":"Keep","plan":Model.starter_plan(),"metrics":{"total_cycles":0}}])},
		{"name":"kept-plan-type","value":changed_state("kept",[{"name":"Keep","plan":[]}])},
		{"name":"kept-duplicate","value":changed_state("kept",[{"name":"Keep","plan":Model.starter_plan()},{"name":"Keep","plan":Model.starter_plan()}])},
	]
	for field: String in Store.STATE_KEYS:
		var missing: Dictionary = base.duplicate(true)
		missing.states.scan_batch.erase(field)
		fixtures.append({"name":"state-missing-"+field,"value":missing})
	for index: int in 8:
		var names: Array = ["","   ","x".repeat(41),"line\nbreak","tab\tname",String.chr(127),String.chr(133),42]
		fixtures.append({"name":"invalid-name-"+str(index),"value":changed_state("kept",[{"name":names[index],"plan":Model.starter_plan()}])})
	var nested: Dictionary = base.duplicate(true)
	nested.states.scan_batch.draft.recipe.groups[0]["score"] = 0
	fixtures.append({"name":"recipe-nested","value":nested})
	nested = base.duplicate(true)
	nested.states.scan_batch.task.queries[0]["future"] = 1
	fixtures.append({"name":"task-nested","value":nested})
	nested = base.duplicate(true)
	nested.states.scan_batch.task.id = "scan_serial"
	fixtures.append({"name":"outer-inner-task","value":nested})
	nested = base.duplicate(true)
	nested.states["mixed_batch"] = state_for("mixed_batch")
	nested.states.scan_batch.draft["claimed_cycles"] = 0
	fixtures.append({"name":"partial-valid-history","value":nested})
	var nine: Array = []
	for index: int in 9: nine.append({"name":str(index),"plan":Model.starter_plan()})
	fixtures.append({"name":"too-many-kept","value":changed_state("kept",nine)})
	for fixture: Dictionary in fixtures:
		check(Store.normalize_snapshot(fixture.value).is_empty(),fixture.name+": invalid snapshot cannot normalize")
		_assert_protected(fixture.name,canonical(fixture.value).to_utf8_buffer())
	var raw: String = canonical(base)
	_assert_protected("broken-json","{valuable unfinished".to_utf8_buffer())
	_assert_protected("oversized","x".repeat(Store.MAX_BYTES+1).to_utf8_buffer(),"size")
	_assert_protected("duplicate-root",raw.replace('"version":2','"version":2,"version":2').to_utf8_buffer())
	var model_text: String = '"model":"'+Model.MODEL_VERSION+'"'
	_assert_protected("duplicate-nested",raw.replace(model_text,model_text+","+model_text).to_utf8_buffer())
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
	for key: String in ["model","condition","task"]:
		var stale: Dictionary = base.duplicate(true)
		if key == "model": stale.states.scan_batch.model = "layout-schedule-experiment-older"
		elif key == "condition": stale.states.scan_batch.condition = "0".repeat(64)
		else: stale.states.scan_batch.task.records[0][0] += 1
		_assert_protected("stale-"+key,canonical(stale).to_utf8_buffer(),"stale")
	var directory_store: RefCounted = store_for("directory-path")
	DirAccess.make_dir_recursive_absolute(directory_store.storage_path)
	raw_write(directory_store.storage_path.path_join("keep.txt"),"original directory")
	check(not directory_store.read().ok and directory_store.storage_status == "read_only","Directory target is protected")
	check(not directory_store.write(base).ok and FileAccess.get_file_as_string(directory_store.storage_path.path_join("keep.txt")) == "original directory","Directory target cannot be replaced by a notebook")
	var denied := FaultStore.new()
	denied.storage_path = fixture_path("injected-read-failure")
	raw_write(denied.storage_path,raw)
	denied.deny_read = true
	check(not denied.read().ok and denied.last_error == "read" and denied.read().snapshot.is_empty(),"Injected read denial adopts no snapshot")
	denied.deny_read = false
	check(not denied.write(base).ok and FileAccess.get_file_as_string(denied.storage_path) == raw,"A previously unreadable notebook remains protected in the same store")


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
	check(not store.write(snapshot_for("mixed_serial")).ok and not store.recover_writer().ok,name+": writes and owner recovery cannot bypass invalid data")
	check(FileAccess.get_file_as_bytes(path) == bytes,name+": original bytes survive every rejected action")
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(store._writer_path()).get_base_dir()),name+": protected read creates no writer directory")


func _external_changes() -> void:
	var original: Dictionary = snapshot_for()
	var updated: Dictionary = snapshot_for("mixed_batch")
	var store: RefCounted = store_for("external-replaced")
	check(store.write(original).ok,"External-change fixture starts with committed input")
	raw_write(store.storage_path,canonical(updated))
	var result: Dictionary = store.write(original)
	check(not result.ok and result.status == "read_only" and result.reason == "changed","Even an identical save detects external replacement before no-op")
	check(result.snapshot == original and FileAccess.get_file_as_string(store.storage_path) == canonical(updated),"External bytes and previously committed memory remain separate")
	var appeared: RefCounted = store_for("external-appeared")
	var empty: Dictionary = appeared.read().snapshot
	raw_write(appeared.storage_path,canonical(updated))
	check(not appeared.write(empty).ok and appeared.last_error == "changed","Externally appeared file cannot be overwritten by an empty loaded state")
	var deleted: RefCounted = store_for("external-deleted")
	check(deleted.write(original).ok,"Deleted-file fixture starts committed")
	DirAccess.remove_absolute(deleted.storage_path)
	check(not deleted.write(updated).ok and not FileAccess.file_exists(deleted.storage_path),"Externally deleted notebook is not silently recreated")
	var redirected: RefCounted = store_for("redirected")
	redirected.read()
	redirected.storage_path = store.storage_path
	check(not redirected.write(updated).ok and redirected.last_error == "changed","Changing a loaded storage path cannot redirect a saved proposal")
	var during := FaultStore.new()
	during.storage_path = fixture_path("external-during-write")
	check(during.write(original).ok,"During-write fixture starts committed")
	during.external_text = canonical(updated)
	var proposed: Dictionary = original.duplicate(true)
	proposed.states.scan_batch.goal.first_limit = 600
	result = during.write(proposed)
	check(not result.ok and result.reason == "changed" and result.snapshot == original,"External update while temporary file is prepared prevents commit")
	check(FileAccess.get_file_as_string(during.storage_path) == canonical(updated),"Late conflict preserves the external replacement")


func _failed_writes() -> void:
	var original: Dictionary = snapshot_for()
	var proposed: Dictionary = original.duplicate(true)
	proposed.states.scan_batch.kept.append({"name":"New name","plan":Model.starter_plan()})
	var store := FaultStore.new()
	store.storage_path = fixture_path("failed-io")
	check(store.write(original).ok,"I/O fixture starts with a committed notebook")
	var raw: String = FileAccess.get_file_as_string(store.storage_path)
	var blocked: String = directory.path_join("blocked-io-directory")
	DirAccess.make_dir_recursive_absolute(blocked)
	raw_write(blocked.path_join("keep.txt"),"preserve directory")
	store.blocked_open = blocked
	var failed: Dictionary = store.write(proposed)
	check(not failed.ok and failed.status == "write_failed" and failed.reason == "write","Actual FileAccess open on a directory fails visibly")
	check(failed.snapshot == original and FileAccess.get_file_as_string(store.storage_path) == raw,"Failed temporary open keeps prior bytes and committed input")
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(store._writer_path())),"Failed open releases writer ownership")
	store.blocked_open = ""
	check(store.write(proposed).ok,"Identical request retries successfully after temporary-open failure")
	original = proposed.duplicate(true)
	raw = FileAccess.get_file_as_string(store.storage_path)
	proposed.states.scan_batch.kept.pop_back()
	store.blocked_replace = ProjectSettings.globalize_path(blocked)
	failed = store.write(proposed)
	check(not failed.ok and failed.reason == "replace" and failed.snapshot == original,"Actual rename failure preserves a pending removal and committed named entry")
	check(FileAccess.get_file_as_string(store.storage_path) == raw and FileAccess.get_file_as_string(blocked.path_join("keep.txt")) == "preserve directory","Failed replacement preserves both the old notebook and blocked destination")
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(store._writer_path())),"Failed rename releases writer ownership")
	store.blocked_replace = ""
	check(store.write(proposed).ok and store.read().snapshot == proposed,"Exact removal retries successfully after rename failure")
	var seen: Array[String] = []
	for path: String in store.temporary_paths:
		check(not seen.has(path) and path.begins_with(store.storage_path+".tmp."),"Every attempted commit gets its own temporary path")
		seen.append(path)


func _writer_contention() -> void:
	var snapshot: Dictionary = snapshot_for()
	var store: RefCounted = store_for("busy")
	check(store.write(snapshot).ok,"Busy fixture has a committed notebook")
	var raw: String = FileAccess.get_file_as_string(store.storage_path)
	var lease: RefCounted = Lease.new(store._writer_path())
	check(lease.owns(store._writer_path()),"Independent cooperative writer holds the notebook lease")
	var proposed: Dictionary = snapshot.duplicate(true)
	proposed.states.scan_batch.goal.first_limit = 600
	var result: Dictionary = store.write(proposed)
	check(not result.ok and result.reason == "busy" and result.snapshot == snapshot,"Active writer refuses another commit without adopting the proposal")
	check(not store.recover_writer().ok and lease.owns(store._writer_path()),"Explicit recovery never steals a live owner")
	check(FileAccess.get_file_as_string(store.storage_path) == raw,"Contention cannot change notebook bytes")
	lease.release()
	check(store.write(proposed).ok,"Same proposal can retry after ordinary owner release")
	var first: RefCounted = store_for("two-stale-readers")
	var second: RefCounted = store_for("two-stale-readers")
	first.read()
	second.read()
	check(first.write(snapshot).ok,"First of two readers commits normally")
	check(not second.write(proposed).ok and second.last_error == "changed","A later writer cannot silently overwrite its stale initial read")
	check(FileAccess.get_file_as_string(first.storage_path) == canonical(snapshot),"First writer's data survives the stale second writer")
	var unrelated: RefCounted = Lease.new(directory.path_join("unrelated-candidate.json"))
	check(unrelated.held,"Unrelated candidate owns its own profile lock")
	var isolated: RefCounted = store_for("independent-lock")
	check(isolated.write(snapshot).ok and unrelated.held,"Notebook lease does not reuse or remove an unrelated candidate lock")
	unrelated.release()
	var gate_store: RefCounted = store_for("recovery-gate")
	check(gate_store.write(snapshot).ok,"Recovery gate fixture starts committed")
	var gate: String = Lease.lock_path(gate_store._writer_path())+".recovering"
	DirAccess.make_dir_absolute(gate)
	check(not gate_store.write(proposed).ok and gate_store.last_error == "busy","Recovery-in-progress gate prevents another notebook writer")
	DirAccess.remove_absolute(gate)
	check(gate_store.write(proposed).ok,"Save retries after recovery gate is released")


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
	check(not store.recover_writer().ok and FileAccess.get_file_as_string(owner_path) == canonical(owner),"Local live process cannot be declared stopped")
	owner.pid = 2147483647
	raw_write(owner_path,canonical(owner))
	var stopped: String = Lease.stopped_owner(store._writer_path())
	if stopped == owner.token:
		var result: Dictionary = store.recover_writer()
		check(result.ok and result.status == "ready" and result.snapshot == snapshot,"Explicit native-checked stopped owner recovery retains committed input")
		check(FileAccess.get_file_as_string(store.storage_path) == raw,"Writer recovery does not save or change notebook content")
		check(FileAccess.get_file_as_string((lock+".abandoned-"+owner.token).path_join("owner.json")) == canonical(owner),"Stopped owner record is preserved by the shared lease")
		check(not DirAccess.dir_exists_absolute(lock),"Recovery releases its temporary ownership before the separate Save action")
		var proposed: Dictionary = snapshot.duplicate(true)
		proposed.states.scan_batch.goal.copy_limit = 0
		check(store.write(proposed).ok,"Separate Save succeeds after explicit stopped-owner recovery")
	else:
		check(not store.recover_writer().ok and FileAccess.get_file_as_string(owner_path) == canonical(owner),"Unsupported/unknown native owner check conservatively refuses recovery")
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
	check(not changed.recover_writer().ok and changed.last_error == "changed","Owner recovery cannot bypass an externally changed notebook")
	check(FileAccess.get_file_as_string(owner_path) == canonical(owner) and FileAccess.get_file_as_string(changed.storage_path) == canonical(external),"Refused recovery preserves both owner and externally updated notebook")
	DirAccess.remove_absolute(owner_path)
	DirAccess.remove_absolute(lock)


func _interrupted_temporary() -> void:
	var snapshot: Dictionary = snapshot_for("mixed_batch")
	var path: String = fixture_path("orphan-temporary")
	var orphan: String = path+".tmp."+("a".repeat(32))
	raw_write(orphan,canonical(snapshot))
	var store: RefCounted = store_for("orphan-temporary")
	check(store.read().ok and store.read().snapshot.states.is_empty(),"An orphan temporary file is never adopted as committed workspace")
	check(FileAccess.get_file_as_string(orphan) == canonical(snapshot),"Reading does not delete or silently install an interrupted temporary file")
	check(store.write(snapshot_for()).ok,"A later explicit save can commit a new valid notebook")
	check(FileAccess.get_file_as_string(orphan) == canonical(snapshot),"Later commits do not reuse or delete another temporary file")
	raw_write(path+".tmp."+("b".repeat(32)),"incomplete")
	check(store_for("orphan-temporary").read().snapshot == snapshot_for(),"Valid committed main remains authoritative beside interrupted temporary files")
