extends SceneTree

const Cinematic = preload("res://src/ui/cinematic_player.gd")
var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run cinematics checks through scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	var save: String = "user://eligibility.json"
	var bench: String = "user://eligibility_workbench.json"
	_check(Cinematic.new_player(save, bench), "A profile without player records is new.")
	for path: String in [save, save + ".bak", save + ".tmp", bench, bench + ".bak", "user://lab_state.cfg", "user://task_navigation.cfg"]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string("invalid or empty progress")
		file.close()
		_check(not Cinematic.new_player(save, bench), "Existing record suppresses opening even if empty, corrupt or backup-only: " + path)
		DirAccess.remove_absolute(path)
	_check(Cinematic.automated_launch(), "Automated launch is recognized.")
	_check(Cinematic.present_once(root, &"opening") == null and not FileAccess.file_exists(Cinematic.HISTORY_PATH), "Automation does not display or consume CGs.")
	_check(Cinematic.take_once(&"opening"), "Opening can be consumed once.")
	Cinematic._consumed.clear()
	_check(not Cinematic.take_once(&"opening"), "History persists across a fresh process cache.")
	_check(Cinematic.take_once(&"prologue_complete"), "The two clips have independent history.")
	_check(not Cinematic.take_once(&"unknown"), "Unknown clips do not write history.")
	var history_before: String = FileAccess.get_file_as_string(Cinematic.HISTORY_PATH)
	var global_save: Node = root.get_node("GlobalSave")
	global_save.configure_for_test("user://reset.json", "user://reset_workbench.json")
	var reset: Dictionary = global_save.start_new_game(false)
	_check(bool(reset.get("ok", false)) and FileAccess.get_file_as_string(Cinematic.HISTORY_PATH) == history_before, "New Game preserves viewing history separately from progression.")
	global_save.disk_write_allowed = false
	for id: StringName in [&"opening", &"prologue_complete"]:
		var movie := Cinematic.new()
		movie.clip_id = id
		var ended: Array[bool] = []
		var natural_end: Array[bool] = []
		movie.finished.connect(func() -> void: ended.append(true))
		root.add_child(movie)
		movie.video.finished.connect(func() -> void: natural_end.append(true))
		_check(paused and movie.video.is_playing(), "%s loads and starts with the scene paused." % id)
		_check(movie.video.bus == &"Effects", "%s follows the existing global sound volume and mute bus." % id)
		_check(movie.video.get_stream_length() > 40.0, "%s has the complete authored runtime." % id)
		for property: Dictionary in movie.video.get_property_list():
			if property.name == "speed_scale":
				movie.video.set("speed_scale", 8.0)
		var deadline: int = Time.get_ticks_msec() + 65000
		while ended.is_empty() and Time.get_ticks_msec() < deadline:
			await process_frame
		_check(ended.size() == 1 and natural_end.size() == 1 and not paused, "%s reaches the decoder's natural end and releases pause exactly once." % id)
		print("Decoded CG: ", id, " natural_end=", natural_end.size())
		movie.queue_free()
		await process_frame
	var skip := Cinematic.new()
	skip.clip_id = &"opening"
	root.add_child(skip)
	await process_frame
	for code: Key in [KEY_F10, KEY_F8]:
		await _key(code)
	_check(not is_instance_valid(root.get_node("WindowMode").settings_layer), "Settings shortcuts stay behind the cinematic.")
	_check(not root.get_node("PlaytestMoments").panel.visible and not root.get_node("OfflineFeedback").backdrop.visible, "Feedback shortcuts stay behind the cinematic.")
	ProjectSettings.set_setting("playtest/offline_tester", true)
	await _key(KEY_F8)
	_check(not root.get_node("OfflineFeedback").backdrop.visible, "Offline tester's polled F8 cannot open a hidden feedback panel.")
	ProjectSettings.set_setting("playtest/offline_tester", false)
	await _key(KEY_ESCAPE)
	_check(not paused and not skip.visible, "Escape skips and releases the modal.")
	skip.queue_free()
	await process_frame
	paused = true
	var button_skip := Cinematic.new()
	button_skip.clip_id = &"prologue_complete"
	root.add_child(button_skip)
	button_skip.skip_button.pressed.emit()
	_check(paused and not button_skip.visible, "Skip button restores a previously paused scene.")
	button_skip.queue_free()
	await process_frame
	paused = false
	var invalid := Cinematic.new()
	invalid.clip_id = &"invalid"
	root.add_child(invalid)
	await process_frame
	_check(not paused and not invalid.visible, "Missing media continues without trapping the player.")
	invalid.queue_free()
	await process_frame
	var closing := Cinematic.new()
	closing.clip_id = &"opening"
	root.add_child(closing)
	global_save.request_quit()
	_check(not paused and not closing.visible and global_save._failure_dialog.visible, "A failed save on window close releases CG before opening recovery controls.")
	global_save._failure_dialog.hide()
	closing.queue_free()
	await process_frame
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	for frame: int in range(12):
		await process_frame
	_check(current_scene != null and current_scene.name == "PrototypeHub", "Automated startup enters the real laboratory homepage.")
	_check(FileAccess.get_file_as_string(Cinematic.HISTORY_PATH) == history_before, "Automated startup leaves viewing history unchanged.")
	current_scene.queue_free()
	for frame: int in range(4):
		await process_frame
	if failures.is_empty():
		print("PASS: cinematics ", checks, " checks, including both complete Godot decoder playbacks")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
