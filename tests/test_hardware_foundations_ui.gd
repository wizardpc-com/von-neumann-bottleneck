extends SceneTree

const CircuitEventType = preload("res://src/circuit/circuit_event.gd")
const CircuitTraceType = preload("res://src/circuit/circuit_trace.gd")
const LogicSignalType = preload("res://src/circuit/logic_signal.gd")
const CircuitLiveStateType = preload("res://src/circuit/circuit_live_state.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://src/hardware_foundations/hardware_foundations.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	for _frame: int in range(5):
		await process_frame

	_assert(StringName(main.get("current_phase")) == &"campaign", "Hardware Foundations must open on the prerequisite-gated level map.")
	var campaign_buttons: Dictionary = main.get("campaign_level_buttons")
	_assert(campaign_buttons.has(&"tutorial") and not (campaign_buttons[&"tutorial"] as Button).disabled, "The wiring tutorial must be the first unlocked Foundations level.")
	_assert(campaign_buttons.has(&"half_adder") and (campaign_buttons[&"half_adder"] as Button).disabled, "Half Adder must be visibly locked before the wiring tutorial is complete.")
	_assert(campaign_buttons.has(&"full_adder") and (campaign_buttons[&"full_adder"] as Button).disabled, "Later arithmetic levels must remain visibly locked at session start.")
	main.call("_start_campaign_level", &"half_adder")
	_assert(StringName(main.get("current_phase")) == &"campaign", "The internal level router must reject a direct Half Adder prerequisite bypass.")
	var tutorial_map_button: Button = campaign_buttons[&"tutorial"]
	tutorial_map_button.pressed.emit()
	for _tutorial_frame: int in range(3):
		await process_frame
	_assert(StringName(main.get("current_phase")) == &"tutorial", "Selecting the first map level must open the short wiring tutorial.")
	_assert(not is_instance_valid(tutorial_map_button), "A clicked map button must be released after its signal finishes instead of triggering Godot's locked-object error.")
	var graph: GraphEdit = main.get("graph")
	var nodes: Dictionary = main.get("component_nodes")
	var symbols: Dictionary = main.get("component_symbols")
	_assert(graph != null and graph.get_connection_list().is_empty(), "Tutorial must begin auto-laid-out but unwired.")
	_assert(graph.connection_lines_thickness >= 8.0, "Schematic wires must be deliberately heavier than Godot's thin default.")
	var desktop_windows: Dictionary = main.get("desktop_windows")
	_assert(desktop_windows.size() == 2 and (desktop_windows[&"task"] as Control).visible and (desktop_windows[&"test_bench"] as Control).visible, "Mission and Test Bench must coexist as desktop-style floating windows.")
	var task_window: Control = desktop_windows[&"task"]
	var original_window_position: Vector2 = task_window.position
	var original_window_height: float = task_window.size.y
	task_window.call("move_by", Vector2(52.0, 18.0))
	_assert(not task_window.position.is_equal_approx(original_window_position), "A Hardware Foundations page must be movable like a desktop/browser window.")
	task_window.call("set_minimized", true)
	await process_frame
	_assert(bool(task_window.get("minimized")) and task_window.size.y < original_window_height, "A floating page must collapse to its title bar when minimized.")
	main.call("_show_desktop_window", &"task")
	await process_frame
	_assert(not bool(task_window.get("minimized")) and task_window.visible, "The desktop taskbar button must restore a minimized page.")
	for component_id: StringName in [&"A_IN", &"B_IN", &"AND_1", &"OR_1", &"NOT_1", &"LAMP"]:
		_assert(nodes.has(component_id), "Tutorial must expose %s." % component_id)
		if nodes.has(component_id):
			var visible_node: GraphNode = nodes[component_id]
			_assert(Rect2(Vector2.ZERO, graph.size).intersects(Rect2(visible_node.position, visible_node.size)), "Tutorial %s must begin inside the visible graph; position=%s offset=%s scroll=%s size=%s graph=%s." % [component_id, visible_node.position, visible_node.position_offset, graph.scroll_offset, visible_node.size, graph.size])
			_assert(visible_node.draggable, "Every supplied gate and external terminal must be movable: %s." % component_id)
	var port_icon: Texture2D = main.theme.get_icon("port", "GraphNode")
	_assert(port_icon != null and port_icon.get_size().x >= 24.0, "Connection ports must use a generous procedural hit icon.")
	var compact_gate_size: Vector2 = (nodes[&"AND_1"] as GraphNode).size
	_assert(compact_gate_size.x <= 170.0 and compact_gate_size.y <= 115.0, "Basic gates must stay compact instead of occupying large cards; actual=%s." % compact_gate_size)
	_assert(symbols.has(&"AND_1") and StringName(symbols[&"AND_1"].get("component_kind")) == &"and", "AND must be a procedural schematic symbol instead of a text-filled gate card.")
	_assert(symbols.has(&"OR_1") and StringName(symbols[&"OR_1"].get("component_kind")) == &"or", "OR must be a distinct procedural schematic symbol.")
	_assert(symbols.has(&"NOT_1") and StringName(symbols[&"NOT_1"].get("component_kind")) == &"not", "NOT must use the triangle-and-inversion-bubble schematic symbol.")
	_assert((symbols[&"AND_1"] as CircuitComponentSymbol).gate_label() == "and", "The AND symbol must visibly carry its English name.")
	_assert((symbols[&"OR_1"] as CircuitComponentSymbol).gate_label() == "or", "The OR symbol must visibly carry its English name.")
	_assert((symbols[&"NOT_1"] as CircuitComponentSymbol).gate_label() == "not", "The NOT symbol must visibly carry its English name.")
	var and_node: GraphNode = nodes[&"AND_1"]
	var and_panel: StyleBoxFlat = and_node.get_theme_stylebox("panel") as StyleBoxFlat
	var and_selected_panel: StyleBoxFlat = and_node.get_theme_stylebox("panel_selected") as StyleBoxFlat
	_assert(
		and_panel != null and and_panel.bg_color.a <= 0.001 and and_panel.border_width_left == 0
		and and_selected_panel != null and and_selected_panel.bg_color.a <= 0.001 and and_selected_panel.border_width_left == 0,
		"GraphNode must remain only an invisible interaction carrier; normal and selected components must not draw an outer card."
	)
	_assert(
		and_node.get_input_port_position(0).y < and_node.get_output_port_position(0).y
		and and_node.get_output_port_position(0).y < and_node.get_input_port_position(1).y,
		"A two-input gate's output must be centered between its schematic input pins."
	)
	_assert((nodes[&"A_IN"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")), "The default low Test Bench source must be red.")
	_assert((nodes[&"AND_1"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("ff6b7d")), "An unconnected input port must default to red/low.")
	_assert((nodes[&"AND_1"] as GraphNode).get_input_port_color(1).is_equal_approx(Color("ff6b7d")), "Every unconnected AND input must independently default low.")
	_assert((nodes[&"AND_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")), "AND with two default-low inputs must continuously expose a low output.")
	_assert((nodes[&"OR_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")), "OR with two default-low inputs must continuously expose a low output.")
	_assert((nodes[&"NOT_1"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("ff6b7d")) and (nodes[&"NOT_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("67e8a5")), "NOT must invert its unconnected default-low input to a live high output.")
	var fixed_source_symbol_color: Color = (symbols[&"A_IN"] as CircuitComponentSymbol).symbol_color()
	var idle_analysis_count: int = int(main.get("live_analysis_count"))
	for _idle_frame: int in range(3):
		await process_frame
	_assert(int(main.get("live_analysis_count")) == idle_analysis_count, "Live port analysis must be event-driven and must not run every frame while the circuit is unchanged.")

	_shift_drag_select(graph, Vector2(600.0, 35.0), Vector2(790.0, 430.0))
	await process_frame
	_assert((nodes[&"AND_1"] as GraphNode).selected and (nodes[&"OR_1"] as GraphNode).selected, "Shift-drag must toggle every component/wire node inside its selection rectangle.")
	_assert(bool((symbols[&"AND_1"] as CircuitComponentSymbol).get("selection_active")), "Selected schematic symbols must show non-rectangular selection feedback.")
	_shift_click_component(main, &"A_IN")
	_assert((nodes[&"A_IN"] as GraphNode).selected, "Shift-click must add or remove one component without clearing the existing group.")
	_connect(main, &"AND_1", 0, &"OR_1", 0)
	_shortcut(main, KEY_C)
	_assert((main.get("clipboard_components") as Array).size() == 2 and (main.get("clipboard_wires") as Array).size() == 1, "Ctrl+C must copy selected player gates and internal wires while excluding the selected Test Bench terminal.")
	_shortcut(main, KEY_V)
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).size() == 8 and graph.get_connection_list().size() == 2, "Ctrl+V must paste the selected two-gate subgraph and its one internal wire as one action.")
	_assert((main.get("component_catalog") as Dictionary).values().filter(func(component: Variant) -> bool: return bool(component.get("fixed_terminal"))).size() == 3, "Pasting must not duplicate Test Bench signal identities.")
	_shortcut(main, KEY_Z)
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).size() == 6 and graph.get_connection_list().size() == 1, "Ctrl+Z must atomically remove an entire pasted subgraph.")
	_shortcut(main, KEY_Y)
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).size() == 8 and graph.get_connection_list().size() == 2, "Ctrl+Y must restore an undone pasted subgraph with the same internal topology.")
	_shortcut(main, KEY_Z)
	_shortcut(main, KEY_Z, true)
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).size() == 8 and graph.get_connection_list().size() == 2, "Ctrl+Shift+Z must remain a redo alias compatible with Turing Complete.")
	_shortcut(main, KEY_Z)
	_shortcut(main, KEY_Z)
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).size() == 6 and graph.get_connection_list().is_empty(), "Undoing paste and the preceding connection must restore the pristine graph.")
	var group_ids: Array[StringName] = [&"AND_1", &"OR_1"]
	main.call("_set_selected_ids", group_ids)
	var and_before_group_move: Vector2 = (nodes[&"AND_1"] as GraphNode).position_offset
	var or_before_group_move: Vector2 = (nodes[&"OR_1"] as GraphNode).position_offset
	main.call("_on_begin_node_move")
	(nodes[&"AND_1"] as GraphNode).position_offset += Vector2(35.0, 20.0)
	(nodes[&"OR_1"] as GraphNode).position_offset += Vector2(35.0, 20.0)
	main.call("_on_end_node_move")
	_shortcut(main, KEY_Z)
	_assert((nodes[&"AND_1"] as GraphNode).position_offset.is_equal_approx(and_before_group_move) and (nodes[&"OR_1"] as GraphNode).position_offset.is_equal_approx(or_before_group_move), "Ctrl+Z must restore every member of one multi-node movement transaction.")
	_shortcut(main, KEY_Y)
	_assert(not (nodes[&"AND_1"] as GraphNode).position_offset.is_equal_approx(and_before_group_move), "Ctrl+Y must reapply a multi-node movement transaction.")
	_shortcut(main, KEY_Z)
	_connect(main, &"A_IN", 0, &"NOT_1", 0)
	_shortcut(main, KEY_Y)
	_assert(graph.get_connection_list().size() == 1, "A new edit after Undo must clear the redo branch.")
	_connect(main, &"NOT_1", 0, &"LAMP", 0)
	await process_frame
	_assert(graph.get_connection_list().size() == 2, "Tutorial connection requests must change the visible and simulated topology.")
	main.call("_clear_wires")
	_shortcut(main, KEY_Z)
	_assert(graph.get_connection_list().size() == 2, "Ctrl+Z must restore Clear Wires as one complete transaction.")
	_shortcut(main, KEY_Y)
	_assert(graph.get_connection_list().is_empty(), "Ctrl+Y must reapply Clear Wires without leaving orphan wire nodes.")
	_shortcut(main, KEY_Z)
	await process_frame
	_assert(graph.get_connection_list().size() == 2, "A second Undo must restore the graph after redoing Clear Wires.")
	_assert((nodes[&"NOT_1"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("ff6b7d")), "A live low input must turn its receiving port red before Run is pressed.")
	_assert((nodes[&"NOT_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("67e8a5")), "NOT must continuously compute a green/high output from its live low input.")
	_assert((nodes[&"LAMP"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("67e8a5")), "The observer input must continuously show the propagated high state.")
	var input_a: CheckButton = main.get("input_a_button")
	input_a.button_pressed = true
	await process_frame
	_assert((nodes[&"NOT_1"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("67e8a5")), "Changing Test Bench A must update the receiving input port to green without running the trace.")
	_assert((nodes[&"NOT_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")), "NOT must update its output to red immediately after A becomes high.")
	_assert((nodes[&"LAMP"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("ff6b7d")), "The live low result must reach the lamp input before trace playback.")
	main.call("_run_debug")
	var tutorial_trace: CircuitTrace = main.get("current_trace")
	_assert(tutorial_trace != null and tutorial_trace.is_valid() and tutorial_trace.outputs.get(&"LAMP") == false, "A=1 through NOT must produce a valid dark lamp trace.")
	_assert(int(tutorial_trace.metrics["propagation_ticks"]) == 1, "Tutorial wire geometry must add no delay beyond the NOT gate tick.")
	main.call("_apply_trace_signal_states", tutorial_trace)
	_assert((nodes[&"A_IN"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("67e8a5")), "A known high source and its outgoing pin must be green.")
	_assert((nodes[&"B_IN"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")), "An unused but known-low external Test Bench source must still be red.")
	_assert((nodes[&"NOT_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")), "A known low gate output and wire source must be red.")
	_assert((nodes[&"NOT_1"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("67e8a5")), "Every receiving input port must retain its live high/green state during playback.")
	_assert((nodes[&"LAMP"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("ff6b7d")), "The lamp input port must retain its live low/red state during playback.")
	_assert((symbols[&"A_IN"] as CircuitComponentSymbol).symbol_color().is_equal_approx(fixed_source_symbol_color), "Changing A must not recolor the source symbol itself.")
	_assert((symbols[&"LAMP"] as CircuitComponentSymbol).symbol_color().is_equal_approx(fixed_source_symbol_color), "Input and output component bodies must share the same fixed schematic color.")
	var high_wire_state: Dictionary = graph.get_connection_signal_value(&"A_IN", 0, &"NOT_1", 0)
	var low_wire_state: Dictionary = graph.get_connection_signal_value(&"NOT_1", 0, &"LAMP", 0)
	_assert(bool(high_wire_state.get("known", false)) and bool(high_wire_state.get("value", false)), "The full A-to-NOT wire must retain the high signal together with its green destination port.")
	_assert(bool(low_wire_state.get("known", false)) and not bool(low_wire_state.get("value", true)), "The full NOT-to-lamp wire must retain the low signal together with its red destination port.")

	var wire_event: CircuitEvent = _first_event(tutorial_trace, &"wire_signal")
	var displayed_path: PackedVector2Array = main.call("_connection_curve", wire_event.from_component, wire_event.from_port, wire_event.to_component, wire_event.to_port)
	var source: GraphNode = nodes[wire_event.from_component]
	var target: GraphNode = nodes[wire_event.to_component]
	var exact_curve: PackedVector2Array = graph.get_connection_line(
		source.position + source.get_output_port_position(wire_event.from_port),
		target.position + target.get_input_port_position(wire_event.to_port)
	)
	_assert(_paths_equal(displayed_path, exact_curve), "Signal playback must use the exact currently rendered connection curve.")
	main.call("_show_circuit_event", wire_event, 0.5)
	_assert((main.get("active_components") as Array).is_empty(), "A direct wire wave must not falsely activate non-routing endpoint components before processing.")
	var overlay: Control = main.get("trace_overlay")
	var single_wire_pulses: Array = overlay.get("wire_pulses")
	_assert(StringName(overlay.get("mode")) == &"parallel" and single_wire_pulses.size() == 1 and _paths_equal(single_wire_pulses[0]["path"], exact_curve), "Trace overlay must receive the exact wire path inside a parallel batch.")
	var not_event: CircuitEvent = _component_event(tutorial_trace, &"NOT_1")
	main.call("_show_circuit_event", not_event, 0.5)
	var single_component_pulses: Array = overlay.get("component_pulses")
	_assert((main.get("active_components") as Array).has(&"NOT_1") and single_component_pulses.size() == 1 and StringName(single_component_pulses[0]["kind"]) == &"not", "NOT processing must own a distinct component animation inside its parallel wave.")

	var input_b: CheckButton = main.get("input_b_button")
	_connect(main, &"B_IN", 0, &"LAMP", 0)
	await process_frame
	var shared_state: CircuitLiveStateType = main.get("live_state")
	_assert(graph.get_connection_list().size() == 3, "One input port must visibly accept more than one distinct wire.")
	_assert(shared_state.is_valid() and shared_state.input_state(&"LAMP", 0) == LogicSignalType.LOW, "Two low drivers on one port must resolve safely to low instead of being rejected.")
	input_b.button_pressed = true
	await process_frame
	shared_state = main.get("live_state")
	_assert(shared_state.shorted_inputs.has("LAMP:i0") and shared_state.input_state(&"LAMP", 0) == LogicSignalType.CONFLICT, "Opposing low/high drivers on one port must produce a live short-circuit state.")
	_assert((nodes[&"LAMP"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("8b929d")), "A conflicted port must use the gray unresolved presentation while diagnostics explain the short circuit.")
	_assert((main.get("diagnostics_label") as Label).text.contains("短路"), "The live Chinese diagnostic must explicitly name a visible short circuit.")
	input_b.button_pressed = false
	await process_frame
	_assert((main.get("live_state") as CircuitLiveStateType).is_valid(), "Removing the opposing value must clear the short circuit without rewiring the shared port.")
	main.call("_undo_wire")
	await process_frame
	_assert(graph.get_connection_list().size() == 2, "Undo must remove only the most recent segment from a multi-wire input port.")

	var analyses_before_cycle: int = int(main.get("live_analysis_count"))
	_connect(main, &"AND_1", 0, &"OR_1", 0)
	_connect(main, &"OR_1", 0, &"AND_1", 0)
	_assert(int(main.get("live_analysis_count")) == analyses_before_cycle, "Multiple topology edits in one frame must coalesce before live analysis runs.")
	await process_frame
	var cycle_state: CircuitLiveStateType = main.get("live_state")
	_assert(int(main.get("live_analysis_count")) == analyses_before_cycle + 1, "One frame of coalesced topology edits must trigger exactly one live analysis pass.")
	_assert(cycle_state.cyclic_components.has(&"AND_1") and cycle_state.cyclic_components.has(&"OR_1"), "A visible same-tick gate feedback loop must be reported as a circular dependency.")
	_assert((main.get("diagnostics_label") as Label).text.contains("循环依赖"), "The live Chinese diagnostic must explicitly name the visible circular dependency.")
	var stable_analysis_count: int = int(main.get("live_analysis_count"))
	for _stable_frame: int in range(3):
		await process_frame
	_assert(int(main.get("live_analysis_count")) == stable_analysis_count, "Cycle diagnostics must remain cached instead of recomputing every frame.")
	main.call("_undo_wire")
	await process_frame
	main.call("_undo_wire")
	await process_frame
	_assert(graph.get_connection_list().size() == 2 and (main.get("live_state") as CircuitLiveStateType).is_valid(), "Undoing both feedback segments must clear the live circular dependency.")

	_right_click_wire(graph, exact_curve[exact_curve.size() / 2])
	await process_frame
	_assert(graph.get_connection_list().size() == 1 and _find_connection(graph, &"A_IN", 0, &"NOT_1", 0).is_empty(), "Right-clicking a rendered wire must delete exactly that segment from the visible topology.")
	main.call("_undo_wire")
	await process_frame
	_assert(graph.get_connection_list().size() == 2 and not _find_connection(graph, &"A_IN", 0, &"NOT_1", 0).is_empty(), "Undo must restore a wire removed by direct right-click.")

	var topology_before_move: String = main.call("_circuit_from_graph").canonical_signature()
	var path_before_move: PackedVector2Array = main.call("_connection_curve", &"A_IN", 0, &"NOT_1", 0)
	(nodes[&"A_IN"] as GraphNode).position_offset += Vector2(0.0, 90.0)
	await process_frame
	var path_after_move: PackedVector2Array = main.call("_connection_curve", &"A_IN", 0, &"NOT_1", 0)
	_assert(not _paths_equal(path_before_move, path_after_move), "Moving a Test Bench input must immediately reshape its displayed cable.")
	_assert(main.call("_circuit_from_graph").canonical_signature() == topology_before_move, "Moving terminals must not change topology, values, or simulation timing.")
	main.call("_auto_layout")
	await process_frame

	var connected_input_position: Vector2 = (nodes[&"NOT_1"] as GraphNode).position + (nodes[&"NOT_1"] as GraphNode).get_input_port_position(0)
	_left_press_port(graph, connected_input_position, false)
	_assert((graph.get("endpoint_candidate") as Dictionary).is_empty(), "Plain left-click must not detach or move an already-connected wire end.")
	_shift_move_endpoint(graph, nodes[&"NOT_1"], 0, nodes[&"OR_1"], 0)
	await process_frame
	_assert(_find_connection(graph, &"A_IN", 0, &"NOT_1", 0).is_empty() and not _find_connection(graph, &"A_IN", 0, &"OR_1", 0).is_empty(), "Shift + left-drag on a connected input must atomically move that wire end.")
	main.call("_undo_wire")
	await process_frame
	_assert(not _find_connection(graph, &"A_IN", 0, &"NOT_1", 0).is_empty() and _find_connection(graph, &"A_IN", 0, &"OR_1", 0).is_empty(), "Undo must restore the endpoint moved with Shift.")
	_connect(main, &"B_IN", 0, &"OR_1", 0)
	await process_frame
	var b_wire_path: PackedVector2Array = main.call("_connection_curve", &"B_IN", 0, &"OR_1", 0)
	var b_wire_midpoint: Vector2 = b_wire_path[b_wire_path.size() / 2]
	_assert(not graph.get_closest_connection_at_point(b_wire_midpoint, 36.0).is_empty(), "The endpoint-move target wire must be hittable at its exact rendered path.")
	_shift_move_endpoint_to_position(graph, nodes[&"NOT_1"], 0, b_wire_midpoint)
	await process_frame
	_assert(
		_routing_node_count(main) == 1 and graph.get_connection_list().size() == 4,
		"Shift-moving a connected input onto an existing wire must create one explicit branch junction transaction; routes=%d wires=%d status=%s." % [
			_routing_node_count(main), graph.get_connection_list().size(), (main.get("status_label") as Label).text,
		]
	)
	main.call("_undo_wire")
	await process_frame
	_assert(_routing_node_count(main) == 0 and graph.get_connection_list().size() == 3 and not _find_connection(graph, &"A_IN", 0, &"NOT_1", 0).is_empty(), "Undo must restore both original segments after moving an endpoint onto a wire.")
	main.call("_undo_wire")
	await process_frame
	_assert(graph.get_connection_list().size() == 2, "The temporary target wire must remain a separate undoable connection action.")

	var source_connection: Dictionary = _find_connection(graph, &"A_IN", 0, &"NOT_1", 0)
	var source_path: PackedVector2Array = main.call("_connection_curve", &"A_IN", 0, &"NOT_1", 0)
	var split_position: Vector2 = source_path[source_path.size() / 2]
	_drag_branch_from_wire(graph, split_position, nodes[&"OR_1"], 0)
	await process_frame
	nodes = main.get("component_nodes")
	_assert(graph.get_connection_list().size() == 4 and _routing_node_count(main) == 1, "Dragging from a rendered wire to a free input must atomically replace it with a trunk and two outgoing segments.")
	var junction_node: GraphNode = _first_routing_node(main)
	_assert(junction_node != null and junction_node.draggable and junction_node.size.x < 100.0, "A branch point must be a small movable wire node, not another large component.")
	main.call("_run_debug")
	var branched_trace: CircuitTrace = main.get("current_trace")
	_assert(branched_trace.outputs.get(&"LAMP") == false and int(branched_trace.metrics["propagation_ticks"]) == 1, "Inserting and moving zero-delay branch nodes must preserve circuit behavior and delay.")
	var branch_wire_batch: Dictionary = _batch_with_wire_count(main.get("playback_batches"), 3)
	_assert(not branch_wire_batch.is_empty(), "All segments in the zero-delay branched net must share one playback wave.")
	main.call("_show_playback_batch", branch_wire_batch, 0.5)
	var branch_pulses: Array = overlay.get("wire_pulses")
	_assert((main.get("active_connections") as Array).size() == 3 and branch_pulses.size() == 3, "Every active branch segment must animate simultaneously instead of serially.")
	_assert(_batch_paths_match(main, branch_wire_batch, branch_pulses), "Every parallel branch pulse must follow its exact currently rendered segment.")
	main.call("_undo_wire")
	await process_frame
	nodes = main.get("component_nodes")
	_assert(graph.get_connection_list().size() == 2 and _routing_node_count(main) == 0 and not _find_connection(graph, &"A_IN", 0, &"NOT_1", 0).is_empty(), "One Undo must restore the complete pre-branch wire transaction.")

	source_path = main.call("_connection_curve", &"A_IN", 0, &"NOT_1", 0)
	split_position = source_path[source_path.size() / 2]
	_drag_branch_from_wire_to_empty(graph, split_position, Vector2(860.0, 690.0))
	await process_frame
	_assert(graph.get_connection_list().size() == 4 and _routing_node_count(main) == 2, "Dragging an existing wire into empty space must create a split node and a freely movable branch endpoint.")
	main.call("_undo_wire")
	await process_frame
	_assert(graph.get_connection_list().size() == 2 and _routing_node_count(main) == 0, "One Undo must remove the entire free-branch transaction and restore the original segment.")

	main.call("_on_connection_from_empty", &"OR_1", 0, Vector2(930.0, 690.0))
	await process_frame
	_assert(graph.get_connection_list().size() == 3 and _routing_node_count(main) == 1, "Dragging an unconnected input into empty space must create a backward-routable wire endpoint.")
	main.call("_undo_wire")
	await process_frame
	_assert(graph.get_connection_list().size() == 2 and _routing_node_count(main) == 0, "Undo must remove a backward input waypoint without disturbing other wires.")
	main.call("_on_connection_to_empty", &"B_IN", 0, Vector2(820.0, 700.0))
	await process_frame
	nodes = main.get("component_nodes")
	_assert(_routing_node_count(main) == 1 and graph.get_connection_list().size() == 3, "Releasing an output in empty space must create a movable endpoint for a multi-segment cable.")
	main.call("_undo_wire")
	await process_frame
	_assert(_routing_node_count(main) == 0 and graph.get_connection_list().size() == 2, "Undo must remove an unfinished wire node and its segment together.")

	_right_click_component(main, &"NOT_1")
	await process_frame
	_assert(not (main.get("component_nodes") as Dictionary).has(&"NOT_1") and graph.get_connection_list().is_empty(), "Right-clicking a player gate must delete that component and only its incident segments.")
	main.call("_undo_wire")
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).has(&"NOT_1") and graph.get_connection_list().size() == 2, "Undo must restore a gate and its incident segments after right-click deletion.")
	_right_click_component(main, &"A_IN")
	await process_frame
	_assert(not (main.get("component_nodes") as Dictionary).has(&"A_IN"), "Right-click erase must include external Test Bench terminals when the player sweeps across every component.")
	main.call("_undo_wire")
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).has(&"A_IN"), "Undo must restore an erased external Test Bench terminal.")

	var fast_erase_curve: PackedVector2Array = main.call("_connection_curve", &"NOT_1", 0, &"LAMP", 0)
	var precision_segment: int = mini(fast_erase_curve.size() - 2, fast_erase_curve.size() / 2)
	var precision_start: Vector2 = fast_erase_curve[precision_segment]
	var precision_end: Vector2 = fast_erase_curve[precision_segment + 1]
	var precision_midpoint: Vector2 = (precision_start + precision_end) * 0.5
	var precision_tangent: Vector2 = precision_start.direction_to(precision_end)
	var precision_normal := Vector2(-precision_tangent.y, precision_tangent.x)
	_right_click_wire(graph, precision_midpoint + precision_normal * 10.0)
	await process_frame
	_assert(not _find_connection(graph, &"NOT_1", 0, &"LAMP", 0).is_empty(), "Right erase must not delete a wire when only nearby empty space, ten pixels from its center line, is touched.")
	_right_click_wire(graph, precision_midpoint)
	await process_frame
	_assert(_find_connection(graph, &"NOT_1", 0, &"LAMP", 0).is_empty(), "The cursor tip must still delete a wire when it directly touches the rendered line.")
	main.call("_undo_wire")
	await process_frame
	_assert(not _find_connection(graph, &"NOT_1", 0, &"LAMP", 0).is_empty(), "Undo must restore a wire removed by a precise cursor-tip click.")

	fast_erase_curve = main.call("_connection_curve", &"NOT_1", 0, &"LAMP", 0)
	var fast_erase_midpoint: Vector2 = fast_erase_curve[fast_erase_curve.size() / 2]
	_right_drag_erase(graph, [fast_erase_midpoint + Vector2(0.0, -90.0), fast_erase_midpoint + Vector2(0.0, 90.0)])
	await process_frame
	_assert(_find_connection(graph, &"NOT_1", 0, &"LAMP", 0).is_empty(), "One fast right-button motion must sample the path between events and cannot skip a thin crossed wire.")
	main.call("_undo_wire")
	await process_frame
	_assert(graph.get_connection_list().size() == 2 and not _find_connection(graph, &"NOT_1", 0, &"LAMP", 0).is_empty(), "Undo must restore a wire removed by a fast continuous erase stroke.")

	nodes = main.get("component_nodes")
	var topology_before_erase_stroke: String = main.call("_circuit_from_graph").canonical_signature()
	var component_count_before_erase_stroke: int = nodes.size()
	var erase_a: Vector2 = (nodes[&"A_IN"] as GraphNode).position + (nodes[&"A_IN"] as GraphNode).size * 0.5
	var erase_not: Vector2 = (nodes[&"NOT_1"] as GraphNode).position + (nodes[&"NOT_1"] as GraphNode).size * 0.5
	var erase_lamp: Vector2 = (nodes[&"LAMP"] as GraphNode).position + (nodes[&"LAMP"] as GraphNode).size * 0.5
	_right_drag_erase(graph, [erase_a, erase_not, erase_lamp])
	await process_frame
	nodes = main.get("component_nodes")
	_assert(not nodes.has(&"A_IN") and not nodes.has(&"NOT_1") and not nodes.has(&"LAMP"), "One held-right sweep must erase every fixed terminal and component crossed by its sampled path.")
	_assert(graph.get_connection_list().is_empty(), "A continuous erase stroke must also remove every crossed or incident wire.")
	main.call("_undo_wire")
	await process_frame
	nodes = main.get("component_nodes")
	_assert(nodes.size() == component_count_before_erase_stroke and main.call("_circuit_from_graph").canonical_signature() == topology_before_erase_stroke, "One Undo must atomically restore every component and wire removed by one right-button stroke.")

	main.call("_on_disconnection_request", &"NOT_1", 0, &"LAMP", 0)
	_connect(main, &"NOT_1", 0, &"LAMP", 0)
	await process_frame
	var tutorial_next: Button = main.get("tutorial_next_button")
	_assert(not tutorial_next.disabled, "Create, input-change, run, remove, and reconnect must complete the compact tutorial.")
	_assert(bool((main.get("completed_levels") as Dictionary).get(&"tutorial", false)), "The five tutorial interactions must record the prerequisite completion immediately.")
	tutorial_next.pressed.emit()
	await process_frame
	_assert(StringName(main.get("current_phase")) == &"half_adder", "The real tutorial completion button must open Half Adder without freeing its locked signal emitter.")
	_assert(not is_instance_valid(tutorial_next), "The clicked tutorial completion button must be released safely at frame end.")

	main.call("_open_campaign_map")
	await process_frame
	campaign_buttons = main.get("campaign_level_buttons")
	_assert(not (campaign_buttons[&"half_adder"] as Button).disabled, "Completing the tutorial must unlock Half Adder on the visible level map.")
	_assert((campaign_buttons[&"full_adder"] as Button).disabled, "Completing only the tutorial must not skip the Half Adder prerequisite for Full Adder.")
	var half_adder_map_button: Button = campaign_buttons[&"half_adder"]
	half_adder_map_button.pressed.emit()
	await process_frame
	_assert(not is_instance_valid(half_adder_map_button), "The clicked Half Adder map button must be released without a locked-object error.")
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	overlay = main.get("trace_overlay")
	_assert(StringName(main.get("current_phase")) == &"half_adder", "Tutorial completion must open the Half Adder challenge.")
	_assert(graph.get_connection_list().is_empty(), "Half Adder challenge must not reveal a prewired solution template.")
	_assert(nodes.size() == 11 and nodes.has(&"SUM_OUT") and nodes.has(&"CARRY_OUT"), "Challenge must provide fixed Test Bench terminals and a spare-gate inventory.")
	_assert((nodes[&"SUM_OUT"] as GraphNode).draggable and (nodes[&"CARRY_OUT"] as GraphNode).draggable, "Half Adder output terminals must be freely movable like desktop schematic parts.")
	_assert(not nodes.has(&"Profiler"), "Early logic section must not introduce the performance Profiler.")
	_assert((main.get("live_state") as CircuitLiveStateType).is_valid(), "A fresh unwired Half Adder must be a valid incomplete design, not a simulator error.")
	_assert((main.get("diagnostics_label") as Label).text.contains("这不是故障"), "The initial Half Adder diagnostic must explicitly distinguish an unwired design from a fault.")

	main.call("_run_official")
	_assert(not bool(main.get("official_passed")) and (main.get("seal_button") as Button).disabled, "An unwired circuit must fail and keep encapsulation locked.")
	_connect_valid_half_adder(main)
	await process_frame
	_assert(graph.get_connection_list().size() == 9, "The valid player topology must consist of the nine visible wires created by the test.")
	var exported_signature: String = main.call("_circuit_from_graph").canonical_signature()
	main.call("_run_official")
	var report: Dictionary = main.get("official_report")
	_assert(bool(main.get("official_passed")) and bool(report["passed"]), "The displayed valid Half Adder must pass all four official cases.")
	_assert((report["cases"] as Array).size() == 4, "Official UI run must show all four fixed truth-table cases.")
	_assert(String(main.get("passing_topology_signature")) == exported_signature, "Seal eligibility must be tied to the exact exported visual topology.")
	_assert(not (main.get("seal_button") as Button).disabled, "Fresh official success must visibly unlock sealing.")
	var batches: Array = main.get("playback_batches")
	var input_batch: Dictionary = _batch_with_components(batches, [&"A_IN", &"B_IN"])
	var parallel_gate_batch: Dictionary = _batch_with_components(batches, [&"AND_1", &"OR_1"])
	_assert(not input_batch.is_empty() and not parallel_gate_batch.is_empty(), "Inputs and same-depth gates must be represented as parallel playback batches.")
	main.set("playback_running", false)
	main.call("_show_playback_batch", parallel_gate_batch, 0.5)
	await process_frame
	var active_parallel: Array = main.get("active_components")
	var parallel_component_pulses: Array = overlay.get("component_pulses")
	_assert(active_parallel.has(&"AND_1") and active_parallel.has(&"OR_1") and parallel_component_pulses.size() == 2, "AND and OR that are ready together must visibly process together.")
	var and_event: CircuitEvent = _component_event((report["cases"] as Array)[3]["trace"], &"AND_1")
	var downstream_not_event: CircuitEvent = _component_event((report["cases"] as Array)[3]["trace"], &"NOT_1")
	_assert(and_event.visual_step < downstream_not_event.visual_step, "A downstream gate must remain causally later even while independent gates animate in parallel.")

	main.call("_on_disconnection_request", &"AND_2", 0, &"SUM_OUT", 0)
	_assert(not bool(main.get("official_passed")) and (main.get("seal_button") as Button).disabled, "Any topology edit must invalidate stale official evidence.")
	_connect(main, &"AND_2", 0, &"SUM_OUT", 0)
	main.call("_run_official")
	_assert(bool(main.get("official_passed")), "Reconnected valid topology must pass after a fresh official run.")
	main.call("_seal_half_adder")
	_assert(main.get("sealed_half_adder") != null and bool(main.get("sealing")), "Seal action must immediately snapshot the verified player circuit and start the visual effect.")
	main.call("_finish_encapsulation")
	await process_frame
	_assert(StringName(main.get("current_phase")) == &"sealed", "Encapsulation must end on the reusable component view.")
	nodes = main.get("component_nodes")
	_assert(nodes.has(&"HalfAdder") and nodes.size() == 1, "The verified low-level graph must visibly collapse into one owned HalfAdder component.")
	var sealed = main.get("sealed_half_adder")
	var sealed_trace: CircuitTrace = sealed.evaluate(true, true)
	_assert(sealed_trace.outputs.get(&"SUM") == false and sealed_trace.outputs.get(&"CARRY") == true, "The reusable HalfAdder view must preserve the sealed circuit's behavior.")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: default-low live ports, editor shortcuts/multi-selection, multi-wire diagnostics, parallel trace, Half Adder, and sealing UI tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d Hardware Foundations UI assertion(s) failed" % failures.size())
		quit(1)


func _connect_valid_half_adder(main: Control) -> void:
	for wire: Array in [
		[&"A_IN", 0, &"AND_1", 0], [&"B_IN", 0, &"AND_1", 1],
		[&"A_IN", 0, &"OR_1", 0], [&"B_IN", 0, &"OR_1", 1],
		[&"AND_1", 0, &"NOT_1", 0],
		[&"OR_1", 0, &"AND_2", 0], [&"NOT_1", 0, &"AND_2", 1],
		[&"AND_2", 0, &"SUM_OUT", 0], [&"AND_1", 0, &"CARRY_OUT", 0],
	]:
		_connect(main, wire[0], wire[1], wire[2], wire[3])


func _connect(main: Control, from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	main.call("_on_connection_request", from_node, from_port, to_node, to_port)


func _shortcut(main: Control, keycode: Key, shifted: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.ctrl_pressed = true
	event.shift_pressed = shifted
	main.call("_input", event)


func _shift_click_component(main: Control, component_id: StringName) -> void:
	var node: GraphNode = (main.get("component_nodes") as Dictionary)[component_id]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	click.shift_pressed = true
	click.position = node.size * 0.5
	main.call("_on_component_gui_input", click, component_id)


func _shift_drag_select(graph: GraphEdit, start: Vector2, finish: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.shift_pressed = true
	press.position = start
	graph.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.shift_pressed = true
	motion.position = finish
	graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.shift_pressed = true
	release.position = finish
	graph.call("_gui_input", release)


func _first_event(trace: CircuitTrace, kind: StringName) -> CircuitEvent:
	for event: CircuitEvent in trace.events:
		if event.kind == kind:
			return event
	return null


func _component_event(trace: CircuitTrace, component_id: StringName) -> CircuitEvent:
	for event: CircuitEvent in trace.events:
		if event.kind == &"component_process" and event.component_id == component_id:
			return event
	return null


func _find_connection(
		graph: GraphEdit,
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
	) -> Dictionary:
	for connection: Dictionary in graph.get_connection_list():
		if connection["from_node"] == from_node and int(connection["from_port"]) == from_port and connection["to_node"] == to_node and int(connection["to_port"]) == to_port:
			return connection
	return {}


func _drag_branch_from_wire(graph: GraphEdit, split_position: Vector2, target: GraphNode, target_port: int) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = split_position
	graph.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = target.position + target.get_input_port_position(target_port)
	graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.button_mask = 0
	release.pressed = false
	release.position = motion.position
	graph.call("_gui_input", release)


func _drag_branch_from_wire_to_empty(graph: GraphEdit, split_position: Vector2, release_position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = split_position
	graph.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = release_position
	graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = release_position
	graph.call("_gui_input", release)


func _right_click_wire(graph: GraphEdit, position: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.position = position
	graph.call("_gui_input", click)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = position
	graph.call("_gui_input", release)


func _right_click_component(main: Control, component_id: StringName) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	main.call("_on_component_gui_input", click, component_id)


func _right_drag_erase(graph: GraphEdit, points: Array[Vector2]) -> void:
	if points.is_empty():
		return
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = points[0]
	graph.call("_gui_input", press)
	for index: int in range(1, points.size()):
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
		motion.position = points[index]
		graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = points[points.size() - 1]
	graph.call("_gui_input", release)


func _left_press_port(graph: GraphEdit, position: Vector2, shifted: bool) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.shift_pressed = shifted
	press.position = position
	graph.call("_gui_input", press)


func _shift_move_endpoint(
		graph: GraphEdit,
		from_target: GraphNode,
		from_port: int,
		to_target: GraphNode,
		to_port: int
	) -> void:
	var start: Vector2 = from_target.position + from_target.get_input_port_position(from_port)
	var finish: Vector2 = to_target.position + to_target.get_input_port_position(to_port)
	_shift_move_endpoint_from_to(graph, start, finish)


func _shift_move_endpoint_to_position(
		graph: GraphEdit,
		from_target: GraphNode,
		from_port: int,
		finish: Vector2
	) -> void:
	var start: Vector2 = from_target.position + from_target.get_input_port_position(from_port)
	_shift_move_endpoint_from_to(graph, start, finish)


func _shift_move_endpoint_from_to(graph: GraphEdit, start: Vector2, finish: Vector2) -> void:
	_left_press_port(graph, start, true)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.shift_pressed = true
	motion.position = finish
	graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.shift_pressed = true
	release.position = finish
	graph.call("_gui_input", release)


func _routing_node_count(main: Control) -> int:
	var count: int = 0
	for component: Variant in (main.get("component_catalog") as Dictionary).values():
		if StringName(component.get("kind")) == &"junction":
			count += 1
	return count


func _first_routing_node(main: Control) -> GraphNode:
	var catalog: Dictionary = main.get("component_catalog")
	var nodes: Dictionary = main.get("component_nodes")
	for component_id: StringName in catalog:
		if StringName(catalog[component_id].get("kind")) == &"junction":
			return nodes.get(component_id)
	return null


func _batch_with_wire_count(batches: Array, wire_count: int) -> Dictionary:
	for batch: Dictionary in batches:
		var count: int = 0
		for event: CircuitEvent in batch.get("events", []):
			if event.kind == &"wire_signal":
				count += 1
		if count == wire_count:
			return batch
	return {}


func _batch_with_components(batches: Array, component_ids: Array) -> Dictionary:
	for batch: Dictionary in batches:
		var found: Array[StringName] = []
		for event: CircuitEvent in batch.get("events", []):
			if event.kind == &"component_process":
				found.append(event.component_id)
		var all_found: bool = true
		for component_id: StringName in component_ids:
			all_found = all_found and found.has(component_id)
		if all_found:
			return batch
	return {}


func _batch_paths_match(main: Control, batch: Dictionary, pulses: Array) -> bool:
	var wire_index: int = 0
	for event: CircuitEvent in batch.get("events", []):
		if event.kind != &"wire_signal":
			continue
		if wire_index >= pulses.size():
			return false
		var expected: PackedVector2Array = main.call("_connection_curve", event.from_component, event.from_port, event.to_component, event.to_port)
		if not _paths_equal(pulses[wire_index]["path"], expected):
			return false
		wire_index += 1
	return wire_index == pulses.size()


func _paths_equal(left: PackedVector2Array, right: PackedVector2Array) -> bool:
	if left.size() != right.size():
		return false
	for index: int in range(left.size()):
		if not left[index].is_equal_approx(right[index]):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
