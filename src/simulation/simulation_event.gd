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
var source_line: int
var route_devices: Array[StringName] = []
var details: Dictionary = {}


func _init(
		p_kind: StringName = &"",
		p_cycle: int = 0,
		p_duration: int = 0,
		p_source_device: StringName = &"",
		p_target_device: StringName = &"",
		p_address: int = -1,
		p_cache_line: int = -1,
		p_value: int = 0,
		p_message: String = "",
		p_source_line: int = 0,
		p_route_devices: Array[StringName] = [],
		p_details: Dictionary = {}
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
	source_line = p_source_line
	route_devices = p_route_devices.duplicate()
	details = p_details.duplicate(true)


func to_dictionary() -> Dictionary:
	# Scheduling coordinates are presentation evidence and must not invalidate an
	# otherwise identical run receipt when Trace navigation evolves.
	var signature_details: Dictionary = details.duplicate(true)
	signature_details.erase("pass_index")
	signature_details.erase("work_group_index")
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
		"source_line": source_line,
		"route_devices": route_devices.map(func(device: StringName) -> String: return String(device)),
		"details": signature_details,
	}
