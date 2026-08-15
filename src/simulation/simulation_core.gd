class_name SimulationCore
extends RefCounted

const DSLParserType = preload("res://src/simulation/dsl_parser.gd")
const DSLProgramType = preload("res://src/simulation/dsl_program.gd")
const DSLInstructionType = preload("res://src/simulation/dsl_instruction.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")

const ARRAY_WIDTH: int = 4
const ARRAY_LENGTH: int = 16
const INT_BYTES: int = 4
const CACHE_LINE_INTS: int = 4
const CACHE_LINE_BYTES: int = CACHE_LINE_INTS * INT_BYTES

const CACHE_LOOKUP_CYCLES: int = 1
const BUS_REQUEST_CYCLES: int = 2
const RAM_ACCESS_CYCLES: int = 12
const BUS_LINE_TRANSFER_CYCLES: int = 4
const ADD_CYCLES: int = 1
const STORE_RESULT_CYCLES: int = 1

const OFFICIAL_DATA: Array[int] = [7, -2, 5, 11, 3, 0, 8, 4, 9, 1, 6, 2, 10, -1, 12, 13]
const CACHE_COSTS: Dictionary[int, int] = {1: 4, 2: 7, 4: 13}


func run(program: DSLProgramType, data: Array[int], cache_lines: int, test_name: String) -> SimulationTraceType:
	var trace := SimulationTraceType.new()
	trace.cache_capacity_lines = cache_lines
	trace.test_name = test_name
	trace.loop_order = program.loop_order.duplicate()
	if not program.is_valid():
		return trace
	if data.size() != ARRAY_LENGTH or not CACHE_COSTS.has(cache_lines):
		return trace

	var registers: Dictionary[StringName, int] = program.registers.duplicate(true)
	var loop_values: Dictionary[StringName, int] = {}
	var resident_lines: Array[int] = []
	var line_last_used: Dictionary[int, int] = {}
	var use_clock: int = 0
	var current_cycle: int = 0
	var compute_cycles: int = 0
	var wait_cycles: int = 0
	var cache_hits: int = 0
	var cache_misses: int = 0
	var ram_bytes: int = 0
	var result_value: int = 0

	for outer_value: int in range(ARRAY_WIDTH):
		loop_values[program.loop_order[0]] = outer_value
		for inner_value: int in range(ARRAY_WIDTH):
			loop_values[program.loop_order[1]] = inner_value
			for instruction: DSLInstructionType in program.loop_instructions:
				if instruction.opcode == &"load":
					var row: int = loop_values[instruction.row_index_variable]
					var column: int = loop_values[instruction.column_index_variable]
					var address: int = row * ARRAY_WIDTH + column
					var line_index: int = address / CACHE_LINE_INTS
					var loaded_value: int = data[address]
					trace.add_event(SimulationEventType.new(
						&"request", current_cycle, 0, &"CPU", &"Cache", address, line_index,
						loaded_value, "LOAD A[%d][%d] → address %d" % [row, column, address]
					))
					trace.add_event(SimulationEventType.new(
						&"cache_lookup", current_cycle, CACHE_LOOKUP_CYCLES, &"Cache", &"Cache",
						address, line_index, loaded_value, "Cache tag lookup for line %d" % line_index
					))
					current_cycle += CACHE_LOOKUP_CYCLES
					wait_cycles += CACHE_LOOKUP_CYCLES
					use_clock += 1
					if line_index in resident_lines:
						cache_hits += 1
						line_last_used[line_index] = use_clock
						trace.add_event(SimulationEventType.new(
							&"cache_hit", current_cycle, 0, &"Cache", &"CPU", address,
							line_index, loaded_value, "HIT — line %d already resident" % line_index
						))
					else:
						cache_misses += 1
						trace.add_event(SimulationEventType.new(
							&"cache_miss", current_cycle, 0, &"Cache", &"Bus", address,
							line_index, loaded_value, "MISS — request cache line %d" % line_index
						))
						trace.add_event(SimulationEventType.new(
							&"bus_request", current_cycle, BUS_REQUEST_CYCLES, &"Cache", &"Bus",
							address, line_index, loaded_value, "Bus carries the read request"
						))
						current_cycle += BUS_REQUEST_CYCLES
						wait_cycles += BUS_REQUEST_CYCLES
						trace.add_event(SimulationEventType.new(
							&"ram_access", current_cycle, RAM_ACCESS_CYCLES, &"Bus", &"RAM",
							address, line_index, loaded_value, "RAM fetches 4 contiguous ints"
						))
						current_cycle += RAM_ACCESS_CYCLES
						wait_cycles += RAM_ACCESS_CYCLES
						trace.add_event(SimulationEventType.new(
							&"line_return", current_cycle, BUS_LINE_TRANSFER_CYCLES, &"RAM", &"Cache",
							address, line_index, loaded_value, "16-byte cache line returns through Bus"
						))
						current_cycle += BUS_LINE_TRANSFER_CYCLES
						wait_cycles += BUS_LINE_TRANSFER_CYCLES
						ram_bytes += CACHE_LINE_BYTES
						if resident_lines.size() >= cache_lines:
							var evicted_line: int = _least_recently_used_line(resident_lines, line_last_used)
							resident_lines.erase(evicted_line)
							line_last_used.erase(evicted_line)
							trace.add_event(SimulationEventType.new(
								&"cache_evict", current_cycle, 0, &"Cache", &"Cache", address,
								evicted_line, 0, "Evict least-recently-used line %d" % evicted_line
							))
						resident_lines.append(line_index)
						line_last_used[line_index] = use_clock
						trace.add_event(SimulationEventType.new(
							&"cache_fill", current_cycle, 0, &"Cache", &"CPU", address,
							line_index, loaded_value, "Fill line %d, then return requested int" % line_index
						))
					registers[instruction.destination] = loaded_value
				elif instruction.opcode == &"add":
					registers[instruction.destination] += registers[instruction.source]
					trace.add_event(SimulationEventType.new(
						&"compute", current_cycle, ADD_CYCLES, &"CPU", &"CPU", -1, -1,
						registers[instruction.destination], "ADD %s, %s → %d" % [
							String(instruction.destination), String(instruction.source), registers[instruction.destination]
						]
					))
					current_cycle += ADD_CYCLES
					compute_cycles += ADD_CYCLES

	for instruction: DSLInstructionType in program.final_instructions:
		if instruction.opcode == &"store":
			result_value = registers[instruction.source]
			trace.add_event(SimulationEventType.new(
				&"store_result", current_cycle, STORE_RESULT_CYCLES, &"CPU", &"TestBench",
				-1, -1, result_value, "STORE result, %s → %d" % [String(instruction.source), result_value]
			))
			current_cycle += STORE_RESULT_CYCLES
			compute_cycles += STORE_RESULT_CYCLES

	var expected: int = 0
	for item: int in data:
		expected += item
	trace.result_value = result_value
	trace.expected_value = expected
	trace.passed = result_value == expected
	trace.metrics = {
		"total_cycles": current_cycle,
		"compute_cycles": compute_cycles,
		"wait_cycles": wait_cycles,
		"cache_hits": cache_hits,
		"cache_misses": cache_misses,
		"ram_bytes_transferred": ram_bytes,
		"hardware_cost": CACHE_COSTS[cache_lines],
	}
	return trace


func run_source(source: String, data: Array[int], cache_lines: int, test_name: String) -> SimulationTraceType:
	return run(DSLParserType.parse(source), data, cache_lines, test_name)


static func official_data_copy() -> Array[int]:
	return OFFICIAL_DATA.duplicate()


static func _least_recently_used_line(lines: Array[int], last_used: Dictionary[int, int]) -> int:
	var selected: int = lines[0]
	var selected_clock: int = last_used.get(selected, -1)
	for line: int in lines:
		var clock: int = last_used.get(line, -1)
		if clock < selected_clock:
			selected = line
			selected_clock = clock
	return selected
