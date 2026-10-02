extends SceneTree
## Development feasibility probe; never registers a task or changes progression.
const Parser = preload("res://src/simulation/dsl_parser.gd")
const Core = preload("res://src/simulation/simulation_core.gd")
const Templates = preload("res://src/simulation/program_templates.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var candidates: Dictionary = {
		"two_rows": Templates.ROW_FIRST.replace("range(4)", "range(2)"),
		"nonadjacent_rows": Templates.ROW_FIRST.replace("A[row][col]", "A[row * 2][col]"),
		"constant_hot_row": Templates.ROW_FIRST.replace("A[row][col]", "A[0][col]"),
	}
	var report: Dictionary = {"candidates": [], "value_only_variant": {}}
	var valid := true
	for name: String in candidates:
		var program = Parser.parse(candidates[name])
		report.candidates.append({"name":name,"accepted":program.is_valid(),"errors":program.errors})
		valid = valid and not program.is_valid()
	var program = Parser.parse(Templates.ROW_FIRST)
	var original = Core.new().run_workload(program, Core.official_data_copy(), 1, "original", 2, 1)
	var new_values: Array[int] = []; new_values.resize(16); new_values.fill(1)
	var changed = Core.new().run_workload(program, new_values, 1, "different-values", 2, 1)
	report.value_only_variant = {"original_metrics":original.metrics,"changed_metrics":changed.metrics,"same_costs":original.metrics==changed.metrics,"different_output":original.result_value!=changed.result_value}
	valid = valid and original.passed and changed.passed and original.metrics==changed.metrics
	print(JSON.stringify(report, "  "))
	print("PASS: hot-row workload requires DSL expansion; changing values alone adds no access-cost decision" if valid else "FAIL: feasibility assumptions changed")
	quit(0 if valid else 1)
