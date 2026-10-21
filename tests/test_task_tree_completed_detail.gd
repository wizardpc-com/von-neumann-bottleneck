extends SceneTree
## Real test-mode accepted solutions exercise the extra ending-review footer.
## No game progress is granted; all persisted game state remains unchanged.
var failures: int=0
var checks: int=0
func _init() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func settle() -> void:
	for frame: int in 6:await process_frame
func snapshot() -> Dictionary:
	var value: Dictionary=root.get_node("GlobalSave")._save_snapshot()
	value.erase("saved_at_utc");return value
func run() -> void:
	var before: Dictionary=snapshot()
	root.get_node("GameMode").set_mode(&"test")
	var state: Node=root.get_node("OverlapChapter")
	var catalog=load("res://src/overlap_chapter/overlap_catalog.gd")
	for id: String in catalog.IDS:
		var solution: Dictionary=catalog.reference_solution(id)
		check(state.record_pass(id,solution.board,solution.program),"Test-mode reference is accepted under the real contract: "+id)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.size=Vector2i(1280,720);root.content_scale_size=root.size
		var scene: Control=load("res://src/campaign/task_tree.tscn").instantiate()
		root.add_child(scene);await settle()
		var review: Button=scene.find_child("TaskTreeCoreReview",true,false)
		check(is_instance_valid(review),"An accepted core path offers its real review")
		for task: Dictionary in scene.rows:
			scene._select(task.key);await settle()
			check(root.get_visible_rect().encloses(scene.detail_panel.get_global_rect()),"Completed-path panel stays inside the viewport: "+locale+str(task.key))
			check(scene.detail_scroll.size.y>=100,"Completed-path task retains reading space: "+locale+str(task.key))
			check(scene.detail_panel.get_global_rect().encloses(review.get_global_rect()),"Ending review remains reachable: "+locale+str(task.key))
		scene.queue_free();await settle()
	state.test_solutions.clear();state.test_routes.clear();state.test_drafts.clear()
	root.get_node("GameMode").set_mode(&"game")
	check(snapshot()==before,"Completed-path presentation leaves real game progression unchanged")
	print("PASS: " if failures==0 else "FAIL: ","test_task_tree_completed_detail ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
