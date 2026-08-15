extends Control

const DSLParserType = preload("res://src/simulation/dsl_parser.gd")
const DSLProgramType = preload("res://src/simulation/dsl_program.gd")
const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationCoreType = preload("res://src/simulation/simulation_core.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")
const TraceOverlayType = preload("res://src/ui/trace_overlay.gd")

const PANEL_COLOR := Color("172033")
const PANEL_DARK := Color("101725")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const BAD := Color("ff6b7d")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")
const REQUIRED_CONNECTIONS: Array = [
	[&"ProgramController", 0, &"CPU", 0],
	[&"CPU", 0, &"Cache", 0],
	[&"Cache", 0, &"Bus", 0],
	[&"Bus", 0, &"RAM", 0],
	[&"CPU", 1, &"TestBench", 0],
	[&"CPU", 2, &"Profiler", 0],
]

var simulation_core := SimulationCoreType.new()
var current_trace: SimulationTraceType

var graph: GraphEdit
var trace_overlay: TraceOverlayType
var editor: CodeEdit
var debug_inputs: Array[SpinBox] = []
var cache_selector: OptionButton
var cache_cost_label: Label
var status_label: Label
var playback_label: Label
var pause_button: Button
var step_button: Button
var speed_selector: OptionButton
var trace_progress: ProgressBar
var official_run_button: Button
var debug_run_button: Button
var result_label: Label
var insight_label: Label
var comparison_label: Label
var profiler_values: Dictionary[String, Label] = {}
var device_detail_labels: Dictionary[StringName, Label] = {}
var comparison_baselines: Dictionary = {}

var playback_index: int = 0
var playback_elapsed: float = 0.0
var playback_speed: float = 2.0
var playback_running: bool = false


func _ready() -> void:
	_build_theme()
	_build_interface()
	_auto_wire()
	_update_cache_display(0)
	set_process(true)
	var user_arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--capture-return" in user_arguments:
		call_deferred("_prepare_line_return_capture")
	elif "--capture-compare" in user_arguments:
		call_deferred("_prepare_comparison_capture")
	elif "--capture-row" in user_arguments:
		_load_program_template(ProgramTemplatesType.ROW_FIRST)
		call_deferred("_run_simulation", "Official Test Set")
	elif "--capture-demo" in user_arguments:
		call_deferred("_run_simulation", "Official Test Set")


func _prepare_comparison_capture() -> void:
	_run_simulation("Official Test Set")
	_load_program_template(ProgramTemplatesType.ROW_FIRST)
	_run_simulation("Official Test Set")


func _prepare_line_return_capture() -> void:
	_run_simulation("Official Test Set")
	playback_running = false
	for index: int in range(current_trace.events.size()):
		var event: SimulationEventType = current_trace.events[index]
		if event.kind == &"line_return":
			playback_index = index
			playback_elapsed = 0.0
			pause_button.text = "Resume"
			_show_event_text(event)
			_draw_event(event, 0.5)
			_update_trace_progress(0.5)
			return


func _process(delta: float) -> void:
	if not playback_running or current_trace == null:
		return
	if playback_index >= current_trace.events.size():
		_finish_playback()
		return
	var event: SimulationEventType = current_trace.events[playback_index]
	var display_duration: float = _display_duration_for(event)
	playback_elapsed += delta * playback_speed
	var progress: float = minf(playback_elapsed / display_duration, 1.0)
	_draw_event(event, progress)
	_update_trace_progress(progress)
	if progress >= 1.0:
		playback_index += 1
		playback_elapsed = 0.0
		if playback_index < current_trace.events.size():
			_show_event_text(current_trace.events[playback_index])


func _build_theme() -> void:
	var prototype_theme := Theme.new()
	prototype_theme.default_font_size = 16
	prototype_theme.set_color("font_color", "Label", TEXT)
	prototype_theme.set_color("font_color", "Button", TEXT)
	prototype_theme.set_color("font_color", "OptionButton", TEXT)
	prototype_theme.set_color("font_color", "LineEdit", TEXT)
	prototype_theme.set_color("font_color", "CodeEdit", TEXT)
	prototype_theme.set_color("font_color", "SpinBox", TEXT)
	prototype_theme.set_color("font_color", "GraphNode", TEXT)
	prototype_theme.set_color("title_color", "GraphNode", TEXT)
	prototype_theme.set_constant("separation", "VBoxContainer", 7)
	prototype_theme.set_constant("separation", "HBoxContainer", 9)
	prototype_theme.set_stylebox("panel", "PanelContainer", _stylebox(PANEL_COLOR, 10, 1, Color("293650")))
	prototype_theme.set_stylebox("normal", "Button", _stylebox(Color("26334a"), 7, 1, Color("354866")))
	prototype_theme.set_stylebox("hover", "Button", _stylebox(Color("30435f"), 7, 1, ACCENT))
	prototype_theme.set_stylebox("pressed", "Button", _stylebox(Color("17283e"), 7, 1, ACCENT))
	theme = prototype_theme


func _stylebox(color: Color, radius: int, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.border_color = border_color
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box


func _build_interface() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	margin.add_child(root_vbox)
	root_vbox.add_child(_build_header())

	var main_split := HSplitContainer.new()
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.split_offset = 405
	root_vbox.add_child(main_split)
	main_split.add_child(_build_program_panel())

	var right_split := HSplitContainer.new()
	right_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_split.split_offset = 865
	main_split.add_child(right_split)
	right_split.add_child(_build_hardware_and_playback())
	right_split.add_child(_build_profiler_panel())


func _build_header() -> Control:
	var header := PanelContainer.new()
	header.custom_minimum_size.y = 70.0
	var row := HBoxContainer.new()
	header.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	var title := Label.new()
	title.text = "VON NEUMANN BOTTLENECK"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", ACCENT)
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "4×4 CACHE LOCALITY LAB  •  ordinary wires: 0 cycles"
	subtitle.add_theme_color_override("font_color", MUTED)
	title_box.add_child(subtitle)
	status_label = Label.new()
	status_label.text = "READY — default program is intentionally column-first"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size.x = 520.0
	status_label.add_theme_color_override("font_color", WARNING)
	row.add_child(status_label)
	return header


func _build_program_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 395.0
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(_section_title("PROGRAM CONTROLLER", "Edit the tiny DSL. Swap the loop headers to optimize locality."))

	editor = CodeEdit.new()
	editor.text = ProgramTemplatesType.COLUMN_FIRST
	editor.size_flags_vertical = Control.SIZE_FILL
	editor.custom_minimum_size.y = 210.0
	editor.add_theme_font_size_override("font_size", 15)
	editor.add_theme_stylebox_override("normal", _stylebox(Color("0b111d"), 7, 1, Color("2a3c58")))
	editor.text_changed.connect(_on_program_changed)
	content.add_child(editor)

	var templates := HBoxContainer.new()
	content.add_child(templates)
	var column_button := Button.new()
	column_button.text = "Load column-first"
	column_button.pressed.connect(func() -> void: _load_program_template(ProgramTemplatesType.COLUMN_FIRST))
	templates.add_child(column_button)
	var row_button := Button.new()
	row_button.text = "Load row-first"
	row_button.pressed.connect(func() -> void: _load_program_template(ProgramTemplatesType.ROW_FIRST))
	templates.add_child(row_button)

	var separator := HSeparator.new()
	content.add_child(separator)
	content.add_child(_section_title("TEST BENCH", "Debug Data is editable. Official Test Set is fixed and scored separately."))
	var grid := GridContainer.new()
	grid.columns = 4
	content.add_child(grid)
	for index: int in range(16):
		var spin := SpinBox.new()
		spin.min_value = -99
		spin.max_value = 99
		spin.step = 1
		spin.value = index + 1
		spin.custom_minimum_size.x = 82.0
		spin.tooltip_text = "Debug A[%d][%d]" % [index / 4, index % 4]
		spin.value_changed.connect(_on_debug_data_changed)
		debug_inputs.append(spin)
		grid.add_child(spin)

	var official := Label.new()
	official.text = "Official A: [7, -2, 5, 11, 3, 0, 8, 4, 9, 1, 6, 2, 10, -1, 12, 13]"
	official.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	official.add_theme_color_override("font_color", MUTED)
	content.add_child(official)

	var run_row := HBoxContainer.new()
	content.add_child(run_row)
	debug_run_button = Button.new()
	debug_run_button.text = "▶ Run Debug"
	debug_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_run_button.pressed.connect(func() -> void: _run_simulation("Debug Data"))
	run_row.add_child(debug_run_button)
	official_run_button = Button.new()
	official_run_button.text = "◆ Run Official"
	official_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	official_run_button.pressed.connect(func() -> void: _run_simulation("Official Test Set"))
	run_row.add_child(official_run_button)
	return panel


func _build_hardware_and_playback() -> Control:
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hardware_bar := PanelContainer.new()
	var row := HBoxContainer.new()
	hardware_bar.add_child(row)
	var label := Label.new()
	label.text = "PLAYER HARDWARE"
	label.add_theme_color_override("font_color", ACCENT)
	row.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var capacity_label := Label.new()
	capacity_label.text = "Cache capacity"
	row.add_child(capacity_label)
	cache_selector = OptionButton.new()
	cache_selector.add_item("1 line / 4 ints", 1)
	cache_selector.add_item("2 lines / 8 ints", 2)
	cache_selector.add_item("4 lines / 16 ints", 4)
	cache_selector.item_selected.connect(_update_cache_display)
	row.add_child(cache_selector)
	cache_cost_label = Label.new()
	cache_cost_label.custom_minimum_size.x = 110.0
	row.add_child(cache_cost_label)
	var wire_button := Button.new()
	wire_button.text = "Auto Wire"
	wire_button.tooltip_text = "Restore the required zero-latency connectivity."
	wire_button.pressed.connect(_auto_wire)
	row.add_child(wire_button)
	content.add_child(hardware_bar)

	var graph_stack := Control.new()
	graph_stack.custom_minimum_size.y = 500.0
	graph_stack.size_flags_vertical = Control.SIZE_FILL
	content.add_child(graph_stack)
	graph = GraphEdit.new()
	graph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph.show_grid = true
	graph.snapping_enabled = true
	graph.minimap_enabled = true
	graph.right_disconnects = true
	graph.connection_request.connect(_on_connection_request)
	graph.disconnection_request.connect(_on_disconnection_request)
	graph_stack.add_child(graph)
	_build_graph_nodes()
	_position_graph_view_after_layout()
	trace_overlay = TraceOverlayType.new()
	trace_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trace_overlay.z_index = 100
	graph_stack.add_child(trace_overlay)

	content.add_child(_build_playback_panel())
	return content


func _build_graph_nodes() -> void:
	_add_device_node(&"ProgramController", "PROGRAM CONTROLLER", "DSL → instructions", Vector2(10, 75), false, [[false, true]])
	_add_device_node(&"CPU", "CPU", "load / add / store", Vector2(210, 75), true, [[true, true], [false, true], [false, true]])
	_add_device_node(&"Cache", "CACHE", "auto · 4 ints/line", Vector2(365, 75), true, [[true, true]])
	_add_device_node(&"Bus", "BUS", "transfer cost", Vector2(535, 75), true, [[true, true]])
	_add_device_node(&"RAM", "RAM", "row-major A[4][4]", Vector2(690, 75), true, [[true, false]])
	_add_device_node(&"TestBench", "TEST BENCH", "checks result", Vector2(365, 300), false, [[true, false]])
	_add_device_node(&"Profiler", "PROFILER", "trace metrics", Vector2(535, 300), false, [[true, false]])


func _position_graph_view_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	# GraphEdit calculates its scroll range after children have been laid out.
	graph.scroll_offset = Vector2.ZERO


func _add_device_node(
		id: StringName,
		title_text: String,
		detail: String,
		position: Vector2,
		movable: bool,
		slots: Array
	) -> void:
	var node := GraphNode.new()
	node.name = id
	node.title = title_text
	node.position_offset = position
	node.draggable = movable
	node.resizable = false
	var device_width: float = 145.0
	if id == &"ProgramController":
		device_width = 190.0
	elif id == &"Cache" or id == &"TestBench":
		device_width = 160.0
	node.custom_minimum_size = Vector2(device_width, 105)
	graph.add_child(node)
	for slot_index: int in range(slots.size()):
		var row := VBoxContainer.new()
		var port_label := Label.new()
		if id == &"CPU":
			port_label.text = ["memory", "result", "telemetry"][slot_index]
		elif slot_index == 0:
			port_label.text = detail
		port_label.clip_text = true
		port_label.tooltip_text = port_label.text
		row.add_child(port_label)
		if slot_index == 0:
			device_detail_labels[id] = port_label
		node.add_child(row)
		var slot: Array = slots[slot_index]
		node.set_slot(slot_index, bool(slot[0]), 0, ACCENT, bool(slot[1]), 0, ACCENT)


func _build_playback_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 125.0
	var content := VBoxContainer.new()
	panel.add_child(content)
	var controls := HBoxContainer.new()
	content.add_child(controls)
	var heading := Label.new()
	heading.text = "TRACE PLAYBACK"
	heading.add_theme_color_override("font_color", ACCENT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(heading)
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.disabled = true
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	step_button = Button.new()
	step_button.text = "Step"
	step_button.disabled = true
	step_button.pressed.connect(_step_trace)
	controls.add_child(step_button)
	speed_selector = OptionButton.new()
	for speed: float in [0.5, 1.0, 2.0, 4.0]:
		var speed_text: String = str(speed).trim_suffix(".0") + "x"
		speed_selector.add_item(speed_text)
		speed_selector.set_item_metadata(speed_selector.item_count - 1, speed)
	speed_selector.select(2)
	speed_selector.item_selected.connect(_on_speed_selected)
	controls.add_child(speed_selector)
	playback_label = Label.new()
	playback_label.text = "Run a test to generate a complete deterministic SimulationTrace."
	playback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	playback_label.add_theme_color_override("font_color", MUTED)
	content.add_child(playback_label)
	trace_progress = ProgressBar.new()
	trace_progress.min_value = 0.0
	trace_progress.max_value = 100.0
	trace_progress.value = 0.0
	trace_progress.show_percentage = false
	trace_progress.custom_minimum_size.y = 8.0
	trace_progress.add_theme_stylebox_override("background", _stylebox(Color("0b111d"), 4))
	trace_progress.add_theme_stylebox_override("fill", _stylebox(ACCENT, 4))
	content.add_child(trace_progress)
	return panel


func _build_profiler_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 290.0
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(_section_title("PROFILER", "Derived from the completed trace, never from animation timing."))
	for entry: Array in [
		["total_cycles", "TOTAL CYCLES"],
		["compute_cycles", "COMPUTE CYCLES"],
		["wait_cycles", "WAIT CYCLES"],
		["cache_hits", "CACHE HITS"],
		["cache_misses", "CACHE MISSES"],
		["ram_bytes_transferred", "RAM BYTES"],
		["hardware_cost", "HARDWARE COST"],
	]:
		var row := HBoxContainer.new()
		var metric_name := Label.new()
		metric_name.text = String(entry[1])
		metric_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		metric_name.add_theme_color_override("font_color", MUTED)
		row.add_child(metric_name)
		var value := Label.new()
		value.text = "—"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_font_size_override("font_size", 22)
		value.add_theme_color_override("font_color", TEXT)
		profiler_values[String(entry[0])] = value
		row.add_child(value)
		content.add_child(row)
		content.add_child(HSeparator.new())

	var result_heading := Label.new()
	result_heading.text = "TEST RESULT"
	result_heading.add_theme_color_override("font_color", MUTED)
	content.add_child(result_heading)
	result_label = Label.new()
	result_label.text = "NOT RUN"
	result_label.name = "ResultValue"
	result_label.add_theme_font_size_override("font_size", 28)
	content.add_child(result_label)

	insight_label = Label.new()
	insight_label.name = "Insight"
	insight_label.text = "Try the default one-line Cache first. Then swap only the two loop headers and compare."
	insight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insight_label.add_theme_color_override("font_color", WARNING)
	content.add_child(insight_label)
	comparison_label = Label.new()
	comparison_label.name = "Comparison"
	comparison_label.text = "COMPARISON — run column-first to set a baseline"
	comparison_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_label.add_theme_color_override("font_color", MUTED)
	content.add_child(comparison_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var assumptions := Label.new()
	assumptions.text = "MODEL\n• fully-associative LRU\n• 4 ints / cache line\n• one outstanding load\n• wires = 0 cycles\n• component costs only"
	assumptions.add_theme_color_override("font_color", MUTED)
	content.add_child(assumptions)
	return panel


func _section_title(title_text: String, subtitle_text: String) -> Control:
	var box := VBoxContainer.new()
	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", MUTED)
	box.add_child(subtitle)
	return box


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_node == to_node:
		return
	if not graph.is_node_connected(from_node, from_port, to_node, to_port):
		graph.connect_node(from_node, from_port, to_node, to_port)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)
	_invalidate_current_run("WIRING CHANGED — reconnect and rerun")


func _auto_wire() -> void:
	if graph == null:
		return
	graph.clear_connections()
	for connection: Array in REQUIRED_CONNECTIONS:
		graph.connect_node(connection[0], connection[1], connection[2], connection[3])
	if status_label != null:
		_set_status("WIRING RESTORED — six zero-latency links connected", GOOD)


func _validate_wiring() -> Array[String]:
	var found: Dictionary[String, bool] = {}
	for connection: Dictionary in graph.get_connection_list():
		var key: String = _connection_key(
			connection["from_node"], int(connection["from_port"]),
			connection["to_node"], int(connection["to_port"])
		)
		found[key] = true
	var missing: Array[String] = []
	for required: Array in REQUIRED_CONNECTIONS:
		var required_key: String = _connection_key(required[0], required[1], required[2], required[3])
		if not found.has(required_key):
			missing.append(required_key)
	return missing


func _connection_key(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> String:
	return "%s:%d>%s:%d" % [String(from_node), from_port, String(to_node), to_port]


func _run_simulation(test_name: String) -> void:
	var missing_wires: Array[String] = _validate_wiring()
	if not missing_wires.is_empty():
		_set_status("RUN BLOCKED — missing wires: %s" % ", ".join(missing_wires), BAD)
		return
	var program: DSLProgramType = DSLParserType.parse(editor.text)
	if not program.is_valid():
		_set_status("PROGRAM ERROR — %s" % " | ".join(program.errors), BAD)
		playback_label.text = "Parser rejected the program. Only the slice DSL is supported."
		return
	var data: Array[int]
	if test_name == "Official Test Set":
		data = SimulationCoreType.official_data_copy()
	else:
		data = []
		for input: SpinBox in debug_inputs:
			data.append(int(input.value))
	var cache_lines: int = cache_selector.get_selected_id()
	current_trace = simulation_core.run(program, data, cache_lines, test_name)
	var traversal_pattern: String = program.traversal_pattern()
	_update_profiler(current_trace, traversal_pattern)
	playback_index = 0
	playback_elapsed = 0.0
	playback_running = not current_trace.events.is_empty()
	pause_button.text = "Pause"
	pause_button.disabled = not playback_running
	step_button.disabled = current_trace.events.is_empty()
	trace_progress.value = 0.0
	if playback_running:
		_show_event_text(current_trace.events[0])
	_set_status(
		"%s — %s — %s — trace %d events" % [
			"PASS" if current_trace.passed else "FAIL",
			test_name,
			traversal_pattern.to_upper(),
			current_trace.events.size(),
		],
		GOOD if current_trace.passed else BAD
	)


func _update_profiler(trace: SimulationTraceType, traversal_pattern: String) -> void:
	for key: String in profiler_values:
		profiler_values[key].text = str(trace.metrics.get(key, 0))
	result_label.text = "%s  %d / %d" % ["PASS" if trace.passed else "FAIL", trace.result_value, trace.expected_value]
	result_label.add_theme_color_override("font_color", GOOD if trace.passed else BAD)
	var misses: int = int(trace.metrics["cache_misses"])
	var hits: int = int(trace.metrics["cache_hits"])
	var interpretation: String = "Spatial locality is working." if hits > misses else "The access stride keeps evicting useful lines."
	if traversal_pattern == "column-first" and trace.cache_capacity_lines == 4:
		interpretation = "Capacity holds the full array, masking the poor stride."
	insight_label.text = "%d hits · %d misses. %s" % [
		hits,
		misses,
		interpretation,
	]
	_update_comparison(trace, traversal_pattern)


func _update_comparison(trace: SimulationTraceType, traversal_pattern: String) -> void:
	var baseline_key: String = "%s|%d" % [trace.test_name, trace.cache_capacity_lines]
	if traversal_pattern == "column-first":
		comparison_baselines[baseline_key] = trace.metrics.duplicate(true)
		comparison_label.text = "BASELINE SAVED — column-first · %d cycles · %d misses" % [
			int(trace.metrics["total_cycles"]), int(trace.metrics["cache_misses"])
		]
		comparison_label.add_theme_color_override("font_color", MUTED)
		return
	if traversal_pattern != "row-first" or not comparison_baselines.has(baseline_key):
		comparison_label.text = "COMPARISON — run column-first with this test and Cache first"
		comparison_label.add_theme_color_override("font_color", MUTED)
		return
	var baseline: Dictionary = comparison_baselines[baseline_key]
	var baseline_cycles: int = int(baseline["total_cycles"])
	var current_cycles: int = int(trace.metrics["total_cycles"])
	var saved_cycles: int = baseline_cycles - current_cycles
	var percent: int = int(round(float(saved_cycles) * 100.0 / float(baseline_cycles))) if baseline_cycles > 0 else 0
	comparison_label.text = "VS COLUMN — %d → %d cycles (%d%% faster) · misses %d → %d · RAM %d → %d B" % [
		baseline_cycles,
		current_cycles,
		percent,
		int(baseline["cache_misses"]),
		int(trace.metrics["cache_misses"]),
		int(baseline["ram_bytes_transferred"]),
		int(trace.metrics["ram_bytes_transferred"]),
	]
	comparison_label.add_theme_color_override("font_color", GOOD if saved_cycles > 0 else WARNING)


func _toggle_pause() -> void:
	if current_trace == null or current_trace.events.is_empty():
		return
	if playback_index >= current_trace.events.size():
		playback_index = 0
		playback_elapsed = 0.0
		trace_progress.value = 0.0
		_show_event_text(current_trace.events[0])
	playback_running = not playback_running
	pause_button.text = "Pause" if playback_running else "Resume"


func _step_trace() -> void:
	if current_trace == null or current_trace.events.is_empty():
		return
	playback_running = false
	pause_button.text = "Resume"
	if playback_index >= current_trace.events.size():
		playback_index = 0
	var event: SimulationEventType = current_trace.events[playback_index]
	_show_event_text(event)
	_draw_event(event, 1.0)
	playback_index += 1
	playback_elapsed = 0.0
	_update_trace_progress(0.0)


func _on_speed_selected(index: int) -> void:
	playback_speed = float(speed_selector.get_item_metadata(index))


func _display_duration_for(event: SimulationEventType) -> float:
	match event.kind:
		&"compute":
			return 0.13
		&"request", &"cache_lookup":
			return 0.17
		&"cache_hit", &"cache_miss", &"cache_fill", &"cache_evict":
			return 0.22
		&"bus_request":
			return 0.28
		&"ram_access":
			return 0.38
		&"line_return":
			return 0.48
		&"store_result":
			return 0.35
		_:
			return maxf(0.18, float(event.duration) * 0.03)


func _draw_event(event: SimulationEventType, progress: float) -> void:
	var color: Color = _event_color(event.kind)
	trace_overlay.show_packet_path(_event_path(event), progress, color, _event_short_label(event.kind))


func _event_path(event: SimulationEventType) -> PackedVector2Array:
	if event.kind == &"line_return":
		return PackedVector2Array([
			_node_port_point(&"RAM", false, 0),
			_device_center(&"Bus"),
			_node_port_point(&"Cache", true, 0),
		])
	var route_key: String = "%s>%s" % [String(event.source_device), String(event.target_device)]
	match route_key:
		"CPU>Cache":
			return PackedVector2Array([_node_port_point(&"CPU", true, 0), _node_port_point(&"Cache", false, 0)])
		"Cache>CPU":
			return PackedVector2Array([_node_port_point(&"Cache", false, 0), _node_port_point(&"CPU", true, 0)])
		"Cache>Bus":
			return PackedVector2Array([_node_port_point(&"Cache", true, 0), _node_port_point(&"Bus", false, 0)])
		"Bus>RAM":
			return PackedVector2Array([_node_port_point(&"Bus", true, 0), _node_port_point(&"RAM", false, 0)])
		"CPU>TestBench":
			return PackedVector2Array([_node_port_point(&"CPU", true, 1), _node_port_point(&"TestBench", false, 0)])
		"CPU>Profiler":
			return PackedVector2Array([_node_port_point(&"CPU", true, 2), _node_port_point(&"Profiler", false, 0)])
		_:
			return PackedVector2Array([_device_center(event.source_device), _device_center(event.target_device)])


func _node_port_point(device: StringName, output: bool, port: int) -> Vector2:
	var device_node: GraphNode = graph.get_node_or_null(NodePath(String(device))) as GraphNode
	if device_node == null:
		return graph.size * 0.5
	var local_position: Vector2
	if output and port < device_node.get_output_port_count():
		local_position = device_node.get_output_port_position(port)
	elif not output and port < device_node.get_input_port_count():
		local_position = device_node.get_input_port_position(port)
	else:
		return device_node.position + device_node.size * 0.5
	return device_node.position + local_position


func _device_center(device: StringName) -> Vector2:
	var device_node: GraphNode = graph.get_node_or_null(NodePath(String(device))) as GraphNode
	if device_node == null:
		return graph.size * 0.5
	return device_node.position + device_node.size * 0.5


func _show_event_text(event: SimulationEventType) -> void:
	playback_label.text = "[%03d/%03d] cycle %d +%d  •  %s" % [
		playback_index + 1,
		current_trace.events.size(),
		event.cycle,
		event.duration,
		event.message,
	]
	playback_label.add_theme_color_override("font_color", _event_color(event.kind))


func _finish_playback() -> void:
	playback_running = false
	pause_button.text = "Replay"
	trace_overlay.clear_packet()
	trace_progress.value = 100.0
	playback_label.text = "Trace complete — animation consumed the precomputed trace without changing the result."
	playback_label.add_theme_color_override("font_color", GOOD)


func _event_color(kind: StringName) -> Color:
	match kind:
		&"cache_hit", &"cache_fill":
			return GOOD
		&"cache_miss", &"cache_evict":
			return BAD
		&"ram_access", &"line_return", &"bus_request":
			return WARNING
		&"compute", &"store_result":
			return Color("bc8cff")
		_:
			return ACCENT


func _event_short_label(kind: StringName) -> String:
	match kind:
		&"request": return "ADDR"
		&"cache_lookup": return "LOOKUP"
		&"cache_hit": return "HIT"
		&"cache_miss": return "MISS"
		&"bus_request": return "REQ"
		&"ram_access": return "RAM"
		&"line_return": return "4 INTS"
		&"cache_fill": return "FILL"
		&"cache_evict": return "EVICT"
		&"compute": return "ADD"
		&"store_result": return "RESULT"
		_: return String(kind).to_upper()


func _update_cache_display(index: int) -> void:
	if cache_selector == null:
		return
	var lines: int = cache_selector.get_item_id(index)
	var cost: int = SimulationCoreType.CACHE_COSTS[lines]
	cache_cost_label.text = "cost %d" % cost
	cache_cost_label.add_theme_color_override("font_color", WARNING)
	if device_detail_labels.has(&"Cache"):
		device_detail_labels[&"Cache"].text = "%d line%s · 4 ints/line" % [lines, "s" if lines > 1 else ""]
	if current_trace != null and current_trace.cache_capacity_lines != lines:
		_invalidate_current_run("CACHE CHANGED — rerun to profile the new hardware")


func _on_program_changed() -> void:
	_invalidate_current_run("PROGRAM CHANGED — rerun to generate a matching trace")


func _load_program_template(source: String) -> void:
	editor.text = source
	_invalidate_current_run("PROGRAM CHANGED — rerun to generate a matching trace")


func _on_debug_data_changed(_value: float) -> void:
	if current_trace != null and current_trace.test_name == "Debug Data":
		_invalidate_current_run("DEBUG DATA CHANGED — rerun the Test Bench")


func _invalidate_current_run(reason: String) -> void:
	if current_trace == null:
		return
	current_trace = null
	playback_running = false
	playback_index = 0
	playback_elapsed = 0.0
	pause_button.text = "Pause"
	pause_button.disabled = true
	step_button.disabled = true
	trace_overlay.clear_packet()
	trace_progress.value = 0.0
	playback_label.text = "Inputs changed. Run again to create a new deterministic SimulationTrace."
	playback_label.add_theme_color_override("font_color", WARNING)
	for key: String in profiler_values:
		profiler_values[key].text = "—"
	result_label.text = "NOT RUN"
	result_label.add_theme_color_override("font_color", TEXT)
	insight_label.text = "The previous result was cleared so Profiler data cannot disagree with current inputs."
	comparison_label.text = "COMPARISON — saved baselines remain available for the same test and Cache"
	comparison_label.add_theme_color_override("font_color", MUTED)
	_set_status(reason, WARNING)


func _update_trace_progress(event_progress: float) -> void:
	if current_trace == null or current_trace.events.is_empty():
		trace_progress.value = 0.0
		return
	var completed: float = float(playback_index) + clampf(event_progress, 0.0, 1.0)
	trace_progress.value = clampf(completed * 100.0 / float(current_trace.events.size()), 0.0, 100.0)


func _set_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)
