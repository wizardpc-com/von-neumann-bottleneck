class_name CircuitSimulator
extends RefCounted

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicSignalType = preload("res://src/circuit/logic_signal.gd")
const CircuitAnalyzerType = preload("res://src/circuit/circuit_analyzer.gd")
const CircuitEventType = preload("res://src/circuit/circuit_event.gd")
const CircuitTraceType = preload("res://src/circuit/circuit_trace.gd")
const CircuitLiveStateType = preload("res://src/circuit/circuit_live_state.gd")


func analyze(circuit: LogicCircuit, external_inputs: Dictionary[StringName, bool]) -> CircuitLiveStateType:
	return CircuitAnalyzerType.new().analyze(circuit, external_inputs)


func evaluate(circuit: LogicCircuit, external_inputs: Dictionary[StringName, bool]) -> CircuitTrace:
	var trace := CircuitTraceType.new()
	if circuit == null:
		trace.add_error(&"circuit.error.circuit_missing", [], "The circuit is missing.")
		return trace
	trace.topology_signature = circuit.canonical_signature()
	trace.input_values = external_inputs.duplicate()
	var live: CircuitLiveStateType = analyze(circuit, external_inputs)
	_copy_analysis_errors(live, trace)
	var required: Dictionary[StringName, bool] = _required_components(circuit, live.incoming_by_input)
	if required.is_empty():
		trace.add_error(&"circuit.error.no_observer", [], "The circuit has no lamp or output terminal to evaluate.")
		_finalize_metrics(trace, circuit, {}, live.component_ticks)
		return trace
	_add_required_input_errors(circuit, external_inputs, live, required, trace)
	if not trace.errors.is_empty():
		_finalize_metrics(trace, circuit, required, live.component_ticks)
		return trace

	var ordered_ids: Array[StringName] = _sorted_required_ids(circuit, required)
	ordered_ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		var left_tick: int = live.component_ticks.get(left, 0)
		var right_tick: int = live.component_ticks.get(right, 0)
		if left_tick != right_tick:
			return left_tick < right_tick
		var left_phase: int = _component_phase(circuit.components[left])
		var right_phase: int = _component_phase(circuit.components[right])
		return left_phase < right_phase if left_phase != right_phase else left < right
	)
	for component_id: StringName in ordered_ids:
		var component: LogicComponent = circuit.components[component_id]
		var tick: int = live.component_ticks.get(component_id, 0)
		var input_values: Array[bool] = []
		for port: int in range(component.input_count()):
			input_values.append(LogicSignalType.to_bool(live.input_state(component_id, port)))
		var output_state: int = live.observed_states.get(component_id, LogicSignalType.HIGH_Z) \
			if component.is_observer() else live.output_state(component_id)
		var output_value: bool = LogicSignalType.to_bool(output_state)
		if component.is_observer() and not component.signal_name.is_empty():
			trace.outputs[component.signal_name] = output_value
		if not component.is_routing_node():
			trace.add_event(CircuitEventType.new(
				&"component_process", tick, component_id, &"", -1, &"", -1,
				output_value, input_values, _component_message(component, input_values, output_value),
				tick * 2 + (1 if component.is_observer() else 0)
			))
		if component.output_count() > 0:
			_emit_outgoing_events(trace, component_id, 0, output_value, tick, live.outgoing_by_output)

	_finalize_metrics(trace, circuit, required, live.component_ticks)
	return trace


func _copy_analysis_errors(live: CircuitLiveStateType, trace: CircuitTrace) -> void:
	for index: int in range(live.errors.size()):
		trace.errors.append(live.errors[index])
		trace.error_specs.append(live.error_specs[index].duplicate(true))


func _add_required_input_errors(
		circuit: LogicCircuit,
		external_inputs: Dictionary[StringName, bool],
		live: CircuitLiveStateType,
		required: Dictionary[StringName, bool],
		trace: CircuitTrace
	) -> void:
	for component_id: StringName in _sorted_required_ids(circuit, required):
		var component: LogicComponent = circuit.components[component_id]
		if component.kind == LogicComponentType.KIND_INPUT:
			if component.signal_name.is_empty() or not external_inputs.has(component.signal_name):
				trace.add_error(&"circuit.error.input_missing", [component.display_name], "Test Bench input %s is missing.")
			continue
		var unresolved_ports: Array[int] = []
		for port: int in range(component.input_count()):
			if not LogicSignalType.is_binary(live.input_state(component_id, port)):
				unresolved_ports.append(port + 1)
		if not unresolved_ports.is_empty() and live.is_valid():
			trace.add_error(
				&"circuit.error.unresolved", [component.display_name],
				"%s is unresolved (cycle, short circuit, or high impedance upstream)."
			)


func _required_components(
		circuit: LogicCircuit,
		incoming_by_input: Dictionary[String, Array]
	) -> Dictionary[StringName, bool]:
	var required: Dictionary[StringName, bool] = {}
	var pending: Array[StringName] = []
	for component_id: StringName in _sorted_component_ids(circuit):
		var component: LogicComponent = circuit.components[component_id]
		if component.is_observer():
			required[component_id] = true
			pending.append(component_id)
	while not pending.is_empty():
		var target_id: StringName = pending.pop_back()
		var target: LogicComponent = circuit.components[target_id]
		for port: int in range(target.input_count()):
			var input_id: String = CircuitLiveStateType.input_key(target_id, port)
			for wire_variant: Variant in incoming_by_input.get(input_id, []):
				var wire: LogicWire = wire_variant
				if required.has(wire.from_component):
					continue
				required[wire.from_component] = true
				pending.append(wire.from_component)
	return required


func _emit_outgoing_events(
		trace: CircuitTrace,
		component_id: StringName,
		port: int,
		value: bool,
		tick: int,
		outgoing_by_output: Dictionary[String, Array]
	) -> void:
	var output_id: String = CircuitLiveStateType.output_key(component_id, port)
	for wire_variant: Variant in outgoing_by_output.get(output_id, []):
		var wire: LogicWire = wire_variant
		trace.add_event(CircuitEventType.new(
			&"wire_signal", tick, &"", wire.from_component, wire.from_port,
			wire.to_component, wire.to_port, value, [],
			"Signal %d travels %s → %s" % [int(value), wire.from_component, wire.to_component],
			tick * 2 + 1
		))


func _component_message(component: LogicComponent, values: Array[bool], result: bool) -> String:
	if component.is_observer():
		return "%s observes %d" % [component.display_name, int(result)]
	if component.kind == LogicComponentType.KIND_INPUT:
		return "%s drives %d" % [component.display_name, int(result)]
	var value_texts: PackedStringArray = []
	for value: bool in values:
		value_texts.append(str(int(value)))
	return "%s processes %s → %d" % [component.display_name, ", ".join(value_texts), int(result)]


func _component_phase(component: LogicComponent) -> int:
	if component.kind == LogicComponentType.KIND_INPUT:
		return 0
	if component.is_observer():
		return 2
	return 1


func _finalize_metrics(
		trace: CircuitTrace,
		circuit: LogicCircuit,
		required: Dictionary[StringName, bool],
		component_ticks: Dictionary[StringName, int]
	) -> void:
	var gate_count: int = 0
	var propagation_ticks: int = 0
	for component_id: StringName in required:
		var component: LogicComponent = circuit.components.get(component_id)
		if component != null and component.is_basic_gate() and component_ticks.has(component_id):
			gate_count += 1
		propagation_ticks = maxi(propagation_ticks, component_ticks.get(component_id, 0))
	trace.metrics = {
		"gate_count": gate_count,
		"propagation_ticks": propagation_ticks,
		"wire_count": _count_wire_events(trace),
	}


func _count_wire_events(trace: CircuitTrace) -> int:
	var count: int = 0
	for event: CircuitEvent in trace.events:
		if event.kind == &"wire_signal":
			count += 1
	return count


func _sorted_component_ids(circuit: LogicCircuit) -> Array[StringName]:
	var ids: Array[StringName] = []
	for component_id: StringName in circuit.components:
		ids.append(component_id)
	ids.sort()
	return ids


func _sorted_required_ids(circuit: LogicCircuit, required: Dictionary[StringName, bool]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for component_id: StringName in circuit.components:
		if required.has(component_id):
			ids.append(component_id)
	ids.sort()
	return ids
