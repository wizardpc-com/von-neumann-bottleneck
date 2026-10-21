extends "res://tests/test_performance_player_input.gd"
## Test-mode capstone entry; actual experiment, completion and chapter response.
const LabState = preload("res://src/lab/lab_state.gd")

func finish() -> void:
	var file := FileAccess.open(evidence_root + root.get_node("Localization").current_locale() + "-ui-observations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(observations, "\t"))
	print("Chapter return checks: %d; failures: %d" % [observations.size(), failures.size()])
	if failures.is_empty(): print("PASS: earned chapter return input")
	quit(0 if failures.is_empty() else 1)

func home() -> void:
	await key(KEY_ESCAPE)
	await create_timer(1.4).timeout
	await settle(12)
	check(current_scene.scene_file_path == "res://src/ui/prototype_hub.tscn", "Map Escape returns to the laboratory.")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("game/reduced_motion", true)
	change_scene_to_file("res://src/ui/prototype_hub.tscn")
	await settle(12)
	check(LabState.completed_keys(LabState.tasks()).is_empty(), "Isolated Test-mode access grants no completion.")
	check(root.get_node("TaskNavigation").enter("chapter_2/capstone"), "Test-mode navigation enters capstone without granting prerequisites.")
	await settle(12)
	ui = current_scene
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	await only_tool(&"mission")
	await press(ui.mission_judgment_buttons[&"repeated_far_fetch"])
	check(ui._capstone_diagnosis_complete(), "The visible diagnosis reply is accepted before modification.")
	if not ui._capstone_diagnosis_complete(): await shot("failed-diagnosis"); await finish(); return
	await only_tool(&"cache")
	check(ui.instrument_host.get_global_rect().encloses(ui.instrument_windows[&"cache"].get_global_rect()), "Nearby Storage stays inside the desktop so its visible choices can receive input.")
	await press(ui.cache_card_buttons[4])
	check(ui.current_cache_lines == 4, "The visible cache choice applies four lines before running.")
	if ui.current_cache_lines != 4: await shot("failed-cache-choice"); await finish(); return
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	await only_tool(&"mission")
	check(ui.current_trace.passed and ui.current_goal_met, "The modified official run meets the actual capstone target.")
	if not ui.current_goal_met: await shot("failed-target"); await finish(); return
	await press(ui.mission_finish_button)
	check(root.get_node("LocalityChapter").completed_levels().get(&"capstone",false), "The real diagnosis and successful modified run earn capstone completion.")
	if not ui.level_completion_overlay.visible: await finish(); return
	await press(ui.level_completion_overlay.continue_button)
	await settle(12)
	check(on_task_tree(), "Completion Continue returns to the journey map.")
	await home()
	var lab: Control = current_scene.laboratory
	var terminal: Control = lab.terminal
	check(terminal.in_dialogue() and terminal.response.get("chapter",{}) == lab.CHAPTER_RESPONSES["chapter_2/capstone"], "Actual earned capstone selects its chapter conversation.")
	check(terminal.choices.get_child_count() == 2 and terminal.dialogue_skip.visible, "The reflection offers two replies and an immediate exit.")
	var completed: Array[String] = LabState.completed_keys(LabState.tasks())
	check(completed == ["chapter_2/capstone"], "Only the earned capstone is complete; test access does not complete the prior journey.")
	await shot("earned-chapter-question")
	await press(terminal.choices.get_child(0))
	check(terminal.echo.visible and terminal.message.text.contains("new task" if lab.english else "换任务重测"), "Choosing another-task reflection answers without claiming universal speed.")
	await shot("earned-chapter-answer")
	await press(terminal.choices.get_child(0))
	check(terminal.in_dialogue() and terminal.choices.get_child_count() == 1, "The final beat offers a return action, not a route selector.")
	check(terminal.message.text.contains("Journey map" if lab.english else "旅程地图"), "The exploration invitation identifies the existing place to choose a route.")
	await shot("chapter-next-exploration")
	await press(terminal.choices.get_child(0))
	check(not terminal.in_dialogue() and terminal.primary.visible and terminal.secondary.visible, "Return restores the existing terminal navigation.")
	check(LabState.completed_keys(LabState.tasks()) == completed, "Reading and replying do not award progress.")
	await press(terminal.archive_button)
	await settle(12)
	check(lab.archive.visible and lab.archive.selected == "nearby", "The earned chapter opens its associated archive page.")
	check(lab.archive.note_label.text.contains("awaiting confirmation" if lab.english else "待确认"), "The historical story remains visibly marked as an unconfirmed draft.")
	await shot("chapter-archive-candidate")
	await key(KEY_ESCAPE)
	await press(terminal.find_child("TerminalJourney",true,false))
	await create_timer(0.3).timeout
	await settle(12)
	check(on_task_tree(), "The existing Journey map action opens the place where routes are selected.")
	await shot("chapter-journey-map")
	await home()
	lab = current_scene.laboratory
	check(lab.terminal.response.is_empty() and not lab.terminal.in_dialogue(), "Returning again does not replay the same completed chapter as a new achievement.")
	check(LabState.completed_keys(LabState.tasks()) == completed, "Archive and map navigation preserve earned completion exactly.")
	await finish()
