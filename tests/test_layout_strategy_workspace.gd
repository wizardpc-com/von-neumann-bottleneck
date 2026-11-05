extends SceneTree
const Workspace = preload("res://experiments/layout_strategy/workspace.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Store = preload("res://experiments/layout_strategy/notebook_store.gd")
var checks: int = 0
var failures: Array[String] = []

class FailOnceStore:
	extends "res://experiments/layout_strategy/notebook_store.gd"
	var fail_next: bool = false
	func write(value: Dictionary) -> Dictionary:
		if fail_next:
			fail_next = false
			return _failed("write")
		return super.write(value)

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func named(rows: Array[Dictionary], value: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.name == value: return row
	return {}

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for notebook checks.")
		quit(1)
		return
	for frame: int in 3: await process_frame
	var official: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	var path: String = "user://workspace/notebook.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var book = Workspace.new()
	book.store = FailOnceStore.new()
	check(book.setup(path).ok,"Missing notebook creates a temporary clean workspace")
	check(not book.is_dirty() and book.kept_rows().is_empty(),"Fresh workspace invents no kept plans or dirty work")
	check(not book.has_saved_workspace(),"Pristine defaults are not labelled as already saved")
	var session = book.session
	var first: Dictionary = session.run_current()
	var starter: Dictionary = session.draft()
	var grouped: Dictionary = starter.duplicate(true)
	grouped.query_group = 8
	grouped.record_tile = 1
	session.edit(grouped)
	check(book.is_dirty(),"Uncommitted draft is detectable")
	check(book.keep_selected("早答 · direct"),"Keeping selected measured plan commits workspace")
	check(not book.is_dirty(),"Successful commit clears dirty state")
	check(book.has_saved_workspace(),"Successful disk commit establishes the saved status")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(saved.states.scan_batch.draft.query_group == 8,"Keep also explicitly saves current workspace draft")
	check(saved.states.scan_batch.kept[0].plan.query_group == 1,"Kept recipe is selected evidence, not the different draft")
	check(not saved.states.scan_batch.kept[0].has("metrics"),"Persistent file contains inputs, not claimed scores")
	check(session.draft() == grouped and session.can_undo(),"Keeping selected evidence preserves draft and edit history")
	var second: Dictionary = session.run_current()
	check(book.keep_selected("少做总工作"),"Keep real competing grouped strategy")
	check(not book.keep_selected("少做总工作") and book.storage_reason == "duplicate","Same name is not silently overwritten")
	check(not book.keep_selected(" \t") and book.storage_reason == "name","Blank/control names rejected")
	check(session.set_goal({"objective":"cycles","first_limit":307,"copy_limit":0}),"Set genuine inclusive operating envelope")
	var rows: Array[Dictionary] = book.kept_rows()
	check(named(rows,"早答 · direct").eligible and named(rows,"早答 · direct").rank == 1,"Direct meets exact307-cycle and0B caps")
	check(not named(rows,"少做总工作").eligible,"Faster total work does not evade Q1 cap")
	session.set_goal({"objective":"cycles","first_limit":531,"copy_limit":0})
	rows = book.kept_rows()
	check(named(rows,"少做总工作").rank == 1 and named(rows,"少做总工作").metrics.total_cycles == 552,"Relaxing Q1 changes the best known feasible recipe")
	check(session.rows().size() == 2 and session.draft() == grouped,"Ranking/caps do not create a run or edit the draft")
	check(named(rows,"早答 · direct").trace_id == first.entry.trace_id and named(rows,"少做总工作").trace_id == second.entry.trace_id,"Kept recipes reproduce exact complete Trace identities")
	for index: int in 27: session.run_current()
	check(session.rows().size() == 24 and book.kept_rows().size() == 2,"Transient history eviction cannot discard named discoveries")
	var before_inspect: Dictionary = session.draft()
	var can_undo: bool = session.can_undo()
	check(book.inspect_kept("早答 · direct"),"Inspect actually replays a retained recipe")
	check(session.draft() == before_inspect and session.can_undo() == can_undo,"Inspection preserves draft and Undo")
	check(session.selected_entry().trace_id == first.entry.trace_id,"Inspection reconstructs the selected Trace")
	check(session.restore_selected() and session.draft() == starter,"Continue improving explicitly restores selected recipe")
	check(session.undo() and session.draft() == grouped,"One Undo restores exact pre-restore draft")
	# Dormant configuration is editor state, even though plan_id omits it.
	var dormant: Dictionary = grouped.duplicate(true)
	dormant.copy_fields = [3,1]
	session.edit(dormant)
	session.change_task("scan_serial")
	var serial: Dictionary = session.run_current()
	check(book.keep_selected("serial direct"),"Other conditions have independent named entries")
	check(book.kept_rows().size() == 1 and serial.entry.condition_id != first.entry.condition_id,"Different condition never joins the scan batch ranking")
	session.change_task("scan_batch")
	check(session.draft() == dormant and session.goal().first_limit == 531,"Returning preserves dormant choices and independent goals")
	check(book.save(),"Explicit workspace save stores active workload, drafts and goals")
	var committed: String = FileAccess.get_file_as_string(path)
	var reopened = Workspace.new()
	check(reopened.setup(path).ok,"New store/session reconstructs committed input state")
	check(reopened.session.task_id == "scan_batch" and reopened.session.draft() == dormant,"Active workload and exact draft reopen")
	check(reopened.session.goal().first_limit == 531 and not reopened.session.can_undo(),"Goal reopens; Undo intentionally starts fresh")
	check(reopened.session.rows().is_empty(),"Reopen invents no historical runs")
	check(named(reopened.kept_rows(),"少做总工作").trace_id == second.entry.trace_id,"Reopened recipe is freshly remeasured identically")
	check(FileAccess.get_file_as_string(path) == committed,"Opening/ranking does not rewrite storage")
	check(book.inspect_kept("早答 · direct"),"Select real evidence before a failed keep")
	book.store.fail_next = true
	check(not book.keep_selected("pending retry"),"Injected commit refusal propagates to controller")
	check(book.is_dirty() and named(book.kept_rows(),"pending retry").correct,"Failed write retains exact proposed recipe in memory")
	check(FileAccess.get_file_as_string(path) == committed,"Failed proposal leaves prior persisted bytes intact")
	check(book.save() and not book.is_dirty(),"Explicit retry writes retained current proposal")
	var retry = Workspace.new()
	check(retry.setup(path).ok and named(retry.kept_rows(),"pending retry").correct,"Retried recipe is available to a new session")
	var selected_before: Dictionary = book.session.selected_entry()
	check(book.remove_kept("pending retry"),"Explicit removal commits without implicit eviction")
	check(book.session.draft() == dormant and book.session.selected_entry() == selected_before,"Removing kept entry preserves live draft and selected evidence")
	check(named(book.kept_rows(),"pending retry").is_empty(),"Removed entry is no longer ranked")
	check(not book.remove_kept("missing") and book.storage_reason == "missing","Unknown removal does not change data")
	# Two loaded workspaces cannot silently overwrite a newer writer.
	book.session.set_goal({"objective":"cycles","first_limit":530,"copy_limit":0})
	check(book.save(),"First writer commits a genuinely different snapshot")
	reopened.session.set_goal({"objective":"traffic","first_limit":-1,"copy_limit":-1})
	var latest: String = FileAccess.get_file_as_string(path)
	check(not reopened.save() and reopened.storage_status == "read_only","Stale disk signature protects another writer's update")
	check(not reopened.has_saved_workspace(),"Detected external conflict withdraws cached saved assurance")
	check(FileAccess.get_file_as_string(path) == latest and reopened.is_dirty(),"Conflict preserves disk and the live unsaved proposal")
	var failure_plan: Dictionary = starter.duplicate(true)
	failure_plan.copy_mode = "full"
	failure_plan.copy_fields = [0,1,2,3]
	book.session.edit(failure_plan)
	var failed: Dictionary = book.session.run_current()
	check(not failed.entry.correct and not book.keep_selected("incomplete"),"Actual allocation failure cannot become a named ranked result")
	check(root.get_node("LayoutChapter").game_snapshot() == official,"Notebook actions leave official state untouched")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy workspace %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
