extends "res://src/content/prologue/prologue_level_factory_base.gd"

const BranchType = preload("res://src/content/campaign_branch_definition.gd")
const LevelType = preload("res://src/content/campaign_level_definition.gd")


func register_into(registry, _builders: Dictionary = {}) -> void:
	registry.register_branch(BranchType.new(
		&"arithmetic", &"hardware.prologue.branch.cpu", 1
	))
	registry.register_level(LevelType.new(
		&"half_adder", &"arithmetic", 0,
		&"hardware.phase.half_adder", &"", [&"tutorial"],
		LevelType.ENTRY_HALF_ADDER, Callable(), [&"HalfAdder"]
	))
	registry.register_level(LevelType.new(
		&"full_adder", &"arithmetic", 1,
		&"hardware.prologue.full_adder.title",
		&"hardware.prologue.full_adder.description",
		[&"half_adder"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_full_adder"), [&"FullAdder"]
	))
	var generated_alu_rewards: Array[Dictionary] = [{
		"name": &"ALU4",
		"behavior_kind": LogicComponentType.KIND_ALU4,
		"properties": {"auto_expanded_bits": 4},
	}]
	registry.register_level(LevelType.new(
		&"alu", &"arithmetic", 2,
		&"hardware.prologue.alu.title", &"hardware.prologue.alu.description",
		[&"full_adder"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_alu"), [&"ALU1", &"ALU4"], generated_alu_rewards
	))


func _full_adder(library: Dictionary) -> Dictionary:
	var half_adder_1: LogicComponent = _library_instance(library, &"HalfAdder", &"HA_1", "HalfAdder · 1")
	var half_adder_2: LogicComponent = _library_instance(library, &"HalfAdder", &"HA_2", "HalfAdder · 2")
	if half_adder_1 == null or half_adder_2 == null:
		return _missing(&"full_adder", &"HalfAdder")
	var components: Array[LogicComponent] = [
		_input(&"A_IN", &"A"), _input(&"B_IN", &"B"), _input(&"CIN_IN", &"CIN"),
		half_adder_1, half_adder_2,
		LogicComponentType.new(&"OR_1", LogicComponentType.KIND_OR, "or"),
		_output(&"SUM_OUT", &"SUM"), _output(&"COUT_OUT", &"COUT"),
	]
	var wires: Array[Dictionary] = [
		_w(&"A_IN", &"HA_1", 0, 0), _w(&"B_IN", &"HA_1", 0, 1),
		_w(&"HA_1", &"HA_2", 0, 0), _w(&"CIN_IN", &"HA_2", 0, 1),
		_w(&"HA_1", &"OR_1", 1, 0), _w(&"HA_2", &"OR_1", 1, 1),
		_w(&"HA_2", &"SUM_OUT", 0, 0), _w(&"OR_1", &"COUT_OUT", 0, 0),
	]
	var steps: Array[Dictionary] = []
	for a: int in range(2):
		for b: int in range(2):
			for carry_in: int in range(2):
				var total: int = a + b + carry_in
				steps.append(_case(
					{&"A": a, &"B": b, &"CIN": carry_in},
					{&"SUM": total & 1, &"COUT": 1 if total >= 2 else 0}
				))
	return _base(
		&"full_adder", &"hardware.prologue.full_adder.title", &"hardware.prologue.full_adder.description",
		components,
		{
			&"A_IN": Vector2(400, 65), &"B_IN": Vector2(400, 250), &"CIN_IN": Vector2(400, 460),
			&"HA_1": Vector2(670, 135), &"HA_2": Vector2(930, 260), &"OR_1": Vector2(930, 60),
			&"SUM_OUT": Vector2(1250, 250), &"COUT_OUT": Vector2(1250, 65),
		}, wires, steps, &"FullAdder", LogicComponentType.KIND_FULL_ADDER,
		{"initial_zoom": 0.88, "palette_components": [
			half_adder_1.duplicate_component(),
			LogicComponentType.new(&"PALETTE_AND", LogicComponentType.KIND_AND, "AND"),
			LogicComponentType.new(&"PALETTE_OR", LogicComponentType.KIND_OR, "OR"),
			LogicComponentType.new(&"PALETTE_NOT", LogicComponentType.KIND_NOT, "NOT"),
			LogicComponentType.new(&"PALETTE_XOR", LogicComponentType.KIND_XOR, "XOR"),
		], "hint_partial_wires": [
			wires[0].duplicate(), wires[1].duplicate(), wires[2].duplicate(),
			wires[3].duplicate(), wires[6].duplicate(),
		]}
	)


func _alu(library: Dictionary) -> Dictionary:
	var full_adder: LogicComponent = _library_instance(library, &"FullAdder", &"FULL_ADDER", "Your FullAdder")
	if full_adder == null:
		return _missing(&"alu", &"FullAdder")
	var components: Array[LogicComponent] = [
		_input(&"A_IN", &"A"), _input(&"B_IN", &"B"), _input(&"CIN_IN", &"CIN"),
		_input(&"OP0_IN", &"OP0"), _input(&"OP1_IN", &"OP1"),
		LogicComponentType.new(&"AND_1", LogicComponentType.KIND_AND, "and"),
		LogicComponentType.new(&"OR_1", LogicComponentType.KIND_OR, "or"),
		LogicComponentType.new(&"NOT_1", LogicComponentType.KIND_NOT, "not"),
		full_adder,
		LogicComponentType.new(&"MUX", LogicComponentType.KIND_MUX4, "4→1 mux"),
		_output(&"RESULT_OUT", &"RESULT"), _output(&"CARRY_OUT", &"CARRY"),
	]
	var wires: Array[Dictionary] = [
		_w(&"A_IN", &"AND_1", 0, 0), _w(&"B_IN", &"AND_1", 0, 1),
		_w(&"A_IN", &"OR_1", 0, 0), _w(&"B_IN", &"OR_1", 0, 1),
		_w(&"A_IN", &"NOT_1", 0, 0),
		_w(&"A_IN", &"FULL_ADDER", 0, 0), _w(&"B_IN", &"FULL_ADDER", 0, 1),
		_w(&"CIN_IN", &"FULL_ADDER", 0, 2),
		_w(&"AND_1", &"MUX", 0, 0), _w(&"OR_1", &"MUX", 0, 1),
		_w(&"FULL_ADDER", &"MUX", 0, 2), _w(&"NOT_1", &"MUX", 0, 3),
		_w(&"OP0_IN", &"MUX", 0, 4), _w(&"OP1_IN", &"MUX", 0, 5),
		_w(&"MUX", &"RESULT_OUT", 0, 0), _w(&"FULL_ADDER", &"CARRY_OUT", 1, 0),
	]
	var steps: Array[Dictionary] = []
	for operation: int in range(4):
		for a: int in range(2):
			for b: int in range(2):
				for carry_in: int in range(2):
					var expected_result: int = 0
					match operation:
						0: expected_result = a & b
						1: expected_result = a | b
						2: expected_result = (a + b + carry_in) & 1
						3: expected_result = 1 - a
					var expected: Dictionary = {&"RESULT": expected_result}
					if operation == 2:
						expected[&"CARRY"] = 1 if a + b + carry_in >= 2 else 0
					steps.append(_case(
						{
							&"A": a, &"B": b, &"CIN": carry_in,
							&"OP0": operation & 1, &"OP1": (operation >> 1) & 1,
						}, expected
					))
	return _base(
		&"alu", &"hardware.prologue.alu.title", &"hardware.prologue.alu.description", components,
		{
			&"A_IN": Vector2(385, 35), &"B_IN": Vector2(385, 160), &"CIN_IN": Vector2(385, 285),
			&"OP0_IN": Vector2(385, 430), &"OP1_IN": Vector2(385, 530),
			&"AND_1": Vector2(625, 20), &"OR_1": Vector2(625, 150),
			&"FULL_ADDER": Vector2(620, 280), &"NOT_1": Vector2(650, 485),
			&"MUX": Vector2(970, 215), &"RESULT_OUT": Vector2(1280, 250), &"CARRY_OUT": Vector2(1280, 85),
		}, wires, steps, &"ALU1", LogicComponentType.KIND_ALU1,
		{
			"initial_zoom": 0.9,
			"palette_components": [
				full_adder.duplicate_component(),
				LogicComponentType.new(&"PALETTE_AND", LogicComponentType.KIND_AND, "AND"),
				LogicComponentType.new(&"PALETTE_OR", LogicComponentType.KIND_OR, "OR"),
				LogicComponentType.new(&"PALETTE_NOT", LogicComponentType.KIND_NOT, "NOT"),
				LogicComponentType.new(&"PALETTE_XOR", LogicComponentType.KIND_XOR, "XOR"),
				LogicComponentType.new(&"PALETTE_MUX", LogicComponentType.KIND_MUX4, "4→1 mux"),
			],
			"hint_partial_wires": [
				wires[0].duplicate(), wires[1].duplicate(), wires[2].duplicate(),
				wires[3].duplicate(), wires[4].duplicate(), wires[8].duplicate(),
				wires[9].duplicate(), wires[11].duplicate(), wires[12].duplicate(),
				wires[13].duplicate(), wires[14].duplicate(),
			],
		}
	)
