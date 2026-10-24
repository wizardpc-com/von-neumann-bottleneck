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
	var remote: Node = root.get_node("RemoteFeedback")
	remote.endpoint=""
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
		check(moments.send_opinion.disabled and moments.opinion_status.text.contains(root.get_node("Localization").text(&"sharing.not_configured_in_this_build_save_and_export_still_work")),"Unconfigured sending explains local alternatives "+locale)
		moments.opinion.text="Keep this draft"
		moments.target.source_commit="1234567890abcdef"
		moments._refresh_language()
		check(moments.context_label.text.contains("12345678") and moments.opinion.text=="Keep this draft","Identity refresh preserves an unfinished opinion "+locale)
		remote.endpoint="https://feedback.example.test"
		remote.status="offline"; moments._remote_updated()
		check(not moments.send_opinion.disabled,"Configured endpoint remains available for offline retry "+locale)
		remote.endpoint=""; moments._remote_updated()
		moments.saved_opinion={"source_commit":"older-root","payload":{"build_version":"saved-build","source_commit":"abcdef1234567890","note":moments.opinion.text,"category":moments.CATEGORIES[moments.category.selected]}}
		moments._remote_updated()
		check(moments.context_label.text.contains("saved-build") and moments.context_label.text.contains("abcdef12"),"Unedited saved opinion retains the identity actually sent "+locale)
		moments.opinion.text+=" revised"; moments._remote_updated()
		check(moments.context_label.text.contains("12345678") and moments.saved_opinion.payload.source_commit=="abcdef1234567890","Editing switches to current context without rewriting the saved event "+locale)
		moments.saved_opinion={}
		var entry := scene.find_child("MomentFeedbackButton",true,false) as Control
		check(entry != null and Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(entry.get_global_rect()),"Visible candidate feedback fits at minimum viewport "+locale)
		if "--feedback-capture" in OS.get_cmdline_user_args():
			await process_frame
			DirAccess.make_dir_recursive_absolute("res://.godot/feedback-captures")
			root.get_texture().get_image().save_png("res://.godot/feedback-captures/"+locale+".png")
		moments.close(); scene.queue_free(); await settle()
	print("PASS: bilingual first-screen feedback and minimum viewport" if failures.is_empty() else "FAIL: feedback first screen")
	quit(0 if failures.is_empty() else 1)
