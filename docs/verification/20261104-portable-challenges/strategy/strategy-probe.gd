extends SceneTree
## Read-only model probe. Root must run only in an isolated QA project/profile.
## Outputs JSON lines to stdout; never calls player state, save or progress APIs.
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const BLOCKS: Array[int] = [0,1,2,4,8,16]
const BATCHES: Array[int] = [1,2,3,4,5,6,8,12,17]
const COPY_SETS: Array = [[0],[3],[0,3],[1,2],[0,1,2,3]]
const MAX_CANDIDATES: int = 2600
var failures: Array[String] = []
var measured_count: int = 0
var started_us: int = 0


func _init() -> void:
	var profile: String = str(ProjectSettings.get_setting("application/config/custom_user_dir_name",""))
	if not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir",false)) or not profile.begins_with("VonNeumannBottleneckChecks/"):
		print("VNB_STRATEGY_ERROR isolated VonNeumannBottleneckChecks profile required")
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	var levels: Array[String] = ["mixed"]
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--strategy-all":
			levels.assign(Catalog.IDS)
		elif arg.begins_with("--strategy-level="):
			var requested: String = arg.trim_prefix("--strategy-level=")
			if requested not in Catalog.IDS:
				print("VNB_STRATEGY_ERROR unknown task: " + requested)
				quit(2)
				return
			levels = [requested]
	started_us = Time.get_ticks_usec()
	print("VNB_STRATEGY_SCOPE " + JSON.stringify({
		"probe":"layout-strategy-sample-1","model":Simulator.MODEL_VERSION,
		"tasks":levels,"families":_families(),"blocks":BLOCKS,"copy_sets":COPY_SETS,
		"batches":BATCHES,"max_candidates":MAX_CANDIDATES,
		"native_early_blocks":[0],"relocation_A":"fixed direct starter",
		"relocation_B_strategies":["direct","full"],
		"other_imported_strategies":["direct","full","batch"],
		"scope":"complete Cartesian sample only; not all legal recipes or a global optimum",
	}))
	for level: String in levels:
		var candidates: Array[Dictionary] = _candidates(level)
		if measured_count + candidates.size() > MAX_CANDIDATES:
			failures.append("Candidate safety bound exceeded before " + level)
			break
		_probe_level(level,candidates)
	print("VNB_STRATEGY_DONE " + JSON.stringify({
		"candidate_count":measured_count,
		"elapsed_ms":(Time.get_ticks_usec()-started_us)/1000.0,
		"failures":failures,
	}))
	quit(0 if failures.is_empty() else 1)


func _families() -> Array[Dictionary]:
	return [
		{"id":"record","recipe":Recipe.record_major()},
		{"id":"field","recipe":Recipe.field_major()},
		{"id":"hot_pair","recipe":{"groups":[{"fields":[0,3],"order":"record"},{"fields":[1,2],"order":"record"}],"block":0}},
		{"id":"hot_pair_field","recipe":{"groups":[{"fields":[0,3],"order":"field"},{"fields":[1,2],"order":"record"}],"block":0}},
	]


func _candidates(level: String) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var native_layout: bool = level in ["fields","records","hot_cold"]
	var blocks: Array[int] = BLOCKS.duplicate()
	if level in ["fields","records"]: blocks = [0]
	if not native_layout:
		_append_candidate(candidates,level,"direct",Catalog.starter_design())
	for family: Dictionary in _families():
		for block: int in blocks:
			var recipe: Dictionary = family.recipe.duplicate(true)
			recipe.block = block
			var prefix: String = family.id + "/block-" + str(block)
			if native_layout:
				var direct: Dictionary = Catalog.starter_design()
				direct.recipe = recipe
				_append_candidate(candidates,level,prefix,direct)
				continue
			for fields: Array in COPY_SETS:
				var design: Dictionary = {"recipe":recipe.duplicate(true),"strategy":"full","copy_fields":fields.duplicate(),"batch":4}
				var copied: String = ""
				for field: int in fields: copied += str(field)
				_append_candidate(candidates,level,prefix+"/copy-"+copied+"/full",design)
				if level == "relocation": continue
				for batch: int in BATCHES:
					var chunked: Dictionary = design.duplicate(true)
					chunked.strategy = "batch"
					chunked.batch = batch
					_append_candidate(candidates,level,prefix+"/copy-"+copied+"/batch-"+str(batch),chunked)
	return candidates


func _append_candidate(candidates: Array[Dictionary], level: String, label: String, chosen: Dictionary) -> void:
	var design: Dictionary = chosen.duplicate(true)
	if level == "relocation":
		design = Catalog.starter_design()
		design["orders"] = {"A":Catalog.starter_design(),"B":chosen.duplicate(true)}
	candidates.append({"id":label,"title":label,"design":design})


func _probe_level(level: String, candidates: Array[Dictionary]) -> void:
	var task_started: int = Time.get_ticks_usec()
	var rows: Array[Dictionary] = []
	var classes: Dictionary = {}
	var reasons: Dictionary = {}
	var eligible_count: int = 0
	var correct_count: int = 0
	var relationship_checks: int = 0
	for index: int in candidates.size():
		var measured: Array[Dictionary] = Board.build_rows(level,[candidates[index]])
		if measured.size() != 1:
			failures.append(level+": incomplete measured row "+str(index))
			continue
		var row: Dictionary = measured[0]
		rows.append(row)
		measured_count += 1
		eligible_count += int(row.eligible)
		correct_count += int(row.correct)
		reasons[row.reason] = int(reasons.get(row.reason,0)) + 1
		if row.reason not in ["ranked","target_unmet","space_limit"]:
			failures.append(level+": unexpected legal-candidate result "+str(row.id)+" "+str(row.reason))
		if row.correct:
			relationship_checks += 1
			if int(row.cycles)-int(row.traffic) != _cycle_traffic_offset(level,row.design):
				failures.append(level+": unexpected cycle/traffic accounting "+str(row.id))
		var key: String = JSON.stringify([row.eligible,row.correct,row.cycles,row.traffic,row.peak,row.reason])
		if not classes.has(key):
			classes[key] = _compact(row)
			classes[key]["candidate_count"] = 0
			classes[key]["examples"] = []
		var metric_class: Dictionary = classes[key]
		metric_class.candidate_count += 1
		if metric_class.examples.size() < 4:
			metric_class.examples.append({"id":row.id,"recipe_id":row.recipe_id})
		if (index+1)%100 == 0:
			print("VNB_STRATEGY_PROGRESS %s %d/%d %.1fms" % [level,index+1,candidates.size(),(Time.get_ticks_usec()-task_started)/1000.0])
	var qualified: Array[Dictionary] = []
	var unqualified: Array[Dictionary] = []
	for value: Dictionary in classes.values():
		if value.eligible: qualified.append(value)
		else: unqualified.append(value)
	qualified.sort_custom(_metric_order)
	unqualified.sort_custom(_metric_order)
	var frontier: Array[Dictionary] = []
	for row: Dictionary in qualified:
		var dominated: bool = false
		for other: Dictionary in qualified:
			if _dominates(other,row):
				dominated = true
				break
		if not dominated: frontier.append(row)
	var samples: Array[Dictionary] = _deterministic_samples(level,rows)
	if eligible_count == 0: failures.append(level+": sampled authored strategy families contain no eligible design")
	var extrema: Dictionary = {}
	for metric: String in ["cycles","traffic","peak"]:
		if qualified.is_empty(): continue
		var winner: Dictionary = qualified[0]
		var tied_candidates: int = 0
		for row: Dictionary in qualified:
			if int(row[metric]) < int(winner[metric]): winner = row
		for row: Dictionary in qualified:
			if int(row[metric]) == int(winner[metric]): tied_candidates += int(row.candidate_count)
		extrema[metric] = {"value":winner[metric],"representative":winner.id,"tied_candidates":tied_candidates}
	print("VNB_STRATEGY_RESULT " + JSON.stringify({
		"task":level,"condition_id":rows[0].condition_id if not rows.is_empty() else "",
		"candidate_count":rows.size(),"correct_count":correct_count,"eligible_count":eligible_count,
		"reason_counts":reasons,"qualified_metric_classes":qualified,"unqualified_metric_classes":unqualified,
		"sample_pareto_frontier":frontier,"objective_minima":extrema,
		"accounting_checks":relationship_checks,"determinism_samples":samples,
		"elapsed_ms":(Time.get_ticks_usec()-task_started)/1000.0,
	}))


func _metric_order(a: Dictionary, b: Dictionary) -> bool:
	for metric: String in ["cycles","traffic","peak"]:
		if int(a[metric]) != int(b[metric]): return int(a[metric]) < int(b[metric])
	return String(a.id) < String(b.id)


func _dominates(a: Dictionary, b: Dictionary) -> bool:
	return (
		int(a.cycles) <= int(b.cycles) and int(a.traffic) <= int(b.traffic) and int(a.peak) <= int(b.peak)
		and (int(a.cycles) < int(b.cycles) or int(a.traffic) < int(b.traffic) or int(a.peak) < int(b.peak))
	)


func _compact(row: Dictionary) -> Dictionary:
	var cases: Array[Dictionary] = []
	for item: Dictionary in row.cases:
		cases.append({
			"name":item.name,"correct":item.correct,"target_met":item.target_met,
			"cycles":item.cycles,"traffic":item.traffic,"peak":item.peak,"error":item.error,
			"case_id":item.case_id,"recipe_id":item.recipe_id,"trace_id":item.trace_id,
			"outputs_match":item.output == item.expected,
		})
	return {
		"id":row.id,"design":row.design.duplicate(true),"recipe_id":row.recipe_id,
		"eligible":row.eligible,"correct":row.correct,"reason":row.reason,
		"cycles":row.cycles,"traffic":row.traffic,"peak":row.peak,"cases":cases,
	}


func _cycle_traffic_offset(level: String, design: Dictionary) -> int:
	var offset: int = 0
	for task: Dictionary in Catalog.cases(level):
		for query: Dictionary in task.queries:
			var indices: Array = query.get("indices",[])
			var records: int = task.records.size() if indices.is_empty() else indices.size()
			var consumed: int = records*query.fields.size()*int(query.get("repeat",1))
			var outputs: int = int(query.get("repeat",1)) if query.kind == "sum" else consumed
			offset += 2*consumed + outputs
		var chosen: Dictionary = design.get("orders",{}).get(task.name,design) if level == "relocation" else design
		if not task.native_layout and chosen.strategy != "direct":
			offset += 6*task.records.size()*chosen.copy_fields.size()
	return offset


func _deterministic_samples(level: String, rows: Array[Dictionary]) -> Array[Dictionary]:
	var selected: Dictionary = {}
	if not rows.is_empty(): selected[rows[0].id] = rows[0]
	for metric: String in ["cycles","traffic","peak"]:
		var winner: Dictionary = {}
		for row: Dictionary in rows:
			if row.eligible and (winner.is_empty() or int(row[metric]) < int(winner[metric])):
				winner = row
		if not winner.is_empty(): selected[winner.id] = winner
	var results: Array[Dictionary] = []
	for row: Dictionary in selected.values():
		var candidate: Dictionary = {"id":row.id,"title":row.title,"design":row.design.duplicate(true)}
		var repeated: Dictionary = Board.build_rows(level,[candidate])[0]
		var round_trip: Dictionary = JSON.parse_string(JSON.stringify(candidate))
		var restored: Dictionary = Board.build_rows(level,[round_trip])[0]
		var stable: bool = row == repeated and row == restored
		var traces: Array[String] = []
		for item: Dictionary in row.cases: traces.append(String(item.trace_id))
		results.append({"id":row.id,"stable":stable,"trace_ids":traces})
		if not stable: failures.append(level+": unstable repeated/JSON trace "+str(row.id))
	return results
