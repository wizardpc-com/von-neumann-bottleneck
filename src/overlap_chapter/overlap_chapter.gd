extends Control
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
const Graph = preload("res://src/hardware_foundations/circuit_graph_edit.gd")
const Instrument = preload("res://src/ui/floating_instrument_panel.gd")
const PaletteItem = preload("res://src/hardware_foundations/component_palette_item.gd")
const Map = preload("res://src/hardware_foundations/campaign_map_view.gd")
const Timeline = preload("res://src/overlap_chapter/overlap_timeline.gd")
const Type = preload("res://src/ui/ui_typography.gd")
const BLUE := Color("50d5ff")
const GOLD := Color("ffbf69")
const GREEN := Color("67e8a5")
var terminology_handbook: TerminologyHandbook
var level: String = ""
var board: Dictionary = {}
var graph: CircuitGraphEdit
var workspace: Control
var map_view: CampaignMapView
var title: Label
var status: Label
var goal: Button
var dock: HBoxContainer
var editor: CodeEdit
var panels: Dictionary = {}
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var armed: String = ""
var body_drag: Dictionary = {}
var hint_level: int = 0
var hint_overlay: Control
var completion: LevelCompletionOverlay
var confirmation: ConfirmationDialog
var runs: Array[SimulationTrace] = []
var trace: SimulationTrace
var timeline: OverlapTimeline
var metrics: Label
var events: ItemList
var scrub: HSlider
var case_select: OptionButton
var playing: bool = false
var elapsed: float = 0.0
var trace_stale: bool = true
var dirty: bool = false
var save_elapsed: float = 0.0
var draft_loading: bool = false

func _ready() -> void:
	var skin := Theme.new()
	skin.default_font_size = Type.BODY_SIZE
	preload("res://src/ui/instrument_theme.gd").apply_to(skin)
	theme = skin
	var backdrop := preload("res://src/ui/technical_backdrop.gd").new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_"+side,14)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	title = Label.new()
	title.text = _t("title") + (" · TEST" if GameMode.is_test_mode() else "")
	title.add_theme_font_size_override("font_size",27)
	title.add_theme_color_override("font_color",BLUE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header,"map",_show_map)
	_button(header,"hub",func() -> void:
		_save_draft()
		get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn"))
	_button(header,"fullscreen",WindowMode.toggle_fullscreen)
	goal = Button.new()
	goal.alignment = HORIZONTAL_ALIGNMENT_LEFT
	goal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	goal.pressed.connect(func() -> void: _toggle("mission"))
	column.add_child(goal)
	workspace = Control.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(workspace)
	dock = HBoxContainer.new()
	column.add_child(dock)
	status = Label.new()
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.custom_minimum_size.x = 320
	dock.add_child(status)
	dock.add_child(PlaytestMoments.make_button())
	for id: String in ["mission","toolbox","program","trace","handbook"]:
		_button(dock,id,func() -> void: _toggle(id))
	_button(dock,"hint",_request_hint)
	_button(dock,"run",_run_official)
	confirmation = ConfirmationDialog.new()
	confirmation.title = _t("hint")
	confirmation.confirmed.connect(_advance_hint)
	confirmation.canceled.connect(func() -> void: PlaytestData.record_hint_action(&"chapter_3",StringName(level),mini(3,hint_level+1),&"cancel"))
	add_child(confirmation)
	completion = preload("res://src/ui/level_completion_overlay.gd").new()
	completion.questionnaire_enabled = PlaytestData.questionnaires_enabled()
	completion.continue_requested.connect(func(_id: StringName) -> void: _show_map())
	completion.feedback_submitted.connect(PlaytestData.submit_level_feedback)
	completion.feedback_skipped.connect(func(chapter: StringName, id: StringName) -> void: PlaytestData.record_feedback_skipped(&"level",StringName("%s/%s" % [chapter,id])))
	add_child(completion)
	get_window().focus_exited.connect(_on_window_focus_exited)
	terminology_handbook = preload("res://src/ui/terminology_handbook.gd").new()
	terminology_handbook.standalone_entry = false
	add_child(terminology_handbook)
	_show_map()
	var requested_task: StringName = TaskNavigation.consume("chapter_3")
	if not requested_task.is_empty(): call_deferred("_open_level",requested_task)

func _process(delta: float) -> void:
	if is_instance_valid(workspace):
		for panel: FloatingInstrumentPanel in panels.values():
			if panel.visible and (panel.size.y > workspace.size.y-16 or panel.position.y+panel.size.y > workspace.size.y-8):
				panel.fit_to_parent()
	if dirty:
		save_elapsed += delta
		if save_elapsed >= 0.7: _save_draft()
	if playing and trace != null and is_instance_valid(scrub):
		elapsed += delta
		if elapsed >= 0.15:
			elapsed = 0
			scrub.value += 1
			if scrub.value >= scrub.max_value: playing = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_cancel_placement()
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		_on_window_focus_exited()

func _on_window_focus_exited() -> void:
	_cancel_body_drag()
	_cancel_placement()
	_save_draft()

func _placement_allowed(position: Vector2) -> bool:
	if is_instance_valid(terminology_handbook) and terminology_handbook.is_open(): return false
	if not is_instance_valid(graph) or not graph.get_global_rect().has_point(position): return false
	if is_instance_valid(hint_overlay) or completion.visible or confirmation.visible: return false
	for panel: FloatingInstrumentPanel in panels.values():
		if panel.visible and panel.get_global_rect().has_point(position): return false
	return true

func _input(event: InputEvent) -> void:
	if is_instance_valid(terminology_handbook) and terminology_handbook.is_open(): return
	if not is_instance_valid(graph): return
	if _handle_body_drag(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and not armed.is_empty():
		graph.placement_pointer = graph.get_global_transform_with_canvas().affine_inverse() * event.position
		graph.placement_has_pointer = _placement_allowed(event.position)
		graph.queue_redraw()
	if not event is InputEventMouseButton or event.pressed or event.button_index != MOUSE_BUTTON_LEFT or not get_viewport().gui_is_dragging(): return
	var payload: Variant = get_viewport().gui_get_drag_data()
	if not payload is Dictionary or StringName(payload.get("type", &"")) != &"circuit_component_template": return
	# Match the existing circuit host: native captured drags use the release
	# event position, which can differ from the OS cursor's hover position.
	var allowed: bool = _placement_allowed(event.position)
	get_viewport().gui_cancel_drag()
	if allowed: _add_part(String(payload.template_key),graph.get_global_transform_with_canvas().affine_inverse() * event.position)
	_cancel_placement()
	get_viewport().set_input_as_handled()

func _handle_body_drag(event: InputEvent) -> bool:
	if not body_drag.is_empty():
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_cancel_body_drag()
			return true
		if event is InputEventKey: return true
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_body_drag()
			return true
		if event is InputEventMouseMotion:
			if not body_drag.moved and event.position.distance_to(body_drag.pointer) < 4: return true
			body_drag.moved = true
			var offset: Vector2 = (event.position - body_drag.pointer) / graph.zoom
			for id: String in body_drag.positions:
				var node: GraphNode = graph.get_node(NodePath(id))
				node.position_offset = (body_drag.positions[id] + offset).snapped(Vector2.ONE * (graph.snapping_distance if graph.snapping_enabled else 1))
			return true
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if body_drag.moved:
				_remember()
				_capture_layout()
				_changed(false)
			body_drag.clear()
			return true
		return false
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT or not _placement_allowed(event.position): return false
	var local: Vector2 = graph.get_global_transform_with_canvas().affine_inverse() * event.position
	if not graph._port_at(local,28).is_empty(): return false
	var id: StringName = graph._node_at(local)
	if id.is_empty(): return false
	_cancel_placement()
	graph.grab_focus()
	var clicked: GraphNode = graph.get_node(NodePath(id))
	if event.shift_pressed: clicked.selected = not clicked.selected
	elif not clicked.selected:
		for child: Node in graph.get_children():
			if child is GraphNode: child.selected = child == clicked
	var positions: Dictionary = {}
	for child: Node in graph.get_children():
		if child is GraphNode and child.selected: positions[String(child.name)] = child.position_offset
	if not positions.is_empty(): body_drag = {"pointer":event.position,"positions":positions,"moved":false}
	return true

func _cancel_body_drag() -> void:
	if is_instance_valid(graph):
		for id: String in body_drag.get("positions",{}):
			var node: GraphNode = graph.get_node_or_null(NodePath(id))
			if node != null: node.position_offset = body_drag.positions[id]
	body_drag.clear()

func _unhandled_key_input(event: InputEvent) -> void:
	if terminology_handbook.handle_escape(event):
		get_viewport().set_input_as_handled()
		return
	if terminology_handbook.is_open(): return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		if is_instance_valid(hint_overlay): hint_overlay.queue_free(); hint_overlay = null
		else: _cancel_placement()
		get_viewport().set_input_as_handled()
	elif is_instance_valid(hint_overlay): return
	elif event.is_command_or_control_pressed() and event.keycode == KEY_Z:
		_undo(event.shift_pressed)
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_DELETE, KEY_BACKSPACE] and not level.is_empty():
		_delete_selected()
		get_viewport().set_input_as_handled()

func _show_map() -> void:
	_save_draft()
	if not level.is_empty(): PlaytestData.level_exited(&"chapter_3",StringName(level))
	level = ""
	if TaskNavigation.return_to_tree(): return
	_reset_workspace()
	goal.text = _t("map_goal")
	status.text = _t("map_status")
	map_view = Map.new()
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workspace.add_child(map_view)
	var branches: Array[Dictionary] = []
	for index: int in range(4):
		branches.append({"id": str(index), "order": index, "title": _t("branch."+str(index)),
			"lane": [0.0,-1.0,1.0,0.0][index]})
	var levels: Array[Dictionary] = []
	for id: String in Catalog.IDS:
		var branch: String = "0" if id == "arrival" else "1" if id in ["buffers","backpressure"] else "2" if id in ["prefetch","distance"] else "3"
		var complete: bool = OverlapChapter.completed().has(id)
		var available: bool = Catalog.unlocked(id,OverlapChapter.completed(),OverlapChapter.chapter_unlocked(),GameMode.is_test_mode())
		levels.append({"id": id,"branch_id":branch,"order":Catalog.IDS.find(id),"title":_t(id+".title"),
			"description":_t(id+".goal"),"dependencies":Catalog.DEPS[id],"completed":complete,"unlocked":available,
			"status":_t("complete" if complete else "available" if available else "locked"),"requirement":_t(id+".goal")})
	map_view.configure(branches,levels,_t("map_legend"))
	map_view.level_requested.connect(func(id: StringName) -> void: _open_level(String(id)))
	var text := _label(_t("map_intro"),true)
	text.custom_minimum_size.x = 320
	var panel: FloatingInstrumentPanel = _panel("mission",_t("mission"),Vector2(18,26),Vector2(350,390))
	panel.content_host.add_child(text)

func _reset_workspace() -> void:
	if is_instance_valid(completion): completion.dismiss()
	playing = false
	graph = null
	editor = null
	trace = null
	runs.clear()
	panels.clear()
	for child: Node in workspace.get_children():
		workspace.remove_child(child)
		child.queue_free()
	if is_instance_valid(hint_overlay): hint_overlay.queue_free(); hint_overlay = null

func _open_level(id: String) -> void:
	if not Catalog.unlocked(id,OverlapChapter.completed(),OverlapChapter.chapter_unlocked(),GameMode.is_test_mode()): return
	_save_draft()
	level = id
	PlaytestData.level_started(&"chapter_3",StringName(id))
	_reset_workspace()
	hint_level = 0
	undo_stack.clear()
	redo_stack.clear()
	armed = ""
	var draft: Dictionary = OverlapChapter.drafts().get(id,{})
	board = draft.get("board",Catalog.seed(id)).duplicate(true)
	var program: String = draft.get("program",Catalog.starter(id))
	goal.text = _t(id+".title") + "   ·   " + _t(id+".goal")
	status.text = _t("edit_help")
	graph = _new_graph(false)
	graph.name = "OverlapWorkbench"
	graph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workspace.add_child(graph)
	_render_board(graph,board,false)
	graph.scroll_offset = Vector2(-80,-100)
	_build_mission()
	_build_toolbox()
	_build_program(program)
	_build_trace()
	_build_handbook()
	panels.toolbox.show()
	panels.trace.hide()

	# Empty construction starts with tools visible, not an authored answer machine.
	panels.program.hide()
	dirty = false

func _new_graph(read_only: bool) -> CircuitGraphEdit:
	var result := Graph.new()
	result.minimap_enabled = false
	result.grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	result.right_disconnects = true
	result.branch_edit_enabled = not read_only
	result.component_drop_enabled = not read_only
	result.connection_lines_thickness = 0.0
	result.connection_lines_antialiased = true
	result.connection_width_provider = func(id: StringName, port: int, output: bool) -> int:
		var node: GraphNode = result.get_node_or_null(NodePath(id))
		return node.get_output_port_type(port) if output and node != null else node.get_input_port_type(port) if node != null else 1
	result.connection_validator = func(from: StringName, output: int, to: StringName, input: int) -> bool:
		var a: GraphNode = result.get_node_or_null(NodePath(from))
		var b: GraphNode = result.get_node_or_null(NodePath(to))
		return a != null and b != null and a.get_output_port_type(output) == b.get_input_port_type(input) and from != to
	if not read_only:
		result.connection_drag_started.connect(func(id: StringName, port: int, output: bool) -> void:
			result.set_draft_color_index(2 if result.port_bit_width(id,port,output)==1 else 0)
			result.begin_builtin_connection_preview(id,port,output))
		result.connection_drag_ended.connect(result.end_builtin_connection_preview)
		result.connection_request.connect(_connect_wire)
		result.disconnection_request.connect(_disconnect_wire)
		result.component_drop_requested.connect(func(kind: String, position: Vector2) -> void:
			_add_part(kind,position)
			_cancel_placement())
		result.empty_canvas_pressed.connect(func(position: Vector2) -> void:
			if not armed.is_empty(): _add_part(armed,position))
		result.component_placement_cancel_requested.connect(func(_reason: StringName) -> void: _cancel_placement())
		result.delete_nodes_request.connect(func(_nodes: Array[StringName]) -> void: _delete_selected())
		result.end_node_move.connect(func() -> void: _remember(); _capture_layout(); _changed(false))
		result.erase_component_requested.connect(_delete_part)
		result.erase_wire_requested.connect(func(wire: Dictionary) -> void: _disconnect_wire(wire.from_node,wire.from_port,wire.to_node,wire.to_port))
		result.branch_connection_requested.connect(func(wire: Dictionary,_position:Vector2,to:StringName,port:int) -> void: _connect_wire(wire.from_node,wire.from_port,to,port))
		result.connection_endpoint_move_requested.connect(func(wire: Dictionary,to:StringName,port:int) -> void:
			_disconnect_wire(wire.from_node,wire.from_port,wire.to_node,wire.to_port)
			_connect_wire(wire.from_node,wire.from_port,to,port))
	return result

func _render_board(target: CircuitGraphEdit, data: Dictionary, read_only: bool) -> void:
	target.clear_connections()
	for child: Node in target.get_children():
		if child is GraphNode: target.remove_child(child); child.queue_free()
	for id: String in data.nodes:
		var spec: Dictionary = data.nodes[id]
		var kind: String = spec.kind
		var node := GraphNode.new()
		node.set_meta("full_card_hit_test", true)
		node.name = id
		node.title = id + " · " + _t(kind)
		node.position_offset = Vector2(float(spec.get("x",0)),float(spec.get("y",0)))
		node.draggable = not read_only
		node.selectable = not read_only
		node.custom_minimum_size.x = 220
		var border := BLUE if kind in ["transfer","cache"] else Color("ba92ff")
		var styling = preload("res://src/ui/instrument_theme.gd")
		node.add_theme_stylebox_override("panel",styling.panel(Color("11212d"),Color(border,0.7)))
		node.add_theme_stylebox_override("panel_selected",styling.panel(Color("173041"),GREEN))
		node.add_theme_stylebox_override("titlebar",styling.panel(Color("1b3142"),Color(border,0.7)))
		node.add_theme_stylebox_override("titlebar_selected",styling.panel(Color("244050"),GREEN))
		target.add_child(node)
		var rows: Array = []
		match kind:
			"transfer": rows = [["free 1",1,"DATA 8",8]]
			"compute": rows = [["DATA 8",8,"",0],["ready 1",1,"",0]]
			"buffer": rows = [["DATA 8",8,"DATA 8",8],["",0,"ready 1",1],["",0,"free 1",1]]
			"cache": rows = [["DATA 8",8,"DATA 8",8]]
		for row: Array in rows:
			var ports := HBoxContainer.new()
			ports.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for side: int in [0,2]:
				var label := Label.new()
				label.text = String(row[side])
				label.add_theme_font_size_override("font_size",16)
				label.add_theme_color_override("font_color", BLUE if int(row[side+1])==8 else GOLD)
				label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side==0 else HORIZONTAL_ALIGNMENT_RIGHT
				ports.add_child(label)
			node.add_child(ports)
			var index: int = node.get_child_count()-1
			node.set_slot(index,int(row[1])>0,int(row[1]),BLUE if int(row[1])==8 else GOLD,
				int(row[3])>0,int(row[3]),BLUE if int(row[3])==8 else GOLD)
		for port: int in range(node.get_input_port_count()):
			if node.get_input_port_type(port)==8: node.set_slot_custom_icon_left(node.get_input_port_slot(port),preload("res://src/ui/signal_notation.gd").bus_port_icon())
		for port: int in range(node.get_output_port_count()):
			if node.get_output_port_type(port)==8: node.set_slot_custom_icon_right(node.get_output_port_slot(port),preload("res://src/ui/signal_notation.gd").bus_port_icon())
		var note := _label(_t(kind+".note"),true)
		note.add_theme_font_size_override("font_size",13)
		note.custom_minimum_size.x = 180
		node.add_child(note)
		var live := _label("")
		live.name = "LiveState"
		live.add_theme_font_size_override("font_size",14)
		node.add_child(live)
	for wire: Array in data.wires:
		target.connect_node(StringName(wire[0]),int(wire[1]),StringName(wire[2]),int(wire[3]))
		target.set_connection_color_index(StringName(wire[0]),int(wire[1]),StringName(wire[2]),int(wire[3]),2 if target.port_bit_width(StringName(wire[0]),int(wire[1]),true)==1 else 0)
	target.queue_redraw()
	_refresh_wire_geometry.call_deferred(target,read_only)

func _refresh_wire_geometry(target: CircuitGraphEdit, read_only: bool) -> void:
	# GraphNode containers settle port rows after the board is rebuilt.
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(target):
		if read_only: target.scroll_offset = Vector2(-70,-150)
		target.queue_redraw()

func _connect_wire(from: StringName, output: int, to: StringName, input: int) -> void:
	if not graph.connection_validator.call(from,output,to,input):
		status.text = _t("width_mismatch")
		return
	var wire: Array = [String(from),output,String(to),input]
	if board.wires.has(wire): return
	_remember()
	board.wires.append(wire)
	_changed()

func _disconnect_wire(from: StringName, output: int, to: StringName, input: int) -> void:
	var wire: Array = [String(from),output,String(to),input]
	if not board.wires.has(wire): return
	_remember()
	board.wires.erase(wire)
	_changed()

func _remember() -> void:
	undo_stack.append(board.duplicate(true))
	if undo_stack.size() > 40: undo_stack.pop_front()
	redo_stack.clear()

func _capture_layout() -> void:
	if not is_instance_valid(graph): return
	for id: String in board.get("nodes",{}):
		var node: GraphNode = graph.get_node_or_null(NodePath(id))
		if node != null: board.nodes[id].merge({"x":node.position_offset.x,"y":node.position_offset.y},true)

func _undo(redo: bool = false) -> void:
	if level.is_empty() or not is_instance_valid(graph): return
	var source: Array[Dictionary] = redo_stack if redo else undo_stack
	if source.is_empty(): return
	var destination: Array[Dictionary] = undo_stack if redo else redo_stack
	destination.append(board.duplicate(true))
	board = source.pop_back()
	_changed()

func _changed(render: bool = true) -> void:
	dirty = true
	trace_stale = true
	save_elapsed = 0
	playing = false
	status.text = _t("stale")
	if is_instance_valid(metrics): metrics.text = _t("stale")
	if render: _render_board(graph,board,false)
	elif is_instance_valid(graph):
		for child: Node in graph.get_children():
			if child is GraphNode:
				var live: Label = child.get_node_or_null("LiveState")
				if live != null: live.text = ""

func _save_draft() -> void:
	if not body_drag.is_empty(): return
	if level.is_empty() or not is_instance_valid(editor) or board.is_empty(): return
	_capture_layout()
	OverlapChapter.store_draft(level,board,editor.text)
	dirty = false
	save_elapsed = 0

func _add_part(kind: String, position: Vector2) -> void:
	if kind not in ["buffer","cache"] or level.is_empty(): return
	if kind == "cache" and level not in ["prefetch","distance","synthesis"]: return
	if kind == "buffer" and level in ["prefetch","distance"]: return
	var cost: int = 0
	for spec: Dictionary in board.nodes.values():
		if spec.kind in ["buffer","cache"]: cost += 1
	if cost >= int(Catalog.cases(level)[0].budget): status.text = _t("error.budget"); return
	var id: String = "CACHE"
	if kind == "buffer":
		for candidate: String in ["A","B","C"]:
			if not board.nodes.has(candidate): id = candidate; break
	if board.nodes.has(id): return
	_remember()
	var at: Vector2 = graph.graph_position_for_local_pointer(position,Vector2(210,155))
	board.nodes[id] = {"kind":kind,"capacity":1,"x":at.x,"y":at.y}
	_changed()

func _delete_selected() -> void:
	var selected: Array[String] = []
	for child: Node in graph.get_children():
		if child is GraphNode and child.selected: selected.append(String(child.name))
	for id: String in selected: _delete_part(id)

func _delete_part(id: StringName) -> void:
	if String(id) in ["TRANSFER","COMPUTE"] or not board.nodes.has(String(id)): return
	_remember()
	board.nodes.erase(String(id))
	board.wires = (board.wires as Array).filter(func(wire: Array) -> bool: return wire[0] != String(id) and wire[2] != String(id))
	_changed()

func _cancel_placement() -> void:
	armed = ""
	if is_instance_valid(graph): graph.set_component_placement_preview(false)

func _build_mission() -> void:
	var panel: FloatingInstrumentPanel = _panel("mission",_t("mission"),Vector2(16,18),Vector2(460,570))
	var box := _scroll_box(panel)
	var objective: Label = _label(_t(level+".goal"),true)
	objective.add_theme_color_override("font_color",GOLD)
	objective.add_theme_font_size_override("font_size",Type.SUBTITLE_SIZE)
	box.add_child(objective)
	_button(box,"learn",func() -> void: _toggle("handbook"))
	if level in ["backpressure","distance"] and not OverlapChapter.drafts().has(level):
		_button(box,"copy_previous",func() -> void:
			if OverlapChapter.copy_previous(level):
				var copied: Dictionary = OverlapChapter.drafts()[level].duplicate(true)
				# _open_level saves the current board first; install the copy locally before reopening.
				board = copied.board
				editor.text = copied.program
				_open_level(level))
	if level in ["distance","synthesis"]:
		var bonus: Dictionary = OverlapChapter.bonus_status(level)
		box.add_child(_label(("✓ " if bonus.complete else "◇ ")+_t("bonus."+level),true))
	box.add_child(_label(_t("output_spec"),true))
	if level == "arrival": box.add_child(_label(_t("independent_work"),true))
	box.add_child(_label(_t("public_cases")))
	for task: Dictionary in Catalog.cases(level):
		_build_case_card(box,task)
	box.add_child(_label(_t(level+".body"),true))
	_button(box,"begin",func() -> void:
		panel.hide()
		_toggle("program" if level not in ["buffers","synthesis"] else "toolbox",true))

func _case_name(task: Dictionary) -> String:
	return _t("case."+String(task.name))

func _build_case_card(parent: VBoxContainer, task: Dictionary) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0c202e")
	style.border_color = Color("315365")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel",style)
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	card.add_child(column)
	var caption: Label = _label(_case_name(task),true)
	caption.add_theme_color_override("font_color",BLUE)
	column.add_child(caption)
	column.add_child(_label(_t("case_limits") % [task.target,task.budget],true))
	var grid := GridContainer.new()
	grid.columns = task.values.size()+1
	grid.add_theme_constant_override("h_separation",8)
	column.add_child(grid)
	for row: int in range(3):
		grid.add_child(_label(_t(["batch_index","batch_value","batch_compute"][row])))
		for index: int in range(task.values.size()):
			var cell: Label = _label(str(index) if row==0 else str(task.values[index]) if row==1 else str(task.compute[index]))
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_color_override("font_color",BLUE if row==1 else GOLD if row==2 else Color("9caebc"))
			grid.add_child(cell)
	column.add_child(_label(_t("batch_transfer") % task.transfer,true))

func _build_toolbox() -> void:
	var panel: FloatingInstrumentPanel = _panel("toolbox",_t("toolbox"),Vector2(1150,18),Vector2(390,400))
	var box := _scroll_box(panel)
	box.add_child(_label(_t("toolbox_help"),true))
	var kinds: Array = ["cache"] if level in ["prefetch","distance"] else ["buffer","cache"] if level == "synthesis" else ["buffer"]
	for kind: String in kinds:
		var item := PaletteItem.new()
		item.configure(kind,&"register4" if kind=="buffer" else &"ram2x4",_t(kind),8,_t(kind+".note"),_t("tool_cost"))
		var preview := preload("res://src/overlap_chapter/overlap_part_preview.gd").new()
		preview.cache = kind == "cache"
		item.set_port_widths([8] if kind == "cache" else [1,8])
		item.set_component_preview(preview)
		item.placement_requested.connect(func(key: String) -> void:
			armed = key
			var ghost := preload("res://src/overlap_chapter/overlap_part_preview.gd").new()
			ghost.cache = key == "cache"
			graph.set_component_placement_preview(true,ghost,Vector2(210,155)))
		box.add_child(item)
	_button(box,"undo",func() -> void: _undo())
	_button(box,"redo",func() -> void: _undo(true))

func _build_program(source: String) -> void:
	var panel: FloatingInstrumentPanel = _panel("program",_t("program"),Vector2(1040,18),Vector2(470,510))
	var box := VBoxContainer.new()
	panel.content_host.add_child(box)
	editor = CodeEdit.new()
	editor.name = "OverlapProgram"
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.custom_minimum_size = Vector2(410,270)
	editor.gutters_draw_line_numbers = true
	editor.add_theme_font_size_override("font_size",19)
	editor.text = source
	editor.focus_entered.connect(_cancel_placement)
	editor.text_changed.connect(func() -> void:
		if not draft_loading: _changed(false))
	box.add_child(editor)
	var commands: PackedStringArray = _t("commands."+("arrival" if level=="arrival" else "cache" if level in ["prefetch","distance"] else "both" if level=="synthesis" else "buffer")).split("\n")
	var help := _label(commands[0],true)
	help.add_theme_font_size_override("font_size",14)
	var navigation := HBoxContainer.new()
	box.add_child(navigation)
	var page := Label.new()
	page.text = _t("command_card") % [1,commands.size()]
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(page)
	var state: Dictionary = {"index":0}
	for direction: int in [-1,1]:
		var button := Button.new()
		button.text = "←" if direction < 0 else "→"
		button.custom_minimum_size = Vector2(42,32)
		button.pressed.connect(func() -> void:
			state.index = posmod(int(state.index)+direction,commands.size())
			help.text = commands[state.index]
			page.text = _t("command_card") % [int(state.index)+1,commands.size()])
		navigation.add_child(button)
	box.add_child(help)
	_button(box,"run",_run_official)

func _build_trace() -> void:
	var panel: FloatingInstrumentPanel = _panel("trace",_t("trace"),Vector2(270,300),Vector2(950,640))
	var box := VBoxContainer.new()
	panel.content_host.add_child(box)
	metrics = _label(_t("no_run"),true)
	box.add_child(metrics)
	case_select = OptionButton.new()
	case_select.item_selected.connect(_select_run)
	box.add_child(case_select)
	timeline = Timeline.new()
	box.add_child(timeline)
	var controls := HBoxContainer.new()
	box.add_child(controls)
	_button(controls,"play",func() -> void:
		if trace != null:
			if scrub.value >= scrub.max_value: scrub.value = 0
			playing = not playing)
	_button(controls,"step",func() -> void: playing=false; scrub.value += 1)
	scrub = HSlider.new()
	scrub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrub.step = 1
	scrub.value_changed.connect(func(value: float) -> void:
		timeline.selected_cycle = int(value)
		timeline.queue_redraw()
		_show_cycle(int(value)))
	controls.add_child(scrub)
	events = ItemList.new()
	events.custom_minimum_size.y = 140
	events.size_flags_vertical = Control.SIZE_EXPAND_FILL
	events.add_theme_font_size_override("font_size",16)
	events.item_selected.connect(func(index: int) -> void: scrub.value = int(events.get_item_metadata(index)))
	box.add_child(events)

func _run_official() -> void:
	if level.is_empty() or is_instance_valid(hint_overlay): return
	_cancel_placement()
	_save_draft()
	var report: Dictionary = Catalog.evaluate(level,board,editor.text)
	runs.assign(report.runs)
	trace_stale = false
	case_select.clear()
	for index: int in range(runs.size()):
		var task: Dictionary = Catalog.cases(level)[index]
		var run: SimulationTrace = runs[index]
		var outcome: String = _t("case_pass") if run.passed and int(run.metrics.total_cycles)<=int(task.target) else _t("case_fail")
		case_select.add_item(_t("case_result") % [_case_name(task),outcome,run.metrics.total_cycles,task.target])
	_select_run(0)
	_toggle("trace",true,&"automatic")
	var recorded_cases: Array[Dictionary] = []
	var output_correct: bool = true
	for index: int in range(runs.size()):
		var run: SimulationTrace = runs[index]
		output_correct = output_correct and run.passed
		recorded_cases.append({"index":index,"passed":run.passed,"metrics":run.metrics,"target_cycles":Catalog.cases(level)[index].target})
	PlaytestData.record_official_run(&"chapter_3",StringName(level),report.passed,{"case_count":runs.size(),"cases":recorded_cases,
		"correct":output_correct,"target_met":report.passed,"result_class":"wrong_output_or_state" if not output_correct else "target_met" if report.passed else "correct_but_target_unmet",
		"program_digest":editor.text.sha256_text(),"board_digest":JSON.stringify(board).sha256_text(),"case_set_version":JSON.stringify(Catalog.cases(level)).sha256_text(),
		"post_completion":OverlapChapter.completed().has(level)})
	if report.passed:
		var newly_completed: bool = not OverlapChapter.completed().has(level)
		OverlapChapter.record_pass(level,board,editor.text)
		if newly_completed:
			PlaytestData.level_completed(&"chapter_3",StringName(level),{"cycles":trace.metrics.total_cycles,"cost":trace.metrics.cost})
			completion.present(StringName(level),_t(level+".title"),_t(level+".learned"),_t("title"),&"chapter_3")
		status.text = _t("passed")
		if level in ["distance","synthesis"]:
			status.text += " · "+_t("bonus.done" if OverlapChapter.bonus_status(level).complete else "bonus.pending")
		status.add_theme_color_override("font_color",GREEN)
	else:
		status.text = _t("try_again")
		status.add_theme_color_override("font_color",GOLD)

func _select_run(index: int) -> void:
	if index < 0 or index >= runs.size(): return
	trace = runs[index]
	timeline.trace = trace
	timeline.queue_redraw()
	scrub.max_value = int(trace.metrics.total_cycles)
	scrub.value = scrub.max_value
	_show_cycle(int(scrub.value))
	var task: Dictionary = Catalog.cases(level)[index]
	metrics.text = _t("metrics") % [trace.metrics.total_cycles,task.target,trace.metrics.compute_busy,trace.metrics.transfer_busy,trace.metrics.overlap,trace.metrics.wait,trace.result_value,trace.expected_value]
	if not String(trace.metrics.error).is_empty(): metrics.text += "\n" + _t("line_error") % [trace.metrics.error_line,_t("error."+String(trace.metrics.error))]
	elif int(trace.metrics.total_cycles)>int(task.target): metrics.text += "\n" + _t("too_slow")
	else: metrics.text += "\n" + _t("passed")
	if trace_stale: metrics.text = _t("stale")+"\n"+metrics.text
	metrics.text += "\n" + _t("cache_metrics") % [trace.metrics.hits,trace.metrics.misses,trace.metrics.evictions,trace.metrics.queue_wait]
	events.clear()
	for event: SimulationEvent in trace.events:
		if event.kind == &"state": continue
		var description: String = _t("event."+String(event.kind))
		if event.kind == &"error": description = _t("error."+String(event.details.code))
		var batch: int = int(event.details.get("batch",-1))
		events.add_item("%3d → %-3d  %s  %s → %s  %s" % [event.cycle,event.cycle+event.duration,description,event.source_device,event.target_device,"#"+str(batch) if batch>=0 else ""])
		events.set_item_metadata(events.item_count-1,event.cycle)

func _show_cycle(cycle: int) -> void:
	if trace == null or trace_stale or not is_instance_valid(graph): return
	var evidence: Dictionary = {}
	for event: SimulationEvent in trace.events:
		if event.cycle <= cycle: evidence = event.details
	for id: String in board.nodes:
		var node: GraphNode = graph.get_node_or_null(NodePath(id))
		if node == null: continue
		var live: Label = node.get_node_or_null("LiveState")
		if live == null: continue
		var text: String = ""
		if evidence.get("buffers",{}).has(id):
			var state: Dictionary = evidence.buffers[id]
			text = _t("state."+String(state.state))
			if int(state.batch)>=0: text += " · #"+str(state.batch)
		elif board.nodes[id].kind == "cache": text = _t("cache_contents")+" "+str(evidence.get("cache",[]))
		else:
			var active: int = int(evidence.get("active_transfer" if id=="TRANSFER" else "active_compute",-2))
			text = _t("state.empty") if active == -2 else _t("state.in_use")+" · "+("#"+str(active) if active>=0 else "work")
		live.text = text
		live.add_theme_color_override("font_color", GREEN)

func _build_handbook() -> void:
	terminology_handbook.set_lesson("overlap",level)


func _request_hint() -> void:
	PlaytestData.record_hint_action(&"chapter_3",StringName(level),mini(3,hint_level+1),&"request")
	if level.is_empty(): return
	if hint_level == 0: _advance_hint(); return
	if is_instance_valid(hint_overlay): return
	confirmation.dialog_text = _t("hint_confirm."+str(mini(3,hint_level+1)))
	confirmation.ok_button_text = Localization.text(StringName("hardware.hint.confirm_button."+str(mini(3,hint_level+1))))
	confirmation.cancel_button_text = Localization.text(&"hardware.hint.cancel")
	confirmation.popup_centered(Vector2i(560,190))

func _advance_hint() -> void:
	PlaytestData.record_hint_action(&"chapter_3",StringName(level),mini(3,hint_level+1),&"confirm")
	hint_level = mini(3,hint_level+1)
	PlaytestData.record_hint(&"chapter_3",StringName(level),hint_level)
	_show_hint(hint_level)

func _show_hint(tier: int) -> void:
	if is_instance_valid(hint_overlay): hint_overlay.queue_free(); hint_overlay=null
	_cancel_placement()
	playing = false
	hint_overlay = Control.new()
	hint_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint_overlay.z_index = 100
	add_child(hint_overlay)
	var background := ColorRect.new()
	background.color = Color("0b1421")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint_overlay.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
	hint_overlay.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	box.add_child(_label(_t("hint_readonly")+" · H"+str(tier)))
	box.add_child(_label(_t(level+".hint."+str(tier)),true))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	var canvas: CircuitGraphEdit = _new_graph(true)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(canvas)
	var answer: Dictionary = Catalog.reference_solution(level)
	var hint_board: Dictionary = Catalog.terminal_board() if tier==1 else Catalog.buffer_board(1) if tier==2 and level not in ["prefetch","distance"] else answer.board
	_render_board(canvas,hint_board,true)
	canvas.zoom = 0.75
	canvas.scroll_offset = Vector2(-70,-150)
	var code := CodeEdit.new()
	code.editable = false
	code.custom_minimum_size.x = 370
	code.add_theme_font_size_override("font_size",19)
	code.add_theme_color_override("font_readonly_color",Color("d8e7f2"))
	code.text = _t("hint_no_program") if tier==1 else String(answer.program).get_slice("\n",0)+"\n…" if tier==2 else answer.program
	row.add_child(code)
	var footer := HBoxContainer.new()
	box.add_child(footer)
	_button(footer,"back_to_design",func() -> void: hint_overlay.queue_free(); hint_overlay=null)
	for previous: int in range(1,hint_level+1):
		var revisit := Button.new()
		revisit.text = "H"+str(previous)
		revisit.pressed.connect(func() -> void: _show_hint(previous))
		footer.add_child(revisit)
	if hint_level<3:
		_button(footer,"hint_next",func() -> void:
			hint_overlay.queue_free(); hint_overlay=null
			_request_hint())

func _panel(id: String, caption: String, at: Vector2, dimensions: Vector2) -> FloatingInstrumentPanel:
	var panel := Instrument.new()
	panel.custom_minimum_size = Vector2(280,200)
	panel.setup(StringName(id),caption)
	panel.position = at
	panel.size = dimensions
	workspace.add_child(panel)
	panel.close_requested.connect(func(_id: StringName) -> void: panel.hide())
	panel.focus_requested.connect(func(_id: StringName) -> void: workspace.move_child(panel,-1))
	panels[id] = panel
	call_deferred("_settle_panel",panel,dimensions)
	return panel

func _settle_panel(panel: FloatingInstrumentPanel, dimensions: Vector2) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(panel): return
	panel.size = dimensions
	panel.fit_to_parent()

func _toggle(id: String, force: bool = false, origin: StringName = &"manual") -> void:
	_cancel_placement()
	if id == "handbook":
		terminology_handbook.open_handbook()
		return
	if not panels.has(id): return
	var panel: FloatingInstrumentPanel = panels[id]
	panel.visible = true if force else not panel.visible
	if panel.visible:
		PlaytestData.record_tool_opened(&"chapter_3",StringName(level),StringName(id),origin)
		workspace.move_child(panel,-1)
		panel.call_deferred("fit_to_parent")
		panel.position = Vector2(clampf(panel.position.x,0,maxf(0,workspace.size.x-panel.size.x)),clampf(panel.position.y,0,maxf(0,workspace.size.y-panel.size.y)))

func _scroll_box(panel: FloatingInstrumentPanel) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.content_host.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",16)
	scroll.add_child(box)
	return box

func _label(text: String, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_color",Color("d8e7f2"))
	return label

func _button(parent: Node, key: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = _t(key)
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	parent.add_child(button)
	if key in ["run","begin"]: preload("res://src/ui/instrument_theme.gd").primary(button)
	return button

func _t(key: String) -> String:
	return Localization.text(StringName("overlap."+key))
