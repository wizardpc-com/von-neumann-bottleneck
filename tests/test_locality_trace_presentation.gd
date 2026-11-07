extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	var main = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for level: StringName in [&"distant_reads", &"nearby_storage", &"cache_failure"]:
		main._start_level(level)
		if level == &"nearby_storage": main._select_cache(1, false)
		for frame: int in 4: await process_frame
		check(not main.trace_progress.visible and not main.pause_button.visible, "Pending replay has no empty progress bar or unavailable controls.")
		main.instrument_open_buttons[&"test_bench"].pressed.emit()
		for frame: int in 4: await process_frame
		check(main.current_trace != null and main.current_trace.test_name == "Official Test Set" and main.playback_running, "One toolbar press runs the existing formal workload.")
		check(not main.instrument_windows[&"mission"].visible and main.instrument_windows[&"test_bench"].visible, "Results yield the task window.")
		check(main.trace_progress.visible and main.pause_button.visible, "Recorded replay exposes its controls and progress.")
		var band: Vector2 = preload("res://src/ui/instrument_dock.gd").free_band(main.graph.size, main.instrument_windows)
		for node: GraphNode in main.device_nodes.values():
			if not node.visible: continue
			var left: float = node.position_offset.x * main.graph.zoom - main.graph.scroll_offset.x
			check(left >= band.x and left + node.size.x * main.graph.zoom <= band.y, "Every machine node fits the free canvas during replay.")
		check(main.trace_progress.get_global_rect().end.x <= main.terminology_handbook.entry_button.get_global_rect().position.x - 4, "Full replay progress ends before the Handbook button.")
		var window = main.instrument_windows[&"test_bench"]
		var body = window.content_host.get_child(0).get_child(1).get_child(0)
		check(window.size.y <= body.get_combined_minimum_size().y + 110, "Result bench fits its existing content without an empty lower half.")
		main.playback_running = false
		for event in main.current_trace.events:
			main._draw_event(event, 0.5)
			var points: PackedVector2Array = main.trace_overlay.primary_path
			if points.size() < 2: continue
			var caption: Rect2 = main.trace_overlay.caption_rect(points, main._event_short_label(event))
			check(caption.has_area(), "Each authored event has room for its wire caption.")
			for node: GraphNode in main.device_nodes.values():
				if not node.visible: continue
				var node_rect := Rect2(node.global_position - main.trace_overlay.global_position, node.size * main.graph.zoom)
				check(not caption.intersects(node_rect), "Wire caption avoids every node, including CPU, RAM and near storage.")
		var recorded: String = main.current_trace.canonical_signature()
		main._open_instrument(&"mission", true)
		check(main.instrument_windows[&"mission"].visible and not main.instrument_windows[&"test_bench"].visible, "Task returns on demand and yields results.")
		check(main.current_trace.canonical_signature() == recorded, "Window navigation does not change the measured trace.")
	main.session_previous_runs.clear()
	main._start_level(&"access_order")
	await process_frame
	main._open_instrument(&"test_bench")
	main._run_simulation("Official Test Set")
	main.playback_running = false
	var trace = main.current_trace
	var signature: String = trace.canonical_signature()
	check(main.instrument_windows[&"test_bench"].visible, "The official result and evidence controls remain open.")
	check(main.hierarchy_ram_labels.size() == preload("res://src/simulation/simulation_core.gd").OFFICIAL_DATA.size(), "The RAM display follows the modeled data size.")
	main._open_instrument(&"program")
	main._open_instrument(&"profiler")
	await process_frame
	main._frame_machine()
	check(main.graph.zoom >= 0.85, "Additional instruments cannot shrink machine text below the readable floor.")
	var resident: Dictionary = {}
	var duration: float = 0.0
	for event in trace.events:
		duration += main._display_duration_for(event)
		if event.kind == &"cache_evict": resident.erase(event.cache_line)
		if event.kind == &"cache_fill": resident[event.cache_line] = true
		main._draw_event(event, 1.0)
		for block in resident:
			check(main.hierarchy_cache_labels[0].text.begins_with("A[%d]" % (block * preload("res://src/simulation/simulation_core.gd").CACHE_LINE_INTS / preload("res://src/simulation/simulation_core.gd").ARRAY_WIDTH)), "Displayed cache must match the real trace prefix.")
	check(duration < 30.0, "Default access-order replay should take under thirty seconds.")
	check(not main.run_comparison_label.visible, "One run cannot show a comparison.")
	main._load_strategy(preload("res://src/simulation/program_templates.gd").ROW_FIRST, "row-first")
	main._apply_program()
	main._run_simulation("Official Test Set")
	main.playback_running = false
	check(main.run_comparison_label.visible, "Two correct formal runs expose a comparison.")
	check("321" in main.run_comparison_label.text and "105" in main.run_comparison_label.text, "Comparison must retain measured cycles.")
	check("→" in main.run_comparison_label.text and "[color=" in main.run_comparison_label.text, "Comparison uses arrows and signed colored deltas.")
	check(main.session_previous_runs.size() == 1, "Session comparison is keyed by task.")
	for event in main.current_trace.events:
		if event.kind == &"cache_hit":
			main._update_hierarchy(event)
			check(main.hierarchy_cache_labels[0].text.count("[") == 3, "The accessed cache word comes from the recorded event address.")
			check(main.hierarchy_cache_labels[0].get_theme_stylebox("normal").bg_color == Color("26584e"), "A recorded hit flashes the resident line green.")
			break
	main.current_trace.passed = false
	main._update_session_comparison("Official Test Set")
	check(not main.run_comparison_label.visible, "An incorrect run cannot be presented as an improvement.")
	main.current_trace.passed = true
	main._update_session_comparison("Debug Data")
	check(not main.run_comparison_label.visible, "Debug data cannot enter the formal comparison.")
	check(trace.canonical_signature() == signature, "Presentation must leave authoritative events and metrics unchanged.")
	main.workspace_mode = &"game"
	main._update_session_comparison("Official Test Set")
	check(not main.run_comparison_label.visible, "A Test result never supplies the preceding Game result.")
	main._update_session_comparison("Official Test Set")
	check(main.run_comparison_label.visible, "Two runs within the same mode remain comparable.")
	main.current_pass_count = 2
	main._update_session_comparison("Official Test Set")
	check(not main.run_comparison_label.visible, "Different pass counts cannot claim a same-work comparison.")
	main.current_pass_count = 1
	main.workspace_mode = &"test"
	# Seeking backward must not retain final cache contents.
	main.current_trace = trace
	main._update_hierarchy(trace.events[0])
	check(main.hierarchy_cache_labels[0].text == "-", "Seeking to the start resets residency.")
	main._start_level(&"distant_reads")
	main._run_simulation("Official Test Set")
	check(not main.run_comparison_label.visible, "A different task cannot reuse the previous task comparison.")
	main._update_hierarchy(main.current_trace.events.back())
	check(not main.hierarchy_cache_labels[0].visible, "Direct RAM reads must not invent cache residency.")
	root.get_node("GameMode").set_mode(&"game")
	main.current_level_id = &"capstone"
	main.current_level = main.catalog.definition(&"capstone")
	main.selected_judgment = &""
	main.session_previous_runs.clear()
	main._update_session_comparison("Official Test Set")
	main._update_session_comparison("Official Test Set")
	check(not main.run_summary_label.text.contains("RAM") and not main.run_comparison_label.text.contains("RAM"), "Capstone summary and comparison obey the existing diagnosis disclosure boundary.")
	main.queue_free()
	await process_frame
	print(("FAIL: " if failures else "PASS: ") + "Locality presentation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
