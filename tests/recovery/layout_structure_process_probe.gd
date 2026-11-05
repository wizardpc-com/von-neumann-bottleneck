extends SceneTree
## Runs against both frozen v1 and current v2 runtimes in a named QA profile.
const Workspace = preload("res://experiments/layout_strategy/workspace.gd")
const Challenges = preload("res://experiments/layout_strategy/challenges.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const OLD_IDS: Array[String] = ["scan_batch","scan_serial","mixed_batch","mixed_serial"]
const BOOK_V1: String = "user://layout_strategy_notebook_v1.json"
const TARGET_V1: String = "user://layout_strategy_challenges_v1.json"
const BOOK_V2: String = "user://layout_strategy_notebook_v2.json"
const TARGET_V2: String = "user://layout_strategy_challenges_v2.json"
var checks: int = 0
var failures: Array[String] = []
var held: RefCounted

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func canonical(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)),"",true)

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Open isolated evidence output")
	if file == null: return
	file.store_string(JSON.stringify(value,"",true))
	file.close()

func signatures(book: RefCounted, board: RefCounted) -> Dictionary:
	var kept: Dictionary = {}
	var targets: Dictionary = {}
	var active: String = book.session.task_id
	for id: String in Model.SCENARIO_IDS:
		book.session.change_task(id)
		kept[id] = book.kept_rows()
		var target: Dictionary = board.target(id)
		targets[id] = {"code":target.code,"active":target.active}
		if target.active:
			targets[id]["trace"] = target.inspection.entry.trace_id
			targets[id]["metrics"] = target.inspection.entry.metrics
	book.session.change_task(active)
	return {"snapshot":book.snapshot(),"kept":kept,"targets":targets}

func compare_expected(path: String, book: RefCounted, board: RefCounted) -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(expected is Dictionary,"Expected previous-process evidence exists")
	if expected is Dictionary:
		check(canonical(signatures(book,board)) == canonical(expected),
			"Inputs, every kept measurement, target and complete Trace survive restart")

func unchanged_legacy(before: Dictionary) -> void:
	check(FileAccess.get_file_as_string(BOOK_V1) == before.book,"New runtime preserves legacy Notebook bytes")
	check(FileAccess.get_file_as_string(TARGET_V1) == before.targets,"New runtime preserves legacy target bytes")

func hold_writer(path: String) -> void:
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir()) == OK,
		"Create isolated writer parent without prewriting a payload")
	held = Lease.new(path)
	check(held.owns(path),"Owned process acquired exact writer lease")
	if failures.is_empty():
		write_json("user://structure-writer-ready.json",{"pid":OS.get_process_id(),"path":path})
		await create_timer(120.0).timeout
	held.release()

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/layout_strategy/structure-upgrade-process-"):
		push_error("Structural process probe requires a fresh named QA profile.")
		quit(1)
		return
	for frame: int in 3: await process_frame
	var phase: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--structure-phase="): phase = arg.trim_prefix("--structure-phase=")
	var book = Workspace.new()
	var board = Challenges.new()
	check(book.setup().ok and board.setup().ok,"Load independent inputs in selected runtime")
	var official: Dictionary = root.get_node("GlobalSave")._save_snapshot().duplicate(true)
	var old: Dictionary = {
		"book":FileAccess.get_file_as_string(BOOK_V1) if FileAccess.file_exists(BOOK_V1) else "",
		"targets":FileAccess.get_file_as_string(TARGET_V1) if FileAccess.file_exists(TARGET_V1) else "",
	}
	match phase:
		"old-seed-read":
			check(Model.SCENARIO_IDS == OLD_IDS,"Frozen runtime retains four original workloads")
			check(book.session.task_id == "scan_serial" and book.kept_rows().size() == 2,"Old runtime reads its actual original Notebook")
			check(board.target("scan_serial").active and board.target("scan_serial").saved,"Old target freshly remeasured and saved")
			write_json("user://expected-v1.json",signatures(book,board))
			check(not FileAccess.file_exists(BOOK_V2) and not FileAccess.file_exists(TARGET_V2),"Old read creates no new files")
		"new-read":
			check(book.origin == "legacy" and book.copy_pending and book.is_dirty(),"New Notebook loads legacy with explicit pending copy")
			check(board.origin == "legacy" and board.copy_pending and board.is_dirty(),"New challenge map loads legacy independently")
			check(not book.has_saved_workspace() and not board.target("scan_serial").saved,"Read does not claim current-version persistence")
			check(not FileAccess.file_exists(BOOK_V2) and not FileAccess.file_exists(TARGET_V2),"First new read writes no payload")
			check(book.session.task_id == "scan_serial" and book.kept_rows().size() == 2,"New read retains actual old draft and recipes")
			unchanged_legacy(old)
		"old-hold-target":
			check(board.store.storage_path == TARGET_V1,"Frozen owner locks legacy target path")
			await hold_writer(board.store._writer_path())
		"contend-source":
			var accepted: Dictionary = board.accept(Code.starter("scan_pair_serial").code,"scan_pair_serial")
			check(accepted.accepted and not accepted.ok and board.storage_reason == "busy","Live old-source owner blocks new target copy")
			check(board.copy_pending and board.target("scan_pair_serial").pending,"Exact new proposal survives source contention")
			check(not board.recover_writer().ok,"Explicit recovery refuses live legacy owner")
			check(not FileAccess.file_exists(TARGET_V2) and not FileAccess.file_exists(BOOK_V2),"Contended copy creates neither sidecar")
			unchanged_legacy(old)
		"recover-source":
			var accepted: Dictionary = board.accept(Code.starter("scan_pair_serial").code,"scan_pair_serial")
			check(not accepted.ok and board.storage_reason == "busy","Stopped source ownership still requires explicit recovery")
			check(board.recover_writer().ok,"Recover exact demonstrably stopped legacy writer")
			check(not FileAccess.file_exists(TARGET_V2),"Recovery itself creates no payload")
			check(board.retry().ok and not board.copy_pending,"Retry commits genuinely changed six-condition target proposal")
			check(board.target("scan_pair_serial").saved and board.target("scan_serial").saved,"Both new and old targets are saved")
			check(not FileAccess.file_exists(BOOK_V2) and book.copy_pending,"Target transaction leaves Notebook pending")
			unchanged_legacy(old)
		"hold-current-book":
			check(book.store.storage_path == BOOK_V2,"New owner locks current Notebook destination")
			await hold_writer(book.store._writer_path())
		"contend-destination":
			var targets_before: String = FileAccess.get_file_as_string(TARGET_V2)
			book.session.change_task("scan_pair_serial")
			book.session.set_goal({"objective":"traffic","first_limit":600,"copy_limit":80})
			check(not book.save() and book.storage_reason == "busy","Live destination owner blocks legacy Notebook copy")
			check(book.copy_pending and book.is_dirty() and not book.has_saved_workspace(),"Unwritten Notebook proposal remains pending")
			check(not book.recover_writer(),"Explicit recovery refuses live destination owner")
			check(not FileAccess.file_exists(BOOK_V2),"Blocked destination creates no Notebook payload")
			check(FileAccess.get_file_as_string(TARGET_V2) == targets_before,"Notebook contention preserves independent current targets")
			unchanged_legacy(old)
		"recover-destination":
			book.session.change_task("scan_pair_serial")
			book.session.set_goal({"objective":"traffic","first_limit":600,"copy_limit":80})
			var plan: Dictionary = Model.starter_plan()
			plan.copy_mode = "full"
			book.session.edit(plan)
			var attempt: Dictionary = book.session.run_current().entry
			check(not book.keep_selected("process copied temperature") and book.storage_reason == "busy","Stopped destination blocks a genuinely changed proposal")
			check(book.recover_writer(),"Recover exact demonstrably stopped current writer")
			check(not FileAccess.file_exists(BOOK_V2),"Destination recovery performs no implicit save")
			check(book.save() and book.origin == "current" and not book.copy_pending,"Explicit retry persists new-condition Notebook")
			check(board.compare("scan_pair_serial",attempt).status == "improved" and board.compare("scan_pair_serial",attempt).delta == -44,"Recovered actual copy improves original RAM challenge by44 bytes")
			check(book.session.draft() == plan and book.kept_rows().size() == 1,"Recovered proposal retains exact new draft and selected recipe")
			unchanged_legacy(old)
			write_json("user://expected-v2.json",signatures(book,board))
		"new-reopen":
			check(book.origin == "current" and board.origin == "current","Existing v2 wins independently over legacy files")
			check(not book.copy_pending and not board.copy_pending and book.has_saved_workspace(),"Reopened current data is truly saved")
			compare_expected("user://expected-v2.json",book,board)
			check(book.session.rows().is_empty() and not book.session.can_undo(),"Transient runs and Undo are not manufactured on reopen")
			unchanged_legacy(old)
		"old-rollback-read":
			check(Model.SCENARIO_IDS == OLD_IDS,"Rollback actually executes frozen old runtime")
			compare_expected("user://expected-v1.json",book,board)
			check(book.has_saved_workspace() and board.target("scan_serial").saved,"Old runtime still reads its untouched saved files")
		"old-rollback-edit":
			var current_book: String = FileAccess.get_file_as_string(BOOK_V2)
			var current_targets: String = FileAccess.get_file_as_string(TARGET_V2)
			book.session.set_goal({"objective":"cycles","first_limit":602,"copy_limit":80})
			check(book.save(),"Frozen old runtime can continue its own Notebook history")
			var goal: Dictionary = Code.starter("scan_serial").envelope.goal
			goal.first_limit = 602
			check(board.accept(Code.create("scan_serial",Model.starter_plan(),goal).code,"scan_serial").ok,"Frozen old runtime can continue its own challenge history")
			check(FileAccess.get_file_as_string(BOOK_V1) != old.book and FileAccess.get_file_as_string(TARGET_V1) != old.targets,"Rollback edits genuinely change both old payloads")
			check(FileAccess.get_file_as_string(BOOK_V2) == current_book and FileAccess.get_file_as_string(TARGET_V2) == current_targets,"Rollback leaves both new histories unchanged")
			write_json("user://expected-v1-edited.json",signatures(book,board))
		"old-edited-reopen":
			compare_expected("user://expected-v1-edited.json",book,board)
		"empty":
			check(book.origin == "empty" and board.origin == "empty" and not book.copy_pending and not board.copy_pending,"Independent profile starts fresh")
			check(not FileAccess.file_exists(BOOK_V1) and not FileAccess.file_exists(TARGET_V1) and not FileAccess.file_exists(BOOK_V2) and not FileAccess.file_exists(TARGET_V2),"Fresh read creates no legacy or current files")
		_:
			check(false,"Known process phase required")
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot().duplicate(true)
	official.erase("saved_at_utc")
	after.erase("saved_at_utc")
	check(official == after,"All process operations preserve formal progression")
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"structural process %s: %d checks" % [phase,checks])
	quit(0 if failures.is_empty() else 1)
