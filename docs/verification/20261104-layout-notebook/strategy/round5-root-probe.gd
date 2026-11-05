extends SceneTree
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
func _init() -> void: call_deferred("probe")
func probe() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/"):
		quit(1)
		return
	var summary: Dictionary = {}
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		var rows: Array[Dictionary] = []
		var jobs: int = 0
		for q: Dictionary in task.queries: jobs += int(q.repeat)
		for group: int in range(1, (1 if task.release == "serial" else jobs)+1):
			for tile: int in range(1,18):
				for copy_choice: int in range(4):
					var plan: Dictionary = Model.starter_plan()
					plan.query_group = group
					plan.record_tile = tile
					if copy_choice > 0:
						plan.copy_mode = "full"
						plan.copy_fields = [0] if copy_choice == 1 else [0,3]
						plan.recipe = Recipe.field_major() if copy_choice == 3 else Recipe.record_major()
					var result: Dictionary = Model.evaluate(task,plan)
					if not result.valid or not result.run.passed:
						push_error("invalid candidate")
						quit(1)
						return
					var m: Dictionary = result.run.metrics
					rows.append({"plan":plan,"q1":m.first_request_cycles,"cycles":m.total_cycles,"ram":int(m.ram_read_bytes)+int(m.ram_write_bytes),"peak":m.peak_extra_bytes})
		var goals: Array[Dictionary] = []
		for limit: int in [350,400,450,500,600,900]:
			for space: int in [0,80,160]:
				var best: Dictionary = {}
				for row: Dictionary in rows:
					if row.q1 > limit or row.peak > space: continue
					if best.is_empty() or int(row.cycles) < int(best.cycles): best = row
				goals.append({"q1_limit":limit,"copy_limit":space,"best":best})
		summary[id] = {"count":rows.size(),"goals":goals}
	var file := FileAccess.open("user://round5-root-probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(summary,"\t",true))
	file.close()
	print("PASS: round5 root envelope probe ",OS.get_user_data_dir())
	quit(0)
