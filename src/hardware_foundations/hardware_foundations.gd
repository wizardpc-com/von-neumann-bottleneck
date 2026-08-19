class_name HardwareFoundations
extends Control

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const LogicSignalType = preload("res://src/circuit/logic_signal.gd")
const CircuitAnalyzerType = preload("res://src/circuit/circuit_analyzer.gd")
const CircuitLiveStateType = preload("res://src/circuit/circuit_live_state.gd")
const CircuitEventType = preload("res://src/circuit/circuit_event.gd")
const CircuitTraceType = preload("res://src/circuit/circuit_trace.gd")
const HalfAdderTestBenchType = preload("res://src/circuit/half_adder_test_bench.gd")
const ReusableHalfAdderType = preload("res://src/circuit/reusable_half_adder.gd")
const DigitalValueType = preload("res://src/circuit/digital_value.gd")
const PrologueEventType = preload("res://src/circuit/prologue_event.gd")
const PrologueSimulationResultType = preload("res://src/circuit/prologue_simulation_result.gd")
const PrologueSimulatorType = preload("res://src/circuit/prologue_simulator.gd")
const ReusableComponentType = preload("res://src/circuit/reusable_component.gd")
const CircuitGraphEditType = preload("res://src/hardware_foundations/circuit_graph_edit.gd")
const CircuitTraceOverlayType = preload("res://src/hardware_foundations/circuit_trace_overlay.gd")
const CircuitComponentSymbolType = preload("res://src/hardware_foundations/circuit_component_symbol.gd")
const CircuitModuleRowType = preload("res://src/hardware_foundations/circuit_module_row.gd")
const CampaignMapViewType = preload("res://src/hardware_foundations/campaign_map_view.gd")
const EncapsulationEffectType = preload("res://src/hardware_foundations/encapsulation_effect.gd")
const PrologueLevelCatalogType = preload("res://src/hardware_foundations/prologue_level_catalog.gd")
const PlayerContentStateType = preload("res://src/content/player_content_state.gd")
const FloatingInstrumentPanelType = preload("res://src/ui/floating_instrument_panel.gd")
const GameModeSelectorType = preload("res://src/ui/game_mode_selector.gd")

const BACKGROUND := Color("09101d")
const PANEL := Color("172033")
const PANEL_DARK := Color("101725")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const BAD := Color("ff6b7d")
const PURPLE := Color("bc8cff")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")
const PORT_TYPE: int = 1
const SIGNAL_HIGH := GOOD
const SIGNAL_LOW := BAD
const SIGNAL_HIGH_Z := Color("8b929d")

var current_phase: StringName = &"tutorial"
var current_circuit: LogicCircuit
var current_trace: CircuitTrace
var live_state: CircuitLiveStateType
var live_refresh_queued: bool = false
var live_state_key: String = ""
var live_analysis_count: int = 0
var official_report: Dictionary = {}
var official_passed: bool = false
var passing_topology_signature: String = ""
var sealed_half_adder: ReusableHalfAdder
var level_catalog := PrologueLevelCatalogType.new()
var prologue_simulator := PrologueSimulatorType.new()
var game_player_content := PlayerContentStateType.new()
var test_player_content := PlayerContentStateType.new()
var player_content = game_player_content
var component_library: Dictionary = player_content.component_library
var completed_levels: Dictionary = player_content.completed_levels
var campaign_level_buttons: Dictionary[StringName, Button] = {}
var current_level_id: StringName = &""
var current_level_definition: Dictionary = {}
var prologue_live_result: PrologueSimulationResult
var prologue_report: Dictionary = {}
var prologue_runtime_state: Dictionary = {}
var prologue_prior_outputs: Dictionary = {}
var prologue_input_controls: Dictionary[StringName, Control] = {}
var prologue_case_labels: Array[Label] = []
var storage_state_label: Label
var storage_reset_button: Button
var storage_playback_values: Dictionary[StringName, DigitalValue] = {}
var prologue_level_completed_view: bool = false
var sealing_level_id: StringName = &""
var pending_sealed_circuit: LogicCircuit

var graph_stack: Control
var graph: CircuitGraphEdit
var campaign_map_view: CampaignMapViewType
var trace_overlay: CircuitTraceOverlay
var encapsulation_effect: EncapsulationEffect
var side_box: VBoxContainer
var task_box: VBoxContainer
var desktop_windows: Dictionary[StringName, FloatingInstrumentPanel] = {}
var desktop_window_buttons: Dictionary[StringName, Button] = {}
var desktop_z_counter: int = 100
var phase_label: Label
var status_label: Label
var trace_caption_label: Label
var diagnostics_label: Label
var tutorial_next_button: Button
var seal_button: Button
var input_a_button: CheckButton
var input_b_button: CheckButton
var debug_result_label: Label
var official_case_labels: Array[Label] = []
var pause_button: Button
var speed_selector: OptionButton
var component_menu_button: MenuButton
var mode_selector: GameModeSelectorType

var component_catalog: Dictionary[StringName, LogicComponent] = {}
var component_nodes: Dictionary[StringName, GraphNode] = {}
var component_symbols: Dictionary[StringName, CircuitComponentSymbol] = {}
var component_row_labels: Dictionary[StringName, Array] = {}
var component_state_labels: Dictionary[StringName, Label] = {}
var component_idle_state_text: Dictionary[StringName, String] = {}
var layout_positions: Dictionary[StringName, Vector2] = {}
var wire_history: Array[Dictionary] = []
var redo_history: Array[Dictionary] = []
var active_erase_action: Dictionary = {}
var junction_counter: int = 0
var history_replaying: bool = false
var node_move_start_positions: Dictionary = {}
var clipboard_components: Array[Dictionary] = []
var clipboard_wires: Array[Dictionary] = []
var clipboard_paste_count: int = 0
var pasted_component_counter: int = 0
var component_menu_templates: Dictionary = {}
var component_menu_template_keys: Array[String] = []
var armed_component_template_key: String = ""
var placed_component_counter: int = 0
var builtin_connection_drag_active: bool = false

var tutorial_created_wire: bool = false
var tutorial_changed_input: bool = false
var tutorial_removed_wire: bool = false
var tutorial_reconnected_wire: bool = false
var tutorial_valid_run: bool = false
var tutorial_check_labels: Dictionary[StringName, Label] = {}

var playback_index: int = 0
var playback_elapsed: float = 0.0
var playback_speed: float = 1.0
var playback_running: bool = false
var playback_batches: Array[Dictionary] = []
var active_components: Array[StringName] = []
var active_connections: Array[Dictionary] = []
var active_component: StringName = &""
var active_connection: Dictionary = {}
var sealing: bool = false
var sealing_elapsed: float = 0.0


func _ready() -> void:
	_build_theme()
	_build_interface()
	_activate_content_state()
	GameMode.mode_changed.connect(_on_game_mode_changed)
	var user_arguments: PackedStringArray = OS.get_cmdline_user_args()
	var preparing_capture: bool = (
		"--capture-prologue-map" in user_arguments
		or "--capture-prologue-storage" in user_arguments
		or "--capture-prologue-cpu" in user_arguments
		or "--capture-schematic-signal" in user_arguments
		or "--capture-component-processing" in user_arguments
		or "--capture-component-placement" in user_arguments
		or "--capture-wiring-guides" in user_arguments
		or "--capture-selection-highlight" in user_arguments
	)
	if preparing_capture:
		# Capture helpers need a deterministic non-empty provenance circuit. Normal
		# play starts on the dependency map instead of silently bypassing it.
		_show_tutorial()
	else:
		_open_campaign_map()
	if "--capture-wiring-guides" in user_arguments:
		call_deferred("_prepare_wiring_guides_capture")
	elif "--capture-selection-highlight" in user_arguments:
		call_deferred("_prepare_selection_highlight_capture")
	elif "--capture-component-placement" in user_arguments:
		call_deferred("_prepare_component_placement_capture")
	elif "--capture-prologue-map" in user_arguments:
		call_deferred("_prepare_prologue_map_capture")
	elif "--capture-prologue-storage" in user_arguments:
		call_deferred("_prepare_prologue_storage_capture")
	elif "--capture-prologue-cpu" in user_arguments:
		call_deferred("_prepare_prologue_cpu_capture")
	elif "--capture-component-processing" in user_arguments:
		call_deferred("_prepare_component_processing_capture")
	elif "--capture-schematic-signal" in user_arguments:
		call_deferred("_prepare_schematic_signal_capture")
	set_process(true)


func _input(event: InputEvent) -> void:
	if not _handle_editor_shortcut(event):
		return
	get_viewport().set_input_as_handled()


func _prepare_schematic_signal_capture() -> void:
	_on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	_on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	input_a_button.set_pressed_no_signal(true)
	_update_input_button_text()
	_run_debug()
	_finish_playback()


func _prepare_component_processing_capture() -> void:
	_on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	_on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	input_a_button.set_pressed_no_signal(true)
	_update_input_button_text()
	_run_debug()
	playback_running = false
	for batch: Dictionary in playback_batches:
		for event: Variant in batch.get("events", []):
			if event.kind == &"component_process" and event.component_id == &"NOT_1":
				_show_playback_batch(batch, 0.5)
				return


func _prepare_wiring_guides_capture() -> void:
	await get_tree().process_frame
	_on_connection_drag_started(&"A_IN", 0, true)
	var target: GraphNode = component_nodes.get(&"NOT_1")
	if target == null:
		return
	var motion := InputEventMouseMotion.new()
	motion.position = target.position + target.get_input_port_position(0) + Vector2(-12.0, 0.0)
	graph.call("_gui_input", motion)


func _prepare_selection_highlight_capture() -> void:
	await get_tree().process_frame
	_set_selected_ids([&"NOT_1"] as Array[StringName])


func _prepare_component_placement_capture() -> void:
	if component_menu_button == null or component_menu_template_keys.is_empty():
		return
	var popup: PopupMenu = component_menu_button.get_popup()
	if popup.item_count <= 0:
		return
	_on_component_menu_item_pressed(popup.get_item_id(0))
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1000.0, 590.0)
	graph.call("_gui_input", motion)


func _prepare_prologue_map_capture() -> void:
	_bootstrap_capture_library(true)
	_open_campaign_map()


func _prepare_prologue_cpu_capture() -> void:
	_bootstrap_capture_library(false)
	_start_prologue_level(&"cpu")
	_load_reference_wires(current_level_definition)
	_run_prologue_official()
	playback_running = false
	for batch: Dictionary in playback_batches:
		var includes_data_path: bool = false
		for event: Variant in batch.get("events", []):
			if event.kind == &"component_process" and event.component_id in [&"ALU", &"RAM", &"ACC"]:
				includes_data_path = true
				break
		if includes_data_path:
			_show_playback_batch(batch, 0.58)
			break


func _prepare_prologue_storage_capture() -> void:
	_bootstrap_capture_library(false)
	_start_prologue_level(&"ram")
	_load_reference_wires(current_level_definition)
	_run_prologue_official()
	playback_running = false
	# GraphEdit applies position_offset/zoom during its next layout pass.  Freeze
	# the diagnostic state wave only after those displayed coordinates exist.
	await get_tree().process_frame
	for batch: Dictionary in playback_batches:
		var state_count: int = 0
		var includes_write: bool = false
		for event: PrologueEvent in batch.get("events", []):
			if event.kind != &"state_transition":
				continue
			state_count += 1
			includes_write = includes_write or event.message_key == &"hardware.trace.state.write"
		if state_count >= 2 and includes_write:
			_show_playback_batch(batch, 0.62)
			break


func _activate_content_state() -> void:
	player_content = test_player_content if GameMode.is_test_mode() else game_player_content
	component_library = player_content.component_library
	completed_levels = player_content.completed_levels
	if GameMode.is_test_mode():
		_install_support_library(component_library, LogicCircuitType.new(), true)


func _on_game_mode_changed(_mode: StringName) -> void:
	sealing = false
	sealing_elapsed = 0.0
	sealing_level_id = &""
	pending_sealed_circuit = null
	_activate_content_state()
	_open_campaign_map()


func _is_level_unlocked(level_id: StringName) -> bool:
	if GameMode.is_test_mode():
		return level_id in level_catalog.level_ids()
	return level_catalog.is_unlocked(level_id, completed_levels)


func _bootstrap_capture_library(include_computer: bool) -> void:
	var source: LogicCircuit = current_circuit.duplicate_circuit()
	_install_support_library(component_library, source, include_computer)
	for level_id: StringName in [&"half_adder", &"full_adder", &"alu", &"latch", &"register", &"ram"]:
		completed_levels[level_id] = true
	if include_computer:
		completed_levels[&"cpu"] = true


func _install_support_library(
		target_library: Dictionary,
		source: LogicCircuit,
		include_computer: bool
	) -> void:
	for entry: Array in [
		[&"HalfAdder", LogicComponentType.KIND_HALF_ADDER, &"half_adder"],
		[&"FullAdder", LogicComponentType.KIND_FULL_ADDER, &"full_adder"],
		[&"ALU1", LogicComponentType.KIND_ALU1, &"alu"],
		[&"SRLatch", LogicComponentType.KIND_SR_LATCH, &"latch"],
		[&"Register1", LogicComponentType.KIND_REGISTER1, &"register"],
		[&"RAM2x4", LogicComponentType.KIND_RAM2X4, &"ram"],
	]:
		if not target_library.has(entry[0]):
			target_library[entry[0]] = ReusableComponentType.new(
				entry[0], entry[1], entry[2], source
			)
	if not target_library.has(&"ALU4"):
		target_library[&"ALU4"] = ReusableComponentType.new(
		&"ALU4", LogicComponentType.KIND_ALU4, &"alu", null,
		[(target_library[&"ALU1"] as ReusableComponent).source_signature],
		{"auto_expanded_bits": 4}
	)
	if not target_library.has(&"Register4"):
		target_library[&"Register4"] = ReusableComponentType.new(
		&"Register4", LogicComponentType.KIND_REGISTER4, &"register", null,
		[(target_library[&"Register1"] as ReusableComponent).source_signature],
		{"auto_expanded_bits": 4}
	)
	if include_computer and not target_library.has(&"TinyComputer"):
		target_library[&"TinyComputer"] = ReusableComponentType.new(
			&"TinyComputer", LogicComponentType.KIND_TINY_COMPUTER, &"cpu", source
		)


func _process(delta: float) -> void:
	if sealing:
		sealing_elapsed += delta
		encapsulation_effect.set_progress(sealing_elapsed / 1.55)
		if sealing_elapsed >= 1.55:
			_finish_encapsulation()
	if not playback_running or playback_batches.is_empty():
		return
	if playback_index >= playback_batches.size():
		_finish_playback()
		return
	var batch: Dictionary = playback_batches[playback_index]
	playback_elapsed += delta * playback_speed
	var duration: float = _playback_batch_duration(batch)
	var progress: float = minf(playback_elapsed / duration, 1.0)
	_show_playback_batch(batch, progress)
	if progress >= 1.0:
		playback_index += 1
		playback_elapsed = 0.0
		if playback_index >= playback_batches.size():
			_finish_playback()


func _build_theme() -> void:
	var prototype_theme := Theme.new()
	prototype_theme.default_font_size = 16
	for control_type: String in ["Label", "Button", "CheckButton", "OptionButton", "GraphNode"]:
		prototype_theme.set_color("font_color", control_type, TEXT)
	prototype_theme.set_color("title_color", "GraphNode", TEXT)
	# Per-signal overlay pulses carry high/low color; a single GraphEdit activity
	# color cannot represent simultaneous green and red branches correctly.
	prototype_theme.set_color("activity", "GraphEdit", Color.TRANSPARENT)
	prototype_theme.set_color("connection_valid_target_tint_color", "GraphEdit", Color(GOOD, 0.72))
	prototype_theme.set_color("connection_hover_tint_color", "GraphEdit", Color(ACCENT, 0.35))
	prototype_theme.set_color("connection_rim_color", "GraphEdit", Color.TRANSPARENT)
	prototype_theme.set_constant("separation", "VBoxContainer", 9)
	prototype_theme.set_constant("separation", "HBoxContainer", 10)
	prototype_theme.set_constant("separation", "GraphNode", 5)
	prototype_theme.set_constant("port_h_offset", "GraphNode", -2)
	prototype_theme.set_stylebox("panel", "PanelContainer", _stylebox(PANEL, 10, 1, Color("293650")))
	prototype_theme.set_stylebox("normal", "Button", _stylebox(Color("26334a"), 7, 1, Color("354866")))
	prototype_theme.set_stylebox("hover", "Button", _stylebox(Color("30435f"), 7, 1, ACCENT))
	prototype_theme.set_stylebox("pressed", "Button", _stylebox(Color("17283e"), 7, 1, ACCENT))
	prototype_theme.set_icon("port", "GraphNode", _make_port_texture(24))
	theme = prototype_theme


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	root_box.add_child(_build_toolbar())

	var graph_panel := PanelContainer.new()
	graph_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(graph_panel)
	graph_stack = Control.new()
	graph_stack.custom_minimum_size = Vector2(1500.0, 650.0)
	graph_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_panel.add_child(graph_stack)
	_create_desktop_windows()

	var footer := HBoxContainer.new()
	root_box.add_child(footer)
	trace_caption_label = Label.new()
	trace_caption_label.text = _t(&"hardware.trace.empty")
	trace_caption_label.add_theme_color_override("font_color", MUTED)
	trace_caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(trace_caption_label)
	diagnostics_label = Label.new()
	diagnostics_label.text = _t(&"hardware.diagnostics.empty")
	diagnostics_label.add_theme_color_override("font_color", MUTED)
	footer.add_child(diagnostics_label)
	for data: Array in [[&"task", &"hardware.window.mission"], [&"test_bench", &"device.test_bench"]]:
		var window_button := Button.new()
		window_button.text = _t(StringName(data[1]))
		window_button.tooltip_text = _t(&"hardware.window.show.tooltip")
		window_button.pressed.connect(_show_desktop_window.bind(data[0]))
		desktop_window_buttons[data[0]] = window_button
		footer.add_child(window_button)


func _create_desktop_windows() -> void:
	var task_content: Control = _make_desktop_window_content(&"task")
	var test_bench_content: Control = _make_desktop_window_content(&"test_bench")
	_add_desktop_window(&"task", _t(&"hardware.window.mission"), task_content)
	_add_desktop_window(&"test_bench", _t(&"device.test_bench"), test_bench_content)


func _make_desktop_window_content(id: StringName) -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	if id == &"task":
		task_box = box
	else:
		side_box = box
	return scroll


func _add_desktop_window(id: StringName, title_text: String, content: Control) -> void:
	var window: FloatingInstrumentPanel = FloatingInstrumentPanelType.new()
	window.name = "%sWindow" % String(id).to_pascal_case()
	window.custom_minimum_size = Vector2(285.0, 180.0)
	window.add_theme_stylebox_override("panel", _stylebox(Color("111a2a"), 12, 2, ACCENT if id == &"test_bench" else PURPLE))
	graph_stack.add_child(window)
	window.setup(id, title_text)
	window.set_content(content)
	window.z_index = 100
	window.close_requested.connect(_close_desktop_window)
	window.focus_requested.connect(_focus_desktop_window)
	window.minimized_changed.connect(_on_desktop_window_minimized)
	desktop_windows[id] = window


func _layout_desktop_windows() -> void:
	var task_window: FloatingInstrumentPanel = desktop_windows[&"task"]
	var bench_window: FloatingInstrumentPanel = desktop_windows[&"test_bench"]
	for window: FloatingInstrumentPanel in [task_window, bench_window]:
		window.show_instrument()
		window.set_minimized(false)
	match current_phase:
		&"tutorial":
			task_window.position = Vector2(18.0, 18.0)
			task_window.size = Vector2(335.0, 340.0)
			bench_window.position = Vector2(18.0, 372.0)
			bench_window.size = Vector2(335.0, 275.0)
		&"half_adder":
			task_window.position = Vector2(18.0, 18.0)
			task_window.size = Vector2(345.0, 245.0)
			bench_window.position = Vector2(18.0, 278.0)
			bench_window.size = Vector2(355.0, 370.0)
		&"sealed":
			task_window.position = Vector2(18.0, 18.0)
			task_window.size = Vector2(350.0, 350.0)
			bench_window.position = Vector2(18.0, 383.0)
			bench_window.size = Vector2(350.0, 265.0)
		&"campaign":
			task_window.position = Vector2(18.0, 18.0)
			task_window.size = Vector2(365.0, 430.0)
			bench_window.position = Vector2(18.0, 462.0)
			bench_window.size = Vector2(365.0, 185.0)
		&"prologue", &"prologue_complete":
			task_window.position = Vector2(18.0, 18.0)
			task_window.size = Vector2(360.0, 285.0)
			bench_window.position = Vector2(18.0, 317.0)
			bench_window.size = Vector2(370.0, 330.0)
	_focus_desktop_window(&"test_bench")


func _show_desktop_window(id: StringName) -> void:
	var window: FloatingInstrumentPanel = desktop_windows.get(id)
	if window == null:
		return
	window.show_instrument()
	window.set_minimized(false)
	_focus_desktop_window(id)


func _close_desktop_window(id: StringName) -> void:
	var window: FloatingInstrumentPanel = desktop_windows.get(id)
	if window != null:
		window.hide()
	var button: Button = desktop_window_buttons.get(id)
	if button != null:
		button.text = _t(&"common.open_named", [_desktop_window_name(id)])


func _focus_desktop_window(id: StringName) -> void:
	var window: FloatingInstrumentPanel = desktop_windows.get(id)
	if window == null:
		return
	desktop_z_counter += 1
	window.z_index = desktop_z_counter
	var button: Button = desktop_window_buttons.get(id)
	if button != null:
		button.text = _desktop_window_name(id)


func _on_desktop_window_minimized(id: StringName, minimized: bool) -> void:
	var button: Button = desktop_window_buttons.get(id)
	if button != null:
		button.text = ("□ " if minimized else "") + _desktop_window_name(id)


func _build_header() -> Control:
	var header := PanelContainer.new()
	header.custom_minimum_size.y = 74.0
	var row := HBoxContainer.new()
	header.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	var title := Label.new()
	title.text = _t(&"hardware.title")
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", ACCENT)
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = _t(&"hardware.subtitle")
	subtitle.add_theme_color_override("font_color", MUTED)
	title_box.add_child(subtitle)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	phase_label.add_theme_color_override("font_color", PURPLE)
	phase_label.add_theme_font_size_override("font_size", 18)
	row.add_child(phase_label)
	mode_selector = GameModeSelectorType.new()
	mode_selector.name = "GameModeSelector"
	mode_selector.show_label = false
	row.add_child(mode_selector)
	var hub_button := Button.new()
	hub_button.text = _t(&"common.prototype_hub")
	hub_button.tooltip_text = _t(&"hardware.hub.tooltip")
	hub_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn"))
	row.add_child(hub_button)
	return header


func _build_toolbar() -> Control:
	var toolbar := PanelContainer.new()
	var row := HBoxContainer.new()
	toolbar.add_child(row)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_color_override("font_color", MUTED)
	row.add_child(status_label)
	component_menu_button = MenuButton.new()
	component_menu_button.text = _t(&"hardware.component_menu.button")
	component_menu_button.tooltip_text = _t(&"hardware.component_menu.tooltip")
	component_menu_button.get_popup().id_pressed.connect(_on_component_menu_item_pressed)
	row.add_child(component_menu_button)
	for data: Array in [
		[&"hardware.toolbar.level_map", &"hardware.toolbar.level_map.tooltip", Callable(self, "_open_campaign_map")],
		[&"common.auto_layout", &"hardware.toolbar.auto_layout.tooltip", Callable(self, "_auto_layout")],
		[&"hardware.toolbar.undo_wire", &"hardware.toolbar.undo_wire.tooltip", Callable(self, "_undo_wire")],
		[&"hardware.toolbar.redo", &"hardware.toolbar.redo.tooltip", Callable(self, "_redo_edit")],
		[&"hardware.toolbar.clear_wires", &"hardware.toolbar.clear_wires.tooltip", Callable(self, "_clear_wires")],
		[&"hardware.toolbar.cancel_cable", &"hardware.toolbar.cancel_cable.tooltip", Callable(self, "_cancel_connection_drag")],
	]:
		var button := Button.new()
		button.text = _t(StringName(data[0]))
		button.tooltip_text = _t(StringName(data[1]))
		button.pressed.connect(data[2])
		row.add_child(button)
	pause_button = Button.new()
	pause_button.text = _t(&"hardware.trace.pause")
	pause_button.pressed.connect(_toggle_playback)
	row.add_child(pause_button)
	var step_button := Button.new()
	step_button.text = _t(&"common.step")
	step_button.pressed.connect(_step_playback)
	row.add_child(step_button)
	speed_selector = OptionButton.new()
	speed_selector.add_item("0.7×", 0)
	speed_selector.add_item("1.0×", 1)
	speed_selector.add_item("1.7×", 2)
	speed_selector.select(1)
	speed_selector.item_selected.connect(_on_speed_selected)
	row.add_child(speed_selector)
	return toolbar


func _show_tutorial() -> void:
	_stop_playback()
	current_phase = &"tutorial"
	current_level_id = &"tutorial"
	current_level_definition.clear()
	phase_label.text = _t(&"hardware.phase.tutorial")
	official_passed = false
	passing_topology_signature = ""
	_build_tutorial_circuit()
	_create_graph()
	_build_component_nodes()
	_build_tutorial_side()
	status_label.text = _t(&"hardware.tutorial.status")
	trace_caption_label.text = _t(&"hardware.tutorial.trace_hint")
	diagnostics_label.text = _t(&"hardware.tutorial.zero_delay")
	_update_tutorial_checklist()
	_schedule_live_refresh()
	call_deferred("_restore_graph_view_after_layout")


func _start_challenge() -> void:
	if not _is_level_unlocked(&"half_adder"):
		status_label.text = _t(&"hardware.prologue.map.locked")
		status_label.add_theme_color_override("font_color", BAD)
		return
	_stop_playback()
	current_phase = &"half_adder"
	current_level_id = &"half_adder"
	current_level_definition.clear()
	phase_label.text = _t(&"hardware.phase.half_adder")
	official_passed = false
	passing_topology_signature = ""
	official_report = {}
	_build_half_adder_circuit()
	_create_graph()
	_build_component_nodes()
	_build_half_adder_side()
	status_label.text = _t(&"hardware.challenge.status")
	trace_caption_label.text = _t(&"hardware.challenge.trace_note")
	diagnostics_label.text = _t(&"hardware.challenge.diagnostics")
	_schedule_live_refresh()
	call_deferred("_restore_graph_view_after_layout")


func _build_tutorial_circuit() -> void:
	current_circuit = LogicCircuitType.new()
	component_catalog.clear()
	junction_counter = 0
	layout_positions = {
		&"A_IN": Vector2(390, 95), &"B_IN": Vector2(390, 360),
		&"AND_1": Vector2(630, 55), &"OR_1": Vector2(630, 330),
		&"NOT_1": Vector2(875, 115), &"LAMP": Vector2(1110, 190),
	}
	for component: LogicComponent in [
		LogicComponentType.new(&"A_IN", &"input", "TEST INPUT A", &"A", true),
		LogicComponentType.new(&"B_IN", &"input", "TEST INPUT B", &"B", true),
		LogicComponentType.new(&"AND_1", &"and", "AND"),
		LogicComponentType.new(&"OR_1", &"or", "OR"),
		LogicComponentType.new(&"NOT_1", &"not", "NOT"),
		LogicComponentType.new(&"LAMP", &"lamp", "OUTPUT LAMP", &"LAMP", true),
	]:
		_add_catalog_component(component)


func _build_half_adder_circuit() -> void:
	current_circuit = LogicCircuitType.new()
	component_catalog.clear()
	junction_counter = 0
	layout_positions = {
		&"A_IN": Vector2(390, 110), &"B_IN": Vector2(390, 425),
		&"AND_1": Vector2(615, 20), &"OR_1": Vector2(615, 245), &"AND_3": Vector2(615, 455),
		&"NOT_1": Vector2(845, 75), &"OR_2": Vector2(845, 350),
		&"AND_2": Vector2(1070, 150), &"NOT_2": Vector2(1070, 430),
		&"SUM_OUT": Vector2(1295, 150), &"CARRY_OUT": Vector2(1295, 455),
	}
	for component: LogicComponent in [
		LogicComponentType.new(&"A_IN", &"input", "TEST BENCH A", &"A", true),
		LogicComponentType.new(&"B_IN", &"input", "TEST BENCH B", &"B", true),
		LogicComponentType.new(&"AND_1", &"and", "AND · 1"),
		LogicComponentType.new(&"AND_2", &"and", "AND · 2"),
		LogicComponentType.new(&"AND_3", &"and", "AND · 3"),
		LogicComponentType.new(&"OR_1", &"or", "OR · 1"),
		LogicComponentType.new(&"OR_2", &"or", "OR · 2"),
		LogicComponentType.new(&"NOT_1", &"not", "NOT · 1"),
		LogicComponentType.new(&"NOT_2", &"not", "NOT · 2"),
		LogicComponentType.new(&"SUM_OUT", &"output", "PROBE SUM", &"SUM", true),
		LogicComponentType.new(&"CARRY_OUT", &"output", "PROBE CARRY", &"CARRY", true),
	]:
		_add_catalog_component(component)


func _add_catalog_component(component: LogicComponent) -> void:
	component_catalog[component.id] = component
	current_circuit.add_component(component.duplicate_component())


func _create_graph() -> void:
	_stop_playback()
	_cancel_component_placement(false)
	_capture_component_menu_templates()
	active_erase_action.clear()
	live_refresh_queued = false
	live_state = null
	live_state_key = ""
	if campaign_map_view != null and is_instance_valid(campaign_map_view):
		campaign_map_view.hide()
		graph_stack.remove_child(campaign_map_view)
		campaign_map_view.queue_free()
		campaign_map_view = null
	if graph != null:
		graph_stack.remove_child(graph)
		graph.free()
	if trace_overlay != null:
		graph_stack.remove_child(trace_overlay)
		trace_overlay.free()
	graph = CircuitGraphEditType.new()
	graph.name = "CircuitGraph"
	graph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph.grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	graph.snapping_enabled = true
	graph.snapping_distance = 20
	graph.minimap_enabled = false
	graph.show_arrange_button = false
	graph.show_grid_buttons = false
	graph.show_minimap_button = false
	graph.show_zoom_buttons = true
	graph.show_zoom_label = false
	graph.show_menu = false
	graph.right_disconnects = false
	graph.connection_lines_antialiased = true
	graph.connection_lines_thickness = 9.0
	graph.connection_lines_curvature = 0.48
	graph.add_valid_connection_type(PORT_TYPE, PORT_TYPE)
	graph.connection_validator = Callable(self, "_is_hover_connection_valid")
	graph.connection_request.connect(_on_connection_request)
	graph.disconnection_request.connect(_on_disconnection_request)
	graph.connection_to_empty.connect(_on_connection_to_empty)
	graph.connection_from_empty.connect(_on_connection_from_empty)
	graph.connection_drag_started.connect(_on_connection_drag_started)
	graph.connection_drag_ended.connect(_on_connection_drag_ended)
	graph.branch_connection_requested.connect(_on_branch_connection_requested)
	graph.branch_waypoint_requested.connect(_on_branch_waypoint_requested)
	graph.branch_drag_state_changed.connect(_on_branch_drag_state_changed)
	graph.erase_stroke_started.connect(_on_erase_stroke_started)
	graph.erase_component_requested.connect(_on_erase_component_requested)
	graph.erase_wire_requested.connect(_on_erase_wire_requested)
	graph.erase_stroke_finished.connect(_on_erase_stroke_finished)
	graph.connection_endpoint_move_requested.connect(_on_connection_endpoint_move_requested)
	graph.connection_endpoint_move_to_empty_requested.connect(_on_connection_endpoint_move_to_empty_requested)
	graph.connection_endpoint_move_to_wire_requested.connect(_on_connection_endpoint_move_to_wire_requested)
	graph.connection_endpoint_move_state_changed.connect(_on_connection_endpoint_move_state_changed)
	graph.selection_rectangle_applied.connect(_on_selection_rectangle_applied)
	graph.empty_canvas_pressed.connect(_on_empty_canvas_pressed)
	graph.delete_nodes_request.connect(_on_delete_nodes_request)
	graph.node_selected.connect(_on_graph_node_selection_changed)
	graph.node_deselected.connect(_on_graph_node_selection_changed)
	graph.begin_node_move.connect(_on_begin_node_move)
	graph.end_node_move.connect(_on_end_node_move)
	graph.gui_input.connect(_on_graph_gui_input)
	graph_stack.add_child(graph)
	graph_stack.move_child(graph, 0)

	trace_overlay = CircuitTraceOverlayType.new()
	trace_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trace_overlay.z_index = 40
	graph_stack.add_child(trace_overlay)
	if encapsulation_effect == null:
		encapsulation_effect = EncapsulationEffectType.new()
		encapsulation_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		encapsulation_effect.z_index = 300
		graph_stack.add_child(encapsulation_effect)
	component_nodes.clear()
	component_symbols.clear()
	component_row_labels.clear()
	component_state_labels.clear()
	component_idle_state_text.clear()
	wire_history.clear()
	redo_history.clear()
	node_move_start_positions.clear()
	clipboard_components.clear()
	clipboard_wires.clear()
	clipboard_paste_count = 0
	pasted_component_counter = 0
	placed_component_counter = 0
	armed_component_template_key = ""
	_rebuild_component_menu()


func _build_component_nodes() -> void:
	var ids: Array[StringName] = []
	for component_id: StringName in component_catalog:
		ids.append(component_id)
	ids.sort()
	for component_id: StringName in ids:
		_add_component_node(component_catalog[component_id], layout_positions[component_id])
	graph.scroll_offset = Vector2.ZERO
	graph.call_deferred("set_scroll_offset", Vector2.ZERO)


func _capture_component_menu_templates() -> void:
	component_menu_templates.clear()
	component_menu_template_keys.clear()
	var component_ids: Array[StringName] = []
	for component_id: StringName in component_catalog:
		component_ids.append(component_id)
	component_ids.sort()
	for component_id: StringName in component_ids:
		var component: LogicComponent = component_catalog[component_id]
		if component.fixed_terminal or component.is_routing_node():
			continue
		var key: String = _component_template_signature(component)
		if component_menu_templates.has(key):
			continue
		var template: LogicComponent = component.duplicate_component()
		template.fixed_terminal = false
		template.signal_name = &""
		if template.is_basic_gate():
			template.display_name = String(template.kind).to_upper()
		component_menu_templates[key] = template
		component_menu_template_keys.append(key)
	# Keep the authoritative menu order independent from the active translation.
	# The signature contains only the electrical specification, never localized text.
	component_menu_template_keys.sort()


func _component_template_signature(component: LogicComponent) -> String:
	var specification: Dictionary = component.to_dictionary()
	for identity_field: String in ["id", "display_name", "signal_name", "fixed_terminal"]:
		specification.erase(identity_field)
	return JSON.stringify(specification)


func _rebuild_component_menu() -> void:
	if component_menu_button == null:
		return
	var popup: PopupMenu = component_menu_button.get_popup()
	popup.clear()
	component_menu_button.text = _t(&"hardware.component_menu.button")
	var placement_allowed: bool = (
		graph != null
		and not _editor_locked()
		and graph.branch_edit_enabled
		and not bool(current_level_definition.get("locked_topology", false))
		and not component_menu_template_keys.is_empty()
	)
	component_menu_button.disabled = not placement_allowed
	if not placement_allowed:
		popup.add_item(_t(&"hardware.component_menu.unavailable"), 0)
		popup.set_item_disabled(0, true)
		return
	for item_index: int in range(component_menu_template_keys.size()):
		var key: String = component_menu_template_keys[item_index]
		var template: LogicComponent = component_menu_templates[key]
		popup.add_item(_component_menu_label(template), item_index)
		popup.set_item_metadata(item_index, key)
		popup.set_item_as_radio_checkable(item_index, true)
	_refresh_component_menu_checks()


func _component_menu_label(component: LogicComponent) -> String:
	var label: String = String(component.kind).to_upper() if component.is_basic_gate() else _component_display_name(component)
	var widest_port: int = 1
	for width: int in component.input_port_widths:
		widest_port = maxi(widest_port, width)
	for width: int in component.output_port_widths:
		widest_port = maxi(widest_port, width)
	if widest_port > 1:
		label += "  ×%d" % widest_port
	return label


func _on_component_menu_item_pressed(item_id: int) -> void:
	if component_menu_button == null or _editor_locked():
		return
	var popup: PopupMenu = component_menu_button.get_popup()
	var item_index: int = popup.get_item_index(item_id)
	if item_index < 0:
		return
	var metadata: Variant = popup.get_item_metadata(item_index)
	var key: String = String(metadata) if metadata != null else ""
	if key.is_empty() or not component_menu_templates.has(key):
		return
	if armed_component_template_key == key:
		_cancel_component_placement()
		return
	armed_component_template_key = key
	var template: LogicComponent = component_menu_templates[key]
	component_menu_button.text = _t(&"hardware.component_menu.armed", [_component_menu_label(template)])
	graph.set_component_placement_preview(true, _component_menu_label(template), _component_node_size(template))
	_refresh_component_menu_checks()
	status_label.text = _t(&"hardware.status.component_placement_armed", [_component_menu_label(template)])
	status_label.add_theme_color_override("font_color", ACCENT)


func _refresh_component_menu_checks() -> void:
	if component_menu_button == null:
		return
	var popup: PopupMenu = component_menu_button.get_popup()
	for item_index: int in range(popup.item_count):
		var metadata: Variant = popup.get_item_metadata(item_index)
		popup.set_item_checked(
			item_index,
			metadata != null and String(metadata) == armed_component_template_key
		)


func _cancel_component_placement(update_status: bool = true) -> void:
	var was_armed: bool = not armed_component_template_key.is_empty()
	armed_component_template_key = ""
	if graph != null and is_instance_valid(graph):
		graph.set_component_placement_preview(false)
	if component_menu_button != null:
		component_menu_button.text = _t(&"hardware.component_menu.button")
		_refresh_component_menu_checks()
	if was_armed and update_status and status_label != null:
		status_label.text = _t(&"hardware.status.component_placement_cancelled")
		status_label.add_theme_color_override("font_color", MUTED)


func _on_empty_canvas_pressed(local_position: Vector2) -> void:
	if armed_component_template_key.is_empty() or _editor_locked():
		return
	var template: LogicComponent = component_menu_templates.get(armed_component_template_key)
	if template == null:
		_cancel_component_placement()
		return
	var placed: LogicComponent = template.duplicate_component()
	placed.id = _next_placed_component_id(template)
	placed.fixed_terminal = false
	placed.signal_name = &""
	var placement_position: Vector2 = _graph_position_from_local(
		local_position, _component_node_size(placed) * 0.5
	)
	if graph.snapping_enabled:
		var snap_distance: float = float(graph.snapping_distance)
		placement_position = Vector2(
			snappedf(placement_position.x, snap_distance),
			snappedf(placement_position.y, snap_distance)
		)
	var previous_selection: Array[StringName] = _selected_node_ids(false)
	if not current_circuit.add_component(placed.duplicate_component()):
		status_label.text = _t(&"hardware.status.component_placement_failed")
		status_label.add_theme_color_override("font_color", BAD)
		return
	component_catalog[placed.id] = placed
	layout_positions[placed.id] = placement_position
	_add_component_node(placed, placement_position)
	var placed_ids: Array[StringName] = [placed.id]
	_set_selected_ids(placed_ids)
	_push_history_action({
		"kind": &"place_component",
		"added": [],
		"removed": [],
		"added_components": [{"component": placed, "position": placement_position}],
		"selection_before": previous_selection,
		"selection_after": placed_ids,
	})
	_topology_changed(
		_t(&"hardware.status.component_placed", [_component_menu_label(placed)]),
		false,
		false
	)
	status_label.add_theme_color_override("font_color", GOOD)


func _next_placed_component_id(template: LogicComponent) -> StringName:
	var base_name: String = String(template.kind).to_upper()
	if base_name.is_empty():
		base_name = "COMPONENT"
	while true:
		placed_component_counter += 1
		var candidate := StringName("%s_NEW_%03d" % [base_name, placed_component_counter])
		if not component_catalog.has(candidate):
			return candidate
	return &""


func _add_component_node(component: LogicComponent, position: Vector2) -> void:
	var node := GraphNode.new()
	node.name = component.id
	node.title = ""
	node.draggable = true
	node.resizable = false
	node.z_index = 2
	node.custom_minimum_size = _component_node_size(component)
	node.tooltip_text = _component_tooltip(component)
	node.add_theme_font_size_override("title_font_size", 1)
	node.add_theme_constant_override("separation", 0)
	graph.add_child(node)
	node.position_offset = position
	if node.has_signal("position_offset_changed"):
		node.position_offset_changed.connect(graph.queue_signal_wire_redraw)
	node.get_titlebar_hbox().hide()
	_add_schematic_slots(node, component)
	node.gui_input.connect(_on_component_gui_input.bind(component.id))
	if component.is_routing_node():
		component_nodes[component.id] = node
		_set_node_style(component.id, ACCENT, false)
		return
	component_nodes[component.id] = node
	_set_node_style(component.id, PURPLE if component.fixed_terminal else MUTED, false)


func _component_node_size(component: LogicComponent) -> Vector2:
	match component.kind:
		LogicComponentType.KIND_JUNCTION:
			return Vector2(62.0, 34.0)
		LogicComponentType.KIND_AND, LogicComponentType.KIND_OR, LogicComponentType.KIND_NOR:
			return Vector2(124.0, 78.0)
		LogicComponentType.KIND_NOT:
			return Vector2(96.0, 48.0)
		LogicComponentType.KIND_INPUT, LogicComponentType.KIND_OUTPUT, LogicComponentType.KIND_LAMP:
			return Vector2(116.0, 62.0)
		LogicComponentType.KIND_CONSTANT:
			return Vector2(92.0, 56.0)
		_:
			var row_count: int = maxi(1, maxi(component.input_count(), component.output_count()))
			var state_height: float = 26.0 if component.is_stateful() else 0.0
			return Vector2(220.0, maxf(64.0, float(row_count) * 31.0 + 16.0 + state_height))


func _add_schematic_slots(node: GraphNode, component: LogicComponent) -> void:
	var height: float = 50.0
	var row_height: float = 50.0
	if component.kind in [LogicComponentType.KIND_AND, LogicComponentType.KIND_OR, LogicComponentType.KIND_NOR]:
		height = 66.0
		row_height = 22.0
	elif component.kind == LogicComponentType.KIND_NOT:
		height = 36.0
		row_height = 36.0
	elif component.kind == LogicComponentType.KIND_JUNCTION:
		height = 28.0
		row_height = 28.0
	var symbol := CircuitComponentSymbolType.new()
	symbol.custom_minimum_size = Vector2(_component_node_size(component).x - 14.0, row_height)
	symbol.configure(component.kind, String(component.signal_name), height)
	node.add_child(symbol)
	component_symbols[component.id] = symbol
	var neutral: Color = SIGNAL_LOW
	match component.kind:
		LogicComponentType.KIND_AND, LogicComponentType.KIND_OR, LogicComponentType.KIND_NOR:
			node.set_slot(0, true, PORT_TYPE, neutral, false, PORT_TYPE, neutral, null, null, false)
			_add_empty_schematic_row(node, row_height)
			node.set_slot(1, false, PORT_TYPE, neutral, true, PORT_TYPE, neutral, null, null, false)
			_add_empty_schematic_row(node, row_height)
			node.set_slot(2, true, PORT_TYPE, neutral, false, PORT_TYPE, neutral, null, null, false)
		LogicComponentType.KIND_INPUT:
			node.set_slot(0, false, PORT_TYPE, neutral, true, PORT_TYPE, neutral, null, null, false)
		LogicComponentType.KIND_OUTPUT, LogicComponentType.KIND_LAMP:
			node.set_slot(0, true, PORT_TYPE, neutral, false, PORT_TYPE, neutral, null, null, false)
		LogicComponentType.KIND_NOT, LogicComponentType.KIND_JUNCTION:
			node.set_slot(0, true, PORT_TYPE, neutral, true, PORT_TYPE, neutral, null, null, false)
		LogicComponentType.KIND_CONSTANT:
			node.set_slot(0, false, PORT_TYPE, neutral, true, PORT_TYPE, neutral, null, null, false)
		_:
			node.remove_child(symbol)
			symbol.free()
			component_symbols.erase(component.id)
			_add_generic_component_slots(node, component)


func _add_generic_component_slots(node: GraphNode, component: LogicComponent) -> void:
	var row_count: int = maxi(1, maxi(component.input_count(), component.output_count()))
	var row_labels: Array = []
	for row_index: int in range(row_count):
		var has_input: bool = row_index < component.input_count()
		var has_output: bool = row_index < component.output_count()
		var left_text: String = ""
		var right_text: String = ""
		if has_input:
			left_text = String(component.input_port_name(row_index))
		if has_output:
			right_text = String(component.output_port_name(row_index))
		var row := CircuitModuleRowType.new()
		row.custom_minimum_size.y = 30.0
		row.configure(
			component.kind, component.display_name, left_text, right_text,
			row_index, row_count, has_input, has_output,
			component.input_width(row_index) if has_input else 1,
			component.output_width(row_index) if has_output else 1
		)
		node.add_child(row)
		node.set_slot(
			row_index, has_input, PORT_TYPE, SIGNAL_LOW,
			has_output, PORT_TYPE, SIGNAL_HIGH_Z
		)
		row_labels.append(row)
	component_row_labels[component.id] = row_labels
	if component.is_stateful():
		var state_label := Label.new()
		state_label.text = _component_default_state_text(component)
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state_label.custom_minimum_size.y = 24.0
		state_label.add_theme_font_size_override("font_size", 12)
		state_label.add_theme_color_override("font_color", PURPLE)
		state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(state_label)
		component_state_labels[component.id] = state_label
		component_idle_state_text[component.id] = state_label.text


func _component_default_state_text(component: LogicComponent) -> String:
	match component.kind:
		LogicComponentType.KIND_SR_LATCH:
			return _t(&"hardware.storage.component.latch", ["0", "1"])
		LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4:
			return _t(&"hardware.storage.component.register", [
				DigitalValueType.known(component.output_width(0), 0).display_text()
			])
		LogicComponentType.KIND_RAM2X4:
			return _t(&"hardware.storage.component.ram", ["0x0", "0x0"])
		LogicComponentType.KIND_TINY_COMPUTER:
			return _t(&"hardware.storage.component.computer", ["0x0", "0x0"])
	return _t(&"hardware.storage.component.uninitialized")


func _add_empty_schematic_row(node: GraphNode, row_height: float) -> void:
	var row := Control.new()
	row.custom_minimum_size = Vector2(_component_node_size(component_catalog[node.name]).x - 14.0, row_height)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(row)


func _add_port_row(
		node: GraphNode,
		slot_index: int,
		text: String,
		has_input: bool,
		has_output: bool,
		input_color: Color,
		output_color: Color,
		row_height: float = 24.0
	) -> void:
	var row := Label.new()
	row.text = text
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.custom_minimum_size.y = row_height
	row.add_theme_font_size_override("font_size", 13)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(row)
	node.set_slot(slot_index, has_input, PORT_TYPE, input_color, has_output, PORT_TYPE, output_color)


func _build_tutorial_side() -> void:
	_clear_container(side_box)
	_clear_container(task_box)
	task_box.add_child(_side_heading(_t(&"hardware.tutorial.heading"), _t(&"hardware.tutorial.heading_subtitle")))
	var prompt := Label.new()
	prompt.text = _t(&"hardware.tutorial.prompt")
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_color_override("font_color", TEXT)
	task_box.add_child(prompt)
	var checklist_title := Label.new()
	checklist_title.text = _t(&"hardware.tutorial.checklist_title")
	checklist_title.add_theme_color_override("font_color", ACCENT)
	task_box.add_child(checklist_title)
	tutorial_check_labels.clear()
	for data: Array in [
		[&"wire", &"hardware.tutorial.check.wire"], [&"input", &"hardware.tutorial.check.input"],
		[&"run", &"hardware.tutorial.check.run"], [&"remove", &"hardware.tutorial.check.remove"],
		[&"reconnect", &"hardware.tutorial.check.reconnect"],
	]:
		var label := Label.new()
		label.text = "○  " + _t(StringName(data[1]))
		label.add_theme_color_override("font_color", MUTED)
		tutorial_check_labels[data[0]] = label
		task_box.add_child(label)
	tutorial_next_button = Button.new()
	tutorial_next_button.text = _t(&"hardware.tutorial.begin_challenge")
	tutorial_next_button.disabled = true
	tutorial_next_button.pressed.connect(_start_challenge)
	task_box.add_child(tutorial_next_button)

	side_box.add_child(_side_heading(_t(&"hardware.practice.heading"), _t(&"hardware.practice.heading_subtitle")))
	_build_input_controls()
	var run_button := Button.new()
	run_button.text = _t(&"hardware.practice.run")
	run_button.pressed.connect(_run_debug)
	side_box.add_child(run_button)
	debug_result_label = Label.new()
	debug_result_label.text = _t(&"hardware.practice.lamp_empty")
	debug_result_label.add_theme_font_size_override("font_size", 20)
	debug_result_label.add_theme_color_override("font_color", MUTED)
	side_box.add_child(debug_result_label)
	_layout_desktop_windows()


func _build_half_adder_side() -> void:
	_clear_container(side_box)
	_clear_container(task_box)
	task_box.add_child(_side_heading(_t(&"hardware.challenge.heading"), _t(&"hardware.challenge.heading_subtitle")))
	var challenge := Label.new()
	challenge.text = _t(&"hardware.challenge.description")
	challenge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	challenge.add_theme_color_override("font_color", TEXT)
	task_box.add_child(challenge)
	var hint := Label.new()
	hint.text = _t(&"hardware.challenge.hint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	hint.add_theme_font_size_override("font_size", 13)
	task_box.add_child(hint)
	seal_button = Button.new()
	seal_button.text = _t(&"hardware.seal.button")
	seal_button.disabled = true
	seal_button.tooltip_text = _t(&"hardware.seal.tooltip")
	seal_button.pressed.connect(_seal_half_adder)
	task_box.add_child(seal_button)

	side_box.add_child(_side_heading(_t(&"hardware.cases.heading"), _t(&"hardware.cases.heading_subtitle")))
	_build_input_controls()
	var debug_button := Button.new()
	debug_button.text = _t(&"hardware.cases.run_debug")
	debug_button.pressed.connect(_run_debug)
	side_box.add_child(debug_button)
	debug_result_label = Label.new()
	debug_result_label.text = _t(&"hardware.cases.actual_empty")
	debug_result_label.add_theme_color_override("font_color", MUTED)
	side_box.add_child(debug_result_label)
	var official_button := Button.new()
	official_button.text = _t(&"hardware.cases.run_official")
	official_button.pressed.connect(_run_official)
	side_box.add_child(official_button)
	_build_official_case_rows()
	_layout_desktop_windows()


func _build_sealed_side() -> void:
	_clear_container(side_box)
	_clear_container(task_box)
	task_box.add_child(_side_heading(_t(&"hardware.sealed.library_heading"), _t(&"hardware.sealed.library_subtitle")))
	var created := Label.new()
	created.text = _t(&"hardware.sealed.created")
	created.add_theme_font_size_override("font_size", 28)
	created.add_theme_color_override("font_color", GOOD)
	task_box.add_child(created)
	var interface := Label.new()
	interface.text = _t(&"hardware.sealed.interface")
	interface.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interface.add_theme_color_override("font_color", TEXT)
	task_box.add_child(interface)
	var proof := Label.new()
	proof.text = _t(&"hardware.sealed.signature", [sealed_half_adder.source_signature.sha256_text().substr(0, 16).to_upper()])
	proof.add_theme_font_size_override("font_size", 13)
	proof.add_theme_color_override("font_color", PURPLE)
	task_box.add_child(proof)
	var continue_button := Button.new()
	continue_button.text = _t(&"hardware.prologue.open_map")
	continue_button.tooltip_text = _t(&"hardware.prologue.open_map.tooltip")
	continue_button.pressed.connect(_open_campaign_map)
	task_box.add_child(continue_button)

	side_box.add_child(_side_heading(_t(&"hardware.sealed.bench_heading"), _t(&"hardware.sealed.bench_subtitle")))
	_build_input_controls()
	var debug_button := Button.new()
	debug_button.text = _t(&"hardware.sealed.run_debug")
	debug_button.pressed.connect(_run_debug)
	side_box.add_child(debug_button)
	debug_result_label = Label.new()
	debug_result_label.text = _t(&"hardware.sealed.result_empty")
	debug_result_label.add_theme_color_override("font_color", MUTED)
	side_box.add_child(debug_result_label)
	var replay_button := Button.new()
	replay_button.text = _t(&"hardware.sealed.run_official")
	replay_button.pressed.connect(_run_sealed_official)
	side_box.add_child(replay_button)
	_layout_desktop_windows()


func _build_input_controls() -> void:
	var input_row := HBoxContainer.new()
	side_box.add_child(input_row)
	input_a_button = CheckButton.new()
	input_a_button.button_pressed = false
	input_a_button.toggled.connect(_on_test_input_toggled.bind(&"A"))
	input_row.add_child(input_a_button)
	input_b_button = CheckButton.new()
	input_b_button.button_pressed = false
	input_b_button.toggled.connect(_on_test_input_toggled.bind(&"B"))
	input_row.add_child(input_b_button)
	_update_input_button_text()


func _build_official_case_rows() -> void:
	official_case_labels.clear()
	for official_case: Dictionary in HalfAdderTestBenchType.OFFICIAL_CASES:
		var label := Label.new()
		label.text = _t(&"hardware.cases.row_not_run", [
			int(official_case["A"]), int(official_case["B"]),
			int(official_case["SUM"]), int(official_case["CARRY"]),
		])
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", MUTED)
		official_case_labels.append(label)
		side_box.add_child(label)


func _side_heading(title: String, subtitle: String) -> Control:
	var box := VBoxContainer.new()
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", PURPLE)
	box.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_color_override("font_color", MUTED)
	box.add_child(subtitle_label)
	return box


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if _editor_locked():
		return
	var diagnostic: Dictionary = current_circuit.connect_ports_detailed(from_node, from_port, to_node, to_port)
	if not diagnostic.is_empty():
		status_label.text = _t(&"hardware.status.invalid_connection", [Localization.text_from_spec(diagnostic)])
		status_label.add_theme_color_override("font_color", BAD)
		return
	graph.connect_node(from_node, from_port, to_node, to_port)
	_stop_playback()
	current_trace = null
	_mark_trace_stale()
	var wire: Dictionary = _wire_data(from_node, from_port, to_node, to_port)
	_push_history_action({"kind": &"connect", "added": [wire], "removed": [], "junction_id": &""})
	status_label.text = _t(&"hardware.status.connected", [from_node, to_node])
	status_label.add_theme_color_override("font_color", GOOD)
	if current_phase == &"tutorial":
		tutorial_created_wire = true
		if tutorial_removed_wire:
			tutorial_reconnected_wire = true
		_update_tutorial_checklist()
	else:
		_invalidate_official_evidence(_t(&"hardware.status.topology_changed"))


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if _editor_locked():
		return
	if current_circuit.disconnect_ports(from_node, from_port, to_node, to_port):
		graph.disconnect_node(from_node, from_port, to_node, to_port)
		var removed_wire: Dictionary = _wire_data(from_node, from_port, to_node, to_port)
		_push_history_action({"kind": &"disconnect", "added": [], "removed": [removed_wire]})
		_stop_playback()
		current_trace = null
		_mark_trace_stale()
		status_label.text = _t(&"hardware.status.wire_removed")
		status_label.add_theme_color_override("font_color", WARNING)
		if current_phase == &"tutorial":
			tutorial_removed_wire = true
			_update_tutorial_checklist()
		else:
			_invalidate_official_evidence(_t(&"hardware.status.topology_changed"))


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	if _editor_locked():
		return
	if not graph.get_closest_connection_at_point(release_position, 16.0).is_empty():
		status_label.text = _t(&"hardware.status.invalid_merge")
		status_label.add_theme_color_override("font_color", BAD)
		return
	_create_waypoint_from_output(from_node, from_port, release_position)


func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	if _editor_locked():
		return
	var connection: Dictionary = graph.get_closest_connection_at_point(release_position, 18.0)
	if connection.is_empty():
		_create_waypoint_to_input(to_node, to_port, release_position)
		return
	_create_branch_transaction(connection, release_position, to_node, to_port)


func _on_branch_connection_requested(
		connection: Dictionary,
		split_position: Vector2,
		to_node: StringName,
		to_port: int
	) -> void:
	_create_branch_transaction(connection, split_position, to_node, to_port)


func _on_branch_waypoint_requested(
		connection: Dictionary,
		split_position: Vector2,
		release_position: Vector2
	) -> void:
	_create_branch_waypoint_transaction(connection, split_position, release_position)


func _on_erase_stroke_started() -> void:
	if _editor_locked():
		return
	active_erase_action = {
		"kind": &"erase_stroke",
		"added": [],
		"removed": [],
		"removed_components": [],
		"prepared": false,
	}
	status_label.text = _t(&"hardware.status.erase_active")
	status_label.add_theme_color_override("font_color", WARNING)


func _on_erase_wire_requested(connection: Dictionary) -> void:
	if _editor_locked():
		return
	_ensure_erase_action()
	var wire: Dictionary = _wire_data(
		StringName(connection.get("from_node", &"")), int(connection.get("from_port", -1)),
		StringName(connection.get("to_node", &"")), int(connection.get("to_port", -1))
	)
	if not current_circuit.has_connection(wire["from_node"], wire["from_port"], wire["to_node"], wire["to_port"]):
		return
	_prepare_erase_mutation()
	if _remove_visible_wire(wire):
		_append_removed_wire(active_erase_action, wire)


func _on_erase_component_requested(component_id: StringName) -> void:
	if _editor_locked() or not component_catalog.has(component_id):
		return
	_ensure_erase_action()
	_prepare_erase_mutation()
	_delete_component_into_action(component_id, active_erase_action, true)


func _on_erase_stroke_finished() -> void:
	if active_erase_action.is_empty():
		return
	var removed_components: Array = active_erase_action.get("removed_components", [])
	var removed_wires: Array = active_erase_action.get("removed", [])
	if removed_components.is_empty() and removed_wires.is_empty():
		active_erase_action.clear()
		status_label.text = _t(&"hardware.status.erase_finished_empty")
		status_label.add_theme_color_override("font_color", MUTED)
		return
	active_erase_action.erase("prepared")
	_push_history_action(active_erase_action)
	active_erase_action = {}
	_topology_changed(
		_t(&"hardware.status.erase_finished", [removed_components.size(), removed_wires.size()]),
		false,
		true
	)


func _ensure_erase_action() -> void:
	if active_erase_action.is_empty():
		_on_erase_stroke_started()


func _prepare_erase_mutation() -> void:
	if bool(active_erase_action.get("prepared", false)):
		return
	active_erase_action["prepared"] = true
	_stop_playback()
	current_trace = null
	_mark_trace_stale()


func _on_connection_endpoint_move_requested(
		connection: Dictionary,
		to_node: StringName,
		to_port: int
	) -> void:
	_move_connection_endpoint(connection, to_node, to_port)


func _on_connection_endpoint_move_to_empty_requested(
		connection: Dictionary,
		release_position: Vector2
	) -> void:
	_move_connection_endpoint_to_empty(connection, release_position)


func _on_connection_endpoint_move_to_wire_requested(
		connection: Dictionary,
		target_connection: Dictionary,
		split_position: Vector2
	) -> void:
	_move_connection_endpoint_to_wire(connection, target_connection, split_position)


func _on_connection_endpoint_move_state_changed(active: bool) -> void:
	if not active:
		_reset_component_feedback()
		return
	status_label.text = _t(&"hardware.status.endpoint_move_active")
	status_label.add_theme_color_override("font_color", ACCENT)


func _on_branch_drag_state_changed(active: bool) -> void:
	if not active:
		_reset_component_feedback()
		return
	status_label.text = _t(&"hardware.status.branch_cable")
	status_label.add_theme_color_override("font_color", ACCENT)
	for component_id: StringName in component_nodes:
		var component: LogicComponent = component_catalog.get(component_id)
		if component != null:
			_set_node_style(component_id, GOOD if component.input_count() > 0 else Color(MUTED, 0.45), false)


func _create_waypoint_from_output(
		from_node: StringName,
		from_port: int,
		release_position: Vector2
	) -> bool:
	var junction_id: StringName = _next_junction_id()
	var junction: LogicComponent = _new_junction(junction_id, _component_output_width(from_node, from_port))
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	if not trial.add_component(junction.duplicate_component()):
		return false
	var diagnostic: Dictionary = trial.connect_ports_detailed(from_node, from_port, junction_id, 0)
	if not diagnostic.is_empty():
		status_label.text = _t(&"hardware.status.invalid_wire_node", [Localization.text_from_spec(diagnostic)])
		status_label.add_theme_color_override("font_color", BAD)
		return false
	_add_catalog_component(junction)
	var graph_position: Vector2 = _graph_position_from_local(release_position, Vector2(34.0, 24.0))
	layout_positions[junction_id] = graph_position
	_add_component_node(junction, graph_position)
	var added: Dictionary = _wire_data(from_node, from_port, junction_id, 0)
	_add_visible_wire(added)
	_push_history_action({"kind": &"waypoint", "added": [added], "removed": [], "junction_id": junction_id})
	_topology_changed(_t(&"hardware.status.wire_node_created"))
	return true


func _create_waypoint_to_input(
		to_node: StringName,
		to_port: int,
		release_position: Vector2
	) -> bool:
	var junction_id: StringName = _next_junction_id()
	var target_component: LogicComponent = component_catalog.get(to_node)
	var junction: LogicComponent = _new_junction(
		junction_id, target_component.input_width(to_port) if target_component != null else 1
	)
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	trial.add_component(junction.duplicate_component())
	var diagnostic: Dictionary = trial.connect_ports_detailed(junction_id, 0, to_node, to_port)
	if not diagnostic.is_empty():
		status_label.text = _t(&"hardware.status.invalid_wire_node", [Localization.text_from_spec(diagnostic)])
		status_label.add_theme_color_override("font_color", BAD)
		return false
	_add_catalog_component(junction)
	var graph_position: Vector2 = _graph_position_from_local(release_position, Vector2(31.0, 17.0))
	layout_positions[junction_id] = graph_position
	_add_component_node(junction, graph_position)
	var added: Dictionary = _wire_data(junction_id, 0, to_node, to_port)
	_add_visible_wire(added)
	_push_history_action({
		"kind": &"waypoint_to_input", "added": [added], "removed": [],
		"junction_ids": [junction_id],
	})
	_topology_changed(_t(&"hardware.status.backward_wire_node_created"))
	return true


func _create_branch_transaction(
		connection: Dictionary,
		split_position: Vector2,
		to_node: StringName,
		to_port: int
	) -> bool:
	if _editor_locked():
		return false
	var original: Dictionary = _wire_data(
		connection.get("from_node", &""), int(connection.get("from_port", -1)),
		connection.get("to_node", &""), int(connection.get("to_port", -1))
	)
	if not current_circuit.has_connection(original["from_node"], original["from_port"], original["to_node"], original["to_port"]):
		status_label.text = _t(&"hardware.status.branch_cancelled_changed")
		status_label.add_theme_color_override("font_color", WARNING)
		return false
	var junction_id: StringName = _next_junction_id()
	var junction: LogicComponent = _new_junction(
		junction_id, _component_output_width(original["from_node"], original["from_port"])
	)
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	trial.disconnect_ports(original["from_node"], original["from_port"], original["to_node"], original["to_port"])
	trial.add_component(junction.duplicate_component())
	var added: Array[Dictionary] = [
		_wire_data(original["from_node"], original["from_port"], junction_id, 0),
		_wire_data(junction_id, 0, original["to_node"], original["to_port"]),
		_wire_data(junction_id, 0, to_node, to_port),
	]
	for wire: Dictionary in added:
		var diagnostic: Dictionary = trial.connect_ports_detailed(wire["from_node"], wire["from_port"], wire["to_node"], wire["to_port"])
		if not diagnostic.is_empty():
			status_label.text = _t(&"hardware.status.invalid_branch", [Localization.text_from_spec(diagnostic)])
			status_label.add_theme_color_override("font_color", BAD)
			return false

	_remove_visible_wire(original)
	_add_catalog_component(junction)
	var graph_position: Vector2 = _graph_position_from_local(split_position, Vector2(34.0, 24.0))
	layout_positions[junction_id] = graph_position
	_add_component_node(junction, graph_position)
	for wire: Dictionary in added:
		_add_visible_wire(wire)
	_push_history_action({"kind": &"branch", "added": added, "removed": [original], "junction_id": junction_id})
	_topology_changed(_t(&"hardware.status.branch_created"))
	return true


func _create_branch_waypoint_transaction(
		connection: Dictionary,
		split_position: Vector2,
		release_position: Vector2
	) -> bool:
	if _editor_locked():
		return false
	var original: Dictionary = _wire_data(
		connection.get("from_node", &""), int(connection.get("from_port", -1)),
		connection.get("to_node", &""), int(connection.get("to_port", -1))
	)
	if not current_circuit.has_connection(original["from_node"], original["from_port"], original["to_node"], original["to_port"]):
		return false
	var split_id: StringName = _next_junction_id()
	var endpoint_id: StringName = _next_junction_id()
	var branch_width: int = _component_output_width(original["from_node"], original["from_port"])
	var split_junction: LogicComponent = _new_junction(split_id, branch_width)
	var endpoint_junction: LogicComponent = _new_junction(endpoint_id, branch_width)
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	trial.disconnect_ports(original["from_node"], original["from_port"], original["to_node"], original["to_port"])
	trial.add_component(split_junction.duplicate_component())
	trial.add_component(endpoint_junction.duplicate_component())
	var added: Array[Dictionary] = [
		_wire_data(original["from_node"], original["from_port"], split_id, 0),
		_wire_data(split_id, 0, original["to_node"], original["to_port"]),
		_wire_data(split_id, 0, endpoint_id, 0),
	]
	for wire: Dictionary in added:
		var diagnostic: Dictionary = trial.connect_ports_detailed(wire["from_node"], wire["from_port"], wire["to_node"], wire["to_port"])
		if not diagnostic.is_empty():
			status_label.text = _t(&"hardware.status.invalid_branch", [Localization.text_from_spec(diagnostic)])
			status_label.add_theme_color_override("font_color", BAD)
			return false
	_remove_visible_wire(original)
	_add_catalog_component(split_junction)
	_add_catalog_component(endpoint_junction)
	var split_graph_position: Vector2 = _graph_position_from_local(split_position, Vector2(31.0, 17.0))
	var endpoint_graph_position: Vector2 = _graph_position_from_local(release_position, Vector2(31.0, 17.0))
	layout_positions[split_id] = split_graph_position
	layout_positions[endpoint_id] = endpoint_graph_position
	_add_component_node(split_junction, split_graph_position)
	_add_component_node(endpoint_junction, endpoint_graph_position)
	for wire: Dictionary in added:
		_add_visible_wire(wire)
	_push_history_action({
		"kind": &"branch_waypoint", "added": added, "removed": [original],
		"junction_ids": [split_id, endpoint_id],
	})
	_topology_changed(_t(&"hardware.status.branch_waypoint_created"))
	return true


func _move_connection_endpoint(connection: Dictionary, to_node: StringName, to_port: int) -> bool:
	var original: Dictionary = _wire_data(
		connection.get("from_node", &""), int(connection.get("from_port", -1)),
		connection.get("to_node", &""), int(connection.get("to_port", -1))
	)
	if not current_circuit.has_connection(original["from_node"], original["from_port"], original["to_node"], original["to_port"]):
		return false
	var replacement: Dictionary = _wire_data(original["from_node"], original["from_port"], to_node, to_port)
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	trial.disconnect_ports(original["from_node"], original["from_port"], original["to_node"], original["to_port"])
	var diagnostic: Dictionary = trial.connect_ports_detailed(replacement["from_node"], replacement["from_port"], replacement["to_node"], replacement["to_port"])
	if not diagnostic.is_empty():
		status_label.text = _t(&"hardware.status.invalid_connection", [Localization.text_from_spec(diagnostic)])
		status_label.add_theme_color_override("font_color", BAD)
		return false
	_remove_visible_wire(original)
	_add_visible_wire(replacement)
	_push_history_action({"kind": &"move_endpoint", "added": [replacement], "removed": [original]})
	_topology_changed(_t(&"hardware.status.endpoint_moved"), false, true)
	return true


func _move_connection_endpoint_to_empty(connection: Dictionary, release_position: Vector2) -> bool:
	var original: Dictionary = _wire_data(
		connection.get("from_node", &""), int(connection.get("from_port", -1)),
		connection.get("to_node", &""), int(connection.get("to_port", -1))
	)
	if not current_circuit.has_connection(original["from_node"], original["from_port"], original["to_node"], original["to_port"]):
		return false
	var junction_id: StringName = _next_junction_id()
	var junction: LogicComponent = _new_junction(
		junction_id, _component_output_width(original["from_node"], original["from_port"])
	)
	var replacement: Dictionary = _wire_data(original["from_node"], original["from_port"], junction_id, 0)
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	trial.disconnect_ports(original["from_node"], original["from_port"], original["to_node"], original["to_port"])
	trial.add_component(junction.duplicate_component())
	var diagnostic: Dictionary = trial.connect_ports_detailed(replacement["from_node"], replacement["from_port"], replacement["to_node"], replacement["to_port"])
	if not diagnostic.is_empty():
		return false
	_remove_visible_wire(original)
	_add_catalog_component(junction)
	var graph_position: Vector2 = _graph_position_from_local(release_position, Vector2(31.0, 17.0))
	layout_positions[junction_id] = graph_position
	_add_component_node(junction, graph_position)
	_add_visible_wire(replacement)
	_push_history_action({
		"kind": &"move_endpoint_to_empty", "added": [replacement], "removed": [original],
		"junction_ids": [junction_id],
	})
	_topology_changed(_t(&"hardware.status.endpoint_moved_to_waypoint"), false, true)
	return true


func _move_connection_endpoint_to_wire(
		connection: Dictionary,
		target_connection: Dictionary,
		split_position: Vector2
	) -> bool:
	var original: Dictionary = _wire_data(
		connection.get("from_node", &""), int(connection.get("from_port", -1)),
		connection.get("to_node", &""), int(connection.get("to_port", -1))
	)
	var target: Dictionary = _wire_data(
		target_connection.get("from_node", &""), int(target_connection.get("from_port", -1)),
		target_connection.get("to_node", &""), int(target_connection.get("to_port", -1))
	)
	if not current_circuit.has_connection(original["from_node"], original["from_port"], original["to_node"], original["to_port"]):
		return false
	if not current_circuit.has_connection(target["from_node"], target["from_port"], target["to_node"], target["to_port"]):
		return false
	var junction_id: StringName = _next_junction_id()
	var junction: LogicComponent = _new_junction(
		junction_id, _component_output_width(target["from_node"], target["from_port"])
	)
	var added: Array[Dictionary] = [
		_wire_data(target["from_node"], target["from_port"], junction_id, 0),
		_wire_data(junction_id, 0, target["to_node"], target["to_port"]),
		_wire_data(junction_id, 0, original["to_node"], original["to_port"]),
	]
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	trial.disconnect_ports(original["from_node"], original["from_port"], original["to_node"], original["to_port"])
	trial.disconnect_ports(target["from_node"], target["from_port"], target["to_node"], target["to_port"])
	trial.add_component(junction.duplicate_component())
	for wire: Dictionary in added:
		var diagnostic: Dictionary = trial.connect_ports_detailed(wire["from_node"], wire["from_port"], wire["to_node"], wire["to_port"])
		if not diagnostic.is_empty():
			status_label.text = _t(&"hardware.status.invalid_branch", [Localization.text_from_spec(diagnostic)])
			status_label.add_theme_color_override("font_color", BAD)
			return false
	_remove_visible_wire(original)
	_remove_visible_wire(target)
	_add_catalog_component(junction)
	var graph_position: Vector2 = _graph_position_from_local(split_position, Vector2(31.0, 17.0))
	layout_positions[junction_id] = graph_position
	_add_component_node(junction, graph_position)
	for wire: Dictionary in added:
		_add_visible_wire(wire)
	_push_history_action({
		"kind": &"move_endpoint_to_wire", "added": added, "removed": [original, target],
		"junction_ids": [junction_id],
	})
	_topology_changed(_t(&"hardware.status.endpoint_moved_to_wire"), false, true)
	return true


func _is_hover_connection_valid(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> bool:
	if _editor_locked():
		return false
	return current_circuit.connection_error(from_node, from_port, to_node, to_port).is_empty()


func _on_connection_drag_started(from_node: StringName, from_port: int, is_output: bool) -> void:
	builtin_connection_drag_active = true
	graph.begin_builtin_connection_preview(from_node, from_port, is_output)
	status_label.text = _t(&"hardware.status.cable_active", [_t(&"hardware.port.input") if is_output else _t(&"hardware.port.output")])
	status_label.add_theme_color_override("font_color", ACCENT)


func _on_connection_drag_ended() -> void:
	builtin_connection_drag_active = false
	graph.end_builtin_connection_preview()
	_reset_component_feedback()
	status_label.text = _t(&"hardware.status.cable_released")
	status_label.add_theme_color_override("font_color", MUTED)


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_connection_drag()


func _handle_editor_shortcut(event: InputEvent) -> bool:
	if (
		_editor_locked()
		or not event is InputEventKey
		or not (event as InputEventKey).pressed
	):
		return false
	var key_event := event as InputEventKey
	if _keyboard_focus_accepts_text():
		return false
	if key_event.ctrl_pressed or key_event.meta_pressed:
		if key_event.echo:
			return false
		match key_event.keycode:
			KEY_Z:
				if key_event.shift_pressed:
					_redo_edit()
				else:
					_undo_wire()
				return true
			KEY_Y:
				_redo_edit()
				return true
			KEY_A:
				_select_all_nodes()
				return true
			KEY_X:
				_cut_selection()
				return true
			KEY_C:
				_copy_selection()
				return true
			KEY_V:
				_paste_selection()
				return true
		return false
	match key_event.keycode:
		KEY_ESCAPE:
			_cancel_connection_drag()
			return true
		KEY_W:
			_pan_graph_view(Vector2.UP)
			return true
		KEY_A:
			_pan_graph_view(Vector2.LEFT)
			return true
		KEY_S:
			_pan_graph_view(Vector2.DOWN)
			return true
		KEY_D:
			_pan_graph_view(Vector2.RIGHT)
			return true
		KEY_F4:
			_reset_current_simulation()
			return true
		KEY_F5:
			_step_playback()
			return true
		KEY_F6:
			_run_current_debug()
			return true
	return false


func _keyboard_focus_accepts_text() -> bool:
	if component_menu_button != null and component_menu_button.get_popup().visible:
		return true
	var focused: Control = get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit


func _pan_graph_view(direction: Vector2) -> void:
	if graph == null:
		return
	graph.scroll_offset += direction * 72.0
	graph.queue_signal_wire_redraw()
	status_label.text = _t(&"hardware.status.view_moved")
	status_label.add_theme_color_override("font_color", MUTED)


func _run_current_debug() -> void:
	match current_phase:
		&"tutorial", &"half_adder":
			_run_debug()
		&"prologue":
			_run_prologue_debug()
		&"sealed":
			_run_sealed_official()


func _reset_current_simulation() -> void:
	if current_phase == &"prologue" and _is_storage_level():
		_reset_storage_debug_state()
		return
	_stop_playback()
	current_trace = null
	if current_phase == &"prologue":
		prologue_runtime_state.clear()
		prologue_prior_outputs.clear()
		prologue_live_result = null
	live_state_key = ""
	_clear_signal_states()
	_schedule_live_refresh()
	status_label.text = _t(&"hardware.status.simulation_reset")
	status_label.add_theme_color_override("font_color", MUTED)


func _on_graph_node_selection_changed(_node: Node) -> void:
	_sync_selection_feedback()


func _on_selection_rectangle_applied(_changed_count: int, _selected_count: int) -> void:
	_sync_selection_feedback()
	_on_selection_count_changed()


func _sync_selection_feedback() -> void:
	for component_id: StringName in component_symbols:
		var symbol: CircuitComponentSymbol = component_symbols[component_id]
		var node: GraphNode = component_nodes.get(component_id)
		symbol.set_selection_active(node != null and node.selected)
	for component_id: StringName in component_row_labels:
		var node: GraphNode = component_nodes.get(component_id)
		var selected: bool = node != null and node.selected
		for row_variant: Variant in component_row_labels[component_id]:
			var row: Variant = row_variant
			if row != null:
				row.set_selection_active(selected)


func _on_selection_count_changed() -> void:
	var selected_count: int = _selected_node_ids(false).size()
	status_label.text = _t(&"hardware.status.selection_count", [selected_count])
	status_label.add_theme_color_override("font_color", ACCENT if selected_count > 0 else MUTED)


func _select_all_nodes() -> void:
	if graph == null or _editor_locked():
		return
	var all_ids: Array[StringName] = []
	for component_id: StringName in component_nodes:
		all_ids.append(component_id)
	all_ids.sort()
	_set_selected_ids(all_ids)
	status_label.text = _t(&"hardware.status.all_selected", [all_ids.size()])
	status_label.add_theme_color_override("font_color", ACCENT)


func _cut_selection() -> bool:
	if graph == null or _editor_locked():
		return false
	var selected_ids: Array[StringName] = _selected_node_ids(false)
	if not _copy_selection():
		return false
	var component_count_before: int = component_catalog.size()
	_on_delete_nodes_request(selected_ids)
	var removed_count: int = component_count_before - component_catalog.size()
	if removed_count <= 0:
		return false
	status_label.text = _t(&"hardware.status.selection_cut", [removed_count])
	status_label.add_theme_color_override("font_color", WARNING)
	return true


func _on_begin_node_move() -> void:
	if history_replaying or _editor_locked():
		return
	node_move_start_positions = _capture_node_positions()


func _on_end_node_move() -> void:
	if history_replaying or node_move_start_positions.is_empty():
		return
	var action: Dictionary = _position_action_from_snapshots(
		&"move_nodes", node_move_start_positions, _capture_node_positions()
	)
	node_move_start_positions.clear()
	if action.is_empty():
		return
	_push_history_action(action)
	status_label.text = _t(&"hardware.status.nodes_moved", [(action["positions_after"] as Dictionary).size()])
	status_label.add_theme_color_override("font_color", ACCENT)


func _copy_selection() -> bool:
	if graph == null or _editor_locked():
		return false
	var selected_ids: Array[StringName] = _selected_node_ids(true)
	if selected_ids.is_empty():
		status_label.text = _t(&"hardware.status.nothing_to_copy")
		status_label.add_theme_color_override("font_color", MUTED)
		return false
	clipboard_components.clear()
	clipboard_wires.clear()
	clipboard_paste_count = 0
	var selected_set: Dictionary[StringName, bool] = {}
	for component_id: StringName in selected_ids:
		selected_set[component_id] = true
		var component: LogicComponent = component_catalog[component_id]
		var node: GraphNode = component_nodes[component_id]
		clipboard_components.append({
			"component": component.duplicate_component(),
			"position": node.position_offset,
		})
	for connection: Dictionary in graph.get_connection_list():
		var from_node: StringName = connection.get("from_node", &"")
		var to_node: StringName = connection.get("to_node", &"")
		if selected_set.has(from_node) and selected_set.has(to_node):
			clipboard_wires.append(_wire_data(
				from_node, int(connection.get("from_port", -1)),
				to_node, int(connection.get("to_port", -1))
			))
	status_label.text = _t(&"hardware.status.selection_copied", [clipboard_components.size(), clipboard_wires.size()])
	status_label.add_theme_color_override("font_color", GOOD)
	return true


func _paste_selection() -> bool:
	if graph == null or _editor_locked():
		return false
	if clipboard_components.is_empty():
		status_label.text = _t(&"hardware.status.clipboard_empty")
		status_label.add_theme_color_override("font_color", MUTED)
		return false
	var previous_selection: Array[StringName] = _selected_node_ids(false)
	var id_map: Dictionary[StringName, StringName] = {}
	var added_entries: Array[Dictionary] = []
	var trial: LogicCircuit = current_circuit.duplicate_circuit()
	var offset: Vector2 = Vector2(42.0, 42.0) * float(clipboard_paste_count + 1)
	for entry: Dictionary in clipboard_components:
		var source: LogicComponent = entry.get("component")
		if source == null or source.fixed_terminal:
			continue
		var pasted: LogicComponent = source.duplicate_component()
		pasted.id = _next_pasted_component_id(source.id)
		pasted.signal_name = &""
		pasted.fixed_terminal = false
		if not trial.add_component(pasted.duplicate_component()):
			return false
		id_map[source.id] = pasted.id
		var source_position: Vector2 = entry.get("position", Vector2.ZERO)
		added_entries.append({
			"component": pasted,
			"position": source_position + offset,
		})
	var added_wires: Array[Dictionary] = []
	for wire: Dictionary in clipboard_wires:
		var old_from: StringName = wire.get("from_node", &"")
		var old_to: StringName = wire.get("to_node", &"")
		if not id_map.has(old_from) or not id_map.has(old_to):
			continue
		var mapped: Dictionary = _wire_data(
			id_map[old_from], int(wire.get("from_port", -1)),
			id_map[old_to], int(wire.get("to_port", -1))
		)
		var diagnostic: Dictionary = trial.connect_ports_detailed(
			mapped["from_node"], mapped["from_port"], mapped["to_node"], mapped["to_port"]
		)
		if not diagnostic.is_empty():
			status_label.text = _t(&"hardware.status.paste_failed", [Localization.text_from_spec(diagnostic)])
			status_label.add_theme_color_override("font_color", BAD)
			return false
		added_wires.append(mapped)
	if added_entries.is_empty():
		return false
	for entry: Dictionary in added_entries:
		var component: LogicComponent = entry["component"]
		var position: Vector2 = entry["position"]
		_add_catalog_component(component)
		layout_positions[component.id] = position
		_add_component_node(component, position)
	for wire: Dictionary in added_wires:
		_add_visible_wire(wire)
	clipboard_paste_count += 1
	var pasted_ids: Array[StringName] = []
	for entry: Dictionary in added_entries:
		pasted_ids.append((entry["component"] as LogicComponent).id)
	_set_selected_ids(pasted_ids)
	_push_history_action({
		"kind": &"paste", "added": added_wires, "removed": [],
		"added_components": added_entries,
		"selection_before": previous_selection,
		"selection_after": pasted_ids,
	})
	_topology_changed(_t(&"hardware.status.selection_pasted", [added_entries.size(), added_wires.size()]))
	return true


func _next_pasted_component_id(source_id: StringName) -> StringName:
	while true:
		pasted_component_counter += 1
		var candidate := StringName("%s_COPY_%03d" % [source_id, pasted_component_counter])
		if not component_catalog.has(candidate):
			return candidate
	return &""


func _selected_node_ids(copyable_only: bool) -> Array[StringName]:
	var ids: Array[StringName] = []
	for component_id: StringName in component_nodes:
		var node: GraphNode = component_nodes[component_id]
		var component: LogicComponent = component_catalog.get(component_id)
		if not node.selected or component == null:
			continue
		if copyable_only and component.fixed_terminal:
			continue
		ids.append(component_id)
	ids.sort()
	return ids


func _set_selected_ids(ids: Array[StringName]) -> void:
	var selected: Dictionary[StringName, bool] = {}
	for component_id: StringName in ids:
		selected[component_id] = true
	for component_id: StringName in component_nodes:
		(component_nodes[component_id] as GraphNode).selected = selected.has(component_id)
	_sync_selection_feedback()


func _select_component_with_connected_route_nodes(component_id: StringName, additive: bool = false) -> void:
	if graph == null or not component_catalog.has(component_id):
		return
	var selected: Dictionary[StringName, bool] = {}
	if additive:
		for selected_id: StringName in _selected_node_ids(false):
			selected[selected_id] = true
	selected[component_id] = true
	var visited: Dictionary[StringName, bool] = {component_id: true}
	var frontier: Array[StringName] = [component_id]
	while not frontier.is_empty():
		var current_id: StringName = frontier.pop_front()
		for connection: Dictionary in graph.get_connection_list():
			var neighbor: StringName = &""
			if StringName(connection.get("from_node", &"")) == current_id:
				neighbor = StringName(connection.get("to_node", &""))
			elif StringName(connection.get("to_node", &"")) == current_id:
				neighbor = StringName(connection.get("from_node", &""))
			if neighbor.is_empty() or visited.has(neighbor):
				continue
			var neighbor_component: LogicComponent = component_catalog.get(neighbor)
			if neighbor_component == null or not neighbor_component.is_routing_node():
				continue
			visited[neighbor] = true
			selected[neighbor] = true
			frontier.append(neighbor)
	var selected_ids: Array[StringName] = []
	for selected_id: StringName in selected:
		selected_ids.append(selected_id)
	selected_ids.sort()
	_set_selected_ids(selected_ids)
	status_label.text = _t(&"hardware.status.component_route_selected", [selected_ids.size()])
	status_label.add_theme_color_override("font_color", ACCENT)


func _local_point_hits_port(node: GraphNode, point: Vector2, radius: float) -> bool:
	for port: int in range(node.get_input_port_count()):
		if point.distance_to(node.get_input_port_position(port)) <= radius:
			return true
	for port: int in range(node.get_output_port_count()):
		if point.distance_to(node.get_output_port_position(port)) <= radius:
			return true
	return false


func _push_history_action(action: Dictionary) -> void:
	if history_replaying or action.is_empty():
		return
	var stored: Dictionary = action.duplicate(true)
	stored["added"] = _duplicate_wire_entries(action.get("added", []))
	stored["removed"] = _duplicate_wire_entries(action.get("removed", []))
	var added_components: Array[Dictionary] = _duplicate_component_entries(action.get("added_components", []))
	if added_components.is_empty():
		var added_ids: Dictionary[StringName, bool] = {}
		var legacy_id: StringName = action.get("junction_id", &"")
		if not legacy_id.is_empty():
			added_ids[legacy_id] = true
		for junction_variant: Variant in action.get("junction_ids", []):
			added_ids[StringName(junction_variant)] = true
		var sorted_ids: Array[StringName] = []
		for component_id: StringName in added_ids:
			sorted_ids.append(component_id)
		sorted_ids.sort()
		for component_id: StringName in sorted_ids:
			var component: LogicComponent = component_catalog.get(component_id)
			var node: GraphNode = component_nodes.get(component_id)
			if component == null:
				continue
			added_components.append({
				"component": component.duplicate_component(),
				"position": node.position_offset if node != null else layout_positions.get(component_id, Vector2.ZERO),
			})
	stored["added_components"] = added_components
	var removed_components: Array[Dictionary] = _duplicate_component_entries(action.get("removed_components", []))
	var legacy_removed: LogicComponent = action.get("removed_component")
	if removed_components.is_empty() and legacy_removed != null:
		removed_components.append({
			"component": legacy_removed.duplicate_component(),
			"position": action.get("removed_position", Vector2.ZERO),
		})
	stored["removed_components"] = removed_components
	stored["positions_before"] = (action.get("positions_before", {}) as Dictionary).duplicate()
	stored["positions_after"] = (action.get("positions_after", {}) as Dictionary).duplicate()
	if action.has("selection_before"):
		stored["selection_before"] = (action.get("selection_before", []) as Array).duplicate()
	else:
		stored.erase("selection_before")
	if action.has("selection_after"):
		stored["selection_after"] = (action.get("selection_after", []) as Array).duplicate()
	else:
		stored.erase("selection_after")
	wire_history.append(stored)
	redo_history.clear()


func _duplicate_wire_entries(source: Array) -> Array[Dictionary]:
	var copies: Array[Dictionary] = []
	for wire_variant: Variant in source:
		if wire_variant is Dictionary:
			copies.append((wire_variant as Dictionary).duplicate())
	return copies


func _duplicate_component_entries(source: Array) -> Array[Dictionary]:
	var copies: Array[Dictionary] = []
	for entry_variant: Variant in source:
		if not entry_variant is Dictionary:
			continue
		var entry := entry_variant as Dictionary
		var component: LogicComponent = entry.get("component")
		if component == null:
			continue
		copies.append({
			"component": component.duplicate_component(),
			"position": entry.get("position", Vector2.ZERO),
		})
	return copies


func _apply_history_action(action: Dictionary, forward: bool) -> bool:
	if graph == null:
		return false
	history_replaying = true
	var changed: bool = false
	var wires_to_remove: Array = action.get("removed", []) if forward else action.get("added", [])
	for wire: Dictionary in wires_to_remove:
		if current_circuit.has_connection(wire["from_node"], wire["from_port"], wire["to_node"], wire["to_port"]):
			changed = _remove_visible_wire(wire) or changed
	var components_to_remove: Array = action.get("removed_components", []) if forward else action.get("added_components", [])
	for entry: Dictionary in components_to_remove:
		var component: LogicComponent = entry.get("component")
		if component != null and component_catalog.has(component.id):
			changed = _remove_component_internal(component.id) or changed
	var components_to_restore: Array = action.get("added_components", []) if forward else action.get("removed_components", [])
	var sorted_restore: Array[Dictionary] = _duplicate_component_entries(components_to_restore)
	sorted_restore.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String((left["component"] as LogicComponent).id) < String((right["component"] as LogicComponent).id)
	)
	for entry: Dictionary in sorted_restore:
		var component: LogicComponent = entry["component"]
		if component_catalog.has(component.id):
			continue
		var position: Vector2 = entry.get("position", Vector2.ZERO)
		_add_catalog_component(component)
		layout_positions[component.id] = position
		_add_component_node(component, position)
		changed = true
	var wires_to_add: Array = action.get("added", []) if forward else action.get("removed", [])
	for wire: Dictionary in wires_to_add:
		if not current_circuit.has_connection(wire["from_node"], wire["from_port"], wire["to_node"], wire["to_port"]):
			changed = _add_visible_wire(wire) or changed
	var positions: Dictionary = action.get("positions_after", {}) if forward else action.get("positions_before", {})
	for component_variant: Variant in positions:
		var component_id := StringName(component_variant)
		var node: GraphNode = component_nodes.get(component_id)
		if node == null:
			continue
		var position: Vector2 = positions[component_variant]
		if node.position_offset.is_equal_approx(position):
			continue
		node.position_offset = position
		changed = true
	var selection_key: String = "selection_after" if forward else "selection_before"
	if action.has(selection_key):
		var selected_ids: Array[StringName] = []
		for id_variant: Variant in action.get(selection_key, []):
			selected_ids.append(StringName(id_variant))
		_set_selected_ids(selected_ids)
	history_replaying = false
	graph.queue_signal_wire_redraw()
	return changed


func _history_action_changes_topology(action: Dictionary) -> bool:
	return (
		not (action.get("added", []) as Array).is_empty()
		or not (action.get("removed", []) as Array).is_empty()
		or not (action.get("added_components", []) as Array).is_empty()
		or not (action.get("removed_components", []) as Array).is_empty()
	)


func _after_history_replay(action: Dictionary, message: String) -> void:
	if _history_action_changes_topology(action):
		_stop_playback()
		current_trace = null
		_mark_trace_stale()
		if current_phase in [&"half_adder", &"prologue"]:
			_invalidate_official_evidence(message)
		else:
			status_label.text = message
			status_label.add_theme_color_override("font_color", ACCENT)
	else:
		status_label.text = message
		status_label.add_theme_color_override("font_color", ACCENT)
	_sync_selection_feedback()


func _capture_node_positions() -> Dictionary:
	var positions: Dictionary = {}
	var ids: Array[StringName] = []
	for component_id: StringName in component_nodes:
		ids.append(component_id)
	ids.sort()
	for component_id: StringName in ids:
		positions[component_id] = (component_nodes[component_id] as GraphNode).position_offset
	return positions


func _position_action_from_snapshots(kind: StringName, before: Dictionary, after: Dictionary) -> Dictionary:
	var changed_before: Dictionary = {}
	var changed_after: Dictionary = {}
	var ids: Array[StringName] = []
	for component_variant: Variant in before:
		var component_id := StringName(component_variant)
		if after.has(component_id):
			ids.append(component_id)
	ids.sort()
	for component_id: StringName in ids:
		var old_position: Vector2 = before[component_id]
		var new_position: Vector2 = after[component_id]
		if old_position.is_equal_approx(new_position):
			continue
		changed_before[component_id] = old_position
		changed_after[component_id] = new_position
	if changed_before.is_empty():
		return {}
	return {
		"kind": kind, "added": [], "removed": [],
		"positions_before": changed_before,
		"positions_after": changed_after,
	}


func _undo_wire() -> void:
	if _editor_locked():
		return
	while not wire_history.is_empty():
		var action: Dictionary = wire_history.pop_back()
		if not _apply_history_action(action, false):
			continue
		redo_history.append(action)
		_after_history_replay(action, _t(&"hardware.status.action_undone"))
		return
	status_label.text = _t(&"hardware.status.nothing_to_undo")
	status_label.add_theme_color_override("font_color", MUTED)


func _redo_edit() -> void:
	if _editor_locked():
		return
	while not redo_history.is_empty():
		var action: Dictionary = redo_history.pop_back()
		if not _apply_history_action(action, true):
			continue
		wire_history.append(action)
		_after_history_replay(action, _t(&"hardware.status.action_redone"))
		return
	status_label.text = _t(&"hardware.status.nothing_to_redo")
	status_label.add_theme_color_override("font_color", MUTED)


func _clear_wires() -> void:
	if graph == null or _editor_locked():
		return
	var connections: Array[Dictionary] = graph.get_connection_list()
	if connections.is_empty():
		status_label.text = _t(&"hardware.status.already_no_wires")
		return
	var action: Dictionary = {
		"kind": &"clear_wires",
		"added": [],
		"removed": [],
		"removed_components": [],
	}
	for connection: Dictionary in connections:
		_append_removed_wire(action, _wire_data(
			connection["from_node"], int(connection["from_port"]),
			connection["to_node"], int(connection["to_port"])
		))
	var junction_ids: Array[StringName] = []
	for component_id: StringName in component_catalog:
		var component: LogicComponent = component_catalog[component_id]
		if component.is_routing_node():
			junction_ids.append(component_id)
	junction_ids.sort()
	for junction_id: StringName in junction_ids:
		var junction: LogicComponent = component_catalog[junction_id]
		var node: GraphNode = component_nodes.get(junction_id)
		(action["removed_components"] as Array).append({
			"component": junction.duplicate_component(),
			"position": node.position_offset if node != null else layout_positions.get(junction_id, Vector2.ZERO),
		})
	for connection: Dictionary in connections:
		_remove_visible_wire(_wire_data(
			connection["from_node"], int(connection["from_port"]),
			connection["to_node"], int(connection["to_port"])
		))
	for junction_id: StringName in junction_ids:
		_remove_junction_component(junction_id)
	_push_history_action(action)
	_stop_playback()
	current_trace = null
	_mark_trace_stale()
	status_label.text = _t(&"hardware.status.all_wires_removed")
	status_label.add_theme_color_override("font_color", WARNING)
	if current_phase == &"tutorial":
		tutorial_removed_wire = true
		_update_tutorial_checklist()
	else:
		_invalidate_official_evidence(_t(&"hardware.status.topology_cleared"))


func _cancel_connection_drag() -> void:
	var placement_was_armed: bool = not armed_component_template_key.is_empty()
	if graph != null:
		if builtin_connection_drag_active:
			graph.force_connection_drag_end()
			builtin_connection_drag_active = false
		graph.end_builtin_connection_preview()
		graph.cancel_branch_drag()
		graph.cancel_endpoint_move()
		graph.cancel_selection_drag()
	_cancel_component_placement(false)
	status_label.text = _t(
		&"hardware.status.component_placement_cancelled"
		if placement_was_armed
		else &"hardware.status.drag_cancelled"
	)
	status_label.add_theme_color_override("font_color", MUTED)
	_reset_component_feedback()


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	if _editor_locked():
		return
	var removed_count: int = 0
	var protected_any: bool = false
	var action: Dictionary = {
		"kind": &"delete_selection", "added": [], "removed": [],
		"removed_components": [],
		"selection_before": _selected_node_ids(false),
		"selection_after": [],
	}
	var sorted_nodes: Array[StringName] = nodes.duplicate()
	sorted_nodes.sort()
	for component_id: StringName in sorted_nodes:
		var component: LogicComponent = component_catalog.get(component_id)
		if component == null:
			continue
		if component.fixed_terminal:
			protected_any = true
			continue
		if _delete_component_into_action(component_id, action, false):
			removed_count += 1
	if removed_count == 0:
		status_label.text = _t(&"hardware.status.test_bench_terminal_protected") if protected_any else _t(&"hardware.status.nothing_selected_delete")
		status_label.add_theme_color_override("font_color", MUTED)
		return
	_push_history_action(action)
	_topology_changed(_t(&"hardware.status.components_removed", [removed_count]), false, true)


func _on_component_gui_input(event: InputEvent, component_id: StringName) -> void:
	if _editor_locked() or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if (
		mouse_event.button_index == MOUSE_BUTTON_LEFT
		and mouse_event.pressed
		and mouse_event.double_click
	):
		var double_clicked_node: GraphNode = component_nodes.get(component_id)
		if double_clicked_node == null or _local_point_hits_port(double_clicked_node, mouse_event.position, 28.0):
			return
		_select_component_with_connected_route_nodes(component_id, mouse_event.shift_pressed)
		get_viewport().set_input_as_handled()
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and mouse_event.shift_pressed:
		var node: GraphNode = component_nodes.get(component_id)
		if node == null or _local_point_hits_port(node, mouse_event.position, 28.0):
			return
		node.selected = not node.selected
		_sync_selection_feedback()
		_on_selection_count_changed()
		get_viewport().set_input_as_handled()
		return
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT or not mouse_event.pressed:
		return
	var component: LogicComponent = component_catalog.get(component_id)
	if component == null:
		return
	_delete_component_with_history(component_id, true)
	get_viewport().set_input_as_handled()


func _delete_component_with_history(component_id: StringName, allow_fixed_terminal: bool = false) -> bool:
	var component: LogicComponent = component_catalog.get(component_id)
	if component == null or (component.fixed_terminal and not allow_fixed_terminal):
		return false
	var display_name: String = _component_display_name(component)
	var action: Dictionary = {
		"kind": &"delete_component",
		"added": [],
		"removed": [],
		"removed_components": [],
	}
	if not _delete_component_into_action(component_id, action, allow_fixed_terminal):
		return false
	_push_history_action(action)
	_topology_changed(_t(&"hardware.status.component_removed", [display_name]), false, true)
	return true


func _delete_component_into_action(
		component_id: StringName,
		action: Dictionary,
		allow_fixed_terminal: bool
	) -> bool:
	var component: LogicComponent = component_catalog.get(component_id)
	if component == null or (component.fixed_terminal and not allow_fixed_terminal):
		return false
	var node: GraphNode = component_nodes.get(component_id)
	var snapshot: LogicComponent = component.duplicate_component()
	var position: Vector2 = node.position_offset if node != null else layout_positions.get(component_id, Vector2.ZERO)
	for connection: Dictionary in graph.get_connection_list():
		if connection["from_node"] == component_id or connection["to_node"] == component_id:
			_append_removed_wire(action, _wire_data(
				connection["from_node"], int(connection["from_port"]),
				connection["to_node"], int(connection["to_port"])
			))
	var removed_components: Array = action.get("removed_components", [])
	removed_components.append({"component": snapshot, "position": position})
	action["removed_components"] = removed_components
	return _remove_component_internal(component_id)


func _append_removed_wire(action: Dictionary, wire: Dictionary) -> void:
	var removed_wires: Array = action.get("removed", [])
	for existing: Dictionary in removed_wires:
		if (
			existing.get("from_node", &"") == wire.get("from_node", &"")
			and int(existing.get("from_port", -1)) == int(wire.get("from_port", -1))
			and existing.get("to_node", &"") == wire.get("to_node", &"")
			and int(existing.get("to_port", -1)) == int(wire.get("to_port", -1))
		):
			return
	removed_wires.append(wire.duplicate())
	action["removed"] = removed_wires


func _wire_data(
		from_node: StringName,
		from_port: int,
		to_node: StringName,
		to_port: int
	) -> Dictionary:
	return {
		"from_node": from_node,
		"from_port": from_port,
		"to_node": to_node,
		"to_port": to_port,
	}


func _add_visible_wire(wire: Dictionary) -> bool:
	var error: String = current_circuit.connect_ports(
		wire["from_node"], int(wire["from_port"]), wire["to_node"], int(wire["to_port"])
	)
	if not error.is_empty():
		push_error("Visible wire commit rejected: %s" % error)
		return false
	graph.connect_node(wire["from_node"], int(wire["from_port"]), wire["to_node"], int(wire["to_port"]))
	return true


func _remove_visible_wire(wire: Dictionary) -> bool:
	if not current_circuit.disconnect_ports(
		wire["from_node"], int(wire["from_port"]), wire["to_node"], int(wire["to_port"])
	):
		return false
	graph.disconnect_node(wire["from_node"], int(wire["from_port"]), wire["to_node"], int(wire["to_port"]))
	return true


func _remove_junction_component(junction_id: StringName) -> bool:
	var component: LogicComponent = component_catalog.get(junction_id)
	if component == null or not component.is_routing_node():
		return false
	return _remove_component_internal(junction_id)


func _remove_component_internal(component_id: StringName) -> bool:
	if not component_catalog.has(component_id):
		return false
	for connection: Dictionary in graph.get_connection_list():
		if connection["from_node"] == component_id or connection["to_node"] == component_id:
			_remove_visible_wire(_wire_data(
				connection["from_node"], int(connection["from_port"]),
				connection["to_node"], int(connection["to_port"])
			))
	current_circuit.remove_component(component_id)
	component_catalog.erase(component_id)
	layout_positions.erase(component_id)
	component_state_labels.erase(component_id)
	component_idle_state_text.erase(component_id)
	component_symbols.erase(component_id)
	var node: GraphNode = component_nodes.get(component_id)
	component_nodes.erase(component_id)
	if node != null:
		graph.remove_child(node)
		node.queue_free()
	return true


func _next_junction_id() -> StringName:
	while true:
		junction_counter += 1
		var candidate := StringName("JUNCTION_%03d" % junction_counter)
		if not component_catalog.has(candidate):
			return candidate
	return &""


func _new_junction(component_id: StringName, width: int) -> LogicComponent:
	return LogicComponentType.new(
		component_id, LogicComponentType.KIND_JUNCTION, "WIRE NODE", &"", false,
		[], [], [], [], {"width": clampi(width, 1, 32)}
	)


func _editor_locked() -> bool:
	return sealing or current_phase in [&"sealed", &"campaign", &"prologue_complete"]


func _component_output_width(component_id: StringName, port: int) -> int:
	var component: LogicComponent = component_catalog.get(component_id)
	return component.output_width(port) if component != null else 1


func _graph_position_from_local(local_position: Vector2, half_size: Vector2) -> Vector2:
	var graph_position: Vector2 = (local_position + graph.scroll_offset) / graph.zoom - half_size
	return Vector2(snappedf(graph_position.x, 10.0), snappedf(graph_position.y, 10.0))


func _schedule_live_refresh() -> void:
	if graph == null or _editor_locked() or live_refresh_queued:
		return
	live_refresh_queued = true
	call_deferred("_refresh_live_signals")


func _refresh_live_signals() -> void:
	live_refresh_queued = false
	if graph == null or _editor_locked():
		return
	if current_phase in [&"campaign", &"prologue_complete"]:
		return
	if current_phase == &"prologue":
		_refresh_prologue_live_signals()
		return
	var circuit: LogicCircuit = _circuit_from_graph()
	var external_inputs: Dictionary[StringName, bool] = _current_live_inputs()
	var next_key: String = circuit.canonical_signature() + "|" + _input_value_signature(external_inputs)
	if live_state != null and next_key == live_state_key:
		return
	current_circuit = circuit
	live_state = CircuitAnalyzerType.new().analyze(circuit, external_inputs)
	live_state_key = next_key
	live_analysis_count += 1
	_apply_live_state(live_state)
	_update_live_diagnostics(live_state)


func _refresh_prologue_live_signals() -> void:
	var circuit: LogicCircuit = _circuit_from_graph()
	var external_inputs: Dictionary = _current_prologue_inputs()
	var next_key: String = circuit.canonical_signature() + "|" + _variant_input_signature(external_inputs)
	if prologue_live_result != null and next_key == live_state_key:
		return
	current_circuit = circuit
	prologue_live_result = prologue_simulator.evaluate(
		circuit, external_inputs, prologue_prior_outputs, prologue_runtime_state,
		bool(current_level_definition.get("allow_feedback", false))
	)
	live_state_key = next_key
	live_analysis_count += 1
	_apply_prologue_live_result(prologue_live_result, false)
	_update_prologue_live_diagnostics(prologue_live_result)


func _variant_input_signature(values: Dictionary) -> String:
	var keys: Array[String] = []
	for key: Variant in values:
		keys.append(String(key))
	keys.sort()
	var parts := PackedStringArray()
	for key: String in keys:
		parts.append("%s=%s" % [key, values.get(StringName(key), values.get(key, 0))])
	return ";".join(parts)


func _apply_prologue_live_result(
		result: PrologueSimulationResult,
		update_persistent_state: bool = true
	) -> void:
	if result == null or graph == null:
		return
	for connection: Dictionary in graph.get_connection_list():
		var from_node := StringName(connection.get("from_node", &""))
		var from_port: int = int(connection.get("from_port", -1))
		var component: LogicComponent = component_catalog.get(from_node)
		var value: DigitalValue = result.output_value(
			from_node, from_port, component.output_width(from_port) if component != null else 1
		)
		graph.set_connection_signal_state(
			from_node, from_port, StringName(connection.get("to_node", &"")),
			int(connection.get("to_port", -1)), _digital_logic_state(value)
		)
	for component_id: StringName in component_catalog:
		var component: LogicComponent = component_catalog[component_id]
		var inputs: Array[DigitalValue] = []
		var outputs: Array[DigitalValue] = []
		for port: int in range(component.input_count()):
			inputs.append(result.input_value(component_id, port, component.input_width(port)))
		for port: int in range(component.output_count()):
			outputs.append(result.output_value(component_id, port, component.output_width(port)))
		_set_component_digital_port_states(component_id, outputs, inputs)
	if update_persistent_state:
		_update_component_state_readouts(result)
	graph.queue_redraw()


func _update_component_state_readouts(result: PrologueSimulationResult) -> void:
	if result == null:
		return
	for component_id: StringName in component_state_labels:
		var component: LogicComponent = component_catalog.get(component_id)
		var label: Label = component_state_labels.get(component_id)
		if component == null or label == null:
			continue
		var text: String = _t(&"hardware.storage.component.uninitialized")
		match component.kind:
			LogicComponentType.KIND_SR_LATCH:
				text = _t(&"hardware.storage.component.latch", [
					result.output_value(component_id, 0, 1).display_text(),
					result.output_value(component_id, 1, 1).display_text(),
				])
			LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4:
				text = _t(&"hardware.storage.component.register", [
					result.output_value(component_id, 0, component.output_width(0)).display_text()
				])
			LogicComponentType.KIND_RAM2X4:
				var memories: Dictionary = result.runtime_state.get("ram", {})
				var raw: Array = memories.get(component_id, [0, 0])
				var m0: int = int(raw[0]) if raw.size() > 0 else 0
				var m1: int = int(raw[1]) if raw.size() > 1 else 0
				text = _t(&"hardware.storage.component.ram", [
					DigitalValueType.known(4, m0).display_text(),
					DigitalValueType.known(4, m1).display_text(),
				])
			LogicComponentType.KIND_TINY_COMPUTER:
				text = _t(&"hardware.storage.component.computer", [
					result.output_value(component_id, 0, 4).display_text(),
					result.output_value(component_id, 1, 4).display_text(),
				])
		component_idle_state_text[component_id] = text
		label.text = text
		label.add_theme_color_override("font_color", PURPLE)


func _set_component_digital_port_states(
		component_id: StringName,
		outputs: Array[DigitalValue],
		inputs: Array[DigitalValue]
	) -> void:
	var symbol: CircuitComponentSymbol = component_symbols.get(component_id)
	var node: GraphNode = component_nodes.get(component_id)
	if node == null:
		return
	if symbol != null:
		var input_bits: Array[bool] = []
		var input_known: Array[bool] = []
		for value: DigitalValue in inputs:
			input_bits.append(value.is_known() and value.value != 0)
			input_known.append(value.is_known())
		var first_output: DigitalValue = outputs[0] if not outputs.is_empty() else DigitalValueType.high_z()
		symbol.set_signal_state(
			first_output.is_known(), first_output.is_known() and first_output.value != 0,
			input_bits, input_known
		)
	for port: int in range(node.get_input_port_count()):
		var value: DigitalValue = inputs[port] if port < inputs.size() else DigitalValueType.low()
		node.set_slot_color_left(node.get_input_port_slot(port), _signal_color(_digital_logic_state(value)))
	for port: int in range(node.get_output_port_count()):
		var value: DigitalValue = outputs[port] if port < outputs.size() else DigitalValueType.high_z()
		node.set_slot_color_right(node.get_output_port_slot(port), _signal_color(_digital_logic_state(value)))


func _digital_logic_state(value: DigitalValue) -> int:
	if value == null or not value.is_known():
		return LogicSignalType.HIGH_Z
	return LogicSignalType.HIGH if value.value != 0 else LogicSignalType.LOW


func _update_prologue_live_diagnostics(result: PrologueSimulationResult) -> void:
	if result == null:
		return
	if not result.errors.is_empty():
		var messages := PackedStringArray()
		for index: int in range(result.errors.size()):
			messages.append(
				Localization.text_from_spec(result.error_specs[index])
				if index < result.error_specs.size() else result.errors[index]
			)
		diagnostics_label.text = _t(&"hardware.live.invalid", [" ".join(messages)])
		diagnostics_label.add_theme_color_override("font_color", BAD)
		return
	diagnostics_label.text = _t(&"hardware.prologue.live.summary", [
		result.settle_ticks, current_circuit.wires.size()
	])
	diagnostics_label.add_theme_color_override("font_color", MUTED)


func _current_live_inputs() -> Dictionary[StringName, bool]:
	var values: Dictionary[StringName, bool] = {}
	var ids: Array[StringName] = []
	for component_id: StringName in component_catalog:
		ids.append(component_id)
	ids.sort()
	for component_id: StringName in ids:
		var component: LogicComponent = component_catalog[component_id]
		if component.kind != LogicComponentType.KIND_INPUT or component.signal_name.is_empty():
			continue
		if component.signal_name == &"A" and input_a_button != null and is_instance_valid(input_a_button):
			values[component.signal_name] = input_a_button.button_pressed
		elif component.signal_name == &"B" and input_b_button != null and is_instance_valid(input_b_button):
			values[component.signal_name] = input_b_button.button_pressed
		else:
			values[component.signal_name] = false
	return values


func _input_value_signature(values: Dictionary[StringName, bool]) -> String:
	var names: Array[StringName] = []
	for input_name: StringName in values:
		names.append(input_name)
	names.sort()
	var parts: PackedStringArray = []
	for input_name: StringName in names:
		parts.append("%s=%d" % [input_name, int(values[input_name])])
	return ";".join(parts)


func _apply_live_state(state: CircuitLiveStateType) -> void:
	if state == null or graph == null:
		return
	for connection: Dictionary in graph.get_connection_list():
		var from_node: StringName = connection.get("from_node", &"")
		var from_port: int = int(connection.get("from_port", -1))
		graph.set_connection_signal_state(
			from_node, from_port,
			StringName(connection.get("to_node", &"")), int(connection.get("to_port", -1)),
			state.output_state(from_node, from_port)
		)
	for component_id: StringName in component_catalog:
		var component: LogicComponent = component_catalog[component_id]
		var input_states: Array[int] = []
		for input_port: int in range(component.input_count()):
			input_states.append(state.input_state(component_id, input_port))
		var output_state: int = state.output_state(component_id) if component.output_count() > 0 else LogicSignalType.HIGH_Z
		_set_component_port_states(component_id, output_state, input_states)
	graph.queue_redraw()


func _update_live_diagnostics(state: CircuitLiveStateType) -> void:
	if diagnostics_label == null or state == null:
		return
	if not state.errors.is_empty():
		var errors: PackedStringArray = []
		for index: int in range(state.errors.size()):
			errors.append(Localization.text_from_spec(state.error_specs[index]))
		diagnostics_label.text = _t(&"hardware.live.invalid", [" ".join(errors)])
		diagnostics_label.add_theme_color_override("font_color", BAD)
		return
	if current_phase == &"half_adder" and graph.get_connection_list().is_empty():
		diagnostics_label.text = _t(&"hardware.challenge.ready_unwired")
		diagnostics_label.add_theme_color_override("font_color", MUTED)
		return
	var high_count: int = 0
	var low_count: int = 0
	var high_z_count: int = 0
	for component_id: StringName in component_catalog:
		var component: LogicComponent = component_catalog[component_id]
		for input_port: int in range(component.input_count()):
			var input_state: int = state.input_state(component_id, input_port)
			if input_state == LogicSignalType.HIGH:
				high_count += 1
			elif input_state == LogicSignalType.LOW:
				low_count += 1
			else:
				high_z_count += 1
		for output_port: int in range(component.output_count()):
			var output_state: int = state.output_state(component_id, output_port)
			if output_state == LogicSignalType.HIGH:
				high_count += 1
			elif output_state == LogicSignalType.LOW:
				low_count += 1
			else:
				high_z_count += 1
	diagnostics_label.text = _t(&"hardware.live.summary", [high_count, low_count, high_z_count])
	diagnostics_label.add_theme_color_override("font_color", MUTED)


func _topology_changed(message: String, created: bool = true, removed: bool = false) -> void:
	_stop_playback()
	current_trace = null
	_mark_trace_stale()
	if current_phase == &"tutorial":
		tutorial_created_wire = tutorial_created_wire or created
		tutorial_removed_wire = tutorial_removed_wire or removed
		if created and tutorial_removed_wire:
			tutorial_reconnected_wire = true
		_update_tutorial_checklist()
		status_label.text = message
		status_label.add_theme_color_override("font_color", GOOD if created else WARNING)
	else:
		_invalidate_official_evidence(message)


func _mark_trace_stale() -> void:
	trace_caption_label.text = _t(&"hardware.trace.topology_changed")
	diagnostics_label.text = _t(&"hardware.diagnostics.awaiting_run")
	_schedule_live_refresh()


func _auto_layout() -> void:
	var before: Dictionary = _capture_node_positions()
	history_replaying = true
	for component_id: StringName in component_nodes:
		if layout_positions.has(component_id):
			(component_nodes[component_id] as GraphNode).position_offset = layout_positions[component_id]
	history_replaying = false
	var action: Dictionary = _position_action_from_snapshots(&"auto_layout", before, _capture_node_positions())
	if not action.is_empty():
		_push_history_action(action)
	status_label.text = _t(&"hardware.status.auto_layout")
	status_label.add_theme_color_override("font_color", ACCENT)
	graph.scroll_offset = Vector2.ZERO


func _restore_graph_view_after_layout() -> void:
	await get_tree().process_frame
	if graph == null or current_phase == &"sealed":
		return
	for component_id: StringName in component_nodes:
		if layout_positions.has(component_id):
			(component_nodes[component_id] as GraphNode).position_offset = layout_positions[component_id]
	graph.scroll_offset = Vector2.ZERO


func _on_test_input_toggled(_pressed: bool, _input_name: StringName) -> void:
	_stop_playback()
	current_trace = null
	_update_input_button_text()
	live_state_key = ""
	_schedule_live_refresh()
	if current_phase == &"tutorial":
		tutorial_changed_input = true
		_update_tutorial_checklist()
	status_label.text = _t(&"hardware.status.input_changed")
	status_label.add_theme_color_override("font_color", ACCENT)


func _update_input_button_text() -> void:
	if input_a_button != null:
		input_a_button.text = "A = %d" % int(input_a_button.button_pressed)
	if input_b_button != null:
		input_b_button.text = "B = %d" % int(input_b_button.button_pressed)


func _run_debug() -> void:
	if current_phase in [&"prologue", &"prologue_complete"]:
		_run_prologue_debug()
		return
	var a: bool = input_a_button.button_pressed
	var b: bool = input_b_button.button_pressed
	if current_phase == &"sealed":
		var sealed_trace: CircuitTrace = sealed_half_adder.evaluate(a, b)
		_show_debug_result(sealed_trace, "HalfAdder")
		_play_trace(sealed_trace)
		return
	var circuit: LogicCircuit = _circuit_from_graph()
	current_circuit = circuit
	var trace: CircuitTrace = HalfAdderTestBenchType.new().run_debug(circuit, a, b)
	_show_debug_result(trace, _t(&"hardware.result.lamp") if current_phase == &"tutorial" else _t(&"hardware.result.actual"))
	_play_trace(trace)
	if current_phase == &"tutorial" and trace.is_valid() and trace.outputs.has(&"LAMP"):
		tutorial_valid_run = true
		_update_tutorial_checklist()


func _show_debug_result(trace: CircuitTrace, prefix: String) -> void:
	if not trace.is_valid():
		var error_text: String = _trace_error_text(trace, 0)
		debug_result_label.text = _t(&"hardware.result.cannot_run", [error_text])
		debug_result_label.add_theme_color_override("font_color", BAD)
		status_label.text = _t(&"hardware.status.circuit_incomplete", [_trace_errors_text(trace)])
		status_label.add_theme_color_override("font_color", BAD)
		return
	if current_phase == &"tutorial":
		var lamp_value: bool = trace.outputs.get(&"LAMP", false)
		debug_result_label.text = _t(&"hardware.result.single", [prefix, int(lamp_value)])
		debug_result_label.add_theme_color_override("font_color", SIGNAL_HIGH if lamp_value else SIGNAL_LOW)
	else:
		var sum_value: bool = trace.outputs.get(&"SUM", false)
		var carry_value: bool = trace.outputs.get(&"CARRY", false)
		debug_result_label.text = _t(&"hardware.result.half_adder", [prefix, int(sum_value), int(carry_value)])
		debug_result_label.add_theme_color_override("font_color", GOOD)
	status_label.text = _t(&"hardware.status.debug_complete")
	status_label.add_theme_color_override("font_color", GOOD)


func _run_official() -> void:
	if current_phase == &"prologue":
		_run_prologue_official()
		return
	if current_phase != &"half_adder":
		return
	var circuit: LogicCircuit = _circuit_from_graph()
	current_circuit = circuit
	official_report = HalfAdderTestBenchType.new().run_official(circuit)
	official_passed = bool(official_report["passed"])
	passing_topology_signature = circuit.canonical_signature() if official_passed else ""
	var cases: Array = official_report["cases"]
	var playback_trace: CircuitTrace
	for index: int in range(cases.size()):
		var result: Dictionary = cases[index]
		var label: Label = official_case_labels[index]
		var actual_sum: Variant = result["actual_sum"]
		var actual_carry: Variant = result["actual_carry"]
		var actual_text: String = "S— C—" if actual_sum == null or actual_carry == null else "S%d C%d" % [int(actual_sum), int(actual_carry)]
		label.text = _t(&"hardware.cases.row_result", [
			int(result["A"]), int(result["B"]), int(result["expected_sum"]), int(result["expected_carry"]),
			actual_text, _t(&"outcome.pass") if result["passed"] else _t(&"outcome.fail"),
		])
		label.add_theme_color_override("font_color", GOOD if result["passed"] else BAD)
		if playback_trace == null or not bool(result["passed"]):
			playback_trace = result["trace"]
	if official_passed:
		playback_trace = cases[cases.size() - 1]["trace"]
		seal_button.disabled = false
		seal_button.text = _t(&"hardware.seal.verified_button")
		status_label.text = _t(&"hardware.status.official_pass")
		status_label.add_theme_color_override("font_color", GOOD)
	else:
		seal_button.disabled = true
		var first_error: String = ""
		if playback_trace != null and not playback_trace.errors.is_empty():
			first_error = "  ·  " + _trace_error_text(playback_trace, 0)
		status_label.text = _t(&"hardware.status.official_fail") + first_error
		status_label.add_theme_color_override("font_color", BAD)
	if playback_trace != null:
		_play_trace(playback_trace)


func _run_prologue_debug() -> void:
	if current_level_definition.is_empty():
		return
	var circuit: LogicCircuit = _circuit_from_graph()
	current_circuit = circuit
	var report: Dictionary = prologue_simulator.run_sequence(
		circuit,
		[{"inputs": _current_prologue_inputs(), "expected": {}}],
		bool(current_level_definition.get("allow_feedback", false)),
		prologue_runtime_state,
		prologue_prior_outputs
	)
	prologue_runtime_state = report.get("runtime_state", {}).duplicate(true)
	prologue_prior_outputs = report.get("prior_outputs", {}).duplicate(true)
	var result: PrologueSimulationResult = report.get("final_result")
	prologue_live_result = result
	if result == null or not result.is_valid():
		var message: String = _prologue_result_errors(result)
		debug_result_label.text = _t(&"hardware.result.cannot_run", [message])
		debug_result_label.add_theme_color_override("font_color", BAD)
		status_label.text = _t(&"hardware.status.circuit_incomplete", [message])
		status_label.add_theme_color_override("font_color", BAD)
		if result != null:
			_play_prologue_events(
				report.get("events", []), result,
				report.get("initial_runtime_state", {}), report.get("initial_prior_outputs", {})
			)
		return
	_update_storage_monitor(result, prologue_runtime_state)
	debug_result_label.text = _t(&"hardware.prologue.debug.result", [
		_format_digital_values(result.observed_values)
	])
	debug_result_label.add_theme_color_override("font_color", GOOD)
	status_label.text = _t(&"hardware.status.debug_complete")
	status_label.add_theme_color_override("font_color", GOOD)
	_play_prologue_events(
		report.get("events", []), result,
		report.get("initial_runtime_state", {}), report.get("initial_prior_outputs", {})
	)


func _run_prologue_official() -> void:
	var circuit: LogicCircuit = _circuit_from_graph()
	current_circuit = circuit
	prologue_report = prologue_simulator.run_sequence(
		circuit,
		current_level_definition.get("official_steps", []),
		bool(current_level_definition.get("allow_feedback", false))
	)
	official_passed = bool(prologue_report.get("passed", false))
	passing_topology_signature = circuit.canonical_signature() if official_passed else ""
	var steps: Array = prologue_report.get("steps", [])
	var previous_storage_state: String = _storage_initial_state_text() if _is_storage_level() else ""
	for index: int in range(prologue_case_labels.size()):
		var label: Label = prologue_case_labels[index]
		if index >= steps.size():
			continue
		var step: Dictionary = steps[index]
		var actual: Dictionary = {}
		for comparison: Dictionary in step.get("comparisons", []):
			actual[comparison["name"]] = comparison["actual"]
		var case_inputs: String = _format_value_dictionary(step.get("inputs", {}))
		var label_key := StringName(step.get("label_key", &""))
		if not label_key.is_empty():
			case_inputs = "%s · %s" % [_t(label_key), case_inputs]
		label.text = _t(&"hardware.prologue.case.result", [
			index + 1,
			case_inputs,
			_format_value_dictionary(step.get("expected", {})),
			_format_digital_values(actual),
			_t(&"outcome.pass") if bool(step.get("passed", false)) else _t(&"outcome.fail"),
		])
		if _is_storage_level():
			var step_result: PrologueSimulationResult = step.get("result")
			var next_storage_state: String = _storage_state_text(
				step_result, step_result.runtime_state if step_result != null else {}
			)
			label.text += "\n" + _t(&"hardware.storage.case.transition", [
				_storage_action_text(step.get("inputs", {})),
				previous_storage_state,
				next_storage_state,
			])
			previous_storage_state = next_storage_state
		label.add_theme_color_override("font_color", GOOD if bool(step.get("passed", false)) else BAD)
	var final_result: PrologueSimulationResult = prologue_report.get("final_result")
	if final_result != null and final_result.is_valid() and _is_storage_level():
		prologue_runtime_state = prologue_report.get("runtime_state", {}).duplicate(true)
		prologue_prior_outputs = prologue_report.get("prior_outputs", {}).duplicate(true)
		_update_storage_monitor(final_result, prologue_runtime_state)
	if official_passed:
		status_label.text = _t(&"hardware.status.official_pass")
		status_label.add_theme_color_override("font_color", GOOD)
		if StringName(current_level_definition.get("seal_name", &"")).is_empty():
			player_content.mark_completed(current_level_id)
			current_phase = &"prologue_complete"
			prologue_level_completed_view = true
			graph.branch_edit_enabled = false
			_build_prologue_complete_side()
		else:
			seal_button.disabled = false
			seal_button.text = _t(&"hardware.prologue.seal_verified", [
				StringName(current_level_definition.get("seal_name", &""))
			])
	else:
		var error_suffix: String = ""
		if final_result != null and not final_result.errors.is_empty():
			error_suffix = "  ·  " + _prologue_result_errors(final_result)
		status_label.text = _t(&"hardware.status.official_fail") + error_suffix
		status_label.add_theme_color_override("font_color", BAD)
		if seal_button != null:
			seal_button.disabled = true
	if final_result != null:
		prologue_live_result = final_result
		_play_prologue_events(
			prologue_report.get("events", []), final_result,
			prologue_report.get("initial_runtime_state", {}),
			prologue_report.get("initial_prior_outputs", {})
		)


func _format_digital_values(values: Dictionary) -> String:
	var keys: Array[String] = []
	for key: Variant in values:
		keys.append(String(key))
	keys.sort()
	var parts := PackedStringArray()
	for key: String in keys:
		var value: DigitalValue = values.get(StringName(key), values.get(key))
		parts.append("%s=%s" % [key, value.display_text() if value != null else "—"])
	return "  ".join(parts)


func _prologue_result_errors(result: PrologueSimulationResult) -> String:
	if result == null:
		return _t(&"hardware.prologue.no_result")
	var messages := PackedStringArray()
	for index: int in range(result.errors.size()):
		messages.append(
			Localization.text_from_spec(result.error_specs[index])
			if index < result.error_specs.size() else result.errors[index]
		)
	return " ".join(messages)


func _run_sealed_official() -> void:
	if current_phase != &"sealed" or sealed_half_adder == null:
		return
	var all_passed: bool = true
	var last_trace: CircuitTrace
	for official_case: Dictionary in HalfAdderTestBenchType.OFFICIAL_CASES:
		var trace: CircuitTrace = sealed_half_adder.evaluate(bool(official_case["A"]), bool(official_case["B"]))
		last_trace = trace
		all_passed = all_passed and trace.outputs.get(&"SUM") == official_case["SUM"] and trace.outputs.get(&"CARRY") == official_case["CARRY"]
	status_label.text = _t(&"hardware.status.sealed_verified") if all_passed else _t(&"hardware.status.sealed_failed")
	status_label.add_theme_color_override("font_color", GOOD if all_passed else BAD)
	if last_trace != null:
		_play_trace(last_trace, false)


func _circuit_from_graph() -> LogicCircuit:
	var exported := LogicCircuitType.new()
	var ids: Array[StringName] = []
	for component_id: StringName in component_catalog:
		ids.append(component_id)
	ids.sort()
	for component_id: StringName in ids:
		exported.add_component((component_catalog[component_id] as LogicComponent).duplicate_component())
	for connection: Dictionary in graph.get_connection_list():
		var error: String = exported.connect_ports(
			connection["from_node"], int(connection["from_port"]),
			connection["to_node"], int(connection["to_port"])
		)
		if not error.is_empty():
			push_error("Visible graph export rejected connection: %s" % error)
	return exported


func _invalidate_official_evidence(message: String) -> void:
	official_passed = false
	passing_topology_signature = ""
	official_report = {}
	prologue_report = {}
	if seal_button != null:
		seal_button.disabled = true
		seal_button.text = _t(&"hardware.seal.button")
	for label: Label in official_case_labels:
		label.add_theme_color_override("font_color", MUTED)
	for label: Label in prologue_case_labels:
		label.add_theme_color_override("font_color", MUTED)
	status_label.text = message
	status_label.add_theme_color_override("font_color", WARNING)


func _seal_half_adder() -> void:
	if current_phase != &"half_adder" or not official_passed or sealing:
		return
	var live_circuit: LogicCircuit = _circuit_from_graph()
	if live_circuit.canonical_signature() != passing_topology_signature:
		_invalidate_official_evidence(_t(&"hardware.status.seal_stale"))
		return
	sealed_half_adder = ReusableHalfAdderType.new(live_circuit)
	sealing = true
	sealing_elapsed = 0.0
	_stop_playback()
	encapsulation_effect.begin()
	status_label.text = _t(&"hardware.status.sealing")
	status_label.add_theme_color_override("font_color", PURPLE)
	seal_button.disabled = true


func _finish_encapsulation() -> void:
	if not sealing:
		return
	if not sealing_level_id.is_empty():
		_finish_prologue_encapsulation()
		return
	sealing = false
	encapsulation_effect.finish()
	current_phase = &"sealed"
	phase_label.text = _t(&"hardware.phase.complete")
	_build_sealed_graph()
	_build_sealed_side()
	status_label.text = _t(&"hardware.status.half_adder_created")
	status_label.add_theme_color_override("font_color", GOOD)
	trace_caption_label.text = "A  B  →  HalfAdder  →  SUM  CARRY"
	var reusable := ReusableComponentType.new(
		&"HalfAdder", LogicComponentType.KIND_HALF_ADDER, &"half_adder",
		sealed_half_adder.circuit_snapshot
	)
	player_content.install_reusable(&"half_adder", reusable, level_catalog)


func _build_sealed_graph() -> void:
	_create_graph()
	component_catalog.clear()
	layout_positions.clear()
	var node := GraphNode.new()
	node.name = &"HalfAdder"
	node.title = _t(&"hardware.sealed.node_title")
	node.draggable = true
	node.resizable = false
	node.custom_minimum_size = Vector2(430.0, 260.0)
	graph.add_child(node)
	node.position_offset = Vector2(690.0, 190.0)
	_add_port_row(node, 0, "A                         SUM", true, true, PURPLE, GOOD)
	_add_port_row(node, 1, "B                       CARRY", true, true, PURPLE, GOOD)
	var ownership := Label.new()
	ownership.text = _t(&"hardware.sealed.ownership")
	ownership.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ownership.add_theme_font_size_override("font_size", 18)
	ownership.add_theme_color_override("font_color", GOOD)
	node.add_child(ownership)
	node.add_theme_stylebox_override("panel", _stylebox(Color("172b33"), 12, 3, GOOD))
	node.add_theme_stylebox_override("titlebar", _stylebox(Color("213f46"), 10, 2, GOOD))
	component_nodes[&"HalfAdder"] = node
	graph.connection_validator = func(_a: StringName, _b: int, _c: StringName, _d: int) -> bool: return false
	graph.right_disconnects = false
	graph.scroll_offset = Vector2.ZERO
	graph.call_deferred("set_scroll_offset", Vector2.ZERO)
	diagnostics_label.text = _t(&"hardware.sealed.diagnostics")


func _open_campaign_map() -> void:
	_stop_playback()
	current_phase = &"campaign"
	current_level_id = &""
	current_level_definition.clear()
	prologue_live_result = null
	prologue_report.clear()
	prologue_level_completed_view = false
	phase_label.text = _t(&"hardware.prologue.map.phase")
	current_circuit = LogicCircuitType.new()
	component_catalog.clear()
	layout_positions.clear()
	_create_graph()
	graph.branch_edit_enabled = false
	_build_campaign_map_view()
	_build_campaign_side()
	status_label.text = _t(&"hardware.prologue.map.status")
	status_label.add_theme_color_override("font_color", ACCENT)
	trace_caption_label.text = _t(&"hardware.prologue.map.trace")
	diagnostics_label.text = _t(&"hardware.prologue.session_only")
	_layout_desktop_windows()


func _build_campaign_side() -> void:
	_clear_container(task_box)
	_clear_container(side_box)
	task_box.add_child(_side_heading(
		_t(&"hardware.prologue.map.title"), _t(&"hardware.prologue.map.subtitle")
	))
	var intro := Label.new()
	intro.text = _t(&"hardware.prologue.map.description")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", TEXT)
	task_box.add_child(intro)
	var map_hint := Label.new()
	map_hint.text = _t(&"hardware.prologue.map.canvas_hint")
	map_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_hint.add_theme_color_override("font_color", ACCENT)
	task_box.add_child(map_hint)
	if GameMode.is_test_mode():
		var test_notice := Label.new()
		test_notice.text = _t(&"hardware.mode.test_notice")
		test_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		test_notice.add_theme_color_override("font_color", WARNING)
		task_box.add_child(test_notice)
	var completed_count: int = 0
	for level_id: StringName in level_catalog.level_ids():
		if bool(completed_levels.get(level_id, false)):
			completed_count += 1
	var progress := Label.new()
	progress.text = _t(&"hardware.prologue.map.progress", [
		completed_count, level_catalog.level_ids().size()
	])
	progress.add_theme_color_override("font_color", GOOD if completed_count > 0 else MUTED)
	task_box.add_child(progress)
	var legend := Label.new()
	legend.text = _t(&"hardware.prologue.map.legend")
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.add_theme_color_override("font_color", MUTED)
	task_box.add_child(legend)

	side_box.add_child(_side_heading(
		_t(&"hardware.prologue.library.title"), _t(&"hardware.prologue.library.subtitle")
	))
	var names: Array[StringName] = []
	for component_name: StringName in component_library:
		names.append(component_name)
	names.sort()
	if names.is_empty():
		var empty := Label.new()
		empty.text = _t(&"hardware.prologue.library.empty")
		empty.add_theme_color_override("font_color", MUTED)
		side_box.add_child(empty)
	else:
		for component_name: StringName in names:
			var definition: ReusableComponent = component_library[component_name]
			var item := Label.new()
			item.text = "◆ %s  ·  %s" % [
				component_name,
				_t(&"hardware.prologue.library.generated") if definition.is_generated_wrapper() \
				else definition.source_signature.sha256_text().substr(0, 8).to_upper(),
			]
			item.tooltip_text = _t(&"hardware.prologue.library.provenance", [
				component_name, definition.source_signature.sha256_text().substr(0, 16).to_upper()
			])
			item.add_theme_color_override("font_color", GOOD)
			side_box.add_child(item)


func _build_campaign_map_view() -> void:
	campaign_map_view = CampaignMapViewType.new()
	campaign_map_view.name = "CampaignMapView"
	campaign_map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	campaign_map_view.z_index = 10
	graph_stack.add_child(campaign_map_view)
	var branch_descriptors: Array[Dictionary] = []
	for branch_id: StringName in level_catalog.branch_ids():
		branch_descriptors.append({
			"id": branch_id,
			"title": _t(level_catalog.branch_title_key(branch_id)),
			"order": level_catalog.branch_order(branch_id),
		})
	var level_descriptors: Array[Dictionary] = []
	for level_id: StringName in level_catalog.level_ids():
		var unlocked: bool = _is_level_unlocked(level_id)
		var completed: bool = bool(completed_levels.get(level_id, false))
		var prerequisite_names := PackedStringArray()
		for dependency: StringName in level_catalog.dependencies(level_id):
			prerequisite_names.append(_level_display_name(dependency))
		var requirement: String = _t(&"hardware.prologue.map.requirement", [
			_t(&"hardware.prologue.none") if prerequisite_names.is_empty()
			else ", ".join(prerequisite_names)
		])
		var description: String = _campaign_level_description(level_id)
		var status_key: StringName = (
			&"hardware.prologue.map.node.completed" if completed
			else (&"hardware.prologue.map.node.unlocked" if unlocked
			else &"hardware.prologue.map.node.locked")
		)
		level_descriptors.append({
			"id": level_id,
			"branch_id": level_catalog.level_branch_id(level_id),
			"order": level_catalog.level_order(level_id),
			"title": _level_display_name(level_id),
			"description": description,
			"dependencies": level_catalog.dependencies(level_id),
			"completed": completed,
			"unlocked": unlocked,
			"status": _t(status_key),
			"requirement": requirement,
			"tooltip": "%s\n%s" % [requirement, description],
		})
	campaign_map_view.level_requested.connect(_start_campaign_level)
	campaign_map_view.configure(
		branch_descriptors,
		level_descriptors,
		_t(&"hardware.prologue.map.canvas_legend")
	)
	campaign_level_buttons = campaign_map_view.level_buttons


func _campaign_level_description(level_id: StringName) -> String:
	var description_key: StringName = level_catalog.description_key(level_id)
	if not description_key.is_empty():
		return _t(description_key)
	match level_id:
		&"tutorial":
			return _t(&"hardware.prologue.map.tutorial_description")
		&"half_adder":
			return _t(&"hardware.prologue.map.half_adder_description")
	return _t(&"hardware.prologue.map.generic_description")


func _level_display_name(level_id: StringName) -> String:
	return _t(level_catalog.title_key(level_id))


func _start_campaign_level(level_id: StringName) -> void:
	if not _is_level_unlocked(level_id):
		status_label.text = _t(&"hardware.prologue.map.locked")
		status_label.add_theme_color_override("font_color", BAD)
		return
	match level_catalog.entry_kind(level_id):
		&"tutorial":
			_show_tutorial()
		&"half_adder":
			_start_challenge()
		&"circuit":
			_start_prologue_level(level_id)
		_:
			status_label.text = _t(&"hardware.prologue.map.missing", [level_id])
			status_label.add_theme_color_override("font_color", BAD)


func _start_prologue_level(level_id: StringName) -> void:
	if not _is_level_unlocked(level_id):
		status_label.text = _t(&"hardware.prologue.map.locked")
		status_label.add_theme_color_override("font_color", BAD)
		return
	var level: Dictionary = level_catalog.definition(level_id, component_library)
	if level.is_empty() or not bool(level.get("available", false)):
		status_label.text = _t(&"hardware.prologue.map.missing", [
			String(level.get("missing_component", &"?"))
		])
		status_label.add_theme_color_override("font_color", BAD)
		return
	_stop_playback()
	current_phase = &"prologue"
	current_level_id = level_id
	current_level_definition = level
	prologue_level_completed_view = false
	prologue_live_result = null
	prologue_report.clear()
	prologue_runtime_state.clear()
	prologue_prior_outputs.clear()
	official_report.clear()
	official_passed = false
	passing_topology_signature = ""
	sealing_level_id = &""
	pending_sealed_circuit = null
	phase_label.text = _t(StringName(level["title_key"]))
	_load_prologue_inventory(level)
	_create_graph()
	_build_component_nodes()
	graph.zoom = float(level.get("initial_zoom", 1.0))
	if bool(level.get("locked_topology", false)):
		_load_reference_wires(level)
		graph.branch_edit_enabled = false
	_build_prologue_side()
	status_label.text = _t(&"hardware.prologue.level.status")
	status_label.add_theme_color_override("font_color", MUTED)
	trace_caption_label.text = _t(&"hardware.prologue.level.trace")
	diagnostics_label.text = _t(&"hardware.prologue.level.zero_wire_delay")
	_schedule_live_refresh()
	call_deferred("_restore_graph_view_after_layout")


func _load_prologue_inventory(level: Dictionary) -> void:
	current_circuit = LogicCircuitType.new()
	component_catalog.clear()
	junction_counter = 0
	layout_positions.clear()
	for component_id: Variant in (level.get("layout", {}) as Dictionary):
		layout_positions[StringName(component_id)] = level["layout"][component_id]
	for component: LogicComponent in level.get("components", []):
		_add_catalog_component(component.duplicate_component())


func _load_reference_wires(level: Dictionary) -> void:
	for source_wire: Dictionary in level.get("reference_wires", []):
		_add_visible_wire(_wire_data(
			source_wire["from"], int(source_wire.get("from_port", 0)),
			source_wire["to"], int(source_wire.get("to_port", 0))
		))
	wire_history.clear()
	redo_history.clear()


func _build_prologue_side() -> void:
	_clear_container(task_box)
	_clear_container(side_box)
	storage_state_label = null
	storage_reset_button = null
	task_box.add_child(_side_heading(
		_t(StringName(current_level_definition["title_key"])),
		_t(&"hardware.prologue.level.subtitle")
	))
	var description := Label.new()
	description.text = _t(StringName(current_level_definition["description_key"]))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", TEXT)
	task_box.add_child(description)
	var ownership_note := Label.new()
	ownership_note.text = _t(&"hardware.prologue.level.ownership_note")
	ownership_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ownership_note.add_theme_font_size_override("font_size", 13)
	ownership_note.add_theme_color_override("font_color", MUTED)
	task_box.add_child(ownership_note)
	var map_button := Button.new()
	map_button.text = _t(&"hardware.prologue.back_map")
	map_button.pressed.connect(_open_campaign_map)
	task_box.add_child(map_button)
	if not StringName(current_level_definition.get("seal_name", &"")).is_empty():
		seal_button = Button.new()
		seal_button.text = _t(&"hardware.prologue.seal")
		seal_button.disabled = true
		seal_button.pressed.connect(_seal_prologue_component)
		task_box.add_child(seal_button)
	else:
		seal_button = null

	side_box.add_child(_side_heading(
		_t(&"hardware.prologue.bench.title"), _t(&"hardware.prologue.bench.subtitle")
	))
	if _is_storage_level():
		_build_storage_monitor()
	_build_prologue_input_controls()
	var debug_button := Button.new()
	debug_button.text = _t(&"hardware.cases.run_debug")
	debug_button.pressed.connect(_run_debug)
	side_box.add_child(debug_button)
	debug_result_label = Label.new()
	debug_result_label.text = _t(&"hardware.cases.actual_empty")
	debug_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_result_label.add_theme_color_override("font_color", MUTED)
	side_box.add_child(debug_result_label)
	var official_button := Button.new()
	official_button.text = _t(&"hardware.cases.run_official")
	official_button.pressed.connect(_run_official)
	side_box.add_child(official_button)
	_build_prologue_case_rows()
	_layout_desktop_windows()


func _is_storage_level() -> bool:
	return &"storage" in (current_level_definition.get("feature_tags", []) as Array)


func _build_storage_monitor() -> void:
	var heading := Label.new()
	heading.text = _t(&"hardware.storage.monitor.title")
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", PURPLE)
	side_box.add_child(heading)
	var explanation := Label.new()
	explanation.text = _t(&"hardware.storage.monitor.explanation")
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 12)
	explanation.add_theme_color_override("font_color", MUTED)
	side_box.add_child(explanation)
	storage_state_label = Label.new()
	storage_state_label.text = _t(&"hardware.storage.state.cleared")
	storage_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	storage_state_label.add_theme_font_size_override("font_size", 15)
	storage_state_label.add_theme_color_override("font_color", PURPLE)
	side_box.add_child(storage_state_label)
	storage_reset_button = Button.new()
	storage_reset_button.text = _t(&"hardware.storage.reset")
	storage_reset_button.tooltip_text = _t(&"hardware.storage.reset.tooltip")
	storage_reset_button.pressed.connect(_reset_storage_debug_state)
	side_box.add_child(storage_reset_button)


func _reset_storage_debug_state() -> void:
	if not _is_storage_level():
		return
	_stop_playback()
	prologue_runtime_state.clear()
	prologue_prior_outputs.clear()
	prologue_live_result = null
	live_state_key = ""
	_clear_signal_states()
	for component_id: StringName in component_state_labels:
		var component: LogicComponent = component_catalog.get(component_id)
		var state: Label = component_state_labels.get(component_id)
		if component == null or state == null:
			continue
		var text: String = _component_default_state_text(component)
		component_idle_state_text[component_id] = text
		state.text = text
		state.add_theme_color_override("font_color", PURPLE)
	_update_storage_monitor()
	_schedule_live_refresh()
	status_label.text = _t(&"hardware.storage.reset.done")
	status_label.add_theme_color_override("font_color", PURPLE)


func _update_storage_monitor(
		result: PrologueSimulationResult = null,
		runtime_state: Dictionary = {}
	) -> void:
	if not _is_storage_level() or storage_state_label == null \
			or not is_instance_valid(storage_state_label):
		return
	if result == null:
		storage_state_label.text = _t(&"hardware.storage.state.cleared")
	else:
		storage_state_label.text = _t(&"hardware.storage.state.committed", [
			_storage_state_text(result, runtime_state)
		])
	storage_state_label.add_theme_color_override("font_color", PURPLE)


func _storage_state_text(
		result: PrologueSimulationResult,
		runtime_state: Dictionary = {}
	) -> String:
	if result == null:
		return _t(&"hardware.storage.state.unknown")
	match current_level_id:
		&"latch":
			return _t(&"hardware.storage.state.latch", [
				_observed_value_text(result, &"Q"), _observed_value_text(result, &"NQ")
			])
		&"register":
			return _t(&"hardware.storage.state.register", [
				_observed_value_text(result, &"Q")
			])
		&"ram":
			var registers: Dictionary = runtime_state.get(
				"registers", result.runtime_state.get("registers", {})
			)
			return _t(&"hardware.storage.state.ram", [
				DigitalValueType.known(4, int(registers.get(&"REG_0", 0))).display_text(),
				DigitalValueType.known(4, int(registers.get(&"REG_1", 0))).display_text(),
			])
	return _t(&"hardware.storage.state.unknown")


func _observed_value_text(result: PrologueSimulationResult, signal_name: StringName) -> String:
	var value: DigitalValue = result.observed_values.get(signal_name)
	return value.display_text() if value != null else "—"


func _build_prologue_input_controls() -> void:
	prologue_input_controls.clear()
	var defaults: Dictionary = current_level_definition.get("debug_inputs", {})
	var inputs: Array[LogicComponent] = []
	for component: LogicComponent in current_level_definition.get("components", []):
		if component.kind == LogicComponentType.KIND_INPUT:
			inputs.append(component)
	for component: LogicComponent in inputs:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "%s [%d-bit]" % [component.signal_name, component.output_width(0)]
		name_label.custom_minimum_size.x = 115.0
		row.add_child(name_label)
		if component.output_width(0) == 1:
			var toggle := CheckButton.new()
			toggle.button_pressed = bool(defaults.get(component.signal_name, 0))
			toggle.text = str(int(toggle.button_pressed))
			toggle.toggled.connect(_on_prologue_toggle_changed.bind(component.signal_name, toggle))
			row.add_child(toggle)
			prologue_input_controls[component.signal_name] = toggle
		else:
			var value_input := SpinBox.new()
			value_input.min_value = 0
			value_input.max_value = DigitalValueType.mask_for_width(component.output_width(0))
			value_input.step = 1
			value_input.value = int(defaults.get(component.signal_name, 0))
			value_input.custom_minimum_size.x = 105.0
			value_input.value_changed.connect(_on_prologue_word_changed.bind(component.signal_name))
			row.add_child(value_input)
			prologue_input_controls[component.signal_name] = value_input
		side_box.add_child(row)


func _build_prologue_case_rows() -> void:
	prologue_case_labels.clear()
	for index: int in range((current_level_definition.get("official_steps", []) as Array).size()):
		var step: Dictionary = current_level_definition["official_steps"][index]
		var label := Label.new()
		var case_inputs: String = _format_value_dictionary(step.get("inputs", {}))
		var label_key := StringName(step.get("label_key", &""))
		if not label_key.is_empty():
			case_inputs = "%s · %s" % [_t(label_key), case_inputs]
		label.text = _t(&"hardware.prologue.case.not_run", [
			index + 1, case_inputs,
			_format_value_dictionary(step.get("expected", {})),
		])
		if _is_storage_level():
			label.text += "\n" + _t(&"hardware.storage.case.plan", [
				_storage_action_text(step.get("inputs", {}))
			])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", MUTED)
		prologue_case_labels.append(label)
		side_box.add_child(label)


func _storage_action_text(inputs: Dictionary) -> String:
	match current_level_id:
		&"latch":
			if int(inputs.get(&"S", 0)) != 0:
				return _t(&"hardware.storage.action.set")
			if int(inputs.get(&"R", 0)) != 0:
				return _t(&"hardware.storage.action.reset")
			return _t(&"hardware.storage.action.hold")
		&"register":
			if int(inputs.get(&"LOAD", 0)) != 0:
				return _t(&"hardware.storage.action.write", [int(inputs.get(&"D", 0))])
			return _t(&"hardware.storage.action.hold")
		&"ram":
			var address: int = int(inputs.get(&"ADDR", 0)) & 1
			if int(inputs.get(&"WRITE", 0)) != 0:
				return _t(&"hardware.storage.action.ram_write", [
					address,
					DigitalValueType.known(4, int(inputs.get(&"DATA", 0))).display_text(),
				])
			return _t(&"hardware.storage.action.ram_read", [address])
	return _t(&"hardware.storage.action.hold")


func _storage_initial_state_text() -> String:
	match current_level_id:
		&"latch":
			return _t(&"hardware.storage.state.initial_latch")
		&"register":
			return _t(&"hardware.storage.state.register", ["0"])
		&"ram":
			return _t(&"hardware.storage.state.ram", ["0x0", "0x0"])
	return _t(&"hardware.storage.state.unknown")


func _on_prologue_toggle_changed(pressed: bool, _name: StringName, control: CheckButton) -> void:
	control.text = str(int(pressed))
	_on_prologue_input_changed()


func _on_prologue_word_changed(_value: float, _name: StringName) -> void:
	_on_prologue_input_changed()


func _on_prologue_input_changed() -> void:
	_stop_playback()
	live_state_key = ""
	_schedule_live_refresh()
	status_label.text = _t(&"hardware.status.input_changed")
	status_label.add_theme_color_override("font_color", ACCENT)


func _current_prologue_inputs() -> Dictionary:
	var values: Dictionary = {}
	for signal_name: StringName in prologue_input_controls:
		var control: Control = prologue_input_controls[signal_name]
		if control is CheckButton:
			values[signal_name] = int((control as CheckButton).button_pressed)
		elif control is SpinBox:
			values[signal_name] = int((control as SpinBox).value)
	return values


func _format_value_dictionary(values: Dictionary) -> String:
	var keys: Array[String] = []
	for key: Variant in values:
		keys.append(String(key))
	keys.sort()
	var parts := PackedStringArray()
	for key: String in keys:
		var value: Variant = values.get(StringName(key), values.get(key, 0))
		if value is DigitalValue:
			parts.append("%s=%s" % [key, (value as DigitalValue).display_text()])
		else:
			parts.append("%s=%s" % [key, value])
	return "  ".join(parts)


func _seal_prologue_component() -> void:
	if current_phase != &"prologue" or not official_passed or sealing:
		return
	var live_circuit: LogicCircuit = _circuit_from_graph()
	if live_circuit.canonical_signature() != passing_topology_signature:
		_invalidate_official_evidence(_t(&"hardware.status.seal_stale"))
		return
	pending_sealed_circuit = live_circuit.duplicate_circuit()
	sealing_level_id = current_level_id
	sealing = true
	sealing_elapsed = 0.0
	_stop_playback()
	encapsulation_effect.begin()
	seal_button.disabled = true
	status_label.text = _t(&"hardware.status.sealing")
	status_label.add_theme_color_override("font_color", PURPLE)


func _finish_prologue_encapsulation() -> void:
	var finished_level: StringName = sealing_level_id
	var component_name := StringName(current_level_definition.get("seal_name", &""))
	var behavior_kind := StringName(current_level_definition.get("seal_kind", &""))
	var reusable := ReusableComponentType.new(
		component_name, behavior_kind, finished_level, pending_sealed_circuit
	)
	player_content.install_reusable(finished_level, reusable, level_catalog)
	sealing = false
	sealing_level_id = &""
	pending_sealed_circuit = null
	encapsulation_effect.finish()
	current_phase = &"prologue_complete"
	prologue_level_completed_view = true
	graph.branch_edit_enabled = false
	graph.connection_validator = func(_a: StringName, _b: int, _c: StringName, _d: int) -> bool: return false
	_build_prologue_complete_side(component_name)
	status_label.text = _t(&"hardware.prologue.created", [component_name])
	status_label.add_theme_color_override("font_color", GOOD)
	trace_caption_label.text = _t(&"hardware.prologue.sealed_trace", [component_name])


func _invalidate_downstream_progress(changed_level: StringName) -> void:
	player_content.invalidate_dependents(changed_level, level_catalog)


func _library_names_for_level(level_id: StringName) -> Array[StringName]:
	return level_catalog.reward_names(level_id)


func _build_prologue_complete_side(component_name: StringName = &"") -> void:
	_clear_container(task_box)
	task_box.add_child(_side_heading(
		_t(&"hardware.prologue.complete.title"), _t(&"hardware.prologue.complete.subtitle")
	))
	var created := Label.new()
	created.text = _t(&"hardware.prologue.complete.bridge") if component_name.is_empty() \
		else _t(&"hardware.prologue.complete.created", [component_name])
	created.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	created.add_theme_font_size_override("font_size", 22)
	created.add_theme_color_override("font_color", GOOD)
	task_box.add_child(created)
	for recipe: Dictionary in level_catalog.generated_rewards(current_level_id):
		var expanded := Label.new()
		expanded.text = _t(&"hardware.prologue.complete.auto_expand", [
			StringName(recipe.get("name", &""))
		])
		expanded.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		expanded.add_theme_color_override("font_color", ACCENT)
		task_box.add_child(expanded)
	var map_button := Button.new()
	map_button.text = _t(&"hardware.prologue.back_map")
	map_button.pressed.connect(_open_campaign_map)
	task_box.add_child(map_button)
	var completion_scene := String(current_level_definition.get("completion_scene", ""))
	if not completion_scene.is_empty():
		var locality_button := Button.new()
		locality_button.text = _t(StringName(current_level_definition.get(
			"completion_action_key", &"hardware.prologue.open_locality"
		)))
		locality_button.pressed.connect(func() -> void:
			get_tree().change_scene_to_file(completion_scene)
		)
		task_box.add_child(locality_button)


func _play_trace(trace: CircuitTrace, allow_graph_animation: bool = true) -> void:
	current_trace = trace
	_apply_trace_signal_states(trace)
	playback_index = 0
	playback_elapsed = 0.0
	_build_playback_batches(trace)
	playback_running = allow_graph_animation and trace != null and not playback_batches.is_empty()
	pause_button.text = _t(&"hardware.trace.pause")
	if trace == null:
		return
	diagnostics_label.text = _t(&"hardware.diagnostics.trace", [
		int(trace.metrics.get("gate_count", 0)), int(trace.metrics.get("propagation_ticks", 0))
	])
	if not trace.errors.is_empty():
		trace_caption_label.text = _t(&"hardware.trace.blocked", [_trace_error_text(trace, 0)])
		_stop_playback()
	elif playback_running:
		trace_caption_label.text = _t(&"hardware.trace.first_wave", [playback_batches.size(), _playback_batch_summary(playback_batches[0])])


func _play_prologue_events(
		events: Array,
		result: PrologueSimulationResult,
		initial_runtime_state: Dictionary = {},
		initial_prior_outputs: Dictionary = {}
	) -> void:
	current_trace = null
	prologue_live_result = result
	if result != null:
		_apply_prologue_live_result(result, not _events_have_state_transition(events))
	if _is_storage_level() and _events_have_state_transition(events):
		_prepare_storage_playback_state(initial_runtime_state, initial_prior_outputs)
	playback_index = 0
	playback_elapsed = 0.0
	_build_prologue_playback_batches(events)
	playback_running = not playback_batches.is_empty() and current_phase != &"prologue_complete"
	pause_button.text = _t(&"hardware.trace.pause")
	if result == null:
		return
	diagnostics_label.text = _t(&"hardware.prologue.trace.metrics", [
		result.settle_ticks, current_circuit.wires.size(), events.size()
	])
	if not result.errors.is_empty():
		trace_caption_label.text = _t(&"hardware.trace.blocked", [_prologue_result_errors(result)])
		playback_running = false
	elif playback_running:
		trace_caption_label.text = _t(&"hardware.trace.first_wave", [
			playback_batches.size(), _playback_batch_summary(playback_batches[0])
		])


func _events_have_state_transition(events: Array) -> bool:
	for event: Variant in events:
		if event != null and event.kind == &"state_transition":
			return true
	return false


func _prepare_storage_playback_state(
		initial_runtime_state: Dictionary,
		initial_prior_outputs: Dictionary
	) -> void:
	storage_playback_values.clear()
	match current_level_id:
		&"latch":
			_store_initial_playback_output(initial_prior_outputs, &"NOR_Q", 1)
			_store_initial_playback_output(initial_prior_outputs, &"NOR_NQ", 1)
		&"register":
			_store_initial_playback_output(initial_prior_outputs, &"LATCH", 1)
			if not storage_playback_values.has(&"LATCH"):
				storage_playback_values[&"LATCH"] = DigitalValueType.low()
		&"ram":
			var registers: Dictionary = initial_runtime_state.get("registers", {})
			storage_playback_values[&"REG_0"] = DigitalValueType.known(
				4, int(registers.get(&"REG_0", 0))
			)
			storage_playback_values[&"REG_1"] = DigitalValueType.known(
				4, int(registers.get(&"REG_1", 0))
			)
	_update_storage_playback_monitor()


func _store_initial_playback_output(
		initial_prior_outputs: Dictionary,
		component_id: StringName,
		width: int
	) -> void:
	var key: String = PrologueSimulationResultType.output_key(component_id, 0)
	var value: DigitalValue = initial_prior_outputs.get(key)
	if value != null:
		storage_playback_values[component_id] = value.duplicate_value()


func _update_storage_playback_monitor() -> void:
	if storage_state_label == null or not is_instance_valid(storage_state_label):
		return
	var state_text: String = _t(&"hardware.storage.state.unknown")
	match current_level_id:
		&"latch":
			if not storage_playback_values.has(&"NOR_Q") \
					or not storage_playback_values.has(&"NOR_NQ"):
				storage_state_label.text = _t(&"hardware.storage.state.initial_latch")
				return
			state_text = _t(&"hardware.storage.state.latch", [
				(storage_playback_values[&"NOR_Q"] as DigitalValue).display_text(),
				(storage_playback_values[&"NOR_NQ"] as DigitalValue).display_text(),
			])
		&"register":
			state_text = _t(&"hardware.storage.state.register", [
				(storage_playback_values.get(&"LATCH", DigitalValueType.low()) as DigitalValue).display_text()
			])
		&"ram":
			state_text = _t(&"hardware.storage.state.ram", [
				(storage_playback_values.get(&"REG_0", DigitalValueType.known(4, 0)) as DigitalValue).display_text(),
				(storage_playback_values.get(&"REG_1", DigitalValueType.known(4, 0)) as DigitalValue).display_text(),
			])
	storage_state_label.text = _t(&"hardware.storage.state.committed", [state_text])
	storage_state_label.add_theme_color_override("font_color", PURPLE)


func _build_prologue_playback_batches(events: Array) -> void:
	playback_batches.clear()
	var events_by_step: Dictionary = {}
	for event_variant: Variant in events:
		var event: PrologueEvent = event_variant
		if event == null:
			continue
		if not events_by_step.has(event.visual_step):
			events_by_step[event.visual_step] = []
		(events_by_step[event.visual_step] as Array).append(event)
	var steps: Array[int] = []
	for step_variant: Variant in events_by_step:
		steps.append(int(step_variant))
	steps.sort()
	for step: int in steps:
		var batch_events: Array = events_by_step[step]
		var tick: int = (batch_events[0] as PrologueEvent).tick if not batch_events.is_empty() else 0
		playback_batches.append({"visual_step": step, "tick": tick, "events": batch_events})


func _build_playback_batches(trace: CircuitTrace) -> void:
	playback_batches.clear()
	if trace == null:
		return
	var events_by_step: Dictionary = {}
	for event: CircuitEvent in trace.events:
		if not events_by_step.has(event.visual_step):
			events_by_step[event.visual_step] = []
		(events_by_step[event.visual_step] as Array).append(event)
	var steps: Array[int] = []
	for step: int in events_by_step:
		steps.append(step)
	steps.sort()
	for step: int in steps:
		var events: Array = events_by_step[step]
		var tick: int = (events[0] as CircuitEvent).tick if not events.is_empty() else 0
		playback_batches.append({"visual_step": step, "tick": tick, "events": events})


func _playback_batch_duration(batch: Dictionary) -> float:
	for event: Variant in batch.get("events", []):
		if event.kind == &"wire_signal":
			return 0.76
	for event: Variant in batch.get("events", []):
		if event.kind == &"state_transition":
			return 1.04
	return 0.88


func _playback_batch_summary(batch: Dictionary) -> String:
	var wire_count: int = 0
	var component_count: int = 0
	var state_count: int = 0
	for event: Variant in batch.get("events", []):
		if event.kind == &"wire_signal":
			wire_count += 1
		elif event.kind == &"state_transition":
			state_count += 1
		else:
			component_count += 1
	var parts: PackedStringArray = []
	if component_count > 0:
		parts.append(_t(&"hardware.trace.component_count", [component_count]))
	if state_count > 0:
		parts.append(_t(&"hardware.trace.state_count", [state_count]))
	if wire_count > 0:
		parts.append(_t(&"hardware.trace.wire_count", [wire_count]))
	return _t(&"hardware.trace.parallel_summary", [" + ".join(parts)])


func _show_playback_batch(batch: Dictionary, progress: float) -> void:
	_reset_component_feedback()
	_reset_connection_activity()
	trace_caption_label.text = _t(&"hardware.trace.wave", [
		playback_index + 1, playback_batches.size(), int(batch.get("tick", 0)), _playback_batch_summary(batch)
	])
	var wire_pulses: Array[Dictionary] = []
	var has_wire: bool = false
	for event: Variant in batch.get("events", []):
		if event.kind == &"wire_signal":
			has_wire = true
			break
	for event: Variant in batch.get("events", []):
		if event.kind == &"wire_signal":
			var path: PackedVector2Array = _connection_curve(event.from_component, event.from_port, event.to_component, event.to_port)
			var wire_high: bool = _event_is_high(event)
			wire_pulses.append({
				"path": path, "progress": progress, "value": wire_high,
				"display": _event_value_text(event),
			})
			graph.set_connection_activity(event.from_component, event.from_port, event.to_component, event.to_port, sin(progress * PI))
			active_connections.append(event.to_dictionary())
			_activate_routing_endpoint(event.from_component, wire_high)
			_activate_routing_endpoint(event.to_component, wire_high)
			continue
		var node: GraphNode = component_nodes.get(event.component_id)
		var component: LogicComponent = component_catalog.get(event.component_id)
		if node == null or component == null:
			continue
		var component_progress: float = progress
		if component.is_observer() and has_wire:
			component_progress = clampf((progress - 0.58) / 0.42, 0.0, 1.0)
			if component_progress <= 0.0:
				continue
		if not active_components.has(event.component_id):
			active_components.append(event.component_id)
		var event_high: bool = _event_is_high(event)
		var color: Color = SIGNAL_HIGH if event_high else SIGNAL_LOW
		_set_node_style(event.component_id, color, true)
		var event_caption: String = _event_caption(event, component)
		var state: Label = component_state_labels.get(event.component_id)
		if state != null:
			state.text = event_caption
			state.add_theme_color_override("font_color", color)
		_set_component_activity(event.component_id, component_progress, event)
	active_component = active_components[0] if not active_components.is_empty() else &""
	active_connection = active_connections[0] if not active_connections.is_empty() else {}
	trace_overlay.show_parallel(wire_pulses)
	if progress >= 1.0:
		for event: Variant in batch.get("events", []):
			if event is PrologueEvent and event.kind == &"state_transition":
				_commit_state_event_readout(event as PrologueEvent)


func _commit_state_event_readout(event: PrologueEvent) -> void:
	_commit_storage_playback_value(event)
	var component: LogicComponent = component_catalog.get(event.component_id)
	if component == null or not component_state_labels.has(event.component_id):
		return
	var text: String = _event_value_text(event)
	match component.kind:
		LogicComponentType.KIND_SR_LATCH:
			var nq: String = "—"
			if event.value != null and event.value.is_known():
				nq = str(0 if event.value.bit() else 1)
			text = _t(&"hardware.storage.component.latch", [_event_value_text(event), nq])
		LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4:
			text = _t(&"hardware.storage.component.register", [_event_value_text(event)])
		LogicComponentType.KIND_RAM2X4:
			if event.message_args.size() >= 4:
				text = _t(&"hardware.storage.component.ram", [
					String(event.message_args[2]), String(event.message_args[3])
				])
	component_idle_state_text[event.component_id] = text


func _commit_storage_playback_value(event: PrologueEvent) -> void:
	if not _is_storage_level() or event.value == null:
		return
	var relevant: bool = event.component_id in (
		current_level_definition.get("state_feedback_components", []) as Array
	)
	if not relevant:
		return
	storage_playback_values[event.component_id] = event.value.duplicate_value()
	_update_storage_playback_monitor()


func _event_is_high(event: Variant) -> bool:
	if event is PrologueEvent:
		var digital: DigitalValue = (event as PrologueEvent).value
		return digital != null and digital.is_known() and digital.value != 0
	return bool(event.value)


func _event_value_text(event: Variant) -> String:
	if event is PrologueEvent:
		var digital: DigitalValue = (event as PrologueEvent).value
		return digital.display_text() if digital != null else "Z"
	return str(int(bool(event.value)))


func _event_caption(event: Variant, component: LogicComponent) -> String:
	if event is PrologueEvent:
		var prologue_event := event as PrologueEvent
		if not prologue_event.message_key.is_empty() \
				and (prologue_event.kind == &"state_transition" or not prologue_event.message_args.is_empty()):
			return _t(prologue_event.message_key, prologue_event.message_args)
	return _t(&"hardware.trace.process", [
		_component_kind_text(component.kind), _event_value_text(event)
	])


func _activate_routing_endpoint(component_id: StringName, value: bool) -> void:
	var component: LogicComponent = component_catalog.get(component_id)
	if component == null or not component.is_routing_node():
		return
	if not active_components.has(component_id):
		active_components.append(component_id)
	_set_node_style(component_id, SIGNAL_HIGH if value else SIGNAL_LOW, true)


func _show_circuit_event(event: CircuitEvent, progress: float) -> void:
	_show_playback_batch({"visual_step": event.visual_step, "tick": event.tick, "events": [event]}, progress)


func _connection_curve(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> PackedVector2Array:
	var source: GraphNode = component_nodes.get(from_node)
	var target: GraphNode = component_nodes.get(to_node)
	if source == null or target == null or from_port >= source.get_output_port_count() or to_port >= target.get_input_port_count():
		return PackedVector2Array()
	var overlay_inverse: Transform2D = trace_overlay.get_global_transform().affine_inverse()
	var start: Vector2 = overlay_inverse * (
		source.get_global_transform() * source.get_output_port_position(from_port)
	)
	var finish: Vector2 = overlay_inverse * (
		target.get_global_transform() * target.get_input_port_position(to_port)
	)
	return graph.get_connection_line(start, finish)


func _finish_playback() -> void:
	playback_running = false
	playback_index = playback_batches.size()
	playback_elapsed = 0.0
	pause_button.text = _t(&"hardware.trace.replay")
	_reset_component_feedback()
	_reset_connection_activity()
	trace_overlay.clear_event()
	if current_trace != null and current_trace.is_valid():
		_apply_trace_signal_states(current_trace)
		trace_caption_label.text = _t(&"hardware.trace.complete")
	elif prologue_live_result != null and prologue_live_result.is_valid():
		_apply_prologue_live_result(prologue_live_result)
		_update_storage_monitor(prologue_live_result, prologue_runtime_state)
		trace_caption_label.text = _t(&"hardware.trace.complete")


func _stop_playback() -> void:
	playback_running = false
	playback_index = 0
	playback_elapsed = 0.0
	playback_batches.clear()
	active_components.clear()
	active_connections.clear()
	active_component = &""
	active_connection = {}
	if trace_overlay != null:
		trace_overlay.clear_event()
	if graph != null:
		_reset_connection_activity()
	_reset_component_feedback()
	if prologue_live_result != null and prologue_live_result.is_valid():
		_update_storage_monitor(prologue_live_result, prologue_runtime_state)


func _toggle_playback() -> void:
	if playback_batches.is_empty() and (current_trace == null or current_trace.events.is_empty()):
		status_label.text = _t(&"hardware.status.trace_control_requires_run")
		return
	if playback_batches.is_empty() and current_trace != null:
		_build_playback_batches(current_trace)
	if playback_index >= playback_batches.size():
		playback_index = 0
		playback_elapsed = 0.0
	playback_running = not playback_running
	pause_button.text = _t(&"hardware.trace.pause") if playback_running else _t(&"hardware.trace.resume")


func _step_playback() -> void:
	if playback_batches.is_empty() and (current_trace == null or current_trace.events.is_empty()):
		status_label.text = _t(&"hardware.status.trace_step_requires_run")
		return
	playback_running = false
	if playback_batches.is_empty() and current_trace != null:
		_build_playback_batches(current_trace)
	if playback_index >= playback_batches.size():
		playback_index = 0
	_show_playback_batch(playback_batches[playback_index], 1.0)
	playback_index += 1
	pause_button.text = _t(&"hardware.trace.resume")


func _on_speed_selected(index: int) -> void:
	playback_speed = [0.7, 1.0, 1.7][index]


func _reset_connection_activity() -> void:
	if graph == null:
		return
	for connection: Dictionary in graph.get_connection_list():
		graph.set_connection_activity(connection["from_node"], connection["from_port"], connection["to_node"], connection["to_port"], 0.0)
	active_connections.clear()
	active_connection = {}


func _set_component_activity(
		component_id: StringName,
		progress: float,
		event: Variant = null
	) -> void:
	var input_visuals: Array[Dictionary] = _event_input_visuals(event)
	var output_visual: Dictionary = _event_output_visual(event)
	var output_port: int = _event_output_port(event)
	var symbol: CircuitComponentSymbol = component_symbols.get(component_id)
	if symbol != null:
		symbol.set_processing_state(progress, input_visuals, output_visual)
	var component: LogicComponent = component_catalog.get(component_id)
	var rows: Array = component_row_labels.get(component_id, [])
	if component == null or rows.is_empty():
		return
	for row_index: int in range(rows.size()):
		var row: Variant = rows[row_index]
		if row == null:
			continue
		row.set_processing_state(progress, input_visuals, output_visual, output_port)


func _event_input_visuals(event: Variant) -> Array[Dictionary]:
	var visuals: Array[Dictionary] = []
	if event is PrologueEvent:
		for value: DigitalValue in (event as PrologueEvent).input_values:
			visuals.append(_digital_value_visual(value))
	elif event is CircuitEvent:
		for value: bool in (event as CircuitEvent).input_values:
			visuals.append(_bool_value_visual(value))
	return visuals


func _event_output_visual(event: Variant) -> Dictionary:
	if event is PrologueEvent:
		return _digital_value_visual((event as PrologueEvent).value)
	if event is CircuitEvent:
		return _bool_value_visual(bool((event as CircuitEvent).value))
	return {"known": false, "numeric": 0, "text": "Z", "color": SIGNAL_HIGH_Z}


func _event_output_port(event: Variant) -> int:
	if event is PrologueEvent:
		var prologue_port: int = (event as PrologueEvent).from_port
		return prologue_port if prologue_port >= 0 else 0
	if event is CircuitEvent:
		var circuit_port: int = (event as CircuitEvent).from_port
		return circuit_port if circuit_port >= 0 else 0
	return -1


func _bool_value_visual(value: bool) -> Dictionary:
	return {
		"known": true,
		"numeric": 1 if value else 0,
		"text": str(int(value)),
		"color": SIGNAL_HIGH if value else SIGNAL_LOW,
	}


func _digital_value_visual(value: DigitalValue) -> Dictionary:
	if value == null or not value.is_known():
		return {
			"known": false,
			"numeric": 0,
			"text": value.display_text() if value != null else "Z",
			"color": SIGNAL_HIGH_Z,
		}
	return {
		"known": true,
		"numeric": value.value,
		"text": value.display_text(),
		"color": SIGNAL_HIGH if value.value != 0 else SIGNAL_LOW,
	}


func _reset_component_feedback() -> void:
	active_components.clear()
	active_component = &""
	for component_id: StringName in component_nodes:
		var component: LogicComponent = component_catalog.get(component_id)
		if component == null:
			continue
		var symbol: CircuitComponentSymbol = component_symbols.get(component_id)
		if symbol != null:
			symbol.clear_processing_state()
		var rows: Array = component_row_labels.get(component_id, [])
		for row_index: int in range(rows.size()):
			var row: Variant = rows[row_index]
			if row == null:
				continue
			row.clear_processing_state()
		_set_node_style(component_id, PURPLE if component.fixed_terminal else MUTED, false)
		var state: Label = component_state_labels.get(component_id)
		if state != null:
			state.text = component_idle_state_text.get(
				component_id,
				_t(&"state.test_bench") if component.fixed_terminal else _t(&"state.ready")
			)
			state.add_theme_color_override(
				"font_color", PURPLE if component.fixed_terminal or component.is_stateful() else MUTED
			)


func _clear_signal_states() -> void:
	if graph != null:
		graph.clear_connection_signal_values()
	for component_id: StringName in component_symbols:
		(component_symbols[component_id] as CircuitComponentSymbol).clear_signal_state()
		var node: GraphNode = component_nodes.get(component_id)
		if node == null:
			continue
		for input_port: int in range(node.get_input_port_count()):
			node.set_slot_color_left(node.get_input_port_slot(input_port), SIGNAL_LOW)
		for output_port: int in range(node.get_output_port_count()):
			node.set_slot_color_right(node.get_output_port_slot(output_port), SIGNAL_HIGH_Z)
	if graph != null:
		graph.queue_redraw()


func _apply_trace_signal_states(trace: CircuitTrace) -> void:
	if trace == null or graph == null or current_phase == &"sealed":
		return
	var circuit: LogicCircuit = _circuit_from_graph()
	current_circuit = circuit
	live_state = CircuitAnalyzerType.new().analyze(circuit, trace.input_values)
	live_state_key = circuit.canonical_signature() + "|" + _input_value_signature(trace.input_values)
	live_analysis_count += 1
	_apply_live_state(live_state)


func _set_component_port_states(
		component_id: StringName,
		output_state: int,
		input_states: Array[int]
	) -> void:
	var symbol: CircuitComponentSymbol = component_symbols.get(component_id)
	var node: GraphNode = component_nodes.get(component_id)
	if symbol == null or node == null:
		return
	var input_values: Array[bool] = []
	var input_known: Array[bool] = []
	for input_state: int in input_states:
		input_values.append(input_state == LogicSignalType.HIGH)
		input_known.append(LogicSignalType.is_binary(input_state))
	var output_known: bool = LogicSignalType.is_binary(output_state)
	symbol.set_signal_state(output_known, output_state == LogicSignalType.HIGH, input_values, input_known)
	for input_port: int in range(node.get_input_port_count()):
		var input_state: int = input_states[input_port] if input_port < input_states.size() else LogicSignalType.HIGH_Z
		node.set_slot_color_left(node.get_input_port_slot(input_port), _signal_color(input_state))
	for output_port: int in range(node.get_output_port_count()):
		node.set_slot_color_right(node.get_output_port_slot(output_port), _signal_color(output_state))
	if graph != null:
		graph.queue_redraw()


func _signal_color(state: int) -> Color:
	if state == LogicSignalType.HIGH:
		return SIGNAL_HIGH
	if state == LogicSignalType.LOW:
		return SIGNAL_LOW
	return SIGNAL_HIGH_Z


func _set_node_style(component_id: StringName, _color: Color, _active: bool) -> void:
	var node: GraphNode = component_nodes.get(component_id)
	if node == null:
		return
	var component: LogicComponent = component_catalog.get(component_id)
	var panel_style: StyleBoxFlat
	if component != null and component.is_routing_node():
		panel_style = _compact_stylebox(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT)
	else:
		panel_style = _node_stylebox(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT)
	var title_style: StyleBoxFlat = _compact_stylebox(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT)
	node.add_theme_stylebox_override("panel", panel_style)
	node.add_theme_stylebox_override("panel_selected", panel_style)
	node.add_theme_stylebox_override("titlebar", title_style)
	node.add_theme_stylebox_override("titlebar_selected", title_style)


func _update_tutorial_checklist() -> void:
	var states: Dictionary[StringName, bool] = {
		&"wire": tutorial_created_wire,
		&"input": tutorial_changed_input,
		&"run": tutorial_valid_run,
		&"remove": tutorial_removed_wire,
		&"reconnect": tutorial_reconnected_wire,
	}
	for key: StringName in states:
		var label: Label = tutorial_check_labels.get(key)
		if label == null:
			continue
		var base_text: String = label.text.trim_prefix("○  ").trim_prefix("✓  ")
		label.text = ("✓  " if states[key] else "○  ") + base_text
		label.add_theme_color_override("font_color", GOOD if states[key] else MUTED)
	var complete: bool = tutorial_created_wire and tutorial_changed_input and tutorial_valid_run and tutorial_removed_wire and tutorial_reconnected_wire
	if complete:
		completed_levels[&"tutorial"] = true
	if tutorial_next_button != null:
		tutorial_next_button.disabled = not complete
		tutorial_next_button.text = _t(&"hardware.tutorial.begin_challenge") if complete else _t(&"hardware.tutorial.complete_five")


func _component_tooltip(component: LogicComponent) -> String:
	var description: String = ""
	match component.kind:
		LogicComponentType.KIND_INPUT:
			description = _t(&"hardware.tooltip.input")
		LogicComponentType.KIND_OUTPUT:
			description = _t(&"hardware.tooltip.output")
		LogicComponentType.KIND_LAMP:
			description = _t(&"hardware.tooltip.lamp")
		LogicComponentType.KIND_AND:
			description = _t(&"hardware.tooltip.and")
		LogicComponentType.KIND_OR:
			description = _t(&"hardware.tooltip.or")
		LogicComponentType.KIND_NOT:
			description = _t(&"hardware.tooltip.not")
		LogicComponentType.KIND_NOR:
			description = _t(&"hardware.tooltip.nor")
		LogicComponentType.KIND_JUNCTION:
			description = _t(&"hardware.tooltip.junction")
		_:
			description = "%s — %s" % [component.display_name, _t(&"hardware.tooltip.logic_component")]
	var port_lines := PackedStringArray()
	if component.input_count() > 0:
		var inputs := PackedStringArray()
		for port: int in range(component.input_count()):
			inputs.append("%s%s" % [
				component.input_port_name(port),
				"×%d" % component.input_width(port) if component.input_width(port) > 1 else "",
			])
		port_lines.append("← " + ", ".join(inputs))
	if component.output_count() > 0:
		var outputs := PackedStringArray()
		for port: int in range(component.output_count()):
			outputs.append("%s%s" % [
				component.output_port_name(port),
				"×%d" % component.output_width(port) if component.output_width(port) > 1 else "",
			])
		port_lines.append("→ " + ", ".join(outputs))
	return description if port_lines.is_empty() else description + "\n" + "\n".join(port_lines)


func _component_display_name(component: LogicComponent) -> String:
	match component.kind:
		LogicComponentType.KIND_INPUT:
			return _t(&"hardware.component.test_input", [component.signal_name])
		LogicComponentType.KIND_OUTPUT:
			return _t(&"hardware.component.probe", [component.signal_name])
		LogicComponentType.KIND_LAMP:
			return _t(&"hardware.component.output_lamp")
	return component.display_name


func _component_kind_text(kind: StringName) -> String:
	match kind:
		LogicComponentType.KIND_INPUT: return _t(&"hardware.kind.input")
		LogicComponentType.KIND_OUTPUT: return _t(&"hardware.kind.output")
		LogicComponentType.KIND_LAMP: return _t(&"hardware.kind.lamp")
		LogicComponentType.KIND_JUNCTION: return _t(&"hardware.kind.junction")
	return String(kind).to_upper()


func _desktop_window_name(id: StringName) -> String:
	return _t(&"hardware.window.mission") if id == &"task" else _t(&"device.test_bench")


func _trace_error_text(trace: CircuitTrace, index: int) -> String:
	if trace == null or index < 0 or index >= trace.errors.size():
		return ""
	if index < trace.error_specs.size():
		return Localization.text_from_spec(trace.error_specs[index])
	return trace.errors[index]


func _trace_errors_text(trace: CircuitTrace) -> String:
	var parts := PackedStringArray()
	for index: int in range(trace.errors.size()):
		parts.append(_trace_error_text(trace, index))
	return " ".join(parts)


func _t(key: StringName, arguments: Array = []) -> String:
	return Localization.text(key, arguments)


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
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	return box


func _compact_stylebox(color: Color, radius: int, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box: StyleBoxFlat = _stylebox(color, radius, border_width, border_color)
	box.content_margin_left = 4.0
	box.content_margin_right = 4.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	return box


func _node_stylebox(color: Color, radius: int, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box: StyleBoxFlat = _stylebox(color, radius, border_width, border_color)
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box


func _make_port_texture(diameter: int) -> Texture2D:
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(diameter - 1), float(diameter - 1)) * 0.5
	for y: int in range(diameter):
		for x: int in range(diameter):
			var distance: float = Vector2(x, y).distance_to(center)
			if distance <= float(diameter) * 0.48:
				var alpha: float = 1.0 if distance <= float(diameter) * 0.38 else 0.72
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _clear_container(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		# A phase-changing Button can be one of these children while its `pressed`
		# signal is still being emitted. Immediate `free()` is illegal for that
		# locked emitter; queueing deletion preserves the same visible transition
		# and releases the detached control safely at the end of the frame.
		child.queue_free()
