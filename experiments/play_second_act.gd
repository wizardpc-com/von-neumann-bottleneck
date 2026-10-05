extends "res://experiments/play_commissions.gd"
## Authored-answer input path for candidate continuity; no novice/native claim.
func open_scene(path: String) -> void:
	if path == "res://experiments/service_plan/lab.tscn" and current_scene != null and current_scene.scene_file_path == path:
		ui = current_scene; await settle(); return
	await super.open_scene(path)

# Only the changed route is under test here. Detailed order-menu comparisons
# remain in the existing Representation driver; do not repeat that popup path.
func representation() -> void:
	await open_scene("res://experiments/representation_region/region.tscn")
	var plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	for id: int in 5:
		await press(handle("Task"+str(id))); await build_partition(plans[id]); await press(handle("Run"))
		check(ui.public_observation().accepted,"Own visible partition earns task%d across all authored orders" % id)

func enter_from_hub(name: String) -> void:
	await press(handle(name)); await settle(25); ui = current_scene

func saved_review() -> void:
	await press(handle("SavedSecondActReview")); await settle()
	var review: AcceptDialog = ui.get_node("SavedJourneyReview")
	var content: Label = review.find_child("SavedJourneyReviewContent",true,false)
	check(review.visible and content.text.contains("A Thought Within the World"),"Saved5+3 measured recipes earn the combined candidate review")
	check(content.text.contains("5 / 5") and content.text.contains("3 / 3"),"Review exposes both independently verified stage counts")
	await capture("second-act-saved-review")
	await press(review.get_ok_button()); check(not review.visible,"Return closes combined review")

func state_view() -> void:
	var bar: TabBar = ui.evidence_tabs.get_tab_bar()
	await click(bar.global_position+bar.get_tab_rect(5).get_center())
	check(ui.evidence_tabs.current_tab == 5,"State journey is reachable from continued service")
	await press(handle("StateEnd"))
	check(ui.state_replay.frames.back().responses.size() == 24,"Continued final service displays24 actual returned requests")
	await capture("second-act-service-state")

func service() -> void:
	await open_scene("res://experiments/service_plan/lab.tscn")
	await build_service(service_draft(true,1,["raw64","raw64","raw64","raw64"])); await press(handle("Run"))
	check(ui.unlocked == 1,"Own grouped exact plan earns traffic contract")
	await press(handle("Task2"))
	await build_service(service_draft(false,4,["raw64","raw64","raw64","raw64"])); await press(handle("Run"))
	check(ui.unlocked == 2,"Own timely exact plan earns response contract")
	await press(handle("Task3"))
	await build_service(service_draft(false,4,["rle64","rle64","raw64","raw64"])); await press(handle("Run"))
	check(ui.has_service_closure(),"Third actual plan earns original service ending")
	await state_view()

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--journey-resume": resume_only = true
	var primary: String = str(ProjectSettings.get_setting("candidate/primary_domain",""))
	var custom: String = str(ProjectSettings.get_setting("application/config/custom_user_dir_name",""))
	if primary != "representation" or not custom.begins_with("VonNeumannBottleneckCandidates/representation/") or not "--candidate-save" in OS.get_cmdline_user_args() or not "--candidate-journey" in OS.get_cmdline_user_args():
		push_error("Second-act QA requires a named isolated representation-primary journey"); quit(2); return
	var core_before: Dictionary = root.get_node("GlobalSave")._save_snapshot(); core_before.erase("saved_at_utc")
	await prepare_window()
	if resume_only:
		await super.open_scene("res://src/ui/prototype_hub.tscn")
		await saved_review()
		await enter_from_hub("EnterRepresentationCandidate")
		check(ui.representation_review_evidence().size() == 5 and not ui.session_dirty,"Independent restart restores protected representation evidence")
		await press(handle("RegionClosure")); await settle()
		await press(handle("ContinueServiceCandidate")); await settle(25); ui = current_scene
		check(ui.has_service_closure() and not ui.session_dirty,"Clean earned continuation restores saved service in same profile")
		await state_view()
	else:
		await representation()
		check(ui.session_dirty and ui.representation_review_evidence().size() == 5,"Actual constructed representation earns continuation with unsaved work")
		await press(handle("RegionClosure")); await settle()
		await capture("second-act-representation-bridge")
		await press(handle("ContinueServiceCandidate")); await settle()
		var guard: ConfirmationDialog = ui.get_node("UnsavedSessionDialog")
		check(guard.visible,"Dirty earned continuation opens original Save/Discard/Cancel guard")
		await press(guard.get_cancel_button()); check(not guard.visible,"Cancel returns to same representation workbench")
		check(ui.session_dirty and ui.representation_review_evidence().size() == 5,"Cancel preserves earned work")
		await press(handle("RegionClosure")); await settle()
		await press(handle("ContinueServiceCandidate")); await settle()
		await press(ui.get_node("UnsavedSessionDialog").get_ok_button()); await settle(25); ui = current_scene
		check(ui.persistent_session and ui.candidate_journey and ui.history.is_empty(),"Save then continue opens separate fresh service without copying representation plans")
		check(RepStore.read_session().supports.size() == 5,"Representation supports reach disk before cross-domain entry")
		await service()
		await press(handle("SaveSession")); check(not ui.session_dirty,"Service plans saved under sibling candidate profile")
		await press(handle("CandidateHome")); await settle(25); ui = current_scene
		await saved_review()
	var core_after: Dictionary = root.get_node("GlobalSave")._save_snapshot(); core_after.erase("saved_at_utc")
	check(core_before == core_after,"Entire second-act candidate route preserves core40 save authority")
	var file := FileAccess.open(evidence_root+"second-act-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t")); file.close()
	print("PASS: known-answer second-act candidate" if failures.is_empty() else "FAIL: known-answer second-act candidate")
	quit(0 if failures.is_empty() else 1)
