extends SceneTree

const PlaytestDataType = preload("res://src/playtest/playtest_data.gd")

var failures: Array[String] = []


func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("PASS: durable playtest session, recovery, feedback, summary, export, and clean-reset tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d test assertion(s) failed" % failures.size())
		quit(1)


func _run_all() -> void:
	var test_directory: String = "res://.godot/playtest_data_test_%d" % Time.get_ticks_usec()
	var first := PlaytestDataType.new()
	_assert(first.configure_for_storage(test_directory, &"test"), "A fresh store must accept an isolated storage directory.")
	_assert(first.start_session(), "A fresh store must create a durable session: %s" % first.last_error)
	var first_session_id: String = first.session_id()
	_assert(not first_session_id.is_empty(), "Every playtest session must have an anonymous non-empty identifier.")
	_assert(FileAccess.file_exists(first.session_file_path()), "Session start must immediately create its JSONL event stream.")

	first.level_started(&"hardware_foundations", &"half_adder")
	first.record_hint(&"hardware_foundations", &"half_adder", 1)
	first.record_hint(&"hardware_foundations", &"half_adder", 2)
	first.record_tool_opened(&"hardware_foundations", &"half_adder", &"test_bench")
	first.record_modification(&"hardware_foundations", &"half_adder", &"hardware", {"operation": "connect"})
	first.record_official_run(&"hardware_foundations", &"half_adder", false)
	first.submit_level_feedback(
		&"hardware_foundations", &"half_adder", 4, 3, 5,
		"x".repeat(PlaytestDataType.MAX_SHORT_TEXT_LENGTH + 40)
	)
	_append_corrupt_trailing_record(first.session_file_path())

	var recovered := PlaytestDataType.new()
	recovered.configure_for_storage(test_directory, &"test")
	_assert(recovered.start_session(), "An interrupted session must be recoverable despite a corrupt trailing record: %s" % recovered.last_error)
	_assert(recovered.session_id() == first_session_id, "Recovery must retain the interrupted session identity.")
	_assert(recovered.recovered_session(), "Recovery must be explicitly marked in the exported session metadata.")
	first.free()

	recovered.level_started(&"chapter_2", &"capstone")
	recovered.record_modification(&"chapter_2", &"capstone", &"program", {"direction": "row_first"})
	recovered.record_modification(&"chapter_2", &"capstone", &"cache", {"from": 1, "to": 4})
	recovered.record_official_run(&"chapter_2", &"capstone", false, {"cycles": 210, "cost": 4})
	recovered.record_official_run(&"chapter_2", &"capstone", true, {"cycles": 138, "cost": 4})
	recovered.level_completed(&"chapter_2", &"capstone", {
		"final_config": {"pattern": "row-first", "cache_lines": 1, "work_group_lines": 1},
		"metrics": {"cycles": 138, "cost": 4},
	})
	recovered.record_official_run(&"chapter_2", &"capstone", true, {
		"cycles": 130, "cost": 7, "post_completion": true,
	})
	recovered.submit_chapter_feedback(&"chapter_2", &"blocking", &"distant_reads", "confusing", "surprising", 3)
	recovered.submit_demo_feedback(4, 3, &"about_right", "Profiler", "shorten intro", 5)

	var export_path: String = recovered.export_current_session()
	_assert(not export_path.is_empty() and FileAccess.file_exists(export_path), "Export must produce one sendable JSON file: %s" % recovered.last_error)
	var document_variant: Variant = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	_assert(document_variant is Dictionary, "Exported playtest data must be valid JSON.")
	if document_variant is Dictionary:
		var document := document_variant as Dictionary
		_assert(int(document.get("schema_version", 0)) == PlaytestDataType.EXPORT_SCHEMA_VERSION, "Export must carry its schema version.")
		var session: Dictionary = document.get("session", {})
		_assert(String(session.get("id", "")) == first_session_id and bool(session.get("recovered", false)), "Export must bind recovery and feedback to the same anonymous session.")
		_assert(int(session.get("ignored_record_count", 0)) == 1, "A corrupt trailing JSONL record must be ignored and reported without losing earlier events.")
		var events: Array = document.get("events", [])
		_assert(not events.is_empty() and _all_events_use_mode(events, "test"), "Every event must explicitly distinguish Test mode.")
		var summaries: Array = document.get("level_summaries", [])
		var half_adder: Dictionary = _find_summary(summaries, "hardware_foundations", "half_adder")
		_assert(
			int(half_adder.get("official_runs", 0)) == 1
			and int(half_adder.get("failures", 0)) == 1
			and int(half_adder.get("hint_uses", 0)) == 2
			and int(half_adder.get("max_hint_stage", 0)) == 2,
			"Level summaries must preserve official attempts, failures, and hint use across recovery."
		)
		var capstone: Dictionary = _find_summary(summaries, "chapter_2", "capstone")
		var first_modification: Dictionary = capstone.get("capstone_first_modification", {})
		_assert(
			String(first_modification.get("target", "")) == "program"
			and bool(capstone.get("post_completion_optimization", false))
			and int(capstone.get("official_runs", 0)) == 3
			and int(capstone.get("retries", 0)) == 2,
			"Capstone summary must preserve the first modification direction, retries, and post-completion optimization."
		)
		var level_feedback: Array = (document.get("feedback", {}) as Dictionary).get("level", [])
		_assert(
			level_feedback.size() == 1
			and String((level_feedback[0] as Dictionary).get("note", "")).length() == PlaytestDataType.MAX_SHORT_TEXT_LENGTH,
			"Optional feedback text must be stored only in its bounded field."
		)
		_assert(not _contains_key_recursive(document, "program_source"), "The playtest export must not contain complete program source fields.")

	recovered.end_session()
	recovered.free()
	var clean_restart := PlaytestDataType.new()
	clean_restart.configure_for_storage(test_directory, &"game")
	_assert(clean_restart.start_session(), "A cleanly ended playtest must allow a new session.")
	_assert(clean_restart.session_id() != first_session_id, "A clean launch must receive a unique session ID instead of resuming the ended session.")
	clean_restart.end_session()
	clean_restart.free()
	var unconfigured := PlaytestDataType.new()
	_assert(not unconfigured.configure_for_storage(""), "An invalid storage target must fail closed without creating a session.")
	_assert(not unconfigured.level_started(&"chapter_1", &"assembly"), "A disabled or uninitialized recorder must be a gameplay-safe no-op.")
	unconfigured.free()

	var reset_directory: String = "res://.godot/playtest_reset_test_%d" % Time.get_ticks_usec()
	var reset_workbench_path: String = reset_directory.path_join("hardware_workbenches_v1.json")
	var reset_export_path: String = reset_directory.path_join("exports/keep.json")
	_write_text(reset_directory.path_join(PlaytestDataType.ACTIVE_SESSION_FILE), "{}")
	_write_text(reset_directory.path_join("session_old.jsonl"), "{}\n")
	_write_text(reset_directory.path_join("notes.txt"), "keep")
	_write_text(reset_export_path, "{}")
	_write_text(reset_workbench_path, "{}")
	var reset_result: Dictionary = PlaytestDataType.reset_local_test_state(reset_directory, reset_workbench_path)
	_assert(bool(reset_result.get("ok", false)), "The explicit clean-playtest reset must complete without errors.")
	_assert(
		not FileAccess.file_exists(reset_directory.path_join(PlaytestDataType.ACTIVE_SESSION_FILE))
		and not FileAccess.file_exists(reset_directory.path_join("session_old.jsonl"))
		and not FileAccess.file_exists(reset_workbench_path),
		"Clean reset must remove the active marker, anonymous session streams, and workbench state."
	)
	_assert(
		FileAccess.file_exists(reset_export_path)
		and FileAccess.file_exists(reset_directory.path_join("notes.txt")),
		"Clean reset must preserve exported playtest JSON and unrelated local files."
	)

	_remove_tree(ProjectSettings.globalize_path(test_directory).replace("\\", "/"))
	_remove_tree(ProjectSettings.globalize_path(reset_directory).replace("\\", "/"))


func _write_text(path: String, text: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path).replace("\\", "/")
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		failures.append("Could not create test directory for %s." % path)
		return
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		failures.append("Could not create reset fixture %s." % path)
		return
	file.store_string(text)
	file.close()


func _append_corrupt_trailing_record(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		failures.append("Could not open the test JSONL stream to simulate an interrupted trailing write.")
		return
	file.seek_end()
	file.store_line("{interrupted")
	file.flush()
	file.close()


func _all_events_use_mode(events: Array, mode: String) -> bool:
	for event_variant: Variant in events:
		if not event_variant is Dictionary or String((event_variant as Dictionary).get("mode", "")) != mode:
			return false
	return true


func _find_summary(summaries: Array, chapter_id: String, level_id: String) -> Dictionary:
	for summary_variant: Variant in summaries:
		if not summary_variant is Dictionary:
			continue
		var summary := summary_variant as Dictionary
		if String(summary.get("chapter_id", "")) == chapter_id and String(summary.get("level_id", "")) == level_id:
			return summary
	return {}


func _contains_key_recursive(value: Variant, target_key: String) -> bool:
	if value is Dictionary:
		for key_variant: Variant in value:
			if String(key_variant) == target_key or _contains_key_recursive(value[key_variant], target_key):
				return true
	elif value is Array:
		for entry: Variant in value:
			if _contains_key_recursive(entry, target_key):
				return true
	return false


func _remove_tree(absolute_path: String) -> void:
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var child: String = absolute_path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
