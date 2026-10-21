extends "res://tests/test_recovery_game_input.gd"
## Saved drafts use real disk reads; actions use the existing next-step button.

func action(id: String = "NextStepAction") -> void:
	await press(ui.find_child(id, true, false))

func reopen(label: String, expected_action: String, take_shot: bool = true) -> void:
	await action("SaveDraft")
	check(not ui.session.dirty, "The visible save action persists the draft: " + label)
	var path: String = ui.session.path
	var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var data: Dictionary = ui.session.data.duplicate(true)
	change_scene_to_file("res://experiments/creation/workbench.tscn")
	await settle(12)
	ui = current_scene
	check(ui.session.path == path and ui.session.data == data, "Reopening reads the same saved draft, learned rules and earned evidence: " + label)
	check(FileAccess.get_file_as_bytes(path) == before, "Opening guidance does not rewrite the profile: " + label)
	check(ui.writable and not ui.session.dirty and ui.latest.is_empty(), "Reopened draft is writable and has no invented current run: " + label)
	check(ui.status.text.contains("learned rules loaded" if ui.english else "已学规则已打开"), "Opening feedback acknowledges retained rules instead of requiring retraining: " + label)
	check(ui.next_step().action == expected_action and ui.next_step_button.text == ui.next_step().button, "The visible next action follows actual restored evidence: " + label)
	if ui.session.data.mode == "predict":
		check(ui.signal_view.captions[0] == ("No prediction round is active" if ui.english else "当前没有进行中的预测"), "The empty prediction caption describes the current round without denying earned evidence: " + label)
	if ui.session.data.mode in ["predict", "generate"]:
		check(ui.signal_view.output_length() == 0 and ui.signal_view._cells.is_empty(), "Reopened temporary tracks contain no invented cells: " + label)
	check(not ui.next_step_button.disabled and root.get_visible_rect().encloses(ui.next_step_button.get_global_rect()), "The next action is available in the viewport: " + label)
	var font: Font = ui.status.get_theme_font("font")
	check(font.get_string_size(ui.status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ui.status.get_theme_font_size("font_size")).x <= ui.status.size.x, "The opening status fits without an ellipsis: " + label)
	if take_shot and "--recovery-capture" in OS.get_cmdline_user_args():
		await create_timer(6.0).timeout
		await capture(label)

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	change_scene_to_file("res://experiments/creation/workbench.tscn")
	await settle(12)
	ui = current_scene
	check(ui.writable and ui.session.data.model.is_empty() and ui.next_step().action == "train", "A fresh profile still starts with selected examples and Learn.")
	await action()
	check(not ui.session.data.model.is_empty() and ui.next_step().action == "transport", "The first action really learns rules before transport.")
	await reopen("learned-draft", "transport")
	# Select the existing short public source; subsequent actions use GUI dispatch.
	ui.source_kind = 2
	await action()
	check(ui.latest.get("lossless", false), "The restored rules actually transport and restore the source.")
	await reopen("transport-evidence", "predict", false)
	await action()
	check(ui.task == 3 and ui.session.data.mode == "predict", "The displayed action connects restored rules to prediction.")
	await action()
	await action()
	check(not ui.session.prediction.get("pending", {}).is_empty() and ui.session.prediction.rows.is_empty(), "The first guess is committed without exposing its truth.")
	await reopen("prediction-restart", "practice")
	check(ui.session.prediction.is_empty() and not ui.session.data.supports.has("P1_commit"), "An unfinished prediction is not persisted or promoted into earned evidence.")
	await action()
	await action()
	await action()
	check(ui.session.prediction.rows.size() == 1 and ui.next_step().action == "remainder", "A restarted round still requires a real first commit and reveal.")
	await action()
	check(ui.session.prediction.finished and ui.session.data.supports.has("P1_commit"), "Run remainder earns the original full-round evidence.")
	await reopen("completed-prediction", "generate_mode")
	await action()
	check(ui.task == 6 and ui.session.data.mode == "generate", "Restored full-round evidence enables the existing feedback action.")
	await action()
	check(ui.can_keep_visible_work(), "Following the next action produces a real savable output.")
	var output: Array = ui.latest.output.duplicate()
	var recipe: Dictionary = ui.latest.recipe.duplicate(true)
	ui.change_task(8)
	await settle(12)
	await reopen("generation-draft", "generate")
	check(ui.session.data.works.is_empty() and not ui.session.data.supports.has("G3_keep") and not ui.can_keep_visible_work(), "Saving a generation draft does not create a work or Keep completion.")
	await action()
	check(ui.latest.output == output and ui.latest.recipe == recipe, "The restored recipe generates the same output without repeating Learn or prediction.")
	check(ui.next_step().action == "keep", "The actual regenerated output now offers naming and Keep.")
	await finish()
