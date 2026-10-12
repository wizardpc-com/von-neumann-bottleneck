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
	var selected_before_region: String = nav.selected
	scene._choose_region(3)
	check(scene.list_view.visible and not scene.detail_view.visible and nav.selected == selected_before_region,"Region choice opens readable tasks without changing the selected task")
	check(scene.list_rows.get_child_count() == 6,"Timing chapter exposes its six full task entries")
	for child: Node in scene.list_rows.get_children():
		var item := child as Button
		check(String(item.get_meta("task_key")).begins_with("chapter_3/"),"Region entries belong to the chosen chapter")
	scene.search.text="chapter_3/"
	scene._on_search_changed(scene.search.text)
	check(scene.list_view.visible and scene.list_rows.get_child_count() == 6,"Search exposes all clickable matching tasks")
	scene.search.text="no-such-task"
	scene._on_search_changed(scene.search.text)
	check(scene.list_rows.get_child_count() == 0 and scene.list_empty.visible,"Search explains an empty result")
	scene._choose_region(3)
	check(scene.search.text.is_empty() and scene.list_rows.get_child_count() == 6,"Choosing a chapter clears the search and restores its list")
	(scene.list_rows.get_child(0) as Button).pressed.emit()
	check(nav.selected == "chapter_3/arrival" and scene.detail_view.visible and scene.enter_button.disabled,"A locked list entry opens details without bypassing access")
	check(scene.prerequisite_rows.get_child_count() > 0,"Locked core task exposes a clickable real prerequisite")
	(scene.prerequisite_rows.get_child(0) as Button).pressed.emit()
	check(nav.selected == "chapter_2/capstone","Prerequisite link locates the actual earlier task")
	(scene.find_child("JourneyTaskListButton",true,false) as Button).pressed.emit()
	check(scene.list_view.visible and nav.selected == "chapter_2/capstone","Chapter task return keeps the current selection")
	check(scene._task_kind({"domain":"creation","optional":false}) != scene._t("main"),"Candidate creation route is not mislabeled as the required main route")
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
	scene = load("res://src/campaign/task_tree.tscn").instantiate()
	root.add_child(scene); current_scene=scene
	await process_frame
	var escape := InputEventKey.new(); escape.pressed=true; escape.keycode=KEY_ESCAPE
	scene._unhandled_key_input(escape)
	for frame: int in range(3): await process_frame
	check(current_scene != null and current_scene.scene_file_path=="res://src/ui/prototype_hub.tscn","Escape consumes input before removing the map from the tree")
	for failure: String in failures: push_error(failure)
	print("PASS: task adapters, locked details, search, camera and ordinary host routing" if failures.is_empty() else "FAIL: task tree")
	quit(0 if failures.is_empty() else 1)
