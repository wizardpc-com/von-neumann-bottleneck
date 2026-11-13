extends SceneTree
## Guidance observes draft/model differences; only explicit Learn changes rules.
const Workbench = preload("res://experiments/creation/workbench.gd")
const Model = preload("res://experiments/creation/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame

func settle_capture_window() -> void:
	# Native macOS startup can resize after the initial deferred window setup.
	# Require consecutive rendered frames at the requested size, never rescale evidence.
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable + 1 if picture != null and picture.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: return

func capture_pending(scene: Control, locale: String, field: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--pending-learning-capture" in OS.get_cmdline_user_args(): return
	await settle_capture_window()
	# Observe the normal post-opening UI; do not hide the real narrative layer.
	for attempt: int in 150:
		if root.get_node_or_null("YiOpening") == null: break
		await create_timer(0.1).timeout
	check(root.get_node_or_null("YiOpening") == null,locale+" "+field+": opening naturally retires before guidance capture")
	await settle()
	for handle: String in ["NextStepText","NextStepAction"]:
		var control := scene.find_child(handle,true,false) as Control
		check(control != null and control.is_visible_in_tree(),locale+" "+field+": visible pending guidance "+handle)
		if control != null: check(root.get_visible_rect().encloses(control.get_global_rect()),locale+" "+field+": pending guidance fits 1280x720 "+handle)
	RenderingServer.force_draw(false); await process_frame
	var folder: String = "res://.godot/pending-learning-captures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var picture: Image = root.get_texture().get_image()
	check(picture != null and picture.get_size() == Vector2i(1280,720),locale+" "+field+": actual pending capture is 1280x720")
	if picture != null: check(picture.save_png(folder.path_join("pending-"+locale+"-"+field+".png")) == OK,locale+" "+field+": pending screenshot saved")

func change_learning_input(scene: Control, field: String, changed: bool) -> void:
	if field == "examples":
		var example := scene.find_child("Example2",true,false) as CheckBox
		example.button_pressed = changed
	else:
		var order := scene.find_child("Order",true,false) as OptionButton
		order.select(2 if changed else 1)
		order.item_selected.emit(order.selected)

func check_generated_work_priority(scene: Control, locale: String, field: String) -> void:
	var context: String = locale+" "+field+" generated work"
	# The current model matches the edited inputs after the explicit Learn above.
	# Restore those rules, then change the draft inputs without relearning them.
	scene.transport("predictive")
	change_learning_input(scene,field,false)
	check(scene.session.set_mode("predict").get("ok",false),context+": restored rules connect sealed input")
	check(scene.session.begin_prediction("practice").get("ok",false),context+": actual practice starts")
	while not scene.session.prediction.get("finished",false):
		var committed: Dictionary = scene.session.commit_prediction()
		var revealed: Dictionary = scene.session.reveal_prediction()
		if not committed.get("ok",false) or not revealed.get("ok",false):
			check(false,context+": practice must actually finish before feedback")
			return
	check(scene.session.set_mode("generate").get("ok",false),context+": completed prediction connects feedback")
	scene.change_task(6); scene.generate_work(); await settle()
	check(scene.can_keep_visible_work(),context+": real generation is eligible to keep despite pending learning inputs")
	var generated: Dictionary = scene.latest.duplicate(true)
	var model: Dictionary = scene.session.data.model.duplicate(true)
	check(scene.next_step().action == "next",context+": G1 retains its existing continuation")
	scene.change_task(7); await settle()
	check(scene.next_step().action == "keep",context+": G2 prioritizes keeping current generation over learning")
	scene.change_task(8); await settle()
	check(scene.next_step().action == "keep",context+": G3 prioritizes keeping current generation over learning")
	check(scene.next_step().text.contains("学习" if locale == "zh_CN" else "Learn"),context+": keep guidance explains the pending edits apply after later learning")
	await capture_pending(scene,locale,field+"-keep")
	check(scene.latest == generated and scene.session.data.model == model and scene.session.data.works.is_empty(),context+": navigation and guidance neither replace nor automatically save generation")
	if scene.next_step().action != "keep": return
	for unit: int in [0,4]:
		scene.change_task(unit); await settle()
		var supports: Dictionary = scene.session.data.supports.duplicate(true)
		check(scene.next_step().action == "g2",context+": browsing C1/P2 offers return to the unsaved creation instead of Learn")
		if scene.next_step().action != "g2": return
		scene.next_step_button.pressed.emit(); await settle()
		check(scene.task == 7 and scene.next_step().action == "keep" and scene.can_keep_visible_work(),context+": the primary return action restores G2 Keep without learning")
		check(scene.latest == generated and scene.session.data.model == model and scene.session.data.supports == supports and scene.session.data.works.is_empty(),context+": return protects output/model/evidence and never saves automatically")
	# Save through G2's ordinary primary action, avoiding an automatic G3 film.
	scene.change_task(7); scene.name_input.text = context
	scene.next_step_button.pressed.emit(); await settle()
	check(scene.session.data.works.size() == 1 and scene.session.data.works[0].output == generated.output,context+": explicit Keep saves the original actual output")
	scene.change_task(8); await settle()
	var saved_action: String = "finish_journey" if preload("res://experiments/candidate_session/context.gd").full_journey() else "works"
	check(scene.next_step().action == saved_action,context+": pending inputs do not displace saved-work closure")
	scene.play_work(); await settle()
	check(scene.next_step().action == saved_action,context+": saved snapshot viewing remains available without relearning")

func run() -> void:
	if not "VonNeumannBottleneckChecks" in OS.get_user_data_dir():
		push_error("Requires an isolated verification profile"); quit(2); return
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
	root.get_node("TaskNavigation").pending = ""
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for field: String in ["examples","history"]:
			var scene := Workbench.new()
			root.add_child(scene); await settle()
			var path: String = "user://creation-pending-learning/"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
			var opened: Dictionary = scene.session.open(path)
			scene.writable = bool(opened.get("writable",false))
			scene.change_task(0); await settle()
			var context: String = locale+" "+field
			check(scene.writable,context+": isolated draft is writable")
			scene.train_model(); scene.transport("predictive"); await settle()
			check(scene.latest.get("lossless",false) and scene.next_step().action == "next",context+": actual learned model restored a packet")
			var old_model: Dictionary = scene.session.data.model.duplicate(true)
			var old_trace: Dictionary = scene.latest.duplicate(true)
			var old_supports: Dictionary = scene.session.data.supports.duplicate(true)
			var old_permission: String = scene.session._transport_model
			change_learning_input(scene,field,true); await settle()
			await capture_pending(scene,locale,field)
			var before_guidance: String = JSON.stringify(scene.session.data)
			var step: Dictionary = scene.next_step()
			check(step.action == "train",context+": changed learning inputs guide explicit Learn before continuing")
			check(scene.next_step_button.text == ("学习样例" if locale == "zh_CN" else "Learn examples"),context+": visible primary action names Learn")
			check(JSON.stringify(scene.session.data) == before_guidance,context+": reading guidance does not mutate the draft or award progress")
			check(scene.session.data.model == old_model and scene.latest == old_trace,context+": edits and guidance preserve frozen model and measured Trace")
			check(scene.session.data.supports == old_supports and scene.session._transport_model == old_permission,context+": existing evidence stays owned by the old rules")
			change_learning_input(scene,field,false); await settle()
			check(scene.next_step().action == "next",context+": restoring matching inputs removes pending-learning guidance without relearning")
			scene.session.data.draft.machine.cpu_ops_per_cycle += 1
			scene.edit_draft()
			check(scene.next_step().action == "next",context+": a machine-only edit does not ask to relearn")
			change_learning_input(scene,field,true); await settle()
			if scene.next_step().action == "train":
				scene.next_step_button.pressed.emit(); await settle()
				check(Model.identity(scene.session.data.model) != Model.identity(old_model),context+": explicit primary Learn learns the changed examples or history")
				check(scene.session.data.model.examples == scene.session.data.draft.examples and int(scene.session.data.model.order) == int(scene.session.data.draft.order),context+": new frozen rules match the current learning inputs")
				check(scene.next_step().action == "transport" and scene.session._transport_model.is_empty(),context+": new rules need their own restoration evidence")
				check(scene.session.data.supports == old_supports,context+": learning alone grants no additional completion")
				await check_generated_work_priority(scene,locale,field)
			scene.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ")+"creation pending learning guidance %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
