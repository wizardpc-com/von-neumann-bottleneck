class_name SimulationTrace
extends RefCounted

const SimulationEventType = preload("res://src/simulation/simulation_event.gd")

var events: Array[SimulationEventType] = []
var metrics: Dictionary = {}
var result_value: int = 0
var expected_value: int = 0
var passed: bool = false
var cache_capacity_lines: int = 1
var test_name: String = ""
var loop_order: Array[StringName] = []
var program_source: String = ""


func add_event(event: SimulationEventType) -> void:
	events.append(event)


func canonical_signature() -> String:
	var event_data: Array[Dictionary] = []
	for event: SimulationEventType in events:
		event_data.append(event.to_dictionary())
	var data: Dictionary = {
		"events": event_data,
		"metrics": metrics,
		"result_value": result_value,
		"expected_value": expected_value,
		"passed": passed,
		"cache_capacity_lines": cache_capacity_lines,
		"test_name": test_name,
		"loop_order": loop_order.map(func(item: StringName) -> String: return String(item)),
		"program_source": program_source,
	}
	return JSON.stringify(data)
