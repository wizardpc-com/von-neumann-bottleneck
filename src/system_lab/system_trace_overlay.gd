class_name SystemTraceOverlay
extends Control

var active: bool = false
var path: PackedVector2Array = PackedVector2Array()
var paths: Array = []
var progress: float = 0.0
var packet_color: Color = Color.WHITE
var caption: String = ""
var segment_count: int = 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_transfer(
		p_path: PackedVector2Array,
		p_progress: float,
		p_color: Color,
		p_caption: String,
		p_segment_count: int = 1
	) -> void:
	show_transfer_segments([p_path], p_progress, p_color, p_caption, p_segment_count)


func show_transfer_segments(
		p_paths: Array,
		p_progress: float,
		p_color: Color,
		p_caption: String,
		p_segment_count: int = 1
	) -> void:
	paths.clear()
	path = PackedVector2Array()
	for path_variant: Variant in p_paths:
		if not path_variant is PackedVector2Array or (path_variant as PackedVector2Array).size() < 2:
			continue
		var segment: PackedVector2Array = path_variant
		paths.append(segment)
		for point: Vector2 in segment:
			path.append(point)
	active = not paths.is_empty()
	progress = smoothstep(0.0, 1.0, clampf(p_progress, 0.0, 1.0))
	packet_color = p_color
	caption = p_caption
	segment_count = maxi(1, p_segment_count)
	queue_redraw()


func clear_event() -> void:
	active = false
	path = PackedVector2Array()
	paths.clear()
	caption = ""
	queue_redraw()


func _draw() -> void:
	if not active or paths.is_empty():
		return
	var flow: Dictionary = _flow_prefixes(progress)
	var current: Vector2 = flow.get("point", Vector2.ZERO)
	for prefix_variant: Variant in flow.get("prefixes", []):
		var prefix: PackedVector2Array = prefix_variant
		if prefix.size() < 2:
			continue
		draw_polyline(prefix, Color(packet_color.lightened(0.28), 0.22), 11.0, true)
		draw_polyline(prefix, packet_color.lightened(0.34), 4.0, true)
	if not caption.is_empty():
		var label: String = caption
		if segment_count > 1:
			var segment_index: int = mini(segment_count, int(floor(progress * float(segment_count))) + 1)
			label += "  %d/%d" % [segment_index, segment_count]
		var label_position := current + Vector2(12.0, -16.0)
		var width: float = maxf(68.0, float(label.length()) * 8.0)
		draw_rect(Rect2(label_position - Vector2(5.0, 16.0), Vector2(width + 10.0, 23.0)), Color("09101d", 0.94), true)
		draw_string(ThemeDB.fallback_font, label_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("eef6ff"))


func _flow_prefixes(amount: float) -> Dictionary:
	var total: float = 0.0
	for segment_variant: Variant in paths:
		total += _path_length(segment_variant)
	var target: float = clampf(amount, 0.0, 1.0) * total
	var prefixes: Array = []
	var point: Vector2 = (paths[0] as PackedVector2Array)[0]
	for segment_variant: Variant in paths:
		var segment: PackedVector2Array = segment_variant
		var length: float = _path_length(segment)
		if target >= length:
			prefixes.append(segment)
			point = segment[segment.size() - 1]
			target -= length
			continue
		var local_amount: float = target / maxf(length, 0.001)
		var prefix: PackedVector2Array = _path_prefix(segment, local_amount)
		prefixes.append(prefix)
		if not prefix.is_empty():
			point = prefix[prefix.size() - 1]
		break
	return {"prefixes": prefixes, "point": point}


func _path_length(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in range(points.size() - 1):
		total += points[index].distance_to(points[index + 1])
	return total


func _path_prefix(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.size() < 2:
		return result
	result.append(points[0])
	var total: float = 0.0
	for index: int in range(points.size() - 1):
		total += points[index].distance_to(points[index + 1])
	if total <= 0.001:
		return result
	var target: float = clampf(amount, 0.0, 1.0) * total
	var travelled: float = 0.0
	for index: int in range(points.size() - 1):
		var length: float = points[index].distance_to(points[index + 1])
		if travelled + length >= target:
			result.append(points[index].lerp(
				points[index + 1], (target - travelled) / maxf(length, 0.001)
			))
			return result
		result.append(points[index + 1])
		travelled += length
	return result


func _point_on_path(points: PackedVector2Array, amount: float) -> Vector2:
	var lengths: PackedFloat32Array = PackedFloat32Array()
	var total: float = 0.0
	for index: int in range(points.size() - 1):
		var length: float = points[index].distance_to(points[index + 1])
		lengths.append(length)
		total += length
	if total <= 0.0:
		return points[0]
	var target: float = clampf(amount, 0.0, 1.0) * total
	for index: int in range(lengths.size()):
		if target <= lengths[index] or index == lengths.size() - 1:
			var local: float = target / maxf(lengths[index], 0.0001)
			return points[index].lerp(points[index + 1], local)
		target -= lengths[index]
	return points[points.size() - 1]


func _path_direction(points: PackedVector2Array, amount: float) -> Vector2:
	var before: Vector2 = _point_on_path(points, maxf(0.0, amount - 0.005))
	var after: Vector2 = _point_on_path(points, minf(1.0, amount + 0.005))
	var direction: Vector2 = after - before
	return direction.normalized() if direction.length_squared() > 0.0001 else Vector2.RIGHT
