extends SceneTree
const Transport = preload("res://src/playtest/remote_feedback.gd")
const Store = preload("res://src/playtest/playtest_data.gd")
class OfflineRetryProbe extends Transport:
	var flushes := 0
	func flush() -> void:
		flushes+=1

class AutostartStore extends Store:
	func _command_line_arguments() -> PackedStringArray:
		return PackedStringArray(["--capture-fixture","--enable-playtest-telemetry","--enable-playtest-feedback"])

var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func run() -> void:
	check_autostart_and_visit_consent()
	check_outbox_restart()
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
	ProjectSettings.set_setting("application/feedback_privacy_url","https://feedback.yanruiqing.com:8443/privacy.html")
	check(transport.privacy_url()=="https://feedback.yanruiqing.com:8443/privacy.html","The dedicated VNB Test Edition privacy link supports port 8443.")
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

func check_autostart_and_visit_consent() -> void:
	var dir := "user://feedback_autostart_"+str(Time.get_ticks_usec())
	var original_batch: Variant = ProjectSettings.get_setting("application/feedback_source_batch")
	ProjectSettings.set_setting("application/feedback_source_batch","new-test-batch")
	var capture := AutostartStore.new()
	capture.configure_for_storage(dir,&"test")
	var remote := OfflineRetryProbe.new()
	remote.state_path = dir.path_join("outbox.json")
	remote.endpoint = "https://receiver.invalid"
	remote._load_state()
	capture.event_appended.connect(remote._on_event)
	root.add_child(capture)
	check(not capture.session_id().is_empty() and capture._events.front().event == "session_start", "The actual ready path creates a session without a manual start.")
	check(capture._automated_launch(PackedStringArray(["--capture-fixture"]),false) and not capture._automated_launch(PackedStringArray(),false), "A rendered capture cannot be attributed to an external player.")
	check(capture._launch_source(PackedStringArray(["--capture-fixture","--playtest-source=agent_native"]),false)=="agent_native" and capture._launch_source(PackedStringArray(["--capture-fixture","--playtest-source=external_player"]),false)=="automated","Rendered capture keeps explicit native QA attribution and cannot claim external player.")
	capture.level_started(&"chapter_4",&"fields")
	capture.record_hint(&"chapter_4",&"fields",3)
	check(remote.queue.is_empty(),"Startup and the first visit before consent stay local.")
	remote.source_batch = "old-test-batch"
	check(remote.set_sharing_mode("detailed"),"A mid-visit detailed choice can be persisted.")
	capture.record_hint(&"chapter_4",&"fields",1)
	capture.level_exited(&"chapter_4",&"fields")
	var detailed: Array = remote.queue.map(func(item: Dictionary) -> String: return item.record.payload.event)
	check("hint_used" in detailed and "visit_summary" not in detailed and "visit_time" not in detailed,"Detailed opt-in sends new actions without the existing visit's pre-consent aggregates or intervals.")
	check(remote.set_sharing_mode("basic"),"Basic starts a fresh observation boundary.")
	capture.level_started(&"chapter_4",&"fields")
	capture.record_hint(&"chapter_4",&"fields",2)
	capture.level_exited(&"chapter_4",&"fields")
	check(remote.queue.size()==1,"An eligible basic visit automatically queues one reduced summary.")
	if remote.queue.size()==1:
		var record: Dictionary = remote.queue.front().record
		check(record.payload.event=="visit_summary" and record.payload.max_hint_stage==2 and record.payload.mode=="test" and record.payload.source=="automated" and record.payload.source_batch=="new-test-batch","Autostart retains separate source, edition, current build batch and real counters.")
		var receipt_id := "existing-opinion".sha256_text()
		remote.receipts[receipt_id]=1
		remote.inflight.assign([str(record.event_id)])
		remote._response(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"ack":[record.event_id]}).to_utf8_buffer())
		check(remote.feedback_state(receipt_id)=="sent" and not remote.receipts.has(record.event_id),"Background statistics never consume opinion receipt history.")
	capture.end_session()
	capture.free()
	remote.free()
	ProjectSettings.set_setting("application/feedback_source_batch",original_batch)

func check_outbox_restart() -> void:
	# Outside the tree these transports have no HTTPRequest. Stop before any ACK.
	var writer := Transport.new()
	writer.state_path="user://remote_restart_contract_"+str(Time.get_ticks_usec())+".json"
	writer.endpoint="https://receiver.invalid"
	writer._load_state()
	var event := {"session_id":"restart-contract","sequence":7,"payload":{"note":"synthetic opinion"}}
	var id := writer.send_feedback(event)
	var original_client := writer.client_id
	var original_token := writer.deletion_token
	var path := writer.state_path
	writer.free()

	var reader := Transport.new()
	reader.state_path=path
	reader.endpoint="https://receiver.invalid"
	reader._load_state()
	check(not id.is_empty() and reader.feedback_state(id)=="pending","An unacknowledged opinion survives restart with its original ID.")
	check(reader.client_id==original_client and reader.deletion_token==original_token,"Restart keeps the deletion identity for the pending opinion.")
	check(reader.send_feedback(event)==id and reader.queue.size()==1 and not reader.enabled and not reader.scores_enabled,"Repeated explicit Send reuses the pending opinion without enabling other sharing.")
	reader.free()
	check_manual_retry(path,id)

	var saved := FileAccess.get_file_as_string(path)
	var future: Variant = JSON.parse_string(saved)
	if not future is Dictionary:
		check(false,"The queued opinion fixture must have a readable outbox before interruption.")
		return
	future.schema_version=3
	for contents: String in [saved.left(saved.length()-1), JSON.stringify(future)]:
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(contents)
		file.close()
		var before := FileAccess.get_file_as_bytes(path)
		var blocked := Transport.new()
		blocked.state_path=path
		root.add_child(blocked)
		blocked.set_process(false)
		check(blocked.status=="storage_error" and blocked.client_id.is_empty() and blocked.deletion_token.is_empty(),"An unreadable or future outbox cannot acquire a replacement identity.")
		var updates: Array[String] = []
		blocked.status_changed.connect(func() -> void: updates.append(blocked.status))
		check(not blocked.set_enabled(true) and not blocked.set_scores_enabled(true),"Read-only settings decline both consent changes.")
		blocked.endpoint="" # Keep the retry path offline even if the guard regresses.
		blocked.retry_pending()
		check(updates==["storage_error","storage_error","storage_error"] and blocked.feedback_state(id)=="storage_error","Read-only choices and Retry refresh the UI with the storage error.")
		check(not blocked._save_state() and FileAccess.get_file_as_bytes(path)==before,"Retry and explicit save preserve every original outbox byte.")
		root.remove_child(blocked)
		blocked.free()
		check(FileAccess.get_file_as_bytes(path)==before,"Tree exit preserves the queued opinion, identity and all recoverable bytes.")

func check_manual_retry(path: String, id: String) -> void:
	var probe := OfflineRetryProbe.new()
	probe.endpoint="https://receiver.invalid"
	probe.state_path=path
	probe._load_state()
	if probe.queue.size()!=1:
		check(false,"Manual Retry requires one persisted explicit opinion.")
		probe.free()
		return
	probe.queue[0]["isolate"]=true
	probe.inflight.assign([id])
	probe._retry(true,"http_422")
	var rejected: Array[Dictionary] = probe.queue.duplicate(true)
	var before := FileAccess.get_file_as_bytes(path)
	var updates: Array[String] = []
	probe.status_changed.connect(func() -> void: updates.append(probe.status+"/"+probe.feedback_state(id)))

	probe.endpoint=""
	probe.retry_pending()
	check(updates==["not_configured/rejected"] and probe.flushes==0 and probe.queue==rejected,"An unconfigured receiver leaves the rejection intact.")
	probe.endpoint="https://receiver.invalid"
	probe.state_path=path.path_join("unwritable.json") # The parent is the existing outbox file.
	probe.retry_pending()
	check(updates.back()=="storage_error/rejected" and probe.flushes==0 and probe.queue==rejected,"A failed Retry save restores the rejection before notifying the UI and never flushes.")
	check(not probe.set_scores_enabled(true) and not probe.scores_enabled and FileAccess.get_file_as_bytes(path)==before,"A failed score opt-in stays off and preserves the saved outbox.")
	probe.state_path=path
	probe.retry_pending()
	check(updates.back()=="pending/pending" and probe.flushes==1 and probe.last_error.is_empty(),"A saved manual retry publishes pending and releases the opinion for sending.")
	var persisted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(persisted.queue.size()==1 and persisted.queue[0].get("permanent")==false and persisted.queue[0].get("paused")==false,"Both flags are released in the saved outbox before restart.")
	probe.free()

	var restarted := Transport.new()
	restarted.endpoint="https://receiver.invalid"
	restarted.state_path=path
	restarted._load_state()
	check(restarted.queue.size()==1 and restarted.feedback_state(id)=="pending" and not restarted.enabled and not restarted.scores_enabled,"Restart before ACK retains the same pending opinion with automatic sharing off.")
	if restarted.queue.size()==1:
		var row := restarted.queue[0]
		check(not row.paused and not row.permanent and row.attempts==0 and row.next_at==0 and row.isolate and restarted.rejected_records==1,"Retry clears both rejection flags and backoff while retaining batch isolation and rejection history.")
	restarted.free()

	# Reconstruct the previous writer's exact reset alongside a genuine rejection.
	var legacy: Dictionary = JSON.parse_string(before.get_string_from_utf8())
	var reset: Dictionary = legacy.queue[0].duplicate(true)
	reset.paused=false
	reset.next_at=0
	reset.attempts=0
	reset.record.event_id="legacy-retry".sha256_text()
	legacy.queue.append(reset)
	var fixture := FileAccess.open(path,FileAccess.WRITE)
	fixture.store_string(JSON.stringify(legacy))
	fixture.close()
	var migrated := Transport.new()
	migrated.endpoint="https://receiver.invalid"
	migrated.state_path=path
	migrated._load_state()
	check(migrated.queue.size()==2 and migrated.feedback_state(reset.record.event_id)=="pending" and not migrated.queue[1].paused and migrated.queue[1].isolate and migrated.feedback_state(id)=="rejected" and migrated.queue[0].paused,"Old manual retry intent resumes while an independently rejected opinion stays paused.")
	for kind: String in ["event","score"]:
		var disabled: Dictionary = rejected[0].duplicate(true)
		disabled.record.kind=kind
		disabled.record.event_id=kind.sha256_text()
		migrated.queue.append(disabled)
	migrated.retry_pending()
	check(migrated.feedback_state(id)=="pending" and migrated.feedback_state("event".sha256_text())=="rejected" and migrated.feedback_state("score".sha256_text())=="rejected","Retry in local-only mode releases the explicit opinion and leaves disabled channels paused.")
	migrated.free()

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
