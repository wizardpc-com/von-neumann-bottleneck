class_name LayoutCatalog
extends RefCounted
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const IDS: Array[String] = ["fields","records","hot_cold","relocation","batches","mixed"]
const DEPS := {"fields":[],"records":["fields"],"hot_cold":["records"],"relocation":["fields"],"batches":["relocation"],"mixed":["hot_cold","batches"]}
const TITLES := ["只取所需", "一窥全貌", "冷热有别", "搬迁有价", "化整为零", "两全之策"]
const EN_TITLES := ["Only what we need","One record, all fields","Hot and cold","Moving has a cost","Make it fit in batches","One layout, two workloads"]
const GOALS := [
	"这一轮只统计温度。保留全部记录和字段，让一趟搬运带回更多有用的温度。",
	"改为抽查少数记录，每条都要四个字段。上一关的布局还适合吗？",
	"温度与告警常一起使用，编号与电量偶尔抽查。为冷热两类访问设计布局。",
	"数据按记录送来。一次查询与反复查询是两张订单，分别决定是否值得先复制整理。",
	"只有 48 B 临时空间。17 条记录不能整齐分完；每条数据都必须恰好参与计算。",
	"相同方案要同时处理反复统计与稀疏抽查。选择整理哪些字段、何时分批，也可以保留原布局。"]
const EN_GOALS := [
	"Sum temperatures. Keep every record and field; bring back more useful data in each transfer.",
	"Inspect a few records, reading all four fields. Does the previous layout still help?",
	"Temperature and alarm are frequently read together; ID and battery are inspected occasionally.",
	"Incoming data is record-major. Choose separately for a single query and repeated queries; count copying too.",
	"Only 48 B of scratch space for 17 records. Process the final partial batch without missing or duplicating data.",
	"Use the same design for repeated scans and sparse inspections. Choose fields to copy and batch size, or read directly."]

static func title(id: String) -> String:
	var i: int = IDS.find(id)
	return (TITLES if TranslationServer.get_locale().begins_with("zh") else EN_TITLES)[i] if i>=0 else id

static func goal(id: String) -> String:
	var i: int = IDS.find(id)
	return (GOALS if TranslationServer.get_locale().begins_with("zh") else EN_GOALS)[i] if i>=0 else ""

static func unlocked(id: String, done: Dictionary, ready: bool, test: bool = false) -> bool:
	if id not in IDS: return false
	if test: return true
	if not ready: return false
	for dep: String in DEPS[id]:
		if not done.has(dep): return false
	return true

static func starter_design() -> Dictionary:
	return {"recipe":Recipe.record_major(),"strategy":"direct","copy_fields":[0],"batch":4}

static func records(count: int, salt: int = 0) -> Array:
	var result: Array = []
	for i: int in range(count): result.append([10+(i*7+salt)%23,100+i+salt,30+(i*11+salt)%70,(i+salt)%2])
	return result

static func cases(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if id not in IDS: return result
	for variant: int in range(2):
		var count: int = (8 if variant == 0 else 12) if id in ["fields","records"] else 16 if id == "hot_cold" else 17
		var query: Dictionary = {"kind":"sum","fields":[0],"repeat":1}
		var queries: Array = [query]
		match id:
			"records": query.merge({"kind":"records","fields":[0,1,2,3],"indices":[1,5] if variant == 0 else [0,5,10]},true)
			"hot_cold":
				query.merge({"fields":[0,3],"repeat":3},true)
				queries.append({"kind":"records","fields":[1,2],"indices":[1,9] if variant == 0 else [3,13]})
			"relocation": query.repeat = 1 if variant == 0 else 8
			"batches": query.repeat = 8
			"mixed":
				query.merge({"fields":[0,3],"repeat":8 if variant == 0 else 3},true)
				queries.append({"kind":"records","fields":[0,1,2,3],"indices":[1,9] if variant == 0 else [0,3,6,9,12,16]})
		result.append({"name":["A","B"][variant],"records":records(count,variant*3),"queries":queries,
			"native_layout":id in ["fields","records","hot_cold"],"scratch_limit":48 if id == "batches" else 160,
			"target_cycles": {"fields":[0,0],"records":[0,0],"hot_cold":[640,640],"relocation":[307,1400],"batches":[1100,1100],"mixed":[2450,1550]}[id][variant],"target_bytes": {"fields":[64,96],"records":[64,96]}.get(id,[0,0])[variant]})
	return result

static func evaluate(id: String, design: Dictionary) -> Dictionary:
	var runs: Array[LayoutRun] = []
	var passed: bool = id in IDS
	for task: Dictionary in cases(id):
		# The relocation lesson explicitly has two independent orders. Every other task uses one recipe.
		var chosen: Dictionary = design.get("orders",{}).get(task.name,design) if id == "relocation" else design
		var trace: LayoutRun = Simulator.new().run(task,chosen)
		runs.append(trace)
		var target_met: bool = trace.passed and (int(task.target_cycles)<=0 or int(trace.metrics.total_cycles)<=int(task.target_cycles)) and (int(task.target_bytes)<=0 or int(trace.metrics.ram_read_bytes)+int(trace.metrics.ram_write_bytes)<=int(task.target_bytes))
		trace.metrics["target_met"] = target_met
		passed = passed and target_met
	return {"passed":passed,"runs":runs}

# Read-only Hint 3 / test fixture. Normal entry always starts with seed or the player's own draft.
static func reference_solution(id: String) -> Dictionary:
	var design: Dictionary = starter_design()
	if id == "fields": design.recipe = Recipe.field_major()
	if id in ["hot_cold","mixed"]:
		design.recipe = {"groups":[{"fields":[0,3],"order":"record"},{"fields":[1,2],"order":"record"}],"block":0}
	if id in ["relocation","batches","mixed"]:
		design.strategy = "full" if id == "relocation" else "batch"
		if id == "mixed": design.copy_fields = [0,3]
		else: design.recipe = Recipe.field_major()
	if id == "relocation":
		var repeated: Dictionary = design.duplicate(true)
		design = starter_design()
		design["orders"] = {"A":starter_design(),"B":repeated}
	return design
