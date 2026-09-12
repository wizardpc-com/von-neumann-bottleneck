extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func run() -> void:
	var nav: Node=root.get_node("TaskNavigation")
	root.get_node("GameMode").set_mode(&"test")
	var last_visit: String=nav.last_visited_task
	for entry: Array in [["","hardware_foundations"],["system","chapter_1"],["locality","chapter_2"],["overlap","chapter_3"],["layout","chapter_4"]]:
		var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub); current_scene=hub
		for frame: int in range(4): await process_frame
		nav.from_tree=true; nav.pending="hardware_foundations/cpu"
		var button: Button=hub.find_child("ChapterEntry_"+entry[0],true,false)
		button.pressed.emit()
		for frame: int in range(8): await process_frame
		if current_scene==null or current_scene.scene_file_path!=nav.SCENES[entry[1]]:
			failures.append("Chapter card must reach its own scene: "+entry[1])
		if nav.from_tree or not nav.pending.is_empty() or nav.last_visited_task!=last_visit:
			failures.append("Card clears only transient tree routing, preserving Continue: "+entry[1])
		current_scene.queue_free(); current_scene=null
		await process_frame
	for failure: String in failures: push_error(failure)
	print("PASS: all five chapter cards clear stale tree routes without changing Continue" if failures.is_empty() else "FAIL: chapter card routes")
	quit(0 if failures.is_empty() else 1)
