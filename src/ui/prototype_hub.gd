extends Control

const GameModeSelectorType = preload("res://src/ui/game_mode_selector.gd")
const FullscreenButtonType = preload("res://src/ui/fullscreen_button.gd")
const TerminologyHandbookType = preload("res://src/ui/terminology_handbook.gd")
const UiTypographyType = preload("res://src/ui/ui_typography.gd")

const BACKGROUND := Color("09101d")
const PANEL := Color("172033")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const DANGER := Color("ff6b7d")
const PURPLE := Color("bc8cff")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")

var mode_selector: GameModeSelectorType
var mode_description_label: Label
var fullscreen_button: FullscreenButtonType
var save_actions: Control
var save_recovery_label: Label
var continue_button: Button
var new_game_button: Button
var new_game_overlay: Control
var new_game_clear_workbenches: CheckBox
var new_game_status: Label
var new_game_confirm_button: Button
var system_entry_button: Button
var layout_entry_button: Button
var overlap_entry_button: Button
var locality_entry_button: Button
var terminology_handbook: TerminologyHandbookType
var options_overlay: Control
var options_resume_button: Button
var options_fullscreen_button: Button
var options_export_button: Button
var options_export_status: Label
var options_open_export_folder_button: Button
var latest_export_path: String = ""
var options_quit_button: Button
var options_previous_focus: Control


func _ready() -> void:
	_build_theme()
	_build_interface()
	GameMode.mode_changed.connect(_on_game_mode_changed)
	SystemChapter.progression_changed.connect(_refresh_locality_entry)
	LocalityChapter.progression_changed.connect(_refresh_overlap_entry)
	LocalityChapter.progression_changed.connect(_refresh_layout_entry)
	WindowMode.window_mode_changed.connect(_on_window_mode_changed)
	_refresh_mode_description()
	if WindowMode.reopen_settings:
		WindowMode.reopen_settings=false; call_deferred("_open_options_menu")
	var choice := preload("res://src/playtest/sharing_first_choice.gd").new(); add_child(choice)
	var arguments: PackedStringArray = GameMode.capture_arguments()
	if "--capture-new-game" in arguments:
		call_deferred("_open_new_game_confirmation")
	elif "--capture-options" in arguments:
		call_deferred("_open_options_menu")
	elif "--capture-terminology" in arguments:
		terminology_handbook.call_deferred("open_handbook", &"accumulator")
	elif "--capture-hardware" in arguments:
		get_tree().call_deferred("change_scene_to_file", "res://src/hardware_foundations/hardware_foundations.tscn")
	elif "--capture-system" in arguments or "--capture-system-run" in arguments or "--capture-system-map" in arguments:
		get_tree().call_deferred("change_scene_to_file", "res://src/system_lab/system_lab.tscn")
	elif (
		"--capture-chapter2-map" in arguments
		or "--capture-chapter2-capstone" in arguments
		or "--capture-demo" in arguments
		or "--capture-profiler" in arguments
		or "--capture-workspace" in arguments
		or "--capture-program-draft" in arguments
		or "--capture-row" in arguments
		or "--capture-playtest-export" in arguments
	):
		get_tree().call_deferred("change_scene_to_file", "res://src/ui/main.tscn")


func _input(event: InputEvent) -> void:
	if terminology_handbook != null and terminology_handbook.handle_escape(event):
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_escape_press(event):
		return
	if new_game_overlay != null and new_game_overlay.visible:
		_close_new_game_confirmation()
	elif options_overlay.visible:
		_close_options_menu()
	else:
		_open_options_menu()
	get_viewport().set_input_as_handled()


func _build_theme() -> void:
	var hub_theme := Theme.new()
	hub_theme.default_font_size = UiTypographyType.BODY_SIZE
	for control_type: String in ["Label", "Button", "OptionButton"]:
		hub_theme.set_color("font_color", control_type, TEXT)
	hub_theme.set_constant("separation", "VBoxContainer", 14)
	hub_theme.set_constant("separation", "HBoxContainer", 18)
	hub_theme.set_stylebox("panel", "PanelContainer", _stylebox(PANEL, 14, 1, Color("293650")))
	hub_theme.set_stylebox("normal", "Button", _stylebox(Color("26334a"), 9, 1, Color("354866")))
	hub_theme.set_stylebox("hover", "Button", _stylebox(Color("30435f"), 9, 2, ACCENT))
	hub_theme.set_stylebox("pressed", "Button", _stylebox(Color("17283e"), 9, 2, ACCENT))
	preload("res://src/ui/instrument_theme.gd").apply_to(hub_theme)
	theme = hub_theme


func _build_interface() -> void:
	var background := preload("res://src/ui/technical_backdrop.gd").new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 72)
	margin.add_theme_constant_override("margin_bottom", 56)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "ChapterScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var title := Label.new()
	title.text = Localization.text(&"game.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTypographyType.HERO_TITLE_SIZE)
	title.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
	title.add_theme_color_override("font_color", ACCENT)
	content.add_child(title)
	var mode_center := CenterContainer.new()
	content.add_child(mode_center)
	mode_selector = GameModeSelectorType.new()
	mode_selector.name = "GameModeSelector"
	mode_center.add_child(mode_selector)
	mode_description_label = Label.new()
	mode_description_label.visible = GameMode.developer_tools_enabled()
	mode_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_description_label.add_theme_color_override("font_color", WARNING if GameMode.is_test_mode() else MUTED)
	content.add_child(mode_description_label)
	_build_tree_entry(content)
	save_recovery_label = Label.new()
	save_recovery_label.name = "SaveRecoveryNotice"
	save_recovery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_recovery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_recovery_label.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	content.add_child(save_recovery_label)
	var cards := HBoxContainer.new()
	cards.name = "ChapterCards"
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cards)
	cards.add_child(_build_card(
		Localization.text(&"hub.hardware.title"),
		Localization.text(&"hub.hardware.eyebrow"),
		Localization.text(&"hub.hardware.description"),
		Localization.text(&"hub.hardware.play"),
		GOOD,
		"res://src/hardware_foundations/hardware_foundations.tscn"
	))
	cards.add_child(_build_card(
		Localization.text(&"hub.system.title"),
		Localization.text(&"hub.system.eyebrow"),
		Localization.text(&"hub.system.description"),
		Localization.text(&"hub.system.open"),
		WARNING,
		"res://src/system_lab/system_lab.tscn",
		&"system"
	))
	cards.add_child(_build_card(
		Localization.text(&"hub.locality.title"),
		Localization.text(&"hub.locality.eyebrow"),
		Localization.text(&"hub.locality.description"),
		Localization.text(&"hub.locality.open"),
		ACCENT,
		"res://src/ui/main.tscn",
		&"locality"
	))
	cards.add_child(_build_card(
		Localization.text(&"overlap.title"), Localization.text(&"overlap.hub.eyebrow"),
		Localization.text(&"overlap.map_goal"), Localization.text(&"overlap.map"), PURPLE,
		"res://src/overlap_chapter/overlap_chapter.tscn", &"overlap"
	))
	cards.add_child(_build_card(
		Localization.text(&"layout.hub.title"),Localization.text(&"layout.hub.eyebrow"),
		Localization.text(&"layout.hub.description"),Localization.text(&"layout.hub.open"),Color("f4a6cb"),
		"res://src/layout_chapter/layout_chapter.tscn",&"layout"
	))
	var note := Label.new()
	note.name = "BuildIdentifier"
	note.text = Localization.text(&"hub.note")+"   ·   "+String(ProjectSettings.get_setting("application/config/version", ""))
	note.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", MUTED)
	content.add_child(note)
	fullscreen_button = FullscreenButtonType.new()
	add_child(fullscreen_button)
	fullscreen_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fullscreen_button.offset_left = -116.0
	fullscreen_button.offset_top = 16.0
	fullscreen_button.offset_right = -16.0
	fullscreen_button.offset_bottom = 60.0
	terminology_handbook = TerminologyHandbookType.new()
	add_child(terminology_handbook)
	_build_options_menu()
	var settings_button := Button.new(); settings_button.text=Localization.text(&"hub.settings.settings_esc")
	add_child(settings_button); settings_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	settings_button.offset_left=-278; settings_button.offset_right=-128; settings_button.offset_top=16; settings_button.offset_bottom=60
	settings_button.pressed.connect(_open_options_menu)
	_build_new_game_confirmation()
	_refresh_save_actions()


func _build_tree_entry(content: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "TaskTreeEntry"
	panel.add_theme_stylebox_override("panel", _stylebox(Color("102a36"), 10, 2, ACCENT))
	content.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 38)
	panel.add_child(row)
	var primary := VBoxContainer.new()
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(primary)
	var heading := Label.new()
	heading.text = Localization.text(&"hub.tree.title")
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", ACCENT)
	primary.add_child(heading)
	var description := Label.new()
	description.text = Localization.text(&"hub.tree.description")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", TEXT)
	primary.add_child(description)
	var button := Button.new()
	button.name = "TaskTree"
	button.text = Localization.text(&"hub.tree.enter")
	button.custom_minimum_size = Vector2(0, 66)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("071b28"))
	button.add_theme_color_override("font_hover_color", Color("071b28"))
	button.add_theme_color_override("font_focus_color", Color("071b28"))
	button.add_theme_color_override("font_pressed_color", Color("071b28"))
	button.add_theme_stylebox_override("normal", _stylebox(ACCENT, 8, 1, ACCENT))
	button.add_theme_stylebox_override("hover", _stylebox(Color("9ceaff"), 8, 2, Color.WHITE))
	button.pressed.connect(func() -> void: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE))
	primary.add_child(button)
	var secondary := VBoxContainer.new()
	secondary.custom_minimum_size.x = 530
	row.add_child(secondary)
	var preview := preload("res://src/ui/task_tree_preview.gd").new()
	secondary.add_child(preview)
	_build_save_actions(secondary)
	call_deferred("_focus_tree_entry", button)


func _focus_tree_entry(button: Button) -> void:
	# Follow-focus must run after wrapped labels have settled their minimum sizes.
	# Otherwise a narrow first frame can scroll the main entry out of view.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(button) or options_overlay.visible or new_game_overlay.visible: return
	button.grab_focus()
	await get_tree().process_frame
	var scroll: ScrollContainer = find_child("ChapterScroll",true,false)
	if is_instance_valid(scroll): scroll.scroll_vertical=0


func _build_save_actions(content: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.name = "SaveActions"
	content.add_child(center)
	save_actions = center
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	center.add_child(row)
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = Localization.text(&"hub.save.continue")
	continue_button.custom_minimum_size = Vector2(210.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	continue_button.pressed.connect(_continue_game)
	row.add_child(continue_button)
	new_game_button = Button.new()
	new_game_button.name = "NewGameButton"
	new_game_button.text = Localization.text(&"hub.save.new_game")
	new_game_button.custom_minimum_size = Vector2(210.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	new_game_button.pressed.connect(_open_new_game_confirmation)
	row.add_child(new_game_button)


func _build_new_game_confirmation() -> void:
	new_game_overlay = Control.new()
	new_game_overlay.name = "NewGameConfirmationOverlay"
	new_game_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	new_game_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	new_game_overlay.z_index = 1200
	add_child(new_game_overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color("050a12", 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	new_game_overlay.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_game_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "NewGameConfirmationPanel"
	panel.custom_minimum_size = Vector2(660.0, 390.0)
	panel.add_theme_stylebox_override("panel", _stylebox(PANEL, 16, 2, DANGER))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.text = Localization.text(&"hub.save.new_game.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	title.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
	title.add_theme_color_override("font_color", DANGER)
	column.add_child(title)
	var body := Label.new()
	body.text = Localization.text(&"hub.save.new_game.body")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", MUTED)
	column.add_child(body)
	new_game_clear_workbenches = CheckBox.new()
	new_game_clear_workbenches.name = "ClearGameWorkbenchesCheckBox"
	new_game_clear_workbenches.text = Localization.text(&"hub.save.new_game.clear_workbenches")
	column.add_child(new_game_clear_workbenches)
	new_game_status = Label.new()
	new_game_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_game_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_game_status.add_theme_color_override("font_color", DANGER)
	column.add_child(new_game_status)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(actions)
	var cancel := Button.new()
	cancel.name = "NewGameCancelButton"
	cancel.text = Localization.text(&"hub.save.new_game.cancel")
	cancel.custom_minimum_size = Vector2(210.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	cancel.pressed.connect(_close_new_game_confirmation)
	actions.add_child(cancel)
	new_game_confirm_button = Button.new()
	new_game_confirm_button.name = "NewGameConfirmButton"
	new_game_confirm_button.text = Localization.text(&"hub.save.new_game.confirm")
	new_game_confirm_button.custom_minimum_size = Vector2(210.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	new_game_confirm_button.add_theme_color_override("font_color", DANGER)
	new_game_confirm_button.pressed.connect(_confirm_new_game)
	actions.add_child(new_game_confirm_button)
	new_game_overlay.hide()


func _build_options_menu() -> void:
	options_overlay=Control.new(); options_overlay.name="ChapterOptionsOverlay"
	options_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_overlay.mouse_filter=Control.MOUSE_FILTER_STOP; options_overlay.z_index=1100; add_child(options_overlay)
	var backdrop := ColorRect.new(); backdrop.color=Color("050a12",0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); options_overlay.add_child(backdrop)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_overlay.add_child(center)
	var panel := PanelContainer.new(); panel.name="ChapterOptionsPanel"
	panel.add_theme_stylebox_override("panel",InstrumentTheme.panel(PANEL,ACCENT,8)); center.add_child(panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",14); panel.add_child(column)
	_settings_label(column,"hub.options.title",28)
	var scroll := ScrollContainer.new(); scroll.name="SettingsScroll"; scroll.follow_focus=true
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	var body := VBoxContainer.new(); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); scroll.add_child(body)
	_settings_label(body,"settings.interface",23)
	var language := OptionButton.new(); language.name="LanguageChoice"
	language.add_item("简体中文"); language.add_item("English")
	language.select(0 if Localization.current_locale()=="zh_CN" else 1)
	language.item_selected.connect(func(index: int) -> void:
		if Localization.set_preferred_locale(["zh_CN","en"][index]): call_deferred("_reload_settings_locale"))
	body.add_child(language)
	_settings_label(body,"settings.display",23)
	options_fullscreen_button=_options_button(""); options_fullscreen_button.name="OptionsFullscreenButton"
	options_fullscreen_button.pressed.connect(WindowMode.toggle_fullscreen); body.add_child(options_fullscreen_button)
	var reduced := CheckButton.new(); reduced.name="ReducedMotion"
	reduced.text=Localization.text(&"hub.settings.reduce_interface_motion")
	reduced.button_pressed=bool(ProjectSettings.get_setting("game/reduced_motion",false))
	reduced.toggled.connect(WindowMode.set_reduced_motion); body.add_child(reduced)
	var frame_choice := OptionButton.new(); frame_choice.name="FrameLimit"
	for key: String in ["60","120","display"]: frame_choice.add_item(Localization.text(StringName("hub.settings.frame_"+key)))
	frame_choice.select(maxi(0,[60,120,0].find(WindowMode.frame_limit)))
	frame_choice.item_selected.connect(func(index: int) -> void: WindowMode.set_frame_limit([60,120,0][index]))
	body.add_child(frame_choice)
	_settings_label(body,"hub.settings.background_rendering_uses_less_power_simulation_scores_are_unchan")
	_settings_label(body,"settings.audio",23)
	var sound := CheckButton.new(); sound.name="SoundEnabled"; sound.text=Localization.text(&"settings.sound")
	sound.button_pressed=WindowMode.sound_enabled; body.add_child(sound)
	var volume := HSlider.new(); volume.name="SoundVolume"; volume.max_value=100; volume.step=1
	volume.value=roundf(WindowMode.sound_volume*100); volume.custom_minimum_size.y=32
	volume.editable=WindowMode.sound_enabled; body.add_child(volume)
	var volume_label := Label.new(); volume_label.text="%d%%" % volume.value; body.add_child(volume_label)
	sound.toggled.connect(func(value: bool) -> void: WindowMode.set_sound(value,volume.value/100); volume.editable=value)
	volume.value_changed.connect(func(value: float) -> void: WindowMode.set_sound(sound.button_pressed,value/100); volume_label.text="%d%%" % value)
	_settings_label(body,"settings.privacy",23)
	_settings_label(body,"settings.privacy_hint")
	body.add_child(PlaytestMoments.make_button())
	_settings_label(body,"settings.support",23)
	var build := Label.new(); build.text=str(ProjectSettings.get_setting("application/config/version",""))
	build.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(build)
	options_export_button=_options_button(Localization.text(&"playtest.export.button")); options_export_button.name="OptionsExportPlaytestButton"
	options_export_button.pressed.connect(_export_playtest_data); body.add_child(options_export_button)
	var diagnostics := _options_button(Localization.text(&"settings.diagnostics")); diagnostics.name="ExportDiagnostics"
	diagnostics.pressed.connect(func() -> void:
		latest_export_path=preload("res://src/ui/support_diagnostics.gd").export_local()
		options_export_status.text=Localization.text(&"settings.export_failed" if latest_export_path.is_empty() else &"settings.export_ready")
		options_open_export_folder_button.visible=not latest_export_path.is_empty())
	body.add_child(diagnostics)
	_settings_label(body,"settings.diagnostics_hint")
	var logs := _options_button(Localization.text(&"settings.open_logs")); body.add_child(logs)
	logs.pressed.connect(func() -> void: OS.shell_open(ProjectSettings.globalize_path("user://")))
	options_export_status=Label.new(); options_export_status.name="OptionsExportStatus"
	options_export_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(options_export_status)
	options_open_export_folder_button=_options_button(Localization.text(&"playtest.export.open_folder"))
	options_open_export_folder_button.pressed.connect(_open_latest_export_folder)
	options_open_export_folder_button.hide(); body.add_child(options_open_export_folder_button)
	options_open_export_folder_button.visibility_changed.connect(_refresh_settings_focus)
	var reset := _options_button(Localization.text(&"settings.reset")); reset.name="ResetPresentation"; body.add_child(reset)
	var confirm := ConfirmationDialog.new(); confirm.name="ResetPresentationConfirm"
	confirm.title=Localization.text(&"settings.reset"); confirm.dialog_text=Localization.text(&"settings.reset_hint")
	confirm.ok_button_text=Localization.text(&"common.confirm")
	confirm.cancel_button_text=Localization.text(&"common.cancel")
	confirm.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; confirm.get_label().custom_minimum_size.x=480
	add_child(confirm)
	reset.pressed.connect(func() -> void: confirm.popup_centered(Vector2i(520,180)))
	confirm.confirmed.connect(func() -> void: WindowMode.reset_presentation(); call_deferred("_reload_settings_locale"))
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation",14); column.add_child(footer)
	options_resume_button=_options_button(Localization.text(&"hub.options.resume")); options_resume_button.name="OptionsResumeButton"
	options_resume_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	options_resume_button.pressed.connect(_close_options_menu); footer.add_child(options_resume_button)
	options_quit_button=_options_button(Localization.text(&"hub.options.quit")); options_quit_button.name="OptionsQuitButton"
	options_quit_button.pressed.connect(_quit_game); footer.add_child(options_quit_button)
	resized.connect(_fit_settings_panel); _fit_settings_panel()
	_refresh_options_fullscreen_label(); options_overlay.hide()

func _settings_label(parent: Node, key: String, font_size: int=18) -> void:
	var label := Label.new(); label.text=Localization.text(StringName(key))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",ACCENT if font_size>=23 else TEXT); parent.add_child(label)

func _fit_settings_panel() -> void:
	var panel: Control = options_overlay.find_child("ChapterOptionsPanel",true,false)
	panel.custom_minimum_size=Vector2(minf(760,size.x-48),minf(780,size.y-48))
	panel.size=panel.custom_minimum_size

func _reload_settings_locale() -> void:
	WindowMode.reopen_settings=true
	get_tree().reload_current_scene()


func _options_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = UiTypographyType.TOOL_BUTTON_HEIGHT
	button.add_theme_font_size_override("font_size", UiTypographyType.BUTTON_SIZE)
	return button


func _open_options_menu() -> void:
	if options_overlay == null or options_overlay.visible or (new_game_overlay != null and new_game_overlay.visible):
		return
	options_previous_focus = get_viewport().gui_get_focus_owner()
	_refresh_options_fullscreen_label()
	options_overlay.show()
	_refresh_settings_focus()
	options_resume_button.grab_focus()


func _refresh_settings_focus() -> void:
	if not is_instance_valid(options_overlay) or not options_overlay.is_visible_in_tree(): return
	var controls: Array[Control] = []
	for node: Node in options_overlay.find_children("*","Control",true,false):
		if node.focus_mode==Control.FOCUS_ALL and node.is_visible_in_tree(): controls.append(node)
	for index: int in range(controls.size()):
		controls[index].focus_next=controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous=controls[index].get_path_to(controls[(index-1+controls.size())%controls.size()])


func _close_options_menu() -> void:
	if options_overlay == null or not options_overlay.visible:
		return
	options_overlay.hide()
	options_resume_button.release_focus()
	if is_instance_valid(options_previous_focus) and options_previous_focus.is_visible_in_tree():
		options_previous_focus.grab_focus()
	options_previous_focus = null


func _quit_game() -> void:
	GlobalSave.save_game()
	get_tree().quit()


func _continue_game() -> void:
	TaskNavigation.prepare_continue()
	var scene_path: String = GlobalSave.continue_scene_path()
	if not scene_path.is_empty():
		get_tree().change_scene_to_file(scene_path)


func _open_new_game_confirmation() -> void:
	if new_game_overlay == null or new_game_overlay.visible:
		return
	new_game_status.text = ""
	new_game_clear_workbenches.button_pressed = false
	new_game_overlay.show()
	new_game_confirm_button.grab_focus()


func _close_new_game_confirmation() -> void:
	if new_game_overlay == null or not new_game_overlay.visible:
		return
	new_game_overlay.hide()
	new_game_confirm_button.release_focus()
	if new_game_button != null:
		new_game_button.grab_focus()


func _confirm_new_game() -> void:
	var result: Dictionary = GlobalSave.start_new_game(new_game_clear_workbenches.button_pressed)
	_refresh_save_actions()
	if not bool(result.get("ok", false)):
		new_game_status.text = Localization.text(&"hub.save.new_game.error", [String(result.get("error", ""))])
		return
	get_tree().change_scene_to_file("res://src/hardware_foundations/hardware_foundations.tscn")


func _export_playtest_data() -> void:
	var export_path: String = PlaytestData.export_current_session()
	latest_export_path = export_path
	if export_path.is_empty():
		options_export_status.text = Localization.text(&"playtest.export.failed", [PlaytestData.last_error])
		options_export_status.add_theme_color_override("font_color", DANGER)
		options_open_export_folder_button.hide()
	else:
		options_export_status.text = Localization.text(&"playtest.export.success", [export_path])
		options_export_status.add_theme_color_override("font_color", GOOD)
		options_open_export_folder_button.show()


func _open_latest_export_folder() -> void:
	if not latest_export_path.is_empty():
		OS.shell_show_in_file_manager(latest_export_path)


func _on_window_mode_changed(_fullscreen: bool) -> void:
	_refresh_options_fullscreen_label()


func _refresh_options_fullscreen_label() -> void:
	if options_fullscreen_button == null:
		return
	options_fullscreen_button.text = Localization.text(
		&"window.fullscreen.exit" if WindowMode.is_fullscreen() else &"window.fullscreen.enter"
	)


func _is_escape_press(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE


func _on_game_mode_changed(_mode: StringName) -> void:
	_refresh_overlap_entry()
	_refresh_mode_description()
	_refresh_save_actions()
	_refresh_system_entry()
	_refresh_locality_entry()


func _refresh_save_actions() -> void:
	if save_recovery_label != null:
		save_recovery_label.visible = not GameMode.is_test_mode() and not GlobalSave.recovery_notice.is_empty()
		save_recovery_label.text = Localization.text(GlobalSave.recovery_notice) if not GlobalSave.recovery_notice.is_empty() else ""
		save_recovery_label.tooltip_text = GlobalSave.recovery_details
		save_recovery_label.mouse_filter = Control.MOUSE_FILTER_PASS
		save_recovery_label.add_theme_color_override("font_color", GOOD if GlobalSave.recovery_notice == &"save.recovery.complete" else WARNING)
	if save_actions == null:
		return
	save_actions.visible = not GameMode.is_test_mode()
	if continue_button == null:
		return
	var can_continue: bool = not GlobalSave.continue_scene_path().is_empty()
	continue_button.disabled = not can_continue
	continue_button.tooltip_text = "" if can_continue else Localization.text(&"hub.save.continue_unavailable")


func _refresh_mode_description() -> void:
	if mode_description_label == null:
		return
	mode_description_label.text = Localization.text(
		&"mode.test.description" if GameMode.is_test_mode() else &"mode.game.description"
	)
	mode_description_label.add_theme_color_override(
		"font_color", WARNING if GameMode.is_test_mode() else MUTED
	)


func _build_card(
		title: String,
		eyebrow: String,
		description: String,
	button_text: String,
	color: Color,
	scene_path: String,
	entry_id: StringName = &""
	) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _stylebox(Color("11212d"), 6, 1, Color(color, 0.55)))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	var eyebrow_label := Label.new()
	eyebrow_label.text = eyebrow
	eyebrow_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eyebrow_label.custom_minimum_size.y = 48.0
	eyebrow_label.add_theme_font_size_override("font_size", 16)
	eyebrow_label.add_theme_color_override("font_color", color)
	box.add_child(eyebrow_label)
	var emblem := preload("res://src/ui/chapter_emblem.gd").new()
	emblem.chapter = &"hardware" if entry_id.is_empty() else entry_id
	emblem.accent = color
	box.add_child(emblem)
	var title_label := Label.new()
	title_label.text = title.replace("：", "：\n").replace(": ", ":\n").replace(" · ", "\n")
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.custom_minimum_size.y = 72
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
	box.add_child(title_label)
	var description_label := Label.new()
	description_label.text = description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_constant_override("line_spacing", 3)
	description_label.add_theme_color_override("font_color", MUTED)
	description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description_label)
	var button := Button.new()
	button.text = button_text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = true
	button.custom_minimum_size.y = 58.0
	button.pressed.connect(func() -> void: get_tree().change_scene_to_file(scene_path))
	box.add_child(button)
	if entry_id == &"system":
		system_entry_button = button
		_refresh_system_entry()
	elif entry_id == &"locality":
		locality_entry_button = button
		_refresh_locality_entry()
	elif entry_id == &"overlap":
		overlap_entry_button = button
		_refresh_overlap_entry()
	elif entry_id == &"layout":
		layout_entry_button=button
		_refresh_layout_entry()
	return panel

func _refresh_layout_entry() -> void:
	if layout_entry_button == null: return
	layout_entry_button.disabled=not LayoutChapter.chapter_unlocked()
	layout_entry_button.text=Localization.text(&"layout.hub.open" if not layout_entry_button.disabled else &"overlap.locked")

func _refresh_overlap_entry() -> void:
	if overlap_entry_button == null: return
	overlap_entry_button.disabled = not OverlapChapter.chapter_unlocked()
	overlap_entry_button.text = Localization.text(&"overlap.map") if not overlap_entry_button.disabled else Localization.text(&"overlap.locked")
	overlap_entry_button.tooltip_text = Localization.text(&"overlap.map_goal")


func _refresh_system_entry() -> void:
	if system_entry_button == null:
		return
	var unlocked: bool = GameMode.is_test_mode() or SystemChapter.prologue_ready
	system_entry_button.disabled = not unlocked
	system_entry_button.text = Localization.text(&"hub.system.open") if unlocked else Localization.text(&"hub.system.locked_action")
	system_entry_button.tooltip_text = "" if unlocked else Localization.text(&"hub.system.locked")


func _refresh_locality_entry() -> void:
	if locality_entry_button == null:
		return
	var unlocked: bool = LocalityChapter.chapter_unlocked()
	locality_entry_button.disabled = not unlocked
	locality_entry_button.text = Localization.text(&"hub.locality.open") if unlocked else Localization.text(&"hub.locality.locked_action")
	locality_entry_button.tooltip_text = "" if unlocked else Localization.text(&"hub.locality.locked")


func _stylebox(color: Color, radius: int, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.border_color = border_color
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	box.content_margin_top = 14.0
	box.content_margin_bottom = 14.0
	return box
