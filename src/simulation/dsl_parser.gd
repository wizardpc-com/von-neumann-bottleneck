class_name DSLParser
extends RefCounted

const DSLInstructionType = preload("res://src/simulation/dsl_instruction.gd")
const DSLProgramType = preload("res://src/simulation/dsl_program.gd")

const ARRAY_PATTERN: String = "^A\\[([A-Za-z_][A-Za-z0-9_]*)\\]\\[([A-Za-z_][A-Za-z0-9_]*)\\]$"


static func parse(source: String) -> DSLProgramType:
	var program := DSLProgramType.new()
	program.source = source
	var loop_depth: int = 0
	var loop_count: int = 0
	var saw_store: bool = false
	var array_regex := RegEx.new()
	var regex_error: Error = array_regex.compile(ARRAY_PATTERN)
	if regex_error != OK:
		program.errors.append("Internal DSL pattern failed to compile.")
		return program

	var lines: PackedStringArray = source.split("\n")
	for index: int in range(lines.size()):
		var raw_line: String = lines[index]
		var comment_index: int = raw_line.find("#")
		if comment_index >= 0:
			raw_line = raw_line.left(comment_index)
		var line: String = raw_line.strip_edges()
		var line_number: int = index + 1
		if line.is_empty():
			continue

		if line.begins_with("register "):
			if loop_depth != 0:
				program.errors.append("Line %d: registers must be declared before the loops." % line_number)
				continue
			_parse_register(line, line_number, program)
			continue

		if line.begins_with("for "):
			var parts: PackedStringArray = line.split(" ", false)
			if parts.size() != 4 or parts[2] != "in" or parts[3] != "0..4":
				program.errors.append("Line %d: expected `for name in 0..4`." % line_number)
				continue
			if loop_depth >= 2:
				program.errors.append("Line %d: this slice supports exactly two nested loops." % line_number)
				continue
			var variable := StringName(parts[1])
			if variable in program.loop_order:
				program.errors.append("Line %d: loop variables must be different." % line_number)
				continue
			program.loop_order.append(variable)
			loop_depth += 1
			loop_count += 1
			continue

		if line == "end":
			if loop_depth <= 0:
				program.errors.append("Line %d: unexpected `end`." % line_number)
			else:
				loop_depth -= 1
			continue

		if line.begins_with("load "):
			if loop_depth != 2:
				program.errors.append("Line %d: `load` must be inside both loops." % line_number)
				continue
			_parse_load(line, line_number, program, array_regex)
			continue

		if line.begins_with("add "):
			if loop_depth != 2:
				program.errors.append("Line %d: `add` must be inside both loops." % line_number)
				continue
			_parse_binary_instruction(line, line_number, &"add", program.loop_instructions, program)
			continue

		if line.begins_with("store "):
			if loop_depth != 0 or loop_count != 2:
				program.errors.append("Line %d: final `store` must follow both loops." % line_number)
				continue
			_parse_binary_instruction(line, line_number, &"store", program.final_instructions, program)
			saw_store = true
			continue

		program.errors.append("Line %d: unsupported statement `%s`." % [line_number, line])

	if loop_depth != 0:
		program.errors.append("Missing `end` for one or more loops.")
	if loop_count != 2 or program.loop_order.size() != 2:
		program.errors.append("The program must contain exactly two nested loops.")
	if program.registers.is_empty():
		program.errors.append("Declare at least one register.")
	if program.loop_instructions.is_empty():
		program.errors.append("The loop body must contain `load` and `add` operations.")
	if not saw_store or program.final_instructions.size() != 1:
		program.errors.append("The program must end with exactly one `store result, register`.")
	_validate_program(program)
	return program


static func _parse_register(line: String, line_number: int, program: DSLProgramType) -> void:
	var declaration: String = line.trim_prefix("register ")
	var parts: PackedStringArray = declaration.split("=", false, 1)
	if parts.size() != 2:
		program.errors.append("Line %d: expected `register name = integer`." % line_number)
		return
	var name: String = parts[0].strip_edges()
	var value_text: String = parts[1].strip_edges()
	if not name.is_valid_identifier() or not value_text.is_valid_int():
		program.errors.append("Line %d: invalid register declaration." % line_number)
		return
	var register_name := StringName(name)
	if program.registers.has(register_name):
		program.errors.append("Line %d: duplicate register `%s`." % [line_number, name])
		return
	program.registers[register_name] = value_text.to_int()


static func _parse_load(line: String, line_number: int, program: DSLProgramType, array_regex: RegEx) -> void:
	var operands: PackedStringArray = line.trim_prefix("load ").split(",", false)
	if operands.size() != 2:
		program.errors.append("Line %d: expected `load register, A[row][col]`." % line_number)
		return
	var destination := StringName(operands[0].strip_edges())
	var address_expression: String = operands[1].strip_edges()
	var match: RegExMatch = array_regex.search(address_expression)
	if match == null:
		program.errors.append("Line %d: expected a two-dimensional `A[row][col]` index." % line_number)
		return
	program.loop_instructions.append(DSLInstructionType.new(
		&"load",
		destination,
		&"A",
		StringName(match.get_string(1)),
		StringName(match.get_string(2)),
		line_number
	))


static func _parse_binary_instruction(
		line: String,
		line_number: int,
		opcode: StringName,
		target: Array[DSLInstructionType],
		program: DSLProgramType
	) -> void:
	var operands: PackedStringArray = line.trim_prefix(String(opcode) + " ").split(",", false)
	if operands.size() != 2:
		program.errors.append("Line %d: expected `%s destination, source`." % [line_number, String(opcode)])
		return
	target.append(DSLInstructionType.new(
		opcode,
		StringName(operands[0].strip_edges()),
		StringName(operands[1].strip_edges()),
		&"",
		&"",
		line_number
	))


static func _validate_program(program: DSLProgramType) -> void:
	var loop_variables: Dictionary[StringName, bool] = {}
	for variable: StringName in program.loop_order:
		loop_variables[variable] = true
	var saw_load: bool = false
	var saw_add: bool = false
	for instruction: DSLInstructionType in program.loop_instructions:
		if not program.registers.has(instruction.destination):
			program.errors.append("Line %d: unknown destination register `%s`." % [instruction.source_line, String(instruction.destination)])
		if instruction.opcode == &"load":
			saw_load = true
			if not loop_variables.has(instruction.row_index_variable) or not loop_variables.has(instruction.column_index_variable):
				program.errors.append("Line %d: array indices must use the two loop variables." % instruction.source_line)
			if instruction.row_index_variable == instruction.column_index_variable:
				program.errors.append("Line %d: row and column indices must be different." % instruction.source_line)
		elif instruction.opcode == &"add":
			saw_add = true
			if not program.registers.has(instruction.source):
				program.errors.append("Line %d: unknown source register `%s`." % [instruction.source_line, String(instruction.source)])
	if not saw_load or not saw_add:
		program.errors.append("The loop body needs at least one `load` and one `add`.")
	if program.final_instructions.size() == 1:
		var store: DSLInstructionType = program.final_instructions[0]
		if store.destination != &"result":
			program.errors.append("Line %d: this slice only supports `store result, register`." % store.source_line)
		if not program.registers.has(store.source):
			program.errors.append("Line %d: unknown stored register `%s`." % [store.source_line, String(store.source)])
