extends RefCounted
## Explicitly saved experimental inputs; measurements are always reconstructed.
const Session = preload("res://experiments/layout_strategy/session.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Store = preload("res://experiments/layout_strategy/notebook_store.gd")
const MAX_KEPT: int = 8
var session = Session.new()
var store = Store.new()
var storage_status: String = "ready"
var storage_reason: String = ""
var origin: String = "empty"
var copy_pending: bool = false
var _kept: Dictionary = {}
var _cache: Dictionary = {}
var _committed: Dictionary = {}
var _initialized: bool = false
var _has_saved: bool = false

func setup(path: String = "", legacy_path: String = "") -> Dictionary:
	if _initialized:
		return {"ok":false,"status":storage_status,"reason":"initialized"}
	_initialized = true
	if not path.is_empty(): store.storage_path = path
	if not legacy_path.is_empty(): store.legacy_path = legacy_path
	var loaded: Dictionary = store.read()
	_observe(loaded)
	if loaded.ok:
		var saved: Dictionary = loaded.snapshot
		var drafts: Dictionary = {}
		var goals: Dictionary = {}
		for id: String in saved.states:
			var state: Dictionary = saved.states[id]
			drafts[id] = state.draft.duplicate(true)
			goals[id] = state.goal.duplicate(true)
		if session.restore_checkpoint(str(saved.active),drafts,goals):
			for id: String in saved.states:
				_kept[id] = saved.states[id].kept.duplicate(true)
			_has_saved = origin == "current" and FileAccess.file_exists(store.storage_path)
		else:
			storage_status = "read_only"
			storage_reason = "format"
	# A pristine unsaved notebook has no work to lose. This is a comparison
	# baseline, not a claim that a file has already been written.
	_committed = snapshot()
	return {"ok":loaded.ok and storage_status == "ready",
		"status":storage_status,"reason":storage_reason,
		"origin":origin,"copy_pending":copy_pending}

func snapshot() -> Dictionary:
	var active: String = session.task_id
	var states: Dictionary = {}
	for id: String in Model.SCENARIO_IDS:
		session.change_task(id)
		var task: Dictionary = session.task()
		states[id] = {
			"model":Model.MODEL_VERSION,"condition":Model.condition_id(task),
			"task":task,"draft":session.draft(),"goal":session.goal(),
			"kept":_kept.get(id,[]).duplicate(true),
		}
	session.change_task(active)
	return {"version":2,"active":active,"states":states}

func is_dirty() -> bool:
	return copy_pending or snapshot() != _committed

func has_saved_workspace() -> bool:
	return _has_saved and storage_status != "read_only"

func save() -> bool:
	if not _initialized: setup()
	if storage_status == "read_only": return false
	var proposed: Dictionary = snapshot()
	var result: Dictionary = store.write(proposed)
	_observe(result)
	if not result.ok: return false
	_committed = proposed.duplicate(true)
	_has_saved = origin == "current" and FileAccess.file_exists(store.storage_path)
	return true

func _valid_name(value: String) -> bool:
	if value.strip_edges().is_empty() or value.length() > 40: return false
	for index: int in value.length():
		var character: int = value.unicode_at(index)
		if character < 32 or character >= 127 and character <= 159: return false
	return true

func _failed(reason: String) -> bool:
	storage_reason = reason
	return false

func keep_selected(name: String) -> bool:
	if not _valid_name(name): return _failed("name")
	var selected: Dictionary = session.selected_entry()
	if selected.is_empty(): return _failed("no_selection")
	if not selected.correct or selected.condition_id != Model.condition_id(session.task()):
		return _failed("incomplete")
	var entries: Array = _kept.get(session.task_id,[]).duplicate(true)
	for entry: Dictionary in entries:
		if entry.name == name: return _failed("duplicate")
	if entries.size() >= MAX_KEPT: return _failed("full")
	# Keep immutable selected evidence even if the draft has since changed.
	# Re-execute the recipe before it enters persistent input state.
	var measured: Dictionary = Model.evaluate(session.task(),selected.plan)
	if not measured.valid or measured.run == null or not measured.run.passed:
		return _failed("incomplete")
	entries.append({"name":name,"plan":selected.plan.duplicate(true)})
	_kept[session.task_id] = entries
	_cache.erase(session.task_id)
	return save()

func remove_kept(name: String) -> bool:
	var entries: Array = _kept.get(session.task_id,[]).duplicate(true)
	for index: int in entries.size():
		if entries[index].name == name:
			entries.remove_at(index)
			_kept[session.task_id] = entries
			_cache.erase(session.task_id)
			return save()
	return _failed("missing")

func kept_rows() -> Array[Dictionary]:
	var id: String = session.task_id
	var task: Dictionary = session.task()
	var condition: String = Model.condition_id(task)
	var kept: Array = _kept.get(id,[])
	var signature: String = JSON.stringify(kept,"",true).sha256_text()
	if not _cache.has(id) or _cache[id].signature != signature or _cache[id].condition != condition:
		var measured_rows: Array[Dictionary] = []
		for entry: Dictionary in kept:
			var result: Dictionary = Model.evaluate(task,entry.plan)
			if not result.valid or result.run == null: continue
			var run: LayoutRun = result.run
			measured_rows.append({
				"id":String(entry.name),"name":String(entry.name),"task_id":id,
				"plan":entry.plan.duplicate(true),"condition_id":run.case_signature,
				"trace_id":run.canonical_signature().sha256_text(),
				"metrics":run.metrics.duplicate(true),"correct":run.passed,
			})
		_cache[id] = {"signature":signature,"condition":condition,"rows":measured_rows}
	var rows: Array[Dictionary] = []
	for row: Dictionary in _cache[id].rows: rows.append(row.duplicate(true))
	return Goals.rank(rows,condition,session.goal())

func inspect_kept(name: String) -> bool:
	for entry: Dictionary in _kept.get(session.task_id,[]):
		if entry.name == name:
			var result: Dictionary = session.replay(entry.plan)
			if not result.get("valid",false) or not result.has("entry"):
				return _failed("incomplete")
			storage_reason = "" if storage_status == "ready" else storage_reason
			return true
	return _failed("missing")

func recover_writer() -> bool:
	var result: Dictionary = store.recover_writer()
	_observe(result)
	return bool(result.ok)

func _observe(result: Dictionary) -> void:
	storage_status = str(result.status)
	storage_reason = str(result.reason)
	origin = str(result.get("origin","empty"))
	copy_pending = bool(result.get("copy_pending",false))
