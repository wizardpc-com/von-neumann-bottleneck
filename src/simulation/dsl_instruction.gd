class_name DSLInstruction
extends RefCounted

var opcode: StringName
var destination: StringName
var source: StringName
var row_index_variable: StringName
var column_index_variable: StringName
var immediate: int
var range_stop: int
var source_line: int
var source_text: String
var children: Array = []


func _init(
		p_opcode: StringName = &"",
		p_destination: StringName = &"",
		p_source: StringName = &"",
		p_row_index_variable: StringName = &"",
		p_column_index_variable: StringName = &"",
		p_immediate: int = 0,
		p_range_stop: int = 0,
		p_source_line: int = 0,
		p_source_text: String = ""
	) -> void:
	opcode = p_opcode
	destination = p_destination
	source = p_source
	row_index_variable = p_row_index_variable
	column_index_variable = p_column_index_variable
	immediate = p_immediate
	range_stop = p_range_stop
	source_line = p_source_line
	source_text = p_source_text

