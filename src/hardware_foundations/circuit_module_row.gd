class_name CircuitModuleRow
extends Control

const SURFACE := Color("101725")
const SYMBOL := Color("aebbd0")
const PROCESS := Color("50d5ff")
const ARITHMETIC := Color("50d5ff")
const STORAGE := Color("bc8cff")
const ROUTING := Color("ffbf69")
const SIGNAL_LOW := Color("ff6b7d")
const SIGNAL_HIGH := Color("67e8a5")
const SIGNAL_HIGH_Z := Color("8b929d")

var component_kind: StringName = &""
var component_label: String = ""
var input_label: String = ""
var output_label: String = ""
var row_index: int = 0
var row_count: int = 1
var has_input: bool = false
var has_output: bool = false
var input_width: int = 1
var output_width: int = 1
var selection_active: bool = false
var processing_active: bool = false
var processing_progress: float = 0.0
var processing_input_visuals: Array[Dictionary] = []
var processing_output_visual: Dictionary = {}
var active_output_port: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(
		p_kind: StringName,
		p_component_label: String,
		p_input_label: String,
		p_output_label: String,
		p_row_index: int,
		p_row_count: int,
		p_has_input: bool,
		p_has_output: bool,
		p_input_width: int,
		p_output_width: int
	) -> void:
	component_kind = p_kind
	component_label = p_component_label
	input_label = p_input_label
	output_label = p_output_label
	row_index = p_row_index
	row_count = maxi(1, p_row_count)
	has_input = p_has_input
	has_output = p_has_output
	input_width = maxi(1, p_input_width)
	output_width = maxi(1, p_output_width)
	queue_redraw()


func set_processing_state(
		progress: float,
		input_visuals: Array[Dictionary] = [],
		output_visual: Dictionary = {},
		p_active_output_port: int = -1
	) -> void:
	processing_active = true
	processing_progress = clampf(progress, 0.0, 1.0)
	processing_input_visuals = input_visuals.duplicate(true)
	processing_output_visual = output_visual.duplicate(true)
	active_output_port = p_active_output_port
	queue_redraw()


func clear_processing_state() -> void:
	if not processing_active:
		return
	processing_active = false
	processing_progress = 0.0
	processing_input_visuals.clear()
	processing_output_visual.clear()
	active_output_port = -1
	queue_redraw()


func set_selection_active(active: bool) -> void:
	if selection_active == active:
		return
	selection_active = active
	queue_redraw()


func shape_profile() -> StringName:
	match component_kind:
		&"mux4", &"mux2_word":
			return &"mux_wedge"
		&"alu1", &"alu4":
			return &"alu_notched"
		&"decoder1_to_2", &"control":
			return &"fanout_module"
		&"sr_latch", &"register1", &"register4":
			return &"register_module"
		&"ram2x4":
			return &"ram_grid"
		&"tiny_computer":
			return &"computer_split"
	return &"arithmetic_module"


func ram_cursor_index() -> int:
	if component_kind != &"ram2x4" or processing_input_visuals.is_empty():
		return -1
	var address: Dictionary = processing_input_visuals[0]
	if not bool(address.get("known", false)):
		return -1
	return clampi(int(address.get("numeric", 0)), 0, 1)


func output_token_enabled() -> bool:
	return _output_is_active()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_draw_module_surface()
	_draw_pin_leads()
	_draw_port_labels()
	if row_index == row_count / 2:
		_draw_function_mark()
	_draw_processing_route()


func _draw_module_surface() -> void:
	var top_t: float = float(row_index) / float(row_count)
	var bottom_t: float = float(row_index + 1) / float(row_count)
	var left_top: float = _body_left(top_t)
	var left_bottom: float = _body_left(bottom_t)
	var right_top: float = _body_right(top_t)
	var right_bottom: float = _body_right(bottom_t)
	var polygon := PackedVector2Array([
		Vector2(left_top, 0.0),
		Vector2(right_top, 0.0),
		Vector2(right_bottom, size.y),
		Vector2(left_bottom, size.y),
	])
	draw_colored_polygon(polygon, SURFACE)
	var outline: Color = PROCESS if selection_active else _outline_color()
	draw_line(Vector2(left_top, 0.0), Vector2(left_bottom, size.y), outline, 3.0, true)
	draw_line(Vector2(right_top, 0.0), Vector2(right_bottom, size.y), outline, 3.0, true)
	if row_index == 0:
		draw_line(Vector2(left_top, 1.5), Vector2(right_top, 1.5), outline, 3.0, true)
	if row_index == row_count - 1:
		draw_line(
			Vector2(left_bottom, size.y - 1.5),
			Vector2(right_bottom, size.y - 1.5), outline, 3.0, true
		)


func _draw_pin_leads() -> void:
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var left: float = _body_left(global_t)
	var right: float = _body_right(global_t)
	if has_input:
		draw_line(Vector2(0.0, center_y), Vector2(left, center_y), SYMBOL, 4.0, true)
	if has_output:
		draw_line(Vector2(right, center_y), Vector2(size.x, center_y), SYMBOL, 4.0, true)


func _draw_port_labels() -> void:
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var left: float = _body_left(global_t)
	var right: float = _body_right(global_t)
	if has_input:
		_draw_text(
			Vector2(left + 7.0, center_y), _width_label(input_label, input_width),
			SYMBOL, HORIZONTAL_ALIGNMENT_LEFT, 9
		)
	if has_output:
		_draw_text(
			Vector2(right - 7.0, center_y), _width_label(output_label, output_width),
			SYMBOL, HORIZONTAL_ALIGNMENT_RIGHT, 9
		)


func _draw_function_mark() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var strength: float = _stage_strength(0.24, 0.76)
	var color: Color = SYMBOL.lerp(PROCESS, strength)
	match component_kind:
		&"half_adder":
			_draw_text(center, "Σ", color, HORIZONTAL_ALIGNMENT_CENTER, 18)
		&"full_adder":
			_draw_text(center, "Σ+", color, HORIZONTAL_ALIGNMENT_CENTER, 15)
		&"mux4", &"mux2_word":
			_draw_mux_mark(center, color)
		&"alu1", &"alu4":
			_draw_alu_mark(center, color)
		&"sr_latch":
			_draw_latch_mark(center, "SR", color)
		&"register1", &"register4":
			_draw_latch_mark(center, "REG", color)
		&"decoder1_to_2":
			_draw_fanout_mark(center, "DEC", color)
		&"control":
			_draw_fanout_mark(center, "CTRL", color)
		&"ram2x4":
			_draw_ram_mark(center, color)
		&"tiny_computer":
			_draw_computer_mark(center, color)
		_:
			_draw_text(center, _module_code(), color, HORIZONTAL_ALIGNMENT_CENTER, 12)


func _draw_processing_route() -> void:
	if not processing_active:
		return
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var left: float = _body_left(global_t)
	var right: float = _body_right(global_t)
	var center_x: float = size.x * 0.5
	var body_strength: float = _stage_strength(0.22, 0.78)
	if body_strength > 0.0:
		var route_color := Color(PROCESS, 0.28 + body_strength * 0.62)
		if has_input:
			draw_line(
				Vector2(left + 3.0, center_y), Vector2(center_x - 15.0, center_y),
				route_color, 3.0, true
			)
		if _output_is_active():
			draw_line(
				Vector2(center_x + 15.0, center_y), Vector2(right - 3.0, center_y),
				route_color, 3.0, true
			)
	if has_input:
		var input_visual: Dictionary = _input_visual()
		_draw_processing_token(
			Vector2(0.0, center_y), Vector2(left + 5.0, center_y),
			0.0, 0.36, input_visual
		)
	if _output_is_active():
		_draw_processing_token(
			Vector2(right - 5.0, center_y), Vector2(size.x, center_y),
			0.64, 1.0, processing_output_visual
		)


func _draw_processing_token(
		start: Vector2,
		finish: Vector2,
		stage_start: float,
		stage_end: float,
		visual: Dictionary
	) -> void:
	if processing_progress < stage_start or processing_progress > stage_end:
		return
	var local_progress: float = smoothstep(
		0.0, 1.0, inverse_lerp(stage_start, stage_end, processing_progress)
	)
	var point: Vector2 = start.lerp(finish, local_progress)
	var color: Color = visual.get("color", SIGNAL_HIGH_Z)
	draw_line(start, point, Color(color, 0.24), 8.0, true)
	draw_line(start, point, color, 3.5, true)


func _draw_mux_mark(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-12.0, -8.0), center + Vector2(10.0, 0.0), color, 2.5, true)
	draw_line(center + Vector2(-12.0, 8.0), center + Vector2(10.0, 0.0), color, 2.5, true)
	draw_circle(center + Vector2(10.0, 0.0), 3.5, color)
	_draw_text(center + Vector2(0.0, 1.0), "MUX", color, HORIZONTAL_ALIGNMENT_CENTER, 8)


func _draw_alu_mark(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-13.0, 0.0), center + Vector2(13.0, 0.0), color, 2.0, true)
	draw_line(center + Vector2(-5.0, -7.0), center + Vector2(-5.0, 7.0), color, 2.0, true)
	draw_circle(center + Vector2(7.0, 0.0), 4.0, SURFACE)
	draw_circle(center + Vector2(7.0, 0.0), 3.0, color, false, 2.0, true)
	_draw_text(center + Vector2(0.0, 1.0), "ALU", color, HORIZONTAL_ALIGNMENT_CENTER, 8)


func _draw_latch_mark(center: Vector2, label: String, color: Color) -> void:
	draw_line(center + Vector2(-12.0, -8.0), center + Vector2(-12.0, 8.0), color, 2.5, true)
	draw_line(center + Vector2(12.0, -8.0), center + Vector2(12.0, 8.0), color, 2.5, true)
	draw_line(center + Vector2(-7.0, 0.0), center + Vector2(7.0, 0.0), color, 2.0, true)
	_draw_text(center + Vector2(0.0, 1.0), label, color, HORIZONTAL_ALIGNMENT_CENTER, 8)


func _draw_fanout_mark(center: Vector2, label: String, color: Color) -> void:
	draw_line(center + Vector2(-13.0, 0.0), center + Vector2(-2.0, 0.0), color, 2.5, true)
	draw_line(center + Vector2(-2.0, 0.0), center + Vector2(12.0, -8.0), color, 2.0, true)
	draw_line(center + Vector2(-2.0, 0.0), center + Vector2(12.0, 8.0), color, 2.0, true)
	_draw_text(center + Vector2(0.0, 1.0), label, color, HORIZONTAL_ALIGNMENT_CENTER, 7)


func _draw_ram_mark(center: Vector2, color: Color) -> void:
	var origin := center + Vector2(-13.0, -8.0)
	var cursor: int = ram_cursor_index()
	for address: int in range(2):
		var row_rect := Rect2(origin + Vector2(0.0, address * 9.0), Vector2(26.0, 7.0))
		if processing_active and cursor == address and _stage_strength(0.22, 0.82) > 0.0:
			draw_rect(row_rect, Color(PROCESS, 0.42), true)
		draw_rect(row_rect, color, false, 1.5)
		for bit: int in range(1, 4):
			var x: float = row_rect.position.x + row_rect.size.x * float(bit) / 4.0
			draw_line(
				Vector2(x, row_rect.position.y),
				Vector2(x, row_rect.end.y), color, 1.0, true
			)


func _draw_computer_mark(center: Vector2, color: Color) -> void:
	var rect := Rect2(center + Vector2(-16.0, -9.0), Vector2(32.0, 18.0))
	draw_rect(rect, color, false, 2.0)
	draw_line(center + Vector2(0.0, -9.0), center + Vector2(0.0, 9.0), color, 2.0, true)
	_draw_text(center + Vector2(-8.0, 1.0), "CPU", color, HORIZONTAL_ALIGNMENT_CENTER, 7)
	_draw_text(center + Vector2(8.0, 1.0), "M", color, HORIZONTAL_ALIGNMENT_CENTER, 7)


func _draw_value_badge(center: Vector2, text: String, color: Color) -> void:
	var font_size: int = 8
	var width: float = ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x + 6.0
	var rect := Rect2(center - Vector2(width * 0.5, 6.0), Vector2(width, 12.0))
	draw_rect(rect, Color(SURFACE, 0.94), true)
	draw_rect(rect, Color(color, 0.8), false, 1.0)
	_draw_text(center + Vector2(0.0, 0.5), text, color, HORIZONTAL_ALIGNMENT_CENTER, font_size)


func _draw_text(
		anchor: Vector2,
		text: String,
		color: Color,
		alignment: HorizontalAlignment,
		font_size: int
	) -> void:
	if text.is_empty():
		return
	var text_width: float = ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x
	var x: float = anchor.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x -= text_width * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= text_width
	draw_string(
		ThemeDB.fallback_font,
		Vector2(x, anchor.y + float(font_size) * 0.36),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color
	)


func _body_left(t: float) -> float:
	var distance: float = absf(clampf(t, 0.0, 1.0) - 0.5) * 2.0
	match shape_profile():
		&"mux_wedge":
			return 34.0 + distance * 12.0
		&"alu_notched":
			return 46.0 - distance * 10.0
		&"fanout_module":
			return 38.0
	return 36.0


func _body_right(t: float) -> float:
	var distance: float = absf(clampf(t, 0.0, 1.0) - 0.5) * 2.0
	match shape_profile():
		&"mux_wedge":
			return size.x - 40.0 + distance * 5.0
		&"alu_notched":
			return size.x - 35.0 - distance * 11.0
		&"fanout_module":
			return size.x - 34.0 - distance * 7.0
	return size.x - 36.0


func _outline_color() -> Color:
	match shape_profile():
		&"register_module", &"ram_grid", &"computer_split":
			return STORAGE
		&"fanout_module":
			return ROUTING
	return ARITHMETIC


func _module_code() -> String:
	match component_kind:
		&"half_adder": return "HA"
		&"full_adder": return "FA"
		&"mux4", &"mux2_word": return "MUX"
		&"alu1", &"alu4": return "ALU"
		&"sr_latch": return "SR"
		&"register1", &"register4": return "REG"
		&"decoder1_to_2": return "DEC"
		&"ram2x4": return "RAM"
		&"control": return "CTRL"
		&"tiny_computer": return "CPU"
	return component_label.left(5).to_upper()


func _input_visual() -> Dictionary:
	if row_index >= 0 and row_index < processing_input_visuals.size():
		return processing_input_visuals[row_index]
	return {"known": false, "numeric": 0, "text": "Z", "color": SIGNAL_HIGH_Z}


func _output_is_active() -> bool:
	return has_output and (active_output_port < 0 or active_output_port == row_index)


func _stage_strength(start: float, finish: float) -> float:
	if not processing_active or finish <= start:
		return 0.0
	if processing_progress < start or processing_progress > finish:
		return 0.0
	return sin(inverse_lerp(start, finish, processing_progress) * PI)


func _width_label(label: String, width: int) -> String:
	var compact: String = _compact_port_label(label)
	return "%s×%d" % [compact, width] if width > 1 else compact


func _compact_port_label(label: String) -> String:
	match label:
		"SOURCE_SEL": return "SRC"
		"RESULT_SEL": return "RES"
		"ACC_LOAD": return "ACC"
		"MEM_WRITE": return "MEM"
		"DATA_IN": return "DIN"
		"DATA_OUT": return "DOUT"
		"ENABLE": return "EN"
		"WRITE": return "WR"
		"LOAD": return "LD"
		"RESULT": return "R"
		"CARRY": return "C"
		"COUT": return "CO"
		"ADDR": return "ADR"
	return label.left(7)
