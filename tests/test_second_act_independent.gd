extends SceneTree
## Integration review oracles: algebraic recurrence and closed-form byte/cycle bills.
const State = preload("res://experiments/intelligent_workload/state_model.gd")
const Plan = preload("res://experiments/representation/plan_model.gd")
const W = [0.83,-0.41,0.17,0.06,-0.29,0.71,-0.13,0.37]
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var baseline: RefCounted = State.run({"slots":1,"batch":1,"order":"round_robin","state_bits":32,"weight_bits":32,"reuse":true})
	var grouped: RefCounted = State.run({"slots":1,"batch":1,"order":"grouped","state_bits":32,"weight_bits":32,"reuse":true})
	var resident: RefCounted = State.run({"slots":4,"batch":1,"order":"round_robin","state_bits":32,"weight_bits":32,"reuse":true})
	# 24 updates (24 ops each), 24 commits + output transfers, 24 input requests,
	# 800 input+weight bytes, 48 state transfers/requests for round-robin single slot.
	check(baseline.metrics.total_cycles==1496,"Independent complete bill: 576+24+24+96+200+192+384=1496")
	check(baseline.metrics.traffic_bytes==2432,"Independent traffic: 768 inputs+32 weights+96 outputs+1536 state=2432")
	check(grouped.metrics.total_cycles==1016 and resident.metrics.total_cycles==1016,"Four reads/four writes replace 24/24: state bill is 96 not576 cycles")
	check(grouped.metrics.traffic_bytes==1152 and resident.metrics.traffic_bytes==1152,"Locality and capacity independently achieve 256 state bytes")
	check(grouped.metrics.all_streams_first_cycle>resident.metrics.all_streams_first_cycle,"Grouping delays other contexts even when total time is equal")
	for stream: int in 4:
		for step: int in 6:
			var score: float=0
			for j: int in 8:
				# Closed form of h_n = .65 h_(n-1) + .35 x_n; no call to State.update/reference.
				var h: float=pow(0.65,step+1)*float((stream*5+j*3)%13-6)/12.0
				for k: int in range(step+1):
					var x: float=float(((stream+2)*(j*7+5)+k*(j+3)*11)%31-15)/15.0
					h+=0.35*pow(0.65,step-k)*x
				score+=h*W[j]
				if step==5: check(absf(h-float(resident.metrics.final_states[stream][j]))<0.00000001,"Final backing store equals algebraic recurrence")
			check(absf(score-float(baseline.metrics.outputs[stream*6+step]))<0.00000001,"Output equals independent recurrence oracle")
	var plan: Array[Dictionary]=[{"start":0,"end":16,"codec":"rle"},{"start":16,"end":48,"codec":"raw"},{"start":48,"end":64,"codec":"rle"}]
	var scan: RefCounted=Plan.run(Plan.orders(0)[0],plan)
	var hot: RefCounted=Plan.run(Plan.orders(1)[0],plan)
	# Two RLE runs cost (2 header+2 pair+4 directory)=8 each; middle raw32+dir4=36.
	check(scan.metrics.stored_bytes==52 and scan.metrics.traffic_bytes==52,"Variable raw block has real directory; 8+36+8=52")
	check(scan.metrics.total_cycles==134,"Independent plan cost: request12+transfer52+decode6+consume64")
	check(hot.metrics.total_cycles==36 and hot.metrics.traffic_bytes==16,"Two compressed16B blocks fit32B and serve six requests: 8+16+6+6")
	var machine: Dictionary=Plan.orders(0)[0].duplicate(true); machine.bandwidth=8; machine.decoder=1
	var raw: RefCounted=Plan.run(machine,Plan.initial_plan())
	var compressed: RefCounted=Plan.run(machine,plan)
	check(raw.metrics.total_cycles<compressed.metrics.total_cycles,"Independent faster-link/slower-decode counterexample remains real")
	print("PASS: independent algebraic state and representation cost oracles" if failures.is_empty() else "FAIL: independent oracles")
	quit(0 if failures.is_empty() else 1)
