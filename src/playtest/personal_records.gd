extends Node
## Local result journal only. Never consulted by progression or simulation.
const PATH: String = "user://personal_task_records_v1.json"
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
var best: Dictionary = {}
func _ready() -> void:
	var file := FileAccess.open(PATH,FileAccess.READ)
	if file != null and file.get_length()<262144:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary and parsed.get("schema_version")==1 and parsed.get("best") is Dictionary:
			for key: Variant in parsed.best:
				if key is String and key.length()<100 and parsed.best[key] is Dictionary and best.size()<100:
					best[key]=preload("res://src/playtest/remote_feedback.gd").minimal_context(parsed.best[key])
	PlaytestData.official_result.connect(_observe)
func _observe(event: Dictionary) -> void:
	if event.get("mode")!="game" or event.get("event")!="official_run": return
	var p: Dictionary = event.get("payload",{})
	if not p.get("passed",false): return
	var safe: Dictionary = preload("res://src/playtest/remote_feedback.gd").minimal_context(event)
	if p.get("chapter_id")=="hardware_foundations" and safe.has("case_count"): safe["passed_cases"]=safe.case_count
	var key: String = str(p.get("chapter_id",""))+"/"+str(p.get("level_id",""))
	var version: String = str(safe.get("case_set_version","unspecified"))
	var prior: Dictionary = best.get(key,{})
	if prior.get("case_set_version")!=version or int(safe.get("cycles",0))<int(prior.get("cycles",9223372036854775807)):
		best[key]=safe
		var file := FileAccess.open(PATH+".tmp",FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"schema_version":1,"best":best})); file.flush(); file.close()
			DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
func snapshot(task_rows: Array[Dictionary] = []) -> Dictionary:
	var result: Dictionary = {"total":0,"completed":0,"main_total":0,"main_completed":0,"side_total":0,"side_completed":0,"regions":[],"tasks":[],"bonus_total":0,"bonus_completed":0,"saved_schemes":0}
	if task_rows.is_empty(): task_rows=TaskNavigation.tasks()
	var region_indices: Dictionary = {}
	for task: Dictionary in task_rows:
		if not region_indices.has(task.region):
			region_indices[task.region]=result.regions.size()
			result.regions.append({"id":task.region,"title_key":task.region_title_key,"total":0,"completed":0})
	# Read the manifest without invoking the workbench store's legacy migration.
	var workbenches: Dictionary = {}
	var file := FileAccess.open("user://hardware_workbenches_v1.json",FileAccess.READ)
	if file != null and file.get_length()<16777216:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary and parsed.get("namespaces") is Dictionary:
			var game: Variant = parsed.namespaces.get("game",{})
			if game is Dictionary: workbenches=game
	for task: Dictionary in task_rows:
		var row: Dictionary = task.duplicate(true)
		row["saved_schemes"]=0
		if task.domain=="hardware_foundations":
			var saved: Variant = workbenches.get(task.id,{})
			if saved is Dictionary and saved.get("workbenches") is Dictionary: row.saved_schemes=saved.workbenches.size()
		elif task.domain=="chapter_4": row.saved_schemes=LayoutChapter.game_named.get(task.id,{}).size()
		elif task.domain=="chapter_3": row.saved_schemes=int(OverlapChapter.game_drafts.has(task.id))
		row["best"]=best.get(task.key,{}).duplicate(true)
		if task.domain=="hardware_foundations" and row.best.get("passed",false) and row.best.has("case_count"): row.best["passed_cases"]=row.best.case_count
		if task.domain=="chapter_4" and LayoutChapter.game_solutions.has(task.id):
			var report: Dictionary = Catalog.evaluate(task.id,LayoutChapter.game_solutions[task.id])
			if report.passed:
				row.best={"cycles":LayoutChapter.cost(report),"ram_read_bytes":0,"ram_write_bytes":0,"peak_extra_bytes":0}
				for run: LayoutRun in report.runs:
					row.best.ram_read_bytes+=int(run.metrics.ram_read_bytes)
					row.best.ram_write_bytes+=int(run.metrics.ram_write_bytes)
					row.best.peak_extra_bytes=maxi(row.best.peak_extra_bytes,int(run.metrics.peak_extra_bytes))
		result.saved_schemes+=row.saved_schemes; result.total+=1
		result.regions[region_indices[task.region]].total+=1
		var category: String = "side" if task.optional else "main"
		result[category+"_total"]+=1
		if task.completed:
			result.completed+=1; result[category+"_completed"]+=1; result.regions[region_indices[task.region]].completed+=1
		for goal: Dictionary in task.get("bonus_goals",[]):
			result.bonus_total+=1; result.bonus_completed+=int(goal.complete)
		result.tasks.append(row)
	return result
func layout_score() -> Dictionary:
	# Reuse locally verified, saved best design. Evaluation runs only in this game client.
	if GameMode.is_test_mode() or not LayoutChapter.game_solutions.has("mixed"): return {}
	var report: Dictionary = Catalog.evaluate("mixed",LayoutChapter.game_solutions.mixed)
	if not report.passed: return {}
	var result: Dictionary = {"chapter_id":"chapter_4","level_id":"mixed","ruleset_version":"layout-mixed-1","model_version":"layout-memory-1",
		"case_set_version":("layout-v1:mixed"+JSON.stringify(Catalog.cases("mixed"))).sha256_text(),"passed":true,"passed_cases":2,"case_count":2,
		"total_cycles":LayoutChapter.cost(report),"build_version":str(ProjectSettings.get_setting("application/config/version","development")),
		"source":PlaytestData.source_kind,"mode":"game"}
	for i: int in range(2):
		for key: String in ["total_cycles","prepare_cycles","query_cycles","output_cycles","ram_read_bytes","ram_write_bytes","peak_extra_bytes"]:
			result[["a","b"][i]+"_"+key]=int(report.runs[i].metrics[key])
	return result
