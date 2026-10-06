extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var Hub: Script = load("res://src/ui/prototype_hub.gd")
	root.content_scale_size = Vector2i(1280,720); root.size = Vector2i(1280,720)
	var empty := {"representation":{"status":"empty"}, "service":{"status":"empty"}, "complete":false}
	var all_saved := {"representation":{"status":"complete"}, "service":{"status":"complete"}, "complete":true}
	check(Hub.recommended_stage(false, all_saved) == "review", "Independent earned second-act ending stays discoverable without inventing a core ending")
	check(Hub.recommended_stage(true, empty) == "representation", "Earned core points to Representation")
	check(Hub.recommended_stage(true, {"representation":{"status":"complete"},"service":{"status":"partial"}}) == "service", "Saved Representation leads to Service")
	check(Hub.recommended_stage(true, all_saved) == "review", "Both completed saved domains lead to closure")
	check(Hub.recommended_stage(true, {"representation":{"status":"unavailable"},"complete":true}) == "representation", "Unavailable source cannot grant a completed route")
	var save: Node = root.get_node("GlobalSave")
	var before: Dictionary = save._save_snapshot(); before.erase("saved_at_utc")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		var hub = load("res://src/ui/prototype_hub.tscn").instantiate(); hub.candidate_journey = true
		root.add_child(hub)
		for i: int in 5: await process_frame
		var recommended := hub.find_child("RecommendedJourneyAction",true,false) as Button
		check(recommended != null and recommended.has_focus(), "Shared first action receives focus in " + locale)
		check(recommended.get_global_rect().end.x <= 1280 and recommended.get_global_rect().end.y <= 720, "Primary action fits minimum viewport")
		var navigation: Node = root.get_node("TaskNavigation")
		check(recommended.text == navigation.home_action_text(), "Primary caption comes from shared continuation")
		check((hub.find_child("HubResumeTitle",true,false) as Label).text == navigation.next_task_title(), "Next-task title comes from the same continuation target")
		check(hub.find_child("EnterRepresentationCandidate",true,false) == null and hub.find_child("CandidateStages",true,false) == null, "Second-act entry belongs on the shared task tree")
		var settings := hub.find_child("HubSettings",true,false) as Button
		settings.grab_focus(); settings.pressed.emit(); await process_frame
		(hub.find_child("HubManageProgress",true,false) as Button).pressed.emit(); await process_frame
		var page := hub.find_child("HubNavigation",true,false) as Control
		check(page.visible and not hub.options_overlay.visible and (hub.find_child("CompletionStory",true,false) as Button).is_visible_in_tree(), "Saved story and evidence remain discoverable through achievements/save management")
		hub.find_child("HubNavigationClose",true,false).pressed.emit(); await process_frame
		check(settings.has_focus(), "Closing management restores its Settings launcher focus")
		check(hub.candidate_review_paths().is_empty(), "Unbound QA profile has no candidate save authority")
		hub._show_completion_bridge()
		await process_frame; await process_frame
		var bridge := hub.get_node("CompletionBridge") as ConfirmationDialog
		check(bridge.visible and bridge.size.x <= 1280 and bridge.size.y <= 720, "Bridge is readable and bounded")
		var bridge_text: String = ""
		for child: Node in bridge.get_children():
			if child is Label: bridge_text += child.text
		check(bridge_text.contains("session-only") if locale == "en" else bridge_text.contains("本次会话"), "Unbound bridge cannot promise persistent progress")
		bridge.get_cancel_button().pressed.emit(); bridge.hide()
		check(is_instance_valid(hub) and not hub.is_queued_for_deletion(), "Cancel bridge preserves current entry")
		hub.show_completion_story(); await process_frame; await process_frame
		var story := hub.get_node("CompletionStoryDialog") as AcceptDialog
		check(story.visible and story.size.x <= 1280 and story.size.y <= 720, "Reopenable story fits minimum window")
		check(hub.completion_story_pages[-1].id != "closure", "Unbound profile cannot show earned ending")
		var count: int = hub.completion_story_pages.size()
		for i: int in count - 1: story.custom_action.emit(&"next")
		check(hub.completion_story_page == count - 1 and (story.find_child("StoryNext",true,false) as Button).disabled, "Pages have a finite ending and no forced progress")
		story.custom_action.emit(&"previous")
		check(hub.completion_story_page == count - 2, "Short story is revisitable")
		story.custom_action.emit(&"evidence"); await process_frame
		check(hub.get_node("SavedJourneyReview").visible, "Exact saved evidence remains one action away")
		hub.get_node("SavedJourneyReview").hide(); hub.show_completion_story(); await process_frame
		check(hub.completion_story_page == 0, "Reopening starts safely at the beginning")
		hub.get_node("CompletionStoryDialog").hide()
		# Synthetic in-memory accepted terminal recipes; never a native/core play claim.
		var overlap: Node = root.get_node("OverlapChapter")
		var layout: Node = root.get_node("LayoutChapter")
		var old_overlap: Dictionary = overlap.game_solutions.duplicate(true)
		var old_layout: Dictionary = layout.game_solutions.duplicate(true)
		overlap.game_solutions["synthesis"] = load("res://src/overlap_chapter/overlap_catalog.gd").reference_solution("synthesis")
		layout.game_solutions["mixed"] = load("res://src/layout_chapter/layout_catalog.gd").reference_solution("mixed")
		hub._open_theme_reflection(); await process_frame
		var next := hub.get_node("ThemeReflection").find_child("CoreToRepresentation",true,false) as Button
		check(next != null, "Joint earned core reflection exposes the next-stage bridge")
		next.pressed.emit(); await process_frame
		check(hub.get_node("CompletionBridge").visible, "Core ending action opens the reversible bridge")
		overlap.game_solutions = old_overlap; layout.game_solutions = old_layout
		hub.queue_free(); await process_frame
	var after: Dictionary = save._save_snapshot(); after.erase("saved_at_utc")
	check(before == after, "Route and story cannot mutate core progress")
	if failures.is_empty(): print("PASS: recommended route, canceled bridge, finite bilingual story, evidence and unchanged progress")
	else:
		for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
