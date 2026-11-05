extends SceneTree
const Workspace = preload("res://experiments/layout_strategy/workspace.gd")
const Challenges = preload("res://experiments/layout_strategy/challenges.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const FIXTURE: String = "res://tests/fixtures/layout_strategy/legacy-scheduling-v1.json"
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func write_text(path: String, text: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(text)
	file.close()
	return true

func _run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/"):
		push_error("Controller upgrade checks require isolated player data.")
		quit(1)
		return
	for frame: int in 3: await process_frame
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var official: Dictionary = root.get_node("GlobalSave")._save_snapshot().duplicate(true)
	var base: String = "user://controller-upgrade"
	var old_book: String = base+"/notebook-v1.json"
	var old_targets: String = base+"/targets-v1.json"
	var new_book: String = base+"/notebook-v2.json"
	var new_targets: String = base+"/targets-v2.json"
	check(write_text(old_book,fixture.notebook_v1) and write_text(old_targets,fixture.targets_v1),"Seed two actual old-format input files")
	var book = Workspace.new()
	var board = Challenges.new()
	check(book.setup(new_book,old_book).ok and board.setup(new_targets,old_targets).ok,"Both validated legacy inputs load independently")
	check(book.origin == "legacy" and book.copy_pending and book.is_dirty(),"Loaded notebook requires explicit new-format save")
	check(not book.has_saved_workspace() and not FileAccess.file_exists(new_book),"Reading legacy creates no current file or saved claim")
	check(board.origin == "legacy" and board.copy_pending and board.is_dirty(),"Loaded target map requires independent explicit save")
	check(not board.target("scan_serial").saved and board.target("scan_serial").pending,"Uncommitted legacy target is usable but not labelled saved")
	check(book.session.task_id == "scan_serial" and book.session.draft().copy_mode == "full","Original active workload and draft survive")
	check(book.session.goal().objective == "traffic" and book.kept_rows().size() == 2,"Original goal and named recipes survive and remeasure")
	check(book.session.rows().is_empty() and not book.session.can_undo(),"Copy-forward invents no transient run history or Undo")
	var original_target: String = board.target("scan_serial").code
	var old_draft: Dictionary = book.session.draft()
	var old_goal: Dictionary = book.session.goal()
	for id: String in ["scan_pair_serial","split_fields_serial"]:
		check(book.session.change_task(id),"New workload is reachable: "+id)
		check(book.session.draft() == Model.starter_plan() and book.kept_rows().is_empty(),"New workload receives no copied recipe/history: "+id)
		check(book.session.goal().first_limit == -1 and board.target(id).code.is_empty(),"New goals and targets start independent: "+id)
		check(book.session.rows().is_empty() and not book.session.can_undo(),"New transient state is empty: "+id)
	book.session.change_task("scan_serial")
	check(book.session.draft() == old_draft and book.session.goal() == old_goal,"Returning recovers exact earlier editor choices")
	var pending_snapshot: Dictionary = book.snapshot()
	var original_selection: Dictionary = book.session.selected_entry()
	var pair: Dictionary = Code.starter("scan_pair_serial")
	check(board.preview(pair.code,"scan_pair_serial").ok,"New structural target locally remeasures")
	check(book.snapshot() == pending_snapshot and book.session.selected_entry() == original_selection,"Preview preserves pending legacy notebook")
	check(board.retry().ok and not board.copy_pending and not board.is_dirty(),"Explicit unchanged target retry creates the v2 copy")
	check(FileAccess.file_exists(new_targets) and board.target("scan_serial").saved,"Actual v2 target bytes establish saved assurance")
	check(not FileAccess.file_exists(new_book) and book.copy_pending,"Target save leaves notebook pending")
	check(board.accept(pair.code,"scan_pair_serial").ok,"New target joins v2 without replacing old targets")
	check(board.target("scan_serial").code == original_target,"Accepting a new condition preserves original code exactly")
	book.session.change_task("scan_pair_serial")
	var direct: Dictionary = book.session.run_current().entry
	check(book.keep_selected("两次 · source"),"Saving new measured recipe creates the pending v2 notebook")
	check(book.origin == "current" and not book.copy_pending and book.has_saved_workspace(),"Actual notebook commit changes origin/saved state")
	var copied: Dictionary = Model.starter_plan()
	copied.copy_mode = "full"
	book.session.edit(copied)
	var copied_run: Dictionary = book.session.run_current().entry
	check(book.keep_selected("两次 · copy"),"Second real recipe retained independently")
	check(board.compare("scan_pair_serial",copied_run).status == "improved","RAM starter is improved by a real copied run")
	book.session.set_goal({"objective":"cycles","first_limit":600,"copy_limit":80})
	var rows: Array[Dictionary] = book.kept_rows()
	check(rows.size() == 2 and rows[0].name == "两次 · source","Total-cycle goal chooses direct recipe")
	book.session.set_goal({"objective":"traffic","first_limit":600,"copy_limit":80})
	rows = book.kept_rows()
	check(rows.size() == 2 and rows[0].name == "两次 · copy","RAM goal reverses the actual retained-plan ranking")
	check(board.compare("scan_pair_serial",copied_run).delta == -44,"Challenge keeps its own44-byte improvement under personal goal edits")
	check(board.compare("scan_serial",copied_run).status == "unavailable","New attempt cannot compare with old repeated-scan condition")
	check(book.save(),"Explicit save retains active new condition and personal goal")
	var reopen = Workspace.new()
	var target_reopen = Challenges.new()
	check(reopen.setup(new_book,old_book).ok and target_reopen.setup(new_targets,old_targets).ok,"Current files reopen independently")
	check(reopen.session.task_id == "scan_pair_serial" and reopen.session.draft() == copied,"New active condition and exact draft reopen")
	check(reopen.kept_rows().size() == 2 and reopen.kept_rows()[0].trace_id == copied_run.trace_id,"Reopened kept result freshly matches full new-condition Trace")
	check(target_reopen.target("scan_pair_serial").code == pair.code and target_reopen.target("scan_serial").code == original_target,"Both old and new targets persist with exact code identity")
	check(reopen.session.rows().is_empty() and not reopen.session.can_undo(),"Current reopen still excludes transient evidence/history")
	reopen.session.change_task("scan_serial")
	check(reopen.session.draft() == old_draft and reopen.session.goal() == old_goal and reopen.kept_rows().size() == 2,"Old condition remains intact after new exploration and reopen")
	check(FileAccess.get_file_as_string(old_book) == fixture.notebook_v1 and FileAccess.get_file_as_string(old_targets) == fixture.targets_v1,"All current-version operations preserve both legacy payloads byte-for-byte")
	check(direct.metrics.total_cycles == 614 and copied_run.metrics.total_cycles == 672,"Actual new timings are not imported scalar scores")
	# A deliberate current clear never revives the legacy target on reopen.
	for id: String in Model.SCENARIO_IDS: check(board.clear(id).ok,"Explicit current target removal: "+id)
	var cleared = Challenges.new()
	check(cleared.setup(new_targets,old_targets).ok and not cleared.copy_pending,"Existing empty v2 is authoritative")
	for id: String in Model.SCENARIO_IDS:
		check(cleared.target(id).code.is_empty(),"Legacy target does not revive after current clear: "+id)
	var final_official: Dictionary = root.get_node("GlobalSave")._save_snapshot().duplicate(true)
	official.erase("saved_at_utc")
	final_official.erase("saved_at_utc")
	check(official == final_official,"Copy-forward and structural exploration leave formal progression unchanged")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy controller upgrade %d checks,%d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
