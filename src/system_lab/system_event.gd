class_name SystemEvent
extends RefCounted

var kind: StringName = &""
var cycle: int = 0
var duration: int = 0
var route_devices: Array[StringName] = []
var source_line: int = 0
var details: Dictionary = {}


func _init(
		p_kind: StringName = &"",
		p_cycle: int = 0,
		p_duration: int = 0,
		p_route_devices: Array[StringName] = [],
		p_source_line: int = 0,
		p_details: Dictionary = {}
	) -> void:
	kind = p_kind
	cycle = p_cycle
	duration = p_duration
	route_devices = p_route_devices.duplicate()
	source_line = p_source_line
	details = p_details.duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"kind": String(kind),
		"cycle": cycle,
		"duration": duration,
		"route_devices": route_devices.map(func(value: StringName) -> String: return String(value)),
		"source_line": source_line,
		"details": details,
	}
