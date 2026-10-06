extends SceneTree
## Historical filename: all chapter routes now use the shared task-map entry.
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func settle() -> void:
	for frame: int in range(8): await process_frame
func run() -> void:
	var nav: Node=root.get_node("TaskNavigation")
	root.get_node("GameMode").set_mode(&"test")
	var last_visit: String=nav.last_visited_task
	var save: Node=root.get_node("GlobalSave")
	var before: Dictionary=save._save_snapshot(); before.erase("saved_at_utc")
	for domain: String in ["hardware_foundations","chapter_1","chapter_2","chapter_3","chapter_4"]:
		var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub); current_scene=hub
		await settle()
		# The shared map route must replace stale routing with the task actually chosen.
		nav.from_tree=true; nav.pending="hardware_foundations/cpu"
		hub.find_child("HubBrowseJourney",true,false).pressed.emit()
		await settle()
		if current_scene==null or current_scene.scene_file_path!=nav.MAP_SCENE:
			failures.append("Unified Hub entry must reach the task map: "+domain)
			continue
		var chosen: String=""
		for task: Dictionary in current_scene.get("rows"):
			if task.domain==domain and task.unlocked: chosen=task.key; break
		if chosen.is_empty():
			failures.append("Original test-mode chapter remains available: "+domain)
			current_scene.queue_free(); current_scene=null; await process_frame
			continue
		current_scene._select(chosen)
		current_scene.get("enter_button").pressed.emit()
		await settle()
		if current_scene==null or current_scene.scene_file_path!=nav.SCENES[domain]:
			failures.append("Exact task-map route must reach its own chapter scene: "+domain)
		if not nav.from_tree or not nav.pending.is_empty() or nav.selected!=chosen or nav.last_visited_task!=last_visit:
			failures.append("Task route consumes stale pending, selects the real task and preserves test-mode Continue preferences: "+domain)
		if not nav.return_to_tree(): failures.append("Chapter route retains its task-map return destination: "+domain)
		await settle()
		if current_scene==null or current_scene.scene_file_path!=nav.MAP_SCENE or current_scene.get("selected").get("key","")!=chosen:
			failures.append("Returning selects the actual opened chapter task: "+domain)
		if current_scene!=null: current_scene.queue_free(); current_scene=null
		await process_frame
	var after: Dictionary=save._save_snapshot(); after.erase("saved_at_utc")
	if before!=after: failures.append("Opening and returning through all five task-map routes must not award campaign completion")
	for failure: String in failures: push_error(failure)
	print("PASS: all five original chapters use exact task-map entry and return without awarding progress" if failures.is_empty() else "FAIL: chapter card routes")
	quit(0 if failures.is_empty() else 1)
