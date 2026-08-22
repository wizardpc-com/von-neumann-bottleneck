class_name SystemInstruction
extends RefCounted

var opcode: StringName = &""
var destination: StringName = &""
var source: StringName = &""
var immediate: int = 0
var index_variable: StringName = &""
var index_constant: int = -1
var range_stop: int = 0
var range_uses_input_size: bool = false
var source_line: int = 0
var source_text: String = ""
var children: Array[SystemInstruction] = []


func _init(p_opcode: StringName = &"", p_source_line: int = 0, p_source_text: String = "") -> void:
	opcode = p_opcode
	source_line = p_source_line
	source_text = p_source_text
