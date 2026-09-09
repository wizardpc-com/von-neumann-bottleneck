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

	registry.register_level(LevelType.new(&"selector4",&"control_exploration",1,&"exploration.selector4.title",
		&"exploration.selector4.description",[&"selector"],LevelType.ENTRY_CIRCUIT,Callable(self,"_selector4")))

	registry.register_level(LevelType.new(&"parity",&"control_exploration",2,&"exploration.parity.title",
		&"exploration.parity.description",[&"half_adder"],LevelType.ENTRY_CIRCUIT,Callable(self,"_parity")))

	registry.register_level(LevelType.new(&"alarm",&"state_exploration",1,&"exploration.alarm.title",
		&"exploration.alarm.description",[&"latch"],LevelType.ENTRY_CIRCUIT,Callable(self,"_alarm")))


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


func _selector4(_library: Dictionary) -> Dictionary:
	var components: Array[LogicComponent] = []
	var layout: Dictionary = {}
	for index: int in range(4):
		var id := StringName("D%d" % index)
		components.append(_input(id,id))
		layout[id] = Vector2(100,80+index*150)
	components.append_array([_input(&"S0",&"S0"),_input(&"S1",&"S1"),_output(&"OUT",&"OUT")])
	layout.merge({&"S0":Vector2(100,740),&"S1":Vector2(100,900),&"OUT":Vector2(1630,320)})
	var wires: Array[Dictionary] = []
	_mux(components,layout,wires,"LOW",&"D0",&"D1",&"S0",Vector2(480,140))
	_mux(components,layout,wires,"HIGH",&"D2",&"D3",&"S0",Vector2(480,580))
	_mux(components,layout,wires,"FINAL",&"LOW_O",&"HIGH_O",&"S1",Vector2(1090,320))
	wires.append(_w(&"FINAL_O",&"OUT"))
	var steps: Array[Dictionary] = []
	for selector: int in range(4):
		for bits: int in range(16):
			var inputs: Dictionary = {&"S0":selector&1,&"S1":(selector>>1)&1}
			for index: int in range(4): inputs[StringName("D%d"%index)] = (bits>>index)&1
			steps.append(_case(inputs,{&"OUT":(bits>>selector)&1}))
	return _base(&"selector4",&"exploration.selector4.title",&"exploration.selector4.description",components,layout,wires,steps,&"",&"",
		{"blank_start":true,"initial_zoom":0.75,"palette_components":_basic_gates(),
		"hint_partial_wires":wires.slice(0,4),"hint_context_components":[&"S0",&"S1"]})


func _mux(components: Array[LogicComponent],layout: Dictionary,wires: Array[Dictionary],prefix: String,a: StringName,b: StringName,s: StringName,at: Vector2) -> void:
	var n := StringName(prefix+"_N")
	var left := StringName(prefix+"_A")
	var right := StringName(prefix+"_B")
	var out := StringName(prefix+"_O")
	components.append_array([LogicComponentType.new(n,LogicComponentType.KIND_NOT,"NOT"),
		LogicComponentType.new(left,LogicComponentType.KIND_AND,"AND"),LogicComponentType.new(right,LogicComponentType.KIND_AND,"AND"),
		LogicComponentType.new(out,LogicComponentType.KIND_OR,"OR")])
	layout.merge({n:at+Vector2(-180,200),left:at,right:at+Vector2(0,180),out:at+Vector2(260,80)})
	wires.append_array([_w(s,n),_w(a,left),_w(n,left,0,1),_w(b,right),_w(s,right,0,1),_w(left,out),_w(right,out,0,1)])


func _parity(_library: Dictionary) -> Dictionary:
	var components: Array[LogicComponent] = []
	var layout: Dictionary = {}
	var signals: Array[StringName] = [&"D0",&"D1",&"D2",&"D3",&"CHECK"]
	for index: int in range(5):
		components.append(_input(signals[index],signals[index]))
		layout[signals[index]] = Vector2(160,80+index*150)
	var wires: Array[Dictionary] = []
	for index: int in range(4):
		var id := StringName("X%d"%index)
		components.append(LogicComponentType.new(id,LogicComponentType.KIND_XOR,"XOR"))
		layout[id] = Vector2(450+index*250,180+index*100)
		wires.append(_w(signals[0] if index == 0 else StringName("X%d"%(index-1)),id))
		wires.append(_w(signals[index+1],id,0,1))
	components.append(_output(&"ERROR",&"ERROR"))
	layout[&"ERROR"] = Vector2(1510,480)
	wires.append(_w(&"X3",&"ERROR"))
	var steps: Array[Dictionary] = []
	for bits: int in range(32):
		var inputs: Dictionary = {}
		var odd: int = 0
		for index: int in range(5):
			inputs[signals[index]] = (bits>>index)&1
			odd ^= (bits>>index)&1
		steps.append(_case(inputs,{&"ERROR":odd}))
	return _base(&"parity",&"exploration.parity.title",&"exploration.parity.description",components,layout,wires,steps,&"",&"",
		{"blank_start":true,"initial_zoom":0.8,"palette_components":_basic_gates(),
		"hint_partial_wires":wires.slice(0,2),"hint_context_components":[&"CHECK"]})


func _alarm(library: Dictionary) -> Dictionary:
	var latch: LogicComponent = _library_instance(library,&"SRLatch",&"MEMORY","SR Latch")
	if latch == null: return _missing(&"alarm",&"SRLatch")
	var gates: Array[LogicComponent] = _basic_gates()
	var components: Array[LogicComponent] = [_input(&"FAULT",&"FAULT"),_input(&"CLEAR",&"CLEAR"),
		LogicComponentType.new(&"NOT_CLEAR",LogicComponentType.KIND_NOT,"NOT"),
		LogicComponentType.new(&"SET",LogicComponentType.KIND_AND,"AND"),latch,_output(&"ALARM",&"ALARM")]
	var wires: Array[Dictionary] = [_w(&"CLEAR",&"NOT_CLEAR"),_w(&"FAULT",&"SET"),_w(&"NOT_CLEAR",&"SET",0,1),
		_w(&"SET",&"MEMORY"),_w(&"CLEAR",&"MEMORY",0,1),_w(&"MEMORY",&"ALARM")]
	var steps: Array[Dictionary] = []
	var remembered: int = 0
	# Every possible pair of successive input states, preceded by an explicit reset.
	for first: int in range(4):
		for second: int in range(4):
			for input: int in [2,first,second,0]:
				var fault: int = input&1
				var clear: int = (input>>1)&1
				remembered = 0 if clear else 1 if fault else remembered
				steps.append(_case({&"FAULT":fault,&"CLEAR":clear},{&"ALARM":remembered}))
	gates.append(latch)
	return _base(&"alarm",&"exploration.alarm.title",&"exploration.alarm.description",components,
		{&"FAULT":Vector2(180,140),&"CLEAR":Vector2(180,480),&"NOT_CLEAR":Vector2(470,480),
		&"SET":Vector2(730,220),&"MEMORY":Vector2(990,300),&"ALARM":Vector2(1320,300)},wires,steps,&"",&"",
		{"blank_start":true,"initial_zoom":0.85,"feature_tags":[&"storage"],"palette_components":gates,
		"hint_partial_wires":[wires[0],wires[1],wires[2]],"hint_context_components":[&"CLEAR"]})


func _basic_gates() -> Array[LogicComponent]:
	return [LogicComponentType.new(&"P_NOT",LogicComponentType.KIND_NOT,"NOT"),
		LogicComponentType.new(&"P_AND",LogicComponentType.KIND_AND,"AND"),
		LogicComponentType.new(&"P_OR",LogicComponentType.KIND_OR,"OR"),
		LogicComponentType.new(&"P_XOR",LogicComponentType.KIND_XOR,"XOR")]
