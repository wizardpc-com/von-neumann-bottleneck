extends SceneTree
## Explicit writer recovery UI preserves exploration and confirms destructive reload.
const Session = preload("res://experiments/creation/session.gd")
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func press(scene: Control, handle: String) -> void:
	var action := scene.find_child(handle,true,false) as Button
	check(action != null and not action.disabled,"Available writer action: "+handle)
	if action != null and not action.disabled:
		if DisplayServer.get_name() == "headless": action.pressed.emit()
		else:
			var point: Vector2 = action.get_global_rect().get_center()
			check(root.get_visible_rect().has_point(point),"Writer action in viewport: "+handle)
			for down: bool in [true,false]:
				var event := InputEventMouseButton.new()
				event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
				root.push_input(event,true); await process_frame
	await settle()
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--writer-capture" not in OS.get_cmdline_user_args(): return
	await settle(); RenderingServer.force_draw(false)
	var folder: String = "res://.godot/writer-captures"
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().get_size() == Vector2i(1280,720),"Writer capture is actual 1280 by 720")
	check(root.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"Writer UI capture")
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	if DisplayServer.get_name() != "headless": await create_timer(1.0).timeout
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout
	await settle()
	var owner = Session.new()
	check(owner.open().writable,"Isolated fixture owns default QA profile")
	check(owner.save() == OK,"Fixture persists readable profile")
	for english: bool in [false,true]:
		root.get_node("Localization").set_locale("en" if english else "zh_CN")
		var scene = load("res://experiments/creation/workbench.tscn").instantiate()
		root.add_child(scene); await settle()
		scene.english = english; scene.build(); await settle()
		check(not scene.writable,"Live owner's second UI is read-only")
		for handle: String in ["RetryWriter","ReloadSaved","SaveDraft","Journey"]:
			var control := scene.find_child(handle,true,false) as Control
			check(control != null and root.get_visible_rect().encloses(control.get_global_rect()),"Read-only controls fit 1280 in both locales: "+handle)
		await capture("read-only-"+str(english))
		scene.session.data.draft.seed += 8; scene.edit_draft(); scene.train_model(); scene.transport("predictive")
		(scene.find_child("WorkName",true,false) as LineEdit).text = "Unsubmitted title"
		(scene.find_child("CustomExample",true,false) as LineEdit).text = "B A B D"
		(scene.find_child("DraftTabs",true,false) as TabContainer).current_tab = 1
		var draft: Dictionary = scene.session.data.duplicate(true)
		var output: Dictionary = scene.latest.duplicate(true)
		await press(scene,"RetryWriter")
		check(not scene.writable and scene.session.data == draft and scene.latest == output,"Busy retry retains all visible exploration")
		check((scene.find_child("WorkName",true,false) as LineEdit).text == "Unsubmitted title" and (scene.find_child("CustomExample",true,false) as LineEdit).text == "B A B D" and (scene.find_child("DraftTabs",true,false) as TabContainer).current_tab == 1,"Busy retry retains unsubmitted fields and selected editor tab")
		owner.close(); await press(scene,"RetryWriter")
		check(scene.writable and scene.session.data == draft and scene.latest == output,"Released owner retry retains all visible exploration")
		check((scene.find_child("WorkName",true,false) as LineEdit).text == "Unsubmitted title", "Successful retry retains unsubmitted work title")
		check(not (scene.find_child("SaveDraft",true,false) as Button).disabled,"Successful retry enables save")
		check(scene.session.save() == OK,"Recovered UI writes retained draft")
		scene.session.close(); owner.open()
		owner.data.task = 2; owner.data.draft.seed += 1; owner.mark_dirty()
		check(owner.save() == OK,"Other window writes newer valid draft")
		var saved: String = FileAccess.get_file_as_string(owner.path)
		owner.close(); scene.retry_writer(); await settle()
		check(not scene.writable and scene.session.data == draft and scene.latest == output,"Changed disk retry retains UI and asks for explicit reload")
		await press(scene,"ReloadSaved")
		await capture("reload-confirm-"+str(english))
		check(scene.writer_dialog.visible and scene.session.data == draft,"Reload only opens confirmation before replacing exploration")
		scene.writer_dialog.canceled.emit(); await settle()
		check(scene.session.data == draft and scene.latest == output and FileAccess.get_file_as_string(scene.session.path) == saved,"Cancel preserves exploration and saved bytes")
		scene.pinned_creation = output.duplicate(true); scene.compared_creation = output.duplicate(true)
		scene.transport_comparisons.append({"fixture":"discarded"}); scene.observation_anchor = {"fixture":"discarded"}
		await press(scene,"ReloadSaved")
		scene.writer_dialog.confirmed.emit(); await settle()
		check(scene.writable and scene.task == 2 and scene.latest.is_empty() and scene.session.generated.is_empty(),"Confirmed reload adopts current saved profile and clears old results")
		check(scene.pinned_creation.is_empty() and scene.compared_creation.is_empty() and scene.transport_comparisons.is_empty() and scene.observation_anchor.is_empty(),"Confirmed reload clears evidence from discarded exploration")
		check(FileAccess.get_file_as_string(scene.session.path) == saved,"Reload never rewrites saved bytes")
		scene.queue_free(); await settle(); owner.open()
	owner.data.task = 0
	owner.train(); owner.transport([0,1,0,2],"predictive"); owner.complete("C1_restore")
	owner.set_mode("predict"); owner.begin_prediction()
	while not owner.prediction.finished: owner.commit_prediction(); owner.reveal_prediction()
	owner.complete("P1_commit"); owner.set_mode("generate"); owner.generate()
	check(owner.save_work("Recovery protected work").ok,"Recovery fixture saves actual protected output")
	var path: String = owner.path
	var raw: String = FileAccess.get_file_as_string(path)
	owner.close()
	var token: String = Crypto.new().generate_random_bytes(16).hex_encode()
	check(DirAccess.make_dir_absolute(Session.Lease.lock_path(path)) == OK,"Stopped-writer fixture lock")
	var file := FileAccess.open(Session.Lease.lock_path(path).path_join("owner.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"pid":2147483647,"token":token,"context":Session.Lease.local_context()})); file.close()
	file = FileAccess.open(path+".tmp.interrupted",FileAccess.WRITE); file.store_string(raw); file.close()
	root.get_node("Localization").set_locale("en")
	var recovery = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(recovery); await settle()
	recovery.english = true; recovery.build(); await settle()
	if Session.Lease.stopped_owner(path) == token:
		for handle: String in ["RetryWriter","ReloadSaved","RecoverWriter","RecoverProfile"]:
			var control := recovery.find_child(handle,true,false) as Control
			check(control != null and root.get_visible_rect().encloses(control.get_global_rect()),"Stopped and interrupted controls fit English 1280: "+handle)
		await capture("stopped-interrupted")
		await press(recovery,"RecoverWriter")
		check(recovery.writer_dialog.visible and not recovery.writable,"Stopped reclaim requires exact-owner confirmation")
		recovery.writer_dialog.confirmed.emit(); await settle()
		check(not recovery.writable and not recovery.recovery_choices.is_empty(),"Reclaim requires subsequent validated snapshot selection")
		await press(recovery,"RecoverProfile")
		check(recovery.recovery_dialog.visible and not recovery.writable,"Recovery copy requires explicit confirmation")
		await capture("recovery-copy")
		recovery.recovery_dialog.confirmed.emit(); await settle()
		check(recovery.writable and recovery.recovery_choices.is_empty() and recovery.session.replay_work(0).get("matches",false),"Explicit recovery restores reproducible protected work")
		check(recovery.latest.is_empty() and recovery.pinned_creation.is_empty(),"Recovery clears all discarded UI evidence")
	else:
		print("SKIP: stopped writer UI needs native owner query; no native UI claim")
	recovery.queue_free(); await settle()
	print("PASS: creation writer retry UI %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
