extends SceneTree
const Session = preload("res://experiments/layout_strategy/session.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
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
	_goal_and_replay()
	_checkpoint()
	_baseline_observation()
	check(root.get_node("LayoutChapter").game_snapshot() == old_state,"Goals, checkpoint and replay preserve official state")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy session %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _goal_and_replay() -> void:
	var session = Session.new()
	check(session.goal() == Goals.default_goal(),"Fresh session has no extra player limits")
	var goal_copy: Dictionary = session.goal()
	goal_copy.first_limit = 0
	check(session.goal() == Goals.default_goal(),"Goal getter cannot mutate live rules")
	var cap: Dictionary = {"objective":"cycles","first_limit":350,"copy_limit":0}
	check(session.set_goal(cap) and session.has_work(),"Goal-only changes count as unsaved session work")
	cap.first_limit = 0
	check(session.goal().first_limit == 350,"Goal input is detached")
	check(not session.can_undo() and session.rows().is_empty(),"Goal editing does not edit a recipe or manufacture a run")
	check(not session.set_goal(session.goal()),"An unchanged goal is not a new edit")
	var malformed: Dictionary = session.goal()
	malformed["score"] = 0
	check(not session.set_goal(malformed) and session.goal().first_limit == 350,"Malformed goals preserve prior rules")
	var starter: Dictionary = session.draft()
	var first: Dictionary = session.run_current()
	check(session.set_baseline(first.entry.id),"Replay test keeps a measured baseline")
	var grouped: Dictionary = starter.duplicate(true)
	grouped.query_group = 2
	grouped.record_tile = 1
	session.edit(grouped)
	var later: Dictionary = grouped.duplicate(true)
	later.query_group = 3
	session.edit(later)
	session.undo()
	check(session.can_undo() and session.can_redo(),"Replay starts with both Undo and Redo available")
	var before: Array[Dictionary] = session.rows()
	var replayed: Dictionary = session.replay(starter)
	check(replayed.valid and replayed.entry.correct and session.selected_entry().id == replayed.entry.id,"Replay records/selects actual evidence")
	check(replayed.entry.trace_id == first.entry.trace_id and replayed.entry.metrics == first.entry.metrics,"Recipe replay reproduces exact real evidence")
	check(session.draft() == grouped and session.can_undo() and session.can_redo(),"Replay preserves current draft and both edit stacks")
	check(session.rows().size() == before.size()+1 and session.baseline_id() == first.entry.id,"Replay preserves baseline and appends one observation")
	check(session.redo() and session.draft() == later,"The original Redo still restores its exact pre-replay edit")
	check(session.undo() and session.draft() == grouped,"Undo still returns the original grouped draft")
	var count: int = session.rows().size()
	var selected: int = session.selected_entry().id
	var bad_plan: Dictionary = starter.duplicate(true)
	bad_plan["claimed_cycles"] = 0
	var invalid: Dictionary = session.replay(bad_plan)
	check(not invalid.valid and session.rows().size() == count and session.selected_entry().id == selected,"Invalid replay preserves selection and history")
	session.run_current()
	var snapshot: Array[Dictionary] = session.rows()
	var ranked: Array[Dictionary] = session.ranked_rows()
	check(ranked[0].metrics.total_cycles == 1368 and ranked[0].rank == 1,"Session ranks actual current-condition runs under its goal")
	check(session.rows() == snapshot and session.draft() == grouped,"Reading rankings does not mutate observation order or draft")
	session.change_task("scan_serial")
	check(session.goal() == Goals.default_goal(),"Another workload has separate player limits")
	session.set_goal({"objective":"traffic","first_limit":600,"copy_limit":80})
	session.change_task("scan_batch")
	check(session.goal().first_limit == 350 and session.goal().copy_limit == 0,"Returning restores that workload's goal")

func _checkpoint() -> void:
	var session = Session.new()
	var dormant: Dictionary = Model.starter_plan()
	dormant.recipe = Recipe.field_major()
	dormant.copy_fields = [3,2]
	dormant.record_tile = 4
	var copied: Dictionary = Model.starter_plan()
	copied.copy_mode = "full"
	copied.copy_fields = [0]
	var drafts: Dictionary = {"scan_batch":dormant.duplicate(true),"scan_serial":copied.duplicate(true)}
	var goals: Dictionary = {
		"scan_batch":{"objective":"traffic","first_limit":0,"copy_limit":-1},
		"scan_serial":{"objective":"cycles","first_limit":557,"copy_limit":80},
	}
	var bad_goals: Dictionary = goals.duplicate(true)
	bad_goals.scan_serial.copy_limit = -2
	check(not session.restore_checkpoint("scan_serial",drafts,bad_goals),"A bad later checkpoint entry rejects the whole proposal")
	check(session.task_id == "scan_batch" and session.draft() == Model.starter_plan() and session.goal() == Goals.default_goal(),"Rejected checkpoint makes no partial active/draft/goal change")
	var bad_drafts: Dictionary = drafts.duplicate(true)
	bad_drafts["unknown"] = Model.starter_plan()
	check(not session.restore_checkpoint("scan_batch",bad_drafts,goals),"Unknown workload draft is rejected")
	var extra_goal: Dictionary = goals.duplicate(true)
	extra_goal["unknown"] = Goals.default_goal()
	check(not session.restore_checkpoint("scan_batch",drafts,extra_goal),"Unknown workload goal is rejected")
	check(not session.restore_checkpoint("unknown",drafts,goals),"Unknown active workload is rejected")
	check(not session.restore_checkpoint("scan_batch",{"scan_batch":"bad"},{}),"Non-dictionary draft is rejected")
	check(not session.restore_checkpoint("scan_batch",{},{"scan_batch":"bad"}),"Non-dictionary goal is rejected")
	check(session.restore_checkpoint("scan_serial",drafts,goals),"Whole valid checkpoint restores before session work")
	check(session.task_id == "scan_serial" and session.draft() == copied and session.goal() == goals.scan_serial,"Checkpoint restores active workload and exact rules")
	check(session.rows().is_empty() and not session.can_undo() and not session.can_redo() and session.baseline_id() == -1,"Checkpoint never restores score/history/Undo authority")
	drafts.scan_serial.copy_fields.clear()
	goals.scan_serial.first_limit = 0
	check(session.draft() == copied and session.goal().first_limit == 557,"Restored checkpoint is detached from caller data")
	session.change_task("scan_batch")
	check(session.draft() == dormant and session.goal().first_limit == 0,"Dormant editable copy choices and zero Q1 survive checkpoint")
	check(not session.restore_checkpoint("mixed_batch",{},{}),"Checkpoint cannot overwrite existing restored work")
	var goal_only = Session.new()
	goal_only.set_goal({"objective":"traffic","first_limit":-1,"copy_limit":-1})
	check(not goal_only.restore_checkpoint("mixed_serial",{},{}),"Goal-only user work also blocks startup restore")
	var blank = Session.new()
	check(blank.restore_checkpoint("mixed_serial",{},{}),"Absent saved states use fresh defaults for a valid active workload")
	check(blank.task_id == "mixed_serial" and blank.draft() == Model.starter_plan() and blank.goal() == Goals.default_goal() and not blank.has_work(),"Empty checkpoint does not manufacture work")

func _baseline_observation() -> void:
	var session = Session.new()
	check(session.baseline_entry().is_empty(),"Missing reference has no invented evidence")
	var original: Dictionary = session.run_current().entry
	check(session.set_baseline(original.id),"Reference observation begins with an explicit measured baseline")
	var edited: Dictionary = session.draft()
	edited.record_tile = 1
	session.edit(edited)
	session.run_current()
	edited.query_group = 2
	session.edit(edited)
	session.undo()
	var before: Dictionary = session._states.duplicate(true)
	var reference: Dictionary = session.baseline_entry()
	check(reference == original and reference.id != session.selected_entry().id,
		"Reference getter returns the pinned full measurement while another run stays selected")
	reference.metrics.total_cycles = 0
	reference.events[0].details["forged"] = true
	reference.events.clear()
	reference.plan.copy_fields.clear()
	reference.outputs.clear()
	reference.source_map.clear()
	check(session.baseline_entry() == original and session._states == before,
		"Mutating nested reference evidence preserves every run, draft, Undo, Redo and goal")
	session.change_task("scan_serial")
	check(session.baseline_entry().is_empty(),"Another workload cannot inspect the previous reference")
	session.change_task("scan_batch")
	check(session.baseline_entry() == original and session._states.scan_batch == before.scan_batch,
		"Returning retains the exact reference and original edit history")
