class_name DSLProgram
extends RefCounted

const DSLInstructionType = preload("res://src/simulation/dsl_instruction.gd")

var source: String = ""
var registers: Dictionary[StringName, int] = {}
var loop_order: Array[StringName] = []
var loop_instructions: Array[DSLInstructionType] = []
var final_instructions: Array[DSLInstructionType] = []
var errors: Array[String] = []


func is_valid() -> bool:
	return errors.is_empty()


func loop_order_text() -> String:
	if loop_order.size() != 2:
		return "invalid"
	return "%s → %s" % [String(loop_order[0]), String(loop_order[1])]


func traversal_pattern() -> String:
	if loop_order.size() != 2:
		return "unknown"
	for instruction: DSLInstructionType in loop_instructions:
		if instruction.opcode != &"load":
			continue
		if loop_order[0] == instruction.row_index_variable:
			return "row-first"
		if loop_order[0] == instruction.column_index_variable:
			return "column-first"
	return "unknown"
