extends "res://tests/test_recovery_settings_language.gd"
## Exercise the real completion button and quit dispatch with isolated disk errors.
## Only the terminal SceneTree.quit call is instrumented. Every persistence and
## refusal branch comes verbatim from the current GlobalSave implementation.

const SystemCatalog = preload("res://src/system_lab/system_level_catalog.gd")
var quit_probe_script: GDScript


func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run recovery departure checks through scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	directory = "user://recovery-departures-" + Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(directory) == OK, "Create independent departure fixtures")
	if not install_quit_probe():
		quit(1)
		return
	await exercise_idle_quit()
	await exercise_busy_seal_quit()
	await exercise_completion_action()
	for route: String in ["direct", "settings", "window_close"]:
		await exercise_quit(route)
	await exercise_quit("sealed")
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "recovery departure paths %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func install_quit_probe() -> bool:
	# Native SceneTree.quit is not a virtual extension point. Derive only the
	# current request_quit method and replace its terminal side effect instead
	# of recreating (and potentially accidentally fixing) the guard under test.
	var source: String = FileAccess.get_file_as_string("res://src/save/global_save.gd")
	var start: int = source.find("\nfunc request_quit()")
	check(start >= 0, "Locate the real GlobalSave quit entry point")
	if start < 0: return false
	start += 1
	var end: int = source.find("\nfunc ", start + 1)
	var method: String = source.substr(start, end - start if end >= 0 else -1)
	check(method.count("get_tree().quit()") == 1, "Instrument exactly one terminal process exit, not a save or guard")
	if method.count("get_tree().quit()") != 1: return false
	quit_probe_script = GDScript.new()
	quit_probe_script.source_code = "extends \"res://src/save/global_save.gd\"\nvar departure_quit_requests: int = 0\n\n" \
		+ method.replace("get_tree().quit()", "departure_quit_requests += 1")
	var result: Error = quit_probe_script.reload()
	check(result == OK, "Compile the current quit path with only its terminal exit intercepted")
	if result != OK: return false
	var save: Node = root.get_node("GlobalSave")
	save.set_script(quit_probe_script)
	save._bind_persistent_sources()
	return true


func quit_requests() -> int:
	return int(root.get_node("GlobalSave").get("departure_quit_requests"))


func game_state() -> Dictionary:
	return root.get_node("GlobalSave")._save_snapshot().game.duplicate(true)


func normalized(snapshot: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(snapshot, "", true, true))


func configure_fixture(prefix: String) -> Node:
	check(root.get_node("GameMode").set_mode(&"game"), prefix + ": start without a live prior workbench")
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test(directory.path_join(prefix + "-save.json"), directory.path_join(prefix + "-boards.json"))
	save.workbench_write_error = ""
	check(save.save_game(true), prefix + ": the supported global save really writes")
	return save


func named_test_level(level: StringName, label: String) -> Control:
	if not await enter_test_from_empty_header(label): return null
	var scene: Control = await open_fixture_level(level, label)
	if scene == null: return null
	scene._show_new_workbench_dialog()
	check(scene.workbench_name_dialog.visible, label + ": actual named-plan dialog opens")
	scene.workbench_name_edit.text = "Departure draft"
	scene.workbench_name_edit.text_submitted.emit("Departure draft")
	await settle(14)
	check(scene.active_workbench_name == "Departure draft" and scene.active_workbench_namespace == &"test",
		label + ": the real dialog selects a persisted Test-only named plan")
	return scene


func move_part(scene: Control, part: StringName) -> void:
	check(not scene._editor_locked() and scene.component_nodes[part].draggable,
		"Fixture placement change uses an actually editable player node")
	scene._on_begin_node_move()
	scene.component_nodes[part].position_offset += Vector2(60, 40)
	scene._on_end_node_move()
	await settle()


func finish_official(scene: Control, label: String) -> bool:
	scene.official_button.pressed.emit()
	for frame: int in 256:
		if not scene.official_sequence_active: break
		if scene.playback_running: scene._finish_playback()
		await process_frame
	check(scene.official_passed and not scene.official_sequence_active,
		label + ": all actual official cases establish the verdict")
	await settle()
	return scene.official_passed and not scene.official_sequence_active


func exercise_idle_quit() -> void:
	var save: Node = configure_fixture("idle")
	root.get_node("TaskNavigation").pending = ""
	root.get_node("TaskNavigation").from_tree = false
	check(change_scene_to_file(HARDWARE_SCENE) == OK, "Idle quit opens the actual hardware campaign")
	await settle(14)
	check(current_scene != null and current_scene.current_phase == &"campaign"
		and current_scene.active_workbench_name.is_empty(), "Idle quit has no active source graph to save")
	var before: int = quit_requests()
	save.request_quit()
	check(quit_requests() == before + 1, "No active workbench does not spuriously prevent normal exit")
	await cleanup()


func exercise_busy_seal_quit() -> void:
	var label: String = "busy verified Test encapsulation"
	var save: Node = configure_fixture("busy-seal")
	var game_before: Dictionary = game_state()
	var scene: Control = await named_test_level(&"half_adder", label)
	if scene == null:
		await cleanup()
		return
	for wire: Dictionary in scene._half_adder_reference_wires():
		scene._on_connection_request(wire.from_node, int(wire.from_port), wire.to_node, int(wire.to_port))
	if not await finish_official(scene, label):
		await cleanup()
		return
	scene._dismiss_level_completion()
	var source: Dictionary = scene._capture_workbench_snapshot()
	check(scene._save_active_workbench() and scene.workbench_store.last_error.is_empty(),
		label + ": the source really saves before sealing, with no injected I/O failure")
	check(save.disk_write_allowed and save.workbench_write_error.is_empty() and save.save_game(true),
		label + ": normal GlobalSave also writes, so only the busy operation can reject exit")
	var instance: int = scene.get_instance_id()
	var graph_instance: int = scene.graph.get_instance_id()
	var content_before: String = scene.test_player_content.canonical_signature()
	scene.seal_button.pressed.emit()
	check(scene.sealing and scene.current_phase == &"half_adder",
		label + ": actual Seal starts the existing timed encapsulation")
	var frozen: Dictionary = scene.pending_visual_snapshot.duplicate(true)
	var before: int = quit_requests()
	# No await here: dispatch while the real animation is unambiguously busy.
	save.request_quit()
	check(quit_requests() == before,
		label + ": normal request_quit cannot exit during an in-flight encapsulation")
	check(current_scene != null and current_scene.get_instance_id() == instance and scene.sealing
		and scene.graph.get_instance_id() == graph_instance and scene._capture_workbench_snapshot() == source,
		label + ": rejected quit retains the active operation and original graph")
	check(scene.pending_visual_snapshot == frozen and scene.test_player_content.canonical_signature() == content_before,
		label + ": quit does not fabricate completion or discard the frozen pending source")
	check(scene.status_label.text == scene._t(&"hardware.status.sealing"),
		label + ": the existing busy-status message explains why departure is refused")
	var deadline: int = Time.get_ticks_msec() + 5000
	while scene.sealing and Time.get_ticks_msec() < deadline: await process_frame
	check(not scene.sealing and scene.current_phase == &"sealed"
		and scene.test_player_content.completed_levels.get(&"half_adder", false),
		label + ": the real timer finishes the verified Test result after refusal")
	if scene.sealing or scene.current_phase != &"sealed":
		await cleanup()
		return
	scene._dismiss_level_completion()
	before = quit_requests()
	save.request_quit()
	check(quit_requests() == before + 1,
		label + ": completed encapsulation does not leave a permanent quit lock")
	var restored = Store.new(save.workbench_storage_path)
	check(restored.active_name(&"test", &"half_adder") == "Departure draft"
		and restored.active_snapshot(&"test", &"half_adder") == normalized(source),
		label + ": allowed exit retains the named source, not the sealed display")
	check(game_state() == game_before, label + ": busy and finished Test exits never grant Game rewards")
	await cleanup()


func exercise_completion_action() -> void:
	var label: String = "load_store completion action"
	var save: Node = configure_fixture("completion")
	var game_before: Dictionary = game_state()
	var system_catalog = SystemCatalog.new()
	var first_system_level: StringName = system_catalog.level_ids()[0]
	var first_system_task: String = "chapter_1/" + String(first_system_level)
	var no_chapter_completions: Dictionary = {}
	check(not root.get_node("GameMode").is_test_mode()
		and root.get_node("SystemChapter").game_completed.is_empty(),
		label + ": entrance contract starts in ordinary Game with no Chapter 1 completions")
	# These are pure catalog inputs, not installed progression or proof of an
	# earned Game run. test_half_adder_reseal_progression earns the real prologue
	# and checks TaskNavigation's live gate without injecting rewards.
	check(not system_catalog.is_unlocked(first_system_level, no_chapter_completions, false, false),
		label + ": catalog first task still requires the ordinary Game prologue gate")
	check(system_catalog.is_unlocked(first_system_level, no_chapter_completions, true, false),
		label + ": catalog first task needs no Chapter 1 completions after the prologue, with Test bypass disabled")
	check(game_state() == game_before, label + ": catalog eligibility checks do not install any earned progress")
	var scene: Control = await named_test_level(&"load_store", label)
	if scene == null:
		await cleanup()
		return
	check(bool(scene.current_level_definition.get("locked_topology", false)),
		label + ": this real authored observation level does not require fabricated sealing rewards")
	check(scene._save_active_workbench(), label + ": named plan has a real saved baseline")
	var disk_before: String = FileAccess.get_file_as_string(save.workbench_storage_path)
	var obstruction: String = save.workbench_storage_path + Store.TEMP_SUFFIX
	check(DirAccess.make_dir_absolute(obstruction) == OK, label + ": inject a real temporary-file failure")
	await move_part(scene, &"COMPUTER")
	var edited: Dictionary = scene._capture_workbench_snapshot()
	check(not scene._save_active_workbench(), label + ": latest player layout is retained only in memory")
	if not await finish_official(scene, label):
		await cleanup()
		return
	check(scene.current_phase == &"prologue_complete" and scene.test_player_content.completed_levels.get(&"load_store", false),
		label + ": official verification reaches the real completed side panel")
	scene._dismiss_level_completion()
	var destination: String = scene.current_level_definition.get("completion_scene", "")
	check(destination == "res://src/system_lab/system_lab.tscn", label + ": use the authored next-chapter destination")
	var button: Button = null
	for child: Node in scene.task_box.get_children():
		if child is Button and child.text == scene._t(scene.current_level_definition.completion_action_key):
			button = child
	check(button != null and button.is_visible_in_tree(), label + ": actual next-chapter button is reachable")
	if button == null:
		await cleanup()
		return
	var instance: int = scene.get_instance_id()
	var previous_selection: String = root.get_node("TaskNavigation").selected
	button.pressed.emit()
	await settle(20)
	check(current_scene != null and current_scene.get_instance_id() == instance,
		label + ": a failed source save must prevent the completion button destroying its Store")
	check(FileAccess.get_file_as_string(save.workbench_storage_path) == disk_before,
		label + ": failed writes have not secretly persisted the latest layout")
	check(game_state() == game_before, label + ": Test completion never fabricates Game rewards or chapter gates")
	check(root.get_node("TaskNavigation").selected == previous_selection,
		label + ": rejected departure does not change the journey destination")
	if not is_instance_valid(scene) or current_scene != scene:
		await cleanup()
		return
	check(scene.workbench_store.active_snapshot(&"test", &"load_store") == edited,
		label + ": rejected departure retains the named source, not just the completed display")
	check(DirAccess.remove_absolute(obstruction) == OK, label + ": restore only this fixture's writable path")
	button.pressed.emit()
	await settle(20)
	var navigation: Node = root.get_node("TaskNavigation")
	var departure_diagnostic: Dictionary = {
		"current_name": String(current_scene.name) if current_scene != null else "<null>",
		"current_path": current_scene.scene_file_path if current_scene != null else "<null>",
		"current_id": current_scene.get_instance_id() if current_scene != null else 0,
		"original_id": instance,
		"original_valid": is_instance_valid(scene),
		"original_phase": String(scene.current_phase) if is_instance_valid(scene) else "<freed>",
		"original_save_pending": scene.workbench_save_pending if is_instance_valid(scene) else null,
		"navigation_pending": navigation.pending,
		"navigation_from_tree": navigation.from_tree,
		"navigation_selected": navigation.selected,
		"mode": String(root.get_node("GameMode").current_mode),
	}
	var shared_map: bool = current_scene != null and current_scene.scene_file_path == navigation.MAP_SCENE
	check(shared_map, label + ": recovered departure reaches the shared journey map; " + JSON.stringify(departure_diagnostic))
	check(navigation.selected == first_system_task
		and shared_map and current_scene.selected.get("key", "") == first_system_task,
		label + ": the enter-chapter-one action actually focuses its first task; " + JSON.stringify(departure_diagnostic))
	check(navigation.selected.get_slice("/", 0) == "chapter_1"
		and system_catalog.is_unlocked(StringName(navigation.selected.get_slice("/", 1)), no_chapter_completions, true, false),
		label + ": actual destination satisfies ordinary Game's post-prologue entry contract without Chapter 1 completions or Test bypass")
	var restored = Store.new(save.workbench_storage_path)
	check(restored.active_name(&"test", &"load_store") == "Departure draft"
		and restored.active_snapshot(&"test", &"load_store") == normalized(edited),
		label + ": successful departure first persists the exact named player source")
	check(game_state() == game_before, label + ": successful Test chapter transition still grants no Game rewards")
	await cleanup()


func exercise_quit(route: String) -> void:
	var label: String = "Test named draft quit / " + route
	var save: Node = configure_fixture("quit-" + route)
	var game_before: Dictionary = game_state()
	var level: StringName = &"half_adder" if route == "sealed" else &"tutorial"
	var scene: Control = await named_test_level(level, label)
	if scene == null:
		await cleanup()
		return
	if route == "sealed":
		for wire: Dictionary in scene._half_adder_reference_wires():
			scene._on_connection_request(wire.from_node, int(wire.from_port), wire.to_node, int(wire.to_port))
		if not await finish_official(scene, label):
			await cleanup()
			return
		scene._dismiss_level_completion()
	else:
		scene._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	await settle()
	check(scene._save_active_workbench(), label + ": the named source initially saves normally")
	var disk_before: String = FileAccess.get_file_as_string(save.workbench_storage_path)
	var obstruction: String = save.workbench_storage_path + Store.TEMP_SUFFIX
	check(DirAccess.make_dir_absolute(obstruction) == OK, label + ": inject real workbench-only write failure")
	await move_part(scene, &"AND_1" if route == "sealed" else &"NOT_1")
	var edited: Dictionary = scene._capture_workbench_snapshot()
	check(not scene._save_active_workbench(), label + ": the last named-plan edit cannot reach disk")
	if route == "sealed":
		scene.seal_button.pressed.emit()
		var deadline: int = Time.get_ticks_msec() + 5000
		while scene.sealing and Time.get_ticks_msec() < deadline: await process_frame
		check(scene.current_phase == &"sealed" and scene.test_player_content.completed_levels.get(&"half_adder", false),
			label + ": verified encapsulation reaches the real completed display")
		if scene.current_phase != &"sealed":
			await cleanup()
			return
		scene._dismiss_level_completion()
	check(save.disk_write_allowed and save.workbench_write_error.is_empty() and save.save_game(true),
		label + ": GlobalSave is genuinely writable and Test failure does not contaminate its Game error flag")
	var instance: int = scene.get_instance_id()
	var before: int = quit_requests()
	await trigger_quit(route)
	check(quit_requests() == before, label + ": the actual quit path refuses loss of an unsaved Test namespace")
	check(current_scene != null and current_scene.get_instance_id() == instance
		and scene.workbench_store.active_snapshot(&"test", level) == edited,
		label + ": rejecting process exit preserves the same named source in memory")
	check(FileAccess.get_file_as_string(save.workbench_storage_path) == disk_before,
		label + ": the obstruction still prevents the edited source reaching disk")
	check(game_state() == game_before, label + ": refusal does not invent Game completion, rewards, or gates")
	check(DirAccess.remove_absolute(obstruction) == OK, label + ": remove only the isolated obstruction")
	if is_instance_valid(save._failure_dialog): save._failure_dialog.hide()
	before = quit_requests()
	await trigger_quit(route)
	check(quit_requests() == before + 1, label + ": storage recovery permits the same normal quit request")
	var restored = Store.new(save.workbench_storage_path)
	check(restored.active_name(&"test", level) == "Departure draft"
		and restored.active_snapshot(&"test", level) == normalized(edited),
		label + ": allowed quit persists the latest source and name, never the sealed display")
	check(game_state() == game_before, label + ": recovered Test exit preserves all Game rewards")
	await cleanup()


func trigger_quit(route: String) -> void:
	var save: Node = root.get_node("GlobalSave")
	if route == "settings":
		var mode: Node = root.get_node("WindowMode")
		if not is_instance_valid(mode.settings_layer): await key(KEY_F10)
		check(is_instance_valid(mode.settings_layer), "Real Settings opens before its Quit button is pressed")
		if is_instance_valid(mode.settings_layer):
			var settings: Control = mode.settings_layer.get_child(0)
			settings.options_quit_button.pressed.emit()
	elif route == "window_close":
		var previous_auto_quit: bool = auto_accept_quit
		auto_accept_quit = false
		save.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		auto_accept_quit = previous_auto_quit
	else:
		save.request_quit()
	await settle()
