class_name CircuitTraceOverlay
extends Control

var mode: StringName = &""
var progress: float = 0.0
var signal_value: bool = false
var path: PackedVector2Array = PackedVector2Array()
var value_text: String = ""
var player_color: Color = Color("50d5ff")
var wire_pulses: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_wire(p_path: PackedVector2Array, p_progress: float, value: bool) -> void:
	mode = &"wire"
	wire_pulses = [{"path": p_path, "progress": p_progress, "value": value}]
	path = p_path
	progress = smoothstep(0.0, 1.0, clampf(p_progress, 0.0, 1.0))
	signal_value = value
	value_text = str(int(value))
	queue_redraw()


func show_parallel(p_wire_pulses: Array[Dictionary]) -> void:
	mode = &"parallel" if not p_wire_pulses.is_empty() else &""
	wire_pulses = p_wire_pulses.duplicate(true)
	if not wire_pulses.is_empty():
		path = wire_pulses[0].get("path", PackedVector2Array())
	else:
		path = PackedVector2Array()
	queue_redraw()


func clear_event() -> void:
	mode = &""
	wire_pulses.clear()
	path = PackedVector2Array()
	value_text = ""
	queue_redraw()


func _draw() -> void:
	if mode == &"parallel":
		for wire_pulse: Dictionary in wire_pulses:
			path = wire_pulse.get("path", PackedVector2Array())
			progress = smoothstep(0.0, 1.0, clampf(float(wire_pulse.get("progress", 0.0)), 0.0, 1.0))
			signal_value = bool(wire_pulse.get("value", false))
			value_text = String(wire_pulse.get("display", str(int(signal_value))))
			player_color = wire_pulse.get("color", Color("50d5ff"))
			_draw_wire_signal()
	elif mode == &"wire":
		_draw_wire_signal()


func _draw_wire_signal() -> void:
	if path.size() < 2:
		return
	# One-bit flow is carried by the cable's growing state stroke. Wider values
	# get one readable badge; no point/capsule competes with the cable color.
	if value_text.length() <= 1:
		return
	var color: Color = player_color.lightened(0.34)
	var current: Vector2 = _point_on_path(path, progress)
	_draw_badge(current + Vector2(10.0, -25.0), value_text, color)


func _draw_badge(position: Vector2, text: String, color: Color) -> void:
	if text.is_empty():
		return
	var width: float = maxf(42.0, minf(170.0, float(text.length()) * 7.6 + 16.0))
	draw_rect(Rect2(position, Vector2(width, 22.0)), Color("101725"), true)
	draw_rect(Rect2(position, Vector2(width, 22.0)), Color(color, 0.72), false, 1.25, true)
	draw_string(ThemeDB.fallback_font, position + Vector2(7.0, 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, width - 14.0, 12, color)


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
