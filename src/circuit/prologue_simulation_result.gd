class_name PrologueSimulationResult
extends RefCounted

const DigitalValueType = preload("res://src/circuit/digital_value.gd")

var topology_signature: String = ""
var external_inputs: Dictionary[StringName, DigitalValue] = {}
var input_values: Dictionary[String, DigitalValue] = {}
var output_values: Dictionary[String, DigitalValue] = {}
var wire_values: Dictionary[String, DigitalValue] = {}
var observed_values: Dictionary[StringName, DigitalValue] = {}
var runtime_state: Dictionary = {}
var events: Array[PrologueEvent] = []
var errors: Array[String] = []
var error_specs: Array[Dictionary] = []
var settle_ticks: int = 0
var settled: bool = false


func add_error(key: StringName, arguments: Array, fallback_template: String) -> void:
	error_specs.append({"key": key, "args": arguments.duplicate(true)})
	errors.append(fallback_template if arguments.is_empty() else fallback_template % arguments)


func is_valid() -> bool:
	return errors.is_empty() and settled


func input_value(component_id: StringName, port: int, width: int = 1) -> DigitalValue:
	var found: DigitalValue = input_values.get(input_key(component_id, port))
	return found.duplicate_value() if found != null else DigitalValueType.low(width)


func output_value(component_id: StringName, port: int, width: int = 1) -> DigitalValue:
	var found: DigitalValue = output_values.get(output_key(component_id, port))
	return found.duplicate_value() if found != null else DigitalValueType.high_z(width)


func wire_value(wire: LogicWire, width: int = 1) -> DigitalValue:
	var found: DigitalValue = wire_values.get(wire.canonical_id())
	return found.duplicate_value() if found != null else DigitalValueType.high_z(width)


func canonical_signature() -> String:
	var event_data: Array[Dictionary] = []
	for event: PrologueEvent in events:
		event_data.append(event.to_dictionary())
	return JSON.stringify({
		"topology": topology_signature,
		"external_inputs": _sorted_named_values(external_inputs),
		"inputs": _sorted_values(input_values),
		"outputs": _sorted_values(output_values),
		"wires": _sorted_values(wire_values),
		"observed": _sorted_named_values(observed_values),
		"runtime_state": runtime_state,
		"events": event_data,
		"errors": errors,
		"settle_ticks": settle_ticks,
		"settled": settled,
	})


static func input_key(component_id: StringName, port: int) -> String:
	return "%s:i%d" % [component_id, port]


static func output_key(component_id: StringName, port: int) -> String:
	return "%s:o%d" % [component_id, port]


func _sorted_values(source: Dictionary[String, DigitalValue]) -> Dictionary:
	var keys: Array[String] = []
	for key: String in source:
		keys.append(key)
	keys.sort()
	var result: Dictionary = {}
	for key: String in keys:
		result[key] = source[key].to_dictionary()
	return result


func _sorted_named_values(source: Dictionary[StringName, DigitalValue]) -> Dictionary:
	var keys: Array[StringName] = []
	for key: StringName in source:
		keys.append(key)
	keys.sort()
	var result: Dictionary = {}
	for key: StringName in keys:
		result[String(key)] = source[key].to_dictionary()
	return result
