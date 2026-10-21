extends "res://tests/test_terminal_language_input.gd"
## Uses the earned chapter route, switching through the existing F10 settings.

func check_settings_bounds(host: Control) -> void:
	var panel: Control = host.find_child("ChapterOptionsPanel", true, false)
	check(panel.get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "The visible settings panel fits the 720p viewport after text reflow.")
	check(panel.get_viewport().get_visible_rect().encloses(host.options_resume_button.get_global_rect()), "The settings return button is inside the visible viewport.")

func finish() -> void:
	if failures.is_empty():
		# Presentation fixture for the task earned by the inherited route.
		var lab: Control = current_scene.laboratory
		var state: Dictionary = lab.terminal.state.duplicate(true)
		for row: Dictionary in LabState.tasks():
			if str(row.key) == CHAPTER: state["response"] = {"task": row}
		lab.terminal.configure(state)
		var was_english: bool = lab.english
		var visits: int = LabState.visits()
		var read_state: String = FileAccess.get_file_as_string(LabState.PATH)
		await press(lab.terminal.find_child("TerminalSettings", true, false))
		check(current_scene.options_overlay.visible, "The terminal Settings button opens the hub settings page.")
		check_settings_bounds(current_scene)
		await choose(current_scene.options_overlay.find_child("LanguageChoice", true, false), 0 if was_english else 1)
		await create_timer(1.4).timeout
		await settle(12)
		check(current_scene.options_overlay.visible, "The hub settings page remains open after the language reload.")
		check_settings_bounds(current_scene)
		await shot("hub-settings")
		await press(current_scene.options_resume_button)
		await settle(12)
		lab = current_scene.laboratory
		var title: String = ""
		for row: Dictionary in LabState.tasks():
			if str(row.key) == CHAPTER: title = Naming.plain_title(str(row.title))
		check(not current_scene.options_overlay.visible and lab.english != was_english, "The visible return button closes the translated hub settings.")
		check(not lab.terminal.response.is_empty() and lab.terminal.message.text.contains(title), "Hub settings preserve the ordinary completion fixture with its translated task title.")
		check(LabState.visits() == visits and FileAccess.get_file_as_string(LabState.PATH) == read_state, "Hub settings do not change visits or archive/read state.")
		check(LabState.completed_keys(LabState.tasks()) == [CHAPTER] and lab._language_checkpoint.is_empty(), "Both settings entry points leave only the earned task and consume the transient view.")
		await shot("hub-completion-fixture")
	await super.finish()

func switch_language(expected: Dictionary, answer: bool = false) -> void:
	var lab: Control = current_scene.laboratory
	var was_english: bool = lab.english
	var completed: Array[String] = LabState.completed_keys(LabState.tasks())
	var read_state: String = FileAccess.get_file_as_string(LabState.PATH)
	var visits: int = LabState.visits()
	var mode: Node = root.get_node("WindowMode")
	await key(KEY_F10)
	await settle(12)
	check(not is_instance_valid(mode.settings_layer) and current_scene.options_overlay.visible, "F10 opens settings inside the terminal while the chapter response is visible.")
	if not current_scene.options_overlay.visible: return
	check_settings_bounds(current_scene)
	var language: OptionButton = current_scene.options_overlay.find_child("LanguageChoice", true, false)
	await choose(language, 0 if was_english else 1)
	await create_timer(1.4).timeout
	await settle(12)
	check(current_scene.options_overlay.visible, "Terminal settings remain open after changing language.")
	check_settings_bounds(current_scene)
	await press(current_scene.options_resume_button)
	await settle(12)
	lab = current_scene.laboratory
	check(not is_instance_valid(mode.settings_layer) and not current_scene.options_overlay.visible, "The visible return button closes F10 settings and returns to the terminal.")
	check(lab.english != was_english, "The settings selector changes the displayed language.")
	var locale: String = "en" if lab.english else "zh"
	var expected_text: String = str(expected["answer_" + locale] if answer else expected[locale])
	check(lab.terminal.message.text == expected_text, "Settings language change retains the current response or selected answer.")
	check(LabState.completed_keys(LabState.tasks()) == completed and FileAccess.get_file_as_string(LabState.PATH) == read_state, "Settings language changes preserve earned progress and archive/read state.")
	check(LabState.visits() == visits and lab._language_checkpoint.is_empty(), "Settings reload consumes the temporary view without adding a laboratory visit.")
	if answer:
		check(lab.terminal.echo.visible and lab.terminal.echo.text.ends_with(str(expected[locale])), "The selected reply stays with its translated answer after settings close.")

func press(control: Control) -> void:
	if control != null and control.get_viewport() is SubViewport:
		var display: Control = current_scene.laboratory.terminal_pages
		var deadline: int = Time.get_ticks_msec() + 2000
		while display.modulate.a < 1.0 and Time.get_ticks_msec() < deadline: await process_frame
		check(display.modulate.a == 1.0 and control.is_visible_in_tree(), "Terminal control is revealed before input")
		await click(display.position + control.get_global_rect().get_center() / Vector2(display.resolution) * display.size)
	else:
		await super.press(control)
