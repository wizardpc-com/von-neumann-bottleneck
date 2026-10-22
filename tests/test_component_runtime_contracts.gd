extends SceneTree
## Production renderers and graph contracts; no completion or fixture installation.
const Component = preload("res://src/circuit/logic_component.gd")
const KINDS: Array[StringName] = [&"input", &"output", &"lamp", &"and", &"or", &"xor", &"not", &"nor", &"junction", &"half_adder", &"full_adder", &"mux4", &"alu1", &"sr_latch", &"register1", &"register4", &"decoder1_to_2", &"mux2_word", &"alu4", &"ram2x4", &"control", &"constant", &"tiny_computer"]
var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func run() -> void:
	var host = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(host)
	for frame: int in 5: await process_frame
	var authority: String = host.player_content.canonical_signature()
	for kind: StringName in KINDS:
		var part := Component.new(&"QA", kind, String(kind))
		check(part.is_supported(), "Supported production kind " + String(kind))
		var contract := LogicCircuit.new()
		contract.add_component(part)
		var signature: String = contract.canonical_signature()
		var ghost: Control = host._create_component_placement_ghost(part)
		root.add_child(ghost)
		await process_frame
		var node: GraphNode = ghost.get_child(0)
		check(node.get_input_port_count() == part.input_count() and node.get_output_port_count() == part.output_count(), "Exact port counts " + String(kind))
		var palette: Control = host._create_component_palette_preview(part)
		root.add_child(palette)
		await process_frame
		var palette_node := palette.get_child(0) as GraphNode
		check(palette_node != null and palette_node.get_input_port_count() == part.input_count()
			and palette_node.get_output_port_count() == part.output_count(), "Palette retains full real interface " + String(kind))
		check(signature == contract.canonical_signature(), "Presentation retains component signature " + String(kind))
		palette.free()
		ghost.free()
	for width: int in [1, 2, 4, 8, 32]:
		var part := Component.new(&"VALUE", &"constant", "constant", &"", false, [], [], [], [], {"width":width})
		var ghost: Control = host._create_component_placement_ghost(part)
		var symbol: CircuitComponentSymbol = ghost.get_child(0).get_child(0)
		check(symbol.terminal_width == width, "Constant presentation follows actual source width")
		symbol.set_signal_state(true, true, [], [], "0x3", 3)
		check(symbol.name_layout().text == ("1" if width == 1 else "3"), "Constant shows numeric value rather than nonzero Boolean")
		if width > 1:
			symbol.set_signal_state(true, true, [], [], "value", 4294967295 if width == 32 else 3)
			var label: Dictionary = symbol.name_layout()
			check(label.text_width <= label.max_width and label.font_size >= 10, "Word constant value fits its measured area at a readable size")
		ghost.free()
	# Access-only QA prerequisite; this test installs no reusable component.
	host.player_content.mark_completed(&"tutorial")
	authority = host.player_content.canonical_signature()
	host._start_challenge(false)
	for frame: int in 5: await process_frame
	var circuit: LogicCircuit = host._circuit_from_graph()
	var original: Dictionary = host._freeze_visual_layout(circuit)
	check(not original.is_empty(), "Actual workbench has a frozen footprint")
	for id: StringName in circuit.components:
		if circuit.components[id].fixed_terminal:
			host.component_nodes[id].position_offset += Vector2(5000.0, -3000.0)
	check(host._freeze_visual_layout(circuit) == original, "External test terminal movement cannot reshape packaged internals")
	var and_node: GraphNode = host.component_nodes[&"AND_1"]
	and_node.position_offset += Vector2(0.0, 800.0)
	check(host._freeze_visual_layout(circuit).bands != original.bands, "Actual internal movement changes new frozen shape")
	check(host.player_content.canonical_signature() == authority, "Preview and freezing confer no player results")
	host.queue_free()
	await process_frame
	for failure: String in failures: push_error(failure)
	print(("PASS" if failures.is_empty() else "FAIL") + ": test_component_runtime_contracts %d checks" % checks)
	quit(0 if failures.is_empty() else 1)
