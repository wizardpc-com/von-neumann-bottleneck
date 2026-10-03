extends SceneTree
const Store = preload("res://experiments/representation_region/session_store.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var failures: int = 0
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func run() -> void:
	var plans: Array = []
	for i: int in 5: plans.append(Model.initial_plan())
	plans[1] = Model.split(Model.initial_plan(),0,17)
	var runs: Array = [{"task":1,"plan":plans[1].duplicate(true)}]
	var raw: String = Store.encode(1,plans,runs)
	var result: Dictionary = Store.decode(raw)
	check(result.ok and result.task == 1 and result.drafts[1] == plans[1],"JSON integer plans roundtrip")
	check(result.runs == runs,"Only performed plan provenance retained")
	check(not Store.decode("broken").ok,"Corrupt JSON refused")
	check(not Store.decode(" ".repeat(Store.MAX_BYTES+1)).ok,"Oversized input refused")
	for field: String in ["schema","model","contracts"]:
		var altered: Dictionary = JSON.parse_string(raw); altered[field] = "future"
		check(not Store.decode(JSON.stringify(altered)).ok,"Future or stale schema/model/contracts refused")
	var altered: Dictionary = JSON.parse_string(raw); altered["completed"] = [true,true,true,true,true]
	check(not Store.decode(JSON.stringify(altered)).ok,"Unknown completion injection refused")
	for invalid: Variant in [-1,5,1.5,"1",null]:
		altered = JSON.parse_string(raw); altered.task = invalid
		check(not Store.decode(JSON.stringify(altered)).ok,"Invalid task refused")
	for invalid: Variant in [-1,65,0.5,"0",null]:
		altered = JSON.parse_string(raw); altered.drafts[0][0].start = invalid
		check(not Store.decode(JSON.stringify(altered)).ok,"Invalid partition refused")
	altered = JSON.parse_string(raw); altered.runs[0]["accepted"] = true
	check(not Store.decode(JSON.stringify(altered)).ok,"No trusted serialized acceptance")
	var path: String = "user://candidate-session-test.json"
	check(Store.write_session(raw,path) == OK,"Initial write")
	check(Store.read_session(path).ok,"Disk read")
	check(Store.write_session(Store.encode(2,plans,runs),path,raw.sha256_text()) == OK,"Atomic replacement")
	check(Store.read_session(path).task == 2 and Store.read_session(path+".bak").task == 1,"Previous bytes retained in backup")
	check(Store.write_session(raw,path,raw.sha256_text()) == ERR_ALREADY_IN_USE,"Stale writer cannot overwrite newer valid save")
	check(Store.write_session(raw,path,Store.encode(2,plans,runs).sha256_text()) == OK,"Repeated replacement")
	var f := FileAccess.open(path,FileAccess.WRITE); f.store_string("future data"); f.close()
	check(Store.write_session(raw,path) != OK,"Do not overwrite unreadable data")
	check(FileAccess.get_file_as_string(path) == "future data","Unreadable save preserved byte for byte")
	check(Store.write_session(raw,"user://missing-dir/save.json") != OK,"Missing destination fails safely")
	var scene = load("res://experiments/representation_region/region.tscn").instantiate()
	root.add_child(scene); await process_frame
	scene.persistent_session = true
	# Use the real default candidate location, isolated by the verifier's per-suite directory.
	check(Store.write_session(raw) == OK,"Candidate profile fixture")
	scene.restore_session(); scene.build(); await process_frame
	check(scene.task == 1 and scene.plan == plans[1],"Scene draft restored")
	check(scene.history.size() == 1 and scene.history[0].traces.size() == Model.orders(1).size(),"Restore recomputes traces from plans")
	check(scene.completed[1] == Model.meets(1,scene.history[0].traces),"Completion follows recomputation")
	check(scene.find_child("SaveSession",true,false) != null,"Explicit save action available")
	scene.edit_plan(Model.represent(scene.plan,0,"rle"))
	check(scene.session_dirty,"Editing marks the profile unsaved")
	scene.request_quit(); await process_frame
	var dialog = scene.get_node_or_null("UnsavedSessionDialog")
	check(dialog != null and dialog.visible,"Unsaved quit offers a decision without exiting")
	dialog.hide()
	check(scene.session_dirty,"Returning to editor keeps unsaved draft")
	scene.save_session()
	check(not scene.session_dirty,"Successful save clears unsaved state")
	scene.queue_free(); await process_frame
	print("PASS: test_representation_session " if failures == 0 else "FAIL: test_representation_session ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
