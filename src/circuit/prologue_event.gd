class_name PrologueEvent
extends RefCounted

const DigitalValueType = preload("res://src/circuit/digital_value.gd")

var kind: StringName = &""
var tick: int = 0
var visual_step: int = 0
var sequence_step: int = 0
var component_id: StringName = &""
var from_component: StringName = &""
var from_port: int = -1
var to_component: StringName = &""
var to_port: int = -1
var value: DigitalValue
var input_values: Array[DigitalValue] = []
var message_key: StringName = &""
var message_args: Array = []


func _init(
		p_kind: StringName = &"",
		p_tick: int = 0,
		p_visual_step: int = 0,
		p_sequence_step: int = 0,
		p_component_id: StringName = &"",
		p_from_component: StringName = &"",
		p_from_port: int = -1,
		p_to_component: StringName = &"",
		p_to_port: int = -1,
		p_value: DigitalValue = null,
		p_input_values: Array[DigitalValue] = [],
		p_message_key: StringName = &"",
		p_message_args: Array = []
	) -> void:
	kind = p_kind
	tick = p_tick
	visual_step = p_visual_step
	sequence_step = p_sequence_step
	component_id = p_component_id
	from_component = p_from_component
	from_port = p_from_port
	to_component = p_to_component
	to_port = p_to_port
	value = p_value.duplicate_value() if p_value != null else DigitalValueType.low()
	for input_value: DigitalValue in p_input_values:
		input_values.append(input_value.duplicate_value())
	message_key = p_message_key
	message_args = p_message_args.duplicate(true)


func wire_id() -> String:
	return "%s:%d>%s:%d" % [from_component, from_port, to_component, to_port]


func to_dictionary() -> Dictionary:
	var input_data: Array[Dictionary] = []
	for input_value: DigitalValue in input_values:
		input_data.append(input_value.to_dictionary())
	return {
		"kind": String(kind),
		"tick": tick,
		"visual_step": visual_step,
		"sequence_step": sequence_step,
		"component_id": String(component_id),
		"from_component": String(from_component),
		"from_port": from_port,
		"to_component": String(to_component),
		"to_port": to_port,
		"value": value.to_dictionary(),
		"input_values": input_data,
		"message_key": String(message_key),
		"message_args": message_args,
	}
