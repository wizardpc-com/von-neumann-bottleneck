extends SceneTree

const CatalogType = preload("res://src/system_lab/system_level_catalog.gd")
const ParserType = preload("res://src/system_lab/system_dsl_parser.gd")
const CoreType = preload("res://src/system_lab/system_simulation_core.gd")
const TopologyType = preload("res://src/system_lab/system_topology.gd")
const TraceType = preload("res://src/system_lab/system_trace.gd")
const ReceiptType = preload("res://src/system_lab/system_run_receipt.gd")

const COMPUTE_HEAVY_PROGRAM := """value = load(INPUT[0])
for step in range(32):
    value += 3
store(OUTPUT[0], value)"""

var failures: Array[String] = []
var catalog := CatalogType.new("player-cpu-source", "player-ram-source")
var core := CoreType.new()


func _init() -> void:
	_test_catalog_and_parser()
	_test_topology_authority()
	_test_exact_cycle_model()
	_test_cpu_speed_reversal()
	_test_bus_serialization_and_determinism()
	_test_bottleneck_categories()
	_test_receipts_and_completion_rules()
	if failures.is_empty():
		print("PASS: deterministic 8-bit system chapter simulation, topology, DSL, and bottleneck tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d system-lab simulation assertion(s) failed" % failures.size())
		quit(1)


func _test_catalog_and_parser() -> void:
	_assert(catalog.validation_errors().is_empty(), "Built-in system chapter content must validate.")
	_assert(
		catalog.level_ids() == [&"assembly", &"cpu_speed", &"ram_wait", &"bus_width", &"bottleneck"],
		"The chapter must expose the accepted five-level investigation order."
	)
	_assert(catalog.dependencies(&"bottleneck") == [&"bus_width"], "The final investigation must follow Bus evidence directly.")
	for level_id: StringName in catalog.level_ids():
		var program = ParserType.parse(String(catalog.definition(level_id).get("program_source", "")))
		_assert(program.is_valid(), "Default program for %s must parse." % level_id)
	var cpu_level: Dictionary = catalog.definition(&"cpu_speed")
	_assert(String(cpu_level.get("program_source", "")) == CatalogType.PROGRAM_SUM, "The CPU prediction must use the memory-heavy sum program.")
	var cpu_ids: Array[StringName] = []
	for cpu_part in catalog.parts_for_level(&"cpu_speed", &"cpu"):
		cpu_ids.append(cpu_part.id)
	_assert(cpu_ids == [&"cpu_eco", &"cpu_fast"], "The CPU prediction must compare the explicit Eco and Fast endpoints.")
	_assert(catalog.default_part_id(&"cpu_speed", &"cpu") == &"cpu_eco" and catalog.default_part_id(&"cpu_speed", &"ram") == &"ram_slow" and catalog.default_part_id(&"cpu_speed", &"bus") == &"bus_8", "The CPU prediction must start on Eco while holding slow RAM and Bus8 fixed.")
	for cpu_case: Dictionary in cpu_level.get("cases", []):
		_assert((cpu_case.get("input", []) as Array).size() == 8, "Every CPU prediction case must contain eight memory items.")
	var final_cases: Array = catalog.definition(&"bottleneck").get("cases", [])
	var final_names := PackedStringArray()
	var final_sizes: Array[int] = []
	for final_case: Dictionary in final_cases:
		final_names.append(String(final_case.get("name", "")))
		final_sizes.append((final_case.get("input", []) as Array).size())
	_assert(final_names == PackedStringArray(["final-4", "final-16", "final-64"]) and final_sizes == [4, 16, 64], "The final investigation must absorb the fixed 4/16/64 workload magnifier.")
	var invalid = ParserType.parse("for i in range(N):\n\tvalue = load(INPUT[i])")
	_assert(not invalid.is_valid(), "Tabs must remain invalid in the editable chapter DSL.")


func _test_topology_authority() -> void:
	var topology := _topology(&"cpu_balanced", &"ram_balanced", &"bus_8", false)
	_assert(not topology.is_valid(), "Selected parts without displayed routes must not simulate.")
	topology.connect_required_routes()
	_assert(topology.is_valid(), "The six exact typed routes must form a valid system topology.")
	_assert(
		not topology.connect_ports(&"CPU", &"request_out", &"RAM", &"request_in"),
		"Unsupported direct CPU-to-RAM wiring must be rejected."
	)
	var signature: String = topology.canonical_signature()
	var copy = topology.duplicate_topology()
	_assert(copy.canonical_signature() == signature, "Topology cloning must preserve deterministic identity.")
	copy.disconnect_ports(&"CPU", &"request_out", &"BUS", &"cpu_request_in")
	_assert(not copy.is_valid() and topology.is_valid(), "Disconnecting a displayed route must invalidate only the edited topology.")


func _test_exact_cycle_model() -> void:
	var definition: Dictionary = catalog.definition(&"assembly")
	var case: Dictionary = (definition["cases"] as Array)[0]
	var trace = core.run(
		ParserType.parse(definition["program_source"]),
		_topology(&"cpu_balanced", &"ram_balanced", &"bus_8"),
		_typed_int_array(case["input"]), _typed_int_array(case["expected"]), "assembly-a"
	)
	_assert(trace.passed and trace.output_data == [8], "Assembly program must load, wrap, and store the expected byte.")
	_assert(int(trace.metrics["total_cycles"]) == 22, "Assembly exact total must be 22 cycles.")
	_assert(int(trace.metrics["cpu_compute_cycles"]) == 2, "Balanced CPU add must cost two cycles.")
	_assert(int(trace.metrics["ram_service_cycles"]) == 16, "Two balanced RAM accesses must cost sixteen cycles.")
	_assert(int(trace.metrics["bus_control_cycles"]) == 2 and int(trace.metrics["bus_transfer_cycles"]) == 2, "Two Bus8 transactions must expose exact control and payload cycles.")
	_assert(int(trace.metrics["cpu_wait_cycles"]) == 20, "CPU wait must equal RAM plus Bus service.")
	_assert(int(trace.metrics["hardware_cost"]) == 27, "Hardware cost must sum the selected authored specs.")
	var wrap_case: Dictionary = (definition["cases"] as Array)[1]
	var wrap_trace = core.run(
		ParserType.parse(definition["program_source"]),
		_topology(&"cpu_balanced", &"ram_balanced", &"bus_8"),
		_typed_int_array(wrap_case["input"]), _typed_int_array(wrap_case["expected"]), "assembly-b"
	)
	_assert(wrap_trace.passed and wrap_trace.output_data == [0], "8-bit arithmetic must wrap 255 + 1 to zero.")


func _test_cpu_speed_reversal() -> void:
	var definition: Dictionary = catalog.definition(&"cpu_speed")
	var program = ParserType.parse(definition["program_source"])
	var eco_traces: Array = []
	var fast_traces: Array = []
	for case: Dictionary in definition["cases"]:
		var eco_trace = core.run(
			program,
			_topology(&"cpu_eco", &"ram_slow", &"bus_8"),
			_typed_int_array(case["input"]), _typed_int_array(case["expected"]), String(case["name"])
		)
		var fast_trace = core.run(
			program,
			_topology(&"cpu_fast", &"ram_slow", &"bus_8"),
			_typed_int_array(case["input"]), _typed_int_array(case["expected"]), String(case["name"])
		)
		_assert(eco_trace.passed and fast_trace.passed, "Both CPU endpoints must preserve the memory-heavy program's result.")
		_assert(int(eco_trace.metrics["total_cycles"]) == 158 and int(fast_trace.metrics["total_cycles"]) == 134, "Eco/Fast must take exactly 158/134 cycles per CPU prediction case.")
		_assert(int(eco_trace.metrics["cpu_wait_cycles"]) == 126 and int(fast_trace.metrics["cpu_wait_cycles"]) == 126, "A faster CPU must leave the 126-cycle memory wait unchanged.")
		_assert(int(eco_trace.metrics["cpu_compute_cycles"]) == 32 and int(fast_trace.metrics["cpu_compute_cycles"]) == 8, "Fast must cut CPU compute from 32 to 8 cycles while waiting remains fixed.")
		eco_traces.append(eco_trace)
		fast_traces.append(fast_trace)
	var eco_receipt = ReceiptType.new()
	eco_receipt.populate_from_traces(
		&"cpu_speed", eco_traces, catalog.test_set_signature(&"cpu_speed"),
		{&"cpu": &"cpu_eco", &"ram": &"ram_slow", &"bus": &"bus_8"}
	)
	var fast_receipt = ReceiptType.new()
	fast_receipt.populate_from_traces(
		&"cpu_speed", fast_traces, catalog.test_set_signature(&"cpu_speed"),
		{&"cpu": &"cpu_fast", &"ram": &"ram_slow", &"bus": &"bus_8"}
	)
	var eco_total: int = int(eco_receipt.metrics["total_cycles"])
	var fast_total: int = int(fast_receipt.metrics["total_cycles"])
	var improvement: float = float(eco_total - fast_total) / float(eco_total)
	_assert(eco_total == 316 and fast_total == 268, "The two-case CPU receipts must aggregate to exactly 316/268 cycles.")
	_assert(improvement > 0.0 and improvement < 0.20, "A four-times-faster arithmetic unit must improve this waiting workload by less than twenty percent overall.")


func _test_bus_serialization_and_determinism() -> void:
	var definition: Dictionary = catalog.definition(&"bus_width")
	var case: Dictionary = (definition["cases"] as Array)[0]
	var program = ParserType.parse(definition["program_source"])
	var bus2 = core.run(program, _topology(&"cpu_fast", &"ram_fast", &"bus_2"), _typed_int_array(case["input"]), _typed_int_array(case["expected"]), "bus-a")
	var bus4 = core.run(program, _topology(&"cpu_fast", &"ram_fast", &"bus_4"), _typed_int_array(case["input"]), _typed_int_array(case["expected"]), "bus-a")
	var bus8 = core.run(program, _topology(&"cpu_fast", &"ram_fast", &"bus_8"), _typed_int_array(case["input"]), _typed_int_array(case["expected"]), "bus-a")
	_assert(bus2.passed and bus4.passed and bus8.passed, "Every compatible Bus spec must preserve functional behavior.")
	_assert(
		[int(bus2.metrics["bus_segments_per_word"]), int(bus4.metrics["bus_segments_per_word"]), int(bus8.metrics["bus_segments_per_word"])] == [4, 2, 1],
		"Bus2/4/8 must serialize one byte into exactly four/two/one stages."
	)
	_assert(int(bus2.metrics["total_cycles"]) > int(bus4.metrics["total_cycles"]) and int(bus4.metrics["total_cycles"]) > int(bus8.metrics["total_cycles"]), "Narrower buses must deterministically take longer for the same program.")
	var repeat = core.run(program, _topology(&"cpu_fast", &"ram_fast", &"bus_2"), _typed_int_array(case["input"]), _typed_int_array(case["expected"]), "bus-a")
	_assert(repeat.canonical_signature() == bus2.canonical_signature(), "Identical system runs must produce identical complete traces.")


func _test_bottleneck_categories() -> void:
	var cpu_trace = core.run(ParserType.parse(COMPUTE_HEAVY_PROGRAM), _topology(&"cpu_eco", &"ram_fast", &"bus_8"), [1], [97], "compute-heavy")
	_assert(cpu_trace.bottleneck() == TraceType.BOTTLENECK_CPU, "Compute-heavy work on the Eco CPU must diagnose CPU.")

	var ram_level: Dictionary = catalog.definition(&"ram_wait")
	var ram_case: Dictionary = (ram_level["cases"] as Array)[0]
	var ram_trace = core.run(ParserType.parse(ram_level["program_source"]), _topology(&"cpu_fast", &"ram_slow", &"bus_8"), _typed_int_array(ram_case["input"]), _typed_int_array(ram_case["expected"]), "ram-a")
	_assert(ram_trace.bottleneck() == TraceType.BOTTLENECK_RAM, "Streaming loads from slow RAM must diagnose RAM.")

	var bus_level: Dictionary = catalog.definition(&"bus_width")
	var bus_case: Dictionary = (bus_level["cases"] as Array)[0]
	var bus_trace = core.run(ParserType.parse(bus_level["program_source"]), _topology(&"cpu_fast", &"ram_fast", &"bus_2"), _typed_int_array(bus_case["input"]), _typed_int_array(bus_case["expected"]), "bus-a")
	_assert(bus_trace.bottleneck() == TraceType.BOTTLENECK_BUS, "Copy traffic over Bus2 must diagnose Bus.")

	var final_level: Dictionary = catalog.definition(&"bottleneck")
	var final_case: Dictionary = (final_level["cases"] as Array)[0]
	var mixed_trace = core.run(ParserType.parse(final_level["program_source"]), _topology(&"cpu_eco", &"ram_fast", &"bus_2"), _typed_int_array(final_case["input"]), _typed_int_array(final_case["expected"]), "final-8")
	_assert(mixed_trace.bottleneck() == TraceType.BOTTLENECK_MIXED, "A balanced contribution split must diagnose mixed instead of inventing a winner.")


func _test_receipts_and_completion_rules() -> void:
	var level: Dictionary = catalog.definition(&"cpu_speed")
	var traces: Array = []
	for case: Dictionary in level["cases"]:
		traces.append(core.run(
			ParserType.parse(level["program_source"]),
			_topology(&"cpu_eco", &"ram_slow", &"bus_8"),
			_typed_int_array(case["input"]), _typed_int_array(case["expected"]), String(case["name"])
		))
	var eco_receipt = ReceiptType.new()
	eco_receipt.populate_from_traces(
		&"cpu_speed", traces, catalog.test_set_signature(&"cpu_speed"),
		{&"cpu": &"cpu_eco", &"ram": &"ram_slow", &"bus": &"bus_8"}
	)
	_assert(eco_receipt.all_passed and eco_receipt.total_cases == 2, "One official receipt must aggregate every fixed case.")
	_assert(not catalog.completion_status(&"cpu_speed", [eco_receipt]).complete, "One CPU observation must not satisfy a two-part comparison.")
	var fast_traces: Array = []
	for case: Dictionary in level["cases"]:
		fast_traces.append(core.run(
			ParserType.parse(level["program_source"]),
			_topology(&"cpu_fast", &"ram_slow", &"bus_8"),
			_typed_int_array(case["input"]), _typed_int_array(case["expected"]), String(case["name"])
		))
	var fast_receipt = ReceiptType.new()
	fast_receipt.populate_from_traces(
		&"cpu_speed", fast_traces, catalog.test_set_signature(&"cpu_speed"),
		{&"cpu": &"cpu_fast", &"ram": &"ram_slow", &"bus": &"bus_8"}
	)
	var uncontrolled_traces: Array = []
	for case: Dictionary in level["cases"]:
		uncontrolled_traces.append(core.run(
			ParserType.parse(level["program_source"]),
			_topology(&"cpu_fast", &"ram_balanced", &"bus_8"),
			_typed_int_array(case["input"]), _typed_int_array(case["expected"]), String(case["name"])
		))
	var uncontrolled_receipt = ReceiptType.new()
	uncontrolled_receipt.populate_from_traces(
		&"cpu_speed", uncontrolled_traces, catalog.test_set_signature(&"cpu_speed"),
		{&"cpu": &"cpu_fast", &"ram": &"ram_balanced", &"bus": &"bus_8"}
	)
	_assert(not catalog.completion_status(&"cpu_speed", [eco_receipt, uncontrolled_receipt]).complete, "Changing RAM while comparing CPU must not count as a controlled comparison.")
	_assert(catalog.completion_status(&"cpu_speed", [eco_receipt, fast_receipt]).complete, "Two distinct CPUs under one applied program must complete the comparison.")
	var changed_source_receipt = ReceiptType.new()
	changed_source_receipt.populate_from_traces(
		&"cpu_speed", fast_traces, "different-test-set",
		{&"cpu": &"cpu_fast", &"ram": &"ram_slow", &"bus": &"bus_8"}
	)
	_assert(not catalog.completion_status(&"cpu_speed", [eco_receipt, changed_source_receipt]).complete, "Evidence from another fixed test set must not unlock this level.")
	var final_level: Dictionary = catalog.definition(&"bottleneck")
	var final_traces: Array = []
	for case: Dictionary in final_level["cases"]:
		final_traces.append(core.run(
			ParserType.parse(final_level["program_source"]),
			_topology(&"cpu_eco", &"ram_fast", &"bus_2"),
			_typed_int_array(case["input"]), _typed_int_array(case["expected"]), String(case["name"])
		))
	var final_receipt = ReceiptType.new()
	final_receipt.populate_from_traces(
		&"bottleneck", final_traces, catalog.test_set_signature(&"bottleneck"),
		{&"cpu": &"cpu_eco", &"ram": &"ram_fast", &"bus": &"bus_2"}
	)
	_assert(not catalog.completion_status(&"bottleneck", [final_receipt], &"cpu").complete, "An unsupported diagnosis must fail without changing the trace.")
	_assert(catalog.completion_status(&"bottleneck", [final_receipt], final_receipt.diagnosed_bottleneck).complete, "The trace-derived diagnosis must complete the final level.")


func _topology(cpu_id: StringName, ram_id: StringName, bus_id: StringName, connect: bool = true) -> SystemTopology:
	var topology: SystemTopology = TopologyType.new()
	topology.set_part(TopologyType.CPU_ID, catalog.part(cpu_id))
	topology.set_part(TopologyType.RAM_ID, catalog.part(ram_id))
	topology.set_part(TopologyType.BUS_ID, catalog.part(bus_id))
	if connect:
		topology.connect_required_routes()
	return topology


func _typed_int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in values:
		result.append(int(value))
	return result


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
