extends SceneTree
const C = preload("res://experiments/service_plan/commissions.gd")
const M = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)

# Independent explicit constraints; deliberately does not consume catalog specs.
func expected(m: Dictionary, id: int) -> bool:
	if id < 0 or id > 2 or not str(m.error).is_empty(): return false
	if m.total_cycles > 1420 or m.first_stream_cycles.max() > 320: return false
	if id == 0: return m.plan.slots <= 1 and m.max_error <= 1e-9 and m.max_state_error <= 1e-9
	if id == 1: return m.final_backing_bytes <= 160 and m.max_error <= 1e-9 and m.max_state_error <= 1e-9
	return m.final_backing_bytes <= 64 and m.max_error <= 0.02 and m.max_state_error <= 0.02

func low_slot(tail_order: Array[int]) -> Dictionary:
	var p: Dictionary = M.initial_plan(); p.representations = ["rle64","rle64","raw64","raw64"]
	p.groups = [[0],[6],[12],[18]]
	for stream: int in tail_order:
		for step: int in range(1,6): p.groups.append([stream*6+step])
	return p

func run() -> void:
	var low: Dictionary = low_slot([0,1,2,3])
	var low_other: Dictionary = low_slot([3,0,1,2])
	var exact: Dictionary = M.initial_plan(); exact.slots = 4; exact.representations = ["rle64","rle64","raw64","raw64"]
	var compact: Dictionary = M.initial_plan(); compact.slots = 4; compact.representations = ["raw8","raw8","raw8","raw8"]
	var compact_other: Dictionary = compact.duplicate(true); compact_other.representations = ["rle8","rle8","rle8","rle8"]
	var grouped: Dictionary = M.initial_plan(); grouped.groups = []
	for request: int in 24: grouped.groups.append([request])
	var cases: Array[Dictionary] = [low,low_other,exact,compact,compact_other,grouped,M.initial_plan()]
	for plan: Dictionary in cases:
		var trace: RefCounted = M.run(plan)
		check(trace.passed,"Commission fixture executes existing model")
		var before: String = JSON.stringify(trace.metrics)
		for id: int in 3:
			check(C.accepted(trace.metrics,id) == expected(trace.metrics,id),"Independent public constraints agree with catalog")
			for en: bool in [false,true]:
				check(not C.feedback(trace.metrics,id,en).is_empty(),"Measured feedback exists in both languages")
		check(before == JSON.stringify(trace.metrics),"Catalog never modifies measured results")
		check(trace.canonical_signature() == M.run(plan).canonical_signature(),"Commission fixtures retain deterministic traces")
	var lm: Dictionary = M.run(low).metrics
	check(lm.total_cycles == 1412 and lm.first_stream_cycles == [78,147,227,318] and lm.final_backing_bytes == 158,"Low-slot fixture reproduces integration measurements")
	check(C.accepted(lm,0) and C.accepted(M.run(low_other).metrics,0),"Different one-slot schedules satisfy duty")
	check(C.accepted(M.run(exact).metrics,1) and C.accepted(lm,1),"Lossless archive accepts different schedules and residency")
	check(C.accepted(M.run(compact).metrics,2) and C.accepted(M.run(compact_other).metrics,2),"Compact archive accepts different real representations")
	check(not C.accepted(M.run(exact).metrics,0),"Four resident slots cannot pass one-slot duty")
	check(not C.accepted(M.run(grouped).metrics,0),"Single-slot throughput winner still fails first-response requirement")
	check(not C.accepted(M.run(compact).metrics,1),"Real approximate errors fail lossless handoff")
	check(not C.accepted(M.run(exact).metrics,2),"Exact archive can exceed compact handoff size")
	for id: int in 3:
		var boundary: Dictionary = lm.duplicate(true)
		boundary.total_cycles = 1420; boundary.all_streams_first_cycle = 320; boundary.first_stream_cycles = [320,320,320,320]
		boundary.max_error = 0.02 if id == 2 else 1e-9; boundary.max_state_error = boundary.max_error
		boundary.final_backing_bytes = 64 if id == 2 else 160
		check(C.accepted(boundary,id),"Exact inclusive public boundaries accepted")
		var mutations: Array[Dictionary] = [{"total_cycles":1421},{"all_streams_first_cycle":321,"first_stream_cycles":[321,320,320,320]},{"max_error":0.021 if id == 2 else 2e-9},{"max_state_error":0.021 if id == 2 else 2e-9}]
		var extra_slots: Dictionary = boundary.plan.duplicate(true); extra_slots.slots = 2
		mutations.append({"plan":extra_slots} if id == 0 else {"final_backing_bytes":65 if id == 2 else 161})
		for mutation: Dictionary in mutations:
			var altered: Dictionary = boundary.duplicate(true); altered.merge(mutation,true)
			check(not C.accepted(altered,id),"Each exceeded public requirement is rejected")
			for en: bool in [false,true]: check(C.feedback(altered,id,en).contains(" / "),"Failure feedback gives actual and limit")
	for key: String in ["error","plan","total_cycles","all_streams_first_cycle","first_stream_cycles","final_backing_bytes","max_error","max_state_error"]:
		var incomplete: Dictionary = lm.duplicate(true); incomplete.erase(key)
		check(not C.accepted(incomplete,0),"Incomplete metrics refused: "+key)
	for mutation: Dictionary in [{"error":"stream_dependency"},{"error":false},{"total_cycles":0},{"total_cycles":"1412"},{"max_error":NAN},{"max_state_error":INF},{"max_error":-1.0},{"first_stream_cycles":[78,147,227]},{"first_stream_cycles":[0,147,227,318]},{"all_streams_first_cycle":319},{"plan":{"slots":1.5}},{"plan":{"slots":0}},{"final_backing_bytes":-1}]:
		var wrong: Dictionary = lm.duplicate(true); wrong.merge(mutation,true)
		for id: int in 3: check(not C.accepted(wrong,id),"Wrong or nonfinite metrics cannot pass commission")
	var invalid: Dictionary = M.move(low,0,1)
	invalid.groups[0][0] = 1
	check(not C.accepted(M.run(invalid).metrics,0),"Real rejected model execution cannot qualify")
	for id: int in [-1,3,99]:
		check(C.spec(id).is_empty() and not C.accepted(lm,id),"Unknown commission ID refused")
		check(not C.feedback(lm,id,true).is_empty(),"Unknown ID feedback remains explicit")
	for id: int in 3:
		for en: bool in [false,true]:
			var text: String = C.briefing(id,en)
			check(text.contains("24") and text.contains("1420") and text.contains("320") and text.contains("512") and text.contains("flush"),"Bilingual briefing exposes unchanged machine and public constraints")
			check(text.contains("0.02" if id == 2 else "1e-9"),"Bilingual briefing exposes both quality tolerances")
			check(not C.title(id,en).is_empty(),"Bilingual title exists")
	print("PASS: test_service_commissions " if failures == 0 else "FAIL: test_service_commissions ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
