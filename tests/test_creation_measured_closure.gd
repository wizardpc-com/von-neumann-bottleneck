extends SceneTree
## The live summary follows recorded evidence; closure watches the actual kept work.
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 8: await process_frame
func capture(name: String) -> void:
	if "--creation-contract-capture" not in OS.get_cmdline_user_args(): return
	if DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute("res://.godot/creation-contract-captures")
	check(root.get_texture().get_image().save_png("res://.godot/creation-contract-captures/"+name+".png") == OK,"Actual viewport capture "+name)
func click(scene: Control, name: String) -> void:
	# Refresh queues container layout; observe settled geometry before clicking.
	await settle()
	var action := scene.find_child(name,true,false) as Button
	check(action != null and action.is_visible_in_tree() and not action.disabled,"Visible action "+name)
	if action == null or action.disabled or not action.is_visible_in_tree(): return
	if DisplayServer.get_name() == "headless": action.pressed.emit()
	else:
		var point: Vector2 = action.get_global_rect().get_center()
		check(root.get_visible_rect().has_point(point),"Action fits viewport "+name)
		for down: bool in [true,false]:
			var event := InputEventMouseButton.new(); event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
			root.push_input(event,true); await process_frame
	await settle()
func check_cost(scene: Variant, cost: Dictionary, message: String) -> void:
	check(scene.measured_summary.text.contains("%s ops"%str(cost.cpu_ops)) and scene.measured_summary.text.contains("%s B"%str(cost.transfer_bytes)) and scene.measured_summary.text.contains(str(cost.total_cycles)),message)
func run() -> void:
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	check(scene.writable,"Measured closure requires a fresh writable isolated profile")
	if not scene.writable: scene.queue_free(); quit(1); return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
	for english: bool in [false,true]:
		scene.english = english; scene.change_task(0); await settle()
		scene.train_model(); check_cost(scene,scene.latest.cost,"Learning summary uses actual preparation cost")
		scene.source_kind = 2; scene.transport("predictive")
		var measured: Dictionary = scene.latest.duplicate(true)
		check_cost(scene,measured.cost,"Transport summary uses actual event totals")
		check(scene.measured_summary.text.contains("exact restoration" if english else "无损一致"),"Transport result is visible without opening measurements")
		scene.inspect_cell(3); await settle()
		check(scene.causal_tabs.current_tab == scene.causal_panel.get_index() and scene.measured_summary.is_visible_in_tree(),"Cause inspection leaves totals visible")
		check(root.get_visible_rect().encloses(scene.measured_summary.get_global_rect()),"Summary remains in 1280 viewport")
		await capture("summary-"+("en" if english else "zh"))
		scene.session.data.draft.machine.cpu_ops_per_cycle = 1; scene.edit_draft()
		check_cost(scene,measured.cost,"Unrun machine edit cannot relabel the prior measurement")
		scene.switch_mode("predict"); scene.begin_prediction("check"); scene.commit_prediction()
		var frozen: Dictionary = scene.latest.cost.duplicate(true)
		check_cost(scene,frozen,"Pending prediction summary uses committed frozen evidence")
		check(scene.measured_summary.text.contains("sealed" if english else "未揭晓") and scene.measured_summary.text.contains("revealed 0" if english else "已揭晓 0"),"Pending result is explicitly sealed with zero revealed outcomes")
		scene.session.data.draft.machine.bytes_per_cycle = 64; scene.edit_draft()
		check_cost(scene,frozen,"Prediction ignores later draft machine edits")
		scene.reveal_prediction()
		check(scene.measured_summary.text.contains("revealed 1" if english else "已揭晓 1"),"Revealed result updates only after authoritative reveal")
		while not scene.session.prediction.finished: scene.commit_prediction(); scene.reveal_prediction()
		scene.switch_mode("generate"); scene.change_task(8); scene.generate_work()
		check_cost(scene,scene.latest.cost,"Generation summary retains actual cost")
		check(scene.measured_summary.text.contains("no target" if english else "无标准答案"),"Generation has no fabricated accuracy")
		var output: Array = scene.latest.output.duplicate()
		scene.name_input.text = ("Original chosen work with a long title " if english else "真实选择的作品，标题仍由玩家保留")+"12345678901234567890"
		scene.keep_work(); await settle()
		var kept: Dictionary = scene.session.data.works[-1].duplicate(true)
		check(scene.selected_work() == scene.session.data.works.size()-1,"Keeping selects the actual newly saved work")
		check(scene.kept_work == kept and scene.saved_work_closure.visible,"Successful keep offers a detached actual saved-work closure")
		check(not is_instance_valid(scene.work_focus),"Watching is optional; keep does not force a modal ritual")
		for handle: String in ["Status", "ModeActions", "LiveMeasurementSummary"]:
			check(root.get_visible_rect().encloses((scene.find_child(handle,true,false) as Control).get_global_rect()),"Kept-work layout keeps full visible bounds: "+handle)
		for name: String in ["ViewKeptWork","ContinueCreation"]:
			check(root.get_visible_rect().encloses((scene.find_child(name,true,false) as Control).get_global_rect()),"Closure action fits 1280: "+name)
		await capture("kept-"+("en" if english else "zh"))
		# A later generated run and collection selection cannot replace the chosen exhibit.
		scene.session.data.draft.seed += 31; scene.edit_draft(); scene.generate_work()
		var before_data: String = JSON.stringify(scene.session.data)
		var before_latest: String = JSON.stringify(scene.latest)
		var saved_bytes: String = FileAccess.get_file_as_string(scene.session.path)
		await click(scene,"ViewKeptWork")
		check(is_instance_valid(scene.work_focus),"Actual closure click opens saved work")
		if not is_instance_valid(scene.work_focus): quit(1); return
		check(scene.work_focus.visible and scene.work_focus.work == kept and scene.work_focus.canvas.output == output,"Closure binds saved-work return value rather than current generated result")
		check(scene.work_focus.canvas.cell_rect(output.size()-1).end.y <= scene.work_focus.canvas.custom_minimum_size.y,"Whole saved output remains available")
		await capture("full-work-"+("en" if english else "zh"))
		scene.work_focus.dismiss(); await settle()
		check(JSON.stringify(scene.session.data) == before_data and JSON.stringify(scene.latest) == before_latest and FileAccess.get_file_as_string(scene.session.path) == saved_bytes,"Watching and returning preserves draft, visible run and protected file")
		await click(scene,"ContinueCreation")
		check(not scene.saved_work_closure.visible and scene.kept_work.is_empty() and scene.session.data.parent_work == kept.id and scene.session.data.works[-1] == kept,"Editing the kept work creates a detached fork and protects its snapshot")
		check(scene.session.can_undo() and FileAccess.get_file_as_string(scene.session.path) == saved_bytes,"Fork is transient and undoable without rewriting the saved work")
		scene.works.select(scene.session.data.works.size()-1); scene.play_work()
		check(scene.measured_summary.text.contains("no current ops" if english else "无本次运算"),"Snapshot never invents a current measurement")
		scene.replay_work(); check_cost(scene,scene.latest.cost,"Recipe replay shows its fresh actual cost")
		check(scene.measured_summary.text.contains("Current recipe replay" if english else "本次配方再生"),"Fresh replay cost is distinguished from original snapshot")
		# Read-only display uses protected evidence and adds no work.
		scene.kept_work = kept.duplicate(true); scene.writable = false; scene.refresh()
		await click(scene,"ViewKeptWork")
		check(is_instance_valid(scene.work_focus),"Actual read-only click opens full saved work")
		if not is_instance_valid(scene.work_focus): quit(1); return
		check(scene.work_focus.work == kept,"Read-only closure still shows the protected work")
		scene.work_focus.dismiss(); await settle(); scene.writable = true
		scene._clear_replaced_exploration(); scene.build(); await settle()
		check(scene.kept_work.is_empty() and not scene.saved_work_closure.visible,"Confirmed profile replacement clears old closure identity")
	scene.queue_free(); await settle()
	print("PASS: creation measured closure %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
