extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var LevelCompletionOverlayType: GDScript = load("res://src/ui/level_completion_overlay.gd")
	var PlaytestFeedbackOverlayType: GDScript = load("res://src/playtest/playtest_feedback_overlay.gd")
	var level_overlay: Variant = LevelCompletionOverlayType.new()
	level_overlay.questionnaire_enabled = true
	root.add_child(level_overlay)
	await process_frame
	var level_submissions: Array = []
	var level_skips: Array = []
	var level_continues: Array = []
	level_overlay.feedback_submitted.connect(func(
		chapter_id: StringName, level_id: StringName,
		fun_rating: int, clarity_rating: int, continue_rating: int, note: String
	) -> void:
		level_submissions.append([chapter_id, level_id, fun_rating, clarity_rating, continue_rating, note])
	)
	level_overlay.feedback_skipped.connect(func(chapter_id: StringName, level_id: StringName) -> void:
		level_skips.append([chapter_id, level_id])
	)
	level_overlay.continue_requested.connect(func(level_id: StringName) -> void: level_continues.append(level_id))

	level_overlay.present(&"half_adder", "Half Adder", "Learned summary", "Hardware Foundations", &"hardware_foundations")
	_assert(level_overlay.visible and (level_overlay.get("feedback_box") as Control).visible, "Ordinary play must show the compact level feedback inside the completion surface.")
	(level_overlay.get("continue_button") as Button).pressed.emit()
	_assert(level_skips.size() == 1 and level_continues == [&"half_adder"], "Unanswered level feedback must remain skippable and never block Continue.")

	level_overlay.present(&"half_adder", "Half Adder", "Learned summary", "Hardware Foundations", &"hardware_foundations")
	var ratings: Dictionary = level_overlay.get("feedback_ratings")
	(ratings[&"fun"] as OptionButton).select(4)
	(ratings[&"clarity"] as OptionButton).select(5)
	(ratings[&"continue"] as OptionButton).select(3)
	var note: LineEdit = level_overlay.get("feedback_note")
	note.text = "Short note"
	(level_overlay.get("continue_button") as Button).pressed.emit()
	_assert(
		level_submissions.size() == 1
		and level_submissions[0] == [&"hardware_foundations", &"half_adder", 4, 5, 3, "Short note"],
		"Three level ratings and the optional note must emit before the unchanged Continue flow."
	)
	level_overlay.questionnaire_enabled = false
	level_overlay.present(&"tutorial", "Tutorial", "Learned", "Hardware Foundations", &"hardware_foundations")
	_assert(not (level_overlay.get("feedback_box") as Control).visible, "The explicit questionnaire flag must hide level feedback for automation/capture flows.")
	level_overlay.dismiss()

	var feedback_overlay: Variant = PlaytestFeedbackOverlayType.new()
	feedback_overlay.questionnaire_enabled = true
	root.add_child(feedback_overlay)
	await process_frame
	var chapter_payloads: Array = []
	var demo_payloads: Array = []
	var finished_scopes: Array = []
	var skipped_scopes: Array = []
	var export_requests: Array[String] = []
	var open_export_paths: Array[String] = []
	feedback_overlay.chapter_feedback_submitted.connect(func(
		chapter_id: StringName, best_level_id: StringName, worst_level_id: StringName,
		confusing_point: String, surprising_point: String, pace_rating: int
	) -> void:
		chapter_payloads.append([chapter_id, best_level_id, worst_level_id, confusing_point, surprising_point, pace_rating])
	)
	feedback_overlay.demo_feedback_submitted.connect(func(
		satisfaction: int, difficulty: int, length_feeling: StringName,
		favorite: String, change: String, continue_interest: int
	) -> void:
		demo_payloads.append([satisfaction, difficulty, length_feeling, favorite, change, continue_interest])
	)
	feedback_overlay.finished.connect(func(scope: StringName, subject_id: StringName) -> void: finished_scopes.append([scope, subject_id]))
	feedback_overlay.feedback_skipped.connect(func(scope: StringName, subject_id: StringName) -> void: skipped_scopes.append([scope, subject_id]))
	feedback_overlay.export_requested.connect(func() -> void: export_requests.append("export"))
	feedback_overlay.open_export_folder_requested.connect(func(path: String) -> void: open_export_paths.append(path))

	var levels: Array[Dictionary] = [
		{"id": &"assembly", "label": "Assembly"},
		{"id": &"bottleneck", "label": "Bottleneck"},
	]
	_assert(feedback_overlay.present_chapter(&"chapter_1", levels), "Chapter completion must open the concise chapter feedback surface when enabled.")
	feedback_overlay.best_level_selector.select(2)
	feedback_overlay.worst_level_selector.select(1)
	feedback_overlay.chapter_pace_selector.select(3)
	feedback_overlay.confusing_edit.text = "Bus timing"
	feedback_overlay.surprising_edit.text = "CPU WAIT"
	feedback_overlay.call("_refresh_submit_state")
	_assert(not feedback_overlay.submit_button.disabled, "Chapter feedback must become submittable after its three compact choices.")
	feedback_overlay.submit_button.pressed.emit()
	_assert(
		chapter_payloads == [[&"chapter_1", &"bottleneck", &"assembly", "Bus timing", "CPU WAIT", 3]]
		and finished_scopes.back() == [&"chapter", &"chapter_1"],
		"Chapter feedback must preserve best/worst level IDs, short text, pace, and completion order."
	)

	_assert(feedback_overlay.present_demo(), "Completing the Demo must open the concise overall feedback surface.")
	(feedback_overlay.demo_ratings[&"satisfaction"] as OptionButton).select(4)
	(feedback_overlay.demo_ratings[&"difficulty"] as OptionButton).select(3)
	(feedback_overlay.demo_ratings[&"continue"] as OptionButton).select(5)
	feedback_overlay.length_selector.select(2)
	feedback_overlay.favorite_edit.text = "Profiler"
	feedback_overlay.change_edit.text = "Shorten intro"
	feedback_overlay.call("_refresh_submit_state")
	feedback_overlay.submit_button.pressed.emit()
	_assert(
		demo_payloads == [[4, 3, &"about_right", "Profiler", "Shorten intro", 5]]
		and finished_scopes.back() == [&"chapter", &"chapter_1"],
		"Demo feedback must emit satisfaction, difficulty, length, favorites, and continuation interest before the Demo is closed."
	)
	_assert(
		(feedback_overlay.export_handoff_box as Control).visible
		and (feedback_overlay.export_button as Button).visible
		and not (feedback_overlay.open_export_folder_button as Button).visible,
		"Submitting final Demo feedback must reveal a prominent export handoff before the player leaves."
	)
	feedback_overlay.export_button.pressed.emit()
	_assert(export_requests == ["export"], "The final handoff Export button must request one anonymous export.")
	feedback_overlay.show_export_result("C:/test/playtest.json")
	_assert(
		"C:/test/playtest.json" in feedback_overlay.export_status_label.text
		and feedback_overlay.open_export_folder_button.visible,
		"A successful export must show its path and offer to open the containing folder."
	)
	feedback_overlay.open_export_folder_button.pressed.emit()
	_assert(open_export_paths == ["C:/test/playtest.json"], "Open Folder must carry the exact exported file path.")
	feedback_overlay.finish_button.pressed.emit()
	_assert(finished_scopes.back() == [&"demo", &"demo"], "Continue must close the export handoff and finish the Demo flow.")

	_assert(feedback_overlay.present_demo(), "The final Demo questionnaire must remain repeatable for skip-path coverage.")
	feedback_overlay.skip_button.pressed.emit()
	_assert(
		skipped_scopes == [[&"demo", &"demo"]]
		and feedback_overlay.export_handoff_box.visible,
		"Skipping final Demo questions must still lead to the anonymous export handoff."
	)
	feedback_overlay.finish_button.pressed.emit()

	feedback_overlay.present_chapter(&"chapter_2", levels)
	feedback_overlay.skip_button.pressed.emit()
	_assert(skipped_scopes == [[&"demo", &"demo"], [&"chapter", &"chapter_2"]], "Chapter and Demo forms must offer an explicit skip path.")
	feedback_overlay.questionnaire_enabled = false
	_assert(not feedback_overlay.present_demo() and not feedback_overlay.visible, "The explicit questionnaire flag must prevent chapter/Demo forms from appearing.")

	level_overlay.queue_free()
	feedback_overlay.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: non-blocking localized level, chapter, Demo feedback, and final export handoff UI tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d test assertion(s) failed" % failures.size())
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
