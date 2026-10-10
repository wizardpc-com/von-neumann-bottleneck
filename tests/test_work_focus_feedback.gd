extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 5: await process_frame
func run() -> void:
	var host_script: Script = load("res://experiments/creation/workbench.gd")
	if host_script == null or not host_script.can_instantiate():
		push_error("Creation workbench did not compile"); quit(1); return
	var scene: Variant = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	check(scene.writable,"Isolated candidate writer is available")
	scene.train_model(); scene.transport("predictive"); scene.switch_mode("predict")
	scene.begin_prediction("practice"); scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction()
	scene.switch_mode("generate"); scene.generate_work(); scene.name_input.text="Private fixture work"; scene.keep_work(); await settle()
	check(not scene.kept_work.is_empty(),"Real generated work is transactionally kept")
	if scene.kept_work.is_empty(): scene.queue_free(); await settle(); quit(1); return
	scene.show_saved_work(scene.kept_work); await settle()
	var exhibit: Variant = scene.work_focus
	check(exhibit != null and exhibit.find_child("WorkFocusFeedback",true,false)!=null,"Saved-work exhibit exposes feedback")
	var saved_bytes: String = FileAccess.get_file_as_string(scene.session.path)
	exhibit.cursor=3; exhibit.static_overview=false; exhibit.playing=true; exhibit.sync_presentation()
	exhibit.request_feedback.emit(); await settle()
	var moments: Node = root.get_node("PlaytestMoments")
	check(not exhibit.visible and not exhibit.playing and moments.panel.visible,"Feedback pauses and hides the existing exhibit")
	check(moments.target.chapter_id=="creation" and moments.target.level_id=="G1_feedback","Work feedback has the actual foreground creation task")
	moments.close(); await settle()
	check(exhibit==scene.work_focus and exhibit.visible and exhibit.cursor==3 and not exhibit.static_overview,"Feedback return preserves the same window and exact observation cursor")
	check(FileAccess.get_file_as_string(scene.session.path)==saved_bytes,"Feedback never writes the protected work/profile")
	exhibit.dismiss(); scene.queue_free(); await settle()
	print("PASS: saved-work feedback pauses and returns with protected cursor/profile" if failures.is_empty() else "FAIL: work-focus feedback")
	quit(0 if failures.is_empty() else 1)
