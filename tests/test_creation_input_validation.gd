extends SceneTree
## Invalid visible input must not execute or save the previous valid recipe.
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func run() -> void:
	root.get_node("TaskNavigation").pending = ""
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	scene.train_model(); scene.transport("predictive"); scene.switch_mode("predict"); scene.change_task(3)
	scene.begin_prediction("practice"); scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction(false)
	scene.switch_mode("generate"); scene.change_task(8); scene.generate_work()
	check(scene.can_keep_visible_work(),"Valid visible generation can be saved")
	var input: LineEdit = scene.find_child("Initial",true,false)
	var old: Array = scene.session.data.draft.initial.duplicate()
	input.text = "A X"; input.text_changed.emit(input.text)
	check(not scene.valid_initial_input() and scene.session.generated.is_empty(),"Invalid input clears executable generation")
	check(scene.session.data.draft.initial == old,"Invalid symbols never enter the persistent recipe")
	check(not scene.can_keep_visible_work() and scene.run_button.disabled,"Invalid visible input disables Generate and Keep")
	scene.generate_work(); scene.name_input.text = "Must not save"; scene.keep_work()
	check(scene.session.data.works.is_empty() and scene.session.generated.is_empty(),"Direct actions also reject stale generation")
	input.text = "A B"; input.text_changed.emit(input.text); scene.generate_work()
	check(scene.can_keep_visible_work(),"Correcting the input permits a fresh measured output")
	scene.keep_work(); check(scene.session.data.works.size()==1,"Corrected visible recipe saves exactly once")
	scene.queue_free(); await settle()
	print("PASS: creation input validation %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
