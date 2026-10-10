extends "res://experiments/play_candidates.gd"
## Known-answer viewport QA of entry, earned plans, Save/Home and process resume.
## The isolated launcher supplies profile identity; never use a campaign directory.
const RepStore = preload("res://experiments/representation_region/session_store.gd")
const ServiceStore = preload("res://experiments/service_plan/session_store.gd")
const JourneyTasks = preload("res://src/campaign/second_act_tasks.gd")
var resume_only: bool = false
var domain: String = "representation_region"
var expected_history: int = 0
var reenter_saved: bool = false

func abort_journey(message: String) -> void:
	check(false,message)
	var file := FileAccess.open(evidence_root+"journey-checks.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(observations,"\t")); file.close()
	print("FAIL: known-answer candidate journey")
	quit(1)
	# End at the event loop boundary so inherited action sequences cannot continue
	# into a different scene after a failed navigation or unavailable control.
	await process_frame

func press(control: Control) -> void:
	if not failures.is_empty(): await abort_journey("An earlier journey check failed; further actions are stopped"); return
	if control == null or not control.is_visible_in_tree():
		await abort_journey("Requested journey action exists and is visible"); return
	var window := control.get_viewport() as Window
	if window != null and window != root and window.is_embedded():
		await click(Vector2(window.position)+control.get_global_rect().get_center())
		return
	await super.press(control)

func at_task_tree() -> bool:
	return current_scene != null and current_scene.scene_file_path == "res://src/campaign/task_tree.tscn"

func domain_entry(path: String, use_saved_task: bool) -> void:
	var representation: bool = path.contains("representation_region")
	var task_index: int = 0
	if use_saved_task:
		var saved: Dictionary = RepStore.read_session() if representation else ServiceStore.read_session()
		if not saved.get("ok",false) or not saved.has("task"):
			await abort_journey("Saved candidate task is readable before resume navigation"); return
		task_index = int(saved.task)
	var task_key: String = JourneyTasks.key_for("representation" if representation else "service",task_index)
	if not at_task_tree():
		check(current_scene != null and current_scene.scene_file_path == "res://src/ui/prototype_hub.tscn","Candidate entry starts on the real Home or journey map")
		if not failures.is_empty(): await abort_journey("Candidate Home is unavailable"); return
		ui = current_scene
		check(ui.candidate_journey,"Candidate hub is explicitly enabled")
		var browse: Control = handle("HubBrowseJourney")
		if browse == null: browse = handle("ChooseJourney")
		await press(browse)
		await settle(25)
	if not at_task_tree(): await abort_journey("Home opens the real unified journey map"); return
	var tree = current_scene
	await press(tree.search)
	await key(KEY_A,true)
	await type_text(task_key)
	await key(KEY_ENTER)
	await settle()
	if not tree.canvas.positions.has(task_key): await abort_journey("Journey search locates the exact candidate task: "+task_key); return
	var at: Vector2 = tree.canvas.global_position+tree.canvas.pan+(tree.canvas.positions[task_key]+tree.canvas.NODE_SIZE/2)*tree.canvas.magnification
	check(tree.canvas.get_global_rect().has_point(at),"Candidate task node is reachable after search")
	await click(at)
	check(tree.selected.get("key","") == task_key and not tree.enter_button.disabled,"Actual candidate task is selected and available: "+task_key)
	if not failures.is_empty(): await abort_journey("Candidate task cannot be entered through the visible map"); return
	await press(tree.enter_button)
	await settle(25)
	ui = current_scene
	if ui == null or ui.scene_file_path != path: await abort_journey("Journey entry opens the exact candidate workspace"); return
	check(ui.persistent_session and ui.candidate_journey,"Entry opens persistent candidate journey")
	check(ui.task == task_index,"Journey enters the exact first or persisted candidate task")
	check(handle("CandidateHome") != null,"Candidate has a real return path")
	if not failures.is_empty(): await abort_journey("Candidate workspace entry contract failed")

func open_scene(path: String) -> void:
	if path not in ["res://experiments/representation_region/region.tscn","res://experiments/service_plan/lab.tscn"]:
		await super.open_scene(path); return
	await super.open_scene("res://src/ui/prototype_hub.tscn")
	await domain_entry(path,resume_only or reenter_saved)

func verify_saved() -> void:
	var representation: bool = domain == "representation_region"
	var store: Script = RepStore if representation else ServiceStore
	var saved: Dictionary = store.read_session()
	check(saved.get("ok",false) and saved.get("supports",[]).size() == (5 if representation else 3),"Protected successful plans survive disk read")
	if not saved.get("ok",false): await abort_journey("Saved journey cannot be verified"); return
	check(ui.history.size() == saved.runs.size() and ui.history.size() > 0,"Restart restores measured plan history")
	check(not ui.session_dirty,"Restored workbench is clean")
	check(not ui.completed.has(false) if representation else ui.has_service_closure(),"Complete candidate can still close after restoration")
	var review_handle: String = "RegionClosure" if representation else "ServiceClosure"
	await press(handle(review_handle)); await settle()
	var review: AcceptDialog = ui.get_node("RegionReview" if representation else "ServiceReview")
	check(review.visible,"Measured journey review is reachable")
	await capture("restored-review-"+domain)
	await press(review.get_ok_button())

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--experiment="): domain = arg.trim_prefix("--experiment=")
		if arg == "--journey-resume": resume_only = true
	var custom: String = str(ProjectSettings.get_setting("application/config/custom_user_dir_name",""))
	if not "--candidate-save" in OS.get_cmdline_user_args() or not "--candidate-journey" in OS.get_cmdline_user_args() or not custom.begins_with("VonNeumannBottleneckCandidates/"):
		push_error("Journey QA requires an explicitly isolated candidate launch"); quit(2); return
	if domain not in ["representation_region","service_plan"]:
		await abort_journey("Journey QA names one of its two supported persistent domains"); return
	var core_before: Dictionary = root.get_node("GlobalSave")._save_snapshot(); core_before.erase("saved_at_utc")
	await prepare_window()
	if resume_only:
		await open_scene("res://experiments/representation_region/region.tscn" if domain == "representation_region" else "res://experiments/service_plan/lab.tscn")
		await verify_saved()
	else:
		if domain == "representation_region": await representation()
		else: await service()
		await press(handle("SaveSession")); check(not ui.session_dirty,"Explicit Save succeeds before leaving")
		expected_history = ui.history.size()
		await press(handle("CandidateHome")); await settle(25); ui = current_scene
		check(at_task_tree() or (ui != null and ui.scene_file_path == "res://src/ui/prototype_hub.tscn"),"Saved return reaches the real shared journey map or Home")
		reenter_saved = true
		await domain_entry("res://experiments/representation_region/region.tscn" if domain == "representation_region" else "res://experiments/service_plan/lab.tscn",true)
		check(ui.history.size() == expected_history,"Same-process return preserves recorded work")
		await verify_saved()
	var core_after: Dictionary = root.get_node("GlobalSave")._save_snapshot(); core_after.erase("saved_at_utc")
	check(core_before == core_after,"Candidate work preserves original core40 authority")
	var file := FileAccess.open(evidence_root+"journey-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t")); file.close()
	print("PASS: known-answer candidate journey" if failures.is_empty() else "FAIL: known-answer candidate journey")
	quit(0 if failures.is_empty() else 1)
