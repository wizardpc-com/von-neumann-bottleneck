class_name DSLProgram
extends RefCounted

const DSLInstructionType = preload("res://src/simulation/dsl_instruction.gd")

var source: String = ""
var instructions: Array[DSLInstructionType] = []
var loop_order: Array[StringName] = []
var errors: Array[String] = []
var error_specs: Array[Dictionary] = []


func is_valid() -> bool:
	return errors.is_empty()


func add_error(key: StringName, arguments: Array, fallback_template: String) -> void:
	var spec: Dictionary = _message_spec(key, arguments, fallback_template)
	error_specs.append(spec)
	errors.append(_fallback_text(spec))


func loop_order_text() -> String:
	if loop_order.size() != 2:
		return "invalid"
	return "%s → %s" % [String(loop_order[0]), String(loop_order[1])]


func traversal_pattern() -> String:
	if loop_order.size() != 2:
		return "unknown"
	var load_instruction: DSLInstructionType = _find_first_load(instructions)
	if load_instruction == null:
		return "unknown"
	if loop_order[0] == load_instruction.row_index_variable:
		return "row-first"
	if loop_order[0] == load_instruction.column_index_variable:
		return "column-first"
	return "unknown"


func memory_address_order(limit: int = 16) -> Array[int]:
	var addresses: Array[int] = []
	if loop_order.size() != 2 or limit <= 0:
		return addresses
	var load_instruction: DSLInstructionType = _find_first_load(instructions)
	if load_instruction == null:
		return addresses
	for outer_value: int in range(4):
		for inner_value: int in range(4):
			var variables: Dictionary[StringName, int] = {
				loop_order[0]: outer_value,
				loop_order[1]: inner_value,
			}
			var row: int = variables.get(load_instruction.row_index_variable, -1)
			var column: int = variables.get(load_instruction.column_index_variable, -1)
			if row < 0 or column < 0:
				return []
			addresses.append(row * 4 + column)
			if addresses.size() >= limit:
				return addresses
	return addresses


func line_explanations() -> Dictionary[int, String]:
	var explanations: Dictionary[int, String] = {}
	var specs: Dictionary[int, Dictionary] = line_explanation_specs()
	for line_number: int in specs:
		explanations[line_number] = _fallback_text(specs[line_number])
	return explanations


func line_explanation_specs() -> Dictionary[int, Dictionary]:
	var explanations: Dictionary[int, Dictionary] = {}
	var source_lines: PackedStringArray = source.split("\n")
	for index: int in range(source_lines.size()):
		var trimmed: String = source_lines[index].strip_edges()
		if trimmed.begins_with("#"):
			explanations[index + 1] = _message_spec(
				&"dsl.explanation.comment", [], "Comment for the reader; it does not execute."
			)
	_collect_line_explanation_specs(instructions, 0, explanations)
	return explanations


func _collect_line_explanation_specs(
		block: Array,
		depth: int,
		explanations: Dictionary[int, Dictionary]
	) -> void:
	for instruction: DSLInstructionType in block:
		match instruction.opcode:
			&"assign_const":
				explanations[instruction.source_line] = _message_spec(
					&"dsl.explanation.assign_const", [instruction.destination, instruction.immediate],
					"Create `%s` with initial integer value %d."
				)
			&"for_range":
				var level_fallback: String = "outer" if depth == 0 else "inner"
				explanations[instruction.source_line] = _message_spec(
					&"dsl.explanation.for_range.outer" if depth == 0 else &"dsl.explanation.for_range.inner",
					[instruction.destination],
					"Run the %s loop variable `%s` through 0, 1, 2, 3."
				)
				explanations[instruction.source_line]["fallback_args"] = [level_fallback, instruction.destination]
				_collect_line_explanation_specs(instruction.children, depth + 1, explanations)
			&"load":
				explanations[instruction.source_line] = _message_spec(
					&"dsl.explanation.load", [instruction.row_index_variable, instruction.column_index_variable, instruction.destination],
					"Load A[%s][%s] through CPU and Cache, then place the value in `%s`."
				)
			&"add_load":
				explanations[instruction.source_line] = _message_spec(
					&"dsl.explanation.add_load", [instruction.row_index_variable, instruction.column_index_variable, instruction.destination],
					"Load A[%s][%s] through CPU and Cache, then add it to `%s`."
				)
			&"add":
				explanations[instruction.source_line] = _message_spec(
					&"dsl.explanation.add", [instruction.source, instruction.destination],
					"Add `%s` to `%s` inside CPU."
				)
			&"store":
				explanations[instruction.source_line] = _message_spec(
					&"dsl.explanation.store", [instruction.source],
					"Send `%s` to OUT[0] so Test Bench can check the result."
				)


func _message_spec(key: StringName, arguments: Array, fallback_template: String) -> Dictionary:
	return {"key": key, "args": arguments.duplicate(), "fallback": fallback_template}


func _fallback_text(spec: Dictionary) -> String:
	var fallback: String = spec.get("fallback", "")
	var arguments: Array = spec.get("fallback_args", spec.get("args", []))
	if arguments.is_empty():
		return fallback
	return fallback % arguments


func _find_first_load(block: Array) -> DSLInstructionType:
	for instruction: DSLInstructionType in block:
		if instruction.opcode == &"load" or instruction.opcode == &"add_load":
			return instruction
		if not instruction.children.is_empty():
			var nested: DSLInstructionType = _find_first_load(instruction.children)
			if nested != null:
				return nested
	return null
