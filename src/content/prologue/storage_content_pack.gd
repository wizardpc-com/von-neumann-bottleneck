extends "res://src/content/prologue/prologue_level_factory_base.gd"

const BranchType = preload("res://src/content/campaign_branch_definition.gd")
const LevelType = preload("res://src/content/campaign_level_definition.gd")


func register_into(registry, _builders: Dictionary = {}) -> void:
	registry.register_branch(BranchType.new(
		&"storage", &"hardware.prologue.branch.storage", 2
	))
	registry.register_level(LevelType.new(
		&"latch", &"storage", 0,
		&"hardware.prologue.latch.title", &"hardware.prologue.latch.description",
		[&"tutorial"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_latch"), [&"SRLatch"]
	))
	var generated_register_rewards: Array[Dictionary] = [{
		"name": &"Register4",
		"behavior_kind": LogicComponentType.KIND_REGISTER4,
		"properties": {"auto_expanded_bits": 4},
	}]
	registry.register_level(LevelType.new(
		&"register", &"storage", 1,
		&"hardware.prologue.register.title", &"hardware.prologue.register.description",
		[&"latch"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_register"), [&"Register1", &"Register4"],
		generated_register_rewards
	))
	registry.register_level(LevelType.new(
		&"ram", &"storage", 2,
		&"hardware.prologue.ram.title", &"hardware.prologue.ram.description",
		[&"register"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_ram"), [&"RAM2x4"]
	))


func _latch(_library: Dictionary = {}) -> Dictionary:
	var components: Array[LogicComponent] = [
		_input(&"S_IN", &"S"), _input(&"R_IN", &"R"),
		LogicComponentType.new(&"NOR_Q", LogicComponentType.KIND_NOR, "nor · Q"),
		LogicComponentType.new(&"NOR_NQ", LogicComponentType.KIND_NOR, "nor · NQ"),
		_output(&"Q_OUT", &"Q"), _output(&"NQ_OUT", &"NQ"),
	]
	var wires: Array[Dictionary] = [
		_w(&"R_IN", &"NOR_Q", 0, 0), _w(&"NOR_NQ", &"NOR_Q", 0, 1),
		_w(&"S_IN", &"NOR_NQ", 0, 0), _w(&"NOR_Q", &"NOR_NQ", 0, 1),
		_w(&"NOR_Q", &"Q_OUT", 0, 0), _w(&"NOR_NQ", &"NQ_OUT", 0, 0),
	]
	var steps: Array[Dictionary] = [
		_case({&"S": 0, &"R": 1}, {&"Q": 0, &"NQ": 1}),
		_case({&"S": 0, &"R": 0}, {&"Q": 0, &"NQ": 1}),
		_case({&"S": 1, &"R": 0}, {&"Q": 1, &"NQ": 0}),
		_case({&"S": 0, &"R": 0}, {&"Q": 1, &"NQ": 0}),
		_case({&"S": 0, &"R": 1}, {&"Q": 0, &"NQ": 1}),
	]
	return _base(
		&"latch", &"hardware.prologue.latch.title", &"hardware.prologue.latch.description", components,
		{
			&"S_IN": Vector2(415, 115), &"R_IN": Vector2(415, 435),
			&"NOR_Q": Vector2(725, 135), &"NOR_NQ": Vector2(725, 385),
			&"Q_OUT": Vector2(1170, 135), &"NQ_OUT": Vector2(1170, 385),
		}, wires, steps, &"SRLatch", LogicComponentType.KIND_SR_LATCH,
		{
			"allow_feedback": true,
			"feature_tags": [&"storage"],
			"state_feedback_components": [&"NOR_Q", &"NOR_NQ"],
			"palette_components": [
				LogicComponentType.new(&"PALETTE_NOR", LogicComponentType.KIND_NOR, "NOR"),
			],
			"hint_partial_wires": [
				wires[0].duplicate(), wires[1].duplicate(),
			],
			"hint_context_components": [&"Q_OUT"],
		}
	)


func _register(library: Dictionary) -> Dictionary:
	var latch: LogicComponent = _library_instance(library, &"SRLatch", &"LATCH", "Your SRLatch")
	if latch == null:
		return _missing(&"register", &"SRLatch")
	var components: Array[LogicComponent] = [
		_input(&"D_IN", &"D"), _input(&"LOAD_IN", &"LOAD"),
		LogicComponentType.new(&"NOT_D", LogicComponentType.KIND_NOT, "not"),
		LogicComponentType.new(&"AND_S", LogicComponentType.KIND_AND, "and · set"),
		LogicComponentType.new(&"AND_R", LogicComponentType.KIND_AND, "and · reset"),
		latch, _output(&"Q_OUT", &"Q"),
	]
	var wires: Array[Dictionary] = [
		_w(&"D_IN", &"NOT_D", 0, 0), _w(&"D_IN", &"AND_S", 0, 0),
		_w(&"LOAD_IN", &"AND_S", 0, 1), _w(&"NOT_D", &"AND_R", 0, 0),
		_w(&"LOAD_IN", &"AND_R", 0, 1), _w(&"AND_S", &"LATCH", 0, 0),
		_w(&"AND_R", &"LATCH", 0, 1), _w(&"LATCH", &"Q_OUT", 0, 0),
	]
	var steps: Array[Dictionary] = [
		_case({&"D": 0, &"LOAD": 1}, {&"Q": 0}),
		_case({&"D": 1, &"LOAD": 1}, {&"Q": 1}),
		_case({&"D": 0, &"LOAD": 0}, {&"Q": 1}),
		_case({&"D": 0, &"LOAD": 1}, {&"Q": 0}),
		_case({&"D": 1, &"LOAD": 0}, {&"Q": 0}),
	]
	return _base(
		&"register", &"hardware.prologue.register.title", &"hardware.prologue.register.description", components,
		{
			&"D_IN": Vector2(400, 100), &"LOAD_IN": Vector2(400, 455),
			&"NOT_D": Vector2(625, 95), &"AND_S": Vector2(805, 245),
			&"AND_R": Vector2(805, 430), &"LATCH": Vector2(1040, 280), &"Q_OUT": Vector2(1300, 300),
		}, wires, steps, &"Register1", LogicComponentType.KIND_REGISTER1,
		{
			"feature_tags": [&"storage"],
			"state_feedback_components": [&"LATCH"],
			"initial_zoom": 0.9,
			"palette_components": [
				latch.duplicate_component(),
				LogicComponentType.new(&"PALETTE_AND", LogicComponentType.KIND_AND, "AND"),
				LogicComponentType.new(&"PALETTE_NOT", LogicComponentType.KIND_NOT, "NOT"),
			],
			"hint_partial_wires": [
				wires[1].duplicate(), wires[2].duplicate(), wires[5].duplicate(),
			],
		}
	)


func _ram(library: Dictionary) -> Dictionary:
	var reg_0: LogicComponent = _library_instance(library, &"Register4", &"REG_0", "Register4 · 0")
	var reg_1: LogicComponent = _library_instance(library, &"Register4", &"REG_1", "Register4 · 1")
	if reg_0 == null or reg_1 == null:
		return _missing(&"ram", &"Register4")
	var components: Array[LogicComponent] = [
		_input(&"ADDR_IN", &"ADDR"), _input(&"DATA_IN", &"DATA", 4), _input(&"WRITE_IN", &"WRITE"),
		LogicComponentType.new(&"DECODER", LogicComponentType.KIND_DECODER1_TO_2, "1→2 decoder"),
		reg_0, reg_1,
		LogicComponentType.new(&"MUX", LogicComponentType.KIND_MUX2_WORD, "word mux"),
		_output(&"OUT", &"OUT", 4),
	]
	var wires: Array[Dictionary] = [
		_w(&"ADDR_IN", &"DECODER", 0, 0), _w(&"WRITE_IN", &"DECODER", 0, 1),
		_w(&"DATA_IN", &"REG_0", 0, 0), _w(&"DATA_IN", &"REG_1", 0, 0),
		_w(&"DECODER", &"REG_0", 0, 1), _w(&"DECODER", &"REG_1", 1, 1),
		_w(&"REG_0", &"MUX", 0, 0), _w(&"REG_1", &"MUX", 0, 1),
		_w(&"ADDR_IN", &"MUX", 0, 2), _w(&"MUX", &"OUT", 0, 0),
	]
	var steps: Array[Dictionary] = [
		_case({&"ADDR": 0, &"DATA": 3, &"WRITE": 1}, {&"OUT": 3}),
		_case({&"ADDR": 1, &"DATA": 12, &"WRITE": 1}, {&"OUT": 12}),
		_case({&"ADDR": 0, &"DATA": 0, &"WRITE": 0}, {&"OUT": 3}),
		_case({&"ADDR": 0, &"DATA": 5, &"WRITE": 1}, {&"OUT": 5}),
		_case({&"ADDR": 1, &"DATA": 0, &"WRITE": 0}, {&"OUT": 12}),
	]
	return _base(
		&"ram", &"hardware.prologue.ram.title", &"hardware.prologue.ram.description", components,
		{
			&"ADDR_IN": Vector2(380, 70), &"DATA_IN": Vector2(380, 250), &"WRITE_IN": Vector2(380, 475),
			&"DECODER": Vector2(610, 400), &"REG_0": Vector2(830, 120), &"REG_1": Vector2(830, 385),
			&"MUX": Vector2(1090, 250), &"OUT": Vector2(1320, 270),
		}, wires, steps, &"RAM2x4", LogicComponentType.KIND_RAM2X4,
		{
			"feature_tags": [&"storage"],
			"state_feedback_components": [&"REG_0", &"REG_1"],
			"initial_zoom": 0.88,
			"palette_components": [
				reg_0.duplicate_component(),
				LogicComponentType.new(&"PALETTE_DECODER", LogicComponentType.KIND_DECODER1_TO_2, "1→2 decoder"),
				LogicComponentType.new(&"PALETTE_MUX", LogicComponentType.KIND_MUX2_WORD, "word mux"),
			],
			"hint_partial_wires": [
				wires[0].duplicate(), wires[1].duplicate(), wires[2].duplicate(),
				wires[4].duplicate(),
			],
		}
	)
