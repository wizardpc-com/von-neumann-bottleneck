class_name PlaytestDataStore
extends Node

const SCHEMA_VERSION: int = 1
const EXPORT_SCHEMA_VERSION: int = 1
const MAX_SHORT_TEXT_LENGTH: int = 240
const DEFAULT_STORAGE_DIRECTORY: String = "user://playtest_data"
const ACTIVE_SESSION_FILE: String = "active_session.json"

var telemetry_enabled: bool = true
var questionnaire_enabled: bool = true
var storage_directory: String = DEFAULT_STORAGE_DIRECTORY
var forced_mode: StringName = &""
var last_error: String = ""

var _initialized: bool = false
var _ended: bool = false
var _session_id: String = ""
var _session_started_at_utc: String = ""
var _events_path: String = ""
var _sequence: int = 0
var _events: Array[Dictionary] = []
var _level_summaries: Dictionary = {}
var _active_level_key: String = ""
var _active_level_started_ms: int = 0
var _recovered: bool = false
var _read_error_count: int = 0


func _ready() -> void:
	_configure_from_command_line()
	if telemetry_enabled:
		start_session()


func _exit_tree() -> void:
	end_session()


func configure_for_storage(directory: String, mode: StringName = &"game") -> bool:
	if _initialized:
		return false
	storage_directory = directory.trim_suffix("/").trim_suffix("\\")
	forced_mode = mode
	telemetry_enabled = true
	return not storage_directory.is_empty()


func start_session() -> bool:
	if _initialized:
		return true
	last_error = ""
	if not telemetry_enabled:
		return false
	if not _ensure_directory(storage_directory):
		return false
	var resumed: bool = _try_resume_active_session()
	if not resumed and not _start_new_session():
		return false
	_initialized = true
	_ended = false
	if resumed:
		_recovered = true
		_append_event(&"session_resumed", {
			"recovered_event_count": _events.size(),
			"ignored_record_count": _read_error_count,
		})
		if not _active_level_key.is_empty():
			_finish_active_level(&"level_exit", {"reason": "interrupted"})
	return true


func end_session() -> void:
	if not _initialized or _ended:
		return
	if not _active_level_key.is_empty():
		_finish_active_level(&"level_exit", {"reason": "application_exit"})
	_append_event(&"session_end", {})
	_ended = true
	_remove_active_marker()


func questionnaires_enabled() -> bool:
	return questionnaire_enabled


func session_id() -> String:
	return _session_id


func session_file_path() -> String:
	return _events_path


func recovered_session() -> bool:
	return _recovered


func level_started(chapter_id: StringName, level_id: StringName) -> bool:
	if not _can_record_level(chapter_id, level_id):
		return false
	var key: String = _level_key(chapter_id, level_id)
	if _active_level_key == key:
		return true
	if not _active_level_key.is_empty():
		_finish_active_level(&"level_exit", {"reason": "superseded"})
	return _append_event(&"level_start", {
		"chapter_id": String(chapter_id),
		"level_id": String(level_id),
	})


func level_completed(chapter_id: StringName, level_id: StringName, details: Dictionary = {}) -> bool:
	if not _can_record_level(chapter_id, level_id):
		return false
	var key: String = _level_key(chapter_id, level_id)
	if _active_level_key != key:
		level_started(chapter_id, level_id)
	var payload: Dictionary = _safe_details(details)
	payload["chapter_id"] = String(chapter_id)
	payload["level_id"] = String(level_id)
	return _finish_active_level(&"level_complete", payload)


func level_exited(chapter_id: StringName, level_id: StringName, reason: StringName = &"map") -> bool:
	if not _can_record_level(chapter_id, level_id):
		return false
	if _active_level_key != _level_key(chapter_id, level_id):
		return false
	return _finish_active_level(&"level_exit", {"reason": String(reason)})


func record_official_run(
		chapter_id: StringName,
		level_id: StringName,
		passed: bool,
		details: Dictionary = {}
	) -> bool:
	var payload: Dictionary = _safe_details(details)
	payload["passed"] = passed
	return _record_level_event(&"official_run", chapter_id, level_id, payload)


func record_modification(
		chapter_id: StringName,
		level_id: StringName,
		target: StringName,
		details: Dictionary = {}
	) -> bool:
	var payload: Dictionary = _safe_details(details)
	payload["target"] = String(target)
	return _record_level_event(&"modification", chapter_id, level_id, payload)


func record_hint(chapter_id: StringName, level_id: StringName, stage: int) -> bool:
	return _record_level_event(&"hint_used", chapter_id, level_id, {
		"stage": maxi(1, stage),
	})


func record_tool_opened(chapter_id: StringName, level_id: StringName, tool_id: StringName) -> bool:
	return _record_level_event(&"tool_opened", chapter_id, level_id, {
		"tool_id": String(tool_id),
	})


func record_trace_action(chapter_id: StringName, level_id: StringName, action: StringName) -> bool:
	return _record_level_event(&"trace_action", chapter_id, level_id, {
		"action": String(action),
	})


func record_action(
		chapter_id: StringName,
		level_id: StringName,
		action: StringName,
		details: Dictionary = {}
	) -> bool:
	var payload: Dictionary = _safe_details(details)
	payload["action"] = String(action)
	return _record_level_event(&"player_action", chapter_id, level_id, payload)


func submit_level_feedback(
		chapter_id: StringName,
		level_id: StringName,
		fun_rating: int,
		clarity_rating: int,
		continue_rating: int,
		note: String = ""
	) -> bool:
	if not _valid_rating(fun_rating) or not _valid_rating(clarity_rating) \
			or not _valid_rating(continue_rating):
		return false
	return _append_event(&"level_feedback", {
		"chapter_id": String(chapter_id),
		"level_id": String(level_id),
		"fun": fun_rating,
		"clarity": clarity_rating,
		"want_to_continue": continue_rating,
		"note": _bounded_text(note),
	})


func submit_chapter_feedback(
		chapter_id: StringName,
		best_level_id: StringName,
		worst_level_id: StringName,
		confusing_point: String,
		surprising_point: String,
		pace_rating: int
	) -> bool:
	if chapter_id.is_empty() or best_level_id.is_empty() or worst_level_id.is_empty() \
			or not _valid_rating(pace_rating):
		return false
	return _append_event(&"chapter_feedback", {
		"chapter_id": String(chapter_id),
		"best_level_id": String(best_level_id),
		"worst_level_id": String(worst_level_id),
		"confusing_point": _bounded_text(confusing_point),
		"surprising_point": _bounded_text(surprising_point),
		"pace": pace_rating,
	})


func submit_demo_feedback(
		satisfaction_rating: int,
		difficulty_rating: int,
		length_feeling: StringName,
		favorite_content: String,
		change_or_remove: String,
		continue_interest_rating: int
	) -> bool:
	if not _valid_rating(satisfaction_rating) or not _valid_rating(difficulty_rating) \
			or not _valid_rating(continue_interest_rating) \
			or length_feeling not in [&"too_short", &"about_right", &"too_long"]:
		return false
	return _append_event(&"demo_feedback", {
		"satisfaction": satisfaction_rating,
		"difficulty": difficulty_rating,
		"length_feeling": String(length_feeling),
		"favorite_content": _bounded_text(favorite_content),
		"change_or_remove": _bounded_text(change_or_remove),
		"continue_interest": continue_interest_rating,
	})


func record_feedback_skipped(scope: StringName, subject_id: StringName) -> bool:
	if scope not in [&"level", &"chapter", &"demo"]:
		return false
	return _append_event(&"feedback_skipped", {
		"scope": String(scope),
		"subject_id": String(subject_id),
	})


func export_current_session() -> String:
	last_error = ""
	if not _initialized or _session_id.is_empty():
		last_error = "No active playtest session is available."
		return ""
	var parsed: Dictionary = _read_event_file(_events_path)
	var export_events: Array = parsed.get("events", [])
	var ignored_records: int = int(parsed.get("errors", 0))
	var summaries: Array[Dictionary] = _export_level_summaries()
	var feedback: Dictionary = {
		"level": [],
		"chapter": [],
		"demo": [],
		"skipped": [],
	}
	for event_variant: Variant in export_events:
		if not event_variant is Dictionary:
			continue
		var event := event_variant as Dictionary
		match StringName(event.get("event", &"")):
			&"level_feedback": (feedback["level"] as Array).append(event.get("payload", {}).duplicate(true))
			&"chapter_feedback": (feedback["chapter"] as Array).append(event.get("payload", {}).duplicate(true))
			&"demo_feedback": (feedback["demo"] as Array).append(event.get("payload", {}).duplicate(true))
			&"feedback_skipped": (feedback["skipped"] as Array).append(event.get("payload", {}).duplicate(true))
	var document: Dictionary = {
		"schema_version": EXPORT_SCHEMA_VERSION,
		"event_schema_version": SCHEMA_VERSION,
		"session": {
			"id": _session_id,
			"started_at_utc": _session_started_at_utc,
			"recovered": _recovered,
			"event_count": export_events.size(),
			"ignored_record_count": ignored_records,
		},
		"level_summaries": summaries,
		"feedback": feedback,
		"events": export_events,
		"privacy": {
			"local_only": true,
			"records_personal_identity": false,
			"records_program_source": false,
			"free_text_max_characters": MAX_SHORT_TEXT_LENGTH,
		},
	}
	var export_directory: String = _storage_path("exports")
	if not _ensure_directory(export_directory):
		return ""
	var destination: String = export_directory.path_join(
		"playtest_%s_%d.json" % [_session_id, _now_ms()]
	)
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		last_error = "Could not create playtest export: %s" % error_string(FileAccess.get_open_error())
		return ""
	file.store_string(JSON.stringify(document, "  ", false))
	file.flush()
	file.close()
	return destination


func _configure_from_command_line() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	var explicitly_enable_telemetry: bool = "--enable-playtest-telemetry" in arguments
	var explicitly_enable_feedback: bool = "--enable-playtest-feedback" in arguments
	var automated: bool = "--script" in arguments or DisplayServer.get_name() == "headless"
	for argument: String in arguments:
		if argument.begins_with("--capture"):
			automated = true
			break
	telemetry_enabled = explicitly_enable_telemetry or (
		not automated and "--disable-playtest-telemetry" not in arguments
	)
	questionnaire_enabled = explicitly_enable_feedback or (
		not automated and "--disable-playtest-feedback" not in arguments
	)


func _try_resume_active_session() -> bool:
	var marker_path: String = _storage_path(ACTIVE_SESSION_FILE)
	if not FileAccess.file_exists(marker_path):
		return false
	var marker_json := JSON.new()
	if marker_json.parse(FileAccess.get_file_as_string(marker_path)) != OK:
		return false
	var marker_variant: Variant = marker_json.data
	if not marker_variant is Dictionary:
		return false
	var marker := marker_variant as Dictionary
	var candidate_id: String = String(marker.get("session_id", ""))
	if not _safe_session_id(candidate_id):
		return false
	var candidate_path: String = _storage_path("session_%s.jsonl" % candidate_id)
	if not FileAccess.file_exists(candidate_path):
		return false
	var parsed: Dictionary = _read_event_file(candidate_path)
	var loaded_events: Array = parsed.get("events", [])
	if loaded_events.is_empty():
		return false
	var last_event: Dictionary = loaded_events[loaded_events.size() - 1]
	if StringName(last_event.get("event", &"")) == &"session_end":
		return false
	_session_id = candidate_id
	_events_path = candidate_path
	_events.assign(loaded_events)
	_read_error_count = int(parsed.get("errors", 0))
	_session_started_at_utc = String((_events[0].get("payload", {}) as Dictionary).get(
		"started_at_utc", _events[0].get("timestamp_utc", "")
	))
	_sequence = 0
	for event: Dictionary in _events:
		_sequence = maxi(_sequence, int(event.get("sequence", 0)))
	_rebuild_state_from_events()
	return true


func _start_new_session() -> bool:
	_session_id = _generate_session_id()
	_session_started_at_utc = _now_utc()
	_events_path = _storage_path("session_%s.jsonl" % _session_id)
	_events.clear()
	_level_summaries.clear()
	_active_level_key = ""
	_active_level_started_ms = 0
	_sequence = 0
	_recovered = false
	_read_error_count = 0
	if not _write_active_marker():
		return false
	var file := FileAccess.open(_events_path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not create playtest event file: %s" % error_string(FileAccess.get_open_error())
		return false
	file.close()
	_initialized = true
	if not _append_event(&"session_start", {
		"started_at_utc": _session_started_at_utc,
		"project_version": String(ProjectSettings.get_setting("application/config/version", "development")),
	}):
		_initialized = false
		return false
	return true


func _write_active_marker() -> bool:
	var marker_path: String = _storage_path(ACTIVE_SESSION_FILE)
	var file := FileAccess.open(marker_path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write active playtest marker at %s: %s" % [
			marker_path, error_string(FileAccess.get_open_error())
		]
		return false
	file.store_string(JSON.stringify({
		"schema_version": SCHEMA_VERSION,
		"session_id": _session_id,
		"started_at_utc": _session_started_at_utc,
	}))
	file.flush()
	file.close()
	return true


func _remove_active_marker() -> void:
	var marker_path: String = _storage_path(ACTIVE_SESSION_FILE)
	if FileAccess.file_exists(marker_path):
		DirAccess.remove_absolute(marker_path)


func _record_level_event(
		event_name: StringName,
		chapter_id: StringName,
		level_id: StringName,
		details: Dictionary
	) -> bool:
	if not _can_record_level(chapter_id, level_id):
		return false
	var payload: Dictionary = _safe_details(details)
	payload["chapter_id"] = String(chapter_id)
	payload["level_id"] = String(level_id)
	return _append_event(event_name, payload)


func _finish_active_level(event_name: StringName, details: Dictionary) -> bool:
	if _active_level_key.is_empty():
		return false
	var summary: Dictionary = _level_summaries.get(_active_level_key, {})
	var payload: Dictionary = _safe_details(details)
	payload["chapter_id"] = String(summary.get("chapter_id", ""))
	payload["level_id"] = String(summary.get("level_id", ""))
	payload["duration_ms"] = maxi(0, _now_ms() - _active_level_started_ms)
	return _append_event(event_name, payload)


func _append_event(event_name: StringName, payload: Dictionary) -> bool:
	if not telemetry_enabled or not _initialized or _ended:
		return false
	var event: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"session_id": _session_id,
		"sequence": _sequence + 1,
		"timestamp_utc": _now_utc(),
		"timestamp_unix_ms": _now_ms(),
		"mode": String(_current_mode()),
		"event": String(event_name),
		"payload": _json_safe(payload),
	}
	var file: FileAccess = null
	if FileAccess.file_exists(_events_path):
		file = FileAccess.open(_events_path, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(_events_path, FileAccess.WRITE)
	if file != null and file.get_position() > 0:
		file.seek_end()
	if file == null:
		last_error = "Could not append playtest event: %s" % error_string(FileAccess.get_open_error())
		return false
	file.store_line(JSON.stringify(event, "", false))
	file.flush()
	file.close()
	_sequence += 1
	_events.append(event)
	_update_state_from_event(event)
	return true


func _rebuild_state_from_events() -> void:
	_level_summaries.clear()
	_active_level_key = ""
	_active_level_started_ms = 0
	for event: Dictionary in _events:
		_update_state_from_event(event)


func _update_state_from_event(event: Dictionary) -> void:
	var event_name := StringName(event.get("event", &""))
	var payload: Dictionary = event.get("payload", {})
	var chapter_id: String = String(payload.get("chapter_id", ""))
	var level_id: String = String(payload.get("level_id", ""))
	var key: String = _level_key(StringName(chapter_id), StringName(level_id)) \
		if not chapter_id.is_empty() and not level_id.is_empty() else ""
	var summary: Dictionary = _ensure_level_summary(key, chapter_id, level_id) if not key.is_empty() else {}
	match event_name:
		&"level_start":
			summary["visits"] = int(summary.get("visits", 0)) + 1
			_active_level_key = key
			_active_level_started_ms = int(event.get("timestamp_unix_ms", 0))
		&"level_exit":
			summary["duration_ms"] = int(summary.get("duration_ms", 0)) + int(payload.get("duration_ms", 0))
			if _active_level_key == key:
				_active_level_key = ""
				_active_level_started_ms = 0
		&"level_complete":
			summary["duration_ms"] = int(summary.get("duration_ms", 0)) + int(payload.get("duration_ms", 0))
			summary["completed"] = true
			summary["completion_count"] = int(summary.get("completion_count", 0)) + 1
			if payload.has("final_config"):
				summary["final_config"] = payload.get("final_config", {}).duplicate(true)
			if payload.has("metrics"):
				summary["final_metrics"] = payload.get("metrics", {}).duplicate(true)
			if _active_level_key == key:
				_active_level_key = ""
				_active_level_started_ms = 0
		&"official_run":
			summary["official_runs"] = int(summary.get("official_runs", 0)) + 1
			if not bool(payload.get("passed", false)):
				summary["failures"] = int(summary.get("failures", 0)) + 1
			if bool(payload.get("post_completion", false)):
				summary["post_completion_optimization"] = true
		&"hint_used":
			summary["hint_uses"] = int(summary.get("hint_uses", 0)) + 1
			summary["max_hint_stage"] = maxi(
				int(summary.get("max_hint_stage", 0)), int(payload.get("stage", 1))
			)
		&"tool_opened":
			var tools: Dictionary = summary.get("tools_opened", {})
			var tool_id: String = String(payload.get("tool_id", "unknown"))
			tools[tool_id] = int(tools.get(tool_id, 0)) + 1
			summary["tools_opened"] = tools
		&"trace_action":
			var trace_actions: Dictionary = summary.get("trace_actions", {})
			var trace_action: String = String(payload.get("action", "unknown"))
			trace_actions[trace_action] = int(trace_actions.get(trace_action, 0)) + 1
			summary["trace_actions"] = trace_actions
		&"modification":
			var modifications: Dictionary = summary.get("modifications", {})
			var target: String = String(payload.get("target", "other"))
			modifications[target] = int(modifications.get(target, 0)) + 1
			summary["modifications"] = modifications
			if chapter_id == "chapter_2" and level_id == "capstone" \
					and (summary.get("capstone_first_modification", {}) as Dictionary).is_empty():
				summary["capstone_first_modification"] = payload.duplicate(true)
		&"player_action":
			var actions: Dictionary = summary.get("actions", {})
			var action: String = String(payload.get("action", "other"))
			actions[action] = int(actions.get(action, 0)) + 1
			summary["actions"] = actions


func _ensure_level_summary(key: String, chapter_id: String, level_id: String) -> Dictionary:
	if not _level_summaries.has(key):
		_level_summaries[key] = {
			"chapter_id": chapter_id,
			"level_id": level_id,
			"visits": 0,
			"duration_ms": 0,
			"official_runs": 0,
			"failures": 0,
			"hint_uses": 0,
			"max_hint_stage": 0,
			"tools_opened": {},
			"trace_actions": {},
			"modifications": {},
			"actions": {},
			"completed": false,
			"completion_count": 0,
			"post_completion_optimization": false,
			"capstone_first_modification": {},
		}
	return _level_summaries[key]


func _export_level_summaries() -> Array[Dictionary]:
	var keys: Array[String] = []
	for key_variant: Variant in _level_summaries:
		keys.append(String(key_variant))
	keys.sort()
	var result: Array[Dictionary] = []
	for key: String in keys:
		var summary: Dictionary = (_level_summaries[key] as Dictionary).duplicate(true)
		summary["retries"] = maxi(0, int(summary.get("official_runs", 0)) - 1)
		result.append(_json_safe(summary))
	return result


func _read_event_file(path: String) -> Dictionary:
	var result: Dictionary = {"events": [], "errors": 0}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["errors"] = 1
		return result
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var json := JSON.new()
		if json.parse(line) != OK or not json.data is Dictionary:
			result["errors"] = int(result["errors"]) + 1
			continue
		var event := json.data as Dictionary
		if int(event.get("schema_version", 0)) != SCHEMA_VERSION \
				or String(event.get("session_id", "")) != _session_id and not _session_id.is_empty():
			result["errors"] = int(result["errors"]) + 1
			continue
		(result["events"] as Array).append(event)
	file.close()
	return result


func _safe_details(details: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key_variant: Variant in details:
		var key: String = String(key_variant)
		var lower_key: String = key.to_lower()
		if lower_key in ["source", "program_source", "notebook_text", "free_text", "note"]:
			continue
		result[key] = _json_safe(details[key_variant])
	return result


func _json_safe(value: Variant, depth: int = 0) -> Variant:
	if depth > 5:
		return null
	if value == null or value is bool or value is int or value is float:
		return value
	if value is String or value is StringName:
		return String(value).left(MAX_SHORT_TEXT_LENGTH)
	if value is Array:
		var safe_array: Array = []
		for entry: Variant in value:
			safe_array.append(_json_safe(entry, depth + 1))
		return safe_array
	if value is Dictionary:
		var safe_dictionary: Dictionary = {}
		for key_variant: Variant in value:
			safe_dictionary[String(key_variant)] = _json_safe(value[key_variant], depth + 1)
		return safe_dictionary
	return String(value).left(160)


func _bounded_text(value: String) -> String:
	return value.strip_edges().left(MAX_SHORT_TEXT_LENGTH)


func _valid_rating(value: int) -> bool:
	return value >= 1 and value <= 5


func _can_record_level(chapter_id: StringName, level_id: StringName) -> bool:
	return _initialized and not _ended and not chapter_id.is_empty() and not level_id.is_empty()


func _current_mode() -> StringName:
	if not forced_mode.is_empty():
		return forced_mode
	var game_mode: Node = get_node_or_null("/root/GameMode")
	if game_mode != null:
		return StringName(game_mode.get("current_mode"))
	return &"game"


func _ensure_directory(directory: String) -> bool:
	var absolute_directory: String = _absolute_path(directory)
	var error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if error != OK and error != ERR_ALREADY_EXISTS:
		last_error = "Could not create playtest data directory: %s" % error_string(error)
		return false
	return true


func _storage_path(relative_path: String) -> String:
	return _absolute_path(storage_directory.path_join(relative_path))


func _absolute_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path).replace("\\", "/")
	return path.replace("\\", "/")


func _generate_session_id() -> String:
	var timestamp: String = _now_utc().replace("-", "").replace(":", "").replace("T", "-")
	var random_suffix: String = Crypto.new().generate_random_bytes(8).hex_encode()
	return "%s-%s" % [timestamp, random_suffix]


func _safe_session_id(value: String) -> bool:
	return not value.is_empty() and value.length() <= 80 \
		and "/" not in value and "\\" not in value and ".." not in value


func _level_key(chapter_id: StringName, level_id: StringName) -> String:
	return "%s/%s" % [String(chapter_id), String(level_id)]


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func _now_utc() -> String:
	return Time.get_datetime_string_from_system(true, false)
