extends SceneTree
## Actual official simulations retain an exact replayable best beyond both caps.
const Core = preload("res://src/simulation/simulation_core.gd")
const Parser = preload("res://src/simulation/dsl_parser.gd")
const Templates = preload("res://src/simulation/program_templates.gd")
const Receipt = preload("res://src/locality_chapter/locality_run_receipt.gd")
const Catalog = preload("res://src/locality_chapter/locality_level_catalog.gd")

var checks: int = 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)


func recipe(source: String, cache_lines: int = 1, passes: int = 2, blocks: int = 0, bypass: bool = false) -> Dictionary:
	return {"source": source, "cache_lines": cache_lines, "passes": passes, "blocks": blocks, "bypass": bypass}


func simulate(id: StringName, design: Dictionary) -> Variant:
	var program = Parser.parse(design.source)
	var data: Array[int] = Core.official_data_copy()
	var trace = Core.new().run_workload(
		program, data, int(design.cache_lines), "Official Test Set",
		int(design.passes), int(design.blocks), bool(design.bypass)
	)
	var receipt = Receipt.new()
	receipt.populate(id, trace, program.traversal_pattern(), data, int(design.passes), int(design.blocks), bool(design.bypass))
	return receipt


func record(state: Node, id: StringName, design: Dictionary) -> Variant:
	var receipt: Variant = simulate(id, design)
	state.record_receipt(id, receipt, design)
	return receipt


func contains_source(receipts: Array, source: String) -> bool:
	for receipt: Variant in receipts:
		if receipt.program_signature == source.sha256_text():
			return true
	return false


func run() -> void:
	var state: Node = root.get_node("LocalityChapter")
	var mode: Node = root.get_node("GameMode")
	mode.set_mode(&"game")
	state.reset_game_progress()
	state.reset_test_progress()
	var baseline: Dictionary = recipe(Templates.COLUMN_FIRST)
	var winning: Dictionary = recipe(Templates.ROW_FIRST, 1, 2, 1)
	var baseline_receipt: Variant = record(state, &"capstone", baseline)
	var winner_receipt: Variant = record(state, &"capstone", winning)
	check(baseline_receipt.passed and winner_receipt.passed, "Baseline and early best are actual correct official simulations")
	check(winner_receipt.metrics.total_cycles < baseline_receipt.metrics.total_cycles, "The retained design really uses fewer cycles than the slower experiments")
	var latest: Dictionary = {}
	for index: int in 40:
		latest = recipe(Templates.COLUMN_FIRST + "\n# later experiment %d" % index)
		var later: Variant = record(state, &"capstone", latest)
		check(later.passed and later.metrics.total_cycles > winner_receipt.metrics.total_cycles, "Later experiment %d has actual slower correct metrics" % index)
	var best: Dictionary = state.best_observation_for(&"capstone")
	check(best.recipe.source == winning.source and best.metrics == winner_receipt.metrics, "Best source and true measured result survive more than 32 later experiments")
	check(best.receipt.trace_signature == winner_receipt.trace_signature, "Revalidation uses the same canonical official trace as a fresh run")
	check(state.game_observations.capstone.size() == 32 and state.receipts_for(&"capstone").size() == state.RECEIPT_LIMIT, "Both recipe and receipt collections remain bounded")
	check(contains_source(state.receipts_for(&"capstone"), winning.source), "The early fastest receipt survives session eviction")
	check(contains_source(state.receipts_for(&"capstone"), latest.source), "The newest actual experiment remains in session history")
	check(Catalog.new().capstone_baseline_seen(state.receipts_for(&"capstone")), "Teaching baseline survives alongside best and latest")
	check(state.game_observations.capstone[-1].source == latest.source, "The latest exact source survives persistent eviction")
	check(state.game_completed.is_empty() and not state.capstone_first_experiment_observed(), "Recording and reading best do not grant progress or first-experiment review")

	var condition: String = best.condition_id
	best.recipe.source = "mutated caller copy"
	best.metrics.total_cycles = 0
	best.receipt.metrics.total_cycles = 0
	check(state.best_observation_for(&"capstone").recipe.source == winning.source, "Returned recipe is detached from saved state")
	check(state.best_observation_for(&"capstone").metrics == winner_receipt.metrics, "Returned result and nested receipt are detached from measured state")
	var tied: Dictionary = recipe(Templates.ROW_FIRST + "\n# same performance", 1, 2, 1)
	var tied_receipt: Variant = record(state, &"capstone", tied)
	check(tied_receipt.metrics == winner_receipt.metrics and state.best_observation_for(&"capstone").recipe.source == winning.source, "Exact measured ties retain the existing best deterministically")
	var expensive: Dictionary = recipe(Templates.ROW_FIRST, 4, 2, 1)
	var expensive_receipt: Variant = record(state, &"capstone", expensive)
	check(expensive_receipt.metrics.total_cycles == winner_receipt.metrics.total_cycles and expensive_receipt.metrics.hardware_cost > winner_receipt.metrics.hardware_cost, "An equally fast actual design can require more hardware")
	check(state.best_observation_for(&"capstone").recipe.cache_lines == 1, "Equal-cycle ranking retains the less expensive actual design")

	var mismatches: Array[Dictionary] = [
		{"id": &"capstone", "design": recipe(Templates.ROW_FIRST, 1, 1, 1)},
		{"id": &"capstone", "design": recipe(Templates.ROW_FIRST, 0, 2, 0, true)},
		{"id": &"capstone", "design": recipe(Templates.ROW_FIRST, 1, 2, 0, true)},
		{"id": &"access_order", "design": recipe(Templates.ROW_FIRST, 1, 1, 1)},
		{"id": &"working_set", "design": recipe(Templates.COLUMN_FIRST, 1, 2, 0)},
	]
	for mismatch: Dictionary in mismatches:
		var measured: Variant = record(state, mismatch.id, mismatch.design)
		check(measured.passed, "Task mismatch is a correct generic simulation, so comparison must inspect its workload")
	check(state.best_observation_for(&"capstone").recipe.source == winning.source, "Wrong passes, unavailable cache and inconsistent bypass cannot replace capstone best")
	check(state.best_observation_for(&"access_order").is_empty(), "An unavailable group size cannot become access-order best")
	check(state.best_observation_for(&"working_set").is_empty(), "A changed fixed program cannot become working-set best")
	check(state.best_observation_for(&"capstone").condition_id == condition, "Design changes retain a single task/workload comparison identity")
	var incorrect: Dictionary = recipe("total = 1\nfor row in range(4):\n    for col in range(4):\n        total += load(A[row][col])\nstore(OUT[0], total)", 1, 2, 1)
	var wrong_receipt: Variant = record(state, &"capstone", incorrect)
	check(not wrong_receipt.passed and state.best_observation_for(&"capstone").recipe.source == winning.source, "An incorrect actual run cannot replace the measured best")

	var unfinished: Dictionary = {"draft_source": "unfinished ???", "applied_source": Templates.COLUMN_FIRST, "cache_lines": 2, "passes": 2, "blocks": 2, "bypass": false}
	state.retain_workspace(&"capstone", unfinished)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(state.game_snapshot()))
	var fields: Array = snapshot.keys()
	fields.sort()
	check(fields == ["completed_levels", "economical_design", "first_experiment_observed", "observations", "schema_version", "workspaces"], "Global chapter save fields remain unchanged for older readers")
	for saved: Dictionary in snapshot.observations.capstone:
		saved["metrics"] = {"total_cycles": 0, "hardware_cost": 0}
		saved["checkpoint"] = true
	state.restore_game(snapshot, true)
	var restored: Dictionary = state.best_observation_for(&"capstone")
	check(restored.recipe.source == winning.source and restored.metrics == winner_receipt.metrics, "JSON reload recomputes the best from source and ignores poisoned saved numbers")
	check(restored.receipt.trace_signature == winner_receipt.trace_signature and restored.condition_id == condition, "Canonical official trace and conditions survive replay")
	check(state.receipts_for(&"capstone").size() == state.RECEIPT_LIMIT, "Reload enforces the same bounded receipt history as live play")
	check(contains_source(state.receipts_for(&"capstone"), winning.source) and Catalog.new().capstone_baseline_seen(state.receipts_for(&"capstone")), "Rebuilt receipt history preserves both best and real baseline")
	var checkpoint_count: int = 0
	for saved: Dictionary in state.game_observations.capstone:
		if bool(saved.get("checkpoint", false)):
			checkpoint_count += 1
	check(checkpoint_count == 1, "Replay rebuilds checkpoint protection instead of trusting saved flags")
	check(state.workspace_for(&"capstone").draft_source == unfinished.draft_source and state.game_completed.is_empty(), "Restoring measurements preserves unfinished draft and grants no completion")
	var game_before_test: Dictionary = state.game_snapshot()
	mode.set_mode(&"test")
	check(state.best_observation_for(&"capstone").is_empty(), "Test has no inherited Game best")
	record(state, &"capstone", baseline)
	check(state.best_observation_for(&"capstone").metrics == baseline_receipt.metrics, "Test best is measured from its own observations")
	check(state.best_observation_for(&"capstone", &"game").recipe.source == winning.source, "Explicit Game read remains available without mixing modes")
	check(state.game_snapshot() == game_before_test, "Test measurements do not alter any persistent Game data")
	state.reset_test_progress()
	check(state.test_observations.is_empty() and state.best_observation_for(&"capstone").is_empty(), "Test reset clears its transient best and source recipes")
	check(state.game_snapshot() == game_before_test, "Test reset preserves Game observations and unfinished work")
	mode.set_mode(&"game")
	var stale: Dictionary = state.game_snapshot()
	stale.observations = {"capstone": [restored.recipe.duplicate(true)]}
	stale.observations.capstone[0].version = "incompatible-model"
	state.restore_game(stale, true)
	check(state.best_observation_for(&"capstone").is_empty(), "An incompatible model cannot provide a comparable best")
	check(state.workspace_for(&"capstone").draft_source == unfinished.draft_source, "Ignoring stale measurements leaves the current unfinished draft intact")
	state.restore_game(game_before_test, true)
	var old_model: String = state._workspace_fingerprint
	state._workspace_fingerprint = "different-runtime-model"
	check(state.best_observation_for(&"capstone").is_empty(), "Cached measured results cannot survive a changed model identity")
	state._workspace_fingerprint = old_model
	check(state.best_observation_for(&"capstone").recipe.source == winning.source, "Returning to the exact same model recovers its intact derived record")
	state.reset_game_progress()
	check(state.best_observation_for(&"capstone").is_empty(), "Game reset clears derived best and saved recipes together")
	print("PASS: locality best observation %d checks" % checks if failures.is_empty() else "FAIL: locality best observation " + str(failures))
	quit(0 if failures.is_empty() else 1)
