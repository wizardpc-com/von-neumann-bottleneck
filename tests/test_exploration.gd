extends SceneTree

const C = preload("res://src/circuit/logic_component.gd")
const Simulator = preload("res://src/circuit/prologue_simulator.gd")
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var main: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(main)
	for _frame: int in range(4):
		await process_frame
	var catalog = main.get("level_catalog")
	var library: Dictionary = main.get("component_library")
	_assert(catalog.dependencies(&"selector") == [&"half_adder"] and catalog.dependencies(&"delay") == [&"register"], "Exploration nodes must branch from earned tools.")
	_assert(catalog.dependencies(&"full_adder") == [&"half_adder"] and catalog.dependencies(&"ram") == [&"register"], "Optional applications must never become old mainline prerequisites.")
	for id: StringName in [&"selector", &"delay", &"selector4", &"parity", &"alarm"]:
		main.call("_start_prologue_level", id, false)
		await process_frame
		var definition: Dictionary = catalog.definition(id, library)
		var reference: LogicCircuit = catalog.reference_circuit(id, library)
		var report: Dictionary = Simulator.new().run_sequence(reference, definition["official_steps"])
		_assert(report["passed"], "%s reference must pass the actual simulator, not a renderer mock." % id)
		_assert(Simulator.new().run_sequence(reference, definition["official_steps"])["runtime_state"] == report["runtime_state"], "Repeated sequence runs must reset to the same deterministic initial state.")
		for component: LogicComponent in main.get("component_catalog").values():
			_assert(component.fixed_terminal, "New application boards must start with public I/O only.")
		var signature: String = main.call("_circuit_from_graph").canonical_signature()
		var first: Dictionary = main.call("_build_hint_snapshot", 1)
		var partial: Dictionary = main.call("_build_hint_snapshot", 2)
		var complete: Dictionary = main.call("_build_hint_snapshot", 3)
		_assert(first["wires"].is_empty() and partial["wires"].size() < complete["wires"].size() and complete["components"].size() == reference.components.size(), "Blank player seeds must not erase the independent staged reference boards.")
		_assert(main.call("_circuit_from_graph").canonical_signature() == signature, "Inspecting hints must not install reference components in the player board.")
		var broken: LogicCircuit = reference.duplicate_circuit()
		broken.wires.clear()
		_assert(not Simulator.new().run_sequence(broken, definition["official_steps"])["passed"], "No-wire answers must fail both applications.")
	main.call("_start_prologue_level", &"delay", false)
	await process_frame
	_assert(main.call("_storage_action_text", {&"DATA": 7, &"ACCEPT": 1}) != main.call("_storage_action_text", {&"DATA": 7, &"ACCEPT": 0}), "Delay acceptance and HOLD must not share misleading action captions.")
	_test_alternative_selector(catalog, library)
	main.call("_start_prologue_level", &"delay", false)
	await process_frame
	# Search must filter presentation, without changing the allowed supply or arming a part.
	var original_keys: Array = main.get("component_menu_template_keys").duplicate()
	var search: LineEdit = main.get("palette_search")
	search.text = "寄存器"
	main.call("_filter_component_palette")
	_assert(not main.get("palette_empty").visible and main.get("armed_component_template_key").is_empty(), "Chinese search must find a register without placing it.")
	search.text = "Register"
	main.call("_filter_component_palette")
	_assert(not main.get("palette_empty").visible and original_keys == main.get("component_menu_template_keys"), "Abbreviation/English search must preserve the authoritative supply.")
	search.text = "unavailable query"
	main.call("_filter_component_palette")
	_assert(main.get("palette_empty").visible, "Empty search results must explain how to recover.")
	main.call("_start_prologue_level", &"ram", false)
	await process_frame
	var seed: Dictionary = main.get("workbench_seed_snapshot").duplicate(true)
	var previous: String = main.call("_circuit_from_graph").canonical_signature()
	_assert(main.call("_create_named_workbench", "empty application", true), "Blank design must be a new named scheme.")
	for component: LogicComponent in main.get("component_catalog").values():
		_assert(component.fixed_terminal, "Blank creation keeps only public terminals.")
	_assert(main.get("workbench_seed_snapshot") == seed, "New blank schemes must not alter the authored seed fingerprint.")
	main.call("_switch_workbench", "default")
	_assert(main.call("_circuit_from_graph").canonical_signature() == previous, "The existing default board must remain unchanged after blank creation.")
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: optional applications, alternative logic, blank schemes, staged hints and palette search")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _test_alternative_selector(catalog, library: Dictionary) -> void:
	# A XOR ((A XOR B) AND S) is a distinct three-gate implementation.
	var definition: Dictionary = catalog.definition(&"selector", library)
	var circuit := LogicCircuit.new()
	for component: LogicComponent in definition["components"]:
		if component.fixed_terminal:
			circuit.add_component(component.duplicate_component())
	circuit.add_component(C.new(&"DIFFERENCE", C.KIND_XOR, "XOR"))
	circuit.add_component(C.new(&"ENABLE", C.KIND_AND, "AND"))
	circuit.add_component(C.new(&"CHOOSE", C.KIND_XOR, "XOR"))
	for wire: Array in [[&"A_IN",0,&"DIFFERENCE",0],[&"B_IN",0,&"DIFFERENCE",1],
		[&"DIFFERENCE",0,&"ENABLE",0],[&"S_IN",0,&"ENABLE",1],
		[&"A_IN",0,&"CHOOSE",0],[&"ENABLE",0,&"CHOOSE",1],[&"CHOOSE",0,&"OUT",0]]:
		circuit.connect_ports(wire[0],wire[1],wire[2],wire[3])
	_assert(Simulator.new().run_sequence(circuit, definition["official_steps"])["passed"], "A different gate count, topology and all-new internal IDs must pass the full public selector table.")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
