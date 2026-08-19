class_name CircuitComponentSymbol
extends Control

const SURFACE := Color("101725")
const SYMBOL := Color("aebbd0")
const SELECTION := Color("50d5ff")

var component_kind: StringName = &""
var terminal_label: String = ""
var display_height: float = 46.0
var output_known: bool = false
var output_value: bool = false
var input_values: Array[bool] = []
var input_known: Array[bool] = []
var selection_active: bool = false


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


func set_selection_active(active: bool) -> void:
	if selection_active == active:
		return
	selection_active = active
	queue_redraw()


func symbol_color() -> Color:
	return SELECTION if selection_active else SYMBOL


func gate_label() -> String:
	return String(component_kind) if component_kind in [&"and", &"or", &"not", &"nor"] else ""


func _draw() -> void:
	match component_kind:
		&"and":
			_draw_and()
		&"or":
			_draw_or()
		&"nor":
			_draw_nor()
		&"not":
			_draw_not()
		&"input":
			_draw_source()
		&"output":
			_draw_observer(false)
		&"lamp":
			_draw_observer(true)
		&"junction":
			_draw_junction()


func _draw_and() -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var input_y := [display_height / 6.0, display_height * 5.0 / 6.0]
	var left: float = width * 0.28
	var arc_center_x: float = width * 0.56
	var radius: float = minf(display_height * 0.34, width * 0.22)
	var right: float = arc_center_x + radius
	var body_color: Color = symbol_color()
	_draw_input_lead(0, Vector2(0.0, input_y[0]), Vector2(left, input_y[0]))
	_draw_input_lead(1, Vector2(0.0, input_y[1]), Vector2(left, input_y[1]))
	draw_line(Vector2(left, center_y - radius), Vector2(arc_center_x, center_y - radius), body_color, 4.0, true)
	draw_line(Vector2(left, center_y - radius), Vector2(left, center_y + radius), body_color, 4.0, true)
	draw_line(Vector2(left, center_y + radius), Vector2(arc_center_x, center_y + radius), body_color, 4.0, true)
	draw_arc(Vector2(arc_center_x, center_y), radius, -PI * 0.5, PI * 0.5, 30, body_color, 4.0, true)
	_draw_centered_text(Vector2((left + right) * 0.5, center_y), "and", body_color)
	_draw_output_lead(Vector2(right, center_y), Vector2(width, center_y))


func _draw_or(label: String = "or", output_finish: float = -1.0) -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var input_y := [display_height / 6.0, display_height * 5.0 / 6.0]
	var left: float = width * 0.27
	var right: float = width * 0.78
	var top: float = display_height * 0.09
	var bottom: float = display_height * 0.91
	var body_color: Color = symbol_color()
	_draw_input_lead(0, Vector2(0.0, input_y[0]), Vector2(width * 0.38, input_y[0]))
	_draw_input_lead(1, Vector2(0.0, input_y[1]), Vector2(width * 0.38, input_y[1]))
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
	_draw_centered_text(Vector2(width * 0.55, center_y), label, body_color)
	_draw_output_lead(
		Vector2(right, center_y),
		Vector2(width if output_finish < 0.0 else output_finish, center_y)
	)


func _draw_nor() -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var bubble_center := Vector2(width * 0.82, center_y)
	_draw_or("nor", bubble_center.x - 6.0)
	draw_circle(bubble_center, 6.0, SURFACE)
	draw_circle(bubble_center, 6.0, symbol_color(), false, 3.0, true)
	_draw_output_lead(bubble_center + Vector2(6.0, 0.0), Vector2(width, center_y))


func _draw_not() -> void:
	var width: float = size.x
	var center_y: float = display_height * 0.5
	var left: float = width * 0.27
	var tip: float = width * 0.69
	var bubble_radius: float = 6.5
	var body_color: Color = symbol_color()
	_draw_input_lead(0, Vector2(0.0, center_y), Vector2(left, center_y))
	var triangle := PackedVector2Array([
		Vector2(left, display_height * 0.15),
		Vector2(left, display_height * 0.85),
		Vector2(tip, center_y),
		Vector2(left, display_height * 0.15),
	])
	draw_polyline(triangle, body_color, 4.0, true)
	draw_circle(Vector2(tip + bubble_radius, center_y), bubble_radius, SURFACE)
	draw_circle(Vector2(tip + bubble_radius, center_y), bubble_radius, body_color, false, 3.5, true)
	_draw_centered_text(Vector2((left + tip) * 0.5, center_y), "not", body_color)
	_draw_output_lead(Vector2(tip + bubble_radius * 2.0, center_y), Vector2(width, center_y))


func _draw_source() -> void:
	var width: float = size.x
	var center := Vector2(width * 0.48, display_height * 0.5)
	var color: Color = symbol_color()
	draw_circle(center, 16.0, Color(color, 0.16))
	draw_circle(center, 16.0, color, false, 4.0, true)
	draw_line(center + Vector2(16.0, 0.0), Vector2(width, center.y), color, 4.0, true)
	_draw_centered_text(center, terminal_label, color)


func _draw_observer(lamp: bool) -> void:
	var width: float = size.x
	var center := Vector2(width * 0.55, display_height * 0.5)
	var color: Color = symbol_color()
	_draw_input_lead(0, Vector2(0.0, center.y), center - Vector2(17.0, 0.0))
	draw_circle(center, 17.0, Color(color, 0.16))
	draw_circle(center, 17.0, color, false, 4.0, true)
	if lamp:
		for index: int in range(8):
			var direction := Vector2.from_angle(float(index) * TAU / 8.0)
			draw_line(center + direction * 21.0, center + direction * 27.0, color, 2.5, true)
	else:
		draw_line(center + Vector2(-7.0, 0.0), center + Vector2(7.0, 0.0), color, 3.0, true)
		draw_line(center + Vector2(2.0, -5.0), center + Vector2(7.0, 0.0), color, 3.0, true)
		draw_line(center + Vector2(2.0, 5.0), center + Vector2(7.0, 0.0), color, 3.0, true)
	_draw_centered_text(center + Vector2(0.0, 1.0), _short_label(terminal_label), color)


func _draw_junction() -> void:
	var center := Vector2(size.x * 0.5, display_height * 0.5)
	var color: Color = symbol_color()
	draw_line(Vector2(0.0, center.y), Vector2(size.x, center.y), color, 5.0, true)
	draw_circle(center, 8.0, SURFACE)
	draw_circle(center, 6.0, color)


func _draw_input_lead(_index: int, start: Vector2, finish: Vector2) -> void:
	draw_line(start, finish, symbol_color(), 4.0, true)


func _draw_output_lead(start: Vector2, finish: Vector2) -> void:
	draw_line(start, finish, symbol_color(), 4.0, true)


func _draw_centered_text(center: Vector2, text: String, color: Color) -> void:
	if text.is_empty():
		return
	var font_size: int = 13 if text.length() <= 3 else 10
	var text_width: float = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	draw_string(
		ThemeDB.fallback_font,
		center + Vector2(-text_width * 0.5, float(font_size) * 0.36),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)


func _short_label(label: String) -> String:
	if label.length() <= 5:
		return label
	return label.left(4)


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
