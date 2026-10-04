extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame: int in 8:
		await process_frame

func clear_scene() -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await settle()

func progress() -> Dictionary:
	var snapshot: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	snapshot.erase("saved_at_utc")
	return snapshot

func run() -> void:
	var nav: Node = root.get_node("TaskNavigation")
	var mode: Node = root.get_node("GameMode")
	var save: Node = root.get_node("GlobalSave")
	var recorder: Node = root.get_node("PlaytestData")
	mode.set_mode(&"game")
	save.configure_for_test("user://direct-navigation-save.json", "user://direct-navigation-workbench.json")
	# Synthetic prerequisite only; native QA separately uses the UI-earned tutorial save.
	save.game_player_content.completed_levels[&"tutorial"] = true
	var before: Dictionary = progress()
	check(nav.enter("hardware_foundations/tutorial"), "Completed tutorial can be replayed through the tree")
	await settle()
	var hardware: Control = current_scene
	check(hardware.current_level_id == &"tutorial" and not hardware.tutorial_next_button.disabled,
		"Earned tutorial retains its direct next-task action")
	nav.camera = Vector2(123, 456)
	nav.camera_saved = true
	hardware.tutorial_next_button.pressed.emit()
	await settle()
	check(hardware.current_level_id == &"half_adder", "The direct button enters Half Adder")
	check(nav.selected == "hardware_foundations/half_adder" and not nav.camera_saved,
		"A direct task change replaces the stale map selection and requests recentering")
	hardware._open_campaign_map()
	await settle()
	check(current_scene.scene_file_path == nav.MAP_SCENE and current_scene.selected.key == "hardware_foundations/half_adder",
		"Level Map actually opens with Half Adder selected")
	check(progress() == before, "Direct entry and map return never award completion or alter saved designs")
	# Re-entering the already-selected tree node retains the user's map view.
	nav.camera = Vector2(123, 456)
	nav.camera_view_size = Vector2(900, 600)
	nav.camera_saved = true
	check(nav.enter("hardware_foundations/half_adder"), "The selected available tree node can be reopened")
	await settle()
	check(nav.camera_saved and nav.camera == Vector2(123, 456), "Matching tree entry preserves map pan")
	check(nav.camera_view_size == Vector2(900, 600), "Matching entry preserves the map viewport")
	hardware = current_scene
	hardware._start_campaign_level(&"latch", false)
	await settle()
	check(hardware.current_level_id == &"latch" and nav.selected == "hardware_foundations/latch" and not nav.camera_saved,
		"A direct prologue branch entry also follows the opened task")
	hardware._start_campaign_level(&"full_adder", false)
	check(hardware.current_level_id == &"latch" and nav.selected == "hardware_foundations/latch",
		"Rejected direct entry cannot replace the current task or its selection")
	hardware._open_campaign_map()
	await settle()
	check(current_scene.selected.key == "hardware_foundations/latch", "The prologue branch returns to its own map node")
	await clear_scene()
	# Picking another map node does not make that node the most recently played task.
	nav.selected = "hardware_foundations/tutorial"
	nav.camera_saved = true
	recorder.level_started(&"hardware_foundations", &"latch")
	check(nav.selected == "hardware_foundations/latch" and not nav.camera_saved,
		"A repeated last-visited task still repairs a different transient selection")
	nav.camera_saved = true
	nav.camera = Vector2(123, 456)
	recorder.level_started(&"hardware_foundations", &"latch")
	check(nav.camera_saved and nav.camera == Vector2(123, 456), "Repeated matching visits do not reset the camera")
	var navigation_file: String = FileAccess.get_file_as_string(nav.NAVIGATION_PATH)
	for rejected: String in ["hardware_foundations/full_adder", "hardware_foundations/missing", "chapter_4/mixed"]:
		recorder.level_started(StringName(rejected.get_slice("/", 0)), StringName(rejected.get_slice("/", 1)))
		check(nav.selected == "hardware_foundations/latch" and nav.camera_saved and nav.last_visited_task == "hardware_foundations/latch",
			"Locked or unknown visits preserve navigation: " + rejected)
	check(FileAccess.get_file_as_string(nav.NAVIGATION_PATH) == navigation_file, "Rejected visits do not rewrite Continue preferences")
	mode.set_mode(&"test")
	recorder.level_started(&"hardware_foundations", &"full_adder")
	check(nav.selected == "hardware_foundations/latch" and nav.camera_saved and nav.last_visited_task == "hardware_foundations/latch",
		"Test visits leave Game selection and Continue unchanged")
	mode.set_mode(&"game")
	check(progress() == before, "Repeated, rejected and Test visits leave all progression snapshots unchanged")
	# The same validated visit hook is used by direct task starts in every later chapter.
	root.get_node("SystemChapter").prologue_ready = true
	root.get_node("SystemChapter").game_completed[&"bottleneck"] = true
	root.get_node("LocalityChapter").game_completed[&"capstone"] = true
	var chapters_before: Dictionary = progress()
	for key: String in ["chapter_1/assembly", "chapter_2/distant_reads", "chapter_3/arrival", "chapter_4/fields"]:
		nav.camera_saved = true
		recorder.level_started(StringName(key.get_slice("/", 0)), StringName(key.get_slice("/", 1)))
		check(nav.selected == key and nav.last_visited_task == key and not nav.camera_saved,
			"The shared direct-visit path tracks the actual task: " + key)
	check(progress() == chapters_before, "Cross-chapter visit bookkeeping never grants progress")
	nav.last_visited_task = ""
	nav.selected = "hardware_foundations/tutorial"
	nav._ready()
	nav.prepare_continue()
	check(nav.selected == "chapter_4/fields", "Reloaded Continue still locates the persisted last visit")
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "direct task navigation (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)
