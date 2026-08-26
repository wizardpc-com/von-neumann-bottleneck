extends SceneTree

const DSLParserType = preload("res://src/simulation/dsl_parser.gd")
const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationCoreType = preload("res://src/simulation/simulation_core.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const CircuitSimulatorType = preload("res://src/circuit/circuit_simulator.gd")
const SystemCatalogType = preload("res://src/system_lab/system_level_catalog.gd")
const SystemParserType = preload("res://src/system_lab/system_dsl_parser.gd")
const SystemCoreType = preload("res://src/system_lab/system_simulation_core.gd")
const SystemTopologyType = preload("res://src/system_lab/system_topology.gd")
const LocalityCatalogType = preload("res://src/locality_chapter/locality_level_catalog.gd")
const MissionNarrativeCatalogType = preload("res://src/ui/mission_narrative_catalog.gd")
const LinkedMissionTextType = preload("res://src/ui/linked_mission_text.gd")

const LOCALIZED_SOURCE_FILES := [
	"res://src/localization/localization.gd",
	"res://src/ui/prototype_hub.gd",
	"res://src/ui/game_mode_selector.gd",
	"res://src/ui/floating_instrument_panel.gd",
	"res://src/ui/trace_overlay.gd",
	"res://src/ui/main.gd",
	"res://src/ui/terminology_handbook.gd",
	"res://src/ui/mission_narrative_catalog.gd",
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
	"res://src/locality_chapter",
	"res://src/system_lab",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(_current_locale() == "zh_CN", "Simplified Chinese must be the startup locale.")
	_assert(_t(&"hub.subtitle") == "可玩研究原型", "The default catalog must present Chinese player-facing copy.")
	_assert(_t(&"hub.options.quit") == "退出游戏", "The chapter Options menu must provide a localized quit action.")
	_assert(_t(&"terminology.button") == "手册", "The Chinese bottom-right handbook entry must use the concise shared tool-button label.")
	_assert(_t(&"hub.locality.title") == "第 2 章：让数据留在近处", "The hub must present the locality campaign as the formal second chapter.")
	_assert("v0.2" not in _t(&"hub.locality.eyebrow") and "v0.2" not in _t(&"hub.locality.open"), "The formal Chapter 2 hub card must not retain legacy-prototype identity copy.")
	_assert(_t(&"trace.playback.next_evidence") == "下一关键证据" and _t(&"trace.playback.finish_now") == "结束播放", "The Chinese Trace controls must name evidence navigation rather than simulation mutation.")
	_assert(_t(&"common.clock_period.label") == "时钟周期" and _t(&"common.clock_period.tooltip").contains("不改变模拟结果"), "The Chinese playback control must describe an editable Clock Period as presentation-only.")
	_assert(_t(&"chapter2.status.first_experiment_one_change") == "第一次实验只改变一个杠杆；先运行并观察结果，再组合方案。", "The Chinese capstone boundary must ask for one controlled first change without prescribing the lever.")
	_assert(_t(&"chapter2.capstone.history.raw_metrics", [642, 608, 32]) == "总计 642 cycles · CPU WAIT 608 cycles · 数据请求 32", "The Chinese pre-diagnosis History copy must expose only raw totals with all placeholders intact.")
	_assert(_t(&"chapter2.history.personal_best", [138, 104, 4, "1-line Cache"]) == "个人最佳 · 138 cycles · CPU WAIT 104 · 成本 4\n1-line Cache", "The Chinese Personal Best copy must preserve all four evidence placeholders.")
	_assert(
		_t(&"chapter2.profiler.tree.schedule") == "调度证据"
		and _t(&"chapter2.profiler.tree.pass", [2]) == "第 2 轮"
		and _t(&"chapter2.profiler.tree.pass_group", [3, 2]) == "工作组 3 · 第 2 轮"
		and _t(&"chapter2.profiler.tree.schedule_event", [42, "远端获取"]) == "cycle 42 · 远端获取"
		and _t(&"chapter2.profiler.event_schedule.pass", [2]) == "调度 · 第 2 轮"
		and _t(&"chapter2.profiler.event_schedule.pass_group", [3, 2]) == "调度 · 工作组 3 · 第 2 轮",
		"The Chinese Profiler schedule copy must preserve pass/work-group meaning and placeholder order."
	)
	_assert(_supported_locales() == PackedStringArray(["zh_CN", "en"]), "Supported locales must be explicit and stable.")
	_validate_mission_page_structure()

	var used_keys: Array[StringName] = _localized_source_keys()
	for key: StringName in LocalityCatalogType.new().localization_keys():
		if key not in used_keys:
			used_keys.append(key)
	used_keys.sort()
	_assert(used_keys.size() > 300, "Localization coverage must include the complete current UI surface.")
	for locale: String in ["zh_CN", "en"]:
		_assert(_set_locale(locale), "Registered locale %s must be selectable." % locale)
		for key: StringName in used_keys:
			_assert(_t(key) != String(key), "%s catalog is missing key %s." % [locale, key])
		_validate_mission_links(locale)
	_assert(_t(&"hub.subtitle") == "PLAYABLE RESEARCH BUILDS", "English must remain a working alternate catalog.")
	_assert(_t(&"hub.options.quit") == "Quit Game", "English must localize the chapter Options quit action.")
	_assert(_t(&"terminology.button") == "Handbook", "The English bottom-right handbook entry must use the concise shared tool-button label.")
	_assert(_t(&"hub.locality.title") == "CHAPTER 2: REDUCING DATA MOVEMENT", "The English hub must present the formal Chapter 2 identity.")
	_assert("v0.2" not in _t(&"hub.locality.eyebrow") and "v0.2" not in _t(&"hub.locality.open"), "The English Chapter 2 hub card must not regress to legacy-prototype identity copy.")
	_assert(_t(&"trace.playback.next_evidence") == "Next evidence" and _t(&"trace.playback.finish_now") == "Finish Trace", "The English Trace controls must preserve their evidence-navigation semantics.")
	_assert(_t(&"common.clock_period.label") == "Clock Period" and _t(&"common.clock_period.tooltip").contains("never simulation results"), "The English playback control must preserve the presentation-only Clock Period boundary.")
	_assert(_t(&"chapter2.status.first_experiment_one_change") == "Change only one lever in the first experiment; run and inspect it before combining solutions.", "The English capstone boundary must ask for one controlled first change without prescribing the lever.")
	_assert(_t(&"chapter2.capstone.history.raw_metrics", [642, 608, 32]) == "Total 642 cycles · CPU WAIT 608 cycles · Data requests 32", "The English pre-diagnosis History copy must expose only raw totals with all placeholders intact.")
	_assert(_t(&"chapter2.history.personal_best", [138, 104, 4, "1-line Cache"]) == "Personal best · 138 cycles · CPU WAIT 104 · Cost 4\n1-line Cache", "The English Personal Best copy must preserve all four evidence placeholders.")
	_assert(
		_t(&"chapter2.profiler.tree.schedule") == "Schedule evidence"
		and _t(&"chapter2.profiler.tree.pass", [2]) == "Pass 2"
		and _t(&"chapter2.profiler.tree.pass_group", [3, 2]) == "Work group 3 · Pass 2"
		and _t(&"chapter2.profiler.tree.schedule_event", [42, "far fetch"]) == "cycle 42 · far fetch"
		and _t(&"chapter2.profiler.event_schedule.pass", [2]) == "Schedule · Pass 2"
		and _t(&"chapter2.profiler.event_schedule.pass_group", [3, 2]) == "Schedule · Work group 3 · Pass 2",
		"The English Profiler schedule copy must preserve pass/work-group meaning and placeholder order."
	)
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

	var system_catalog = SystemCatalogType.new("locale-cpu", "locale-ram")
	var system_level: Dictionary = system_catalog.definition(&"assembly")
	var system_case: Dictionary = (system_level["cases"] as Array)[0]
	var system_topology = SystemTopologyType.new()
	system_topology.set_part(&"CPU", system_catalog.part(&"cpu_balanced"))
	system_topology.set_part(&"RAM", system_catalog.part(&"ram_balanced"))
	system_topology.set_part(&"BUS", system_catalog.part(&"bus_8"))
	system_topology.connect_required_routes()
	var system_program = SystemParserType.parse(system_level["program_source"])
	_set_locale("zh_CN")
	var chinese_system_trace = SystemCoreType.new().run(system_program, system_topology, [7], [8], String(system_case["name"]))
	_set_locale("en")
	var english_system_trace = SystemCoreType.new().run(system_program, system_topology, [7], [8], String(system_case["name"]))
	_assert(chinese_system_trace.canonical_signature() == english_system_trace.canonical_signature(), "Locale must not change system-chapter timing, diagnosis, or trace identity.")

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


func _validate_mission_page_structure() -> void:
	for level_id: StringName in MissionNarrativeCatalogType.HARDWARE_PAGES:
		var pages: Array = MissionNarrativeCatalogType.HARDWARE_PAGES[level_id]
		_assert(pages.size() >= 1 and pages.size() <= 4, "Hardware mission %s must use one to four useful narrative pages." % level_id)
	for page_mapping: Dictionary in [MissionNarrativeCatalogType.SYSTEM_PAGES, MissionNarrativeCatalogType.LOCALITY_PAGES]:
		for level_id: StringName in page_mapping:
			var pages: Array = page_mapping[level_id]
			_assert(pages.size() >= 1 and pages.size() <= 4, "Mission %s must use one to four useful narrative pages." % level_id)
	_assert(LinkedMissionTextType.TERM_COLOR == Color("50d5ff"), "Mission terms must use the shared Handbook accent color.")


func _validate_mission_links(locale: String) -> void:
	var handbook_script: Script = load("res://src/ui/terminology_handbook.gd")
	var levels: Array[Dictionary] = []
	for level_id: StringName in MissionNarrativeCatalogType.HARDWARE_PAGES:
		var keys: Array[StringName] = []
		for page: Dictionary in MissionNarrativeCatalogType.HARDWARE_PAGES[level_id]:
			keys.append(StringName(page[&"body"]))
		levels.append({"id": level_id, "keys": keys})
	for page_mapping: Dictionary in [MissionNarrativeCatalogType.SYSTEM_PAGES, MissionNarrativeCatalogType.LOCALITY_PAGES]:
		for level_id: StringName in page_mapping:
			var keys: Array[StringName] = []
			for key: StringName in page_mapping[level_id]:
				keys.append(key)
			levels.append({"id": level_id, "keys": keys})
	levels.append({"id": &"hardware_compact", "keys": [
		&"hardware.tutorial.prompt", &"hardware.challenge.description",
		&"hardware.challenge.hint", &"hardware.cases.truth_table_definition",
	]})
	for level: Dictionary in levels:
		var link_count: int = 0
		for key: StringName in level["keys"]:
			var source: String = _t(key)
			var term_ids: Array[StringName] = LinkedMissionTextType.linked_term_ids(source)
			link_count += term_ids.size()
			_assert("[[" not in LinkedMissionTextType.plain_text(source), "%s mission key %s has a malformed term link." % [locale, key])
			for term_id: StringName in term_ids:
				_assert(bool(handbook_script.call("has_term", term_id)), "%s mission key %s links to missing Handbook term %s." % [locale, key, term_id])
		_assert(link_count > 0, "%s mission %s must contain at least one highlighted Handbook link." % [locale, level["id"]])


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
