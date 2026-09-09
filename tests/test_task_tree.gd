extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	var nav: Node = root.get_node("TaskNavigation")
	var rows: Array = nav.tasks()
	var keys: Dictionary = {}
	for row: Dictionary in rows:
		check(not keys.has(row.key),"Domain qualified IDs must be unique")
		keys[row.key] = row
	for row: Dictionary in rows:
		for dep: String in row.dependencies: check(keys.has(dep),"Every drawn dependency must be a real task")
	check(keys["hardware_foundations/tutorial"].unlocked,"Fresh players can start Tutorial")
	check(not keys["chapter_3/synthesis"].unlocked,"Global tree cannot bypass the original gates")
	check(not nav.enter("chapter_3/synthesis"),"Locked direct routing must reject")
	check(keys["chapter_1/assembly"].dependencies == ["hardware_foundations/load_store"],"Chapter bridge must expose its real prerequisite")
	check(keys["hardware_foundations/full_adder"].dependencies == ["hardware_foundations/half_adder"],"Optional branches cannot gate the main route")
	var scene: Control = load("res://src/campaign/task_tree.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._select("chapter_3/synthesis")
	check(scene.enter_button.disabled and not scene.details.text.is_empty(),"Locked nodes remain inspectable")
	scene.canvas.set_search("tutorial")
	scene.canvas.locate_match()
	check(nav.selected == "hardware_foundations/tutorial","Search locates the actual task")
	var camera_before: Vector2 = nav.camera
	scene.queue_free()
	await process_frame
	scene = load("res://src/campaign/task_tree.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	check(scene.canvas.pan == camera_before,"Returning to the map preserves the camera")
	scene.queue_free()
	await process_frame
	# Exercise the same pending route consumed by the ordinary host; no unlock mutation.
	nav.from_tree = true
	nav.pending = "hardware_foundations/tutorial"
	var host: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(host)
	for frame: int in range(5): await process_frame
	check(host.current_level_id == &"tutorial","Direct route must survive the host initial map construction")
	nav.from_tree = false
	host.queue_free()
	await process_frame
	for failure: String in failures: push_error(failure)
	print("PASS: task adapters, locked details, search, camera and ordinary host routing" if failures.is_empty() else "FAIL: task tree")
	quit(0 if failures.is_empty() else 1)
