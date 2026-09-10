extends SceneTree
const Transport = preload("res://src/playtest/remote_feedback.gd")
const Store = preload("res://src/playtest/playtest_data.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func run() -> void:
	var transport := Transport.new()
	transport.state_path="user://remote_contract_"+str(Time.get_ticks_usec())+".json"
	root.add_child(transport)
	transport.endpoint="http://127.0.0.1:8765"
	transport.set_process(false)
	var event: Dictionary = {"session_id":"synthetic-session","sequence":1,"source":"automated","mode":"test","event":"player_action","payload":{"chapter_id":"chapter_4","level_id":"fields","action":"layout_edit","note":"secret opinion","program_source":"secret program","design_name":"secret name","added_wires":2}}
	transport._on_event(event)
	check(transport.queue.is_empty(),"Default off must enqueue no events.")
	check(transport.set_enabled(true),"Local receiver can be consented.")
	transport._on_event(event)
	check(transport.queue.size()==1,"Only future event added after consent.")
	var payload: Dictionary = transport.queue[0].record.payload
	check(not payload.has("note") and not payload.has("program_source") and not payload.has("design_name"),"Automatic allowlist excludes freeform and circuits.")
	check(payload.added_wires==2,"Actual numeric counters retained.")
	var restored := Transport.new(); restored.state_path=transport.state_path; restored.endpoint="https://another.invalid"
	restored._load_state()
	check(not restored.enabled,"Endpoint change requires new consent.")
	transport.set_enabled(false)
	check(transport.queue.is_empty(),"Withdrawal cancels pending automatic records.")
	var store := Store.new(); store.configure_for_storage("user://rating_contract_"+str(Time.get_ticks_usec())); store.start_session()
	store.telemetry_enabled=false
	store.level_started(&"chapter_4",&"fields")
	check(store.submit_level_feedback(&"chapter_4",&"fields",0,4,0,"first"),"Unfinished feedback independent from telemetry.")
	var first: Dictionary = store.latest_level_feedback("chapter_4","fields")
	check(store.submit_level_feedback(&"chapter_4",&"fields",5,0,0,"revision"),"Revision saved.")
	var second: Dictionary = store.latest_level_feedback("chapter_4","fields")
	check(first.visit_id==second.visit_id and int(second.payload.revision)==2 and second.payload.clarity==null,"Same visit revisions and missing ratings kept accurately.")
	store.submit_level_feedback(&"chapter_4",&"mixed",0,0,0,"map feedback")
	check(store.latest_level_feedback("chapter_4","mixed").visit_id=="","Different task never borrows active visit.")
	store.end_session(); store.free(); restored.free(); transport.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: optional transport, privacy, consent and feedback revisions")
	else:
		for error: String in failures: push_error(error)
	quit(0 if failures.is_empty() else 1)
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
