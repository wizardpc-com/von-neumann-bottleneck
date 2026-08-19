extends Control

const GameModeSelectorType = preload("res://src/ui/game_mode_selector.gd")

const BACKGROUND := Color("09101d")
const PANEL := Color("172033")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")

var mode_selector: GameModeSelectorType
var mode_description_label: Label


func _ready() -> void:
	_build_theme()
	_build_interface()
	GameMode.mode_changed.connect(_on_game_mode_changed)
	_refresh_mode_description()
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--capture-hardware" in arguments:
		get_tree().call_deferred("change_scene_to_file", "res://src/hardware_foundations/hardware_foundations.tscn")


func _build_theme() -> void:
	var hub_theme := Theme.new()
	hub_theme.default_font_size = 17
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
	title.add_theme_font_size_override("font_size", 34)
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
		Localization.text(&"hub.locality.title"),
		Localization.text(&"hub.locality.eyebrow"),
		Localization.text(&"hub.locality.description"),
		Localization.text(&"hub.locality.open"),
		ACCENT,
		"res://src/ui/main.tscn"
	))
	var note := Label.new()
	note.text = Localization.text(&"hub.note")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", MUTED)
	content.add_child(note)


func _on_game_mode_changed(_mode: StringName) -> void:
	_refresh_mode_description()


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
		scene_path: String
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
	title_label.add_theme_font_size_override("font_size", 27)
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
	return panel


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
