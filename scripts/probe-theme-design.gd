extends SceneTree
## Read-only calibration; run in the isolated copy made by verify-project.py.

const Core = preload("res://src/simulation/simulation_core.gd")
const Parser = preload("res://src/simulation/dsl_parser.gd")
const Templates = preload("res://src/simulation/program_templates.gd")
const Overlap = preload("res://src/overlap_chapter/overlap_catalog.gd")
const Layout = preload("res://src/layout_chapter/layout_catalog.gd")

func _init() -> void:
	call_deferred("_probe")

func _probe() -> void:
	var rows: Array[Dictionary] = []
	var valid: bool = true
	for order: String in ["row", "column"]:
		var program = Parser.parse(Templates.ROW_FIRST if order == "row" else Templates.COLUMN_FIRST)
		for capacity: int in [1, 2, 4]:
			for group: int in [0, 1, 2, 4]:
				var first = Core.new().run_workload(program, Core.official_data_copy(), capacity, "probe", 2, group)
				var second = Core.new().run_workload(program, Core.official_data_copy(), capacity, "probe", 2, group)
				var deterministic: bool = first.canonical_signature() == second.canonical_signature()
				valid = valid and first.passed and deterministic
				rows.append({"order":order, "capacity":capacity, "group":group,
					"correct":first.passed, "deterministic":deterministic, "metrics":first.metrics})
	var endpoints: Array[Dictionary] = []
	for id: String in Overlap.IDS:
		var solution: Dictionary = Overlap.reference_solution(id)
		var report: Dictionary = Overlap.evaluate(id, solution.board, solution.program)
		var repeat: Dictionary = Overlap.evaluate(id, solution.board, solution.program)
		valid = valid and report.passed and repeat.passed
		for i: int in range(report.runs.size()):
			var same: bool = report.runs[i].canonical_signature() == repeat.runs[i].canonical_signature()
			valid = valid and same
			endpoints.append({"task":"chapter_3/"+id, "case":i, "deterministic":same, "metrics":report.runs[i].metrics})
	for id: String in Layout.IDS:
		var report: Dictionary = Layout.evaluate(id, Layout.reference_solution(id))
		var repeat: Dictionary = Layout.evaluate(id, Layout.reference_solution(id))
		valid = valid and report.passed and repeat.passed
		for i: int in range(report.runs.size()):
			var same: bool = report.runs[i].canonical_signature() == repeat.runs[i].canonical_signature()
			valid = valid and same
			endpoints.append({"task":"chapter_4/"+id, "case":i, "deterministic":same, "metrics":report.runs[i].metrics})
	print(JSON.stringify({"locality":rows, "reference_endpoints":endpoints, "valid":valid}, "\t"))
	quit(0 if valid else 1)
