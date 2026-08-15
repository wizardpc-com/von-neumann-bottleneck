class_name DSLInstruction
extends RefCounted

var opcode: StringName
var destination: StringName
var source: StringName
var row_index_variable: StringName
var column_index_variable: StringName
var source_line: int


func _init(
		p_opcode: StringName = &"",
		p_destination: StringName = &"",
		p_source: StringName = &"",
		p_row_index_variable: StringName = &"",
		p_column_index_variable: StringName = &"",
		p_source_line: int = 0
	) -> void:
	opcode = p_opcode
	destination = p_destination
	source = p_source
	row_index_variable = p_row_index_variable
	column_index_variable = p_column_index_variable
	source_line = p_source_line

