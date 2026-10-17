extends Control

const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
const Typography = preload("res://src/ui/ui_typography.gd")

signal launch_requested

var launch_on_finish: bool = false
var previous_focus: Control
var start_button: Button
var skip_button: Button
var close_button: Button


func _ready() -> void:
	name = "YiIntroduction"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 1200
	mouse_filter = Control.MOUSE_FILTER_STOP
	var english: bool = Localization.current_locale() == "en"
	var page: Dictionary = Catalog.introduction(english)
	var shade := ColorRect.new()
	shade.color = Color("07131e", 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 32)
	add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	frame.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 700
	panel.add_theme_stylebox_override("panel", InstrumentTheme.surface(Color("112431"), Color("47767c"), 14))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	margin.add_child(body)
	_add_text(body, str(page.title), Typography.SUBTITLE_SIZE, Color("a3d7d6"))
	_add_text(body, str(page.context), Typography.BODY_SIZE)
	body.add_child(HSeparator.new())
	_add_text(body, str(page.goal_title), Typography.SUBTITLE_SIZE, Color("a3d7d6"))
	_add_text(body, str(page.goal), Typography.BODY_SIZE)
	_add_text(body, str(page.operations), Typography.CAPTION_SIZE)
	_add_text(body, str(page.help), Typography.CAPTION_SIZE, Color("a7bbc8"))
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	body.add_child(actions)
	start_button = _button(actions, "开始操作" if not english else "Begin building")
	InstrumentTheme.primary(start_button)
	start_button.pressed.connect(finish)
	skip_button = _button(actions, "跳过导入，直接操作" if not english else "Skip introduction and build")
	skip_button.pressed.connect(finish)
	close_button = _button(actions, "返回首页 · Esc" if not english else "Back to Home · Esc")
	close_button.pressed.connect(close)
	hide()


func _add_text(parent: Control, text: String, font_size: int, color: Color = Color("e0ecf2")) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 648
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = Typography.CONTROL_HEIGHT
	parent.add_child(button)
	return button


func present(should_launch: bool) -> void:
	launch_on_finish = should_launch
	previous_focus = get_viewport().gui_get_focus_owner()
	start_button.visible = should_launch
	skip_button.visible = should_launch
	var controls: Array[Button] = [close_button]
	if should_launch: controls = [start_button, skip_button, close_button]
	for index: int in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index + 1) % controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index + controls.size() - 1) % controls.size()])
	show()
	controls[0].grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
	previous_focus = null


func finish() -> void:
	var should_launch: bool = launch_on_finish
	close()
	if should_launch: launch_requested.emit()
