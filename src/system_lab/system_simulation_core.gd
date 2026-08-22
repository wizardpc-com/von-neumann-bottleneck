class_name SystemSimulationCore
extends RefCounted

const EventType = preload("res://src/system_lab/system_event.gd")
const InstructionType = preload("res://src/system_lab/system_instruction.gd")
const ProgramType = preload("res://src/system_lab/system_program.gd")
const TopologyType = preload("res://src/system_lab/system_topology.gd")
const TraceType = preload("res://src/system_lab/system_trace.gd")

const WORD_MASK: int = 0xff
const BUS_CONTROL_CYCLES: int = 1
const MAX_INPUT_ITEMS: int = 64


func run(
		program: SystemProgram,
		topology: SystemTopology,
		input_data: Array[int],
		expected_output: Array[int],
		test_name: String
	) -> SystemTrace:
	var trace := TraceType.new()
	trace.program_source = program.source if program != null else ""
	trace.program_signature = program.canonical_signature() if program != null else ""
	trace.topology_signature = topology.canonical_signature() if topology != null else ""
	trace.test_name = test_name
	trace.expected_output = expected_output.duplicate()
	if program == null or topology == null or not program.is_valid() or not topology.is_valid():
		return trace
	if input_data.is_empty() or input_data.size() > MAX_INPUT_ITEMS or expected_output.is_empty():
		return trace

	var cpu = topology.part(TopologyType.CPU_ID)
	var bus = topology.part(TopologyType.BUS_ID)
	var ram = topology.part(TopologyType.RAM_ID)
	var state: Dictionary = {
		"cycle": 0,
		"registers": {},
		"loop_values": {},
		"output": _zero_output(expected_output.size()),
		"cpu_compute_cycles": 0,
		"ram_service_cycles": 0,
		"bus_control_cycles": 0,
		"bus_transfer_cycles": 0,
		"memory_requests": 0,
		"bytes_transferred": 0,
		"execution_valid": true,
	}
	_execute_block(program.instructions, input_data, cpu, ram, bus, trace, state)
	trace.output_data = (state["output"] as Array[int]).duplicate()
	trace.passed = bool(state["execution_valid"]) and trace.output_data == trace.expected_output
	var wait_cycles: int = (
		int(state["ram_service_cycles"])
		+ int(state["bus_control_cycles"])
		+ int(state["bus_transfer_cycles"])
	)
	trace.metrics = {
		"total_cycles": int(state["cycle"]),
		"cpu_compute_cycles": int(state["cpu_compute_cycles"]),
		"cpu_wait_cycles": wait_cycles,
		"ram_service_cycles": int(state["ram_service_cycles"]),
		"bus_control_cycles": int(state["bus_control_cycles"]),
		"bus_transfer_cycles": int(state["bus_transfer_cycles"]),
		"memory_requests": int(state["memory_requests"]),
		"bytes_transferred": int(state["bytes_transferred"]),
		"hardware_cost": cpu.hardware_cost + ram.hardware_cost + bus.hardware_cost,
		"bus_segments_per_word": ceili(8.0 / float(bus.bandwidth_bits_per_cycle)),
	}
	return trace


func _execute_block(
		block: Array[SystemInstruction],
		input_data: Array[int],
		cpu,
		ram,
		bus,
		trace: SystemTrace,
		state: Dictionary
	) -> void:
	var registers: Dictionary = state["registers"]
	var loop_values: Dictionary = state["loop_values"]
	for instruction: SystemInstruction in block:
		if not bool(state["execution_valid"]):
			return
		match instruction.opcode:
			&"assign_const":
				registers[instruction.destination] = instruction.immediate & WORD_MASK
			&"for_range":
				var stop: int = input_data.size() if instruction.range_uses_input_size else instruction.range_stop
				if stop < 0 or stop > MAX_INPUT_ITEMS:
					state["execution_valid"] = false
					return
				for value: int in range(stop):
					loop_values[instruction.destination] = value
					_execute_block(instruction.children, input_data, cpu, ram, bus, trace, state)
			&"load":
				var load_index: int = _resolve_index(instruction, loop_values)
				if load_index < 0 or load_index >= input_data.size():
					state["execution_valid"] = false
					return
				registers[instruction.destination] = _perform_load(
					load_index, input_data[load_index] & WORD_MASK,
					instruction.source_line, ram, bus, trace, state
				)
			&"add":
				if not registers.has(instruction.destination) or not registers.has(instruction.source):
					state["execution_valid"] = false
					return
				registers[instruction.destination] = (
					int(registers[instruction.destination]) + int(registers[instruction.source])
				) & WORD_MASK
				_add_compute_event(instruction, int(registers[instruction.destination]), cpu, trace, state)
			&"add_const":
				if not registers.has(instruction.destination):
					state["execution_valid"] = false
					return
				registers[instruction.destination] = (
					int(registers[instruction.destination]) + instruction.immediate
				) & WORD_MASK
				_add_compute_event(instruction, int(registers[instruction.destination]), cpu, trace, state)
			&"store":
				if not registers.has(instruction.source):
					state["execution_valid"] = false
					return
				var store_index: int = _resolve_index(instruction, loop_values)
				var output: Array[int] = state["output"]
				if store_index < 0 or store_index >= output.size():
					state["execution_valid"] = false
					return
				var stored_value: int = int(registers[instruction.source]) & WORD_MASK
				_perform_store(store_index, stored_value, instruction.source_line, ram, bus, trace, state)
				output[store_index] = stored_value
				state["output"] = output
	state["registers"] = registers
	state["loop_values"] = loop_values


func _perform_load(
		index: int,
		value: int,
		source_line: int,
		ram,
		bus,
		trace: SystemTrace,
		state: Dictionary
	) -> int:
	state["memory_requests"] = int(state["memory_requests"]) + 1
	_append_event(&"read_request", BUS_CONTROL_CYCLES, [&"CPU", &"BUS", &"RAM"], source_line, {
		"index": index, "value": value, "phase": "bus_control", "cpu_waiting": true,
	}, trace, state)
	state["bus_control_cycles"] = int(state["bus_control_cycles"]) + BUS_CONTROL_CYCLES
	_append_event(&"ram_read", ram.access_cycles, [&"RAM"], source_line, {
		"index": index, "value": value, "phase": "ram", "cpu_waiting": true,
	}, trace, state)
	state["ram_service_cycles"] = int(state["ram_service_cycles"]) + ram.access_cycles
	var transfer_cycles: int = ceili(8.0 / float(bus.bandwidth_bits_per_cycle))
	_append_event(&"read_data", transfer_cycles, [&"RAM", &"BUS", &"CPU"], source_line, {
		"index": index, "value": value, "phase": "bus_data", "cpu_waiting": true,
		"segments": transfer_cycles, "bits_per_cycle": bus.bandwidth_bits_per_cycle,
	}, trace, state)
	state["bus_transfer_cycles"] = int(state["bus_transfer_cycles"]) + transfer_cycles
	state["bytes_transferred"] = int(state["bytes_transferred"]) + 1
	return value


func _perform_store(
		index: int,
		value: int,
		source_line: int,
		ram,
		bus,
		trace: SystemTrace,
		state: Dictionary
	) -> void:
	state["memory_requests"] = int(state["memory_requests"]) + 1
	_append_event(&"write_request", BUS_CONTROL_CYCLES, [&"CPU", &"BUS", &"RAM"], source_line, {
		"index": index, "value": value, "phase": "bus_control", "cpu_waiting": true,
	}, trace, state)
	state["bus_control_cycles"] = int(state["bus_control_cycles"]) + BUS_CONTROL_CYCLES
	var transfer_cycles: int = ceili(8.0 / float(bus.bandwidth_bits_per_cycle))
	_append_event(&"write_data", transfer_cycles, [&"CPU", &"BUS", &"RAM"], source_line, {
		"index": index, "value": value, "phase": "bus_data", "cpu_waiting": true,
		"segments": transfer_cycles, "bits_per_cycle": bus.bandwidth_bits_per_cycle,
	}, trace, state)
	state["bus_transfer_cycles"] = int(state["bus_transfer_cycles"]) + transfer_cycles
	state["bytes_transferred"] = int(state["bytes_transferred"]) + 1
	_append_event(&"ram_write", ram.access_cycles, [&"RAM"], source_line, {
		"index": index, "value": value, "phase": "ram", "cpu_waiting": true,
	}, trace, state)
	state["ram_service_cycles"] = int(state["ram_service_cycles"]) + ram.access_cycles


func _add_compute_event(instruction: SystemInstruction, value: int, cpu, trace: SystemTrace, state: Dictionary) -> void:
	_append_event(&"compute", cpu.compute_cycles, [&"CPU"], instruction.source_line, {
		"value": value, "phase": "cpu", "cpu_waiting": false,
	}, trace, state)
	state["cpu_compute_cycles"] = int(state["cpu_compute_cycles"]) + cpu.compute_cycles


func _append_event(
		kind: StringName,
		duration: int,
		route: Array[StringName],
		source_line: int,
		details: Dictionary,
		trace: SystemTrace,
		state: Dictionary
	) -> void:
	trace.add_event(EventType.new(kind, int(state["cycle"]), duration, route, source_line, details))
	state["cycle"] = int(state["cycle"]) + duration


func _resolve_index(instruction: SystemInstruction, loop_values: Dictionary) -> int:
	if instruction.index_constant >= 0:
		return instruction.index_constant
	return int(loop_values.get(instruction.index_variable, -1))


func _zero_output(size: int) -> Array[int]:
	var output: Array[int] = []
	output.resize(size)
	output.fill(0)
	return output
