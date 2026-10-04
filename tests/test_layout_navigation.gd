extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func settle() -> void:
	for frame: int in range(8): await process_frame
func clear_scene() -> void:
	if current_scene != null: current_scene.queue_free(); current_scene=null
	await settle()
func card() -> void:
	var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene=hub
	await settle()
	hub.find_child("ChapterEntry_layout",true,false).pressed.emit()
	await settle()
func run() -> void:
	var nav: Node=root.get_node("TaskNavigation")
	var mode: Node=root.get_node("GameMode")
	var layout: Node=root.get_node("LayoutChapter")
	var locality: Node=root.get_node("LocalityChapter")
	mode.set_mode(&"game")
	# Synthetic prerequisite only: navigation must not grant any completion.
	locality.game_completed[&"capstone"]=true
	var completion_before: Dictionary=layout.completed().duplicate(true)
	nav.selected="hardware_foundations/tutorial"; nav.camera_saved=true
	await card()
	check(current_scene.get("level")=="fields","Chapter card chooses the first unfinished available task")
	check(nav.selected=="chapter_4/fields" and not nav.camera_saved,"Direct entry replaces stale selection and requests recentering")
	current_scene._leave(); await settle()
	check(current_scene.get("selected").get("key","")=="chapter_4/fields","First card entry returns to its current tree node")
	check(layout.completed()==completion_before,"Opening and returning never awards completion")
	# The ordinary tree route must retain the player's camera.
	nav.camera=Vector2(123,456); nav.camera_view_size=Vector2(900,600); nav.camera_saved=true
	check(nav.enter("chapter_4/fields"),"Available selected node enters")
	await settle()
	check(nav.camera_saved and nav.camera==Vector2(123,456),"Matching tree entry preserves camera")
	current_scene._leave(); await settle()
	check(nav.selected=="chapter_4/fields","Matching tree selection survives return")
	# Reload the independent navigation preference as a new launch does.
	nav.last_visited_task=""; nav.selected="hardware_foundations/tutorial"; nav._ready(); nav.prepare_continue()
	check(nav.selected=="chapter_4/fields","Reloaded Continue locates the visited task")
	check(layout.completed()==completion_before,"Tree entry and Continue preserve completion")
	await clear_scene()
	# A card still chooses the next unfinished task rather than stale tree selection.
	layout.game_solutions["fields"]=preload("res://src/layout_chapter/layout_catalog.gd").reference_solution("fields")
	var next_before: Dictionary=layout.completed().duplicate(true)
	await card()
	check(current_scene.get("level")=="records" and nav.selected=="chapter_4/records","Card chooses and selects the next unfinished task")
	current_scene._leave(); await settle()
	check(current_scene.get("selected").get("key","")=="chapter_4/records","Next unfinished task is selected on return")
	check(layout.completed()==next_before,"Next-task navigation preserves completed progress")
	await clear_scene()
	layout.game_solutions.clear()
	# Rejected task entry and unavailable chapter must not replace selection.
	locality.game_completed.clear()
	nav.selected="hardware_foundations/tutorial"; nav.camera_saved=true
	check(not nav.enter("chapter_4/mixed") and not nav.enter("chapter_4/missing"),"Locked and unknown nodes reject entry")
	await card()
	check(current_scene.scene_file_path==nav.MAP_SCENE,"Unavailable direct chapter returns to tree")
	check(nav.selected=="hardware_foundations/tutorial","Unavailable chapter preserves selection")
	check(layout.completed()==completion_before,"Rejected routes preserve completion")
	await clear_scene()
	for failure: String in failures: push_error(failure)
	print("PASS: layout card return, selected tree route, persisted Continue and unavailable navigation" if failures.is_empty() else "FAIL: layout navigation")
	quit(0 if failures.is_empty() else 1)
