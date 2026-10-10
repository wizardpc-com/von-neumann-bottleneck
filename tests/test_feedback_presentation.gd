extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	var store: Node = root.get_node("PlaytestData")
	store.telemetry_enabled=true; store.questionnaire_enabled=true; store.start_session()
	var moments: Node = root.get_node("PlaytestMoments")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var scene: Variant = load("res://experiments/creation/workbench.tscn").instantiate()
		root.add_child(scene); scene.size=Vector2(1280,720); await settle()
		scene.change_task(7); moments.toggle(); await settle()
		var clip: Rect2 = moments.content_scroll.get_global_rect()
		for name: String in ["FeedbackCategory","SendTaskFeedback","KeepFeedbackLocally"]:
			var control := moments.panel.find_child(name,true,false) as Control
			check(control != null and control.is_visible_in_tree() and clip.encloses(control.get_global_rect()),"First screen control fits without scrolling "+locale+" "+name)
		check(clip.encloses(moments.opinion.get_global_rect()),"Optional opinion is on the first screen "+locale)
		check(moments.ratings[0].selected==0 and not moments.ratings[0].is_visible_in_tree(),"Ratings are unselected and optional "+locale)
		var entry := scene.find_child("MomentFeedbackButton",true,false) as Control
		check(entry != null and Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(entry.get_global_rect()),"Visible candidate feedback fits at minimum viewport "+locale)
		if "--feedback-capture" in OS.get_cmdline_user_args():
			await process_frame
			DirAccess.make_dir_recursive_absolute("res://.godot/feedback-captures")
			root.get_texture().get_image().save_png("res://.godot/feedback-captures/"+locale+".png")
		moments.close(); scene.queue_free(); await settle()
	print("PASS: bilingual first-screen feedback and minimum viewport" if failures.is_empty() else "FAIL: feedback first screen")
	quit(0 if failures.is_empty() else 1)
