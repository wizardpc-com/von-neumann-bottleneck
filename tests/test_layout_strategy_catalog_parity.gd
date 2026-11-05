extends SceneTree
## Expected values were measured at e1e27db before adding any scenario.
const Model = preload("res://experiments/layout_strategy/model.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const FIXTURE: String = "res://tests/fixtures/layout_strategy/legacy-scheduling-v1.json"
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func same(left: Variant, right: Variant) -> bool:
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not same(left[key],right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for index: int in left.size():
			if not same(left[index],right[index]): return false
		return true
	return left == right

func _run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for frozen scheduling parity.")
		quit(1)
		return
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not fixture is Dictionary or not fixture.get("samples") is Array:
		push_error("Frozen pre-extension scheduling observations are missing.")
		quit(1)
		return
	check(fixture.base_commit == "e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8","Observations identify the unchanged captured base")
	check(fixture.model == Model.MODEL_VERSION,"Calculation model token is unchanged")
	check(fixture.tasks.size() == 4 and fixture.samples.size() == 56,"Frozen scope is exactly four tasks and56 measurements")
	for id: String in fixture.tasks:
		check(same(Model.scenario(id),fixture.tasks[id]),id+": complete original task dictionary unchanged")
	var exports: int = 0
	for index: int in fixture.samples.size():
		var sample: Dictionary = fixture.samples[index]
		var label: String = "%s/%d" % [sample.task,index]
		var result: Dictionary = Model.evaluate(Model.scenario(sample.task),sample.plan)
		check(result.get("valid",false) and result.get("run") != null,label+": real measurement exists")
		if not result.get("valid",false) or result.get("run") == null: continue
		var run: LayoutRun = result.run
		check(run.case_signature == sample.condition,label+": exact full condition")
		check(run.recipe_signature == sample.plan_id,label+": exact semantic plan identity")
		check(run.canonical_signature().sha256_text() == sample.trace_id,label+": exact complete Trace identity")
		check(run.passed == sample.correct,label+": output/completion classification")
		check(same(run.metrics,sample.metrics),label+": every measured metric")
		check(same(run.output_values,sample.outputs),label+": ordered actual outputs")
		check(same(run.expected_values,sample.expected),label+": ordered expected outputs")
		for frozen: Dictionary in sample.codes:
			var exported: Dictionary = Code.create(sample.task,sample.plan,frozen.goal)
			exports += 1
			check(exported.ok == frozen.ok and exported.reason == frozen.reason,label+": original export eligibility")
			check(str(exported.get("code","")) == frozen.code,label+": byte-exact original canonical code")
	check(exports == 112,"Both original objectives replayed across all56 frozen observations")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+
		"layout scheduling catalog parity %d checks,56 measurements,%d code outcomes,%d failures" %
		[checks,exports,failures.size()])
	quit(0 if failures.is_empty() else 1)
