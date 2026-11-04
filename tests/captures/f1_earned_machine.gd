extends "res://tests/test_half_adder_reseal_progression.gd"
## Earn every source through official cases and real sealing before opening the film's return card.
func run() -> void:
	root.size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	ProjectSettings.set_setting("playtest/offline_tester", false)
	root.get_node("GameMode").set_mode(&"game")
	navigation = root.get_node("TaskNavigation")
	navigation.pending = ""
	navigation.from_tree = false
	save = root.get_node("GlobalSave")
	system = root.get_node("SystemChapter")
	save.configure_for_test("user://f1-earned.json", "user://f1-boards.json")
	save.load_game()
	await open_workbench()
	if not await earn_tutorial(): quit(1); return
	for pair: Array in [[&"half_adder",&"HalfAdder"],[&"full_adder",&"FullAdder"],[&"alu",&"ALU1"],[&"latch",&"SRLatch"],[&"register",&"Register1"],[&"ram",&"RAM2x4"],[&"cpu",&"TinyComputer"]]:
		if not await open_level(pair[0]): quit(1); return
		var wires: Array = main._half_adder_reference_wires() if pair[0] == &"half_adder" else main.current_level_definition.reference_wires
		if not connect_reference_wires(wires, String(pair[0])): quit(1); return
		if not await verify_and_seal(pair[0],pair[1]): quit(1); return
	if not await open_level(&"load_store") or not await run_official(&"load_store"): quit(1); return
	main.level_completion_overlay.dismiss()
	preload("res://src/lab/cinematic_artifact.gd").present_prologue.call_deferred(main,main.component_library)
	await settle(12)
	var card: Control = main.get_node_or_null("CinematicArtifact")
	if not check(card != null, "Real earned machine signatures are accepted by the post-film card"):
		quit(1); return
	await RenderingServer.frame_post_draw
	var destination: String = "res://docs/verification/20261104-f1-feel/earned-machine.png"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="): destination = arg.trim_prefix("--shot=")
	root.get_texture().get_image().save_png(destination)
	card.dismissed.emit()
	await settle()
	await close_workbench()
	print("PASS: real prologue flow and source-validated post-film machine card; %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func run_official(level_id: StringName) -> bool:
	var passed: bool = await super.run_official(level_id)
	if passed and level_id == &"half_adder":
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--ready-shot="):
				await settle(12)
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(argument.trim_prefix("--ready-shot="))
	return passed
