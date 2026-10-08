extends SceneTree
const Model = preload("res://experiments/creation/model.gd")
var failures: int = 0
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func control(scene: Control,id: String) -> Control: return scene.find_child(id,true,false) as Control
func press(scene: Control,id: String) -> void:
	var action := control(scene,id) as Button
	check(action != null and not action.disabled,"Available action: "+id)
	if action != null and not action.disabled:
		var ancestor: Node = action.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(action)
			ancestor = ancestor.get_parent()
		await settle()
		if DisplayServer.get_name() == "headless": action.pressed.emit()
		else:
			var point: Vector2 = action.get_global_rect().get_center()
			check(root.get_visible_rect().has_point(point),"Viewport click is on screen: "+id)
			var motion := InputEventMouseMotion.new(); motion.position = point; root.push_input(motion,true)
			for down: bool in [true,false]:
				var mouse := InputEventMouseButton.new(); mouse.position = point; mouse.button_index = MOUSE_BUTTON_LEFT; mouse.pressed = down
				root.push_input(mouse,true)
				await process_frame
	await settle()
func bounds(scene: Control,ids: Array) -> void:
	var view: Rect2 = root.get_visible_rect()
	for id: String in ids:
		var node: Control = control(scene,id)
		check(node != null and node.is_visible_in_tree(),"Visible operation: "+id)
		if node != null: check(view.encloses(node.get_global_rect()),"1280x720 bounds: "+id+" "+str(node.get_global_rect()))
func capture(name: String) -> void:
	if not "--creation-capture" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var picture: Image = root.get_texture().get_image()
	var folder: String = "res://.godot/creation-captures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	check(picture != null and picture.save_png(folder.path_join(name+".png")) == OK,"Capture: "+name)
func run() -> void:
	var localization: Node = root.get_node("Localization")
	root.get_node("TaskNavigation").pending = ""
	root.get_node("TaskNavigation").from_tree = false
	var packed: PackedScene = load("res://experiments/creation/workbench.tscn")
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		var scene: Control = packed.instantiate(); root.add_child(scene); await settle()
		root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
		var session: RefCounted = scene.get("session")
		if locale == "en":
			check(not session.data.works.is_empty(),"Reopening retains confirmed work")
			if not session.data.works.is_empty(): check(session.replay_work(0).get("matches",false),"Reopened full recipe matches snapshot")
		session.data.mode = "compress"; scene.call("change_task",0); await settle()
		for unit: int in [1,2,4,5,7,8]:
			scene.call("change_task",unit); await settle()
			bounds(scene,["Language","SaveDraft","Journey","Train","ModeActions","SignalView","MachineResources","Status"])
		scene.call("change_task",0); await settle()
		bounds(scene,["Language","SaveDraft","Journey","Train","Transport","Raw","ToPredict","SignalView","MachineResources","Status"])
		await press(scene,"Train")
		check(not session.data.model.is_empty(),"Learn creates real sample-derived rules")
		var inherited: String = Model.identity(session.data.model)
		await press(scene,"Transport")
		check(scene.get("latest").get("lossless",false),"Transport restores actual packet exactly")
		var before: Array = scene.get("latest").output.duplicate()
		await press(scene,"PlaybackStep"); check(scene.get("latest").output == before,"Playback cannot change output")
		await capture("compress-"+locale)
		session.data.draft.machine.memory_bytes = 64; scene.call("edit_draft"); await press(scene,"Transport")
		check(scene.get("latest").is_empty() and ((control(scene,"Status") as Label).text.contains("内存") or (control(scene,"Status") as Label).text.contains("memory")),"Memory failure has explicit feedback, with no new successful trace")
		await capture("memory-failure-"+locale)
		session.data.draft.machine.memory_bytes = 8192; scene.call("edit_draft"); await press(scene,"Transport")
		await press(scene,"ToPredict")
		check(Model.identity(session.data.model) == inherited and session.data.mode == "predict","C→P retains actual model")
		await press(scene,"Practice")
		bounds(scene,["Practice","Check","Commit","Reveal","SignalView","Status"])
		await press(scene,"Commit")
		check(session.prediction.prefix.size() == 2 and session.prediction.rows.is_empty(),"Commit reveals no truth")
		check(scene.get("signal_view").lanes[0].size() == 2 and scene.get("signal_view").lanes[1].size() == 3,"Tracks show observed prefix and pending guess only")
		await capture("prediction-"+locale)
		for step: int in 16:
			if session.prediction.get("finished",false): break
			if session.prediction.pending.is_empty(): await press(scene,"Commit")
			await press(scene,"Reveal")
		check(session.prediction.get("finished",false),"Commit/reveal completes real practice")
		check(Model.identity(session.data.model) == inherited,"Reveal never trains rules")
		scene.call("change_task",6); await settle(); await press(scene,"ToGenerate")
		check(Model.identity(session.data.model) == inherited and session.data.mode == "generate","P→G retains actual model and changes feedback")
		await press(scene,"Generate")
		check(not session.generated.is_empty() and session.generated.output.size() == session.data.draft.length,"Generation produces configured real output")
		bounds(scene,["Generate","ToGenerate","KeepCurrent","SignalView","Status"]); await capture("generation-"+locale)
		scene.call("change_task",8); await settle()
		bounds(scene,["WorkName","KeepCurrent","Generate","SignalView","Status"])
		(control(scene,"WorkName") as LineEdit).text = "QA · "+locale; await press(scene,"KeepWork")
		check(not session.data.works.is_empty() and not session.dirty,"UI saves named work and recipe")
		var index: int = session.data.works.size()-1; (control(scene,"Works") as ItemList).select(index)
		var protected_output: Array = session.data.works[index].output.duplicate()
		await press(scene,"PlayWork"); check(scene.get("latest").output == protected_output,"Playback reads protected snapshot")
		await press(scene,"ReplayWork"); check(scene.get("latest").get("matches",false),"Full recipe action reproduces output")
		await press(scene,"ForkWork")
		check(session.data.works[index].output == protected_output and session.data.parent_work == session.data.works[index].id,"Fork protects parent and records lineage")
		await capture("works-"+locale)
		if "--creation-capture" in OS.get_cmdline_user_args():
			var artifact := FileAccess.open("res://.godot/creation-captures/qa-work-"+locale+".json",FileAccess.WRITE)
			check(artifact != null,"QA work export opens")
			if artifact != null: artifact.store_string(JSON.stringify(session.data.works[index],"\t")); artifact.close()
		session.save(); scene.queue_free(); await settle()
	if failures == 0: print("PASS: creation workbench checks=",checks)
	else: print("FAIL: creation workbench failures=",failures," / ",checks)
	quit(0 if failures == 0 else 1)
