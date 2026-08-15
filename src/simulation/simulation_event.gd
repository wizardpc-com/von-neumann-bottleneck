class_name SimulationEvent
extends RefCounted

var kind: StringName
var cycle: int
var duration: int
var source_device: StringName
var target_device: StringName
var address: int
var cache_line: int
var value: int
var message: String


func _init(
		p_kind: StringName = &"",
		p_cycle: int = 0,
		p_duration: int = 0,
		p_source_device: StringName = &"",
		p_target_device: StringName = &"",
		p_address: int = -1,
		p_cache_line: int = -1,
		p_value: int = 0,
		p_message: String = ""
	) -> void:
	kind = p_kind
	cycle = p_cycle
	duration = p_duration
	source_device = p_source_device
	target_device = p_target_device
	address = p_address
	cache_line = p_cache_line
	value = p_value
	message = p_message


func to_dictionary() -> Dictionary:
	return {
		"kind": String(kind),
		"cycle": cycle,
		"duration": duration,
		"source": String(source_device),
		"target": String(target_device),
		"address": address,
		"cache_line": cache_line,
		"value": value,
		"message": message,
	}

