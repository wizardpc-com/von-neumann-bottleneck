extends SceneTree
## Separate-process acceptance; only root's fresh named QA profile is permitted.
const Challenges = preload("res://experiments/layout_strategy/challenges.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Workspace = preload("res://experiments/layout_strategy/workspace.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var checks: int = 0
var failures: Array[String] = []
var held: RefCounted

func _init() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func json_form(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)),"",true)

func signatures(board: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	for id: String in Model.SCENARIO_IDS:
		var target: Dictionary = board.target(id)
		result[id] = {"code":target.code,"active":target.active}
		if target.active:
			result[id]["metrics"] = target.inspection.entry.metrics
			result[id]["trace"] = target.inspection.entry.trace_id
			result[id]["identity"] = target.inspection.challenge_id
	return result

func save_expected(book: RefCounted, board: RefCounted) -> void:
	var file := FileAccess.open("user://expected-challenge-replay.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"notebook":book.snapshot(),"targets":signatures(board)},"",true))
	file.close()

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/layout_strategy/challenges-process-"):
		push_error("Challenge process probe requires a fresh named QA process profile.")
		quit(1)
		return
	var phase: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--challenge-phase="): phase = arg.trim_prefix("--challenge-phase=")
	var board = Challenges.new()
	var book = Workspace.new()
	check(board.setup().ok and book.setup().ok,"Read independent challenge and notebook inputs")
	var before: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	match phase:
		"seed":
			check(not FileAccess.file_exists(board.store.storage_path),"Seed has no inherited challenge")
			book.session.run_current()
			check(book.keep_selected("direct before challenge"),"Retain ordinary measured notebook recipe")
			var notebook_bytes: String = FileAccess.get_file_as_string(book.store.storage_path)
			check(board.accept(Code.starter("scan_batch").code,"scan_batch").ok,"Accept actual batch target")
			check(board.accept(Code.starter("scan_serial").code,"scan_serial").ok,"Accept actual serial target")
			check(FileAccess.get_file_as_string(book.store.storage_path) == notebook_bytes,"Target writes preserve notebook bytes")
			save_expected(book,board)
		"reopen":
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://expected-challenge-replay.json"))
			check(json_form(book.snapshot()) == json_form(expected.notebook),"Notebook inputs reproduce after process restart")
			check(json_form(signatures(board)) == json_form(expected.targets),"Canonical codes, metrics and full Traces reproduce after restart")
			check(board.target("scan_batch").saved and board.target("scan_serial").saved,"Restarted targets truthfully labelled saved")
			var plan: Dictionary = Model.starter_plan()
			plan.query_group = 2
			plan.record_tile = 1
			book.session.edit(plan)
			var attempt: Dictionary = book.session.run_current().entry
			check(board.compare("scan_batch",attempt).status == "improved","Reloaded target is playable and admits actual339/1368 improvement")
			check(not board.is_dirty(),"Read/replay/comparison does not dirty target file")
		"hold":
			var writer_path: String = board.store._writer_path()
			held = Lease.new(writer_path)
			check(held.owns(writer_path),"Owned process acquires actual challenge writer lease")
			if failures.is_empty():
				var marker := FileAccess.open("user://challenge-writer-ready.json",FileAccess.WRITE)
				marker.store_string(JSON.stringify({"pid":OS.get_process_id()}))
				marker.close()
				# Root kills only this owned PID after proving live contention.
				await create_timer(120.0).timeout
			held.release()
		"contend":
			var original: String = FileAccess.get_file_as_string(board.store.storage_path)
			var plan: Dictionary = Model.starter_plan()
			plan.query_group = 2
			plan.record_tile = 1
			var proposal: Dictionary = Code.create("scan_batch",plan,Code.starter("scan_batch").envelope.goal)
			var accepted: Dictionary = board.accept(proposal.code,"scan_batch")
			check(accepted.accepted and not accepted.ok and board.storage_reason == "busy","Live writer prevents replacement; proposal remains temporary")
			check(board.is_dirty() and board.target("scan_batch").pending,"Contended proposal retained exactly")
			check(not board.recover_writer().ok,"Explicit recovery refuses live owner")
			check(FileAccess.get_file_as_string(board.store.storage_path) == original,"Live contention protects target bytes")
			var notebook_before: String = FileAccess.get_file_as_string(book.store.storage_path)
			book.session.set_goal({"objective":"traffic","first_limit":500,"copy_limit":0})
			check(book.save(),"Independent notebook can save while challenge writer is held")
			check(FileAccess.get_file_as_string(book.store.storage_path) != notebook_before,"Independent notebook save writes genuinely changed inputs")
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://expected-challenge-replay.json"))
			expected.notebook = book.snapshot()
			var file := FileAccess.open("user://expected-challenge-replay.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(expected,"",true))
			file.close()
		"recover":
			var original: String = FileAccess.get_file_as_string(board.store.storage_path)
			var notebook_bytes: String = FileAccess.get_file_as_string(book.store.storage_path)
			check(board.recover_writer().ok,"Explicit recovery reclaims demonstrably stopped owned writer")
			var goal: Dictionary = Code.starter("scan_serial").envelope.goal
			goal.first_limit = 601
			var changed: Dictionary = Code.create("scan_serial",Model.starter_plan(),goal)
			check(board.accept(changed.code,"scan_serial").ok,"Recovered owner commits a genuinely changed challenge")
			check(FileAccess.get_file_as_string(board.store.storage_path) != original,"Recovery replaces real target bytes, not a no-op")
			check(board.target("scan_serial").inspection.envelope.goal.first_limit == 601,"Recovered challenge preserves exact changed cap")
			check(FileAccess.get_file_as_string(book.store.storage_path) == notebook_bytes,"Recovery never rewrites notebook")
			save_expected(book,board)
		"empty":
			check(not FileAccess.file_exists(board.store.storage_path) and not FileAccess.file_exists(book.store.storage_path),"Another profile inherits neither notebook nor targets")
			check(board.target("scan_batch").code.is_empty() and not board.is_dirty(),"Separate profile starts unchallenged")
		_:
			check(false,"Known challenge process phase required")
	check(root.get_node("LayoutChapter").game_snapshot() == before,"Process operations preserve formal chapter state")
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"challenge process %s: %d checks" % [phase,checks])
	quit(0 if failures.is_empty() else 1)
