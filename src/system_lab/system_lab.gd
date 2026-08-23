extends Control

const CatalogType = preload("res://src/system_lab/system_level_catalog.gd")
const CoreType = preload("res://src/system_lab/system_simulation_core.gd")
const ParserType = preload("res://src/system_lab/system_dsl_parser.gd")
const TopologyType = preload("res://src/system_lab/system_topology.gd")
const TraceType = preload("res://src/system_lab/system_trace.gd")
const ReceiptType = preload("res://src/system_lab/system_run_receipt.gd")
const PartSpecType = preload("res://src/system_lab/system_part_spec.gd")
const MapViewType = preload("res://src/system_lab/system_chapter_map_view.gd")
const DeviceSurfaceType = preload("res://src/system_lab/system_device_surface.gd")
const TraceOverlayType = preload("res://src/system_lab/system_trace_overlay.gd")
const SystemGraphEditType = preload("res://src/system_lab/system_graph_edit.gd")
const FloatingPanelType = preload("res://src/ui/floating_instrument_panel.gd")
const GameModeSelectorType = preload("res://src/ui/game_mode_selector.gd")
const FullscreenButtonType = preload("res://src/ui/fullscreen_button.gd")
const LevelCompletionOverlayType = preload("res://src/ui/level_completion_overlay.gd")
const WirePaletteType = preload("res://src/ui/wire_palette.gd")

const BACKGROUND := Color("08101d")
const PANEL := Color("172033")
const PANEL_DARK := Color("101725")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const BAD := Color("ff6b7d")
const PURPLE := Color("bc8cff")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")
const RUN_HISTORY_LIMIT: int = 10
const GRAPH_KEYBOARD_PAN_SPEED: float = 720.0
const COMPLETION_SUMMARY_KEYS := {
	&"assembly": &"system.completion.summary.assembly",
	&"cpu_speed": &"system.completion.summary.cpu_speed",
	&"ram_wait": &"system.completion.summary.ram_wait",
	&"bus_width": &"system.completion.summary.bus_width",
	&"bottleneck": &"system.completion.summary.bottleneck",
}

const STANDARD_LAYOUT := {
	&"CPU": Vector2(155.0, 145.0),
	&"BUS": Vector2(560.0, 145.0),
	&"RAM": Vector2(965.0, 145.0),
}

const WINDOW_LAYOUT := {
	&"mission": Rect2(16.0, 16.0, 420.0, 450.0),
	&"parts": Rect2(1050.0, 20.0, 430.0, 390.0),
	&"program": Rect2(35.0, 38.0, 610.0, 540.0),
	&"test_bench": Rect2(455.0, 50.0, 590.0, 500.0),
	&"profiler": Rect2(770.0, 24.0, 690.0, 510.0),
	&"history": Rect2(510.0, 82.0, 600.0, 430.0),
}
const WINDOW_REFERENCE_SIZE := Vector2(1500.0, 560.0)

const INPUT_NAMES := {
	&"CPU": [&"read_in"],
	&"BUS": [&"cpu_request_in", &"cpu_write_in", &"ram_read_in"],
	&"RAM": [&"request_in", &"write_in"],
}
const OUTPUT_NAMES := {
	&"CPU": [&"request_out", &"write_out"],
	&"BUS": [&"ram_request_out", &"ram_write_out", &"cpu_read_out"],
	&"RAM": [&"read_out"],
}

var catalog
var core := CoreType.new()
var current_level_id: StringName = &""
var current_level_definition: Dictionary = {}
var current_topology: SystemTopology
var selected_part_ids: Dictionary[StringName, StringName] = {}
var level_sessions: Dictionary[StringName, Dictionary] = {}
var active_mode: StringName = &"game"

var map_host: Control
var map_view
var level_completion_overlay: LevelCompletionOverlay
var lab_host: Control
var graph
var desktop_host: Control
var trace_overlay
var device_nodes: Dictionary[StringName, GraphNode] = {}
var device_surfaces: Dictionary[StringName, Control] = {}
var device_state_labels: Dictionary[StringName, Label] = {}

var instrument_windows: Dictionary[StringName, FloatingInstrumentPanel] = {}
var instrument_layout_size: Vector2 = WINDOW_REFERENCE_SIZE
var instrument_z_counter: int = 100
var mission_title_label: Label
var mission_body_label: Label
var prediction_box: VBoxContainer
var prediction_question_label: Label
var prediction_selector: OptionButton
var prediction_lock_button: Button
var prediction_status_label: Label
var mission_progress_label: Label
var conclusion_button: Button
var part_selectors: Dictionary[StringName, OptionButton] = {}
var parts_summary_label: Label
var editor: CodeEdit
var program_validation_label: Label
var program_apply_label: Label
var program_explanation_label: RichTextLabel
var apply_program_button: Button
var case_selector: OptionButton
var debug_run_button: Button
var official_run_button: Button
var official_result_box: VBoxContainer
var test_status_label: Label
var diagnosis_row: HBoxContainer
var diagnosis_selector: OptionButton
var diagnosis_button: Button
var profiler_labels: Dictionary[StringName, Label] = {}
var profiler_tier_label: Label
var history_label: RichTextLabel

var status_label: Label
var level_label: Label
var playback_caption: Label
var playback_progress: ProgressBar
var pause_button: Button
var speed_selector: OptionButton
var wire_color_menu_button: MenuButton
var active_wire_color_index: int = WirePaletteType.DEFAULT_INDEX

var draft_dirty: bool = false
var locked_prediction_id: StringName = &""
var applied_program: SystemProgram
var applied_program_source: String = ""
var latest_receipt
var revealed_breakdown_receipt_signature: String = ""
var latest_official_traces: Array[SystemTrace] = []
var current_trace: SystemTrace
var playback_index: int = 0
var playback_elapsed: float = 0.0
var playback_speed: float = 1.0
var playback_running: bool = false
var pending_history_after_playback: bool = false
var highlighted_source_line: int = -1
var editor_history: Array[Dictionary] = []
var editor_redo_history: Array[Dictionary] = []
var editor_history_replaying: bool = false
var node_move_start_snapshot: Dictionary = {}
var erase_start_snapshot: Dictionary = {}
var graph_pan_keys: Dictionary[Key, bool] = {}


func _ready() -> void:
	active_mode = &"test" if GameMode.is_test_mode() else &"game"
	_rebuild_catalog()
	_build_theme()
	_build_interface()
	GameMode.mode_changed.connect(_on_mode_changed)
	SystemChapter.progression_changed.connect(_refresh_map)
	_open_map()
	set_process(true)
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--capture-system" in arguments:
		call_deferred("_capture_system_workspace")
	elif "--capture-system-run" in arguments:
		call_deferred("_capture_system_run")
	elif "--capture-system-map" in arguments:
		call_deferred("_open_map")


func _input(event: InputEvent) -> void:
	if current_level_id.is_empty():
		graph_pan_keys.clear()
		return
	if _handle_system_graph_pan_key_event(event):
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if _system_keyboard_focus_accepts_text():
		return
	if key_event.ctrl_pressed or key_event.meta_pressed:
		match key_event.keycode:
			KEY_Z:
				if key_event.shift_pressed:
					_redo_system_edit()
				else:
					_undo_system_edit()
				get_viewport().set_input_as_handled()
			KEY_Y:
				_redo_system_edit()
				get_viewport().set_input_as_handled()
			KEY_A:
				_select_all_system_devices()
				get_viewport().set_input_as_handled()
			KEY_F:
				_color_hovered_system_wire(false)
				get_viewport().set_input_as_handled()
			KEY_E:
				_color_hovered_system_wire(true)
				get_viewport().set_input_as_handled()
			KEY_R:
				_sample_hovered_system_wire()
				get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_DELETE:
		_delete_selected_system_devices()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_ESCAPE:
		graph.cancel_selection_drag()
		_set_selected_system_devices([] as Array[StringName])
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_9:
		_set_active_system_wire_color(int(key_event.keycode - KEY_1))
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		graph_pan_keys.clear()


func _handle_system_graph_pan_key_event(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if key_event.keycode in [KEY_CTRL, KEY_META, KEY_ALT]:
		if key_event.pressed:
			graph_pan_keys.clear()
		return false
	var pan_key: Key = key_event.physical_keycode
	if pan_key not in [KEY_W, KEY_A, KEY_S, KEY_D]:
		pan_key = key_event.keycode
	if pan_key not in [KEY_W, KEY_A, KEY_S, KEY_D]:
		return false
	if not key_event.pressed:
		var was_active: bool = graph_pan_keys.has(pan_key)
		graph_pan_keys.erase(pan_key)
		return was_active
	if key_event.ctrl_pressed or key_event.meta_pressed or key_event.alt_pressed \
			or graph == null or not graph.is_visible_in_tree() \
			or _system_keyboard_focus_accepts_text():
		graph_pan_keys.clear()
		return false
	graph_pan_keys[pan_key] = true
	if not key_event.echo:
		_focus_system_graph_for_keyboard()
		status_label.text = _t(&"system.status.view_moved")
		status_label.add_theme_color_override("font_color", MUTED)
	return true


func _focus_system_graph_for_keyboard() -> void:
	if graph == null or not graph.is_visible_in_tree():
		return
	graph.grab_focus()
	for key: Key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		if Input.is_physical_key_pressed(key):
			graph_pan_keys[key] = true


func _process(delta: float) -> void:
	_update_graph_keyboard_pan(delta)
	if not playback_running or current_trace == null:
		return
	if playback_index >= current_trace.events.size():
		_finish_playback()
		return
	var event: SystemEvent = current_trace.events[playback_index]
	playback_elapsed += delta * playback_speed
	var duration: float = _display_duration(event)
	var progress: float = minf(1.0, playback_elapsed / duration)
	_show_event(event, progress)
	playback_progress.value = (float(playback_index) + progress) / float(maxi(1, current_trace.events.size())) * 100.0
	if progress >= 1.0:
		playback_index += 1
		playback_elapsed = 0.0


func _update_graph_keyboard_pan(delta: float) -> void:
	if current_level_id.is_empty() or graph == null or not graph.is_visible_in_tree() \
			or _system_keyboard_focus_accepts_text():
		graph_pan_keys.clear()
		return
	var direction := Vector2(
		float(graph_pan_keys.has(KEY_D)) - float(graph_pan_keys.has(KEY_A)),
		float(graph_pan_keys.has(KEY_S)) - float(graph_pan_keys.has(KEY_W))
	)
	_advance_graph_pan(delta, direction)


func _advance_graph_pan(delta: float, direction: Vector2) -> void:
	if graph == null or direction.is_zero_approx() or delta <= 0.0:
		return
	graph.scroll_offset += direction.normalized() * GRAPH_KEYBOARD_PAN_SPEED * delta


func _system_keyboard_focus_accepts_text() -> bool:
	if wire_color_menu_button != null and wire_color_menu_button.get_popup().visible:
		return true
	var focused: Control = get_viewport().gui_get_focus_owner()
	return focused != null and focused.is_visible_in_tree() \
		and (focused is LineEdit or focused is TextEdit)


func _rebuild_catalog() -> void:
	catalog = CatalogType.new(
		SystemChapter.current_cpu_source_signature(),
		SystemChapter.current_ram_source_signature()
	)


func _build_theme() -> void:
	var system_theme := Theme.new()
	system_theme.default_font_size = 16
	for control_type: String in ["Label", "Button", "OptionButton", "LineEdit", "CodeEdit", "SpinBox", "RichTextLabel", "GraphNode"]:
		system_theme.set_color("font_color", control_type, TEXT)
	system_theme.set_color("title_color", "GraphNode", TEXT)
	system_theme.set_icon("port", "GraphNode", _make_port_texture(24, 12))
	system_theme.set_constant("separation", "VBoxContainer", 8)
	system_theme.set_constant("separation", "HBoxContainer", 9)
	system_theme.set_stylebox("panel", "PanelContainer", _stylebox(PANEL, 10, 1, Color("293650")))
	system_theme.set_stylebox("normal", "Button", _stylebox(Color("26334a"), 7, 1, Color("354866")))
	system_theme.set_stylebox("hover", "Button", _stylebox(Color("30435f"), 7, 1, ACCENT))
	system_theme.set_stylebox("pressed", "Button", _stylebox(Color("17283e"), 7, 1, ACCENT))
	theme = system_theme


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root_box := VBoxContainer.new()
	margin.add_child(root_box)
	root_box.add_child(_build_header())
	var content := Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(content)
	_build_map(content)
	_build_lab(content)
	_create_level_completion_overlay()


func _create_level_completion_overlay() -> void:
	level_completion_overlay = LevelCompletionOverlayType.new()
	level_completion_overlay.continue_requested.connect(_on_level_completion_continue)
	add_child(level_completion_overlay)


func _show_level_completion(level_id: StringName) -> void:
	if level_completion_overlay == null or level_id.is_empty():
		return
	level_completion_overlay.present(
		level_id,
		_t(catalog.title_key(level_id)),
		_t(StringName(COMPLETION_SUMMARY_KEYS.get(level_id, &"system.completion.summary.assembly"))),
		_t(&"system.completion.chapter")
	)


func _review_level_conclusion() -> void:
	if current_level_id.is_empty() or not bool(SystemChapter.completed_levels().get(current_level_id, false)):
		return
	_show_level_completion(current_level_id)


func _dismiss_level_completion() -> void:
	if level_completion_overlay != null:
		level_completion_overlay.dismiss()


func _on_level_completion_continue(_level_id: StringName) -> void:
	_open_map()


func _build_header() -> Control:
	var header := PanelContainer.new()
	header.custom_minimum_size.y = 72.0
	var row := HBoxContainer.new()
	header.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	var title := Label.new()
	title.text = _t(&"system.chapter.title")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", ACCENT)
	title_box.add_child(title)
	level_label = Label.new()
	level_label.text = _t(&"system.chapter.subtitle")
	level_label.add_theme_color_override("font_color", MUTED)
	title_box.add_child(level_label)
	status_label = Label.new()
	status_label.text = _t(&"system.status.map")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size.x = 380.0
	status_label.add_theme_color_override("font_color", WARNING)
	row.add_child(status_label)
	var mode_selector: GameModeSelectorType = GameModeSelectorType.new()
	mode_selector.show_label = false
	row.add_child(mode_selector)
	var fullscreen_button: FullscreenButtonType = FullscreenButtonType.new()
	row.add_child(fullscreen_button)
	var map_button := Button.new()
	map_button.name = "ChapterMapButton"
	map_button.text = _t(&"system.action.map")
	map_button.pressed.connect(_open_map)
	row.add_child(map_button)
	var hub_button := Button.new()
	hub_button.text = _t(&"common.prototype_hub")
	hub_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn"))
	row.add_child(hub_button)
	return header


func _build_map(parent: Control) -> void:
	map_host = Control.new()
	map_host.name = "SystemChapterMap"
	map_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(map_host)
	map_view = MapViewType.new()
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_view.level_requested.connect(_start_level)
	map_host.add_child(map_view)


func _build_lab(parent: Control) -> void:
	lab_host = Control.new()
	lab_host.name = "SystemWorkbench"
	lab_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(lab_host)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lab_host.add_child(box)
	box.add_child(_build_workbench_bar())
	desktop_host = Control.new()
	desktop_host.custom_minimum_size.y = 560.0
	desktop_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desktop_host)
	graph = SystemGraphEditType.new()
	graph.name = "SystemGraph"
	graph.focus_mode = Control.FOCUS_ALL
	graph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph.show_grid = true
	graph.grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	graph.snapping_enabled = true
	graph.minimap_enabled = false
	graph.show_arrange_button = false
	graph.show_grid_buttons = false
	graph.show_minimap_button = false
	graph.show_zoom_buttons = false
	graph.show_zoom_label = false
	graph.show_menu = false
	graph.right_disconnects = false
	graph.connection_lines_thickness = 0.0
	graph.connection_lines_curvature = 0.48
	graph.connection_request.connect(_on_connection_request)
	graph.disconnection_request.connect(_on_disconnection_request)
	graph.connection_drag_started.connect(Callable(graph, "begin_connection_preview"))
	graph.connection_drag_ended.connect(Callable(graph, "end_connection_preview"))
	graph.erase_stroke_started.connect(_on_system_erase_stroke_started)
	graph.erase_component_requested.connect(_on_system_erase_component_requested)
	graph.erase_wire_requested.connect(_on_system_erase_wire_requested)
	graph.erase_stroke_finished.connect(_on_system_erase_stroke_finished)
	graph.selection_rectangle_applied.connect(_on_system_selection_rectangle_applied)
	graph.delete_nodes_request.connect(_on_system_delete_nodes_request)
	graph.node_selected.connect(_on_system_node_selection_changed)
	graph.node_deselected.connect(_on_system_node_selection_changed)
	graph.begin_node_move.connect(_on_system_begin_node_move)
	graph.end_node_move.connect(_on_system_end_node_move)
	graph.gui_input.connect(_on_system_graph_gui_input)
	graph.set_draft_color_index(active_wire_color_index)
	desktop_host.add_child(graph)
	_build_device_nodes()
	trace_overlay = TraceOverlayType.new()
	trace_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trace_overlay.z_index = 50
	desktop_host.add_child(trace_overlay)
	_build_instruments()
	desktop_host.resized.connect(_on_desktop_resized)
	box.add_child(_build_playback_bar())
	call_deferred("_on_desktop_resized")


func _build_workbench_bar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 52.0
	var row := HBoxContainer.new()
	panel.add_child(row)
	var title := Label.new()
	title.text = _t(&"system.workbench.title")
	title.add_theme_color_override("font_color", ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var layout_button := Button.new()
	layout_button.text = _t(&"common.auto_layout")
	layout_button.pressed.connect(func() -> void: _auto_layout(true))
	row.add_child(layout_button)
	var undo_button := Button.new()
	undo_button.name = "SystemUndoButton"
	undo_button.text = _t(&"system.action.undo")
	undo_button.tooltip_text = _t(&"system.action.undo.tooltip")
	undo_button.pressed.connect(_undo_system_edit)
	row.add_child(undo_button)
	var redo_button := Button.new()
	redo_button.name = "SystemRedoButton"
	redo_button.text = _t(&"system.action.redo")
	redo_button.tooltip_text = _t(&"system.action.redo.tooltip")
	redo_button.pressed.connect(_redo_system_edit)
	row.add_child(redo_button)
	var wire_button := Button.new()
	wire_button.name = "AutoWireButton"
	wire_button.text = _t(&"system.action.auto_wire")
	wire_button.pressed.connect(_auto_connect)
	row.add_child(wire_button)
	wire_color_menu_button = MenuButton.new()
	wire_color_menu_button.name = "SystemWireColorMenuButton"
	wire_color_menu_button.tooltip_text = _t(&"system.wire_color.tooltip")
	wire_color_menu_button.get_popup().id_pressed.connect(_set_active_system_wire_color)
	for color_index: int in range(WirePaletteType.COLORS.size()):
		wire_color_menu_button.get_popup().add_icon_item(
			_make_color_swatch(WirePaletteType.color(color_index)),
			_t(&"system.wire_color.item", [color_index + 1]), color_index
		)
	row.add_child(wire_color_menu_button)
	_refresh_system_wire_color_button()
	for instrument_id: StringName in [&"mission", &"parts", &"program", &"test_bench", &"profiler", &"history"]:
		var button := Button.new()
		button.text = _t(StringName("system.window.%s.short" % String(instrument_id)))
		button.pressed.connect(_open_instrument.bind(instrument_id))
		row.add_child(button)
	return panel


func _make_color_swatch(color: Color) -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y: int in range(3, 13):
		for x: int in range(3, 13):
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _set_active_system_wire_color(color_index: int) -> void:
	active_wire_color_index = WirePaletteType.normalized_index(color_index)
	if graph != null:
		graph.set_draft_color_index(active_wire_color_index)
	_refresh_system_wire_color_button()
	status_label.text = _t(&"system.wire_color.selected", [active_wire_color_index + 1])
	status_label.add_theme_color_override("font_color", WirePaletteType.color(active_wire_color_index))


func _refresh_system_wire_color_button() -> void:
	if wire_color_menu_button == null:
		return
	wire_color_menu_button.text = _t(&"system.wire_color.button", [active_wire_color_index + 1])
	wire_color_menu_button.icon = _make_color_swatch(WirePaletteType.color(active_wire_color_index))


func _color_hovered_system_wire(whole_lane: bool) -> void:
	var hovered: Dictionary = graph.hovered_connection_snapshot()
	if hovered.is_empty():
		status_label.text = _t(&"system.wire_color.hover_required")
		status_label.add_theme_color_override("font_color", WARNING)
		return
	var members: Array[Dictionary] = []
	if whole_lane:
		var lane: StringName = _system_connection_lane(hovered)
		for connection: Dictionary in graph.get_connection_list():
			if _system_connection_lane(connection) == lane:
				members.append(connection)
	else:
		members.append(hovered)
	var before: Dictionary = _capture_system_editor_snapshot()
	for connection: Dictionary in members:
		graph.set_connection_color_index(
			StringName(connection.get("from_node", &"")), int(connection.get("from_port", 0)),
			StringName(connection.get("to_node", &"")), int(connection.get("to_port", 0)),
			active_wire_color_index
		)
	_commit_system_editor_snapshot(&"wire_color", before)
	status_label.text = _t(
		&"system.wire_color.lane_done" if whole_lane else &"system.wire_color.segment_done",
		[members.size()]
	)
	status_label.add_theme_color_override("font_color", WirePaletteType.color(active_wire_color_index))


func _sample_hovered_system_wire() -> void:
	var hovered: Dictionary = graph.hovered_connection_snapshot()
	if hovered.is_empty():
		status_label.text = _t(&"system.wire_color.hover_required")
		status_label.add_theme_color_override("font_color", WARNING)
		return
	_set_active_system_wire_color(graph.get_connection_color_index(
		StringName(hovered.get("from_node", &"")), int(hovered.get("from_port", 0)),
		StringName(hovered.get("to_node", &"")), int(hovered.get("to_port", 0))
	))


func _system_connection_lane(connection: Dictionary) -> StringName:
	var route: Dictionary = _system_route_for_connection(connection)
	var from_name: String = String(route.get("from_port", ""))
	var to_name: String = String(route.get("to_port", ""))
	var names: String = "%s %s" % [from_name, to_name]
	if "write" in names:
		return &"write"
	if "read" in names:
		return &"read"
	return &"request"


func _system_route_for_connection(connection: Dictionary) -> Dictionary:
	for route: Dictionary in TopologyType.REQUIRED_CONNECTIONS:
		var from_id := StringName(route.get("from", &""))
		var to_id := StringName(route.get("to", &""))
		if from_id != StringName(connection.get("from_node", &"")) \
				or to_id != StringName(connection.get("to_node", &"")):
			continue
		if (OUTPUT_NAMES[from_id] as Array).find(StringName(route.get("from_port", &""))) \
				== int(connection.get("from_port", -1)) \
				and (INPUT_NAMES[to_id] as Array).find(StringName(route.get("to_port", &""))) \
				== int(connection.get("to_port", -1)):
			return route
	return {}


func _default_system_wire_color(connection: Dictionary) -> int:
	match _system_connection_lane(connection):
		&"write": return 2
		&"read": return 1
	return WirePaletteType.DEFAULT_INDEX


func _build_device_nodes() -> void:
	_add_device_node(&"CPU", &"cpu", [
		{"label": _t(&"system.port.request"), "input": false, "input_type": 0, "output": true, "output_type": 1, "color": ACCENT},
		{"label": _t(&"system.port.write_data"), "input": false, "input_type": 0, "output": true, "output_type": 3, "color": WARNING},
		{"label": _t(&"system.port.read_data"), "input": true, "input_type": 6, "output": false, "output_type": 0, "color": GOOD},
	])
	_add_device_node(&"BUS", &"bus", [
		{"label": _t(&"system.port.request_lane"), "input": true, "input_type": 1, "output": true, "output_type": 2, "color": ACCENT},
		{"label": _t(&"system.port.write_lane"), "input": true, "input_type": 3, "output": true, "output_type": 4, "color": WARNING},
		{"label": _t(&"system.port.read_lane"), "input": true, "input_type": 5, "output": true, "output_type": 6, "color": GOOD},
	])
	_add_device_node(&"RAM", &"ram", [
		{"label": _t(&"system.port.request"), "input": true, "input_type": 2, "output": false, "output_type": 0, "color": ACCENT},
		{"label": _t(&"system.port.write_data"), "input": true, "input_type": 4, "output": false, "output_type": 0, "color": WARNING},
		{"label": _t(&"system.port.read_data"), "input": false, "input_type": 0, "output": true, "output_type": 5, "color": GOOD},
	])


func _add_device_node(id: StringName, kind: StringName, slots: Array[Dictionary]) -> void:
	var node := GraphNode.new()
	node.name = id
	node.title = String(id)
	node.draggable = true
	node.resizable = false
	node.custom_minimum_size = Vector2(230.0, 245.0)
	graph.add_child(node)
	for slot_index: int in range(slots.size()):
		var slot: Dictionary = slots[slot_index]
		var row := Label.new()
		row.text = String(slot["label"])
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_color_override("font_color", slot["color"])
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(row)
		node.set_slot(
			slot_index,
			bool(slot["input"]), int(slot["input_type"]), slot["color"],
			bool(slot["output"]), int(slot["output_type"]), slot["color"]
		)
	var surface: Control = DeviceSurfaceType.new()
	surface.configure(kind)
	node.add_child(surface)
	device_surfaces[id] = surface
	var state := Label.new()
	state.text = _t(&"system.device.idle")
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_color_override("font_color", MUTED)
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(state)
	device_state_labels[id] = state
	device_nodes[id] = node
	node.gui_input.connect(_on_system_device_gui_input.bind(id))


func _build_instruments() -> void:
	_add_instrument(&"mission", _t(&"system.window.mission.title"), _build_mission_instrument())
	_add_instrument(&"parts", _t(&"system.window.parts.title"), _build_parts_instrument())
	_add_instrument(&"program", _t(&"system.window.program.title"), _build_program_instrument())
	_add_instrument(&"test_bench", _t(&"system.window.test_bench.title"), _build_test_bench_instrument())
	_add_instrument(&"profiler", _t(&"system.window.profiler.title"), _build_profiler_instrument())
	_add_instrument(&"history", _t(&"system.window.history.title"), _build_history_instrument())


func _add_instrument(id: StringName, title_text: String, content: Control) -> void:
	var panel: FloatingInstrumentPanel = FloatingPanelType.new()
	panel.name = "%sInstrument" % String(id).to_pascal_case()
	panel.custom_minimum_size = Vector2(350.0, 250.0)
	panel.add_theme_stylebox_override("panel", _stylebox(Color("111a2a"), 12, 2, ACCENT))
	desktop_host.add_child(panel)
	panel.setup(id, title_text)
	panel.set_content(content)
	var rect: Rect2 = WINDOW_LAYOUT[id]
	panel.position = rect.position
	panel.size = rect.size
	panel.visible = false
	panel.close_requested.connect(_close_instrument)
	panel.focus_requested.connect(_focus_instrument)
	instrument_windows[id] = panel


func _build_mission_instrument() -> Control:
	var box := VBoxContainer.new()
	mission_title_label = Label.new()
	mission_title_label.add_theme_font_size_override("font_size", 22)
	mission_title_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(mission_title_label)
	mission_body_label = Label.new()
	mission_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_body_label.size_flags_vertical = Control.SIZE_FILL
	box.add_child(mission_body_label)
	prediction_box = VBoxContainer.new()
	prediction_box.add_theme_constant_override("separation", 6)
	box.add_child(prediction_box)
	var prediction_title := Label.new()
	prediction_title.text = _t(&"system.prediction.title")
	prediction_title.add_theme_color_override("font_color", PURPLE)
	prediction_box.add_child(prediction_title)
	prediction_question_label = Label.new()
	prediction_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prediction_box.add_child(prediction_question_label)
	var prediction_row := HBoxContainer.new()
	prediction_box.add_child(prediction_row)
	prediction_selector = OptionButton.new()
	prediction_selector.name = "PredictionSelector"
	prediction_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prediction_selector.item_selected.connect(_on_prediction_selected)
	prediction_row.add_child(prediction_selector)
	prediction_lock_button = Button.new()
	prediction_lock_button.name = "PredictionLockButton"
	prediction_lock_button.text = _t(&"system.prediction.lock")
	prediction_lock_button.pressed.connect(_lock_prediction)
	prediction_row.add_child(prediction_lock_button)
	prediction_status_label = Label.new()
	prediction_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prediction_status_label.add_theme_color_override("font_color", WARNING)
	prediction_box.add_child(prediction_status_label)
	mission_progress_label = Label.new()
	mission_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_progress_label.add_theme_color_override("font_color", WARNING)
	box.add_child(mission_progress_label)
	conclusion_button = Button.new()
	conclusion_button.name = "ReviewLevelConclusionButton"
	conclusion_button.text = _t(&"system.mission.review_finding")
	conclusion_button.pressed.connect(_review_level_conclusion)
	conclusion_button.hide()
	box.add_child(conclusion_button)
	return box


func _build_parts_instrument() -> Control:
	var box := VBoxContainer.new()
	var help := Label.new()
	help.text = _t(&"system.parts.help")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", MUTED)
	box.add_child(help)
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		var label := Label.new()
		label.text = _t(StringName("system.part.%s" % String(kind)))
		label.add_theme_color_override("font_color", ACCENT)
		box.add_child(label)
		var selector := OptionButton.new()
		selector.name = "%sPartSelector" % String(kind).to_pascal_case()
		selector.item_selected.connect(_on_part_selected.bind(kind))
		box.add_child(selector)
		part_selectors[kind] = selector
	parts_summary_label = Label.new()
	parts_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parts_summary_label.add_theme_color_override("font_color", MUTED)
	parts_summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(parts_summary_label)
	return _scrollable(box)


func _build_program_instrument() -> Control:
	var box := VBoxContainer.new()
	var help := Label.new()
	help.text = _t(&"system.program.help")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", MUTED)
	box.add_child(help)
	editor = CodeEdit.new()
	editor.name = "SystemProgramEditor"
	editor.custom_minimum_size.y = 230.0
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.line_folding = true
	editor.draw_tabs = true
	editor.text_changed.connect(_on_program_changed)
	box.add_child(editor)
	program_validation_label = Label.new()
	program_validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(program_validation_label)
	var apply_row := HBoxContainer.new()
	box.add_child(apply_row)
	apply_program_button = Button.new()
	apply_program_button.name = "ApplyProgramButton"
	apply_program_button.text = _t(&"system.program.apply")
	apply_program_button.pressed.connect(_apply_program)
	apply_program_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_row.add_child(apply_program_button)
	program_apply_label = Label.new()
	program_apply_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	program_apply_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_row.add_child(program_apply_label)
	program_explanation_label = RichTextLabel.new()
	program_explanation_label.fit_content = true
	program_explanation_label.bbcode_enabled = true
	program_explanation_label.custom_minimum_size.y = 100.0
	box.add_child(program_explanation_label)
	return _scrollable(box)


func _build_test_bench_instrument() -> Control:
	var box := VBoxContainer.new()
	var help := Label.new()
	help.text = _t(&"system.test_bench.help")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", MUTED)
	box.add_child(help)
	case_selector = OptionButton.new()
	case_selector.name = "SystemCaseSelector"
	box.add_child(case_selector)
	var row := HBoxContainer.new()
	box.add_child(row)
	debug_run_button = Button.new()
	debug_run_button.text = _t(&"system.test_bench.run_one")
	debug_run_button.pressed.connect(_run_debug_case)
	debug_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(debug_run_button)
	official_run_button = Button.new()
	official_run_button.name = "OfficialRunButton"
	official_run_button.text = _t(&"system.test_bench.run_official")
	official_run_button.pressed.connect(_run_official)
	official_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(official_run_button)
	test_status_label = Label.new()
	test_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	test_status_label.add_theme_color_override("font_color", MUTED)
	box.add_child(test_status_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 145.0
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	official_result_box = VBoxContainer.new()
	official_result_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(official_result_box)
	diagnosis_row = HBoxContainer.new()
	box.add_child(diagnosis_row)
	diagnosis_selector = OptionButton.new()
	for category: StringName in [&"cpu", &"ram", &"bus", &"mixed"]:
		diagnosis_selector.add_item(_t(StringName("system.diagnosis.%s" % String(category))))
		diagnosis_selector.set_item_metadata(diagnosis_selector.item_count - 1, category)
	diagnosis_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagnosis_row.add_child(diagnosis_selector)
	diagnosis_button = Button.new()
	diagnosis_button.text = _t(&"system.diagnosis.confirm")
	diagnosis_button.pressed.connect(_confirm_diagnosis)
	diagnosis_row.add_child(diagnosis_button)
	return _scrollable(box)


func _build_profiler_instrument() -> Control:
	var box := VBoxContainer.new()
	profiler_tier_label = Label.new()
	profiler_tier_label.add_theme_color_override("font_color", PURPLE)
	box.add_child(profiler_tier_label)
	var help := Label.new()
	help.text = _t(&"system.profiler.help")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", MUTED)
	box.add_child(help)
	for metric: StringName in [
		&"total_cycles", &"cpu_compute_cycles", &"cpu_wait_cycles", &"ram_service_cycles",
		&"memory_requests", &"bus_control_cycles", &"bus_transfer_cycles",
		&"bus_segments_per_word", &"bytes_transferred", &"hardware_cost", &"shares",
	]:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", TEXT)
		box.add_child(label)
		profiler_labels[metric] = label
	return _scrollable(box)


func _build_history_instrument() -> Control:
	history_label = RichTextLabel.new()
	history_label.bbcode_enabled = true
	history_label.scroll_active = true
	history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return history_label


func _scrollable(content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll


func _build_playback_bar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 78.0
	var row := HBoxContainer.new()
	panel.add_child(row)
	playback_caption = Label.new()
	playback_caption.text = _t(&"system.playback.ready")
	playback_caption.custom_minimum_size.x = 455.0
	playback_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(playback_caption)
	playback_progress = ProgressBar.new()
	playback_progress.show_percentage = false
	playback_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(playback_progress)
	pause_button = Button.new()
	pause_button.text = _t(&"system.playback.pause")
	pause_button.pressed.connect(_toggle_pause)
	row.add_child(pause_button)
	var step_button := Button.new()
	step_button.text = _t(&"system.playback.step")
	step_button.pressed.connect(_step_playback)
	row.add_child(step_button)
	speed_selector = OptionButton.new()
	for speed: float in [0.5, 1.0, 2.0, 4.0]:
		speed_selector.add_item("%.1fx" % speed)
		speed_selector.set_item_metadata(speed_selector.item_count - 1, speed)
	speed_selector.select(1)
	speed_selector.item_selected.connect(func(index: int) -> void: playback_speed = float(speed_selector.get_item_metadata(index)))
	row.add_child(speed_selector)
	return panel


func _open_map() -> void:
	_dismiss_level_completion()
	if not current_level_id.is_empty() and lab_host != null and lab_host.visible:
		_save_level_session()
	_stop_playback()
	current_level_id = &""
	current_level_definition.clear()
	map_host.show()
	lab_host.hide()
	level_label.text = _t(&"system.chapter.subtitle")
	status_label.text = _t(&"system.status.map")
	status_label.add_theme_color_override("font_color", WARNING)
	_refresh_map()


func _refresh_map() -> void:
	if map_view == null or catalog == null:
		return
	var levels: Array[Dictionary] = []
	var completed: Dictionary = SystemChapter.completed_levels()
	for index: int in range(catalog.level_ids().size()):
		var level_id: StringName = catalog.level_ids()[index]
		var unlocked: bool = catalog.is_unlocked(
			level_id, completed, SystemChapter.prologue_ready, GameMode.is_test_mode()
		)
		var is_completed: bool = bool(completed.get(level_id, false))
		var status_key: StringName = &"system.map.completed" if is_completed else (&"system.map.unlocked" if unlocked else &"system.map.locked")
		levels.append({
			"id": level_id,
			"eyebrow": _t(&"system.map.level", [index + 1]),
			"title": _t(catalog.title_key(level_id)),
			"status": _t(status_key),
			"tooltip": _t(catalog.description_key(level_id)),
			"unlocked": unlocked,
			"completed": is_completed,
		})
	var intro_body: String = _t(&"system.map.intro.body")
	if not SystemChapter.prologue_ready and not GameMode.is_test_mode():
		intro_body += "\n\n" + _t(&"system.map.prologue_required")
	elif GameMode.is_test_mode():
		intro_body += "\n\n" + _t(&"system.map.test_mode")
	map_view.configure(levels, _t(&"system.map.intro.title"), intro_body)


func _start_level(level_id: StringName) -> void:
	if not catalog.is_unlocked(
		level_id,
		SystemChapter.completed_levels(),
		SystemChapter.prologue_ready,
		GameMode.is_test_mode()
	):
		status_label.text = _t(&"system.status.locked")
		status_label.add_theme_color_override("font_color", BAD)
		return
	_dismiss_level_completion()
	if not current_level_id.is_empty() and current_level_id != level_id:
		_save_level_session()
	_stop_playback()
	current_level_id = level_id
	current_level_definition = catalog.definition(level_id)
	latest_receipt = null
	latest_official_traces.clear()
	map_host.hide()
	lab_host.show()
	level_label.text = _t(&"system.level.header", [
		int(current_level_definition.get("order", 0)) + 1,
		_t(catalog.title_key(level_id)),
	])
	status_label.text = _t(&"system.status.ready")
	status_label.add_theme_color_override("font_color", WARNING)
	_load_level_session()
	_refresh_level_ui()
	_open_instrument(&"mission")
	_open_instrument(&"parts")


func _save_level_session() -> void:
	if current_level_id.is_empty() or editor == null:
		return
	var positions: Dictionary = {}
	for device_id: StringName in device_nodes:
		positions[String(device_id)] = (device_nodes[device_id] as GraphNode).position_offset
	var connections: Array[Dictionary] = []
	for connection: Dictionary in graph.get_connection_list():
		connections.append({
			"from_node": StringName(connection["from_node"]),
			"from_port": int(connection["from_port"]),
			"to_node": StringName(connection["to_node"]),
			"to_port": int(connection["to_port"]),
			"color_index": graph.get_connection_color_index(
				StringName(connection["from_node"]), int(connection["from_port"]),
				StringName(connection["to_node"]), int(connection["to_port"])
			),
		})
	level_sessions[_level_session_key(current_level_id)] = {
		"part_ids": selected_part_ids.duplicate(),
		"prediction_id": locked_prediction_id,
		"draft_source": editor.text,
		"applied_source": applied_program_source,
		"connections": connections,
		"positions": positions,
	}


func _load_level_session() -> void:
	editor_history.clear()
	editor_redo_history.clear()
	node_move_start_snapshot.clear()
	erase_start_snapshot.clear()
	graph.clear_connections()
	graph.clear_connection_presentations()
	_set_selected_system_devices([] as Array[StringName])
	var session: Dictionary = level_sessions.get(_level_session_key(current_level_id), {})
	var diagnosis_sandbox_locked: bool = _diagnosis_sandbox_locked()
	locked_prediction_id = StringName(session.get("prediction_id", &""))
	selected_part_ids.clear()
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		var default_part_id: StringName = catalog.default_part_id(current_level_id, kind)
		var saved_part_id := StringName(session.get("part_ids", {}).get(kind, default_part_id))
		selected_part_ids[kind] = default_part_id if diagnosis_sandbox_locked else saved_part_id
	_populate_part_selectors()
	var authored_source: String = String(current_level_definition.get("program_source", ""))
	var source: String = authored_source if diagnosis_sandbox_locked else String(session.get("draft_source", authored_source))
	editor.text = source
	var applied_source: String = authored_source if diagnosis_sandbox_locked else String(session.get("applied_source", ""))
	if applied_source.is_empty():
		applied_source = authored_source
	applied_program = ParserType.parse(applied_source)
	applied_program_source = applied_source if applied_program.is_valid() else ""
	draft_dirty = editor.text != applied_program_source
	var saved_positions: Dictionary = session.get("positions", {})
	for device_id: StringName in device_nodes:
		var node: GraphNode = device_nodes[device_id]
		node.position_offset = saved_positions.get(String(device_id), STANDARD_LAYOUT[device_id])
	var connections: Array = session.get("connections", [])
	if connections.is_empty() and int(current_level_definition.get("order", 0)) > 0:
		_connect_required_routes(false)
	else:
		for connection: Dictionary in connections:
			graph.connect_node(
				StringName(connection["from_node"]), int(connection["from_port"]),
				StringName(connection["to_node"]), int(connection["to_port"])
			)
			graph.set_connection_color_index(
				StringName(connection["from_node"]), int(connection["from_port"]),
				StringName(connection["to_node"]), int(connection["to_port"]),
				int(connection.get("color_index", _default_system_wire_color(connection)))
			)
	current_topology = _topology_from_graph()
	_validate_program_editor()
	_refresh_device_titles()


func _refresh_level_ui() -> void:
	mission_title_label.text = _t(catalog.title_key(current_level_id))
	mission_body_label.text = "%s\n\n%s" % [
		_t(catalog.description_key(current_level_id)),
		_t(StringName(current_level_definition.get("objective_key", &"system.level.unknown.objective"))),
	]
	_refresh_prediction_ui()
	case_selector.clear()
	for case: Dictionary in current_level_definition.get("cases", []):
		case_selector.add_item(_case_display(case))
	diagnosis_row.visible = bool(current_level_definition.get("diagnosis_required", false))
	profiler_tier_label.text = _t(&"system.profiler.tier", [int(current_level_definition.get("profiler_tier", 1))])
	_clear_result_rows()
	test_status_label.text = _t(&"system.test_bench.not_run")
	_refresh_program_state()
	_refresh_comparison_part_lock()
	_refresh_parts_summary()
	_refresh_profiler()
	_refresh_history()
	_refresh_mission_progress()


func _refresh_prediction_ui() -> void:
	if prediction_box == null:
		return
	var question_key := StringName(current_level_definition.get("prediction_key", &""))
	var options: Array = current_level_definition.get("prediction_options", [])
	prediction_box.visible = not question_key.is_empty() and not options.is_empty()
	if not prediction_box.visible:
		locked_prediction_id = &""
		return
	prediction_question_label.text = _t(question_key)
	prediction_selector.clear()
	prediction_selector.add_item(_t(&"system.prediction.choose"))
	prediction_selector.set_item_metadata(0, &"")
	var locked_index: int = 0
	for option: Dictionary in options:
		var option_id := StringName(option.get("id", &""))
		prediction_selector.add_item(_t(StringName(option.get("text_key", &""))))
		prediction_selector.set_item_metadata(prediction_selector.item_count - 1, option_id)
		if option_id == locked_prediction_id:
			locked_index = prediction_selector.item_count - 1
	if locked_index == 0:
		locked_prediction_id = &""
	prediction_selector.select(locked_index)
	var is_locked: bool = not locked_prediction_id.is_empty()
	prediction_selector.disabled = is_locked
	prediction_lock_button.disabled = is_locked or locked_index == 0
	prediction_status_label.text = _t(&"system.prediction.locked", [
		_prediction_option_text(locked_prediction_id)
	]) if is_locked else ""
	prediction_status_label.add_theme_color_override("font_color", GOOD if is_locked else WARNING)


func _on_prediction_selected(index: int) -> void:
	if prediction_selector == null or not locked_prediction_id.is_empty():
		return
	var selected_id := StringName(prediction_selector.get_item_metadata(index))
	prediction_lock_button.disabled = selected_id.is_empty()


func _lock_prediction() -> void:
	if prediction_selector == null or not locked_prediction_id.is_empty():
		return
	var selected_id := StringName(prediction_selector.get_item_metadata(prediction_selector.selected))
	if selected_id.is_empty():
		return
	locked_prediction_id = selected_id
	_refresh_prediction_ui()
	_refresh_program_state()
	_refresh_history()


func _prediction_required() -> bool:
	return not StringName(current_level_definition.get("prediction_key", &"")).is_empty()


func _prediction_option_text(prediction_id: StringName) -> String:
	for option: Dictionary in current_level_definition.get("prediction_options", []):
		if StringName(option.get("id", &"")) == prediction_id:
			return _t(StringName(option.get("text_key", &"")))
	return String(prediction_id)


func _reset_prediction() -> void:
	if not _prediction_required():
		return
	locked_prediction_id = &""
	_refresh_prediction_ui()


func _populate_part_selectors() -> void:
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		var selector: OptionButton = part_selectors[kind]
		selector.clear()
		var selected_index: int = 0
		for part: SystemPartSpec in catalog.parts_for_level(current_level_id, kind):
			selector.add_item(_part_label(part))
			selector.set_item_metadata(selector.item_count - 1, part.id)
			if part.id == selected_part_ids.get(kind, &""):
				selected_index = selector.item_count - 1
		selector.select(selected_index)
		if selector.item_count > 0:
			selected_part_ids[kind] = StringName(selector.get_item_metadata(selected_index))


func _comparison_kind() -> StringName:
	return StringName(current_level_definition.get("comparison_kind", &"none"))


func _is_part_comparison() -> bool:
	return _comparison_kind() in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]


func _applied_program_is_official() -> bool:
	return (
		applied_program != null
		and applied_program.is_valid()
		and catalog.is_official_program_signature(current_level_id, applied_program.canonical_signature())
	)


func _diagnosis_sandbox_locked() -> bool:
	return (
		bool(current_level_definition.get("diagnosis_required", false))
		and not bool(SystemChapter.completed_levels().get(current_level_id, false))
	)


func _uses_authored_diagnosis_configuration() -> bool:
	if applied_program == null or not applied_program.is_valid():
		return false
	if not catalog.is_official_program_signature(current_level_id, applied_program.canonical_signature()):
		return false
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		if selected_part_ids.get(kind, &"") != catalog.default_part_id(current_level_id, kind):
			return false
	return true


func _restore_authored_diagnosis_configuration() -> void:
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		selected_part_ids[kind] = catalog.default_part_id(current_level_id, kind)
	_populate_part_selectors()
	var authored_source: String = String(current_level_definition.get("program_source", ""))
	editor.text = authored_source
	applied_program = ParserType.parse(authored_source)
	applied_program_source = authored_source
	draft_dirty = false
	current_topology = _topology_from_graph()
	_validate_program_editor()
	_refresh_program_state()
	_refresh_comparison_part_lock()
	_refresh_device_titles()
	_refresh_parts_summary()


func _has_current_baseline_receipt() -> bool:
	if not _is_part_comparison() or applied_program == null or not applied_program.is_valid():
		return false
	var comparison_kind := _comparison_kind()
	var default_id: StringName = catalog.default_part_id(current_level_id, comparison_kind)
	var program_signature: String = applied_program.canonical_signature()
	var test_signature: String = catalog.test_set_signature(current_level_id)
	for receipt: Variant in SystemChapter.receipts_for(current_level_id):
		if (
			receipt == null
			or not receipt.all_passed
			or receipt.level_id != current_level_id
			or receipt.program_signature != program_signature
			or receipt.test_set_signature != test_signature
			or StringName(receipt.part_ids.get(comparison_kind, &"")) != default_id
		):
			continue
		var fixed_parts_match: bool = true
		for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
			if kind != comparison_kind and receipt.part_ids.get(kind, &"") != selected_part_ids.get(kind, &""):
				fixed_parts_match = false
				break
		if fixed_parts_match:
			return true
	return false


func _refresh_comparison_part_lock() -> void:
	for selector: OptionButton in part_selectors.values():
		selector.disabled = false
	if _diagnosis_sandbox_locked():
		for selector: OptionButton in part_selectors.values():
			selector.disabled = true
		return
	if not _is_part_comparison():
		return
	if not _applied_program_is_official():
		return
	var comparison_kind := _comparison_kind()
	var selector: OptionButton = part_selectors[comparison_kind]
	var baseline_ready: bool = _has_current_baseline_receipt()
	if not baseline_ready:
		var default_id: StringName = catalog.default_part_id(current_level_id, comparison_kind)
		selected_part_ids[comparison_kind] = default_id
		for index: int in range(selector.item_count):
			if StringName(selector.get_item_metadata(index)) == default_id:
				selector.select(index)
				break
		current_topology = _topology_from_graph()
		_refresh_device_titles()
	selector.disabled = not baseline_ready


func _on_part_selected(index: int, kind: StringName) -> void:
	if current_level_id.is_empty():
		return
	var selector: OptionButton = part_selectors[kind]
	if selector.disabled:
		for selected_index: int in range(selector.item_count):
			if StringName(selector.get_item_metadata(selected_index)) == selected_part_ids.get(kind, &""):
				selector.select(selected_index)
				break
		return
	selected_part_ids[kind] = StringName(selector.get_item_metadata(index))
	current_topology = _topology_from_graph()
	latest_receipt = null
	latest_official_traces.clear()
	_stop_playback()
	_refresh_device_titles()
	_refresh_parts_summary()
	_refresh_profiler()
	status_label.text = _t(&"system.status.hardware_changed")
	status_label.add_theme_color_override("font_color", WARNING)


func _refresh_device_titles() -> void:
	if current_level_id.is_empty():
		return
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		var slot: StringName = _slot_for_kind(kind)
		var selected: SystemPartSpec = catalog.part(selected_part_ids.get(kind, &""))
		if selected != null:
			(device_nodes[slot] as GraphNode).title = selected.display_name


func _refresh_parts_summary() -> void:
	if current_level_id.is_empty():
		return
	var lines := PackedStringArray()
	var cost: int = 0
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		var part: SystemPartSpec = catalog.part(selected_part_ids.get(kind, &""))
		if part == null:
			continue
		cost += part.hardware_cost
		lines.append(_part_detail(part))
	lines.append(_t(&"system.parts.total_cost", [cost]))
	parts_summary_label.text = "\n".join(lines)


func _part_label(part: SystemPartSpec) -> String:
	return "%s  ·  %s" % [part.display_name, _t(&"system.parts.cost", [part.hardware_cost])]


func _part_detail(part: SystemPartSpec) -> String:
	match part.kind:
		PartSpecType.KIND_CPU:
			return _t(&"system.parts.cpu_detail", [part.display_name, part.compute_cycles, part.hardware_cost])
		PartSpecType.KIND_RAM:
			return _t(&"system.parts.ram_detail", [part.display_name, part.access_cycles, part.hardware_cost])
		PartSpecType.KIND_BUS:
			return _t(&"system.parts.bus_detail", [part.display_name, part.bandwidth_bits_per_cycle, part.hardware_cost])
	return part.display_name


func _slot_for_kind(kind: StringName) -> StringName:
	match kind:
		PartSpecType.KIND_CPU: return TopologyType.CPU_ID
		PartSpecType.KIND_RAM: return TopologyType.RAM_ID
		PartSpecType.KIND_BUS: return TopologyType.BUS_ID
	return &""


func _capture_system_editor_snapshot() -> Dictionary:
	if graph == null:
		return {}
	var positions: Dictionary = {}
	for device_id: StringName in device_nodes:
		positions[device_id] = (device_nodes[device_id] as GraphNode).position_offset
	var connections: Array[Dictionary] = []
	for connection: Dictionary in graph.get_connection_list():
		connections.append(_system_connection_data(connection))
	connections.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return _system_connection_key(left) < _system_connection_key(right)
	)
	return {
		"positions": positions,
		"connections": connections,
		"selection": _selected_system_device_ids(),
	}


func _system_connection_data(connection: Dictionary) -> Dictionary:
	var from_node := StringName(connection.get("from_node", &""))
	var from_port: int = int(connection.get("from_port", 0))
	var to_node := StringName(connection.get("to_node", &""))
	var to_port: int = int(connection.get("to_port", 0))
	return {
		"from_node": from_node,
		"from_port": from_port,
		"to_node": to_node,
		"to_port": to_port,
		"color_index": graph.get_connection_color_index(from_node, from_port, to_node, to_port),
	}


func _system_connection_key(connection: Dictionary, include_color: bool = false) -> String:
	var key: String = "%s:%d>%s:%d" % [
		connection.get("from_node", &""), int(connection.get("from_port", 0)),
		connection.get("to_node", &""), int(connection.get("to_port", 0)),
	]
	return "%s@%d" % [key, int(connection.get("color_index", WirePaletteType.DEFAULT_INDEX))] \
		if include_color else key


func _system_editor_snapshot_signature(snapshot: Dictionary) -> String:
	var fields := PackedStringArray()
	var positions: Dictionary = snapshot.get("positions", {})
	var ids: Array[String] = []
	for id_variant: Variant in positions:
		ids.append(String(id_variant))
	ids.sort()
	for id: String in ids:
		var position: Vector2 = positions.get(StringName(id), positions.get(id, Vector2.ZERO))
		fields.append("P:%s:%.3f:%.3f" % [id, position.x, position.y])
	for connection: Dictionary in snapshot.get("connections", []):
		fields.append("W:%s" % _system_connection_key(connection, true))
	var selection: Array[String] = []
	for id_variant: Variant in snapshot.get("selection", []):
		selection.append(String(id_variant))
	selection.sort()
	for id: String in selection:
		fields.append("S:%s" % id)
	return "|".join(fields)


func _system_editor_topology_signature(snapshot: Dictionary) -> String:
	var keys := PackedStringArray()
	for connection: Dictionary in snapshot.get("connections", []):
		keys.append(_system_connection_key(connection))
	keys.sort()
	return "|".join(keys)


func _commit_system_editor_snapshot(kind: StringName, before: Dictionary) -> bool:
	if editor_history_replaying or before.is_empty():
		return false
	var after: Dictionary = _capture_system_editor_snapshot()
	if _system_editor_snapshot_signature(before) == _system_editor_snapshot_signature(after):
		return false
	editor_history.append({
		"kind": kind,
		"before": before.duplicate(true),
		"after": after.duplicate(true),
	})
	editor_redo_history.clear()
	_after_system_editor_mutation(
		_system_editor_topology_signature(before) != _system_editor_topology_signature(after)
	)
	return true


func _apply_system_editor_snapshot(snapshot: Dictionary) -> void:
	editor_history_replaying = true
	graph.clear_connections()
	graph.clear_connection_presentations()
	var positions: Dictionary = snapshot.get("positions", {})
	for device_id: StringName in device_nodes:
		var node: GraphNode = device_nodes[device_id]
		node.position_offset = positions.get(device_id, positions.get(String(device_id), node.position_offset))
	for connection: Dictionary in snapshot.get("connections", []):
		var from_node := StringName(connection.get("from_node", &""))
		var from_port: int = int(connection.get("from_port", 0))
		var to_node := StringName(connection.get("to_node", &""))
		var to_port: int = int(connection.get("to_port", 0))
		graph.connect_node(from_node, from_port, to_node, to_port)
		graph.set_connection_color_index(
			from_node, from_port, to_node, to_port,
			int(connection.get("color_index", WirePaletteType.DEFAULT_INDEX))
		)
	var selected_ids: Array[StringName] = []
	for id_variant: Variant in snapshot.get("selection", []):
		selected_ids.append(StringName(id_variant))
	_set_selected_system_devices(selected_ids)
	editor_history_replaying = false
	graph.queue_redraw()


func _after_system_editor_mutation(topology_changed: bool) -> void:
	current_topology = _topology_from_graph()
	if topology_changed:
		latest_receipt = null
		latest_official_traces.clear()
		_stop_playback()
	_save_level_session()


func _undo_system_edit() -> void:
	if editor_history.is_empty():
		status_label.text = _t(&"system.status.nothing_to_undo")
		status_label.add_theme_color_override("font_color", MUTED)
		return
	var action: Dictionary = editor_history.pop_back()
	var before: Dictionary = action.get("before", {})
	var after: Dictionary = action.get("after", {})
	_apply_system_editor_snapshot(before)
	editor_redo_history.append(action)
	_after_system_editor_mutation(
		_system_editor_topology_signature(before) != _system_editor_topology_signature(after)
	)
	status_label.text = _t(&"system.status.action_undone")
	status_label.add_theme_color_override("font_color", ACCENT)


func _redo_system_edit() -> void:
	if editor_redo_history.is_empty():
		status_label.text = _t(&"system.status.nothing_to_redo")
		status_label.add_theme_color_override("font_color", MUTED)
		return
	var action: Dictionary = editor_redo_history.pop_back()
	var before: Dictionary = action.get("before", {})
	var after: Dictionary = action.get("after", {})
	_apply_system_editor_snapshot(after)
	editor_history.append(action)
	_after_system_editor_mutation(
		_system_editor_topology_signature(before) != _system_editor_topology_signature(after)
	)
	status_label.text = _t(&"system.status.action_redone")
	status_label.add_theme_color_override("font_color", ACCENT)


func _selected_system_device_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for device_id: StringName in device_nodes:
		if (device_nodes[device_id] as GraphNode).selected:
			ids.append(device_id)
	ids.sort()
	return ids


func _set_selected_system_devices(ids: Array[StringName]) -> void:
	var selected: Dictionary[StringName, bool] = {}
	for device_id: StringName in ids:
		selected[device_id] = true
	for device_id: StringName in device_nodes:
		(device_nodes[device_id] as GraphNode).selected = selected.has(device_id)
	_sync_system_selection_feedback()


func _select_all_system_devices() -> void:
	var ids: Array[StringName] = []
	for device_id: StringName in device_nodes:
		ids.append(device_id)
	ids.sort()
	_set_selected_system_devices(ids)
	status_label.text = _t(&"system.status.all_selected", [ids.size()])
	status_label.add_theme_color_override("font_color", ACCENT)


func _sync_system_selection_feedback() -> void:
	for device_id: StringName in device_nodes:
		var surface: Control = device_surfaces.get(device_id)
		if surface != null:
			surface.call("set_selection_active", (device_nodes[device_id] as GraphNode).selected)


func _on_system_node_selection_changed(_node: Node) -> void:
	_sync_system_selection_feedback()


func _on_system_selection_rectangle_applied(_changed_count: int, selected_count: int) -> void:
	_sync_system_selection_feedback()
	status_label.text = _t(&"system.status.selection_count", [selected_count])
	status_label.add_theme_color_override("font_color", ACCENT if selected_count > 0 else MUTED)


func _system_node_local_point_hits_port(node: GraphNode, point: Vector2, radius: float) -> bool:
	for port: int in range(node.get_input_port_count()):
		if point.distance_to(node.get_input_port_position(port)) <= radius:
			return true
	for port: int in range(node.get_output_port_count()):
		if point.distance_to(node.get_output_port_position(port)) <= radius:
			return true
	return false


func _on_system_device_gui_input(event: InputEvent, device_id: StringName) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.pressed:
		_focus_system_graph_for_keyboard()
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed \
			or not mouse_event.shift_pressed:
		return
	var node: GraphNode = device_nodes.get(device_id)
	if node == null or _system_node_local_point_hits_port(node, mouse_event.position, 28.0):
		return
	node.selected = not node.selected
	_sync_system_selection_feedback()
	status_label.text = _t(&"system.status.selection_count", [_selected_system_device_ids().size()])
	status_label.add_theme_color_override("font_color", ACCENT)
	get_viewport().set_input_as_handled()


func _on_system_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_focus_system_graph_for_keyboard()


func _on_system_begin_node_move() -> void:
	if editor_history_replaying:
		return
	node_move_start_snapshot = _capture_system_editor_snapshot()


func _on_system_end_node_move() -> void:
	if editor_history_replaying or node_move_start_snapshot.is_empty():
		return
	var before: Dictionary = node_move_start_snapshot
	node_move_start_snapshot = {}
	if _commit_system_editor_snapshot(&"move_nodes", before):
		status_label.text = _t(&"system.status.nodes_moved", [_selected_system_device_ids().size()])
		status_label.add_theme_color_override("font_color", ACCENT)


func _on_system_erase_stroke_started() -> void:
	if erase_start_snapshot.is_empty():
		erase_start_snapshot = _capture_system_editor_snapshot()


func _on_system_erase_wire_requested(connection: Dictionary) -> void:
	_remove_system_connection(
		StringName(connection.get("from_node", &"")), int(connection.get("from_port", 0)),
		StringName(connection.get("to_node", &"")), int(connection.get("to_port", 0))
	)


func _on_system_erase_component_requested(device_id: StringName) -> void:
	_remove_incident_system_connections([device_id] as Array[StringName])


func _on_system_erase_stroke_finished() -> void:
	if erase_start_snapshot.is_empty():
		return
	var before: Dictionary = erase_start_snapshot
	erase_start_snapshot = {}
	if _commit_system_editor_snapshot(&"erase_stroke", before):
		status_label.text = _t(&"system.status.erase_finished")
		status_label.add_theme_color_override("font_color", WARNING)


func _on_system_delete_nodes_request(nodes: Array[StringName]) -> void:
	_delete_system_device_routes(nodes)


func _delete_selected_system_devices() -> void:
	_delete_system_device_routes(_selected_system_device_ids())


func _delete_system_device_routes(device_ids: Array[StringName]) -> void:
	if device_ids.is_empty():
		status_label.text = _t(&"system.status.nothing_selected_delete")
		status_label.add_theme_color_override("font_color", MUTED)
		return
	var before: Dictionary = _capture_system_editor_snapshot()
	_remove_incident_system_connections(device_ids)
	if _commit_system_editor_snapshot(&"delete_routes", before):
		status_label.text = _t(&"system.status.device_routes_removed", [device_ids.size()])
		status_label.add_theme_color_override("font_color", WARNING)
	else:
		status_label.text = _t(&"system.status.nothing_to_delete")
		status_label.add_theme_color_override("font_color", MUTED)


func _remove_incident_system_connections(device_ids: Array[StringName]) -> void:
	var targets: Dictionary[StringName, bool] = {}
	for device_id: StringName in device_ids:
		targets[device_id] = true
	var connections: Array[Dictionary] = graph.get_connection_list()
	for connection: Dictionary in connections:
		if targets.has(StringName(connection.get("from_node", &""))) \
				or targets.has(StringName(connection.get("to_node", &""))):
			_remove_system_connection(
				StringName(connection.get("from_node", &"")), int(connection.get("from_port", 0)),
				StringName(connection.get("to_node", &"")), int(connection.get("to_port", 0))
			)


func _remove_system_connection(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
	) -> bool:
	if not graph.is_node_connected(from_node, from_port, to_node, to_port):
		return false
	graph.disconnect_node(from_node, from_port, to_node, to_port)
	graph.remove_connection_presentation(from_node, from_port, to_node, to_port)
	return true


func _auto_layout(show_status: bool = true) -> void:
	if graph == null:
		return
	var before: Dictionary = _capture_system_editor_snapshot() if show_status else {}
	var width: float = maxf(1120.0, graph.size.x / maxf(graph.zoom, 0.01))
	var start_x: float = maxf(80.0, (width - 1120.0) * 0.5 + 80.0)
	for device_id: StringName in [&"CPU", &"BUS", &"RAM"]:
		var offset: Vector2 = STANDARD_LAYOUT[device_id]
		(device_nodes[device_id] as GraphNode).position_offset = Vector2(start_x + offset.x - 155.0, offset.y)
	if show_status:
		_commit_system_editor_snapshot(&"auto_layout", before)
		status_label.text = _t(&"system.status.layout_restored")
		status_label.add_theme_color_override("font_color", GOOD)


func _auto_connect() -> void:
	var before: Dictionary = _capture_system_editor_snapshot()
	_connect_required_routes(true)
	_commit_system_editor_snapshot(&"auto_connect", before)


func _connect_required_routes(show_status: bool) -> void:
	graph.clear_connections()
	graph.clear_connection_presentations()
	for route: Dictionary in TopologyType.REQUIRED_CONNECTIONS:
		var from_id := StringName(route["from"])
		var to_id := StringName(route["to"])
		var from_port: int = (OUTPUT_NAMES[from_id] as Array).find(StringName(route["from_port"]))
		var to_port: int = (INPUT_NAMES[to_id] as Array).find(StringName(route["to_port"]))
		graph.connect_node(from_id, from_port, to_id, to_port)
		graph.set_connection_color_index(
			from_id, from_port, to_id, to_port,
			_default_system_wire_color({
				"from_node": from_id, "from_port": from_port,
				"to_node": to_id, "to_port": to_port,
			})
		)
	current_topology = _topology_from_graph()
	latest_receipt = null
	if show_status:
		status_label.text = _t(&"system.status.wired")
		status_label.add_theme_color_override("font_color", GOOD)


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if not OUTPUT_NAMES.has(from_node) or not INPUT_NAMES.has(to_node):
		_show_connection_error()
		return
	var output_names: Array = OUTPUT_NAMES[from_node]
	var input_names: Array = INPUT_NAMES[to_node]
	if from_port < 0 or from_port >= output_names.size() or to_port < 0 or to_port >= input_names.size():
		_show_connection_error()
		return
	var trial: SystemTopology = _topology_from_graph()
	if not trial.connect_ports(from_node, output_names[from_port], to_node, input_names[to_port]):
		_show_connection_error()
		return
	var before: Dictionary = _capture_system_editor_snapshot()
	graph.connect_node(from_node, from_port, to_node, to_port)
	graph.set_connection_color_index(from_node, from_port, to_node, to_port, active_wire_color_index)
	_commit_system_editor_snapshot(&"connect", before)
	status_label.text = _t(&"system.status.connection_added")
	status_label.add_theme_color_override("font_color", GOOD)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var before: Dictionary = _capture_system_editor_snapshot()
	_remove_system_connection(from_node, from_port, to_node, to_port)
	_commit_system_editor_snapshot(&"disconnect", before)
	status_label.text = _t(&"system.status.connection_removed")
	status_label.add_theme_color_override("font_color", WARNING)


func _show_connection_error() -> void:
	status_label.text = _t(&"system.status.invalid_connection")
	status_label.add_theme_color_override("font_color", BAD)


func _topology_from_graph() -> SystemTopology:
	var topology := TopologyType.new()
	topology.set_part(TopologyType.CPU_ID, catalog.part(selected_part_ids.get(PartSpecType.KIND_CPU, &"")))
	topology.set_part(TopologyType.RAM_ID, catalog.part(selected_part_ids.get(PartSpecType.KIND_RAM, &"")))
	topology.set_part(TopologyType.BUS_ID, catalog.part(selected_part_ids.get(PartSpecType.KIND_BUS, &"")))
	for connection: Dictionary in graph.get_connection_list():
		var from_id := StringName(connection["from_node"])
		var to_id := StringName(connection["to_node"])
		var from_port: int = int(connection["from_port"])
		var to_port: int = int(connection["to_port"])
		if not OUTPUT_NAMES.has(from_id) or not INPUT_NAMES.has(to_id):
			continue
		var output_names: Array = OUTPUT_NAMES[from_id]
		var input_names: Array = INPUT_NAMES[to_id]
		if from_port >= 0 and from_port < output_names.size() and to_port >= 0 and to_port < input_names.size():
			topology.connect_ports(from_id, output_names[from_port], to_id, input_names[to_port])
	return topology


func _on_program_changed() -> void:
	if current_level_id.is_empty():
		return
	draft_dirty = editor.text != applied_program_source
	_validate_program_editor()
	_refresh_program_state()


func _validate_program_editor() -> void:
	if editor == null:
		return
	var parsed: SystemProgram = ParserType.parse(editor.text)
	if parsed.is_valid():
		program_validation_label.text = _t(&"system.program.valid")
		program_validation_label.add_theme_color_override("font_color", GOOD)
	else:
		var localized_errors := PackedStringArray()
		for spec: Dictionary in parsed.error_specs:
			localized_errors.append(Localization.text_from_spec(spec))
		program_validation_label.text = "\n".join(localized_errors)
		program_validation_label.add_theme_color_override("font_color", BAD)
	apply_program_button.disabled = not parsed.is_valid() or not draft_dirty
	_update_program_explanation(parsed)


func _apply_program() -> void:
	if _diagnosis_sandbox_locked():
		_restore_authored_diagnosis_configuration()
		status_label.text = _t(&"system.status.official_program_required")
		status_label.add_theme_color_override("font_color", WARNING)
		return
	var parsed: SystemProgram = ParserType.parse(editor.text)
	if not parsed.is_valid():
		_validate_program_editor()
		status_label.text = _t(&"system.status.program_invalid")
		status_label.add_theme_color_override("font_color", BAD)
		return
	applied_program = parsed
	applied_program_source = editor.text
	draft_dirty = false
	_reset_prediction()
	latest_receipt = null
	latest_official_traces.clear()
	_stop_playback()
	_validate_program_editor()
	_refresh_program_state()
	_refresh_comparison_part_lock()
	_refresh_device_titles()
	_refresh_parts_summary()
	_refresh_history()
	status_label.text = _t(&"system.status.program_applied")
	status_label.add_theme_color_override("font_color", GOOD)


func _refresh_program_state() -> void:
	if program_apply_label == null:
		return
	var diagnosis_sandbox_locked: bool = _diagnosis_sandbox_locked()
	editor.editable = not diagnosis_sandbox_locked
	if draft_dirty:
		program_apply_label.text = _t(&"system.program.draft_pending")
		program_apply_label.add_theme_color_override("font_color", WARNING)
	else:
		program_apply_label.text = _t(&"system.program.applied")
		program_apply_label.add_theme_color_override("font_color", GOOD)
	var prediction_ready: bool = not _prediction_required() or not locked_prediction_id.is_empty()
	debug_run_button.disabled = draft_dirty or applied_program == null or not applied_program.is_valid() or not prediction_ready
	official_run_button.disabled = debug_run_button.disabled
	apply_program_button.disabled = apply_program_button.disabled or diagnosis_sandbox_locked


func _update_program_explanation(program: SystemProgram) -> void:
	if program_explanation_label == null:
		return
	var lines := PackedStringArray(["[color=#50d5ff]%s[/color]" % _t(&"system.program.explanation.title")])
	var specs: Dictionary[int, Dictionary] = program.line_explanation_specs()
	var line_numbers: Array[int] = []
	for line_number: int in specs:
		line_numbers.append(line_number)
	line_numbers.sort()
	for line_number: int in line_numbers:
		lines.append("[color=#91a0b9]%d[/color]  %s" % [line_number, Localization.text_from_spec(specs[line_number])])
	program_explanation_label.text = "\n".join(lines)


func _run_debug_case() -> void:
	if not _prepare_run():
		return
	var cases: Array = current_level_definition.get("cases", [])
	if cases.is_empty():
		return
	var index: int = clampi(case_selector.selected, 0, cases.size() - 1)
	var case: Dictionary = cases[index]
	var trace: SystemTrace = core.run(
		applied_program,
		current_topology,
		_typed_int_array(case.get("input", [])),
		_typed_int_array(case.get("expected", [])),
		String(case.get("name", "debug"))
	)
	_clear_result_rows()
	_add_result_row(trace)
	test_status_label.text = _t(&"system.test_bench.debug_pass") if trace.passed else _t(&"system.test_bench.debug_fail")
	test_status_label.add_theme_color_override("font_color", GOOD if trace.passed else BAD)
	latest_receipt = null
	pending_history_after_playback = false
	_close_instrument(&"history")
	_play_trace(trace)
	_refresh_profiler(trace.metrics)


func _run_official() -> void:
	if not _prepare_run():
		return
	latest_official_traces.clear()
	_clear_result_rows()
	for case: Dictionary in current_level_definition.get("cases", []):
		var trace: SystemTrace = core.run(
			applied_program,
			current_topology,
			_typed_int_array(case.get("input", [])),
			_typed_int_array(case.get("expected", [])),
			String(case.get("name", "official"))
		)
		latest_official_traces.append(trace)
		_add_result_row(trace)
	latest_receipt = ReceiptType.new()
	latest_receipt.populate_from_traces(
		current_level_id,
		latest_official_traces,
		catalog.test_set_signature(current_level_id),
		selected_part_ids
	)
	var is_progression_evidence: bool = catalog.is_official_program_signature(
		current_level_id, latest_receipt.program_signature
	)
	if is_progression_evidence:
		SystemChapter.record_receipt(current_level_id, latest_receipt)
	_refresh_comparison_part_lock()
	if not is_progression_evidence:
		test_status_label.text = _t(&"system.test_bench.custom_program_debug_only", [
			latest_receipt.passed_cases, latest_receipt.total_cases,
		])
		test_status_label.add_theme_color_override("font_color", WARNING)
	elif latest_receipt.all_passed:
		test_status_label.text = _t(&"system.test_bench.official_pass", [latest_receipt.passed_cases, latest_receipt.total_cases])
		test_status_label.add_theme_color_override("font_color", GOOD)
	else:
		test_status_label.text = _t(&"system.test_bench.official_fail", [latest_receipt.passed_cases, latest_receipt.total_cases])
		test_status_label.add_theme_color_override("font_color", BAD)
	pending_history_after_playback = is_progression_evidence and _comparison_kind() != &"none"
	_close_instrument(&"history")
	if not latest_official_traces.is_empty():
		_play_trace(latest_official_traces[0])
	_refresh_profiler(latest_receipt.metrics)
	_refresh_history()
	if pending_history_after_playback and not playback_running:
		pending_history_after_playback = false
		_open_instrument(&"history")
	if is_progression_evidence:
		if bool(SystemChapter.completed_levels().get(current_level_id, false)):
			_refresh_mission_progress()
		else:
			_evaluate_completion(&"")
	else:
		status_label.text = _t(&"system.status.official_program_required")
		status_label.add_theme_color_override("font_color", WARNING)
		_refresh_mission_progress()


func _prepare_run() -> bool:
	# Re-check the actual editor text at the evidence boundary. This also covers
	# programmatic paste/set operations that do not emit TextEdit.text_changed.
	draft_dirty = editor.text != applied_program_source
	_refresh_program_state()
	if draft_dirty or applied_program == null or not applied_program.is_valid():
		status_label.text = _t(&"system.status.apply_required")
		status_label.add_theme_color_override("font_color", WARNING)
		_open_instrument(&"program")
		return false
	if _prediction_required() and locked_prediction_id.is_empty():
		status_label.text = _t(&"system.status.prediction_required")
		status_label.add_theme_color_override("font_color", WARNING)
		_open_instrument(&"mission")
		return false
	if _diagnosis_sandbox_locked() and not _uses_authored_diagnosis_configuration():
		_restore_authored_diagnosis_configuration()
		status_label.text = _t(&"system.status.official_program_required")
		status_label.add_theme_color_override("font_color", WARNING)
		_open_instrument(&"program")
		return false
	if _is_part_comparison() and _applied_program_is_official() and not _has_current_baseline_receipt():
		var comparison_kind := _comparison_kind()
		var default_id: StringName = catalog.default_part_id(current_level_id, comparison_kind)
		if selected_part_ids.get(comparison_kind, &"") != default_id:
			status_label.text = _t(&"system.status.baseline_required")
			status_label.add_theme_color_override("font_color", WARNING)
			_refresh_comparison_part_lock()
			_refresh_parts_summary()
			_open_instrument(&"parts")
			return false
	current_topology = _topology_from_graph()
	var errors: PackedStringArray = current_topology.validation_errors()
	if not errors.is_empty():
		status_label.text = _t(&"system.status.topology_invalid", [errors.size()])
		status_label.add_theme_color_override("font_color", BAD)
		playback_caption.text = _localized_topology_error(errors[0])
		return false
	return true


func _confirm_diagnosis() -> void:
	if latest_receipt == null or not latest_receipt.all_passed:
		test_status_label.text = _t(&"system.diagnosis.run_first")
		test_status_label.add_theme_color_override("font_color", WARNING)
		return
	revealed_breakdown_receipt_signature = latest_receipt.canonical_signature()
	_refresh_profiler(latest_receipt.metrics)
	var selected := StringName(diagnosis_selector.get_item_metadata(diagnosis_selector.selected))
	_evaluate_completion(selected)


func _evaluate_completion(selected_diagnosis: StringName) -> void:
	var receipts: Array = SystemChapter.receipts_for(current_level_id)
	var completion: Dictionary = catalog.completion_status(current_level_id, receipts, selected_diagnosis)
	if bool(completion.get("complete", false)):
		SystemChapter.mark_completed(current_level_id)
		_refresh_program_state()
		_refresh_comparison_part_lock()
		mission_progress_label.text = _t(&"system.mission.complete")
		mission_progress_label.add_theme_color_override("font_color", GOOD)
		status_label.text = _t(&"system.status.level_complete")
		status_label.add_theme_color_override("font_color", GOOD)
		if bool(current_level_definition.get("diagnosis_required", false)):
			test_status_label.text = _t(&"system.diagnosis.correct", [
				_t(StringName("system.diagnosis.%s" % String(latest_receipt.diagnosed_bottleneck)))
			])
			test_status_label.add_theme_color_override("font_color", GOOD)
	else:
		var reason := StringName(completion.get("reason", &"run_required"))
		if reason == &"diagnosis_required":
			if selected_diagnosis.is_empty():
				status_label.text = _t(&"system.status.diagnosis_ready")
			else:
				test_status_label.text = _t(&"system.diagnosis.incorrect")
				test_status_label.add_theme_color_override("font_color", BAD)
				status_label.text = _t(&"system.status.diagnosis_retry")
		else:
			status_label.text = _t(&"system.status.evidence_progress", [
				int(completion.get("progress", 0)), int(completion.get("required", 1))
			])
		status_label.add_theme_color_override("font_color", WARNING)
	_refresh_mission_progress(selected_diagnosis)


func _refresh_mission_progress(selected_diagnosis: StringName = &"") -> void:
	if current_level_id.is_empty():
		return
	var completion: Dictionary = catalog.completion_status(
		current_level_id,
		SystemChapter.receipts_for(current_level_id),
		selected_diagnosis
	)
	if bool(SystemChapter.completed_levels().get(current_level_id, false)):
		mission_progress_label.text = _t(&"system.mission.complete")
		mission_progress_label.add_theme_color_override("font_color", GOOD)
		conclusion_button.show()
	else:
		mission_progress_label.text = _t(&"system.mission.progress", [
			int(completion.get("progress", 0)), int(completion.get("required", 1))
		])
		mission_progress_label.add_theme_color_override("font_color", WARNING)
		conclusion_button.hide()


func _clear_result_rows() -> void:
	if official_result_box == null:
		return
	for child: Node in official_result_box.get_children():
		child.queue_free()


func _add_result_row(trace: SystemTrace) -> void:
	var row := Label.new()
	row.text = _t(&"system.test_bench.result", [
		trace.test_name,
		_format_bytes(trace.expected_output),
		_format_bytes(trace.output_data),
		int(trace.metrics.get("total_cycles", 0)),
		_t(&"system.result.pass") if trace.passed else _t(&"system.result.fail"),
	])
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_theme_color_override("font_color", GOOD if trace.passed else BAD)
	official_result_box.add_child(row)


func _refresh_profiler(metrics: Dictionary = {}) -> void:
	var tier: int = int(current_level_definition.get("profiler_tier", 1)) if not current_level_definition.is_empty() else 1
	var has_trace: bool = not metrics.is_empty()
	var diagnosis_required: bool = bool(current_level_definition.get("diagnosis_required", false))
	var diagnosis_gate_active: bool = diagnosis_required and _diagnosis_sandbox_locked()
	var breakdown_revealed: bool = (
		latest_receipt != null
		and latest_receipt.canonical_signature() == revealed_breakdown_receipt_signature
	)
	var final_raw_metrics: Array[StringName] = [
		&"total_cycles", &"cpu_wait_cycles", &"memory_requests",
		&"bus_segments_per_word", &"bytes_transferred", &"hardware_cost",
	]
	var visibility := {
		&"total_cycles": 1,
		&"cpu_compute_cycles": 2,
		&"cpu_wait_cycles": 2,
		&"ram_service_cycles": 3,
		&"memory_requests": 3,
		&"bus_control_cycles": 4,
		&"bus_transfer_cycles": 4,
		&"bus_segments_per_word": 4,
		&"bytes_transferred": 5,
		&"hardware_cost": 5,
		&"shares": 5,
	}
	for metric: StringName in profiler_labels:
		var label: Label = profiler_labels[metric]
		label.visible = tier >= int(visibility[metric])
		if diagnosis_gate_active and not breakdown_revealed:
			label.visible = metric in final_raw_metrics or metric == &"shares"
		if not label.visible:
			continue
		if metric == &"shares" and diagnosis_gate_active and not breakdown_revealed:
			label.text = _t(&"system.profiler.breakdown_locked")
			continue
		if not has_trace:
			label.text = _t(&"system.profiler.no_data", [_profiler_metric_name(metric)])
			continue
		if metric == &"shares":
			var cpu: int = int(metrics.get("cpu_compute_cycles", 0))
			var ram: int = int(metrics.get("ram_service_cycles", 0))
			var bus: int = int(metrics.get("bus_control_cycles", 0)) + int(metrics.get("bus_transfer_cycles", 0))
			var accounted: int = maxi(1, cpu + ram + bus)
			label.text = _t(&"system.profiler.shares", [
				roundi(float(cpu) * 100.0 / accounted),
				roundi(float(ram) * 100.0 / accounted),
				roundi(float(bus) * 100.0 / accounted),
			])
		else:
			label.text = _t(StringName("system.profiler.metric.%s" % String(metric)), [int(metrics.get(String(metric), metrics.get(metric, 0)))])


func _profiler_metric_name(metric: StringName) -> String:
	return _t(StringName("system.profiler.name.%s" % String(metric)))


func _refresh_history() -> void:
	if history_label == null or current_level_id.is_empty():
		return
	var receipts: Array = []
	var current_program_signature: String = applied_program.canonical_signature() if applied_program != null and applied_program.is_valid() else ""
	var current_test_signature: String = catalog.test_set_signature(current_level_id)
	for receipt: Variant in SystemChapter.receipts_for(current_level_id):
		if (
			receipt != null
			and receipt.all_passed
			and receipt.test_set_signature == current_test_signature
			and (current_program_signature.is_empty() or receipt.program_signature == current_program_signature)
		):
			receipts.append(receipt)
	var lines := PackedStringArray(["[color=#50d5ff]%s[/color]" % _t(&"system.history.heading")])
	if not locked_prediction_id.is_empty():
		lines.append(_t(&"system.history.prediction", [_prediction_option_text(locked_prediction_id)]))
	if receipts.is_empty():
		lines.append(_t(&"system.history.empty"))
	else:
		var comparison_kind := StringName(current_level_definition.get("comparison_kind", &"none"))
		var pair: Array = _latest_controlled_pair(receipts, comparison_kind)
		if pair.size() == 2:
			var before = pair[0]
			var after = pair[1]
			lines.append("[color=#bc8cff]%s[/color]" % _t(&"system.history.comparison", [
				_friendly_part_name(StringName(before.part_ids.get(comparison_kind, &""))),
				_friendly_part_name(StringName(after.part_ids.get(comparison_kind, &""))),
			]))
			lines.append(_t(&"system.history.only_changed", [_part_kind_name(comparison_kind)]))
			lines.append(_t(&"system.history.fixed", [_fixed_control_summary(before, comparison_kind)]))
			var before_total: int = int(before.metrics.get("total_cycles", 0))
			var after_total: int = int(after.metrics.get("total_cycles", 0))
			lines.append(_t(&"system.history.total_delta", [
				before_total, after_total, _history_delta(after_total - before_total, before_total, true),
			]))
			var before_wait: int = int(before.metrics.get("cpu_wait_cycles", 0))
			var after_wait: int = int(after.metrics.get("cpu_wait_cycles", 0))
			lines.append(_t(&"system.history.wait_delta", [
				before_wait, after_wait, _history_delta(after_wait - before_wait, before_wait, false),
			]))
			var metric := _comparison_history_metric(comparison_kind)
			if not metric.is_empty():
				var before_metric: int = int(before.metrics.get(String(metric), before.metrics.get(metric, 0)))
				var after_metric: int = int(after.metrics.get(String(metric), after.metrics.get(metric, 0)))
				lines.append(_t(&"system.history.metric_delta", [
					_profiler_metric_name(metric), before_metric, after_metric,
					_history_delta(after_metric - before_metric, before_metric, false),
				]))
		else:
			var baseline = receipts[receipts.size() - 1]
			var evidence_key := &"system.history.observation" if comparison_kind == &"diagnosis" else &"system.history.baseline"
			lines.append(_t(evidence_key, [_machine_summary(baseline)]))
			lines.append(_t(&"system.history.baseline_metrics", [
				int(baseline.metrics.get("total_cycles", 0)),
				int(baseline.metrics.get("cpu_wait_cycles", 0)),
			]))
			if comparison_kind in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
				lines.append(_t(&"system.history.next", [_part_kind_name(comparison_kind)]))
	if bool(current_level_definition.get("diagnosis_required", false)) and latest_official_traces.size() > 1:
		lines.append("[color=#bc8cff]%s[/color]" % _t(&"system.history.workload_heading"))
		for trace: SystemTrace in latest_official_traces:
			lines.append(_t(&"system.history.workload_row", [
				trace.test_name,
				int(trace.metrics.get("total_cycles", 0)),
				int(trace.metrics.get("cpu_wait_cycles", 0)),
			]))
	history_label.text = "\n".join(lines)


func _latest_controlled_pair(receipts: Array, comparison_kind: StringName) -> Array:
	if comparison_kind not in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		return []
	var start: int = maxi(0, receipts.size() - RUN_HISTORY_LIMIT)
	for after_index: int in range(receipts.size() - 1, start - 1, -1):
		var after = receipts[after_index]
		for before_index: int in range(after_index - 1, start - 1, -1):
			var before = receipts[before_index]
			if before.program_signature != after.program_signature or before.test_set_signature != after.test_set_signature:
				continue
			if before.part_ids.get(comparison_kind, &"") == after.part_ids.get(comparison_kind, &""):
				continue
			var controlled: bool = true
			for fixed_kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
				if fixed_kind != comparison_kind and before.part_ids.get(fixed_kind, &"") != after.part_ids.get(fixed_kind, &""):
					controlled = false
					break
			if controlled:
				return [before, after]
	return []


func _machine_summary(receipt: Variant) -> String:
	var parts := PackedStringArray()
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		parts.append(_friendly_part_name(StringName(receipt.part_ids.get(kind, &""))))
	return " / ".join(parts)


func _fixed_control_summary(receipt: Variant, comparison_kind: StringName) -> String:
	var controls := PackedStringArray()
	for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		if kind == comparison_kind:
			continue
		controls.append("%s=%s" % [
			_part_kind_name(kind), _friendly_part_name(StringName(receipt.part_ids.get(kind, &""))),
		])
	return " · ".join(controls)


func _friendly_part_name(part_id: StringName) -> String:
	var part: SystemPartSpec = catalog.part(part_id)
	return part.display_name if part != null else String(part_id)


func _part_kind_name(kind: StringName) -> String:
	return _t(StringName("system.part.%s" % String(kind)))


func _comparison_history_metric(comparison_kind: StringName) -> StringName:
	match comparison_kind:
		PartSpecType.KIND_CPU:
			return &"cpu_compute_cycles"
		PartSpecType.KIND_RAM:
			return &"ram_service_cycles"
		PartSpecType.KIND_BUS:
			return &"bus_transfer_cycles"
	return &""


func _history_delta(change: int, baseline: int, include_percent: bool) -> String:
	var signed_change: String = "+%d" % change if change > 0 else str(change)
	if not include_percent or baseline == 0:
		return signed_change
	var percent: int = roundi(float(change) * 100.0 / float(baseline))
	var signed_percent: String = "+%d%%" % percent if percent > 0 else "%d%%" % percent
	return "%s · %s" % [signed_change, signed_percent]


func _play_trace(trace: SystemTrace) -> void:
	current_trace = trace
	playback_index = 0
	playback_elapsed = 0.0
	playback_progress.value = 0.0
	playback_running = trace != null and not trace.events.is_empty()
	pause_button.text = _t(&"system.playback.pause")
	if playback_running:
		playback_caption.text = _t(&"system.playback.case", [trace.test_name])
	else:
		playback_caption.text = _t(&"system.playback.no_events")


func _show_event(event: SystemEvent, progress: float) -> void:
	_clear_device_feedback()
	for device: StringName in event.route_devices:
		if device_surfaces.has(device):
			device_surfaces[device].call("show_activity", event.kind, progress, event.details)
		_set_device_state(device, _event_device_state(event, device), _event_color(event.kind))
	if bool(event.details.get("cpu_waiting", false)):
		device_surfaces[&"CPU"].call("show_activity", event.kind, progress, event.details)
		_set_device_state(&"CPU", _t(&"system.device.cpu_wait"), WARNING)
	var route_paths: Array = _event_paths(event)
	if not route_paths.is_empty():
		trace_overlay.show_transfer_segments(
			route_paths,
			progress,
			_event_wire_color(event),
			_event_packet_label(event),
			int(event.details.get("segments", 1))
		)
	else:
		trace_overlay.clear_event()
	playback_caption.text = _t(&"system.playback.event", [
		event.cycle,
		event.cycle + event.duration,
		_event_name(event.kind),
		event.source_line,
	])
	_highlight_source_line(event.source_line)


func _clear_device_feedback() -> void:
	for device_id: StringName in device_surfaces:
		device_surfaces[device_id].call("clear_activity")
		_set_device_state(device_id, _t(&"system.device.idle"), MUTED)


func _set_device_state(device: StringName, text_value: String, color: Color) -> void:
	var label: Label = device_state_labels.get(device)
	if label == null:
		return
	label.text = text_value
	label.add_theme_color_override("font_color", color)


func _event_device_state(event: SystemEvent, device: StringName) -> String:
	if device == &"CPU":
		return _t(&"system.device.cpu_compute") if event.kind == &"compute" else _t(&"system.device.cpu_wait")
	if device == &"RAM":
		return _t(&"system.device.ram_write") if event.kind == &"ram_write" else _t(&"system.device.ram_read")
	if device == &"BUS":
		return _t(&"system.device.bus_control") if event.kind in [&"read_request", &"write_request"] else _t(&"system.device.bus_transfer")
	return _t(&"system.device.idle")


func _event_path(event: SystemEvent) -> PackedVector2Array:
	var complete := PackedVector2Array()
	for segment_variant: Variant in _event_paths(event):
		var segment: PackedVector2Array = segment_variant
		for point: Vector2 in segment:
			complete.append(point)
	return complete


func _event_paths(event: SystemEvent) -> Array:
	if event.route_devices.size() < 2:
		return []
	var paths: Array = []
	for index: int in range(event.route_devices.size() - 1):
		var segment: PackedVector2Array = _connection_curve(event.route_devices[index], event.route_devices[index + 1])
		if segment.size() < 2:
			return []
		paths.append(segment)
	return paths


func _connection_curve(from_device: StringName, to_device: StringName) -> PackedVector2Array:
	for route: Dictionary in TopologyType.REQUIRED_CONNECTIONS:
		if StringName(route["from"]) != from_device or StringName(route["to"]) != to_device:
			continue
		var from_port: int = (OUTPUT_NAMES[from_device] as Array).find(StringName(route["from_port"]))
		var to_port: int = (INPUT_NAMES[to_device] as Array).find(StringName(route["to_port"]))
		if not graph.is_node_connected(from_device, from_port, to_device, to_port):
			return PackedVector2Array()
		var graph_curve: PackedVector2Array = graph.connection_curve({
			"from_node": from_device,
			"from_port": from_port,
			"to_node": to_device,
			"to_port": to_port,
		})
		var overlay_curve := PackedVector2Array()
		var overlay_inverse: Transform2D = trace_overlay.get_global_transform().affine_inverse()
		for point: Vector2 in graph_curve:
			overlay_curve.append(overlay_inverse * (graph.get_global_transform() * point))
		return overlay_curve
	return PackedVector2Array()


func _event_packet_label(event: SystemEvent) -> String:
	if event.kind in [&"read_data", &"write_data"]:
		return "0x%02X" % int(event.details.get("value", 0))
	if event.kind in [&"read_request", &"write_request"]:
		return "@%d" % int(event.details.get("index", 0))
	return ""


func _event_wire_color(event: SystemEvent) -> Color:
	if event.route_devices.size() < 2:
		return _event_color(event.kind)
	var from_id: StringName = event.route_devices[0]
	var to_id: StringName = event.route_devices[1]
	for route: Dictionary in TopologyType.REQUIRED_CONNECTIONS:
		if StringName(route.get("from", &"")) != from_id \
				or StringName(route.get("to", &"")) != to_id:
			continue
		var from_port: int = (OUTPUT_NAMES[from_id] as Array).find(StringName(route["from_port"]))
		var to_port: int = (INPUT_NAMES[to_id] as Array).find(StringName(route["to_port"]))
		return WirePaletteType.color(graph.get_connection_color_index(
			from_id, from_port, to_id, to_port
		))
	return _event_color(event.kind)


func _event_name(kind: StringName) -> String:
	return _t(StringName("system.event.%s" % String(kind)))


func _event_color(kind: StringName) -> Color:
	match kind:
		&"read_data", &"ram_read": return GOOD
		&"write_data", &"ram_write": return WARNING
		&"compute": return PURPLE
	return ACCENT


func _display_duration(event: SystemEvent) -> float:
	return 0.28 + sqrt(float(maxi(1, event.duration))) * 0.11


func _toggle_pause() -> void:
	if current_trace == null:
		return
	playback_running = not playback_running
	pause_button.text = _t(&"system.playback.pause") if playback_running else _t(&"system.playback.resume")


func _step_playback() -> void:
	if current_trace == null or playback_index >= current_trace.events.size():
		return
	playback_running = false
	pause_button.text = _t(&"system.playback.resume")
	_show_event(current_trace.events[playback_index], 1.0)
	playback_index += 1
	playback_elapsed = 0.0
	playback_progress.value = float(playback_index) / float(maxi(1, current_trace.events.size())) * 100.0
	if playback_index >= current_trace.events.size():
		_finish_playback()


func _finish_playback() -> void:
	playback_running = false
	playback_index = current_trace.events.size() if current_trace != null else 0
	playback_elapsed = 0.0
	playback_progress.value = 100.0 if current_trace != null else 0.0
	trace_overlay.clear_event()
	_clear_device_feedback()
	_clear_source_highlight()
	pause_button.text = _t(&"system.playback.resume")
	playback_caption.text = _t(&"system.playback.complete")
	if pending_history_after_playback:
		pending_history_after_playback = false
		_open_instrument(&"history")


func _stop_playback() -> void:
	playback_running = false
	pending_history_after_playback = false
	current_trace = null
	playback_index = 0
	playback_elapsed = 0.0
	if trace_overlay != null:
		trace_overlay.clear_event()
	if not device_surfaces.is_empty():
		_clear_device_feedback()
	if playback_progress != null:
		playback_progress.value = 0.0
	_clear_source_highlight()


func _highlight_source_line(line_number: int) -> void:
	if editor == null or line_number <= 0:
		return
	_clear_source_highlight()
	highlighted_source_line = line_number - 1
	if highlighted_source_line < editor.get_line_count():
		editor.set_line_background_color(highlighted_source_line, Color(ACCENT, 0.13))
		editor.set_caret_line(highlighted_source_line)


func _clear_source_highlight() -> void:
	if editor != null and highlighted_source_line >= 0 and highlighted_source_line < editor.get_line_count():
		editor.set_line_background_color(highlighted_source_line, Color.TRANSPARENT)
	highlighted_source_line = -1


func _open_instrument(id: StringName) -> void:
	var panel: FloatingInstrumentPanel = instrument_windows.get(id)
	if panel == null:
		return
	panel.show()
	if panel.minimized:
		panel.set_minimized(false)
	_focus_instrument(id)


func _close_instrument(id: StringName) -> void:
	var panel: FloatingInstrumentPanel = instrument_windows.get(id)
	if panel != null:
		panel.hide()


func _focus_instrument(id: StringName) -> void:
	var panel: FloatingInstrumentPanel = instrument_windows.get(id)
	if panel == null:
		return
	instrument_z_counter += 1
	panel.z_index = instrument_z_counter


func _on_desktop_resized() -> void:
	if desktop_host == null or instrument_windows.is_empty():
		return
	var new_size: Vector2 = desktop_host.size
	if new_size.x <= 0.0 or new_size.y <= 0.0:
		return
	var previous := Vector2(maxf(1.0, instrument_layout_size.x), maxf(1.0, instrument_layout_size.y))
	var scale := Vector2(new_size.x / previous.x, new_size.y / previous.y)
	for panel: FloatingInstrumentPanel in instrument_windows.values():
		panel.position *= scale
		if not panel.minimized:
			panel.size *= scale
		panel.fit_to_parent(8.0)
	instrument_layout_size = new_size


func _on_mode_changed(_mode: StringName) -> void:
	_save_level_session()
	current_level_id = &""
	current_level_definition.clear()
	active_mode = &"test" if GameMode.is_test_mode() else &"game"
	_rebuild_catalog()
	_open_map()


func _level_session_key(level_id: StringName) -> StringName:
	return StringName("%s:%s" % [active_mode, level_id])


func _capture_system_workspace() -> void:
	if GameMode.is_test_mode():
		_start_level(&"bus_width")
	else:
		_open_map()
	if not current_level_id.is_empty():
		_auto_connect()
		_open_instrument(&"program")
		_open_instrument(&"profiler")
		_open_instrument(&"mission")


func _capture_system_run() -> void:
	if not GameMode.is_test_mode():
		return
	_start_level(&"bus_width")
	_auto_connect()
	prediction_selector.select(1)
	_lock_prediction()
	_run_official()
	playback_running = false
	pending_history_after_playback = false
	for panel: FloatingInstrumentPanel in instrument_windows.values():
		panel.hide()
	# Wait for GraphNode slot layout so the frozen QA packet uses final displayed
	# port transforms just like ordinary per-frame playback.
	await get_tree().process_frame
	await get_tree().process_frame
	for trace_event: SystemEvent in current_trace.events:
		if trace_event.kind == &"read_data":
			_show_event(trace_event, 0.58)
			break


func _case_display(case: Dictionary) -> String:
	return _t(&"system.test_bench.case", [
		String(case.get("name", "case")),
		_format_bytes(_typed_int_array(case.get("input", []))),
	])


func _format_bytes(values: Array[int]) -> String:
	var formatted := PackedStringArray()
	for value: int in values:
		formatted.append("0x%02X" % (value & 0xff))
	return "[" + ", ".join(formatted) + "]"


func _typed_int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in values:
		result.append(int(value))
	return result


func _localized_topology_error(error: String) -> String:
	if "missing connection" in error:
		return _t(&"system.topology.missing_route")
	if "missing" in error:
		return _t(&"system.topology.missing_part")
	return _t(&"system.topology.invalid")


func _t(key: StringName, arguments: Array = []) -> String:
	return Localization.text(key, arguments)


func _make_port_texture(canvas_size: int, visible_diameter: int) -> Texture2D:
	var image := Image.create(canvas_size, canvas_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(canvas_size - 1), float(canvas_size - 1)) * 0.5
	var radius: float = float(clampi(visible_diameter, 4, canvas_size)) * 0.5
	for y: int in range(canvas_size):
		for x: int in range(canvas_size):
			var distance: float = Vector2(x, y).distance_to(center)
			if distance <= radius:
				image.set_pixel(
					x, y, Color(1.0, 1.0, 1.0, 1.0 if distance <= radius - 1.5 else 0.76)
				)
	return ImageTexture.create_from_image(image)


func _stylebox(color: Color, radius: int, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border_width)
	box.border_color = border_color
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box
