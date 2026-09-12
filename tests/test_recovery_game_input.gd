extends SceneTree

# Acceptance actions travel through the viewport's real GUI dispatch. Model and
# control reads below are observations; no reference loader or progress setter is used.
var evidence_root: String = "res://.godot/experience/game-input/"
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var ui: Control

func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			evidence_root = argument.trim_prefix("--evidence-dir=").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_root))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	observations.append({"ok": ok, "check": message})
	if not ok:
		failures.append(message)
		push_error(message)

func settle(frames: int = 5) -> void:
	for frame: int in range(frames):
		await process_frame

func point(at: Vector2, mask: int = 0, relative: Vector2 = Vector2.ZERO) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	motion.relative = relative
	motion.button_mask = mask
	root.push_input(motion, true)
	await process_frame

func click(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT, shift: bool = false) -> void:
	await point(at)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = button
		event.button_mask = (1 << (button - 1)) if down else 0
		event.pressed = down
		event.shift_pressed = shift
		root.push_input(event, true)
		await process_frame
	await settle(2)

func drag(from: Vector2, to: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await point(from)
	var event := InputEventMouseButton.new()
	event.position = from
	event.global_position = from
	event.button_index = button
	event.button_mask = 1 << (button - 1)
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	for step: int in range(1, 9):
		await point(from.lerp(to, step / 8.0), 1 << (button - 1), (to - from) / 8.0)
	event = InputEventMouseButton.new()
	event.position = to
	event.global_position = to
	event.button_index = button
	event.pressed = false
	root.push_input(event, true)
	await settle()

func key(code: Key, ctrl: bool = false, shift: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		event.ctrl_pressed = ctrl and OS.get_name() != "macOS"
		event.meta_pressed = ctrl and OS.get_name() == "macOS"
		event.shift_pressed = shift
		root.push_input(event, true)
		await process_frame
	await settle(3)

func type_text(value: String) -> void:
	for character: String in value:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame

func frequency() -> void:
	await press(ui.clock_period_control.get_line_edit())
	await key(KEY_A, true)
	await type_text("120")
	await key(KEY_ENTER)
	await click(ui.graph.global_position + Vector2(28, ui.graph.size.y-28))
	check(ui.clock_period_control.value == 120, "Playback Hz can be edited through its text field, then focus returns to the graph.")

func wait_playback() -> void:
	var deadline: int = Time.get_ticks_msec() + 45000
	while (ui.official_sequence_active or ui.playback_running or ui.sealing) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not ui.official_sequence_active and not ui.playback_running and not ui.sealing, "Visible playback and sealing finish without internal fast-forward calls.")

func press(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(), "Requested UI control exists and is visible.")
	if control == null or not control.is_visible_in_tree():
		return
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			var scroll := parent as ScrollContainer
			for attempt: int in range(40):
				var rect: Rect2 = control.get_global_rect()
				if scroll.get_global_rect().encloses(rect):
					break
				await click(scroll.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_UP if rect.position.y < scroll.global_position.y else MOUSE_BUTTON_WHEEL_DOWN)
		parent = parent.get_parent()
	await click(control.get_global_rect().get_center())
	await settle()

func named_button(parent: Node, label: String) -> Button:
	for child: Node in parent.get_children():
		if child is Button and child.is_visible_in_tree() and child.text == label:
			return child as Button
		var found: Button = named_button(child, label)
		if found != null:
			return found
	return null

func text(key_name: StringName) -> String:
	return root.get_node("Localization").text(key_name)

func capture(label: String) -> void:
	if "--recovery-capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var locale: String = root.get_node("Localization").current_locale()
		root.get_texture().get_image().save_png(evidence_root + locale + "-" + label + ".png")

func dismiss_briefing() -> void:
	if not ui.mission_briefing_active:
		return
	for attempt: int in range(8):
		if not ui.mission_briefing_active:
			break
		await press(ui.mission_briefing_continue_button)
	check(not ui.mission_briefing_active and ui.mission_compact, "Start leaves a compact movable Mission.")

func close_window(id: StringName) -> void:
	var window: Control = ui.desktop_windows[id]
	if window.visible:
		# Another freely positioned instrument can cover this window's title bar.
		# Its dock toggle is always exposed and closes it through ordinary input.
		var dock_button: Button = ui.desktop_window_buttons.get(id)
		await press(dock_button if dock_button != null and dock_button.is_visible_in_tree()
			else window.find_child("CloseButton", true, false))
		check(not window.visible, "The visible window close control closes %s." % id)

func named_design() -> void:
	await press(ui.workbench_menu_button)
	await key(KEY_DOWN)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(ui.workbench_name_dialog.visible, "The actual workbench menu opens New Design.")
	if not ui.workbench_name_dialog.visible:
		return
	await type_text("Recovery A")
	await key(KEY_ENTER)
	check(ui.active_workbench_name == "Recovery A" and not ui.workbench_name_dialog.visible, "Typing and confirming creates a named player design.")
	await dismiss_briefing()

func port(id: StringName, index: int, output: bool) -> Vector2:
	var node: GraphNode = ui.component_nodes[id]
	return node.get_global_transform() * (node.get_output_port_position(index) if output else node.get_input_port_position(index))

func wire(source: StringName, target: StringName, out_port: int = 0, in_port: int = 0) -> void:
	await drag(port(source, out_port, true), port(target, in_port, false))
	if not ui.graph.is_node_connected(source, out_port, target, in_port):
		await capture("failed-wire-%s-%s" % [source, target])
		print("WIRE INPUT FAILURE: ", source, " -> ", target, " status=", ui.status_label.text,
			" source=", port(source, out_port, true), " target=", port(target, in_port, false))
	check(ui.graph.is_node_connected(source, out_port, target, in_port), "UI wire %s:%d → %s:%d" % [source, out_port, target, in_port])

func snapshot() -> String:
	var nodes: Dictionary = {}
	var ids: Array = ui.component_nodes.keys()
	ids.sort()
	for id: StringName in ids:
		nodes[id] = ui.component_nodes[id].position_offset
	var colors: Dictionary = {}
	for connection: Dictionary in ui.graph.get_connection_list():
		var id: String = "%s:%d>%s:%d" % [connection.from_node, connection.from_port, connection.to_node, connection.to_port]
		colors[id] = ui.graph.get_connection_color_index(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
	colors.sort()
	return JSON.stringify({"name": ui.active_workbench_name, "nodes": nodes, "circuit": ui.current_circuit.canonical_signature(), "colors": colors})

func hint_roundtrip(inspect_id: StringName = &"NOT_1") -> void:
	await close_window(&"components")
	var view_before: Dictionary = ui._capture_player_view()
	var before: String = snapshot()
	check(not ui.hint_mode and not ui.hint_confirmation.visible, "Hints and spoiler confirmation are hidden by default.")
	await press(ui.hint_button)
	check(ui.hint_mode and ui.hint_level == 1 and ui.graph.get_connection_list().is_empty(), "H1 enters only the independent interface canvas.")
	check(not ui.mission_compact and ui.task_box.find_child("HintExplanation",true,false).is_visible_in_tree(), "H1 opens its readable explanation instead of inheriting a compact Mission.")
	var hint_fold: Button = ui.desktop_windows[&"task"].find_child("MinimizeButton",true,false)
	await press(hint_fold)
	await press(hint_fold)
	check(not ui.mission_briefing_active and ui.task_box.find_child("MissionBriefing",true,false)==null and ui.task_box.find_child("HintExplanation",true,false).is_visible_in_tree(), "Expanding Hint keeps its explanation and never substitutes the player briefing.")
	await capture(String(ui.current_level_id) + "-hint-1")
	await press(ui.hint_button)
	check(ui.hint_level == 1 and ui.pending_hint_level == 2, "Requesting H2 does not reveal it.")
	await key(KEY_ESCAPE)
	check(ui.hint_level == 1 and ui.pending_hint_level == 0, "Escape cancels only the spoiler confirmation.")
	await press(ui.hint_button)
	await press(ui.hint_confirm_button)
	check(ui.hint_level == 2 and ui.graph.get_connection_list().size() > 0, "Separate confirmation reveals the relevant H2 partial circuit.")
	await capture(String(ui.current_level_id) + "-hint-2")
	await press(ui.hint_button)
	check(ui.hint_level == 2 and ui.pending_hint_level == 3 and ui.hint_confirmation_text.text.contains(text(&"hardware.hint.confirm.3").split("\n")[0]), "H3 requires an explicit complete-answer warning.")
	await capture(String(ui.current_level_id) + "-hint-3-confirm")
	await press(ui.hint_cancel_button)
	check(ui.hint_level == 2, "Cancelling H3 keeps H2.")
	await press(ui.hint_button)
	await press(ui.hint_confirm_button)
	check(ui.hint_level == 3 and ui.hint_button.disabled, "H3 appears only after its own confirmation and cannot advance.")
	var readonly_before: String = snapshot()
	var node: GraphNode = ui.component_nodes[inspect_id]
	await drag(node.get_global_rect().get_center(), node.get_global_rect().get_center() + Vector2(60, 30))
	await key(KEY_DELETE)
	await key(KEY_C, true)
	check(snapshot() == readonly_before and ui.clipboard_components.is_empty(), "Hint input cannot move, delete, or copy the reference.")
	await close_window(&"inspector")
	var hint_zoom: float = ui.graph.zoom
	await click(node.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_UP)
	check(ui.graph.zoom != hint_zoom, "A read-only hint still accepts wheel zoom over a component.")
	var hint_scroll: Vector2 = ui.graph.scroll_offset
	var pan := InputEventKey.new()
	pan.pressed = true
	pan.keycode = KEY_D
	pan.physical_keycode = KEY_D
	Input.parse_input_event(pan)
	await create_timer(0.1).timeout
	pan.pressed = false
	Input.parse_input_event(pan)
	await settle()
	check(ui.graph.scroll_offset != hint_scroll, "A read-only hint still accepts WASD panning.")
	await press(ui.hint_exit_button)
	if snapshot() != before:
		var mismatch := FileAccess.open(evidence_root + "hint-return-diff.json", FileAccess.WRITE)
		mismatch.store_string(JSON.stringify({"before": JSON.parse_string(before), "after": JSON.parse_string(snapshot())}, "\t"))
	check(not ui.hint_mode and snapshot() == before, "Hint return preserves player name, topology, positions and wire colors exactly.")
	check(ui.mission_compact==view_before.compact,"Hint return preserves the player's compact Mission state.")
	check(is_equal_approx(ui.graph.zoom,view_before.zoom) and ui.graph.scroll_offset.is_equal_approx(view_before.scroll),"Hint return restores the player camera instead of fitting to the reference view.")
	for row: Dictionary in view_before.windows:
		var window: Control=ui.desktop_windows[row.id]
		check(window.visible==row.state.visible and window.position.is_equal_approx(row.state.position) and window.size.is_equal_approx(row.state.size),"Hint preserves window visibility and geometry: "+String(row.id))
	check(ui.wire_history.is_empty() and ui.redo_history.is_empty(), "Hint return retains the documented ADR 0015 history reset.")
	await dismiss_briefing()
	await press(ui.hint_button)
	check(ui.hint_level == 3 and not ui.hint_confirmation.visible, "Reentry remembers the explicitly viewed level without upgrading it.")
	await press(ui.hint_exit_button)
	await dismiss_briefing()

func place(kind: StringName, at: Vector2) -> StringName:
	var before: Array = ui.component_nodes.keys()
	if not ui.desktop_windows[&"components"].visible:
		await press(ui.desktop_window_buttons[&"components"])
	for item: Control in ui.component_palette_items.values():
		if item.component_kind == kind:
			await press(item)
			break
	var toolbox_rect: Rect2 = ui.desktop_windows[&"components"].get_global_rect()
	if toolbox_rect.has_point(at): at.x = toolbox_rect.position.x - 80
	var expected: Vector2 = ((at - ui.graph.global_position + ui.graph.scroll_offset) / ui.graph.zoom - ui.graph.placement_preview_size * 0.5).snapped(Vector2(20, 20))
	await point(at)
	await capture("placement-preview")
	await click(at)
	await key(KEY_ESCAPE)
	await close_window(&"components")
	for id: StringName in ui.component_nodes:
		if not before.has(id):
			check(ui.component_catalog[id].kind == kind, "Palette input places the requested component.")
			check(ui.component_nodes[id].position_offset.is_equal_approx(expected), "The drop matches its preview's snapped graph coordinates under the current zoom and pan.")
			return id
	check(false, "Palette input must create a component.")
	return &""

func curve_point(target: StringName, input_index: int = 0) -> Vector2:
	for connection: Dictionary in ui.graph.get_connection_list():
		if connection.to_node == target and connection.to_port == input_index:
			var curve: PackedVector2Array = ui.graph.connection_curve(connection)
			return ui.graph.global_position + curve[curve.size() / 2]
	check(false, "A rendered wire must exist for gesture targeting.")
	return Vector2.ZERO

func editing_roundtrip() -> void:
	await close_window(&"task")
	await close_window(&"test_bench")
	await palette_drag_roundtrip(false)
	await palette_drag_roundtrip(true)
	await palette_drag_roundtrip(true, true)
	await palette_drag_roundtrip(false, false, &"escape")
	await palette_drag_roundtrip(true, false, &"escape")
	await palette_drag_roundtrip(true, false, &"focus_out")
	await palette_drag_roundtrip(false, false, &"right_click")
	var and_id: StringName = await place(&"and", ui.graph.global_position + Vector2(900, 390))
	var or_id: StringName = await place(&"or", ui.graph.global_position + Vector2(1160, 475))
	if and_id.is_empty() or or_id.is_empty():
		return
	var count_before: int = ui.component_nodes.size()
	await drag(curve_point(&"NOT_1"), port(and_id, 0, false))
	check(ui.component_nodes.size() == count_before + 1 and ui.graph.get_connection_list().size() == 4, "Dragging from a rendered wire middle adds an explicit three-way junction.")
	var branched: String = snapshot()
	await capture("wire-middle-branch")
	await point(curve_point(and_id))
	check(ui.graph.hovered_net.size() == 3, "Hover follows the three connected network segments, without crossing the NOT gate.")
	var wire_description: String = ui.graph.get_tooltip(curve_point(and_id) - ui.graph.global_position)
	var scalar_label: String = "1 位" if root.get_node("Localization").current_locale() == "zh_CN" else "1-bit"
	check(wire_description.contains(scalar_label) and wire_description.contains("→"), "The wire probe explains localized width and endpoint direction.")
	await capture("network-inspection")
	await click(curve_point(and_id), MOUSE_BUTTON_RIGHT)
	check(ui.component_nodes.size() == count_before + 1 and ui.graph.get_connection_list().size() == 3, "Precise right-click removes only the targeted wire segment.")
	await key(KEY_Z, true)
	check(snapshot() == branched, "Undo restores the erased branch with original color and endpoints.")
	await key(KEY_Y, true)
	check(ui.graph.get_connection_list().size() == 3, "Redo erases the same branch.")
	await key(KEY_Z, true)
	await drag(port(and_id, 0, false), port(or_id, 0, false))
	check(ui.graph.get_connection_list().size() == 6 and ui.component_nodes.size() == count_before + 2, "An already wired input continues its network using exactly one new junction and no native phantom wire.")
	await capture("wire-end-continuation")
	var original_node: GraphNode = ui.component_nodes[and_id]
	await click(original_node.get_global_rect().get_center())
	await close_window(&"inspector")
	await key(KEY_C, true)
	var before_paste: int = ui.component_nodes.size()
	await key(KEY_V, true)
	check(ui.component_nodes.size() == before_paste + 1, "Copy/paste duplicates a selected player component through shortcuts.")
	await key(KEY_Z, true)
	check(ui.component_nodes.size() == before_paste, "Undo removes the pasted component.")
	# The toolbox is intentionally open on entry; close it through its dock before a marquee extending across that area.
	await close_window(&"components")
	var original_pos: Vector2 = original_node.position_offset
	var other_node: GraphNode = ui.component_nodes[or_id]
	var other_pos: Vector2 = other_node.position_offset
	# Leave enough space around the bodies for a true empty-canvas start after
	# the panel-aware camera fit; a small inset can land on the nearby NOT gate.
	var rectangle: Rect2 = original_node.get_global_rect().merge(other_node.get_global_rect()).grow(80)
	await drag(rectangle.position, rectangle.end)
	check(original_node.selected and other_node.selected, "Empty-canvas marquee selects multiple component bodies.")
	await drag(original_node.get_global_rect().get_center(), original_node.get_global_rect().get_center() + Vector2(40, -40))
	check(original_node.position_offset != original_pos and other_node.position_offset != other_pos, "Dragging a selected body moves the whole selection.")
	await key(KEY_Z, true)
	check(original_node.position_offset == original_pos and other_node.position_offset == other_pos, "One undo restores the multi-selection move.")

func palette_drag_roundtrip(empty_motion_mask: bool, onto_instrument: bool = false, cancel_action: StringName = &"") -> void:
	var before: String = snapshot()
	var original_ids: Array = ui.component_nodes.keys()
	if not ui.desktop_windows[&"components"].visible:
		await press(ui.desktop_window_buttons[&"components"])
	if onto_instrument:
		await press(ui.desktop_window_buttons[&"test_bench"])
	var item: Control
	for candidate: Control in ui.component_palette_items.values():
		if candidate.component_kind == &"and":
			item = candidate
			break
	check(item != null, "Tutorial exposes a draggable AND card.")
	if item == null:
		return
	var from: Vector2 = item.get_global_rect().get_center()
	var to: Vector2 = ui.graph.global_position + Vector2(860, 300)
	var toolbox_rect: Rect2 = ui.desktop_windows[&"components"].get_global_rect()
	if toolbox_rect.has_point(to): to.x = toolbox_rect.position.x - 80
	if onto_instrument:
		to = ui.desktop_windows[&"test_bench"].get_global_rect().get_center()
	await point(from)
	var held := InputEventMouseButton.new()
	held.button_index = MOUSE_BUTTON_LEFT
	held.pressed = true
	held.position = Vector2(-1000, -1000)
	if empty_motion_mask:
		Input.parse_input_event(held)
		Input.flush_buffered_events()
	var event := InputEventMouseButton.new()
	event.position = from
	event.global_position = from
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	var expected: Vector2 = ui.graph.graph_position_for_local_pointer(to - ui.graph.global_position, ui.graph.placement_preview_size)
	for step: int in range(1, 9):
		await point(from.lerp(to, step / 8.0), 0 if empty_motion_mask else MOUSE_BUTTON_MASK_LEFT, (to - from) / 8.0)
	if not onto_instrument:
		check(root.gui_is_dragging() and ui.graph.placement_preview_control != null
			and ui.graph.placement_preview_control.visible
			and ui.graph.placement_pointer.is_equal_approx(to - ui.graph.global_position),
			"Held drag shows the canvas ghost at the latest input position.")
	else:
		check(not ui.graph.placement_has_pointer and not ui.graph.placement_preview_control.visible,
			"Dragging over a floating instrument hides the invalid placement ghost.")
	if cancel_action == &"escape":
		await key(KEY_ESCAPE)
	elif cancel_action == &"focus_out":
		root.propagate_notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		await settle()
	elif cancel_action == &"right_click":
		await click(to, MOUSE_BUTTON_RIGHT)
	if not cancel_action.is_empty():
		check(not root.gui_is_dragging() and ui.armed_component_template_key.is_empty(),
			"%s cancels both the Godot drag payload and the placement ghost before release." % cancel_action)
	var cancelled: bool = onto_instrument or not cancel_action.is_empty()
	event = InputEventMouseButton.new()
	event.position = to
	event.global_position = to
	event.button_index = MOUSE_BUTTON_LEFT
	root.push_input(event, true)
	if empty_motion_mask:
		held.pressed = false
		Input.parse_input_event(held)
		Input.flush_buffered_events()
	await settle()
	check(ui.component_nodes.size() == original_ids.size() + (0 if cancelled else 1), "A valid drag places one item; an invalid or cancelled drag places none, including on a later release.")
	for id: StringName in ui.component_nodes:
		if not original_ids.has(id):
			check(ui.component_nodes[id].position_offset.is_equal_approx(expected), "Palette drop matches the snapped ghost position: expected %s, got %s." % [expected, ui.component_nodes[id].position_offset])
	check(ui.armed_component_template_key.is_empty(), "A completed drag returns to editing instead of leaving an extra placement ghost.")
	if not cancelled:
		await key(KEY_Z, true)
	check(snapshot() == before, "Undo or a cancelled drop preserves the original circuit exactly.")
	if onto_instrument:
		await close_window(&"test_bench")
	await close_window(&"components")


func complete_tutorial() -> void:
	await close_window(&"task")
	await close_window(&"test_bench")
	for id: StringName in ui.component_nodes.keys():
		if ui.component_catalog[id].kind in [&"and", &"or"]:
			await click(ui.component_nodes[id].get_global_rect().get_center())
			await close_window(&"inspector")
			await key(KEY_DELETE)
	await press(ui.desktop_window_buttons[&"test_bench"])
	await frequency()
	await press(ui.input_a_button)
	await press(named_button(ui.desktop_windows[&"test_bench"], text(&"hardware.practice.run")))
	await wait_playback()
	check(ui.completed_levels.has(&"tutorial") and ui.level_completion_overlay.visible, "Five real Tutorial actions earn ordinary Game completion and an explicit Continue.")
	await capture("tutorial-success")
	if ui.level_completion_overlay.visible:
		await press(ui.level_completion_overlay.continue_button)
	check(ui.current_level_id == &"half_adder", "Continue enters Half Adder through the original progression gate.")

func camera_and_windows() -> void:
	await close_window(&"components")
	await close_window(&"task")
	await close_window(&"test_bench")
	var geometry_before: String = snapshot()
	var zoom_before: float = ui.graph.zoom
	await click(ui.graph.get_global_rect().end - Vector2(80, 100), MOUSE_BUTTON_WHEEL_DOWN)
	check(ui.graph.zoom != zoom_before, "Wheel input zooms the editable canvas.")
	var scroll_before: Vector2 = ui.graph.scroll_offset
	var from: Vector2 = ui.graph.get_global_rect().end - Vector2(80, 100)
	await drag(from, from + Vector2(-90, -35), MOUSE_BUTTON_MIDDLE)
	check(ui.graph.scroll_offset != scroll_before and snapshot() == geometry_before, "Middle-drag pans the camera without changing topology, positions, or wire colors.")
	var extra: StringName = await place(&"not", ui.graph.global_position + Vector2(1050, 100))
	if not extra.is_empty():
		var junction: StringName = &"JUNCTION_001"
		await wire(junction, extra)
		await click(ui.component_nodes[extra].get_global_rect().get_center())
		await close_window(&"inspector")
		check(ui.graph.has_focus(), "Closing Inspector returns keyboard focus to the selected circuit.")
		await key(KEY_DELETE)
		check(not ui.component_nodes.has(extra), "A transformed wire-node connection and later Delete remain editable.")
	await press(ui.mission_summary_button)
	var window: Control = ui.desktop_windows[&"task"]
	var header: Control = window.find_child("WindowHeader", true, false)
	var position_before: Vector2 = window.position
	await drag(header.global_position + Vector2(100, 15), header.global_position + Vector2(145, 35))
	check(window.position != position_before, "Mission remains a movable desktop window.")
	await press(window.find_child("MinimizeButton", true, false))
	await close_window(&"task")
	await press(ui.mission_summary_button)
	check(window.visible and ui.mission_briefing_active, "The persistent short goal restores the closed Mission with Previous/Next.")
	await dismiss_briefing()
	await close_window(&"task")
	await close_window(&"test_bench")
	if DisplayServer.get_name() == "headless":
		return
	var window_mode: int = root.mode
	await press(ui.fullscreen_button)
	check(root.mode != window_mode, "The real fullscreen button changes the window mode.")
	await capture("fullscreen-editable")
	check(ui.get_global_rect().encloses(ui.mission_summary_button.get_global_rect()), "The short goal stays on screen in fullscreen.")
	await press(ui.fullscreen_button)
	check(root.mode == window_mode, "The same fullscreen control returns to the window.")
	await capture("window-editable")

func build_half_adder() -> void:
	await capture("half-adder-mission")
	check(ui.terminology_handbook.is_term_unlocked(&"half_adder") and ui.terminology_handbook.is_term_unlocked(&"sr_latch"), "Earned Tutorial progress opens both original learning branches in the Handbook.")
	await dismiss_briefing()
	await named_design()
	await close_window(&"task")
	await close_window(&"test_bench")
	await frequency()
	await press(ui.desktop_window_buttons[&"test_bench"])
	var before_example: String = snapshot()
	await press(ui.side_box.find_child("TryCase3", true, false))
	check(ui.input_a_button.button_pressed and ui.input_b_button.button_pressed, "Clicking the 1 1 example selects both visible Test Bench inputs.")
	check(snapshot() == before_example and not ui.official_passed and not ui.official_sequence_active, "Trying a truth-table input neither wires an answer nor performs or passes the full test.")
	await capture("half-adder-test-bench")
	await close_window(&"test_bench")
	# A second, manually wired expression: (A OR B) AND NOT(A AND B).
	# Reuse the supplied gates; this deliberately differs from the H3 topology.
	var sum_and := &"AND_1"
	var carry_and := &"AND_1_COPY_002"
	await wire(&"A_IN", &"OR_1")
	await wire(&"B_IN", &"OR_1", 0, 1)
	await wire(&"A_IN", carry_and)
	await wire(&"B_IN", carry_and, 0, 1)
	await wire(carry_and, &"CARRY_OUT")
	await wire(carry_and, &"NOT_1")
	await wire(&"OR_1", sum_and)
	await wire(&"NOT_1", sum_and, 0, 1)
	await wire(sum_and, &"SUM_OUT")
	# Remove unused player gates with visible selection and Delete.
	await click(ui.component_nodes[&"AND_2"].get_global_rect().get_center())
	await close_window(&"inspector")
	await click(ui.component_nodes[&"NOT_1_COPY_001"].get_global_rect().get_center(), MOUSE_BUTTON_LEFT, true)
	await key(KEY_DELETE)
	check(not ui.component_nodes.has(&"AND_2") and not ui.component_nodes.has(&"NOT_1_COPY_001"), "Delete removes selected unused gates while test terminals remain.")
	await capture("half-adder-player-circuit")
	await hint_roundtrip(&"NOT_1")
	await official_and_seal()


func focus_view_check() -> void:
	await close_window(&"task")
	await close_window(&"test_bench")
	var before: String = snapshot()
	await key(KEY_HOME, false, true)
	check(snapshot() == before, "Shift+Home fits the circuit without moving components or changing any wires.")
	for node: GraphNode in ui.component_nodes.values():
		check(ui.graph.get_global_rect().encloses(node.get_global_rect()), "Fit all keeps every component inside the canvas.")
	var node: GraphNode = ui.component_nodes[&"NOT_1"]
	await click(node.get_global_rect().get_center())
	await close_window(&"inspector")
	await press(named_button(ui.editor_toolbar, text(&"hardware.view.focus")))
	check(ui.graph.zoom > 1.0 and snapshot() == before, "The visible Focus action enlarges a selected component without editing it.")
	await capture("focused-component")
	await key(KEY_HOME, false, true)
	await press(ui.mission_summary_button)
	root.size = Vector2i(1280, 720)
	await settle(10)
	check(ui.get_global_rect().encloses(ui.mission_summary_button.get_global_rect()), "The goal bar stays reachable at 1280×720.")
	check(ui.graph.get_global_rect().encloses(ui.desktop_windows[&"task"].get_global_rect()), "The movable Mission fits the smaller canvas.")
	await capture("mission-1280")
	root.size = Vector2i(1600, 900)
	await settle(10)
	await dismiss_briefing()
	await close_window(&"task")

func official_and_seal() -> void:
	if not ui.desktop_windows[&"test_bench"].visible:
		await press(ui.desktop_window_buttons[&"test_bench"])
	await press(ui.official_button)
	await wait_playback()
	check(ui.official_passed, "%s passes its complete unchanged behavior tests using only UI-built topology." % ui.current_level_id)
	if not ui.official_passed:
		await capture(String(ui.current_level_id) + "-failed-test")
		print("FAILED TEST TOPOLOGY: ", ui.graph.get_connection_list())
		return
	await capture(String(ui.current_level_id) + "-tested")
	if ui.level_completion_overlay.visible:
		check(ui.level_completion_overlay.primary_action_button.text == ui.seal_button.text and ui.level_completion_overlay.primary_action_button.text != text(&"hardware.prologue.seal"), "After a passing test, the success action explicitly offers sealing the verified component.")
		await press(ui.level_completion_overlay.primary_action_button)
	else:
		if not ui.desktop_windows[&"task"].visible:
			await press(ui.desktop_window_buttons[&"task"])
		await press(ui.seal_button)
	check(ui.encapsulation_effect.active and ui.encapsulation_effect.module_label.text == String(ui.current_level_definition.get("seal_name", &"HalfAdder")), "Sealing visibly names the actual verified module being saved.")
	await capture(String(ui.current_level_id) + "-sealing")
	await wait_playback()
	check(ui.level_completion_overlay.visible, "Sealing shows success and lets the player choose the next step.")
	check(not ui.level_completion_overlay.next_capability_label.text.is_empty(), "Completion explains the next capability on the original route.")
	if ui.level_completion_overlay.visible:
		await press(ui.level_completion_overlay.return_button)
	check(ui.current_phase == &"campaign", "Explicit return after sealing restores the original map.")

func enter_level(id: StringName) -> void:
	check(ui.current_phase == &"campaign" and not ui.campaign_level_buttons[id].disabled, "%s is unlocked by actual prior Game builds." % id)
	await press(ui.campaign_level_buttons[id])
	check(ui.desktop_windows[&"components"].visible, "Every construction level opens its toolbox before editing.")
	check(ui.mission_briefing_panel.find_child("SignalGuide", true, false) != null, "Mission explains this lesson's signal widths before construction.")
	await capture(String(id) + "-signal-guide")
	await dismiss_briefing()
	await close_window(&"task")
	await close_window(&"test_bench")
	await frequency()

func connect_actions(actions: Array) -> void:
	for action: Array in actions:
		await wire(StringName(action[0]), StringName(action[1]), int(action[2]) if action.size() > 2 else 0, int(action[3]) if action.size() > 3 else 0)

func build_prerequisites() -> void:
	await enter_level(&"full_adder")
	await connect_actions([
		["A_IN", "HA_1"], ["B_IN", "HA_1", 0, 1], ["HA_1", "HA_2"], ["CIN_IN", "HA_2", 0, 1],
		["HA_1", "OR_1", 1, 0], ["HA_2", "OR_1", 1, 1], ["HA_2", "SUM_OUT"], ["OR_1", "COUT_OUT"]])
	await official_and_seal()
	if ui.current_phase != &"campaign": return
	await enter_level(&"alu")
	await connect_actions([
		["A_IN", "AND_1"], ["B_IN", "AND_1", 0, 1], ["A_IN", "OR_1"], ["B_IN", "OR_1", 0, 1], ["A_IN", "NOT_1"],
		["A_IN", "FULL_ADDER"], ["B_IN", "FULL_ADDER", 0, 1], ["CIN_IN", "FULL_ADDER", 0, 2],
		["AND_1", "MUX"], ["OR_1", "MUX", 0, 1], ["FULL_ADDER", "MUX", 0, 2], ["NOT_1", "MUX", 0, 3],
		["OP0_IN", "MUX", 0, 4], ["OP1_IN", "MUX", 0, 5], ["MUX", "RESULT_OUT"], ["FULL_ADDER", "CARRY_OUT", 1, 0]])
	await official_and_seal()
	if ui.current_phase != &"campaign": return
	await enter_level(&"latch")
	await connect_actions([
		["S_IN", "NOR_Q"], ["R_IN", "NOR_NQ", 0, 1], ["NOR_NQ", "NOR_Q", 0, 1],
		["NOR_Q", "NOR_NQ"], ["NOR_NQ", "Q_OUT"], ["NOR_Q", "NQ_OUT"]])
	await official_and_seal()
	if ui.current_phase != &"campaign": return
	await enter_level(&"register")
	await connect_actions([
		["D_IN", "NOT_D"], ["D_IN", "AND_S"], ["LOAD_IN", "AND_S", 0, 1], ["NOT_D", "AND_R"],
		["LOAD_IN", "AND_R", 0, 1], ["AND_S", "LATCH"], ["AND_R", "LATCH", 0, 1], ["LATCH", "Q_OUT"]])
	await official_and_seal()
	if ui.current_phase != &"campaign": return
	await enter_level(&"ram")
	await connect_actions([
		["ADDR_IN", "DECODER"], ["WRITE_IN", "DECODER", 0, 1], ["DATA_IN", "REG_0"], ["DATA_IN", "REG_1"],
		["DECODER", "REG_0", 0, 1], ["DECODER", "REG_1", 1, 1], ["REG_0", "MUX"], ["REG_1", "MUX", 0, 1],
		["ADDR_IN", "MUX", 0, 2], ["MUX", "OUT"]])
	await official_and_seal()

func build_cpu() -> void:
	await enter_level(&"cpu")
	check(not ui.official_button.disabled and ui.component_nodes[&"RAM"].draggable, "CPU exposes all modules and complete tests before connecting any stage.")
	await press(ui.mission_summary_button)
	await capture("cpu-mission")
	await dismiss_briefing()
	await close_window(&"task")
	await close_window(&"test_bench")
	await inspect_width_draft(&"RAM", 0, false, 1)
	await inspect_width_draft(&"CONTROL", 0, false, 2)
	await inspect_width_draft(&"RAM", 1, false, 4)
	var before_invalid: int = ui.graph.get_connection_list().size()
	await drag(port(&"OP_IN", 0, true), port(&"RAM", 0, false))
	check(ui.graph.get_connection_list().size() == before_invalid and ui.status_label.text.contains("2") and ui.status_label.text.contains("1"), "A 2-bit to 1-bit rejection explains the width mismatch after release.")
	await capture("cpu-width-rejection")
	await hint_roundtrip(&"SOURCE_MUX")
	await close_window(&"task")
	await close_window(&"test_bench")
	# Start with later-stage RAM wiring; no stage may disable a legal gesture.
	await connect_actions([
		["ADDR_IN", "RAM"], ["ACC", "RAM", 0, 1], ["CONTROL", "RAM", 3, 2], ["RAM", "MEM_OUT"],
		["OP_IN", "CONTROL"], ["ARG_IN", "SOURCE_MUX"], ["RAM", "SOURCE_MUX", 0, 1], ["CONTROL", "SOURCE_MUX", 0, 2],
		["ARG_IN", "ALU"], ["SOURCE_MUX", "ALU", 0, 1], ["CIN_0", "ALU", 0, 2], ["ADD_OP0", "ALU", 0, 3], ["ADD_OP1", "ALU", 0, 4],
		["SOURCE_MUX", "RESULT_MUX"], ["ALU", "RESULT_MUX", 0, 1], ["CONTROL", "RESULT_MUX", 1, 2],
		["RESULT_MUX", "ACC"], ["CONTROL", "ACC", 2, 1], ["ACC", "ACC_OUT"]])
	check(ui.cpu_stage_index == 4, "The interface checklist accepts connected inputs without requiring the author's exact sources.")
	await press(ui.desktop_window_buttons[&"test_bench"])
	await press(ui.official_button)
	await wait_playback()
	check(not ui.official_passed and not ui.completed_levels.has(&"cpu"), "A fully connected but wrong CPU fails real behavior tests and earns no unlock.")
	await capture("cpu-wrong-source")
	await close_window(&"test_bench")
	var before_erasing: int = ui.graph.get_connection_list().size()
	await click(curve_point(&"ALU"), MOUSE_BUTTON_RIGHT)
	check(not ui.graph.is_node_connected(&"ARG_IN", 0, &"ALU", 0) and ui.graph.get_connection_list().size() == before_erasing - 1, "A precise CPU wire click erases only the pointed wire, preserving nearby crossing connections.")
	await wire(&"ACC", &"ALU")
	var strokes: Dictionary = {}
	for connection: Dictionary in ui.graph.get_connection_list():
		strokes[ui.graph.connection_stroke_width(connection)] = true
	check(strokes.has(3.5) and strokes.has(8.0), "CPU keeps thin scalar cables distinct from wide ribbon buses, including mixed 1/2/4-bit modules.")
	await capture("cpu-player-circuit")
	await official_and_seal()

func inspect_width_draft(node: StringName, input_port: int, is_output: bool, width: int) -> void:
	var before: String = snapshot()
	var start: Vector2 = port(node, input_port, is_output)
	await point(start)
	var down := InputEventMouseButton.new()
	down.position = start
	down.global_position = start
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	root.push_input(down, true)
	await settle(2)
	await point(start + Vector2(-90, 55), MOUSE_BUTTON_MASK_LEFT, Vector2(-90, 55))
	var draft: Dictionary = ui.graph.builtin_connection_source
	check(draft.get("node", &"") == node and int(draft.get("port", -1)) == input_port and not bool(draft.get("is_output", true)), "A reverse cable gesture starts on the selected input socket.")
	check(ui.graph.port_bit_width(node, input_port, is_output) == width, "The active reverse draft retains its actual %d-bit input width." % width)
	var status_before: String = ui.status_label.text
	ui.graph.visible_connection_targets()
	check(ui.status_label.text == status_before, "Enumerating compatible sockets must not replace the active gesture message with an unrelated width error.")
	await capture("cpu-reverse-%d-bit-draft" % width)
	await key(KEY_ESCAPE)
	var up := InputEventMouseButton.new()
	up.position = start
	up.global_position = start
	up.button_index = MOUSE_BUTTON_LEFT
	root.push_input(up, true)
	await settle()
	check(snapshot() == before and ui.graph.builtin_connection_source.is_empty(), "Cancelling a width preview preserves the player's circuit and clears its cable.")

func load_store_bridge() -> void:
	await enter_level(&"load_store")
	check(not ui.graph.branch_edit_enabled and ui.graph.get_connection_list().size() == 5, "LOAD/STORE retains its original fixed external Test Bench, backed by the UI-built CPU.")
	await press(ui.desktop_window_buttons[&"test_bench"])
	await press(ui.official_button)
	await wait_playback()
	check(ui.current_phase == &"prologue_complete" and ui.completed_levels.has(&"load_store"), "The unchanged LOAD/STORE program completes through the earned CPU and RAM.")
	await capture("load-store-complete")
	await press(ui.level_completion_overlay.return_button)
	await press(ui.hub_button)
	check(current_scene.name == "PrototypeHub" and not current_scene.system_entry_button.disabled, "Returning to the default hub exposes Chapter 1 after verified prologue completion.")
	await press(current_scene.system_entry_button)
	check(current_scene.name == "SystemLab" and root.get_node("SystemChapter").prologue_ready, "Chapter 1 opens through the ordinary Game card with earned hardware sources.")
	await capture("chapter-1-entry")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 900)
	# macOS may deliver its native fullscreen/window transition after the first
	# viewport resize. Let that transition finish before dispatching scene input.
	if OS.get_name() == "macOS":
		await create_timer(1.0).timeout
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await settle(8)
	check(current_scene.name == "PrototypeHub" and not root.get_node("GameMode").is_test_mode(), "The configured default scene is the original hub in ordinary Game mode.")
	await capture("default-hub")
	await press(named_button(current_scene, text(&"hub.hardware.play")))
	ui = current_scene
	check(ui.name == "HardwareFoundations" and ui.current_phase == &"campaign", "Normal Hardware card enters the original prerequisite map.")
	await capture("prologue-map")
	await press(ui.campaign_level_buttons[&"tutorial"])
	check(ui.current_phase == &"tutorial" and ui.mission_briefing_active and not ui.hint_mode, "Tutorial first entry prominently displays Mission and no solution hint.")
	if ui.mission_briefing_panel == null:
		await capture("failed-tutorial-entry")
		await finish()
		return
	var start_building: Control = ui.mission_briefing_panel.find_child("MissionStartBuilding", true, false)
	var task_scroll: ScrollContainer = ui.desktop_windows[&"task"].find_child("TaskScroll", true, false) as ScrollContainer
	check(task_scroll != null and task_scroll.get_global_rect().encloses(start_building.get_global_rect()), "First Mission exposes Start Building without scrolling or searching for the action.")
	await capture("tutorial-mission")
	root.size = Vector2i(1280, 720)
	await settle(10)
	check(task_scroll.get_global_rect().encloses(start_building.get_global_rect()), "First Mission actions stay visible at the minimum window size in either language.")
	await capture("tutorial-mission-minimum")
	root.size = Vector2i(1600, 900)
	await settle(10)
	await press(ui.mission_briefing_continue_button)
	await press(ui.mission_briefing_previous_button)
	check(ui.mission_briefing_page == 0, "Mission Previous/Next remain functional.")
	await press(ui.mission_briefing_panel.find_child("MissionSections", true, false).get_child(2))
	check(ui.mission_briefing_page == 2, "Mission section buttons go directly to requested specifications without visiting hints.")
	await press(ui.mission_briefing_panel.find_child("MissionSections", true, false).get_child(0))
	await press(ui.mission_briefing_panel.find_child("MissionStartBuilding", true, false))
	check(not ui.mission_briefing_active and ui.mission_compact and not ui.hint_mode, "Start building folds the first page and preserves the independently hidden hints.")
	await handbook_input_check()
	await named_design()
	await close_window(&"task")
	await close_window(&"test_bench")
	await capture("tutorial-board")
	var node: GraphNode = ui.component_nodes[&"NOT_1"]
	var before_position: Vector2 = node.position_offset
	await drag(node.get_global_rect().get_center(), node.get_global_rect().get_center() + Vector2(80, 40))
	check(node.position_offset.is_equal_approx(before_position + Vector2(80, 50)) and node.selected, "Component body follows the actual event displacement and 20-unit grid snapping.")
	await key(KEY_Z, true)
	check(node.position_offset == before_position, "Undo restores body position.")
	await key(KEY_Y, true)
	check(node.position_offset != before_position, "Redo reapplies body movement.")
	await capture("tutorial-after-drag")
	await key(KEY_3)
	await wire(&"A_IN", &"NOT_1")
	check(ui.graph.get_connection_color_index(&"A_IN", 0, &"NOT_1", 0) == 2, "A newly drawn wire retains the actively selected palette color.")
	await wire(&"NOT_1", &"LAMP")
	await hint_roundtrip()
	await editing_roundtrip()
	await camera_and_windows()
	await focus_view_check()
	await capture("tutorial-return")
	if "--interaction-only" in OS.get_cmdline_user_args():
		await finish()
		return
	await complete_tutorial()
	if ui.current_level_id == &"half_adder":
		await build_half_adder()
	if ui.current_phase == &"campaign":
		await build_prerequisites()
	if ui.current_phase == &"campaign" and not ui.campaign_level_buttons[&"cpu"].disabled:
		await build_cpu()
	if ui.current_phase == &"campaign" and not ui.campaign_level_buttons[&"load_store"].disabled:
		await load_store_bridge()
	await finish()


func handbook_input_check() -> void:
	var original: String = snapshot()
	var handbook: Control = ui.terminology_handbook
	await press(handbook.entry_button)
	check(handbook.is_open() and handbook.visible_term_ids.size() == 3, "The ordinary Handbook recommends three current topics without hiding available specifications.")
	await capture("handbook-first-lesson")
	await press(handbook.search_edit)
	await type_text("cache")
	check(not handbook.is_term_unlocked(&"cache") and not handbook.detail_diagram.visible, "Searching a future topic explains its unlock lesson without showing the diagram or answer.")
	await capture("handbook-future-locked")
	await key(KEY_A, true)
	await type_text("signal")
	check(handbook.search_edit.text == "signal", "The platform select-all shortcut replaces the previous Handbook query exactly.")
	check(handbook.detail_diagram.visible, "Searching the current signal concept exposes its high/low illustration.")
	await capture("handbook-signal")
	await key(KEY_ESCAPE)
	check(not handbook.is_open() and snapshot() == original, "Escape returns from handbook text focus with player topology, positions, name and colors intact.")

func finish() -> void:
	var file := FileAccess.open(evidence_root + root.get_node("Localization").current_locale() + "-ui-observations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(observations, "\t"))
	print("Recovery GUI checks: %d; failures: %d" % [observations.size(), failures.size()])
	if failures.is_empty():
		print("PASS: recovery ordinary Game input")
	quit(0 if failures.is_empty() else 1)
