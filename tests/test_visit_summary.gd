extends SceneTree
const Summary = preload("res://src/playtest/visit_summary.gd")
const Transport = preload("res://src/playtest/remote_feedback.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func run() -> void:
	var reducer := Summary.new()
	var rows: Array[Dictionary] = [
		{"event":"level_start"},
		{"event":"visit_time","payload":{"kind":"foreground","duration_ms":1234}},
		{"event":"visit_time","payload":{"kind":"background","duration_ms":456}},
		{"event":"modification","payload":{"operation":"branch","added_wires":3,"removed_wires":1}},
		{"event":"modification","payload":{"operation":"delete_component","removed_components":1,"incident_wire_removals":2}},
		{"event":"modification","payload":{"operation":"disconnect","explicit_wire_deletes":1}},
		{"event":"player_action","payload":{"action":"connection_rejected"}},
		{"event":"player_action","payload":{"action":"undo"}},
		{"event":"player_action","payload":{"action":"debug_run"}},
		{"event":"official_run","payload":{"cycles":81}},
		{"event":"case_outcome"},{"event":"case_outcome"},
		{"event":"hint_used","payload":{"stage":2}},
		{"event":"level_complete"}]
	for row: Dictionary in rows:
		row.visit_id="synthetic-visit"; reducer.observe(row)
	var summary: Dictionary = reducer.observe({"event":"level_exit","visit_id":"synthetic-visit"})
	check(summary.connections==1 and summary.branches==1 and summary.wire_deletes==1,"Branch is one connection, no explicit delete.")
	check(summary.component_deletes==1 and summary.incident_wire_removals==2,"Component and incident edges separated.")
	check(summary.debug_runs==1 and summary.official_runs==1,"Official cases are not debug runs.")
	check(summary.foreground_ms==1234 and summary.background_ms==456 and summary.max_hint_stage==2 and summary.completed,"Time, hint, completion reduced.")
	var transport := Transport.new(); transport.state_path="user://summary_contract.json"; root.add_child(transport)
	transport.endpoint="http://127.0.0.1:8765/v1"; transport.set_process(false); transport.queue.clear()
	transport.set_sharing_mode("basic")
	transport._on_event({"event":"visit_summary","visit_id":"old-visit","payload":summary})
	check(transport.queue.is_empty(),"No pre-consent summary backfill.")
	transport._on_event({"event":"level_start","visit_id":"new-visit"})
	transport._on_event({"event":"modification","visit_id":"new-visit"})
	check(transport.queue.is_empty(),"Basic mode excludes granular records.")
	transport._on_event({"event":"visit_summary","session_id":"synthetic","sequence":12,"visit_id":"new-visit","payload":summary})
	check(transport.queue.size()==1 and transport.queue[0].record.payload.foreground_ms==1234,"Basic summary queued with counters.")
	check(transport.api_url("events")=="http://127.0.0.1:8765/v1/events","Versioned root not doubled.")
	transport.set_sharing_mode("local"); check(transport.queue.is_empty(),"Withdrawal clears pending summaries.")
	transport.queue_free(); await process_frame
	if failures.is_empty(): print("PASS: semantic visit summaries and basic sharing boundaries")
	else:
		for message: String in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
