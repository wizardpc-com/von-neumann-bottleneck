class_name SystemChapterMapView
extends Control

signal level_requested(level_id: StringName)

const NODE_SIZE := Vector2(168.0, 140.0)
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
var _intro_panel: PanelContainer


func _ready() -> void:
	resized.connect(_relayout)


func configure(levels: Array[Dictionary], intro_title: String, intro_body: String) -> void:
	_levels = levels.duplicate(true)
	_intro_title = intro_title
	_intro_body = intro_body
	if is_instance_valid(_intro_panel):
		_intro_panel.queue_free()
	_intro_panel = PanelContainer.new()
	_intro_panel.add_theme_stylebox_override("panel", _stylebox(Color("111a2a", 0.94), ACCENT, 2))
	add_child(_intro_panel)
	var intro_margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		intro_margin.add_theme_constant_override("margin_"+side,20)
	_intro_panel.add_child(intro_margin)
	var intro_scroll := ScrollContainer.new()
	intro_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	intro_margin.add_child(intro_scroll)
	var intro_column := VBoxContainer.new()
	intro_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_column.add_theme_constant_override("separation",16)
	intro_scroll.add_child(intro_column)
	for is_title: bool in [true,false]:
		var label := Label.new()
		label.text = _intro_title if is_title else _intro_body
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size",26 if is_title else 16)
		label.add_theme_color_override("font_color",ACCENT if is_title else TEXT)
		intro_column.add_child(label)
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
		button.tooltip_text = "%s\n%s" % [String(data.get("title", level_id)), String(data.get("tooltip", ""))]
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
		title.size_flags_vertical = Control.SIZE_EXPAND_FILL
		title.max_lines_visible = 3
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.clip_text = true
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
	var step: float = available_width / float(maxi(1, mini(5,_levels.size()) - 1))
	var center_y: float = size.y * 0.5 - NODE_SIZE.y * 0.5
	level_positions.clear()
	for index: int in range(_levels.size()):
		var level_id := StringName(_levels[index].get("id", &""))
		var row: int = index / 5
		var row_count: int = mini(5,_levels.size()-row*5)
		var offset_y: float = -80.0 + row*230.0
		var column: int = index%5 + 5-row_count
		var position := Vector2(LEFT_RESERVED + float(column) * step, center_y + offset_y)
		level_positions[level_id] = position
		var button: Button = level_buttons[level_id]
		button.position = position
		button.size = NODE_SIZE
	if is_instance_valid(_intro_panel):
		_intro_panel.position = Vector2(24,48)
		_intro_panel.size = Vector2(LEFT_RESERVED-54,maxf(160,size.y-96))
	queue_redraw()


func _draw() -> void:
	for data: Dictionary in _levels:
		var to_id := StringName(data.get("id",&""))
		for dependency: Variant in data.get("dependencies",[]):
			var from_id := StringName(dependency)
			if not level_positions.has(from_id) or not level_positions.has(to_id): continue
			var start: Vector2 = level_positions[from_id]+Vector2(NODE_SIZE.x,NODE_SIZE.y/2)
			var finish: Vector2 = level_positions[to_id]+Vector2(0,NODE_SIZE.y/2)
			if level_positions[from_id].x == level_positions[to_id].x:
				start = level_positions[from_id]+Vector2(NODE_SIZE.x/2,NODE_SIZE.y)
				finish = level_positions[to_id]+Vector2(NODE_SIZE.x/2,0)
			var points := PackedVector2Array([start,Vector2((start.x+finish.x)/2,start.y),Vector2((start.x+finish.x)/2,finish.y),finish])
			draw_polyline(points,Color(_state_color(data),0.72),3.0,true)


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
