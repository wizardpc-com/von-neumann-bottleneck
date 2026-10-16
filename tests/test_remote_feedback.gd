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
	check(Transport.NOTICE_VERSION=="2026-10-17","The public privacy notice requires renewed consent.")
	ProjectSettings.set_setting("application/feedback_privacy_url","https://privacy.example.test/privacy.html")
	check(transport.privacy_url()=="https://privacy.example.test/privacy.html","An explicitly configured HTTPS privacy page is available to both UIs.")
	ProjectSettings.set_setting("application/feedback_privacy_url","https://privacy.example.test:443/privacy.html")
	check(transport.privacy_url()=="https://privacy.example.test:443/privacy.html","An explicit default HTTPS port keeps the privacy link visible.")
	for invalid: String in ["", "http://privacy.example.test/privacy.html", "https://", "https://name@privacy.example.test/privacy.html", "https://privacy.example.test:8443/privacy.html", "https://privacy.example.test/privacy%20notice", "https://privacy.example.test/privacy.html?token=1", "https://pri vacy.example.test/privacy.html"]:
		ProjectSettings.set_setting("application/feedback_privacy_url",invalid)
		check(transport.privacy_url().is_empty(),"Missing, insecure or malformed privacy URL stays hidden: "+invalid)
	ProjectSettings.set_setting("application/feedback_privacy_url","")
	var legacy := Transport.new(); legacy.state_path="user://remote_old_notice_"+str(Time.get_ticks_usec())+".json"; legacy.endpoint=transport.endpoint
	var old_state: Dictionary = {"schema_version":2,"notice_version":"2026-09-11","consented_endpoint":legacy.endpoint,"sharing_mode":"basic","enabled":true,"scores_enabled":true,"client_id":"a".repeat(32),"deletion_token":"b".repeat(64),"deletion_pending":true,"queue":[{"record":{"event_id":"c".repeat(64),"kind":"feedback","payload":{"note":"old consent"}},"destination":legacy.endpoint}]}
	var old_file := FileAccess.open(legacy.state_path,FileAccess.WRITE)
	old_file.store_string(JSON.stringify(old_state)); old_file.close()
	root.add_child(legacy); legacy.set_process(false); legacy.endpoint=transport.endpoint; legacy._load_state()
	check(not legacy.enabled and legacy.sharing_mode=="local" and not legacy.scores_enabled and legacy.queue.is_empty(),"An older notice revokes automatic, score and queued upload consent.")
	check(legacy.client_id==old_state.client_id and legacy.deletion_token==old_state.deletion_token and legacy.deletion_pending,"Notice renewal preserves the deletion identity and pending request.")
	var event: Dictionary = {"session_id":"synthetic-session","sequence":1,"source":"automated","mode":"test","event":"player_action","payload":{"chapter_id":"chapter_4","level_id":"fields","action":"layout_edit","note":"secret opinion","program_source":"secret program","design_name":"secret name","added_wires":2}}
	var reloaded_event: Dictionary = JSON.parse_string(JSON.stringify(event))
	check(Transport.feedback_id(event)==Transport.feedback_id(reloaded_event),"Persisted JSON numeric representation retains the exact opinion receipt ID.")
	transport._on_event(event)
	check(transport.queue.is_empty(),"Default off must enqueue no events.")
	check(transport.set_enabled(true),"Local receiver can be consented.")
	transport._on_event(event)
	check(transport.queue.size()==1,"Only future event added after consent.")
	var payload: Dictionary = transport.queue[0].record.payload
	check(not payload.has("note") and not payload.has("program_source") and not payload.has("design_name"),"Automatic allowlist excludes freeform and circuits.")
	check(payload.added_wires==2,"Actual numeric counters retained.")
	var timing: Dictionary = Transport.minimal_context({"event":"visit_time","sequence":12,"payload":{"kind":"foreground","duration_ms":1234,"duration_unknown":false}})
	check(timing.kind=="foreground" and timing.duration_ms==1234 and timing.sequence==12 and not timing.duration_unknown,"Remote timing keeps duration category and ordering; missing category cannot be reported as zero time.")
	var hint: Dictionary = Transport.minimal_context({"event":"hint_action","payload":{"phase":"reveal","stage":2,"program_source":"excluded"}})
	check(hint.stage==2 and hint.phase=="reveal" and not hint.has("program_source"),"Hint metadata survives without source disclosure.")
	var restored := Transport.new(); restored.state_path=transport.state_path; restored.endpoint="https://another.invalid"
	restored._load_state()
	check(not restored.enabled,"Endpoint change requires new consent.")
	transport.set_enabled(false)
	check(transport.queue.is_empty(),"Withdrawal cancels pending automatic records.")
	transport.queue.clear()
	for index: int in range(256):
		transport.queue.append({"record":{"event_id":str(index).sha256_text(),"kind":"event","payload":{"event":"player_action"}},"attempts":0,"next_at":0,"paused":false,"destination":transport.endpoint})
	check(transport._enqueue({"event_id":"opinion".sha256_text(),"kind":"feedback","payload":{}}),"Explicit opinion displaces low-priority telemetry in a full queue.")
	check(transport.queue.size()==256 and transport.evicted_records==1,"Queue remains bounded and eviction is counted.")
	var retry_id: String=transport.queue[0].record.event_id
	for attempt: int in range(12):
		transport.inflight.assign([retry_id]);transport._retry(false,"offline")
	check(not transport.queue[0].paused and transport.queue[0].next_at>Time.get_unix_time_from_system(),"Long outage still retries with bounded delay after eight failures.")
	transport.inflight.assign([retry_id,transport.queue[1].record.event_id]);transport._retry(true,"http_400")
	check(not transport.queue[0].paused and transport.queue[0].isolate,"Rejected batch is split to isolate the bad record.")
	transport.inflight.assign([retry_id]);transport._retry(true,"http_400")
	check(transport.queue[0].paused and not transport.queue[1].paused,"Only a individually rejected record is paused.")
	transport.queue.clear()
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
	store.end_session(); store.free(); restored.free(); legacy.queue_free(); transport.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: optional transport, privacy, consent and feedback revisions")
	else:
		for error: String in failures: push_error(error)
	quit(0 if failures.is_empty() else 1)
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
