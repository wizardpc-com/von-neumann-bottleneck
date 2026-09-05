class_name DemoPerformance
extends RefCounted

const SystemCatalog = preload("res://src/system_lab/system_level_catalog.gd")
const SystemCore = preload("res://src/system_lab/system_simulation_core.gd")
const SystemParser = preload("res://src/system_lab/system_dsl_parser.gd")
const Topology = preload("res://src/system_lab/system_topology.gd")
const LocalCore = preload("res://src/simulation/simulation_core.gd")
const Parser = preload("res://src/simulation/dsl_parser.gd")

const VERSION := "demo-performance-v1"
const STANDARD_SOURCE := "standard-system-v1"
const IDS := ["d1_cpu", "d1_upgrade", "d2_cache", "d2_order", "d2_group", "d2_final"]
const ROW_SOURCE := "acc = 0\nfor row in range(4):\n    for col in range(4):\n        acc += load(A[row][col])\nstore(OUT[0], acc)"
const COLUMN_SOURCE := "acc = 0\nfor col in range(4):\n    for row in range(4):\n        acc += load(A[row][col])\nstore(OUT[0], acc)"

static func is_system(id: String) -> bool:
	return id in ["d1_cpu", "d1_upgrade"]


static func initial(id: String, stage: int = 0) -> Dictionary:
	if is_system(id):
		return {"cpu": "cpu_eco" if stage == 0 else "cpu_fast", "ram": "ram_slow" if stage == 0 else "ram_fast", "bus": "bus_8" if stage == 0 else "bus_2", "source": SystemCatalog.PROGRAM_SUM if stage == 0 else SystemCatalog.PROGRAM_COPY, "provenance": STANDARD_SOURCE}
	return {"source": ROW_SOURCE if id in ["d2_cache", "d2_group"] else COLUMN_SOURCE, "cache": 2 if id == "d2_final" else 1, "group": 0, "bypass": id == "d2_cache", "provenance": "standard-locality-v1"}


static func choices(id: String, stage: int = 0) -> Dictionary:
	if id == "d1_cpu":
		return {"cpu": ["cpu_eco", "cpu_fast"]}
	if id == "d1_upgrade":
		return {"cpu": ["cpu_eco", "cpu_balanced", "cpu_fast"], "ram": ["ram_slow", "ram_balanced", "ram_fast"], "bus": ["bus_2", "bus_4", "bus_8"]}
	if id == "d2_cache":
		return {"bypass": [true, false]}
	if id == "d2_group":
		return {"group": [0, 1, 2, 4]}
	if id == "d2_final":
		return {"cache": [1, 2, 4], "group": [0, 1, 2, 4]}
	return {}


static func editable_program(id: String) -> bool:
	return id in ["d2_order", "d2_final"]


static func passes(id: String) -> int:
	return 2 if id in ["d2_group", "d2_final"] else 1


static func constraint_error(id: String, stage: int, design: Dictionary) -> String:
	if id not in IDS or stage < 0 or stage > (1 if id == "d1_upgrade" else 0):
		return "demo.error.task"
	var base := initial(id, stage)
	var allowed := choices(id, stage)
	if design.size() != base.size():
		return "demo.error.supply"
	for key: String in base:
		if not design.has(key):
			return "demo.error.supply"
		if key == "source" and editable_program(id):
			if not design[key] is String or design[key].length() > 8000:
				return "demo.error.program"
		elif allowed.has(key):
			if design[key] not in allowed[key]:
				return "demo.error.supply"
		elif design[key] != base[key]:
			return "demo.error.supply"
	if id == "d1_upgrade":
		var changed := 0
		for key: String in ["cpu", "ram", "bus"]:
			changed += int(design[key] != base[key])
		if changed > 1:
			return "demo.error.one_part"
	return ""


static func system_topology(design: Dictionary) -> SystemTopology:
	var catalog := SystemCatalog.new(STANDARD_SOURCE, STANDARD_SOURCE)
	var topology := Topology.new()
	for key: String in ["cpu", "bus", "ram"]:
		var part: SystemPartSpec = catalog.part(StringName(design[key]))
		if part == null:
			return topology
		part.source_signature = "%s/%s" % [STANDARD_SOURCE, part.id]
		part.metadata.erase("generated_from")
		part.metadata["origin"] = "standard"
		topology.set_part(StringName(key.to_upper()), part)
	topology.connect_required_routes()
	return topology


static func run(id: String, stage: int, design: Dictionary) -> Dictionary:
	design = design.duplicate(true)
	for key: String in ["cache", "group"]:
		if design.get(key) is float and is_equal_approx(design[key], float(int(design[key]))):
			design[key] = int(design[key])
	var error := constraint_error(id, stage, design)
	if not error.is_empty():
		return {"valid": false, "error": error}
	return _run_system(id, stage, design) if is_system(id) else _run_locality(id, design)


static func baseline(id: String, stage: int = 0) -> Dictionary:
	return run(id, stage, initial(id, stage))


static func _run_system(id: String, stage: int, design: Dictionary) -> Dictionary:
	var catalog := SystemCatalog.new(STANDARD_SOURCE, STANDARD_SOURCE)
	var cases: Array = catalog.definition(&"cpu_speed" if stage == 0 else &"bus_width")["cases"]
	if stage == 1:
		var alternate: Array[int] = [0, 255, 1, 128, 7, 64, 3, 17]
		cases.append({"name": "copy-alternate", "input": alternate, "expected": alternate.duplicate()})
	var program := SystemParser.parse(design["source"])
	var topology := system_topology(design)
	var traces: Array = []
	var passed := true
	for example: Dictionary in cases:
		var trace := SystemCore.new().run(program, topology, example["input"], example["expected"], example["name"])
		traces.append(trace)
		passed = passed and trace.passed
	var metrics: Dictionary = traces[0].metrics.duplicate(true)
	metrics["compute_cycles"] = metrics["cpu_compute_cycles"]
	metrics["wait_cycles"] = metrics["cpu_wait_cycles"]
	var achieved := false
	if id == "d1_cpu":
		achieved = design["cpu"] != initial(id)["cpu"]
	else:
		# Thresholds are calibrated by the unchanged sequential cost model.
		achieved = int(metrics["total_cycles"]) <= (100 if stage == 0 else 96)
	return _receipt(id, stage, design, cases, traces, metrics, passed, achieved)


static func locality_cases() -> Array[Array]:
	var result: Array[Array] = [LocalCore.official_data_copy()]
	var negative: Array[int] = []
	for index: int in range(16):
		negative.append(-index - 1)
	result.append(negative)
	# The bounded DSL is linear in input values. Basis cases also catch a constant
	# result that coincidentally matches the displayed example.
	for address: int in range(16):
		var basis: Array[int] = []
		basis.resize(16)
		basis.fill(0)
		basis[address] = 1
		result.append(basis)
	return result


static func _run_locality(id: String, design: Dictionary) -> Dictionary:
	var program := Parser.parse(design["source"])
	if not program.is_valid():
		return {"valid": false, "error": "demo.error.program", "diagnostics": program.error_specs}
	var traces: Array = []
	var passed := true
	var examples := locality_cases()
	var failure_case := -1
	var failure_reason := ""
	for index: int in range(examples.size()):
		var data: Array[int] = []
		data.assign(examples[index])
		var trace := LocalCore.new().run_workload(program, data, int(design["cache"]), "demo-data-%d" % index, passes(id), int(design["group"]), bool(design["bypass"]))
		traces.append(trace)
		var work_valid := _valid_work(trace, passes(id))
		if (not trace.passed or not work_valid) and failure_case < 0:
			failure_case = index
			failure_reason = "demo.wrong_output" if not trace.passed else "demo.wrong_work"
		passed = passed and trace.passed and work_valid
	var metrics: Dictionary = traces[0].metrics.duplicate(true)
	var achieved := false
	match id:
		"d2_cache":
			achieved = int(metrics.get("cache_hits", 0)) > 0 and int(metrics.get("cache_misses", 0)) > 0
		"d2_order":
			achieved = int(metrics.get("total_cycles", 99999)) <= 110
		"d2_group", "d2_final":
			achieved = int(metrics.get("total_cycles", 99999)) <= 145
	var receipt := _receipt(id, 0, design, examples, traces, metrics, passed, achieved)
	receipt["display_case"] = maxi(0, failure_case)
	receipt["failure_reason"] = failure_reason
	return receipt


static func _valid_work(trace: SimulationTrace, pass_count: int) -> bool:
	var counts: Dictionary = {}
	var stores := 0
	for event: SimulationEvent in trace.events:
		if event.kind == &"request":
			var key := "%d:%d" % [int(event.details.get("pass_index", 0)), event.address]
			counts[key] = int(counts.get(key, 0)) + 1
		if event.kind == &"store_result":
			stores += 1
			if event.value != trace.expected_value:
				return false
	if counts.size() != 16 * pass_count or stores != pass_count:
		return false
	for pass_index: int in range(pass_count):
		for address: int in range(16):
			if counts.get("%d:%d" % [pass_index, address], 0) != 1:
				return false
	return true


static func _receipt(id: String, stage: int, design: Dictionary, cases: Array, traces: Array, metrics: Dictionary, passed: bool, achieved: bool) -> Dictionary:
	var signatures: Array[String] = []
	for trace: Variant in traces:
		signatures.append(trace.canonical_signature().sha256_text())
	var identity := JSON.stringify([VERSION, id, stage, cases, "cold-zero-initial-state"]).sha256_text()
	return {"valid": true, "passed": passed, "complete": passed and achieved, "task": id, "stage": stage, "identity": identity, "design": design.duplicate(true), "metrics": metrics, "traces": traces, "signature": JSON.stringify([identity, design, signatures]).sha256_text(), "case_count": cases.size()}
