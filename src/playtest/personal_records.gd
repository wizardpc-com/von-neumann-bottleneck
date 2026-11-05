extends Node
## Local result journal only. Never consulted by progression or simulation.
const PATH: String = "user://personal_task_records_v1.json"
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const SafeContext = preload("res://src/playtest/remote_feedback.gd")
const MAX_FILE_BYTES: int = 262144
const MAX_TASKS: int = 100
const MAX_CONDITIONS: int = 8
const CYCLE_DOMAINS := ["chapter_1","chapter_2","chapter_3","chapter_4","representation","service"]
# `best` is the schema-1 compatibility view of observed summaries, not replay proof.
var best: Dictionary = {}
var conditions: Dictionary = {}
var legacy: Dictionary = {}
var storage_path: String = PATH
var disk_write_allowed: bool = true
var storage_status: String = "ready"
var last_error: String = ""

func _ready() -> void:
	_load_records()
	PlaytestData.official_result.connect(_observe)

func _load_records() -> void:
	best.clear()
	conditions.clear()
	legacy.clear()
	disk_write_allowed = true
	storage_status = "ready"
	last_error = ""
	if not FileAccess.file_exists(storage_path): return
	var file := FileAccess.open(storage_path,FileAccess.READ)
	if file == null or file.get_length() >= MAX_FILE_BYTES:
		_protect_records("Existing personal records could not be read safely.")
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		_protect_records("Existing personal records have an unsupported or corrupt format.")
		return
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or not parsed.get("best") is Dictionary:
		_protect_records("Existing personal records have an unsupported or corrupt format.")
		return
	for field: String in parsed:
		if field not in ["schema_version","best","conditions","legacy"]:
			_protect_records("Existing personal records contain unsupported fields.")
			return
	if (parsed.has("conditions") and not parsed.conditions is Dictionary) or (parsed.has("legacy") and not parsed.legacy is Dictionary):
		_protect_records("Existing personal record history has an unsupported format.")
		return
	# Validate the entire persisted history before normalizing any field. Silently
	# skipping damaged entries would overwrite the original on the next valid run.
	if not _valid_saved_history(parsed):
		_protect_records("Existing personal record entries are corrupt or unsupported.")
		return
	best = _loaded_summaries(parsed.best)
	legacy = _loaded_summaries(parsed.get("legacy",{}))
	var saved_conditions: Dictionary = parsed.get("conditions",{})
	for key: String in saved_conditions:
		var bucket: Dictionary = {}
		for signature: String in saved_conditions[key]:
			var safe: Dictionary = SafeContext.minimal_context(saved_conditions[key][signature])
			safe.cycles = _cycle_value(safe)
			bucket[signature] = safe
		conditions[key] = bucket
	# Old summaries remain historical even when current metadata could be guessed.
	for key: String in best:
		var signature: String = _condition_id(best[key])
		if signature.is_empty() or not conditions.get(key,{}).has(signature):
			if not legacy.has(key): legacy[key] = best[key].duplicate(true)

func _valid_saved_history(value: Dictionary) -> bool:
	var task_keys: Dictionary = {}
	for field: String in ["best","legacy"]:
		var summaries: Dictionary = value.get(field,{})
		if summaries.size() > MAX_TASKS: return false
		for key: Variant in summaries:
			if not _valid_task_key(key) or not _valid_saved_summary(key,summaries[key]): return false
			task_keys[key] = true
	var saved_conditions: Dictionary = value.get("conditions",{})
	if saved_conditions.size() > MAX_TASKS: return false
	for key: Variant in saved_conditions:
		if not _valid_task_key(key) or not saved_conditions[key] is Dictionary: return false
		task_keys[key] = true
		var bucket: Dictionary = saved_conditions[key]
		if bucket.size() > MAX_CONDITIONS: return false
		for signature: Variant in bucket:
			if not signature is String or signature.is_empty() or not _valid_saved_summary(key,bucket[signature]): return false
			var entry: Dictionary = bucket[signature]
			if entry.get("chapter_id") not in CYCLE_DOMAINS or _condition_id(entry) != signature or _cycle_value(entry) < 0: return false
	return task_keys.size() <= MAX_TASKS

func _valid_saved_summary(key: String, value: Variant) -> bool:
	if not value is Dictionary: return false
	# Persisted summaries are flat sanitizer output. Check names first so an
	# unsupported nested payload cannot be flattened or discarded during loading.
	var supported: Array = SafeContext.TEXT_FIELDS + SafeContext.NUMBER_FIELDS + SafeContext.BOOL_FIELDS + SafeContext.SUMMARY.COUNTERS
	for field: Variant in value:
		if field not in supported: return false
	var safe: Dictionary = SafeContext.minimal_context(value)
	if safe.size() != value.size(): return false
	for field: String in value:
		if safe[field] != value[field]: return false
	if value.has("chapter_id") and value.chapter_id != key.get_slice("/",0): return false
	if value.has("level_id") and value.level_id != key.get_slice("/",1): return false
	if (value.has("cycles") or value.has("total_cycles")) and _cycle_value(value) < 0: return false
	return true

func _loaded_summaries(value: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in value:
		result[key] = SafeContext.minimal_context(value[key])
	return result

func _valid_task_key(value: Variant) -> bool:
	return value is String and value.length() < 100 and value.count("/") == 1 and not value.get_slice("/",0).is_empty() and not value.get_slice("/",1).is_empty()

func _has_task_capacity(key: String) -> bool:
	var task_keys: Dictionary = {}
	for entries: Dictionary in [best,conditions,legacy]:
		for existing: String in entries: task_keys[existing] = true
	return task_keys.has(key) or task_keys.size() < MAX_TASKS

func _protect_records(message: String) -> void:
	disk_write_allowed = false
	storage_status = "read_only"
	last_error = message

func _cycle_value(value: Dictionary) -> int:
	var cycles: Variant = value.get("cycles",value.get("total_cycles"))
	if not (cycles is int or cycles is float) or not is_finite(float(cycles)) or float(cycles) < 0 or float(cycles) > 1e10 or float(cycles) != floor(float(cycles)):
		return -1
	if value.has("cycles") and value.has("total_cycles"):
		var total: Variant = value.total_cycles
		if not (total is int or total is float) or not is_finite(float(total)) or float(total) != float(cycles): return -1
	return int(cycles)

func _condition_id(value: Dictionary) -> String:
	for field: String in ["chapter_id","level_id","model_version","case_set_version","task_version"]:
		if not value.get(field) is String or value[field] in ["","unspecified","unknown"]: return ""
	return JSON.stringify([
		value.chapter_id,value.level_id,value.model_version,value.case_set_version,
		value.task_version,value.get("ruleset_version","")
	]).sha256_text()

func _observe(event: Dictionary) -> void:
	if event.get("mode")!="game" or event.get("event")!="official_run": return
	if not event.get("payload") is Dictionary: return
	var p: Dictionary = event.payload
	if p.get("passed") != true or p.get("qualified_for_progression",true) != true or p.get("correct",true) != true: return
	var safe: Dictionary = SafeContext.minimal_context(event)
	var key: String = str(p.get("chapter_id",""))+"/"+str(p.get("level_id",""))
	if not _valid_task_key(key) or not _has_task_capacity(key): return
	if p.get("chapter_id") == "hardware_foundations":
		if not safe.has("case_count"): return
		safe["passed_cases"] = safe.case_count
		safe.erase("cycles")
		safe.erase("total_cycles")
		best[key] = safe
		_save_records()
		return
	if p.get("chapter_id") not in CYCLE_DOMAINS: return
	# Validate before the transport sanitizer can round fractional or drop invalid values.
	var measured: Dictionary = event.duplicate(true)
	measured.merge(p,true)
	if measured.get("metrics") is Dictionary: measured.merge(measured.metrics,true)
	var cycles: int = _cycle_value(measured)
	if cycles < 0: return
	safe["cycles"] = cycles
	var signature: String = _condition_id(safe)
	if signature.is_empty():
		# An identity-less result is an observation, never a comparable minimum.
		if not legacy.has(key): legacy[key] = safe
		if not best.has(key): best[key] = safe
		_save_records()
		return
	var bucket: Dictionary = conditions.get(key,{})
	var prior: Dictionary = bucket.get(signature,{})
	if not prior.is_empty() and cycles >= _cycle_value(prior):
		# The selected workload can change without improving its retained minimum.
		var projection_changed: bool = best.get(key,{}) != prior
		best[key] = prior.duplicate(true)
		if projection_changed or storage_status == "write_failed": _save_records()
		return
	if not best.get(key,{}).is_empty() and _condition_id(best[key]).is_empty() and not legacy.has(key):
		legacy[key] = best[key].duplicate(true)
	if not bucket.has(signature) and bucket.size() >= MAX_CONDITIONS:
		bucket.erase(bucket.keys()[0])
	bucket[signature] = safe.duplicate(true)
	conditions[key] = bucket
	best[key] = safe
	_save_records()

func _save_records() -> bool:
	if not disk_write_allowed: return false
	var text: String = JSON.stringify({"schema_version":1,"best":best,"conditions":conditions,"legacy":legacy})
	if text.to_utf8_buffer().size() >= MAX_FILE_BYTES:
		storage_status = "write_failed"
		last_error = "Personal records exceed the safe file size."
		return false
	var file := FileAccess.open(storage_path+".tmp",FileAccess.WRITE)
	if file == null:
		storage_status = "write_failed"
		last_error = "Could not write personal records: "+error_string(FileAccess.get_open_error())
		return false
	file.store_string(text)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		storage_status = "write_failed"
		last_error = "Could not finish personal records: "+error_string(write_error)
		return false
	var rename_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(storage_path+".tmp"),ProjectSettings.globalize_path(storage_path))
	if rename_error != OK:
		storage_status = "write_failed"
		last_error = "Could not replace personal records: "+error_string(rename_error)
		return false
	storage_status = "ready"
	last_error = ""
	return true

func snapshot(task_rows: Array[Dictionary] = []) -> Dictionary:
	var result: Dictionary = {"total":0,"completed":0,"main_total":0,"main_completed":0,"side_total":0,"side_completed":0,"regions":[],"tasks":[],"bonus_total":0,"bonus_completed":0,"saved_schemes":0}
	if task_rows.is_empty(): task_rows=TaskNavigation.game_tasks()
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
		row["historical_best"]=best.get(task.key,legacy.get(task.key,{})).duplicate(true)
		row["best"]={}
		row["record_kind"]="none" if row.historical_best.is_empty() else "historical"
		row["condition_count"]=conditions.get(task.key,{}).size()
		if task.domain=="hardware_foundations" and row.historical_best.get("passed",false) and row.historical_best.has("case_count"):
			row.best=row.historical_best.duplicate(true)
			row.best["passed_cases"]=row.best.case_count
			row.record_kind="observed"
		if task.domain=="chapter_2":
			var observation: Dictionary = LocalityChapter.best_observation_for(StringName(task.id),&"game")
			if not observation.is_empty():
				row.best=observation.metrics.duplicate(true)
				row.best["cycles"]=int(row.best.total_cycles)
				row.best["condition_id"]=observation.condition_id
				row.record_kind="replayed"
		if task.domain=="chapter_4" and LayoutChapter.game_solutions.has(task.id):
			var report: Dictionary = Catalog.evaluate(task.id,LayoutChapter.game_solutions[task.id])
			if report.passed:
				row.best={"cycles":LayoutChapter.cost(report),"ram_read_bytes":0,"ram_write_bytes":0,"peak_extra_bytes":0,
					"model_version":Catalog.Simulator.MODEL_VERSION,
					"case_set_version":("layout-v1:"+str(task.id)+JSON.stringify(Catalog.cases(task.id))).sha256_text()}
				row.record_kind="replayed"
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
