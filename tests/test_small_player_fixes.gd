extends SceneTree

var checks: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame: int in 12: await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/small-fix-previews")
	root.get_texture().get_image().save_png("res://.godot/small-fix-previews/" + name + ".png")

func run() -> void:
	ProjectSettings.set_setting("game/reduced_motion", true)
	var mode: Node = root.get_node("GameMode")
	var save: Node = root.get_node("GlobalSave")
	var nav: Node = root.get_node("TaskNavigation")
	var signature: String = save.game_player_content.canonical_signature()
	ProjectSettings.set_setting("playtest/offline_tester", false)
	var game_service: Control = load("res://experiments/service_plan/lab.tscn").instantiate()
	root.add_child(game_service); await settle()
	check(game_service.task_buttons[1].disabled and game_service.task_buttons[2].disabled, "Game keeps the existing Service prerequisites")
	game_service.queue_free(); await settle()
	mode.set_mode(&"test")
	var entered: bool = nav.enter("service/prompt_response")
	check(entered, "The normal Test route accepts Service 6-2 without offline-tester flags")
	await settle()
	var service: Control = current_scene
	if not entered:
		nav.pending = "service/prompt_response"
		service = load("res://experiments/service_plan/lab.tscn").instantiate()
		root.add_child(service); await settle()
	check(service.task == 1, "Service opens the requested second task")
	check(not service.task_buttons[1].disabled and not service.task_buttons[2].disabled, "Both later Service task buttons work in Test")
	service.task_buttons[2].pressed.emit(); await settle()
	check(service.task == 2 and service.unlocked == 0 and service.support_plans.is_empty(), "Test enters 6-3 without fabricating qualifying plans")
	check(not service.persistent_session, "Service Test exploration cannot write the Game candidate profile")
	await capture("service-test-third-task")
	service.queue_free(); current_scene = null; await settle()
	mode.set_mode(&"game")
	check(save.game_player_content.canonical_signature() == signature, "Test navigation leaves real player progress unchanged")
	nav.from_tree = false; nav.pending = ""; nav.selected = "hardware_foundations/tutorial"
	nav.last_visited_task = "hardware_foundations/tutorial"

	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); await settle()
	var lab: Control = hub.laboratory
	var globe: MeshInstance3D = lab.room.model.find_child("Status globe | opal sphere",true,false)
	var material: BaseMaterial3D = globe.get_active_material(0)
	check(not material.emission_enabled, "An unearned globe has no first-light emission")
	await capture("globe-before-first-completion")
	hub.queue_free(); await settle()
	save.game_player_content.completed_levels[&"tutorial"] = true
	hub = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); await settle()
	lab = hub.laboratory
	globe = lab.room.model.find_child("Status globe | opal sphere",true,false)
	material = globe.get_active_material(0)
	check(material.emission_enabled and material.emission_energy_multiplier > 0.0, "The actual globe responds to earned first-lesson progress")
	check(lab.room.display_state.get("first_light", false), "The globe's recorded presentation follows the first completion")
	check(lab.fragments_open == 1 and lab.fragments_unread == 1, "The first completion unlocks exactly one unread archive")
	check(lab.terminal.archive_button.text.contains("新"), "Composing the terminal preserves the new-archive indicator")
	check(not lab.room_focus, "First-light arrival keeps the actual globe in the room view")
	await capture("globe-after-first-completion")
	hub.queue_free(); await settle()
	save.game_player_content.completed_levels.erase(&"tutorial")

	ProjectSettings.set_setting("game/reduced_motion", false)
	var bench: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench); await settle()
	bench._show_tutorial(false); await settle()
	var completed_steps: Array[bool] = [true,true,true,true,true]
	bench.tutorial_coach.update_states(completed_steps)
	var circuit: String = bench._circuit_from_graph().canonical_signature()
	check(not bench.tutorial_coach.demonstration_button.disabled, "The completed guide still offers explicit replay")
	bench.operation_demo.elapsed = 1.0
	bench.tutorial_coach.demonstration_button.pressed.emit()
	check(bench.operation_demo.running and not bench.operation_demo.path.is_empty(), "Replay starts the existing gesture animation even after all steps")
	check(bench.operation_demo.elapsed == 0.0, "Explicit replay rewinds the original animation")
	check(bench._circuit_from_graph().canonical_signature() == circuit, "Replaying the guide does not modify the player's circuit")
	await capture("replayed-operation-guide")
	bench.operation_demo.stop()
	mode.set_mode(&"test")
	bench._show_level_completion(&"tutorial")
	check(not bench.level_completion_overlay.return_button.text.contains("发光") and not bench.level_completion_overlay.return_button.text.contains("glowing"), "Test completion never promises an unearned glowing globe")
	bench._dismiss_level_completion()
	mode.set_mode(&"game")
	bench._show_level_completion(&"tutorial")
	check(bench.level_completion_overlay.return_button.text.contains("地球仪") or bench.level_completion_overlay.return_button.text.contains("globe"), "Game completion keeps the earned globe destination")
	bench._dismiss_level_completion()
	bench.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "small player fixes %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
