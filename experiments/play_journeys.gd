extends "res://experiments/play_candidates.gd"
## Known-answer viewport QA of entry, earned plans, Save/Home and process resume.
## The isolated launcher supplies profile identity; never use a campaign directory.
const RepStore = preload("res://experiments/representation_region/session_store.gd")
const ServiceStore = preload("res://experiments/service_plan/session_store.gd")
var resume_only: bool = false
var domain: String = "representation_region"
var expected_history: int = 0

func open_scene(path: String) -> void:
	if path not in ["res://experiments/representation_region/region.tscn","res://experiments/service_plan/lab.tscn"]:
		await super.open_scene(path); return
	await super.open_scene("res://src/ui/prototype_hub.tscn")
	check(ui.candidate_journey,"Candidate hub is explicitly enabled")
	check(handle("EnterRepresentationCandidate") != null and handle("EnterServiceCandidate") != null,"Both candidate domains have independent entries")
	await press(handle("EnterRepresentationCandidate" if path.contains("representation_region") else "EnterServiceCandidate"))
	await settle(25); ui = current_scene
	check(ui.persistent_session and ui.candidate_journey,"Entry opens persistent candidate journey")
	check(handle("CandidateHome") != null,"Candidate has a return path")

func verify_saved() -> void:
	var representation: bool = domain == "representation_region"
	var store: Script = RepStore if representation else ServiceStore
	var saved: Dictionary = store.read_session()
	check(saved.ok and saved.supports.size() == (5 if representation else 3),"Protected successful plans survive disk read")
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
		check(ui.find_child("EnterServiceCandidate",true,false) != null,"Saved Home returns to shared candidate hub")
		await press(handle("EnterRepresentationCandidate" if domain == "representation_region" else "EnterServiceCandidate")); await settle(25); ui = current_scene
		check(ui.history.size() == expected_history,"Same-process return preserves recorded work")
		await verify_saved()
	var core_after: Dictionary = root.get_node("GlobalSave")._save_snapshot(); core_after.erase("saved_at_utc")
	check(core_before == core_after,"Candidate work preserves original core40 authority")
	var file := FileAccess.open(evidence_root+"journey-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t")); file.close()
	print("PASS: known-answer candidate journey" if failures.is_empty() else "FAIL: known-answer candidate journey")
	quit(0 if failures.is_empty() else 1)
