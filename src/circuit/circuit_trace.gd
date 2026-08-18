class_name CircuitTrace
extends RefCounted

const CircuitEventType = preload("res://src/circuit/circuit_event.gd")

var events: Array[CircuitEvent] = []
var outputs: Dictionary[StringName, bool] = {}
var errors: Array[String] = []
var error_specs: Array[Dictionary] = []
var metrics: Dictionary = {}
var topology_signature: String = ""
var input_values: Dictionary[StringName, bool] = {}


func add_event(event: CircuitEvent) -> void:
	events.append(event)


func is_valid() -> bool:
	return errors.is_empty()


func add_error(key: StringName, arguments: Array, fallback_template: String) -> void:
	error_specs.append({"key": key, "args": arguments.duplicate()})
	errors.append(fallback_template if arguments.is_empty() else fallback_template % arguments)


func canonical_signature() -> String:
	var event_data: Array[Dictionary] = []
	for event: CircuitEvent in events:
		event_data.append(event.to_dictionary())
	var output_data: Dictionary = {}
	var output_names: Array[StringName] = []
	for output_name: StringName in outputs:
		output_names.append(output_name)
	output_names.sort()
	for output_name: StringName in output_names:
		output_data[String(output_name)] = outputs[output_name]
	var input_data: Dictionary = {}
	var input_names: Array[StringName] = []
	for input_name: StringName in input_values:
		input_names.append(input_name)
	input_names.sort()
	for input_name: StringName in input_names:
		input_data[String(input_name)] = input_values[input_name]
	return JSON.stringify({
		"events": event_data,
		"outputs": output_data,
		"errors": errors,
		"metrics": metrics,
		"topology_signature": topology_signature,
		"input_values": input_data,
	})
