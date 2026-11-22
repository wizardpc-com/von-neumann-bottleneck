extends Node
## Synthetic controller for the hosted Windows draft-package check.

const NOTE := "SYNTHETIC hosted Windows release check"
const BENCH := "Synthetic hosted restart"
const UPGRADE_BENCH := "Synthetic previous build"
const CHAPTER := &"hardware_foundations"
const LEVEL := &"tutorial"
const RESULTS_ORIGIN := "https://feedback.yanruiqing.com:8443"
var failures: Array[String] = []
var config: Dictionary
var evidence: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path).replace("\\", "/").simplify_path()


func matches_engine(expected: String) -> bool:
	var version: Dictionary = Engine.get_version_info()
	var prefix: String = "%d.%d.%d.%s.%s." % [version.major, version.minor, version.patch,
		version.status, version.build]
	return expected.begins_with(prefix) and str(version.hash).begins_with(expected.trim_prefix(prefix))


func run() -> void:
	print("VNB_WINDOWS_QA: probe scene started")
	var raw: Variant = JSON.parse_string(str(ProjectSettings.get_setting("windows_release_qa/configuration", "")))
	if not raw is Dictionary:
		push_error("Missing isolated hosted QA configuration.")
		get_tree().quit(2)
		return
	config = raw
	var identity: Dictionary = config.identity
	var test: bool = identity.edition == "test"
	var mode: Node = get_node("/root/GameMode")
	var remote: Node = get_node("/root/RemoteFeedback")
	var store: Node = get_node("/root/PlaytestData")
	var offline: Node = get_node("/root/OfflineFeedback")
	var user_dir: String = absolute(OS.get_user_data_dir())
	var endpoint: String = config.endpoint
	var save_check: bool = config.phase in ["seed", "upgrade"]
	var private_view: bool = config.phase == "private_view"
	var final_candidate: bool = identity.display_version == "0.6.1-playtest.2"
	var offline_capture: bool = test and (not final_candidate or config.phase in ["capture", "export"])
	var isolated: bool = (OS.get_name() == "Windows" and OS.has_feature("free_candidate")
		and config.phase in ["write", "restart", "decline", "private_view", "capture", "export", "seed", "upgrade"]
		and user_dir.nocasecmp_to(absolute(config.user_dir)) == 0
		and user_dir.ends_with("/HostedWindowsReleaseQA/VonNeumannBottleneckCandidates/representation/" + identity.save_profile))
	var correct_endpoint: bool = endpoint.is_empty() if save_check or (test and not final_candidate) else is_loopback(endpoint)
	if private_view:
		correct_endpoint = (final_candidate and endpoint == RESULTS_ORIGIN + "/v1"
			and is_loopback(str(config.get("transport_endpoint", ""))))
	if (not isolated or not correct_endpoint or remote.endpoint != endpoint or remote.privacy_url() != ""
			or store.source_kind != "automated" or remote.enabled or remote.scores_enabled):
		push_error("Refusing feedback or saves without the exact isolated Windows profile and loopback-only settings.")
		get_tree().quit(2)
		return
	if not endpoint.is_empty():
		remote.request.max_redirects = 0
	var expected_settings := {"config/build_commit":identity.source_commit, "config/build_id":identity.build_id,
		"config/version":identity.display_version, "test_batch":identity.test_batch}
	for key: String in expected_settings:
		check(ProjectSettings.get_setting("application/" + key) == expected_settings[key], "Embedded identity mismatch: " + key)
	check(ProjectSettings.get_setting("candidate/profile") == identity.save_profile, "Embedded player save profile mismatch.")
	check(matches_engine(identity.engine), "Embedded engine version must match the platform manifest.")
	check(mode.edition() == identity.edition and mode.edition_locked() and mode.is_test_mode() == test
		and OS.has_feature(str(identity.edition) + "_edition") and not mode.set_mode(&"game" if test else &"test"),
		"Exported edition must remain locked.")
	check(offline.enabled() == test, "Offline capture must be enabled only for the Test package.")
	if final_candidate:
		check(remote.is_public_test() == test and remote.is_public_game() != test,
			"Only the final Test package enables the dual feedback surface.")
	if not test or final_candidate:
		check((test or remote.is_public_game()) and not remote.community_available()
			and ProjectSettings.get_setting("application/community_feedback_enabled", true) == false
			and not remote.set_scores_enabled(true),
			"Player releases keep community scores disabled.")
	var unlocked: int = 0
	var tasks: Array = get_node("/root/TaskNavigation").journey_tasks()
	for task: Dictionary in tasks:
		if task.unlocked: unlocked += 1
		check(not task.completed, "The isolated probe starts before loading the upgrade fixture.")
	check(tasks.size() == 60 and (unlocked == 60 if test else unlocked > 0 and unlocked < 60),
		"The locked edition has the expected actual task access.")
	if not failures.is_empty():
		finish(user_dir)
		return
	print("VNB_WINDOWS_QA: isolated profile, identity and edition policy verified")
	if private_view:
		await verify_private_view(remote, store)
		finish(user_dir)
		return
	if config.phase == "decline":
		if choose_first_consent(false):
			check(not remote.enabled and remote.sharing_mode == "local" and not remote.scores_enabled,
				"Declining the service leaves sharing disabled.")
			check(store.start_session() and store.level_started(CHAPTER, LEVEL)
				and store.level_completed(CHAPTER, LEVEL) and store.level_exited(CHAPTER, LEVEL),
				"Local play records a completed visit after declining.")
			await get_tree().process_frame
			check(remote.queue.is_empty() and remote.inflight.is_empty(), "Declining sends no visit data.")
			var moments: Node = get_node("/root/PlaytestMoments")
			moments.open_for_task(str(CHAPTER), str(LEVEL))
			check_loopback_results(moments, remote)
			moments.close()
		finish(user_dir)
		return

	var save: Node = get_node("/root/GlobalSave")
	var workbench_path: String = absolute(save.workbench_storage_path)
	if (not workbench_path.to_lower().begins_with(user_dir.to_lower() + "/")
			or not absolute(save.storage_path).to_lower().begins_with(user_dir.to_lower() + "/")):
		push_error("Refusing to write an unisolated workbench.")
		get_tree().quit(2)
		return
	var repo: Variant = load("res://src/hardware_foundations/circuit_workbench_store.gd").new(save.workbench_storage_path)
	var namespace_id: StringName = &"test" if test else &"game"
	var board := {"components":[], "wires":[]}
	if save_check:
		check_upgrade(save, repo, namespace_id, workbench_path)
		finish(user_dir)
		return
	var previous: Dictionary = {}
	if config.phase in ["write", "capture"]:
		check(not FileAccess.file_exists(workbench_path), "The first process opens a fresh workbench store.")
		check(repo.create_workbench(namespace_id, LEVEL, BENCH, board) == &"", "The real workbench store saved the synthetic board.")
	else:
		var first_phase: String = "capture" if config.phase == "export" else "write"
		var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(config.output).path_join(first_phase + ".json")))
		if not source is Dictionary:
			push_error("Missing first-process receipt.")
			get_tree().quit(2)
			return
		previous = source
		check(repo.active_name(namespace_id, LEVEL) == BENCH and repo.active_snapshot(namespace_id, LEVEL) == board,
			"A separate process reopened the exact named board and its contents.")
		check(FileAccess.get_sha256(workbench_path) == previous.get("workbench_sha256"),
			"Reopening preserves the original workbench bytes.")
	evidence["workbench_sha256"] = FileAccess.get_sha256(workbench_path)
	check(str(evidence.workbench_sha256).length() == 64, "The workbench file exists inside isolated userdata.")
	check(store.start_session(), "Synthetic feedback uses a local questionnaire session.")
	store.level_started(CHAPTER, LEVEL)
	if not failures.is_empty():
		finish(user_dir)
		return
	print("VNB_WINDOWS_QA: workbench file and local feedback session verified")
	if offline_capture:
		await offline_feedback(offline, previous)
		check(remote.queue.is_empty() and not remote.enabled and not remote.scores_enabled,
			"Offline capture and export do not enqueue or enable online sharing.")
	else:
		await online_feedback(remote, store, previous, final_candidate)
	check(FileAccess.get_sha256(workbench_path) == evidence.workbench_sha256, "Feedback leaves the workbench bytes unchanged.")
	finish(user_dir)


func check_upgrade(save: Node, repo: Variant, namespace_id: StringName, workbench_path: String) -> void:
	var component: Variant = load("res://src/circuit/logic_component.gd").new(&"qa_not", &"not", "QA NOT")
	var board: Dictionary = JSON.parse_string(JSON.stringify({
		"schema_version":1, "components":[component.to_dictionary()],
		"layout":{"qa_not":{"x":120,"y":80}}, "wires":[],
	}))
	var game: bool = namespace_id == &"game"
	var opposite: StringName = &"test" if game else &"game"
	var save_path: String = absolute(save.storage_path)
	if config.phase == "seed":
		check(not FileAccess.file_exists(workbench_path) and not FileAccess.file_exists(save_path),
			"The predecessor opens a new isolated profile.")
		check(repo.create_workbench(namespace_id, LEVEL, UPGRADE_BENCH, board) == &"",
			"The predecessor writes a named workbench using its shipped store.")
		if game:
			save.load_game()
			save.game_player_content.mark_completed(LEVEL)
			check(save.save_game(true), "The predecessor writes synthetic tutorial progress with its own save writer.")
	else:
		save.load_game()
		check(save.disk_write_allowed and save.last_error.is_empty() and save.loaded_save == game
			and bool(save.game_player_content.completed_levels.get(LEVEL, false)) == game
			and save.has_resume_progress() == game,
			"The new package reads previous Game progress, and the Test profile has no Game progress.")
		check(repo.active_name(namespace_id, LEVEL) == UPGRADE_BENCH
			and repo.active_snapshot(namespace_id, LEVEL) == board,
			"The new package restores the predecessor's named workbench and exact contents.")
	check(repo.active_name(opposite, LEVEL).is_empty(), "The opposite edition namespace stays empty.")
	evidence["workbench_sha256"] = FileAccess.get_sha256(workbench_path)
	evidence["save_sha256"] = FileAccess.get_sha256(save_path) if FileAccess.file_exists(save_path) else ""
	check(str(evidence.workbench_sha256).length() == 64
		and str(evidence.save_sha256).length() == (64 if game else 0),
		"The representative prior-build saves exist only in their expected edition.")
	# Quit must not rewrite the saved timestamp after recording the fixture hash.
	save.disk_write_allowed = false


func offline_feedback(offline: Node, previous: Dictionary) -> void:
	print("VNB_WINDOWS_QA: checking offline capture and local bundle")
	if config.phase in ["write", "capture"]:
		check(offline.store.cases().is_empty(), "The offline case store starts empty.")
		if config.phase == "capture":
			var moments: Node = get_node("/root/PlaytestMoments")
			moments.open_for_task(str(CHAPTER), str(LEVEL))
			var capture: Button = moments.panel.find_child("OpenLocalDiagnosticCapture", true, false) as Button
			var export_button: Button = moments.panel.find_child("ExportLocalDiagnosticZip", true, false) as Button
			if capture == null or not capture.is_visible_in_tree() or capture.disabled:
				check(false, "The actual Test feedback form exposes a usable local capture action.")
				return
			check(export_button != null and export_button.is_visible_in_tree() and not export_button.disabled,
				"The actual Test feedback form exposes a separate local ZIP action.")
			capture.pressed.emit()
		else:
			offline.open_for_task(str(CHAPTER), str(LEVEL))
		await get_tree().process_frame
		check(offline.backdrop.visible and not offline.current.is_empty(), "The actual offline panel recorded the unfinished task.")
		if offline.current.is_empty(): return
		check(offline.current.get("screenshot_status") == "headless" and offline.preview.texture == null,
			"The headless capture records its context without attempting a screenshot.")
		offline.note.text = NOTE
		offline.note.text_changed.emit()
		evidence["feedback_id"] = str(offline.current.id)
		offline.close_panel()
		check(not offline.backdrop.visible and offline.store.read_case(evidence.feedback_id).get("note") == NOTE,
			"The offline opinion persisted locally.")
	else:
		var id: String = previous.feedback_id
		evidence["feedback_id"] = id
		var case_data: Dictionary = offline.store.read_case(id)
		check(case_data.get("note") == NOTE and case_data.get("task", {}).get("level_id") == str(LEVEL),
			"A separate process reopened the same offline case and note.")
		var build: Dictionary = case_data.get("build", {})
		check(build.get("source_commit") == config.identity.source_commit
			and build.get("version") == config.identity.display_version
			and case_data.get("screenshot_status") == "headless",
			"The case keeps its frozen build identity and accurately records the headless capture.")
		# Use the shipped ZIP store without launching Explorer on the hosted runner.
		var destination: String = str(config.output).path_join("offline-feedback.zip")
		check(offline.store.export_bundle(destination) == destination, "The restarted offline store exports a local bundle.")


func has_durable_opinion(remote: Node, id: String) -> bool:
	if id.length() != 64 or remote.queue.size() != 1:
		return false
	var state: Variant = JSON.parse_string(FileAccess.get_file_as_string(remote.state_path))
	if not state is Dictionary or not state.get("queue") is Array or state.queue.size() != 1:
		return false
	var pending: Variant = state.queue[0]
	if not pending is Dictionary or not pending.get("record") is Dictionary:
		return false
	return (pending.get("destination") == config.endpoint
		and pending.record.get("event_id") == id and pending.record.get("kind") == "feedback")


func wait_for_feedback(remote: Node, id: String, expected: String) -> String:
	# The Windows connection may stay in flight until the product HTTP timeout.
	var deadline: int = Time.get_ticks_msec() + ceili((remote.request.timeout + 3.0) * 1000.0)
	var state: String = remote.feedback_state(id)
	while state != expected and not state in ["rejected", "storage_error", "local"] and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.1).timeout
		state = remote.feedback_state(id)
	return state


func online_feedback(remote: Node, store: Node, previous: Dictionary, final_candidate: bool) -> void:
	print("VNB_WINDOWS_QA: checking unfinished task opinion with loopback fixture")
	var moments: Node = get_node("/root/PlaytestMoments")
	moments.open_for_task(str(CHAPTER), str(LEVEL))
	await get_tree().process_frame
	if not moments.panel.visible or not moments.send_opinion.is_visible_in_tree() or moments.send_opinion.disabled:
		check(false, "The actual configured player form must expose an enabled Send action.")
		return
	if final_candidate:
		check_loopback_results(moments, remote)
	if config.phase == "write":
		check(remote.queue.is_empty(), "The new isolated outbox starts empty.")
		moments.opinion.text = NOTE
		moments.send_opinion.pressed.emit()
		var id: String = remote.feedback_id(moments.saved_opinion)
		evidence["feedback_id"] = id
		var durable: bool = has_durable_opinion(remote, id)
		check(durable, "Explicit Send writes exactly one opinion and its loopback destination to the outbox.")
		if durable:
			var state: String = await wait_for_feedback(remote, id, "failed_retryable")
			print("VNB_WINDOWS_QA: offline transport state=%s queue_count=%d" % [state, remote.queue.size()])
			check(state == "failed_retryable", "An unavailable loopback receiver leaves the opinion retryable.")
			check(has_durable_opinion(remote, id), "The retryable opinion remains in the persisted outbox.")
		else:
			print("VNB_WINDOWS_QA: initial Send state=%s queue_count=%d saved_id_present=%s" %
				[remote.feedback_state(id), remote.queue.size(), str(id.length() == 64)])
	else:
		var id: String = previous.feedback_id
		evidence["feedback_id"] = id
		check(remote.feedback_id(moments.saved_opinion) == id and moments.opinion.text == NOTE,
			"A separate Game process reopened the same unfinished-task opinion.")
		remote.retry_pending()
		var state: String = await wait_for_feedback(remote, id, "sent")
		print("VNB_WINDOWS_QA: restart transport state=%s queue_count=%d" % [state, remote.queue.size()])
		check(state == "sent" and remote.queue.is_empty() and id in moments.opinion_status.text,
			"The loopback receiver acknowledged the same ID after restart.")
	check(not remote.enabled and not remote.scores_enabled, "Explicit opinion did not enable automatic sharing.")
	if final_candidate:
		check(store.telemetry_enabled and store.level_exited(CHAPTER, LEVEL),
			"The client records a real task visit locally before automatic consent.")
		check(remote.queue.is_empty() if config.phase == "restart" else has_durable_opinion(remote, evidence.feedback_id),
			"No automatic events were queued before consent.")
		if config.phase == "restart" and failures.is_empty():
			await automatic_feedback(remote, store, moments)
	moments.close()


func automatic_feedback(remote: Node, store: Node, moments: Node) -> void:
	print("VNB_WINDOWS_QA: checking explicit service acceptance and automatic completion delivery")
	if not choose_first_consent(true):
		return
	check(remote.enabled and remote.sharing_mode == "basic" and remote.consented_endpoint == config.endpoint
		and not remote.scores_enabled, "Basic consent authorizes automatic events for loopback only.")
	check_loopback_results(moments, remote)
	await send_completed_visit(remote, store)
	check_loopback_results(moments, remote)


func send_completed_visit(remote: Node, store: Node) -> void:
	check(store.level_started(CHAPTER, LEVEL), "A new visit starts after consent.")
	var visit_id: String = store.current_visit_id
	check(store.level_completed(CHAPTER, LEVEL) and store.level_exited(CHAPTER, LEVEL)
		and not visit_id.is_empty(), "The synthetic local task completes and the consented visit ends.")
	var ids := {}
	for item: Dictionary in remote.queue:
		var record: Dictionary = item.record
		if record.kind == "event" and record.payload.get("visit_id") == visit_id:
			ids[record.payload.get("event", "")] = record.event_id
	if remote.queue.size() != 2 or not ids.has_all(["level_complete", "visit_summary"]):
		check(false, "Basic sharing queues exactly the completion and summary for the new visit.")
		return
	var started := {"ids": {}}
	var observe := func() -> void:
		for id: String in remote.inflight:
			started.ids[id] = true
	remote.status_changed.connect(observe)
	# The packaged scheduler must send before the periodic 45-second flush.
	var deadline: int = Time.get_ticks_msec() + ceili((remote.request.timeout + 3.0) * 1000.0)
	while remote.status in ["pending", "sending"] and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.1).timeout
	remote.status_changed.disconnect(observe)
	# An exact ACK drains automatic events without persisting an opinion receipt.
	# The Python verifier also checks both exact IDs against the receiver database.
	print("VNB_WINDOWS_QA: automatic transport status=%s queue_count=%d inflight_count=%d" %
		[remote.status, remote.queue.size(), remote.inflight.size()])
	check(started.ids.has_all(ids.values()) and remote.status == "sent"
		and remote.queue.is_empty() and remote.inflight.is_empty(),
		"The packaged scheduler sent both records and the receiver acknowledged them.")
	evidence["automatic_ids"] = ids
	evidence["automatic_visit_id"] = visit_id


func is_loopback(endpoint: String) -> bool:
	var port: String = endpoint.trim_prefix("http://127.0.0.1:")
	return endpoint.begins_with("http://127.0.0.1:") and port.is_valid_int() and int(port) in range(1, 65536)


func verify_private_view(remote: Node, store: Node) -> void:
	# The EXE firewall is active. Only the event transport is redirected; the
	# packaged client still evaluates consent and registration for its real origin.
	var isolated_url: String = str(config.transport_endpoint) + "/v1/events"
	remote._post_events = func(logical_url: String, body: String) -> Error:
		if logical_url != RESULTS_ORIGIN + "/v1/events":
			check(false, "Unexpected logical destination in the private-view phase.")
			return ERR_INVALID_PARAMETER
		return remote.request.request(isolated_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if not choose_first_consent(true):
		return
	check(remote.enabled and remote.consented_endpoint == RESULTS_ORIGIN + "/v1" and remote.sharing_mode == "basic",
		"Accepting applies Basic to the canonical service.")
	var moments: Node = get_node("/root/PlaytestMoments")
	moments.open_for_task(str(CHAPTER), str(LEVEL))
	var button: Button = moments.panel.find_child("ViewMyResults", true, false) as Button
	if button == null:
		check(false, "The actual feedback form exposes the personal results control.")
		moments.close()
		return
	check(button.is_visible_in_tree() and button.disabled and not remote.has_registered_upload()
		and remote.my_results_url().is_empty(), "Before the first ACK, results are visible but disabled and have no URL.")
	if not failures.is_empty():
		moments.close()
		return
	check(store.start_session(), "The isolated private-view scenario starts its local session.")
	await send_completed_visit(remote, store)
	var link: String = remote.my_results_url()
	var prefix: String = RESULTS_ORIGIN + "/my-results.html#"
	var fragment := RegEx.new()
	var valid: bool = (fragment.compile("^client_id=[0-9a-f]{32}&key=[0-9a-f]{64}$") == OK
		and link.begins_with(prefix) and fragment.search(link.trim_prefix(prefix)) != null)
	check(button.is_visible_in_tree() and not button.disabled and remote.has_registered_upload() and valid,
		"After the matching ACK, the results control is enabled with a private read link.")
	moments.close()
	print("VNB_WINDOWS_QA: private results authorization checked without opening or recording the URL")


func check_loopback_results(moments: Node, remote: Node) -> void:
	var button: Button = moments.panel.find_child("ViewMyResults", true, false) as Button
	check(button != null and not button.is_visible_in_tree() and remote.my_results_url().is_empty(),
		"Loopback never exposes the personal results link or its credentials.")


func choose_first_consent(accept: bool) -> bool:
	var prompt: CanvasLayer = load("res://src/playtest/sharing_first_choice.gd").new()
	add_child(prompt)
	var decline: Button = prompt.find_child("SharingLocalOnly", true, false) as Button
	var allow: Button = prompt.find_child("SharingBasic", true, false) as Button
	var details: LinkButton = prompt.find_child("SharingInventory", true, false) as LinkButton
	var valid: bool = (decline != null and allow != null and details != null
		and decline.is_visible_in_tree() and allow.is_visible_in_tree() and details.is_visible_in_tree()
		and not decline.disabled and not allow.disabled
		and decline.get_meta("locale_key", "") == "settings.decline_service"
		and allow.get_meta("locale_key", "") == "settings.accept_service"
		and decline.size_flags_horizontal == allow.size_flags_horizontal
		and decline.custom_minimum_size == allow.custom_minimum_size)
	check(valid, "Both explicit consent choices and local details are visible with equal sizing rules.")
	if valid:
		var button: Button = allow if accept else decline
		button.pressed.emit()
		var saved := ConfigFile.new()
		valid = (not button.is_visible_in_tree() and saved.load("user://sharing_prompt.cfg") == OK
			and saved.get_value("choice", "endpoint", "") == config.endpoint)
		check(valid, "The actual consent action closed the prompt and persisted the loopback choice.")
		evidence["consent_control"] = "SharingBasic" if accept else "SharingLocalOnly"
	prompt.queue_free()
	return valid


func finish(user_dir: String) -> void:
	evidence.merge({"passed":failures.is_empty(),"phase":config.phase,"user_dir":user_dir,
		"pid":OS.get_process_id(),"failures":failures})
	var file := FileAccess.open(str(config.output).path_join(str(config.phase) + ".json"), FileAccess.WRITE)
	if file == null:
		push_error("Could not write the Windows package QA receipt.")
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(evidence, "  "))
	file.close()
	if failures.is_empty(): print("PASS: Windows release " + str(config.phase))
	get_tree().quit(0 if failures.is_empty() else 1)
