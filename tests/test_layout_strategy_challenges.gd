extends SceneTree
const Challenges = preload("res://experiments/layout_strategy/challenges.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Workspace = preload("res://experiments/layout_strategy/workspace.gd")
var checks: int = 0
var failures: Array[String] = []

class FailStore:
	extends "res://experiments/layout_strategy/challenge_store.gd"
	var fail_next: bool = false
	func write(value: Dictionary) -> Dictionary:
		if fail_next:
			fail_next = false
			return {"ok":false,"status":"write_failed","reason":"write","snapshot":{}}
		return super.write(value)

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Challenge controller checks require an isolated verifier profile.")
		quit(1)
		return
	for frame: int in 3: await process_frame
	var official: Dictionary = root.get_node("GlobalSave")._save_snapshot().duplicate(true)
	var book = Workspace.new()
	check(book.setup("user://challenge-controller/notebook.json").ok,"New notebook opens independently")
	var board = Challenges.new()
	board.store = FailStore.new()
	var path: String = "user://challenge-controller/targets.json"
	check(board.setup(path).ok and not board.is_dirty(),"Empty targets start clean without writing")
	check(not FileAccess.file_exists(path),"Opening challenges does not invent a persisted file")
	check(board.target("scan_batch").code.is_empty(),"No default target or automatic challenge")
	check(not board.setup(path).ok,"Controller cannot be reinitialized over live proposals")
	var session = book.session
	var direct: Dictionary = session.run_current().entry
	var starter: Dictionary = session.draft()
	var grouped: Dictionary = starter.duplicate(true)
	grouped.query_group = 2
	grouped.record_tile = 1
	session.edit(grouped)
	session.undo()
	var saved_selection: Dictionary = session.selected_entry()
	var state_before: Dictionary = book.snapshot()
	var initial: Dictionary = Code.starter("scan_batch")
	check(initial.ok and initial.entry.metrics.total_cycles == 2456,"Starter target is an actual complete2456-cycle run")
	check(board.preview(initial.code,"scan_batch").ok,"Explicit preview locally reconstructs a valid target")
	check(not board.preview(initial.code,"scan_serial").ok,"Foreign workload preview cannot become current target")
	check(not board.preview("VNBSC1:broken","scan_batch").ok,"Malformed code rejected before acceptance")
	check(not board.accept(initial.code,"scan_serial").accepted,"Confirmation rechecks actual workload")
	check(board.target("scan_batch").code.is_empty(),"Rejected preview/accept never changes target")
	check(book.snapshot() == state_before and session.selected_entry() == saved_selection and session.can_redo(),"Preview preserves draft, personal goals, selection and Redo")
	check(board.accept(initial.code,"scan_batch").ok,"Explicit accept writes target separately")
	check(board.target("scan_batch").active and board.target("scan_batch").saved and not board.is_dirty(),"Accepted target reports current, saved and clean")
	check(book.snapshot() == state_before and session.can_redo(),"Accept never edits the notebook or edit history")
	check(not FileAccess.file_exists(book.store.storage_path),"Target accept does not pretend to save the notebook")
	var saved_bytes: String = FileAccess.get_file_as_string(path)
	check(board.compare("scan_batch",direct).status == "tied","Original actual run ties the accepted target")
	session.redo()
	var winning: Dictionary = session.run_current().entry
	check(winning.metrics.first_request_cycles == 339 and winning.metrics.total_cycles == 1368,"Playable grouped response actually measures339/1368")
	var verdict: Dictionary = board.compare("scan_batch",winning)
	check(verdict.status == "improved" and verdict.delta == -1088,"Measured qualifying improvement uses target's objective")
	var relaxed: Dictionary = grouped.duplicate(true)
	relaxed.query_group = 8
	session.edit(relaxed)
	var outside: Dictionary = session.run_current().entry
	check(outside.metrics.total_cycles == 552 and board.compare("scan_batch",outside).status == "outside","Lower total cannot bypass immutable Q1 cap")
	session.set_goal({"objective":"traffic","first_limit":1000000,"copy_limit":-1})
	check(board.compare("scan_batch",outside).status == "outside","Personal goal edits cannot relax target rules")
	check(board.target("scan_batch").code == initial.code,"Goal/filter changes preserve exact code")
	check(book.save(),"Notebook can be saved separately")
	var notebook_bytes: String = FileAccess.get_file_as_string(book.store.storage_path)
	check(FileAccess.get_file_as_string(path) == saved_bytes,"Notebook saving leaves target bytes unchanged")
	var fake: Dictionary = winning.duplicate(true)
	fake.metrics.total_cycles = 0
	fake.metrics.first_request_cycles = 0
	check(board.compare("scan_batch",fake) == verdict,"Recomparison reconstructs actual result instead of trusting row numbers")
	fake.trace_id = "not the actual full trace"
	check(board.compare("scan_batch",fake).status == "unavailable","Mismatched measurement identity cannot report a win")
	fake = winning.duplicate(true)
	fake.condition_id = Model.condition_id(Model.scenario("scan_serial"))
	check(board.compare("scan_batch",fake).status == "unavailable","Same-looking metrics in a different condition cannot compare")
	var failed_plan: Dictionary = starter.duplicate(true)
	failed_plan.copy_mode = "full"
	failed_plan.copy_fields = [0,1,2,3]
	session.edit(failed_plan)
	var incomplete: Dictionary = session.run_current().entry
	check(not incomplete.correct and board.compare("scan_batch",incomplete).status == "unavailable","Failed allocation with partial totals never beats a target")
	var improved_code: Dictionary = Code.create("scan_batch",winning.plan,initial.envelope.goal)
	check(improved_code.ok,"An actual improvement can be shared under the original immutable goal")
	board.store.fail_next = true
	var pending: Dictionary = board.accept(improved_code.code,"scan_batch")
	check(pending.accepted and not pending.ok and board.is_dirty(),"Failed replacement keeps accepted proposal temporary")
	check(board.target("scan_batch").active and not board.target("scan_batch").saved and board.target("scan_batch").pending,"Pending replacement has truthful storage status")
	check(board.target("scan_batch").code == improved_code.code and FileAccess.get_file_as_string(path) == saved_bytes,"Pending exact code retained; committed bytes protected")
	var old = Challenges.new()
	check(old.setup(path).ok and old.target("scan_batch").code == initial.code and old.target("scan_batch").saved,"Reopening before retry uses the prior saved target")
	session.set_goal({"objective":"cycles","first_limit":0,"copy_limit":0})
	check(board.retry().ok and not board.is_dirty(),"Explicit retry saves exact proposal despite unrelated impossible personal goal")
	check(board.target("scan_batch").code == improved_code.code and board.target("scan_batch").saved,"Retry preserves exact recipe/caps/objective")
	check(board.compare("scan_batch",direct).status == "behind" and board.compare("scan_batch",winning).status == "tied","New actual target yields behind and tied verdicts")
	var restarted = Challenges.new()
	check(restarted.setup(path).ok and restarted.target("scan_batch").inspection.entry.trace_id == winning.trace_id,"New controller reconstructs exact complete target Trace")
	check(FileAccess.get_file_as_string(book.store.storage_path) == notebook_bytes,"Target operations preserve notebook bytes")
	board.store.fail_next = true
	check(not board.clear("scan_batch").ok and board.is_dirty(),"Failed removal remains an explicit pending proposal")
	var cleared: Dictionary = board.target("scan_batch")
	check(cleared.code.is_empty() and not cleared.active and cleared.pending,"Pending removal stops current challenge and reports pending")
	check(board.compare("scan_batch",winning).status == "unavailable","No active target means no challenge verdict")
	var before_clear: String = FileAccess.get_file_as_string(path)
	check(not before_clear.is_empty() and before_clear.contains(improved_code.code.c_escape()),"Failed clear does not delete committed target bytes")
	check(board.retry().ok and not board.is_dirty(),"Retry commits removal")
	check(JSON.parse_string(FileAccess.get_file_as_string(path)).targets.is_empty(),"Saved target map now actually empty")
	var serial: Dictionary = Code.starter("scan_serial")
	check(board.accept(serial.code,"scan_serial").ok,"Independent serial challenge persists")
	check(board.target("scan_batch").code.is_empty() and board.target("scan_serial").saved,"Workloads retain independent target state")
	session.change_task("scan_serial")
	var copy: Dictionary = Model.starter_plan()
	copy.copy_mode = "full"
	session.edit(copy)
	var serial_winner: Dictionary = session.run_current().entry
	check(serial_winner.metrics.first_request_cycles == 557 and serial_winner.metrics.total_cycles == 1362,"Serial reuse is measured557/1362, not a stored score")
	check(board.compare("scan_serial",serial_winner).status == "improved","Second opt-in target has an actual admissible improvement")
	check(board.compare("scan_batch",serial_winner).status == "unavailable","Cross-workload attempt stays excluded")
	var before_restore: Dictionary = session.draft()
	check(session.edit(board.target("scan_serial").inspection.envelope.plan),"Explicit target recipe restoration changes draft")
	check(session.undo() and session.draft() == before_restore,"One Undo restores exact pre-target draft")
	# A structurally supported stale code survives storage without becoming live.
	var stale: Dictionary = Code.decode(serial.code).envelope
	stale.model = "layout-schedule-experiment-old"
	var stale_code: String = Code.PREFIX+JSON.stringify(stale,"",true)
	var stale_path: String = "user://challenge-controller/stale.json"
	var file := FileAccess.open(stale_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"targets":{"scan_serial":stale_code}},"",true))
	file.close()
	var stale_board = Challenges.new()
	check(stale_board.setup(stale_path).ok,"Supported stale input is retained as data")
	var stale_target: Dictionary = stale_board.target("scan_serial")
	check(stale_target.saved and not stale_target.active and stale_target.code == stale_code,"Old code remains copyable and inactive")
	check(stale_board.compare("scan_serial",serial_winner).status == "unavailable","Stale conditions cannot participate in live comparison")
	check(not stale_board.accept(stale_code,"scan_serial").accepted,"Stale code cannot be newly accepted as a live target")
	check(FileAccess.get_file_as_string(stale_path).contains(stale_code.c_escape()),"Stale read/inspection preserves exact persistent bytes")
	# A stale writer's proposal cannot overwrite a newer actual disk version.
	check(not old.accept(serial.code,"scan_serial").ok and old.storage_status == "read_only","External target update is protected from stale writer")
	check(old.target("scan_serial").pending and old.target("scan_serial").active,"Conflict preserves usable temporary proposal")
	check(old.target("scan_batch").code == initial.code and not old.target("scan_batch").saved,"Detected external conflict withdraws saved assurance for the old cached target")
	check(not JSON.parse_string(FileAccess.get_file_as_string(path)).targets.has("scan_batch"),"Conflict assertion uses a genuinely removed on-disk target")
	var deletion = Challenges.new()
	check(deletion.setup(path).ok and deletion.target("scan_serial").saved,"Deletion fixture begins with a real saved target")
	check(DirAccess.remove_absolute(path) == OK,"Delete only this isolated test's committed target file")
	check(not deletion.retry().ok and deletion.storage_status == "read_only","Detected external deletion protects missing disk state")
	check(not deletion.target("scan_serial").saved and deletion.target("scan_serial").code == serial.code,"Externally deleted target stays copyable without a saved claim")
	var official_after: Dictionary = root.get_node("GlobalSave")._save_snapshot().duplicate(true)
	official.erase("saved_at_utc")
	official_after.erase("saved_at_utc")
	check(official_after == official,"Challenge loop leaves official save/progress unchanged")
	for issue: String in failures: print("FAILED CHECK: "+issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy challenges %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
