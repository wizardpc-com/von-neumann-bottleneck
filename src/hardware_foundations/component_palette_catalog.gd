class_name ComponentPaletteCatalog
extends RefCounted

const C = preload("res://src/circuit/logic_component.gd")
const GROUPS: Array[StringName] = [&"compute", &"route", &"store", &"observe"]


static func category(component: LogicComponent) -> StringName:
	if component.kind in [C.KIND_MUX4, C.KIND_MUX2_WORD, C.KIND_DECODER1_TO_2, C.KIND_CONTROL]:
		return &"route"
	if component.kind in [C.KIND_SR_LATCH, C.KIND_REGISTER1, C.KIND_REGISTER4, C.KIND_RAM2X4]:
		return &"store"
	if component.kind in [C.KIND_INPUT, C.KIND_OUTPUT, C.KIND_CONSTANT]:
		return &"observe"
	return &"compute"


static func search_words(component: LogicComponent) -> String:
	var aliases := ""
	match category(component):
		&"compute": aliases = "逻辑 计算 logic compute arithmetic"
		&"route": aliases = "选择 连接 控制 选择器 mux decoder 译码器"
		&"store": aliases = "保存 数据 存储 寄存器 锁存器 memory register latch ram"
		&"observe": aliases = "观察 调试 constant 常量"
	return "%s %s %s" % [component.kind, component.display_name, aliases]
