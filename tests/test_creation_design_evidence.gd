extends SceneTree
const Model = preload("res://experiments/creation/model.gd")
const Session = preload("res://experiments/creation/session.gd")
const Comparison = preload("res://experiments/creation/comparison.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func generation(examples: Array, seed: int = 17) -> Dictionary:
	var learned: Dictionary = Model.learn(examples,1,Model.default_machine())
	var result: Dictionary = Model.generate(learned.model,[0],12,seed,"max",Model.default_machine())
	result["training"] = {"cost":learned.cost,"events":learned.events.slice(0,16),"model_id":Model.identity(learned.model),"machine":Model.default_machine()}
	result["parent_work"] = ""
	return result

func run() -> void:
	var a: Dictionary = generation([[0,1,0,1,0,1]])
	var b: Dictionary = generation([[0,2,0,2,0,2]])
	var report: Dictionary = Comparison.compare(a,b)
	check(report.single and report.controlled_effect and report.first_difference == 1,"One fixed-seed passage intervention changes actual output")
	check(report.first_difference_evidence.shared_prefix and report.first_difference_evidence.a.context == [0] and report.first_difference_evidence.a.counts == [0,3,0,0] and report.first_difference_evidence.b.counts == [0,0,3,0],"First difference uses real recorded context and counts")
	check(not report.later_independent_causality,"Later feedback positions carry no independent causality claim")
	var receipt: Dictionary = Session.design_receipt(a,b)
	check(receipt.ok,"Full real recipes create a controlled design receipt")
	check(not Session.design_receipt(a,generation([[0,1,0,1,0,1]],18)).ok,"Seed-only exploration cannot certify structural design")
	var provenance_only: Dictionary = generation([[0,2,0,1,0]])
	check(not Session.design_receipt(generation([[0,1,0,2,0]]),provenance_only).ok,"Changed source with identical learned rows cannot certify structural change")
	var equal: Dictionary = generation([[0,1,0,1,0,1,0,1]])
	check(Session.design_receipt(a,equal).ok and not Comparison.compare(a,equal).controlled_effect,"Equal-output changed model is a valid observation without observed effect")
	var session = Session.new()
	check(session.open("user://design-evidence/session.json").get("writable",false),"Isolated design profile owned")
	session.generated = b.duplicate(true)
	check(session.save_work("Designed signal",receipt.receipt).ok,"Transactional Keep saves full controlled receipt")
	check(session.design_provenance().observed_change and session.design_provenance().source == Comparison.DESIGN_VERSION,"Saved provenance distinguishes observed controlled change")
	var saved: Dictionary = session.data.works[0].duplicate(true)
	var altered: Dictionary = session.data.duplicate(true)
	altered.supports.G2_intent.comparison.b.output[1] = 3
	check(not Session.decode(JSON.stringify(altered)).ok,"Receipt replay rejects fabricated output")
	altered = session.data.duplicate(true); altered.supports.G2_intent.comparison.version = "controlled-design-v2"
	var future: Dictionary = Session.decode(JSON.stringify(altered))
	check(not future.ok and future.error == "version" and future.readonly_works == session.data.works,"Unknown comparison version preserves works read-only")
	altered = session.data.duplicate(true); altered.supports.G2_intent.comparison["claim"] = true
	check(not Session.decode(JSON.stringify(altered)).ok,"Unknown receipt claims rejected")
	session.generated = generation([[0,3,0,3,0,3]])
	check(session.save_work("Later free choice").ok and session.design_provenance().observed_change,"Ordinary Keep preserves earlier controlled receipt")
	session.close()
	check(session.open("user://design-evidence/session.json").get("writable",false) and session.data.works[0] == saved and session.replay_work(0).get("matches",false),"Reopen preserves original immutable work and receipt")
	var legacy: Dictionary = session.data.duplicate(true); legacy.supports.G2_intent.erase("comparison")
	check(Session.decode(JSON.stringify(legacy)).ok,"Legacy confirmed choice remains readable without migration")
	session.data.model = a.recipe.model.duplicate(true); session.data.mode = "predict"
	check(session.begin_prediction("check-v2").ok and not session.prediction.seen,"New sealed check has independent unseen identity")
	check(not session.reveal_prediction().ok and session.prediction.prefix == [0,2],"New check cannot reveal truth before committing")
	while not session.prediction.finished:
		session.commit_prediction(); session.reveal_prediction()
	check(session.prediction.prefix.slice(11,14) == [1,0,3],"The independent check retains the trained BA-to-D exception family, without a hidden context-rule shift")
	session.complete("P3_check")
	check("check-v2" in session.data.seen_checks and "check-v1" not in session.data.seen_checks,"New check does not consume legacy check identity")
	# Restore real training snapshot to make the full profile internally valid.
	session.data.training = a.training.duplicate(true)
	check(Session.decode(JSON.stringify(session.data)).ok,"New sealed check support strictly replays")
	check(session.begin_prediction("check-v2").ok and session.prediction.seen,"Repeated sealed check marked seen")
	session.close()
	print("PASS: creation design evidence checks=",checks) if failures.is_empty() else print("FAIL: creation design evidence ",failures)
	quit(0 if failures.is_empty() else 1)
