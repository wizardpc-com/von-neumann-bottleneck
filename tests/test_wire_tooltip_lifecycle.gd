extends SceneTree
## Real graph geometry and custom tooltip content; no native pointer acceptance claim.

const Graph = preload("res://src/hardware_foundations/circuit_graph_edit.gd")

var checks: int = 0
var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _node(graph: CircuitGraphEdit, id: StringName, at: Vector2) -> void:
	var part := GraphNode.new()
	part.name = id
	part.position_offset = at
	part.add_child(Label.new())
	part.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	graph.add_child(part)


func _settle() -> void:
	for _frame: int in range(4):
		await process_frame


func _sample(points: PackedVector2Array, fraction: float) -> Vector2:
	var distance: float = 0.0
	for index: int in range(points.size() - 1):
		distance += points[index].distance_to(points[index + 1])
	distance *= fraction
	for index: int in range(points.size() - 1):
		var length: float = points[index].distance_to(points[index + 1])
		if distance <= length and length > 0.001:
			return points[index].lerp(points[index + 1], distance / length)
		distance -= length
	return points[points.size() - 1]


func _tooltip(graph: CircuitGraphEdit, connection: Dictionary) -> Control:
	var curve: PackedVector2Array = graph.connection_curve(connection)
	_check(curve.size() >= 2, "Existing wire has rendered curve geometry")
	if curve.size() < 2:
		return null
	# A straight connection can contain only two samples: its middle array
	# index is the target port, where hover deliberately excludes wires.
	var point: Vector2 = _sample(curve, 0.5)
	graph._update_hovered_connection(point)
	_check(graph.hovered_connection == connection,
		"Initial hover belongs to the requested exact wire: actual=%s expected=%s point=%s" % [
			graph.hovered_connection, connection, point])
	var text: String = graph._get_tooltip(point)
	_check(not text.is_empty(), "Existing exact wire has tooltip text")
	var content := graph._make_custom_tooltip(text) as Control
	root.add_child(content)
	return content


func _run() -> void:
	root.size = Vector2i(1100, 700)
	var graph: CircuitGraphEdit = Graph.new()
	graph.size = Vector2(1000, 600)
	root.add_child(graph)
	graph.connection_description = func(connection: Dictionary) -> String:
		return str(connection.from_node) + " -> " + str(connection.to_node)
	_node(graph, &"N0", Vector2(50, 50))
	_node(graph, &"N1", Vector2(550, 50))
	_node(graph, &"N2", Vector2(50, 300))
	_node(graph, &"N3", Vector2(550, 300))
	await _settle()
	graph.connect_node(&"N0", 0, &"N1", 0)
	graph.connect_node(&"N2", 0, &"N3", 0)
	await _settle()
	var wires: Array[Dictionary] = graph.get_connection_list()
	_check(wires.size() == 2, "Independent real wires are connected")
	if wires.size() != 2:
		quit(1)
		return
	var first: Dictionary = wires[0]
	var second: Dictionary = wires[1]
	var parent_visible: bool = root.visible
	var content: Control = _tooltip(graph, first)
	if content == null:
		quit(1)
		return
	_check(content.visible, "Wire tooltip content is shown")
	var neighbor_point: Vector2 = _sample(graph.connection_curve(second), 0.5)
	graph._update_hovered_connection(neighbor_point)
	_check(not content.visible and graph.hovered_connection == second,
		"Moving directly to another wire clears the old tooltip and assigns the new hover")
	_check(root.visible == parent_visible, "Clearing content in the graph's window preserves the parent window")
	content.queue_free()
	content = _tooltip(graph, first)
	if content == null:
		quit(1)
		return
	graph.disconnect_node(second.from_node, second.from_port, second.to_node, second.to_port)
	graph.remove_connection_presentation(second.from_node, second.from_port, second.to_node, second.to_port)
	_check(content.visible and graph.hovered_connection == first,
		"Deleting unrelated wire preserves the pointed wire and its tooltip")
	graph.disconnect_node(first.from_node, first.from_port, first.to_node, first.to_port)
	graph.remove_connection_presentation(first.from_node, first.from_port, first.to_node, first.to_port)
	_check(not content.visible and graph.hovered_connection.is_empty() and graph.hovered_net.is_empty(),
		"Deleting pointed wire immediately clears tooltip and hover without mouse motion")
	_check(graph._get_tooltip(Vector2(200, 100)).is_empty(), "Empty graph has no stale wire description")
	graph.connect_node(second.from_node, second.from_port, second.to_node, second.to_port)
	await _settle()
	var next: Control = _tooltip(graph, second)
	if next == null:
		quit(1)
		return
	_check(next.visible and (next.get_child(0) as Label).text == "N2 -> N3",
		"Neighboring retained or restored wire receives its own valid tooltip")
	graph.clear_connections()
	await process_frame
	_check(not next.visible and graph.hovered_connection.is_empty(),
		"Native clear_connections invalidates cached tooltip without presentation callbacks")
	graph.connect_node(first.from_node, first.from_port, first.to_node, first.to_port)
	await _settle()
	var rebuilt: Control = _tooltip(graph, first)
	if rebuilt == null:
		quit(1)
		return
	# A test-owned public PopupPanel models the custom content's enclosing
	# window. This verifies the window boundary, not native tooltip dispatch.
	var popup := PopupPanel.new()
	popup.set_flag(Window.FLAG_NO_FOCUS, true)
	popup.set_flag(Window.FLAG_MOUSE_PASSTHROUGH, true)
	root.add_child(popup)
	rebuilt.reparent(popup)
	popup.popup(Rect2i(30, 30, 300, 80))
	_check(popup.visible and rebuilt.get_window() == popup,
		"Custom content has its own visible tooltip window")
	graph.disconnect_node(first.from_node, first.from_port, first.to_node, first.to_port)
	graph.remove_connection_presentation(first.from_node, first.from_port, first.to_node, first.to_port)
	_check(not rebuilt.visible and not popup.visible and root.visible == parent_visible,
		"Deleting the pointed wire hides content and its outer frame while preserving the parent window")
	graph.connect_node(first.from_node, first.from_port, first.to_node, first.to_port)
	await _settle()
	var exiting: Control = _tooltip(graph, first)
	if exiting == null:
		quit(1)
		return
	graph.queue_free()
	await process_frame
	_check(not exiting.visible, "Replacing graph clears its old custom tooltip content")
	content.queue_free()
	next.queue_free()
	popup.queue_free()
	exiting.queue_free()
	if failures == 0:
		print("PASS: wire tooltip lifecycle %d checks" % checks)
	else:
		print("FAIL: wire tooltip lifecycle %d failures" % failures)
	quit(0 if failures == 0 else 1)
