extends SceneTree

const CircuitEventType = preload("res://src/circuit/circuit_event.gd")
const CircuitTraceType = preload("res://src/circuit/circuit_trace.gd")
const LogicSignalType = preload("res://src/circuit/logic_signal.gd")
const CircuitLiveStateType = preload("res://src/circuit/circuit_live_state.gd")
const CircuitWorkbenchStoreType = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
const HalfAdderTestBenchType = preload("res://src/circuit/half_adder_test_bench.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_workbench_store_model()
	var scene: PackedScene = load("res://src/hardware_foundations/hardware_foundations.tscn")
	var main: Control = scene.instantiate()
	root.size = Vector2i(1600, 900)
	root.add_child(main)
	for _frame: int in range(5):
		await process_frame

	var game_mode: Node = root.get_node("GameMode")
	_assert(main.get("fullscreen_button") != null, "Hardware Foundations must expose the shared visible fullscreen toggle.")
	_assert(StringName(main.get("current_phase")) == &"campaign", "Hardware Foundations must open on the prerequisite-gated level map.")
	_assert(main.get("mode_selector") != null and not bool(game_mode.call("is_test_mode")), "Hardware Foundations must expose the shared selector and default to Game mode.")
	_assert(not bool(game_mode.call("set_mode", &"unknown")) and not bool(game_mode.call("is_test_mode")), "The global mode boundary must reject unknown modes without changing state.")
	var campaign_buttons: Dictionary = main.get("campaign_level_buttons")
	var campaign_map: Control = main.get("campaign_map_view")
	_assert(campaign_map != null and is_instance_valid(campaign_map), "The campaign must use the central graphical dependency map instead of leaving the canvas empty.")
	_assert(not (main.get("graph") as GraphEdit).visible, "Level select must hide the circuit canvas and its editor scrollbars behind the dedicated map.")
	_assert(campaign_buttons.size() == 9 and (campaign_map.call("dependency_edges") as Array).size() == 9, "The graphical map must expose all nine registered levels and all nine prerequisite edges.")
	_assert(
		(campaign_map.call("level_position", &"tutorial") as Vector2).x < (campaign_map.call("level_position", &"half_adder") as Vector2).x
		and (campaign_map.call("level_position", &"full_adder") as Vector2).y < (campaign_map.call("level_position", &"latch") as Vector2).y
		and (campaign_map.call("level_position", &"cpu") as Vector2).x > (campaign_map.call("level_position", &"alu") as Vector2).x
		and (campaign_map.call("level_position", &"cpu") as Vector2).x > (campaign_map.call("level_position", &"ram") as Vector2).x,
		"The dependency layout must visibly fork into arithmetic/storage lanes and merge at CPU."
	)
	_assert(StringName(campaign_map.call("level_state", &"tutorial")) == &"unlocked" and StringName(campaign_map.call("level_state", &"half_adder")) == &"locked", "Graphical node state must match the authoritative prerequisite gate.")
	_assert((campaign_buttons[&"tutorial"] as Button).get_parent() == campaign_map, "Level selection buttons must live on the central graphical map, not in the Mission text list.")
	_assert(campaign_buttons.has(&"tutorial") and not (campaign_buttons[&"tutorial"] as Button).disabled, "The wiring tutorial must be the first unlocked Foundations level.")
	_assert(campaign_buttons.has(&"half_adder") and (campaign_buttons[&"half_adder"] as Button).disabled, "Half Adder must be visibly locked before the wiring tutorial is complete.")
	_assert(campaign_buttons.has(&"full_adder") and (campaign_buttons[&"full_adder"] as Button).disabled, "Later arithmetic levels must remain visibly locked at session start.")
	var map_windows: Dictionary = main.get("desktop_windows")
	var map_window_buttons: Dictionary = main.get("desktop_window_buttons")
	var map_task_window: Control = map_windows[&"task"]
	var map_bench_window: Control = map_windows[&"test_bench"]
	_assert(map_task_window.visible and not map_bench_window.visible, "Level select must keep the interactive Mission page but remove the irrelevant Test Bench page.")
	_assert(not (map_window_buttons[&"test_bench"] as Button).visible, "Level select must not offer a taskbar action that can reopen its removed Test Bench.")
	_assert(not (map_window_buttons[&"components"] as Button).visible, "Level select must not offer the circuit-editor Components page.")
	_assert(
		not (main.get("editor_toolbar") as Control).visible
		and not (main.get("trace_caption_label") as Label).visible
		and not (main.get("diagnostics_label") as Label).visible,
		"Level select must hide editing, layout, and Trace controls instead of carrying the playable-level toolbar onto the map."
	)
	var chapter_select_button: Button = main.get("hub_button")
	_assert(
		chapter_select_button != null and chapter_select_button.visible
		and chapter_select_button.text == String(main.call("_t", &"common.chapter_select")),
		"The map header must expose an explicit localized return to chapter selection."
	)
	_assert(
		campaign_map.get_index() < map_task_window.get_index(),
		"The full-rect level map must stay below desktop windows in GUI sibling order."
	)
	main.call("_show_desktop_window", &"test_bench")
	_assert(not map_bench_window.visible, "The map must reject attempts to reopen the Test Bench until a playable level starts.")
	var map_task_rect := Rect2(map_task_window.position, map_task_window.size)
	for button: Button in campaign_buttons.values():
		_assert(
			not map_task_rect.intersects(Rect2(button.position, button.size)),
			"The default Mission page must stay entirely inside the map's reserved lane instead of covering %s. mission=%s level=%s" % [button.name, map_task_rect, Rect2(button.position, button.size)]
		)
	var map_task_start: Vector2 = map_task_window.position
	var map_task_z: int = map_task_window.z_index
	var map_header: Control = map_task_window.find_child("WindowHeader", true, false)
	await _drag_control(map_header, Vector2(8.0, 8.0))
	_assert(not map_task_window.position.is_equal_approx(map_task_start) and map_task_window.z_index > map_task_z, "The map Mission page must remain movable and focusable.")
	var minimize_button: Button = map_task_window.find_child("MinimizeButton", true, false)
	await _click_control(minimize_button)
	_assert(bool(map_task_window.get("minimized")), "The map Mission page must remain minimizable.")
	await _click_control(minimize_button)
	map_task_window.call("resize_by", Vector2(0.0, -1000.0))
	var task_scroll: ScrollContainer = map_task_window.find_child("TaskScroll", true, false)
	await _scroll_control(task_scroll)
	_assert(task_scroll.scroll_vertical > 0, "The map Mission page must receive wheel input and scroll overflowing content.")
	var close_button: Button = map_task_window.find_child("CloseButton", true, false)
	await _click_control(close_button)
	_assert(not map_task_window.visible, "The map Mission page close action must remove it without affecting the level map.")
	await _click_control(map_window_buttons[&"task"])
	_assert(map_task_window.visible and not bool(map_task_window.get("minimized")), "The Mission taskbar action must restore a closed or minimized map page.")
	main.call("_layout_desktop_windows")
	main.call("_start_campaign_level", &"half_adder")
	_assert(StringName(main.get("current_phase")) == &"campaign", "The internal level router must reject a direct Half Adder prerequisite bypass.")
	var tutorial_map_button: Button = campaign_buttons[&"tutorial"]
	tutorial_map_button.pressed.emit()
	for _tutorial_frame: int in range(3):
		await process_frame
	_assert(StringName(main.get("current_phase")) == &"tutorial", "Selecting the first map level must open the short wiring tutorial.")
	_assert(not is_instance_valid(tutorial_map_button), "A clicked map button must be released after its signal finishes instead of triggering Godot's locked-object error.")
	_assert(
		(main.get("editor_toolbar") as Control).visible and (main.get("graph") as GraphEdit).visible,
		"Playable levels must restore their circuit canvas and editing toolbar after leaving the simplified map."
	)
	var graph: GraphEdit = main.get("graph")
	var nodes: Dictionary = main.get("component_nodes")
	var symbols: Dictionary = main.get("component_symbols")
	_assert(graph != null and graph.get_connection_list().is_empty(), "Tutorial must begin auto-laid-out but unwired.")
	var workbench_store = main.get("workbench_store")
	var workbench_menu: MenuButton = main.get("workbench_menu_button")
	var hint_button: Button = main.get("hint_button")
	_assert(
		workbench_store != null and String(workbench_store.get("storage_path")).is_empty(),
		"Automated tests must use an in-memory workbench store instead of touching a player's durable schematics."
	)
	_assert(
		String(main.get("active_workbench_name")) == "default"
		and workbench_menu != null and workbench_menu.visible
		and workbench_menu.text.contains("default"),
		"Entering a level must automatically create and select its default workbench."
	)
	_assert(hint_button != null and hint_button.visible, "Every playable level must expose the top-right progressive Hint action.")
	main.call("_show_new_workbench_dialog")
	await process_frame
	var workbench_name_dialog: Control = main.get("workbench_name_dialog")
	var workbench_name_panel: Control = workbench_name_dialog.find_child("WorkbenchNamePanel", true, false)
	_assert(
		workbench_name_dialog.visible
		and workbench_name_panel != null
		and workbench_name_panel.size.x <= 540.0
		and workbench_name_panel.size.y <= 270.0,
		"The create-workbench prompt must remain a compact in-canvas modal instead of resizing or replacing the desktop workspace."
	)
	main.call("_hide_new_workbench_dialog")
	_assert(bool(main.call("_create_named_workbench", "方案 A")), "Players must be able to create and name an independent workbench.")
	for _named_frame: int in range(3):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	var moved_not_start: Vector2 = (nodes[&"NOT_1"] as GraphNode).position_offset
	main.call("_on_begin_node_move")
	(nodes[&"NOT_1"] as GraphNode).position_offset += Vector2(80.0, 40.0)
	main.call("_on_end_node_move")
	main.call("_on_connection_request", &"A_IN", 0, &"NOT_1", 0)
	for _save_frame: int in range(2):
		await process_frame
	var scheme_position: Vector2 = (nodes[&"NOT_1"] as GraphNode).position_offset
	var scheme_signature: String = JSON.stringify(main.call("_capture_workbench_snapshot"))
	_assert(graph.get_connection_list().size() == 1 and not scheme_position.is_equal_approx(moved_not_start), "A named workbench must save both placed geometry and visible wiring.")
	_assert(bool(main.call("_create_named_workbench", "空白方案")), "Creating another workbench from a modified design must succeed.")
	for _clean_workbench_frame: int in range(3):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	_assert(
		String(main.get("active_workbench_name")) == "空白方案"
		and graph.get_connection_list().is_empty()
		and (nodes[&"NOT_1"] as GraphNode).position_offset.is_equal_approx(moved_not_start)
		and (main.get("wire_history") as Array).is_empty(),
		"A new workbench must start from the pristine level inventory rather than cloning the modified active design."
	)
	_assert(bool(main.call("_switch_workbench", "default")), "The workbench selector must switch back to default.")
	for _default_frame: int in range(3):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	_assert(
		graph.get_connection_list().is_empty()
		and (nodes[&"NOT_1"] as GraphNode).position_offset.is_equal_approx(moved_not_start)
		and (main.get("wire_history") as Array).is_empty(),
		"Default must remain independent, restore its own positions, and start with no persisted undo chain."
	)
	_assert(bool(main.call("_switch_workbench", "方案 A")), "The selector must reopen the named workbench.")
	for _scheme_frame: int in range(3):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	_assert(
		graph.get_connection_list().size() == 1
		and (nodes[&"NOT_1"] as GraphNode).position_offset.is_equal_approx(scheme_position)
		and (main.get("wire_history") as Array).is_empty(),
		"Reopening a named workbench must restore its topology and positions without restoring its operation history."
	)
	main.call("_enter_hint_workbench")
	for _hint_frame: int in range(3):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	_assert(
		bool(main.get("hint_mode")) and int(main.get("hint_level")) == 1
		and nodes.size() == 3 and graph.get_connection_list().is_empty(),
		"Hint stage 1 must enter a separate board with only fixed terminals and conceptual guidance."
	)
	for node_variant: Variant in nodes.values():
		_assert(not (node_variant as GraphNode).draggable, "Every component on a hint workbench must be read-only.")
	main.call("_show_hint_level", 2)
	for _hint_two_frame: int in range(2):
		await process_frame
	graph = main.get("graph")
	_assert(graph.get_connection_list().size() == 2 and (main.get("component_nodes") as Dictionary).has(&"NOT_1"), "Hint stage 2 must reveal the tutorial's key NOT signal path on the real graph.")
	main.call("_show_hint_level", 3)
	for _hint_three_frame: int in range(2):
		await process_frame
	graph = main.get("graph")
	var hint_component_count: int = (main.get("component_nodes") as Dictionary).size()
	main.call("_on_erase_component_requested", &"NOT_1")
	_assert(
		hint_component_count == 6
		and graph.get_connection_list().size() == 2
		and (main.get("component_nodes") as Dictionary).has(&"NOT_1"),
		"Hint stage 3 must show the complete reference topology while rejecting editing gestures."
	)
	main.call("_exit_hint_workbench")
	for _hint_exit_frame: int in range(3):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	_assert(
		not bool(main.get("hint_mode"))
		and String(main.get("active_workbench_name")) == "方案 A"
		and JSON.stringify(main.call("_capture_workbench_snapshot")) == scheme_signature,
		"Leaving hints must return to the exact player workbench without saving hint topology over it."
	)
	_assert(bool(main.call("_switch_workbench", "default")), "The test must restore default before exercising the ordinary tutorial flow.")
	for _restore_default_frame: int in range(3):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	symbols = main.get("component_symbols")
	_assert(float(graph.get("settled_wire_thickness")) >= 8.0 and graph.connection_lines_thickness == 0.0, "The custom single cable must stay heavy while the duplicate native stroke remains hidden.")
	_assert(graph.get_node_or_null("SignalWireLayer") == null, "Each settled cable must have one full-path renderer; a duplicate signal-wire layer would make it look like two stacked wires.")
	var port_image: Image = main.theme.get_icon("port", "GraphNode").get_image()
	var visible_port_pixels: Rect2i = port_image.get_used_rect()
	_assert(port_image.get_width() == 24 and visible_port_pixels.size.x <= 13 and visible_port_pixels.size.y <= 13, "Ports must use a compact 12px visible disk inside the unchanged 24px interaction canvas.")
	var component_menu: MenuButton = main.get("component_menu_button")
	var menu_templates: Dictionary = main.get("component_menu_templates")
	var menu_kinds: Array[StringName] = []
	for template_variant: Variant in menu_templates.values():
		menu_kinds.append(StringName(template_variant.get("kind")))
	_assert(component_menu != null and not component_menu.disabled, "An editable level must expose its allowed-components menu.")
	_assert(menu_kinds.size() == 3 and &"and" in menu_kinds and &"not" in menu_kinds and &"or" in menu_kinds, "The tutorial menu must deduplicate supplied gates and exclude unique Test Bench terminals and wire nodes; got %s." % [menu_kinds])
	var palette_items: Dictionary = main.get("component_palette_items")
	_assert(palette_items.size() == 3, "The visible component palette must mirror the level-owned supply instead of hiding it only in a popup menu.")
	var and_menu_item: int = _component_menu_item_for_kind(main, &"and")
	_assert(and_menu_item >= 0, "The allowed-components menu must contain an AND gate item.")
	graph.zoom = 0.82
	graph.scroll_offset = Vector2(96.0, 64.0)
	for _placement_transform_frame: int in range(2):
		await process_frame
	main.call("_on_component_menu_item_pressed", and_menu_item)
	_assert(not String(main.get("armed_component_template_key")).is_empty() and bool(graph.get("component_placement_enabled")), "Choosing a component must arm a snapped empty-canvas placement mode.")
	var preview_motion := InputEventMouseMotion.new()
	preview_motion.position = Vector2(905.0, 575.0)
	graph.call("_gui_input", preview_motion)
	graph.call("_draw_component_placement_preview")
	var placement_ghost: Control = graph.get("placement_preview_control")
	var ghost_symbol: CircuitComponentSymbol = placement_ghost.get_child(0) as CircuitComponentSymbol
	var ghost_symbol_position: Vector2 = ghost_symbol.position
	var ghost_symbol_size: Vector2 = ghost_symbol.size
	var ghost_half_size: Vector2 = graph.get("placement_preview_size") * 0.5
	var ghost_graph_position: Vector2 = (preview_motion.position + graph.scroll_offset) / graph.zoom - ghost_half_size
	ghost_graph_position = Vector2(
		snappedf(ghost_graph_position.x, float(graph.snapping_distance)),
		snappedf(ghost_graph_position.y, float(graph.snapping_distance))
	)
	var expected_ghost_position: Vector2 = ghost_graph_position * graph.zoom - graph.scroll_offset
	_assert(
		placement_ghost.visible
		and ghost_symbol != null
		and ghost_symbol.component_kind == &"and"
		and placement_ghost.modulate.a < 0.5
		and placement_ghost.position.is_equal_approx(expected_ghost_position),
		"Clicking a palette item must show the actual selected symbol as a dim ghost at the exact snapped placement position."
	)
	_left_click_empty_canvas(graph, Vector2(905.0, 575.0))
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).has(&"AND_NEW_001") and (main.get("component_nodes") as Dictionary).size() == 7, "One empty-canvas click must create a deterministic real component, not a visual-only ghost.")
	_assert((main.get("component_catalog") as Dictionary)[&"AND_NEW_001"].kind == &"and" and (main.get("component_nodes") as Dictionary)[&"AND_NEW_001"].selected, "A placed menu component must enter the authoritative catalog and become selected.")
	_assert((main.get("current_circuit") as LogicCircuit).components.has(&"AND_NEW_001"), "A placed menu component must enter the circuit model that simulation evaluates.")
	_assert(not String(main.get("armed_component_template_key")).is_empty() and bool(graph.get("component_placement_enabled")), "A successful left click must keep the same component armed for continuous placement.")
	var placed_node := (main.get("component_nodes") as Dictionary)[&"AND_NEW_001"] as GraphNode
	var placed_symbol := (main.get("component_symbols") as Dictionary)[&"AND_NEW_001"] as CircuitComponentSymbol
	var placed_position: Vector2 = placed_node.position_offset
	_assert(is_zero_approx(fmod(placed_position.x, float(graph.snapping_distance))) and is_zero_approx(fmod(placed_position.y, float(graph.snapping_distance))), "Menu placement must snap the actual component to the same visible dot grid as its preview.")
	_assert(
		placed_node.position.is_equal_approx(placement_ghost.position)
		and placed_symbol.position.is_equal_approx(ghost_symbol_position)
		and placed_symbol.size.is_equal_approx(ghost_symbol_size)
		and is_equal_approx(placed_symbol.display_height, ghost_symbol.display_height),
		"The placed component must occupy the exact preview geometry instead of jumping below the ghost."
	)
	graph.zoom = 1.0
	graph.scroll_offset = Vector2.ZERO
	for _placement_restore_frame: int in range(2):
		await process_frame
	_left_click_empty_canvas(graph, Vector2(1085.0, 575.0))
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).has(&"AND_NEW_002") and (main.get("component_nodes") as Dictionary).size() == 8, "A second left click must place another copy without returning to the palette.")
	var component_count_before_cancel: int = (main.get("component_nodes") as Dictionary).size()
	var cancel_click := InputEventMouseButton.new()
	cancel_click.button_index = MOUSE_BUTTON_RIGHT
	cancel_click.pressed = true
	main.call("_input", cancel_click)
	_assert(
		String(main.get("armed_component_template_key")).is_empty()
		and not bool(graph.get("component_placement_enabled"))
		and (main.get("component_nodes") as Dictionary).size() == component_count_before_cancel,
		"Right click while placing must cancel the ghost without erasing the component underneath that gesture."
	)
	_shortcut(main, KEY_Z)
	_assert((main.get("component_nodes") as Dictionary).size() == 7 and not (main.get("component_nodes") as Dictionary).has(&"AND_NEW_002"), "Undo must remove only the latest continuously placed component.")
	_shortcut(main, KEY_Z)
	_assert((main.get("component_nodes") as Dictionary).size() == 6 and not (main.get("component_nodes") as Dictionary).has(&"AND_NEW_001") and not (main.get("current_circuit") as LogicCircuit).components.has(&"AND_NEW_001"), "A second Undo must atomically remove the first menu-placed component from both the view and simulation model.")
	_shortcut(main, KEY_Y)
	_assert((main.get("component_nodes") as Dictionary).has(&"AND_NEW_001") and (main.get("current_circuit") as LogicCircuit).components.has(&"AND_NEW_001"), "Redo must restore the same deterministic placed component to both the view and simulation model.")
	_shortcut(main, KEY_Z)
	main.call("_on_component_menu_item_pressed", and_menu_item)
	var existing_click := InputEventMouseButton.new()
	existing_click.button_index = MOUSE_BUTTON_LEFT
	existing_click.pressed = true
	existing_click.position = ((main.get("component_nodes") as Dictionary)[&"NOT_1"] as GraphNode).size * 0.5
	main.call("_on_component_gui_input", existing_click, &"NOT_1")
	_assert(String(main.get("armed_component_template_key")).is_empty(), "Clicking an existing component must cancel placement before normal component interaction continues.")
	main.call("_on_component_menu_item_pressed", and_menu_item)
	var or_template_key: String = _component_template_key_for_kind(main, &"or")
	main.call("_arm_component_template", or_template_key)
	_assert(String(main.get("armed_component_template_key")) == or_template_key, "Selecting a different palette item must immediately replace the old placement ghost.")
	_key(main, KEY_ESCAPE)
	_assert(String(main.get("armed_component_template_key")).is_empty() and not bool(graph.get("component_placement_enabled")), "Esc must cancel component placement without changing the graph.")
	var drop_payload := {"type": &"circuit_component_template", "template_key": or_template_key}
	_assert(bool(graph.call("_can_drop_data", Vector2(1030.0, 575.0), drop_payload)), "The editable graph must accept a valid level-owned palette drag.")
	graph.call("_drop_data", Vector2(1030.0, 575.0), drop_payload)
	await process_frame
	_assert((main.get("component_nodes") as Dictionary).has(&"OR_NEW_003") and (main.get("current_circuit") as LogicCircuit).components.has(&"OR_NEW_003"), "Dropping a palette item must create one snapped authoritative component through the normal history transaction.")
	_shortcut(main, KEY_Z)
	_assert(not (main.get("component_nodes") as Dictionary).has(&"OR_NEW_003"), "Undo must remove a drag-created component atomically.")
	_shortcut(main, KEY_A)
	_assert((main.call("_selected_node_ids", false) as Array).size() == 6, "Ctrl+A must select every component and explicit wire node on the current canvas.")
	_shortcut(main, KEY_X)
	_assert((main.get("component_nodes") as Dictionary).size() == 3 and (main.get("clipboard_components") as Array).size() == 3, "Ctrl+X must cut player gates while keeping unique Test Bench terminals and a reusable clipboard.")
	_shortcut(main, KEY_Z)
	main.call("_set_selected_ids", [] as Array[StringName])
	nodes = main.get("component_nodes")
	symbols = main.get("component_symbols")
	_assert(nodes.size() == 6, "Undo must restore the complete cut selection as one edit.")
	var scroll_before_keys: Vector2 = graph.scroll_offset
	_key(main, KEY_D)
	_assert(graph.scroll_offset.x > scroll_before_keys.x, "D must pan the schematic view to the right.")
	_key(main, KEY_A)
	_assert(graph.scroll_offset.is_equal_approx(scroll_before_keys), "Opposite WASD navigation must return to the prior view without moving components.")
	var desktop_windows: Dictionary = main.get("desktop_windows")
	_assert(desktop_windows.size() == 3 and (desktop_windows[&"task"] as Control).visible and (desktop_windows[&"test_bench"] as Control).visible and (desktop_windows[&"components"] as Control).visible, "Mission, Test Bench, and the component palette must coexist as desktop-style floating windows.")
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
	var graph_stack: Control = main.get("graph_stack")
	task_window.position = graph_stack.size + Vector2(200.0, 160.0)
	task_window.size = graph_stack.size * 2.0
	task_window.call("fit_to_parent", 10.0)
	_assert(_control_fits(task_window, graph_stack, 10.0), "Fullscreen or aspect-ratio changes must keep a Hardware page completely within the visible circuit desktop.")
	main.call("_layout_desktop_windows")
	await process_frame
	for window_variant: Variant in desktop_windows.values():
		var desktop_window := window_variant as Control
		_assert(_control_fits(desktop_window, graph_stack, 10.0), "Every automatically arranged Hardware page must fit the current desktop size.")
	for component_id: StringName in [&"A_IN", &"B_IN", &"AND_1", &"OR_1", &"NOT_1", &"LAMP"]:
		_assert(nodes.has(component_id), "Tutorial must expose %s." % component_id)
		if nodes.has(component_id):
			var visible_node: GraphNode = nodes[component_id]
			_assert(Rect2(Vector2.ZERO, graph.size).intersects(Rect2(visible_node.position, visible_node.size)), "Tutorial %s must begin inside the visible graph; position=%s offset=%s scroll=%s size=%s graph=%s." % [component_id, visible_node.position, visible_node.position_offset, graph.scroll_offset, visible_node.size, graph.size])
			_assert(visible_node.draggable, "Every supplied gate and external terminal must be movable: %s." % component_id)
	var port_icon: Texture2D = main.theme.get_icon("port", "GraphNode")
	_assert(port_icon != null and port_icon.get_size().x >= 24.0, "Connection ports must use a generous procedural hit icon.")
	var source_node := nodes[&"A_IN"] as GraphNode
	var target_node := nodes[&"AND_1"] as GraphNode
	var target_position_before_transform: Vector2 = target_node.position_offset
	graph.zoom = 0.72
	graph.scroll_offset = Vector2(135.0, 84.0)
	for _transform_frame: int in range(2):
		await process_frame
	var transform_probe := {
		"from_node": &"A_IN", "from_port": 0,
		"to_node": &"AND_1", "to_port": 0,
	}
	var transformed_curve: PackedVector2Array = graph.call("connection_curve", transform_probe)
	var graph_inverse: Transform2D = graph.get_global_transform().affine_inverse()
	var expected_source_port: Vector2 = graph_inverse * (
		source_node.get_global_transform() * source_node.get_output_port_position(0)
	)
	var expected_target_port: Vector2 = graph_inverse * (
		target_node.get_global_transform() * target_node.get_input_port_position(0)
	)
	_assert(
		transformed_curve.size() >= 2
		and transformed_curve[0].is_equal_approx(expected_source_port)
		and transformed_curve[-1].is_equal_approx(expected_target_port),
		"Custom cables must stay attached to the actual displayed ports after pan and non-unit zoom."
	)
	var transformed_overlay_curve: PackedVector2Array = main.call(
		"_connection_curve", &"A_IN", 0, &"AND_1", 0
	)
	var trace_overlay: Control = main.get("trace_overlay")
	var overlay_source_port: Vector2 = trace_overlay.get_global_transform().affine_inverse() * (
		source_node.get_global_transform() * source_node.get_output_port_position(0)
	)
	_assert(
		transformed_overlay_curve.size() >= 2
		and transformed_overlay_curve[0].is_equal_approx(overlay_source_port),
		"Trace playback must reuse the transformed displayed cable instead of a stale pre-pan path."
	)
	target_node.position_offset += Vector2(80.0, 40.0)
	for _move_frame: int in range(2):
		await process_frame
	var moved_curve: PackedVector2Array = graph.call("connection_curve", transform_probe)
	var moved_target_port: Vector2 = graph_inverse * (
		target_node.get_global_transform() * target_node.get_input_port_position(0)
	)
	_assert(
		not moved_curve[-1].is_equal_approx(transformed_curve[-1])
		and moved_curve[-1].is_equal_approx(moved_target_port),
		"Moving a component must update the cable endpoint and playback route on the displayed frame."
	)
	target_node.position_offset = target_position_before_transform
	graph.zoom = 1.0
	graph.scroll_offset = scroll_before_keys
	for _restore_transform_frame: int in range(2):
		await process_frame
	var compact_gate_size: Vector2 = (nodes[&"AND_1"] as GraphNode).size
	_assert(compact_gate_size.x <= 170.0 and compact_gate_size.y <= 115.0, "Basic gates must stay compact instead of occupying large cards; actual=%s." % compact_gate_size)
	var not_gate_size: Vector2 = (nodes[&"NOT_1"] as GraphNode).size
	_assert(not_gate_size.x <= 110.0 and not_gate_size.x < compact_gate_size.x and not_gate_size.y < compact_gate_size.y, "The one-input NOT must be visibly shorter and smaller than a two-input gate; NOT=%s AND=%s." % [not_gate_size, compact_gate_size])
	_assert(symbols.has(&"AND_1") and StringName(symbols[&"AND_1"].get("component_kind")) == &"and", "AND must be a procedural schematic symbol instead of a text-filled gate card.")
	_assert(symbols.has(&"OR_1") and StringName(symbols[&"OR_1"].get("component_kind")) == &"or", "OR must be a distinct procedural schematic symbol.")
	_assert(symbols.has(&"NOT_1") and StringName(symbols[&"NOT_1"].get("component_kind")) == &"not", "NOT must use the triangle-and-inversion-bubble schematic symbol.")
	_assert((symbols[&"AND_1"] as CircuitComponentSymbol).gate_label() == "and", "The AND symbol must visibly carry its English name.")
	_assert((symbols[&"OR_1"] as CircuitComponentSymbol).gate_label() == "or", "The OR symbol must visibly carry its English name.")
	_assert((symbols[&"NOT_1"] as CircuitComponentSymbol).gate_label() == "not", "The NOT symbol must visibly carry its English name.")
	var xor_symbol: Control = load("res://src/hardware_foundations/circuit_component_symbol.gd").new()
	xor_symbol.call("configure", LogicComponent.KIND_XOR, "", 66.0)
	_assert(StringName(xor_symbol.call("shape_profile")) == &"ieee_xor", "XOR must use a distinct extra-curve schematic silhouette rather than reusing OR unchanged.")
	xor_symbol.free()
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
	main.call("_on_connection_drag_started", &"A_IN", 0, true)
	var initial_targets: Array = graph.call("visible_connection_targets")
	_assert(initial_targets.size() == 6 and _target_is_valid(initial_targets, &"NOT_1", 0), "Starting from A must advertise every exact compatible input port, including NOT, before release.")
	_assert((nodes[&"A_IN"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")), "Wiring target rings must not replace the source port's live red/green/gray electrical color.")
	main.call("_on_connection_drag_ended")
	_assert((graph.call("visible_connection_targets") as Array).is_empty(), "Ending a cable gesture must clear every temporary target guide.")
	var fixed_source_symbol_color: Color = (symbols[&"A_IN"] as CircuitComponentSymbol).symbol_color()
	var idle_analysis_count: int = int(main.get("live_analysis_count"))
	for _idle_frame: int in range(3):
		await process_frame
	_assert(int(main.get("live_analysis_count")) == idle_analysis_count, "Live port analysis must be event-driven and must not run every frame while the circuit is unchanged.")

	main.call("_set_selected_ids", [&"A_IN"] as Array[StringName])
	_drag_select(graph, Vector2(600.0, 35.0), Vector2(790.0, 430.0), false)
	_assert((nodes[&"AND_1"] as GraphNode).selected and (nodes[&"OR_1"] as GraphNode).selected and not (nodes[&"A_IN"] as GraphNode).selected, "Ordinary empty-canvas drag must replace the selection with every intersected component.")
	_drag_select(graph, Vector2(1390.0, 600.0), Vector2(1390.0, 600.0), false)
	_assert((main.call("_selected_node_ids", false) as Array).is_empty(), "An ordinary click on empty canvas must clear the current component selection.")
	_shift_drag_select(graph, Vector2(600.0, 35.0), Vector2(790.0, 430.0))
	await process_frame
	_assert((nodes[&"AND_1"] as GraphNode).selected and (nodes[&"OR_1"] as GraphNode).selected, "Shift-drag must toggle every component/wire node inside its selection rectangle.")
	_assert(bool((symbols[&"AND_1"] as CircuitComponentSymbol).get("selection_active")) and (symbols[&"AND_1"] as CircuitComponentSymbol).symbol_color().is_equal_approx(Color("50d5ff")), "Selection must recolor the complete schematic symbol instead of drawing a separate blue circle.")
	_assert((nodes[&"AND_1"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("ff6b7d")), "Whole-component selection highlighting must leave the port's live electrical color unchanged.")
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
	main.call("_on_connection_drag_started", &"A_IN", 0, true)
	var duplicate_targets: Array = graph.call("visible_connection_targets")
	_assert(not _target_is_valid(duplicate_targets, &"NOT_1", 0), "An already-existing identical cable must show its destination as invalid instead of advertising a false valid drop.")
	main.call("_on_connection_drag_ended")
	_shortcut(main, KEY_Y)
	_assert(graph.get_connection_list().size() == 1, "A new edit after Undo must clear the redo branch.")
	_connect(main, &"NOT_1", 0, &"LAMP", 0)
	await process_frame
	_assert(graph.get_connection_list().size() == 2, "Tutorial connection requests must change the visible and simulated topology.")
	var hover_path: PackedVector2Array = main.call("_connection_curve", &"A_IN", 0, &"NOT_1", 0)
	var hover_motion := InputEventMouseMotion.new()
	hover_motion.position = hover_path[hover_path.size() / 2]
	graph.call("_gui_input", hover_motion)
	var hovered_wire: Dictionary = graph.get("hovered_connection")
	_assert(StringName(hovered_wire.get("from_node", &"")) == &"A_IN" and StringName(hovered_wire.get("to_node", &"")) == &"NOT_1", "Moving over the rendered cable must expose an exact-path hover highlight before branching or deletion; point=%s closest=%s hovered=%s." % [hover_motion.position, graph.get_closest_connection_at_point(hover_motion.position, 13.0), hovered_wire])
	_key(main, KEY_5)
	_shortcut(main, KEY_F)
	_assert(graph.get_connection_color_index(&"A_IN", 0, &"NOT_1", 0) == 4, "1–9 plus Ctrl+F must apply the chosen player hue to the hovered segment.")
	_shortcut(main, KEY_Z)
	_assert(graph.get_connection_color_index(&"A_IN", 0, &"NOT_1", 0) == 0, "Wire color changes must be atomic under Ctrl+Z without changing topology.")
	_shortcut(main, KEY_Y)
	_assert(graph.get_connection_color_index(&"A_IN", 0, &"NOT_1", 0) == 4, "Ctrl+Y must restore presentation-only wire color metadata.")
	hover_motion.position = Vector2(1390.0, 600.0)
	graph.call("_gui_input", hover_motion)
	_assert((graph.get("hovered_connection") as Dictionary).is_empty(), "Moving away from a cable must clear its temporary hover highlight.")
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
	_assert(bool(main.get("playback_running")) and (main.get("playback_batches") as Array).size() >= 4, "Changing a valid one-bit input must start causal color-flow playback automatically.")
	var saw_input_wire: bool = false
	var saw_not_process: bool = false
	var saw_output_wire: bool = false
	for batch: Dictionary in main.get("playback_batches"):
		main.call("_show_playback_batch", batch, 1.0)
		if _batch_has_wire(batch, &"A_IN", &"NOT_1"):
			saw_input_wire = true
			_assert((nodes[&"NOT_1"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("67e8a5")) and (nodes[&"NOT_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("67e8a5")), "The source wire must arrive before NOT changes its output.")
		if _batch_has_component(batch, &"NOT_1"):
			saw_not_process = true
			_assert((nodes[&"NOT_1"] as GraphNode).get_output_port_color(0).is_equal_approx(Color("ff6b7d")) and (nodes[&"LAMP"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("67e8a5")), "NOT processing must update its output before the downstream cable arrives.")
		if _batch_has_wire(batch, &"NOT_1", &"LAMP"):
			saw_output_wire = true
			_assert((nodes[&"LAMP"] as GraphNode).get_input_port_color(0).is_equal_approx(Color("ff6b7d")), "The lamp input must change only when the downstream wire wave arrives.")
	_assert(saw_input_wire and saw_not_process and saw_output_wire, "The one-bit animation must expose source-wire, component-process, and downstream-wire waves.")
	main.call("_finish_playback")
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
	_assert(StringName((symbols[&"A_IN"] as CircuitComponentSymbol).shape_profile()) == &"level_input_tag", "The level input must use a large directional input-pin silhouette instead of the old generic circle.")
	_assert(StringName((symbols[&"LAMP"] as CircuitComponentSymbol).shape_profile()) == &"lamp_probe", "The lamp must remain visually distinct from the level input terminal.")
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
	var not_symbol := symbols[&"NOT_1"] as CircuitComponentSymbol
	_assert((main.get("active_components") as Array).has(&"NOT_1") and not_symbol.processing_active and is_equal_approx(not_symbol.processing_progress, 0.5), "NOT processing must animate the real displayed NOT symbol inside its parallel wave.")
	_assert(not_symbol.processing_input_visuals.size() == 1 and (not_symbol.processing_input_visuals[0].get("color") as Color).is_equal_approx(Color("67e8a5")), "The NOT input token must carry the actual high/green input value into the displayed triangle.")
	_assert((not_symbol.processing_output_visual.get("color") as Color).is_equal_approx(Color("ff6b7d")), "The NOT output token must leave the inversion bubble with the actual low/red result.")
	_assert(StringName(overlay.get("mode")).is_empty() and (overlay.get("wire_pulses") as Array).is_empty(), "A component wave must not draw a second approximate component model or radial halo in the trace overlay.")

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
	var inherited_color_count: int = 0
	for connection: Dictionary in graph.get_connection_list():
		if graph.get_connection_color_index(
			connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"]
		) == 4:
			inherited_color_count += 1
	_assert(inherited_color_count == 3, "Splitting a colored segment must give the replacement trunk and both branch segments the original player hue.")
	var junction_node: GraphNode = _first_routing_node(main)
	_assert(junction_node != null and junction_node.draggable and junction_node.size.x < 100.0, "A branch point must be a small movable wire node, not another large component.")
	main.call("_set_selected_ids", [] as Array[StringName])
	_double_click_component(main, &"A_IN")
	_assert((nodes[&"A_IN"] as GraphNode).selected and junction_node.selected, "Double-clicking a routed component must select it together with explicit wire nodes connected to its pins.")
	_assert(not (nodes[&"NOT_1"] as GraphNode).selected and not (nodes[&"OR_1"] as GraphNode).selected, "Connected-route selection must not absorb the other endpoint components on the same electrical net.")
	main.call("_set_selected_ids", [] as Array[StringName])
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
	var completion_overlay: Control = main.get("level_completion_overlay")
	var completion_continue: Button = completion_overlay.get("continue_button")
	_assert(
		completion_overlay.visible
		and StringName(completion_overlay.get("current_level_id")) == &"tutorial"
		and not String((completion_overlay.get("summary_label") as Label).text).is_empty()
		and int(completion_overlay.get("music_cue_count")) == 1,
		"Completing the tutorial must automatically present its learning summary and one presentation-only music cue."
	)
	completion_continue.pressed.emit()
	for _completion_frame: int in range(2):
		await process_frame
	_assert(StringName(main.get("current_phase")) == &"campaign" and not completion_overlay.visible, "Continue on the completion window must return to the graphical level map.")
	_assert(not is_instance_valid(tutorial_next), "Returning through the completion window must release the old tutorial controls after their signal work is done.")
	campaign_buttons = main.get("campaign_level_buttons")
	_assert(not (campaign_buttons[&"half_adder"] as Button).disabled, "Completing the tutorial must unlock Half Adder on the visible level map.")
	_assert(not (campaign_buttons[&"latch"] as Button).disabled, "Completing the tutorial must independently unlock the storage branch without requiring Half Adder.")
	_assert((campaign_buttons[&"full_adder"] as Button).disabled, "Completing only the tutorial must not skip the Half Adder prerequisite for Full Adder.")
	var half_adder_map_button: Button = campaign_buttons[&"half_adder"]
	half_adder_map_button.pressed.emit()
	await process_frame
	_assert(not is_instance_valid(half_adder_map_button), "The clicked Half Adder map button must be released without a locked-object error.")
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	overlay = main.get("trace_overlay")
	_assert(StringName(main.get("current_phase")) == &"half_adder", "Tutorial completion must open the Half Adder challenge.")
	var half_adder_menu_kinds: Array[StringName] = []
	for template_variant: Variant in (main.get("component_menu_templates") as Dictionary).values():
		half_adder_menu_kinds.append(StringName(template_variant.kind))
	_assert(&"xor" not in half_adder_menu_kinds and &"and" in half_adder_menu_kinds and &"or" in half_adder_menu_kinds and &"not" in half_adder_menu_kinds, "Half Adder itself must be built from earlier gates; XOR unlocks only afterward.")
	_assert(graph.get_connection_list().is_empty(), "Half Adder challenge must not reveal a prewired solution template.")
	_assert(nodes.size() == 11 and nodes.has(&"SUM_OUT") and nodes.has(&"CARRY_OUT"), "Challenge must provide fixed Test Bench terminals and a spare-gate inventory.")
	_assert((nodes[&"SUM_OUT"] as GraphNode).draggable and (nodes[&"CARRY_OUT"] as GraphNode).draggable, "Half Adder output terminals must be freely movable like desktop schematic parts.")
	symbols = main.get("component_symbols")
	_assert(StringName((symbols[&"SUM_OUT"] as CircuitComponentSymbol).shape_profile()) == &"level_output_tag", "Half Adder probes must use the larger, directionally distinct level-output silhouette.")
	_assert((symbols[&"SUM_OUT"] as CircuitComponentSymbol).shape_profile() != (symbols[&"A_IN"] as CircuitComponentSymbol).shape_profile(), "Input and output terminals must not reuse the same visual shape.")
	_assert(not nodes.has(&"Profiler"), "Early logic section must not introduce the performance Profiler.")
	_assert((main.get("live_state") as CircuitLiveStateType).is_valid(), "A fresh unwired Half Adder must be a valid incomplete design, not a simulator error.")
	_assert((main.get("diagnostics_label") as Label).text.contains("这不是故障"), "The initial Half Adder diagnostic must explicitly distinguish an unwired design from a fault.")
	var empty_half_adder_snapshot: String = JSON.stringify(main.call("_capture_workbench_snapshot"))
	main.call("_enter_hint_workbench")
	main.call("_show_hint_level", 2)
	await process_frame
	_assert(
		(main.get("graph") as GraphEdit).get_connection_list().size() == 8
		and (main.get("component_nodes") as Dictionary).has(&"SUM_OUT")
		and (main.get("component_nodes") as Dictionary).has(&"CARRY_OUT")
		and _find_connection(main.get("graph"), &"AND_3", 0, &"CARRY_OUT", 0).is_empty(),
		"Half Adder hint stage 2 must reveal only the complete SUM subcircuit, not the CARRY answer."
	)
	main.call("_show_hint_level", 3)
	await process_frame
	var hint_half_adder: LogicCircuit = main.call("_circuit_from_graph")
	var hint_half_report: Dictionary = HalfAdderTestBenchType.new().run_official(hint_half_adder)
	_assert(
		(main.get("graph") as GraphEdit).get_connection_list().size() == 11
		and bool(hint_half_report.get("passed", false)),
		"Half Adder hint stage 3 must be a complete visible topology that genuinely passes the official truth table."
	)
	main.call("_exit_hint_workbench")
	for _half_hint_exit_frame: int in range(2):
		await process_frame
	graph = main.get("graph")
	nodes = main.get("component_nodes")
	overlay = main.get("trace_overlay")
	_assert(
		JSON.stringify(main.call("_capture_workbench_snapshot")) == empty_half_adder_snapshot
		and not bool(main.get("official_passed")),
		"Inspecting the complete Half Adder hint must not copy its answer or official success into the player's default workbench."
	)

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
	var and_symbol := symbols[&"AND_1"] as CircuitComponentSymbol
	var or_symbol := symbols[&"OR_1"] as CircuitComponentSymbol
	_assert(active_parallel.has(&"AND_1") and active_parallel.has(&"OR_1") and and_symbol.processing_active and or_symbol.processing_active, "AND and OR that are ready together must animate their real symbols in parallel.")
	_assert(StringName(overlay.get("mode")).is_empty(), "Parallel component activity must stay on the displayed symbols instead of creating overlay models.")
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
	_assert(
		(main.get("level_completion_overlay") as Control).visible
		and StringName((main.get("level_completion_overlay") as Control).get("current_level_id")) == &"half_adder",
		"Sealing the player's HalfAdder must automatically show its ownership-and-abstraction summary."
	)
	nodes = main.get("component_nodes")
	_assert(nodes.has(&"HalfAdder") and nodes.size() == 1, "The verified low-level graph must visibly collapse into one owned HalfAdder component.")
	var sealed = main.get("sealed_half_adder")
	var sealed_trace: CircuitTrace = sealed.evaluate(true, true)
	_assert(sealed_trace.outputs.get(&"SUM") == false and sealed_trace.outputs.get(&"CARRY") == true, "The reusable HalfAdder view must preserve the sealed circuit's behavior.")

	var game_content_signature: String = main.get("game_player_content").canonical_signature()
	var mode_option: OptionButton = main.get("mode_selector").get("option_button")
	mode_option.item_selected.emit(1)
	_assert(bool(game_mode.call("is_test_mode")), "Choosing Test mode in the shared selector must update the global service.")
	for _test_mode_frame: int in range(3):
		await process_frame
	var test_buttons: Dictionary = main.get("campaign_level_buttons")
	var all_test_levels_unlocked: bool = test_buttons.size() == 9
	for test_button: Button in test_buttons.values():
		all_test_levels_unlocked = all_test_levels_unlocked and not test_button.disabled
	_assert(all_test_levels_unlocked, "Test mode must make every registered campaign node enterable.")
	_assert(not bool(main.call("_is_level_unlocked", &"unknown")), "Test mode must not make unregistered level IDs enterable.")
	_assert((main.get("completed_levels") as Dictionary).is_empty(), "Unlocking Test mode must not fabricate completed-level evidence.")
	var test_library: Dictionary = main.get("component_library")
	_assert(test_library.size() == 9 and test_library.has(&"HalfAdder") and test_library.has(&"ALU4") and test_library.has(&"Register4") and test_library.has(&"TinyComputer"), "Test mode must provide an isolated temporary library sufficient to instantiate every level.")
	main.call("_start_campaign_level", &"load_store")
	await process_frame
	_assert(StringName(main.get("current_phase")) == &"prologue" and (main.get("graph") as GraphEdit).get_connection_list().size() == 5, "An end-of-prologue level must actually open in Test mode, not merely display an enabled map button.")
	mode_option.item_selected.emit(0)
	_assert(not bool(game_mode.call("is_test_mode")), "Choosing Game mode in the shared selector must leave Test mode.")
	for _game_mode_frame: int in range(3):
		await process_frame
	_assert(main.get("player_content").canonical_signature() == game_content_signature, "Returning to Game mode must restore its exact player progress without Test-mode helper content.")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: global test mode, compact NOT, whole-symbol selection, graphical map, wiring, and Hardware UI tests passed")
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


func _key(main: Control, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	main.call("_input", event)


func _component_menu_item_for_kind(main: Control, kind: StringName) -> int:
	var menu: MenuButton = main.get("component_menu_button")
	var templates: Dictionary = main.get("component_menu_templates")
	if menu == null:
		return -1
	var popup: PopupMenu = menu.get_popup()
	for item_index: int in range(popup.item_count):
		var metadata: Variant = popup.get_item_metadata(item_index)
		if metadata == null or not templates.has(String(metadata)):
			continue
		var template: LogicComponent = templates[String(metadata)]
		if template.kind == kind:
			return popup.get_item_id(item_index)
	return -1


func _click_control(control: Control) -> void:
	var position: Vector2 = control.get_global_rect().get_center()
	await _send_mouse_button(position, MOUSE_BUTTON_LEFT, true)
	await _send_mouse_button(position, MOUSE_BUTTON_LEFT, false)


func _drag_control(control: Control, delta: Vector2) -> void:
	var start: Vector2 = control.get_global_rect().get_center()
	var finish: Vector2 = start + delta
	await _send_mouse_button(start, MOUSE_BUTTON_LEFT, true)
	var motion := InputEventMouseMotion.new()
	motion.position = finish
	motion.global_position = finish
	motion.relative = delta
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion)
	await process_frame
	await _send_mouse_button(finish, MOUSE_BUTTON_LEFT, false)


func _scroll_control(control: Control) -> void:
	var position: Vector2 = control.get_global_rect().get_center()
	await _send_mouse_button(position, MOUSE_BUTTON_WHEEL_DOWN, true)
	await _send_mouse_button(position, MOUSE_BUTTON_WHEEL_DOWN, false)


func _send_mouse_button(position: Vector2, button_index: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button_index
	event.pressed = pressed
	event.factor = 1.0
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if button_index == MOUSE_BUTTON_LEFT and pressed else 0
	root.push_input(event)
	await process_frame


func _component_template_key_for_kind(main: Control, kind: StringName) -> String:
	var templates: Dictionary = main.get("component_menu_templates")
	for key: String in templates:
		var template: LogicComponent = templates[key]
		if template.kind == kind:
			return key
	return ""


func _shift_click_component(main: Control, component_id: StringName) -> void:
	var node: GraphNode = (main.get("component_nodes") as Dictionary)[component_id]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	click.shift_pressed = true
	click.position = node.size * 0.5
	main.call("_on_component_gui_input", click, component_id)


func _double_click_component(main: Control, component_id: StringName) -> void:
	var node: GraphNode = (main.get("component_nodes") as Dictionary)[component_id]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	click.double_click = true
	click.position = node.size * 0.5
	main.call("_on_component_gui_input", click, component_id)


func _shift_drag_select(graph: GraphEdit, start: Vector2, finish: Vector2) -> void:
	_drag_select(graph, start, finish, true)


func _drag_select(graph: GraphEdit, start: Vector2, finish: Vector2, shifted: bool) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.shift_pressed = shifted
	press.position = start
	graph.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.shift_pressed = shifted
	motion.position = finish
	graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.shift_pressed = shifted
	release.position = finish
	graph.call("_gui_input", release)


func _left_click_empty_canvas(graph: GraphEdit, position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = position
	graph.call("_gui_input", press)


func _first_event(trace: CircuitTrace, kind: StringName) -> CircuitEvent:
	for event: CircuitEvent in trace.events:
		if event.kind == kind:
			return event
	return null


func _batch_has_wire(batch: Dictionary, from_node: StringName, to_node: StringName) -> bool:
	for event: Variant in batch.get("events", []):
		if event.kind == &"wire_signal" \
				and event.from_component == from_node and event.to_component == to_node:
			return true
	return false


func _batch_has_component(batch: Dictionary, component_id: StringName) -> bool:
	for event: Variant in batch.get("events", []):
		if event.kind != &"wire_signal" and event.component_id == component_id:
			return true
	return false


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


func _target_is_valid(targets: Array, node_id: StringName, port: int) -> bool:
	for target_variant: Variant in targets:
		if not target_variant is Dictionary:
			continue
		var target := target_variant as Dictionary
		if StringName(target.get("node", &"")) == node_id and int(target.get("port", -1)) == port:
			return bool(target.get("valid", false))
	return false


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


func _control_fits(control: Control, parent: Control, margin: float) -> bool:
	return (
		control.position.x >= margin - 0.1
		and control.position.y >= margin - 0.1
		and control.position.x + control.size.x <= parent.size.x - margin + 0.1
		and control.position.y + control.size.y <= parent.size.y - margin + 0.1
	)


func _test_workbench_store_model() -> void:
	var store = CircuitWorkbenchStoreType.new("")
	var seed := {
		"schema_version": 1,
		"components": [{"id": "A", "kind": "input"}],
		"layout": {"A": {"x": 10.0, "y": 20.0}},
		"wires": [],
	}
	store.call("ensure_default", &"game", &"half_adder", seed)
	_assert(store.call("active_name", &"game", &"half_adder") == "default", "The model must create a deterministic default workbench.")
	_assert(StringName(store.call("create_workbench", &"game", &"half_adder", "方案 A", seed)) == &"", "The model must accept a unique Unicode workbench name.")
	_assert(StringName(store.call("create_workbench", &"game", &"half_adder", "方案 A", seed)) == &"duplicate", "Workbench names must be unique within one mode and level.")
	var changed: Dictionary = seed.duplicate(true)
	changed["wires"] = [{"from": "A", "from_port": 0, "to": "B", "to_port": 0}]
	_assert(bool(store.call("save_active", &"game", &"half_adder", changed)), "The active workbench snapshot must be replaceable without adding history.")
	store.call("ensure_default", &"test", &"half_adder", seed)
	_assert((store.call("active_snapshot", &"test", &"half_adder") as Dictionary)["wires"].is_empty(), "Test-mode workbenches must be isolated from Game-mode designs.")
	var manifest: Dictionary = store.call("manifest_snapshot")
	_assert(int(manifest.get("schema_version", 0)) == 1 and not JSON.stringify(manifest).contains("history"), "The durable manifest must be versioned and must not contain an operation chain.")
	var disk_path: String = ProjectSettings.globalize_path("res://.godot/test-workbench-store.json")
	if FileAccess.file_exists(disk_path):
		DirAccess.remove_absolute(disk_path)
	var disk_store = CircuitWorkbenchStoreType.new(disk_path)
	disk_store.call("ensure_default", &"game", &"tutorial", seed)
	disk_store.call("create_workbench", &"game", &"tutorial", "持久方案", changed)
	var reloaded_store = CircuitWorkbenchStoreType.new(disk_path)
	_assert(
		reloaded_store.call("active_name", &"game", &"tutorial") == "持久方案"
		and (reloaded_store.call("active_snapshot", &"game", &"tutorial") as Dictionary)["wires"].size() == 1,
		"A fresh store instance must reload the active named workbench and its topology from disk."
	)
	var incompatible_file := FileAccess.open(disk_path, FileAccess.WRITE)
	incompatible_file.store_string('{"schema_version":99,"namespaces":{"future":true}}')
	incompatible_file.close()
	var incompatible_store = CircuitWorkbenchStoreType.new(disk_path)
	incompatible_store.call("ensure_default", &"game", &"tutorial", seed)
	var preserved_file := FileAccess.open(disk_path, FileAccess.READ)
	_assert(
		not bool(incompatible_store.get("disk_write_allowed"))
		and preserved_file.get_as_text().contains('"schema_version":99'),
		"An unknown future workbench schema must fail closed without overwriting the player's file."
	)
	if FileAccess.file_exists(disk_path):
		DirAccess.remove_absolute(disk_path)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
