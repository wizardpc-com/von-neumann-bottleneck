extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func settle() -> void:
	for frame: int in range(12): await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	var ui: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(ui)
	await settle()
	ui._start_campaign_level(&"cpu")
	await settle()
	check(not ui.mission_briefing_active and not ui.desktop_windows[&"task"].visible, "CPU entry leaves the circuit visible and Mission available on demand")
	for id: StringName in [&"test_bench", &"components"]:
		var tool: Control = ui.desktop_windows[id]
		check(tool.visible and tool.minimized and tool.minimizable, "CPU tool opens as a restorable title strip: " + String(id))
	var canvas: Rect2 = ui.graph.get_global_rect()
	for node: GraphNode in ui.component_nodes.values():
		var bounds: Rect2 = node.get_global_rect()
		check(canvas.encloses(bounds), "CPU component stays inside the canvas: " + String(node.name))
		for id: StringName in [&"test_bench", &"components"]:
			check(not bounds.intersects(ui.desktop_windows[id].get_global_rect()), "CPU title strip leaves component unobscured: " + String(node.name))
	ui._show_desktop_window(&"test_bench")
	await settle()
	for node: GraphNode in ui.component_nodes.values():
		check(not node.get_global_rect().intersects(ui.desktop_windows[&"test_bench"].get_global_rect()), "Restored CPU bench leaves the component visible: " + String(node.name))
	check(not ui.desktop_windows[&"test_bench"].minimized, "Taskbar restores the complete Test Bench")
	ui.graph.zoom *= 0.9
	ui.graph.scroll_offset += Vector2(55.0, 25.0)
	await settle()
	var manual_zoom: float = ui.graph.zoom
	var manual_scroll: Vector2 = ui.graph.scroll_offset
	ui.desktop_windows[&"test_bench"].set_minimized(true)
	await settle()
	check(is_equal_approx(ui.graph.zoom, manual_zoom) and ui.graph.scroll_offset.is_equal_approx(manual_scroll), "CPU tool folding preserves the player's adjusted view")
	ui._reopen_mission()
	check(ui.mission_briefing_active and ui.desktop_windows[&"task"].visible, "Mission reopens its full staged specification")
	ui._start_campaign_level(&"full_adder")
	await settle()
	check(ui.desktop_windows[&"components"].visible and not ui.desktop_windows[&"components"].minimized, "Next task restores its full component palette")
	check(not ui.desktop_windows[&"components"].minimizable, "CPU folding does not change other levels' tool contract")
	ui._start_campaign_level(&"half_adder", false)
	await settle()
	ProjectSettings.set_setting("game/reduced_motion", true)
	for wire: Dictionary in ui._half_adder_reference_wires():
		if wire.to_node == &"SUM_OUT": wire.from_node = &"A_IN"
		ui._on_connection_request(wire.from_node, wire.from_port, wire.to_node, wire.to_port)
	ui.official_button.pressed.emit()
	for frame: int in range(100):
		if not ui.official_sequence_active: break
		await process_frame
	check(not ui.official_passed and ui.selected_result_case == 1, "Formal failure selects the first failing recorded case")
	check(ui.mismatch_markers.size() == 1 and ui.mismatch_markers[0].text.contains("0") and ui.mismatch_markers[0].text.contains("1"), "Canvas marks only the mismatching output with actual and expected values")
	ui._try_half_adder_input(3)
	check(ui.selected_result_case == 3 and ui.input_a_button.button_pressed and ui.input_b_button.button_pressed, "Clicking a completed case restores its recorded inputs")
	check(ui.current_trace == ui.official_report.cases[3].trace and not ui.playback_running, "Case review uses the actual receipt and reduced motion settles instantly")
	ui._on_disconnection_request(&"A_IN", 0, &"SUM_OUT", 0)
	check(ui.mismatch_markers.is_empty() and ui.selected_result_case == -1, "Editing clears obsolete canvas comparisons")
	ui.queue_free()
	await process_frame
	for failure: String in failures: push_error(failure)
	print("PASS: %d hardware workspace checks" % checks if failures.is_empty() else "FAIL: %d/%d hardware workspace checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
