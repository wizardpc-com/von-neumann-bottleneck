extends SceneTree
## Root integration review: hand-derived bills and an algebraic numerical oracle.
const Region = preload("res://experiments/representation_region/model.gd")
const Prediction = preload("res://experiments/prediction/model.gd")
const Service = preload("res://experiments/service_plan/model.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures.append(why); push_error(why)
func run() -> void:
	var raw: RefCounted = Region.run(Region.orders(3)[0],[{"start":0,"end":64,"codec":"raw"}])
	var rle: RefCounted = Region.run(Region.orders(3)[0],[{"start":0,"end":64,"codec":"rle"}])
	check(raw.metrics.total_cycles == 81,"RAW short: directory request4+write4 + demand request4+68B+consume1")
	check(rle.metrics.total_cycles == 111,"RLE short: prepare4+64+9+4+8 then serve4+8+9+1")
	check(raw.metrics.total_traffic_bytes == 72 and rle.metrics.total_traffic_bytes == 80,"All-phase bytes include preparation, not just serving")
	var many_raw: RefCounted = Region.run(Region.orders(3)[1],[{"start":0,"end":64,"codec":"raw"}])
	var many_rle: RefCounted = Region.run(Region.orders(3)[1],[{"start":0,"end":64,"codec":"rle"}])
	check(many_raw.metrics.total_cycles == 8+8*136 and many_rle.metrics.total_cycles == 89+8*85,"One paid preparation amortizes over eight genuinely cold clients")
	var spec: Dictionary = {"name":"short-gap-oracle","addresses":[0,4,8],"compute_gap":0,"cache_slots":2}
	var prediction: RefCounted = Prediction.run(spec,{"rule":"stride","confidence":1,"lookahead":1,"cooldown":0})
	check(prediction.metrics.total_cycles == 26,"Causal short-gap timeline:7+7+6 then6-cycle final speculative drain")
	check(prediction.metrics.baseline_cycles == 21 and prediction.metrics.inflight_wait_cycles == 5 and prediction.metrics.drain_cycles == 6,"Speculation is not a free prefetch timing reward")
	check(prediction.metrics.traffic_bytes == 16 and prediction.metrics.wasted_prediction_bytes == 4,"Unconsumed final speculative bytes remain charged")
	var plan: Dictionary = Service.initial_plan(); plan.slots = 4
	var uncompressed: RefCounted = Service.run(plan)
	check(uncompressed.metrics.total_cycles == 20+480+576+72+176,"Independent complete RAW service bill")
	plan.representations = ["rle64","rle64","raw64","raw64"]
	var mixed: RefCounted = Service.run(plan)
	check(mixed.metrics.state_read_bytes+mixed.metrics.state_write_bytes == 4*13+4*66,"Repeated float vectors use13-byte records; varied raw vectors66-byte records")
	check(mixed.metrics.total_cycles == 1280 and mixed.metrics.max_error == 0.0,"Lossless mixed bill removes44 cycles without assigning a quality bonus")
	var weights: Array = [0.83,-0.41,0.17,0.06,-0.29,0.71,-0.13,0.37]
	for stream: int in 4:
		for step: int in 6:
			var score: float = 0.0
			for j: int in 8:
				var component: int = 0 if stream < 2 else j
				var h: float = pow(0.65,step+1)*float((stream*5+component*3)%13-6)/12.0
				for past: int in range(step+1):
					var x: float = float(((stream+2)*(component*7+5)+past*(component+3)*11)%31-15)/15.0
					h += 0.35*pow(0.65,step-past)*x
				score += h*weights[j]
				if step == 5: check(absf(h-mixed.metrics.final_states[stream][j])<0.000000001,"Persisted lossless state equals independent closed form")
			check(absf(score-mixed.metrics.outputs[stream*6+step])<0.000000001,"Service output equals independent closed form")
	var valid: PackedByteArray = Service.pack([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],"rle64")
	var malformed: PackedByteArray = valid.duplicate(); malformed[2] = 0
	check(Service.unpack(malformed,"rle64").is_empty(),"Zero-count word run cannot deserialize state")
	malformed = valid.duplicate(); malformed[0] = 7
	check(Service.unpack(malformed,"rle64").is_empty(),"Wrong word count rejected")
	malformed = valid.slice(0,valid.size()-1)
	check(Service.unpack(malformed,"rle64").is_empty(),"Truncated float word rejected")
	print("PASS: independent second-act content review ",checks if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
