extends SceneTree
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func _candidate(id: String, design: Dictionary) -> Dictionary:
	return {"id": id, "title": "My " + id, "design": design}


func _by_id(rows: Array[Dictionary], id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.id == id:
			return row
	return {}


func _run() -> void:
	var packed: Dictionary = Catalog.reference_solution("mixed")
	var small: Dictionary = packed.duplicate(true)
	small.batch = 1
	var full: Dictionary = packed.duplicate(true)
	full.strategy = "full"
	var candidates: Array[Dictionary] = [
		_candidate("small", small),
		_candidate("packed", packed),
		_candidate("full", full),
	]
	var before: String = JSON.stringify(candidates)
	var rows: Array[Dictionary] = Board.build_rows("mixed", candidates)
	check(JSON.stringify(candidates) == before, "Measurement leaves every source recipe intact")
	check(rows.size() == 3 and rows[0].id == "packed", "Real batch-of-four design wins on cycles")
	var best: Dictionary = _by_id(rows, "packed")
	check(best.eligible and best.correct and best.rank == 1, "All official cases qualify the measured best")
	check(best.cycles == 2495 and best.traffic == 1232 and best.peak == 32,
		"Actual mixed recipe measures 2495 cycles, 1232 B traffic and 32 B peak")
	check(best.cases.size() == 2 and best.cases[0].cycles == 1364 and best.cases[1].cycles == 1131,
		"Aggregate includes both independently executed official orders")
	check(best.cases[0].output == best.cases[0].expected and best.cases[1].output == best.cases[1].expected,
		"Rows retain exact observed and expected outputs")
	check(rows == Board.build_rows("mixed", candidates), "Repeated evaluation yields identical measured rows and trace signatures")
	var restored_candidates: Array[Dictionary] = []
	restored_candidates.assign(JSON.parse_string(before))
	check(rows == Board.build_rows("mixed", restored_candidates), "JSON numeric round trip retains measurement and recipe identity")
	var space_rows: Array[Dictionary] = Board.build_rows("mixed", candidates, "space")
	check(space_rows[0].id == "small" and space_rows[0].peak == 16 and space_rows[0].eligible,
		"Space objective selects a distinct real passing 16 B design")
	check(space_rows[0].cycles > best.cycles, "Choosing smaller space exposes its measured cycle tradeoff")
	var traffic_rows: Array[Dictionary] = Board.build_rows("mixed", candidates, "traffic")
	var measured_before: String = JSON.stringify(rows)
	check(Board.rank_rows(rows,"space") == space_rows and Board.rank_rows(rows,"traffic") == traffic_rows,
		"Sorting the current measurement snapshot agrees with complete remeasurement for each objective")
	check(JSON.stringify(rows) == measured_before, "Changing objective leaves the measured snapshot unchanged")
	check(traffic_rows[0].id == "packed" and traffic_rows[0].traffic == best.traffic,
		"Traffic ranks actual reads plus writes rather than an invented combined score")
	check(space_rows[0].condition_id == best.condition_id, "Changing objective retains the exact same task conditions")
	check(_by_id(rows, "full").peak == 144 and _by_id(rows, "full").cycles == 3919,
		"Full-copy strategy includes its actual preparation costs and larger peak")
	var equal: Array[Dictionary] = [
		_candidate("b", packed.duplicate(true)),
		_candidate("a", packed.duplicate(true)),
		_candidate("c", full.duplicate(true)),
	]
	var ties: Array[Dictionary] = Board.build_rows("mixed", equal)
	check(ties[0].id == "a" and ties[1].id == "b" and ties[2].id == "c",
		"Equal metrics use deterministic candidate ID ordering")
	check(ties[0].rank == 1 and ties[1].rank == 1 and ties[2].rank == 3,
		"Equal metrics share competition ranks 1, 1, 3")
	equal.reverse()
	check(ties == Board.build_rows("mixed", equal), "Input order does not decide a tied ranking")
	check(ties[0].recipe_id == ties[1].recipe_id, "Different names do not change recipe identity")
	check(Board.build_rows("mixed", candidates, "unknown") == rows, "Unknown sorting choice safely uses cycles")
	best.design.recipe.groups[0].fields[0] = 99
	best.cases[0].output[0] = -1
	check(JSON.stringify(candidates) == before, "Returned nested data does not alias any candidate")
	check(Board.build_rows("mixed", candidates)[0].cycles == 2495, "Changing a returned row cannot forge subsequent measurements")

	var invalid: Dictionary = Catalog.starter_design()
	invalid.recipe.groups[0].fields = [0, 0, 2, 3]
	var over_space: Dictionary = Catalog.reference_solution("batches")
	over_space.strategy = "full"
	var batches: Array[Dictionary] = [
		_candidate("invalid", invalid),
		_candidate("slow", Catalog.starter_design()),
		_candidate("over_space", over_space),
		_candidate("qualified", Catalog.reference_solution("batches")),
	]
	var batch_rows: Array[Dictionary] = Board.build_rows("batches", batches, "space")
	check(batch_rows[0].id == "qualified" and batch_rows[0].rank == 1,
		"Zero-space invalid or slow attempts cannot outrank a qualified design")
	var slow: Dictionary = _by_id(batch_rows, "slow")
	check(slow.correct and not slow.eligible and slow.rank == 0 and slow.reason == "target_unmet",
		"Correct output without meeting every original target remains unranked")
	var failed: Dictionary = _by_id(batch_rows, "over_space")
	check(not failed.correct and not failed.eligible and failed.rank == 0 and failed.reason == "space_limit",
		"Real failed allocation is unranked despite reporting zero cycles")
	check(failed.cycles == 0 and failed.traffic == 0 and failed.peak == 0,
		"Failed allocation does not invent space, work, or traffic")
	var malformed: Dictionary = _by_id(batch_rows, "invalid")
	check(not malformed.eligible and malformed.reason == "invalid_design" and malformed.cases.is_empty(),
		"Malformed designs are rejected before model execution")
	var unknown: Array[Dictionary] = Board.build_rows("unknown", [_candidate("a", packed)])
	check(unknown.size() == 1 and unknown[0].reason == "unknown_task" and unknown[0].rank == 0,
		"Unknown tasks never create empty-case passing scores")
	check(Board.build_rows("mixed", []).is_empty(), "An empty player library does not invent candidates")

	var relocation: Dictionary = Catalog.reference_solution("relocation")
	var swapped: Dictionary = relocation.duplicate(true)
	swapped.orders = {"A": relocation.orders.B.duplicate(true), "B": relocation.orders.A.duplicate(true)}
	var order_candidates: Array[Dictionary] = [
		_candidate("independent", relocation),
		_candidate("swapped", swapped),
	]
	var order_rows: Array[Dictionary] = Board.build_rows("relocation", order_candidates)
	var independent: Dictionary = _by_id(order_rows, "independent")
	check(independent.eligible and independent.cycles == 1669,
		"Relocation independently uses direct A and prepared B with measured total 1669")
	check(independent.cases[0].cycles == 307 and independent.cases[1].cycles == 1362,
		"Relocation does not apply the top-level recipe to both orders")
	check(independent.cases[0].recipe_id != independent.cases[1].recipe_id,
		"Per-order evidence retains the actually executed recipe identities")
	check(not _by_id(order_rows, "swapped").eligible and _by_id(order_rows, "swapped").correct,
		"Swapping two individually correct order recipes fails their original targets")
	check(independent.recipe_id != _by_id(order_rows, "swapped").recipe_id,
		"Whole-design identity includes both independent order recipes")
	check(independent.condition_id != rows[0].condition_id, "Different full ordered workloads never share a condition identity")
	var reverse_orders: Dictionary = relocation.duplicate(true)
	reverse_orders.orders = {"B": relocation.orders.B.duplicate(true), "A": relocation.orders.A.duplicate(true)}
	var reordered: Dictionary = Board.build_rows("relocation", [_candidate("independent", reverse_orders)])[0]
	check(reordered.recipe_id == independent.recipe_id and reordered.cases == independent.cases,
		"Dictionary insertion order has no effect on normalized recipe or executed orders")
	var field_rows: Array[Dictionary] = Board.build_rows("fields", [
		_candidate("field", {"recipe": Recipe.field_major(), "strategy": "direct"}),
	])
	check(field_rows[0].eligible and field_rows[0].cycles == 122 and field_rows[0].traffic == 80,
		"Independent simple cold-cache example sums real 49 and 73 cycle cases")
	print("PASS: layout scoreboard %d checks" % checks if failures.is_empty() else "FAIL: layout scoreboard " + str(failures))
	quit(0 if failures.is_empty() else 1)
