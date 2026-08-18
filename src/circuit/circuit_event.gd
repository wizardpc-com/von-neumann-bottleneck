class_name CircuitEvent
extends RefCounted

var kind: StringName
var tick: int
var visual_step: int
var component_id: StringName
var from_component: StringName
var from_port: int
var to_component: StringName
var to_port: int
var value: bool
var input_values: Array[bool] = []
var message: String


func _init(
		p_kind: StringName = &"",
		p_tick: int = 0,
		p_component_id: StringName = &"",
		p_from_component: StringName = &"",
		p_from_port: int = -1,
		p_to_component: StringName = &"",
		p_to_port: int = -1,
		p_value: bool = false,
		p_input_values: Array[bool] = [],
		p_message: String = "",
		p_visual_step: int = 0
	) -> void:
	kind = p_kind
	tick = p_tick
	visual_step = p_visual_step
	component_id = p_component_id
	from_component = p_from_component
	from_port = p_from_port
	to_component = p_to_component
	to_port = p_to_port
	value = p_value
	input_values = p_input_values.duplicate()
	message = p_message


func wire_id() -> String:
	return "%s:%d>%s:%d" % [from_component, from_port, to_component, to_port]


func to_dictionary() -> Dictionary:
	return {
		"kind": String(kind),
		"tick": tick,
		"visual_step": visual_step,
		"component_id": String(component_id),
		"from_component": String(from_component),
		"from_port": from_port,
		"to_component": String(to_component),
		"to_port": to_port,
		"value": value,
		"input_values": input_values,
		"message": message,
	}
