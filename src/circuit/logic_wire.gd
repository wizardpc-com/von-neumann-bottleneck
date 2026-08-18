class_name LogicWire
extends RefCounted

var from_component: StringName
var from_port: int
var to_component: StringName
var to_port: int


func _init(
		p_from_component: StringName = &"",
		p_from_port: int = 0,
		p_to_component: StringName = &"",
		p_to_port: int = 0
	) -> void:
	from_component = p_from_component
	from_port = p_from_port
	to_component = p_to_component
	to_port = p_to_port


func canonical_id() -> String:
	return "%s:%d>%s:%d" % [from_component, from_port, to_component, to_port]


func duplicate_wire() -> LogicWire:
	return LogicWire.new(from_component, from_port, to_component, to_port)


func to_dictionary() -> Dictionary:
	return {
		"from_component": String(from_component),
		"from_port": from_port,
		"to_component": String(to_component),
		"to_port": to_port,
	}
