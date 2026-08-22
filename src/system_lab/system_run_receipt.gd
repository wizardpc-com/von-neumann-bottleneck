class_name SystemRunReceipt
extends RefCounted

const TraceType = preload("res://src/system_lab/system_trace.gd")

var level_id: StringName = &""
var program_signature: String = ""
var topology_signature: String = ""
var test_set_signature: String = ""
var part_ids: Dictionary[StringName, StringName] = {}
var metrics: Dictionary = {}
var trace_signatures: PackedStringArray = PackedStringArray()
var passed_cases: int = 0
var total_cases: int = 0
var all_passed: bool = false
var diagnosed_bottleneck: StringName = TraceType.BOTTLENECK_MIXED


func populate_from_traces(
		p_level_id: StringName,
		traces: Array,
		p_test_set_signature: String,
		p_part_ids: Dictionary
	) -> void:
	level_id = p_level_id
	test_set_signature = p_test_set_signature
	for key: Variant in p_part_ids:
		part_ids[StringName(key)] = StringName(p_part_ids[key])
	total_cases = traces.size()
	var aggregate := {
		"total_cycles": 0,
		"cpu_compute_cycles": 0,
		"cpu_wait_cycles": 0,
		"ram_service_cycles": 0,
		"bus_control_cycles": 0,
		"bus_transfer_cycles": 0,
		"memory_requests": 0,
		"bytes_transferred": 0,
		"hardware_cost": 0,
		"bus_segments_per_word": 0,
	}
	for trace_variant: Variant in traces:
		var trace: SystemTrace = trace_variant
		if program_signature.is_empty():
			program_signature = trace.program_signature
			topology_signature = trace.topology_signature
		if trace.program_signature != program_signature or trace.topology_signature != topology_signature:
			# A receipt is deliberately one immutable machine/program observation.
			all_passed = false
			return
		trace_signatures.append(trace.canonical_signature().sha256_text())
		if trace.passed:
			passed_cases += 1
		for metric_name: String in aggregate:
			if metric_name in ["hardware_cost", "bus_segments_per_word"]:
				aggregate[metric_name] = int(trace.metrics.get(metric_name, 0))
			else:
				aggregate[metric_name] = int(aggregate[metric_name]) + int(trace.metrics.get(metric_name, 0))
	metrics = aggregate
	all_passed = total_cases > 0 and passed_cases == total_cases
	var aggregate_trace := TraceType.new()
	aggregate_trace.metrics = aggregate.duplicate(true)
	diagnosed_bottleneck = aggregate_trace.bottleneck()


func is_bound_to(
		p_level_id: StringName,
		p_program_signature: String,
		p_topology_signature: String,
		p_test_set_signature: String
	) -> bool:
	return (
		level_id == p_level_id
		and program_signature == p_program_signature
		and topology_signature == p_topology_signature
		and test_set_signature == p_test_set_signature
	)


func canonical_signature() -> String:
	var normalized_parts: Dictionary = {}
	for kind: StringName in part_ids:
		normalized_parts[String(kind)] = String(part_ids[kind])
	return JSON.stringify({
		"level_id": String(level_id),
		"program_signature": program_signature,
		"topology_signature": topology_signature,
		"test_set_signature": test_set_signature,
		"part_ids": normalized_parts,
		"metrics": metrics,
		"trace_signatures": trace_signatures,
		"passed_cases": passed_cases,
		"total_cases": total_cases,
		"all_passed": all_passed,
		"diagnosed_bottleneck": String(diagnosed_bottleneck),
	})
