class_name SystemProgram
extends RefCounted

const InstructionType = preload("res://src/system_lab/system_instruction.gd")

var source: String = ""
var instructions: Array[SystemInstruction] = []
var errors: Array[String] = []
var error_specs: Array[Dictionary] = []


func is_valid() -> bool:
	return errors.is_empty() and not instructions.is_empty()


func add_error(key: StringName, arguments: Array, fallback: String) -> void:
	error_specs.append({"key": key, "args": arguments.duplicate(), "fallback": fallback})
	errors.append(fallback % arguments if not arguments.is_empty() else fallback)


func line_explanation_specs() -> Dictionary[int, Dictionary]:
	var result: Dictionary[int, Dictionary] = {}
	_collect_explanations(instructions, result)
	return result


func canonical_signature() -> String:
	return source.sha256_text()


func _collect_explanations(block: Array[SystemInstruction], result: Dictionary[int, Dictionary]) -> void:
	for instruction: SystemInstruction in block:
		var key := StringName("system.dsl.explanation.%s" % String(instruction.opcode))
		result[instruction.source_line] = {
			"key": key,
			"args": [instruction.source_text],
			"fallback": instruction.source_text,
		}
		if not instruction.children.is_empty():
			_collect_explanations(instruction.children, result)
