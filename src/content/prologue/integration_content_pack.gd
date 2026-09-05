extends "res://src/content/prologue/prologue_level_factory_base.gd"

const BranchType = preload("res://src/content/campaign_branch_definition.gd")
const LevelType = preload("res://src/content/campaign_level_definition.gd")


func register_into(registry, _builders: Dictionary = {}) -> void:
	registry.register_branch(BranchType.new(
		&"integration", &"hardware.prologue.branch.integration", 3
	))
	registry.register_level(LevelType.new(
		&"cpu", &"integration", 0,
		&"hardware.prologue.cpu.title", &"hardware.prologue.cpu.description",
		[&"alu", &"ram"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_cpu"), [&"TinyComputer"]
	))
	registry.register_level(LevelType.new(
		&"load_store", &"integration", 1,
		&"hardware.prologue.load_store.title", &"hardware.prologue.load_store.description",
		[&"cpu"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_load_store")
	))


func _cpu(library: Dictionary) -> Dictionary:
	var alu: LogicComponent = _library_instance(library, &"ALU4", &"ALU", "ALU (4-bit)")
	var acc: LogicComponent = _library_instance(library, &"Register4", &"ACC", "ACC Register (4-bit)")
	var ram: LogicComponent = _library_instance(library, &"RAM2x4", &"RAM", "RAM (2×4-bit)")
	if alu == null:
		return _missing(&"cpu", &"ALU4")
	if acc == null:
		return _missing(&"cpu", &"Register4")
	if ram == null:
		return _missing(&"cpu", &"RAM2x4")
	var components: Array[LogicComponent] = [
		_input(&"OP_IN", &"OP", 2), _input(&"ARG_IN", &"ARG", 4), _input(&"ADDR_IN", &"ADDR"),
		LogicComponentType.new(&"CONTROL", LogicComponentType.KIND_CONTROL, "Controller"),
		LogicComponentType.new(&"SOURCE_MUX", LogicComponentType.KIND_MUX2_WORD, "SOURCE MUX"),
		alu,
		_constant(&"ADD_OP0", 0), _constant(&"ADD_OP1", 1), _constant(&"CIN_0", 0),
		LogicComponentType.new(&"RESULT_MUX", LogicComponentType.KIND_MUX2_WORD, "RESULT MUX"),
		acc, ram, _output(&"ACC_OUT", &"ACC", 4), _output(&"MEM_OUT", &"MEM", 4),
	]
	var wires: Array[Dictionary] = [
		_w(&"OP_IN", &"CONTROL", 0, 0),
		_w(&"ARG_IN", &"SOURCE_MUX", 0, 0), _w(&"RAM", &"SOURCE_MUX", 0, 1),
		_w(&"CONTROL", &"SOURCE_MUX", 0, 2),
		_w(&"ACC", &"ALU", 0, 0), _w(&"SOURCE_MUX", &"ALU", 0, 1),
		_w(&"CIN_0", &"ALU", 0, 2), _w(&"ADD_OP0", &"ALU", 0, 3), _w(&"ADD_OP1", &"ALU", 0, 4),
		_w(&"SOURCE_MUX", &"RESULT_MUX", 0, 0), _w(&"ALU", &"RESULT_MUX", 0, 1),
		_w(&"CONTROL", &"RESULT_MUX", 1, 2),
		_w(&"RESULT_MUX", &"ACC", 0, 0), _w(&"CONTROL", &"ACC", 2, 1),
		_w(&"ADDR_IN", &"RAM", 0, 0), _w(&"ACC", &"RAM", 0, 1), _w(&"CONTROL", &"RAM", 3, 2),
		_w(&"ACC", &"ACC_OUT", 0, 0), _w(&"RAM", &"MEM_OUT", 0, 0),
	]
	return _base(
		&"cpu", &"hardware.prologue.cpu.title", &"hardware.prologue.cpu.description", components,
		{
			&"OP_IN": Vector2(750, 40), &"ARG_IN": Vector2(750, 245), &"ADDR_IN": Vector2(750, 500),
			&"CONTROL": Vector2(930, 25), &"SOURCE_MUX": Vector2(1110, 255),
			&"RAM": Vector2(1030, 500), &"ACC": Vector2(1330, 55),
			&"ADD_OP0": Vector2(1240, 565), &"ADD_OP1": Vector2(1350, 565), &"CIN_0": Vector2(1460, 565),
			&"ALU": Vector2(1440, 225), &"RESULT_MUX": Vector2(1690, 255),
			&"ACC_OUT": Vector2(1900, 95), &"MEM_OUT": Vector2(1900, 505),
		}, wires, _computer_program(), &"TinyComputer", LogicComponentType.KIND_TINY_COMPUTER,
		{
			"initial_zoom": 0.62,
			"palette_components": [
				LogicComponentType.new(&"PALETTE_CONTROL", LogicComponentType.KIND_CONTROL, "control"),
				LogicComponentType.new(&"PALETTE_MUX", LogicComponentType.KIND_MUX2_WORD, "word mux"),
				alu.duplicate_component(), acc.duplicate_component(), ram.duplicate_component(),
				_constant(&"PALETTE_ZERO", 0), _constant(&"PALETTE_ONE", 1),
			],
			"hint_partial_wires": [
				wires[0].duplicate(), wires[1].duplicate(), wires[3].duplicate(),
				wires[9].duplicate(), wires[11].duplicate(), wires[12].duplicate(),
				wires[13].duplicate(), wires[17].duplicate(),
			],
		}
	)


func _load_store(library: Dictionary) -> Dictionary:
	var tiny: LogicComponent = _library_instance(library, &"TinyComputer", &"COMPUTER", "Tiny Computer")
	if tiny == null:
		return _missing(&"load_store", &"TinyComputer")
	var level: Dictionary = _base(
		&"load_store", &"hardware.prologue.load_store.title", &"hardware.prologue.load_store.description",
		[
			_input(&"OP_IN", &"OP", 2), _input(&"ARG_IN", &"ARG", 4), _input(&"ADDR_IN", &"ADDR"),
			tiny, _output(&"ACC_OUT", &"ACC", 4), _output(&"MEM_OUT", &"MEM", 4),
		],
		{
			&"OP_IN": Vector2(410, 90), &"ARG_IN": Vector2(410, 265), &"ADDR_IN": Vector2(410, 450),
			&"COMPUTER": Vector2(760, 205), &"ACC_OUT": Vector2(1190, 190), &"MEM_OUT": Vector2(1190, 390),
		},
		[
			_w(&"OP_IN", &"COMPUTER", 0, 0), _w(&"ARG_IN", &"COMPUTER", 0, 1),
			_w(&"ADDR_IN", &"COMPUTER", 0, 2), _w(&"COMPUTER", &"ACC_OUT", 0, 0),
			_w(&"COMPUTER", &"MEM_OUT", 1, 0),
		], _computer_program()
	)
	level["locked_topology"] = true
	level["hint_partial_wires"] = [
		(level["reference_wires"] as Array)[2].duplicate(),
		(level["reference_wires"] as Array)[4].duplicate(),
	]
	level["completion_scene"] = "res://src/system_lab/system_lab.tscn"
	level["completion_action_key"] = &"hardware.prologue.open_system"
	return level


func _computer_program() -> Array[Dictionary]:
	return [
		_case({&"OP": 0, &"ARG": 3, &"ADDR": 0}, {&"ACC": 3, &"MEM": 0}, &"hardware.program.load_imm_3"),
		_case({&"OP": 3, &"ARG": 0, &"ADDR": 0}, {&"ACC": 3, &"MEM": 3}, &"hardware.program.store_0"),
		_case({&"OP": 0, &"ARG": 5, &"ADDR": 1}, {&"ACC": 5, &"MEM": 0}, &"hardware.program.load_imm_5"),
		_case({&"OP": 1, &"ARG": 2, &"ADDR": 1}, {&"ACC": 7, &"MEM": 0}, &"hardware.program.add_2"),
		_case({&"OP": 3, &"ARG": 0, &"ADDR": 1}, {&"ACC": 7, &"MEM": 7}, &"hardware.program.store_1"),
		_case({&"OP": 2, &"ARG": 0, &"ADDR": 0}, {&"ACC": 3, &"MEM": 3}, &"hardware.program.load_0"),
		_case({&"OP": 1, &"ARG": 4, &"ADDR": 0}, {&"ACC": 7, &"MEM": 3}, &"hardware.program.add_4"),
	]
