extends SceneTree
## Root's separate-process acceptance; never point this at a player profile.
const Workspace = preload("res://experiments/layout_strategy/workspace.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var failures: Array[String] = []
var checks: int = 0
var held: RefCounted

func _init() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func json_form(value: Variant) -> String:
	# Compare both sides after the same JSON numeric representation conversion.
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)),"",true)

func signatures(book: RefCounted) -> Dictionary:
	var active: String = book.session.task_id
	var result: Dictionary = {}
	for id: String in Model.SCENARIO_IDS:
		book.session.change_task(id)
		var rows: Array = []
		for row: Dictionary in book.kept_rows():
			rows.append({"name":row.name,"metrics":row.metrics,
				"condition":row.condition_id,"trace":row.trace_id})
		result[id] = rows
	book.session.change_task(active)
	return result

func _run() -> void:
	var directory: String = OS.get_user_data_dir().replace("\\","/")
	if not directory.contains("VonNeumannBottleneckChecks/layout_strategy/process-"):
		push_error("Notebook process probe requires a fresh named QA process profile.")
		quit(1)
		return
	var phase: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--notebook-phase="): phase = arg.trim_prefix("--notebook-phase=")
	var book = Workspace.new()
	check(book.setup().ok,"Read committed notebook")
	var before: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	match phase:
		"seed":
			check(not FileAccess.file_exists(book.store.storage_path),"Seed starts with absent notebook")
			book.session.run_current()
			check(book.keep_selected("first response"),"Keep direct strategy")
			var plan: Dictionary = Model.starter_plan()
			plan.query_group = 8
			plan.record_tile = 1
			book.session.edit(plan)
			book.session.run_current()
			check(book.keep_selected("less total work"),"Keep grouped strategy")
			book.session.set_goal({"objective":"cycles","first_limit":531,"copy_limit":0})
			plan.copy_fields = [3,1]
			book.session.edit(plan)
			book.session.change_task("scan_serial")
			var retained: Dictionary = Model.starter_plan()
			retained.copy_mode = "full"
			book.session.edit(retained)
			book.session.run_current()
			check(book.keep_selected("retained temperature"),"Keep serial copy strategy")
			book.session.set_goal({"objective":"traffic","first_limit":557,"copy_limit":80})
			check(book.save() and not book.is_dirty(),"Save active condition and exact draft/goal inputs")
			var expected := FileAccess.open("user://expected-replay.json",FileAccess.WRITE)
			expected.store_string(JSON.stringify({"snapshot":book.snapshot(),"measured":signatures(book)},"",true))
			expected.close()
		"reopen":
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://expected-replay.json"))
			check(json_form(book.snapshot()) == json_form(expected.snapshot),"All workspace inputs match across process restart")
			check(json_form(signatures(book)) == json_form(expected.measured),"All metrics and full Trace hashes reproduce across restart")
			check(book.session.task_id == "scan_serial" and book.session.rows().is_empty(),"Active workload returns without invented history")
			check(book.inspect_kept("retained temperature"),"Reconstructed retained input is playable")
			var metrics: Dictionary = book.session.selected_entry().metrics
			check(metrics.first_request_cycles == 557 and metrics.total_cycles == 1362 and metrics.peak_extra_bytes == 80,"Actual retained serial strategy reproduces")
			check(not book.is_dirty(),"Reading/replaying creates no unsaved input state")
		"hold":
			var writer_path: String = book.store._writer_path()
			held = Lease.new(writer_path)
			check(held.owns(writer_path),"Owned test process acquires real writer lease")
			if failures.is_empty():
				var signal_file := FileAccess.open("user://writer-ready.json",FileAccess.WRITE)
				signal_file.store_string(JSON.stringify({"pid":OS.get_process_id()}))
				signal_file.close()
				# Root deliberately ends only this owned process to test a stale lease.
				await create_timer(120.0).timeout
			held.release()
		"contend":
			book.session.set_goal({"objective":"cycles","first_limit":-1,"copy_limit":-1})
			check(not book.save() and book.storage_reason == "busy","Concurrent live writer cannot be overwritten")
			check(not book.recover_writer(),"Explicit recovery refuses the live writer")
			check(book.is_dirty(),"Contended save retains current proposal")
		"recover":
			var previous_bytes: String = FileAccess.get_file_as_string(book.store.storage_path)
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://expected-replay.json"))
			check(json_form(book.snapshot()) == json_form(expected.snapshot),"Recovery begins with the prior committed workspace")
			check(book.recover_writer(),"Explicit recovery reclaims demonstrably stopped test owner")
			var next_goal: Dictionary = book.session.goal()
			next_goal.first_limit = 558
			check(book.session.set_goal(next_goal) and book.is_dirty(),"Recovery test changes a real goal before saving")
			check(book.save() and not book.is_dirty(),"Actual changed input write succeeds after explicit owner recovery")
			check(FileAccess.get_file_as_string(book.store.storage_path) != previous_bytes,"Recovered writer replaces notebook bytes, not a no-op save")
			expected.snapshot.states.scan_serial.goal.first_limit = 558
			check(json_form(book.snapshot()) == json_form(expected.snapshot),"Only the intended saved goal changes")
			var expected_file := FileAccess.open("user://expected-replay.json",FileAccess.WRITE)
			expected_file.store_string(JSON.stringify(expected,"",true))
			expected_file.close()
		"empty":
			check(not FileAccess.file_exists(book.store.storage_path) and book.kept_rows().is_empty(),"Another named profile has no inherited notebook")
		_:
			check(false,"Known process phase required")
	check(root.get_node("LayoutChapter").game_snapshot() == before,"Process actions preserve official chapter state")
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"notebook process %s: %d checks" % [phase,checks])
	quit(0 if failures.is_empty() else 1)
