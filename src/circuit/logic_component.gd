class_name LogicComponent
extends RefCounted

const KIND_INPUT: StringName = &"input"
const KIND_OUTPUT: StringName = &"output"
const KIND_LAMP: StringName = &"lamp"
const KIND_AND: StringName = &"and"
const KIND_OR: StringName = &"or"
const KIND_NOT: StringName = &"not"
const KIND_NOR: StringName = &"nor"
const KIND_JUNCTION: StringName = &"junction"

const KIND_HALF_ADDER: StringName = &"half_adder"
const KIND_FULL_ADDER: StringName = &"full_adder"
const KIND_MUX4: StringName = &"mux4"
const KIND_ALU1: StringName = &"alu1"
const KIND_SR_LATCH: StringName = &"sr_latch"
const KIND_REGISTER1: StringName = &"register1"
const KIND_REGISTER4: StringName = &"register4"
const KIND_DECODER1_TO_2: StringName = &"decoder1_to_2"
const KIND_MUX2_WORD: StringName = &"mux2_word"
const KIND_ALU4: StringName = &"alu4"
const KIND_RAM2X4: StringName = &"ram2x4"
const KIND_CONTROL: StringName = &"control"
const KIND_CONSTANT: StringName = &"constant"
const KIND_TINY_COMPUTER: StringName = &"tiny_computer"

var id: StringName
var kind: StringName
var display_name: String
var signal_name: StringName
var fixed_terminal: bool
var input_port_names: Array[StringName] = []
var output_port_names: Array[StringName] = []
var input_port_widths: Array[int] = []
var output_port_widths: Array[int] = []
var properties: Dictionary = {}


func _init(
		p_id: StringName = &"",
		p_kind: StringName = &"",
		p_display_name: String = "",
		p_signal_name: StringName = &"",
		p_fixed_terminal: bool = false,
		p_input_port_names: Array[StringName] = [],
		p_output_port_names: Array[StringName] = [],
		p_input_port_widths: Array[int] = [],
		p_output_port_widths: Array[int] = [],
		p_properties: Dictionary = {}
	) -> void:
	id = p_id
	kind = p_kind
	display_name = p_display_name
	signal_name = p_signal_name
	fixed_terminal = p_fixed_terminal
	input_port_names = p_input_port_names.duplicate()
	output_port_names = p_output_port_names.duplicate()
	input_port_widths = p_input_port_widths.duplicate()
	output_port_widths = p_output_port_widths.duplicate()
	properties = p_properties.duplicate(true)
	_apply_default_port_spec()


func input_count() -> int:
	return input_port_names.size()


func output_count() -> int:
	return output_port_names.size()


func input_port_name(port: int) -> StringName:
	return input_port_names[port] if port >= 0 and port < input_port_names.size() else &""


func output_port_name(port: int) -> StringName:
	return output_port_names[port] if port >= 0 and port < output_port_names.size() else &""


func input_width(port: int) -> int:
	return input_port_widths[port] if port >= 0 and port < input_port_widths.size() else 1


func output_width(port: int) -> int:
	return output_port_widths[port] if port >= 0 and port < output_port_widths.size() else 1


func is_basic_gate() -> bool:
	return kind in [KIND_AND, KIND_OR, KIND_NOT, KIND_NOR]


func is_observer() -> bool:
	return kind in [KIND_OUTPUT, KIND_LAMP]


func is_routing_node() -> bool:
	return kind == KIND_JUNCTION


func is_stateful() -> bool:
	return kind in [KIND_SR_LATCH, KIND_REGISTER1, KIND_REGISTER4, KIND_RAM2X4, KIND_TINY_COMPUTER]


func is_reusable_abstraction() -> bool:
	return kind in [
		KIND_HALF_ADDER, KIND_FULL_ADDER, KIND_ALU1, KIND_SR_LATCH,
		KIND_REGISTER1, KIND_REGISTER4, KIND_RAM2X4, KIND_ALU4, KIND_TINY_COMPUTER,
	]


func is_supported() -> bool:
	return kind in [
		KIND_INPUT, KIND_OUTPUT, KIND_LAMP, KIND_AND, KIND_OR, KIND_NOT, KIND_NOR,
		KIND_JUNCTION, KIND_HALF_ADDER, KIND_FULL_ADDER, KIND_MUX4, KIND_ALU1,
		KIND_SR_LATCH, KIND_REGISTER1, KIND_REGISTER4, KIND_DECODER1_TO_2,
		KIND_MUX2_WORD, KIND_ALU4, KIND_RAM2X4, KIND_CONTROL, KIND_CONSTANT,
		KIND_TINY_COMPUTER,
	]


func duplicate_component() -> LogicComponent:
	return LogicComponent.new(
		id, kind, display_name, signal_name, fixed_terminal,
		input_port_names, output_port_names, input_port_widths, output_port_widths,
		properties
	)


func to_dictionary() -> Dictionary:
	return {
		"id": String(id),
		"kind": String(kind),
		"display_name": display_name,
		"signal_name": String(signal_name),
		"fixed_terminal": fixed_terminal,
		"input_port_names": input_port_names.map(func(port_name: StringName) -> String: return String(port_name)),
		"output_port_names": output_port_names.map(func(port_name: StringName) -> String: return String(port_name)),
		"input_port_widths": input_port_widths,
		"output_port_widths": output_port_widths,
		"properties": _canonical_properties(),
	}


func _apply_default_port_spec() -> void:
	if input_port_names.is_empty() and output_port_names.is_empty():
		match kind:
			KIND_INPUT:
				_set_ports([], [&"OUT"], [], [_property_width(&"width", 1)])
			KIND_OUTPUT, KIND_LAMP:
				_set_ports([&"IN"], [], [_property_width(&"width", 1)], [])
			KIND_AND, KIND_OR, KIND_NOR:
				_set_ports([&"A", &"B"], [&"Y"], [1, 1], [1])
			KIND_NOT:
				_set_ports([&"A"], [&"Y"], [1], [1])
			KIND_JUNCTION:
				var junction_width: int = _property_width(&"width", 1)
				_set_ports([&"IN"], [&"OUT"], [junction_width], [junction_width])
			KIND_HALF_ADDER:
				_set_ports([&"A", &"B"], [&"SUM", &"CARRY"], [1, 1], [1, 1])
			KIND_FULL_ADDER:
				_set_ports([&"A", &"B", &"CIN"], [&"SUM", &"COUT"], [1, 1, 1], [1, 1])
			KIND_MUX4:
				var mux_width: int = _property_width(&"width", 1)
				_set_ports(
					[&"D0", &"D1", &"D2", &"D3", &"S0", &"S1"], [&"Y"],
					[mux_width, mux_width, mux_width, mux_width, 1, 1], [mux_width]
				)
			KIND_ALU1:
				_set_ports(
					[&"A", &"B", &"CIN", &"OP0", &"OP1"], [&"RESULT", &"CARRY"],
					[1, 1, 1, 1, 1], [1, 1]
				)
			KIND_SR_LATCH:
				_set_ports([&"S", &"R"], [&"Q", &"NQ"], [1, 1], [1, 1])
			KIND_REGISTER1:
				_set_ports([&"D", &"LOAD"], [&"Q"], [1, 1], [1])
			KIND_REGISTER4:
				_set_ports([&"DATA", &"LOAD"], [&"Q"], [4, 1], [4])
			KIND_DECODER1_TO_2:
				_set_ports([&"ADDR", &"ENABLE"], [&"SEL0", &"SEL1"], [1, 1], [1, 1])
			KIND_MUX2_WORD:
				var word_width: int = _property_width(&"width", 4)
				_set_ports([&"A", &"B", &"SEL"], [&"Y"], [word_width, word_width, 1], [word_width])
			KIND_ALU4:
				_set_ports(
					[&"A", &"B", &"CIN", &"OP0", &"OP1"], [&"RESULT", &"CARRY"],
					[4, 4, 1, 1, 1], [4, 1]
				)
			KIND_RAM2X4:
				_set_ports([&"ADDR", &"DATA_IN", &"WRITE"], [&"DATA_OUT"], [1, 4, 1], [4])
			KIND_CONTROL:
				_set_ports(
					[&"OP"], [&"SOURCE_SEL", &"RESULT_SEL", &"ACC_LOAD", &"MEM_WRITE"],
					[2], [1, 1, 1, 1]
				)
			KIND_CONSTANT:
				_set_ports([], [&"OUT"], [], [_property_width(&"width", 1)])
			KIND_TINY_COMPUTER:
				_set_ports([&"OP", &"ARG", &"ADDR"], [&"ACC", &"MEM"], [2, 4, 1], [4, 4])
	if input_port_widths.size() != input_port_names.size():
		input_port_widths = _filled_widths(input_port_names.size(), 1)
	if output_port_widths.size() != output_port_names.size():
		output_port_widths = _filled_widths(output_port_names.size(), 1)
	for index: int in range(input_port_widths.size()):
		input_port_widths[index] = clampi(input_port_widths[index], 1, 32)
	for index: int in range(output_port_widths.size()):
		output_port_widths[index] = clampi(output_port_widths[index], 1, 32)


func _set_ports(
		p_input_names: Array[StringName],
		p_output_names: Array[StringName],
		p_input_widths: Array[int],
		p_output_widths: Array[int]
	) -> void:
	input_port_names = p_input_names.duplicate()
	output_port_names = p_output_names.duplicate()
	input_port_widths = p_input_widths.duplicate()
	output_port_widths = p_output_widths.duplicate()


func _property_width(key: StringName, fallback: int) -> int:
	return clampi(int(properties.get(key, fallback)), 1, 32)


func _filled_widths(count: int, width: int) -> Array[int]:
	var result: Array[int] = []
	for _index: int in range(count):
		result.append(width)
	return result


func _canonical_properties() -> Dictionary:
	var keys: Array[String] = []
	for key: Variant in properties:
		keys.append(String(key))
	keys.sort()
	var result: Dictionary = {}
	for key: String in keys:
		result[key] = properties[key]
	return result
