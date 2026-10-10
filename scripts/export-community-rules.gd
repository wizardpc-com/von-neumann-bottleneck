extends SceneTree
## Development export only; the receiver never loads or executes Godot.
func _init() -> void: call_deferred("run")
func run() -> void:
	var navigation: Node = root.get_node("TaskNavigation")
	var tasks: Array[String] = []
	for task: Dictionary in navigation.tasks(): tasks.append(task.key)
	var catalog = preload("res://src/layout_chapter/layout_catalog.gd")
	var rules: Dictionary = {"api_version":1,"task_version":"tasks-20260910-v1","tasks":tasks,
		"content_manifests":{
			"tasks-20260910-v1":{"tasks":tasks},
			"tasks-20261010-journey-v1":{"tasks":journey_keys(tasks),"identities":journey_identities(tasks)}},
		"boards":{"chapter_4/mixed":{"ruleset_version":"layout-mixed-1","model_version":"layout-memory-1",
		"case_set_version":("layout-v1:mixed"+JSON.stringify(catalog.cases("mixed"))).sha256_text(),
		"case_count":2,"cycle_limits":[2450,1550],"cycle_floors":[280,126],"scratch_limit":160}}}
	var file := FileAccess.open("res://server/community_rules.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rules,"  ")); file.close()
	print("Exported community manifest: ",tasks.size()," tasks")
	quit()

func journey_keys(core: Array[String]) -> Array[String]:
	var result: Array[String] = core.duplicate()
	var second = preload("res://src/campaign/second_act_tasks.gd")
	for domain: String in second.IDS:
		for index: int in second.IDS[domain].size(): result.append(second.key_for(domain,index))
	var creation = preload("res://src/campaign/creation_tasks.gd")
	for index: int in preload("res://experiments/creation/catalog.gd").IDS.size(): result.append(creation.key_for(index))
	return result

func journey_identities(core: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	var identity = preload("res://src/playtest/task_identity.gd")
	for key: String in journey_keys(core):
		if key in core: continue
		var fields: Dictionary = identity.metadata(key.get_slice("/",0),key.get_slice("/",1))
		result[key]={"model_version":fields.model_version,"case_set_version":fields.case_set_version}
	return result
