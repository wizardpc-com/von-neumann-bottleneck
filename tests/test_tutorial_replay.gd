extends SceneTree

const SCENE_PATH = "res://src/hardware_foundations/hardware_foundations.tscn"
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func run() -> void:
	root.get_node("GameMode").set_mode(&"game")
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test("user://tutorial-replay-save.json", "user://tutorial-replay-workbench.json")
	var main: Control = await open_tutorial()
	check(main.tutorial_next_button.disabled, "Fresh tutorial keeps the five-action next-step gate")
	check(main.mission_summary_button.text.contains("0/5"), "Fresh tutorial starts with no earned actions")
	for label: Label in main.tutorial_check_labels.values():
		check(label.text.begins_with("○"), "Fresh tutorial checklist is incomplete")
	main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	main.input_a_button.button_pressed = true
	main._run_debug()
	main._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
	check(not main.completed_levels.get(&"tutorial", false) and main.tutorial_next_button.disabled
		and main.mission_summary_button.text.contains("4/5"), "Four interactions cannot bypass the final reconnection requirement")
	main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await process_frame
	check(main.completed_levels.get(&"tutorial", false), "Five actual controller interactions earn tutorial completion")
	check(not main.tutorial_next_button.disabled, "First completion enables the existing next action")
	check(main.level_completion_overlay.visible and main.level_completion_overlay.music_cue_count == 1,
		"First completion still presents one completion cue")
	var signature: String = main._circuit_from_graph().canonical_signature()
	main._save_active_workbench()
	check(save.save_game(true), "Earned completion and the built circuit can be saved")
	main.queue_free()
	await process_frame
	check(save.load_game(), "Saved tutorial authority can be reloaded before a fresh scene")
	for locale: String in ["en", "zh_CN"]:
		root.get_node("Localization").set_locale(locale)
		main = await open_tutorial()
		var before: Dictionary = main.completed_levels.duplicate(true)
		check(main._circuit_from_graph().canonical_signature() == signature, "Revisit preserves saved circuit topology")
		check(not main.tutorial_created_wire and not main.tutorial_changed_input and not main.tutorial_valid_run
			and not main.tutorial_removed_wire and not main.tutorial_reconnected_wire,
			"Revisit does not manufacture current-session interactions or a new run")
		check(not main.tutorial_next_button.disabled and main.tutorial_next_button.text == main._t(&"hardware.tutorial.begin_challenge"),
			"Earned tutorial keeps its next action on a fresh scene")
		check(main.mission_summary_button.text == main._t(&"hardware.goal.tutorial_complete"),
			"Revisit goal acknowledges earned completion in " + locale)
		for label: Label in main.tutorial_check_labels.values():
			check(label.text.begins_with("✓") and label.get_theme_color("font_color") == main.GOOD,
				"Revisit checklist acknowledges the five already-earned requirements")
		check(not main.level_completion_overlay.visible and main.level_completion_overlay.music_cue_count == 0,
			"Revisit does not replay the completion overlay or cue")
		check(not main.mission_briefing_active and main.mission_compact, "Revisit retains optional compact mission")
		main._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
		check(not main.tutorial_next_button.disabled and main.mission_summary_button.text == main._t(&"hardware.goal.tutorial_complete"),
			"An incomplete practice circuit cannot revoke previously earned tutorial guidance")
		check(not main.tutorial_valid_run, "Editing a replay circuit does not manufacture a new practice run")
		main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
		main.input_a_button.button_pressed = true
		main._run_debug()
		await process_frame
		check(main.completed_levels == before and not main.level_completion_overlay.visible
			and main.level_completion_overlay.music_cue_count == 0, "Repeated practice never re-awards completion")
		main.tutorial_next_button.pressed.emit()
		await process_frame
		check(main.current_level_id == &"half_adder", "The restored next action enters the unchanged Half Adder task")
		main.queue_free()
		await process_frame
	print("PASS: tutorial earned-completion replay" if failures.is_empty() else "FAIL: tutorial earned-completion replay")
	quit(0 if failures.is_empty() else 1)

func open_tutorial() -> Control:
	var main: Control = load(SCENE_PATH).instantiate()
	root.add_child(main)
	for frame: int in 3:
		await process_frame
	main.workbench_store = load("res://src/hardware_foundations/circuit_workbench_store.gd").new(root.get_node("GlobalSave").workbench_storage_path)
	main._start_campaign_level(&"tutorial")
	for frame: int in 4:
		await process_frame
	return main
