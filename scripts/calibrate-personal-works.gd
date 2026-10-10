extends SceneTree
## Bounded QA measurement. Run only in the isolated verifier's QA user directory.
const Model = preload("res://experiments/creation/model.gd")
const Session = preload("res://experiments/creation/session.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
const Conditions = preload("res://experiments/creation/condition_examples.gd")
var errors: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok: errors.append(message)
	return ok

func accepted(result: Dictionary, operation: String) -> bool:
	return check(result.get("ok",false),operation+": "+str(result.get("error","")))

func round_report(session: RefCounted, kind: String) -> Dictionary:
	if not accepted(session.begin_prediction(kind),"begin "+kind): return {}
	var seen: bool = session.prediction.seen
	var identity: String = session.prediction.model_id
	var model: Dictionary = session.data.model.duplicate(true)
	var prefix: Array = session.prediction.prefix.duplicate()
	check(not session.reveal_prediction().get("ok",false) and session.prediction.prefix == prefix,"Truth cannot reveal before commit")
	var cost: Dictionary = {}
	while not session.prediction.finished:
		prefix = session.prediction.prefix.duplicate()
		var expected: Dictionary = Model.predict(model,prefix)
		var committed: Dictionary = session.commit_prediction()
		if not accepted(committed,"commit "+kind): return {}
		check(committed.symbol == expected.symbol and committed.context == expected.context and committed.counts == expected.counts,"Commit depends only on observed prefix")
		check(session.prediction.prefix == prefix,"Commit does not expose the next truth")
		var revealed: Dictionary = session.reveal_prediction()
		if not accepted(revealed,"reveal "+kind): return {}
		cost = revealed.cost.duplicate(true)
	check(Model.identity(session.data.model) == identity,"Reveal never retrains the frozen model")
	return {"kind":kind,"model_id":identity,"seen_check_at_start":seen,
		"hits":session.prediction.hits,"total":session.prediction.total,
		"accuracy":float(session.prediction.hits)/float(session.prediction.total),
		"revealed_source":session.prediction.prefix.duplicate(),
		"rows":session.prediction.rows.duplicate(true),"cost":cost,
		"scope":"Complete revealed finite QA stream; no universal generalization claim"}

func measure(order: int, profile: String) -> Dictionary:
	var session: RefCounted = Session.new()
	var opened: Dictionary = session.open("user://personal-works-calibration/"+profile+"/order-"+str(order)+"/session.json")
	if not accepted(opened,"open fresh order "+str(order)): return {}
	if not check(opened.get("empty",false) and opened.get("writable",false),"Calibration needs a fresh owned QA subprofile"):
		session.close(); return {}
	session.data.draft.machine = Conditions.machine(1)
	session.data.draft.examples = [Catalog.sample(5)]
	session.data.draft.order = order
	if not accepted(session.train(),"train order "+str(order)):
		session.close(); return {}
	var preparation: Dictionary = session.data.training.duplicate(true)
	var transport: Dictionary = session.transport(Catalog.source(2),"predictive")
	if not accepted(transport,"actual restoration order "+str(order)) or not accepted(session.set_mode("predict"),"connect prediction"):
		session.close(); return {}
	var rounds: Array = []
	for kind: String in ["practice-v2","check-v2","check-v2"]:
		rounds.append(round_report(session,kind))
	if rounds.size() == 3 and not rounds[1].is_empty() and not rounds[2].is_empty():
		check(not rounds[1].seen_check_at_start and rounds[2].seen_check_at_start,"Repeated check is labelled seen")
		check(rounds[1].rows == rounds[2].rows and rounds[1].cost == rounds[2].cost,"Repeated frozen check is deterministic")
	var memory_boundary: Dictionary = {}
	if not rounds[0].is_empty():
		var active: Dictionary = session.prediction.duplicate(true)
		var budget: int = int(rounds[0].cost.peak_bytes)-1
		session.data.draft.machine.memory_bytes = budget
		var refused: Dictionary = session.begin_prediction("practice-v2")
		check(not refused.get("ok",false) and refused.get("error","") == "memory_limit" and session.prediction == active,"Insufficient memory rejects new round and preserves prior evidence")
		memory_boundary = {"budget_bytes":budget,"required_bytes":refused.get("required_bytes",-1),"error":refused.get("error","")}
		session.data.draft.machine = Conditions.machine(1)
	session.complete("P3_check")
	check(session.save() == OK,"Measured sealed support saves in isolated profile")
	check(Session.decode(FileAccess.get_file_as_string(session.path)).get("ok",false),"Saved measured support strictly replays")
	var result: Dictionary = {"order":order,"machine":session.data.draft.machine.duplicate(true),
		"examples":session.data.model.examples.duplicate(true),"model":session.data.model.duplicate(true),
		"model_id":Model.identity(session.data.model),"canonical_model_bytes":Model.canonical_bytes(session.data.model).size(),
		"preparation":preparation,"transport":{"cost":transport.cost.duplicate(true),"lossless":transport.lossless},"rounds":rounds,"memory_boundary":memory_boundary}
	session.close()
	return result

func run() -> void:
	var evidence_dir: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="): evidence_dir = argument.trim_prefix("--evidence-dir=")
	if not check(not evidence_dir.is_empty(),"--evidence-dir is required"):
		push_error(str(errors)); quit(1); return
	var profile: String = str(Time.get_unix_time_from_system()).replace(".","-")+"-"+str(Time.get_ticks_usec())
	var rows: Array = []
	for order: int in [1,2]: rows.append(measure(order,profile))
	var comparison: Dictionary = {}
	if not rows[0].is_empty() and not rows[1].is_empty():
		comparison = {"changed_factor":"history order","same_machine":rows[0].machine == rows[1].machine,
			"same_examples":rows[0].examples == rows[1].examples,
			"canonical_model_byte_delta":rows[1].canonical_model_bytes-rows[0].canonical_model_bytes,
			"preparation_cycle_delta":rows[1].preparation.cost.total_cycles-rows[0].preparation.cost.total_cycles,
			"practice_hit_delta":rows[1].rounds[0].get("hits",0)-rows[0].rounds[0].get("hits",0),
			"check_hit_delta":rows[1].rounds[1].get("hits",0)-rows[0].rounds[1].get("hits",0),
			"scope":"Finite same-family examples; measured differences only, rare successors remain uncertain"}
	var report: Dictionary = {"version":"personal-works-calibration-v1","profile":profile,
		"orders":rows,"comparison":comparison,"checks":checks,"errors":errors,
		"engine":Engine.get_version_info(),"evidence_kind":"headless actual Session measurements"}
	check(DirAccess.make_dir_recursive_absolute(evidence_dir) == OK,"Create evidence directory")
	var file := FileAccess.open(evidence_dir.path_join("prediction-family.json"),FileAccess.WRITE)
	if check(file != null,"Write evidence JSON"):
		report.checks = checks; report.errors = errors.duplicate(); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("PASS: personal works calibration checks=",checks) if errors.is_empty() else push_error("FAIL: personal works calibration "+str(errors))
	quit(0 if errors.is_empty() else 1)
