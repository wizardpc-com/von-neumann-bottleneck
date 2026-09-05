extends VBoxContainer

signal design_changed(design: Dictionary)
signal inspected(component: LogicComponent)

const Foundations = preload("res://src/demo/demo_foundations.gd")
const ModuleRow = preload("res://src/hardware_foundations/circuit_module_row.gd")

var circuit: LogicCircuit
var graph: GraphEdit
var status: Label
var graph_nodes: Dictionary = {}
var input_values: Dictionary = {}
var runtime_state: Dictionary = {}
var prior_outputs: Dictionary = {}
var live_labels: Dictionary = {}
var resetting := false


func _ready() -> void:
	var row := HBoxContainer.new()
	add_child(row)
	for entry: Array in [["demo.step", commit_step], ["demo.reset_state", reset_state]]:
		var button := Button.new()
		button.text = Localization.text(StringName(entry[0]))
		button.pressed.connect(entry[1])
		row.add_child(button)
	var fit := Button.new()
	fit.text = Localization.text(&"demo.fit")
	fit.pressed.connect(fit_circuit)
	row.add_child(fit)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(status)
	graph = GraphEdit.new()
	graph.name = "Circuit"
	graph.size_flags_vertical = SIZE_EXPAND_FILL
	graph.custom_minimum_size.y = 330
	graph.right_disconnects = true
	graph.minimap_enabled = false
	graph.connection_request.connect(connect_wire)
	graph.disconnection_request.connect(disconnect_wire)
	graph.node_selected.connect(func(node: Node) -> void:
		if circuit.components.has(StringName(node.name)):
			inspected.emit(circuit.components[StringName(node.name)])
	)
	graph.end_node_move.connect(_layout_changed)
	graph.add_valid_connection_type(1, 1)
	graph.add_valid_connection_type(4, 4)
	add_child(graph)


func load_design(design: Dictionary) -> void:
	resetting = true
	circuit = Foundations.restore(design)
	graph.clear_connections()
	for node: Node in graph_nodes.values():
		node.free()
	graph_nodes.clear()
	live_labels.clear()
	input_values.clear()
	runtime_state.clear()
	prior_outputs.clear()
	if circuit == null:
		status.text = Localization.text(&"demo.error.supply")
		resetting = false
		return
	var positions: Dictionary = design.get("layout", {})
	var layout := {
		"A": Vector2(30, 60), "B": Vector2(30, 220), "SEL": Vector2(30, 380),
		"MUX": Vector2(350, 170), "OUT": Vector2(700, 170),
		"DATA": Vector2(30, 60), "LOAD": Vector2(30, 220), "WRITE": Vector2(30, 380),
		"READ": Vector2(230, 60), "ADDR": Vector2(230, 380),
		"SOURCE": Vector2(440, 60), "REG": Vector2(670, 60), "RAM": Vector2(670, 350),
		"Q": Vector2(900, 60), "MEM": Vector2(900, 350),
	}
	for key: StringName in circuit.components:
		var part: LogicComponent = circuit.components[key]
		var node := GraphNode.new()
		node.name = key
		node.title = part.display_name
		var position: Vector2 = layout.get(String(key), Vector2(350, 60))
		if positions.has(String(key)) and positions[String(key)] is Array and positions[String(key)].size() == 2:
			position = Vector2(float(positions[String(key)][0]), float(positions[String(key)][1]))
		node.position_offset = position
		graph.add_child(node)
		graph_nodes[key] = node
		var rows := maxi(part.input_count(), part.output_count())
		for port: int in range(rows):
			var module := ModuleRow.new()
			module.custom_minimum_size = Vector2(145, 36)
			module.configure(part.kind, part.display_name, String(part.input_port_name(port)), String(part.output_port_name(port)), port, rows, port < part.input_count(), port < part.output_count(), part.input_width(port), part.output_width(port))
			node.add_child(module)
			node.set_slot(port, port < part.input_count(), part.input_width(port), Color("eac479") if part.input_width(port) == 4 else Color("bfa9f2"), port < part.output_count(), part.output_width(port), Color("eac479") if part.output_width(port) == 4 else Color("bfa9f2"))
		if part.kind == &"input":
			var input := SpinBox.new()
			input.min_value = 0
			input.max_value = 15 if part.output_width(0) == 4 else 1
			input.step = 1
			input.value_changed.connect(func(value: float) -> void:
				input_values[String(key)] = int(value)
				preview()
			)
			node.add_child(input)
			input_values[String(key)] = 0
		var live := Label.new()
		live.add_theme_font_size_override("font_size", 16)
		node.add_child(live)
		live_labels[key] = live
	for wire: LogicWire in circuit.wires:
		graph.connect_node(wire.from_component, wire.from_port, wire.to_component, wire.to_port)
	resetting = false
	preview()
	call_deferred("fit_circuit")


func fit_circuit() -> void:
	if graph_nodes.is_empty():
		return
	var bounds := Rect2()
	var first := true
	for node: GraphNode in graph_nodes.values():
		var rect := Rect2(node.position_offset, node.size)
		bounds = rect if first else bounds.merge(rect)
		first = false
	graph.zoom = clampf(minf((graph.size.x - 60.0) / bounds.size.x, (graph.size.y - 75.0) / bounds.size.y), 0.35, 1.0)
	graph.scroll_offset = bounds.position * graph.zoom - Vector2(25, 55)


func current_design() -> Dictionary:
	var design := Foundations.snapshot(circuit)
	var layout: Dictionary = {}
	for key: StringName in graph_nodes:
		var position: Vector2 = graph_nodes[key].position_offset
		layout[String(key)] = [position.x, position.y]
	design["layout"] = layout
	return design


func connect_wire(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	if circuit == null:
		return
	var diagnostic := circuit.connect_ports_detailed(from, from_port, to, to_port)
	if not diagnostic.is_empty():
		status.text = Localization.text(diagnostic["key"], diagnostic["args"])
		return
	graph.connect_node(from, from_port, to, to_port)
	_changed()


func disconnect_wire(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	if circuit.disconnect_ports(from, from_port, to, to_port):
		graph.disconnect_node(from, from_port, to, to_port)
		_changed()


func _changed() -> void:
	runtime_state.clear()
	prior_outputs.clear()
	design_changed.emit(current_design())
	preview()


func _layout_changed() -> void:
	if not resetting and circuit != null:
		design_changed.emit(current_design())


func preview() -> void:
	if circuit == null or resetting:
		return
	var result := Foundations.Simulator.new().evaluate(circuit, input_values, prior_outputs, runtime_state)
	if not result.is_valid():
		status.text = Localization.text(&"demo.circuit_invalid")
		if not result.error_specs.is_empty():
			var diagnostic: Dictionary = result.error_specs[0]
			status.text += " " + Localization.text(diagnostic["key"], diagnostic["args"])
		return
	status.text = Localization.text(&"demo.preview_only")
	for key: StringName in live_labels:
		var part: LogicComponent = circuit.components[key]
		var value: DigitalValue = result.input_value(key, 0, part.input_width(0)) if part.is_observer() else result.output_value(key, 0, part.output_width(0))
		live_labels[key].text = value.display_text()
		live_labels[key].modulate = Color("67e8a5") if value.is_known() and value.value != 0 else Color("ff6b7d")
		if part.is_stateful():
			live_labels[key].text = Localization.text(&"demo.stored") + " " + value.display_text()
		if part.kind == &"ram2x4":
			var memories: Dictionary = runtime_state.get("ram", {})
			live_labels[key].text += " " + str(memories.get(key, [0, 0]))


func commit_step() -> void:
	if circuit == null:
		return
	var steps: Array[Dictionary] = [{"inputs": input_values.duplicate(true)}]
	var result := Foundations.Simulator.new().run_sequence(circuit, steps, false, runtime_state, prior_outputs)
	if not result["passed"]:
		status.text = Localization.text(&"demo.circuit_invalid")
		return
	runtime_state = result["runtime_state"]
	prior_outputs = result["prior_outputs"]
	preview()
	status.text = Localization.text(&"demo.step_committed")


func reset_state() -> void:
	runtime_state.clear()
	prior_outputs.clear()
	preview()
