extends SceneTree
const Model = preload("res://experiments/prediction/model.gd")
const Catalog = preload("res://experiments/prediction/catalog.gd")
const Predictor = preload("res://experiments/prediction/predictor.gd")
const Lab = preload("res://experiments/prediction/lab.tscn")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func policy(rule: String, confidence: int = 1, multiplier: int = 1, pause: int = 0) -> Dictionary:
	return {"rule":rule,"confidence":confidence,"lookahead":multiplier,"cooldown":pause}

func prefix_independence() -> void:
	var a := Predictor.new(); var b := Predictor.new()
	a.configure(policy("stride",2)); b.configure(policy("stride",2))
	for address: int in [0,4,8,12]: check(a.observe(address)==b.observe(address),"identical observed prefix same decisions")
	check(a.observe(16).guess != b.observe(32).guess,"different observation, not future, changes decision")
	var first: Dictionary = Catalog.scenario(0)
	var second: Dictionary = first.duplicate(true); second.addresses = [0,4,8,12,32,0,32,0]
	var one = Model.run(first,policy("stride")); var two = Model.run(second,policy("stride"))
	for i: int in 4: check(one.metrics.decisions[i]==two.metrics.decisions[i],"different suffix cannot alter prefix decision")
	var bounded := Predictor.new(); bounded.configure(policy("stride"))
	for i: int in 20: check(bounded.observe(i*4).history.size()<=8,"bounded history")

func costs(trace: Variant, label: String) -> void:
	var m: Dictionary = trace.metrics
	check(trace.passed and m.error=="",label+" valid outputs")
	check(m.total_cycles==m.lookup_cycles+m.compute_cycles+m.blocking_cycles+m.drain_cycles,label+" wall sum")
	check(m.blocking_cycles==m.queue_wait_cycles+m.fallback_cycles+m.inflight_wait_cycles,label+" blocking sum")
	check(m.traffic_bytes==m.prediction_bytes+m.demand_bytes,label+" byte sum")
	check(m.prediction_bytes==m.useful_prediction_bytes+m.wasted_prediction_bytes,label+" useful plus wasted")
	check(m.request_cycles/4==m.transfer_cycles/2 and m.request_cycles==m.traffic_bytes,label+" physical fetch units")
	check(m.peak_cache_bytes<=trace.cache_capacity_lines*4,label+" cache budget")
	for access: Dictionary in m.accesses:
		check(access.value==Catalog.value_at(int(access.address)),label+" authoritative output")
		check(access.cache_after.keys.size()<=trace.cache_capacity_lines and access.cache_after.used_bytes<=trace.cache_capacity_lines*4,label+" finite residency")
	var bus_end: int = -1
	for event: Variant in trace.events:
		if event.kind==&"request":
			check(event.cycle>=bus_end,label+" no overlapping bus requests"); bus_end=event.cycle+6
		if event.kind==&"prediction": check(not event.details.has("next_address"),label+" decision has no next-demand field")

func run() -> void:
	prefix_independence()
	var off = Model.run(Catalog.scenario(0),policy("off"))
	var stride = Model.run(Catalog.scenario(0),policy("stride"))
	check(off.metrics.total_cycles==150 and off.metrics.traffic_bytes==40,"independent regular Off arithmetic 10*(1+6+8)")
	check(stride.metrics.total_cycles==102 and stride.metrics.useful_prediction_bytes==32 and stride.metrics.wasted_prediction_bytes==4,"regular saves 8 demand fetches and wastes final prediction")
	var alternate_off = Model.run(Catalog.scenario(2),policy("off"))
	var alternate_bad = Model.run(Catalog.scenario(2),policy("stride"))
	var alternate_safe = Model.run(Catalog.scenario(2),policy("two_stride"))
	check(alternate_off.metrics.total_cycles==120,"independent two-hotspot Off arithmetic 12*9+2*6")
	check(alternate_bad.metrics.total_cycles>120 and alternate_bad.metrics.wasted_prediction_bytes>0 and alternate_bad.metrics.pollution_misses>0,"wrong guesses truly pollute cache and lose")
	check(alternate_safe.metrics.total_cycles==120 and alternate_safe.metrics.prediction_bytes==0,"cache-safe history rule suppresses redundant traffic")
	for task: int in 3:
		for rule: String in ["off","stride","two_stride"]:
			for count: int in [1,2,3]:
				for multiplier: int in [1,2]:
					for pause: int in [0,2]:
						var p: Dictionary = policy(rule,count,multiplier,pause)
						var trace = Model.run(Catalog.scenario(task),p)
						costs(trace,"task%d/%s/%d/%d/%d" % [task,rule,count,multiplier,pause])
						check(trace.canonical_signature()==Model.run(Catalog.scenario(task),p).canonical_signature(),"full deterministic Trace and metrics")
		for p: Dictionary in [policy("off"),policy("stride"),policy("two_stride"),policy("stride",2,1,2)]:
			var m: Dictionary = Model.run(Catalog.scenario(task),p).metrics
			print("CALIBRATION task",task," ",p," cycles=",m.total_cycles," traffic=",m.traffic_bytes," useful=",m.useful_prediction_bytes," waste=",m.wasted_prediction_bytes," pollution=",m.pollution_misses)
	var short: Dictionary = {"name":"short","addresses":[0,4,8],"compute_gap":0,"cache_slots":2}
	var matching = Model.run(short,policy("stride")); costs(matching,"matching in-flight")
	check(matching.metrics.inflight_matches==1 and matching.metrics.inflight_wait_cycles==5 and matching.metrics.drain_cycles==6,"matching demand coalesces with remainder and tail drains")
	short.addresses=[0,8,0]
	var wrong = Model.run(short,policy("stride")); costs(wrong,"wrong in-flight")
	check(wrong.metrics.queue_wait_cycles==0,"resident demand can consume while unrelated prediction remains in flight")
	short.addresses=[0,8,4]
	wrong=Model.run(short,policy("stride")); costs(wrong,"queued fallback")
	check(wrong.metrics.queue_wait_cycles==5 and wrong.metrics.fallback_cycles==18,"wrong in-flight costs remaining five plus real fallback")
	check(not Model.run(Catalog.scenario(0),policy("oracle")).passed,"unknown rule rejected")
	var malformed: Dictionary = policy("stride"); malformed.confidence="2"
	check(not Model.run(Catalog.scenario(0),malformed).passed,"string confidence rejected")
	malformed=policy("stride"); malformed.cooldown=2.5
	check(not Model.run(Catalog.scenario(0),malformed).passed,"fractional pause rejected")
	var bad_spec: Dictionary = Catalog.scenario(0); bad_spec.compute_gap=33
	check(not Model.run(bad_spec,policy("off")).passed,"unbounded compute rejected")
	bad_spec=Catalog.scenario(0); bad_spec.cache_slots="2"
	check(not Model.run(bad_spec,policy("off")).passed,"string cache slots rejected")
	short.addresses=[1]; check(not Model.run(short,policy("off")).passed,"unaligned demand rejected")
	var lab = Lab.instantiate(); root.add_child(lab); await process_frame
	var public: Dictionary = lab.public_observation()
	check(public.observed_addresses.is_empty() and public.completed_runs.is_empty(),"initial public API exposes no hidden stream or cost")
	lab.step_current(); public=lab.public_observation()
	check(public.observed_addresses==[0] and public.revealed_decisions.size()==1 and public.completed_runs.is_empty(),"Step exposes one observation and no future final metrics")
	for event: Variant in lab.active_trace.events:
		if int(event.details.step)>1: check(not public.revealed_decisions.has(event.details),"future decision absent from public whitelist")
	lab.run_current(); public=lab.public_observation()
	check(public.completed_runs.size()==1 and public.completed_runs[0].metrics.outputs.size()==10,"completed run unlocks observed results")
	var signature: String=lab.history[0].trace.canonical_signature()
	lab.rule.select(1); lab.edit_policy(); lab.run_current()
	check(lab.history[0].trace.canonical_signature()==signature and lab.goal_met(0),"history immutable and evidence goal follows actual regular win")
	public.completed_runs[0].metrics.total_cycles=-1
	check(lab.history[0].trace.metrics.total_cycles==150,"public dictionaries detached from receipts")
	for viewport: Vector2i in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size = viewport; lab.size = Vector2(viewport)
		for english: bool in [false,true]:
			lab.english = english; lab.task = 2; lab.build(); await process_frame; await process_frame
			check(lab.mission.get_global_rect().end.x <= viewport.x, "Bilingual mission wraps inside viewport")
			check(lab.events.get_global_rect().end.x <= viewport.x, "Evidence column remains inside viewport")
	lab.queue_free(); await process_frame
	print("PASS: prediction slice %d checks" % checks if failures.is_empty() else "FAIL: prediction slice "+str(failures))
	quit(0 if failures.is_empty() else 1)
