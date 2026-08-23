extends SceneTree

const DSLParserType = preload("res://src/simulation/dsl_parser.gd")
const DSLProgramType = preload("res://src/simulation/dsl_program.gd")
const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationCoreType = preload("res://src/simulation/simulation_core.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")

var failures: Array[String] = []


func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("PASS: Python-shaped DSL, deterministic simulation, route, and cache-goal tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d test assertion(s) failed" % failures.size())
		quit(1)


func _run_all() -> void:
	var core := SimulationCoreType.new()
	var official: Array[int] = SimulationCoreType.official_data_copy()
	var column_program: DSLProgramType = DSLParserType.parse(ProgramTemplatesType.COLUMN_FIRST)
	var row_program: DSLProgramType = DSLParserType.parse(ProgramTemplatesType.ROW_FIRST)
	_assert(column_program.is_valid(), "Column-first Python-shaped template must parse: %s" % str(column_program.errors))
	_assert(row_program.is_valid(), "Row-first Python-shaped template must parse: %s" % str(row_program.errors))
	if not column_program.is_valid() or not row_program.is_valid():
		return
	_assert(column_program.traversal_pattern() == "column-first", "Starter template must be identified as column-first.")
	_assert(row_program.traversal_pattern() == "row-first", "Edited template must be identified as row-first.")
	_assert(column_program.memory_address_order(8) == [0, 4, 8, 12, 1, 5, 9, 13], "Live Program preview must derive the starter address order from parsed IR.")
	_assert(row_program.memory_address_order(8) == [0, 1, 2, 3, 4, 5, 6, 7], "Live Program preview must change when the executable loop order changes.")
	var column_explanations: Dictionary[int, String] = column_program.line_explanations()
	_assert(column_explanations.size() == 6, "Every non-blank starter line, including its comment, must have a line explanation.")
	_assert("outer" in column_explanations[3] and "`col`" in column_explanations[3], "Outer-loop explanation must come from parsed IR.")
	_assert("Load A[row][col]" in column_explanations[5] and "add it to `acc`" in column_explanations[5], "Memory-line explanation must describe the executable load and accumulation.")
	_assert("OUT[0]" in column_explanations[6], "Final store explanation must describe Test Bench output.")
	_assert(column_program.instructions.size() == 3, "Nested IR must contain initialization, one root loop, and final store.")
	_assert(column_program.instructions[1].children.size() == 1, "Outer loop must own the inner loop in IR.")

	var column: SimulationTraceType = core.run(column_program, official, 1, "Official Test Set")
	var row: SimulationTraceType = core.run(row_program, official, 1, "Official Test Set")
	_assert(column.passed and row.passed, "Both official programs must produce the correct sum.")
	_assert(column.result_value == 88, "Official data sum must stay fixed at 88.")
	_assert(int(column.metrics["cache_misses"]) == 16, "One-line column-first should miss on all 16 loads.")
	_assert(int(row.metrics["cache_misses"]) == 4, "One-line row-first should miss once per row cache line.")
	_assert(int(row.metrics["cache_hits"]) == 12, "One-line row-first should hit 12 times.")
	_assert(int(column.metrics["total_cycles"]) == 321, "Column-first reference total must remain 321 cycles.")
	_assert(int(column.metrics["compute_cycles"]) == 17, "Column-first must spend 17 compute cycles.")
	_assert(int(column.metrics["wait_cycles"]) == 304, "Column-first must spend 304 wait cycles.")
	_assert(int(column.metrics["ram_bytes_transferred"]) == 256, "Column-first must fetch 256 RAM bytes.")
	_assert(int(row.metrics["total_cycles"]) == 105, "Row-first reference total must remain 105 cycles.")
	_assert(int(row.metrics["wait_cycles"]) == 88, "Row-first must spend 88 wait cycles.")
	_assert(int(row.metrics["ram_bytes_transferred"]) == 64, "Row-first must fetch only 64 RAM bytes.")

	var column_addresses: Array[int] = _request_addresses(column)
	var row_addresses: Array[int] = _request_addresses(row)
	_assert(column_addresses.slice(0, 4) == [0, 4, 8, 12], "Column-first DSL must directly generate its strided address order.")
	_assert(row_addresses.slice(0, 4) == [0, 1, 2, 3], "Swapping the DSL loops must directly generate contiguous addresses.")

	var first_request: SimulationEventType = _first_event(column, &"request")
	var first_miss: SimulationEventType = _first_event(column, &"cache_miss")
	var first_return: SimulationEventType = _first_event(column, &"line_return")
	_assert(first_request != null and first_request.source_line == 5, "Trace events must retain the executable DSL source line.")
	_assert(first_request.route_devices == [&"CPU", &"Cache"], "Load request route must be CPU → Cache.")
	_assert(first_miss.route_devices == [&"Cache"], "Cache miss is internal component feedback, not a fake wire packet.")
	_assert(first_return.route_devices == [&"RAM", &"Bus", &"Cache"], "Line return must explicitly route RAM → Bus → Cache.")
	_assert(first_return.details.get("line_values", []) == [7, -2, 5, 11], "Trace must carry the authoritative returned Cache-line values.")
	_assert(column.program_source == ProgramTemplatesType.COLUMN_FIRST, "Trace must retain the exact program source used for the run.")

	var wait_from_events: int = 0
	for event: SimulationEventType in column.events:
		if event.kind in [&"cache_lookup", &"bus_request", &"ram_access", &"line_return"]:
			wait_from_events += event.duration
	_assert(wait_from_events == int(column.metrics["wait_cycles"]), "Profiler waiting evidence must sum exactly to wait_cycles.")

	var repeat: SimulationTraceType = core.run(row_program, official, 1, "Official Test Set")
	_assert(row.canonical_signature() == repeat.canonical_signature(), "Identical source and inputs must generate an identical enriched trace.")
	var signature_before_playback: String = row.canonical_signature()
	for event: SimulationEventType in row.events:
		var ignored: Dictionary = event.to_dictionary()
		if ignored.is_empty():
			failures.append("Every event must serialize for playback.")
	_assert(signature_before_playback == row.canonical_signature(), "Reading an enriched trace must not mutate simulation output.")

	var column_two_lines: SimulationTraceType = core.run(column_program, official, 2, "Official Test Set")
	var column_four_lines: SimulationTraceType = core.run(column_program, official, 4, "Official Test Set")
	_assert(int(column_two_lines.metrics["total_cycles"]) == 321, "Two-line column-first must remain over the 105-cycle target.")
	_assert(int(column_two_lines.metrics["hardware_cost"]) == 7, "Two-line Cache cost must remain 7.")
	_assert(int(column_four_lines.metrics["total_cycles"]) == 105, "Four-line column-first must meet the 105-cycle target through hardware capacity.")
	_assert(int(column_four_lines.metrics["cache_misses"]) == 4, "Four-line column-first must keep all four lines after compulsory misses.")
	_assert(int(column.metrics["hardware_cost"]) == 4 and int(column_four_lines.metrics["hardware_cost"]) == 13, "Software and hardware solutions must expose cost 4 versus cost 13.")

	var direct: SimulationTraceType = core.run_workload(row_program, official, 0, "Direct Memory", 1, 0, true)
	_assert(direct.passed and direct.result_value == 88, "The authored no-Cache observation workload must remain correct.")
	_assert(int(direct.metrics["total_cycles"]) == 257 and int(direct.metrics["wait_cycles"]) == 240, "Direct word reads must spend 15 wait cycles per load and preserve 17 compute cycles.")
	_assert(int(direct.metrics["ram_bytes_transferred"]) == 64 and int(direct.metrics["hardware_cost"]) == 0, "Direct reads must transfer one four-byte value each without Cache cost.")
	_assert(int(direct.metrics["cache_hits"]) == 0 and int(direct.metrics["cache_misses"]) == 0, "Cache-free evidence must not fabricate hit or miss counts.")
	var direct_request: SimulationEventType = _first_event(direct, &"request")
	var direct_return: SimulationEventType = _first_event(direct, &"value_return")
	_assert(direct_request.route_devices == [&"CPU", &"Bus"], "Cache-free requests must follow the visible CPU → Bus route.")
	_assert(direct_return.route_devices == [&"RAM", &"Bus", &"CPU"], "Cache-free values must return RAM → Bus → CPU.")

	var two_pass: SimulationTraceType = core.run_workload(row_program, official, 1, "Two Passes", 2)
	var blocked: SimulationTraceType = core.run_workload(row_program, official, 1, "Blocked Two Passes", 2, 1)
	var large_cache: SimulationTraceType = core.run_workload(row_program, official, 4, "Two Passes", 2)
	_assert(two_pass.passed and blocked.passed and large_cache.passed, "Repeated and blocked workloads must preserve program correctness.")
	_assert(int(two_pass.metrics["total_cycles"]) == 210 and int(two_pass.metrics["cache_misses"]) == 8, "A one-line Cache must reload all four lines on the second unblocked pass.")
	_assert(int(two_pass.metrics["cache_hits"]) == 24 and int(two_pass.metrics["ram_bytes_transferred"]) == 128, "Two unblocked row-first passes must expose the complete working-set reload evidence.")
	_assert(int(blocked.metrics["total_cycles"]) == 138 and int(blocked.metrics["cache_misses"]) == 4, "Line-sized blocking must reuse each fetched line across both passes.")
	_assert(int(blocked.metrics["cache_hits"]) == 28 and int(blocked.metrics["ram_bytes_transferred"]) == 64, "Blocked evidence must show four compulsory misses and 28 hits.")
	_assert(int(large_cache.metrics["total_cycles"]) == 138 and int(large_cache.metrics["hardware_cost"]) == 13, "A four-line Cache must provide a costlier capstone solution with the same cycle target.")
	var blocked_repeat: SimulationTraceType = core.run_workload(row_program, official, 1, "Blocked Two Passes", 2, 1)
	_assert(blocked.canonical_signature() == blocked_repeat.canonical_signature(), "Program-derived blocking schedules must be deterministic.")
	_assert(_request_addresses(blocked).slice(0, 8) == [0, 1, 2, 3, 0, 1, 2, 3], "Blocking must derive addresses from IR and finish both passes for one line before moving on.")

	var explicit_load_source: String = """acc = 0
for row in range(4):
    for col in range(4):
        value = load(A[row][col])
        acc += value
store(OUT[0], acc)
"""
	var explicit_load: DSLProgramType = DSLParserType.parse(explicit_load_source)
	_assert(explicit_load.is_valid(), "Separate load and += statements must be valid: %s" % str(explicit_load.errors))
	if explicit_load.is_valid():
		var explicit_trace: SimulationTraceType = core.run(explicit_load, official, 1, "Official Test Set")
		_assert(explicit_trace.result_value == 88 and int(explicit_trace.metrics["total_cycles"]) == 105, "Separate explicit operations must execute through the same core semantics.")

	var old_syntax: DSLProgramType = DSLParserType.parse("register sum = 0\nfor row in 0..4\nend\nstore result, sum")
	var tabbed: DSLProgramType = DSLParserType.parse("acc = 0\nfor row in range(4):\n\tfor col in range(4):\n        acc += load(A[row][col])\nstore(OUT[0], acc)")
	var bad_range: DSLProgramType = DSLParserType.parse("acc = 0\nfor row in range(8):\n    for col in range(4):\n        acc += load(A[row][col])\nstore(OUT[0], acc)")
	_assert(not old_syntax.is_valid(), "The tagged v0.1 syntax must be rejected after the deliberate v0.2 cutover.")
	_assert(not tabbed.is_valid(), "Tabs must be rejected with a line-aware indentation error.")
	_assert(not bad_range.is_valid(), "Only range(4) is valid for this focused challenge.")


func _request_addresses(trace: SimulationTraceType) -> Array[int]:
	var addresses: Array[int] = []
	for event: SimulationEventType in trace.events:
		if event.kind == &"request":
			addresses.append(event.address)
	return addresses


func _first_event(trace: SimulationTraceType, kind: StringName) -> SimulationEventType:
	for event: SimulationEventType in trace.events:
		if event.kind == kind:
			return event
	return null


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
