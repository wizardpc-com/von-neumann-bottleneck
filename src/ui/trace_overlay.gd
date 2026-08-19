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
		# The displayed device itself provides the processing feedback. Keeping the
		# packet unlabelled here avoids drawing a second, unrelated device model.
		label = ""
	_draw_packet(primary_path, packet_progress, packet_color, label)


func _draw_packet(
		points: PackedVector2Array,
		progress: float,
		color: Color,
		text: String
	) -> void:
	var visible_tail := PackedVector2Array()
	var tail_start: float = maxf(0.0, progress - 0.085)
	for sample: int in range(16):
		visible_tail.append(_point_on_path(points, lerpf(tail_start, progress, float(sample) / 15.0)))
	draw_polyline(visible_tail, Color(color, 0.15), 8.0, true)
	draw_polyline(visible_tail, Color(color, 0.86), 2.75, true)
	var current: Vector2 = _point_on_path(points, progress)
	draw_circle(current, 9.0, Color(color, 0.14))
	draw_circle(current, 5.5, color)
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
