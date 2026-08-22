class_name SystemGraphEdit
extends GraphEdit

const WirePaletteType = preload("res://src/ui/wire_palette.gd")

const WIRE_THICKNESS: float = 6.0
const HOVER_RADIUS: float = 12.0
const ERASER_COLOR := Color("ff6b7d")
const ERASER_TIP_RADIUS: float = 2.0
const ERASER_SAMPLE_SPACING: float = 4.0
const SELECTION_DRAG_THRESHOLD: float = 4.0

signal erase_stroke_started()
signal erase_component_requested(component_id: StringName)
signal erase_wire_requested(connection: Dictionary)
signal erase_stroke_finished()
signal selection_rectangle_applied(changed_count: int, selected_count: int)

var connection_color_indices: Dictionary = {}
var hovered_connection: Dictionary = {}
var settled_wire_thickness: float = WIRE_THICKNESS
var draft_connection_source: Dictionary = {}
var draft_pointer: Vector2 = Vector2.ZERO
var draft_color_index: int = WirePaletteType.DEFAULT_INDEX
var displayed_scroll_offset: Vector2 = Vector2(INF, INF)
var displayed_zoom: float = -1.0
var displayed_node_transforms: Dictionary[StringName, Transform2D] = {}
var erase_active: bool = false
var erase_pointer: Vector2 = Vector2.ZERO
var erase_last_position: Vector2 = Vector2.ZERO
var erase_has_anchor: bool = false
var erase_component_ids: Dictionary[StringName, bool] = {}
var erase_wire_keys: Dictionary[String, bool] = {}
var selection_dragging: bool = false
var selection_start: Vector2 = Vector2.ZERO
var selection_pointer: Vector2 = Vector2.ZERO
var selection_toggle_mode: bool = false


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


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseMotion and erase_active:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) == 0:
			finish_erase_stroke()
		elif _is_graph_hover_target(motion.position):
			continue_erase_stroke(_local_from_global(motion.position))
		else:
			erase_has_anchor = false
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return
	if mouse_event.pressed:
		if _is_graph_hover_target(mouse_event.position):
			begin_erase_stroke(_local_from_global(mouse_event.position))
			get_viewport().set_input_as_handled()
	elif erase_active:
		finish_erase_stroke()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_selection_drag()
		accept_event()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				begin_erase_stroke(mouse_event.position)
			elif erase_active:
				finish_erase_stroke()
			accept_event()
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			if _point_hits_port(mouse_event.position, 28.0) \
					or not _node_at(mouse_event.position).is_empty() \
					or not _connection_at(mouse_event.position, HOVER_RADIUS).is_empty():
				return
			selection_dragging = true
			selection_toggle_mode = mouse_event.shift_pressed
			selection_start = mouse_event.position
			selection_pointer = mouse_event.position
			accept_event()
			queue_redraw()
			return
		if selection_dragging:
			selection_pointer = mouse_event.position
			_apply_selection_rectangle()
			selection_dragging = false
			accept_event()
			queue_redraw()
			return
	if not event is InputEventMouseMotion:
		return
	var motion := event as InputEventMouseMotion
	draft_pointer = motion.position
	if erase_active:
		if (motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) == 0:
			finish_erase_stroke()
		else:
			continue_erase_stroke(motion.position)
		accept_event()
		return
	if selection_dragging:
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			cancel_selection_drag()
			return
		selection_pointer = motion.position
		queue_redraw()
		accept_event()
		return
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
	if selection_dragging:
		var selection_rect: Rect2 = _selection_rectangle()
		draw_rect(selection_rect, Color("50d5ff", 0.12), true)
		draw_rect(selection_rect, Color("50d5ff", 0.9), false, 2.0, true)
	if erase_active:
		draw_circle(erase_pointer, ERASER_TIP_RADIUS, Color(ERASER_COLOR, 0.95))


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
	var closest: Dictionary = _connection_at(point, HOVER_RADIUS)
	if closest == hovered_connection:
		return
	hovered_connection = closest.duplicate()
	queue_redraw()


func _connection_at(point: Vector2, radius: float) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance: float = radius
	for connection: Dictionary in get_connection_list():
		var curve: PackedVector2Array = connection_curve(connection)
		for index: int in range(curve.size() - 1):
			var distance: float = _distance_to_segment(point, curve[index], curve[index + 1])
			if distance <= closest_distance:
				closest_distance = distance
				closest = connection.duplicate()
	return closest


func _connections_at(point: Vector2, radius: float) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for connection: Dictionary in get_connection_list():
		var curve: PackedVector2Array = connection_curve(connection)
		for index: int in range(curve.size() - 1):
			if _distance_to_segment(point, curve[index], curve[index + 1]) <= radius:
				hits.append(connection.duplicate())
				break
	return hits


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


func cancel_selection_drag() -> void:
	if not selection_dragging:
		return
	selection_dragging = false
	selection_toggle_mode = false
	queue_redraw()


func _selection_rectangle() -> Rect2:
	var top_left := Vector2(
		minf(selection_start.x, selection_pointer.x),
		minf(selection_start.y, selection_pointer.y)
	)
	var bottom_right := Vector2(
		maxf(selection_start.x, selection_pointer.x),
		maxf(selection_start.y, selection_pointer.y)
	)
	return Rect2(top_left, bottom_right - top_left)


func _apply_selection_rectangle() -> void:
	var selection_rect: Rect2 = _selection_rectangle()
	var is_click: bool = selection_rect.size.length() < SELECTION_DRAG_THRESHOLD
	var changed_count: int = 0
	var selected_count: int = 0
	for child: Node in get_children():
		if not child is GraphNode or not (child as GraphNode).visible:
			continue
		var node := child as GraphNode
		var inside: bool = not is_click and selection_rect.intersects(displayed_node_rect(node), true)
		var next_selected: bool = node.selected
		if selection_toggle_mode:
			if inside:
				next_selected = not node.selected
		else:
			next_selected = inside
		if next_selected != node.selected:
			node.selected = next_selected
			changed_count += 1
		if node.selected:
			selected_count += 1
	selection_toggle_mode = false
	selection_rectangle_applied.emit(changed_count, selected_count)


func begin_erase_stroke(position: Vector2) -> void:
	if not erase_active:
		erase_active = true
		erase_component_ids.clear()
		erase_wire_keys.clear()
		erase_stroke_started.emit()
	erase_pointer = position
	erase_last_position = position
	erase_has_anchor = true
	_erase_at_point(position)
	queue_redraw()


func continue_erase_stroke(position: Vector2) -> void:
	if not erase_active:
		return
	erase_pointer = position
	if not erase_has_anchor:
		erase_last_position = position
		erase_has_anchor = true
		_erase_at_point(position)
		queue_redraw()
		return
	var distance: float = erase_last_position.distance_to(position)
	var steps: int = maxi(1, int(ceilf(distance / ERASER_SAMPLE_SPACING)))
	for step: int in range(1, steps + 1):
		_erase_at_point(erase_last_position.lerp(position, float(step) / float(steps)))
	erase_last_position = position
	queue_redraw()


func finish_erase_stroke() -> void:
	if not erase_active:
		return
	erase_active = false
	erase_has_anchor = false
	erase_component_ids.clear()
	erase_wire_keys.clear()
	erase_stroke_finished.emit()
	queue_redraw()


func _erase_at_point(point: Vector2) -> void:
	var component_id: StringName = _node_at(point)
	if not component_id.is_empty() and not erase_component_ids.has(component_id):
		erase_component_ids[component_id] = true
		erase_component_requested.emit(component_id)
	var wire_radius: float = WIRE_THICKNESS * 0.5 + ERASER_TIP_RADIUS
	for connection: Dictionary in _connections_at(point, wire_radius):
		var key: String = _connection_key(
			StringName(connection.get("from_node", &"")), int(connection.get("from_port", -1)),
			StringName(connection.get("to_node", &"")), int(connection.get("to_port", -1))
		)
		if erase_wire_keys.has(key):
			continue
		erase_wire_keys[key] = true
		erase_wire_requested.emit(connection.duplicate())


func _node_at(point: Vector2) -> StringName:
	var children: Array[Node] = get_children()
	children.reverse()
	for child: Node in children:
		if child is GraphNode and (child as GraphNode).visible \
				and displayed_node_rect(child as GraphNode).has_point(point):
			return (child as GraphNode).name
	return &""


func _point_hits_port(point: Vector2, radius: float) -> bool:
	for child: Node in get_children():
		if not child is GraphNode or not (child as GraphNode).visible:
			continue
		var node := child as GraphNode
		for port: int in range(node.get_input_port_count()):
			if point.distance_to(displayed_port_position(node, port, false)) <= radius:
				return true
		for port: int in range(node.get_output_port_count()):
			if point.distance_to(displayed_port_position(node, port, true)) <= radius:
				return true
	return false


func _is_graph_hover_target(global_position: Vector2) -> bool:
	if not get_global_rect().has_point(global_position):
		return false
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return true
	var current: Node = hovered
	while current != null:
		if current == self:
			return true
		current = current.get_parent()
	return false


func _local_from_global(global_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_position


func _connection_key(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> String:
	return "%s:%d>%s:%d" % [from_node, from_port, to_node, to_port]
