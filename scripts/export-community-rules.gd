extends SceneTree
## Development export only; the receiver never loads or executes Godot.
func _init() -> void: call_deferred("run")
func run() -> void:
	var navigation: Node = root.get_node("TaskNavigation")
	var tasks: Array[String] = []
	for task: Dictionary in navigation.tasks(): tasks.append(task.key)
	var catalog = preload("res://src/layout_chapter/layout_catalog.gd")
	var rules: Dictionary = {"api_version":1,"task_version":"tasks-20260910-v1","tasks":tasks,
		"boards":{"chapter_4/mixed":{"ruleset_version":"layout-mixed-1","model_version":"layout-memory-1",
		"case_set_version":("layout-v1:mixed"+JSON.stringify(catalog.cases("mixed"))).sha256_text(),
		"case_count":2,"cycle_limits":[2450,1550],"cycle_floors":[280,126],"scratch_limit":160}}}
	var file := FileAccess.open("res://server/community_rules.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rules,"  ")); file.close()
	print("Exported community manifest: ",tasks.size()," tasks")
	quit()
