extends SceneTree
const Catalog = preload("res://src/system_lab/system_level_catalog.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var c := Catalog.new()
	var fixed: Dictionary = {&"cpu":&"cpu_fast",&"ram":&"ram_slow",&"bus":&"bus_8"}
	var starter: SystemRunReceipt = c.replay_application(&"read_once",Catalog.PROGRAM_REPEATED,fixed)
	check(starter.all_passed and not c.completion_status(&"read_once",[starter]).complete,"Correct but repeated loads must miss the request goal")
	check(starter.case_metrics[0].memory_requests == 33,"N16 baseline includes 32 reads and final store")
	var source: String = Catalog.PROGRAM_REPEATED.replace("    value = load(INPUT[i])\n    acc += value\n    value = load(INPUT[i])","    value = load(INPUT[i])\n    acc += value")
	var solution: SystemRunReceipt = c.replay_application(&"read_once",source,fixed)
	check(solution.all_passed and c.completion_status(&"read_once",[solution]).complete,"Reuse must pass varied data, wraparound and each request cap")
	check(solution.case_metrics[0].memory_requests == 17,"N16 solution requires 17 requests")
	var alternate: String = Catalog.PROGRAM_SUM.replace("store(OUTPUT[0], acc)","acc += acc\nstore(OUTPUT[0], acc)")
	check(c.completion_status(&"read_once",[c.replay_application(&"read_once",alternate,fixed)]).complete,"A distinct equivalent program must qualify")
	check(not c.replay_application(&"read_once","acc = 16\nstore(OUTPUT[0], acc)",fixed).all_passed,"A constant answer cannot pass varied inputs")
	var compute_count: int = 0
	var move_count: int = 0
	var overlap_count: int = 0
	var good_compute: SystemRunReceipt
	var good_move: SystemRunReceipt
	for cpu: String in ["cpu_eco","cpu_balanced","cpu_fast"]:
		for ram: String in ["ram_slow","ram_balanced","ram_fast"]:
			for bus: String in ["bus_2","bus_4","bus_8"]:
				var parts: Dictionary = {&"cpu":StringName(cpu),&"ram":StringName(ram),&"bus":StringName(bus)}
				var a: SystemRunReceipt = c.replay_application(&"two_orders",Catalog.PROGRAM_CPU,parts)
				var b: SystemRunReceipt = c.replay_application(&"two_orders",Catalog.PROGRAM_COPY,parts)
				var a_ok: bool = c.completion_status(&"two_orders",[a]).progress == 1
				var b_ok: bool = c.completion_status(&"two_orders",[b]).progress == 1
				compute_count += int(a_ok); move_count += int(b_ok); overlap_count += int(a_ok and b_ok)
				if a_ok: good_compute = a
				if b_ok: good_move = b
	check(compute_count == 3 and move_count == 4 and overlap_count == 0,"Real 27-combination calibration must offer distinct multiple routes")
	check(not c.completion_status(&"two_orders",[good_compute,good_compute]).complete,"Repeating one order cannot satisfy both")
	check(c.completion_status(&"two_orders",[good_compute,good_move]).complete,"Each order may use its own accepted machine")
	var state: Node = root.get_node("SystemChapter")
	state.prologue_ready = true
	state.game_completed.clear()
	state.game_completed[&"ram_wait"] = true
	state.game_completed[&"bottleneck"] = true
	var saved: Dictionary = {"read_once":{"read":{"source":source,"parts":fixed}}}
	state._restore_application(&"read_once",saved,c)
	check(state.game_completed.has(&"read_once"),"Saved valid application is re-simulated before restoring completion")
	state.game_completed.erase(&"read_once")
	state.game_receipts.erase(&"read_once")
	saved.read_once.read.source = "acc = 16\nstore(OUTPUT[0], acc)"
	state._restore_application(&"read_once",saved,c)
	check(not state.game_completed.has(&"read_once"),"Altered saved programs cannot retain completion")
	for failure: String in failures: push_error(failure)
	print("PASS: application alternatives, per-case limits, budget enumeration and recovery" if failures.is_empty() else "FAIL: applications")
	quit(0 if failures.is_empty() else 1)
