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
const BUS_VALUE_TRANSFER_CYCLES: int = 1
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
		"pass_index": 0,
		"work_group_index": -1,
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


func run_workload(
		program: DSLProgramType,
		data: Array[int],
		cache_lines: int,
		test_name: String,
		pass_count: int = 1,
		block_lines: int = 0,
		bypass_cache: bool = false
	) -> SimulationTraceType:
	if pass_count == 1 and block_lines == 0 and not bypass_cache:
		return run(program, data, cache_lines, test_name)

	var trace := SimulationTraceType.new()
	trace.cache_capacity_lines = 0 if bypass_cache else cache_lines
	trace.test_name = test_name
	trace.loop_order = program.loop_order.duplicate()
	trace.program_source = program.source
	if not program.is_valid() or data.size() != ARRAY_LENGTH:
		return trace
	if pass_count < 1 or block_lines not in [0, 1, 2, 4]:
		return trace
	if not bypass_cache and not CACHE_COSTS.has(cache_lines):
		return trace

	var state: Dictionary = _initial_state()
	state["bypass_cache"] = bypass_cache
	_execute_scheduled_program(program, data, cache_lines, pass_count, block_lines, trace, state)
	_finalize_trace(trace, data, state, 0 if bypass_cache else int(CACHE_COSTS[cache_lines]))
	return trace


static func official_data_copy() -> Array[int]:
	return OFFICIAL_DATA.duplicate()


func _initial_state() -> Dictionary:
	return {
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
		"pass_index": 0,
		"work_group_index": -1,
	}


func _finalize_trace(trace: SimulationTraceType, data: Array[int], state: Dictionary, hardware_cost: int) -> void:
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
		"hardware_cost": hardware_cost,
	}


func _execute_scheduled_program(
		program: DSLProgramType,
		data: Array[int],
		cache_lines: int,
		pass_count: int,
		block_lines: int,
		trace: SimulationTraceType,
		state: Dictionary
	) -> void:
	var outer_loop: DSLInstructionType = null
	var inner_loop: DSLInstructionType = null
	for instruction: DSLInstructionType in program.instructions:
		if instruction.opcode == &"for_range":
			outer_loop = instruction
			break
	if outer_loop == null:
		return
	for instruction: DSLInstructionType in outer_loop.children:
		if instruction.opcode == &"for_range":
			inner_loop = instruction
			break
	if inner_loop == null:
		return
	var load_instruction: DSLInstructionType = _first_load_instruction(inner_loop.children)
	if load_instruction == null:
		return

	var pass_registers: Array[Dictionary] = []
	for pass_index: int in range(pass_count):
		state["registers"] = {}
		state["loop_values"] = {}
		for instruction: DSLInstructionType in program.instructions:
			if instruction == outer_loop:
				break
			_execute_block([instruction], data, cache_lines, trace, state)
		pass_registers.append((state["registers"] as Dictionary).duplicate(true))

	var contexts: Array[Dictionary] = []
	for outer_value: int in range(outer_loop.range_stop):
		for inner_value: int in range(inner_loop.range_stop):
			var loop_values: Dictionary = {
				outer_loop.destination: outer_value,
				inner_loop.destination: inner_value,
			}
			var row: int = int(loop_values[load_instruction.row_index_variable])
			var column: int = int(loop_values[load_instruction.column_index_variable])
			contexts.append({
				"loop_values": loop_values,
				"cache_line": (row * ARRAY_WIDTH + column) / CACHE_LINE_INTS,
			})

	if block_lines == 0:
		for pass_index: int in range(pass_count):
			_execute_iteration_contexts(
				contexts, inner_loop.children, pass_index, -1, pass_registers,
				data, cache_lines, trace, state
			)
	else:
		var block_count: int = ceili(float(ARRAY_LENGTH / CACHE_LINE_INTS) / float(block_lines))
		for block_index: int in range(block_count):
			var block_contexts: Array[Dictionary] = []
			for context: Dictionary in contexts:
				if int(context["cache_line"]) / block_lines == block_index:
					block_contexts.append(context)
			for pass_index: int in range(pass_count):
				_execute_iteration_contexts(
					block_contexts, inner_loop.children, pass_index, block_index, pass_registers,
					data, cache_lines, trace, state
				)

	for pass_index: int in range(pass_count):
		state["registers"] = pass_registers[pass_index]
		state["loop_values"] = {}
		var loop_seen: bool = false
		for instruction: DSLInstructionType in program.instructions:
			if instruction == outer_loop:
				loop_seen = true
				continue
			if loop_seen:
				_execute_block([instruction], data, cache_lines, trace, state)


func _execute_iteration_contexts(
		contexts: Array[Dictionary],
		body: Array,
		pass_index: int,
		work_group_index: int,
		pass_registers: Array[Dictionary],
		data: Array[int],
		cache_lines: int,
		trace: SimulationTraceType,
		state: Dictionary
	) -> void:
	state["registers"] = pass_registers[pass_index]
	state["pass_index"] = pass_index
	state["work_group_index"] = work_group_index
	for context: Dictionary in contexts:
		state["loop_values"] = context["loop_values"]
		_execute_block(body, data, cache_lines, trace, state)
	pass_registers[pass_index] = state["registers"]


func _first_load_instruction(block: Array) -> DSLInstructionType:
	for instruction: DSLInstructionType in block:
		if instruction.opcode == &"load" or instruction.opcode == &"add_load":
			return instruction
		if not instruction.children.is_empty():
			var nested: DSLInstructionType = _first_load_instruction(instruction.children)
			if nested != null:
				return nested
	return null


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
				registers[instruction.destination] = _perform_data_load(instruction, data, cache_lines, trace, state)
			&"add_load":
				var loaded_value: int = _perform_data_load(instruction, data, cache_lines, trace, state)
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


func _perform_data_load(
		instruction: DSLInstructionType,
		data: Array[int],
		cache_lines: int,
		trace: SimulationTraceType,
		state: Dictionary
	) -> int:
	if bool(state.get("bypass_cache", false)):
		return _perform_direct_load(instruction, data, trace, state)
	return _perform_load(instruction, data, cache_lines, trace, state)


func _perform_direct_load(
		instruction: DSLInstructionType,
		data: Array[int],
		trace: SimulationTraceType,
		state: Dictionary
	) -> int:
	var loop_values: Dictionary = state["loop_values"]
	var row: int = int(loop_values[instruction.row_index_variable])
	var column: int = int(loop_values[instruction.column_index_variable])
	var address: int = row * ARRAY_WIDTH + column
	var loaded_value: int = data[address]
	var details: Dictionary = {
		"instruction_text": instruction.source_text,
		"array_row": row,
		"array_column": column,
		"transfer_bytes": INT_BYTES,
		"pass_index": int(state.get("pass_index", 0)),
		"work_group_index": int(state.get("work_group_index", -1)),
	}

	trace.add_event(SimulationEventType.new(
		&"request", int(state["current_cycle"]), 0, &"CPU", &"Bus", address, -1,
		loaded_value, "LOAD A[%d][%d] → address %d" % [row, column, address],
		instruction.source_line, [&"CPU", &"Bus"], details
	))
	trace.add_event(SimulationEventType.new(
		&"bus_request", int(state["current_cycle"]), BUS_REQUEST_CYCLES, &"CPU", &"Bus",
		address, -1, loaded_value, "Bus carries the value request",
		instruction.source_line, [&"CPU", &"Bus"], details
	))
	state["current_cycle"] = int(state["current_cycle"]) + BUS_REQUEST_CYCLES
	state["wait_cycles"] = int(state["wait_cycles"]) + BUS_REQUEST_CYCLES
	trace.add_event(SimulationEventType.new(
		&"ram_access", int(state["current_cycle"]), RAM_ACCESS_CYCLES, &"Bus", &"RAM",
		address, -1, loaded_value, "RAM reads address %d → %d" % [address, loaded_value],
		instruction.source_line, [&"Bus", &"RAM"], details
	))
	state["current_cycle"] = int(state["current_cycle"]) + RAM_ACCESS_CYCLES
	state["wait_cycles"] = int(state["wait_cycles"]) + RAM_ACCESS_CYCLES
	trace.add_event(SimulationEventType.new(
		&"value_return", int(state["current_cycle"]), BUS_VALUE_TRANSFER_CYCLES, &"RAM", &"CPU",
		address, -1, loaded_value, "4-byte value returns through Bus",
		instruction.source_line, [&"RAM", &"Bus", &"CPU"], details
	))
	state["current_cycle"] = int(state["current_cycle"]) + BUS_VALUE_TRANSFER_CYCLES
	state["wait_cycles"] = int(state["wait_cycles"]) + BUS_VALUE_TRANSFER_CYCLES
	state["ram_bytes"] = int(state["ram_bytes"]) + INT_BYTES
	return loaded_value


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
		"pass_index": int(state.get("pass_index", 0)),
		"work_group_index": int(state.get("work_group_index", -1)),
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
		[&"CPU"], {
			"instruction_text": instruction.source_text,
			"pass_index": int(state.get("pass_index", 0)),
			"work_group_index": int(state.get("work_group_index", -1)),
		}
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
