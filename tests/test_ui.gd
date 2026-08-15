extends SceneTree

const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_resource: PackedScene = load("res://src/ui/main.tscn")
	var main: Control = scene_resource.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var graph: GraphEdit = main.get("graph")
	_assert(graph != null, "Main UI must create a GraphEdit.")
	_assert(graph.get_connection_list().size() == 6, "Auto Wire must create all six required links.")
	_assert((main.call("_validate_wiring") as Array[String]).is_empty(), "The initial wiring must use every exact required port.")
	for device_name: String in ["ProgramController", "CPU", "Cache", "Bus", "RAM", "TestBench", "Profiler"]:
		_assert(graph.has_node(NodePath(device_name)), "Graph must contain %s." % device_name)
	var cpu_node: GraphNode = graph.get_node("CPU")
	_assert(
		cpu_node.position.x >= 0.0 and cpu_node.position.y >= 0.0 and cpu_node.position.x < graph.size.x and cpu_node.position.y < graph.size.y,
		"CPU must be visible initially (position=%s, offset=%s, graph_size=%s, scroll=%s)." % [cpu_node.position, cpu_node.position_offset, graph.size, graph.scroll_offset]
	)
	var official_button: Button = main.get("official_run_button")
	var debug_button: Button = main.get("debug_run_button")
	var progress_bar: ProgressBar = main.get("trace_progress")
	var viewport_bottom: float = main.get_global_rect().end.y
	_assert(official_button.get_global_rect().end.y <= viewport_bottom + 1.0, "Run Official must be visible at the default 1600×900 size.")
	_assert(debug_button.get_global_rect().end.y <= viewport_bottom + 1.0, "Run Debug must be visible at the default 1600×900 size.")
	_assert(progress_bar.get_global_rect().end.y <= viewport_bottom + 1.0, "Trace progress must be visible at the default 1600×900 size.")

	graph.disconnect_node(&"CPU", 0, &"Cache", 0)
	graph.connect_node(&"CPU", 1, &"Cache", 0)
	var wrong_port_missing: Array[String] = main.call("_validate_wiring")
	_assert("CPU:0>Cache:0" in wrong_port_missing, "Wiring validation must reject a connection on the wrong CPU port.")
	main.call("_auto_wire")
	_assert((main.call("_validate_wiring") as Array[String]).is_empty(), "Auto Wire must restore exact required ports.")

	main.call("_run_simulation", "Official Test Set")
	var column_trace: SimulationTraceType = main.get("current_trace")
	_assert(column_trace != null and column_trace.passed, "Official column-first run must pass correctness.")
	var column_cycles: int = int(column_trace.metrics.get("total_cycles", 0))
	var found_line_return: bool = false
	for event: SimulationEventType in column_trace.events:
		if event.kind == &"line_return":
			var return_path: PackedVector2Array = main.call("_event_path", event)
			_assert(return_path.size() == 3, "A RAM cache-line return must visibly route through Bus.")
			found_line_return = true
			break
	_assert(found_line_return, "Column-first trace must contain cache-line return events.")
	var signature_before_playback: String = column_trace.canonical_signature()
	main.call("_step_trace")
	_assert(progress_bar.value > 0.0, "Step must advance overall trace progress.")
	main.call("_step_trace")
	_assert(signature_before_playback == column_trace.canonical_signature(), "UI Step must not mutate the trace.")
	var debug_inputs: Array[SpinBox] = main.get("debug_inputs")
	debug_inputs[0].value = 99
	await process_frame
	_assert(main.get("current_trace") == column_trace, "Editing Debug Data must not invalidate an Official trace.")
	main.call("_run_simulation", "Debug Data")
	var debug_trace: SimulationTraceType = main.get("current_trace")
	_assert(debug_trace.passed and debug_trace.expected_value == 234, "Run Debug must use editable Debug Data.")
	main.call("_run_simulation", "Official Test Set")
	_assert((main.get("current_trace") as SimulationTraceType).expected_value == 88, "Official Test Set must ignore edited Debug Data.")

	var editor: CodeEdit = main.get("editor")
	main.call("_load_program_template", ProgramTemplatesType.ROW_FIRST)
	await process_frame
	_assert(main.get("current_trace") == null, "Editing the program must clear stale Profiler and trace state.")
	main.call("_run_simulation", "Official Test Set")
	var row_trace: SimulationTraceType = main.get("current_trace")
	_assert(row_trace.passed, "Official row-first run must pass correctness.")
	_assert(int(row_trace.metrics["total_cycles"]) * 2 < column_cycles, "UI should expose the same substantial row-first speedup.")
	var comparison: Label = main.get("comparison_label")
	_assert("321 → 105" in comparison.text, "Profiler must show a same-test, same-Cache baseline comparison.")

	var cache_selector: OptionButton = main.get("cache_selector")
	cache_selector.select(1)
	main.call("_update_cache_display", 1)
	_assert(main.get("current_trace") == null, "Changing Cache capacity must clear stale Profiler and trace state.")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: UI layout, exact wiring, state invalidation, profiler comparison, and playback tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d UI assertion(s) failed" % failures.size())
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
