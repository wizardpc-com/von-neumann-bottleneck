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
	_assert(level_overlay.visible and not (level_overlay.get("feedback_box") as Control).visible and level_overlay.feedback_toggle.visible, "Ordinary play must offer optional feedback without placing a questionnaire ahead of the next challenge.")
	(level_overlay.get("continue_button") as Button).pressed.emit()
	_assert(level_skips.size() == 1 and level_continues == [&"half_adder"], "Unanswered level feedback must remain skippable and never block Continue.")

	level_overlay.present(&"half_adder", "Half Adder", "Learned summary", "Hardware Foundations", &"hardware_foundations")
	level_overlay.feedback_toggle.button_pressed = true
	_assert(level_overlay.feedback_box.visible, "Feedback must expand on explicit request and retain all ratings and notes.")
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
	_assert(feedback_overlay.submit_button.text == root.get_node("Localization").text(&"sharing.keep_locally"), "The completion questionnaire labels its action as a save on this device.")
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
	await _check_unfinished_workbench_opinion()
	if failures.is_empty():
		print("PASS: non-blocking localized feedback, final export, and unfinished workbench opinion UI tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d test assertion(s) failed" % failures.size())
		quit(1)


func _check_unfinished_workbench_opinion() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/VonNeumannBottleneckChecks/"):
		_assert(false, "Use the isolated verifier for the workbench opinion test. It writes a local session, draft and outbox.")
		return
	var remote: Node = root.get_node("RemoteFeedback")
	var store: Node = root.get_node("PlaytestData")
	var localization: Node = root.get_node("Localization")
	var previous_locale: String = localization.current_locale()
	var previous_endpoint: String = remote.endpoint
	var previous_request: HTTPRequest = remote.request
	var previous_source: String = store.source_kind
	var previous_public: Variant = ProjectSettings.get_setting("application/public_game_feedback")
	var previous_community: Variant = ProjectSettings.get_setting("application/community_feedback_enabled")
	var previous_notice: Variant = ProjectSettings.get_setting("application/feedback_privacy_url", "")
	var notice := "https://privacy.example.test/privacy.html"
	ProjectSettings.set_setting("application/feedback_privacy_url", notice)
	remote.endpoint = "https://receiver.example.test/v1"
	# Let the real Send handler queue the opinion, then drive response callbacks
	# explicitly. The fixture never opens a socket or a browser.
	remote.request = null
	ProjectSettings.set_setting("application/public_game_feedback", true)
	ProjectSettings.set_setting("application/community_feedback_enabled", false)
	store.questionnaire_enabled = true
	_assert(store.start_session(), "The isolated fixture can save opinions locally.")
	store.source_kind = "agent_native"
	var moments: Node = load("res://src/playtest/playtest_moments.gd").new()
	root.add_child(moments)
	var entry: Button = moments.make_workbench_button()
	root.add_child(entry)
	_assert(entry.is_visible_in_tree(), "A configured receiver exposes the workbench feedback button.")
	entry.pressed.emit()
	await process_frame
	_assert(moments.public_issues.is_visible_in_tree() and moments.public_issues.uri == "https://github.com/wizardpc-com/von-neumann-bottleneck/issues", "Before the first task, Game exposes the project's public issue tracker.")
	_assert(moments.opinion.is_visible_in_tree() and moments.send_opinion.is_visible_in_tree() and not moments.source_selector.visible, "A fresh public Game offers a general opinion with the technical source selector hidden.")
	_assert(remote.queue.is_empty() and not remote.enabled and not moments.score_toggle.visible, "Opening feedback neither opts into sharing nor offers unavailable score submission.")
	moments.opinion.text = "Synthetic first-session feedback"
	moments.send_opinion.pressed.emit()
	var general_id: String = remote.feedback_id(moments.saved_opinion)
	_assert(remote.queue.size() == 1 and not remote.enabled, "Explicit general feedback does not enable statistics.")
	if remote.queue.size() == 1:
		var general: Dictionary = remote.queue[0].record.payload
		_assert(general.event == "general_feedback" and general.visit_id == "" and not general.has("task_version") and not general.has("level_id"), "A first-session opinion carries no invented task, visit or task contract.")
	remote.inflight.assign([general_id])
	remote._response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify({"ack":[general_id]}).to_utf8_buffer())
	moments.close()
	entry.pressed.emit()
	_assert(moments.opinion.text == "Synthetic first-session feedback" and general_id in moments.opinion_status.text, "The general draft reopens with its own acknowledged receipt.")
	moments.close()
	store.level_started(&"hardware_foundations", &"half_adder")
	entry.pressed.emit()
	_assert(moments.panel.visible and moments.target.get("chapter_id") == "hardware_foundations" and moments.target.get("level_id") == "half_adder", "The workbench button opens feedback for the active unfinished task.")
	_assert(not moments.public_issues.visible and moments.opinion.is_visible_in_tree(), "The active task offers the targeted form.")
	var send: Button = moments.send_opinion
	var keep: Button = moments.panel.find_child("KeepFeedbackLocally", true, false)
	var disclosure: Control = moments.panel.find_child("OpinionSendDisclosure", true, false)
	var privacy: LinkButton = moments.panel.find_child("PrivacyNoticeLink", true, false)
	_assert(not send.disabled and disclosure.is_visible_in_tree() and disclosure.get_index() == send.get_parent().get_index() + 1, "Disclosure is adjacent to the enabled Send action and visible without opening the settings foldout.")
	_assert(privacy != null and privacy.is_visible_in_tree() and privacy.get_parent() == disclosure, "The configured privacy link is available beside Send.")
	var disclosure_text: Label = disclosure.get_child(0)
	for locale: String in ["zh_CN", "en"]:
		localization.set_locale(locale)
		_assert(disclosure_text.text == localization.text(&"sharing.opinion_send_disclosure") and disclosure_text.text != "sharing.opinion_send_disclosure", "Send disclosure is translated in " + locale)
		if privacy != null:
			_assert(privacy.text == localization.text(&"sharing.view_privacy_notice"), "The inline privacy link follows " + locale)
	moments.opinion.text = "Synthetic unfinished-task opinion"
	keep.pressed.emit()
	_assert(remote.queue.is_empty() and moments.opinion_status.text == localization.text(&"sharing.state.local"), "Save on this device leaves the queue empty and shows a local save.")
	moments.close()
	store.source_kind = "external_player"
	entry.pressed.emit()
	_assert(moments.context_label.text.ends_with("agent_native"), "Reopening a QA opinion preserves the saved attribution in diagnostics.")
	send.pressed.emit()
	var id: String = remote.feedback_id(moments.saved_opinion)
	_assert(remote.queue.size() == 1 and moments.opinion_status.text == localization.text(&"sharing.state.pending") and not remote.enabled and not remote.scores_enabled, "Send queues only this opinion with no receipt or automatic sharing.")
	if remote.queue.size() == 1:
		_assert(remote.queue[0].record.payload.source == "agent_native", "Explicit Send retains the source of the saved opinion after a source change.")
	remote.inflight.assign([id])
	remote._response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), '{"ack":["different-id"]}'.to_utf8_buffer())
	_assert(moments.opinion_status.text == localization.text(&"sharing.state.failed_retryable"), "An HTTP success without this opinion's acknowledgement remains pending retry.")
	remote.inflight.assign([id])
	var ack: PackedByteArray = JSON.stringify({"ack": [id]}).to_utf8_buffer()
	remote._response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), ack)
	_assert(remote.queue.is_empty() and moments.opinion_status.text.begins_with(localization.text(&"sharing.state.sent")) and id in moments.opinion_status.text, "Only a matching acknowledgement shows a receipt for this opinion.")
	moments.saved_opinion.erase("source")
	moments._remote_updated()
	_assert(moments.context_label.text.ends_with("unknown"), "A legacy opinion without a source displays the receiver's unknown attribution.")
	remote.endpoint = ""
	remote.status_changed.emit()
	var offline_entry: Button = moments.make_workbench_button()
	_assert(not offline_entry.visible and send.disabled and not disclosure.visible and keep.is_visible_in_tree(), "Without a receiver the ordinary workbench keeps its existing entry policy and the form remains usable locally.")
	offline_entry.free()
	moments.opinion.text = "Synthetic local-only revision"
	keep.pressed.emit()
	_assert(moments.saved_opinion.get("source") == "external_player" and moments.context_label.text.ends_with("external_player"), "A newly saved revision records its actual current source.")
	_assert(remote.queue.is_empty() and moments.opinion_status.text.begins_with(localization.text(&"sharing.state.local")) and id not in moments.opinion_status.text, "A local edit after a successful send does not inherit the earlier receipt.")
	moments.close()
	entry.queue_free()
	moments.queue_free()
	await process_frame
	store.level_exited(&"hardware_foundations", &"half_adder")
	var previous_test: Variant = ProjectSettings.get_setting("application/public_test_feedback")
	var previous_capture: Variant = ProjectSettings.get_setting("playtest/offline_feedback")
	ProjectSettings.set_setting("application/public_game_feedback", null)
	ProjectSettings.set_setting("application/public_test_feedback", true)
	ProjectSettings.set_setting("playtest/offline_feedback", true)
	remote.endpoint = "https://receiver.example.test/v1"
	var dual: Node = load("res://src/playtest/playtest_moments.gd").new()
	root.add_child(dual)
	dual.toggle()
	_assert(not store.last_exit_context.is_empty() and dual.target.get("level_id") == "" and dual.saved_opinion.get("event") == "general_feedback", "Public Test opens the general opinion after leaving a task, even with a last-exit context.")
	dual.close()
	dual.open_for_task("hardware_foundations","half_adder")
	var capture: Button = dual.panel.find_child("OpenLocalDiagnosticCapture",true,false)
	var export_zip: Button = dual.panel.find_child("ExportLocalDiagnosticZip",true,false)
	_assert(dual.panel.visible and not root.get_node("OfflineFeedback").backdrop.visible and dual.send_opinion.is_visible_in_tree(), "A task in public Test opens the private opinion form before any local capture.")
	_assert(capture != null and capture.is_visible_in_tree() and export_zip != null and export_zip.is_visible_in_tree() and not dual.source_selector.visible and not remote.community_available(), "Public Test exposes independent local capture and ZIP actions with its release capabilities.")
	if export_zip != null:
		export_zip.pressed.emit()
		var dialog: FileDialog = root.get_node("OfflineFeedback").export_dialog
		_assert(not dual.panel.visible and dialog != null and dialog.visible and dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE and remote.queue.is_empty(), "ZIP opens a local destination chooser without transmitting anything.")
		if dialog != null: dialog.hide()
	dual.free()
	ProjectSettings.set_setting("application/public_test_feedback", previous_test)
	ProjectSettings.set_setting("playtest/offline_feedback", previous_capture)
	ProjectSettings.set_setting("application/public_game_feedback", true)
	_check_community_capabilities(remote)
	remote.endpoint = previous_endpoint
	remote.request = previous_request
	store.source_kind = previous_source
	ProjectSettings.set_setting("application/public_game_feedback", previous_public)
	ProjectSettings.set_setting("application/community_feedback_enabled", previous_community)
	ProjectSettings.set_setting("application/feedback_privacy_url", previous_notice)
	localization.set_locale(previous_locale)


func _check_community_capabilities(remote: Node) -> void:
	remote.endpoint = "https://receiver.example.test/v1"
	var records_scene: PackedScene = load("res://src/playtest/personal_records_view.tscn")
	var records: Control = records_scene.instantiate()
	root.add_child(records)
	_assert(records.find_child("CommunityToggle",true,false) == null and records.online == null and records.find_child("CompletionTotal",true,false) != null, "Public Game keeps personal records without creating community read or score controls.")
	records._fetch("community/tasks")
	_assert(records.request_kind.is_empty() and not remote.set_scores_enabled(true), "Unsupported community reads and score opt-in cannot start.")
	var retained_score := {"record":{"kind":"score"}, "destination":remote.endpoint}
	remote.scores_enabled = true
	_assert(remote.consented_endpoint == remote.endpoint and not remote._can_send_item(retained_score) and remote.send_score({}).is_empty(), "Even previously consented scores cannot be sent on the feedback-only lane.")
	remote.scores_enabled = false
	records.free()

	ProjectSettings.set_setting("application/community_feedback_enabled", null)
	_assert(not remote.community_available(), "A public Game with an omitted community flag still needs an explicit community capability.")
	ProjectSettings.set_setting("application/public_game_feedback", null)
	var legacy: Control = records_scene.instantiate()
	root.add_child(legacy)
	_assert(legacy.find_child("CommunityToggle",true,false) != null and legacy.online != null and legacy.fetch_buttons.size() == 2, "Existing configured lanes retain their community reads and score controls.")
	legacy.free()
	var diagnostic: Node = load("res://src/playtest/playtest_moments.gd").new()
	root.add_child(diagnostic)
	_assert(diagnostic.score_toggle.visible and diagnostic.source_selector.visible, "A configured diagnostic build retains score opt-in and source selection.")
	var developer_index: int = 2
	diagnostic.source_selector.select(developer_index)
	diagnostic.source_selector.item_selected.emit(developer_index)
	_assert(root.get_node("PlaytestData").source_kind == "developer" and diagnostic.context_label.text.ends_with("developer"), "Changing the diagnostic source updates the attribution displayed for new feedback.")
	diagnostic.free()
	ProjectSettings.set_setting("application/public_game_feedback", true)
	ProjectSettings.set_setting("application/community_feedback_enabled", true)
	_assert(remote.community_available(), "An explicitly enabled Game can use a configured community service.")
	remote.endpoint = ""
	_assert(not remote.community_available(), "An enabled flag alone cannot create a community destination.")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
