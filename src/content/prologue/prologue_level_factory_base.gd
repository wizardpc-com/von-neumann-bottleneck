extends RefCounted

const LogicComponentType = preload("res://src/circuit/logic_component.gd")


func _base(
		level_id: StringName,
		title_key: StringName,
		description_key: StringName,
		components: Array[LogicComponent],
		layout: Dictionary,
		wires: Array[Dictionary],
		steps: Array[Dictionary],
		seal_name: StringName = &"",
		seal_kind: StringName = &"",
		options: Dictionary = {}
	) -> Dictionary:
	var level := {
		"id": level_id,
		"title_key": title_key,
		"description_key": description_key,
		"components": components,
		"layout": layout,
		"reference_wires": wires,
		"official_steps": steps,
		"debug_inputs": steps[0]["inputs"].duplicate(true) if not steps.is_empty() else {},
		"allow_feedback": false,
		"seal_name": seal_name,
		"seal_kind": seal_kind,
		"available": true,
	}
	level.merge(options, true)
	return level


func _library_instance(
		library: Dictionary,
		name: StringName,
		component_id: StringName,
		display_name: String
	) -> LogicComponent:
	var definition: ReusableComponent = library.get(name)
	return definition.instantiate(component_id, display_name) if definition != null else null


func _input(id: StringName, signal_name: StringName, width: int = 1) -> LogicComponent:
	return LogicComponentType.new(
		id, LogicComponentType.KIND_INPUT, "TEST %s" % signal_name,
		signal_name, true, [], [], [], [], {"width": width}
	)


func _output(id: StringName, signal_name: StringName, width: int = 1) -> LogicComponent:
	return LogicComponentType.new(
		id, LogicComponentType.KIND_OUTPUT, "PROBE %s" % signal_name,
		signal_name, true, [], [], [], [], {"width": width}
	)


func _constant(id: StringName, value: int, width: int = 1) -> LogicComponent:
	return LogicComponentType.new(
		id, LogicComponentType.KIND_CONSTANT, str(value), &"", false,
		[], [], [], [], {"width": width, "value": value}
	)


func _w(
		from_id: StringName,
		to_id: StringName,
		from_port: int = 0,
		to_port: int = 0
	) -> Dictionary:
	return {"from": from_id, "from_port": from_port, "to": to_id, "to_port": to_port}


func _case(
		inputs: Dictionary,
		expected: Dictionary,
		label_key: StringName = &""
	) -> Dictionary:
	return {"inputs": inputs, "expected": expected, "label_key": label_key}


func _missing(level_id: StringName, component_name: StringName) -> Dictionary:
	return {
		"id": level_id,
		"available": false,
		"missing_component": component_name,
		"title_key": StringName("hardware.prologue.%s.title" % level_id),
		"description_key": StringName("hardware.prologue.%s.description" % level_id),
	}
