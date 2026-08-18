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
	trace.program_source = program.source
	if not program.is_valid():
		return trace
	if data.size() != ARRAY_LENGTH or not CACHE_COSTS.has(cache_lines):
		return trace

	var state: Dictionary = {
		"registers": {},
		"loop_values": {},
		"resident_lines": [],
		"line_last_used": {},
		"use_clock": 0,
		"current_cycle": 0,
		"compute_cycles": 0,
		"wait_cycles": 0,
		"cache_hits": 0,
		"cache_misses": 0,
		"ram_bytes": 0,
		"result_value": 0,
	}
	_execute_block(program.instructions, data, cache_lines, trace, state)

	var expected: int = 0
	for item: int in data:
		expected += item
	trace.result_value = int(state["result_value"])
	trace.expected_value = expected
	trace.passed = trace.result_value == expected
	trace.metrics = {
		"total_cycles": int(state["current_cycle"]),
		"compute_cycles": int(state["compute_cycles"]),
		"wait_cycles": int(state["wait_cycles"]),
		"cache_hits": int(state["cache_hits"]),
		"cache_misses": int(state["cache_misses"]),
		"ram_bytes_transferred": int(state["ram_bytes"]),
		"hardware_cost": CACHE_COSTS[cache_lines],
	}
	return trace


func run_source(source: String, data: Array[int], cache_lines: int, test_name: String) -> SimulationTraceType:
	return run(DSLParserType.parse(source), data, cache_lines, test_name)


static func official_data_copy() -> Array[int]:
	return OFFICIAL_DATA.duplicate()


func _execute_block(
		block: Array,
		data: Array[int],
		cache_lines: int,
		trace: SimulationTraceType,
		state: Dictionary
	) -> void:
	var registers: Dictionary = state["registers"]
	var loop_values: Dictionary = state["loop_values"]
	for instruction: DSLInstructionType in block:
		match instruction.opcode:
			&"assign_const":
				registers[instruction.destination] = instruction.immediate
			&"for_range":
				for loop_value: int in range(instruction.range_stop):
					loop_values[instruction.destination] = loop_value
					_execute_block(instruction.children, data, cache_lines, trace, state)
			&"load":
				registers[instruction.destination] = _perform_load(instruction, data, cache_lines, trace, state)
			&"add_load":
				var loaded_value: int = _perform_load(instruction, data, cache_lines, trace, state)
				registers[instruction.destination] = int(registers[instruction.destination]) + loaded_value
				_add_compute_event(instruction, int(registers[instruction.destination]), trace, state)
			&"add":
				registers[instruction.destination] = int(registers[instruction.destination]) + int(registers[instruction.source])
				_add_compute_event(instruction, int(registers[instruction.destination]), trace, state)
			&"store":
				var result_value: int = int(registers[instruction.source])
				state["result_value"] = result_value
				var store_details: Dictionary = {"instruction_text": instruction.source_text}
				trace.add_event(SimulationEventType.new(
					&"store_result", int(state["current_cycle"]), STORE_RESULT_CYCLES,
					&"CPU", &"TestBench", -1, -1, result_value,
					"STORE OUT[0], %s → %d" % [String(instruction.source), result_value],
					instruction.source_line, [&"CPU", &"TestBench"], store_details
				))
				state["current_cycle"] = int(state["current_cycle"]) + STORE_RESULT_CYCLES
				state["compute_cycles"] = int(state["compute_cycles"]) + STORE_RESULT_CYCLES


func _perform_load(
		instruction: DSLInstructionType,
		data: Array[int],
		cache_lines: int,
		trace: SimulationTraceType,
		state: Dictionary
	) -> int:
	var loop_values: Dictionary = state["loop_values"]
	var row: int = int(loop_values[instruction.row_index_variable])
	var column: int = int(loop_values[instruction.column_index_variable])
	var address: int = row * ARRAY_WIDTH + column
	var line_index: int = address / CACHE_LINE_INTS
	var line_base: int = line_index * CACHE_LINE_INTS
	var loaded_value: int = data[address]
	var line_values: Array[int] = []
	for line_offset: int in range(CACHE_LINE_INTS):
		line_values.append(data[line_base + line_offset])
	var details: Dictionary = {
		"instruction_text": instruction.source_text,
		"array_row": row,
		"array_column": column,
		"line_base_address": line_base,
		"line_values": line_values,
	}

	trace.add_event(SimulationEventType.new(
		&"request", int(state["current_cycle"]), 0, &"CPU", &"Cache", address, line_index,
		loaded_value, "LOAD A[%d][%d] → address %d" % [row, column, address],
		instruction.source_line, [&"CPU", &"Cache"], details
	))
	trace.add_event(SimulationEventType.new(
		&"cache_lookup", int(state["current_cycle"]), CACHE_LOOKUP_CYCLES, &"Cache", &"Cache",
		address, line_index, loaded_value, "Cache lookup for line %d" % line_index,
		instruction.source_line, [&"Cache"], details
	))
	state["current_cycle"] = int(state["current_cycle"]) + CACHE_LOOKUP_CYCLES
	state["wait_cycles"] = int(state["wait_cycles"]) + CACHE_LOOKUP_CYCLES
	state["use_clock"] = int(state["use_clock"]) + 1

	var resident_lines: Array = state["resident_lines"]
	var line_last_used: Dictionary = state["line_last_used"]
	if line_index in resident_lines:
		state["cache_hits"] = int(state["cache_hits"]) + 1
		line_last_used[line_index] = int(state["use_clock"])
		trace.add_event(SimulationEventType.new(
			&"cache_hit", int(state["current_cycle"]), 0, &"Cache", &"CPU", address,
			line_index, loaded_value, "HIT — line %d returns value %d" % [line_index, loaded_value],
			instruction.source_line, [&"Cache", &"CPU"], details
		))
	else:
		state["cache_misses"] = int(state["cache_misses"]) + 1
		trace.add_event(SimulationEventType.new(
			&"cache_miss", int(state["current_cycle"]), 0, &"Cache", &"Cache", address,
			line_index, loaded_value, "MISS — line %d is not resident" % line_index,
			instruction.source_line, [&"Cache"], details
		))
		trace.add_event(SimulationEventType.new(
			&"bus_request", int(state["current_cycle"]), BUS_REQUEST_CYCLES, &"Cache", &"Bus",
			address, line_index, loaded_value, "Bus carries the line request",
			instruction.source_line, [&"Cache", &"Bus"], details
		))
		state["current_cycle"] = int(state["current_cycle"]) + BUS_REQUEST_CYCLES
		state["wait_cycles"] = int(state["wait_cycles"]) + BUS_REQUEST_CYCLES
		trace.add_event(SimulationEventType.new(
			&"ram_access", int(state["current_cycle"]), RAM_ACCESS_CYCLES, &"Bus", &"RAM",
			address, line_index, loaded_value, "RAM reads line %d: %s" % [line_index, str(line_values)],
			instruction.source_line, [&"Bus", &"RAM"], details
		))
		state["current_cycle"] = int(state["current_cycle"]) + RAM_ACCESS_CYCLES
		state["wait_cycles"] = int(state["wait_cycles"]) + RAM_ACCESS_CYCLES
		trace.add_event(SimulationEventType.new(
			&"line_return", int(state["current_cycle"]), BUS_LINE_TRANSFER_CYCLES, &"RAM", &"Cache",
			address, line_index, loaded_value, "16-byte line %d returns through Bus" % line_index,
			instruction.source_line, [&"RAM", &"Bus", &"Cache"], details
		))
		state["current_cycle"] = int(state["current_cycle"]) + BUS_LINE_TRANSFER_CYCLES
		state["wait_cycles"] = int(state["wait_cycles"]) + BUS_LINE_TRANSFER_CYCLES
		state["ram_bytes"] = int(state["ram_bytes"]) + CACHE_LINE_BYTES
		if resident_lines.size() >= cache_lines:
			var evicted_line: int = _least_recently_used_line(resident_lines, line_last_used)
			resident_lines.erase(evicted_line)
			line_last_used.erase(evicted_line)
			var eviction_details: Dictionary = details.duplicate(true)
			eviction_details["evicted_line"] = evicted_line
			trace.add_event(SimulationEventType.new(
				&"cache_evict", int(state["current_cycle"]), 0, &"Cache", &"Cache", address,
				evicted_line, 0, "Evict least-recently-used line %d" % evicted_line,
				instruction.source_line, [&"Cache"], eviction_details
			))
		resident_lines.append(line_index)
		line_last_used[line_index] = int(state["use_clock"])
		trace.add_event(SimulationEventType.new(
			&"cache_fill", int(state["current_cycle"]), 0, &"Cache", &"CPU", address,
			line_index, loaded_value, "Fill line %d, return value %d" % [line_index, loaded_value],
			instruction.source_line, [&"Cache", &"CPU"], details
		))
	state["resident_lines"] = resident_lines
	state["line_last_used"] = line_last_used
	return loaded_value


func _add_compute_event(
		instruction: DSLInstructionType,
		result: int,
		trace: SimulationTraceType,
		state: Dictionary
	) -> void:
	trace.add_event(SimulationEventType.new(
		&"compute", int(state["current_cycle"]), ADD_CYCLES, &"CPU", &"CPU", -1, -1,
		result, "%s → %d" % [instruction.source_text, result], instruction.source_line,
		[&"CPU"], {"instruction_text": instruction.source_text}
	))
	state["current_cycle"] = int(state["current_cycle"]) + ADD_CYCLES
	state["compute_cycles"] = int(state["compute_cycles"]) + ADD_CYCLES


static func _least_recently_used_line(lines: Array, last_used: Dictionary) -> int:
	var selected: int = int(lines[0])
	var selected_clock: int = int(last_used.get(selected, -1))
	for raw_line: Variant in lines:
		var line: int = int(raw_line)
		var clock: int = int(last_used.get(line, -1))
		if clock < selected_clock:
			selected = line
			selected_clock = clock
	return selected
