extends Control

const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
const Typography = preload("res://src/ui/ui_typography.gd")
const DEFAULT_MEDIA_PATH: String = "res://assets/narrative/yi-learning-fragment.svg"

signal launch_requested

@export var media_texture: Texture2D:
	set(value):
		media_texture = value
		_refresh_media()

var launch_on_finish: bool = false
var previous_focus: Control
var start_button: Button
var skip_button: Button
var close_button: Button
var media_view: TextureRect
var media_column: VBoxContainer
var media_caption: Label
var context_label: Label
var goal_label: Label
var content_scroll: ScrollContainer
var actions: BoxContainer


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
	var page_layout := VBoxContainer.new()
	page_layout.add_theme_constant_override("separation",12)
	frame.add_child(page_layout)
	content_scroll = ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.follow_focus = true
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_layout.add_child(content_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(center)
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
	var context_row := HBoxContainer.new()
	context_row.add_theme_constant_override("separation", 14)
	body.add_child(context_row)
	context_label = _add_text(context_row, str(page.context), Typography.BODY_SIZE, Color("e0ecf2"), 486)
	context_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	media_column = VBoxContainer.new()
	media_column.name = "YiIntroductionMedia"
	media_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media_column.custom_minimum_size.x = 148
	media_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	context_row.add_child(media_column)
	media_view = TextureRect.new()
	media_view.name = "ReplaceableArchiveImage"
	media_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media_view.focus_mode = Control.FOCUS_NONE
	media_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	media_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	media_view.custom_minimum_size = Vector2(148, 64)
	media_column.add_child(media_view)
	media_caption = _add_text(media_column, "候选虚构档案" if not english else "Candidate fictional archive", Typography.CAPTION_SIZE, Color("a7bbc8"), 148)
	media_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if media_texture == null and ResourceLoader.exists(DEFAULT_MEDIA_PATH):
		media_texture = load(DEFAULT_MEDIA_PATH) as Texture2D
	_refresh_media()
	body.add_child(HSeparator.new())
	_add_text(body, str(page.goal_title), Typography.SUBTITLE_SIZE, Color("a3d7d6"))
	goal_label = _add_text(body, str(page.goal), Typography.BODY_SIZE)
	var steps := VBoxContainer.new()
	steps.name = "IntroductionSteps"
	steps.add_theme_constant_override("separation",10)
	body.add_child(steps)
	for index: int in page.steps.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		steps.add_child(row)
		var number := _add_text(row, "%02d" % (index+1), Typography.SUBTITLE_SIZE, Color("a3d7d6"), 32)
		number.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		_add_text(copy, str(page.steps[index][0]), Typography.BODY_SIZE, Color("a3d7d6"), 604)
		_add_text(copy, str(page.steps[index][1]), Typography.CAPTION_SIZE, Color("e0ecf2"), 604)
	_add_text(body, str(page.help), Typography.CAPTION_SIZE, Color("a7bbc8"))
	actions = BoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	page_layout.add_child(actions)
	start_button = _button(actions, "开始操作" if not english else "Begin building")
	InstrumentTheme.primary(start_button)
	start_button.pressed.connect(finish)
	skip_button = _button(actions, "跳过导入，直接操作" if not english else "Skip introduction and build")
	skip_button.pressed.connect(finish)
	close_button = _button(actions, "返回首页 · Esc" if not english else "Back to Home · Esc")
	close_button.pressed.connect(close)
	resized.connect(_fit_actions)
	for button: Button in [start_button,skip_button,close_button]: button.minimum_size_changed.connect(_fit_actions)
	_fit_actions()
	hide()

func _fit_actions() -> void:
	if not is_instance_valid(close_button): return
	var width: float = 0.0
	var count: int = 0
	for button: Button in [start_button,skip_button,close_button]:
		if button.visible:
			width += button.get_combined_minimum_size().x
			count += 1
	actions.vertical = width + 8.0 * maxi(0,count-1) > size.x - 64.0


func _add_text(parent: Control, text: String, font_size: int, color: Color = Color("e0ecf2"), minimum_width: float = 648.0) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = minimum_width
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _refresh_media() -> void:
	if not is_instance_valid(media_view): return
	media_view.texture = media_texture
	media_column.visible = media_texture != null and media_texture.get_width() > 0 and media_texture.get_height() > 0


func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = Typography.CONTROL_HEIGHT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button


func present(should_launch: bool) -> void:
	launch_on_finish = should_launch
	previous_focus = get_viewport().gui_get_focus_owner()
	start_button.visible = should_launch
	skip_button.visible = should_launch
	_fit_actions()
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
