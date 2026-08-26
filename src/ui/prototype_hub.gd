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
var system_entry_button: Button
var locality_entry_button: Button
var terminology_handbook: TerminologyHandbookType
var options_overlay: Control
var options_resume_button: Button
var options_fullscreen_button: Button
var options_quit_button: Button
var options_previous_focus: Control


func _ready() -> void:
	_build_theme()
	_build_interface()
	GameMode.mode_changed.connect(_on_game_mode_changed)
	SystemChapter.progression_changed.connect(_refresh_locality_entry)
	WindowMode.window_mode_changed.connect(_on_window_mode_changed)
	_refresh_mode_description()
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--capture-options" in arguments:
		call_deferred("_open_options_menu")
	elif "--capture-terminology" in arguments:
		terminology_handbook.call_deferred("open_handbook", &"truth_table")
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
	):
		get_tree().call_deferred("change_scene_to_file", "res://src/ui/main.tscn")


func _input(event: InputEvent) -> void:
	if terminology_handbook != null and terminology_handbook.handle_escape(event):
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_escape_press(event):
		return
	if options_overlay.visible:
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
	theme = hub_theme


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(1180.0, 650.0)
	center.add_child(content)
	var title := Label.new()
	title.text = Localization.text(&"game.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTypographyType.HERO_TITLE_SIZE)
	title.add_theme_color_override("font_color", ACCENT)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = Localization.text(&"hub.subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", MUTED)
	content.add_child(subtitle)
	var mode_center := CenterContainer.new()
	content.add_child(mode_center)
	mode_selector = GameModeSelectorType.new()
	mode_selector.name = "GameModeSelector"
	mode_center.add_child(mode_selector)
	mode_description_label = Label.new()
	mode_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_description_label.add_theme_color_override("font_color", WARNING if GameMode.is_test_mode() else MUTED)
	content.add_child(mode_description_label)
	var cards := HBoxContainer.new()
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
	var note := Label.new()
	note.text = Localization.text(&"hub.note")
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


func _build_options_menu() -> void:
	options_overlay = Control.new()
	options_overlay.name = "ChapterOptionsOverlay"
	options_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	options_overlay.z_index = 1100
	add_child(options_overlay)

	var backdrop := ColorRect.new()
	backdrop.color = Color("050a12", 0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	options_overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "ChapterOptionsPanel"
	panel.custom_minimum_size = Vector2(460.0, 340.0)
	panel.add_theme_stylebox_override("panel", _stylebox(PANEL, 16, 2, PURPLE))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = Localization.text(&"hub.options.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	title.add_theme_color_override("font_color", PURPLE)
	column.add_child(title)

	var hint := Label.new()
	hint.text = Localization.text(&"hub.options.hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	column.add_child(hint)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	options_resume_button = _options_button(Localization.text(&"hub.options.resume"))
	options_resume_button.name = "OptionsResumeButton"
	options_resume_button.pressed.connect(_close_options_menu)
	column.add_child(options_resume_button)

	options_fullscreen_button = _options_button("")
	options_fullscreen_button.name = "OptionsFullscreenButton"
	options_fullscreen_button.tooltip_text = Localization.text(&"window.fullscreen.tooltip")
	options_fullscreen_button.pressed.connect(WindowMode.toggle_fullscreen)
	column.add_child(options_fullscreen_button)

	options_quit_button = _options_button(Localization.text(&"hub.options.quit"))
	options_quit_button.name = "OptionsQuitButton"
	options_quit_button.add_theme_color_override("font_color", DANGER)
	options_quit_button.add_theme_stylebox_override("normal", _stylebox(Color("30202c"), 9, 1, Color("653244")))
	options_quit_button.add_theme_stylebox_override("hover", _stylebox(Color("402433"), 9, 2, DANGER))
	options_quit_button.pressed.connect(_quit_game)
	column.add_child(options_quit_button)

	_refresh_options_fullscreen_label()
	options_overlay.hide()


func _options_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = UiTypographyType.TOOL_BUTTON_HEIGHT
	button.add_theme_font_size_override("font_size", UiTypographyType.BUTTON_SIZE)
	return button


func _open_options_menu() -> void:
	if options_overlay == null or options_overlay.visible:
		return
	options_previous_focus = get_viewport().gui_get_focus_owner()
	_refresh_options_fullscreen_label()
	options_overlay.show()
	options_resume_button.grab_focus()


func _close_options_menu() -> void:
	if options_overlay == null or not options_overlay.visible:
		return
	options_overlay.hide()
	options_resume_button.release_focus()
	if is_instance_valid(options_previous_focus) and options_previous_focus.is_visible_in_tree():
		options_previous_focus.grab_focus()
	options_previous_focus = null


func _quit_game() -> void:
	get_tree().quit()


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
	_refresh_mode_description()
	_refresh_system_entry()
	_refresh_locality_entry()


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
	panel.add_theme_stylebox_override("panel", _stylebox(Color(color, 0.08), 14, 2, color))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	var eyebrow_label := Label.new()
	eyebrow_label.text = eyebrow
	eyebrow_label.add_theme_color_override("font_color", color)
	box.add_child(eyebrow_label)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	box.add_child(title_label)
	var description_label := Label.new()
	description_label.text = description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", MUTED)
	description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description_label)
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size.y = 58.0
	button.pressed.connect(func() -> void: get_tree().change_scene_to_file(scene_path))
	box.add_child(button)
	if entry_id == &"system":
		system_entry_button = button
		_refresh_system_entry()
	elif entry_id == &"locality":
		locality_entry_button = button
		_refresh_locality_entry()
	return panel


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
