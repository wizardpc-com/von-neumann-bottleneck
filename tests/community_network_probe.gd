extends SceneTree
const Transport = preload("res://src/playtest/remote_feedback.gd")
const C = preload("res://src/layout_chapter/layout_catalog.gd")
var endpoint: String
var phase: String
func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--receiver="): endpoint=arg.trim_prefix("--receiver=")
		if arg.begins_with("--phase="): phase=arg.trim_prefix("--phase=")
	call_deferred("run")
func run() -> void:
	ProjectSettings.set_setting("application/feedback_endpoint",endpoint)
	var transport := Transport.new(); transport.state_path="user://community_network_outbox.json"
	root.add_child(transport); transport.set_process(false)
	if phase=="queue":
		transport.set_sharing_mode("basic"); transport.set_scores_enabled(true)
		transport._on_event({"event":"level_start","visit_id":"synthetic-community-visit"})
		transport._on_event({"event":"visit_summary","visit_id":"synthetic-community-visit","session_id":"synthetic-community","sequence":1,"source":"automated","mode":"test","task_version":"tasks-20260910-v1","payload":{"chapter_id":"chapter_4","level_id":"mixed","foreground_ms":1234,"background_ms":567,"feedback_ms":80,"max_hint_stage":2,"completed":true,"connections":1,"branches":1,"official_runs":1}})
		transport.send_feedback({"session_id":"synthetic-community","sequence":2,"source":"automated","mode":"test","payload":{"chapter_id":"chapter_4","level_id":"mixed","note":"synthetic opinion","fun":4}})
		var design: Dictionary = C.starter_design(); design.strategy="batch"; design.copy_fields=[0,3]
		design.recipe={"groups":[{"fields":[0,3],"order":"record"},{"fields":[1,2],"order":"record"}],"block":0}
		var report: Dictionary = C.evaluate("mixed",design)
		if not report.passed: fail("synthetic local case fixture"); return
		var payload: Dictionary = {"chapter_id":"chapter_4","level_id":"mixed","ruleset_version":"layout-mixed-1","model_version":"layout-memory-1","case_set_version":("layout-v1:mixed"+JSON.stringify(C.cases("mixed"))).sha256_text(),"build_version":"synthetic-build","source":"automated","mode":"test","passed":true,"passed_cases":2,"case_count":2,"total_cycles":int(report.runs[0].metrics.total_cycles)+int(report.runs[1].metrics.total_cycles)}
		for i: int in range(2):
			for key: String in ["total_cycles","prepare_cycles","query_cycles","output_cycles","ram_read_bytes","ram_write_bytes","peak_extra_bytes"]: payload[["a","b"][i]+"_"+key]=int(report.runs[i].metrics[key])
		transport.send_score(payload)
		await create_timer(0.3).timeout
		if transport.queue.size()!=3: fail("three durable records"); return
		var file := FileAccess.open("user://synthetic_records.json",FileAccess.WRITE); file.store_string(JSON.stringify(transport.queue)); file.close()
		var changed := Transport.new(); changed.state_path=transport.state_path; changed.endpoint="https://changed.invalid/v1"; changed._load_state()
		if changed.enabled or changed.scores_enabled or not changed.queue.is_empty(): fail("changed endpoint consent"); return
		changed.free()
	elif phase=="resume":
		if transport.queue.size()!=3 or transport.sharing_mode!="basic" or not transport.scores_enabled: fail("restart preserved consent and records"); return
		transport.retry_pending(); await wait_empty(transport)
		if not transport.queue.is_empty(): fail("HTTP ack "+transport.status+" "+transport.last_error); return
		var replay: Array = JSON.parse_string(FileAccess.get_file_as_string("user://synthetic_records.json"))
		for item: Dictionary in replay: transport._enqueue(item.record)
		transport.flush(); await wait_empty(transport)
		if not transport.queue.is_empty(): fail("idempotent retransmission"); return
		transport.set_sharing_mode("local"); transport._on_event({"event":"level_start","visit_id":"after-withdraw"})
		if not transport.queue.is_empty(): fail("withdrawal"); return
	elif phase=="delete_offline":
		transport.delete_uploaded_data(); await create_timer(0.3).timeout
		if not transport.deletion_pending or transport.enabled or transport.scores_enabled: fail("durable offline deletion"); return
	elif phase=="delete_resume":
		if not transport.deletion_pending: fail("restart lost deletion request"); return
		transport.flush()
		for i: int in range(600):
			if transport.status=="deleted": break
			await create_timer(0.02).timeout
		if transport.status!="deleted" or not transport.identity_deleted: fail("delete confirmation "+transport.status); return
	print("PASS: community loopback "+phase)
	quit(0)
func wait_empty(transport: Node) -> void:
	for i: int in range(600):
		if transport.queue.is_empty(): return
		await create_timer(0.02).timeout
func fail(message: String) -> void:
	push_error(message); quit(1)
