extends SceneTree
## Graphical QA in an isolated profile. Catalog boards are explicitly synthetic.
const Component = preload("res://src/circuit/logic_component.gd")
const SaveService = preload("res://src/save/global_save.gd")
const WorkbenchStore = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
const VisualLayout = preload("res://src/hardware_foundations/component_visual_layout.gd")
const KINDS: Array[StringName] = [&"input", &"output", &"lamp", &"and", &"or", &"xor", &"not", &"nor", &"junction", &"half_adder", &"full_adder", &"mux4", &"alu1", &"sr_latch", &"register1", &"register4", &"decoder1_to_2", &"mux2_word", &"alu4", &"ram2x4", &"control", &"constant", &"tiny_computer"]
var destination: String = ""
var phase: String = ""
var receipt: Dictionary = {"qa_only": true, "native_pointer_acceptance": false, "captures": [], "seals": []}
var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)
	return condition

func settle() -> void:
	for frame: int in 8: await process_frame
	await RenderingServer.frame_post_draw

func hide_hardware_windows(ui) -> void:
	for window: Control in ui.desktop_windows.values(): window.hide()

func snap(label: String) -> void:
	await settle()
	var image: Image = root.get_texture().get_image()
	if not require(image != null and image.get_size() == Vector2i(1280, 720), "Expected a real 1280x720 render"): return
	var filename: String = phase + "-" + label + ".png"
	if require(image.save_png(destination.path_join(filename)) == OK, "Save screenshot " + filename):
		receipt.captures.append({"file": filename, "sha256": FileAccess.get_sha256(destination.path_join(filename)), "width": 1280, "height": 720})

func check_wire_geometry(ui, zoom: float) -> void:
	ui.graph.zoom = zoom
	await settle()
	var checked: int = 0
	for wire: Dictionary in ui.graph.get_connection_list():
		var curve: PackedVector2Array = ui.graph.connection_curve(wire)
		var source: GraphNode = ui.component_nodes.get(StringName(wire.from_node))
		var target: GraphNode = ui.component_nodes.get(StringName(wire.to_node))
		if not require(source != null and target != null and curve.size() >= 2, "Rendered wire has both endpoints"): continue
		require(curve[0].is_equal_approx(ui.graph.displayed_port_position(source, int(wire.from_port), true)), "Wire starts at displayed output at zoom %s" % zoom)
		require(curve[-1].is_equal_approx(ui.graph.displayed_port_position(target, int(wire.to_port), false)), "Wire ends at displayed input at zoom %s" % zoom)
		checked += 1
	require(checked == 12, "All twelve real HalfAdder wires rendered")
	if not receipt.has("wire_geometry"): receipt["wire_geometry"] = []
	receipt.wire_geometry.append({"zoom": zoom, "checked": checked})

func check_restart(ui, earned) -> void:
	ui.flush_workspace()
	var writer = root.get_node("GlobalSave")
	require(writer.save_game(true), "Real earned circuit saves through GlobalSave: %s" % writer.last_error)
	var reader = SaveService.new()
	reader.configure_for_test(writer.storage_path, writer.workbench_storage_path)
	var loaded: bool = reader.load_game()
	require(loaded, "Saved earned circuit reloads through provenance verifier")
	var restored = reader.game_player_content.component_library.get(&"HalfAdder")
	require(restored != null, "Reload preserves earned HalfAdder")
	if restored != null:
		require(restored.source_signature == earned.source_signature, "Reload preserves verified source")
		require(VisualLayout.is_valid(restored.visual_snapshot, restored.source_signature), "Reload preserves a valid source-bound footprint")
		var rect := Rect2(0, 0, 240, 160)
		require(VisualLayout.outline(restored.visual_snapshot, restored.source_signature, rect) == VisualLayout.outline(earned.visual_snapshot, earned.source_signature, rect)
			and restored.visual_snapshot.get("layout_digest") == earned.visual_snapshot.get("layout_digest"), "Reload preserves exact frozen shape and digest")
	reader.free()

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="): destination = argument.trim_prefix("--evidence-dir=")
		if argument.begins_with("--phase="): phase = argument.trim_prefix("--phase=")
	var isolated: bool = bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false))
	var profile: String = String(ProjectSettings.get_setting("application/config/custom_user_dir_name", ""))
	if not require(isolated and not profile.is_empty() and (profile.to_lower().contains("qa") or profile.to_lower().contains("capture")), "Requires explicitly named QA/capture custom user directory"):
		quit(2); return
	if not require(DisplayServer.get_name() != "headless", "Headless renderer cannot produce graphical evidence"):
		quit(2); return
	if not require(not destination.is_empty() and phase in ["before", "after"], "Supply --evidence-dir=PATH and --phase=before|after"):
		quit(2); return
	DirAccess.make_dir_recursive_absolute(destination)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"game")
	var save_service = root.get_node("GlobalSave")
	if not require(not FileAccess.file_exists(save_service.storage_path), "Use a fresh QA custom profile per run; existing save found"):
		quit(2); return
	# --script disables autoload writes by default. The isolation checks above
	# allow this harness's explicitly requested real persistence verification.
	save_service.disk_write_allowed = true
	root.get_node("TaskNavigation").from_tree = false
	receipt.merge({"phase": phase, "profile": profile, "display": DisplayServer.get_name(), "engine": Engine.get_version_info()})
	var source_hashes: Dictionary = {}
	for path: String in ["src/hardware_foundations/hardware_foundations.gd", "src/hardware_foundations/circuit_component_symbol.gd", "src/hardware_foundations/circuit_module_row.gd", "src/hardware_foundations/circuit_module_thumbnail.gd", "src/hardware_foundations/component_palette_item.gd", "src/hardware_foundations/component_visual_layout.gd", "src/system_lab/system_device_surface.gd", "src/circuit/logic_component.gd", "src/save/global_save.gd"]:
		source_hashes[path] = FileAccess.get_sha256("res://" + path)
	receipt["source_sha256"] = source_hashes
	var ui = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(ui)
	current_scene = ui
	await settle()
	# Automated launches intentionally default to an in-memory workbench. Real
	# restart verification needs its matching source in this isolated QA profile.
	ui.workbench_store = WorkbenchStore.new(save_service.workbench_storage_path)
	# Access-only QA prerequisite; neither HalfAdder topology nor its award is installed.
	ui.player_content.mark_completed(&"tutorial")
	receipt["prerequisite"] = "QA tutorial access only; HalfAdder earned through official cases and seal callback"
	for arrangement: int in 2:
		ui._start_challenge(false)
		await settle()
		ui._close_desktop_window(&"task")
		ui._close_desktop_window(&"components")
		ui._close_desktop_window(&"test_bench")
		hide_hardware_windows(ui)
		var ids: Array = ui.component_nodes.keys()
		ids.sort()
		for index: int in ids.size():
			var node: GraphNode = ui.component_nodes[ids[index]]
			if arrangement == 0:
				node.position_offset = Vector2(120 + (index % 5) * 200, 120 + (index / 5) * 220)
			else:
				node.position_offset = Vector2(120 + (index % 4) * 220, 90 + (index / 4) * 170 + (150 if index == 9 else 0))
		if arrangement == 1:
			var internal_index: int = 0
			for id: StringName in ids:
				if ui.component_catalog[id].fixed_terminal: continue
				ui.component_nodes[id].position_offset = Vector2(220 + internal_index * 160, 90) if internal_index < 3 else Vector2(540, 90 + (internal_index - 2) * 140)
				internal_index += 1
		for wire: Dictionary in ui._half_adder_reference_wires():
			ui._on_connection_request(wire.from_node, int(wire.from_port), wire.to_node, int(wire.to_port))
		ui.graph.zoom = 0.65
		ui.graph.scroll_offset = Vector2.ZERO
		await check_wire_geometry(ui, 0.65)
		await snap("half-adder-layout-%d-zoom-065" % arrangement)
		if arrangement == 0:
			await check_wire_geometry(ui, 1.0)
			await snap("half-adder-zoom-100")
			ui.graph.zoom = 1.35
			await check_wire_geometry(ui, 1.35)
			await snap("half-adder-zoom-135")
			ui.graph.zoom = 0.65
		ui._run_official()
		var deadline: int = Time.get_ticks_msec() + 15000
		while ui.official_sequence_active and Time.get_ticks_msec() < deadline:
			if ui.playback_running: ui._finish_playback()
			await process_frame
		if not require(ui.official_passed and not ui.official_sequence_active, "HalfAdder official verification passes layout %d" % arrangement): break
		var source: String = ui._circuit_from_graph().canonical_signature()
		require(ui.passing_topology_signature == source, "Verdict binds displayed circuit")
		ui.level_completion_overlay.primary_action_button.pressed.emit()
		require(ui.sealing, "Production primary action begins sealing")
		deadline = Time.get_ticks_msec() + 10000
		while ui.sealing and Time.get_ticks_msec() < deadline: await process_frame
		if not require(ui.current_phase == &"sealed" and ui.component_library.has(&"HalfAdder"), "Timed production sealing installs HalfAdder"): break
		var earned = ui.component_library[&"HalfAdder"]
		require(earned.source_signature == source, "Earned component source remains verified")
		check_restart(ui, earned)
		receipt.seals.append({"source_signature": source, "visual_snapshot": earned.visual_snapshot.duplicate(true), "official_report": ui.official_report.duplicate(true)})
		ui._dismiss_level_completion()
		hide_hardware_windows(ui)
		await snap("earned-half-adder-layout-%d" % arrangement)
		ui._start_campaign_level(&"full_adder", false)
		await settle()
		hide_hardware_windows(ui)
		ui._show_desktop_window(&"components")
		ui.palette_scope.select(1)
		ui._filter_component_palette()
		await snap("earned-palette-layout-%d" % arrangement)
	if receipt.seals.size() == 2:
		require(receipt.seals[0].source_signature == receipt.seals[1].source_signature, "Same logical circuit in both arrangements")
		require(receipt.seals[0].visual_snapshot.get("bands", []) != receipt.seals[1].visual_snapshot.get("bands", []), "Distinct earned frozen shapes")
	ui.flush_workspace()
	save_service.disk_write_allowed = false
	ui.workbench_store.storage_path = ""
	# These nodes use the production graph/node path, but grant no progression.
	ui._close_desktop_window(&"components")
	hide_hardware_windows(ui)
	ui._dismiss_level_completion()
	ui.phase_label.text = "QA ONLY · production component catalog"
	ui.status_label.text = "Synthetic visual inspection board · no completion or reward"
	for page: int in 4:
		ui.component_catalog.clear()
		ui.layout_positions.clear()
		ui.level_palette_templates.clear()
		ui._create_graph()
		for offset: int in 6:
			var index: int = page * 6 + offset
			if index >= KINDS.size(): break
			var id: StringName = StringName("QA_" + String(KINDS[index]))
			var part = Component.new(id, KINDS[index], String(KINDS[index]))
			ui.component_catalog[id] = part
			ui._add_component_node(part, Vector2(100 + (offset % 3) * 360, 100 + (offset / 3) * 290))
		ui.graph.zoom = 0.65
		ui.graph.scroll_offset = Vector2.ZERO
		hide_hardware_windows(ui)
		await snap("qa-catalog-%d" % page)
	ui.component_catalog.clear()
	ui._create_graph()
	for index: int in 12:
		var kind: StringName = [&"alu4", &"ram2x4", &"register4", &"mux2_word"][index % 4]
		var id: StringName = StringName("DENSE_%d" % index)
		var part = Component.new(id, kind, String(kind))
		ui.component_catalog[id] = part
		ui._add_component_node(part, Vector2(80 + (index % 4) * 260, 60 + (index / 4) * 200))
	ui.graph.zoom = 0.65
	ui.graph.scroll_offset = Vector2.ZERO
	ui.phase_label.text = "QA ONLY · dense ALU / RAM visual inspection"
	hide_hardware_windows(ui)
	await snap("qa-dense-mixed-alu-ram")
	ui.component_catalog.clear()
	ui._create_graph()
	for index: int in 3:
		var kind: StringName = [&"alu4", &"ram2x4", &"control"][index]
		var id: StringName = StringName("QA_NATIVE_%d" % index)
		var part = Component.new(id, kind, String(kind))
		ui.component_catalog[id] = part
		ui._add_component_node(part, Vector2(90 + index * 360, 60))
	ui.graph.zoom = 1.0
	ui.graph.scroll_offset = Vector2.ZERO
	ui.phase_label.text = "QA ONLY · mixed-width ports at 100%"
	hide_hardware_windows(ui)
	await snap("qa-mixed-width-zoom-100")
	ui.queue_free()
	await process_frame
	root.get_node("GameMode").set_mode(&"test")
	var system = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(system)
	system.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_scene = system
	await settle()
	system._start_level(&"assembly")
	system._auto_connect()
	for window: Control in system.instrument_windows.values(): window.hide()
	system.graph.zoom = 0.8
	system.graph.scroll_offset = Vector2.ZERO
	system._auto_layout(false)
	await settle()
	system._frame_machine()
	await settle()
	for window: Control in system.instrument_windows.values(): window.hide()
	require(root.get_visible_rect().encloses(system.get_global_rect()), "System scene fits the actual capture viewport")
	for node: GraphNode in system.device_nodes.values():
		require(system.graph.get_global_rect().encloses(node.get_global_rect()), "Framed system device is fully visible: " + String(node.name))
	await snap("system-production-cpu-ram-bus")
	require(system.device_nodes.size() >= 3, "System workbench renders actual CPU/RAM/Bus nodes")
	system._run_debug_case()
	system.playback_running = false
	if require(system.current_trace != null, "System state captures use an actual simulated trace"):
		require(system.current_trace.passed, "Actual system debug case passes")
		receipt["system_trace"] = {"signature": system.current_trace.canonical_signature().sha256_text(),
			"metrics": system.current_trace.metrics, "output_data": system.current_trace.output_data,
			"expected_output": system.current_trace.expected_output, "passed": system.current_trace.passed}
		var captured_kinds: Dictionary = {}
		for event in system.current_trace.events:
			if event.kind not in [&"compute", &"ram_read", &"ram_write", &"read_data", &"write_data"] or captured_kinds.has(event.kind): continue
			captured_kinds[event.kind] = true
			system._show_event(event, 0.58)
			await snap("system-trace-" + String(event.kind))
			receipt.get_or_add("system_trace_frames", []).append(event.to_dictionary())
	receipt["logic_catalog_kinds"] = KINDS
	receipt["system_catalog_kinds"] = ["cpu", "ram", "bus"]
	receipt["failures"] = failures
	receipt["checks"] = checks
	var file := FileAccess.open(destination.path_join(phase + "-receipt.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(receipt, "\t")); file.close()
	print("COMPONENT_CAPTURE ", phase, " failures=", failures.size(), " captures=", receipt.captures.size())
	quit(0 if failures.is_empty() else 1)
