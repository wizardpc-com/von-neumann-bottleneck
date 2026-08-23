class_name LocalityRunReceipt
extends RefCounted

const TraceType = preload("res://src/simulation/simulation_trace.gd")

var level_id: StringName = &""
var program_signature: String = ""
var traversal_pattern: String = "unknown"
var data_signature: String = ""
var cache_lines: int = 0
var pass_count: int = 1
var block_lines: int = 0
var bypass_cache: bool = false
var metrics: Dictionary = {}
var trace_signature: String = ""
var passed: bool = false


func populate(
		p_level_id: StringName,
		trace: TraceType,
		p_traversal_pattern: String,
		data: Array[int],
		p_pass_count: int,
		p_block_lines: int,
		p_bypass_cache: bool
	) -> void:
	level_id = p_level_id
	program_signature = trace.program_source.sha256_text()
	traversal_pattern = p_traversal_pattern
	data_signature = JSON.stringify(data).sha256_text()
	cache_lines = trace.cache_capacity_lines
	pass_count = p_pass_count
	block_lines = p_block_lines
	bypass_cache = p_bypass_cache
	metrics = trace.metrics.duplicate(true)
	trace_signature = trace.canonical_signature().sha256_text()
	passed = trace.passed


func canonical_signature() -> String:
	return JSON.stringify({
		"level_id": String(level_id),
		"program_signature": program_signature,
		"traversal_pattern": traversal_pattern,
		"data_signature": data_signature,
		"cache_lines": cache_lines,
		"pass_count": pass_count,
		"block_lines": block_lines,
		"bypass_cache": bypass_cache,
		"metrics": metrics,
		"trace_signature": trace_signature,
		"passed": passed,
	})
