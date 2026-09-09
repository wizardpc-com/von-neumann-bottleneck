extends "res://src/content/prologue/prologue_level_factory_base.gd"

const BranchType = preload("res://src/content/campaign_branch_definition.gd")
const LevelType = preload("res://src/content/campaign_level_definition.gd")


func register_into(registry, _builders: Dictionary = {}) -> void:
	registry.register_branch(BranchType.new(&"control_exploration", &"exploration.branch.control", 4))
	registry.register_branch(BranchType.new(&"state_exploration", &"exploration.branch.state", 5))
	registry.register_level(LevelType.new(
		&"selector", &"control_exploration", 0, &"exploration.selector.title",
		&"exploration.selector.description", [&"half_adder"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_selector")
	))
	registry.register_level(LevelType.new(
		&"delay", &"state_exploration", 0, &"exploration.delay.title",
		&"exploration.delay.description", [&"register"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_delay")
	))


func _selector(_library: Dictionary) -> Dictionary:
	var components: Array[LogicComponent] = [
		_input(&"A_IN", &"A"), _input(&"B_IN", &"B"), _input(&"S_IN", &"S"),
		LogicComponentType.new(&"NOT_S", LogicComponentType.KIND_NOT, "NOT"),
		LogicComponentType.new(&"AND_A", LogicComponentType.KIND_AND, "AND"),
		LogicComponentType.new(&"AND_B", LogicComponentType.KIND_AND, "AND"),
		LogicComponentType.new(&"OR_OUT", LogicComponentType.KIND_OR, "OR"),
		_output(&"OUT", &"OUT"),
	]
	var wires: Array[Dictionary] = [
		_w(&"S_IN", &"NOT_S"), _w(&"A_IN", &"AND_A"), _w(&"NOT_S", &"AND_A", 0, 1),
		_w(&"B_IN", &"AND_B"), _w(&"S_IN", &"AND_B", 0, 1),
		_w(&"AND_A", &"OR_OUT"), _w(&"AND_B", &"OR_OUT", 0, 1), _w(&"OR_OUT", &"OUT"),
	]
	var steps: Array[Dictionary] = []
	for s: int in range(2):
		for a: int in range(2):
			for b: int in range(2):
				steps.append(_case({&"A": a, &"B": b, &"S": s}, {&"OUT": a if s == 0 else b}))
	return _base(&"selector", &"exploration.selector.title", &"exploration.selector.description", components,
		{&"A_IN": Vector2(200, 100), &"B_IN": Vector2(200, 280), &"S_IN": Vector2(200, 460),
		&"NOT_S": Vector2(440, 460), &"AND_A": Vector2(650, 150), &"AND_B": Vector2(650, 340),
		&"OR_OUT": Vector2(860, 230), &"OUT": Vector2(1130, 230)}, wires, steps, &"", &"",
		{"blank_start": true, "initial_zoom": 0.9,
		"palette_components": [components[3], components[4], components[6],
		LogicComponentType.new(&"PALETTE_XOR", LogicComponentType.KIND_XOR, "XOR")],
		"hint_partial_wires": [wires[0], wires[1], wires[2]], "hint_context_components": [&"S_IN"]})


func _delay(library: Dictionary) -> Dictionary:
	var recent: LogicComponent = _library_instance(library, &"Register4", &"RECENT", "Register4")
	var previous: LogicComponent = _library_instance(library, &"Register4", &"PREVIOUS", "Register4")
	if recent == null or previous == null:
		return _missing(&"delay", &"Register4")
	var components: Array[LogicComponent] = [
		_input(&"DATA_IN", &"DATA", 4), _input(&"ACCEPT_IN", &"ACCEPT"),
		recent, previous, _output(&"OUT", &"OUT", 4),
	]
	var wires: Array[Dictionary] = [
		_w(&"DATA_IN", &"RECENT"), _w(&"RECENT", &"PREVIOUS"),
		_w(&"ACCEPT_IN", &"RECENT", 0, 1), _w(&"ACCEPT_IN", &"PREVIOUS", 0, 1),
		_w(&"PREVIOUS", &"OUT"),
	]
	var steps: Array[Dictionary] = []
	var last: int = 0
	var output: int = 0
	# Fixed public sequence includes pauses, consecutive accepts, repeated values,
	# zero and the full four-bit range. Both registers commit at the same boundary.
	for sample: Array in [[3, 0], [3, 1], [7, 1], [15, 0], [2, 1], [2, 1], [0, 1], [15, 1], [9, 0], [9, 0], [4, 1], [1, 1]]:
		if int(sample[1]) == 1:
			output = last
			last = int(sample[0])
		steps.append(_case({&"DATA": int(sample[0]), &"ACCEPT": int(sample[1])}, {&"OUT": output}))
	return _base(&"delay", &"exploration.delay.title", &"exploration.delay.description", components,
		{&"DATA_IN": Vector2(200, 150), &"ACCEPT_IN": Vector2(200, 390),
		&"RECENT": Vector2(510, 230), &"PREVIOUS": Vector2(790, 230), &"OUT": Vector2(1140, 250)},
		wires, steps, &"", &"", {"blank_start": true, "initial_zoom": 0.9,
		"feature_tags": [&"storage"], "palette_components": [recent],
		"hint_partial_wires": [wires[0], wires[2]], "hint_context_components": [&"OUT"]})
