extends SceneTree
const Model = preload("res://experiments/layout_strategy/model.gd")
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Notebook = preload("res://experiments/layout_strategy/notebook_store.gd")
const Targets = preload("res://experiments/layout_strategy/challenge_store.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/"))
	var samples: Array[Dictionary] = []
	var tasks: Dictionary = {}
	var states: Dictionary = {}
	var targets: Dictionary = {}
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		tasks[id] = task
		var jobs: int = 0
		for query: Dictionary in task.queries: jobs += int(query.repeat)
		var groups: Array[int] = [1]
		if task.release != "serial":
			groups.append(2)
			groups.append(jobs)
		var plans: Array[Dictionary] = []
		for group: int in groups:
			for tile: int in [1,4,17]:
				var plan: Dictionary = Model.starter_plan()
				plan.query_group = group
				plan.record_tile = tile
				plans.append(plan)
		for fields: Array in [[0],[3],[0,3],[0,1,2,3]]:
			for recipe: Dictionary in [Recipe.record_major(),Recipe.field_major()]:
				var plan: Dictionary = Model.starter_plan()
				plan.copy_mode = "full"
				plan.copy_fields = fields
				plan.recipe = recipe
				plans.append(plan)
		for plan: Dictionary in plans:
			var result: Dictionary = Model.evaluate(task,plan)
			assert(result.valid and result.run != null)
			var run: LayoutRun = result.run
			var codes: Array[Dictionary] = []
			for objective: String in ["cycles","traffic"]:
				var goal: Dictionary = Goals.default_goal()
				goal.objective = objective
				var exported: Dictionary = Code.create(id,plan,goal)
				codes.append({"goal":goal,"ok":exported.ok,"reason":exported.reason,
					"code":str(exported.get("code",""))})
			samples.append({"task":id,"plan":plan,"condition":run.case_signature,
				"plan_id":run.recipe_signature,"trace_id":run.canonical_signature().sha256_text(),
				"correct":run.passed,"metrics":run.metrics,"outputs":run.output_values,
				"expected":run.expected_values,"codes":codes})
		var draft: Dictionary = Model.starter_plan()
		draft.copy_mode = "full"
		draft.copy_fields = [0]
		var goal: Dictionary = {"objective":"traffic","first_limit":600,"copy_limit":80}
		states[id] = {"model":Model.MODEL_VERSION,"condition":Model.condition_id(task),
			"task":task,"draft":draft,"goal":goal,"kept":[
				{"name":"Legacy direct","plan":Model.starter_plan()},
				{"name":"Legacy copy","plan":draft}]}
		targets[id] = Code.create(id,Model.starter_plan(),goal).code
	var notebook: Dictionary = {"version":1,"active":"scan_serial","states":states}
	var target_file: Dictionary = {"version":1,"targets":targets}
	var store := Notebook.new()
	store.storage_path = "user://frozen-notebook-v1.json"
	assert(store.write(notebook).ok)
	var target_store := Targets.new()
	target_store.storage_path = "user://frozen-targets-v1.json"
	assert(target_store.write(target_file).ok)
	var fixture: Dictionary = {"base_commit":"e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8",
		"model":Model.MODEL_VERSION,"tasks":tasks,"samples":samples,
		"notebook_v1":FileAccess.get_file_as_string(store.storage_path),
		"targets_v1":FileAccess.get_file_as_string(target_store.storage_path)}
	var file := FileAccess.open("res://round7-frozen-baseline.json",FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(fixture,"  ",true)+"\n")
	file.close()
	print("PASS: froze %d original workload observations, exact codes and two actual v1 files" % samples.size())
	quit(0)
