extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func settle() -> void:
	for frame: int in 5: await process_frame
func key(code: Key, shift: bool = false) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.shift_pressed = shift; event.pressed = down
		root.push_input(event,true); await process_frame
	await settle()
func escape() -> void:
	var press := InputEventKey.new(); press.keycode = KEY_ESCAPE; press.physical_keycode = KEY_ESCAPE; press.pressed = true
	root.push_input(press,true); await process_frame
	var release := InputEventKey.new(); release.keycode = KEY_ESCAPE; release.physical_keycode = KEY_ESCAPE
	root.push_input(release,true); await settle()
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
		var previous_button := story.find_child("StoryPrevious",true,false) as Button
		var next_button := story.find_child("StoryNext",true,false) as Button
		var back_button := story.get_ok_button()
		check(previous_button.disabled and previous_button.focus_mode == Control.FOCUS_NONE and not next_button.disabled, "First page leaves Previous outside the Tab chain")
		next_button.grab_focus()
		await key(KEY_TAB,true)
		check(story.gui_get_focus_owner() != null and not previous_button.has_focus(), "Viewport Shift-Tab skips unavailable first-page Previous")
		next_button.grab_focus()
		for page_index: int in range(1,count):
			await key(KEY_ENTER)
			check(hub.completion_story_page == page_index and (next_button.has_focus() if page_index < count - 1 else back_button.has_focus()), "Repeated viewport Enter advances story and hands final focus to Back")
		check(next_button.disabled and next_button.focus_mode == Control.FOCUS_NONE, "Final page removes unavailable Next from the Tab chain")
		previous_button.grab_focus(); await key(KEY_ENTER)
		check(hub.completion_story_page == count - 2 and not next_button.disabled and next_button.focus_mode == Control.FOCUS_ALL, "Viewport Previous restores available Next")
		for back_index: int in count - 2: await key(KEY_ENTER)
		check(hub.completion_story_page == 0 and previous_button.disabled and previous_button.focus_mode == Control.FOCUS_NONE and next_button.has_focus(), "Repeated Previous Enter returns to first page and hands focus to Next")
		for forward_index: int in count - 1: await key(KEY_ENTER)
		check(hub.completion_story_page == count - 1 and back_button.has_focus(), "Returning to final page again focuses Back to journey")
		await key(KEY_ENTER)
		check(not story.visible, "Viewport Enter on Back closes the completed story")
		hub.show_completion_story(); await settle()
		story = hub.get_node("CompletionStoryDialog") as AcceptDialog
		for i: int in count - 1: story.custom_action.emit(&"next")
		check(hub.completion_story_page == count - 1 and (story.find_child("StoryNext",true,false) as Button).disabled, "Pages have a finite ending and no forced progress")
		story.custom_action.emit(&"previous")
		check(hub.completion_story_page == count - 2, "Short story is revisitable")
		var retained_page: int = hub.completion_story_page
		var retained_pages: Array = hub.completion_story_pages.duplicate(true)
		var retained_text: String = (story.find_child("StoryText",true,false) as Label).text
		(story.find_child("StoryEvidence",true,false) as Button).pressed.emit(); await settle()
		var evidence := hub.get_node("SavedJourneyReview") as AcceptDialog
		check(evidence.visible and not story.visible, "Exact saved evidence remains one action away without stacked dialogs")
		check(evidence.ok_button_text == ("Back to journey review" if locale == "en" else "回到旅程回顾"), "Evidence opened from the story names its return destination")
		evidence.get_ok_button().pressed.emit(); await settle()
		check(story.visible and not evidence.visible and hub.completion_story_page == retained_page, "Confirming evidence returns to the same story page")
		check(hub.completion_story_pages == retained_pages and (story.find_child("StoryText",true,false) as Label).text == retained_text, "Returning preserves the displayed evidence snapshot and text")
		var story_next := story.find_child("StoryNext",true,false) as Button
		check(story_next.has_focus(), "The next story action receives keyboard focus after evidence")
		story_next.pressed.emit(); await settle()
		check(hub.completion_story_page == retained_page+1, "The restored focus can continue to the next story page")
		(story.find_child("StoryEvidence",true,false) as Button).pressed.emit(); await settle()
		evidence = hub.get_node("SavedJourneyReview") as AcceptDialog
		await escape()
		check(story.visible and not evidence.visible and hub.completion_story_page == count-1, "Escape returns evidence to the same final story page")
		check((story.find_child("StoryEvidence",true,false) as Button).has_focus(), "Final story page restores a usable evidence action instead of disabled Next")
		(story.find_child("StoryPrevious",true,false) as Button).pressed.emit(); await settle()
		(story.find_child("StoryEvidence",true,false) as Button).pressed.emit(); await settle()
		evidence = hub.get_node("SavedJourneyReview") as AcceptDialog
		var old_evidence_id: int = evidence.get_instance_id()
		(evidence.find_child("RefreshSavedJourneyReview",true,false) as Button).pressed.emit(); await settle()
		evidence = hub.get_node("SavedJourneyReview") as AcceptDialog
		check(evidence.get_instance_id() != old_evidence_id and evidence.visible and not story.visible, "Refresh replaces only the detail dialog")
		evidence.get_ok_button().pressed.emit(); await settle()
		check(story.visible and hub.completion_story_page == retained_page and story_next.has_focus(), "Refreshed evidence keeps the original page and return focus")
		check(hub.completion_story_pages == retained_pages, "Refreshing detail never writes completion into the story snapshot")
		# Standalone evidence must not revive a hidden story or its return callbacks.
		story.hide(); hub.show_candidate_review(); await settle()
		evidence = hub.get_node("SavedJourneyReview") as AcceptDialog
		check(evidence.ok_button_text == ("Back to journey entries" if locale == "en" else "回到旅程入口"), "Independent evidence retains its original destination")
		(evidence.find_child("RefreshSavedJourneyReview",true,false) as Button).pressed.emit(); await settle()
		evidence = hub.get_node("SavedJourneyReview") as AcceptDialog
		evidence.get_ok_button().pressed.emit(); await settle()
		check(not story.visible and not evidence.visible, "Closing standalone refreshed evidence never opens a story")
		# A superseded evidence callback cannot resurrect an obsolete story.
		hub.show_completion_story(); await settle()
		var old_story := hub.get_node("CompletionStoryDialog") as AcceptDialog
		old_story.custom_action.emit(&"evidence"); await settle()
		evidence = hub.get_node("SavedJourneyReview") as AcceptDialog
		evidence.get_ok_button().pressed.emit()
		hub.show_completion_story(); await settle()
		story = hub.get_node("CompletionStoryDialog") as AcceptDialog
		check(story.visible and not evidence.visible and hub.get_children().filter(func(node: Node) -> bool: return node.name == "CompletionStoryDialog").size() == 1, "Queued return cannot revive a replaced story or duplicate its dialog")
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
