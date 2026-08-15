class_name TraceOverlay
extends Control

var active: bool = false
var path_points: PackedVector2Array = PackedVector2Array()
var packet_progress: float = 0.0
var packet_color: Color = Color.WHITE
var caption: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_packet(from_point: Vector2, to_point: Vector2, progress: float, color: Color, text: String) -> void:
	show_packet_path(PackedVector2Array([from_point, to_point]), progress, color, text)


func show_packet_path(points: PackedVector2Array, progress: float, color: Color, text: String) -> void:
	active = true
	path_points = points
	packet_progress = clampf(progress, 0.0, 1.0)
	packet_color = color
	caption = text
	queue_redraw()


func clear_packet() -> void:
	active = false
	caption = ""
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	if path_points.is_empty():
		return
	var eased_progress: float = smoothstep(0.0, 1.0, packet_progress)
	var current: Vector2 = _point_on_path(eased_progress)
	if path_points.size() > 1:
		draw_polyline(path_points, Color(packet_color, 0.24), 5.0, true)
		for tail_index: int in range(1, 4):
			var tail_progress: float = maxf(0.0, eased_progress - float(tail_index) * 0.055)
			var tail_point: Vector2 = _point_on_path(tail_progress)
			draw_circle(tail_point, 5.5 - float(tail_index), Color(packet_color, 0.24 / float(tail_index)))
	var pulse: float = 1.0 + sin(packet_progress * PI) * 0.35
	draw_circle(current, 13.0 * pulse, Color(packet_color, 0.16))
	draw_circle(current, 7.0, packet_color)
	if not caption.is_empty():
		var font: Font = ThemeDB.fallback_font
		var label_position: Vector2 = current + Vector2(16.0, -14.0)
		var label_width: float = maxf(42.0, float(caption.length()) * 8.2)
		draw_rect(Rect2(label_position + Vector2(-5.0, -16.0), Vector2(label_width + 10.0, 22.0)), Color(0.035, 0.047, 0.071, 0.88), true)
		draw_string(font, label_position, caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.94, 0.97, 1.0))


func _point_on_path(progress: float) -> Vector2:
	if path_points.size() == 1:
		return path_points[0]
	var total_length: float = 0.0
	for index: int in range(path_points.size() - 1):
		total_length += path_points[index].distance_to(path_points[index + 1])
	if total_length <= 0.001:
		return path_points[0]
	var target_distance: float = clampf(progress, 0.0, 1.0) * total_length
	var traversed: float = 0.0
	for index: int in range(path_points.size() - 1):
		var segment_length: float = path_points[index].distance_to(path_points[index + 1])
		if target_distance <= traversed + segment_length:
			var local_progress: float = (target_distance - traversed) / segment_length if segment_length > 0.001 else 0.0
			return path_points[index].lerp(path_points[index + 1], local_progress)
		traversed += segment_length
	return path_points[path_points.size() - 1]
