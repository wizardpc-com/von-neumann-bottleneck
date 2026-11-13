extends SceneTree
## CPU framing after real title-bar minimizing/dragging; synthetic reference wiring.
var failures: Array[String] = []
var checks: int = 0
var completed: Array[String] = []
var bench: Control

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame
func key_home(all_nodes: bool) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_HOME; event.physical_keycode = KEY_HOME
		event.pressed = down; event.shift_pressed = all_nodes
		root.push_input(event,true); await process_frame
	await settle()
func mouse(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at; event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
	root.push_input(event,true); await process_frame
func click(control: Control) -> void:
	await mouse(control.get_global_rect().get_center(),true)
	await mouse(control.get_global_rect().get_center(),false)
	await settle()
func drag_title(window: Control, destination: Vector2) -> void:
	var title: Control = window.find_child("WindowTitle",true,false)
	var start: Vector2 = title.get_global_rect().get_center()
	var finish: Vector2 = start + destination - window.position
	await mouse(start,true)
	var motion := InputEventMouseMotion.new()
	motion.position = finish; motion.global_position = finish
	motion.relative = finish-start; motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true); await process_frame
	await mouse(finish,false); await settle()
	check(window.position.distance_to(destination) < 2.0, "Actual title drag reaches requested edge")
func resize(dimensions: Vector2i) -> void:
	root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
	await settle()
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
		DisplayServer.window_set_size(dimensions)
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable+1 if picture != null and picture.get_size() == dimensions else 0
		if stable >= 5: return
	check(false,"Actual renderer stabilizes at "+str(dimensions))
func unchanged_state() -> Dictionary:
	var windows: Dictionary = {}
	for id: StringName in bench.desktop_windows:
		var window: Control = bench.desktop_windows[id]
		windows[id] = {"rect":window.get_rect(),"visible":window.visible,"minimized":window.minimized}
	return {"board":bench._capture_workbench_snapshot(),"history":bench.wire_history.duplicate(true),
		"redo":bench.redo_history.duplicate(true),"windows":windows,"passed":bench.official_passed,
		"passing":bench.passing_topology_signature,"debug":bench.debug_result_label.text,
		"result":bench.prologue_live_result.canonical_signature() if bench.prologue_live_result != null else ""}
func node_bounds() -> Rect2:
	var bounds := Rect2()
	var first: bool = true
	for node: GraphNode in bench.component_nodes.values():
		bounds = node.get_global_rect() if first else bounds.merge(node.get_global_rect())
		first = false
	return bounds
func focus_check(all_nodes: bool, selected: GraphNode, minimized: Control, label: String) -> void:
	bench.graph.grab_focus()
	var state: Dictionary = unchanged_state()
	await key_home(all_nodes)
	var visible: Rect2 = bench.graph.get_global_rect()
	var target: Rect2 = node_bounds() if all_nodes else selected.get_global_rect()
	check(visible.has_point(target.get_center()), label+": focused target center is inside the real graph viewport; target="+str(target)+" view="+str(visible))
	if not all_nodes:
		check(visible.encloses(target),label+": selected node fits inside the graph")
		check(not minimized.get_global_rect().intersects(target),label+": selected node is not hidden by the minimized title")
	else:
		var seen: int = 0
		for node: GraphNode in bench.component_nodes.values():
			if visible.has_point(node.get_global_rect().get_center()): seen += 1
		check(seen > 0,label+": dense CPU retains visible components")
	check(unchanged_state() == state,label+": framing preserves circuit, evidence, history and every window")
func capture(label: String, dimensions: Vector2i) -> void:
	if "--circuit-focus-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	var picture: Image = root.get_texture().get_image()
	check(picture.get_size() == dimensions,label+": actual capture dimensions")
	if picture.get_size() != dimensions: return
	var path: String = "user://circuit-focus-"+label+".png"
	check(picture.save_png(path) == OK,label+": saves raw capture")
	print("CAPTURE: "+ProjectSettings.globalize_path(path))
func exercise(locale: String) -> void:
	root.get_node("Localization").set_locale(locale)
	bench = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench); current_scene = bench; await settle()
	bench._start_campaign_level(&"cpu",false); await settle()
	bench._finish_mission_briefing(); await settle()
	for wire: Dictionary in bench.current_level_definition.reference_wires:
		bench._on_connection_request(wire["from"],int(wire.get("from_port",0)),wire["to"],int(wire.get("to_port",0)))
	bench._run_debug(); bench._finish_playback(); await settle()
	bench.set_process(false)
	check(bench.prologue_live_result != null and bench.prologue_live_result.is_valid(),locale+": actual CPU Debug supplies evidence before framing")
	# Keep the default instruments' positions; close other windows to isolate each
	# minimized title as an obstruction. No circuit nodes are relocated by setup.
	for id: StringName in [&"task",&"test_bench",&"inspector"]: bench._close_desktop_window(id)
	bench._show_desktop_window(&"components"); await settle()
	var window: Control = bench.desktop_windows[&"components"]
	await click(window.find_child("MinimizeButton",true,false))
	check(window.minimized,locale+": actual minimize button collapses CPU palette")
	var selected: GraphNode = bench.component_nodes.values()[0]
	bench._set_selected_ids([StringName(selected.name)] as Array[StringName])
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(960,640)]:
		await resize(dimensions)
		var area: Vector2 = bench.graph_stack.size
		var positions: Dictionary = {
			"bottom":Vector2((area.x-window.size.x)*0.5,area.y-window.size.y-10),
			"top":Vector2((area.x-window.size.x)*0.5,10),
			"left":Vector2(10,(area.y-window.size.y)*0.5),
			"right":Vector2(area.x-window.size.x-10,(area.y-window.size.y)*0.5)}
		for edge: String in positions:
			await drag_title(window,positions[edge])
			await focus_check(false,selected,window,locale+" "+str(dimensions)+" "+edge+" Home")
			await focus_check(true,selected,window,locale+" "+str(dimensions)+" "+edge+" ShiftHome")
			if edge == "bottom": await capture(locale+"-"+str(dimensions.x),dimensions)
		# Match the native CPU case: both real titles remain visible, then exchange
		# their top/bottom positions. Only framing visibility is required here.
		bench._show_desktop_window(&"test_bench"); await settle()
		var tester: Control = bench.desktop_windows[&"test_bench"]
		if not tester.minimized: await click(tester.find_child("MinimizeButton",true,false))
		check(tester.minimized and window.minimized,locale+": both CPU instruments are minimized")
		for palette_bottom: bool in [true,false]:
			await drag_title(window,Vector2(10,(area.y-window.size.y)*0.5))
			await drag_title(tester,Vector2((area.x-tester.size.x)*0.5,10 if palette_bottom else area.y-tester.size.y-10))
			await drag_title(window,positions["bottom" if palette_bottom else "top"])
			for all_nodes: bool in [false,true]:
				bench.graph.grab_focus()
				var state: Dictionary = unchanged_state()
				await key_home(all_nodes)
				var target: Rect2 = node_bounds() if all_nodes else selected.get_global_rect()
				var label: String = locale+" "+str(dimensions)+" dual titles palette_bottom="+str(palette_bottom)+" all="+str(all_nodes)
				check(bench.graph.get_global_rect().has_point(target.get_center()),label+": focus center stays inside graph")
				check(unchanged_state() == state,label+": framing preserves circuit, evidence, history and both titles")
		bench._close_desktop_window(&"test_bench"); await settle()
	# Empty-canvas API boundary: temporarily remove all nodes from the live graph,
	# without invoking user deletion of protected terminals or persisting a fixture.
	var nodes: Dictionary = bench.component_nodes.duplicate()
	for node: GraphNode in nodes.values(): bench.graph.remove_child(node)
	bench.component_nodes.clear()
	var zoom: float = bench.graph.zoom
	var scroll: Vector2 = bench.graph.scroll_offset
	bench._focus_circuit(true)
	check(bench.graph.zoom == zoom and bench.graph.scroll_offset == scroll,locale+": empty circuit focus is a safe no-op")
	for node: GraphNode in nodes.values(): bench.graph.add_child(node)
	bench.component_nodes.assign(nodes)
	completed.append(locale)
	bench.queue_free(); current_scene = null; await settle()
func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile."); quit(2); return
	root.get_node("GameMode").set_mode(&"test")
	var original: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	for locale: String in ["zh_CN","en"]: await exercise(locale)
	check(completed == ["zh_CN","en"],"Both complete real title/Home loops reach the end")
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == original,"Test framing does not alter earned Game content")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"circuit focus visibility %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
