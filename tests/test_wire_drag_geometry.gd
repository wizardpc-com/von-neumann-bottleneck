extends SceneTree

var failures: Array[String] = []
var hover_checks_completed: bool = false


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1400, 900)
	var graph: GraphEdit = load("res://src/hardware_foundations/circuit_graph_edit.gd").new()
	graph.size = Vector2(1300, 780)
	root.add_child(graph)
	var source: GraphNode = _node(graph, &"Source", Vector2(130, 120))
	var target: GraphNode = _node(graph, &"Target", Vector2(650, 350))
	var spare: GraphNode = _node(graph, &"Spare", Vector2(800, 100))
	graph.set("connection_validator", func(from_node: StringName, _from_port: int, to_node: StringName, _to_port: int) -> bool:
		return from_node == source.name and to_node == spare.name)
	graph.connect_node(source.name, 0, target.name, 0)
	await _settle()
	var wire: Dictionary = graph.get_connection_list()[0].duplicate()
	var topology: Array = graph.get_connection_list().duplicate(true)
	var curve: PackedVector2Array = graph.call("connection_curve", wire)
	var start: Vector2 = _sample(curve, 0.37)
	graph.call("_capture_branch_anchor", wire, start)
	graph.set("branch_dragging", true)
	graph.set("branch_pointer", Vector2(1000, 600))
	var fraction: float = float(graph.get("branch_anchor_fraction"))
	_check(absf(fraction - 0.37) < 0.001, "The branch captures its selected position along the original curve.")
	var geometry_events: Array[int] = [0]
	graph.connect("displayed_geometry_changed", func() -> void: geometry_events[0] += 1)
	graph.scroll_offset += Vector2(70, 45)
	graph.zoom = 0.8
	await _settle()
	curve = graph.call("connection_curve", wire)
	var anchor: Vector2 = graph.get("branch_anchor")
	# GraphEdit zooms around its view center, which can partly cancel a pan.
	# Verify attachment and a real position change, not an arbitrary travel length.
	_check(anchor.distance_to(_sample(curve, fraction)) < 0.01 and not anchor.is_equal_approx(start),
		"Pan and zoom keep a pending branch attached to its visible source wire, not the original screen point: actual=%s expected=%s start=%s fraction=%s." % [anchor, _sample(curve, fraction), start, fraction])
	_check(geometry_events[0] > 0, "Displayed geometry changes notify presentation overlays.")
	# Moving a source changes the sampled curve itself; the branch still owns
	# the same fraction and must not jump to whichever segment is now nearest.
	source.position_offset += Vector2(50, 90)
	graph.move_child(target, graph.get_child_count() - 1)
	await _settle()
	curve = graph.call("connection_curve", wire)
	_check((graph.get("branch_anchor") as Vector2).distance_to(_sample(curve, fraction)) < 0.01
		and is_equal_approx(float(graph.get("branch_anchor_fraction")), fraction),
		"Endpoint relayout and child reordering preserve the selected point along the wire.")
	var submitted: Dictionary = {}
	graph.connect("branch_connection_requested", func(connection: Dictionary, point: Vector2, to_node: StringName, to_port: int) -> void:
		submitted.merge({"wire": connection, "point": point, "node": to_node, "port": to_port}, true))
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = graph.call("displayed_port_position", spare, 0, false)
	graph.call("_gui_input", release)
	_check(not submitted.is_empty(), "Releasing a panned branch over a valid input emits the editing request.")
	if not submitted.is_empty():
		_check((submitted.point as Vector2).distance_to(_sample(curve, fraction)) < 0.01
			and submitted.node == spare.name and submitted.wire == wire,
			"Branch submission carries the current displayed split point and original source wire.")
	_check((graph.get("branch_candidate") as Dictionary).is_empty(), "Release clears the pending branch.")
	graph.call("_begin_endpoint_move", wire, release.position)
	graph.call("_refresh_drag_geometry")
	_check(bool((graph.get("endpoint_target") as Dictionary).get("valid", false)), "Reconnection initially recognizes the hovered input.")
	var old_origin: Vector2 = graph.get("endpoint_anchor")
	graph.scroll_offset += Vector2(90, 55)
	graph.zoom = 1.1
	await _settle()
	var expected_origin: Vector2 = graph.call("displayed_port_position", source, 0, true)
	_check((graph.get("endpoint_anchor") as Vector2).distance_to(expected_origin) < 0.01
		and expected_origin.distance_to(old_origin) > 20.0,
		"A moved endpoint preview remains anchored at the displayed output during pan and zoom.")
	_check((graph.get("endpoint_target") as Dictionary).is_empty(),
		"Moving the target away from a stationary pointer clears its stale snap indicator.")
	graph.call("cancel_endpoint_move")
	_check(graph.get_connection_list() == topology, "Preview movement, release requests and cancellation never mutate connectivity.")
	await _check_hover_feedback(graph, source, target, spare)
	_check(hover_checks_completed, "The hover and release regression path completes without an interrupted fixture.")
	graph.queue_free()
	await process_frame
	for message: String in failures:
		push_error(message)
	print("PASS: wire drag geometry, current split submission, pure hover and release diagnostics" if failures.is_empty() else "FAIL: wire drag geometry")
	quit(0 if failures.is_empty() else 1)


func _node(graph: GraphEdit, id: StringName, position: Vector2) -> GraphNode:
	var node := GraphNode.new()
	node.name = id
	node.custom_minimum_size = Vector2(110, 70)
	var row := Label.new()
	row.text = String(id)
	node.add_child(row)
	node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	graph.add_child(node)
	node.position_offset = position
	return node


func _check_hover_feedback(graph: GraphEdit, source: GraphNode, target: GraphNode, spare: GraphNode) -> void:
	# Exercise the production controller callbacks without opening a second UI
	# or loading player progress. This graph has a synthetic 4 -> 1 mismatch.
	var controller: Control = load("res://src/hardware_foundations/hardware_foundations.gd").new()
	var status := Label.new()
	status.text = "Connect to an input"
	status.add_theme_color_override("font_color", Color.CYAN)
	controller.set("status_label", status)
	controller.set("current_phase", &"tutorial")
	var circuit: RefCounted = load("res://src/circuit/logic_circuit.gd").new()
	var component_type: Script = load("res://src/circuit/logic_component.gd")
	var no_ports: Array[StringName] = []
	var output_ports: Array[StringName] = [&"OUT"]
	var input_ports: Array[StringName] = [&"IN"]
	var no_widths: Array[int] = []
	var scalar_width: Array[int] = [1]
	var word_width: Array[int] = [4]
	circuit.call("add_component", component_type.new(source.name, &"input", "Source", &"DATA", false, no_ports, output_ports, no_widths, word_width))
	circuit.call("add_component", component_type.new(target.name, &"output", "Target", &"OUT", false, input_ports, no_ports, scalar_width, no_widths))
	circuit.call("add_component", component_type.new(spare.name, &"output", "Spare", &"OUT4", false, input_ports, no_ports, word_width, no_widths))
	controller.set("current_circuit", circuit)
	graph.set("connection_validator", Callable(controller, "_is_connection_compatible"))
	graph.set("connection_hover_validator", Callable(controller, "_is_hover_connection_valid"))
	graph.connect("connection_rejection_diagnostic_requested", Callable(controller, "_show_rejected_connection_diagnostic"))
	var rejected: Array[int] = [0]
	graph.connect("connection_attempt_rejected", func() -> void: rejected[0] += 1)
	graph.zoom = 1.0
	graph.scroll_offset = Vector2.ZERO
	await _settle()
	var before: Array = graph.get_connection_list().duplicate(true)
	graph.call("begin_builtin_connection_preview", source.name, 0, true)
	graph.set("builtin_connection_pointer", graph.call("displayed_port_position", target, 0, false))
	for _query: int in range(4):
		_check((graph.call("builtin_connection_preview") as Dictionary).state == &"invalid", "The mismatched input keeps its immediate invalid preview.")
	_check(status.text == "Connect to an input" and status.get_theme_color("font_color").is_equal_approx(Color.CYAN) and rejected[0] == 0,
		"Hovering an invalid port neither overwrites action instructions nor records rejected attempts.")
	graph.set("builtin_connection_pointer", Vector2(1000, 600))
	_check((graph.call("builtin_connection_preview") as Dictionary).state == &"free", "Leaving a mismatched port clears the invalid preview.")
	graph.set("builtin_connection_pointer", graph.call("displayed_port_position", spare, 0, false))
	_check((graph.call("builtin_connection_preview") as Dictionary).state == &"valid" and status.text == "Connect to an input",
		"A subsequent compatible hover does not retain an earlier error message.")
	graph.call("end_builtin_connection_preview")
	_check(status.text == "Connect to an input" and rejected[0] == 0, "Cancelling a preview that crossed an invalid port leaves no error or rejection count.")
	graph.call("begin_builtin_connection_preview", source.name, 0, true)
	graph.set("_rejection_reported", false)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = graph.get_global_transform() * (graph.call("displayed_port_position", target, 0, false) as Vector2)
	graph.call("_input", release)
	var diagnostic: Dictionary = circuit.call("connection_diagnostic", source.name, 0, target.name, 0)
	var expected: String = root.get_node("Localization").call("text_from_spec", diagnostic)
	_check(status.text == expected and status.get_theme_color("font_color").is_equal_approx(Color("ff6b7d")) and rejected[0] == 1,
		"A real failed release displays the exact localized diagnostic and records one rejection: status=%s expected=%s count=%s." % [status.text, expected, rejected[0]])
	graph.call("_input", release)
	_check(rejected[0] == 1, "Duplicate native rejection reporting cannot count a second player attempt.")
	graph.call("end_builtin_connection_preview")
	_check(graph.get_connection_list() == before, "Hover checks and failed release diagnostics preserve the original wires.")
	graph.disconnect("connection_rejection_diagnostic_requested", Callable(controller, "_show_rejected_connection_diagnostic"))
	graph.set("connection_validator", Callable())
	graph.set("connection_hover_validator", Callable())
	controller.free()
	status.free()
	hover_checks_completed = true


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
