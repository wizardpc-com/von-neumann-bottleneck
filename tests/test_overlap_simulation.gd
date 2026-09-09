extends SceneTree
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
const Sim = preload("res://src/overlap_chapter/overlap_simulator.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	for id: String in Catalog.IDS:
		var answer: Dictionary = Catalog.reference_solution(id)
		var report: Dictionary = Catalog.evaluate(id, answer.board, answer.program)
		for trace: SimulationTrace in report.runs:
			print("MEASURE %s/%s %s" % [id, trace.test_name, JSON.stringify(trace.metrics)])
		_assert(report.passed, "Authored reference must meet every public workload: " + id)
		var repeated: Dictionary = Catalog.evaluate(id, answer.board, answer.program)
		for i: int in range(report.runs.size()):
			_assert(report.runs[i].canonical_signature() == repeated.runs[i].canonical_signature(), "Deterministic whole trace " + id)
	var task: Dictionary = Catalog.cases("buffers")[0]
	var serial: SimulationTrace = Sim.new().run(Catalog.serial_program(), Catalog.buffer_board(1), task)
	var overlap: SimulationTrace = Sim.new().run(Catalog.buffer_program(), Catalog.buffer_board(2), task)
	_assert(serial.passed and serial.metrics.total_cycles == 40, "Serial four-batch schedule must be 40 cycles.")
	_assert(overlap.passed and overlap.metrics.total_cycles == 28 and overlap.metrics.overlap == 12, "Two resources must actually overlap for 28 cycles, not sum busy time.")
	var early: SimulationTrace = Sim.new().run("fetch A 0\nconsume A", Catalog.buffer_board(1), task)
	_assert(early.metrics.error == "not_ready", "An issued request is not ready data.")
	var followed_error: SimulationTrace = Sim.new().run("# first batch\nfetch A 0\nconsume A\nidle\n", Catalog.buffer_board(1), task)
	_assert(followed_error.metrics.error_line == 3 and followed_error.metrics.total_cycles == 0, "Failure must retain the offending source line and stop before unfinished transfers complete.")
	var overwrite: SimulationTrace = Sim.new().run(Catalog.starter("backpressure"), Catalog.buffer_board(2), Catalog.cases("backpressure")[0])
	_assert(overwrite.metrics.error == "overwrite", "Fixed waits must expose overwriting an in-use buffer on the variable workload.")
	var disconnected: Dictionary = Catalog.buffer_board(2)
	disconnected.wires.erase(["A", 1, "COMPUTE", 1])
	_assert(not Sim.new().run(Catalog.buffer_program(), disconnected, task).passed, "Ready feedback wires are authoritative, not decoration.")
	var prefetched: Dictionary = Catalog.reference_solution("distance")
	var bad: SimulationTrace = Sim.new().run(Catalog.starter("distance"), prefetched.board, Catalog.cases("distance")[0])
	var good: SimulationTrace = Catalog.evaluate("distance", prefetched.board, prefetched.program).runs[0]
	_assert(bad.passed and bad.metrics.total_cycles > good.metrics.total_cycles and bad.metrics.transfer_busy > good.metrics.transfer_busy, "Over-eager prefetch must evict and refetch real data on the shared transfer engine.")
	_assert(Catalog.evaluate("synthesis", Catalog.cache_board(), Catalog.cache_program()).passed, "The merge accepts an alternative Cache design, not mandatory gadget completion.")
	var wider: Dictionary = Catalog.buffer_board(3)
	var bandwidth: Dictionary = Catalog.cases("synthesis")[1].duplicate(true)
	bandwidth.budget = 3
	var two: SimulationTrace = Sim.new().run(Catalog.buffer_program(), Catalog.buffer_board(2), bandwidth)
	var three: SimulationTrace = Sim.new().run(Catalog.buffer_program(), wider, bandwidth)
	_assert(two.metrics.total_cycles == 33 and three.metrics.total_cycles == 33, "A third buffer does not create extra bandwidth.")
	_assert(not Catalog.unlocked("synthesis", {"backpressure":true}, true), "Merge must require both skill branches.")
	if failures.is_empty(): print("PASS: deterministic overlap, backpressure, prefetch limits and alternative synthesis")
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
func _assert(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
