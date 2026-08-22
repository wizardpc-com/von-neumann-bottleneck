class_name SystemChapterMapView
extends Control

signal level_requested(level_id: StringName)

const NODE_SIZE := Vector2(168.0, 92.0)
const LEFT_RESERVED := 330.0
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const MUTED := Color("74839b")
const SURFACE := Color("111a2a")
const TEXT := Color("e9f0fa")

var level_buttons: Dictionary[StringName, Button] = {}
var level_positions: Dictionary[StringName, Vector2] = {}
var _levels: Array[Dictionary] = []
var _intro_title: String = ""
var _intro_body: String = ""


func _ready() -> void:
	resized.connect(_relayout)


func configure(levels: Array[Dictionary], intro_title: String, intro_body: String) -> void:
	_levels = levels.duplicate(true)
	_intro_title = intro_title
	_intro_body = intro_body
	for button: Button in level_buttons.values():
		if is_instance_valid(button):
			button.queue_free()
	level_buttons.clear()
	for data: Dictionary in _levels:
		var level_id := StringName(data.get("id", &""))
		var button := Button.new()
		button.name = "SystemLevel_%s" % String(level_id).to_pascal_case()
		button.custom_minimum_size = NODE_SIZE
		button.size = NODE_SIZE
		button.disabled = not bool(data.get("unlocked", false))
		button.tooltip_text = String(data.get("tooltip", ""))
		button.add_theme_stylebox_override("normal", _stylebox(SURFACE, _state_color(data), 2))
		button.add_theme_stylebox_override("hover", _stylebox(Color(_state_color(data), 0.18), _state_color(data), 3))
		button.add_theme_stylebox_override("pressed", _stylebox(Color(_state_color(data), 0.28), _state_color(data), 3))
		button.add_theme_stylebox_override("disabled", _stylebox(Color("0d1523"), Color(MUTED, 0.42), 1))
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 9)
		margin.add_theme_constant_override("margin_bottom", 8)
		button.add_child(margin)
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(column)
		var index_label := Label.new()
		index_label.text = String(data.get("eyebrow", ""))
		index_label.add_theme_font_size_override("font_size", 12)
		index_label.add_theme_color_override("font_color", _state_color(data))
		column.add_child(index_label)
		var title := Label.new()
		title.text = String(data.get("title", level_id))
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", TEXT if not button.disabled else MUTED)
		column.add_child(title)
		var status := Label.new()
		status.text = String(data.get("status", ""))
		status.add_theme_font_size_override("font_size", 12)
		status.add_theme_color_override("font_color", _state_color(data))
		column.add_child(status)
		button.pressed.connect(func() -> void: level_requested.emit(level_id))
		level_buttons[level_id] = button
		add_child(button)
	_relayout()


func _relayout() -> void:
	if _levels.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var available_width: float = maxf(520.0, size.x - LEFT_RESERVED - 40.0 - NODE_SIZE.x)
	var step: float = available_width / float(maxi(1, _levels.size() - 1))
	var center_y: float = size.y * 0.5 - NODE_SIZE.y * 0.5
	level_positions.clear()
	for index: int in range(_levels.size()):
		var level_id := StringName(_levels[index].get("id", &""))
		var offset_y: float = -72.0 if index % 2 == 0 else 72.0
		var position := Vector2(LEFT_RESERVED + float(index) * step, center_y + offset_y)
		level_positions[level_id] = position
		var button: Button = level_buttons[level_id]
		button.position = position
		button.size = NODE_SIZE
	queue_redraw()


func _draw() -> void:
	var intro_rect := Rect2(24.0, 48.0, LEFT_RESERVED - 54.0, maxf(260.0, size.y - 96.0))
	draw_style_box(_stylebox(Color("111a2a", 0.94), ACCENT, 2), intro_rect)
	draw_string(ThemeDB.fallback_font, intro_rect.position + Vector2(20.0, 45.0), _intro_title, HORIZONTAL_ALIGNMENT_LEFT, intro_rect.size.x - 40.0, 26, ACCENT)
	draw_multiline_string(ThemeDB.fallback_font, intro_rect.position + Vector2(20.0, 88.0), _intro_body, HORIZONTAL_ALIGNMENT_LEFT, intro_rect.size.x - 40.0, 16, 24, TEXT)
	for index: int in range(_levels.size() - 1):
		var from_id := StringName(_levels[index].get("id", &""))
		var to_id := StringName(_levels[index + 1].get("id", &""))
		if not level_positions.has(from_id) or not level_positions.has(to_id):
			continue
		var start: Vector2 = level_positions[from_id] + Vector2(NODE_SIZE.x, NODE_SIZE.y * 0.5)
		var finish: Vector2 = level_positions[to_id] + Vector2(0.0, NODE_SIZE.y * 0.5)
		var points := PackedVector2Array([start, Vector2((start.x + finish.x) * 0.5, start.y), Vector2((start.x + finish.x) * 0.5, finish.y), finish])
		var color: Color = _state_color(_levels[index + 1])
		draw_polyline(points, Color("09101d"), 9.0, true)
		draw_polyline(points, Color(color, 0.72), 3.0, true)


func _state_color(data: Dictionary) -> Color:
	if bool(data.get("completed", false)):
		return GOOD
	return ACCENT if bool(data.get("unlocked", false)) else MUTED


func _stylebox(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(12)
	return box
