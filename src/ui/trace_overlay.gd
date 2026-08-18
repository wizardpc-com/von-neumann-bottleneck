class_name TraceOverlay
extends Control

var active: bool = false
var primary_path: PackedVector2Array = PackedVector2Array()
var processing_ranges: Array[Dictionary] = []
var packet_progress: float = 0.0
var packet_color: Color = Color.WHITE
var caption: String = ""
var active_processing_device: StringName = &""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_event(
		path: PackedVector2Array,
		component_ranges: Array[Dictionary],
		progress: float,
		color: Color,
		text: String
	) -> void:
	active = true
	primary_path = path
	processing_ranges = component_ranges
	packet_progress = smoothstep(0.0, 1.0, clampf(progress, 0.0, 1.0))
	packet_color = color
	caption = text
	active_processing_device = _processing_device_at(packet_progress)
	queue_redraw()


func clear_event() -> void:
	active = false
	primary_path = PackedVector2Array()
	processing_ranges = []
	active_processing_device = &""
	caption = ""
	queue_redraw()


func _draw() -> void:
	if not active or primary_path.size() < 2:
		return
	var process_range: Dictionary = _processing_range_at(packet_progress)
	var label: String = caption
	if not process_range.is_empty():
		label = Localization.text(&"trace.overlay.process")
		_draw_processing_indicator(process_range)
	_draw_packet(primary_path, packet_progress, packet_color, label)


func _draw_processing_indicator(process_range: Dictionary) -> void:
	var center: Vector2 = process_range.get("center", Vector2.ZERO)
	var start: float = float(process_range.get("start", 0.0))
	var finish: float = float(process_range.get("end", 1.0))
	var local_progress: float = inverse_lerp(start, finish, packet_progress) if finish > start else 0.0
	var rotation: float = local_progress * TAU * 2.0
	draw_circle(center, 27.0, Color(packet_color, 0.10))
	draw_arc(center, 24.0, rotation, rotation + PI * 1.35, 28, Color(packet_color, 0.95), 4.0, true)
	draw_arc(center, 16.0, -rotation, -rotation + PI, 24, Color(packet_color, 0.55), 3.0, true)
	for index: int in range(3):
		var angle: float = rotation + float(index) * TAU / 3.0
		draw_circle(center + Vector2(cos(angle), sin(angle)) * 24.0, 3.5, packet_color)


func _draw_packet(
		points: PackedVector2Array,
		progress: float,
		color: Color,
		text: String
	) -> void:
	var visible_tail := PackedVector2Array()
	var tail_start: float = maxf(0.0, progress - 0.095)
	for sample: int in range(19):
		visible_tail.append(_point_on_path(points, lerpf(tail_start, progress, float(sample) / 18.0)))
	draw_polyline(visible_tail, Color(color, 0.18), 10.0, true)
	draw_polyline(visible_tail, Color(color, 0.78), 3.0, true)
	var current: Vector2 = _point_on_path(points, progress)
	for tail_index: int in range(1, 6):
		var tail_progress: float = maxf(0.0, progress - float(tail_index) * 0.026)
		var tail_point: Vector2 = _point_on_path(points, tail_progress)
		draw_circle(tail_point, 7.0 - float(tail_index), Color(color, 0.25 / float(tail_index)))
	var pulse: float = 1.0 + sin(progress * PI) * 0.4
	draw_circle(current, 14.0 * pulse, Color(color, 0.18))
	draw_circle(current, 7.0, color)
	if not text.is_empty():
		var font: Font = ThemeDB.fallback_font
		var label_position: Vector2 = current + Vector2(16.0, -14.0)
		var label_width: float = maxf(58.0, float(text.length()) * 8.2)
		draw_rect(
			Rect2(label_position + Vector2(-5.0, -16.0), Vector2(label_width + 10.0, 22.0)),
			Color(0.035, 0.047, 0.071, 0.94), true
		)
		draw_string(font, label_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.94, 0.97, 1.0))


func _processing_device_at(progress: float) -> StringName:
	var process_range: Dictionary = _processing_range_at(progress)
	return StringName(process_range.get("device", &""))


func _processing_range_at(progress: float) -> Dictionary:
	for process_range: Dictionary in processing_ranges:
		if progress >= float(process_range.get("start", 0.0)) and progress <= float(process_range.get("end", 0.0)):
			return process_range
	return {}


func _point_on_path(points: PackedVector2Array, progress: float) -> Vector2:
	if points.size() == 1:
		return points[0]
	var total_length: float = 0.0
	for index: int in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	if total_length <= 0.001:
		return points[0]
	var target_distance: float = clampf(progress, 0.0, 1.0) * total_length
	var traversed: float = 0.0
	for index: int in range(points.size() - 1):
		var segment_length: float = points[index].distance_to(points[index + 1])
		if target_distance <= traversed + segment_length:
			var local_progress: float = (target_distance - traversed) / segment_length if segment_length > 0.001 else 0.0
			return points[index].lerp(points[index + 1], local_progress)
		traversed += segment_length
	return points[points.size() - 1]
