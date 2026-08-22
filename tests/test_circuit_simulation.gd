extends SceneTree

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const LogicSignalType = preload("res://src/circuit/logic_signal.gd")
const CircuitLiveStateType = preload("res://src/circuit/circuit_live_state.gd")
const CircuitSimulatorType = preload("res://src/circuit/circuit_simulator.gd")
const HalfAdderTestBenchType = preload("res://src/circuit/half_adder_test_bench.gd")
const ReusableHalfAdderType = preload("res://src/circuit/reusable_half_adder.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_component_dictionary_round_trip()
	_test_basic_gates()
	_test_unconnected_ports_default_low()
	_test_connectivity_rules()
	_test_multidriver_resolution()
	_test_cycle_detection()
	_test_junction_fan_out()
	_test_determinism_and_delay()
	_test_half_adder_truth_table()
	_test_invalid_half_adder()
	_test_encapsulation_snapshot()
	if failures.is_empty():
		print("PASS: deterministic default-low tri-state circuit, multi-driver wiring, Half Adder, and encapsulation tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d circuit assertion(s) failed" % failures.size())
		quit(1)


func _test_component_dictionary_round_trip() -> void:
	var original := LogicComponentType.new(
		&"MUX_SAVED", LogicComponentType.KIND_MUX2_WORD, "Saved mux", &"", false,
		[], [], [], [], {"width": 4, "note": "桌布"}
	)
	var restored: LogicComponent = LogicComponentType.from_dictionary(original.to_dictionary())
	_assert(
		restored != null
		and restored.to_dictionary() == original.to_dictionary()
		and restored.input_width(0) == 4
		and restored.output_width(0) == 4,
		"A supported component must round-trip through the versioned workbench dictionary without changing its ports or properties."
	)
	var unsupported: LogicComponent = LogicComponentType.from_dictionary({"id": "BAD", "kind": "unknown"})
	_assert(unsupported == null, "Workbench loading must reject unsupported component kinds instead of injecting unknown simulation behavior.")


func _test_basic_gates() -> void:
	var simulator := CircuitSimulatorType.new()
	var and_circuit: LogicCircuit = _single_gate_circuit(&"and")
	var or_circuit: LogicCircuit = _single_gate_circuit(&"or")
	var xor_circuit: LogicCircuit = _single_gate_circuit(&"xor")
	for a: bool in [false, true]:
		for b: bool in [false, true]:
			var inputs: Dictionary[StringName, bool] = {&"A": a, &"B": b}
			_assert(simulator.evaluate(and_circuit, inputs).outputs.get(&"Y") == (a and b), "AND must match its truth table for %d,%d." % [int(a), int(b)])
			_assert(simulator.evaluate(or_circuit, inputs).outputs.get(&"Y") == (a or b), "OR must match its truth table for %d,%d." % [int(a), int(b)])
			_assert(simulator.evaluate(xor_circuit, inputs).outputs.get(&"Y") == (a != b), "XOR must be high exactly when its inputs differ for %d,%d." % [int(a), int(b)])
	var xor_trace: CircuitTrace = simulator.evaluate(xor_circuit, {&"A": true, &"B": false})
	_assert(xor_trace.is_valid() and int(xor_trace.metrics["gate_count"]) == 1 and int(xor_trace.metrics["propagation_ticks"]) == 1, "XOR must be a supported one-tick basic gate.")
	var not_circuit := LogicCircuitType.new()
	not_circuit.add_component(LogicComponentType.new(&"A_IN", &"input", "A", &"A", true))
	not_circuit.add_component(LogicComponentType.new(&"NOT_1", &"not", "NOT"))
	not_circuit.add_component(LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true))
	_assert(not_circuit.connect_ports(&"A_IN", 0, &"NOT_1", 0).is_empty(), "Input must connect to NOT.")
	_assert(not_circuit.connect_ports(&"NOT_1", 0, &"Y_OUT", 0).is_empty(), "NOT must connect to output.")
	for a: bool in [false, true]:
		var inputs: Dictionary[StringName, bool] = {&"A": a}
		_assert(simulator.evaluate(not_circuit, inputs).outputs.get(&"Y") == not a, "NOT must invert %d." % int(a))


func _test_unconnected_ports_default_low() -> void:
	var simulator := CircuitSimulatorType.new()
	var bare_output := LogicCircuitType.new()
	bare_output.add_component(LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true))
	var bare_live: CircuitLiveStateType = simulator.analyze(bare_output, {})
	_assert(bare_live.input_state(&"Y_OUT", 0) == LogicSignalType.LOW, "An unconnected observer input must resolve to deterministic low instead of high impedance.")
	var bare_trace: CircuitTrace = simulator.evaluate(bare_output, {})
	_assert(bare_trace.is_valid() and bare_trace.outputs.get(&"Y") == false, "An unconnected low-default port must remain a valid executable circuit value.")
	var not_circuit := LogicCircuitType.new()
	not_circuit.add_component(LogicComponentType.new(&"NOT_1", &"not", "NOT"))
	not_circuit.add_component(LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true))
	not_circuit.connect_ports(&"NOT_1", 0, &"Y_OUT", 0)
	var not_live: CircuitLiveStateType = simulator.analyze(not_circuit, {})
	_assert(not_live.input_state(&"NOT_1", 0) == LogicSignalType.LOW and not_live.output_state(&"NOT_1") == LogicSignalType.HIGH, "NOT must continuously invert its unconnected default-low input to high.")
	_assert(simulator.evaluate(not_circuit, {}).outputs.get(&"Y") == true, "Official/debug execution must share the same unconnected-input default as live feedback.")
	var high_z_circuit := LogicCircuitType.new()
	high_z_circuit.add_component(LogicComponentType.new(&"A_IN", &"input", "A", &"A", true))
	high_z_circuit.add_component(LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true))
	high_z_circuit.connect_ports(&"A_IN", 0, &"Y_OUT", 0)
	var high_z_live: CircuitLiveStateType = simulator.analyze(high_z_circuit, {})
	_assert(high_z_live.output_state(&"A_IN") == LogicSignalType.HIGH_Z and high_z_live.input_state(&"Y_OUT", 0) == LogicSignalType.HIGH_Z, "A connected explicit high-Z driver must remain high impedance; only a port with zero wires defaults low.")


func _test_connectivity_rules() -> void:
	var circuit := LogicCircuitType.new()
	circuit.add_component(LogicComponentType.new(&"A_IN", &"input", "A", &"A"))
	circuit.add_component(LogicComponentType.new(&"B_IN", &"input", "B", &"B"))
	circuit.add_component(LogicComponentType.new(&"AND_1", &"and", "AND"))
	_assert(circuit.connect_ports(&"A_IN", 0, &"AND_1", 0).is_empty(), "A valid output-to-input wire must be accepted.")
	_assert(circuit.connect_ports(&"B_IN", 0, &"AND_1", 0).is_empty(), "One input port must accept multiple distinct wire segments.")
	_assert(not circuit.connect_ports(&"B_IN", 0, &"AND_1", 0).is_empty(), "An exact duplicate segment must still be rejected.")
	_assert(circuit.connect_ports(&"AND_1", 0, &"AND_1", 1).is_empty(), "Feedback wiring must be constructible so the analyzer can report a circular dependency.")
	_assert(circuit.has_connection(&"A_IN", 0, &"AND_1", 0), "Accepted wire must be authoritative circuit connectivity.")
	_assert(circuit.disconnect_ports(&"A_IN", 0, &"AND_1", 0), "An existing wire must be removable.")
	_assert(not circuit.has_connection(&"A_IN", 0, &"AND_1", 0), "Removed wire must leave the circuit topology.")


func _test_multidriver_resolution() -> void:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A_IN", &"input", "A", &"A", true),
		LogicComponentType.new(&"B_IN", &"input", "B", &"B", true),
		LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true),
	]:
		circuit.add_component(component)
	circuit.connect_ports(&"A_IN", 0, &"Y_OUT", 0)
	circuit.connect_ports(&"B_IN", 0, &"Y_OUT", 0)
	var simulator := CircuitSimulatorType.new()
	var same_live: CircuitLiveStateType = simulator.analyze(circuit, {&"A": true, &"B": true})
	_assert(same_live.is_valid(), "Two drivers with the same value must share one input without a short circuit.")
	_assert(same_live.input_state(&"Y_OUT", 0) == LogicSignalType.HIGH, "A shared input with only high drivers must resolve high.")
	var same_trace: CircuitTrace = simulator.evaluate(circuit, {&"A": true, &"B": true})
	_assert(same_trace.is_valid() and same_trace.outputs.get(&"Y") == true, "A safe same-value multi-driver net must execute normally.")
	_assert(int(same_trace.metrics["wire_count"]) == 2, "Both visible segments on one port must remain authoritative trace wires.")
	var conflict_live: CircuitLiveStateType = simulator.analyze(circuit, {&"A": false, &"B": true})
	_assert(not conflict_live.is_valid() and conflict_live.input_state(&"Y_OUT", 0) == LogicSignalType.CONFLICT, "Low and high on one input must resolve to an explicit internal conflict.")
	_assert(conflict_live.shorted_inputs.has("Y_OUT:i0"), "The exact conflicting input must be identified as a short circuit.")
	var conflict_trace: CircuitTrace = simulator.evaluate(circuit, {&"A": false, &"B": true})
	_assert(not conflict_trace.is_valid() and _has_error_key(conflict_trace, &"circuit.error.short_circuit"), "A low/high short circuit must block execution with a structured diagnostic.")
	var high_z_live: CircuitLiveStateType = simulator.analyze(circuit, {&"A": true})
	_assert(high_z_live.output_state(&"B_IN") == LogicSignalType.HIGH_Z, "A missing external driver must expose high impedance in live analysis.")
	_assert(high_z_live.input_state(&"Y_OUT", 0) == LogicSignalType.HIGH, "High impedance must not conflict with the remaining driven value.")
	_assert(not simulator.evaluate(circuit, {&"A": true}).is_valid(), "Official execution must still reject a missing required Test Bench input.")


func _test_cycle_detection() -> void:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"NOT_A", &"not", "NOT A"),
		LogicComponentType.new(&"NOT_B", &"not", "NOT B"),
		LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true),
	]:
		circuit.add_component(component)
	circuit.connect_ports(&"NOT_A", 0, &"NOT_B", 0)
	circuit.connect_ports(&"NOT_B", 0, &"NOT_A", 0)
	circuit.connect_ports(&"NOT_B", 0, &"Y_OUT", 0)
	var simulator := CircuitSimulatorType.new()
	var first: CircuitLiveStateType = simulator.analyze(circuit, {})
	var second: CircuitLiveStateType = simulator.analyze(circuit, {})
	_assert(first.cyclic_components.has(&"NOT_A") and first.cyclic_components.has(&"NOT_B"), "Every gate in a same-tick feedback loop must be marked cyclic.")
	_assert(first.output_state(&"NOT_A") == LogicSignalType.HIGH_Z and first.output_state(&"NOT_B") == LogicSignalType.HIGH_Z, "Cyclic outputs must remain unresolved/high-impedance for presentation.")
	_assert(first.canonical_signature() == second.canonical_signature(), "Cycle and tri-state analysis must be deterministic.")
	var trace: CircuitTrace = simulator.evaluate(circuit, {})
	_assert(not trace.is_valid() and _has_error_key(trace, &"circuit.error.circular_dependency"), "A combinational loop must block execution with a circular-dependency diagnostic.")


func _test_junction_fan_out() -> void:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A_IN", &"input", "A", &"A", true),
		LogicComponentType.new(&"B_IN", &"input", "B", &"B", true),
		LogicComponentType.new(&"J1", &"junction", "WIRE NODE"),
		LogicComponentType.new(&"J2", &"junction", "WIRE NODE"),
		LogicComponentType.new(&"Y1_OUT", &"output", "Y1", &"Y1", true),
		LogicComponentType.new(&"Y2_OUT", &"output", "Y2", &"Y2", true),
	]:
		circuit.add_component(component)
	_assert(circuit.connect_ports(&"A_IN", 0, &"J1", 0).is_empty(), "A source must connect to a wire node.")
	_assert(circuit.connect_ports(&"J1", 0, &"J2", 0).is_empty(), "Wire nodes must support multi-segment paths.")
	_assert(circuit.connect_ports(&"J2", 0, &"Y1_OUT", 0).is_empty(), "A junction must feed its first destination.")
	_assert(circuit.connect_ports(&"J2", 0, &"Y2_OUT", 0).is_empty(), "One junction output must fan out to another destination.")
	_assert(circuit.connect_ports(&"B_IN", 0, &"J1", 0).is_empty(), "A junction input must accept another segment so shared nets can be constructed.")
	_assert(circuit.disconnect_ports(&"B_IN", 0, &"J1", 0), "The temporary second junction driver must be removable without disturbing the branch.")
	var trace: CircuitTrace = CircuitSimulatorType.new().evaluate(circuit, {&"A": true, &"B": false})
	_assert(trace.is_valid() and trace.outputs.get(&"Y1") == true and trace.outputs.get(&"Y2") == true, "Every sink on a branched wire must observe the same driven value.")
	_assert(int(trace.metrics["propagation_ticks"]) == 0 and int(trace.metrics["gate_count"]) == 0, "Any number of wire nodes must add zero delay and zero gates.")
	_assert(int(trace.metrics["wire_count"]) == 4, "Every visible branch segment must remain an authoritative zero-delay wire.")
	for event: CircuitEvent in trace.events:
		_assert(event.component_id not in [&"J1", &"J2"], "Routing nodes must not create fake component-processing stages.")
		if event.kind == &"wire_signal":
			_assert(event.tick == 0 and event.visual_step == 1, "All zero-delay segments in one net must share the same parallel wire wave.")
	var removable: LogicCircuit = circuit.duplicate_circuit()
	_assert(removable.remove_component(&"J2"), "A dynamic junction must be removable.")
	_assert(removable.wires.size() == 1, "Removing a junction must also remove every incident segment without touching unrelated topology.")


func _test_determinism_and_delay() -> void:
	var circuit := LogicCircuitType.new()
	circuit.add_component(LogicComponentType.new(&"A_IN", &"input", "A", &"A", true))
	circuit.add_component(LogicComponentType.new(&"NOT_1", &"not", "NOT"))
	circuit.add_component(LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true))
	circuit.connect_ports(&"A_IN", 0, &"NOT_1", 0)
	circuit.connect_ports(&"NOT_1", 0, &"Y_OUT", 0)
	var simulator := CircuitSimulatorType.new()
	var inputs: Dictionary[StringName, bool] = {&"A": true}
	var first: CircuitTrace = simulator.evaluate(circuit, inputs)
	var second: CircuitTrace = simulator.evaluate(circuit, inputs)
	_assert(first.canonical_signature() == second.canonical_signature(), "Identical topology and inputs must produce an identical trace.")
	_assert(int(first.metrics["propagation_ticks"]) == 1, "One NOT gate must add exactly one tick; its two wires add zero.")
	_assert(int(first.metrics["gate_count"]) == 1 and int(first.metrics["wire_count"]) == 2, "Diagnostics must count one active gate and two active wires.")
	var input_event: CircuitEvent = _component_event(first, &"A_IN")
	var not_event: CircuitEvent = _component_event(first, &"NOT_1")
	_assert(input_event.visual_step == 0 and not_event.visual_step == 2, "Independent work must be grouped by causal visual wave, not serial event order.")


func _test_half_adder_truth_table() -> void:
	var circuit: LogicCircuit = _valid_half_adder()
	var bench := HalfAdderTestBenchType.new()
	var report: Dictionary = bench.run_official(circuit)
	_assert(bool(report["passed"]), "The player-built four-gate Half Adder must pass all official cases.")
	var cases: Array = report["cases"]
	_assert(cases.size() == 4, "Official Test Bench must always run the four fixed truth-table cases.")
	for case_result: Dictionary in cases:
		_assert(bool(case_result["passed"]), "Official case A=%d B=%d must match expected SUM/CARRY." % [int(case_result["A"]), int(case_result["B"])])
	var trace: CircuitTrace = cases[3]["trace"]
	_assert(int(trace.metrics["gate_count"]) == 4, "Only the four active Half Adder gates must count; unused spare gates are allowed.")
	_assert(int(trace.metrics["propagation_ticks"]) == 3, "SUM's longest active path must be three gate ticks.")


func _test_invalid_half_adder() -> void:
	var circuit: LogicCircuit = _invalid_half_adder()
	var report: Dictionary = HalfAdderTestBenchType.new().run_official(circuit)
	_assert(not bool(report["passed"]), "A circuit using OR directly for SUM must fail the official suite.")
	var failing_case: Dictionary = (report["cases"] as Array)[3]
	_assert(not bool(failing_case["passed"]), "The invalid OR SUM must specifically fail A=1,B=1.")
	_assert(failing_case["actual_sum"] == true and failing_case["expected_sum"] == false, "Failure evidence must expose expected versus actual without changing topology.")


func _test_encapsulation_snapshot() -> void:
	var source: LogicCircuit = _valid_half_adder_with_junction()
	var sealed := ReusableHalfAdderType.new(source)
	var signature_before: String = sealed.canonical_signature()
	_assert(sealed.is_ready(), "A passing circuit snapshot must create a reusable HalfAdder.")
	for official_case: Dictionary in HalfAdderTestBenchType.OFFICIAL_CASES:
		var trace: CircuitTrace = sealed.evaluate(bool(official_case["A"]), bool(official_case["B"]))
		_assert(trace.outputs.get(&"SUM") == official_case["SUM"] and trace.outputs.get(&"CARRY") == official_case["CARRY"], "Encapsulated HalfAdder must preserve every official behavior.")
	source.disconnect_ports(&"AND_SUM", 0, &"SUM_OUT", 0)
	_assert(sealed.canonical_signature() == signature_before, "The sealed component must own an immutable-style topology snapshot.")
	var retained: CircuitTrace = sealed.evaluate(true, false)
	_assert(retained.outputs.get(&"SUM") == true and retained.outputs.get(&"CARRY") == false, "Editing the source graph after sealing must not mutate the reusable component.")


func _single_gate_circuit(kind: StringName) -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	circuit.add_component(LogicComponentType.new(&"A_IN", &"input", "A", &"A", true))
	circuit.add_component(LogicComponentType.new(&"B_IN", &"input", "B", &"B", true))
	circuit.add_component(LogicComponentType.new(&"GATE", kind, String(kind).to_upper()))
	circuit.add_component(LogicComponentType.new(&"Y_OUT", &"output", "Y", &"Y", true))
	circuit.connect_ports(&"A_IN", 0, &"GATE", 0)
	circuit.connect_ports(&"B_IN", 0, &"GATE", 1)
	circuit.connect_ports(&"GATE", 0, &"Y_OUT", 0)
	return circuit


func _valid_half_adder() -> LogicCircuit:
	var circuit: LogicCircuit = _half_adder_terminals()
	for data: Array in [
		[&"AND_CARRY", &"and", "AND · 1"],
		[&"OR_SUM", &"or", "OR · 1"],
		[&"NOT_CARRY", &"not", "NOT · 1"],
		[&"AND_SUM", &"and", "AND · 2"],
		[&"SPARE_OR", &"or", "OR · SPARE"],
	]:
		circuit.add_component(LogicComponentType.new(data[0], data[1], data[2]))
	for wire: Array in [
		[&"A_IN", 0, &"AND_CARRY", 0], [&"B_IN", 0, &"AND_CARRY", 1],
		[&"A_IN", 0, &"OR_SUM", 0], [&"B_IN", 0, &"OR_SUM", 1],
		[&"AND_CARRY", 0, &"NOT_CARRY", 0],
		[&"OR_SUM", 0, &"AND_SUM", 0], [&"NOT_CARRY", 0, &"AND_SUM", 1],
		[&"AND_SUM", 0, &"SUM_OUT", 0], [&"AND_CARRY", 0, &"CARRY_OUT", 0],
	]:
		circuit.connect_ports(wire[0], wire[1], wire[2], wire[3])
	return circuit


func _valid_half_adder_with_junction() -> LogicCircuit:
	var circuit: LogicCircuit = _valid_half_adder()
	circuit.disconnect_ports(&"A_IN", 0, &"AND_CARRY", 0)
	circuit.disconnect_ports(&"A_IN", 0, &"OR_SUM", 0)
	circuit.add_component(LogicComponentType.new(&"A_BRANCH", &"junction", "A BRANCH"))
	circuit.connect_ports(&"A_IN", 0, &"A_BRANCH", 0)
	circuit.connect_ports(&"A_BRANCH", 0, &"AND_CARRY", 0)
	circuit.connect_ports(&"A_BRANCH", 0, &"OR_SUM", 0)
	return circuit


func _invalid_half_adder() -> LogicCircuit:
	var circuit: LogicCircuit = _half_adder_terminals()
	circuit.add_component(LogicComponentType.new(&"OR_SUM", &"or", "OR"))
	circuit.add_component(LogicComponentType.new(&"AND_CARRY", &"and", "AND"))
	for wire: Array in [
		[&"A_IN", 0, &"OR_SUM", 0], [&"B_IN", 0, &"OR_SUM", 1],
		[&"A_IN", 0, &"AND_CARRY", 0], [&"B_IN", 0, &"AND_CARRY", 1],
		[&"OR_SUM", 0, &"SUM_OUT", 0], [&"AND_CARRY", 0, &"CARRY_OUT", 0],
	]:
		circuit.connect_ports(wire[0], wire[1], wire[2], wire[3])
	return circuit


func _half_adder_terminals() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	circuit.add_component(LogicComponentType.new(&"A_IN", &"input", "A", &"A", true))
	circuit.add_component(LogicComponentType.new(&"B_IN", &"input", "B", &"B", true))
	circuit.add_component(LogicComponentType.new(&"SUM_OUT", &"output", "SUM", &"SUM", true))
	circuit.add_component(LogicComponentType.new(&"CARRY_OUT", &"output", "CARRY", &"CARRY", true))
	return circuit


func _component_event(trace: CircuitTrace, component_id: StringName) -> CircuitEvent:
	for event: CircuitEvent in trace.events:
		if event.kind == &"component_process" and event.component_id == component_id:
			return event
	return null


func _has_error_key(trace: CircuitTrace, key: StringName) -> bool:
	for spec: Dictionary in trace.error_specs:
		if StringName(spec.get("key", &"")) == key:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
