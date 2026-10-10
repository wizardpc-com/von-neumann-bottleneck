extends SceneTree
## User edits remain within the save contract and survive ordinary task navigation.
const Session = preload("res://experiments/creation/session.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func press(scene: Control, handle: String) -> void:
	var action := scene.find_child(handle,true,false) as Button
	check(action != null and not action.disabled,"Available edit action "+handle)
	if action != null and not action.disabled:
		var ancestor: Node = action.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(action)
			ancestor = ancestor.get_parent()
		await settle()
		if DisplayServer.get_name() == "headless": action.pressed.emit()
		else:
			var point: Vector2 = action.get_global_rect().get_center()
			check(root.get_visible_rect().has_point(point),"Onscreen viewport edit action "+handle)
			var motion := InputEventMouseMotion.new(); motion.position = point; root.push_input(motion,true)
			for down: bool in [true,false]:
				var event := InputEventMouseButton.new(); event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
				root.push_input(event,true); await process_frame
	await settle()
func input(scene: Control, handle: String) -> LineEdit:
	return scene.find_child(handle,true,false) as LineEdit
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--creation-edit-capture" not in OS.get_cmdline_user_args(): return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var picture: Image = root.get_texture().get_image()
	check(picture.get_size() == Vector2i(1280,720),"Actual minimum-size capture "+name)
	DirAccess.make_dir_recursive_absolute("res://.godot/creation-edit-captures")
	check(picture.save_png("res://.godot/creation-edit-captures/"+name+".png") == OK,"Capture "+name)
func run() -> void:
	var prior_enabled: Variant = ProjectSettings.get_setting("candidate/creation_enabled",false)
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await exercise(locale)
	ProjectSettings.set_setting("candidate/creation_enabled",prior_enabled)
	print("PASS: creation edit controls %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
func exercise(locale: String) -> void:
	var navigation: Node = root.get_node("TaskNavigation")
	navigation.pending = ""
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
	scene.session.close()
	var path: String = "user://creation-edit-controls/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	check(scene.session.open(path).writable,"Own isolated edit-control profile")
	scene.change_task(0); await settle()
	await press(scene,"ClearExamples")
	for passage: int in 16:
		input(scene,"CustomExample").text = "A D"
		await press(scene,"AddExample")
	check(scene.session.data.draft.examples.size() == 16,"Sixteen legal passages are accepted")
	var draft: Dictionary = scene.session.data.draft.duplicate(true)
	check(scene.session.save() == OK,"A full legal sample selection saves successfully")
	input(scene,"CustomExample").text = "B C"
	await press(scene,"AddExample")
	check(scene.session.data.draft == draft and not scene.session.dirty,"Rejected seventeenth custom example preserves saved draft")
	check(input(scene,"CustomExample").text == "B C" and "16" in scene.status_text,"Rejected custom example retains its text and explains capacity")
	var public_sample := scene.find_child("Example0",true,false) as CheckBox
	public_sample.button_pressed = true
	await settle()
	check(not public_sample.button_pressed and scene.session.data.draft == draft,"Full selection rejects public sample and restores checkbox")
	check(scene.session.save() == OK and Session.decode(FileAccess.get_file_as_string(path)).ok,"Both rejected additions leave a valid savable profile")
	await capture("sample-limit-"+locale)
	scene.train_model(); scene.transport("predictive"); scene.switch_mode("predict")
	scene.begin_prediction("practice"); scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction(false)
	scene.switch_mode("generate"); scene.generate_work()
	scene.name_input.text = "Full selection work"; scene.keep_work()
	check(scene.session.data.works.size() == 1 and not scene.session.dirty,"Full selection can still generate and keep a protected work")
	input(scene,"Initial").text = "A X"
	input(scene,"Initial").text_changed.emit("A X")
	input(scene,"CustomExample").text = "Unsubmitted sample"
	scene.name_input.text = "Unsubmitted work"
	await press(scene,"Next")
	check(scene.task == 7 and (scene.find_child("DraftTabs",true,false) as TabContainer).current_tab == 2,"Next chooses the creation recipe tab")
	await press(scene,"Previous")
	var unit := scene.find_child("Unit",true,false) as OptionButton
	unit.select(2); unit.item_selected.emit(2); await settle()
	check((scene.find_child("DraftTabs",true,false) as TabContainer).current_tab == 1,"Unit selection chooses the machine tab")
	unit = scene.find_child("Unit",true,false) as OptionButton
	unit.select(8); unit.item_selected.emit(8); await settle()
	check(input(scene,"Initial").text == "A X" and not scene.valid_initial_input(),"Next, Previous and Unit retain invalid unsubmitted Initial")
	check(input(scene,"CustomExample").text == "Unsubmitted sample" and scene.name_input.text == "Unsubmitted work","Ordinary navigation retains unsubmitted sample and work name")
	check(scene.run_button.disabled and not scene.can_keep_visible_work(),"Navigation does not unblock invalid generation or keeping")
	await press(scene,"Language")
	await press(scene,"Language")
	check(input(scene,"Initial").text == "A X" and input(scene,"CustomExample").text == "Unsubmitted sample" and scene.name_input.text == "Unsubmitted work","Both language rebuilds preserve unsubmitted inputs")
	check(scene.run_button.disabled and not scene.can_keep_visible_work(),"Language does not unblock invalid generation or keeping")
	await capture("retained-invalid-"+locale)
	scene.generate_work()
	check(scene.session.generated.is_empty() and scene.session.data.works.size() == 1,"Direct generation also rejects retained invalid input")
	scene.session.data.task = 4
	scene._clear_replaced_exploration()
	check(scene.task == 4 and navigation.selected == navigation.candidate_key("creation",4),"Adopting restored task also restores Journey selection")
	scene.queue_free(); await settle()
