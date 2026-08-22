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


func visible_component_name() -> String:
	match component_kind:
		&"half_adder": return "HalfAdder"
		&"full_adder": return "FullAdder"
		&"mux4": return "Mux4"
		&"mux2_word": return "Word Mux"
		&"alu1": return "ALU1"
		&"alu4": return "ALU4"
		&"sr_latch": return "SR Latch"
		&"register1": return "Register1"
		&"register4": return "Register4"
		&"decoder1_to_2": return "Decoder"
		&"control": return "Control"
		&"ram2x4": return "RAM2x4"
		&"tiny_computer": return "CPU + RAM"
	return component_label if not component_label.is_empty() else String(component_kind)


func name_layout() -> Dictionary:
	var text: String = visible_component_name()
	var safe_rect: Rect2 = _central_content_rect()
	var preferred_icon_width: float = 24.0
	var icon_gap: float = 7.0
	var font_size: int = _name_font_size(
		text, 11, maxf(1.0, safe_rect.size.x - preferred_icon_width - icon_gap)
	)
	var text_width: float = _text_width(text, font_size)
	var text_box_width: float = text_width + 4.0
	var icon_width: float = preferred_icon_width
	if text_box_width + icon_width + icon_gap > safe_rect.size.x:
		icon_width = 0.0
		icon_gap = 0.0
		font_size = _name_font_size(text, 11, maxf(1.0, safe_rect.size.x))
		text_width = _text_width(text, font_size)
		text_box_width = text_width + 4.0
	var group_width: float = minf(safe_rect.size.x, icon_width + icon_gap + text_box_width)
	var group_left: float = safe_rect.get_center().x - group_width * 0.5
	var center_y: float = size.y * 0.5
	var text_left: float = group_left + icon_width + icon_gap + 2.0
	var text_rect := Rect2(
		Vector2(text_left - 2.0, center_y - float(font_size) * 0.58 - 2.0),
		Vector2(text_width + 4.0, float(font_size) + 4.0)
	)
	var icon_rect := Rect2()
	if icon_width > 0.0:
		icon_rect = Rect2(
			Vector2(group_left, center_y - 10.0),
			Vector2(icon_width, 20.0)
		)
	return {
		"text": text,
		"font_size": font_size,
		"text_width": text_width,
		"center": Vector2(text_left + text_width * 0.5, center_y),
		"rect": text_rect,
		"icon_rect": icon_rect,
		"safe_rect": safe_rect,
	}


func port_label_layouts() -> Array[Dictionary]:
	var layouts: Array[Dictionary] = []
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var left: float = _body_left(global_t)
	var right: float = _body_right(global_t)
	if has_input:
		var text: String = _width_label(input_label, input_width)
		layouts.append(_text_layout(
			Vector2(left + 7.0, center_y), text, HORIZONTAL_ALIGNMENT_LEFT, 9, &"input"
		))
	if has_output:
		var text: String = _width_label(output_label, output_width)
		layouts.append(_text_layout(
			Vector2(right - 7.0, center_y), text, HORIZONTAL_ALIGNMENT_RIGHT, 9, &"output"
		))
	return layouts


func function_mark_rect() -> Rect2:
	if row_index != row_count / 2:
		return Rect2()
	var layout: Dictionary = name_layout()
	var result: Rect2 = layout["rect"]
	var icon_rect: Rect2 = layout["icon_rect"]
	if icon_rect.has_area():
		result = result.merge(icon_rect)
	return result.grow(2.0)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_draw_module_surface()
	_draw_pin_leads()
	_draw_processing_route()
	_draw_port_labels()
	if row_index == row_count / 2:
		_draw_function_mark()


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
	for layout: Dictionary in port_label_layouts():
		_draw_text(
			layout["anchor"], layout["text"], SYMBOL,
			layout["alignment"], int(layout["font_size"])
		)


func _draw_function_mark() -> void:
	var strength: float = _stage_strength(0.24, 0.76)
	var color: Color = SYMBOL.lerp(PROCESS, strength)
	var layout: Dictionary = name_layout()
	var icon_rect: Rect2 = layout["icon_rect"]
	if icon_rect.has_area():
		_draw_function_icon(icon_rect, color)
	var name_rect: Rect2 = layout["rect"]
	draw_rect(name_rect.grow(1.5), Color(SURFACE, 0.98), true)
	_draw_text(
		layout["center"], layout["text"], color,
		HORIZONTAL_ALIGNMENT_CENTER, int(layout["font_size"])
	)


func _draw_function_icon(rect: Rect2, color: Color) -> void:
	var center: Vector2 = rect.get_center()
	match component_kind:
		&"half_adder", &"full_adder":
			_draw_text(center, "Σ", color, HORIZONTAL_ALIGNMENT_CENTER, 13)
		&"mux4", &"mux2_word":
			_draw_mux_mark(center, color)
		&"alu1", &"alu4":
			_draw_alu_mark(center, color)
		&"sr_latch", &"register1", &"register4":
			_draw_latch_mark(center, color)
		&"decoder1_to_2", &"control":
			_draw_fanout_mark(center, color)
		&"ram2x4":
			_draw_ram_mark(center, color)
		&"tiny_computer":
			_draw_computer_mark(center, color)
		_:
			draw_circle(center, 5.0, color, false, 2.0, true)


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
		var guarded_rect := function_mark_rect()
		var input_start_x: float = left + 3.0
		var output_finish_x: float = right - 3.0
		for layout: Dictionary in port_label_layouts():
			var label_rect: Rect2 = layout["rect"]
			if StringName(layout["side"]) == &"input":
				input_start_x = maxf(input_start_x, label_rect.end.x + 3.0)
			else:
				output_finish_x = minf(output_finish_x, label_rect.position.x - 3.0)
		var input_finish_x: float = center_x - 15.0
		var output_start_x: float = center_x + 15.0
		if guarded_rect.has_area():
			input_finish_x = minf(input_finish_x, guarded_rect.position.x - 3.0)
			output_start_x = maxf(output_start_x, guarded_rect.end.x + 3.0)
		if has_input:
			if input_finish_x > input_start_x:
				draw_line(
					Vector2(input_start_x, center_y), Vector2(input_finish_x, center_y),
					route_color, 3.0, true
				)
		if _output_is_active() and output_start_x < output_finish_x:
			draw_line(
				Vector2(output_start_x, center_y), Vector2(output_finish_x, center_y),
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
	var wedge := PackedVector2Array([
		center + Vector2(-8.0, -8.0), center + Vector2(8.0, -5.0),
		center + Vector2(8.0, 5.0), center + Vector2(-8.0, 8.0),
		center + Vector2(-8.0, -8.0),
	])
	draw_polyline(wedge, color, 2.0, true)
	draw_line(center + Vector2(-11.0, -4.0), center + Vector2(-8.0, -4.0), color, 2.0, true)
	draw_line(center + Vector2(-11.0, 4.0), center + Vector2(-8.0, 4.0), color, 2.0, true)
	draw_line(center + Vector2(8.0, 0.0), center + Vector2(11.0, 0.0), color, 2.0, true)


func _draw_alu_mark(center: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		center + Vector2(-10.0, -8.0), center + Vector2(9.0, -6.0),
		center + Vector2(5.0, 0.0), center + Vector2(9.0, 6.0),
		center + Vector2(-10.0, 8.0), center + Vector2(-5.0, 0.0),
		center + Vector2(-10.0, -8.0),
	])
	draw_polyline(body, color, 2.0, true)
	draw_line(center + Vector2(-2.0, -3.0), center + Vector2(4.0, -3.0), color, 1.5, true)
	draw_line(center + Vector2(1.0, -6.0), center + Vector2(1.0, 0.0), color, 1.5, true)


func _draw_latch_mark(center: Vector2, color: Color) -> void:
	var rect := Rect2(center - Vector2(9.0, 7.0), Vector2(18.0, 14.0))
	draw_rect(rect, color, false, 2.0)
	draw_line(center + Vector2(-9.0, -3.0), center + Vector2(-5.0, -3.0), color, 1.5, true)
	draw_line(center + Vector2(-9.0, 3.0), center + Vector2(-5.0, 3.0), color, 1.5, true)
	draw_line(center + Vector2(5.0, -3.0), center + Vector2(9.0, -3.0), color, 1.5, true)
	draw_line(center + Vector2(5.0, 3.0), center + Vector2(9.0, 3.0), color, 1.5, true)


func _draw_fanout_mark(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-10.0, 0.0), center + Vector2(-2.0, 0.0), color, 2.0, true)
	draw_circle(center + Vector2(-2.0, 0.0), 2.0, color)
	draw_line(center + Vector2(-2.0, 0.0), center + Vector2(9.0, -6.0), color, 1.8, true)
	draw_line(center + Vector2(-2.0, 0.0), center + Vector2(9.0, 6.0), color, 1.8, true)


func _draw_ram_mark(center: Vector2, color: Color) -> void:
	var origin := center + Vector2(-10.0, -7.0)
	var cursor: int = ram_cursor_index()
	for address: int in range(2):
		var row_rect := Rect2(origin + Vector2(0.0, address * 8.0), Vector2(20.0, 6.0))
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
	var rect := Rect2(center + Vector2(-10.0, -7.0), Vector2(20.0, 14.0))
	draw_rect(rect, color, false, 2.0)
	draw_line(center + Vector2(0.0, -7.0), center + Vector2(0.0, 7.0), color, 1.5, true)
	draw_circle(center + Vector2(-5.0, 0.0), 2.0, color, false, 1.5, true)
	draw_rect(Rect2(center + Vector2(3.0, -3.0), Vector2(4.0, 6.0)), color, false, 1.0)


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
	var position := Vector2(x, anchor.y + float(font_size) * 0.36)
	for offset: Vector2 in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(0.0, 1.0)]:
		draw_string(
			ThemeDB.fallback_font, position + offset,
			text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(SURFACE, 0.96)
		)
	draw_string(
		ThemeDB.fallback_font,
		position,
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color
	)


func _name_font_size(text: String, preferred: int, max_width: float = 86.0) -> int:
	var font_size: int = preferred
	while font_size > 6 and _text_width(text, font_size) > max_width:
		font_size -= 1
	return font_size


func _text_width(text: String, font_size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x


func _text_layout(
		anchor: Vector2,
		text: String,
		alignment: HorizontalAlignment,
		font_size: int,
		side: StringName
	) -> Dictionary:
	var text_width: float = _text_width(text, font_size)
	var x: float = anchor.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x -= text_width * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= text_width
	return {
		"anchor": anchor,
		"text": text,
		"alignment": alignment,
		"font_size": font_size,
		"side": side,
		"rect": Rect2(
			Vector2(x - 2.0, anchor.y - float(font_size) * 0.58 - 2.0),
			Vector2(text_width + 4.0, float(font_size) + 4.0)
		),
	}


func _central_content_rect() -> Rect2:
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var safe_left: float = _body_left(global_t) + 8.0
	var safe_right: float = _body_right(global_t) - 8.0
	for layout: Dictionary in port_label_layouts():
		var rect: Rect2 = layout["rect"]
		if StringName(layout["side"]) == &"input":
			safe_left = maxf(safe_left, rect.end.x + 7.0)
		else:
			safe_right = minf(safe_right, rect.position.x - 7.0)
	if safe_right <= safe_left:
		var center_x: float = (_body_left(global_t) + _body_right(global_t)) * 0.5
		safe_left = center_x - 1.0
		safe_right = center_x + 1.0
	return Rect2(
		Vector2(safe_left, 3.0),
		Vector2(safe_right - safe_left, maxf(1.0, size.y - 6.0))
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
