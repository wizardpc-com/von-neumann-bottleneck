extends "res://tests/test_performance_player_input.gd"
## Actual capstone completion, then language-button input within its response.
const LabState = preload("res://src/lab/lab_state.gd")
const Dialogues = preload("res://src/lab/chapter_dialogues.gd")
const Naming = preload("res://src/campaign/journey_naming.gd")
const CHAPTER := "chapter_2/capstone"

func finish() -> void:
	var file := FileAccess.open(evidence_root + "language-ui-observations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(observations, "\t"))
	print("Terminal language checks: %d; failures: %d" % [observations.size(), failures.size()])
	if failures.is_empty(): print("PASS: terminal language continuity")
	quit(0 if failures.is_empty() else 1)

func arrive(path: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 8000
	while (current_scene == null or current_scene.scene_file_path != path) and Time.get_ticks_msec() < deadline:
		await process_frame
	var reached: bool = current_scene != null and current_scene.scene_file_path == path
	check(reached, "Scene transition reaches " + path)
	await settle(12)
	return reached

func switch_language(expected: Dictionary, answer: bool = false) -> void:
	var lab: Control = current_scene.laboratory
	var was_english: bool = lab.english
	var completed: Array[String] = LabState.completed_keys(LabState.tasks())
	var read_state: String = FileAccess.get_file_as_string(LabState.PATH)
	var visits: int = LabState.visits()
	await press(lab.terminal.language_button)
	await create_timer(1.4).timeout
	await settle(12)
	lab = current_scene.laboratory
	check(lab.english != was_english, "The actual language button changes the displayed language.")
	var locale: String = "en" if lab.english else "zh"
	var expected_text: String = str(expected["answer_" + locale] if answer else expected[locale])
	check(lab.terminal.message.text == expected_text, "Language change retains the same response or answer in the selected language.")
	check(LabState.completed_keys(LabState.tasks()) == completed and FileAccess.get_file_as_string(LabState.PATH) == read_state, "Language changes do not alter earned progress or archive/read state.")
	check(LabState.visits() == visits and lab._language_checkpoint.is_empty(), "The language reload consumes its temporary view without counting another laboratory visit.")
	if answer:
		check(lab.terminal.echo.visible and lab.terminal.echo.text.ends_with(str(expected[locale])), "The selected reply is retained and translated with its answer.")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("game/reduced_motion", true)
	change_scene_to_file("res://src/ui/prototype_hub.tscn")
	await settle(12)
	check(LabState.completed_keys(LabState.tasks()).is_empty(), "The isolated language test starts with no earned completion.")
	check(root.get_node("TaskNavigation").enter(CHAPTER), "Test access enters the capstone without granting its completion.")
	await settle(12)
	ui = current_scene
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	await only_tool(&"mission")
	await press(ui.mission_judgment_buttons[&"repeated_far_fetch"])
	await only_tool(&"cache")
	await press(ui.cache_card_buttons[4])
	check(ui.current_cache_lines == 4, "The requested cache modification is actually applied.")
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	await only_tool(&"mission")
	await press(ui.mission_finish_button)
	check(root.get_node("LocalityChapter").completed_levels().get(&"capstone", false), "The real successful experiment earns the chapter response.")
	if not ui.level_completion_overlay.visible: await finish(); return
	await press(ui.level_completion_overlay.continue_button)
	await settle(12)
	await key(KEY_ESCAPE)
	await create_timer(1.4).timeout
	await settle(12)
	check(current_scene.laboratory.terminal.in_dialogue(), "Returning from the actual completion opens the chapter response.")
	await shot("before-language-question")
	await switch_language(Dialogues.DIALOGUES[CHAPTER][0])
	await shot("after-language-question")
	check(current_scene.laboratory.terminal.in_dialogue(), "Changing language does not discard the earned chapter conversation.")
	if not current_scene.laboratory.terminal.in_dialogue(): await finish(); return
	await switch_language(Dialogues.DIALOGUES[CHAPTER][0])
	check(current_scene.laboratory.terminal.choices.get_child_count() == 2, "Switching back preserves the original two choices without duplication.")
	ProjectSettings.set_setting("game/reduced_motion", false)
	ProjectSettings.set_setting("game/yi_text_speed", "slow")
	await press(current_scene.laboratory.terminal.choices.get_child(1))
	check(current_scene.laboratory.terminal.message.is_playing(), "The chosen answer is still being typed before switching language.")
	await switch_language(Dialogues.DIALOGUES[CHAPTER][0].replies[1], true)
	await shot("translated-answer")
	await click(current_scene.laboratory.terminal.message.get_global_rect().get_center())
	await press(current_scene.laboratory.terminal.choices.get_child(0))
	await switch_language(Dialogues.DIALOGUES[CHAPTER][1])
	check(not current_scene.laboratory.terminal.echo.visible, "The final exploration beat does not retain the earlier player reply.")
	await shot("translated-exploration")
	await press(current_scene.laboratory.terminal.dialogue_skip)
	await press(current_scene.laboratory.terminal.language_button)
	await create_timer(1.4).timeout
	await settle(12)
	var lab: Control = current_scene.laboratory
	check(not lab.terminal.in_dialogue() and lab.terminal.response.is_empty(), "After Back, changing language does not resurrect the conversation.")
	await shot("after-exit-language")
	# Ordinary completion presentation fixture for the task actually earned above.
	var task: Dictionary = {}
	for row: Dictionary in LabState.tasks():
		if str(row.key) == CHAPTER: task = row
	var state: Dictionary = lab.terminal.state.duplicate(true)
	state["response"] = {"task": task}
	lab.terminal.configure(state)
	await press(lab.terminal.language_button)
	await create_timer(1.4).timeout
	await settle(12)
	lab = current_scene.laboratory
	var localized_title: String = ""
	for row: Dictionary in LabState.tasks():
		if str(row.key) == CHAPTER: localized_title = Naming.plain_title(str(row.title))
	check(not lab.terminal.response.is_empty() and lab.terminal.message.text.contains(localized_title), "Ordinary completion feedback survives with the current-language task title.")
	await shot("ordinary-response-fixture")
	await press(lab.terminal.find_child("TerminalJourney",true,false))
	if not await arrive("res://src/campaign/task_tree.tscn"): await finish(); return
	await key(KEY_ESCAPE)
	if not await arrive("res://src/ui/prototype_hub.tscn"): await finish(); return
	await create_timer(1.4).timeout
	await settle(12)
	lab = current_scene.laboratory
	check(not lab.terminal.in_dialogue() and lab.terminal.response.is_empty(), "Leaving and returning does not retain the temporary language checkpoint.")
	check(LabState.completed_keys(LabState.tasks()) == [CHAPTER], "Language and navigation never complete another task.")
	await finish()
