extends Node
## Optional upload transport; never participates in game or simulation state.
signal status_changed
const STATE_PATH: String = "user://feedback_outbox_v1.json"
const NOTICE_VERSION: String = "2026-10-17"
const CONSENT_VERSION: String = "sharing-2"
const SUMMARY = preload("res://src/playtest/visit_summary.gd")
const MAX_QUEUE: int = 256
const MAX_DISK_BYTES: int = 524288
const MAX_BATCH: int = 32
const FLUSH_SECONDS: float = 45
const TEXT_FIELDS := ["kind","phase","target","case_id","tool_id","origin","program_digest","chapter_id","level_id","visit_id","session_id","source","mode","build_version","source_commit","test_batch","task_version","case_set_version","model_version","event","action","operation","result_class","reason","strategy","recipe_digest","run_id","privacy_notice_version","consent_version","consent_timestamp","source_batch","background_cohort","sharing_mode","ruleset_version"]
const NUMBER_FIELDS := ["stage","sequence","duration_ms","cycles","cost","case_count","passed_cases","total_cases","added_wires","removed_wires","added_components","removed_components","explicit_wire_deletes","incident_wire_removals","total_cycles","prepare_cycles","query_cycles","output_cycles","ram_read_bytes","ram_write_bytes","peak_extra_bytes","required_extra_bytes","requests","fills","hits","evictions","batch","group_count","block","copy_field_count"]
const BOOL_FIELDS := ["duration_unknown","eligible","passed","correct","target_met","post_completion","budget_met","completed","completed_on_entry","completed_during_visit"]
var endpoint: String = ""
var enabled: bool = false
var consented_endpoint: String = ""
var sharing_mode: String = "local"
var consent_timestamp: String = ""
var source_batch: String = ""
var background_cohort: String = "unspecified"
var scores_enabled: bool = false
var identity_deleted: bool = false
var eligible_visits: Dictionary = {}
var deletion_pending: bool = false
var deleting: bool = false
var client_id: String = ""
var deletion_token: String = ""
var queue: Array[Dictionary] = []
var evicted_records: int = 0
var rejected_records: int = 0
var receipts: Dictionary = {}
var status: String = "local_only"
var last_error: String = ""
var elapsed: float = 0
var request: HTTPRequest
var inflight: Array[String] = []
var state_path: String = STATE_PATH
var _outbox_read_only: bool = false
var _withdrawal_unsaved: bool = false

func _ready() -> void:
	endpoint=str(ProjectSettings.get_setting("application/feedback_endpoint",""))
	_load_state()
	request=HTTPRequest.new(); request.timeout=8; request.body_size_limit=131072
	add_child(request); request.request_completed.connect(_response)
	get_node("/root/PlaytestData").event_appended.connect(_on_event)
func endpoint_allowed() -> bool:
	if endpoint.is_empty() or endpoint.contains("?") or endpoint.contains("#") or endpoint.contains("@") or endpoint.ends_with("/"): return false
	if endpoint.begins_with("https://"): return true
	# Cleartext is only for this approved local integration path.
	return endpoint.begins_with("http://127.0.0.1:") or endpoint.begins_with("http://localhost:")

func is_public_game() -> bool:
	return ProjectSettings.get_setting("application/public_game_feedback", false) == true

func is_public_test() -> bool:
	return ProjectSettings.get_setting("application/public_test_feedback", false) == true

func is_public_release() -> bool:
	return is_public_game() or is_public_test()

func community_available() -> bool:
	return endpoint_allowed() and ProjectSettings.get_setting("application/community_feedback_enabled", not is_public_release()) == true

func privacy_url() -> String:
	var url: String = str(ProjectSettings.get_setting("application/feedback_privacy_url",""))
	if url == "https://feedback.yanruiqing.com:8443/privacy.html": return url
	if url == "https://feedback.yanruiqing.com:8443/privacy-player.html": return url
	if url.length() > 2048: return ""
	var pattern := RegEx.new()
	if pattern.compile("^https://[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+(?::443)?(?:/[A-Za-z0-9._~/-]*)?$") != OK: return ""
	return url if pattern.search(url) != null else ""
func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed>=FLUSH_SECONDS:
		elapsed=0
		flush()
func api_url(resource: String) -> String:
	return endpoint+("" if endpoint.ends_with("/v1") else "/v1")+"/"+resource
func set_enabled(value: bool) -> bool:
	# Compatibility for internal callers: explicit old detailed choice remains detailed.
	return set_sharing_mode("detailed" if value else "local")
func set_sharing_mode(value: String) -> bool:
	if _outbox_read_only or _withdrawal_unsaved or deletion_pending:
		status_changed.emit()
		return false
	if value not in ["local","basic","detailed"]: return false
	if value==sharing_mode and consented_endpoint==endpoint: return _save_state()
	if value != "local" and not endpoint_allowed(): status="not_configured"; status_changed.emit(); return false
	if not inflight.is_empty() and request != null: request.cancel_request(); inflight.clear()
	var retained: Array[Dictionary] = []
	for item: Dictionary in queue:
		if item.record.kind != "event": retained.append(item)
	queue=retained
	eligible_visits.clear()
	sharing_mode=value; enabled=value!="local"
	if enabled: _consent()
	status="pending" if not queue.is_empty() else "ready" if enabled else "local_only"
	var saved: bool = _save_state()
	if not saved: enabled=false; sharing_mode="local"
	status_changed.emit()
	return saved
func _consent() -> void:
	if identity_deleted:
		client_id=Crypto.new().generate_random_bytes(16).hex_encode()
		deletion_token=Crypto.new().generate_random_bytes(32).hex_encode()
		identity_deleted=false
	consented_endpoint=endpoint
	consent_timestamp=Time.get_datetime_string_from_system(true)+"Z"
	if source_batch.is_empty(): source_batch=str(ProjectSettings.get_setting("application/feedback_source_batch","free-alpha")).left(64)
func set_scores_enabled(value: bool) -> bool:
	if _outbox_read_only or _withdrawal_unsaved or deletion_pending:
		status_changed.emit()
		return false
	if value and not community_available(): return false
	scores_enabled=value
	if value: _consent()
	else:
		if request != null: request.cancel_request(); inflight.clear()
		var retained: Array[Dictionary] = []
		for item: Dictionary in queue:
			if item.record.kind != "score": retained.append(item)
		queue=retained
	var saved := _save_state()
	if not saved: scores_enabled=false
	status_changed.emit()
	return saved
func consent_metadata() -> Dictionary:
	return {"privacy_notice_version":NOTICE_VERSION,"consent_version":CONSENT_VERSION,"consent_timestamp":consent_timestamp,"source_batch":source_batch,"background_cohort":background_cohort,"sharing_mode":sharing_mode}
func _attach_consent(payload: Dictionary) -> void:
	var batch: String = str(payload.get("source_batch", source_batch))
	# Earlier public builds used the package test_batch as their source batch.
	if not payload.has("source_batch") and is_public_release() and payload.has("test_batch"):
		batch = str(payload.test_batch)
	payload.merge(consent_metadata(),true)
	payload.source_batch = batch

func _on_event(event: Dictionary) -> void:
	if not enabled or consented_endpoint!=endpoint or not endpoint_allowed(): return
	var kind: String = str(event.get("event",""))
	var visit: String = str(event.get("visit_id",""))
	if kind == "level_start": eligible_visits[visit]=true
	# These span a time interval or reduce earlier actions. A mid-visit opt-in
	# permits future detailed actions, but cannot authorize the preceding interval.
	if kind in ["visit_time","visit_summary"] and not eligible_visits.has(visit): return
	if sharing_mode == "basic":
		if kind not in ["visit_summary","level_complete","moment"]: return
		# Starting mid-visit never backfills pre-consent actions in a later summary.
		if not eligible_visits.has(visit): return
	else:
		if kind not in ["map_action","hint_used","tool_opened","level_start","level_exit","level_complete","visit_time","official_run","case_outcome","modification","player_action","hint_action","trace_action","visit_summary","moment"]: return
	var payload: Dictionary = minimal_context(event)
	_attach_consent(payload)
	_enqueue({"event_id":(str(event.get("session_id",""))+":"+str(event.get("sequence",0))).sha256_text(),"kind":"event","payload":payload})
	if kind == "visit_summary": eligible_visits.erase(visit)
static func minimal_context(event: Dictionary) -> Dictionary:
	var merged: Dictionary = event.duplicate(true)
	merged.merge(event.get("payload",{}),true)
	if merged.get("metrics") is Dictionary: merged.merge(merged.metrics,true)
	var result: Dictionary = {}
	for key: String in TEXT_FIELDS:
		if merged.get(key) is String: result[key]=String(merged[key]).left(64 if key in ["chapter_id","level_id","action","operation","result_class","reason","strategy","recipe_digest"] else 100 if key in ["visit_id","session_id","run_id"] else 80)
	for key: String in NUMBER_FIELDS+SUMMARY.COUNTERS:
		var value: Variant = merged.get(key)
		if (value is int or value is float) and is_finite(float(value)) and float(value)>=0 and float(value)<=1e10: result[key]=int(value)
	for key: String in BOOL_FIELDS:
		if merged.get(key) is bool: result[key]=merged[key]
	return result
func send_feedback(event: Dictionary) -> String:
	if _outbox_read_only or _withdrawal_unsaved or deletion_pending: return ""
	if not endpoint_allowed(): status="not_configured"; status_changed.emit(); return ""
	_consent() # This individual Send is opinion consent, independent of statistics.
	var payload: Dictionary = minimal_context(event)
	_attach_consent(payload)
	payload.sharing_mode="opinion"
	var original: Dictionary = event.get("payload",{})
	payload["note"]=str(original.get("note","")).left(240)
	for key: String in ["fun","clarity","want_to_continue"]:
		var value: Variant = original.get(key)
		payload[key]=int(value) if (value is int or value is float) and int(value) in range(1,6) else null
	var category: String = str(original.get("category",""))
	if category in preload("res://src/playtest/task_identity.gd").CATEGORIES: payload["category"]=category
	payload["revision"]=int(original.get("revision",1))
	var id: String = feedback_id(event)
	if receipts.has(id): status="sent"; status_changed.emit(); return id
	for item: Dictionary in queue:
		if item.record.event_id == id: return id
	if not _enqueue({"event_id":id,"kind":"feedback","payload":payload}): return ""
	flush()
	return id
func _priority(record: Dictionary) -> int:
	if record.get("kind") in ["feedback", "score"]: return 3
	if record.get("payload",{}).get("event") in ["visit_summary", "level_complete", "moment"]: return 2
	return 0

func _enqueue(record: Dictionary) -> bool:
	var previous: Array[Dictionary] = queue.duplicate(true)
	var old_evicted: int = evicted_records
	var priority: int = _priority(record)
	# Reserve room for opinions and visit totals while offline. Never evict in-flight work.
	var limit: int = MAX_QUEUE-32 if priority==0 else MAX_QUEUE
	if queue.size()>=limit:
		var victim: int = -1
		for index: int in range(queue.size()):
			if _priority(queue[index].record)<priority and not inflight.has(str(queue[index].record.event_id)):
				victim=index; break
		if victim<0: status="queue_full"; status_changed.emit(); return false
		queue.remove_at(victim); evicted_records+=1
	var item: Dictionary = {"record":record,"attempts":0,"next_at":0,"paused":false,"destination":endpoint}
	queue.append(item)
	if not _save_state():
		queue=previous; evicted_records=old_evicted; return false
	status="pending"; status_changed.emit()
	if queue.size()%MAX_BATCH==0: call_deferred("flush")
	return true
func _can_send_item(item: Dictionary) -> bool:
	if item.get("destination","")!=endpoint: return false
	match item.record.kind:
		"event": return enabled and consented_endpoint==endpoint
		"score": return scores_enabled and consented_endpoint==endpoint and community_available()
		"feedback": return true # Explicit Send is independent of automatic sharing.
	return false

func flush() -> void:
	if _outbox_read_only: return
	if _withdrawal_unsaved or deletion_pending:
		_resume_deletion()
		return
	if request == null or deleting or not inflight.is_empty() or not endpoint_allowed(): return
	var records: Array[Dictionary] = []
	var now: int = int(Time.get_unix_time_from_system())
	for item: Dictionary in queue:
		if not _can_send_item(item): continue
		if item.paused or int(item.next_at)>now: continue
		if item.get("isolate",false) and not records.is_empty(): continue
		records.append(item.record); inflight.append(item.record.event_id)
		if records.size()>=(1 if item.get("isolate",false) else MAX_BATCH): break
	if records.is_empty(): return
	var body: String = JSON.stringify({"client_id":client_id,"deletion_token":deletion_token,"records":records})
	if body.to_utf8_buffer().size()>131072: _retry(true,"body_limit"); return
	var error: Error = request.request(api_url("events"),["Content-Type: application/json"],HTTPClient.METHOD_POST,body)
	if error!=OK: _retry(false,"request_error")
	else: status="sending"; status_changed.emit()
func _response(result: int, code: int, _headers: PackedStringArray, bytes: PackedByteArray) -> void:
	if deleting:
		deleting=false
		var deletion: Variant = null
		if result==HTTPRequest.RESULT_SUCCESS and code==200 and not bytes.is_empty():
			deletion=JSON.parse_string(bytes.get_string_from_utf8())
		status="deleted" if deletion is Dictionary and deletion.get("deleted")==true else "delete_failed"
		if status=="deleted":
			identity_deleted=true
			deletion_pending=false
			if not _save_state():
				# Disk still holds the original identity and durable DELETE.
				identity_deleted=false
				deletion_pending=true
		status_changed.emit(); return
	if inflight.is_empty(): return
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200:
		_retry(code in [400,401,403,404,409,410,413,422],"http_"+str(code) if result==HTTPRequest.RESULT_SUCCESS else "offline")
		return
	var body: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not body is Dictionary or not body.get("ack") is Array:
		_retry(false,"invalid_ack"); return
	for id: String in inflight:
		if not body.ack.has(id): _retry(false,"incomplete_ack"); return
	var retained: Array[Dictionary] = []
	for item: Dictionary in queue:
		if inflight.has(str(item.record.event_id)):
			if item.record.kind != "event": receipts[item.record.event_id]=int(Time.get_unix_time_from_system())
		else: retained.append(item)
	queue=retained; inflight.clear()
	while receipts.size()>64: receipts.erase(receipts.keys()[0])
	status="sent"; last_error=""; _save_state(); status_changed.emit()
func _retry(permanent: bool, reason: String) -> void:
	var split_batch: bool = permanent and inflight.size()>1
	for item: Dictionary in queue:
		if inflight.has(str(item.record.event_id)):
			item.attempts=mini(1000,int(item.attempts)+1)
			item.paused=permanent and not split_batch
			item["permanent"]=item.paused
			if split_batch: item["isolate"]=true
			if item.paused: rejected_records+=1
			# Bounded exponential delay plus jitter continues across long outages.
			var delay: int = mini(900,int(pow(2,mini(10,int(item.attempts)))))
			item.next_at=int(Time.get_unix_time_from_system())+delay+randi_range(0,maxi(1,delay/5))
	inflight.clear(); status="rejected" if permanent and not split_batch else "failed_retryable"; last_error=reason
	_save_state(); status_changed.emit()
func retry_pending() -> void:
	if _outbox_read_only:
		status_changed.emit()
		return
	if not endpoint_allowed():
		status="not_configured"
		status_changed.emit()
		return
	if _withdrawal_unsaved or deletion_pending or deleting:
		flush()
		return
	var resumed_queue: Array[Dictionary] = queue.duplicate()
	var changed := false
	for index: int in range(queue.size()):
		var item := queue[index]
		if not _can_send_item(item) or inflight.has(item.record.event_id): continue
		if not item.paused and int(item.attempts)==0 and int(item.next_at)==0: continue
		var resumed := item.duplicate()
		resumed.paused=false
		resumed["permanent"]=false
		resumed.next_at=0
		resumed.attempts=0
		resumed_queue[index]=resumed
		changed=true
	if changed:
		var previous: Array[Dictionary] = queue
		queue=resumed_queue
		if not _save_state():
			queue=previous
			status_changed.emit()
			return
		status="pending" if inflight.is_empty() else "sending"
		last_error=""
		status_changed.emit()
	flush()
func _save_state() -> bool:
	if _outbox_read_only: return false
	var body: String = JSON.stringify({"schema_version":2,"notice_version":NOTICE_VERSION,"sharing_mode":sharing_mode,"consent_timestamp":consent_timestamp,"source_batch":source_batch,"background_cohort":background_cohort,"scores_enabled":scores_enabled,"identity_deleted":identity_deleted,"deletion_pending":deletion_pending or _withdrawal_unsaved,"eligible_visits":eligible_visits,"enabled":enabled,"consented_endpoint":consented_endpoint,"client_id":client_id,"deletion_token":deletion_token,"queue":[] if _withdrawal_unsaved else queue,"receipts":{} if _withdrawal_unsaved else receipts,"evicted_records":evicted_records,"rejected_records":rejected_records})
	var bytes := body.to_utf8_buffer()
	if bytes.size()>MAX_DISK_BYTES: status="queue_full"; return false
	var file: FileAccess = FileAccess.open(state_path+".tmp",FileAccess.WRITE)
	if file == null: status="storage_error"; return false
	var written := file.store_buffer(bytes)
	file.flush()
	var complete := written and file.get_error()==OK and file.get_length()==bytes.size()
	file.close()
	if not complete: status="storage_error"; return false
	var err: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(state_path+".tmp"),ProjectSettings.globalize_path(state_path))
	if err!=OK: status="storage_error"; return false
	if _withdrawal_unsaved:
		queue.clear()
		receipts.clear()
		deletion_pending=true
		_withdrawal_unsaved=false
	return true
func _load_state() -> void:
	if not FileAccess.file_exists(state_path):
		client_id=Crypto.new().generate_random_bytes(16).hex_encode()
		deletion_token=Crypto.new().generate_random_bytes(32).hex_encode()
		return
	# Until this existing identity can be loaded, even shutdown must preserve the file.
	_outbox_read_only=true
	var file: FileAccess = FileAccess.open(state_path,FileAccess.READ)
	if file == null or file.get_length()>MAX_DISK_BYTES: status="storage_error"; return
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error!=OK: status="storage_error"; return
	var state: Variant = parser.data
	if not state is Dictionary or int(state.get("schema_version",0)) not in [1,2]: status="storage_error"; return
	if not state.get("client_id") is String or state.client_id.length()!=32 or not state.get("deletion_token") is String or state.deletion_token.length()!=64: status="storage_error"; return
	evicted_records=maxi(0,int(state.get("evicted_records",0)))
	rejected_records=maxi(0,int(state.get("rejected_records",0)))
	client_id=state.client_id; deletion_token=state.deletion_token
	consented_endpoint=str(state.get("consented_endpoint",""))
	var same_consent: bool = state.get("notice_version","")==NOTICE_VERSION and consented_endpoint==endpoint and endpoint_allowed()
	sharing_mode=str(state.get("sharing_mode","local")) if same_consent else "local"
	if sharing_mode not in ["local","basic","detailed"]: sharing_mode="local"
	enabled=sharing_mode!="local"
	scores_enabled=bool(state.get("scores_enabled",false)) and same_consent
	consent_timestamp=str(state.get("consent_timestamp",""))
	source_batch=str(state.get("source_batch",""))
	background_cohort=str(state.get("background_cohort","unspecified"))
	if background_cohort not in ["unspecified","new_to_circuits","some_experience","experienced"]: background_cohort="unspecified"
	identity_deleted=bool(state.get("identity_deleted",false))
	deletion_pending=bool(state.get("deletion_pending",false))
	if deletion_pending or identity_deleted:
		enabled=false
		scores_enabled=false
		sharing_mode="local"
		queue.clear()
		receipts.clear()
		eligible_visits.clear()
		status="delete_failed" if deletion_pending else "deleted"
		_outbox_read_only=false
		return
	if same_consent and state.get("eligible_visits") is Dictionary: eligible_visits=state.eligible_visits
	if state.get("receipts") is Dictionary and state.receipts.size()<=64: receipts=state.receipts
	if state.get("queue") is Array and state.queue.size()<=MAX_QUEUE:
		for raw: Variant in state.queue:
			if not raw is Dictionary or not raw.get("record") is Dictionary: continue
			var record: Dictionary = raw.record
			if not record.get("event_id") is String or record.event_id.length()!=64 or record.get("kind") not in ["event","feedback","score"] or not record.get("payload") is Dictionary: continue
			if str(raw.get("destination",""))!=endpoint or not same_consent: continue
			var attempts := int(raw.get("attempts",0))
			var next_at := int(raw.get("next_at",0))
			var paused := bool(raw.get("permanent",bool(raw.get("paused",false)) and attempts<8))
			# Older manual retries reset these three fields but left permanent set.
			if raw.get("paused")==false and raw.get("attempts")==0 and raw.get("next_at")==0: paused=false
			queue.append({"record":record,"attempts":attempts,"next_at":next_at,"paused":paused,"permanent":paused,"isolate":bool(raw.get("isolate",false)),"destination":str(raw.get("destination",""))})
	status="pending" if not queue.is_empty() else "ready" if enabled else "local_only"
	if not queue.is_empty() and queue.all(func(item: Dictionary) -> bool: return item.paused):
		status="rejected"
	_outbox_read_only=false

func delete_uploaded_data() -> void:
	if _outbox_read_only:
		status_changed.emit()
		return
	if not endpoint_allowed(): status="not_configured"; status_changed.emit(); return
	if not deletion_pending and not _withdrawal_unsaved:
		if request != null: request.cancel_request()
		inflight.clear()
		enabled=false
		sharing_mode="local"
		scores_enabled=false
		eligible_visits.clear()
		consented_endpoint=endpoint
		_withdrawal_unsaved=true
	_resume_deletion()

func _resume_deletion() -> void:
	if deleting: return
	# One atomic replacement retires all queued POSTs and commits the DELETE
	# identity. An unwritable outbox suspends transmission in this process.
	if _withdrawal_unsaved and not _save_state():
		status_changed.emit()
		return
	if not endpoint_allowed() or consented_endpoint!=endpoint:
		status="not_configured"
	elif request==null:
		status="delete_failed"
	else:
		var error: Error = request.request(api_url("data"),["Content-Type: application/json"],HTTPClient.METHOD_DELETE,JSON.stringify({"client_id":client_id,"deletion_token":deletion_token}))
		deleting=error==OK
		status="deleting" if deleting else "delete_failed"
	status_changed.emit()

func _exit_tree() -> void:
	# Finish while the outbox still exists; never wait for HTTP during exit.
	var store: Node = get_node_or_null("/root/PlaytestData")
	if store != null and get_node_or_null("/root/RemoteFeedback")==self: store.end_session()
	if request != null: request.cancel_request()
	_save_state()

func send_score(payload: Dictionary) -> String:
	if not scores_enabled or deletion_pending or consented_endpoint!=endpoint or not community_available(): return ""
	var safe: Dictionary = minimal_context(payload)
	for prefix: String in ["a","b"]:
		for key: String in ["total_cycles","prepare_cycles","query_cycles","output_cycles","ram_read_bytes","ram_write_bytes","peak_extra_bytes"]:
			var field: String = prefix+"_"+key
			if payload.has(field): safe[field]=int(payload[field])
	safe.merge(consent_metadata(),true); safe.sharing_mode="score"
	var id: String = (client_id+JSON.stringify(safe)).sha256_text()
	if receipts.has(id): return id
	for item: Dictionary in queue:
		if item.record.event_id==id: return id
	if not _enqueue({"event_id":id,"kind":"score","payload":safe}): return ""
	flush()
	return id


static func feedback_id(event: Dictionary) -> String:
	# JSON reload represents integral sequence numbers as float. Normalize that
	# representation so a persisted opinion never acquires a second receipt ID.
	return ("feedback:"+str(event.get("session_id",""))+":"+str(int(event.get("sequence",0)))).sha256_text()

func feedback_state(id: String) -> String:
	if id.is_empty(): return "local"
	if _outbox_read_only or _withdrawal_unsaved: return "storage_error"
	if receipts.has(id): return "sent"
	if inflight.has(id): return "sending"
	for item: Dictionary in queue:
		if str(item.record.event_id) != id: continue
		if item.get("permanent",false): return "rejected"
		return "failed_retryable" if int(item.get("attempts",0)) > 0 else "pending"
	return "local"
