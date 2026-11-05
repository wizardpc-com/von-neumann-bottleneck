extends SceneTree
const Session = preload("res://experiments/layout_strategy/session.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for scheduling checks.")
		quit(1)
		return
	for frame: int in 3: await process_frame
	var old_state: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	var session = Session.new()
	check(not session.has_work() and session.rows().is_empty(),"Fresh session has no invented results")
	var starter: Dictionary = session.draft()
	var detached: Dictionary = session.draft()
	detached.record_tile = 2
	check(session.draft() == starter,"Draft getter cannot mutate the live recipe")
	var first: Dictionary = session.run_current()
	check(first.valid and first.entry.correct,"Starter executes the actual model")
	check(first.entry.metrics.first_request_cycles == 307 and first.entry.metrics.total_cycles == 2456,"Known source-only baseline has real response and work")
	check(session.set_baseline(first.entry.id),"Explicit baseline selection")
	var grouped: Dictionary = starter.duplicate(true)
	grouped.query_group = 8
	grouped.record_tile = 1
	check(session.edit(grouped) and session.is_stale(),"Editing invalidates current-measurement label")
	var faster: Dictionary = session.run_current()
	check(faster.entry.correct and faster.entry.metrics.first_request_cycles == 531 and faster.entry.metrics.total_cycles == 552,"Grouped run measures response/total tradeoff")
	var difference: Dictionary = session.comparison()
	check(difference.kind == "tradeoff" and difference.first == 224 and difference.cycles == -1904,"Comparison preserves competing axes without a weighted score")
	check(not session.is_stale(),"Measured draft is current")
	check(session.select(first.entry.id) and session.is_stale(),"Selecting old evidence does not replace draft")
	check(session.draft() == grouped,"Inspection preserves live plan")
	check(session.restore_selected() and session.draft() == starter,"Restore copies the selected plan")
	check(session.undo() and session.draft() == grouped,"One Undo returns exact pre-restore plan")
	check(session.redo() and session.draft() == starter,"Redo reapplies restore")
	check(session.undo(),"Return to grouped plan before workload switch")
	check(session.change_task("scan_serial") and session.rows().is_empty(),"Workloads isolate comparison histories")
	check(session.baseline_id() == -1 and session.draft() == starter,"Workload starts with its own draft and baseline")
	var serial: Dictionary = session.run_current()
	check(serial.entry.condition_id != first.entry.condition_id,"Different admission contracts cannot share an identity")
	check(not session.select(first.entry.id) and not session.set_baseline(first.entry.id),"Cannot inspect or compare a different workload entry")
	check(session.change_task("scan_batch") and session.draft() == grouped,"Returning restores edited plan")
	check(session.can_redo() and session.baseline_id() == first.entry.id,"Returning preserves Undo/Redo and reference")
	check(not session.change_task("not-a-task") and session.task_id == "scan_batch","Unknown workload cannot discard work")
	var view: Dictionary = session.selected_entry()
	view.metrics.total_cycles = 0
	view.events.clear()
	view.plan.copy_fields.clear()
	var row_view: Array[Dictionary] = session.rows()
	row_view[0].metrics.total_cycles = 1
	check(session.selected_entry().metrics.total_cycles == 2456 and not session.selected_entry().events.is_empty(),"Returned snapshots cannot corrupt historical metrics/events")
	check(session.rows()[0].metrics.total_cycles == 2456,"Returned rows are detached")
	var history_size: int = session.rows().size()
	var malformed: Dictionary = grouped.duplicate(true)
	malformed["claimed_score"] = 1
	check(not session.edit(malformed) and session.rows().size() == history_size,"Malformed edit is rejected without losing history")
	session.change_task("scan_serial")
	session.edit(grouped)
	var unavailable: Dictionary = session.run_current()
	check(not unavailable.valid and session.rows().size() == 1,"Illegal serial grouping produces no invented zero-cycle result")
	session.undo()
	var oversized: Dictionary = starter.duplicate(true)
	oversized.copy_mode = "full"
	oversized.copy_fields = [0,1,2,3]
	session.edit(oversized)
	var failed: Dictionary = session.run_current()
	check(failed.valid and not failed.entry.correct and failed.entry.metrics.error == "space_limit","Real allocation failure remains inspectable")
	check(not session.set_baseline(failed.entry.id) and session.comparison().is_empty(),"Incomplete work cannot win comparisons")
	check(failed.entry.metrics.first_request_cycles == -1,"Unfinished first response is not represented as zero")
	session.change_task("scan_batch")
	for index: int in 30:
		session.run_current()
	check(session.rows().size() == Session.MAX_RUNS,"History remains bounded")
	check(session.select(first.entry.id) and session.baseline_id() == first.entry.id,"Pinned reference survives later runs")
	for index: int in 75:
		var edit: Dictionary = session.draft()
		edit.record_tile = 1 if index%2 == 0 else 2
		session.edit(edit)
	var undo_count: int = 0
	while session.undo(): undo_count += 1
	check(undo_count == Session.MAX_EDITS,"Edit history remains bounded")
	var redo_count: int = 0
	while session.redo(): redo_count += 1
	check(redo_count == Session.MAX_EDITS,"Bounded Undo retains symmetric Redo")
	check(root.get_node("LayoutChapter").game_snapshot() == old_state,"Experimental actions never change official layout progress/drafts")
	check(session.has_work(),"Existing session work is detectable before exit")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy session %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
