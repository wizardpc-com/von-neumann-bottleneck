class_name SystemGraphEdit
extends GraphEdit

const WirePaletteType = preload("res://src/ui/wire_palette.gd")

const WIRE_THICKNESS: float = 6.0
const HOVER_RADIUS: float = 12.0

var connection_color_indices: Dictionary = {}
var hovered_connection: Dictionary = {}
var settled_wire_thickness: float = WIRE_THICKNESS
var draft_connection_source: Dictionary = {}
var draft_pointer: Vector2 = Vector2.ZERO
var draft_color_index: int = WirePaletteType.DEFAULT_INDEX
var displayed_scroll_offset: Vector2 = Vector2(INF, INF)
var displayed_zoom: float = -1.0
var displayed_node_transforms: Dictionary[StringName, Transform2D] = {}


func _ready() -> void:
	mouse_exited.connect(_clear_hovered_connection)
	set_process(true)


func _process(_delta: float) -> void:
	var geometry_changed: bool = (
		not displayed_scroll_offset.is_equal_approx(scroll_offset)
		or not is_equal_approx(displayed_zoom, zoom)
	)
	var current_transforms: Dictionary[StringName, Transform2D] = {}
	for child: Node in get_children():
		if not child is GraphNode or not (child as GraphNode).visible:
			continue
		var node := child as GraphNode
		var node_transform: Transform2D = node.get_transform()
		current_transforms[node.name] = node_transform
		if not displayed_node_transforms.has(node.name) \
				or not displayed_node_transforms[node.name].is_equal_approx(node_transform):
			geometry_changed = true
	if current_transforms.size() != displayed_node_transforms.size():
		geometry_changed = true
	if not geometry_changed:
		return
	displayed_scroll_offset = scroll_offset
	displayed_zoom = zoom
	displayed_node_transforms = current_transforms
	queue_redraw()


func displayed_port_position(node: GraphNode, port: int, is_output: bool) -> Vector2:
	var local_position: Vector2 = (
		node.get_output_port_position(port) if is_output
		else node.get_input_port_position(port)
	)
	return node.get_transform() * local_position


func displayed_node_rect(node: GraphNode) -> Rect2:
	var transform: Transform2D = node.get_transform()
	var top_left: Vector2 = transform * Vector2.ZERO
	var bottom_right: Vector2 = transform * node.size
	return Rect2(top_left, bottom_right - top_left).abs()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		draft_pointer = (event as InputEventMouseMotion).position
		_update_hovered_connection(draft_pointer)
		if not draft_connection_source.is_empty():
			queue_redraw()


func _draw() -> void:
	for connection: Dictionary in get_connection_list():
		var curve: PackedVector2Array = connection_curve(connection)
		if curve.size() < 2:
			continue
		var color: Color = WirePaletteType.color(get_connection_color_index(
			StringName(connection.get("from_node", &"")), int(connection.get("from_port", 0)),
			StringName(connection.get("to_node", &"")), int(connection.get("to_port", 0))
		))
		draw_polyline(curve, Color("07101c", 0.92), WIRE_THICKNESS + 3.0, true)
		draw_polyline(curve, Color(color, 0.82), WIRE_THICKNESS, true)
	if not hovered_connection.is_empty():
		var hover_curve: PackedVector2Array = connection_curve(hovered_connection)
		if hover_curve.size() >= 2:
			draw_polyline(hover_curve, Color("50d5ff", 0.18), WIRE_THICKNESS + 9.0, true)
			draw_polyline(hover_curve, Color("50d5ff", 0.88), 2.0, true)
	if not draft_connection_source.is_empty():
		_draw_connection_preview()


func begin_connection_preview(from_node: StringName, from_port: int, is_output: bool) -> void:
	draft_connection_source = {
		"node": from_node,
		"port": from_port,
		"is_output": is_output,
	}
	var source: GraphNode = get_node_or_null(NodePath(String(from_node))) as GraphNode
	if source != null:
		draft_pointer = displayed_port_position(source, from_port, is_output)
	queue_redraw()


func end_connection_preview() -> void:
	draft_connection_source.clear()
	queue_redraw()


func set_draft_color_index(color_index: int) -> void:
	draft_color_index = WirePaletteType.normalized_index(color_index)
	queue_redraw()


func _draw_connection_preview() -> void:
	var source: GraphNode = get_node_or_null(NodePath(String(
		draft_connection_source.get("node", "")
	))) as GraphNode
	if source == null:
		return
	var port: int = int(draft_connection_source.get("port", 0))
	var is_output: bool = bool(draft_connection_source.get("is_output", true))
	var origin: Vector2 = displayed_port_position(source, port, is_output)
	var curve: PackedVector2Array = get_connection_line(origin, draft_pointer)
	var color: Color = WirePaletteType.color(draft_color_index)
	draw_polyline(curve, Color(color, 0.20), WIRE_THICKNESS + 7.0, true)
	draw_polyline(curve, color.lightened(0.24), WIRE_THICKNESS, true)


func set_connection_color_index(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int,
		color_index: int
	) -> void:
	connection_color_indices[_connection_key(from_node, from_port, to_node, to_port)] = \
		WirePaletteType.normalized_index(color_index)
	queue_redraw()


func get_connection_color_index(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
	) -> int:
	return WirePaletteType.normalized_index(connection_color_indices.get(
		_connection_key(from_node, from_port, to_node, to_port),
		WirePaletteType.DEFAULT_INDEX
	))


func remove_connection_presentation(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
	) -> void:
	connection_color_indices.erase(_connection_key(from_node, from_port, to_node, to_port))
	queue_redraw()


func clear_connection_presentations() -> void:
	connection_color_indices.clear()
	hovered_connection.clear()
	queue_redraw()


func hovered_connection_snapshot() -> Dictionary:
	return hovered_connection.duplicate()


func connection_curve(connection: Dictionary) -> PackedVector2Array:
	var source: GraphNode = get_node_or_null(NodePath(String(connection.get("from_node", "")))) as GraphNode
	var target: GraphNode = get_node_or_null(NodePath(String(connection.get("to_node", "")))) as GraphNode
	if source == null or target == null:
		return PackedVector2Array()
	var start: Vector2 = displayed_port_position(source, int(connection.get("from_port", 0)), true)
	var finish: Vector2 = displayed_port_position(target, int(connection.get("to_port", 0)), false)
	if finish.x < start.x:
		# GraphNode inputs live on the left and outputs on the right. Reverse-flow
		# lanes therefore need an explicit route around the devices instead of a
		# direct curve that cuts through their procedural surfaces.
		var source_bottom: float = displayed_node_rect(source).end.y
		var target_bottom: float = displayed_node_rect(target).end.y
		var lane_offset: float = 36.0 + float(int(connection.get("from_port", 0))) * 18.0
		var detour_y: float = maxf(source_bottom, target_bottom) + lane_offset
		var source_clear_x: float = start.x + 34.0
		var target_clear_x: float = finish.x - 34.0
		return PackedVector2Array([
			start,
			Vector2(source_clear_x, start.y),
			Vector2(source_clear_x, detour_y),
			Vector2(target_clear_x, detour_y),
			Vector2(target_clear_x, finish.y),
			finish,
		])
	return get_connection_line(start, finish)


func _update_hovered_connection(point: Vector2) -> void:
	var closest: Dictionary = {}
	var closest_distance: float = HOVER_RADIUS
	for connection: Dictionary in get_connection_list():
		var curve: PackedVector2Array = connection_curve(connection)
		for index: int in range(curve.size() - 1):
			var distance: float = _distance_to_segment(point, curve[index], curve[index + 1])
			if distance <= closest_distance:
				closest_distance = distance
				closest = connection.duplicate()
	if closest == hovered_connection:
		return
	hovered_connection = closest.duplicate()
	queue_redraw()


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment: Vector2 = finish - start
	var length_squared: float = segment.length_squared()
	if is_zero_approx(length_squared):
		return point.distance_to(start)
	var ratio: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)


func _clear_hovered_connection() -> void:
	if hovered_connection.is_empty():
		return
	hovered_connection.clear()
	queue_redraw()


func _connection_key(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> String:
	return "%s:%d>%s:%d" % [from_node, from_port, to_node, to_port]
