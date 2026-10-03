extends SceneTree
## These are synthetic public observations, not catalog answers or novice evidence.
## Only the pure policies are imported; no simulation/reference solver is consulted.
const Representation = preload("res://experiments/candidate_proxy/representation_policy.gd")
const Prediction = preload("res://experiments/candidate_proxy/prediction_policy.gd")
const Service = preload("res://experiments/candidate_proxy/service_policy.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func representation_observation() -> Dictionary:
	return {"accepted":false, "plan":[{"start":0,"end":20,"codec":"raw"}],
		"assets":[[1,2,3,4,9,9,9,9,9,9,9,9,5,6,7,8,10,11,12,13]],
		"orders":[[1,1,18], [0,4,8,12,16]]}

func prediction_observation() -> Dictionary:
	return {"goal_met":false, "observed_addresses":[0,4,8],
		"policy":{"rule":"stride","confidence":1,"lookahead":1,"cooldown":0},
		"control_ranges":{"rule":["off","stride","two_stride"],
			"confidence":[1,2,3],"lookahead":[1,2],"cooldown":[0,2]},
		"completed_runs":[{"metrics":{"wasted_prediction_bytes":0,"total_cycles":42}}]}

func poison(source: Dictionary) -> Dictionary:
	var out: Dictionary = source.duplicate(true)
	out["reference"] = {"accepted":true,"goal_met":true,"plan":[{"start":0,"end":1,"codec":"oracle"}]}
	out["answer"] = {"rule":"oracle","confidence":999}
	out["reference_solution"] = {"budget":0,"plan":["invalid"]}
	out["future_addresses"] = [400,4,400,4]
	out["future_metrics"] = {"wasted_prediction_bytes":99999,"total_cycles":0}
	out["future"] = {"accepted":true,"goal_met":true,"next_address":400}
	if out.has("completed_runs"):
		out.completed_runs[0]["reference"] = out.reference.duplicate(true)
		out.completed_runs[0].metrics["answer"] = out.answer.duplicate(true)
		out.completed_runs[0].metrics["future_metrics"] = out.future_metrics.duplicate(true)
	return out

func apply_proposal(observation: Dictionary, decision: Dictionary) -> void:
	if decision.action == "try_plan": observation.plan = decision.plan.duplicate(true)
	if decision.action == "try_policy": observation.policy = decision.policy.duplicate(true)
	if decision.action == "try_service": observation.draft = decision.plan.duplicate(true)

func evidence_boundary(script: Script, source: Dictionary, label: String) -> void:
	var honest: Variant = script.new()
	var attacked: Variant = script.new()
	var clean: Dictionary = source.duplicate(true)
	var tainted: Dictionary = poison(source)
	var stopped: bool = false
	for i: int in range(20):
		var clean_before: Dictionary = clean.duplicate(true)
		var tainted_before: Dictionary = tainted.duplicate(true)
		var one: Dictionary = honest.decide(clean)
		var two: Dictionary = attacked.decide(tainted)
		check(one == two, label+" ignores fake answer/reference/future at decision "+str(i))
		check(clean == clean_before and tainted == tainted_before, label+" leaves observation dictionaries unchanged")
		if stopped: check(one.action == "stop", label+" remains stopped without new public evidence")
		if one.action == "stop": stopped = true
		apply_proposal(clean,one)
		apply_proposal(tainted,two)
	check(stopped, label+" reaches stop within a finite public action stream")

func decision_budget(script: Script, source: Dictionary, label: String) -> void:
	var policy: Variant = script.new()
	var observation: Dictionary = source.duplicate(true)
	var seen_proposals: Array = []
	var measured: int = 0
	var hints: int = 0
	var stopped: bool = false
	for i: int in range(30):
		var action: Dictionary = policy.decide(observation)
		if action.action == "run" or action.action == "try_plan" or action.action == "try_policy" or action.action == "try_service":
			measured += 1
			check(not stopped,label+" never starts a trial after stopping")
		if action.action == "hint1": hints += 1
		if action.action == "try_plan" or action.action == "try_policy" or action.action == "try_service":
			var proposal: Variant = action.get("plan",action.get("policy",{}))
			check(not seen_proposals.has(proposal),label+" does not retry the same proposal")
			seen_proposals.append(proposal.duplicate(true))
		if action.action == "stop": stopped = true
		apply_proposal(observation,action)
	check(measured > 1 and measured <= int(script.BUDGET),label+" actual run/edit trials obey its published budget")
	check(hints == 1,label+" first hint is requested at most once")
	check(stopped,label+" finite budget cannot spin forever on failure")

func ready(script: Script, observation: Dictionary) -> Variant:
	var policy: Variant = script.new()
	check(policy.decide(observation).action == "run","first action measures the public starter")
	check(policy.decide(observation).action == "hint1","first hint follows the initial measurement")
	return policy

func has_region(hypotheses: Array, begin: int, end: int, codec: String = "") -> bool:
	for candidate: Dictionary in hypotheses:
		for region: Dictionary in candidate.plan:
			if region.start == begin and region.end == end and (codec.is_empty() or region.codec == codec):
				return true
	return false

func representation_bytes() -> void:
	var policy: Variant = Representation.new()
	var public: Dictionary = representation_observation()
	var before: Dictionary = public.duplicate(true)
	var first: Array = policy.hypotheses(public.assets,public.orders)
	check(public == before,"byte-derived hypothesis enumeration does not mutate public arrays")
	check(has_region(first,4,12,"rle"),"visible eight-byte equal run supplies an encoded region")
	var moved: Array = [[1,2,3,4,5,6,7,9,9,9,9,9,9,9,9,8,10,11,12,13]]
	var second: Array = policy.hypotheses(moved,public.orders)
	check(has_region(second,7,15,"rle"),"moving the public run moves the proposed region")
	check(not has_region(second,4,12),"old byte boundary is not retained as an answer template")
	var varied: Array = public.assets.duplicate(true)
	varied.append([1,2,3,4,5,6,7,8,9,10,11,12,5,6,7,8,10,11,12,13])
	check(has_region(policy.hypotheses(varied,public.orders),4,12,"raw"),"one varying asset prevents treating a shared region as universally compressible")
	check(has_region(first,18,19),"public sparse requested address motivates an isolated byte")
	check(has_region(policy.hypotheses(public.assets,[[2,2,17]]),17,18),"changing public requests moves the requested byte region")
	check(policy.hypotheses([],[]).is_empty(),"missing public bytes produces no byte hypothesis")
	check(policy.hypotheses([[1,2],[1]],[]).is_empty(),"unequal visible asset lengths produce no partition")
	var clean_policy: Variant = ready(Representation,public)
	var untouched: Variant = ready(Representation,public)
	var decision: Dictionary = clean_policy.decide(public)
	var same: Dictionary = untouched.decide(public)
	check(decision.action == "try_plan","public bytes produce a bounded plan proposal")
	decision.plan[0].codec = "oracle"
	decision.plan[0].end = -1
	check(clean_policy.decide(public) == untouched.decide(public),"caller mutation of returned plan cannot alter subsequent decisions")
	check(same.plan[0].end == 20 and public == before,"returned plan is detached from other policy instances and source")

func prediction_evidence() -> void:
	var public: Dictionary = prediction_observation()
	var before: Dictionary = public.duplicate(true)
	var no_waste: Variant = ready(Prediction,public)
	var observed_waste: Dictionary = public.duplicate(true)
	observed_waste.completed_runs[0].metrics.wasted_prediction_bytes = 32
	var waste_policy: Variant = ready(Prediction,observed_waste)
	var ordinary: Dictionary = no_waste.decide(public)
	var cautious: Dictionary = waste_policy.decide(observed_waste)
	check(ordinary.action == "try_policy" and cautious.action == "try_policy","both public completed histories allow actionable hypotheses")
	check(cautious.policy != ordinary.policy,"already completed wasted traffic may change the next hypothesis")
	check(cautious.policy.confidence > public.policy.confidence or cautious.policy.cooldown > public.policy.cooldown,"observed failed speculation motivates a stricter gate or pause")
	check(public == before,"reading completed measurements does not mutate receipt data")
	var future_only: Dictionary = poison(public)
	future_only["active_run"] = {"metrics":{"wasted_prediction_bytes":32}}
	future_only["pending_run"] = {"metrics":{"wasted_prediction_bytes":32}}
	var future_policy: Variant = ready(Prediction,future_only)
	var clean_policy: Variant = ready(Prediction,public)
	check(future_policy.decide(future_only) == clean_policy.decide(public),"uncompleted/future metrics cannot substitute for completed evidence")
	var absent: Dictionary = public.duplicate(true)
	absent.completed_runs = []
	var absent_policy: Variant = ready(Prediction,absent)
	check(absent_policy.decide(absent).action == "try_policy","policy can compare public controls before a completed result exists")
	var left: Variant = ready(Prediction,observed_waste)
	var right: Variant = ready(Prediction,observed_waste)
	var detached: Dictionary = left.decide(observed_waste)
	right.decide(observed_waste)
	detached.policy.confidence = -1
	check(left.decide(observed_waste) == right.decide(observed_waste),"returned policy mutations cannot affect subsequent decisions")
	var unavailable: Dictionary = public.duplicate(true)
	unavailable.control_ranges = {}
	var unavailable_policy: Variant = ready(Prediction,unavailable)
	check(unavailable_policy.decide(unavailable).action == "stop","no visible controls stops policy without inventing actions")

func service_observation() -> Dictionary:
	return {"accepted":false,"draft":{"groups":[[0],[2],[1],[3]],"representations":["raw64","raw64"],"slots":1},"rules":{"stream_steps":2},"slot_range":[1,4],"formats":["raw64","rle64","raw8","rle8"],"public_data":[{"initial":[0.2,0.2],"requests":[{"values":[0.1,0.1]}]},{"initial":[0.1,0.4],"requests":[{"values":[0.4,0.9]}]}]}

func run() -> void:
	evidence_boundary(Representation,representation_observation(),"Representation")
	evidence_boundary(Prediction,prediction_observation(),"Prediction")
	decision_budget(Representation,representation_observation(),"Representation")
	decision_budget(Prediction,prediction_observation(),"Prediction")
	evidence_boundary(Service,service_observation(),"Service")
	decision_budget(Service,service_observation(),"Service")
	representation_bytes()
	prediction_evidence()
	print("PASS: candidate policy %d checks" % checks if failures.is_empty() else "FAIL: candidate policy "+str(failures))
	quit(0 if failures.is_empty() else 1)
