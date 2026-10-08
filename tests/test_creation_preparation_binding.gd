extends SceneTree
## Preparation belongs to the displayed run, not a later selected model.
## Renderer captures show fixture-driven controller state, not viewport button input.
const Model = preload("res://experiments/creation/model.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func preparation_line(scene: Variant, cost: Dictionary) -> String:
	return ("Recorded preparation (not charged again): " if scene.english else "已记录准备（不每次重收）：")+scene.cost_text(cost)
func shows_preparation(scene: Variant, cost: Dictionary) -> bool:
	return preparation_line(scene,cost) in scene.measurement_text().split("\n")
func capture_size() -> Vector2i:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-size="):
			var pieces: PackedStringArray = argument.trim_prefix("--capture-size=").split("x")
			if pieces.size() == 2 and pieces[0].is_valid_int() and pieces[1].is_valid_int():
				return Vector2i(maxi(640,int(pieces[0])),maxi(480,int(pieces[1])))
	return Vector2i(1280,720)
func review_b(scene: Variant, b: Dictionary, stage: String) -> void:
	for english: bool in [false,true]:
		scene.english = english; scene.change_task(7); scene.show_creation_difference()
		scene.set_evidence_expanded(true)
		(scene.find_child("EvidenceTabs",true,false) as TabContainer).current_tab = 0
		var difference := scene.find_child("CreationFirstDifference",true,false) as Button
		var ancestor: Node = difference.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(difference)
			ancestor = ancestor.get_parent()
		await settle()
		check(scene.latest.recipe.model_id == b.recipe.model_id and scene.latest.output == b.output,stage+" displays actual B identity and output in "+("en" if english else "zh"))
		check(shows_preparation(scene,b.training.cost) and preparation_line(scene,b.training.cost) in scene.costs.text.split("\n"),stage+" visible cost page binds B preparation in both locales")
		check(scene.costs.text.contains(b.recipe.model_id),stage+" visible measurement identifies the actual B model")
		check(scene.creation_caption.text.contains("Currently showing: B" if english else "当前显示：B"),stage+" labels B as the displayed comparison")
		check(scene.costs.is_visible_in_tree() and difference.is_visible_in_tree() and not difference.disabled,stage+" exposes measurements and first-difference controls")
		if "--creation-preparation-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": continue
		RenderingServer.force_draw(false); await process_frame
		var folder: String = "res://.godot/creation-preparation-captures"
		DirAccess.make_dir_recursive_absolute(folder)
		var name: String = stage+"-"+("en" if english else "zh")
		check(root.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"Capture fixture-driven preparation review "+name)
		var evidence := FileAccess.open(folder.path_join(name+".json"),FileAccess.WRITE)
		check(evidence != null,"Capture actual B preparation identities")
		if evidence != null:
			evidence.store_string(JSON.stringify({"source":"fixture-driven controller; no viewport button acceptance","stage":stage,"english":english,"displayed_model_id":scene.latest.recipe.model_id,"draft_model_id":Model.identity(scene.session.data.model),"displayed_preparation":scene.latest.training.cost,"draft_preparation":scene.session.data.training.cost,"measurement_text":scene.costs.text},"\t"))
			evidence.close()
func run() -> void:
	root.get_node("TaskNavigation").pending = ""
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	root.mode = Window.MODE_WINDOWED; root.size = capture_size(); root.content_scale_size = capture_size(); await settle()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(capture_size()); await create_timer(0.4).timeout; await settle()
	scene.session.close()
	var path: String = "user://creation-preparation-binding/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	check(scene.session.open(path).writable,"Own isolated preparation profile")
	scene.english = true; scene.change_task(0)
	scene.train_model(); scene.transport("predictive"); scene.switch_mode("predict")
	scene.begin_prediction("practice"); scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction(false)
	scene.switch_mode("generate"); scene.generate_work()
	var a: Dictionary = scene.latest.duplicate(true)
	check(a.training == scene.session.generated.training,"Ordinary generation retains its complete preparation record")
	scene.pin_creation_a()
	scene.session.data.draft.examples.remove_at(1); scene.edit_draft(); scene.train_model(); scene.generate_work()
	var b: Dictionary = scene.latest.duplicate(true)
	check(a.training.cost != b.training.cost and a.output != b.output,"Actual A/B example change produces distinct preparation and output")
	check(shows_preparation(scene,b.training.cost),"Ordinary B measurement uses B preparation")
	scene.name_input.text = "Protected A"; scene.choose_creation_result(false)
	check(scene.session.data.works.size() == 1 and scene.session.data.training == a.training,"Keep A restores A recipe and preparation")
	var saved_a: Dictionary = scene.session.data.works[0].duplicate(true)
	var saved_bytes: String = FileAccess.get_file_as_string(path)
	scene.show_creation_difference()
	check(scene.latest.recipe == b.recipe and shows_preparation(scene,b.training.cost),"Keep A then locate B shows B preparation despite active A model")
	await review_b(scene,b,"keep-a-review-b")
	scene.session.data.draft.examples = [[0,3,0,3,0,3]]
	scene.edit_draft(); scene.train_model()
	check(scene.session.data.training.cost != b.training.cost,"Learning C creates a genuinely different preparation")
	scene.show_creation_difference()
	check(scene.latest.recipe == b.recipe and shows_preparation(scene,b.training.cost),"Learning C without generating cannot relabel frozen B preparation")
	await review_b(scene,b,"learn-c-review-b")
	check(scene.session.data.works[0] == saved_a and FileAccess.get_file_as_string(path) == saved_bytes,"Review and relearning preserve saved A and its file")
	scene.works.select(0); scene.play_work()
	check(shows_preparation(scene,saved_a.training.cost),"Snapshot preparation comes from protected A")
	scene.replay_work()
	check(shows_preparation(scene,saved_a.training.cost) and scene.latest.matches,"Recipe replay retains protected A preparation with fresh replay cost")
	scene.clear_creation_comparison(); scene.generate_work()
	var ordinary: Dictionary = scene.latest.duplicate(true)
	scene.session.data.draft.examples = [[0,1,2,3,0,1,2,3,0,1,2,3]]
	check(scene.session.train().ok,"Later authoritative learning succeeds independently of presentation")
	check(scene.latest == ordinary and shows_preparation(scene,ordinary.training.cost),"Detached ordinary generation retains its preparation after later learning")
	scene.transport("predictive")
	var transport_preparation: Dictionary = scene.latest.preparation.duplicate(true)
	scene.session.data.draft.examples = [[0,0,0,0]]
	check(scene.session.train().ok,"Train a later model after a detached transport")
	check(shows_preparation(scene,transport_preparation),"Transport uses its existing frozen preparation field")
	scene.transport("predictive"); scene.switch_mode("predict"); scene.begin_prediction("practice")
	check(shows_preparation(scene,scene.session.data.training.cost),"Prediction can show the known matching model preparation")
	scene.session.data.draft.examples = [[1,2,1,2,1,2]]
	check(scene.session.train().ok,"Train a different model after detached prediction evidence")
	check(not scene.measurement_text().contains("Recorded preparation"),"Prediction does not borrow preparation from an unknown different model")
	check(scene.session.data.works[0] == saved_a and FileAccess.get_file_as_string(path) == saved_bytes,"All detached measurements leave protected work bytes intact")
	scene.queue_free(); await settle()
	print("PASS: creation preparation binding %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
