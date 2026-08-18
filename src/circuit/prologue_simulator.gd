class_name PrologueSimulator
extends RefCounted

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const DigitalValueType = preload("res://src/circuit/digital_value.gd")
const PrologueEventType = preload("res://src/circuit/prologue_event.gd")
const PrologueSimulationResultType = preload("res://src/circuit/prologue_simulation_result.gd")

const MAX_SETTLE_TICKS: int = 64


func evaluate(
		circuit: LogicCircuit,
		external_inputs: Dictionary,
		prior_outputs: Dictionary = {},
		runtime_state: Dictionary = {},
		allow_gate_feedback: bool = false,
		sequence_step: int = 0,
		tick_offset: int = 0
	) -> PrologueSimulationResult:
	var result := PrologueSimulationResultType.new()
	if circuit == null:
		result.add_error(&"circuit.error.circuit_missing", [], "The circuit is missing.")
		return result
	result.topology_signature = circuit.canonical_signature()
	result.runtime_state = runtime_state.duplicate(true)
	var normalized_inputs: Dictionary[StringName, DigitalValue] = _normalize_external_inputs(circuit, external_inputs)
	result.external_inputs = _clone_named_values(normalized_inputs)
	var indexed: Dictionary = _validate_and_index(circuit, result)
	if not allow_gate_feedback:
		var cycle: Array[StringName] = _find_combinational_cycle(circuit, indexed.get("valid_wires", []))
		if not cycle.is_empty():
			var cycle_names := PackedStringArray()
			for component_id: StringName in cycle:
				cycle_names.append((circuit.components[component_id] as LogicComponent).display_name)
			result.add_error(
				&"circuit.error.circular_dependency", [", ".join(cycle_names)],
				"Circular dependency: %s feeds back within the same simulation tick."
			)
	if not result.errors.is_empty():
		return result

	var incoming: Dictionary = indexed.get("incoming", {})
	var outgoing: Dictionary = indexed.get("outgoing", {})
	var valid_wires: Array = indexed.get("valid_wires", [])
	var current_outputs: Dictionary[String, DigitalValue] = _initial_outputs(
		circuit, normalized_inputs, prior_outputs, runtime_state
	)
	_refresh_junction_outputs(circuit, incoming, current_outputs)
	_emit_source_events(
		circuit, normalized_inputs, outgoing, result.events,
		sequence_step, tick_offset
	)
	var seen_signatures: Dictionary[String, bool] = {}
	seen_signatures[_value_map_signature(current_outputs)] = true
	for settle_tick: int in range(1, MAX_SETTLE_TICKS + 1):
		var resolved_inputs: Dictionary[String, DigitalValue] = _resolve_all_inputs(
			circuit, incoming, current_outputs, result
		)
		if not result.errors.is_empty():
			result.input_values = resolved_inputs
			result.output_values = _clone_values(current_outputs)
			return result
		var next_outputs: Dictionary[String, DigitalValue] = {}
		for component_id: StringName in _sorted_component_ids(circuit):
			var component: LogicComponent = circuit.components[component_id]
			var component_inputs: Array[DigitalValue] = []
			for port: int in range(component.input_count()):
				component_inputs.append(resolved_inputs[
					PrologueSimulationResultType.input_key(component_id, port)
				])
			var component_outputs: Array[DigitalValue] = _evaluate_component(
				component, component_inputs, current_outputs, normalized_inputs, runtime_state
			)
			for port: int in range(component.output_count()):
				var value: DigitalValue = component_outputs[port] if port < component_outputs.size() \
					else DigitalValueType.high_z(component.output_width(port))
				next_outputs[PrologueSimulationResultType.output_key(component_id, port)] = value
		_refresh_junction_outputs(circuit, incoming, next_outputs)
		_emit_changed_events(
			circuit, current_outputs, next_outputs, resolved_inputs, outgoing,
			result.events, sequence_step, tick_offset + settle_tick
		)
		if _value_maps_equal(current_outputs, next_outputs):
			result.input_values = _clone_values(resolved_inputs)
			result.output_values = _clone_values(next_outputs)
			result.settle_ticks = settle_tick
			result.settled = true
			break
		var signature: String = _value_map_signature(next_outputs)
		if seen_signatures.has(signature):
			result.input_values = _clone_values(resolved_inputs)
			result.output_values = _clone_values(next_outputs)
			result.add_error(
				&"circuit.error.temporal_oscillation", [settle_tick],
				"The circuit did not settle and repeated a previous state at tick %d."
			)
			break
		seen_signatures[signature] = true
		current_outputs = next_outputs
	if not result.settled and result.errors.is_empty():
		result.output_values = _clone_values(current_outputs)
		result.add_error(
			&"circuit.error.temporal_timeout", [MAX_SETTLE_TICKS],
			"The circuit did not settle within %d ticks."
		)
	if result.settled:
		_validate_settled_state(circuit, result)
	_finalize_result(circuit, valid_wires, result)
	return result


func run_sequence(
		circuit: LogicCircuit,
		steps: Array[Dictionary],
		allow_gate_feedback: bool = false,
		initial_runtime_state: Dictionary = {},
		initial_prior_outputs: Dictionary = {}
	) -> Dictionary:
	var runtime_state: Dictionary = initial_runtime_state.duplicate(true)
	var prior_outputs: Dictionary = _clone_values(initial_prior_outputs)
	var starting_runtime_state: Dictionary = runtime_state.duplicate(true)
	var starting_prior_outputs: Dictionary = _clone_values(prior_outputs)
	var step_results: Array[Dictionary] = []
	var all_events: Array[PrologueEvent] = []
	var all_passed: bool = true
	var tick_offset: int = 0
	for step_index: int in range(steps.size()):
		var step: Dictionary = steps[step_index]
		var before: PrologueSimulationResult = evaluate(
			circuit, step.get("inputs", {}), prior_outputs, runtime_state,
			allow_gate_feedback, step_index, tick_offset
		)
		_append_events(all_events, before.events)
		tick_offset += maxi(1, before.settle_ticks + 1)
		if before.is_valid():
			_commit_state(circuit, before, runtime_state)
			# Sequential storage commits at one logical boundary.  Emit that
			# boundary explicitly so HOLD/READ remains visible even when no gate
			# output changes, while every independent cell shares one visual wave.
			var boundary_event_count: int = _emit_state_boundary_events(
					circuit, before, runtime_state, all_events, step_index, tick_offset
				)
			if allow_gate_feedback:
				boundary_event_count += _emit_feedback_boundary_events(
					circuit, before, all_events, step_index, tick_offset
				)
			if boundary_event_count > 0:
				tick_offset += 1
		var after: PrologueSimulationResult = before
		if before.is_valid() and _has_edge_state(circuit):
			after = evaluate(
				circuit, step.get("inputs", {}), before.output_values, runtime_state,
				allow_gate_feedback, step_index, tick_offset
			)
			_append_events(all_events, after.events)
			tick_offset += maxi(1, after.settle_ticks + 1)
		prior_outputs = _clone_values(after.output_values)
		var expected: Dictionary = step.get("expected", {})
		var comparisons: Array[Dictionary] = []
		var step_passed: bool = after.is_valid()
		var expected_names: Array[StringName] = []
		for name_variant: Variant in expected:
			expected_names.append(StringName(name_variant))
		expected_names.sort()
		for output_name: StringName in expected_names:
			var actual: DigitalValue = after.observed_values.get(output_name)
			var observer_width: int = actual.width if actual != null else _observer_width(circuit, output_name)
			var expected_value: DigitalValue = DigitalValueType.from_variant(observer_width, expected[output_name])
			var matches: bool = actual != null and actual.equals(expected_value)
			step_passed = step_passed and matches
			comparisons.append({
				"name": output_name,
				"expected": expected_value,
				"actual": actual.duplicate_value() if actual != null else DigitalValueType.high_z(observer_width),
				"passed": matches,
			})
		all_passed = all_passed and step_passed
		step_results.append({
			"index": step_index,
			"label_key": step.get("label_key", &""),
			"inputs": step.get("inputs", {}).duplicate(true),
			"expected": expected.duplicate(true),
			"comparisons": comparisons,
			"passed": step_passed,
			"result": after,
		})
	return {
		"passed": all_passed,
		"steps": step_results,
		"events": all_events,
		"final_result": step_results[-1]["result"] if not step_results.is_empty() else null,
		"runtime_state": runtime_state.duplicate(true),
		"prior_outputs": _clone_values(prior_outputs),
		"initial_runtime_state": starting_runtime_state,
		"initial_prior_outputs": starting_prior_outputs,
		"topology_signature": circuit.canonical_signature(),
		"canonical_signature": _sequence_signature(circuit, step_results, runtime_state),
	}


func _validate_and_index(circuit: LogicCircuit, result: PrologueSimulationResult) -> Dictionary:
	var incoming: Dictionary = {}
	var outgoing: Dictionary = {}
	var valid_wires: Array[LogicWire] = []
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if not component.is_supported():
			result.add_error(
				&"circuit.error.unsupported_kind", [component.display_name, component.kind],
				"%s has unsupported kind '%s'."
			)
	var sorted_wires: Array[LogicWire] = circuit.wires.duplicate()
	sorted_wires.sort_custom(func(left: LogicWire, right: LogicWire) -> bool:
		return left.canonical_id() < right.canonical_id()
	)
	var seen: Dictionary[String, bool] = {}
	for wire: LogicWire in sorted_wires:
		var diagnostic: Dictionary = circuit.connection_diagnostic(
			wire.from_component, wire.from_port, wire.to_component, wire.to_port
		)
		if not diagnostic.is_empty() and StringName(diagnostic.get("key", &"")) != &"circuit.connection.duplicate":
			result.add_error(
				StringName(diagnostic.get("key", &"circuit.error.wire_port_invalid")),
				diagnostic.get("args", []), diagnostic.get("fallback", "Invalid wire.")
			)
			continue
		var wire_id: String = wire.canonical_id()
		if seen.has(wire_id):
			result.add_error(&"circuit.error.duplicate_wire", [wire_id], "Wire %s is duplicated.")
			continue
		seen[wire_id] = true
		valid_wires.append(wire)
		var input_key: String = PrologueSimulationResultType.input_key(wire.to_component, wire.to_port)
		if not incoming.has(input_key):
			incoming[input_key] = []
		(incoming[input_key] as Array).append(wire)
		var output_key: String = PrologueSimulationResultType.output_key(wire.from_component, wire.from_port)
		if not outgoing.has(output_key):
			outgoing[output_key] = []
		(outgoing[output_key] as Array).append(wire)
	return {"incoming": incoming, "outgoing": outgoing, "valid_wires": valid_wires}


func _normalize_external_inputs(circuit: LogicCircuit, source: Dictionary) -> Dictionary[StringName, DigitalValue]:
	var result: Dictionary[StringName, DigitalValue] = {}
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.kind != LogicComponentType.KIND_INPUT or component.signal_name.is_empty():
			continue
		var width: int = component.output_width(0)
		result[component.signal_name] = DigitalValueType.from_variant(width, source.get(component.signal_name))
	return result


func _initial_outputs(
		circuit: LogicCircuit,
		external_inputs: Dictionary[StringName, DigitalValue],
		prior_outputs: Dictionary,
		runtime_state: Dictionary
	) -> Dictionary[String, DigitalValue]:
	var result: Dictionary[String, DigitalValue] = {}
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		for port: int in range(component.output_count()):
			var key: String = PrologueSimulationResultType.output_key(component_id, port)
			var width: int = component.output_width(port)
			var prior: Variant = prior_outputs.get(key)
			if prior is DigitalValue and (prior as DigitalValue).width == width:
				result[key] = (prior as DigitalValue).duplicate_value()
			elif component.kind == LogicComponentType.KIND_INPUT:
				result[key] = external_inputs.get(component.signal_name, DigitalValueType.high_z(width)).duplicate_value()
			elif component.kind == LogicComponentType.KIND_CONSTANT:
				result[key] = DigitalValueType.known(width, int(component.properties.get("value", 0)))
			elif component.kind in [LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4]:
				result[key] = DigitalValueType.known(width, _register_value(runtime_state, component_id))
			elif component.kind == LogicComponentType.KIND_SR_LATCH:
				var q: int = int(_latch_value(runtime_state, component_id))
				result[key] = DigitalValueType.known(1, q if port == 0 else 1 - q)
			else:
				result[key] = DigitalValueType.low(width)
	return result


func _resolve_all_inputs(
		circuit: LogicCircuit,
		incoming: Dictionary,
		outputs: Dictionary[String, DigitalValue],
		result: PrologueSimulationResult
	) -> Dictionary[String, DigitalValue]:
	var resolved: Dictionary[String, DigitalValue] = {}
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		for port: int in range(component.input_count()):
			var key: String = PrologueSimulationResultType.input_key(component_id, port)
			var width: int = component.input_width(port)
			var drivers: Array[DigitalValue] = []
			for wire_variant: Variant in incoming.get(key, []):
				var wire := wire_variant as LogicWire
				var driver: DigitalValue = outputs.get(
					PrologueSimulationResultType.output_key(wire.from_component, wire.from_port)
				)
				if driver != null:
					drivers.append(driver)
			var value: DigitalValue = DigitalValueType.resolve(drivers, width)
			resolved[key] = value
			if value.is_conflict():
				result.add_error(
					&"circuit.error.short_circuit", [component.display_name, port + 1],
					"Short circuit at %s input %d: incompatible values drive the same port."
				)
	return resolved


func _refresh_junction_outputs(
		circuit: LogicCircuit,
		incoming: Dictionary,
		outputs: Dictionary[String, DigitalValue]
	) -> void:
	var resolved: Dictionary[StringName, bool] = {}
	var visiting: Dictionary[StringName, bool] = {}
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.is_routing_node():
			_resolve_junction_output(component_id, circuit, incoming, outputs, resolved, visiting)


func _resolve_junction_output(
		component_id: StringName,
		circuit: LogicCircuit,
		incoming: Dictionary,
		outputs: Dictionary[String, DigitalValue],
		resolved: Dictionary[StringName, bool],
		visiting: Dictionary[StringName, bool]
	) -> DigitalValue:
	var component: LogicComponent = circuit.components[component_id]
	var output_key: String = PrologueSimulationResultType.output_key(component_id, 0)
	if resolved.has(component_id):
		return outputs.get(output_key, DigitalValueType.low(component.output_width(0)))
	if visiting.has(component_id):
		return DigitalValueType.conflict(component.output_width(0))
	visiting[component_id] = true
	var drivers: Array[DigitalValue] = []
	var input_key: String = PrologueSimulationResultType.input_key(component_id, 0)
	for wire_variant: Variant in incoming.get(input_key, []):
		var wire := wire_variant as LogicWire
		var source: LogicComponent = circuit.components[wire.from_component]
		var value: DigitalValue
		if source.is_routing_node():
			value = _resolve_junction_output(
				wire.from_component, circuit, incoming, outputs, resolved, visiting
			)
		else:
			value = outputs.get(PrologueSimulationResultType.output_key(wire.from_component, wire.from_port))
		if value != null:
			drivers.append(value)
	var result: DigitalValue = DigitalValueType.resolve(drivers, component.output_width(0))
	outputs[output_key] = result
	visiting.erase(component_id)
	resolved[component_id] = true
	return result


func _evaluate_component(
		component: LogicComponent,
		inputs: Array[DigitalValue],
		current_outputs: Dictionary[String, DigitalValue],
		external_inputs: Dictionary[StringName, DigitalValue],
		runtime_state: Dictionary
	) -> Array[DigitalValue]:
	match component.kind:
		LogicComponentType.KIND_INPUT:
			return [external_inputs.get(
				component.signal_name, DigitalValueType.high_z(component.output_width(0))
			).duplicate_value()]
		LogicComponentType.KIND_CONSTANT:
			return [DigitalValueType.known(
				component.output_width(0), int(component.properties.get("value", 0))
			)]
		LogicComponentType.KIND_AND:
			return [_bit_and(inputs)]
		LogicComponentType.KIND_OR:
			return [_bit_or(inputs)]
		LogicComponentType.KIND_NOT:
			return [_bit_not(inputs[0])]
		LogicComponentType.KIND_NOR:
			return [_bit_not(_bit_or(inputs))]
		LogicComponentType.KIND_JUNCTION:
			return [inputs[0].duplicate_value()]
		LogicComponentType.KIND_HALF_ADDER:
			return _half_adder(inputs[0], inputs[1])
		LogicComponentType.KIND_FULL_ADDER:
			return _full_adder(inputs[0], inputs[1], inputs[2])
		LogicComponentType.KIND_MUX4:
			return [_mux4(inputs)]
		LogicComponentType.KIND_ALU1:
			return _alu(inputs, 1)
		LogicComponentType.KIND_SR_LATCH:
			return _sr_latch(component, inputs, current_outputs, runtime_state)
		LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4:
			return [DigitalValueType.known(
				component.output_width(0), _register_value(runtime_state, component.id)
			)]
		LogicComponentType.KIND_DECODER1_TO_2:
			return _decoder(inputs)
		LogicComponentType.KIND_MUX2_WORD:
			return [_mux2(inputs)]
		LogicComponentType.KIND_ALU4:
			return _alu(inputs, 4)
		LogicComponentType.KIND_RAM2X4:
			return [_ram_read(component, inputs, runtime_state)]
		LogicComponentType.KIND_CONTROL:
			return _control(inputs)
		LogicComponentType.KIND_TINY_COMPUTER:
			return _tiny_computer_outputs(component, inputs, runtime_state)
	return []


func _bit_and(inputs: Array[DigitalValue]) -> DigitalValue:
	for value: DigitalValue in inputs:
		if value.is_conflict():
			return DigitalValueType.conflict()
		if value.is_known() and not value.bit():
			return DigitalValueType.low()
	for value: DigitalValue in inputs:
		if not value.is_known():
			return DigitalValueType.high_z()
	return DigitalValueType.high()


func _bit_or(inputs: Array[DigitalValue]) -> DigitalValue:
	for value: DigitalValue in inputs:
		if value.is_conflict():
			return DigitalValueType.conflict()
		if value.is_known() and value.bit():
			return DigitalValueType.high()
	for value: DigitalValue in inputs:
		if not value.is_known():
			return DigitalValueType.high_z()
	return DigitalValueType.low()


func _bit_not(value: DigitalValue) -> DigitalValue:
	if value.is_conflict():
		return DigitalValueType.conflict()
	if not value.is_known():
		return DigitalValueType.high_z()
	return DigitalValueType.low() if value.bit() else DigitalValueType.high()


func _half_adder(a: DigitalValue, b: DigitalValue) -> Array[DigitalValue]:
	if a.is_conflict() or b.is_conflict():
		return [DigitalValueType.conflict(), DigitalValueType.conflict()]
	if not a.is_known() or not b.is_known():
		return [DigitalValueType.high_z(), DigitalValueType.high_z()]
	var a_bit: int = 1 if a.bit() else 0
	var b_bit: int = 1 if b.bit() else 0
	return [DigitalValueType.known(1, a_bit ^ b_bit), DigitalValueType.known(1, a_bit & b_bit)]


func _full_adder(a: DigitalValue, b: DigitalValue, carry_in: DigitalValue) -> Array[DigitalValue]:
	if a.is_conflict() or b.is_conflict() or carry_in.is_conflict():
		return [DigitalValueType.conflict(), DigitalValueType.conflict()]
	if not a.is_known() or not b.is_known() or not carry_in.is_known():
		return [DigitalValueType.high_z(), DigitalValueType.high_z()]
	var total: int = int(a.bit()) + int(b.bit()) + int(carry_in.bit())
	return [DigitalValueType.known(1, total & 1), DigitalValueType.known(1, 1 if total >= 2 else 0)]


func _mux4(inputs: Array[DigitalValue]) -> DigitalValue:
	var selector: DigitalValue = _selector(inputs[4], inputs[5])
	if not selector.is_known():
		return DigitalValueType.conflict(inputs[0].width) if selector.is_conflict() else DigitalValueType.high_z(inputs[0].width)
	return inputs[selector.value].duplicate_value()


func _mux2(inputs: Array[DigitalValue]) -> DigitalValue:
	var selector: DigitalValue = inputs[2]
	if not selector.is_known():
		return DigitalValueType.conflict(inputs[0].width) if selector.is_conflict() else DigitalValueType.high_z(inputs[0].width)
	return inputs[1 if selector.bit() else 0].duplicate_value()


func _selector(low_bit: DigitalValue, high_bit: DigitalValue) -> DigitalValue:
	if low_bit.is_conflict() or high_bit.is_conflict():
		return DigitalValueType.conflict(2)
	if not low_bit.is_known() or not high_bit.is_known():
		return DigitalValueType.high_z(2)
	return DigitalValueType.known(2, int(low_bit.bit()) | (int(high_bit.bit()) << 1))


func _alu(inputs: Array[DigitalValue], width: int) -> Array[DigitalValue]:
	var selector: DigitalValue = _selector(inputs[3], inputs[4])
	if not selector.is_known():
		var unknown: DigitalValue = DigitalValueType.conflict(width) if selector.is_conflict() else DigitalValueType.high_z(width)
		return [unknown, DigitalValueType.conflict() if selector.is_conflict() else DigitalValueType.high_z()]
	var a: DigitalValue = inputs[0]
	var b: DigitalValue = inputs[1]
	var carry: DigitalValue = inputs[2]
	if not a.is_known() or not b.is_known() or not carry.is_known():
		var conflict_state: bool = a.is_conflict() or b.is_conflict() or carry.is_conflict()
		return [DigitalValueType.conflict(width) if conflict_state else DigitalValueType.high_z(width), DigitalValueType.conflict() if conflict_state else DigitalValueType.high_z()]
	var total: int = a.value + b.value + int(carry.bit())
	var add_carry: int = 1 if total > DigitalValueType.mask_for_width(width) else 0
	var result_value: int = 0
	match selector.value:
		0: result_value = a.value & b.value
		1: result_value = a.value | b.value
		2: result_value = total
		3: result_value = (~a.value) & DigitalValueType.mask_for_width(width)
	return [DigitalValueType.known(width, result_value), DigitalValueType.known(1, add_carry)]


func _sr_latch(
		component: LogicComponent,
		inputs: Array[DigitalValue],
		current_outputs: Dictionary[String, DigitalValue],
		runtime_state: Dictionary
	) -> Array[DigitalValue]:
	var set_value: DigitalValue = inputs[0]
	var reset_value: DigitalValue = inputs[1]
	if set_value.is_conflict() or reset_value.is_conflict():
		return [DigitalValueType.conflict(), DigitalValueType.conflict()]
	if not set_value.is_known() or not reset_value.is_known():
		return [DigitalValueType.high_z(), DigitalValueType.high_z()]
	var q: int = _latch_value(runtime_state, component.id)
	var current_q: DigitalValue = current_outputs.get(
		PrologueSimulationResultType.output_key(component.id, 0)
	)
	if current_q != null and current_q.is_known():
		q = current_q.value & 1
	# A gate-level D latch can briefly assert S and R together while an
	# upstream inverter settles. Holding the previous state here lets that
	# physical transient converge; a stable S=R=1 state is rejected after the
	# whole circuit has settled by _validate_settled_state().
	if set_value.bit() and reset_value.bit():
		return [DigitalValueType.known(1, q), DigitalValueType.known(1, 1 - q)]
	if set_value.bit():
		q = 1
	elif reset_value.bit():
		q = 0
	return [DigitalValueType.known(1, q), DigitalValueType.known(1, 1 - q)]


func _validate_settled_state(circuit: LogicCircuit, result: PrologueSimulationResult) -> void:
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.kind != LogicComponentType.KIND_SR_LATCH:
			continue
		var set_value: DigitalValue = result.input_value(component_id, 0)
		var reset_value: DigitalValue = result.input_value(component_id, 1)
		if set_value.is_known() and reset_value.is_known() \
				and set_value.bit() and reset_value.bit():
			result.add_error(
				&"circuit.error.invalid_latch_state", [component.display_name],
				"%s cannot keep SET and RESET active at the same time."
			)


func _decoder(inputs: Array[DigitalValue]) -> Array[DigitalValue]:
	if inputs[0].is_conflict() or inputs[1].is_conflict():
		return [DigitalValueType.conflict(), DigitalValueType.conflict()]
	if not inputs[0].is_known() or not inputs[1].is_known():
		return [DigitalValueType.high_z(), DigitalValueType.high_z()]
	if not inputs[1].bit():
		return [DigitalValueType.low(), DigitalValueType.low()]
	return [
		DigitalValueType.known(1, 0 if inputs[0].bit() else 1),
		DigitalValueType.known(1, 1 if inputs[0].bit() else 0),
	]


func _ram_read(component: LogicComponent, inputs: Array[DigitalValue], runtime_state: Dictionary) -> DigitalValue:
	var address: DigitalValue = inputs[0]
	if address.is_conflict():
		return DigitalValueType.conflict(4)
	if not address.is_known():
		return DigitalValueType.high_z(4)
	var memory: Array[int] = _ram_values(runtime_state, component.id)
	return DigitalValueType.known(4, memory[address.value & 1])


func _control(inputs: Array[DigitalValue]) -> Array[DigitalValue]:
	var operation: DigitalValue = inputs[0]
	if operation.is_conflict():
		return [DigitalValueType.conflict(), DigitalValueType.conflict(), DigitalValueType.conflict(), DigitalValueType.conflict()]
	if not operation.is_known():
		return [DigitalValueType.high_z(), DigitalValueType.high_z(), DigitalValueType.high_z(), DigitalValueType.high_z()]
	var op: int = operation.value & 3
	return [
		DigitalValueType.known(1, 1 if op == 2 else 0),
		DigitalValueType.known(1, 1 if op == 1 else 0),
		DigitalValueType.known(1, 0 if op == 3 else 1),
		DigitalValueType.known(1, 1 if op == 3 else 0),
	]


func _tiny_computer_outputs(
		component: LogicComponent,
		inputs: Array[DigitalValue],
		runtime_state: Dictionary
	) -> Array[DigitalValue]:
	var computers: Dictionary = runtime_state.get("tiny_computers", {})
	var state: Dictionary = computers.get(component.id, {})
	var memory: Array = state.get("memory", [0, 0])
	var address: int = inputs[2].value & 1 if inputs.size() > 2 and inputs[2].is_known() else 0
	return [
		DigitalValueType.known(4, int(state.get("acc", 0))),
		DigitalValueType.known(4, int(memory[address]) if memory.size() > address else 0),
	]


func _commit_state(circuit: LogicCircuit, result: PrologueSimulationResult, runtime_state: Dictionary) -> void:
	var register_values: Dictionary = runtime_state.get("registers", {}).duplicate(true)
	var ram_values: Dictionary = runtime_state.get("ram", {}).duplicate(true)
	var computer_values: Dictionary = runtime_state.get("tiny_computers", {}).duplicate(true)
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.kind in [LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4]:
			var data: DigitalValue = result.input_value(component_id, 0, component.input_width(0))
			var load: DigitalValue = result.input_value(component_id, 1, 1)
			if load.is_known() and load.bit() and data.is_known():
				register_values[component_id] = data.value
		elif component.kind == LogicComponentType.KIND_RAM2X4:
			var address: DigitalValue = result.input_value(component_id, 0, 1)
			var data_in: DigitalValue = result.input_value(component_id, 1, 4)
			var write: DigitalValue = result.input_value(component_id, 2, 1)
			if write.is_known() and write.bit() and address.is_known() and data_in.is_known():
				var memory: Array[int] = _ram_values(runtime_state, component_id)
				memory[address.value & 1] = data_in.value & 0xF
				ram_values[component_id] = memory
		elif component.kind == LogicComponentType.KIND_TINY_COMPUTER:
			var operation: DigitalValue = result.input_value(component_id, 0, 2)
			var argument: DigitalValue = result.input_value(component_id, 1, 4)
			var address: DigitalValue = result.input_value(component_id, 2, 1)
			if operation.is_known() and argument.is_known() and address.is_known():
				var previous: Dictionary = computer_values.get(component_id, {})
				var acc: int = int(previous.get("acc", 0)) & 0xF
				var memory: Array = previous.get("memory", [0, 0]).duplicate()
				while memory.size() < 2:
					memory.append(0)
				match operation.value & 3:
					0: acc = argument.value & 0xF
					1: acc = (acc + argument.value) & 0xF
					2: acc = int(memory[address.value & 1]) & 0xF
					3: memory[address.value & 1] = acc
				computer_values[component_id] = {"acc": acc, "memory": memory}
	runtime_state["registers"] = register_values
	runtime_state["ram"] = ram_values
	runtime_state["tiny_computers"] = computer_values


func _emit_state_boundary_events(
		circuit: LogicCircuit,
		settled_result: PrologueSimulationResult,
		runtime_state: Dictionary,
		events: Array[PrologueEvent],
		sequence_step: int,
		tick: int
	) -> int:
	var emitted: int = 0
	var registers: Dictionary = runtime_state.get("registers", {})
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.kind not in [
			LogicComponentType.KIND_SR_LATCH,
			LogicComponentType.KIND_REGISTER1,
			LogicComponentType.KIND_REGISTER4,
			LogicComponentType.KIND_RAM2X4,
		]:
			continue
		var inputs: Array[DigitalValue] = []
		for port: int in range(component.input_count()):
			inputs.append(settled_result.input_value(component_id, port, component.input_width(port)))
		var value: DigitalValue = DigitalValueType.low(component.output_width(0))
		var message_key: StringName = &"hardware.trace.state.hold"
		var message_args: Array = []
		match component.kind:
			LogicComponentType.KIND_SR_LATCH:
				value = settled_result.output_value(component_id, 0, 1)
				var set_value: DigitalValue = inputs[0]
				var reset_value: DigitalValue = inputs[1]
				if set_value.is_known() and set_value.bit():
					message_key = &"hardware.trace.state.set"
				elif reset_value.is_known() and reset_value.bit():
					message_key = &"hardware.trace.state.reset"
				message_args = [value.display_text()]
			LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4:
				value = DigitalValueType.known(
					component.output_width(0), int(registers.get(component_id, 0))
				)
				var load: DigitalValue = inputs[1]
				message_key = &"hardware.trace.state.write" \
					if load.is_known() and load.bit() else &"hardware.trace.state.hold"
				message_args = [value.display_text()]
			LogicComponentType.KIND_RAM2X4:
				var memory: Array[int] = _ram_values(runtime_state, component_id)
				var address_value: DigitalValue = inputs[0]
				var address: int = address_value.value & 1 if address_value.is_known() else 0
				value = DigitalValueType.known(4, memory[address])
				var write: DigitalValue = inputs[2]
				message_key = &"hardware.trace.state.ram_write" \
					if write.is_known() and write.bit() else &"hardware.trace.state.ram_read"
				message_args = [
					address,
					value.display_text(),
					DigitalValueType.known(4, memory[0]).display_text(),
					DigitalValueType.known(4, memory[1]).display_text(),
				]
		events.append(PrologueEventType.new(
			&"state_transition", tick, tick * 2, sequence_step, component_id,
			&"", -1, &"", -1, value, inputs, message_key, message_args
		))
		emitted += 1
	return emitted


func _emit_feedback_boundary_events(
		circuit: LogicCircuit,
		settled_result: PrologueSimulationResult,
		events: Array[PrologueEvent],
		sequence_step: int,
		tick: int
	) -> int:
	var feedback_components: Array[StringName] = _find_combinational_cycle(circuit, circuit.wires)
	feedback_components.sort()
	var set_value: DigitalValue = settled_result.external_inputs.get(&"S")
	var reset_value: DigitalValue = settled_result.external_inputs.get(&"R")
	var message_key: StringName = &"hardware.trace.state.feedback_hold"
	if set_value != null and set_value.is_known() and set_value.bit():
		message_key = &"hardware.trace.state.feedback_set"
	elif reset_value != null and reset_value.is_known() and reset_value.bit():
		message_key = &"hardware.trace.state.feedback_reset"
	for component_id: StringName in feedback_components:
		var component: LogicComponent = circuit.components[component_id]
		if component.output_count() == 0:
			continue
		var inputs: Array[DigitalValue] = []
		for port: int in range(component.input_count()):
			inputs.append(settled_result.input_value(component_id, port, component.input_width(port)))
		var value: DigitalValue = settled_result.output_value(
			component_id, 0, component.output_width(0)
		)
		events.append(PrologueEventType.new(
			&"state_transition", tick, tick * 2, sequence_step, component_id,
			&"", -1, &"", -1, value, inputs, message_key,
			[component.display_name, value.display_text()]
		))
	return feedback_components.size()


func _finalize_result(circuit: LogicCircuit, valid_wires: Array, result: PrologueSimulationResult) -> void:
	for wire_variant: Variant in valid_wires:
		var wire := wire_variant as LogicWire
		var source: LogicComponent = circuit.components[wire.from_component]
		result.wire_values[wire.canonical_id()] = result.output_value(
			wire.from_component, wire.from_port, source.output_width(wire.from_port)
		)
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if not component.is_observer() or component.signal_name.is_empty():
			continue
		result.observed_values[component.signal_name] = result.input_value(
			component_id, 0, component.input_width(0)
		)


func _emit_source_events(
		circuit: LogicCircuit,
		external_inputs: Dictionary[StringName, DigitalValue],
		outgoing: Dictionary,
		events: Array[PrologueEvent],
		sequence_step: int,
		tick: int
	) -> void:
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.kind not in [LogicComponentType.KIND_INPUT, LogicComponentType.KIND_CONSTANT]:
			continue
		var value: DigitalValue = external_inputs.get(component.signal_name) if component.kind == LogicComponentType.KIND_INPUT \
			else DigitalValueType.known(component.output_width(0), int(component.properties.get("value", 0)))
		if value == null:
			value = DigitalValueType.high_z(component.output_width(0))
		events.append(PrologueEventType.new(
			&"component_process", tick, tick * 2, sequence_step, component_id,
			&"", 0, &"", -1, value, [], &"hardware.trace.component"
		))
		_emit_wire_events(
			circuit, component_id, 0, value, outgoing, events, sequence_step, tick,
			true, {}
		)


func _emit_changed_events(
		circuit: LogicCircuit,
		current_outputs: Dictionary[String, DigitalValue],
		next_outputs: Dictionary[String, DigitalValue],
		resolved_inputs: Dictionary[String, DigitalValue],
		outgoing: Dictionary,
		events: Array[PrologueEvent],
		sequence_step: int,
		tick: int
	) -> void:
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.kind in [LogicComponentType.KIND_INPUT, LogicComponentType.KIND_CONSTANT]:
			continue
		var inputs: Array[DigitalValue] = []
		for input_port: int in range(component.input_count()):
			inputs.append(resolved_inputs[PrologueSimulationResultType.input_key(component_id, input_port)])
		for output_port: int in range(component.output_count()):
			var key: String = PrologueSimulationResultType.output_key(component_id, output_port)
			var before: DigitalValue = current_outputs.get(key)
			var after: DigitalValue = next_outputs[key]
			if before != null and before.equals(after):
				continue
			if not component.is_routing_node():
				events.append(PrologueEventType.new(
					&"component_process", tick, tick * 2, sequence_step, component_id,
					&"", output_port, &"", -1, after, inputs, &"hardware.trace.component"
				))
			_emit_wire_events(
				circuit, component_id, output_port, after, outgoing, events, sequence_step, tick,
				false, {}
			)
	if not next_outputs.is_empty():
		for component_id: StringName in _sorted_component_ids(circuit):
			var component: LogicComponent = circuit.components[component_id]
			if not component.is_observer():
				continue
			var observed: DigitalValue = resolved_inputs.get(
				PrologueSimulationResultType.input_key(component_id, 0)
			)
			if observed != null:
				events.append(PrologueEventType.new(
					&"component_process", tick, tick * 2 + 1, sequence_step, component_id,
					&"", -1, &"", -1, observed, [observed], &"hardware.trace.observer"
				))


func _emit_wire_events(
		circuit: LogicCircuit,
		component_id: StringName,
		output_port: int,
		value: DigitalValue,
		outgoing: Dictionary,
		events: Array[PrologueEvent],
		sequence_step: int,
		tick: int,
		follow_routing: bool = false,
		visited: Dictionary = {}
	) -> void:
	var key: String = PrologueSimulationResultType.output_key(component_id, output_port)
	for wire_variant: Variant in outgoing.get(key, []):
		var wire := wire_variant as LogicWire
		var wire_id: String = wire.canonical_id()
		if visited.has(wire_id):
			continue
		visited[wire_id] = true
		events.append(PrologueEventType.new(
			&"wire_signal", tick, tick * 2 + 1, sequence_step, &"",
			wire.from_component, wire.from_port, wire.to_component, wire.to_port,
			value, [], &"hardware.trace.wire"
		))
		var target: LogicComponent = circuit.components[wire.to_component]
		if follow_routing and target.is_routing_node():
			_emit_wire_events(
				circuit, target.id, 0, value, outgoing, events, sequence_step, tick,
				true, visited
			)


func _find_combinational_cycle(circuit: LogicCircuit, wires: Array) -> Array[StringName]:
	var outgoing_ids: Dictionary[StringName, Array] = {}
	for wire_variant: Variant in wires:
		var wire := wire_variant as LogicWire
		var target: LogicComponent = circuit.components[wire.to_component]
		if target.is_stateful():
			continue
		if not outgoing_ids.has(wire.from_component):
			outgoing_ids[wire.from_component] = []
		(outgoing_ids[wire.from_component] as Array).append(wire.to_component)
	var visit: Dictionary[StringName, int] = {}
	var stack: Array[StringName] = []
	for component_id: StringName in _sorted_component_ids(circuit):
		var found: Array[StringName] = _dfs_cycle(component_id, outgoing_ids, visit, stack)
		if not found.is_empty():
			return found
	return []


func _dfs_cycle(
		component_id: StringName,
		outgoing_ids: Dictionary[StringName, Array],
		visit: Dictionary[StringName, int],
		stack: Array[StringName]
	) -> Array[StringName]:
	var state: int = visit.get(component_id, 0)
	if state == 2:
		return []
	if state == 1:
		var start: int = stack.find(component_id)
		return stack.slice(start) if start >= 0 else [component_id]
	visit[component_id] = 1
	stack.append(component_id)
	var targets: Array = outgoing_ids.get(component_id, []).duplicate()
	targets.sort()
	for target_variant: Variant in targets:
		var found: Array[StringName] = _dfs_cycle(StringName(target_variant), outgoing_ids, visit, stack)
		if not found.is_empty():
			return found
	stack.pop_back()
	visit[component_id] = 2
	return []


func _has_edge_state(circuit: LogicCircuit) -> bool:
	for component: LogicComponent in circuit.components.values():
		if component.kind in [
			LogicComponentType.KIND_REGISTER1, LogicComponentType.KIND_REGISTER4,
			LogicComponentType.KIND_RAM2X4, LogicComponentType.KIND_TINY_COMPUTER,
		]:
			return true
	return false


func _register_value(runtime_state: Dictionary, component_id: StringName) -> int:
	var values: Dictionary = runtime_state.get("registers", {})
	return int(values.get(component_id, 0))


func _latch_value(runtime_state: Dictionary, component_id: StringName) -> int:
	var values: Dictionary = runtime_state.get("latches", {})
	return int(values.get(component_id, 0)) & 1


func _ram_values(runtime_state: Dictionary, component_id: StringName) -> Array[int]:
	var values: Dictionary = runtime_state.get("ram", {})
	var raw: Array = values.get(component_id, [0, 0])
	var result: Array[int] = [0, 0]
	for index: int in range(mini(2, raw.size())):
		result[index] = int(raw[index]) & 0xF
	return result


func _observer_width(circuit: LogicCircuit, signal_name: StringName) -> int:
	for component: LogicComponent in circuit.components.values():
		if component.is_observer() and component.signal_name == signal_name:
			return component.input_width(0)
	return 1


func _sorted_component_ids(circuit: LogicCircuit) -> Array[StringName]:
	var ids: Array[StringName] = []
	for component_id: StringName in circuit.components:
		ids.append(component_id)
	ids.sort()
	return ids


func _clone_values(source: Dictionary) -> Dictionary[String, DigitalValue]:
	var result: Dictionary[String, DigitalValue] = {}
	for key_variant: Variant in source:
		var value: DigitalValue = source[key_variant]
		result[String(key_variant)] = value.duplicate_value()
	return result


func _clone_named_values(source: Dictionary) -> Dictionary[StringName, DigitalValue]:
	var result: Dictionary[StringName, DigitalValue] = {}
	for key_variant: Variant in source:
		var value: DigitalValue = source[key_variant]
		result[StringName(key_variant)] = value.duplicate_value()
	return result


func _value_maps_equal(left: Dictionary[String, DigitalValue], right: Dictionary[String, DigitalValue]) -> bool:
	if left.size() != right.size():
		return false
	for key: String in left:
		if not right.has(key) or not left[key].equals(right[key]):
			return false
	return true


func _value_map_signature(source: Dictionary[String, DigitalValue]) -> String:
	var keys: Array[String] = []
	for key: String in source:
		keys.append(key)
	keys.sort()
	var parts := PackedStringArray()
	for key: String in keys:
		parts.append(key + "=" + source[key].canonical_signature())
	return ";".join(parts)


func _append_events(target: Array[PrologueEvent], source: Array[PrologueEvent]) -> void:
	for event: PrologueEvent in source:
		target.append(event)


func _sequence_signature(circuit: LogicCircuit, step_results: Array[Dictionary], runtime_state: Dictionary) -> String:
	var steps: Array[Dictionary] = []
	for step: Dictionary in step_results:
		var result: PrologueSimulationResult = step["result"]
		steps.append({"passed": step["passed"], "result": result.canonical_signature()})
	return JSON.stringify({
		"topology": circuit.canonical_signature(),
		"steps": steps,
		"runtime_state": runtime_state,
	})
