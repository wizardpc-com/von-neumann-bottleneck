extends SceneTree
## Controller integration, separate from native-input and unfamiliar-player acceptance.

const HUB := "res://src/ui/prototype_hub.tscn"
const HARDWARE := "res://src/hardware_foundations/hardware_foundations.tscn"
const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
var failures: Array[String] = []
var checks: int = 0


func _init() -> void: call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle() -> void:
	for frame: int in 8: await process_frame


func snapshot() -> Dictionary:
	var data: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	data.erase("saved_at_utc")
	return data


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event, true); await process_frame
	event = InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = false
	root.push_input(event, true); await process_frame


func open_home() -> Control:
	check(change_scene_to_file(HUB) == OK, "Home scene loads")
	await settle()
	return current_scene as Control


func run() -> void:
	var save: Node = root.get_node("GlobalSave")
	var navigation: Node = root.get_node("TaskNavigation")
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test("user://night-narrative-save.json", "user://night-narrative-workbench.json")
	navigation.last_visited_task = ""
	var before: Dictionary = snapshot()
	var hub: Control = await open_home()
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		hub = await open_home()
		for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1440,900)]:
			root.size = dimensions; root.content_scale_size = dimensions
			await settle()
			var replay := hub.find_child("ReplayYiIntroduction", true, false) as Button
			replay.grab_focus(); replay.pressed.emit(); await settle()
			var introduction: Control = hub.yi_introduction
			check(introduction.visible and not introduction.start_button.visible and not introduction.skip_button.visible, "Replay only returns Home in " + locale)
			check(root.gui_get_focus_owner() == introduction.close_button, "Replay focuses its available action")
			await key(KEY_TAB)
			check(root.gui_get_focus_owner() == introduction.close_button, "Replay keyboard focus stays inside the introduction")
			check(root.get_visible_rect().encloses(introduction.close_button.get_global_rect()), "Replay return action fits " + str(dimensions))
			await key(KEY_ESCAPE)
			check(not introduction.visible and not hub.options_overlay.visible and root.gui_get_focus_owner() == replay, "Escape dismisses only the introduction and restores Home focus")
		check(snapshot() == before, "Replay, resize and dismissal do not write progress")
		var primary := hub.find_child("TaskTree", true, false) as Button
		if primary == null: primary = hub.find_child("RecommendedJourneyAction", true, false) as Button
		primary.grab_focus(); primary.pressed.emit(); await settle()
		check(current_scene == hub and hub.yi_introduction.visible, "Fresh Home Start opens optional context before the actual task")
		check(hub.yi_introduction.start_button.visible and hub.yi_introduction.skip_button.visible, "Fresh context offers both Begin and Skip")
		await key(KEY_TAB)
		check(root.gui_get_focus_owner() == hub.yi_introduction.skip_button, "Begin and Skip are adjacent keyboard actions")
		check(snapshot() == before, "Opening context does not earn completion")
		if locale == "zh_CN":
			await key(KEY_ESCAPE)
		else:
			var offline: Node = root.get_node("OfflineFeedback")
			var old_setting: Variant = ProjectSettings.get_setting("playtest/offline_tester", false)
			ProjectSettings.set_setting("playtest/offline_tester", true)
			offline.open_panel(); await settle()
			check(offline.backdrop.visible and paused and hub.yi_introduction.visible, "Existing offline feedback can open over the introduction")
			offline.close_panel(); await settle()
			check(not paused and hub.yi_introduction.visible and root.gui_get_focus_owner() == hub.yi_introduction.skip_button, "Feedback dismissal resumes introduction with its prior focus")
			ProjectSettings.set_setting("playtest/offline_tester", old_setting)
			hub.yi_introduction.skip_button.pressed.emit(); await settle()
	check(current_scene != null and current_scene.scene_file_path == HARDWARE, "Skip enters the actual Hardware Foundations scene")
	var main: Control = current_scene
	if main == null or main.scene_file_path != HARDWARE:
		quit(1); return
	check(main.current_level_id == &"tutorial" and main.tutorial_next_button.disabled, "Actual navigation opens the unearned first tutorial")
	check(not main.completed_levels.get(&"tutorial", false) and not main.level_completion_overlay.visible, "Skipping grants neither completion nor response")
	main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	main.input_a_button.button_pressed = true
	main._run_debug()
	main._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
	check(not main.completed_levels.get(&"tutorial", false), "Four actual actions cannot bypass reconnection")
	main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await settle()
	check(main.completed_levels.get(&"tutorial", false) and main.level_completion_overlay.visible, "Five real tutorial actions trigger the existing completion event")
	check(main.level_completion_overlay.yi_response_label.text.contains("NOT") and main.level_completion_overlay.yi_response_label.text.contains("1 → 0"), "Completion response reflects the real NOT rule, including the unlit result")
	check(main.level_completion_overlay.music_cue_count == 1, "Narrative adds no extra completion cue")
	main._save_active_workbench()
	check(save.save_game(true), "Built work and earned completion can be saved")
	var earned: Dictionary = snapshot()
	hub = await open_home()
	var primary := hub.find_child("TaskTree", true, false) as Button
	if primary == null: primary = hub.find_child("RecommendedJourneyAction", true, false) as Button
	primary.pressed.emit(); await settle()
	check(current_scene.scene_file_path == HARDWARE, "Returning Home resumes actual saved work without repeating context")
	main = current_scene
	check(main.completed_levels.get(&"tutorial", false) and not main.level_completion_overlay.visible, "Revisit does not re-award the narrative or completion")
	check(snapshot() == earned, "Resume preserves the earned save authority")
	for locale: bool in [false, true]:
		check(Catalog.completion_response(&"chapter_1", &"cpu_speed", locale).length() > 0, "Representative middle-game response is available in both languages")
		check(Catalog.completion_response(&"unknown", &"tutorial", locale).is_empty(), "Unknown task identity cannot borrow a tutorial claim")
	if navigation.candidate_journey_enabled():
		navigation.last_visited_task = "prediction/regular"
		hub = await open_home()
		check(not navigation.has_resume() and navigation.next_task_key() == "prediction/regular", "Temporary Prediction has a real non-resume destination")
		primary = hub.find_child("RecommendedJourneyAction", true, false) as Button
		primary.pressed.emit(); await settle()
		check(current_scene.scene_file_path == "res://experiments/prediction/lab.tscn", "Temporary Prediction reopens its real workbench without NOT introduction")
		check(snapshot() == earned, "Temporary exploration entry does not alter earned core authority")
		print("TEMPORARY_ROUTE_CHECK: actual Prediction reopen exercised")
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "night narrative controller integration (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)
