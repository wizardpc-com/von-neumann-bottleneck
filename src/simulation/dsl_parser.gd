class_name DSLParser
extends RefCounted

const DSLInstructionType = preload("res://src/simulation/dsl_instruction.gd")
const DSLProgramType = preload("res://src/simulation/dsl_program.gd")

const IDENTIFIER: String = "[A-Za-z_][A-Za-z0-9_]*"
const FOR_PATTERN: String = "^for\\s+(%s)\\s+in\\s+range\\(4\\):$" % IDENTIFIER
const CONST_PATTERN: String = "^(%s)\\s*=\\s*(-?[0-9]+)$" % IDENTIFIER
const LOAD_PATTERN: String = "^(%s)\\s*=\\s*load\\(A\\[(%s)\\]\\[(%s)\\]\\)$" % [IDENTIFIER, IDENTIFIER, IDENTIFIER]
const ADD_LOAD_PATTERN: String = "^(%s)\\s*\\+=\\s*load\\(A\\[(%s)\\]\\[(%s)\\]\\)$" % [IDENTIFIER, IDENTIFIER, IDENTIFIER]
const ADD_PATTERN: String = "^(%s)\\s*\\+=\\s*(%s)$" % [IDENTIFIER, IDENTIFIER]
const STORE_PATTERN: String = "^store\\(OUT\\[0\\],\\s*(%s)\\)$" % IDENTIFIER


static func parse(source: String) -> DSLProgramType:
	var program := DSLProgramType.new()
	program.source = source
	var regexes: Dictionary[StringName, RegEx] = {}
	for entry: Array in [
		[&"for", FOR_PATTERN],
		[&"const", CONST_PATTERN],
		[&"load", LOAD_PATTERN],
		[&"add_load", ADD_LOAD_PATTERN],
		[&"add", ADD_PATTERN],
		[&"store", STORE_PATTERN],
	]:
		var regex := RegEx.new()
		if regex.compile(String(entry[1])) != OK:
			program.add_error(&"dsl.error.internal_pattern", [], "Internal DSL pattern failed to compile.")
			return program
		regexes[entry[0]] = regex

	var loop_stack: Array[DSLInstructionType] = []
	var lines: PackedStringArray = source.split("\n")
	for index: int in range(lines.size()):
		var raw_line: String = lines[index]
		var line_number: int = index + 1
		if "\t" in raw_line:
			program.add_error(&"dsl.error.tabs", [line_number], "Line %d: use four spaces for indentation; tabs are not supported.")
			continue
		var comment_index: int = raw_line.find("#")
		if comment_index >= 0:
			raw_line = raw_line.left(comment_index)
		if raw_line.strip_edges().is_empty():
			continue
		var trimmed_left: String = raw_line.lstrip(" ")
		var indent_spaces: int = raw_line.length() - trimmed_left.length()
		if indent_spaces % 4 != 0:
			program.add_error(&"dsl.error.indent_multiple", [line_number], "Line %d: indentation must use multiples of four spaces.")
			continue
		var depth: int = indent_spaces / 4
		while loop_stack.size() > depth:
			loop_stack.pop_back()
		if depth > loop_stack.size():
			program.add_error(&"dsl.error.unexpected_indent", [line_number], "Line %d: unexpected indentation.")
			continue

		var line: String = trimmed_left.strip_edges()
		var regex_match: RegExMatch = regexes[&"for"].search(line)
		if regex_match != null:
			if depth >= 2:
				program.add_error(&"dsl.error.too_many_loops", [line_number], "Line %d: this prototype supports exactly two nested loops.")
				continue
			var loop_variable := StringName(regex_match.get_string(1))
			var instruction := DSLInstructionType.new(
				&"for_range", loop_variable, &"", &"", &"", 0, 4, line_number, line
			)
			_append_instruction(program, loop_stack, instruction)
			program.loop_order.append(loop_variable)
			loop_stack.append(instruction)
			continue

		regex_match = regexes[&"const"].search(line)
		if regex_match != null:
			_append_instruction(program, loop_stack, DSLInstructionType.new(
				&"assign_const", StringName(regex_match.get_string(1)), &"", &"", &"",
				regex_match.get_string(2).to_int(), 0, line_number, line
			))
			continue

		regex_match = regexes[&"load"].search(line)
		if regex_match != null:
			_append_instruction(program, loop_stack, DSLInstructionType.new(
				&"load", StringName(regex_match.get_string(1)), &"A", StringName(regex_match.get_string(2)),
				StringName(regex_match.get_string(3)), 0, 0, line_number, line
			))
			continue

		regex_match = regexes[&"add_load"].search(line)
		if regex_match != null:
			_append_instruction(program, loop_stack, DSLInstructionType.new(
				&"add_load", StringName(regex_match.get_string(1)), &"A", StringName(regex_match.get_string(2)),
				StringName(regex_match.get_string(3)), 0, 0, line_number, line
			))
			continue

		regex_match = regexes[&"add"].search(line)
		if regex_match != null:
			_append_instruction(program, loop_stack, DSLInstructionType.new(
				&"add", StringName(regex_match.get_string(1)), StringName(regex_match.get_string(2)),
				&"", &"", 0, 0, line_number, line
			))
			continue

		regex_match = regexes[&"store"].search(line)
		if regex_match != null:
			_append_instruction(program, loop_stack, DSLInstructionType.new(
				&"store", &"OUT", StringName(regex_match.get_string(1)), &"", &"", 0, 0, line_number, line
			))
			continue

		program.add_error(&"dsl.error.unsupported_statement", [line_number, line], "Line %d: unsupported statement `%s`.")

	_validate_program(program)
	return program


static func _append_instruction(
		program: DSLProgramType,
		loop_stack: Array[DSLInstructionType],
		instruction: DSLInstructionType
	) -> void:
	if loop_stack.is_empty():
		program.instructions.append(instruction)
	else:
		loop_stack.back().children.append(instruction)


static func _validate_program(program: DSLProgramType) -> void:
	if program.instructions.is_empty():
		program.add_error(&"dsl.error.empty", [], "Program is empty.")
		return
	if program.loop_order.size() != 2 or program.loop_order[0] == program.loop_order[1]:
		program.add_error(&"dsl.error.two_distinct_loops", [], "The program must contain exactly two nested loops with different variables.")
	var loop_roots: int = 0
	for instruction: DSLInstructionType in program.instructions:
		if instruction.opcode == &"for_range":
			loop_roots += 1
	if loop_roots != 1:
		program.add_error(&"dsl.error.one_nested_traversal", [], "The two loops must form one nested traversal.")
	if program.instructions.back().opcode != &"store":
		program.add_error(&"dsl.error.final_store", [], "The final statement must be `store(OUT[0], name)`.")

	var validation: Dictionary = {
		"defined": {},
		"loop_variables": [],
		"load_count": 0,
		"add_count": 0,
		"store_count": 0,
	}
	_validate_block(program.instructions, 0, validation, program)
	if int(validation["load_count"]) == 0:
		program.add_error(&"dsl.error.load_required", [], "The loop body must load at least one value from A.")
	if int(validation["add_count"]) == 0:
		program.add_error(&"dsl.error.add_required", [], "The loop body must perform at least one `+=` operation.")
	if int(validation["store_count"]) != 1:
		program.add_error(&"dsl.error.one_store", [], "The program must contain exactly one final store.")


static func _validate_block(
		block: Array,
		depth: int,
		validation: Dictionary,
		program: DSLProgramType
	) -> void:
	var defined: Dictionary = validation["defined"]
	var loop_variables: Array = validation["loop_variables"]
	for instruction: DSLInstructionType in block:
		match instruction.opcode:
			&"assign_const":
				if depth != 0:
					program.add_error(&"dsl.error.scalar_outside_loops", [instruction.source_line], "Line %d: scalar initialization must be outside the loops.")
				elif instruction.destination in loop_variables:
					program.add_error(&"dsl.error.assign_loop_variable", [instruction.source_line], "Line %d: cannot assign to a loop variable.")
				else:
					defined[instruction.destination] = true
			&"for_range":
				if instruction.destination in loop_variables:
					program.add_error(&"dsl.error.loop_variables_different", [instruction.source_line], "Line %d: loop variables must be different.")
				loop_variables.append(instruction.destination)
				_validate_block(instruction.children, depth + 1, validation, program)
				loop_variables.pop_back()
			&"load", &"add_load":
				validation["load_count"] = int(validation["load_count"]) + 1
				if instruction.opcode == &"add_load":
					validation["add_count"] = int(validation["add_count"]) + 1
				if depth != 2:
					program.add_error(&"dsl.error.memory_inside_loops", [instruction.source_line], "Line %d: memory access must be inside both loops.")
				if not instruction.row_index_variable in loop_variables or not instruction.column_index_variable in loop_variables:
					program.add_error(&"dsl.error.indices_active_loops", [instruction.source_line], "Line %d: A indices must use the two active loop variables.")
				if instruction.row_index_variable == instruction.column_index_variable:
					program.add_error(&"dsl.error.indices_different", [instruction.source_line], "Line %d: row and column indices must be different.")
				if instruction.opcode == &"add_load" and not defined.has(instruction.destination):
					program.add_error(&"dsl.error.initialize_before_add", [instruction.source_line, String(instruction.destination)], "Line %d: `%s` must be initialized before `+=`.")
				defined[instruction.destination] = true
			&"add":
				validation["add_count"] = int(validation["add_count"]) + 1
				if depth != 2:
					program.add_error(&"dsl.error.add_inside_loops", [instruction.source_line], "Line %d: `+=` must be inside both loops.")
				if not defined.has(instruction.destination) or not defined.has(instruction.source):
					program.add_error(&"dsl.error.add_variables_initialized", [instruction.source_line], "Line %d: both variables in `+=` must already be initialized.")
			&"store":
				validation["store_count"] = int(validation["store_count"]) + 1
				if depth != 0:
					program.add_error(&"dsl.error.store_outside_loops", [instruction.source_line], "Line %d: store must be outside both loops.")
				if not defined.has(instruction.source):
					program.add_error(&"dsl.error.stored_variable_initialized", [instruction.source_line, String(instruction.source)], "Line %d: stored variable `%s` is not initialized.")
