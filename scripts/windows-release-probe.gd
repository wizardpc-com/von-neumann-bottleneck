extends Node
## Synthetic controller for the hosted Windows draft-package check.

const NOTE := "SYNTHETIC hosted Windows release check"
const BENCH := "Synthetic hosted restart"
const CHAPTER := &"hardware_foundations"
const LEVEL := &"tutorial"
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
	var port: String = endpoint.trim_prefix("http://127.0.0.1:")
	var isolated: bool = (OS.get_name() == "Windows" and OS.has_feature("free_candidate")
		and config.phase in ["write", "restart"] and user_dir.nocasecmp_to(absolute(config.user_dir)) == 0
		and user_dir.ends_with("/HostedWindowsReleaseQA/VonNeumannBottleneckCandidates/representation/" + identity.save_profile))
	var correct_endpoint: bool = endpoint.is_empty() if test else (
		endpoint.begins_with("http://127.0.0.1:") and port.is_valid_int() and int(port) in range(1, 65536))
	if (not isolated or not correct_endpoint or remote.endpoint != endpoint or remote.privacy_url() != ""
			or store.source_kind != "automated" or remote.enabled or remote.scores_enabled):
		push_error("Refusing feedback or saves without the exact isolated Windows profile and loopback-only settings.")
		get_tree().quit(2)
		return
	if not test:
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
	if not test:
		check(remote.is_public_game() and not remote.community_available()
			and ProjectSettings.get_setting("application/community_feedback_enabled", true) == false
			and not remote.set_scores_enabled(true),
			"Public Game must keep its opinion-only player policy.")
	var unlocked: int = 0
	var tasks: Array = get_node("/root/TaskNavigation").journey_tasks()
	for task: Dictionary in tasks:
		if task.unlocked: unlocked += 1
		check(not task.completed, "The synthetic setup must not grant campaign completion.")
	check(tasks.size() == 60 and (unlocked == 60 if test else unlocked > 0 and unlocked < 60),
		"The locked edition has the expected actual task access.")
	if not failures.is_empty():
		finish(user_dir)
		return
	print("VNB_WINDOWS_QA: isolated profile, identity and edition policy verified")

	var save: Node = get_node("/root/GlobalSave")
	var workbench_path: String = absolute(save.workbench_storage_path)
	if not workbench_path.to_lower().begins_with(user_dir.to_lower() + "/"):
		push_error("Refusing to write an unisolated workbench.")
		get_tree().quit(2)
		return
	var repo: Variant = load("res://src/hardware_foundations/circuit_workbench_store.gd").new(save.workbench_storage_path)
	var namespace_id: StringName = &"test" if test else &"game"
	var board := {"components":[], "wires":[]}
	var previous: Dictionary = {}
	if config.phase == "write":
		check(not FileAccess.file_exists(workbench_path), "The first process opens a fresh workbench store.")
		check(repo.create_workbench(namespace_id, LEVEL, BENCH, board) == &"", "The real workbench store saved the synthetic board.")
	else:
		var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(config.output).path_join("write.json")))
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
	if test:
		await offline_feedback(offline, previous)
	else:
		await online_feedback(remote, previous)
	check(FileAccess.get_sha256(workbench_path) == evidence.workbench_sha256, "Feedback leaves the workbench bytes unchanged.")
	finish(user_dir)


func offline_feedback(offline: Node, previous: Dictionary) -> void:
	print("VNB_WINDOWS_QA: checking offline capture and local bundle")
	if config.phase == "write":
		check(offline.store.cases().is_empty(), "The offline case store starts empty.")
		offline.open_for_task(str(CHAPTER), str(LEVEL))
		await get_tree().process_frame
		check(offline.backdrop.visible and not offline.current.is_empty(), "The actual offline panel recorded the unfinished task.")
		if offline.current.is_empty(): return
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


func online_feedback(remote: Node, previous: Dictionary) -> void:
	print("VNB_WINDOWS_QA: checking unfinished task opinion with loopback fixture")
	var moments: Node = get_node("/root/PlaytestMoments")
	moments.open_for_task(str(CHAPTER), str(LEVEL))
	await get_tree().process_frame
	if not moments.panel.visible or moments.send_opinion.disabled:
		check(false, "The actual configured Game form must expose an enabled Send action.")
		return
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
	moments.close()


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
