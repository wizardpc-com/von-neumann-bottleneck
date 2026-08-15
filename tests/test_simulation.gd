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
		print("PASS: all cache-locality simulation tests passed")
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
	_assert(column_program.is_valid(), "Column-first template must parse: %s" % str(column_program.errors))
	_assert(row_program.is_valid(), "Row-first template must parse: %s" % str(row_program.errors))
	if not column_program.is_valid() or not row_program.is_valid():
		return
	_assert(column_program.traversal_pattern() == "column-first", "Default template must be identified as column-first.")
	_assert(row_program.traversal_pattern() == "row-first", "Optimized template must be identified as row-first.")

	var column: SimulationTraceType = core.run(column_program, official, 1, "Official")
	var row: SimulationTraceType = core.run(row_program, official, 1, "Official")
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
	_assert(
		int(row.metrics["total_cycles"]) * 2 < int(column.metrics["total_cycles"]),
		"Row-first total cycles must be less than half of column-first."
	)

	var repeat: SimulationTraceType = core.run(row_program, official, 1, "Official")
	_assert(row.canonical_signature() == repeat.canonical_signature(), "Identical input must generate an identical trace.")

	var signature_before_playback: String = row.canonical_signature()
	var playback_checksum: int = 0
	for event: SimulationEventType in row.events:
		playback_checksum += event.cycle + event.duration
	_assert(playback_checksum > 0, "Trace should contain playable timed events.")
	_assert(signature_before_playback == row.canonical_signature(), "Reading a trace for playback must not mutate simulation output.")

	var column_four_lines: SimulationTraceType = core.run(column_program, official, 4, "Official")
	var column_two_lines: SimulationTraceType = core.run(column_program, official, 2, "Official")
	_assert(int(column_two_lines.metrics["cache_misses"]) == 16, "Two lines still thrash under the column-first stride.")
	_assert(int(column_two_lines.metrics["hardware_cost"]) == 7, "Two-line Cache cost must remain 7.")
	_assert(int(column_four_lines.metrics["cache_misses"]) == 4, "Four cache lines should retain the whole 4x4 array.")
	_assert(
		int(column.metrics["hardware_cost"]) < int(column_four_lines.metrics["hardware_cost"]),
		"Larger cache capacity must have a higher hardware cost."
	)

	var invalid: DSLProgramType = DSLParserType.parse("register sum = 0\nfor row in 0..4\nadd sum, sum\nend\nstore result, sum")
	_assert(not invalid.is_valid(), "A program without two nested loops and a load must be rejected.")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
