class_name CircuitComponentSymbol
extends Control

const SURFACE := Color("101725")
const SYMBOL := Color("aebbd0")
const SELECTION := Color("50d5ff")
const PROCESS := Color("50d5ff")
const SIGNAL_LOW := Color("ff6b7d")
const SIGNAL_HIGH := Color("67e8a5")
const SIGNAL_HIGH_Z := Color("8b929d")

var component_kind: StringName = &""
var terminal_label: String = ""
var display_height: float = 46.0
var output_known: bool = false
var output_value: bool = false
var input_values: Array[bool] = []
var input_known: Array[bool] = []
var selection_active: bool = false
var processing_active: bool = false
var processing_progress: float = 0.0
var processing_input_visuals: Array[Dictionary] = []
var processing_output_visual: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(kind: StringName, label: String, height: float) -> void:
	component_kind = kind
	terminal_label = label
	display_height = height
	queue_redraw()


func set_signal_state(
		p_output_known: bool,
		p_output_value: bool,
		p_input_values: Array[bool],
		p_input_known: Array[bool]
	) -> void:
	output_known = p_output_known
	output_value = p_output_value
	input_values = p_input_values.duplicate()
	input_known = p_input_known.duplicate()
	queue_redraw()


func clear_signal_state() -> void:
	output_known = false
	output_value = false
	input_values.clear()
	input_known.clear()
	queue_redraw()


func set_processing_state(
		progress: float,
		p_input_visuals: Array[Dictionary] = [],
		p_output_visual: Dictionary = {}
	) -> void:
	processing_active = true
	processing_progress = clampf(progress, 0.0, 1.0)
	processing_input_visuals = p_input_visuals.duplicate(true)
	processing_output_visual = p_output_visual.duplicate(true)
	queue_redraw()


func clear_processing_state() -> void:
	if not processing_active:
		return
	processing_active = false
	processing_progress = 0.0
	processing_input_visuals.clear()
	processing_output_visual.clear()
	queue_redraw()


func set_selection_active(active: bool) -> void:
	if selection_active == active:
		return
	selection_active = active
	queue_redraw()


func symbol_color() -> Color:
	return SELECTION if selection_active else SYMBOL


func gate_label() -> String:
	return String(component_kind) if component_kind in [&"and", &"or", &"xor", &"not", &"nor"] else ""


func name_layout() -> Dictionary:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var text: String = ""
	var center := Vector2(width * 0.5, center_y)
	var max_width: float = 0.0
	var preferred_font_size: int = 13
	var color: Color = symbol_color()
	match component_kind:
		&"and":
			var left: float = width * 0.28
			var arc_center_x: float = width * 0.56
			var radius: float = minf(display_height * 0.34, width * 0.22)
			text = "and"
			center.x = (left + arc_center_x + radius) * 0.5
			max_width = arc_center_x + radius - left - 10.0
			color = _stage_color(symbol_color(), 0.20, 0.80)
		&"or", &"xor", &"nor":
			text = String(component_kind)
			center.x = width * 0.55
			max_width = width * 0.36
			color = _stage_color(symbol_color(), 0.20, 0.80)
		&"not":
			var left: float = width * 0.27
			var tip: float = width * 0.69
			text = "not"
			center.x = lerpf(left, tip, 0.35)
			max_width = (tip - left) * 0.58
			preferred_font_size = 11
			color = _stage_color(symbol_color(), 0.20, 0.78)
		&"input":
			text = terminal_label
			center = Vector2(width * 0.41, display_height * 0.22)
			max_width = 52.0
			preferred_font_size = 10
		&"constant":
			text = str(int(output_value)) if output_known else "C"
			center.x = width * 0.48
			max_width = 24.0
		&"output", &"lamp":
			text = terminal_label
			center = Vector2(width * (0.59 if component_kind == &"output" else 0.55), display_height * 0.22)
			max_width = 58.0 if component_kind == &"output" else 42.0
			preferred_font_size = 10
	if text.is_empty():
		return {}
	var font_size: int = _fitted_font_size(text, preferred_font_size, max_width)
	var text_width: float = _text_width(text, font_size)
	return {
		"text": text,
		"center": center,
		"max_width": max_width,
		"font_size": font_size,
		"text_width": text_width,
		"rect": Rect2(
			center - Vector2(text_width * 0.5 + 1.0, float(font_size) * 0.5 + 2.0),
			Vector2(text_width + 2.0, float(font_size) + 4.0)
		),
		"color": color,
	}


func shape_profile() -> StringName:
	match component_kind:
		&"and": return &"ieee_and"
		&"or", &"nor": return &"ieee_or"
		&"xor": return &"ieee_xor"
		&"not": return &"ieee_inverter"
		&"input": return &"level_input_tag"
		&"output": return &"level_output_tag"
		&"lamp": return &"lamp_probe"
		&"constant": return &"constant_diamond"
		&"junction": return &"wire_junction"
	return &""


func _draw() -> void:
	match component_kind:
		&"and":
			_draw_and()
		&"or":
			_draw_or()
		&"xor":
			_draw_xor()
		&"nor":
			_draw_nor()
		&"not":
			_draw_not()
		&"input":
			_draw_source()
		&"constant":
			_draw_constant()
		&"output":
			_draw_observer(false)
		&"lamp":
			_draw_observer(true)
		&"junction":
			_draw_junction()
	_draw_name_overlay()
	if component_kind in [&"input", &"output", &"lamp"]:
		_draw_terminal_value()


func visual_hit_test(point: Vector2, tolerance: float = 3.0) -> bool:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	match component_kind:
		&"input":
			var center := Vector2(width * 0.41, center_y)
			var body := PackedVector2Array([
				center + Vector2(-26.0, -22.0), center + Vector2(8.0, -22.0),
				center + Vector2(26.0, 0.0), center + Vector2(8.0, 22.0),
				center + Vector2(-26.0, 22.0),
			])
			return Geometry2D.is_point_in_polygon(point, body) or _near_segment(
				point, center + Vector2(26.0, 0.0), Vector2(width, center.y), tolerance + 2.0
			)
		&"output":
			var center := Vector2(width * 0.59, center_y)
			var body := PackedVector2Array([
				center + Vector2(-26.0, 0.0), center + Vector2(-8.0, -22.0),
				center + Vector2(26.0, -22.0), center + Vector2(26.0, 22.0),
				center + Vector2(-8.0, 22.0),
			])
			return Geometry2D.is_point_in_polygon(point, body) or _near_segment(
				point, Vector2(0.0, center.y), center + Vector2(-26.0, 0.0), tolerance + 2.0
			)
		&"lamp":
			var center := Vector2(width * 0.55, center_y)
			return point.distance_to(center) <= 22.0 + tolerance or _near_segment(
				point, Vector2(0.0, center.y), center - Vector2(22.0, 0.0), tolerance + 2.0
			)
		&"and":
			var left: float = width * 0.28
			var arc_center_x: float = width * 0.56
			var radius: float = minf(display_height * 0.34, width * 0.22)
			return Rect2(
				Vector2(left - tolerance, center_y - radius - tolerance),
				Vector2(arc_center_x + radius - left + tolerance * 2.0, radius * 2.0 + tolerance * 2.0)
			).has_point(point) or _near_gate_leads(point, left, arc_center_x + radius, tolerance)
		&"or", &"xor", &"nor":
			var left: float = width * (0.22 if component_kind == &"xor" else 0.27)
			var right: float = width * (0.88 if component_kind == &"nor" else 0.78)
			return Rect2(
				Vector2(left - tolerance, display_height * 0.09 - tolerance),
				Vector2(right - left + tolerance * 2.0, display_height * 0.82 + tolerance * 2.0)
			).has_point(point) or _near_gate_leads(point, width * 0.38, right, tolerance)
		&"not":
			var left: float = width * 0.27
			var right: float = width * 0.69 + 13.0
			var triangle := PackedVector2Array([
				Vector2(left, display_height * 0.15),
				Vector2(left, display_height * 0.85),
				Vector2(width * 0.69, center_y),
			])
			return Geometry2D.is_point_in_polygon(point, triangle) \
				or point.distance_to(Vector2(width * 0.69 + 6.5, center_y)) <= 6.5 + tolerance \
				or _near_segment(point, Vector2(0.0, center_y), Vector2(left, center_y), tolerance + 2.0) \
				or _near_segment(point, Vector2(right, center_y), Vector2(width, center_y), tolerance + 2.0)
		&"constant":
			var center := Vector2(width * 0.48, center_y)
			var diamond := PackedVector2Array([
				center + Vector2(0.0, -16.0), center + Vector2(16.0, 0.0),
				center + Vector2(0.0, 16.0), center + Vector2(-16.0, 0.0),
			])
			return Geometry2D.is_point_in_polygon(point, diamond) or _near_segment(
				point, center + Vector2(16.0, 0.0), Vector2(width, center.y), tolerance + 2.0
			)
		&"junction":
			return _near_segment(point, Vector2(0.0, center_y), Vector2(width, center_y), tolerance + 3.0)
	return Rect2(Vector2.ZERO, Vector2(width, display_height)).grow(-4.0).has_point(point)


func _near_gate_leads(point: Vector2, input_finish_x: float, output_start_x: float, tolerance: float) -> bool:
	for y: float in [display_height / 6.0, display_height * 5.0 / 6.0]:
		if _near_segment(point, Vector2(0.0, y), Vector2(input_finish_x, y), tolerance + 2.0):
			return true
	return _near_segment(
		point, Vector2(output_start_x, display_height * 0.5),
		Vector2(size.x, display_height * 0.5), tolerance + 2.0
	)


func _near_segment(point: Vector2, start: Vector2, finish: Vector2, tolerance: float) -> bool:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, finish)) <= tolerance


func _draw_and() -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var input_y := [display_height / 6.0, display_height * 5.0 / 6.0]
	var left: float = width * 0.28
	var arc_center_x: float = width * 0.56
	var radius: float = minf(display_height * 0.34, width * 0.22)
	var right: float = arc_center_x + radius
	var base: Color = symbol_color()
	var input_color: Color = _stage_color(base, 0.0, 0.48)
	var body_color: Color = _stage_color(base, 0.20, 0.80)
	var output_color: Color = _stage_color(base, 0.56, 1.0)
	_draw_input_lead(Vector2(0.0, input_y[0]), Vector2(left, input_y[0]), input_color)
	_draw_input_lead(Vector2(0.0, input_y[1]), Vector2(left, input_y[1]), input_color)
	draw_line(Vector2(left, center_y - radius), Vector2(arc_center_x, center_y - radius), body_color, 4.0, true)
	draw_line(Vector2(left, center_y - radius), Vector2(left, center_y + radius), body_color, 4.0, true)
	draw_line(Vector2(left, center_y + radius), Vector2(arc_center_x, center_y + radius), body_color, 4.0, true)
	draw_arc(Vector2(arc_center_x, center_y), radius, -PI * 0.5, PI * 0.5, 30, body_color, 4.0, true)
	_draw_output_lead(Vector2(right, center_y), Vector2(width, center_y), output_color)
	_draw_processing_dot(
		Vector2(0.0, input_y[0]), Vector2(left, input_y[0]), 0.0, 0.38,
		_processing_input_visual(0)
	)
	_draw_processing_dot(
		Vector2(0.0, input_y[1]), Vector2(left, input_y[1]), 0.0, 0.38,
		_processing_input_visual(1)
	)
	_draw_processing_dot(
		Vector2(right, center_y), Vector2(width, center_y), 0.62, 1.0,
		_processing_output_visual()
	)


func _draw_or(
		output_finish: float = -1.0,
		draw_output_token: bool = true
	) -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var input_y := [display_height / 6.0, display_height * 5.0 / 6.0]
	var left: float = width * 0.27
	var right: float = width * 0.78
	var top: float = display_height * 0.09
	var bottom: float = display_height * 0.91
	var finish: float = width if output_finish < 0.0 else output_finish
	var base: Color = symbol_color()
	var input_color: Color = _stage_color(base, 0.0, 0.48)
	var body_color: Color = _stage_color(base, 0.20, 0.80)
	var output_color: Color = _stage_color(base, 0.56, 1.0)
	_draw_input_lead(Vector2(0.0, input_y[0]), Vector2(width * 0.38, input_y[0]), input_color)
	_draw_input_lead(Vector2(0.0, input_y[1]), Vector2(width * 0.38, input_y[1]), input_color)
	draw_polyline(_cubic(
		Vector2(left, top), Vector2(width * 0.49, top),
		Vector2(width * 0.69, display_height * 0.17), Vector2(right, center_y)
	), body_color, 4.0, true)
	draw_polyline(_cubic(
		Vector2(right, center_y), Vector2(width * 0.69, display_height * 0.83),
		Vector2(width * 0.49, bottom), Vector2(left, bottom)
	), body_color, 4.0, true)
	draw_polyline(_cubic(
		Vector2(left, top), Vector2(width * 0.43, display_height * 0.28),
		Vector2(width * 0.43, display_height * 0.72), Vector2(left, bottom)
	), body_color, 4.0, true)
	_draw_output_lead(Vector2(right, center_y), Vector2(finish, center_y), output_color)
	_draw_processing_dot(
		Vector2(0.0, input_y[0]), Vector2(width * 0.38, input_y[0]), 0.0, 0.38,
		_processing_input_visual(0)
	)
	_draw_processing_dot(
		Vector2(0.0, input_y[1]), Vector2(width * 0.38, input_y[1]), 0.0, 0.38,
		_processing_input_visual(1)
	)
	if draw_output_token:
		_draw_processing_dot(
			Vector2(right, center_y), Vector2(finish, center_y), 0.62, 1.0,
			_processing_output_visual()
		)


func _draw_xor() -> void:
	_draw_or()
	var width: float = size.x
	var top: float = display_height * 0.09
	var bottom: float = display_height * 0.91
	var left: float = width * 0.22
	var body_color: Color = _stage_color(symbol_color(), 0.20, 0.80)
	draw_polyline(_cubic(
		Vector2(left, top), Vector2(width * 0.38, display_height * 0.28),
		Vector2(width * 0.38, display_height * 0.72), Vector2(left, bottom)
	), body_color, 3.0, true)


func _draw_nor() -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var bubble_center := Vector2(width * 0.82, center_y)
	_draw_or(bubble_center.x - 6.0, false)
	var body_color: Color = _stage_color(symbol_color(), 0.20, 0.86)
	draw_circle(bubble_center, 6.0, SURFACE)
	draw_circle(bubble_center, 6.0, body_color, false, 3.0, true)
	_draw_output_lead(
		bubble_center + Vector2(6.0, 0.0),
		Vector2(width, center_y),
		_stage_color(symbol_color(), 0.62, 1.0)
	)
	_draw_processing_dot(
		bubble_center + Vector2(6.0, 0.0), Vector2(width, center_y), 0.67, 1.0,
		_processing_output_visual()
	)


func _draw_not() -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var left: float = width * 0.27
	var tip: float = width * 0.69
	var bubble_radius: float = 6.5
	var base: Color = symbol_color()
	var input_color: Color = _stage_color(base, 0.0, 0.45)
	var body_color: Color = _stage_color(base, 0.20, 0.78)
	var output_color: Color = _stage_color(base, 0.58, 1.0)
	_draw_input_lead(Vector2(0.0, center_y), Vector2(left, center_y), input_color)
	var triangle := PackedVector2Array([
		Vector2(left, display_height * 0.15),
		Vector2(left, display_height * 0.85),
		Vector2(tip, center_y),
		Vector2(left, display_height * 0.15),
	])
	draw_polyline(triangle, body_color, 4.0, true)
	draw_circle(Vector2(tip + bubble_radius, center_y), bubble_radius, SURFACE)
	draw_circle(Vector2(tip + bubble_radius, center_y), bubble_radius, body_color, false, 3.5, true)
	var output_start := Vector2(tip + bubble_radius * 2.0, center_y)
	_draw_output_lead(output_start, Vector2(width, center_y), output_color)
	_draw_processing_dot(
		Vector2(0.0, center_y), Vector2(left, center_y), 0.0, 0.38,
		_processing_input_visual(0)
	)
	_draw_processing_dot(
		output_start, Vector2(width, center_y), 0.62, 1.0,
		_processing_output_visual()
	)


func _draw_source() -> void:
	var width: float = size.x
	var center := Vector2(width * 0.41, display_height * 0.5)
	var signal_color: Color = _terminal_signal_color()
	var body := PackedVector2Array([
		center + Vector2(-26.0, -22.0),
		center + Vector2(8.0, -22.0),
		center + Vector2(26.0, 0.0),
		center + Vector2(8.0, 22.0),
		center + Vector2(-26.0, 22.0),
		center + Vector2(-26.0, -22.0),
	])
	draw_colored_polygon(PackedVector2Array(body.slice(0, 5)), Color(signal_color, 0.92))
	draw_polyline(body, SELECTION if selection_active else signal_color.lightened(0.18), 4.0, true)
	_draw_output_lead(center + Vector2(26.0, 0.0), Vector2(width, center.y), signal_color)
	_draw_processing_dot(
		center + Vector2(12.0, 0.0), Vector2(width, center.y), 0.22, 1.0,
		_processing_output_visual()
	)


func _draw_constant() -> void:
	var width: float = size.x
	var center := Vector2(width * 0.48, display_height * 0.5)
	var base: Color = symbol_color()
	var body_color: Color = base
	var output_color: Color = _stage_color(base, 0.34, 1.0)
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -16.0), center + Vector2(16.0, 0.0),
		center + Vector2(0.0, 16.0), center + Vector2(-16.0, 0.0),
		center + Vector2(0.0, -16.0),
	])
	draw_polyline(diamond, body_color, 4.0, true)
	_draw_output_lead(center + Vector2(16.0, 0.0), Vector2(width, center.y), output_color)
	_draw_processing_dot(
		center + Vector2(4.0, 0.0), Vector2(width, center.y), 0.22, 1.0,
		_processing_output_visual()
	)


func _draw_observer(lamp: bool) -> void:
	var width: float = size.x
	var center := Vector2(width * (0.55 if lamp else 0.59), display_height * 0.5)
	var signal_color: Color = _terminal_signal_color()
	var entry_finish := center - Vector2(22.0 if lamp else 26.0, 0.0)
	_draw_input_lead(Vector2(0.0, center.y), entry_finish, signal_color)
	if lamp:
		draw_circle(center, 22.0, Color(signal_color, 0.92))
		draw_circle(center, 22.0, SELECTION if selection_active else signal_color.lightened(0.18), false, 4.0, true)
		for index: int in range(8):
			var direction := Vector2.from_angle(float(index) * TAU / 8.0)
			draw_line(center + direction * 25.0, center + direction * 29.0, signal_color, 2.5, true)
	else:
		var body := PackedVector2Array([
			center + Vector2(-26.0, 0.0),
			center + Vector2(-8.0, -22.0),
			center + Vector2(26.0, -22.0),
			center + Vector2(26.0, 22.0),
			center + Vector2(-8.0, 22.0),
			center + Vector2(-26.0, 0.0),
		])
		draw_colored_polygon(PackedVector2Array(body.slice(0, 5)), Color(signal_color, 0.92))
		draw_polyline(body, SELECTION if selection_active else signal_color.lightened(0.18), 4.0, true)
	_draw_processing_dot(
		Vector2(0.0, center.y), center - Vector2(2.0, 0.0), 0.0, 0.76,
		_processing_input_visual(0)
	)


func _terminal_signal_color() -> Color:
	if component_kind == &"input":
		return SIGNAL_HIGH if output_known and output_value else SIGNAL_LOW if output_known else SIGNAL_HIGH_Z
	var known: bool = not input_known.is_empty() and input_known[0]
	var value: bool = not input_values.is_empty() and input_values[0]
	return SIGNAL_HIGH if known and value else SIGNAL_LOW if known else SIGNAL_HIGH_Z


func _terminal_value_text() -> String:
	if component_kind == &"input":
		return str(int(output_value)) if output_known else "?"
	var known: bool = not input_known.is_empty() and input_known[0]
	return str(int(input_values[0])) if known and not input_values.is_empty() else "?"


func _draw_terminal_value() -> void:
	var center_x: float = size.x * (0.41 if component_kind == &"input" else 0.55 if component_kind == &"lamp" else 0.59)
	var text: String = _terminal_value_text()
	var font_size: int = 23
	var text_width: float = _text_width(text, font_size)
	var position := Vector2(center_x - text_width * 0.5, display_height * 0.71)
	for offset: Vector2 in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(0.0, 1.0)]:
		draw_string(
			ThemeDB.fallback_font, position + offset, text,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(SURFACE, 0.98)
		)
	draw_string(
		ThemeDB.fallback_font, position, text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color("f7fbff")
	)


func _draw_junction() -> void:
	var center := Vector2(size.x * 0.5, display_height * 0.5)
	var color: Color = _stage_color(symbol_color(), 0.0, 1.0)
	draw_line(Vector2(0.0, center.y), Vector2(size.x, center.y), color, 5.0, true)
	draw_circle(center, 8.0, SURFACE)
	draw_circle(center, 6.0, color)
	_draw_processing_dot(
		Vector2(0.0, center.y), Vector2(size.x, center.y), 0.0, 1.0,
		_processing_input_visual(0)
	)


func _draw_input_lead(start: Vector2, finish: Vector2, color: Color) -> void:
	draw_line(start, finish, color, 4.0, true)


func _draw_output_lead(start: Vector2, finish: Vector2, color: Color) -> void:
	draw_line(start, finish, color, 4.0, true)


func _stage_color(base: Color, start: float, finish: float) -> Color:
	return base.lerp(PROCESS, _stage_strength(start, finish) * 0.94)


func _stage_strength(start: float, finish: float) -> float:
	if not processing_active or finish <= start:
		return 0.0
	if processing_progress < start or processing_progress > finish:
		return 0.0
	return sin(inverse_lerp(start, finish, processing_progress) * PI)


func _draw_processing_dot(
		start: Vector2,
		finish: Vector2,
		stage_start: float,
		stage_end: float,
		visual: Dictionary = {}
	) -> void:
	if not processing_active or stage_end <= stage_start:
		return
	if processing_progress < stage_start or processing_progress > stage_end:
		return
	var local_progress: float = smoothstep(
		0.0, 1.0, inverse_lerp(stage_start, stage_end, processing_progress)
	)
	var point: Vector2 = start.lerp(finish, local_progress)
	var color: Color = visual.get("color", PROCESS)
	# Processing is a growing lead/surface state, not a detached data point.
	draw_line(start, point, Color(color, 0.26), 8.0, true)
	draw_line(start, point, color, 3.5, true)


func _processing_input_visual(index: int) -> Dictionary:
	if index >= 0 and index < processing_input_visuals.size():
		return processing_input_visuals[index]
	if index >= 0 and index < input_values.size() and index < input_known.size():
		return _bool_visual(input_values[index], input_known[index])
	return {"known": false, "numeric": 0, "text": "Z", "color": SIGNAL_HIGH_Z}


func _processing_output_visual() -> Dictionary:
	if not processing_output_visual.is_empty():
		return processing_output_visual
	return _bool_visual(output_value, output_known)


func _bool_visual(value: bool, known: bool) -> Dictionary:
	if not known:
		return {"known": false, "numeric": 0, "text": "Z", "color": SIGNAL_HIGH_Z}
	return {
		"known": true,
		"numeric": 1 if value else 0,
		"text": str(int(value)),
		"color": SIGNAL_HIGH if value else SIGNAL_LOW,
	}


func _draw_value_badge(center: Vector2, text: String, color: Color) -> void:
	var font_size: int = 8
	var text_width: float = ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x
	var rect := Rect2(
		center - Vector2((text_width + 6.0) * 0.5, 6.0),
		Vector2(text_width + 6.0, 12.0)
	)
	draw_rect(rect, Color(SURFACE, 0.94), true)
	draw_rect(rect, Color(color, 0.82), false, 1.0)
	draw_string(
		ThemeDB.fallback_font,
		center + Vector2(-text_width * 0.5, float(font_size) * 0.36),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color
	)


func _draw_name_overlay() -> void:
	var layout: Dictionary = name_layout()
	if layout.is_empty():
		return
	var center: Vector2 = layout["center"]
	var text: String = layout["text"]
	var font_size: int = int(layout["font_size"])
	var text_width: float = float(layout["text_width"])
	var position := center + Vector2(-text_width * 0.5, float(font_size) * 0.36)
	for offset: Vector2 in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(0.0, 1.0)]:
		draw_string(
			ThemeDB.fallback_font, position + offset, text,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(SURFACE, 0.98)
		)
	draw_string(
		ThemeDB.fallback_font, position, text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, layout["color"]
	)


func _fitted_font_size(text: String, preferred: int, max_width: float) -> int:
	var font_size: int = preferred
	while font_size > 8 and _text_width(text, font_size) > max_width:
		font_size -= 1
	return font_size


func _text_width(text: String, font_size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x


func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(25):
		var t: float = float(index) / 24.0
		var one_minus_t: float = 1.0 - t
		points.append(
			a * one_minus_t * one_minus_t * one_minus_t
			+ b * 3.0 * one_minus_t * one_minus_t * t
			+ c * 3.0 * one_minus_t * t * t
			+ d * t * t * t
		)
	return points
