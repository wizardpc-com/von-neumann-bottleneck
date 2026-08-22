class_name SystemTrace
extends RefCounted

const EventType = preload("res://src/system_lab/system_event.gd")

const BOTTLENECK_CPU: StringName = &"cpu"
const BOTTLENECK_RAM: StringName = &"ram"
const BOTTLENECK_BUS: StringName = &"bus"
const BOTTLENECK_MIXED: StringName = &"mixed"

var events: Array[SystemEvent] = []
var metrics: Dictionary = {}
var output_data: Array[int] = []
var expected_output: Array[int] = []
var passed: bool = false
var program_source: String = ""
var program_signature: String = ""
var topology_signature: String = ""
var test_name: String = ""


func add_event(event: SystemEvent) -> void:
	events.append(event)


func bottleneck() -> StringName:
	var shares: Dictionary[StringName, int] = {
		BOTTLENECK_CPU: int(metrics.get("cpu_compute_cycles", 0)),
		BOTTLENECK_RAM: int(metrics.get("ram_service_cycles", 0)),
		BOTTLENECK_BUS: int(metrics.get("bus_control_cycles", 0)) + int(metrics.get("bus_transfer_cycles", 0)),
	}
	var accounted: int = 0
	var maximum: int = 0
	for category: StringName in shares:
		accounted += shares[category]
		maximum = maxi(maximum, shares[category])
	if accounted <= 0 or maximum * 2 < accounted:
		return BOTTLENECK_MIXED
	var winners: Array[StringName] = []
	for category: StringName in [BOTTLENECK_CPU, BOTTLENECK_RAM, BOTTLENECK_BUS]:
		if shares[category] == maximum:
			winners.append(category)
	return winners[0] if winners.size() == 1 else BOTTLENECK_MIXED


func canonical_signature() -> String:
	var event_data: Array[Dictionary] = []
	for event: SystemEvent in events:
		event_data.append(event.to_dictionary())
	return JSON.stringify({
		"events": event_data,
		"metrics": metrics,
		"output_data": output_data,
		"expected_output": expected_output,
		"passed": passed,
		"program_source": program_source,
		"program_signature": program_signature,
		"topology_signature": topology_signature,
		"test_name": test_name,
		"bottleneck": String(bottleneck()),
	})
