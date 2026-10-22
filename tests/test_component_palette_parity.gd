extends "res://tests/test_global_save.gd"
## QA-only constructor/geometry comparison; no save, reward or fixture installation.
const VisualLayout = preload("res://src/hardware_foundations/component_visual_layout.gd")
const PaletteItem = preload("res://src/hardware_foundations/component_palette_item.gd")
const KINDS: Array[StringName] = [&"input", &"output", &"lamp", &"and", &"or", &"xor", &"not", &"nor", &"junction", &"half_adder", &"full_adder", &"mux4", &"alu1", &"sr_latch", &"register1", &"register4", &"decoder1_to_2", &"mux2_word", &"alu4", &"ram2x4", &"control", &"constant", &"tiny_computer"]
var parity_checks: int = 0

func ensure(ok: bool, text: String) -> void:
	parity_checks += 1
	_assert(ok, text)

func settled() -> void:
	for frame: int in 5: await process_frame

func geometry(node: GraphNode) -> String:
	var rows: Array = []
	for child: Node in node.get_children():
		if child is CircuitModuleRow:
			rows.append([child.position, child.size, child.component_kind, child.row_index, child.row_count,
				child.input_label, child.output_label, child.input_width, child.output_width,
				child.body_polygon(), child.port_label_layouts(), child.visual_bands])
		elif child is CircuitComponentSymbol:
			rows.append([child.position, child.size, child.component_kind, child.terminal_width, child.name_layout()])
		elif child is Label:
			rows.append([child.position, child.size, child.text])
	var ports: Array = []
	for index: int in node.get_input_port_count():
		ports.append(["input", index, node.get_input_port_slot(index), node.get_input_port_position(index)])
	for index: int in node.get_output_port_count():
		ports.append(["output", index, node.get_output_port_slot(index), node.get_output_port_position(index)])
	return JSON.stringify([node.size, rows, ports])

func compare_views(host, component: LogicComponent) -> void:
	var signature: String = JSON.stringify(component.to_dictionary())
	host._add_catalog_component(component)
	host._add_component_node(component, Vector2(240, 180))
	var actual: GraphNode = host.component_nodes[component.id]
	var item := PaletteItem.new()
	item.configure("qa", component.kind, String(component.kind))
	var palette: Control = host._create_component_palette_preview(component)
	item.set_component_preview(palette)
	host.add_child(item)
	item.size = item.custom_minimum_size
	var ghost: Control = host._create_component_placement_ghost(component)
	host.add_child(ghost)
	await settled()
	item.size = item.custom_minimum_size
	await settled()
	var label: String = String(component.kind) + " " + str(component.properties)
	ensure(host.graph.is_visible_in_tree() and actual.is_visible_in_tree(), "Compare a visible, settled GraphEdit node: " + label)
	ensure(palette.get_child(0) is GraphNode, "Palette uses a complete node: " + label)
	ensure(geometry(actual) == geometry(palette.get_child(0)), "Palette geometry/ports/frozen rows equal actual node: " + label)
	ensure(geometry(actual) == geometry(ghost.get_child(0)), "Placement geometry equals actual node: " + label)
	if component.properties.has("library_name"):
		var definition: ReusableComponent = host.component_library[StringName(component.properties.library_name)]
		var heading: CircuitModuleRow = actual.get_child(0)
		ensure(not heading.visual_bands.is_empty() and heading.visual_bands == definition.visual_snapshot.bands,
			"Actual palette/placement comparison consumes the source-bound frozen bands: " + label)
	ensure(actual.size == host._component_node_size(component) and ghost.size == actual.size and palette.size == actual.size,
		"Declared/preview/actual footprints agree: " + label)
	var bounds := Rect2(Vector2.ZERO, item.size)
	ensure(bounds.encloses(Rect2(palette.position, palette.size * palette.scale)), "Card encloses full uniformly scaled preview: " + label)
	ensure(is_equal_approx(palette.scale.x, palette.scale.y), "Palette preserves aspect ratio: " + label)
	for node: GraphNode in [actual, palette.get_child(0), ghost.get_child(0)]:
		ensure(node.get_input_port_count() == component.input_count() and node.get_output_port_count() == component.output_count(), "Real indexed port counts retained: " + label)
	if component.kind == &"constant":
		var expected := DigitalValue.known(component.output_width(0), int(component.properties.get("value", 0)))
		for node: GraphNode in [actual, palette.get_child(0), ghost.get_child(0)]:
			var symbol: CircuitComponentSymbol = node.get_child(0)
			ensure(symbol.name_layout().text == str(expected.value) and symbol.terminal_width == expected.width, "Constant shows configured numeric value and width: " + label)
	ensure(signature == JSON.stringify(component.to_dictionary()), "Views do not mutate logical component: " + label)
	actual.free()
	host.component_nodes.erase(component.id)
	host.component_catalog.erase(component.id)
	host.current_circuit.remove_component(component.id)
	item.free()
	ghost.free()

func _run() -> void:
	var host = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(host)
	host._show_tutorial(false)
	await settled()
	# The production panel is visible to exercise native GraphNode child fitting.
	var parent: Node = host.graph
	while parent != null:
		if parent is CanvasItem: parent.show()
		parent = parent.get_parent()
	host.graph.zoom = 1.0
	var authority: String = host.player_content.canonical_signature()
	for kind: StringName in KINDS:
		await compare_views(host, LogicComponent.new(&"PARITY", kind, "Parity"))
	for width: int in [1, 4, 8, 32]:
		for value: int in [0, 1, 15, 4294967295]:
			await compare_views(host, LogicComponent.new(&"PARITY", &"constant", "Constant", &"", false, [], [], [], [], {"width": width, "value": value}))
	ensure(host.player_content.canonical_signature() == authority, "Constructor tests confer no player results")
	# Valid provenance fixture is local to this test host; never awarded or saved.
	var definition := ReusableComponent.new(&"ParityFrozen", &"half_adder", &"half_adder", _half_adder_circuit())
	host.component_library = host.component_library.duplicate()
	host.component_library[&"ParityFrozen"] = definition
	var source_before: String = definition.canonical_signature()
	var frozen_digests: Array[String] = []
	for offset: int in [0, 180]:
		definition.visual_snapshot = VisualLayout.freeze(definition.source_signature, {"A": {"x": 0, "y": 0, "w": 124, "h": 102}, "B": {"x": 180, "y": offset, "w": 112, "h": 78}})
		frozen_digests.append(definition.visual_snapshot.layout_digest)
		var part: LogicComponent = definition.instantiate(&"PARITY", "Frozen")
		part.properties["library_name"] = "ParityFrozen"
		await compare_views(host, part)
	ensure(source_before == definition.canonical_signature(), "Frozen presentation preserves reusable identity")
	ensure(frozen_digests[0] != frozen_digests[1], "Distinct QA arrangements exercise distinct frozen presentations")
	ensure(host.player_content.canonical_signature() == authority, "Frozen preview fixture remains outside player content")
	host.free()
	await settled()
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "component palette parity %d checks, %d failures" % [parity_checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
