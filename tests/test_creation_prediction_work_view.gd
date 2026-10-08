extends SceneTree
## Fixture-driven controller/rendering evidence, not native pointer acceptance.
## Saved-work views must not replace or borrow the retained prediction round.
const Model = preload("res://experiments/creation/model.gd")
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func capture(scene: Variant, name: String) -> void:
	if "--creation-prediction-work-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var folder: String = "res://.godot/creation-prediction-work-captures"
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"Capture fixture-driven saved-work view "+name)
	var evidence := FileAccess.open(folder.path_join(name+".json"),FileAccess.WRITE)
	check(evidence != null,"Capture displayed work and retained prediction identities")
	if evidence != null:
		evidence.store_string(JSON.stringify({"source":"fixture-driven controller; no native pointer acceptance","kind":scene.latest.kind,"work_id":scene.latest.work.id,"displayed_model_id":scene.latest.work.recipe.model_id,"prediction_model_id":scene.session.prediction.model_id,"prediction_pending":not scene.session.prediction.pending.is_empty(),"prediction_finished":scene.session.prediction.finished,"output":scene.signal_view.lanes[2],"saved_output":scene.latest.work.output,"measurement":scene.measured_summary.text},"\t"))
		evidence.close()
func run() -> void:
	root.get_node("TaskNavigation").pending = ""
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
	scene.session.close()
	var path: String = "user://creation-prediction-work-view/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	check(scene.session.open(path).writable,"Own isolated saved-work prediction profile")
	scene.change_task(0); scene.train_model(); scene.transport("predictive"); scene.switch_mode("predict")
	scene.begin_prediction("practice"); scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction(false)
	scene.switch_mode("generate"); scene.generate_work(); scene.name_input.text = "Protected actual output"; scene.keep_work()
	check(scene.session.data.works.size() == 1,"Save one real generated output and its complete recipe")
	var saved: Dictionary = scene.session.data.works[0].duplicate(true)
	var saved_bytes: String = FileAccess.get_file_as_string(path)
	scene.session.data.draft.examples = [[0,3,0,3,0,3]]
	scene.edit_draft(); scene.train_model(); scene.transport("predictive"); scene.switch_mode("predict")
	check(Model.identity(scene.session.data.model) != saved.recipe.model_id,"Active prediction uses a different actual model from the saved work")
	for english: bool in [false,true]:
		for task: int in [3,4,5]:
			for finished: bool in [false,true]:
				scene.english = english; scene.change_task(task); scene.begin_prediction("practice"); scene.commit_prediction()
				if finished:
					scene.reveal_prediction(); scene.continue_prediction(false)
				var retained: Dictionary = scene.session.prediction.duplicate(true)
				var retained_events: Array = scene.session.prediction_evidence().events.duplicate(true)
				check(bool(retained.finished) == finished and (retained.pending.is_empty() if finished else not retained.pending.is_empty()),"Create real pending or finished round in each prediction task")
				for replay: bool in [false,true]:
					scene.works.select(0)
					if replay: scene.replay_work()
					else: scene.play_work()
					await settle()
					check(scene.signal_view.lanes[2] == saved.output and scene.signal_view.lanes[1] == saved.recipe.initial,"Saved-work tracks override retained P-task prediction")
					check(scene.latest.work == saved and scene.costs.text.contains(saved.recipe.model_id),"Work identity and visible result model belong to the selected saved work")
					if replay:
						var expected: Dictionary = scene.session.replay_work(0)
						check(scene.latest.kind == "replay" and scene.latest.matches and scene.latest.cost == expected.cost,"Replay shows exact saved output and genuine recipe cost")
						check(scene.measured_summary.text.contains(str(expected.cost.total_cycles)) and scene.measured_summary.text.contains("Current recipe replay" if english else "本次配方再生"),"Live replay measurement uses the selected work cost")
					else:
						check(scene.latest.kind == "snapshot" and not scene.latest.has("cost") and scene.measured_summary.text.contains("no current ops" if english else "无本次运算"),"Snapshot carries no borrowed prediction cost")
					check(scene.session.prediction == retained and scene.session.prediction_evidence().events == retained_events,"Viewing or replaying preserves pending truth boundary and all committed prediction events")
					check(scene.session.data.works[0] == saved and FileAccess.get_file_as_string(path) == saved_bytes,"Saved work and profile bytes remain protected")
					if task == 4:
						await capture(scene,("finished" if finished else "pending")+"-"+("replay" if replay else "snapshot")+"-"+("en" if english else "zh"))
				if finished:
					check(scene.commit_button.disabled and scene.reveal_button.disabled,"Finished round cannot commit or reveal again while a saved work is viewed")
					scene.begin_prediction("practice"); scene.commit_prediction()
				scene.reveal_prediction()
				check(scene.latest.kind == "prediction" and scene.session.prediction.rows.size() == 1 and scene.session.prediction.pending.is_empty(),"Reveal returns from saved-work view to the original pending guess or newly started round")
				check(scene.signal_view.lanes[2] == scene.session.prediction.prefix and scene.signal_view.lanes[2].size() == 3,"Returning to prediction reveals exactly one truth and shows its track")
				scene.commit_prediction()
				check(scene.session.prediction.prefix.size() == 3 and scene.signal_view.lanes[1].size() == 4,"Next commit still obeys the sealed-future boundary")
				scene.reveal_prediction(); scene.continue_prediction(false)
				check(scene.session.prediction.finished and scene.session.prediction.rows.size() == scene.session.prediction.total,"Prediction completes intact after the saved-work detour")
	check(scene.session.data.works[0] == saved and FileAccess.get_file_as_string(path) == saved_bytes,"All task, locale and round detours preserve the protected save")
	scene.queue_free(); await settle()
	print("PASS: creation prediction work view %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
