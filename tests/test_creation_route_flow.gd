extends SceneTree
## Actual host routing; requires the full project's autoloads, not the minimal harness.
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 12: await process_frame
func run() -> void:
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	var nav: Node = root.get_node("TaskNavigation")
	var core: Node = root.get_node("GlobalSave")
	var completed: Dictionary = core.game_player_content.completed_levels.duplicate(true)
	check(nav.enter("hardware_foundations/tutorial"), "Original tutorial remains enterable")
	await settle()
	check(current_scene != null and current_scene.scene_file_path == "res://src/hardware_foundations/hardware_foundations.tscn", "Actual original chapter scene opens")
	check(nav.return_to_tree(), "Original task returns through existing navigation")
	await settle()
	check(current_scene != null and current_scene.scene_file_path == "res://src/campaign/task_tree.tscn", "Actual journey tree is restored")
	check(nav.enter_candidate("creation",1), "Candidate C2 is selected through real tree router")
	await settle()
	var scene = current_scene
	check(scene != null and scene.scene_file_path == "res://experiments/creation/workbench.tscn" and scene.task == 1 and nav.pending.is_empty(), "Candidate consumes exact requested task once")
	scene.source_kind = 2; scene.train_model(); scene.compare_transport(); await settle()
	check(scene.evidence_expanded and scene.session.dirty, "Measured work remains unsaved until explicit choice")
	scene.switch_mode("predict"); scene.change_task(4); scene.begin_prediction("practice")
	while not scene.session.prediction.finished: scene.commit_prediction(); scene.reveal_prediction()
	check(scene.session.prediction.finished and scene.task==4, "Actual prediction chapter finishes committed/revealed stream")
	scene.switch_mode("generate"); scene.change_task(7); scene.generate_work()
	scene.name_input.text = "Three-chapter route work"; scene.keep_work(); await settle()
	check(scene.session.data.works.size()==1 and scene.session.replay_work(0).get("matches",false), "Creation chapter saves an actual reproducible work")
	scene.session.data.draft.seed += 1; scene.edit_draft()

	scene.request_leave(true); await settle()
	check(scene.leave_dialog.visible and current_scene == scene, "Dirty candidate departure waits for a choice")
	scene.leave_dialog.get_cancel_button().pressed.emit(); scene.leave_dialog.hide(); await settle()
	check(current_scene == scene and scene.session.dirty and scene.transport_comparisons.size()==1, "Cancel retains draft and measured evidence")
	var path: String = scene.session.path
	scene.request_leave(true); scene.leave_dialog.confirmed.emit(); await settle()
	check(current_scene != null and current_scene.scene_file_path == "res://src/campaign/task_tree.tscn" and FileAccess.file_exists(path), "Save-and-leave returns to actual tree with candidate file")
	check(nav.enter_candidate("creation",1), "Saved candidate can reopen")
	await settle(); scene = current_scene
	check(scene.task==1 and scene.session.data.supports.has("C2_cost"), "Reopened selected task restores earned comparison support")
	check(scene.session.data.works.size()==1 and scene.session.replay_work(0).get("matches",false), "Returning to compression preserves the generation work and recipe")
	scene.request_leave(true); await settle()
	check(current_scene.scene_file_path == "res://src/campaign/task_tree.tscn", "Clean reopened candidate returns without a new dirty prompt")
	check(nav.enter("hardware_foundations/tutorial"), "Original task remains accessible after candidate round-trip")
	await settle()
	check(core.game_player_content.completed_levels==completed and nav.tasks().size()==40, "Candidate round-trip does not grant or remove original campaign completion")
	print("PASS: creation route flow %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
