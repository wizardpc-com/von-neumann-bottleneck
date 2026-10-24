extends SceneTree
## Real protected-save loaders, editor operations, Settings callbacks and rescue export.
## --script workbenches are memory-only; opt only this Store into isolated fixture
## files. Controller/viewport regression, not native-input or package acceptance.

const Store = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
const HARDWARE_SCENE: String = "res://src/hardware_foundations/hardware_foundations.tscn"
var checks: int = 0
var failures: Array[String] = []
var directory: String


func _init() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)


func settle(frames: int = 10) -> void:
	for frame: int in frames:
		await process_frame


func write_fixture(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "Open isolated protected-save fixture")
	if file == null:
		return false
	file.store_string(contents)
	file.close()
	return true


func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()


func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run recovery Settings checks through scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	root.get_node("GameMode").set_mode(&"game")
	directory = "user://recovery-settings-" + Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(directory) == OK, "Create independent recovery fixtures")
	for scenario: String in ["future_workbench", "future_global", "unsupported_transaction"]:
		for action: String in ["language", "defaults", "home", "map", "escape", "mode"]:
			await exercise(scenario, action)
	# Test workbench failures do not populate GlobalSave.workbench_write_error.
	# Exercise this reachable state separately, including the return to Game.
	for action: String in ["language", "defaults", "home", "map", "escape", "mode"]:
		await exercise("future_workbench", action, &"test")
	await exercise_hint_recovery()
	await exercise_sealed_recovery()
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "recovery Settings language %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func exercise(scenario: String, action: String, initial_mode: StringName = &"game") -> void:
	var label: String = String(initial_mode) + " / " + scenario + " / " + action
	var prefix: String = directory.path_join(String(initial_mode) + "-" + scenario + "-" + action)
	var game_mode: Node = root.get_node("GameMode")
	# The previous scene has been freed before this fixture reset.
	check(game_mode.set_mode(&"game"), label + ": empty fixture starts in Game")
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test(prefix + "-save.json", prefix + "-boards.json")
	save.workbench_write_error = ""
	check(save.save_game(true), label + ": create a supported baseline global save")
	var board_file: String = save.workbench_storage_path
	if scenario == "unsupported_transaction":
		board_file += Store.TEMP_SUFFIX
	var protected_board: String = JSON.stringify({"schema_version": 99, "signature_version": 2, "namespaces": {}})
	if not write_fixture(board_file, protected_board):
		return
	if scenario == "future_global":
		if not write_fixture(save.storage_path, JSON.stringify({"schema_version": 99, "game": {}})):
			return
	var protected_save: String = FileAccess.get_file_as_string(save.storage_path)
	check(not save.load_game() and not save.disk_write_allowed,
		label + ": real loading enters protected recovery without rewriting the source")
	check(save.recovery_notice == (&"save.recovery.newer" if scenario == "future_global" else &"save.recovery.failed"),
		label + ": protection comes from the expected unsupported file")
	var initial_locale: String = "en" if action == "defaults" else "zh_CN"
	var localization: Node = root.get_node("Localization")
	if action in ["language", "defaults"]:
		check(localization.set_preferred_locale(initial_locale), label + ": prepare a persisted source language")
		root.get_node("WindowMode").set_sound(false, 0.23)
		root.get_node("WindowMode").set_frame_limit(120)
		root.get_node("WindowMode").set_yi_text_speed("fast")
	else:
		localization.set_locale(initial_locale)
	var navigation: Node = root.get_node("TaskNavigation")
	navigation.pending = ""
	if initial_mode == &"test":
		if not await enter_test_from_empty_header(label):
			await cleanup()
			return
	check(navigation.enter("hardware_foundations/tutorial"), label + ": normal task route still permits the unlocked tutorial")
	await settle(14)
	var scene: Control = current_scene
	check(scene != null and scene.name == "HardwareFoundations", label + ": task route opens the real hardware workbench")
	if scene == null or scene.name != "HardwareFoundations":
		return
	# Production constructs this same Store at the ordinary workbench path.
	scene.workbench_store = Store.new(save.workbench_storage_path)
	scene._start_campaign_level(&"tutorial", false)
	await settle(14)
	check(not scene.workbench_store.disk_write_allowed and not scene._editor_locked(),
		label + ": protected Store still allows live rescue editing")
	scene._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	scene._on_begin_node_move()
	var component: GraphNode = scene.component_nodes[&"NOT_1"]
	component.position_offset += Vector2(60, 40)
	scene._on_end_node_move()
	await settle()
	check(scene.graph.is_node_connected(&"A_IN", 0, &"NOT_1", 0), label + ": actual editor callback creates an unfinished connection")
	check(not scene._save_active_workbench() and not scene.workbench_store.last_error.is_empty(),
		label + ": real write refusal retains an actionable workbench error")
	check(save.workbench_write_error.is_empty() == (initial_mode == &"test"),
		label + ": fixture distinguishes Test write refusal from the Game global error")
	var before: Dictionary = scene._capture_workbench_snapshot()
	var recovery_before: Dictionary = scene.workbench_recovery_data()
	var history_count: int = scene.wire_history.size()
	var instance: int = scene.get_instance_id()
	var graph_instance: int = scene.graph.get_instance_id()
	var content_instance: int = scene.player_content.get_instance_id()
	var content_signature: String = scene.player_content.canonical_signature()
	var library_before: Dictionary = scene.component_library.duplicate()
	var game_signature: String = save.game_player_content.canonical_signature()
	var preferences_before: Dictionary = presentation_state()
	check(scene.active_workbench_namespace == initial_mode, label + ": edit namespace matches the active mode")
	check(scene.workbench_store.active_snapshot(initial_mode, &"tutorial") == before,
		label + ": the failed write keeps the edited board in rescue memory")
	check(not save.game_player_content.completed_levels.has(&"tutorial"), label + ": fixture awards no completion")
	if action == "home":
		(scene.find_child("ChapterSelectButton", true, false) as Button).pressed.emit()
	elif action == "map":
		var map_button: Button
		for candidate: Node in scene.editor_toolbar.find_children("*", "Button", true, false):
			if candidate is Button and candidate.text == scene._t(&"hardware.toolbar.level_map"):
				map_button = candidate
				break
		check(map_button != null, label + ": real toolbar exposes the map action")
		if map_button != null:
			map_button.pressed.emit()
	elif action == "escape":
		scene.graph.grab_focus()
		check(not scene._has_active_graph_gesture(), label + ": Escape has no draft gesture to cancel")
		await key(KEY_ESCAPE)
	elif action == "mode":
		var choice: OptionButton = scene.mode_selector.option_button
		check(choice.name == "ModeOption" and choice.is_visible_in_tree(),
			label + ": exercise the real visible header mode selector")
		var requested: int = 1 if initial_mode == &"game" else 0
		choice.select(requested)
		choice.item_selected.emit(requested)
	else:
		await settings_action(action, label)
	await settle(20)
	var after: Node = current_scene
	check(after != null and after.get_instance_id() == instance,
		label + ": failed persistence must not replace the only live workbench")
	check(game_mode.current_mode == initial_mode,
		label + ": failed departure must not commit a different global mode")
	check(save.game_player_content.canonical_signature() == game_signature,
		label + ": protected editing and refused departure do not alter Game rewards")
	if action in ["language", "defaults"]:
		check(localization.current_locale() == initial_locale and presentation_state() == preferences_before,
			label + ": refused presentation change preserves live settings and exact preference bytes")
		var layer: CanvasLayer = root.get_node("WindowMode").settings_layer
		check(is_instance_valid(layer), label + ": refused presentation change leaves Settings open")
		if is_instance_valid(layer):
			var choice: OptionButton = layer.find_child("LanguageChoice", true, false)
			check(choice != null and choice.selected == (1 if initial_locale == "en" else 0),
				label + ": language selector returns to the actual unchanged locale")
	if after != null and after.has_method("_capture_workbench_snapshot"):
		check(after.graph.get_instance_id() == graph_instance,
			label + ": refusal keeps the same graph rather than rebuilding a partial domain")
		check(after.player_content.get_instance_id() == content_instance
			and after.player_content.canonical_signature() == content_signature
			and after.component_library == library_before,
			label + ": refusal keeps the original content and library, not a mixed Game/Test scene")
		check(after.active_workbench_namespace == initial_mode
			and after.mode_selector.option_button.selected == (1 if initial_mode == &"test" else 0),
			label + ": selector, active namespace and content remain in the same mode")
		check(after._capture_workbench_snapshot() == before, label + ": navigation preserves edited topology and placement")
		check(after.wire_history.size() == history_count, label + ": navigation preserves undoable live work")
		check(after.workbench_recovery_data() == recovery_before, label + ": rescue memory is not replaced by a fresh Store")
	var rescue_path: String = prefix + "-rescue.json"
	check(save.export_rescue(rescue_path), label + ": separate rescue export remains available")
	var rescue: Variant = JSON.parse_string(FileAccess.get_file_as_string(rescue_path))
	var expected: Dictionary = JSON.parse_string(JSON.stringify(recovery_before, "", true, true))
	check(rescue is Dictionary and rescue.get("current_workbenches", []).has(expected),
		label + ": exported rescue still contains the original edited board")
	check(FileAccess.get_file_as_string(save.storage_path) == protected_save
		and FileAccess.get_file_as_string(board_file) == protected_board,
		label + ": original protected global and workbench bytes remain untouched")
	if scenario == "unsupported_transaction":
		check(not FileAccess.file_exists(save.workbench_storage_path), label + ": no fresh main overwrites the protected transaction")
	await cleanup()


func presentation_state() -> Dictionary:
	var mode: Node = root.get_node("WindowMode")
	return {
		"locale": root.get_node("Localization").current_locale(),
		"frame_limit": mode.frame_limit,
		"sound": [mode.sound_enabled, mode.sound_volume],
		"ambience": [mode.ambience_enabled, mode.ambience_volume, mode.ambience_reduced_dynamics],
		"reduced_motion": ProjectSettings.get_setting("game/reduced_motion", false),
		"text_speed": ProjectSettings.get_setting("game/yi_text_speed", "standard"),
		"preferences_exist": FileAccess.file_exists("user://presentation.cfg"),
		"preferences": FileAccess.get_file_as_string("user://presentation.cfg"),
	}


func open_fixture_level(level: StringName, label: String) -> Control:
	var navigation: Node = root.get_node("TaskNavigation")
	navigation.pending = ""
	check(navigation.enter("hardware_foundations/" + String(level)), label + ": enter the normal task route")
	await settle(14)
	var scene: Control = current_scene
	check(scene != null and scene.name == "HardwareFoundations", label + ": actual workbench is open")
	if scene == null or scene.name != "HardwareFoundations":
		return null
	scene.workbench_store = Store.new(root.get_node("GlobalSave").workbench_storage_path)
	scene._start_campaign_level(level, false)
	await settle(14)
	return scene


func exercise_hint_recovery() -> void:
	var label: String = "writable Hint recovery"
	var save: Node = root.get_node("GlobalSave")
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test(directory.path_join("hint-save.json"), directory.path_join("hint-boards.json"))
	save.workbench_write_error = ""
	check(save.save_game(true), label + ": create a supported isolated profile")
	var game_signature: String = save.game_player_content.canonical_signature()
	var scene: Control = await open_fixture_level(&"tutorial", label)
	if scene == null:
		await cleanup()
		return
	scene._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	await settle()
	check(scene._save_active_workbench(), label + ": initial player board persists normally")
	var initial: Dictionary = scene._capture_workbench_snapshot()
	scene._enter_hint_workbench()
	await settle()
	check(scene.hint_mode and scene.workbench_store.active_snapshot(&"game", &"tutorial") == initial,
		label + ": normal Hint leaves the saved player board intact")
	scene.hint_exit_button.pressed.emit()
	await settle()
	check(not scene.hint_mode and scene._capture_workbench_snapshot() == initial,
		label + ": normal Hint return is not blocked")
	var obstruction: String = save.workbench_storage_path + Store.TEMP_SUFFIX
	check(DirAccess.make_dir_absolute(obstruction) == OK, label + ": inject a real temporary-file I/O failure")
	scene._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await settle()
	check(not scene._save_active_workbench(), label + ": newer player edits cannot reach disk")
	var edited: Dictionary = scene._capture_workbench_snapshot()
	scene._enter_hint_workbench()
	await settle()
	check(scene.hint_mode and scene._capture_workbench_snapshot() != edited,
		label + ": the visible Hint graph is demonstrably not the edited player board")
	var instance: int = scene.get_instance_id()
	scene.hub_button.pressed.emit()
	await settle()
	check(current_scene != null and current_scene.get_instance_id() == instance,
		label + ": failed cached-board save blocks destructive departure from Hint")
	if not is_instance_valid(scene) or current_scene != scene:
		await cleanup()
		return
	check(scene.hint_mode and scene.workbench_store.active_snapshot(&"game", &"tutorial") == edited,
		label + ": refusing departure cannot save the reference graph over the player board")
	scene.hint_exit_button.pressed.emit()
	await settle()
	check(not scene.hint_mode and scene._capture_workbench_snapshot() == edited,
		label + ": even while storage fails, Hint can return to the intact player board")
	scene._enter_hint_workbench()
	await settle()
	check(DirAccess.remove_absolute(obstruction) == OK, label + ": remove only this fixture's I/O obstruction")
	scene.hub_button.pressed.emit()
	await settle(20)
	check(current_scene != null and current_scene.name == "PrototypeHub",
		label + ": recovery permits the same Hint departure without a permanent lock")
	var restored = Store.new(save.workbench_storage_path)
	check(restored.active_snapshot(&"game", &"tutorial") == JSON.parse_string(JSON.stringify(edited, "", true, true)),
		label + ": recovered disk contains the edited player board, never the Hint graph")
	check(save.game_player_content.canonical_signature() == game_signature,
		label + ": complete wiring and Hint never fabricate Game completion or rewards")
	await cleanup()


func exercise_sealed_recovery() -> void:
	var label: String = "verified Test sealing recovery"
	var save: Node = root.get_node("GlobalSave")
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test(directory.path_join("sealed-save.json"), directory.path_join("sealed-boards.json"))
	save.workbench_write_error = ""
	check(save.save_game(true), label + ": create a supported isolated profile")
	var game_signature: String = save.game_player_content.canonical_signature()
	if not await enter_test_from_empty_header(label):
		await cleanup()
		return
	var scene: Control = await open_fixture_level(&"half_adder", label)
	if scene == null:
		await cleanup()
		return
	# Build through the editor and execute all official cases. Test availability
	# avoids fabricated Game prerequisites, and the verdict is not injected.
	for wire: Dictionary in scene._half_adder_reference_wires():
		scene._on_connection_request(wire.from_node, int(wire.from_port), wire.to_node, int(wire.to_port))
	await settle()
	check(scene._save_active_workbench(), label + ": built Test circuit has a saved baseline")
	scene._run_official()
	for frame: int in 128:
		if not scene.official_sequence_active:
			break
		if scene.playback_running:
			scene._finish_playback()
		await process_frame
	check(scene.official_passed and not scene.official_sequence_active,
		label + ": real official HalfAdder cases establish the sealing verdict")
	if not scene.official_passed or scene.official_sequence_active:
		await cleanup()
		return
	scene._dismiss_level_completion()
	var obstruction: String = save.workbench_storage_path + Store.TEMP_SUFFIX
	check(DirAccess.make_dir_absolute(obstruction) == OK, label + ": inject failure before saving the final placement")
	scene._on_begin_node_move()
	scene.component_nodes[&"AND_1"].position_offset += Vector2(60, 40)
	scene._on_end_node_move()
	await settle()
	var player_board: Dictionary = scene._capture_workbench_snapshot()
	check(not scene._save_active_workbench(), label + ": the final placement is retained only in memory")
	scene.seal_button.pressed.emit()
	check(scene.sealing, label + ": real Seal begins after the verified verdict")
	var deadline: int = Time.get_ticks_msec() + 5000
	while scene.sealing and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not scene.sealing and scene.current_phase == &"sealed",
		label + ": actual encapsulation reaches its completed display")
	if scene.sealing or scene.current_phase != &"sealed":
		await cleanup()
		return
	check(scene.test_player_content.completed_levels.get(&"half_adder", false),
		label + ": only the verified Test result is completed")
	check(scene._capture_workbench_snapshot() != player_board,
		label + ": completed display differs from the retained source circuit")
	var instance: int = scene.get_instance_id()
	scene.hub_button.pressed.emit()
	await settle()
	check(current_scene != null and current_scene.get_instance_id() == instance,
		label + ": failed cached-source save blocks destructive departure after sealing")
	if not is_instance_valid(scene) or current_scene != scene:
		await cleanup()
		return
	check(scene.workbench_store.active_snapshot(&"test", &"half_adder") == player_board,
		label + ": the failed guard does not persist the sealed presentation as source")
	check(DirAccess.remove_absolute(obstruction) == OK, label + ": restore this fixture's writable storage")
	scene.hub_button.pressed.emit()
	await settle(20)
	check(current_scene != null and current_scene.name == "PrototypeHub",
		label + ": recovered sealed work can leave normally")
	var restored = Store.new(save.workbench_storage_path)
	check(restored.active_snapshot(&"test", &"half_adder") == JSON.parse_string(JSON.stringify(player_board, "", true, true)),
		label + ": recovery persists the complete original source and final placement")
	check(save.game_player_content.canonical_signature() == game_signature,
		label + ": verified Test sealing does not create Game rewards")
	await cleanup()


func enter_test_from_empty_header(label: String) -> bool:
	var navigation: Node = root.get_node("TaskNavigation")
	navigation.pending = ""
	navigation.from_tree = false
	# An empty hardware campaign has no active board to lose. This real header
	# transition must remain legal; an unconditional save-false guard is wrong.
	if change_scene_to_file(HARDWARE_SCENE) != OK:
		check(false, label + ": open the idle hardware header")
		return false
	await settle(14)
	var idle: Node = current_scene
	check(idle != null and idle.name == "HardwareFoundations" and idle.current_phase == &"campaign",
		label + ": Test setup begins without an active workbench")
	if idle == null or idle.name != "HardwareFoundations":
		return false
	var choice: OptionButton = idle.mode_selector.option_button
	check(choice.name == "ModeOption" and choice.is_visible_in_tree(),
		label + ": empty campaign exposes the actual header selector")
	choice.select(1)
	choice.item_selected.emit(1)
	await settle()
	var switched: bool = root.get_node("GameMode").is_test_mode() and choice.selected == 1
	check(switched and idle.player_content == idle.test_player_content,
		label + ": the empty header may legitimately enter isolated Test mode")
	check(idle.component_library.has(&"TinyComputer") and idle.completed_levels.is_empty(),
		label + ": Test support is available without fabricated completion")
	await cleanup()
	return switched


func settings_action(action: String, label: String) -> void:
	await key(KEY_F10)
	var mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(mode.settings_layer), label + ": F10 opens real Settings while recovery work is pending")
	if not is_instance_valid(mode.settings_layer):
		return
	var settings: Control = mode.settings_layer.get_child(0)
	if action == "defaults":
		(settings.find_child("ResetPresentation", true, false) as Button).pressed.emit()
		await settle()
		var dialog: ConfirmationDialog = settings.find_child("ResetPresentationConfirm", true, false)
		check(dialog.visible, label + ": resetting presentation retains its confirmation")
		dialog.hide()
		dialog.confirmed.emit()
	else:
		var choice: OptionButton = settings.find_child("LanguageChoice", true, false)
		choice.select(1)
		choice.item_selected.emit(1)


func cleanup() -> void:
	var mode: Node = root.get_node("WindowMode")
	if is_instance_valid(mode.settings_layer):
		mode.settings_layer.queue_free()
		mode.settings_layer = null
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	root.get_node("TaskNavigation").pending = ""
	await settle()
