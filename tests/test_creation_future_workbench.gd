extends SceneTree
## Actual file recovery and fixture-driven UI/rendering, not native input evidence.
const Session = preload("res://experiments/creation/session.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func capture(name: String) -> void:
	if "--creation-future-work-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var folder: String = "res://.godot/creation-future-work-captures"
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"Capture unsupported recipe snapshot "+name)
func run() -> void:
	var base_path: String = "user://creation-future-workbench/"+Crypto.new().generate_random_bytes(8).hex_encode()
	var writer = Session.new()
	check(writer.open(base_path.path_join("original.json")).writable,"Own isolated original profile")
	check(writer.train().ok and writer.transport([0,1,0,2],"predictive").ok,"Learn and restore an actual source")
	writer.set_mode("predict"); writer.begin_prediction("practice")
	while not writer.prediction.finished: writer.commit_prediction(); writer.reveal_prediction()
	writer.set_mode("generate"); check(writer.generate().ok and writer.save_work("Future protected signal").ok,"Generate and save a real snapshot before upgrading metadata")
	var original: Dictionary = writer.data.duplicate(true)
	writer.close()
	for kind: String in ["future-model","future-sampler"]:
		var future: Dictionary = original.duplicate(true)
		var work: Dictionary = future.works[0]
		if kind == "future-model":
			work.recipe = {"version":99,"model":"future representation","initial":"future context","model_id":"future-model-id"}
		else:
			work.recipe.sampler_version = "future-v99"
			work.recipe.initial = [9]
		work.training = {"cost":"future cost representation","machine":"future machine"}
		var raw: String = JSON.stringify(future)
		var path: String = base_path.path_join(kind+".json")
		var file := FileAccess.open(path,FileAccess.WRITE)
		check(file != null,"Write isolated future recipe file")
		if file == null: continue
		file.store_string(raw); file.close()
		check(Session.decode(raw).get("readonly_works",[]).size() == 1,"Future recipe exposes legal output as read-only")
		for english: bool in [false,true]:
			root.get_node("TaskNavigation").pending = ""
			var scene = load("res://experiments/creation/workbench.tscn").instantiate()
			root.add_child(scene); await settle()
			root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
			if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(Vector2i(1280,720))
			scene.session.close()
			var opened: Dictionary = scene.session.open(path)
			check(opened.ok and not opened.writable and opened.error == "incompatible_readonly","Actual future file opens as a read-only work collection")
			scene.writable = false; scene.english = english; scene._clear_replaced_exploration(); scene.change_task(8); await settle()
			check(scene.latest.kind == "snapshot" and scene.signal_view.lanes[2] == work.output,"G3 automatically displays the preserved future snapshot")
			check(scene.signal_view.lanes[1].is_empty() and scene.rules.get_root().get_child_count() == 0,"Unknown initial context and model rules are not interpreted")
			check(scene.costs.text.contains("cannot be interpreted" if english else "暂不能解释") and scene.costs.text.contains(work.name) and scene.costs.text.contains(work.id),"Snapshot measurements identify the saved work and explain the version boundary")
			check(not scene.costs.text.contains("Canonical rule bytes" if english else "规则盒规范字节") and not scene.costs.text.contains("Recorded preparation" if english else "已记录准备"),"Unknown model and training metadata never become fake costs")
			scene.works.select(0); scene.play_work(); await settle()
			check(scene.latest.work == work and scene.signal_view.lanes[2] == original.works[0].output,"Explicit Play also shows the exact protected output")
			(scene.find_child("EvidenceTabs",true,false) as TabContainer).current_tab = 0
			await capture(kind+"-"+("en" if english else "zh"))
			scene.focus_work(); await settle()
			check(is_instance_valid(scene.work_focus) and scene.work_focus.canvas.output == work.output and scene.work_focus.recipe_label.text.contains("cannot be interpreted" if english else "暂不能解释"),"Focus exhibits the future work without parsing incompatible provenance")
			if is_instance_valid(scene.work_focus): scene.work_focus.dismiss()
			await settle()
			scene.replay_work(); scene.fork_work()
			check(scene.latest.kind == "snapshot" and scene.latest.work == work and scene.session.data.works[0] == work,"Rejected Replay/Fork keep the protected snapshot view intact")
			check(scene.session.save() != OK and FileAccess.get_file_as_string(path) == raw,"Read-only review and rejected actions preserve exact future file bytes")
			scene.queue_free(); await settle()
	print("PASS: creation future workbench %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
