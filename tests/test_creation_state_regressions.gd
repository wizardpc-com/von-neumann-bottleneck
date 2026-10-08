extends SceneTree
## Controller regression only; headless execution is not native/visual acceptance.
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func run() -> void:
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	var session = scene.session
	check(session.train().ok and session.transport([0,1,0,2],"predictive").ok, "Prepare learned and restored model")
	check(session.set_mode("predict").ok and session.begin_prediction("practice").ok, "Prepare prediction")
	while not session.prediction.finished:
		session.commit_prediction(); session.reveal_prediction()
	check(session.set_mode("generate").ok, "Connect output feedback")
	scene.change_task(8); await settle()
	scene.generate_work(); await settle()
	var a: Array = session.generated.output.duplicate()
	scene.name_input.text = "Visible A"
	scene.keep_work(); await settle()
	check(session.data.works.size() == 1 and session.data.works[0].output == a, "Visible generation A is saved")
	session.data.draft.seed = 891
	scene.generate_work(); await settle()
	var b: Array = session.generated.output.duplicate()
	check(a != b and scene.can_keep_visible_work(), "Different generated B is eligible while visible")
	scene.works.select(0); scene.play_work(); await settle()
	check(scene.latest.output == a and not scene.can_keep_visible_work(), "Protected A snapshot is visible and save is unavailable")
	for id: String in ["KeepWork", "KeepCurrent"]:
		check(scene.find_child(id,true,false).disabled, "Save control disabled during snapshot: "+id)
	scene.name_input.text = "Must not save hidden B"
	scene.keep_work()
	check(session.data.works.size() == 1 and session.generated.output == b, "Direct handler cannot save hidden B; draft B remains intact")
	scene.works.select(0); scene.replay_work(); await settle()
	scene.keep_work()
	check(session.data.works.size() == 1, "Recipe replay cannot save hidden B")
	scene.generate_work(); await settle()
	scene.name_input.text = "Visible B"
	scene.keep_work()
	check(session.data.works.size() == 2 and session.data.works[1].output == b, "Generating again re-enables save of visible B")
	scene.change_task(3); await settle()
	check(not scene.can_keep_visible_work() and scene.find_child("KeepWork",true,false).disabled, "Prediction tracks cannot save a hidden generation after task navigation")
	scene.change_task(8); await settle()
	var view = scene.signal_view
	view.size.x = 1186
	view.cursor = 47; view.page = 0; scene.playing = true
	for i: int in 5: scene._process(0.23)
	check(view.cursor == 52 and view.page == 1, "64-cell playback follows cursor 52 onto second 48-cell page")
	scene.browse_page(-1)
	check(not scene.playing and view.page == 0 and view.cursor == 52, "Manual browse pauses while retaining cursor")
	scene._process(1.0)
	check(view.page == 0 and view.cursor == 52, "Paused browsing remains stable")
	scene.toggle_playback()
	check(scene.playing and view.page == 1, "Resume restores cursor-following page immediately")
	scene.browse_page(-1); scene.step_playback()
	check(not scene.playing and view.cursor == 53 and view.page == 1, "Step follows cursor while staying paused")
	view.cursor = 63; scene.playing = true; scene._process(0.23)
	check(not scene.playing and view.cursor == -1 and view.page == 1, "Playback completion keeps last page for inspection")
	scene.toggle_playback()
	check(scene.playing and view.cursor == 0 and view.page == 0, "Restart follows the first output cell")
	scene.playing = false
	session.mark_dirty(); scene.refresh()
	check(not scene.can_keep_visible_work() and scene.find_child("KeepCurrent",true,false).disabled, "Changed recipe disables stale visible generation saving")
	scene.queue_free(); await settle()
	print("PASS: creation state regressions %d checks" % checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
