extends SceneTree
## Observational benchmark only; run from a copied project with an isolated QA profile.
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
func _init() -> void: call_deferred("run")
func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated QA project/profile."); quit(1); return
	var report: Array[Dictionary] = []
	for task: String in Catalog.IDS:
		for variant: String in ["starter","reference","full","batch1"]:
			var design: Dictionary = Catalog.starter_design() if variant == "starter" else Catalog.reference_solution(task)
			if variant == "full": design.strategy = "full"
			if variant == "batch1": design.strategy = "batch"; design.batch = 1
			var candidates: Array[Dictionary] = []
			for index: int in range(26):
				candidates.append({"id":str(index),"title":"Capacity "+str(index),"design":design.duplicate(true)})
			var elapsed_ms: Array[float] = []
			var rerank_ms: Array[float] = []
			var eligible: int = 0
			for objective: String in ["cycles","traffic","space"]:
				var start: int = Time.get_ticks_usec()
				var rows: Array[Dictionary] = Board.build_rows(task,candidates,objective)
				elapsed_ms.append(float(Time.get_ticks_usec()-start)/1000.0)
				assert(rows.size() == 26)
				start = Time.get_ticks_usec()
				var reranked: Array[Dictionary] = Board.rank_rows(rows,objective)
				rerank_ms.append(float(Time.get_ticks_usec()-start)/1000.0)
				assert(rows == reranked)
				eligible = 0
				for row: Dictionary in rows:
					if row.eligible: eligible += 1
			report.append({"task":task,"variant":variant,"candidates":26,"eligible":eligible,"elapsed_ms_cycles_traffic_space":elapsed_ms,"rerank_ms_cycles_traffic_space":rerank_ms})
	var output: Dictionary = {"engine":Engine.get_version_info().string,"os":OS.get_name(),"processor":OS.get_processor_name(),"repeats_per_library":3,"notes":"26 candidates = 24 named + current + best. Fixture libraries are repeated identical recipes, not exhaustive worst-case or UI frame timings. No pass/fail latency threshold.","libraries":report}
	var file := FileAccess.open("res://score-capacity.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	print("PASS: capacity probe completed ",report.size()," libraries of 26 candidates, 3 objectives each")
	quit()
