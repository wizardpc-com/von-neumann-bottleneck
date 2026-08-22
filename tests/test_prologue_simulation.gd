extends SceneTree

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const PrologueSimulatorType = preload("res://src/circuit/prologue_simulator.gd")
const ReusableComponentType = preload("res://src/circuit/reusable_component.gd")
const PrologueLevelCatalogType = preload("res://src/hardware_foundations/prologue_level_catalog.gd")

var failures: Array[String] = []
var simulator := PrologueSimulatorType.new()


func _init() -> void:
	_test_width_validation()
	_test_junction_zero_latency()
	_test_xor_gate()
	_test_full_adder_truth_table()
	_test_cross_coupled_latch_sequence()
	_test_register_sequence()
	_test_ram_sequence()
	_test_tiny_computer_sequence()
	_test_campaign_catalog()
	if failures.is_empty():
		print("PASS: deterministic reusable-component, latch, register, RAM, and tiny-computer prologue tests passed")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _test_width_validation() -> void:
	var circuit := LogicCircuitType.new()
	_add(circuit, LogicComponentType.new(&"WORD", &"input", "WORD", &"WORD", true, [], [], [], [], {"width": 4}))
	_add(circuit, LogicComponentType.new(&"BIT", &"output", "BIT", &"BIT", true))
	var diagnostic: Dictionary = circuit.connection_diagnostic(&"WORD", 0, &"BIT", 0)
	_assert(StringName(diagnostic.get("key", &"")) == &"circuit.connection.width_mismatch", "A four-bit output must not connect to a one-bit input.")


func _test_junction_zero_latency() -> void:
	var direct := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A", &"input", "A", &"A", true),
		LogicComponentType.new(&"NOT", &"not", "not"),
		LogicComponentType.new(&"OUT", &"output", "OUT", &"OUT", true),
	]:
		_add(direct, component)
	_wire(direct, &"A", 0, &"NOT", 0)
	_wire(direct, &"NOT", 0, &"OUT", 0)

	var routed := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A", &"input", "A", &"A", true),
		LogicComponentType.new(&"J1", &"junction", "J1"),
		LogicComponentType.new(&"J2", &"junction", "J2"),
		LogicComponentType.new(&"NOT", &"not", "not"),
		LogicComponentType.new(&"J3", &"junction", "J3"),
		LogicComponentType.new(&"OUT", &"output", "OUT", &"OUT", true),
	]:
		_add(routed, component)
	_wire(routed, &"A", 0, &"J1", 0)
	_wire(routed, &"J1", 0, &"J2", 0)
	_wire(routed, &"J2", 0, &"NOT", 0)
	_wire(routed, &"NOT", 0, &"J3", 0)
	_wire(routed, &"J3", 0, &"OUT", 0)
	var direct_result = simulator.evaluate(direct, {&"A": 0})
	var routed_result = simulator.evaluate(routed, {&"A": 0})
	_assert(direct_result.is_valid() and routed_result.is_valid(), "Direct and multi-segment NOT circuits must both settle.")
	_assert(direct_result.observed_values[&"OUT"].equals(routed_result.observed_values[&"OUT"]), "Routing nodes must not change the electrical result.")
	_assert(direct_result.settle_ticks == routed_result.settle_ticks, "Adding any number of routing nodes must add zero simulation ticks.")
	var source_wire_steps: Dictionary[int, bool] = {}
	var source_wire_count: int = 0
	for event: PrologueEvent in routed_result.events:
		if event.kind == &"wire_signal" and event.from_component in [&"A", &"J1", &"J2"]:
			source_wire_steps[event.visual_step] = true
			source_wire_count += 1
	_assert(source_wire_count == 3 and source_wire_steps.size() == 1, "Every segment of one zero-delay routed net must animate in the same parallel wave.")


func _test_xor_gate() -> void:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A", LogicComponentType.KIND_INPUT, "A", &"A", true),
		LogicComponentType.new(&"B", LogicComponentType.KIND_INPUT, "B", &"B", true),
		LogicComponentType.new(&"XOR", LogicComponentType.KIND_XOR, "xor"),
		LogicComponentType.new(&"OUT", LogicComponentType.KIND_OUTPUT, "OUT", &"OUT", true),
	]:
		_add(circuit, component)
	_wire(circuit, &"A", 0, &"XOR", 0)
	_wire(circuit, &"B", 0, &"XOR", 1)
	_wire(circuit, &"XOR", 0, &"OUT", 0)
	for a: int in range(2):
		for b: int in range(2):
			var result = simulator.evaluate(circuit, {&"A": a, &"B": b})
			_assert(result.is_valid() and result.observed_values[&"OUT"].value == (a ^ b), "Prologue XOR must match its truth table for %d,%d." % [a, b])
			var replay = simulator.evaluate(circuit, {&"A": a, &"B": b})
			_assert(result.canonical_signature() == replay.canonical_signature(), "Prologue XOR evaluation must remain deterministic for %d,%d." % [a, b])


func _test_full_adder_truth_table() -> void:
	var circuit: LogicCircuit = _full_adder_circuit()
	var steps: Array[Dictionary] = []
	for a: int in range(2):
		for b: int in range(2):
			for carry_in: int in range(2):
				var total: int = a + b + carry_in
				steps.append({
					"inputs": {&"A": a, &"B": b, &"CIN": carry_in},
					"expected": {&"SUM": total & 1, &"COUT": 1 if total >= 2 else 0},
				})
	var first: Dictionary = simulator.run_sequence(circuit, steps)
	var second: Dictionary = simulator.run_sequence(circuit, steps)
	_assert(bool(first["passed"]), "Two sealed HalfAdder instances plus OR must pass the complete Full Adder truth table.")
	_assert(first["canonical_signature"] == second["canonical_signature"], "Full Adder temporal evaluation must be deterministic.")


func _test_cross_coupled_latch_sequence() -> void:
	var circuit: LogicCircuit = _latch_circuit()
	var sequence: Array[Dictionary] = [
		{"inputs": {&"S": 0, &"R": 1}, "expected": {&"Q": 0, &"NQ": 1}},
		{"inputs": {&"S": 0, &"R": 0}, "expected": {&"Q": 0, &"NQ": 1}},
		{"inputs": {&"S": 1, &"R": 0}, "expected": {&"Q": 1, &"NQ": 0}},
		{"inputs": {&"S": 0, &"R": 0}, "expected": {&"Q": 1, &"NQ": 0}},
		{"inputs": {&"S": 0, &"R": 1}, "expected": {&"Q": 0, &"NQ": 1}},
	]
	var report: Dictionary = simulator.run_sequence(circuit, sequence, true)
	_assert(bool(report["passed"]), "A visible two-NOR feedback loop must retain set/reset state across the official sequence.")
	var feedback_events_per_step: Dictionary[int, Array] = {}
	var hold_boundaries: Dictionary[int, bool] = {}
	for event: PrologueEvent in report["events"]:
		if event.kind != &"state_transition":
			continue
		var step_events: Array = feedback_events_per_step.get(event.sequence_step, [])
		step_events.append(event)
		feedback_events_per_step[event.sequence_step] = step_events
		if event.message_key == &"hardware.trace.state.feedback_hold":
			hold_boundaries[event.sequence_step] = true
	for step_index: int in range(sequence.size()):
		_assert((feedback_events_per_step.get(step_index, []) as Array).size() == 2, "Both visible NOR gates must acknowledge every latch boundary in one parallel feedback wave.")
	_assert(hold_boundaries.has(1) and hold_boundaries.has(3), "An unchanged raw-latch HOLD must still produce explicit feedback processing.")
	var rejected: Dictionary = simulator.run_sequence(circuit, sequence, false)
	_assert(not bool(rejected["passed"]), "The same feedback must remain illegal outside the explicitly temporal latch level.")


func _test_register_sequence() -> void:
	var circuit: LogicCircuit = _register_circuit()
	var sequence: Array[Dictionary] = [
		{"inputs": {&"D": 0, &"LOAD": 1}, "expected": {&"Q": 0}},
		{"inputs": {&"D": 1, &"LOAD": 1}, "expected": {&"Q": 1}},
		{"inputs": {&"D": 0, &"LOAD": 0}, "expected": {&"Q": 1}},
		{"inputs": {&"D": 0, &"LOAD": 1}, "expected": {&"Q": 0}},
		{"inputs": {&"D": 1, &"LOAD": 0}, "expected": {&"Q": 0}},
	]
	var report: Dictionary = simulator.run_sequence(circuit, sequence)
	_assert(bool(report["passed"]), "D/LOAD gating around the player's SRLatch must behave as a one-bit register.")
	var state_events: Array[PrologueEvent] = []
	var hold_steps: Dictionary[int, bool] = {}
	for event: PrologueEvent in report["events"]:
		if event.kind != &"state_transition":
			continue
		state_events.append(event)
		if event.message_key == &"hardware.trace.state.hold":
			hold_steps[event.sequence_step] = true
	_assert(state_events.size() == sequence.size(), "Every register clock boundary must emit one explicit latch-state event, including unchanged output.")
	_assert(hold_steps.has(2) and hold_steps.has(4), "LOAD=0 must emit a visible HOLD boundary even when no component output changes.")


func _test_ram_sequence() -> void:
	var circuit: LogicCircuit = _ram_circuit()
	var sequence: Array[Dictionary] = [
		{"inputs": {&"ADDR": 0, &"DATA": 3, &"WRITE": 1}, "expected": {&"OUT": 3}},
		{"inputs": {&"ADDR": 1, &"DATA": 12, &"WRITE": 1}, "expected": {&"OUT": 12}},
		{"inputs": {&"ADDR": 0, &"DATA": 0, &"WRITE": 0}, "expected": {&"OUT": 3}},
		{"inputs": {&"ADDR": 0, &"DATA": 5, &"WRITE": 1}, "expected": {&"OUT": 5}},
		{"inputs": {&"ADDR": 1, &"DATA": 0, &"WRITE": 0}, "expected": {&"OUT": 12}},
	]
	var report: Dictionary = simulator.run_sequence(circuit, sequence)
	_assert(bool(report["passed"]), "Decoder + two Register4 components + word mux must preserve two independent RAM addresses.")
	var events_per_step: Dictionary[int, Array] = {}
	var visual_step_per_sequence: Dictionary[int, Dictionary] = {}
	var saw_write: bool = false
	var saw_hold: bool = false
	for event: PrologueEvent in report["events"]:
		if event.kind != &"state_transition":
			continue
		if not events_per_step.has(event.sequence_step):
			events_per_step[event.sequence_step] = []
		var step_events: Array = events_per_step[event.sequence_step]
		step_events.append(event)
		events_per_step[event.sequence_step] = step_events
		if not visual_step_per_sequence.has(event.sequence_step):
			visual_step_per_sequence[event.sequence_step] = {}
		var step_visuals: Dictionary = visual_step_per_sequence[event.sequence_step]
		step_visuals[event.visual_step] = true
		visual_step_per_sequence[event.sequence_step] = step_visuals
		saw_write = saw_write or event.message_key == &"hardware.trace.state.write"
		saw_hold = saw_hold or event.message_key == &"hardware.trace.state.hold"
	for step_index: int in range(sequence.size()):
		_assert((events_per_step.get(step_index, []) as Array).size() == 2, "Each RAM boundary must expose both physical Register4 cells.")
		_assert((visual_step_per_sequence.get(step_index, {}) as Dictionary).size() == 1, "Both RAM cells must commit or hold in the same parallel animation wave.")
	_assert(saw_write and saw_hold, "RAM playback must distinguish selected-cell WRITE from unselected-cell HOLD.")


func _test_tiny_computer_sequence() -> void:
	var circuit: LogicCircuit = _tiny_computer_circuit()
	var sequence: Array[Dictionary] = [
		{"inputs": {&"OP": 0, &"ARG": 3, &"ADDR": 0}, "expected": {&"ACC": 3, &"MEM": 0}},
		{"inputs": {&"OP": 3, &"ARG": 0, &"ADDR": 0}, "expected": {&"ACC": 3, &"MEM": 3}},
		{"inputs": {&"OP": 0, &"ARG": 5, &"ADDR": 1}, "expected": {&"ACC": 5, &"MEM": 0}},
		{"inputs": {&"OP": 1, &"ARG": 2, &"ADDR": 1}, "expected": {&"ACC": 7, &"MEM": 0}},
		{"inputs": {&"OP": 3, &"ARG": 0, &"ADDR": 1}, "expected": {&"ACC": 7, &"MEM": 7}},
		{"inputs": {&"OP": 2, &"ARG": 0, &"ADDR": 0}, "expected": {&"ACC": 3, &"MEM": 3}},
		{"inputs": {&"OP": 1, &"ARG": 4, &"ADDR": 0}, "expected": {&"ACC": 7, &"MEM": 3}},
	]
	var first: Dictionary = simulator.run_sequence(circuit, sequence)
	var second: Dictionary = simulator.run_sequence(circuit, sequence)
	_assert(bool(first["passed"]), "The graph-built accumulator computer must execute LOAD_IMM, ADD_IMM, LOAD_MEM, and STORE_MEM.")
	_assert(first["canonical_signature"] == second["canonical_signature"], "The same computer/program must produce an identical canonical temporal trace.")
	_assert((first["events"] as Array).size() > 20, "The computer run must expose enough component/wire events for causal playback.")


func _test_campaign_catalog() -> void:
	var catalog := PrologueLevelCatalogType.new()
	var library: Dictionary = {}
	var completed: Dictionary = {}
	_assert(catalog.level_ids().slice(0, 2) == [&"tutorial", &"half_adder"], "The campaign catalog must visibly begin with the wiring tutorial and Half Adder.")
	_assert(catalog.is_unlocked(&"tutorial", completed), "The wiring tutorial must be the only root prerequisite.")
	_assert(not catalog.is_unlocked(&"half_adder", completed), "Half Adder must stay locked until the tutorial is complete.")
	completed[&"tutorial"] = true
	_assert(catalog.is_unlocked(&"half_adder", completed), "Tutorial completion must unlock Half Adder.")
	completed[&"half_adder"] = true
	library[&"HalfAdder"] = ReusableComponentType.new(
		&"HalfAdder", LogicComponentType.KIND_HALF_ADDER, &"half_adder", _full_adder_circuit()
	)
	_assert(catalog.is_unlocked(&"full_adder", completed), "HalfAdder completion must unlock Full Adder.")
	_assert(catalog.is_unlocked(&"latch", completed), "HalfAdder completion must unlock the independent latch branch.")
	_assert(not catalog.is_unlocked(&"cpu", completed), "CPU must stay locked until ALU and RAM are both complete.")

	var full_definition: Dictionary = catalog.definition(&"full_adder", library)
	var full_circuit: LogicCircuit = catalog.reference_circuit(&"full_adder", library)
	var full_report: Dictionary = simulator.run_sequence(full_circuit, full_definition["official_steps"])
	_assert(bool(full_report["passed"]), "Catalog Full Adder reference topology must pass its complete official table.")
	var broken_full: LogicCircuit = full_circuit.duplicate_circuit()
	broken_full.disconnect_ports(&"OR_1", 0, &"COUT_OUT", 0)
	_assert(not bool(simulator.run_sequence(broken_full, full_definition["official_steps"])["passed"]), "A Full Adder with a missing visible COUT wire must fail official evidence.")
	library[&"FullAdder"] = ReusableComponentType.new(
		&"FullAdder", LogicComponentType.KIND_FULL_ADDER, &"full_adder", full_circuit
	)
	completed[&"full_adder"] = true

	var alu_definition: Dictionary = catalog.definition(&"alu", library)
	var alu_circuit: LogicCircuit = catalog.reference_circuit(&"alu", library)
	_assert((alu_definition["official_steps"] as Array).size() == 32, "The ALU bench must exhaust all A/B/CIN values across all four operations.")
	_assert(bool(simulator.run_sequence(alu_circuit, alu_definition["official_steps"])["passed"]), "Catalog ALU reference topology must select AND, OR, ADD, and NOT-A correctly.")
	var broken_alu: LogicCircuit = alu_circuit.duplicate_circuit()
	broken_alu.disconnect_ports(&"OP1_IN", 0, &"MUX", 5)
	_assert(not bool(simulator.run_sequence(broken_alu, alu_definition["official_steps"])["passed"]), "An ALU whose operation selector is not visibly wired must fail official evidence.")
	var alu1 := ReusableComponentType.new(&"ALU1", LogicComponentType.KIND_ALU1, &"alu", alu_circuit)
	library[&"ALU1"] = alu1
	library[&"ALU4"] = ReusableComponentType.new(
		&"ALU4", LogicComponentType.KIND_ALU4, &"alu", null,
		[alu1.source_signature], {"auto_expanded_bits": 4}
	)
	completed[&"alu"] = true

	var latch_definition: Dictionary = catalog.definition(&"latch", library)
	var latch_circuit: LogicCircuit = catalog.reference_circuit(&"latch", library)
	_assert(bool(simulator.run_sequence(latch_circuit, latch_definition["official_steps"], true)["passed"]), "Catalog latch must retain state through its official temporal sequence.")
	var broken_latch: LogicCircuit = latch_circuit.duplicate_circuit()
	broken_latch.disconnect_ports(&"NOR_NQ", 0, &"NOR_Q", 1)
	_assert(not bool(simulator.run_sequence(broken_latch, latch_definition["official_steps"], true)["passed"]), "A latch missing one visible feedback segment must fail hold cases.")
	library[&"SRLatch"] = ReusableComponentType.new(
		&"SRLatch", LogicComponentType.KIND_SR_LATCH, &"latch", latch_circuit
	)
	completed[&"latch"] = true

	var register_definition: Dictionary = catalog.definition(&"register", library)
	var register_circuit: LogicCircuit = catalog.reference_circuit(&"register", library)
	_assert(bool(simulator.run_sequence(register_circuit, register_definition["official_steps"])["passed"]), "Catalog Register1 must preserve D while LOAD is low.")
	var broken_register: LogicCircuit = register_circuit.duplicate_circuit()
	broken_register.disconnect_ports(&"AND_S", 0, &"LATCH", 0)
	_assert(not bool(simulator.run_sequence(broken_register, register_definition["official_steps"])["passed"]), "A register with an unwired SET path must fail its write sequence.")
	var register1 := ReusableComponentType.new(&"Register1", LogicComponentType.KIND_REGISTER1, &"register", register_circuit)
	library[&"Register1"] = register1
	library[&"Register4"] = ReusableComponentType.new(
		&"Register4", LogicComponentType.KIND_REGISTER4, &"register", null,
		[register1.source_signature], {"auto_expanded_bits": 4}
	)
	completed[&"register"] = true

	var ram_definition: Dictionary = catalog.definition(&"ram", library)
	var ram_circuit: LogicCircuit = catalog.reference_circuit(&"ram", library)
	_assert(bool(simulator.run_sequence(ram_circuit, ram_definition["official_steps"])["passed"]), "Catalog RAM2x4 must preserve two independently addressed words.")
	var broken_ram: LogicCircuit = ram_circuit.duplicate_circuit()
	broken_ram.disconnect_ports(&"ADDR_IN", 0, &"MUX", 2)
	_assert(not bool(simulator.run_sequence(broken_ram, ram_definition["official_steps"])["passed"]), "RAM without a visible read-address selector wire must fail address-one cases.")
	library[&"RAM2x4"] = ReusableComponentType.new(
		&"RAM2x4", LogicComponentType.KIND_RAM2X4, &"ram", ram_circuit
	)
	completed[&"ram"] = true
	_assert(catalog.is_unlocked(&"cpu", completed), "Completing ALU and RAM branches must unlock CPU construction.")

	var cpu_definition: Dictionary = catalog.definition(&"cpu", library)
	var cpu_circuit: LogicCircuit = catalog.reference_circuit(&"cpu", library)
	var cpu_report: Dictionary = simulator.run_sequence(cpu_circuit, cpu_definition["official_steps"])
	_assert(bool(cpu_report["passed"]), "Catalog CPU graph must execute the fixed accumulator instruction program.")
	var broken_cpu: LogicCircuit = cpu_circuit.duplicate_circuit()
	broken_cpu.disconnect_ports(&"CONTROL", 1, &"RESULT_MUX", 2)
	_assert(not bool(simulator.run_sequence(broken_cpu, cpu_definition["official_steps"])["passed"]), "CPU with an unwired result-select control must fail ADD instructions.")
	library[&"TinyComputer"] = ReusableComponentType.new(
		&"TinyComputer", LogicComponentType.KIND_TINY_COMPUTER, &"cpu", cpu_circuit
	)
	completed[&"cpu"] = true

	var bridge_definition: Dictionary = catalog.definition(&"load_store", library)
	var bridge_circuit: LogicCircuit = catalog.reference_circuit(&"load_store", library)
	var bridge_report: Dictionary = simulator.run_sequence(bridge_circuit, bridge_definition["official_steps"])
	_assert(bool(bridge_report["passed"]), "Sealed TinyComputer must preserve LOAD/STORE behavior in the final bridge.")


func _full_adder_circuit() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A_IN", &"input", "A", &"A", true),
		LogicComponentType.new(&"B_IN", &"input", "B", &"B", true),
		LogicComponentType.new(&"CIN_IN", &"input", "CIN", &"CIN", true),
		LogicComponentType.new(&"HA_1", &"half_adder", "HalfAdder 1"),
		LogicComponentType.new(&"HA_2", &"half_adder", "HalfAdder 2"),
		LogicComponentType.new(&"OR_1", &"or", "OR"),
		LogicComponentType.new(&"SUM_OUT", &"output", "SUM", &"SUM", true),
		LogicComponentType.new(&"COUT_OUT", &"output", "COUT", &"COUT", true),
	]:
		_add(circuit, component)
	_wire(circuit, &"A_IN", 0, &"HA_1", 0)
	_wire(circuit, &"B_IN", 0, &"HA_1", 1)
	_wire(circuit, &"HA_1", 0, &"HA_2", 0)
	_wire(circuit, &"CIN_IN", 0, &"HA_2", 1)
	_wire(circuit, &"HA_1", 1, &"OR_1", 0)
	_wire(circuit, &"HA_2", 1, &"OR_1", 1)
	_wire(circuit, &"HA_2", 0, &"SUM_OUT", 0)
	_wire(circuit, &"OR_1", 0, &"COUT_OUT", 0)
	return circuit


func _latch_circuit() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"S_IN", &"input", "S", &"S", true),
		LogicComponentType.new(&"R_IN", &"input", "R", &"R", true),
		LogicComponentType.new(&"NOR_Q", &"nor", "NOR Q"),
		LogicComponentType.new(&"NOR_NQ", &"nor", "NOR NQ"),
		LogicComponentType.new(&"Q_OUT", &"output", "Q", &"Q", true),
		LogicComponentType.new(&"NQ_OUT", &"output", "NQ", &"NQ", true),
	]:
		_add(circuit, component)
	_wire(circuit, &"R_IN", 0, &"NOR_Q", 0)
	_wire(circuit, &"NOR_NQ", 0, &"NOR_Q", 1)
	_wire(circuit, &"S_IN", 0, &"NOR_NQ", 0)
	_wire(circuit, &"NOR_Q", 0, &"NOR_NQ", 1)
	_wire(circuit, &"NOR_Q", 0, &"Q_OUT", 0)
	_wire(circuit, &"NOR_NQ", 0, &"NQ_OUT", 0)
	return circuit


func _register_circuit() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"D_IN", &"input", "D", &"D", true),
		LogicComponentType.new(&"LOAD_IN", &"input", "LOAD", &"LOAD", true),
		LogicComponentType.new(&"NOT_D", &"not", "NOT D"),
		LogicComponentType.new(&"AND_S", &"and", "SET GATE"),
		LogicComponentType.new(&"AND_R", &"and", "RESET GATE"),
		LogicComponentType.new(&"LATCH", &"sr_latch", "Your SRLatch"),
		LogicComponentType.new(&"Q_OUT", &"output", "Q", &"Q", true),
	]:
		_add(circuit, component)
	_wire(circuit, &"D_IN", 0, &"NOT_D", 0)
	_wire(circuit, &"D_IN", 0, &"AND_S", 0)
	_wire(circuit, &"LOAD_IN", 0, &"AND_S", 1)
	_wire(circuit, &"NOT_D", 0, &"AND_R", 0)
	_wire(circuit, &"LOAD_IN", 0, &"AND_R", 1)
	_wire(circuit, &"AND_S", 0, &"LATCH", 0)
	_wire(circuit, &"AND_R", 0, &"LATCH", 1)
	_wire(circuit, &"LATCH", 0, &"Q_OUT", 0)
	return circuit


func _ram_circuit() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"ADDR_IN", &"input", "ADDR", &"ADDR", true),
		LogicComponentType.new(&"DATA_IN", &"input", "DATA", &"DATA", true, [], [], [], [], {"width": 4}),
		LogicComponentType.new(&"WRITE_IN", &"input", "WRITE", &"WRITE", true),
		LogicComponentType.new(&"DECODER", &"decoder1_to_2", "1→2 DECODER"),
		LogicComponentType.new(&"REG_0", &"register4", "Register4 · 0"),
		LogicComponentType.new(&"REG_1", &"register4", "Register4 · 1"),
		LogicComponentType.new(&"MUX", &"mux2_word", "WORD MUX"),
		LogicComponentType.new(&"OUT", &"output", "OUT", &"OUT", true, [], [], [], [], {"width": 4}),
	]:
		_add(circuit, component)
	_wire(circuit, &"ADDR_IN", 0, &"DECODER", 0)
	_wire(circuit, &"WRITE_IN", 0, &"DECODER", 1)
	_wire(circuit, &"DATA_IN", 0, &"REG_0", 0)
	_wire(circuit, &"DATA_IN", 0, &"REG_1", 0)
	_wire(circuit, &"DECODER", 0, &"REG_0", 1)
	_wire(circuit, &"DECODER", 1, &"REG_1", 1)
	_wire(circuit, &"REG_0", 0, &"MUX", 0)
	_wire(circuit, &"REG_1", 0, &"MUX", 1)
	_wire(circuit, &"ADDR_IN", 0, &"MUX", 2)
	_wire(circuit, &"MUX", 0, &"OUT", 0)
	return circuit


func _tiny_computer_circuit() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"OP_IN", &"input", "OP", &"OP", true, [], [], [], [], {"width": 2}),
		LogicComponentType.new(&"ARG_IN", &"input", "ARG", &"ARG", true, [], [], [], [], {"width": 4}),
		LogicComponentType.new(&"ADDR_IN", &"input", "ADDR", &"ADDR", true),
		LogicComponentType.new(&"CONTROL", &"control", "CONTROL"),
		LogicComponentType.new(&"SOURCE_MUX", &"mux2_word", "SOURCE MUX"),
		LogicComponentType.new(&"ALU", &"alu4", "Your ALU4"),
		LogicComponentType.new(&"ADD_OP0", &"constant", "0", &"", false, [], [], [], [], {"width": 1, "value": 0}),
		LogicComponentType.new(&"ADD_OP1", &"constant", "1", &"", false, [], [], [], [], {"width": 1, "value": 1}),
		LogicComponentType.new(&"CIN_0", &"constant", "0", &"", false, [], [], [], [], {"width": 1, "value": 0}),
		LogicComponentType.new(&"RESULT_MUX", &"mux2_word", "RESULT MUX"),
		LogicComponentType.new(&"ACC", &"register4", "ACC Register4"),
		LogicComponentType.new(&"RAM", &"ram2x4", "Your RAM2x4"),
		LogicComponentType.new(&"ACC_OUT", &"output", "ACC", &"ACC", true, [], [], [], [], {"width": 4}),
		LogicComponentType.new(&"MEM_OUT", &"output", "MEM", &"MEM", true, [], [], [], [], {"width": 4}),
	]:
		_add(circuit, component)
	_wire(circuit, &"OP_IN", 0, &"CONTROL", 0)
	_wire(circuit, &"ARG_IN", 0, &"SOURCE_MUX", 0)
	_wire(circuit, &"RAM", 0, &"SOURCE_MUX", 1)
	_wire(circuit, &"CONTROL", 0, &"SOURCE_MUX", 2)
	_wire(circuit, &"ACC", 0, &"ALU", 0)
	_wire(circuit, &"SOURCE_MUX", 0, &"ALU", 1)
	_wire(circuit, &"CIN_0", 0, &"ALU", 2)
	_wire(circuit, &"ADD_OP0", 0, &"ALU", 3)
	_wire(circuit, &"ADD_OP1", 0, &"ALU", 4)
	_wire(circuit, &"SOURCE_MUX", 0, &"RESULT_MUX", 0)
	_wire(circuit, &"ALU", 0, &"RESULT_MUX", 1)
	_wire(circuit, &"CONTROL", 1, &"RESULT_MUX", 2)
	_wire(circuit, &"RESULT_MUX", 0, &"ACC", 0)
	_wire(circuit, &"CONTROL", 2, &"ACC", 1)
	_wire(circuit, &"ADDR_IN", 0, &"RAM", 0)
	_wire(circuit, &"ACC", 0, &"RAM", 1)
	_wire(circuit, &"CONTROL", 3, &"RAM", 2)
	_wire(circuit, &"ACC", 0, &"ACC_OUT", 0)
	_wire(circuit, &"RAM", 0, &"MEM_OUT", 0)
	return circuit


func _add(circuit: LogicCircuit, component: LogicComponent) -> void:
	_assert(circuit.add_component(component), "Component %s must be added exactly once." % component.id)


func _wire(circuit: LogicCircuit, from_id: StringName, from_port: int, to_id: StringName, to_port: int) -> void:
	var error: String = circuit.connect_ports(from_id, from_port, to_id, to_port)
	_assert(error.is_empty(), "Wire %s:%d → %s:%d must be valid: %s" % [from_id, from_port, to_id, to_port, error])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
