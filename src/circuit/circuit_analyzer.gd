class_name CircuitAnalyzer
extends RefCounted

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicSignalType = preload("res://src/circuit/logic_signal.gd")
const CircuitLiveStateType = preload("res://src/circuit/circuit_live_state.gd")

const VISIT_NONE: int = 0
const VISIT_ACTIVE: int = 1
const VISIT_DONE: int = 2

var _circuit: LogicCircuit
var _result: CircuitLiveStateType
var _visit_states: Dictionary[StringName, int] = {}
var _visit_stack: Array[StringName] = []


func analyze(circuit: LogicCircuit, external_inputs: Dictionary[StringName, bool]) -> CircuitLiveStateType:
	_result = CircuitLiveStateType.new()
	if circuit == null:
		_result.add_error(&"circuit.error.circuit_missing", [], "The circuit is missing.")
		return _result
	_circuit = circuit
	_result.topology_signature = circuit.canonical_signature()
	_result.input_values = external_inputs.duplicate()
	_visit_states.clear()
	_visit_stack.clear()
	_validate_and_index()
	for component_id: StringName in _sorted_component_ids():
		_evaluate_component(component_id)
	for wire: LogicWire in _result.valid_wires:
		_result.wire_states[wire.canonical_id()] = _result.output_state(wire.from_component, wire.from_port)
	if not _result.cyclic_components.is_empty():
		var cycle_names: PackedStringArray = []
		var cycle_ids: Array[StringName] = []
		for component_id: StringName in _result.cyclic_components:
			cycle_ids.append(component_id)
		cycle_ids.sort()
		for component_id: StringName in cycle_ids:
			var component: LogicComponent = _circuit.components.get(component_id)
			cycle_names.append(component.display_name if component != null else String(component_id))
		_result.add_error(
			&"circuit.error.circular_dependency", [", ".join(cycle_names)],
			"Circular dependency: %s feeds back within the same simulation tick."
		)
	return _result


func _validate_and_index() -> void:
	for component_id: StringName in _sorted_component_ids():
		var component: LogicComponent = _circuit.components[component_id]
		if not component.is_supported():
			_result.add_error(
				&"circuit.error.unsupported_kind", [component.display_name, component.kind],
				"%s has unsupported kind '%s'."
			)
	var sorted_wires: Array[LogicWire] = _circuit.wires.duplicate()
	sorted_wires.sort_custom(func(left: LogicWire, right: LogicWire) -> bool: return left.canonical_id() < right.canonical_id())
	var seen_wires: Dictionary[String, bool] = {}
	for wire: LogicWire in sorted_wires:
		var source: LogicComponent = _circuit.components.get(wire.from_component)
		var target: LogicComponent = _circuit.components.get(wire.to_component)
		if source == null or target == null:
			_result.add_error(
				&"circuit.error.wire_endpoint_missing", [wire.canonical_id()],
				"Wire %s has a missing endpoint."
			)
			continue
		if wire.from_port < 0 or wire.from_port >= source.output_count() or wire.to_port < 0 or wire.to_port >= target.input_count():
			_result.add_error(
				&"circuit.error.wire_port_invalid", [wire.canonical_id()],
				"Wire %s uses an invalid port."
			)
			continue
		var wire_id: String = wire.canonical_id()
		if seen_wires.has(wire_id):
			_result.add_error(&"circuit.error.duplicate_wire", [wire_id], "Wire %s is duplicated.")
			continue
		seen_wires[wire_id] = true
		_result.valid_wires.append(wire)
		var input_id: String = CircuitLiveStateType.input_key(wire.to_component, wire.to_port)
		if not _result.incoming_by_input.has(input_id):
			_result.incoming_by_input[input_id] = []
		(_result.incoming_by_input[input_id] as Array).append(wire)
		var output_id: String = CircuitLiveStateType.output_key(wire.from_component, wire.from_port)
		if not _result.outgoing_by_output.has(output_id):
			_result.outgoing_by_output[output_id] = []
		(_result.outgoing_by_output[output_id] as Array).append(wire)


func _evaluate_component(component_id: StringName) -> int:
	var visit_state: int = _visit_states.get(component_id, VISIT_NONE)
	if visit_state == VISIT_DONE:
		var existing: LogicComponent = _circuit.components.get(component_id)
		if existing == null or existing.output_count() == 0:
			return _result.observed_states.get(component_id, LogicSignalType.HIGH_Z)
		return _result.output_state(component_id)
	if visit_state == VISIT_ACTIVE:
		_mark_cycle(component_id)
		return LogicSignalType.HIGH_Z
	var component: LogicComponent = _circuit.components.get(component_id)
	if component == null:
		return LogicSignalType.HIGH_Z
	_visit_states[component_id] = VISIT_ACTIVE
	_visit_stack.append(component_id)
	var output_state: int = LogicSignalType.HIGH_Z
	var component_tick: int = 0
	if component.kind == LogicComponentType.KIND_INPUT:
		if not component.signal_name.is_empty() and _result.input_values.has(component.signal_name):
			output_state = LogicSignalType.from_bool(_result.input_values[component.signal_name])
	else:
		var inputs: Array[int] = []
		for port: int in range(component.input_count()):
			var input_id: String = CircuitLiveStateType.input_key(component_id, port)
			var driver_states: Array[int] = []
			var incoming: Array = _result.incoming_by_input.get(input_id, [])
			for wire_variant: Variant in incoming:
				var wire: LogicWire = wire_variant
				driver_states.append(_evaluate_component(wire.from_component))
				component_tick = maxi(component_tick, _result.output_ticks.get(
					CircuitLiveStateType.output_key(wire.from_component, wire.from_port), 0
				))
			var resolved: int = LogicSignalType.resolve_driver_states(driver_states)
			_result.input_states[input_id] = resolved
			inputs.append(resolved)
			if LogicSignalType.has_binary_conflict(driver_states) and not _result.shorted_inputs.has(input_id):
				_result.shorted_inputs[input_id] = true
				_result.add_error(
					&"circuit.error.short_circuit", [component.display_name, port + 1],
					"Short circuit at %s input %d: low and high drive the same port."
				)
		output_state = LogicSignalType.evaluate_gate(component.kind, inputs)
		if component.is_basic_gate():
			component_tick += 1
	if _result.cyclic_components.has(component_id):
		output_state = LogicSignalType.HIGH_Z
		component_tick = 0
	_result.component_ticks[component_id] = component_tick
	if component.output_count() > 0:
		var output_id: String = CircuitLiveStateType.output_key(component_id, 0)
		_result.output_states[output_id] = output_state
		_result.output_ticks[output_id] = component_tick
	elif component.is_observer():
		_result.observed_states[component_id] = output_state
	_visit_stack.pop_back()
	_visit_states[component_id] = VISIT_DONE
	_result.evaluation_order.append(component_id)
	return output_state


func _mark_cycle(reentered_id: StringName) -> void:
	var start_index: int = _visit_stack.find(reentered_id)
	if start_index < 0:
		return
	for index: int in range(start_index, _visit_stack.size()):
		_result.cyclic_components[_visit_stack[index]] = true


func _sorted_component_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for component_id: StringName in _circuit.components:
		ids.append(component_id)
	ids.sort()
	return ids
