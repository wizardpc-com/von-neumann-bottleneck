extends "res://tests/test_terminal_language_input.gd"
## Uses the earned chapter route, switching through the existing F10 settings.

func check_settings_bounds(host: Control) -> void:
	var panel: Control = host.find_child("ChapterOptionsPanel", true, false)
	check(root.get_visible_rect().encloses(panel.get_global_rect()), "The visible settings panel fits the 720p viewport after text reflow.")
	check(root.get_visible_rect().encloses(host.options_resume_button.get_global_rect()), "The settings return button is inside the visible viewport.")

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
	check(is_instance_valid(mode.settings_layer), "F10 opens the existing settings while the chapter response is visible.")
	if not is_instance_valid(mode.settings_layer): return
	check_settings_bounds(mode.settings_layer.get_child(0))
	var language: OptionButton = mode.settings_layer.find_child("LanguageChoice", true, false)
	await choose(language, 0 if was_english else 1)
	await create_timer(1.4).timeout
	await settle(12)
	check(is_instance_valid(mode.settings_layer), "Settings remain open after changing language.")
	check_settings_bounds(mode.settings_layer.get_child(0))
	await press(mode.settings_layer.get_child(0).options_resume_button)
	await settle(12)
	lab = current_scene.laboratory
	check(not is_instance_valid(mode.settings_layer), "The visible return button closes F10 settings and returns to the terminal.")
	check(lab.english != was_english, "The settings selector changes the displayed language.")
	var locale: String = "en" if lab.english else "zh"
	var expected_text: String = str(expected["answer_" + locale] if answer else expected[locale])
	check(lab.terminal.message.text == expected_text, "Settings language change retains the current response or selected answer.")
	check(LabState.completed_keys(LabState.tasks()) == completed and FileAccess.get_file_as_string(LabState.PATH) == read_state, "Settings language changes preserve earned progress and archive/read state.")
	check(LabState.visits() == visits and lab._language_checkpoint.is_empty(), "Settings reload consumes the temporary view without adding a laboratory visit.")
	if answer:
		check(lab.terminal.echo.visible and lab.terminal.echo.text.ends_with(str(expected[locale])), "The selected reply stays with its translated answer after settings close.")
