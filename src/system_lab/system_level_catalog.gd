class_name SystemLevelCatalog
extends RefCounted

const PartSpecType = preload("res://src/system_lab/system_part_spec.gd")

const LEVEL_IDS: Array[StringName] = [
	&"assembly", &"cpu_speed", &"ram_wait", &"bus_width", &"bottleneck",
]

const PROGRAM_ASSEMBLY := """value = load(INPUT[0])
value += 1
store(OUTPUT[0], value)"""

const PROGRAM_CPU := """value = load(INPUT[0])
for step in range(32):
    value += 3
store(OUTPUT[0], value)"""

const PROGRAM_SUM := """acc = 0
for i in range(N):
    value = load(INPUT[i])
    acc += value
store(OUTPUT[0], acc)"""

const PROGRAM_COPY := """for i in range(N):
    value = load(INPUT[i])
    store(OUTPUT[i], value)"""

const PROGRAM_FINAL := """for i in range(N):
    value = load(INPUT[i])
    value += 3
    value += 5
    value += 7
    store(OUTPUT[i], value)"""

var _parts: Dictionary[StringName, SystemPartSpec] = {}
var _levels: Dictionary[StringName, Dictionary] = {}


func _init(cpu_source_signature: String = "reference-cpu4", ram_source_signature: String = "reference-ram2x4") -> void:
	_build_parts(cpu_source_signature, ram_source_signature)
	_build_levels()


func level_ids() -> Array[StringName]:
	return LEVEL_IDS.duplicate()


func definition(level_id: StringName) -> Dictionary:
	return (_levels.get(level_id, {}) as Dictionary).duplicate(true)


func title_key(level_id: StringName) -> StringName:
	return StringName(_levels.get(level_id, {}).get("title_key", &"system.level.unknown.title"))


func description_key(level_id: StringName) -> StringName:
	return StringName(_levels.get(level_id, {}).get("description_key", &"system.level.unknown.description"))


func dependencies(level_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in _levels.get(level_id, {}).get("dependencies", []):
		result.append(StringName(value))
	return result


func is_unlocked(level_id: StringName, completed: Dictionary, prologue_ready: bool, test_mode: bool = false) -> bool:
	if level_id not in LEVEL_IDS:
		return false
	if test_mode:
		return true
	if level_id == LEVEL_IDS[0] and not prologue_ready:
		return false
	for dependency: StringName in dependencies(level_id):
		if not bool(completed.get(dependency, false)):
			return false
	return true


func part(part_id: StringName) -> SystemPartSpec:
	var selected: SystemPartSpec = _parts.get(part_id)
	return selected.duplicate_spec() if selected != null else null


func parts_for_level(level_id: StringName, kind: StringName) -> Array[SystemPartSpec]:
	var key: String = "%s_parts" % String(kind)
	var result: Array[SystemPartSpec] = []
	for value: Variant in _levels.get(level_id, {}).get(key, []):
		var selected: SystemPartSpec = part(StringName(value))
		if selected != null:
			result.append(selected)
	return result


func default_part_id(level_id: StringName, kind: StringName) -> StringName:
	return StringName(_levels.get(level_id, {}).get("default_%s" % String(kind), &""))


func test_set_signature(level_id: StringName) -> String:
	var cases: Array = _levels.get(level_id, {}).get("cases", [])
	return JSON.stringify(cases).sha256_text()


func official_program_signature(level_id: StringName) -> String:
	return String(_levels.get(level_id, {}).get("program_source", "")).sha256_text()


func requires_authored_program(level_id: StringName) -> bool:
	return bool(_levels.get(level_id, {}).get("requires_authored_program", false))


func is_official_program_signature(level_id: StringName, program_signature: String) -> bool:
	return not requires_authored_program(level_id) or program_signature == official_program_signature(level_id)


func completion_status(level_id: StringName, receipts: Array, selected_diagnosis: StringName = &"") -> Dictionary:
	var level: Dictionary = _levels.get(level_id, {})
	if level.is_empty():
		return {"complete": false, "progress": 0, "required": 1, "reason": &"unknown_level"}
	var matching: Array = []
	var expected_test_signature: String = test_set_signature(level_id)
	for receipt_variant: Variant in receipts:
		if receipt_variant == null:
			continue
		var receipt = receipt_variant
		if (
			receipt.level_id == level_id
			and receipt.test_set_signature == expected_test_signature
			and receipt.all_passed
			and is_official_program_signature(level_id, receipt.program_signature)
		):
			matching.append(receipt)
	var comparison_kind := StringName(level.get("comparison_kind", &"none"))
	var minimum_runs: int = int(level.get("minimum_runs", 1))
	if comparison_kind == &"diagnosis":
		if matching.is_empty():
			return {"complete": false, "progress": 0, "required": 1, "reason": &"run_required"}
		var latest = matching[matching.size() - 1]
		var correct: bool = not selected_diagnosis.is_empty() and selected_diagnosis == latest.diagnosed_bottleneck
		return {
			"complete": correct,
			"progress": 1 if correct else 0,
			"required": 1,
			"reason": &"complete" if correct else &"diagnosis_required",
			"expected_diagnosis": latest.diagnosed_bottleneck,
		}
	if comparison_kind == &"scale":
		var best_cases: int = 0
		for receipt_variant: Variant in matching:
			best_cases = maxi(best_cases, int(receipt_variant.total_cases))
		return {
			"complete": best_cases >= minimum_runs,
			"progress": mini(best_cases, minimum_runs),
			"required": minimum_runs,
			"reason": &"complete" if best_cases >= minimum_runs else &"more_scales_required",
		}
	if comparison_kind in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
		var parts_by_control: Dictionary[String, Dictionary] = {}
		for receipt_variant: Variant in matching:
			var receipt = receipt_variant
			var fixed_parts: Array[String] = []
			for fixed_kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
				if fixed_kind != comparison_kind:
					fixed_parts.append("%s=%s" % [fixed_kind, receipt.part_ids.get(fixed_kind, &"")])
			fixed_parts.sort()
			var control_key: String = "%s|%s" % [receipt.program_signature, "|".join(fixed_parts)]
			var compared_parts: Dictionary = parts_by_control.get(control_key, {})
			var compared_id := StringName(receipt.part_ids.get(comparison_kind, &""))
			if not compared_id.is_empty():
				compared_parts[compared_id] = true
			parts_by_control[control_key] = compared_parts
		var maximum_compared: int = 0
		for compared_parts: Dictionary in parts_by_control.values():
			maximum_compared = maxi(maximum_compared, compared_parts.size())
		return {
			"complete": maximum_compared >= minimum_runs,
			"progress": mini(maximum_compared, minimum_runs),
			"required": minimum_runs,
			"reason": &"complete" if maximum_compared >= minimum_runs else &"more_parts_required",
		}
	return {
		"complete": not matching.is_empty(),
		"progress": 1 if not matching.is_empty() else 0,
		"required": 1,
		"reason": &"complete" if not matching.is_empty() else &"run_required",
	}


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for part_id: StringName in _parts:
		errors.append_array((_parts[part_id] as SystemPartSpec).validation_errors())
	for index: int in range(LEVEL_IDS.size()):
		var level_id: StringName = LEVEL_IDS[index]
		if not _levels.has(level_id):
			errors.append("Missing system level %s." % level_id)
			continue
		var level: Dictionary = _levels[level_id]
		if StringName(level.get("id", &"")) != level_id:
			errors.append("System level %s has mismatched identity." % level_id)
		if int(level.get("order", -1)) != index:
			errors.append("System level %s has unexpected order." % level_id)
		for dependency: StringName in dependencies(level_id):
			if dependency not in LEVEL_IDS or LEVEL_IDS.find(dependency) >= index:
				errors.append("System level %s has invalid dependency %s." % [level_id, dependency])
		for kind: StringName in [PartSpecType.KIND_CPU, PartSpecType.KIND_RAM, PartSpecType.KIND_BUS]:
			var available: Array[SystemPartSpec] = parts_for_level(level_id, kind)
			if available.is_empty():
				errors.append("System level %s has no %s parts." % [level_id, kind])
			var default_id: StringName = default_part_id(level_id, kind)
			var default_part: SystemPartSpec = _parts.get(default_id)
			if default_part == null or default_part.kind != kind:
				errors.append("System level %s has invalid default %s." % [level_id, kind])
		var prediction_key := StringName(level.get("prediction_key", &""))
		var prediction_options: Array = level.get("prediction_options", [])
		if prediction_key.is_empty() != prediction_options.is_empty():
			errors.append("System level %s has incomplete prediction content." % level_id)
		var prediction_ids: Dictionary[StringName, bool] = {}
		for option: Dictionary in prediction_options:
			var prediction_id := StringName(option.get("id", &""))
			var text_key := StringName(option.get("text_key", &""))
			if prediction_id.is_empty() or text_key.is_empty() or prediction_ids.has(prediction_id):
				errors.append("System level %s has an invalid prediction option." % level_id)
			prediction_ids[prediction_id] = true
		if (level.get("cases", []) as Array).is_empty():
			errors.append("System level %s has no official cases." % level_id)
	return errors


func _build_parts(cpu_source: String, ram_source: String) -> void:
	for data: Dictionary in [
		{"id": &"cpu_eco", "kind": PartSpecType.KIND_CPU, "name": "CPU8 · ECO", "cost": 4, "compute_cycles": 4},
		{"id": &"cpu_balanced", "kind": PartSpecType.KIND_CPU, "name": "CPU8 · BALANCED", "cost": 7, "compute_cycles": 2},
		{"id": &"cpu_fast", "kind": PartSpecType.KIND_CPU, "name": "CPU8 · FAST", "cost": 13, "compute_cycles": 1},
	]:
		_parts[data["id"]] = PartSpecType.new(
			data["id"], data["kind"], data["name"], data["cost"],
			"CPU8<%s>" % cpu_source,
			{"word_bits": 8, "compute_cycles": data["compute_cycles"], "generated_from": cpu_source}
		)
	for data: Dictionary in [
		{"id": &"ram_slow", "kind": PartSpecType.KIND_RAM, "name": "RAM64x8 · SLOW", "cost": 4, "access_cycles": 12},
		{"id": &"ram_balanced", "kind": PartSpecType.KIND_RAM, "name": "RAM64x8 · BALANCED", "cost": 7, "access_cycles": 8},
		{"id": &"ram_fast", "kind": PartSpecType.KIND_RAM, "name": "RAM64x8 · FAST", "cost": 13, "access_cycles": 4},
	]:
		_parts[data["id"]] = PartSpecType.new(
			data["id"], data["kind"], data["name"], data["cost"],
			"RAM64x8<%s>" % ram_source,
			{"word_bits": 8, "access_cycles": data["access_cycles"], "generated_from": ram_source, "capacity_words": 64}
		)
	for data: Dictionary in [
		{"id": &"bus_2", "name": "BUS · 2 bit/cycle", "cost": 4, "bandwidth": 2},
		{"id": &"bus_4", "name": "BUS · 4 bit/cycle", "cost": 7, "bandwidth": 4},
		{"id": &"bus_8", "name": "BUS · 8 bit/cycle", "cost": 13, "bandwidth": 8},
	]:
		_parts[data["id"]] = PartSpecType.new(
			data["id"], PartSpecType.KIND_BUS, data["name"], data["cost"], "authored-bus-v1",
			{"word_bits": 8, "bandwidth_bits_per_cycle": data["bandwidth"]}
		)


func _build_levels() -> void:
	_register_level(&"assembly", 0, [], 1, PROGRAM_ASSEMBLY,
		[_case("assembly-a", [7], [8]), _case("assembly-b", [255], [0])],
		[&"cpu_balanced"], [&"ram_balanced"], [&"bus_8"],
		&"cpu_balanced", &"ram_balanced", &"bus_8", &"none", 1, false)
	_register_level(&"cpu_speed", 1, [&"assembly"], 2, PROGRAM_SUM,
		[_sum_case("cpu-a", [1, 2, 3, 4, 5, 6, 7, 8]), _sum_case("cpu-b", [21, 34, 55, 89, 13, 8, 5, 3])],
		[&"cpu_eco", &"cpu_fast"], [&"ram_slow"], [&"bus_8"],
		&"cpu_eco", &"ram_slow", &"bus_8", PartSpecType.KIND_CPU, 2, false,
		&"system.prediction.cpu_speed.question", [
			_prediction_option(&"large", &"system.prediction.cpu_speed.large"),
			_prediction_option(&"modest", &"system.prediction.cpu_speed.modest"),
			_prediction_option(&"none", &"system.prediction.cpu_speed.none"),
		])
	_register_level(&"ram_wait", 2, [&"cpu_speed"], 3, PROGRAM_SUM,
		[_sum_case("ram-a", [1, 2, 3, 4, 5, 6, 7, 8]), _sum_case("ram-b", [21, 34, 55, 89, 13, 8, 5, 3])],
		[&"cpu_fast"], [&"ram_slow", &"ram_fast"], [&"bus_8"],
		&"cpu_fast", &"ram_slow", &"bus_8", PartSpecType.KIND_RAM, 2, false,
		&"system.prediction.ram_wait.question", [
			_prediction_option(&"compute", &"system.prediction.ram_wait.compute"),
			_prediction_option(&"wait", &"system.prediction.ram_wait.wait"),
			_prediction_option(&"both", &"system.prediction.ram_wait.both"),
		])
	_register_level(&"bus_width", 3, [&"ram_wait"], 4, PROGRAM_COPY,
		[_case("bus-a", [3, 5, 8, 13, 21, 34, 55, 89], [3, 5, 8, 13, 21, 34, 55, 89])],
		[&"cpu_fast"], [&"ram_fast"], [&"bus_2", &"bus_8"],
		&"cpu_fast", &"ram_fast", &"bus_2", PartSpecType.KIND_BUS, 2, false,
		&"system.prediction.bus_width.question", [
			_prediction_option(&"four_to_one", &"system.prediction.bus_width.four_to_one"),
			_prediction_option(&"two_to_one", &"system.prediction.bus_width.two_to_one"),
			_prediction_option(&"unchanged", &"system.prediction.bus_width.unchanged"),
		])
	_register_level(&"bottleneck", 4, [&"bus_width"], 5, PROGRAM_FINAL,
		[_transform_case("final-4", _series(4), 15), _transform_case("final-16", _series(16), 15), _transform_case("final-64", _series(64), 15)],
		[&"cpu_eco", &"cpu_balanced", &"cpu_fast"],
		[&"ram_slow", &"ram_balanced", &"ram_fast"],
		[&"bus_2", &"bus_4", &"bus_8"],
		&"cpu_balanced", &"ram_balanced", &"bus_4", &"diagnosis", 1, true)


func _register_level(
		id: StringName,
		order: int,
		dependencies: Array[StringName],
		profiler_tier: int,
		program_source: String,
		cases: Array[Dictionary],
		cpu_parts: Array[StringName],
		ram_parts: Array[StringName],
		bus_parts: Array[StringName],
		default_cpu: StringName,
		default_ram: StringName,
		default_bus: StringName,
		comparison_kind: StringName,
		minimum_runs: int,
		diagnosis_required: bool,
		prediction_key: StringName = &"",
		prediction_options: Array[Dictionary] = []
	) -> void:
	_levels[id] = {
		"id": id,
		"order": order,
		"title_key": StringName("system.level.%s.title" % String(id)),
		"description_key": StringName("system.level.%s.description" % String(id)),
		"objective_key": StringName("system.level.%s.objective" % String(id)),
		"dependencies": dependencies.duplicate(),
		"profiler_tier": profiler_tier,
		"program_source": program_source,
		"cases": cases.duplicate(true),
		"cpu_parts": cpu_parts.duplicate(),
		"ram_parts": ram_parts.duplicate(),
		"bus_parts": bus_parts.duplicate(),
		"default_cpu": default_cpu,
		"default_ram": default_ram,
		"default_bus": default_bus,
		"comparison_kind": comparison_kind,
		"minimum_runs": minimum_runs,
		"diagnosis_required": diagnosis_required,
		"requires_authored_program": order > 0,
		"prediction_key": prediction_key,
		"prediction_options": prediction_options.duplicate(true),
	}


func _prediction_option(id: StringName, text_key: StringName) -> Dictionary:
	return {"id": id, "text_key": text_key}


func _case(name: String, input_data: Array[int], expected: Array[int]) -> Dictionary:
	return {"name": name, "input": input_data.duplicate(), "expected": expected.duplicate()}


func _sum_case(name: String, input_data: Array[int]) -> Dictionary:
	var total: int = 0
	for value: int in input_data:
		total = (total + value) & 0xff
	return _case(name, input_data, [total])


func _transform_case(name: String, input_data: Array[int], amount: int) -> Dictionary:
	var expected: Array[int] = []
	for value: int in input_data:
		expected.append((value + amount) & 0xff)
	return _case(name, input_data, expected)


func _series(size: int) -> Array[int]:
	var result: Array[int] = []
	for index: int in range(size):
		result.append((index * 17 + 3) & 0xff)
	return result
