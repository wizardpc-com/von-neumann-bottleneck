extends Control

const DSLParserType = preload("res://src/simulation/dsl_parser.gd")
const DSLProgramType = preload("res://src/simulation/dsl_program.gd")
const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationCoreType = preload("res://src/simulation/simulation_core.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")
const TraceOverlayType = preload("res://src/ui/trace_overlay.gd")
const FloatingInstrumentPanelType = preload("res://src/ui/floating_instrument_panel.gd")
const GameModeSelectorType = preload("res://src/ui/game_mode_selector.gd")
const FullscreenButtonType = preload("res://src/ui/fullscreen_button.gd")

const PANEL_COLOR := Color("172033")
const PANEL_DARK := Color("101725")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const BAD := Color("ff6b7d")
const PURPLE := Color("bc8cff")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")
const OFFICIAL_CYCLE_TARGET: int = 105
const RUN_HISTORY_LIMIT: int = 8

const REQUIRED_CONNECTIONS: Array = [
	[&"ProgramController", 0, &"CPU", 0],
	[&"CPU", 0, &"Cache", 0],
	[&"Cache", 0, &"Bus", 0],
	[&"Bus", 0, &"RAM", 0],
	[&"CPU", 1, &"TestBench", 0],
	[&"CPU", 2, &"Profiler", 0],
]

const STANDARD_LAYOUT: Dictionary = {
	&"ProgramController": Vector2(30, 92),
	&"CPU": Vector2(270, 92),
	&"Cache": Vector2(515, 92),
	&"Bus": Vector2(755, 92),
	&"RAM": Vector2(985, 92),
	&"TestBench": Vector2(455, 330),
	&"Profiler": Vector2(730, 330),
}

const INSTRUMENT_LAYOUT: Dictionary = {
	&"program": Rect2(20, 18, 560, 470),
	&"test_bench": Rect2(380, 38, 650, 445),
	&"profiler": Rect2(710, 18, 700, 470),
	&"cache": Rect2(1080, 92, 410, 360),
}
const INSTRUMENT_REFERENCE_SIZE := Vector2(1500.0, 510.0)

var simulation_core := SimulationCoreType.new()
var current_trace: SimulationTraceType
var current_goal_met: bool = false
var current_cache_lines: int = 1
var run_history: Array[Dictionary] = []

var graph: GraphEdit
var trace_overlay: TraceOverlayType
var editor: CodeEdit
var debug_inputs: Array[SpinBox] = []
var status_label: Label
var program_validation_label: Label
var program_effect_label: Label
var program_apply_label: Label
var program_explanation_label: RichTextLabel
var program_run_label: Label
var apply_program_button: Button
var column_strategy_button: Button
var row_strategy_button: Button
var playback_label: Label
var pause_button: Button
var step_button: Button
var speed_selector: OptionButton
var mode_selector: GameModeSelectorType
var fullscreen_button: FullscreenButtonType
var trace_progress: ProgressBar
var official_run_button: Button
var debug_run_button: Button
var result_label: Label
var profiler_summary_label: Label
var profiler_detail_label: Label
var profiler_tree: Tree
var profiler_history_label: Label
var inspect_event_button: Button
var selected_profiler_event_index: int = -1

var instrument_windows: Dictionary[StringName, FloatingInstrumentPanel] = {}
var instrument_host: Control
var instrument_layout_size: Vector2 = INSTRUMENT_REFERENCE_SIZE
var focused_instrument: StringName = &""
var instrument_z_counter: int = 100
var program_dirty: bool = false
var applied_program_source: String = ProgramTemplatesType.COLUMN_FIRST
var last_executed_source: String = ""
var last_run_receipt_text: String = ""

var device_nodes: Dictionary[StringName, GraphNode] = {}
var device_detail_labels: Dictionary[StringName, Label] = {}
var device_state_labels: Dictionary[StringName, Label] = {}
var device_default_states: Dictionary[StringName, String] = {}
var cache_card_buttons: Dictionary[int, Button] = {}

var playback_index: int = 0
var playback_elapsed: float = 0.0
var playback_speed: float = 1.0
var playback_running: bool = false
var highlighted_source_line: int = -1
var active_component: StringName = &""


func _ready() -> void:
	_build_theme()
	_build_interface()
	_connect_fixed_topology()
	_auto_layout(false)
	_select_cache(1, false)
	_validate_program_editor()
	set_process(true)
	var user_arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--capture-demo" in user_arguments:
		call_deferred("_run_simulation", "Official Test Set")
	elif "--capture-profiler" in user_arguments:
		call_deferred("_prepare_profiler_capture")
	elif "--capture-workspace" in user_arguments:
		call_deferred("_prepare_workspace_capture")
	elif "--capture-program-draft" in user_arguments:
		call_deferred("_prepare_program_draft_capture")
	elif "--capture-row" in user_arguments:
		call_deferred("_prepare_row_capture")


func _prepare_profiler_capture() -> void:
	_run_simulation("Official Test Set")
	playback_running = false
	_open_instrument(&"profiler")


func _prepare_workspace_capture() -> void:
	_run_simulation("Official Test Set")
	playback_running = false
	_open_instrument(&"program")
	_open_instrument(&"profiler")


func _prepare_row_capture() -> void:
	_load_strategy(ProgramTemplatesType.ROW_FIRST, "row-first")
	_apply_program()
	_run_simulation("Official Test Set")


func _prepare_program_draft_capture() -> void:
	_open_instrument(&"program")
	_load_strategy(ProgramTemplatesType.ROW_FIRST, "row-first")


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
	for control_type: String in ["Label", "Button", "OptionButton", "LineEdit", "CodeEdit", "SpinBox", "Tree", "GraphNode"]:
		prototype_theme.set_color("font_color", control_type, TEXT)
	prototype_theme.set_color("title_color", "GraphNode", TEXT)
	prototype_theme.set_constant("separation", "VBoxContainer", 8)
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
	root_vbox.add_child(_build_workbench())
	root_vbox.add_child(_build_playback_panel())


func _build_header() -> Control:
	var header := PanelContainer.new()
	header.custom_minimum_size.y = 70.0
	var row := HBoxContainer.new()
	header.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	var title := Label.new()
	title.text = _t(&"game.title")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", ACCENT)
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = _t(&"locality.subtitle")
	subtitle.add_theme_color_override("font_color", MUTED)
	title_box.add_child(subtitle)
	status_label = Label.new()
	status_label.text = _t(&"locality.status.ready")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size.x = 570.0
	status_label.add_theme_color_override("font_color", WARNING)
	row.add_child(status_label)
	mode_selector = GameModeSelectorType.new()
	mode_selector.name = "GameModeSelector"
	mode_selector.show_label = false
	row.add_child(mode_selector)
	fullscreen_button = FullscreenButtonType.new()
	row.add_child(fullscreen_button)
	var hub_button := Button.new()
	hub_button.text = _t(&"common.prototype_hub")
	hub_button.tooltip_text = _t(&"locality.hub.tooltip")
	hub_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn"))
	row.add_child(hub_button)
	return header


func _build_workbench() -> Control:
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hardware_bar := PanelContainer.new()
	var bar_row := HBoxContainer.new()
	hardware_bar.add_child(bar_row)
	var heading := Label.new()
	heading.text = _t(&"locality.workbench.title")
	heading.add_theme_color_override("font_color", ACCENT)
	bar_row.add_child(heading)
	var goal := Label.new()
	goal.text = _t(&"locality.workbench.goal", [OFFICIAL_CYCLE_TARGET])
	goal.add_theme_color_override("font_color", MUTED)
	goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(goal)
	var layout_button := Button.new()
	layout_button.text = _t(&"common.auto_layout")
	layout_button.tooltip_text = _t(&"locality.auto_layout.tooltip")
	layout_button.pressed.connect(func() -> void: _auto_layout(true))
	bar_row.add_child(layout_button)
	content.add_child(hardware_bar)

	var stack := Control.new()
	stack.custom_minimum_size.y = 510.0
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(stack)
	instrument_host = stack
	graph = GraphEdit.new()
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
	graph.connection_lines_thickness = 5.0
	graph.connection_lines_curvature = 0.55
	stack.add_child(graph)
	_build_graph_nodes()

	trace_overlay = TraceOverlayType.new()
	trace_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trace_overlay.z_index = 50
	stack.add_child(trace_overlay)
	_build_instruments(stack)
	stack.resized.connect(_on_instrument_host_resized)
	call_deferred("_on_instrument_host_resized")
	return content


func _build_graph_nodes() -> void:
	_add_device_node(&"ProgramController", _t(&"device.program"), _t(&"device.program.detail"), _t(&"state.ready"), false, [[false, true]], &"program")
	_add_device_node(&"CPU", "CPU", _t(&"device.cpu.detail"), _t(&"state.idle"), true, [[true, true], [false, true], [false, true]])
	_add_device_node(&"Cache", _t(&"device.cache"), _t(&"device.cache.default_detail"), _t(&"state.ready"), true, [[true, true]], &"cache")
	_add_device_node(&"Bus", _t(&"device.bus"), _t(&"device.bus.detail"), _t(&"state.idle"), true, [[true, true]])
	_add_device_node(&"RAM", _t(&"device.ram"), _t(&"device.ram.detail"), _t(&"state.idle"), true, [[true, false]])
	_add_device_node(&"TestBench", _t(&"device.test_bench"), _t(&"device.test_bench.detail", [OFFICIAL_CYCLE_TARGET]), _t(&"state.not_run"), false, [[true, false]], &"test_bench")
	_add_device_node(&"Profiler", _t(&"device.profiler"), _t(&"device.profiler.detail"), _t(&"state.no_trace"), false, [[true, false]], &"profiler")


func _add_device_node(
		id: StringName,
		title_text: String,
		detail: String,
		default_state: String,
		movable: bool,
		slots: Array,
		open_instrument: StringName = &""
	) -> void:
	var node := GraphNode.new()
	node.name = id
	node.title = title_text
	node.draggable = movable or not open_instrument.is_empty()
	node.resizable = false
	node.custom_minimum_size = Vector2(190.0 if id != &"ProgramController" else 205.0, 118.0)
	graph.add_child(node)
	for slot_index: int in range(slots.size()):
		var row := VBoxContainer.new()
		var port_label := Label.new()
		if id == &"CPU":
			port_label.text = [_t(&"port.memory"), _t(&"port.result"), _t(&"port.telemetry")][slot_index]
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
	var state_label := Label.new()
	state_label.text = default_state
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_color_override("font_color", MUTED)
	state_label.add_theme_font_size_override("font_size", 14)
	node.add_child(state_label)
	device_state_labels[id] = state_label
	device_default_states[id] = default_state
	if not open_instrument.is_empty():
		var open_button := Button.new()
		open_button.text = _t(&"common.open_named", [title_text])
		open_button.focus_mode = Control.FOCUS_ALL
		open_button.pressed.connect(_open_instrument.bind(open_instrument))
		node.add_child(open_button)
	device_nodes[id] = node
	_set_device_style(id, MUTED, false)


func _build_instruments(parent: Control) -> void:
	_add_instrument(parent, &"program", _t(&"device.program"), _build_program_instrument())
	_add_instrument(parent, &"test_bench", _t(&"device.test_bench"), _build_test_bench_instrument())
	_add_instrument(parent, &"profiler", _t(&"device.profiler"), _build_profiler_instrument())
	_add_instrument(parent, &"cache", _t(&"device.cache"), _build_cache_instrument())


func _add_instrument(parent: Control, id: StringName, title_text: String, content: Control) -> void:
	var instrument: FloatingInstrumentPanel = FloatingInstrumentPanelType.new()
	instrument.name = "%sInstrument" % String(id).to_pascal_case()
	instrument.custom_minimum_size = Vector2(360.0, 250.0)
	instrument.add_theme_stylebox_override("panel", _stylebox(Color("111a2a"), 12, 2, ACCENT))
	parent.add_child(instrument)
	instrument.setup(id, title_text)
	instrument.set_content(content)
	var default_rect: Rect2 = INSTRUMENT_LAYOUT[id]
	instrument.position = default_rect.position
	instrument.size = default_rect.size
	instrument.visible = false
	instrument.close_requested.connect(_close_instrument)
	instrument.focus_requested.connect(_focus_instrument)
	instrument_windows[id] = instrument


func _on_instrument_host_resized() -> void:
	if instrument_host == null or instrument_windows.is_empty():
		return
	var new_size: Vector2 = instrument_host.size
	if new_size.x <= 0.0 or new_size.y <= 0.0:
		return
	var previous := Vector2(
		maxf(1.0, instrument_layout_size.x),
		maxf(1.0, instrument_layout_size.y)
	)
	var scale := Vector2(new_size.x / previous.x, new_size.y / previous.y)
	for instrument: FloatingInstrumentPanel in instrument_windows.values():
		instrument.position = Vector2(
			instrument.position.x * scale.x,
			instrument.position.y * scale.y
		)
		if not instrument.minimized:
			instrument.size = Vector2(
				instrument.size.x * scale.x,
				instrument.size.y * scale.y
			)
		instrument.fit_to_parent(10.0)
	instrument_layout_size = new_size


func _build_program_instrument() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	var subtitle := Label.new()
	subtitle.text = _t(&"program.draft.description")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", MUTED)
	panel.add_child(subtitle)
	var reference_heading := Label.new()
	reference_heading.text = _t(&"program.reference.title")
	reference_heading.add_theme_color_override("font_color", ACCENT)
	panel.add_child(reference_heading)
	var reference := Label.new()
	reference.text = _t(&"program.reference.body")
	reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reference.add_theme_color_override("font_color", MUTED)
	panel.add_child(reference)
	var strategy_heading := Label.new()
	strategy_heading.text = _t(&"program.strategy_library.title")
	strategy_heading.add_theme_color_override("font_color", WARNING)
	panel.add_child(strategy_heading)
	var strategy_row := HBoxContainer.new()
	panel.add_child(strategy_row)
	column_strategy_button = Button.new()
	column_strategy_button.text = _t(&"program.strategy.column.use")
	column_strategy_button.tooltip_text = _t(&"program.strategy.column.tooltip")
	column_strategy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column_strategy_button.pressed.connect(_load_strategy.bind(ProgramTemplatesType.COLUMN_FIRST, "column-first"))
	strategy_row.add_child(column_strategy_button)
	row_strategy_button = Button.new()
	row_strategy_button.text = _t(&"program.strategy.row.use")
	row_strategy_button.tooltip_text = _t(&"program.strategy.row.tooltip")
	row_strategy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_strategy_button.pressed.connect(_load_strategy.bind(ProgramTemplatesType.ROW_FIRST, "row-first"))
	strategy_row.add_child(row_strategy_button)
	program_apply_label = Label.new()
	program_apply_label.text = _t(&"program.applied_starter", [_strategy_text("column-first")])
	program_apply_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	program_apply_label.add_theme_color_override("font_color", GOOD)
	panel.add_child(program_apply_label)
	apply_program_button = Button.new()
	apply_program_button.text = _t(&"program.apply.button")
	apply_program_button.tooltip_text = _t(&"program.apply.tooltip")
	apply_program_button.disabled = true
	apply_program_button.pressed.connect(_apply_program)
	panel.add_child(apply_program_button)
	editor = CodeEdit.new()
	editor.text = ProgramTemplatesType.COLUMN_FIRST
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.custom_minimum_size.y = 210.0
	editor.gutters_draw_line_numbers = true
	editor.indent_size = 4
	editor.indent_use_spaces = true
	editor.indent_automatic = true
	editor.add_theme_font_size_override("font_size", 16)
	editor.add_theme_stylebox_override("normal", _stylebox(Color("0b111d"), 7, 1, Color("2a3c58")))
	var code_highlighter := CodeHighlighter.new()
	for keyword: String in ["for", "in", "range", "load", "store"]:
		code_highlighter.add_keyword_color(keyword, ACCENT)
	code_highlighter.number_color = WARNING
	code_highlighter.symbol_color = PURPLE
	editor.syntax_highlighter = code_highlighter
	editor.text_changed.connect(_on_program_changed)
	panel.add_child(editor)
	program_validation_label = Label.new()
	program_validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(program_validation_label)
	program_effect_label = Label.new()
	program_effect_label.text = _t(&"program.effect.waiting")
	program_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	program_effect_label.add_theme_color_override("font_color", ACCENT)
	panel.add_child(program_effect_label)
	var explanation_heading := Label.new()
	explanation_heading.text = _t(&"program.explanation.title")
	explanation_heading.add_theme_color_override("font_color", PURPLE)
	panel.add_child(explanation_heading)
	program_explanation_label = RichTextLabel.new()
	program_explanation_label.bbcode_enabled = false
	program_explanation_label.fit_content = true
	program_explanation_label.scroll_active = false
	program_explanation_label.custom_minimum_size.y = 150.0
	program_explanation_label.add_theme_font_size_override("normal_font_size", 15)
	panel.add_child(program_explanation_label)
	program_run_label = Label.new()
	program_run_label.text = _t(&"program.receipt.not_executed_starter")
	program_run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	program_run_label.add_theme_color_override("font_color", WARNING)
	panel.add_child(program_run_label)
	var reset_button := Button.new()
	reset_button.text = _t(&"program.reset.button")
	reset_button.tooltip_text = _t(&"program.reset.tooltip")
	reset_button.pressed.connect(_reset_starter_program)
	panel.add_child(reset_button)
	return scroll


func _build_test_bench_instrument() -> Control:
	var panel := VBoxContainer.new()
	var goal := Label.new()
	goal.text = _t(&"test_bench.official_goal", [OFFICIAL_CYCLE_TARGET])
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.add_theme_color_override("font_color", WARNING)
	panel.add_child(goal)
	var grid := GridContainer.new()
	grid.columns = 4
	panel.add_child(grid)
	for index: int in range(16):
		var spin := SpinBox.new()
		spin.min_value = -99
		spin.max_value = 99
		spin.step = 1
		spin.value = index + 1
		spin.custom_minimum_size.x = 92.0
		spin.tooltip_text = _t(&"test_bench.debug_input.tooltip", [index / 4, index % 4])
		spin.value_changed.connect(_on_debug_data_changed)
		debug_inputs.append(spin)
		grid.add_child(spin)
	var official := Label.new()
	official.text = _t(&"test_bench.official_data")
	official.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	official.add_theme_color_override("font_color", MUTED)
	panel.add_child(official)
	var run_row := HBoxContainer.new()
	panel.add_child(run_row)
	debug_run_button = Button.new()
	debug_run_button.text = _t(&"test_bench.run_debug")
	debug_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_run_button.pressed.connect(_run_simulation.bind("Debug Data"))
	run_row.add_child(debug_run_button)
	official_run_button = Button.new()
	official_run_button.text = _t(&"test_bench.run_official")
	official_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	official_run_button.pressed.connect(_run_simulation.bind("Official Test Set"))
	run_row.add_child(official_run_button)
	result_label = Label.new()
	result_label.text = _t(&"state.not_run")
	result_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(result_label)
	return panel


func _build_profiler_instrument() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	var subtitle := Label.new()
	subtitle.text = _t(&"profiler.description")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", MUTED)
	panel.add_child(subtitle)
	profiler_summary_label = Label.new()
	profiler_summary_label.text = _t(&"state.no_trace")
	profiler_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profiler_summary_label.add_theme_color_override("font_color", WARNING)
	panel.add_child(profiler_summary_label)
	profiler_tree = Tree.new()
	profiler_tree.columns = 2
	profiler_tree.column_titles_visible = true
	profiler_tree.set_column_title(0, _t(&"profiler.column.evidence"))
	profiler_tree.set_column_title(1, _t(&"profiler.column.value"))
	profiler_tree.set_column_expand(0, true)
	profiler_tree.set_column_custom_minimum_width(1, 100)
	profiler_tree.hide_root = true
	profiler_tree.custom_minimum_size.y = 245.0
	profiler_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profiler_tree.item_selected.connect(_on_profiler_item_selected)
	panel.add_child(profiler_tree)
	profiler_detail_label = Label.new()
	profiler_detail_label.text = _t(&"profiler.select_miss")
	profiler_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profiler_detail_label.add_theme_color_override("font_color", MUTED)
	panel.add_child(profiler_detail_label)
	inspect_event_button = Button.new()
	inspect_event_button.text = _t(&"profiler.inspect_trace")
	inspect_event_button.disabled = true
	inspect_event_button.pressed.connect(_inspect_profiler_event)
	panel.add_child(inspect_event_button)
	var history_heading := Label.new()
	history_heading.text = _t(&"profiler.history.title")
	history_heading.add_theme_color_override("font_color", ACCENT)
	panel.add_child(history_heading)
	profiler_history_label = Label.new()
	profiler_history_label.text = _t(&"profiler.history.empty")
	profiler_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profiler_history_label.add_theme_color_override("font_color", MUTED)
	panel.add_child(profiler_history_label)
	return scroll


func _build_cache_instrument() -> Control:
	var panel := VBoxContainer.new()
	var subtitle := Label.new()
	subtitle.text = _t(&"cache.description")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", MUTED)
	panel.add_child(subtitle)
	for lines: int in [1, 2, 4]:
		var card := Button.new()
		card.text = _t(&"cache.card", [lines, lines * 4, SimulationCoreType.CACHE_COSTS[lines]])
		card.custom_minimum_size.y = 92.0
		card.pressed.connect(_select_cache.bind(lines, true))
		cache_card_buttons[lines] = card
		panel.add_child(card)
	return panel


func _build_playback_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 135.0
	var content := VBoxContainer.new()
	panel.add_child(content)
	var controls := HBoxContainer.new()
	content.add_child(controls)
	var heading := Label.new()
	heading.text = _t(&"trace.playback.title")
	heading.add_theme_color_override("font_color", ACCENT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(heading)
	pause_button = Button.new()
	pause_button.text = _t(&"common.pause")
	pause_button.disabled = true
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	step_button = Button.new()
	step_button.text = _t(&"common.step")
	step_button.disabled = true
	step_button.pressed.connect(_step_trace)
	controls.add_child(step_button)
	speed_selector = OptionButton.new()
	for speed: float in [0.5, 1.0, 2.0, 4.0]:
		speed_selector.add_item(str(speed).trim_suffix(".0") + "x")
		speed_selector.set_item_metadata(speed_selector.item_count - 1, speed)
	speed_selector.select(1)
	speed_selector.item_selected.connect(_on_speed_selected)
	controls.add_child(speed_selector)
	playback_label = Label.new()
	playback_label.text = _t(&"trace.playback.empty")
	playback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	playback_label.add_theme_color_override("font_color", MUTED)
	content.add_child(playback_label)
	trace_progress = ProgressBar.new()
	trace_progress.min_value = 0.0
	trace_progress.max_value = 100.0
	trace_progress.value = 0.0
	trace_progress.show_percentage = false
	trace_progress.custom_minimum_size.y = 9.0
	trace_progress.add_theme_stylebox_override("background", _stylebox(Color("0b111d"), 4))
	trace_progress.add_theme_stylebox_override("fill", _stylebox(ACCENT, 4))
	content.add_child(trace_progress)
	return panel


func _open_instrument(id: StringName) -> void:
	if not instrument_windows.has(id):
		return
	instrument_windows[id].fit_to_parent(10.0)
	instrument_windows[id].show_instrument()


func _close_instrument(id: StringName) -> void:
	if not instrument_windows.has(id):
		return
	instrument_windows[id].visible = false
	if focused_instrument == id:
		focused_instrument = &""
		for other_id: StringName in instrument_windows:
			if instrument_windows[other_id].visible:
				focused_instrument = other_id
				break


func _focus_instrument(id: StringName) -> void:
	if not instrument_windows.has(id):
		return
	instrument_z_counter += 1
	instrument_windows[id].z_index = instrument_z_counter
	focused_instrument = id


func _connect_fixed_topology() -> void:
	graph.clear_connections()
	for connection: Array in REQUIRED_CONNECTIONS:
		graph.connect_node(connection[0], connection[1], connection[2], connection[3])


func _auto_layout(report_status: bool = true) -> void:
	for device: StringName in STANDARD_LAYOUT:
		var node: GraphNode = device_nodes.get(device)
		if node != null:
			node.position_offset = STANDARD_LAYOUT[device]
	graph.scroll_offset = Vector2.ZERO
	if report_status:
		_set_status(_t(&"locality.status.auto_layout"), GOOD)


func _reset_starter_program() -> void:
	_load_strategy(ProgramTemplatesType.COLUMN_FIRST, "column-first")


func _load_strategy(source: String, strategy_name: String) -> void:
	var localized_strategy: String = _strategy_text(strategy_name)
	if editor.text == source:
		_validate_program_editor()
		_set_status(_t(&"locality.status.strategy_already_loaded", [localized_strategy]), ACCENT)
		return
	editor.set_block_signals(true)
	editor.text = source
	editor.set_block_signals(false)
	_on_program_changed()
	_set_status(_t(&"locality.status.strategy_loaded_draft", [localized_strategy]), WARNING)


func _on_program_changed() -> void:
	program_dirty = editor.text != applied_program_source
	_invalidate_current_run(_t(&"locality.status.program_changed"))
	_validate_program_editor()
	_update_program_run_receipt()


func _validate_program_editor() -> DSLProgramType:
	var program: DSLProgramType = DSLParserType.parse(editor.text)
	program_dirty = editor.text != applied_program_source
	if program.is_valid():
		program_validation_label.text = _t(
			&"program.validation.valid_draft" if program_dirty else &"program.validation.valid_applied",
			[program.loop_order_text()]
		)
		program_validation_label.add_theme_color_override("font_color", GOOD)
		var addresses: Array[int] = program.memory_address_order(8)
		program_effect_label.text = _t(&"program.effect.preview", [
			_strategy_text(program.traversal_pattern()), String(program.loop_order[0]), String(program.loop_order[1]),
			_address_preview_text(addresses)
		])
		program_effect_label.add_theme_color_override("font_color", ACCENT)
		_update_program_explanation(program)
		program_apply_label.text = _t(&"program.apply.draft_pending") if program_dirty else _t(&"program.apply.applied", [_strategy_text(program.traversal_pattern())])
		program_apply_label.add_theme_color_override("font_color", WARNING if program_dirty else GOOD)
		apply_program_button.disabled = not program_dirty
		device_detail_labels[&"ProgramController"].text = _t(
			&"device.program.draft_detail" if program_dirty else &"device.program.applied_detail",
			[_strategy_text(program.traversal_pattern())]
		)
		device_state_labels[&"ProgramController"].text = _t(&"state.apply_required") if program_dirty else _t(&"state.applied_ready")
		device_state_labels[&"ProgramController"].add_theme_color_override("font_color", WARNING if program_dirty else GOOD)
		official_run_button.disabled = program_dirty
		debug_run_button.disabled = program_dirty
	else:
		var error_text: String = Localization.text_list(program.error_specs, " | ")
		if error_text.is_empty():
			error_text = " | ".join(program.errors)
		program_validation_label.text = _t(&"program.validation.error", [error_text])
		program_validation_label.add_theme_color_override("font_color", BAD)
		program_effect_label.text = _t(&"program.effect.invalid")
		program_effect_label.add_theme_color_override("font_color", BAD)
		program_apply_label.text = _t(&"program.apply.invalid")
		program_apply_label.add_theme_color_override("font_color", BAD)
		program_explanation_label.text = _t(&"program.explanation.invalid")
		apply_program_button.disabled = true
		device_detail_labels[&"ProgramController"].text = _t(&"device.program.invalid_source")
		device_state_labels[&"ProgramController"].text = _t(&"state.draft_error")
		device_state_labels[&"ProgramController"].add_theme_color_override("font_color", BAD)
		official_run_button.disabled = true
		debug_run_button.disabled = true
	return program


func _apply_program() -> void:
	var program: DSLProgramType = DSLParserType.parse(editor.text)
	if not program.is_valid():
		_validate_program_editor()
		_set_status(_t(&"locality.status.apply_blocked"), BAD)
		return
	if editor.text == applied_program_source:
		_validate_program_editor()
		_set_status(_t(&"locality.status.program_already_applied"), GOOD)
		return
	applied_program_source = editor.text
	program_dirty = false
	_invalidate_current_run(_t(&"locality.status.program_applied_cleared"))
	_validate_program_editor()
	_update_program_run_receipt()
	_set_status(_t(&"locality.status.program_applied", [_strategy_text(program.traversal_pattern())]), GOOD)


func _update_program_explanation(program: DSLProgramType) -> void:
	var explanations: Dictionary[int, Dictionary] = program.line_explanation_specs()
	var source_lines: PackedStringArray = program.source.split("\n")
	var output := PackedStringArray()
	for line_number: int in range(1, source_lines.size() + 1):
		if not explanations.has(line_number):
			continue
		output.append(_t(&"program.explanation.line", [
			line_number, source_lines[line_number - 1].strip_edges(), Localization.text_from_spec(explanations[line_number])
		]))
	program_explanation_label.text = "\n\n".join(output)


func _update_program_run_receipt() -> void:
	if last_run_receipt_text.is_empty():
		program_run_label.text = _t(&"program.receipt.not_executed")
	else:
		program_run_label.text = last_run_receipt_text
	if program_dirty:
		program_run_label.text += "\n" + _t(&"program.receipt.draft_not_applied")
	elif not last_executed_source.is_empty() and applied_program_source != last_executed_source:
		program_run_label.text += "\n" + _t(&"program.receipt.applied_not_run")
	program_run_label.add_theme_color_override("font_color", WARNING if program_dirty or applied_program_source != last_executed_source else GOOD)


func _address_preview_text(addresses: Array[int]) -> String:
	var parts := PackedStringArray()
	for address: int in addresses:
		parts.append(str(address))
	return " → ".join(parts)


func _on_debug_data_changed(_value: float) -> void:
	if current_trace != null and current_trace.test_name == "Debug Data":
		_invalidate_current_run(_t(&"locality.status.debug_data_changed"))


func _select_cache(lines: int, invalidate: bool = true) -> void:
	if not SimulationCoreType.CACHE_COSTS.has(lines):
		return
	var changed: bool = current_cache_lines != lines
	current_cache_lines = lines
	for option: int in cache_card_buttons:
		var button: Button = cache_card_buttons[option]
		button.disabled = option == lines
		button.text = ("✓ " if option == lines else "") + _t(&"cache.card", [option, option * 4, SimulationCoreType.CACHE_COSTS[option]])
	device_detail_labels[&"Cache"].text = _t(&"cache.detail", [lines, lines * 4, SimulationCoreType.CACHE_COSTS[lines]])
	if invalidate and changed:
		_invalidate_current_run(_t(&"locality.status.cache_replaced_rerun"))
		_set_status(_t(&"locality.status.cache_replaced", [lines, SimulationCoreType.CACHE_COSTS[lines]]), WARNING)


func _run_simulation(test_name: String) -> void:
	var draft: DSLProgramType = _validate_program_editor()
	if not draft.is_valid():
		_set_status(_t(&"locality.status.run_blocked_invalid_draft"), BAD)
		return
	if editor.text != applied_program_source:
		program_dirty = true
		_validate_program_editor()
		_set_status(_t(&"locality.status.run_blocked_unapplied"), BAD)
		return
	var program: DSLProgramType = DSLParserType.parse(applied_program_source)
	if not program.is_valid():
		_set_status(_t(&"locality.status.run_blocked_applied_invalid"), BAD)
		return
	var data: Array[int] = []
	if test_name == "Official Test Set":
		data = SimulationCoreType.official_data_copy()
	else:
		for input: SpinBox in debug_inputs:
			data.append(int(input.value))
	current_trace = simulation_core.run(program, data, current_cache_lines, test_name)
	last_executed_source = applied_program_source
	program_dirty = false
	current_goal_met = test_name == "Official Test Set" and current_trace.passed and int(current_trace.metrics["total_cycles"]) <= OFFICIAL_CYCLE_TARGET
	_record_run(program.traversal_pattern())
	_rebuild_profiler()
	playback_index = 0
	playback_elapsed = 0.0
	playback_running = not current_trace.events.is_empty()
	pause_button.text = _t(&"common.pause")
	pause_button.disabled = not playback_running
	step_button.disabled = current_trace.events.is_empty()
	trace_progress.value = 0.0
	if playback_running:
		_show_event_text(current_trace.events[0])
	var outcome: String
	if test_name == "Official Test Set":
		outcome = _t(&"outcome.target_met") if current_goal_met else (_t(&"outcome.correct_over_target") if current_trace.passed else _t(&"outcome.incorrect"))
	else:
		outcome = _t(&"outcome.correct") if current_trace.passed else _t(&"outcome.incorrect")
	result_label.text = _t(&"test_bench.result", [
		outcome, current_trace.result_value, current_trace.expected_value, int(current_trace.metrics["total_cycles"])
	])
	result_label.add_theme_color_override("font_color", GOOD if current_trace.passed else BAD)
	device_state_labels[&"TestBench"].text = outcome
	device_state_labels[&"Profiler"].text = _t(&"state.trace_ready")
	device_detail_labels[&"ProgramController"].text = _t(&"device.program.executing", [_strategy_text(program.traversal_pattern())])
	device_state_labels[&"ProgramController"].text = _t(&"state.trace_source")
	device_state_labels[&"ProgramController"].add_theme_color_override("font_color", GOOD)
	last_run_receipt_text = _t(&"program.receipt.last_executed", [
		_strategy_text(program.traversal_pattern()), int(current_trace.metrics["total_cycles"]), int(current_trace.metrics["cache_misses"])
	])
	_update_program_run_receipt()
	_set_status(
		_t(&"locality.status.run_complete", [
			outcome, _strategy_text(program.traversal_pattern()), int(current_trace.metrics["total_cycles"]),
			current_cache_lines, int(current_trace.metrics["hardware_cost"])
		]),
		GOOD if current_goal_met or (test_name == "Debug Data" and current_trace.passed) else WARNING
	)


func _record_run(traversal_pattern: String) -> void:
	var is_official: bool = current_trace.test_name == "Official Test Set"
	run_history.append({
		"test": current_trace.test_name,
		"pattern": traversal_pattern,
		"cache_lines": current_cache_lines,
		"cycles": int(current_trace.metrics["total_cycles"]),
		"misses": int(current_trace.metrics["cache_misses"]),
		"ram_bytes": int(current_trace.metrics["ram_bytes_transferred"]),
		"cost": int(current_trace.metrics["hardware_cost"]),
		"correct": current_trace.passed,
		"target_met": is_official and current_trace.passed and int(current_trace.metrics["total_cycles"]) <= OFFICIAL_CYCLE_TARGET,
	})
	while run_history.size() > RUN_HISTORY_LIMIT:
		run_history.pop_front()
	_update_history_label()


func _update_history_label() -> void:
	if run_history.is_empty():
		profiler_history_label.text = _t(&"profiler.history.empty")
		return
	var lines: PackedStringArray = []
	for index: int in range(run_history.size()):
		var record: Dictionary = run_history[index]
		var outcome: String = _t(&"outcome.met") if bool(record["target_met"]) else (_t(&"outcome.correct") if bool(record["correct"]) else _t(&"outcome.incorrect"))
		lines.append(_t(&"profiler.history.entry", [
			index + 1, _test_name_text(String(record["test"])), _strategy_text(String(record["pattern"])),
			int(record["cache_lines"]), int(record["cycles"]), int(record["misses"]),
			int(record["ram_bytes"]), int(record["cost"]), outcome
		]))
	profiler_history_label.text = "\n".join(lines)


func _rebuild_profiler() -> void:
	profiler_tree.clear()
	selected_profiler_event_index = -1
	inspect_event_button.disabled = true
	if current_trace == null:
		profiler_summary_label.text = _t(&"state.no_trace")
		return
	var metrics: Dictionary = current_trace.metrics
	var goal_text: String = _t(&"outcome.target_met") if current_goal_met else (_t(&"outcome.correct_over_target") if current_trace.passed else _t(&"outcome.incorrect"))
	profiler_summary_label.text = _t(&"profiler.summary", [
		goal_text, int(metrics["total_cycles"]), int(metrics["compute_cycles"]), int(metrics["wait_cycles"]),
		int(metrics["cache_hits"]), int(metrics["cache_misses"]), int(metrics["ram_bytes_transferred"]), int(metrics["hardware_cost"])
	])
	profiler_summary_label.add_theme_color_override("font_color", GOOD if current_goal_met else WARNING)
	var root: TreeItem = profiler_tree.create_item()
	var cycles: TreeItem = profiler_tree.create_item(root)
	cycles.set_text(0, _t(&"profiler.tree.cycles"))
	cycles.set_text(1, str(metrics["total_cycles"]))
	_add_tree_value(cycles, _t(&"profiler.tree.compute"), int(metrics["compute_cycles"]))
	var waiting: TreeItem = _add_tree_value(cycles, _t(&"profiler.tree.waiting"), int(metrics["wait_cycles"]))
	var breakdown: Dictionary[StringName, int] = {
		&"cache_lookup": 0,
		&"bus_request": 0,
		&"ram_access": 0,
		&"line_return": 0,
	}
	for event: SimulationEventType in current_trace.events:
		if breakdown.has(event.kind):
			breakdown[event.kind] += event.duration
	for entry: Array in [
		[&"cache_lookup", &"profiler.tree.cache_lookup"],
		[&"bus_request", &"profiler.tree.bus_request"],
		[&"ram_access", &"profiler.tree.ram_access"],
		[&"line_return", &"profiler.tree.line_return"],
	]:
		_add_tree_value(waiting, _t(StringName(entry[1])), breakdown[entry[0]])

	var memory: TreeItem = profiler_tree.create_item(root)
	memory.set_text(0, _t(&"profiler.tree.memory_accesses"))
	memory.set_text(1, str(int(metrics["cache_hits"]) + int(metrics["cache_misses"])))
	_add_tree_value(memory, _t(&"profiler.tree.cache_hits"), int(metrics["cache_hits"]))
	var misses: TreeItem = _add_tree_value(memory, _t(&"profiler.tree.cache_misses"), int(metrics["cache_misses"]))
	for event_index: int in range(current_trace.events.size()):
		var event: SimulationEventType = current_trace.events[event_index]
		if event.kind != &"cache_miss":
			continue
		var item: TreeItem = profiler_tree.create_item(misses)
		item.set_text(0, _t(&"profiler.tree.miss_event", [
			event.cycle, event.source_line, int(event.details.get("array_row", -1)), int(event.details.get("array_column", -1))
		]))
		item.set_text(1, _t(&"profiler.tree.cache_line", [event.cache_line]))
		item.set_metadata(0, event_index)
	_update_history_label()


func _add_tree_value(parent: TreeItem, label_text: String, value: int) -> TreeItem:
	var item: TreeItem = profiler_tree.create_item(parent)
	item.set_text(0, label_text)
	item.set_text(1, str(value))
	return item


func _on_profiler_item_selected() -> void:
	var item: TreeItem = profiler_tree.get_selected()
	if item == null or item.get_metadata(0) == null:
		selected_profiler_event_index = -1
		inspect_event_button.disabled = true
		return
	selected_profiler_event_index = int(item.get_metadata(0))
	if current_trace == null or selected_profiler_event_index < 0 or selected_profiler_event_index >= current_trace.events.size():
		inspect_event_button.disabled = true
		return
	var event: SimulationEventType = current_trace.events[selected_profiler_event_index]
	profiler_detail_label.text = _t(&"profiler.event_detail", [
		event.cycle, event.source_line, int(event.details.get("array_row", -1)), int(event.details.get("array_column", -1)),
		event.address, event.cache_line, int(event.details.get("line_base_address", -1)),
		int(event.details.get("line_base_address", -1)) + 3, str(event.details.get("line_values", []))
	])
	profiler_detail_label.add_theme_color_override("font_color", WARNING)
	inspect_event_button.disabled = false


func _inspect_profiler_event() -> void:
	if current_trace == null or selected_profiler_event_index < 0 or selected_profiler_event_index >= current_trace.events.size():
		return
	playback_running = false
	playback_index = selected_profiler_event_index
	playback_elapsed = 0.0
	pause_button.text = _t(&"common.resume")
	var event: SimulationEventType = current_trace.events[playback_index]
	_show_event_text(event)
	_draw_event(event, 0.72)
	_update_trace_progress(0.72)
	_set_status(_t(&"locality.status.profiler_inspect", [event.cycle, event.source_line, _event_message(event)]), WARNING)


func _toggle_pause() -> void:
	if current_trace == null or current_trace.events.is_empty():
		return
	if playback_index >= current_trace.events.size():
		playback_index = 0
		playback_elapsed = 0.0
		trace_progress.value = 0.0
		_show_event_text(current_trace.events[0])
	playback_running = not playback_running
	pause_button.text = _t(&"common.pause") if playback_running else _t(&"common.resume")


func _step_trace() -> void:
	if current_trace == null or current_trace.events.is_empty():
		return
	playback_running = false
	pause_button.text = _t(&"common.resume")
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
		&"request": return 0.62
		&"cache_lookup": return 0.34
		&"cache_hit", &"cache_fill": return 0.46
		&"cache_miss", &"cache_evict": return 0.38
		&"bus_request": return 0.56
		&"ram_access": return 0.64
		&"line_return": return 0.92
		&"compute": return 0.42
		&"store_result": return 0.66
		_: return maxf(0.32, float(event.duration) * 0.04)


func _draw_event(event: SimulationEventType, progress: float) -> void:
	var animation: Dictionary = _event_animation(event)
	trace_overlay.show_event(
		animation.get("path", PackedVector2Array()), animation.get("processing_ranges", []),
		progress, _event_color(event.kind), _event_short_label(event)
	)
	_apply_event_feedback(event, animation, progress)
	_highlight_source_line(event.source_line)


func _event_animation(event: SimulationEventType) -> Dictionary:
	var devices: Array[StringName] = _presentation_devices(event)
	if devices.is_empty():
		return {"path": PackedVector2Array(), "processing_ranges": []}
	var wires: Array[PackedVector2Array] = []
	for index: int in range(devices.size() - 1):
		var wire: PackedVector2Array = _connection_curve(devices[index], devices[index + 1])
		if wire.size() < 2:
			return {"path": PackedVector2Array(), "processing_ranges": []}
		wires.append(wire)

	var complete := PackedVector2Array()
	var raw_ranges: Array[Dictionary] = []
	for device_index: int in range(devices.size()):
		var center: Vector2 = _device_center(devices[device_index])
		var entry: Vector2 = center if device_index == 0 else wires[device_index - 1][wires[device_index - 1].size() - 1]
		var exit: Vector2 = center if device_index == devices.size() - 1 else wires[device_index][0]
		var process_path: PackedVector2Array = _component_process_curve(devices[device_index], entry, exit)
		var start_index: int = complete.size()
		if not complete.is_empty() and not process_path.is_empty() and complete[complete.size() - 1].is_equal_approx(process_path[0]):
			start_index = complete.size() - 1
		for point: Vector2 in process_path:
			if not complete.is_empty() and complete[complete.size() - 1].is_equal_approx(point):
				continue
			complete.append(point)
		raw_ranges.append({
			"device": devices[device_index],
			"center": center,
			"rect": _device_rect(devices[device_index]),
			"start_index": maxi(0, start_index),
			"end_index": maxi(0, complete.size() - 1),
		})
		if device_index < wires.size():
			for point: Vector2 in wires[device_index]:
				if not complete.is_empty() and complete[complete.size() - 1].is_equal_approx(point):
					continue
				complete.append(point)

	var distances: Array[float] = [0.0]
	for point_index: int in range(1, complete.size()):
		distances.append(distances[point_index - 1] + complete[point_index - 1].distance_to(complete[point_index]))
	var total_length: float = distances[distances.size() - 1] if not distances.is_empty() else 0.0
	var normalized_ranges: Array[Dictionary] = []
	if total_length > 0.001:
		for raw_range: Dictionary in raw_ranges:
			normalized_ranges.append({
				"device": raw_range["device"],
				"center": raw_range["center"],
				"rect": raw_range["rect"],
				"start": distances[int(raw_range["start_index"])] / total_length,
				"end": distances[int(raw_range["end_index"])] / total_length,
			})
	return {"path": complete, "processing_ranges": normalized_ranges}


func _presentation_devices(event: SimulationEventType) -> Array[StringName]:
	var devices: Array[StringName] = event.route_devices.duplicate()
	if event.kind == &"request" or event.kind == &"compute" or event.kind == &"store_result":
		if devices.is_empty() or devices[0] != &"ProgramController":
			devices.push_front(&"ProgramController")
	return devices


func _component_process_curve(device: StringName, entry: Vector2, exit: Vector2) -> PackedVector2Array:
	var rect: Rect2 = _device_rect(device)
	var center: Vector2 = rect.get_center()
	var lane_half_width: float = minf(42.0, rect.size.x * 0.20)
	var lane_start := center - Vector2(lane_half_width, 0.0)
	var lane_end := center + Vector2(lane_half_width, 0.0)
	var path := PackedVector2Array()
	if not entry.is_equal_approx(center):
		path.append(entry)
	path.append(lane_start)
	path.append(center)
	path.append(lane_end)
	if not exit.is_equal_approx(center):
		path.append(exit)
	return path


func _device_center(device: StringName) -> Vector2:
	var node: GraphNode = device_nodes.get(device)
	if node == null:
		return Vector2.ZERO
	return node.position + node.size * 0.5


func _device_rect(device: StringName) -> Rect2:
	var node: GraphNode = device_nodes.get(device)
	if node == null:
		return Rect2()
	return Rect2(node.position, node.size)


func _event_path(event: SimulationEventType) -> PackedVector2Array:
	if event.route_devices.size() < 2:
		return PackedVector2Array()
	var complete := PackedVector2Array()
	for route_index: int in range(event.route_devices.size() - 1):
		var segment: PackedVector2Array = _connection_curve(event.route_devices[route_index], event.route_devices[route_index + 1])
		if segment.size() < 2:
			return PackedVector2Array()
		for point_index: int in range(segment.size()):
			if not complete.is_empty() and point_index == 0 and complete[complete.size() - 1].is_equal_approx(segment[0]):
				continue
			complete.append(segment[point_index])
	return complete


func _connection_curve(from_device: StringName, to_device: StringName) -> PackedVector2Array:
	for connection: Array in REQUIRED_CONNECTIONS:
		var canonical_from: StringName = connection[0]
		var canonical_to: StringName = connection[2]
		var reverse: bool = canonical_from == to_device and canonical_to == from_device
		if not (canonical_from == from_device and canonical_to == to_device) and not reverse:
			continue
		var start: Vector2 = _node_port_point(canonical_from, true, int(connection[1]))
		var finish: Vector2 = _node_port_point(canonical_to, false, int(connection[3]))
		var curve: PackedVector2Array = graph.get_connection_line(start, finish)
		if not reverse:
			return curve
		var reversed := PackedVector2Array()
		for index: int in range(curve.size() - 1, -1, -1):
			reversed.append(curve[index])
		return reversed
	return PackedVector2Array()


func _node_port_point(device: StringName, output: bool, port: int) -> Vector2:
	var device_node: GraphNode = device_nodes.get(device)
	if device_node == null:
		return Vector2.ZERO
	var local_position: Vector2
	if output and port < device_node.get_output_port_count():
		local_position = device_node.get_output_port_position(port)
	elif not output and port < device_node.get_input_port_count():
		local_position = device_node.get_input_port_position(port)
	else:
		return Vector2.ZERO
	return device_node.position + local_position


func _apply_event_feedback(event: SimulationEventType, animation: Dictionary, progress: float) -> void:
	_reset_device_feedback()
	_apply_passive_context(event)
	var movement_progress: float = smoothstep(0.0, 1.0, clampf(progress, 0.0, 1.0))
	var active_range: Dictionary = {}
	for process_range: Dictionary in animation.get("processing_ranges", []):
		if movement_progress >= float(process_range["start"]) and movement_progress <= float(process_range["end"]):
			active_range = process_range
			break
	if active_range.is_empty():
		return
	var device: StringName = active_range["device"]
	active_component = device
	var local_progress: float = inverse_lerp(float(active_range["start"]), float(active_range["end"]), movement_progress)
	var pulse: float = sin(clampf(local_progress, 0.0, 1.0) * PI)
	_activate_device(device, _component_state_text(event, device), _event_color(event.kind), pulse)


func _apply_passive_context(event: SimulationEventType) -> void:
	if event.kind in [&"cache_lookup", &"cache_hit", &"cache_miss", &"bus_request", &"ram_access", &"line_return", &"cache_evict", &"cache_fill"]:
		_set_passive_device_state(&"CPU", _t(&"state.waiting_for_memory"))


func _set_passive_device_state(device: StringName, state_text: String) -> void:
	if not device_state_labels.has(device):
		return
	device_state_labels[device].text = state_text
	device_state_labels[device].add_theme_color_override("font_color", MUTED)


func _component_state_text(event: SimulationEventType, device: StringName) -> String:
	match event.kind:
		&"request":
			if device == &"ProgramController": return _t(&"event.state.issue_load", [event.source_line])
			if device == &"CPU": return _t(&"event.state.form_address", [event.details.get("array_row", -1), event.details.get("array_column", -1)])
			return _t(&"event.state.accept_request")
		&"cache_lookup": return _t(&"event.state.lookup_line", [event.cache_line])
		&"cache_hit":
			return _t(&"event.state.read_hit_line", [event.cache_line]) if device == &"Cache" else _t(&"event.state.latch_value", [event.value])
		&"cache_miss": return _t(&"event.state.miss_line", [event.cache_line])
		&"bus_request":
			return _t(&"event.state.send_line_request", [event.cache_line]) if device == &"Cache" else _t(&"event.state.forward_request")
		&"ram_access":
			return _t(&"event.state.send_address") if device == &"Bus" else _t(&"event.state.read_line", [event.cache_line])
		&"line_return":
			if device == &"RAM": return _t(&"event.state.pack_line", [event.cache_line])
			if device == &"Bus": return _t(&"event.state.relay_16b")
			return _t(&"event.state.install_line", [event.cache_line])
		&"cache_evict": return _t(&"event.state.evict_line", [event.cache_line])
		&"cache_fill":
			return _t(&"event.state.read_filled_line", [event.cache_line]) if device == &"Cache" else _t(&"event.state.latch_value", [event.value])
		&"compute":
			return _t(&"event.state.issue_add", [event.source_line]) if device == &"ProgramController" else _t(&"event.state.add_result", [event.value])
		&"store_result":
			if device == &"ProgramController": return _t(&"event.state.issue_store", [event.source_line])
			if device == &"CPU": return _t(&"event.state.send_value", [event.value])
			return _t(&"event.state.check_value", [event.value])
	return _t(&"event.state.process_device", [_device_name(device)])


func _reset_device_feedback() -> void:
	active_component = &""
	for device: StringName in device_nodes:
		device_state_labels[device].text = device_default_states[device]
		device_state_labels[device].add_theme_color_override("font_color", MUTED)
		_set_device_style(device, MUTED, false)
	if current_trace != null:
		device_state_labels[&"Profiler"].text = _t(&"state.trace_ready")
		device_state_labels[&"TestBench"].text = _t(&"outcome.target_met") if current_goal_met else (_t(&"outcome.correct") if current_trace.passed else _t(&"outcome.incorrect"))


func _activate_device(device: StringName, state_text: String, color: Color, pulse: float) -> void:
	if not device_nodes.has(device):
		return
	device_state_labels[device].text = state_text
	device_state_labels[device].add_theme_color_override("font_color", color)
	_set_device_style(device, color, true, pulse)


func _set_device_style(device: StringName, color: Color, active: bool, pulse: float = 0.0) -> void:
	var node: GraphNode = device_nodes.get(device)
	if node == null:
		return
	var background: Color = Color("152039") if active else Color("121a2a")
	if active:
		background = background.lerp(Color(color, 1.0), 0.08 + pulse * 0.08)
	var border: Color = Color(color, 0.95 if active else 0.30)
	var width: int = 3 if active else 1
	node.add_theme_stylebox_override("panel", _stylebox(background, 8, width, border))
	node.add_theme_stylebox_override("titlebar", _stylebox(background.darkened(0.08), 8, width, border))


func _highlight_source_line(source_line: int) -> void:
	if editor == null:
		return
	if highlighted_source_line > 0 and highlighted_source_line <= editor.get_line_count():
		editor.set_line_background_color(highlighted_source_line - 1, Color.TRANSPARENT)
	highlighted_source_line = source_line
	if source_line > 0 and source_line <= editor.get_line_count():
		editor.set_line_background_color(source_line - 1, Color(ACCENT, 0.22))


func _show_event_text(event: SimulationEventType) -> void:
	playback_label.text = _t(&"trace.playback.event", [
		playback_index + 1, current_trace.events.size(), event.cycle, event.duration, event.source_line, _event_message(event)
	])
	playback_label.add_theme_color_override("font_color", _event_color(event.kind))


func _finish_playback() -> void:
	playback_running = false
	pause_button.text = _t(&"common.replay")
	trace_overlay.clear_event()
	trace_progress.value = 100.0
	_reset_device_feedback()
	_highlight_source_line(-1)
	playback_label.text = _t(&"trace.playback.complete")
	playback_label.add_theme_color_override("font_color", GOOD)


func _event_color(kind: StringName) -> Color:
	match kind:
		&"cache_hit", &"cache_fill": return GOOD
		&"cache_miss", &"cache_evict": return BAD
		&"ram_access", &"line_return", &"bus_request": return WARNING
		&"compute", &"store_result": return PURPLE
		_: return ACCENT


func _event_short_label(event: SimulationEventType) -> String:
	match event.kind:
		&"request": return "A[%d][%d]" % [event.details.get("array_row", -1), event.details.get("array_column", -1)]
		&"cache_lookup": return _t(&"event.short.lookup")
		&"cache_hit": return _t(&"event.short.hit")
		&"cache_miss": return _t(&"event.short.miss")
		&"bus_request": return _t(&"event.short.request")
		&"ram_access": return _t(&"event.short.read_line")
		&"line_return": return _t(&"event.short.four_ints")
		&"cache_fill": return _t(&"event.short.value", [event.value])
		&"cache_evict": return _t(&"event.short.evict")
		&"compute": return _t(&"event.short.add")
		&"store_result": return "OUT[0]"
		_: return String(event.kind).to_upper()


func _event_message(event: SimulationEventType) -> String:
	match event.kind:
		&"request":
			return _t(&"event.message.request", [
				event.details.get("array_row", -1), event.details.get("array_column", -1), event.address
			])
		&"cache_lookup":
			return _t(&"event.message.cache_lookup", [event.cache_line])
		&"cache_hit":
			return _t(&"event.message.cache_hit", [event.cache_line, event.value])
		&"cache_miss":
			return _t(&"event.message.cache_miss", [event.cache_line])
		&"bus_request":
			return _t(&"event.message.bus_request")
		&"ram_access":
			return _t(&"event.message.ram_access", [event.cache_line, str(event.details.get("line_values", []))])
		&"line_return":
			return _t(&"event.message.line_return", [event.cache_line])
		&"cache_evict":
			return _t(&"event.message.cache_evict", [event.cache_line])
		&"cache_fill":
			return _t(&"event.message.cache_fill", [event.cache_line, event.value])
		&"compute":
			return _t(&"event.message.compute", [event.details.get("instruction_text", ""), event.value])
		&"store_result":
			return _t(&"event.message.store_result", [event.value])
	return event.message


func _strategy_text(pattern: String) -> String:
	match pattern:
		"row-first": return _t(&"strategy.row_first")
		"column-first": return _t(&"strategy.column_first")
	return _t(&"strategy.unknown")


func _test_name_text(test_name: String) -> String:
	match test_name:
		"Official Test Set": return _t(&"test.official")
		"Debug Data": return _t(&"test.debug")
	return test_name


func _device_name(device: StringName) -> String:
	match device:
		&"ProgramController": return _t(&"device.program")
		&"Cache": return _t(&"device.cache")
		&"Bus": return _t(&"device.bus")
		&"RAM": return _t(&"device.ram")
		&"TestBench": return _t(&"device.test_bench")
		&"Profiler": return _t(&"device.profiler")
	return String(device)


func _invalidate_current_run(reason: String) -> void:
	current_trace = null
	current_goal_met = false
	playback_running = false
	playback_index = 0
	playback_elapsed = 0.0
	pause_button.text = _t(&"common.pause")
	pause_button.disabled = true
	step_button.disabled = true
	trace_overlay.clear_event()
	trace_progress.value = 0.0
	playback_label.text = _t(&"trace.playback.inputs_changed")
	playback_label.add_theme_color_override("font_color", WARNING)
	profiler_tree.clear()
	profiler_summary_label.text = _t(&"state.no_trace")
	profiler_detail_label.text = _t(&"profiler.select_miss")
	inspect_event_button.disabled = true
	selected_profiler_event_index = -1
	result_label.text = _t(&"state.not_run")
	result_label.add_theme_color_override("font_color", TEXT)
	_reset_device_feedback()
	device_state_labels[&"Profiler"].text = _t(&"state.no_trace")
	device_state_labels[&"TestBench"].text = _t(&"state.not_run")
	_highlight_source_line(-1)
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


func _t(key: StringName, arguments: Array = []) -> String:
	return Localization.text(key, arguments)
