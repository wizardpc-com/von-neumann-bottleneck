extends RefCounted
## Bounded in-memory experiments. No campaign, file, telemetry or UI authority.
const Model = preload("res://experiments/layout_strategy/model.gd")
const MAX_RUNS: int = 24
const MAX_EDITS: int = 64
var task_id: String = "scan_batch"
var _states: Dictionary = {}
var _next_id: int = 1

func _state() -> Dictionary:
	if not _states.has(task_id):
		_states[task_id] = {
			"draft":Model.starter_plan(), "undo":[], "redo":[],
			"runs":[], "selected":-1, "baseline":-1,
		}
	return _states[task_id]

func task() -> Dictionary:
	return Model.scenario(task_id)

func draft() -> Dictionary:
	return _state().draft.duplicate(true)

func change_task(id: String) -> bool:
	if id not in Model.SCENARIO_IDS: return false
	task_id = id
	_state()
	return true

func edit(plan: Dictionary) -> bool:
	var normalized: Dictionary = Model.normalize_plan(plan)
	var state: Dictionary = _state()
	if normalized.is_empty() or normalized == state.draft: return false
	state.undo.append(state.draft.duplicate(true))
	if state.undo.size() > MAX_EDITS: state.undo.pop_front()
	state.redo.clear()
	state.draft = normalized.duplicate(true)
	return true

func can_undo() -> bool:
	return not _state().undo.is_empty()

func can_redo() -> bool:
	return not _state().redo.is_empty()

func undo() -> bool:
	var state: Dictionary = _state()
	if state.undo.is_empty(): return false
	state.redo.append(state.draft.duplicate(true))
	state.draft = state.undo.pop_back()
	return true

func redo() -> bool:
	var state: Dictionary = _state()
	if state.redo.is_empty(): return false
	state.undo.append(state.draft.duplicate(true))
	state.draft = state.redo.pop_back()
	return true

func run_current() -> Dictionary:
	var state: Dictionary = _state()
	var plan: Dictionary = draft()
	var result: Dictionary = Model.evaluate(task(),plan)
	if not result.get("valid",false) or result.get("run") == null: return result
	var trace: LayoutRun = result.run
	var events: Array[Dictionary] = []
	for event: SimulationEvent in trace.events: events.append(event.to_dictionary())
	var entry: Dictionary = {
		"id":_next_id, "task_id":task_id, "plan":plan.duplicate(true),
		"condition_id":trace.case_signature, "trace_id":trace.canonical_signature().sha256_text(),
		"metrics":trace.metrics.duplicate(true), "correct":trace.passed,
		"events":events, "outputs":trace.output_values.duplicate(),
		"expected":trace.expected_values.duplicate(), "source_map":trace.source_map.duplicate(true),
		"scratch_maps":trace.scratch_maps.duplicate(true),
	}
	_next_id += 1
	state.runs.append(entry)
	state.selected = entry.id
	while state.runs.size() > MAX_RUNS:
		for index: int in state.runs.size():
			var old: Dictionary = state.runs[index]
			if old.id != state.baseline and old.id != state.selected:
				state.runs.remove_at(index)
				break
	result["entry"] = entry.duplicate(true)
	return result

func _entry(id: int) -> Dictionary:
	for entry: Dictionary in _state().runs:
		if int(entry.id) == id: return entry
	return {}

func rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _state().runs:
		var row: Dictionary = {}
		for key: String in ["id","task_id","plan","condition_id","trace_id","metrics","correct"]:
			row[key] = entry[key]
		result.append(row.duplicate(true))
	return result

func selected_entry() -> Dictionary:
	return _entry(int(_state().selected)).duplicate(true)

func select(id: int) -> bool:
	if _entry(id).is_empty(): return false
	_state().selected = id
	return true

func restore_selected() -> bool:
	var selected: Dictionary = _entry(int(_state().selected))
	return false if selected.is_empty() else edit(selected.plan)

func set_baseline(id: int) -> bool:
	var entry: Dictionary = _entry(id)
	if entry.is_empty() or not entry.correct or entry.condition_id != Model.condition_id(task()):
		return false
	_state().baseline = id
	return true

func baseline_id() -> int:
	return int(_state().baseline)

func comparison() -> Dictionary:
	var selected: Dictionary = _entry(int(_state().selected))
	var baseline: Dictionary = _entry(baseline_id())
	if selected.is_empty() or baseline.is_empty() or not selected.correct or not baseline.correct:
		return {}
	if selected.condition_id != baseline.condition_id or selected.condition_id != Model.condition_id(task()):
		return {}
	var result: Dictionary = {}
	var less: bool = false
	var more: bool = false
	for key: String in ["first","cycles","traffic","peak"]:
		var difference: int = _metric(selected.metrics,key)-_metric(baseline.metrics,key)
		result[key] = difference
		less = less or difference < 0
		more = more or difference > 0
	result["kind"] = "tradeoff" if less and more else "better" if less else "worse" if more else "tied"
	return result

static func _metric(metrics: Dictionary, key: String) -> int:
	match key:
		"first": return int(metrics.first_request_cycles)
		"cycles": return int(metrics.total_cycles)
		"traffic": return int(metrics.ram_read_bytes)+int(metrics.ram_write_bytes)
		"peak": return int(metrics.peak_extra_bytes)
	return 0

func is_stale() -> bool:
	var selected: Dictionary = _entry(int(_state().selected))
	return selected.is_empty() or Model.plan_id(selected.plan) != Model.plan_id(draft())

func has_work() -> bool:
	for state: Dictionary in _states.values():
		if not state.runs.is_empty() or not state.undo.is_empty() or not state.redo.is_empty() or state.draft != Model.starter_plan():
			return true
	return false
