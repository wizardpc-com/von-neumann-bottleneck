class_name SystemDSLParser
extends RefCounted

const InstructionType = preload("res://src/system_lab/system_instruction.gd")
const ProgramType = preload("res://src/system_lab/system_program.gd")


static func parse(source: String) -> SystemProgram:
	var program := ProgramType.new()
	program.source = source
	var current_loop: SystemInstruction = null
	var saw_statement := false
	var lines: PackedStringArray = source.split("\n")
	for index: int in range(lines.size()):
		var raw_line: String = lines[index].trim_suffix("\r")
		var line_number: int = index + 1
		if raw_line.strip_edges().is_empty() or raw_line.strip_edges().begins_with("#"):
			continue
		if "\t" in raw_line:
			program.add_error(&"system.dsl.error.tabs", [line_number], "Line %d uses a tab; use four spaces.")
			continue
		var indent: int = 0
		while indent < raw_line.length() and raw_line[indent] == " ":
			indent += 1
		if indent not in [0, 4]:
			program.add_error(&"system.dsl.error.indent", [line_number], "Line %d must use zero or four spaces.")
			continue
		var trimmed: String = raw_line.strip_edges()
		if indent == 0:
			current_loop = null
			var loop_instruction: SystemInstruction = _parse_loop(trimmed, line_number)
			if loop_instruction != null:
				program.instructions.append(loop_instruction)
				current_loop = loop_instruction
				saw_statement = true
				continue
		elif current_loop == null:
			program.add_error(&"system.dsl.error.body", [line_number], "Line %d has an indented statement outside a loop.")
			continue
		var instruction: SystemInstruction = _parse_statement(trimmed, line_number)
		if instruction == null:
			program.add_error(&"system.dsl.error.syntax", [line_number, trimmed], "Line %d is not supported: %s")
			continue
		if indent == 4:
			current_loop.children.append(instruction)
		else:
			program.instructions.append(instruction)
		saw_statement = true
	for instruction: SystemInstruction in program.instructions:
		if instruction.opcode == &"for_range" and instruction.children.is_empty():
			program.add_error(&"system.dsl.error.empty_loop", [instruction.source_line], "Loop on line %d has no body.")
	if not saw_statement:
		program.add_error(&"system.dsl.error.empty", [], "Program contains no executable statements.")
	return program


static func _parse_loop(text: String, line_number: int) -> SystemInstruction:
	var regex := RegEx.new()
	regex.compile("^for\\s+([A-Za-z_][A-Za-z0-9_]*)\\s+in\\s+range\\((N|[0-9]+)\\):$")
	var matched: RegExMatch = regex.search(text)
	if matched == null:
		return null
	var instruction := InstructionType.new(&"for_range", line_number, text)
	instruction.destination = StringName(matched.get_string(1))
	var range_text: String = matched.get_string(2)
	instruction.range_uses_input_size = range_text == "N"
	instruction.range_stop = -1 if instruction.range_uses_input_size else int(range_text)
	return instruction


static func _parse_statement(text: String, line_number: int) -> SystemInstruction:
	var regex := RegEx.new()
	regex.compile("^([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*(-?[0-9]+)$")
	var matched: RegExMatch = regex.search(text)
	if matched != null:
		var assign := InstructionType.new(&"assign_const", line_number, text)
		assign.destination = StringName(matched.get_string(1))
		assign.immediate = int(matched.get_string(2))
		return assign
	regex.compile("^([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*load\\(INPUT\\[([A-Za-z_][A-Za-z0-9_]*|[0-9]+)\\]\\)$")
	matched = regex.search(text)
	if matched != null:
		var load_instruction := InstructionType.new(&"load", line_number, text)
		load_instruction.destination = StringName(matched.get_string(1))
		_set_index(load_instruction, matched.get_string(2))
		return load_instruction
	regex.compile("^([A-Za-z_][A-Za-z0-9_]*)\\s*\\+=\\s*([A-Za-z_][A-Za-z0-9_]*|-?[0-9]+)$")
	matched = regex.search(text)
	if matched != null:
		var add_instruction := InstructionType.new(&"add", line_number, text)
		add_instruction.destination = StringName(matched.get_string(1))
		var operand: String = matched.get_string(2)
		if operand.is_valid_int():
			add_instruction.opcode = &"add_const"
			add_instruction.immediate = int(operand)
		else:
			add_instruction.source = StringName(operand)
		return add_instruction
	regex.compile("^store\\((OUTPUT|OUT)\\[([A-Za-z_][A-Za-z0-9_]*|[0-9]+)\\],\\s*([A-Za-z_][A-Za-z0-9_]*)\\)$")
	matched = regex.search(text)
	if matched != null:
		var store_instruction := InstructionType.new(&"store", line_number, text)
		_set_index(store_instruction, matched.get_string(2))
		store_instruction.source = StringName(matched.get_string(3))
		return store_instruction
	return null


static func _set_index(instruction: SystemInstruction, token: String) -> void:
	if token.is_valid_int():
		instruction.index_constant = int(token)
	else:
		instruction.index_variable = StringName(token)
