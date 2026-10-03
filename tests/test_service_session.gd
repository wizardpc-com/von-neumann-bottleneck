extends SceneTree
const Store = preload("res://experiments/service_plan/session_store.gd")
const Model = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func write_raw(path: String, value: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(value); file.close()
func remove_fixture(path: String) -> void:
	for suffix: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
func run() -> void:
	var baseline: Dictionary = Model.initial_plan()
	var per_stream: Dictionary = baseline.duplicate(true); per_stream.groups = []
	for i: int in 24: per_stream.groups.append([i])
	check(Model.accepted(Model.run(per_stream).metrics,0),"Fixture is genuinely accepted by contract1")
	var raw: String = Store.encode(1,baseline,[{"task":0,"plan":per_stream}])
	var decoded: Dictionary = Store.decode(raw)
	check(decoded.ok and decoded.draft == baseline,"Draft JSON roundtrip")
	check(typeof(decoded.draft.groups[0][0]) == TYPE_INT,"JSON integer IDs restored to integers")
	for invalid: String in ["{}","[]","{bad",raw.repeat(500)]: check(not Store.decode(invalid).ok,"Malformed or oversized snapshot refused")
	var data: Dictionary = JSON.parse_string(raw)
	for mutation: Dictionary in [{"schema":2},{"task":3},{"task":1.5},{"model":"future"},{"contracts":"changed"},{"unlocked":2},{"runs":[{"task":0,"plan":baseline,"accepted":true}]}]:
		var changed: Dictionary = data.duplicate(true); changed.merge(mutation,true)
		check(not Store.decode(JSON.stringify(changed)).ok,"Unknown version, fields or forged result refused")
	for mutation: Dictionary in [{"slots":0},{"slots":1.5},{"groups":[[0,0]]},{"representations":["secret","raw64","raw64","raw64"]},{"extra":"x"}]:
		var altered: Dictionary = baseline.duplicate(true); altered.merge(mutation,true)
		check(Store.clean_plan(altered).is_empty(),"Malformed draft shape refused")
	var unfinished: Dictionary = Model.move(baseline,4,-4)
	check(not Model.validate(unfinished).is_empty(),"Fixture violates stream ordering")
	check(Store.decode(Store.encode(0,unfinished,[])).ok,"Unfinished semantic-invalid draft survives without acceptance")
	var temp: String = "user://service-session-test.json"; remove_fixture(temp)
	check(Store.write_session(raw,temp,"") == OK,"First save written")
	check(Store.read_session(temp).digest == raw.sha256_text(),"Written snapshot digest verified")
	check(Store.write_session(raw,temp,"wrong") == ERR_ALREADY_IN_USE,"Stale writer refused")
	var second: String = Store.encode(1,unfinished,[{"task":0,"plan":per_stream}])
	check(Store.write_session(second,temp,raw.sha256_text()) == OK,"Matching writer can save next version")
	check(FileAccess.get_file_as_string(temp+".bak") == raw,"Previous save retained")
	write_raw(temp,"{unknown")
	check(Store.write_session(raw,temp,"") == ERR_INVALID_DATA and FileAccess.get_file_as_string(temp) == "{unknown","Corrupt existing file preserved")
	check(Store.write_session(raw,"user://missing-service-dir/file.json","") != OK,"Write failure reported")
	remove_fixture(temp)
	# All paths are in this verifier's fresh isolated user directory.
	remove_fixture(Store.PATH); write_raw(Store.PATH,raw)
	root.content_scale_size = Vector2i(1280,720); root.size = Vector2i(1280,720)
	var campaign_before: String = JSON.stringify(root.get_node("LocalityChapter").completed_levels())
	var scene = load("res://experiments/service_plan/lab.tscn").instantiate(); scene.persistent_session = true; root.add_child(scene); await process_frame; await process_frame
	check(scene.plan == baseline and scene.task == 1 and scene.unlocked == 1,"Restore recomputes unlock and selected contract")
	check(scene.history.size() == 1 and scene.history[0].signature == Model.run(per_stream).canonical_signature(),"Stored plans are recomputed, not trusted metrics")
	check(scene.find_child("SaveSession",true,false) != null,"Opt-in save control exists")
	check(not scene.session_dirty,"Restored session begins clean")
	check(scene.find_child("SaveSession",true,false).get_global_rect().end.y <= 720,"Profile save action fits minimum viewport")
	scene.edit(unfinished,0); check(scene.session_dirty,"Editing marks session dirty")
	check(scene.is_in_group("candidate_quit_owners"),"Persistent scene owns its window-close guard")
	root.get_node("GlobalSave")._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await process_frame
	scene._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(scene.has_node("UnsavedServiceDialog"),"Global save does not preempt the candidate window-close guard")
	scene.get_node("UnsavedServiceDialog").hide()
	scene.save_session(); check(not scene.session_dirty and Store.read_session().draft == unfinished,"Unfinished draft explicitly saved")
	scene.english = true; scene.build(); await process_frame
	check(scene.status.text.begins_with("Isolated candidate profile saved"),"Saved notice follows language changes")
	check(campaign_before == JSON.stringify(root.get_node("LocalityChapter").completed_levels()),"No formal campaign changes")
	scene.queue_free(); await process_frame; await process_frame
	write_raw(Store.PATH,"{future")
	var blocked = load("res://experiments/service_plan/lab.tscn").instantiate(); blocked.persistent_session = true; root.add_child(blocked); await process_frame
	check(blocked.save_blocked and blocked.find_child("SaveSession",true,false).disabled,"Unknown save cannot be overwritten from UI")
	blocked.save_session(); check(FileAccess.get_file_as_string(Store.PATH) == "{future","Blocked save leaves exact original bytes")
	blocked.queue_free(); await process_frame; await process_frame; remove_fixture(Store.PATH)
	print("PASS: test_service_session " if failures == 0 else "FAIL: test_service_session ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
