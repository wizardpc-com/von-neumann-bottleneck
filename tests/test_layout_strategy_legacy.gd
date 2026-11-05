extends SceneTree
## Frozen pre-extraction observations, not recalculated expected values.
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
const FIXTURE: String = "res://tests/fixtures/layout_strategy/legacy-layout-traces.json"
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for legacy parity checks.")
		quit(1)
		return
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not fixture is Dictionary or not fixture.get("samples") is Array:
		push_error("Missing or malformed frozen legacy Trace observations.")
		quit(1)
		return
	var samples: Array = fixture.samples
	check(samples.size() == 141,"Frozen fixture contains 141 representative designs")
	var cases: int = 0
	var task_counts: Dictionary = {}
	for index: int in samples.size():
		var sample: Dictionary = samples[index]
		var task_id: String = sample.task
		task_counts[task_id] = int(task_counts.get(task_id,0))+1
		var candidates: Array[Dictionary] = [{"id":"parity","title":"Parity","design":sample.design}]
		var rows: Array[Dictionary] = Board.build_rows(task_id,candidates)
		check(rows.size() == 1,"%s/%d produces one real row" % [task_id,index])
		if rows.size() != 1: continue
		var row: Dictionary = rows[0]
		for key: String in ["condition_id","recipe_id","correct","eligible","cycles","traffic","peak"]:
			check(row[key] == sample[key],"%s/%d retains %s" % [task_id,index,key])
		check(row.cases.size() == sample.cases.size(),"%s/%d retains official case count" % [task_id,index])
		if row.cases.size() != sample.cases.size(): continue
		for case_index: int in row.cases.size():
			cases += 1
			var actual: Dictionary = row.cases[case_index]
			var expected: Dictionary = sample.cases[case_index]
			for key: String in ["case_id","recipe_id","trace_id","correct","target_met","cycles","traffic","peak","error"]:
				check(actual[key] == expected[key],"%s/%d/%d retains %s" % [task_id,index,case_index,key])
	check(task_counts.size() == 6,"Parity sample covers all six official layout tasks")
	check(cases == 282,"Remeasured all 282 frozen official cases")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+
		"layout strategy legacy parity %d checks, %d designs, %d cases, %d failures" %
		[checks,samples.size(),cases,failures.size()])
	quit(0 if failures.is_empty() else 1)
