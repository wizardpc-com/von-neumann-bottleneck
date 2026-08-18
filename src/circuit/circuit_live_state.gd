class_name CircuitLiveState
extends RefCounted

const LogicSignalType = preload("res://src/circuit/logic_signal.gd")

var topology_signature: String = ""
var input_values: Dictionary[StringName, bool] = {}
var input_states: Dictionary[String, int] = {}
var output_states: Dictionary[String, int] = {}
var wire_states: Dictionary[String, int] = {}
var output_ticks: Dictionary[String, int] = {}
var component_ticks: Dictionary[StringName, int] = {}
var observed_states: Dictionary[StringName, int] = {}
var evaluation_order: Array[StringName] = []
var cyclic_components: Dictionary[StringName, bool] = {}
var shorted_inputs: Dictionary[String, bool] = {}
var incoming_by_input: Dictionary[String, Array] = {}
var outgoing_by_output: Dictionary[String, Array] = {}
var valid_wires: Array[LogicWire] = []
var errors: Array[String] = []
var error_specs: Array[Dictionary] = []


func add_error(key: StringName, arguments: Array, fallback_template: String) -> void:
	error_specs.append({"key": key, "args": arguments.duplicate()})
	errors.append(fallback_template if arguments.is_empty() else fallback_template % arguments)


func is_valid() -> bool:
	return errors.is_empty()


func input_state(component_id: StringName, port: int) -> int:
	return input_states.get(input_key(component_id, port), LogicSignalType.LOW)


func output_state(component_id: StringName, port: int = 0) -> int:
	return output_states.get(output_key(component_id, port), LogicSignalType.HIGH_Z)


func wire_state(wire: LogicWire) -> int:
	return wire_states.get(wire.canonical_id(), LogicSignalType.HIGH_Z)


func canonical_signature() -> String:
	var cycle_ids: Array[String] = []
	for component_id: StringName in cyclic_components:
		cycle_ids.append(String(component_id))
	cycle_ids.sort()
	var short_ids: Array[String] = []
	for port_id: String in shorted_inputs:
		short_ids.append(port_id)
	short_ids.sort()
	return JSON.stringify({
		"topology": topology_signature,
		"inputs": _sorted_state_map(input_states),
		"outputs": _sorted_state_map(output_states),
		"wires": _sorted_state_map(wire_states),
		"cycles": cycle_ids,
		"shorts": short_ids,
		"errors": errors,
	})


static func input_key(component_id: StringName, port: int) -> String:
	return "%s:i%d" % [component_id, port]


static func output_key(component_id: StringName, port: int) -> String:
	return "%s:o%d" % [component_id, port]


func _sorted_state_map(source: Dictionary[String, int]) -> Dictionary:
	var keys: Array[String] = []
	for key: String in source:
		keys.append(key)
	keys.sort()
	var result: Dictionary = {}
	for key: String in keys:
		result[key] = source[key]
	return result
