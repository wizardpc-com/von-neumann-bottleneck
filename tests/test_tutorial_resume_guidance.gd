extends SceneTree
## Persist an unfinished ordinary tutorial, then rebuild its scene. The guide
## must offer a possible next gesture, not ask to add a wire that already exists.
## Controller/layout regression only; this is not native-input or beginner QA.

const SCENE_PATH = "res://src/hardware_foundations/hardware_foundations.tscn"
const Store = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
const Demo = preload("res://src/hardware_foundations/operation_demonstration.gd")
const Coach = preload("res://src/hardware_foundations/tutorial_coach.gd")
var failures: Array[String] = []
var checks: int = 0
var fixture_prefix: String


func _init() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)


func settle(frames: int = 8) -> void:
	for frame: int in frames:
		await process_frame


func run() -> void:
	root.size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	root.get_node("GameMode").set_mode(&"game")
	root.get_node("TaskNavigation").pending = ""
	root.get_node("TaskNavigation").from_tree = false
	Coach.collapsed = false
	fixture_prefix = "user://tutorial-resume-guidance-%d" % Time.get_ticks_usec()
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		for shape: String in ["empty", "missing_input", "missing_lamp", "wired"]:
			await check_resume(locale, shape)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "tutorial resume guidance %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func open_tutorial() -> Control:
	var main: Control = load(SCENE_PATH).instantiate()
	root.add_child(main)
	await settle(4)
	main.workbench_store = Store.new(root.get_node("GlobalSave").workbench_storage_path)
	main._start_campaign_level(&"tutorial", false)
	await settle(14)
	return main


func check_resume(locale: String, shape: String) -> void:
	var context: String = locale + " " + shape
	var save: Node = root.get_node("GlobalSave")
	var prefix: String = fixture_prefix + "-" + locale + "-" + shape
	save.configure_for_test(prefix + "-save.json", prefix + "-boards.json")
	var main: Control = await open_tutorial()
	# All fixtures arise from actual editor controller operations, never a
	# completed-level flag or a reference solution granted as player progress.
	main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	if shape in ["empty", "missing_input"]:
		main._on_disconnection_request(&"A_IN", 0, &"NOT_1", 0)
	if shape in ["empty", "missing_lamp"]:
		main._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
	check(not main.completed_levels.get(&"tutorial", false), context + ": edited but unfinished tutorial is not completed")
	var signature: String = main._circuit_from_graph().canonical_signature()
	var saved_player_signature: String = save.game_player_content.canonical_signature()
	check(main._save_active_workbench(), context + ": unfinished board is persisted")
	# The storage contract is JSON: decoding converts integers to floats and
	# typed arrays/StringNames to JSON arrays/strings. Normalize only the expected
	# in-memory snapshot using the writer's full-precision encoding. This retains
	# every field and still compares against a separate reader of the real file.
	var saved_board: Dictionary = JSON.parse_string(JSON.stringify(
		main.workbench_store.active_snapshot(&"game", &"tutorial"), "", false, true))
	# Force only the empty ordinary Game envelope onto disk; no completion or
	# reward is fabricated. The separate workbench file owns the unfinished board.
	check(save.save_game(true), context + ": ordinary incomplete progression is persisted")
	main.queue_free()
	await settle(3)
	# load_game returns has_resume_progress (earned completions), not I/O success.
	# A valid first-lesson save therefore returns false. Require successful actual
	# loading independently, so a missing/corrupt save cannot pass this fixture.
	var has_earned_progress: bool = save.load_game()
	check(save.loaded_save and save.disk_write_allowed and save.last_error.is_empty()
		and save.last_warning.is_empty(), context + ": saved ordinary profile reloads without recovery errors: " + save.last_error)
	check(not has_earned_progress and not save.has_resume_progress()
		and save.game_player_content.completed_levels.is_empty()
		and save.game_player_content.canonical_signature() == saved_player_signature,
		context + ": reload restores the exact unearned player state, not fabricated resume progress")
	var restored_store = Store.new(save.workbench_storage_path)
	check(restored_store.disk_write_allowed and restored_store.last_error.is_empty()
		and not saved_board.is_empty()
		and restored_store.active_snapshot(&"game", &"tutorial") == saved_board,
		context + ": a fresh disk reader restores the full ordinary tutorial workbench")
	main = await open_tutorial()
	check(main._circuit_from_graph().canonical_signature() == signature, context + ": resumed topology is preserved exactly")
	check(not main.completed_levels.get(&"tutorial", false) and main.tutorial_next_button.disabled,
		context + ": loading an unfinished board does not award the tutorial")
	check(no_session_actions(main), context + ": recovery does not invent current-session actions or a run")
	check(main.tutorial_coach.is_visible_in_tree() and not main.mission_briefing_active,
		context + ": unfinished lesson resumes with its actionable guide")
	var player_signature: String = save.game_player_content.canonical_signature()
	main._show_operation_demonstration()
	# Let the normal process update run too: a correct initial cutting path
	# must not be overwritten on the next frame by the default wiring path.
	await settle(3)
	check(main.operation_demo.running, context + ": the offered gesture can be demonstrated")
	if shape == "wired":
		var guidance: String = main.tutorial_coach.instruction.text.to_lower()
		var describes_removal: bool = ("拆" in guidance) if locale == "zh_CN" else ("remove" in guidance or "disconnect" in guidance)
		check(describes_removal, context + ": two restored wires require an explicit removal/reconnection instruction, not duplicate wiring: " + guidance)
		check(demonstrates_existing_wire_cut(main), context + ": resumed complete wiring demonstrates a real wire cut, including subsequent process frames")
	else:
		var from_id: StringName = &"NOT_1" if shape == "missing_lamp" else &"A_IN"
		var to_id: StringName = &"LAMP" if shape == "missing_lamp" else &"NOT_1"
		check(not main.graph.is_node_connected(from_id, 0, to_id, 0), context + ": the suggested connection is genuinely missing")
		check(demonstrates_connection(main, from_id, to_id), context + ": resumed incomplete wiring points at the actual missing ports")
	check(main._circuit_from_graph().canonical_signature() == signature and no_session_actions(main),
		context + ": demonstration leaves the board and action requirements unchanged")
	check(save.game_player_content.canonical_signature() == player_signature,
		context + ": guidance does not grant progression or reusable rewards")
	main.operation_demo.stop()
	if shape == "wired":
		# The offered recovery is ordinary practice, not an alternate award path.
		main._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
		check(not main.completed_levels.get(&"tutorial", false), context + ": removal alone cannot complete the lesson")
		main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
		check(not main.completed_levels.get(&"tutorial", false), context + ": reconnection still requires input and a valid run")
		main.input_a_button.button_pressed = not main.input_a_button.button_pressed
		main._run_debug()
		await settle(3)
		check(main.tutorial_created_wire and main.tutorial_changed_input and main.tutorial_valid_run
			and main.tutorial_removed_wire and main.tutorial_reconnected_wire,
			context + ": actual recovery actions satisfy all five existing requirements")
		check(main.completed_levels.get(&"tutorial", false) and main.level_completion_overlay.visible,
			context + ": real five-action completion still opens the earned result")
	main.queue_free()
	await settle(4)


func no_session_actions(main: Control) -> bool:
	return not main.tutorial_created_wire and not main.tutorial_changed_input and not main.tutorial_valid_run \
		and not main.tutorial_removed_wire and not main.tutorial_reconnected_wire


func demonstrates_connection(main: Control, from_id: StringName, to_id: StringName) -> bool:
	var points: PackedVector2Array = main.operation_demo.path
	if points.size() != 2:
		return false
	var source: GraphNode = main.component_nodes[from_id]
	var target: GraphNode = main.component_nodes[to_id]
	var transform: Transform2D = main.operation_demo.get_global_transform_with_canvas().affine_inverse() * main.graph.get_global_transform_with_canvas()
	var start: Vector2 = transform * main.graph.displayed_port_position(source, 0, true)
	var end: Vector2 = transform * main.graph.displayed_port_position(target, 0, false)
	return points[0].is_equal_approx(start) and points[1].is_equal_approx(end)


func demonstrates_existing_wire_cut(main: Control) -> bool:
	var points: PackedVector2Array = main.operation_demo.path
	if points.size() != 2:
		return false
	var transform: Transform2D = main.operation_demo.get_global_transform_with_canvas().affine_inverse() * main.graph.get_global_transform_with_canvas()
	for connection: Dictionary in main.graph.get_connection_list():
		var curve: PackedVector2Array = main.graph.connection_curve(connection)
		var cut: PackedVector2Array = Demo.wire_cut_path(curve)
		if cut.size() != 2:
			continue
		var start: Vector2 = transform * cut[0]
		var end: Vector2 = transform * cut[1]
		if (points[0].is_equal_approx(start) and points[1].is_equal_approx(end)) \
			or (points[0].is_equal_approx(end) and points[1].is_equal_approx(start)):
			return true
	return false
