extends SceneTree
const Transport = preload("res://src/playtest/remote_feedback.gd")
var endpoint: String
var phase: String
func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--receiver="): endpoint=arg.trim_prefix("--receiver=")
		if arg.begins_with("--phase="): phase=arg.trim_prefix("--phase=")
	call_deferred("run")
func run() -> void:
	ProjectSettings.set_setting("application/feedback_endpoint",endpoint)
	var transport := Transport.new(); transport.state_path="user://synthetic_outbox.json"
	root.add_child(transport); transport.set_process(false)
	transport.endpoint=endpoint
	# The probe explicitly opts into its loopback receiver in each isolated process.
	if phase=="resume" and transport.queue.size()!=1:
		push_error("Durable event was lost between processes"); quit(1); return
	transport.set_enabled(true)
	if phase=="queue":
		transport._on_event({"session_id":"synthetic-network-session","sequence":1,"source":"automated","mode":"test","event":"visit_time","visit_id":"synthetic-visit","payload":{"chapter_id":"chapter_4","level_id":"fields","kind":"foreground","duration_ms":1234}})
		transport.flush()
		for frame: int in range(500):
			if transport.status=="failed_retryable": break
			await create_timer(0.02).timeout
		if transport.status!="failed_retryable" or transport.queue.size()!=1: push_error("Offline event must stay pending"); quit(1); return
		var catalog = preload("res://src/layout_chapter/layout_catalog.gd")
		var report: Dictionary = catalog.evaluate("fields",catalog.starter_design())
		if report.runs.size()!=2: push_error("Offline simulation unavailable"); quit(1); return
		print("PASS: offline simulation and durable queue before process exit")
		quit(0); return
	transport.retry_pending()
	for frame: int in range(800):
		if transport.queue.is_empty(): break
		await create_timer(0.02).timeout
	if not transport.queue.is_empty(): push_error("Queue lacks stored acknowledgement: "+transport.status); quit(1); return
	if phase=="resume":
		# Simulate duplicate delivery after a lost acknowledgement; same ID and payload.
		transport._on_event({"session_id":"synthetic-network-session","sequence":1,"source":"automated","mode":"test","event":"visit_time","visit_id":"synthetic-visit","payload":{"chapter_id":"chapter_4","level_id":"fields","kind":"foreground","duration_ms":1234}})
		transport.flush()
		for frame: int in range(800):
			if transport.queue.is_empty(): break
			await create_timer(0.02).timeout
		if not transport.queue.is_empty(): push_error("Duplicate not acknowledged"); quit(1); return
		transport.set_enabled(false)
		transport._on_event({"event":"player_action","session_id":"synthetic-network-session","sequence":99})
		if not transport.queue.is_empty(): push_error("Withdrawal still enqueued telemetry"); quit(1); return
		transport.send_feedback({"session_id":"synthetic-network-session","sequence":2,"source":"automated","mode":"test","event":"level_feedback","payload":{"chapter_id":"chapter_4","level_id":"fields","note":"synthetic local integration only","fun":4,"clarity":null,"revision":1}})
		for frame: int in range(800):
			if transport.queue.is_empty(): break
			await create_timer(0.02).timeout
		if not transport.queue.is_empty(): push_error("Explicit feedback not acknowledged"); quit(1); return
	print("PASS: actual HTTP acknowledgement, recovered queue, duplicate and explicit feedback")
	quit(0)
