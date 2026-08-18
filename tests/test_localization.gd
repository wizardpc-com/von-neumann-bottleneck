extends SceneTree

const DSLParserType = preload("res://src/simulation/dsl_parser.gd")
const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationCoreType = preload("res://src/simulation/simulation_core.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const CircuitSimulatorType = preload("res://src/circuit/circuit_simulator.gd")

const LOCALIZED_SOURCE_FILES := [
	"res://src/localization/localization.gd",
	"res://src/ui/prototype_hub.gd",
	"res://src/ui/floating_instrument_panel.gd",
	"res://src/ui/trace_overlay.gd",
	"res://src/ui/main.gd",
	"res://src/hardware_foundations/hardware_foundations.gd",
	"res://src/hardware_foundations/prologue_level_catalog.gd",
	"res://src/simulation/dsl_parser.gd",
	"res://src/simulation/dsl_program.gd",
	"res://src/circuit/logic_circuit.gd",
	"res://src/circuit/circuit_simulator.gd",
	"res://src/circuit/prologue_simulator.gd",
]
const LOCALIZED_SOURCE_DIRECTORIES := [
	"res://src/content",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(_current_locale() == "zh_CN", "Simplified Chinese must be the startup locale.")
	_assert(_t(&"hub.subtitle") == "可玩研究原型", "The default catalog must present Chinese player-facing copy.")
	_assert(_supported_locales() == PackedStringArray(["zh_CN", "en"]), "Supported locales must be explicit and stable.")

	var used_keys: Array[StringName] = _localized_source_keys()
	_assert(used_keys.size() > 300, "Localization coverage must include the complete current UI surface.")
	for locale: String in ["zh_CN", "en"]:
		_assert(_set_locale(locale), "Registered locale %s must be selectable." % locale)
		for key: StringName in used_keys:
			_assert(_t(key) != String(key), "%s catalog is missing key %s." % [locale, key])
	_assert(_t(&"hub.subtitle") == "PLAYABLE RESEARCH BUILDS", "English must remain a working alternate catalog.")
	var locale_before_rejection: String = _current_locale()
	_assert(not _set_locale("ja") and _current_locale() == locale_before_rejection, "Unsupported locales must be rejected without changing presentation state.")

	var invalid_program = DSLParserType.parse("not valid DSL")
	var debug_errors_before: Array[String] = invalid_program.errors.duplicate()
	_set_locale("zh_CN")
	var chinese_error: String = _text_from_spec(invalid_program.error_specs[0])
	_set_locale("en")
	var english_error: String = _text_from_spec(invalid_program.error_specs[0])
	_assert(chinese_error != english_error and "not valid DSL" in chinese_error and "not valid DSL" in english_error, "Structured DSL diagnostics must localize while preserving technical source text.")
	_assert(invalid_program.errors == debug_errors_before, "Changing locale must not mutate parser diagnostics or program state.")

	var row_program = DSLParserType.parse(ProgramTemplatesType.ROW_FIRST)
	_set_locale("zh_CN")
	var chinese_trace = SimulationCoreType.new().run(row_program, SimulationCoreType.official_data_copy(), 1, "Official Test Set")
	_set_locale("en")
	var english_trace = SimulationCoreType.new().run(row_program, SimulationCoreType.official_data_copy(), 1, "Official Test Set")
	_assert(chinese_trace.canonical_signature() == english_trace.canonical_signature(), "Locale must not change SimulationCore events, results, metrics, or signatures.")

	var circuit: LogicCircuit = _valid_half_adder()
	_set_locale("zh_CN")
	var chinese_circuit_trace = CircuitSimulatorType.new().evaluate(circuit, {&"A": true, &"B": true})
	_set_locale("en")
	var english_circuit_trace = CircuitSimulatorType.new().evaluate(circuit, {&"A": true, &"B": true})
	_assert(chinese_circuit_trace.canonical_signature() == english_circuit_trace.canonical_signature(), "Locale must not change circuit evaluation or its canonical trace.")

	_set_locale("zh_CN")
	if failures.is_empty():
		print("PASS: Chinese default, English catalog, key coverage, and locale-independent simulation tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d localization assertion(s) failed" % failures.size())
		quit(1)


func _localized_source_keys() -> Array[StringName]:
	var matcher := RegEx.new()
	matcher.compile("&\\\"([a-z][a-z0-9_.]+)\\\"")
	var keys: Dictionary[StringName, bool] = {}
	var source_paths: Array[String] = []
	for path: String in LOCALIZED_SOURCE_FILES:
		source_paths.append(path)
	for directory_path: String in LOCALIZED_SOURCE_DIRECTORIES:
		_collect_gdscript_paths(directory_path, source_paths)
	source_paths.sort()
	for path: String in source_paths:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("Cannot read localized source file %s." % path)
			continue
		for result: RegExMatch in matcher.search_all(file.get_as_text()):
			var key := StringName(result.get_string(1))
			if "." in String(key):
				keys[key] = true
	var sorted_keys: Array[StringName] = []
	for key: StringName in keys:
		sorted_keys.append(key)
	sorted_keys.sort()
	return sorted_keys


func _collect_gdscript_paths(directory_path: String, paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		failures.append("Cannot scan localized source directory %s." % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child_path := directory_path.path_join(entry)
			if directory.current_is_dir():
				_collect_gdscript_paths(child_path, paths)
			elif entry.ends_with(".gd") and child_path not in paths:
				paths.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _valid_half_adder() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A_IN", &"input", "A", &"A", true),
		LogicComponentType.new(&"B_IN", &"input", "B", &"B", true),
		LogicComponentType.new(&"SUM_OUT", &"output", "SUM", &"SUM", true),
		LogicComponentType.new(&"CARRY_OUT", &"output", "CARRY", &"CARRY", true),
		LogicComponentType.new(&"AND_CARRY", &"and", "AND CARRY"),
		LogicComponentType.new(&"OR_SUM", &"or", "OR SUM"),
		LogicComponentType.new(&"NOT_CARRY", &"not", "NOT CARRY"),
		LogicComponentType.new(&"AND_SUM", &"and", "AND SUM"),
	]:
		circuit.add_component(component)
	for wire: Array in [
		[&"A_IN", 0, &"AND_CARRY", 0], [&"B_IN", 0, &"AND_CARRY", 1],
		[&"A_IN", 0, &"OR_SUM", 0], [&"B_IN", 0, &"OR_SUM", 1],
		[&"AND_CARRY", 0, &"NOT_CARRY", 0],
		[&"OR_SUM", 0, &"AND_SUM", 0], [&"NOT_CARRY", 0, &"AND_SUM", 1],
		[&"AND_SUM", 0, &"SUM_OUT", 0], [&"AND_CARRY", 0, &"CARRY_OUT", 0],
	]:
		circuit.connect_ports(wire[0], wire[1], wire[2], wire[3])
	return circuit


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _localization() -> Node:
	return root.get_node("Localization")


func _current_locale() -> String:
	return String(_localization().call("current_locale"))


func _supported_locales() -> PackedStringArray:
	return PackedStringArray(_localization().call("supported_locales"))


func _set_locale(locale: String) -> bool:
	return bool(_localization().call("set_locale", locale))


func _t(key: StringName, arguments: Array = []) -> String:
	return String(_localization().call("text", key, arguments))


func _text_from_spec(spec: Dictionary) -> String:
	return String(_localization().call("text_from_spec", spec))
