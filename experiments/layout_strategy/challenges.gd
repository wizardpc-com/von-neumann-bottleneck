extends RefCounted
## Proposed targets are independent from Notebook inputs and campaign results.
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Store = preload("res://experiments/layout_strategy/challenge_store.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
var store = Store.new()
var storage_status: String = "ready"
var storage_reason: String = ""
var _initialized: bool = false
var _has_saved: bool = false
var _targets: Dictionary = {}
var _committed: Dictionary = {}
var _cache: Dictionary = {}


func setup(path: String = "") -> Dictionary:
	if _initialized: return _result(false,"initialized")
	_initialized = true
	if not path.is_empty(): store.storage_path = path
	var loaded: Dictionary = store.read()
	_observe(loaded)
	if loaded.ok:
		_targets = loaded.snapshot.targets.duplicate(true)
		_committed = _targets.duplicate(true)
		_has_saved = FileAccess.file_exists(store.storage_path)
	return _result(bool(loaded.ok))


func target(task_id: String) -> Dictionary:
	if not _initialized: setup()
	if task_id not in Model.SCENARIO_IDS:
		return {"code":"","active":false,"inspection":{},"saved":false,"pending":false}
	var code: String = str(_targets.get(task_id,""))
	var pending: bool = code != str(_committed.get(task_id,""))
	if code.is_empty():
		return {"code":"","active":false,"inspection":{},"saved":false,"pending":pending}
	var condition: String = Model.condition_id(Model.scenario(task_id))
	var key: String = code+"\n"+condition
	if not _cache.has(task_id) or _cache[task_id].key != key:
		_cache[task_id] = {"key":key,"inspection":Code.inspect(code)}
	var inspection: Dictionary = _cache[task_id].inspection.duplicate(true)
	return {
		"code":code,"active":bool(inspection.ok),"inspection":inspection,
		"saved":_has_saved and storage_status != "read_only" and not pending,"pending":pending,
	}


func preview(code: String, task_id: String) -> Dictionary:
	if task_id not in Model.SCENARIO_IDS: return {"ok":false,"reason":"task"}
	var decoded: Dictionary = Code.decode(code)
	if not decoded.ok: return decoded
	if decoded.envelope.task != task_id: return {"ok":false,"reason":"task"}
	return Code.inspect(code)


func accept(code: String, task_id: String) -> Dictionary:
	if not _initialized: setup()
	# Recheck the actual current input and workload, never a stale preview.
	var inspected: Dictionary = preview(code,task_id)
	if not inspected.ok: return _result(false,str(inspected.reason))
	_targets[task_id] = String(inspected.code)
	_cache.erase(task_id)
	var result: Dictionary = retry()
	result["accepted"] = true
	return result


func clear(task_id: String) -> Dictionary:
	if not _initialized: setup()
	if task_id not in Model.SCENARIO_IDS: return _result(false,"task")
	_targets.erase(task_id)
	_cache.erase(task_id)
	var result: Dictionary = retry()
	result["accepted"] = true
	return result


func retry() -> Dictionary:
	if not _initialized: setup()
	# Save the exact proposed map, including failed replacements/removals.
	# Notebook goals, filters, selected runs and drafts are not inputs here.
	var written: Dictionary = store.write({"version":1,"targets":_targets.duplicate(true)})
	_observe(written)
	if written.ok:
		_committed = _targets.duplicate(true)
		_has_saved = FileAccess.file_exists(store.storage_path)
	return _result(bool(written.ok))


func recover_writer() -> Dictionary:
	if not _initialized: setup()
	var recovered: Dictionary = store.recover_writer()
	_observe(recovered)
	return _result(bool(recovered.ok))


func is_dirty() -> bool:
	return _targets != _committed


func compare(task_id: String, attempt: Dictionary) -> Dictionary:
	var unavailable: Dictionary = {"status":"unavailable","exclusions":[]}
	if task_id not in Model.SCENARIO_IDS: return unavailable
	var retained: Dictionary = target(task_id)
	if not retained.active: return unavailable
	var task: Dictionary = Model.scenario(task_id)
	if not attempt.get("task_id") is String or attempt.task_id != task_id:
		return unavailable
	if not attempt.get("condition_id") is String or attempt.condition_id != Model.condition_id(task):
		return unavailable
	if not attempt.get("correct") is bool or not attempt.correct or not attempt.get("plan") is Dictionary:
		return unavailable
	if not attempt.get("trace_id") is String: return unavailable
	# The selected row identifies an actual run. Reconstruct its full result,
	# rather than using editable/cached metric numbers as challenge authority.
	var measured: Dictionary = Model.evaluate(task,attempt.plan)
	if not measured.get("valid",false) or measured.get("run") == null: return unavailable
	var run: LayoutRun = measured.run
	if not run.passed or run.canonical_signature().sha256_text() != attempt.trace_id:
		return unavailable
	var events: Array[Dictionary] = []
	for event: SimulationEvent in run.events: events.append(event.to_dictionary())
	var row: Dictionary = {
		"task_id":task_id,"plan":Model.normalize_plan(attempt.plan),
		"condition_id":run.case_signature,"trace_id":run.canonical_signature().sha256_text(),
		"correct":run.passed,"metrics":run.metrics.duplicate(true),
		"events":events,"outputs":run.output_values.duplicate(),
		"expected":run.expected_values.duplicate(),"source_map":run.source_map.duplicate(true),
		"scratch_maps":run.scratch_maps.duplicate(true),
	}
	return Code.compare(retained.inspection,row)


func _observe(result: Dictionary) -> void:
	storage_status = str(result.status)
	storage_reason = str(result.reason)


func _result(ok: bool, reason: String = "") -> Dictionary:
	return {
		"ok":ok,"reason":storage_reason if reason.is_empty() else reason,
		"status":storage_status,"accepted":false,
	}
