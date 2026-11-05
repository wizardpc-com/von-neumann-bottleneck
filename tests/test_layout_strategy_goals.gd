extends SceneTree
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for goal checks.")
		quit(1)
		return
	_normalization()
	_ready_envelopes()
	_copy_envelopes()
	_ties_and_isolation()
	_invalid_measurements()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy goals %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _goal(first: int = -1, copy: int = -1, objective: String = "cycles") -> Dictionary:
	return {"objective":objective,"first_limit":first,"copy_limit":copy}

func _row(id: String, task: Dictionary, group: int = 1, fields: Array = []) -> Dictionary:
	var plan: Dictionary = Model.starter_plan()
	plan.query_group = group
	plan.record_tile = 1
	if not fields.is_empty():
		plan.copy_mode = "full"
		plan.copy_fields = fields.duplicate()
	var measured: Dictionary = Model.evaluate(task,plan)
	check(measured.valid and measured.run != null,"Actual model returned a trace for "+id)
	if not measured.valid or measured.run == null: return {}
	var trace: LayoutRun = measured.run
	return {
		"id":id,"task_id":task.id,"plan":plan,"condition_id":trace.case_signature,
		"trace_id":trace.canonical_signature().sha256_text(),
		"metrics":trace.metrics.duplicate(true),"correct":trace.passed,
		"extra":{"name":"Retain "+id},
	}

func _by_id(rows: Array[Dictionary], id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.id == id: return row
	return {}

func _normalization() -> void:
	check(Goals.default_goal() == _goal(),"New goals impose no extra cap")
	check(Goals.normalize(_goal(0,0)) == _goal(0,0),"Zero is a real response/space cap")
	check(Goals.normalize(_goal(Goals.MAX_LIMIT,Goals.MAX_LIMIT,"traffic")) == _goal(Goals.MAX_LIMIT,Goals.MAX_LIMIT,"traffic"),"Declared finite upper limits are accepted")
	var numeric: Dictionary = {"copy_limit":80.0,"first_limit":557.0,"objective":"traffic"}
	check(Goals.normalize(numeric) == _goal(557,80,"traffic"),"Integral JSON numbers normalize without losing limits")
	for key: String in ["objective","first_limit","copy_limit"]:
		var missing: Dictionary = _goal()
		missing.erase(key)
		check(Goals.normalize(missing).is_empty(),"Missing goal field rejected: "+key)
	var extra: Dictionary = _goal()
	extra["score"] = 1
	check(Goals.normalize(extra).is_empty(),"Extra claimed score is not a goal field")
	for value: Variant in ["first","",1,null]:
		var goal: Dictionary = _goal()
		goal.objective = value
		check(Goals.normalize(goal).is_empty(),"Unknown objective rejected: "+str(value))
	for value: Variant in [-2,Goals.MAX_LIMIT+1,1.5,INF,NAN,true,"80",null]:
		for key: String in ["first_limit","copy_limit"]:
			var goal: Dictionary = _goal()
			goal[key] = value
			check(Goals.normalize(goal).is_empty(),"Invalid finite integer cap rejected: "+key+"/"+str(value))
	var condition: String = Model.condition_id(Model.scenario("scan_batch"))
	var identity: String = Goals.rule_id(condition,_goal(557,80,"traffic"))
	check(identity.length() == 64 and identity == Goals.rule_id(condition,numeric),"Rule identity survives normalized dictionary/number ordering")
	check(identity != Goals.rule_id(condition,_goal(556,80,"traffic")),"Q1 limit is part of goal identity")
	check(identity != Goals.rule_id(condition,_goal(557,79,"traffic")),"Copy limit is part of goal identity")
	check(identity != Goals.rule_id(condition,_goal(557,80,"cycles")),"Objective is part of goal identity")
	check(identity != Goals.rule_id(Model.condition_id(Model.scenario("scan_serial")),_goal(557,80,"traffic")),"Full simulation condition is part of goal identity")
	check(Goals.rule_id(condition,_goal(-1,0)) != Goals.rule_id(condition,_goal(-1,-1)),"Zero and unrestricted space have different identities")
	check(Goals.rule_id("",_goal()).is_empty() and Goals.rule_id(condition,extra).is_empty(),"Invalid rule identity is unavailable")

func _ready_envelopes() -> void:
	var task: Dictionary = Model.scenario("scan_batch")
	var condition: String = Model.condition_id(task)
	var rows: Array[Dictionary] = [
		_row("direct",task),_row("group2",task,2),
		_row("group3",task,3),_row("group8",task,8),
	]
	var ranked: Array[Dictionary] = Goals.rank(rows,condition,_goal())
	check(ranked[0].id == "group8" and ranked[0].metrics.total_cycles == 552,"Unrestricted measured total favors the real fused run")
	ranked = Goals.rank(rows,condition,_goal(350,0))
	check(ranked[0].id == "group2" and ranked[0].rank == 1 and ranked[0].metrics.total_cycles == 1368,"A350-cycle envelope changes the feasible winner")
	check(_by_id(ranked,"group3").exclusions == ["first"] and _by_id(ranked,"group8").rank == 0,"Faster overall results cannot evade response limits")
	ranked = Goals.rank(rows,condition,_goal(400,0))
	check(ranked[0].id == "group3" and ranked[0].metrics.total_cycles == 1096,"Expanded real group3 remains discoverable")
	check(_by_id(Goals.rank(rows,condition,_goal(339,0)),"group2").eligible,"Q1 cap includes its exact measured boundary")
	check(not _by_id(Goals.rank(rows,condition,_goal(338,0)),"group2").eligible,"One cycle below excludes that run")
	ranked = Goals.rank(rows,condition,_goal(0,-1))
	check(ranked.all(func(row: Dictionary) -> bool: return not row.eligible and row.rank == 0),"Zero Q1 produces an honest empty feasible set")
	check(ranked[0].id == "direct" and ranked[1].id == "group2","Unranked results preserve observation order")
	ranked = Goals.rank(rows,condition,_goal(-1,0,"traffic"))
	check(ranked[0].id == "group8" and ranked[0].metrics.ram_read_bytes == 272,"Traffic objective uses actual read/write totals")

func _copy_envelopes() -> void:
	var task: Dictionary = Model.scenario("scan_serial")
	var condition: String = Model.condition_id(task)
	var rows: Array[Dictionary] = [
		_row("direct",task),_row("retained",task,1,[0]),_row("too_large",task,1,[0,1,2,3]),
	]
	var ranked: Array[Dictionary] = Goals.rank(rows,condition,_goal(557,80))
	check(ranked[0].id == "retained" and ranked[0].metrics.total_cycles == 1362,"Inclusive557/80 admits actual retained-copy tradeoff")
	var failed: Dictionary = _by_id(ranked,"too_large")
	check(not failed.eligible and failed.rank == 0 and "incomplete" in failed.exclusions,"Failed zero-cycle allocation cannot win")
	ranked = Goals.rank(rows,condition,_goal(557,79))
	check(ranked[0].id == "direct" and _by_id(ranked,"retained").exclusions == ["copy"],"One byte below real copy peak excludes it")
	ranked = Goals.rank(rows,condition,_goal(556,80))
	check(ranked[0].id == "direct" and _by_id(ranked,"retained").exclusions == ["first"],"Copy preparation cannot bypass Q1")
	ranked = Goals.rank(rows,condition,_goal(556,0))
	check(_by_id(ranked,"retained").exclusions == ["first","copy"],"Both independent violated caps remain visible")
	check(Goals.rank(rows,condition,_goal(-1,0))[0].id == "direct","Zero copy means source-only")
	check(Goals.rank(rows,condition,_goal(-1,-1,"traffic"))[0].id == "retained","Unrestricted traffic comparison includes true copy traffic")

func _ties_and_isolation() -> void:
	var task: Dictionary = Model.scenario("scan_batch")
	var condition: String = Model.condition_id(task)
	var rows: Array[Dictionary] = [
		_row("later_first",task,7),_row("earlier_first",task,4),_row("direct",task),
	]
	check(rows[0].metrics.total_cycles == rows[1].metrics.total_cycles and rows[0].metrics.first_request_cycles > rows[1].metrics.first_request_cycles,"Real distinct response plans tie on total work")
	var original: Array[Dictionary] = rows.duplicate(true)
	var ranked: Array[Dictionary] = Goals.rank(rows,condition,_goal())
	check(ranked[0].id == "later_first" and ranked[1].id == "earlier_first","Objective tie retains original order without a Q1 tiebreak")
	check(ranked[0].rank == 1 and ranked[1].rank == 1 and ranked[2].rank == 3,"Competition ranks are1,1,3")
	check(ranked[0].extra == rows[0].extra and ranked[0].trace_id == rows[0].trace_id,"Ranking preserves unrelated measurement metadata")
	ranked[0].metrics.total_cycles = 0
	ranked[0].plan.copy_fields.clear()
	ranked[0].extra.name = "changed"
	check(rows == original,"Ranking returns fully detached rows")
	rows.append(_row("serial",Model.scenario("scan_serial")))
	ranked = Goals.rank(rows,condition,_goal())
	check(_by_id(ranked,"serial").exclusions == ["condition"] and _by_id(ranked,"serial").rank == 0,"Equal-looking metrics from another condition never rank")
	var invalid: Dictionary = _goal()
	invalid.first_limit = -2
	ranked = Goals.rank(rows,condition,invalid)
	check(ranked.all(func(row: Dictionary) -> bool: return not row.eligible and "invalid" in row.exclusions),"Invalid goal never silently removes a cap")
	check(Goals.rank([],condition,_goal()).is_empty(),"Empty observations remain empty")

func _invalid_measurements() -> void:
	var task: Dictionary = Model.scenario("scan_batch")
	var condition: String = Model.condition_id(task)
	var original: Dictionary = _row("source",task)
	var rows: Array[Dictionary] = []
	var mutations: Array[Dictionary] = [
		{"id":"negative_traffic","key":"ram_read_bytes","value":-1},
		{"id":"fractional_cycles","key":"total_cycles","value":1.5},
		{"id":"infinite_cycles","key":"total_cycles","value":INF},
		{"id":"huge_cycles","key":"total_cycles","value":1e100},
		{"id":"nan_response","key":"first_request_cycles","value":NAN},
		{"id":"unknown_response","key":"first_request_cycles","value":-1},
		{"id":"negative_space","key":"peak_extra_bytes","value":-1},
		{"id":"runtime_error","key":"error","value":"bounds"},
		{"id":"partial_responses","key":"response_cycles","value":[307]},
		{"id":"wrong_q1","key":"first_request_cycles","value":308},
	]
	for mutation: Dictionary in mutations:
		var row: Dictionary = original.duplicate(true)
		row.id = mutation.id
		row.metrics[mutation.key] = mutation.value
		rows.append(row)
	var missing: Dictionary = original.duplicate(true)
	missing.id = "missing_traffic"
	missing.metrics.erase("ram_write_bytes")
	rows.append(missing)
	var wrong_flag: Dictionary = original.duplicate(true)
	wrong_flag.id = "wrong_flag"
	wrong_flag.correct = "true"
	rows.append(wrong_flag)
	var reversed: Dictionary = original.duplicate(true)
	reversed.id = "response_before_admission"
	reversed.metrics.admission_cycles[0] = 308
	rows.append(reversed)
	var ranked: Array[Dictionary] = Goals.rank(rows,condition,_goal())
	check(ranked.all(func(row: Dictionary) -> bool: return not row.eligible and row.rank == 0 and not row.exclusions.is_empty()),"Invalid numeric, incomplete and causal summaries cannot rank")
	check("incomplete" in _by_id(ranked,"unknown_response").exclusions,"Unknown response is incomplete, not a winning negative time")
	check("invalid" in _by_id(ranked,"response_before_admission").exclusions,"Impossible response summary is invalid")
	check("invalid" in _by_id(ranked,"huge_cycles").exclusions,"Finite out-of-range numeric input cannot overflow sorting")
