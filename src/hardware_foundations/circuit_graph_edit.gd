class_name CircuitGraphEdit
extends GraphEdit

const LogicSignalType = preload("res://src/circuit/logic_signal.gd")
const WirePaletteType = preload("res://src/ui/wire_palette.gd")

const SIGNAL_HIGH := Color("67e8a5")
const SIGNAL_LOW := Color("ff6b7d")
const ERASER_COLOR := Color("ff6b7d")
const ERASER_TIP_RADIUS: float = 2.0
const ERASER_SAMPLE_SPACING: float = 4.0
const SELECTION_DRAG_THRESHOLD: float = 4.0
const WIRE_HOVER_RADIUS: float = 13.0
const TARGET_GUIDE_RADIUS: float = 15.0
const SETTLED_WIRE_THICKNESS: float = 8.0
const FLOW_WIRE_THICKNESS: float = 4.5

signal branch_connection_requested(
	connection: Dictionary,
	split_position: Vector2,
	to_node: StringName,
	to_port: int
)
signal branch_waypoint_requested(
	connection: Dictionary,
	split_position: Vector2,
	release_position: Vector2
)
signal branch_drag_state_changed(active: bool)
signal erase_stroke_started()
signal erase_component_requested(component_id: StringName)
signal erase_wire_requested(connection: Dictionary)
signal erase_stroke_finished()
signal connection_endpoint_move_requested(
	connection: Dictionary,
	to_node: StringName,
	to_port: int
)
signal connection_endpoint_move_to_empty_requested(
	connection: Dictionary,
	release_position: Vector2
)
signal connection_endpoint_move_to_wire_requested(
	connection: Dictionary,
	target_connection: Dictionary,
	split_position: Vector2
)
signal connection_endpoint_move_state_changed(active: bool)
signal selection_rectangle_applied(changed_count: int, selected_count: int)
signal empty_canvas_pressed(position: Vector2)
signal component_drop_requested(template_key: String, local_position: Vector2)
signal component_placement_cancel_requested(reason: StringName)

var connection_validator: Callable
var settled_wire_thickness: float = SETTLED_WIRE_THICKNESS
var branch_edit_enabled: bool = true
var branch_candidate: Dictionary = {}
var branch_anchor: Vector2 = Vector2.ZERO
var branch_pointer: Vector2 = Vector2.ZERO
var branch_dragging: bool = false
var branch_target: Dictionary = {}
var endpoint_candidate: Dictionary = {}
var endpoint_anchor: Vector2 = Vector2.ZERO
var endpoint_pointer: Vector2 = Vector2.ZERO
var endpoint_target: Dictionary = {}
var connection_signal_values: Dictionary = {}
var connection_color_indices: Dictionary = {}
var connection_flows: Dictionary = {}
var draft_color_index: int = WirePaletteType.DEFAULT_INDEX
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
var hovered_connection: Dictionary = {}
var hovered_wire_point: Vector2 = Vector2.ZERO
var builtin_connection_source: Dictionary = {}
var builtin_connection_pointer: Vector2 = Vector2.ZERO
var component_placement_enabled: bool = false
var component_drop_enabled: bool = false
var placement_pointer: Vector2 = Vector2.ZERO
var placement_has_pointer: bool = false
var placement_preview_size: Vector2 = Vector2(120.0, 72.0)
var placement_preview_control: Control
var displayed_scroll_offset: Vector2 = Vector2(INF, INF)
var displayed_zoom: float = -1.0
var displayed_node_transforms: Dictionary[StringName, Transform2D] = {}


func _ready() -> void:
	# Native GraphEdit still owns topology, geometry, hit testing, and dragging.
	# Its cable stroke is hidden; this control draws that exact curve once so a
	# player's wire hue can stay independent from red/green/gray port truth.
	mouse_exited.connect(_on_graph_mouse_exited)
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


func queue_signal_wire_redraw(_value: Variant = null) -> void:
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


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		component_drop_enabled
		and branch_edit_enabled
		and data is Dictionary
		and StringName((data as Dictionary).get("type", &"")) == &"circuit_component_template"
		and not String((data as Dictionary).get("template_key", "")).is_empty()
	)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	var payload := data as Dictionary
	component_drop_requested.emit(String(payload.get("template_key", "")), at_position)


func _input(event: InputEvent) -> void:
	if not branch_edit_enabled:
		return
	if event is InputEventMouseMotion and not builtin_connection_source.is_empty():
		builtin_connection_pointer = _local_from_global((event as InputEventMouseMotion).position)
		queue_redraw()
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if component_placement_enabled and mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				component_placement_cancel_requested.emit(&"right_click")
				get_viewport().set_input_as_handled()
				return
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and _is_graph_hover_target(mouse_event.position):
				var local_position: Vector2 = _local_from_global(mouse_event.position)
				if _placement_hits_existing_content(local_position):
					# Cancellation is synchronous. Do not consume this left click: once the
					# ghost is gone, the same gesture can select, move, or wire the item.
					component_placement_cancel_requested.emit(&"canvas_content")
		if mouse_event.button_index != MOUSE_BUTTON_RIGHT:
			return
		if mouse_event.pressed:
			if _is_graph_hover_target(mouse_event.position):
				begin_erase_stroke(_local_from_global(mouse_event.position))
				get_viewport().set_input_as_handled()
		elif erase_active:
			finish_erase_stroke()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and erase_active:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) == 0:
			finish_erase_stroke()
			return
		if _is_graph_hover_target(motion.position):
			continue_erase_stroke(_local_from_global(motion.position))
		else:
			erase_has_anchor = false
		get_viewport().set_input_as_handled()


func _is_node_hover_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	if connection_validator.is_valid():
		return bool(connection_validator.call(from_node, from_port, to_node, to_port))
	return from_node != to_node


func _placement_hits_existing_content(point: Vector2) -> bool:
	return (
		not _port_at(point, 28.0).is_empty()
		or not _node_at(point).is_empty()
		or not get_closest_connection_at_point(point, WIRE_HOVER_RADIUS).is_empty()
	)


func _gui_input(event: InputEvent) -> void:
	if not branch_edit_enabled:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if selection_dragging:
			cancel_selection_drag()
			accept_event()
			return
		if not endpoint_candidate.is_empty():
			cancel_endpoint_move()
			accept_event()
			return
		if not branch_candidate.is_empty():
			cancel_branch_drag()
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
			placement_pointer = mouse_event.position
			placement_has_pointer = true
			var pressed_port: Dictionary = _port_at(mouse_event.position, 28.0)
			if mouse_event.shift_pressed and not pressed_port.is_empty() and not bool(pressed_port.get("is_output", true)):
				var existing: Dictionary = _connection_to_input(StringName(pressed_port["node"]), int(pressed_port["port"]))
				if not existing.is_empty():
					_begin_endpoint_move(existing, mouse_event.position)
					accept_event()
					return
			# Deterministic gesture priority: ports, component bodies, rendered wires,
			# component placement, then empty-canvas marquee selection.
			if not pressed_port.is_empty() or not _node_at(mouse_event.position).is_empty():
				return
			var connection: Dictionary = get_closest_connection_at_point(mouse_event.position, 16.0)
			if not connection.is_empty():
				branch_candidate = connection.duplicate()
				branch_anchor = _closest_point_on_connection(connection, mouse_event.position)
				branch_pointer = branch_anchor
				branch_target.clear()
				accept_event()
				queue_redraw()
				return
			if component_placement_enabled:
				empty_canvas_pressed.emit(mouse_event.position)
				accept_event()
				queue_redraw()
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
		if not endpoint_candidate.is_empty():
			endpoint_target = _input_port_at(
				mouse_event.position, 30.0,
				StringName(endpoint_candidate.get("from_node", &"")),
				int(endpoint_candidate.get("from_port", -1)),
				endpoint_candidate
			)
			if bool(endpoint_target.get("valid", false)):
				var same_target: bool = (
					StringName(endpoint_target["node"]) == StringName(endpoint_candidate.get("to_node", &""))
					and int(endpoint_target["port"]) == int(endpoint_candidate.get("to_port", -1))
				)
				if not same_target:
					connection_endpoint_move_requested.emit(
						endpoint_candidate.duplicate(),
						StringName(endpoint_target["node"]), int(endpoint_target["port"])
					)
			elif _port_at(mouse_event.position, 30.0).is_empty():
				var target_connection: Dictionary = get_closest_connection_at_point(mouse_event.position, 36.0)
				if not target_connection.is_empty() and not _same_connection(target_connection, endpoint_candidate):
					connection_endpoint_move_to_wire_requested.emit(
						endpoint_candidate.duplicate(), target_connection.duplicate(),
						_closest_point_on_connection(target_connection, mouse_event.position)
					)
				elif target_connection.is_empty():
					connection_endpoint_move_to_empty_requested.emit(endpoint_candidate.duplicate(), mouse_event.position)
			cancel_endpoint_move()
			accept_event()
			return
		if not branch_candidate.is_empty():
			if branch_dragging:
				branch_target = _input_port_at(
					mouse_event.position, 30.0,
					StringName(branch_candidate.get("from_node", &"")),
					int(branch_candidate.get("from_port", -1))
				)
				if bool(branch_target.get("valid", false)):
					branch_connection_requested.emit(
						branch_candidate.duplicate(), branch_anchor,
						StringName(branch_target["node"]), int(branch_target["port"])
					)
				elif _port_at(mouse_event.position, 30.0).is_empty():
					branch_waypoint_requested.emit(
						branch_candidate.duplicate(), branch_anchor, mouse_event.position
					)
			cancel_branch_drag()
			accept_event()
			return
	if event is InputEventMouseMotion:
		var pointer_motion := event as InputEventMouseMotion
		if not builtin_connection_source.is_empty():
			builtin_connection_pointer = pointer_motion.position
		if (
			not selection_dragging
			and not erase_active
			and endpoint_candidate.is_empty()
			and branch_candidate.is_empty()
			and builtin_connection_source.is_empty()
			and not component_placement_enabled
		):
			_update_hovered_connection(pointer_motion.position)
		else:
			_clear_hovered_connection()
	if event is InputEventMouseMotion and component_placement_enabled:
		placement_pointer = (event as InputEventMouseMotion).position
		placement_has_pointer = true
		queue_redraw()
	if event is InputEventMouseMotion and selection_dragging:
		var selection_motion := event as InputEventMouseMotion
		if (selection_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			cancel_selection_drag()
			return
		selection_pointer = selection_motion.position
		queue_redraw()
		accept_event()
		return
	if event is InputEventMouseMotion and not endpoint_candidate.is_empty():
		var endpoint_motion := event as InputEventMouseMotion
		if (endpoint_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			cancel_endpoint_move()
			return
		endpoint_pointer = endpoint_motion.position
		endpoint_target = _input_port_at(
			endpoint_pointer, 30.0,
			StringName(endpoint_candidate.get("from_node", &"")),
			int(endpoint_candidate.get("from_port", -1)),
			endpoint_candidate
		)
		queue_redraw()
		accept_event()
		return
	if event is InputEventMouseMotion and erase_active:
		var erase_motion := event as InputEventMouseMotion
		if (erase_motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) == 0:
			finish_erase_stroke()
		else:
			continue_erase_stroke(erase_motion.position)
		accept_event()
		return
	if event is InputEventMouseMotion and not branch_candidate.is_empty():
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			cancel_branch_drag()
			return
		branch_pointer = motion.position
		if not branch_dragging and branch_pointer.distance_to(branch_anchor) >= 6.0:
			branch_dragging = true
			branch_drag_state_changed.emit(true)
		branch_target = _input_port_at(
			branch_pointer, 30.0,
			StringName(branch_candidate.get("from_node", &"")),
			int(branch_candidate.get("from_port", -1))
		) if branch_dragging else {}
		queue_redraw()
		accept_event()


func _draw() -> void:
	_draw_settled_connections()
	_draw_hovered_connection()
	_draw_component_placement_preview()
	if not builtin_connection_source.is_empty():
		_draw_builtin_connection_preview()
		_draw_connection_target_guides(
			StringName(builtin_connection_source.get("node", &"")),
			int(builtin_connection_source.get("port", -1)),
			bool(builtin_connection_source.get("is_output", true)),
			builtin_connection_pointer
		)
	if selection_dragging:
		var selection_rect: Rect2 = _selection_rectangle()
		draw_rect(selection_rect, Color("50d5ff", 0.12), true)
		draw_rect(selection_rect, Color("50d5ff", 0.9), false, 2.0, true)
	if erase_active:
		draw_circle(erase_pointer, ERASER_TIP_RADIUS, Color(ERASER_COLOR, 0.95))
	if not endpoint_candidate.is_empty():
		_draw_connection_target_guides(
			StringName(endpoint_candidate.get("from_node", &"")),
			int(endpoint_candidate.get("from_port", -1)), true,
			endpoint_pointer, endpoint_candidate
		)
		_draw_endpoint_preview()
	if not branch_dragging:
		return
	_draw_connection_target_guides(
		StringName(branch_candidate.get("from_node", &"")),
		int(branch_candidate.get("from_port", -1)), true,
		branch_pointer
	)
	var valid: bool = bool(branch_target.get("valid", false))
	var color := Color("67e8a5") if valid else Color("50d5ff")
	var end: Vector2 = branch_pointer
	if not branch_target.is_empty():
		end = branch_target.get("position", branch_pointer)
		if not valid:
			color = Color("ff6b7d")
	var preview: PackedVector2Array = get_connection_line(branch_anchor, end)
	draw_polyline(preview, Color(color, 0.22), 16.0, true)
	draw_polyline(preview, color, 5.0, true)
	draw_circle(branch_anchor, 8.0, Color("101725"))
	draw_circle(branch_anchor, 6.0, color)
	draw_circle(end, 10.0, Color(color, 0.18))
	draw_circle(end, 5.0, color)


func set_draft_color_index(color_index: int) -> void:
	draft_color_index = WirePaletteType.normalized_index(color_index)
	queue_redraw()


func _draw_builtin_connection_preview() -> void:
	var source: GraphNode = get_node_or_null(NodePath(String(
		builtin_connection_source.get("node", "")
	))) as GraphNode
	if source == null:
		return
	var port: int = int(builtin_connection_source.get("port", 0))
	var is_output: bool = bool(builtin_connection_source.get("is_output", true))
	var origin: Vector2 = displayed_port_position(source, port, is_output)
	var preview: PackedVector2Array = get_connection_line(origin, builtin_connection_pointer)
	var color: Color = WirePaletteType.color(draft_color_index)
	draw_polyline(preview, Color(color, 0.20), SETTLED_WIRE_THICKNESS + 7.0, true)
	draw_polyline(preview, color.lightened(0.24), SETTLED_WIRE_THICKNESS - 1.0, true)


func _draw_settled_connections() -> void:
	for connection: Dictionary in get_connection_list():
		var curve: PackedVector2Array = connection_curve(connection)
		if curve.size() < 2:
			continue
		var key: String = _connection_key(
			connection.get("from_node", &""), int(connection.get("from_port", -1)),
			connection.get("to_node", &""), int(connection.get("to_port", -1))
		)
		var base: Color = WirePaletteType.color(int(connection_color_indices.get(
			key, WirePaletteType.DEFAULT_INDEX
		)))
		var state: int = int(connection_signal_values.get(key, LogicSignalType.LOW))
		_draw_settled_curve(curve, base, state)
		if connection_flows.has(key):
			_draw_connection_flow(curve, base, connection_flows[key])


func _draw_settled_curve(curve: PackedVector2Array, base: Color, state: int) -> void:
	draw_polyline(curve, Color("07101c", 0.92), SETTLED_WIRE_THICKNESS + 3.0, true)
	if state == LogicSignalType.HIGH_Z:
		_draw_dashed_curve(curve, Color("8b929d", 0.82), SETTLED_WIRE_THICKNESS - 1.5)
		return
	var settled: Color = base.lightened(0.22) if state == LogicSignalType.HIGH \
		else base.darkened(0.54)
	settled.a = 1.0 if state == LogicSignalType.HIGH else 0.78
	draw_polyline(curve, settled, SETTLED_WIRE_THICKNESS, true)
	if state == LogicSignalType.HIGH:
		draw_polyline(curve, Color(base.lightened(0.48), 0.38), 2.0, true)


func _draw_connection_flow(curve: PackedVector2Array, base: Color, flow: Dictionary) -> void:
	var progress: float = clampf(float(flow.get("progress", 0.0)), 0.0, 1.0)
	var prefix: PackedVector2Array = _path_prefix(curve, progress)
	if prefix.size() < 2:
		return
	var state: int = int(flow.get("state", LogicSignalType.LOW))
	var flow_color: Color = Color("8b929d") if state == LogicSignalType.HIGH_Z \
		else (base.lightened(0.55) if state == LogicSignalType.HIGH else base.lightened(0.08))
	draw_polyline(prefix, Color(flow_color, 0.24), FLOW_WIRE_THICKNESS + 5.0, true)
	draw_polyline(prefix, flow_color, FLOW_WIRE_THICKNESS, true)


func _draw_dashed_curve(curve: PackedVector2Array, color: Color, width: float) -> void:
	var draw_length: float = 8.0
	var gap_length: float = 6.0
	var drawing: bool = true
	var remaining: float = draw_length
	for index: int in range(curve.size() - 1):
		var start: Vector2 = curve[index]
		var finish: Vector2 = curve[index + 1]
		var segment_length: float = start.distance_to(finish)
		if segment_length <= 0.001:
			continue
		var direction: Vector2 = (finish - start) / segment_length
		var travelled: float = 0.0
		while travelled < segment_length:
			var step: float = minf(remaining, segment_length - travelled)
			if drawing:
				draw_line(
					start + direction * travelled,
					start + direction * (travelled + step), color, width, true
				)
			travelled += step
			remaining -= step
			if remaining <= 0.001:
				drawing = not drawing
				remaining = draw_length if drawing else gap_length


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
			var local: float = (target - travelled) / maxf(length, 0.001)
			result.append(points[index].lerp(points[index + 1], local))
			return result
		result.append(points[index + 1])
		travelled += length
	return result


func connection_curve(connection: Dictionary) -> PackedVector2Array:
	var source: GraphNode = get_node_or_null(NodePath(String(connection.get("from_node", "")))) as GraphNode
	var target: GraphNode = get_node_or_null(NodePath(String(connection.get("to_node", "")))) as GraphNode
	if source == null or target == null:
		return PackedVector2Array()
	var start: Vector2 = displayed_port_position(source, int(connection.get("from_port", 0)), true)
	var finish: Vector2 = displayed_port_position(target, int(connection.get("to_port", 0)), false)
	return get_connection_line(start, finish)


func begin_builtin_connection_preview(
		from_node: StringName,
		from_port: int,
		is_output: bool
	) -> void:
	builtin_connection_source = {
		"node": from_node,
		"port": from_port,
		"is_output": is_output,
	}
	var source: GraphNode = get_node_or_null(NodePath(String(from_node))) as GraphNode
	if source != null:
		builtin_connection_pointer = displayed_port_position(source, from_port, is_output)
	_clear_hovered_connection()
	queue_redraw()


func end_builtin_connection_preview() -> void:
	if builtin_connection_source.is_empty():
		return
	builtin_connection_source.clear()
	queue_redraw()


func visible_connection_targets() -> Array[Dictionary]:
	if not builtin_connection_source.is_empty():
		return _connection_targets(
			StringName(builtin_connection_source.get("node", &"")),
			int(builtin_connection_source.get("port", -1)),
			bool(builtin_connection_source.get("is_output", true))
		)
	if not endpoint_candidate.is_empty():
		return _connection_targets(
			StringName(endpoint_candidate.get("from_node", &"")),
			int(endpoint_candidate.get("from_port", -1)), true,
			endpoint_candidate
		)
	if branch_dragging:
		return _connection_targets(
			StringName(branch_candidate.get("from_node", &"")),
			int(branch_candidate.get("from_port", -1)), true
		)
	return []


func _connection_targets(
		from_node: StringName,
		from_port: int,
		from_is_output: bool,
		allowed_connection: Dictionary = {}
	) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for child: Node in get_children():
		if not child is GraphNode or not (child as GraphNode).visible:
			continue
		var node := child as GraphNode
		var port_count: int = node.get_input_port_count() if from_is_output else node.get_output_port_count()
		for port: int in range(port_count):
			var position: Vector2 = displayed_port_position(node, port, not from_is_output)
			var valid: bool = (
				from_is_output
				and not allowed_connection.is_empty()
				and node.name == StringName(allowed_connection.get("to_node", &""))
				and port == int(allowed_connection.get("to_port", -1))
			)
			if not valid and connection_validator.is_valid():
				if from_is_output:
					valid = bool(connection_validator.call(from_node, from_port, node.name, port))
				else:
					valid = bool(connection_validator.call(node.name, port, from_node, from_port))
			targets.append({
				"node": node.name,
				"port": port,
				"is_output": not from_is_output,
				"position": position,
				"valid": valid,
			})
	return targets


func _draw_connection_target_guides(
		from_node: StringName,
		from_port: int,
		from_is_output: bool,
		pointer: Vector2,
		allowed_connection: Dictionary = {}
	) -> void:
	for target: Dictionary in _connection_targets(
		from_node, from_port, from_is_output, allowed_connection
	):
		var position: Vector2 = target["position"]
		var hovered: bool = pointer.distance_to(position) <= 31.0
		var valid: bool = bool(target["valid"])
		if not valid and not hovered:
			continue
		var color: Color = SIGNAL_HIGH if valid else SIGNAL_LOW
		if hovered:
			draw_circle(position, TARGET_GUIDE_RADIUS + 7.0, Color(color, 0.13))
		draw_circle(position, TARGET_GUIDE_RADIUS, Color(color, 0.10))
		draw_circle(position, TARGET_GUIDE_RADIUS, color, false, 3.0 if hovered else 2.0, true)
	var source: GraphNode = get_node_or_null(NodePath(String(from_node))) as GraphNode
	if source == null:
		return
	var origin: Vector2 = displayed_port_position(source, from_port, from_is_output)
	draw_circle(origin, TARGET_GUIDE_RADIUS + 2.0, Color("50d5ff", 0.12))
	draw_circle(origin, TARGET_GUIDE_RADIUS + 2.0, Color("50d5ff"), false, 2.0, true)


func _update_hovered_connection(point: Vector2) -> void:
	if not _port_at(point, 28.0).is_empty():
		_clear_hovered_connection()
		return
	var connection: Dictionary = get_closest_connection_at_point(point, WIRE_HOVER_RADIUS)
	if connection.is_empty():
		_clear_hovered_connection()
		return
	hovered_connection = connection.duplicate()
	hovered_wire_point = _closest_point_on_connection(connection, point)
	queue_redraw()


func _clear_hovered_connection() -> void:
	if hovered_connection.is_empty():
		return
	hovered_connection.clear()
	queue_redraw()


func _draw_hovered_connection() -> void:
	if hovered_connection.is_empty():
		return
	var source: GraphNode = get_node_or_null(NodePath(String(hovered_connection.get("from_node", "")))) as GraphNode
	var target: GraphNode = get_node_or_null(NodePath(String(hovered_connection.get("to_node", "")))) as GraphNode
	if source == null or target == null:
		return
	var curve: PackedVector2Array = connection_curve(hovered_connection)
	draw_polyline(curve, Color("50d5ff", 0.13), 18.0, true)
	draw_polyline(curve, Color("50d5ff", 0.86), 2.5, true)
	draw_circle(hovered_wire_point, 7.0, Color("101725"))
	draw_circle(hovered_wire_point, 5.0, Color("50d5ff"))


func _on_graph_mouse_exited() -> void:
	if builtin_connection_source.is_empty() and branch_candidate.is_empty() and endpoint_candidate.is_empty():
		_clear_hovered_connection()


func set_component_placement_preview(
		enabled: bool,
		preview_control: Control = null,
		footprint: Vector2 = Vector2(120.0, 72.0)
	) -> void:
	if placement_preview_control != null and is_instance_valid(placement_preview_control):
		placement_preview_control.hide()
		placement_preview_control.queue_free()
	placement_preview_control = preview_control
	component_placement_enabled = enabled
	placement_preview_size = Vector2(maxf(48.0, footprint.x), maxf(32.0, footprint.y))
	placement_has_pointer = false
	if enabled and placement_preview_control != null:
		placement_preview_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placement_preview_control.z_index = 1000
		placement_preview_control.modulate = Color(0.82, 0.93, 1.0, 0.42)
		add_child(placement_preview_control)
		placement_preview_control.hide()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	queue_redraw()


func _draw_component_placement_preview() -> void:
	if not component_placement_enabled or not placement_has_pointer:
		if placement_preview_control != null and is_instance_valid(placement_preview_control):
			placement_preview_control.hide()
		return
	var half_size: Vector2 = placement_preview_size * 0.5
	var graph_top_left: Vector2 = (placement_pointer + scroll_offset) / zoom - half_size
	var snap_distance: float = float(snapping_distance) if snapping_enabled else 1.0
	graph_top_left = Vector2(
		snappedf(graph_top_left.x, snap_distance),
		snappedf(graph_top_left.y, snap_distance)
	)
	var display_top_left: Vector2 = graph_top_left * zoom - scroll_offset
	if placement_preview_control == null or not is_instance_valid(placement_preview_control):
		return
	placement_preview_control.position = display_top_left
	placement_preview_control.size = placement_preview_size
	placement_preview_control.scale = Vector2.ONE * zoom
	placement_preview_control.show()


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
	var changed_count: int = 0
	var is_click: bool = selection_rect.size.length() < SELECTION_DRAG_THRESHOLD
	for child: Node in get_children():
		if not child is GraphNode or not (child as GraphNode).visible:
			continue
		var node := child as GraphNode
		var inside: bool = (
			not is_click
			and selection_rect.intersects(displayed_node_rect(node), true)
		)
		var next_selected: bool = node.selected
		if selection_toggle_mode:
			if inside:
				next_selected = not node.selected
		else:
			next_selected = inside
		if next_selected != node.selected:
			node.selected = next_selected
			changed_count += 1
	var selected_count: int = 0
	for child: Node in get_children():
		if child is GraphNode and (child as GraphNode).visible and (child as GraphNode).selected:
			selected_count += 1
	selection_toggle_mode = false
	selection_rectangle_applied.emit(changed_count, selected_count)


func begin_erase_stroke(position: Vector2) -> void:
	if not branch_edit_enabled:
		return
	if not endpoint_candidate.is_empty():
		cancel_endpoint_move()
	if not branch_candidate.is_empty():
		cancel_branch_drag()
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
	# The eraser is a cursor-tip contact patch, not a circular brush. Include half
	# the rendered wire width so touching a visible wire counts, while nearby
	# empty space remains safe.
	var wire_hit_radius: float = SETTLED_WIRE_THICKNESS * 0.5 + ERASER_TIP_RADIUS
	for connection: Dictionary in _connections_at(point, wire_hit_radius):
		var key: String = _connection_key(
			connection.get("from_node", &""), int(connection.get("from_port", -1)),
			connection.get("to_node", &""), int(connection.get("to_port", -1))
		)
		if erase_wire_keys.has(key):
			continue
		erase_wire_keys[key] = true
		erase_wire_requested.emit(connection.duplicate())


func _connections_at(point: Vector2, radius: float) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	var radius_squared: float = radius * radius
	for connection: Dictionary in get_connection_list():
		var source: GraphNode = get_node_or_null(NodePath(String(connection.get("from_node", "")))) as GraphNode
		var target: GraphNode = get_node_or_null(NodePath(String(connection.get("to_node", "")))) as GraphNode
		if source == null or target == null:
			continue
		var curve: PackedVector2Array = connection_curve(connection)
		for index: int in range(curve.size() - 1):
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, curve[index], curve[index + 1])
			if closest.distance_squared_to(point) <= radius_squared:
				hits.append(connection.duplicate())
				break
	return hits


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


func set_connection_signal_value(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int,
		value: bool
	) -> void:
	set_connection_signal_state(
		from_node, from_port, to_node, to_port,
		LogicSignalType.HIGH if value else LogicSignalType.LOW
	)


func set_connection_signal_state(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int,
		state: int
	) -> void:
	var key: String = _connection_key(from_node, from_port, to_node, to_port)
	if connection_signal_values.get(key, -1) == state:
		return
	connection_signal_values[key] = state
	queue_redraw()


func clear_connection_signal_values() -> void:
	connection_signal_values.clear()
	queue_redraw()


func set_connection_color_index(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int,
		color_index: int
	) -> void:
	var key: String = _connection_key(from_node, from_port, to_node, to_port)
	var normalized: int = WirePaletteType.normalized_index(color_index)
	if int(connection_color_indices.get(key, -1)) == normalized:
		return
	connection_color_indices[key] = normalized
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
	var key: String = _connection_key(from_node, from_port, to_node, to_port)
	connection_color_indices.erase(key)
	connection_signal_values.erase(key)
	connection_flows.erase(key)
	queue_redraw()


func set_connection_flow(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int,
		state: int,
		progress: float
	) -> void:
	connection_flows[_connection_key(from_node, from_port, to_node, to_port)] = {
		"state": state,
		"progress": clampf(progress, 0.0, 1.0),
	}
	queue_redraw()


func clear_connection_flows() -> void:
	if connection_flows.is_empty():
		return
	connection_flows.clear()
	queue_redraw()


func hovered_connection_snapshot() -> Dictionary:
	return hovered_connection.duplicate()


func get_connection_signal_value(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
	) -> Dictionary:
	var key: String = _connection_key(from_node, from_port, to_node, to_port)
	if not connection_signal_values.has(key):
		return {"known": false, "state": LogicSignalType.HIGH_Z}
	var state: int = int(connection_signal_values[key])
	return {
		"known": LogicSignalType.is_binary(state),
		"value": state == LogicSignalType.HIGH,
		"state": state,
	}


func _connection_key(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> String:
	return "%s:%d>%s:%d" % [from_node, from_port, to_node, to_port]


func cancel_branch_drag() -> void:
	var was_dragging: bool = branch_dragging
	branch_candidate.clear()
	branch_target.clear()
	branch_dragging = false
	queue_redraw()
	if was_dragging:
		branch_drag_state_changed.emit(false)


func _begin_endpoint_move(connection: Dictionary, pointer: Vector2) -> void:
	endpoint_candidate = connection.duplicate()
	endpoint_pointer = pointer
	var source: GraphNode = get_node_or_null(NodePath(String(connection.get("from_node", "")))) as GraphNode
	if source == null:
		endpoint_candidate.clear()
		return
	endpoint_anchor = displayed_port_position(source, int(connection.get("from_port", 0)), true)
	endpoint_target.clear()
	connection_endpoint_move_state_changed.emit(true)
	queue_redraw()


func cancel_endpoint_move() -> void:
	var was_active: bool = not endpoint_candidate.is_empty()
	endpoint_candidate.clear()
	endpoint_target.clear()
	queue_redraw()
	if was_active:
		connection_endpoint_move_state_changed.emit(false)


func _draw_endpoint_preview() -> void:
	var valid: bool = bool(endpoint_target.get("valid", false))
	var color := Color("67e8a5") if valid else Color("50d5ff")
	var finish: Vector2 = endpoint_pointer
	if not endpoint_target.is_empty():
		finish = endpoint_target.get("position", endpoint_pointer)
		if not valid:
			color = Color("ff6b7d")
	var preview: PackedVector2Array = get_connection_line(endpoint_anchor, finish)
	draw_polyline(preview, Color(color, 0.2), 16.0, true)
	draw_polyline(preview, color, 5.0, true)
	draw_circle(endpoint_anchor, 7.0, color)
	draw_circle(finish, 10.0, Color(color, 0.2))
	draw_circle(finish, 5.0, color)


func _input_port_at(
		point: Vector2,
		radius: float,
		from_node: StringName,
		from_port: int,
		allowed_connection: Dictionary = {}
	) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance: float = radius
	for child: Node in get_children():
		if not child is GraphNode or not (child as GraphNode).visible:
			continue
		var node := child as GraphNode
		for port: int in range(node.get_input_port_count()):
			var port_position: Vector2 = displayed_port_position(node, port, false)
			var distance: float = point.distance_to(port_position)
			if distance > closest_distance:
				continue
			var valid: bool = (
				not allowed_connection.is_empty()
				and node.name == StringName(allowed_connection.get("to_node", &""))
				and port == int(allowed_connection.get("to_port", -1))
			)
			if not valid and connection_validator.is_valid():
				valid = bool(connection_validator.call(from_node, from_port, node.name, port))
			closest_distance = distance
			closest = {"node": node.name, "port": port, "position": port_position, "valid": valid}
	return closest


func _connection_to_input(to_node: StringName, to_port: int) -> Dictionary:
	for connection: Dictionary in get_connection_list():
		if connection.get("to_node", &"") == to_node and int(connection.get("to_port", -1)) == to_port:
			return connection.duplicate()
	return {}


func _same_connection(left: Dictionary, right: Dictionary) -> bool:
	return (
		left.get("from_node", &"") == right.get("from_node", &"")
		and int(left.get("from_port", -1)) == int(right.get("from_port", -1))
		and left.get("to_node", &"") == right.get("to_node", &"")
		and int(left.get("to_port", -1)) == int(right.get("to_port", -1))
	)


func _port_at(point: Vector2, radius: float) -> Dictionary:
	for child: Node in get_children():
		if not child is GraphNode or not (child as GraphNode).visible:
			continue
		var node := child as GraphNode
		for port: int in range(node.get_input_port_count()):
			if point.distance_to(displayed_port_position(node, port, false)) <= radius:
				return {"node": node.name, "port": port, "is_output": false}
		for port: int in range(node.get_output_port_count()):
			if point.distance_to(displayed_port_position(node, port, true)) <= radius:
				return {"node": node.name, "port": port, "is_output": true}
	return {}


func _node_at(point: Vector2) -> StringName:
	for child: Node in get_children():
		if child is GraphNode and (child as GraphNode).visible:
			var node := child as GraphNode
			if displayed_node_rect(node).has_point(point):
				return node.name
	return &""


func _closest_point_on_connection(connection: Dictionary, point: Vector2) -> Vector2:
	var source: GraphNode = get_node_or_null(NodePath(String(connection.get("from_node", "")))) as GraphNode
	var target: GraphNode = get_node_or_null(NodePath(String(connection.get("to_node", "")))) as GraphNode
	if source == null or target == null:
		return point
	var curve: PackedVector2Array = connection_curve(connection)
	var closest: Vector2 = point
	var closest_distance: float = INF
	for index: int in range(curve.size() - 1):
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(point, curve[index], curve[index + 1])
		var distance: float = candidate.distance_squared_to(point)
		if distance < closest_distance:
			closest_distance = distance
			closest = candidate
	return closest
