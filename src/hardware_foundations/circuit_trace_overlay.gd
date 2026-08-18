class_name CircuitTraceOverlay
extends Control

const PROCESS_COLOR := Color("50d5ff")

var mode: StringName = &""
var progress: float = 0.0
var signal_value: bool = false
var path: PackedVector2Array = PackedVector2Array()
var component_rect: Rect2 = Rect2()
var component_kind: StringName = &""
var input_values: Array[bool] = []
var caption: String = ""
var value_text: String = ""
var wire_pulses: Array[Dictionary] = []
var component_pulses: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_wire(p_path: PackedVector2Array, p_progress: float, value: bool) -> void:
	mode = &"wire"
	wire_pulses = [{"path": p_path, "progress": p_progress, "value": value}]
	component_pulses.clear()
	path = p_path
	progress = smoothstep(0.0, 1.0, clampf(p_progress, 0.0, 1.0))
	signal_value = value
	value_text = str(int(value))
	queue_redraw()


func show_component(
		p_rect: Rect2,
		p_kind: StringName,
		p_progress: float,
		value: bool,
		p_input_values: Array[bool],
		p_caption: String
	) -> void:
	mode = &"component"
	wire_pulses.clear()
	component_pulses = [{
		"rect": p_rect,
		"kind": p_kind,
		"progress": p_progress,
		"value": value,
		"input_values": p_input_values,
		"caption": p_caption,
	}]
	component_rect = p_rect
	component_kind = p_kind
	progress = smoothstep(0.0, 1.0, clampf(p_progress, 0.0, 1.0))
	signal_value = value
	input_values = p_input_values.duplicate()
	caption = p_caption
	queue_redraw()


func show_parallel(
		p_wire_pulses: Array[Dictionary],
		p_component_pulses: Array[Dictionary]
	) -> void:
	mode = &"parallel"
	wire_pulses = p_wire_pulses.duplicate(true)
	component_pulses = p_component_pulses.duplicate(true)
	if not wire_pulses.is_empty():
		path = wire_pulses[0].get("path", PackedVector2Array())
	if not component_pulses.is_empty():
		component_rect = component_pulses[0].get("rect", Rect2())
		component_kind = component_pulses[0].get("kind", &"")
	queue_redraw()


func clear_event() -> void:
	mode = &""
	wire_pulses.clear()
	component_pulses.clear()
	path = PackedVector2Array()
	component_rect = Rect2()
	caption = ""
	value_text = ""
	queue_redraw()


func _draw() -> void:
	if mode == &"parallel":
		for wire_pulse: Dictionary in wire_pulses:
			path = wire_pulse.get("path", PackedVector2Array())
			progress = smoothstep(0.0, 1.0, clampf(float(wire_pulse.get("progress", 0.0)), 0.0, 1.0))
			signal_value = bool(wire_pulse.get("value", false))
			value_text = String(wire_pulse.get("display", str(int(signal_value))))
			_draw_wire_signal()
		for component_pulse: Dictionary in component_pulses:
			component_rect = component_pulse.get("rect", Rect2())
			component_kind = component_pulse.get("kind", &"")
			progress = smoothstep(0.0, 1.0, clampf(float(component_pulse.get("progress", 0.0)), 0.0, 1.0))
			signal_value = bool(component_pulse.get("value", false))
			input_values.assign(component_pulse.get("input_values", []))
			caption = String(component_pulse.get("caption", ""))
			_draw_component_process()
	elif mode == &"wire":
		_draw_wire_signal()
	elif mode == &"component":
		_draw_component_process()


func _draw_wire_signal() -> void:
	if path.size() < 2:
		return
	var color: Color = Color("67e8a5") if signal_value else Color("ff6b7d")
	var current: Vector2 = _point_on_path(path, progress)
	var tail := PackedVector2Array()
	var tail_start: float = maxf(0.0, progress - 0.13)
	for sample: int in range(20):
		tail.append(_point_on_path(path, lerpf(tail_start, progress, float(sample) / 19.0)))
	draw_polyline(tail, Color(color, 0.18), 14.0, true)
	draw_polyline(tail, Color(color, 0.9), 4.0, true)
	for tail_index: int in range(1, 5):
		var dot: Vector2 = _point_on_path(path, maxf(0.0, progress - float(tail_index) * 0.03))
		draw_circle(dot, 7.0 - float(tail_index), Color(color, 0.42 / float(tail_index)))
	var pulse: float = 1.0 + 0.28 * sin(progress * PI)
	draw_circle(current, 15.0 * pulse, Color(color, 0.2))
	draw_circle(current, 8.0, color)
	_draw_badge(
		current + Vector2(17.0, -16.0),
		value_text if not value_text.is_empty() else str(int(signal_value)), color
	)


func _draw_component_process() -> void:
	if component_rect.size == Vector2.ZERO:
		return
	var center: Vector2 = component_rect.get_center()
	var color: Color = PROCESS_COLOR
	var halo_progress: float = sin(progress * PI)
	var halo_radius: float = minf(component_rect.size.x, component_rect.size.y) * 0.38 + 10.0 * halo_progress
	draw_circle(center, halo_radius, Color(color, 0.04 + 0.08 * halo_progress))
	draw_arc(center, halo_radius + 5.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 42, Color(color, 0.28 + 0.45 * halo_progress), 3.0, true)
	match component_kind:
		&"and":
			_draw_and(center, color)
		&"or":
			_draw_or(center, color)
		&"nor":
			_draw_nor(center, color)
		&"not":
			_draw_not(center, color)
		&"half_adder", &"full_adder":
			_draw_adder(center, color)
		&"mux4", &"mux2_word":
			_draw_mux(center, color)
		&"alu1", &"alu4":
			_draw_alu(center, color)
		&"sr_latch":
			_draw_latch(center, color)
		&"register1", &"register4":
			_draw_register(center, color)
		&"ram2x4":
			_draw_ram(center, color)
		&"control":
			_draw_control(center, color)
		&"decoder1_to_2":
			_draw_decoder(center, color)
		&"tiny_computer":
			_draw_computer(center, color)
		&"input":
			_draw_input(center, color)
		&"lamp", &"output":
			_draw_observer(center, color)
		_:
			draw_circle(center, 22.0 + 5.0 * sin(progress * PI), Color(color, 0.35), false, 4.0, true)
	if not caption.is_empty():
		_draw_badge(component_rect.position + Vector2(4.0, -29.0), caption, color)


func _draw_and(center: Vector2, color: Color) -> void:
	var merge: float = minf(progress * 1.7, 1.0)
	var left_top: Vector2 = center + Vector2(lerpf(-35.0, -7.0, merge), lerpf(-12.0, 0.0, merge))
	var left_bottom: Vector2 = center + Vector2(lerpf(-35.0, -7.0, merge), lerpf(12.0, 0.0, merge))
	draw_line(left_top, center, Color(color, 0.55), 3.0, true)
	draw_line(left_bottom, center, Color(color, 0.55), 3.0, true)
	draw_circle(left_top, 6.0, _input_color(0))
	draw_circle(left_bottom, 6.0, _input_color(1))
	var output_progress: float = clampf((progress - 0.48) / 0.52, 0.0, 1.0)
	var output: Vector2 = center.lerp(center + Vector2(35.0, 0.0), output_progress)
	draw_arc(center, 16.0, -PI * 0.5, PI * 0.5, 18, color, 3.0, true)
	draw_circle(output, 7.0, color)


func _draw_or(center: Vector2, color: Color) -> void:
	var phase: float = progress * TAU
	for offset: float in [-1.0, 1.0]:
		var start: Vector2 = center + Vector2(-35.0, offset * 12.0)
		var control: Vector2 = center + Vector2(-4.0, offset * (9.0 - progress * 9.0))
		var points := PackedVector2Array([start, start.lerp(control, 0.5), control, center])
		draw_polyline(points, Color(color, 0.65), 3.0, true)
		draw_circle(start.lerp(center, minf(progress * 1.45, 1.0)), 6.0, _input_color(0 if offset < 0.0 else 1))
	draw_arc(center, 17.0, phase, phase + PI * 1.4, 22, color, 3.0, true)
	var output: Vector2 = center.lerp(center + Vector2(35.0, 0.0), clampf((progress - 0.45) / 0.55, 0.0, 1.0))
	draw_circle(output, 7.0, color)


func _draw_nor(center: Vector2, color: Color) -> void:
	_draw_or(center, color)
	var invert_progress: float = clampf((progress - 0.48) / 0.32, 0.0, 1.0)
	var bubble_center := center + Vector2(20.0, 0.0)
	draw_circle(bubble_center, 5.0 + 4.0 * sin(invert_progress * PI), Color("101725"))
	draw_circle(bubble_center, 5.0 + 4.0 * sin(invert_progress * PI), color, false, 3.0, true)


func _draw_not(center: Vector2, color: Color) -> void:
	var entry: Vector2 = center + Vector2(lerpf(-35.0, 0.0, minf(progress * 1.8, 1.0)), 0.0)
	var triangle := PackedVector2Array([center + Vector2(-18.0, -15.0), center + Vector2(-18.0, 15.0), center + Vector2(12.0, 0.0)])
	draw_polyline(PackedVector2Array([triangle[0], triangle[1], triangle[2], triangle[0]]), Color(color, 0.8), 3.0, true)
	draw_circle(entry, 7.0, _input_color(0))
	var invert_pulse: float = clampf((progress - 0.42) / 0.25, 0.0, 1.0)
	draw_circle(center + Vector2(18.0, 0.0), 5.0 + 5.0 * sin(invert_pulse * PI), color, false, 3.0, true)
	var output_progress: float = clampf((progress - 0.62) / 0.38, 0.0, 1.0)
	draw_circle(center + Vector2(18.0 + 20.0 * output_progress, 0.0), 7.0, color)


func _draw_adder(center: Vector2, color: Color) -> void:
	var merge: float = minf(progress * 1.7, 1.0)
	for y: float in [-14.0, 14.0]:
		var start := center + Vector2(-42.0, y)
		var moving := start.lerp(center, merge)
		draw_line(start, center, Color(color, 0.38), 2.5, true)
		draw_circle(moving, 6.0, color)
	draw_circle(center, 18.0 + 4.0 * sin(progress * PI), Color(color, 0.12))
	draw_line(center + Vector2(-8.0, 0.0), center + Vector2(8.0, 0.0), color, 3.0, true)
	draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, 8.0), color, 3.0, true)
	var split: float = clampf((progress - 0.52) / 0.48, 0.0, 1.0)
	for y: float in [-12.0, 12.0]:
		var destination := center + Vector2(43.0, y)
		draw_line(center, destination, Color(color, 0.35), 2.5, true)
		draw_circle(center.lerp(destination, split), 6.0, color)


func _draw_mux(center: Vector2, color: Color) -> void:
	var selected: int = int(floor(progress * 4.0)) % 4
	for index: int in range(4):
		var start := center + Vector2(-43.0, -24.0 + float(index) * 16.0)
		var tint: Color = color if index == selected else Color(color, 0.25)
		draw_line(start, center, tint, 2.5, true)
		draw_circle(start.lerp(center, progress), 5.5, tint)
	var output_progress: float = clampf((progress - 0.42) / 0.58, 0.0, 1.0)
	draw_line(center, center + Vector2(45.0, 0.0), Color(color, 0.45), 3.0, true)
	draw_circle(center + Vector2(45.0 * output_progress, 0.0), 7.0, color)
	draw_polyline(PackedVector2Array([
		center + Vector2(-14.0, -28.0), center + Vector2(14.0, -17.0),
		center + Vector2(14.0, 17.0), center + Vector2(-14.0, 28.0),
		center + Vector2(-14.0, -28.0),
	]), color, 3.0, true)


func _draw_alu(center: Vector2, color: Color) -> void:
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -29.0), center + Vector2(34.0, 0.0),
		center + Vector2(0.0, 29.0), center + Vector2(-34.0, 0.0),
		center + Vector2(0.0, -29.0),
	])
	draw_polyline(diamond, Color(color, 0.78), 3.5, true)
	var operations := ["&", "≥1", "+", "¬"]
	var operation_index: int = mini(3, int(progress * 4.0))
	_draw_binary(center + Vector2(-7.0, 5.0), operations[operation_index], color)
	var radius: float = 11.0 + 14.0 * progress
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 28, color, 3.0, true)


func _draw_latch(center: Vector2, color: Color) -> void:
	var phase: float = progress * TAU
	draw_arc(center + Vector2(-12.0, 0.0), 20.0, phase, phase + PI * 1.55, 26, color, 3.0, true)
	draw_arc(center + Vector2(12.0, 0.0), 20.0, phase + PI, phase + PI * 2.55, 26, Color(color, 0.65), 3.0, true)
	draw_line(center + Vector2(-22.0, -13.0), center + Vector2(22.0, 13.0), Color(color, 0.42), 2.5, true)
	draw_line(center + Vector2(-22.0, 13.0), center + Vector2(22.0, -13.0), Color(color, 0.42), 2.5, true)
	draw_circle(center, 7.0 + 5.0 * sin(progress * PI), color)


func _draw_register(center: Vector2, color: Color) -> void:
	draw_rect(Rect2(center - Vector2(27.0, 23.0), Vector2(54.0, 46.0)), Color(color, 0.08), true)
	draw_rect(Rect2(center - Vector2(27.0, 23.0), Vector2(54.0, 46.0)), color, false, 3.0, true)
	var input_progress: float = minf(progress * 2.0, 1.0)
	draw_circle(center + Vector2(lerpf(-47.0, 0.0, input_progress), 0.0), 6.0, color)
	var stored_pulse: float = clampf((progress - 0.35) / 0.3, 0.0, 1.0)
	draw_circle(center, 7.0 + 8.0 * sin(stored_pulse * PI), Color(color, 0.75))
	var output_progress: float = clampf((progress - 0.63) / 0.37, 0.0, 1.0)
	draw_circle(center + Vector2(47.0 * output_progress, 0.0), 6.0, color)


func _draw_ram(center: Vector2, color: Color) -> void:
	var cell_size := Vector2(25.0, 19.0)
	for row: int in range(2):
		for column: int in range(2):
			var cell_index: int = row * 2 + column
			var rect := Rect2(center + Vector2(-27.0 + column * 29.0, -21.0 + row * 23.0), cell_size)
			var active: bool = cell_index == int(progress * 4.0) % 4
			draw_rect(rect, Color(color, 0.22 if active else 0.05), true)
			draw_rect(rect, color if active else Color(color, 0.35), false, 2.0, true)
	var scan_x: float = lerpf(-25.0, 25.0, progress)
	draw_line(center + Vector2(scan_x, -28.0), center + Vector2(scan_x, 28.0), Color(color, 0.65), 2.0, true)


func _draw_control(center: Vector2, color: Color) -> void:
	draw_circle(center, 13.0 + 5.0 * sin(progress * PI), Color(color, 0.35))
	for index: int in range(4):
		var angle: float = -PI * 0.55 + float(index) * PI * 0.36
		var destination := center + Vector2.from_angle(angle) * 43.0
		draw_line(center, destination, Color(color, 0.35), 2.5, true)
		draw_circle(center.lerp(destination, clampf((progress - 0.2) / 0.8, 0.0, 1.0)), 5.5, color)


func _draw_decoder(center: Vector2, color: Color) -> void:
	var entry := center + Vector2(-42.0, 0.0)
	draw_line(entry, center, Color(color, 0.5), 3.0, true)
	draw_circle(entry.lerp(center, minf(progress * 1.7, 1.0)), 6.0, color)
	for y: float in [-18.0, 18.0]:
		var destination := center + Vector2(43.0, y)
		draw_line(center, destination, Color(color, 0.42), 3.0, true)
		draw_circle(center.lerp(destination, clampf((progress - 0.48) / 0.52, 0.0, 1.0)), 6.0, color)


func _draw_computer(center: Vector2, color: Color) -> void:
	var cpu := center + Vector2(-27.0, 0.0)
	var memory := center + Vector2(27.0, 0.0)
	draw_circle(cpu, 19.0, Color(color, 0.11))
	draw_circle(cpu, 19.0, color, false, 3.0, true)
	draw_rect(Rect2(memory - Vector2(16.0, 19.0), Vector2(32.0, 38.0)), Color(color, 0.1), true)
	draw_rect(Rect2(memory - Vector2(16.0, 19.0), Vector2(32.0, 38.0)), color, false, 3.0, true)
	var forward: bool = progress < 0.5
	var local_progress: float = progress * 2.0 if forward else (progress - 0.5) * 2.0
	var start: Vector2 = cpu if forward else memory
	var finish: Vector2 = memory if forward else cpu
	draw_line(cpu, memory, Color(color, 0.4), 4.0, true)
	draw_circle(start.lerp(finish, local_progress), 7.0, color)


func _draw_input(center: Vector2, color: Color) -> void:
	var radius: float = 10.0 + 22.0 * progress
	draw_circle(center, radius, Color(color, 0.32 * (1.0 - progress)), false, 4.0, true)
	draw_circle(center + Vector2(32.0 * progress, 0.0), 8.0, color)
	_draw_binary(center, str(int(signal_value)), color)


func _draw_observer(center: Vector2, color: Color) -> void:
	var pulse: float = sin(progress * PI)
	draw_circle(center, 14.0 + pulse * 10.0, Color(color, 0.18 + pulse * 0.2))
	draw_circle(center, 12.0, color)
	for index: int in range(8):
		var direction := Vector2.from_angle(float(index) * TAU / 8.0)
		draw_line(center + direction * 18.0, center + direction * (25.0 + pulse * 7.0), Color(color, 0.75), 2.5, true)
	_draw_binary(center, str(int(signal_value)), Color("101725"))


func _input_color(_index: int) -> Color:
	return PROCESS_COLOR


func _draw_binary(center: Vector2, text: String, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, center + Vector2(-4.5, 5.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, color)


func _draw_badge(position: Vector2, text: String, color: Color) -> void:
	if text.is_empty():
		return
	var width: float = maxf(52.0, minf(230.0, float(text.length()) * 8.2 + 20.0))
	draw_rect(Rect2(position, Vector2(width, 25.0)), Color("101725"), true)
	draw_rect(Rect2(position, Vector2(width, 25.0)), Color(color, 0.75), false, 1.5, true)
	draw_string(ThemeDB.fallback_font, position + Vector2(8.0, 18.0), text, HORIZONTAL_ALIGNMENT_LEFT, width - 16.0, 13, color)


func _point_on_path(points: PackedVector2Array, p_progress: float) -> Vector2:
	var total_length: float = 0.0
	for index: int in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	if total_length <= 0.001:
		return points[0]
	var target: float = clampf(p_progress, 0.0, 1.0) * total_length
	var travelled: float = 0.0
	for index: int in range(points.size() - 1):
		var segment: float = points[index].distance_to(points[index + 1])
		if target <= travelled + segment:
			return points[index].lerp(points[index + 1], (target - travelled) / segment if segment > 0.001 else 0.0)
		travelled += segment
	return points[points.size() - 1]
