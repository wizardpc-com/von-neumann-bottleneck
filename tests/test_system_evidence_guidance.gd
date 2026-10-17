extends SceneTree
## Real controller runs and catalog evidence; no saved-game completion fixtures.
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame

func capture(main: Control, locale: String) -> void:
	if not "--system-guidance-capture" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	main._open_instrument(&"mission")
	await settle(); RenderingServer.force_draw(false); await process_frame
	DirAccess.make_dir_recursive_absolute("res://.godot/system-guidance-captures")
	check(root.get_texture().get_image().save_png("res://.godot/system-guidance-captures/"+locale+".png") == OK,"Real missing-evidence frame saved")

func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var chapter: Node = root.get_node("SystemChapter")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		chapter.reset_test_progress()
		var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
		root.add_child(main); await settle()
		for pair: Array in [[&"cpu_speed", &"cpu"], [&"ram_wait", &"ram"], [&"bus_width", &"bus"]]:
			var level: StringName = pair[0]
			var kind: StringName = pair[1]
			main._start_level(level); await settle()
			check(main.mission_next_action_label.text == main._t(&"system.mission.next.baseline", [main._part_kind_name(kind)]), "No evidence asks for a real baseline in " + locale)
			main.prediction_selector.select(1); main._lock_prediction()
			main._run_official(); main._finish_playback(); await settle()
			var receipts: Array = chapter.receipts_for(level)
			check(receipts.size() == 1 and receipts[0].all_passed and not chapter.completed_levels().get(level, false), "First correct observation stays incomplete: " + str(level))
			var signature: String = receipts[0].canonical_signature()
			var guidance: String = main.mission_next_action_label.text
			check(guidance == main._t(&"system.mission.next.comparison", [main._part_kind_name(kind)]), "First observation explains the controlled variable: " + str(level))
			if level == &"cpu_speed": await capture(main,locale)
			if level == &"cpu_speed":
				# Boundary fixture exposes another modeled fixed part, not a new public option.
				var ram_selector: OptionButton = main.part_selectors[&"ram"]
				ram_selector.add_item("Alternate fixed-part test")
				ram_selector.set_item_metadata(1, &"ram_balanced")
				ram_selector.select(1); main._on_part_selected(1, &"ram")
				check(not main._has_current_baseline_receipt() and main.mission_next_action_label.text == main._t(&"system.mission.next.baseline", [main._part_kind_name(kind)]), "Changed fixed RAM requests a matching baseline instead of relabeling the old CPU observation")
				check(chapter.receipts_for(level).size() == 1 and receipts[0].canonical_signature() == signature, "Fixed-part changes retain the original receipt")
				ram_selector.select(0); main._on_part_selected(0, &"ram")
				ram_selector.remove_item(1)
				check(main._has_current_baseline_receipt() and main.mission_next_action_label.text == guidance, "Returning to the recorded fixed parts restores valid comparison guidance")
				main.editor.text = main.applied_program_source + "\nvalue = 0"
				main._apply_program()
				check(main.mission_next_action_label.text == main._t(&"system.mission.next.baseline", [main._part_kind_name(kind)]), "Applying a different program invalidates current baseline guidance")
				main.editor.text = str(main.current_level_definition.program_source)
				main._apply_program()
				main.prediction_selector.select(1); main._lock_prediction()
				check(main.mission_next_action_label.text == guidance, "Reapplying the original program restores its unchanged evidence context")
			main.part_selectors[kind].select(1); main._on_part_selected(1, kind)
			check(main.mission_next_action_label.text == guidance and receipts[0].canonical_signature() == signature, "Unrun controls cannot relabel recorded evidence")
			main._run_debug_case(); main._finish_playback(); await settle()
			check(chapter.receipts_for(level).size() == 1 and not chapter.completed_levels().get(level, false), "Debug cannot supply the missing official comparison")
			main._run_official(); main._finish_playback(); await settle()
			check(chapter.receipts_for(level).size() == 2 and chapter.completed_levels().get(level, false), "Second real controlled observation earns original completion")
			check(not main.mission_next_action_label.visible, "Completed task hides its incomplete-task action")
			check(receipts[0].canonical_signature() == signature, "Guidance preserves baseline identity")
		main._start_level(&"assembly"); main._auto_connect()
		main.editor.text = "value = 0\nstore(OUTPUT[0], value)"
		main._apply_program(); main._run_official(); main._finish_playback(); await settle()
		check(main.latest_receipt != null and not main.latest_receipt.all_passed and not chapter.completed_levels().get(&"assembly", false), "Actual wrong output cannot become task completion")
		check(main.status_label.get_theme_color("font_color") == main.BAD and main.status_label.text == main.test_status_label.text, "Wrong-output error stays visible instead of becoming generic progress")
		main._start_level(&"read_once"); main._run_official(); main._finish_playback(); await settle()
		check(main.latest_receipt.all_passed and not chapter.completed_levels().get(&"read_once", false), "Correct repeated-load starter still misses the request target")
		check(main.mission_next_action_label.text == main._t(&"system.mission.next.read_once"), "Target-unmet application points to actual per-case budgets")
		var baseline: SystemRunReceipt = main.latest_receipt
		main.editor.text = main.catalog.PROGRAM_SUM.replace("store(OUTPUT[0], acc)", "acc += acc\nstore(OUTPUT[0], acc)")
		main._apply_program(); main._run_official(); main._finish_playback(); await settle()
		check(main.latest_receipt.all_passed and chapter.completed_levels().get(&"read_once", false), "Alternative legal reuse program retains original acceptance")
		check(not main.mission_next_action_label.visible and not main.catalog.completion_status(&"read_once", [baseline]).complete, "New success cannot rewrite an older over-budget run")
		main._start_level(&"two_orders")
		var compute: SystemRunReceipt
		var move: SystemRunReceipt
		for cpu: StringName in [&"cpu_eco", &"cpu_balanced", &"cpu_fast"]:
			for ram: StringName in [&"ram_slow", &"ram_balanced", &"ram_fast"]:
				for bus: StringName in [&"bus_2", &"bus_4", &"bus_8"]:
					var parts: Dictionary = {&"cpu": cpu, &"ram": ram, &"bus": bus}
					if compute == null:
						var candidate: SystemRunReceipt = main.catalog.replay_application(&"two_orders", main.catalog.PROGRAM_CPU, parts)
						if main.catalog.completion_status(&"two_orders", [candidate]).progress == 1: compute = candidate
					if move == null:
						var candidate: SystemRunReceipt = main.catalog.replay_application(&"two_orders", main.catalog.PROGRAM_COPY, parts)
						if main.catalog.completion_status(&"two_orders", [candidate]).progress == 1: move = candidate
		check(compute != null and move != null, "Both order fixtures come from actual qualifying model replays")
		if compute != null and move != null:
			var compute_status: Dictionary = main.catalog.completion_status(&"two_orders", [compute])
			var move_status: Dictionary = main.catalog.completion_status(&"two_orders", [move])
			check(main._completion_next_action(compute_status) == main._t(&"system.mission.next.move_order"), "Compute-only evidence requests the missing move order")
			check(main._completion_next_action(move_status) == main._t(&"system.mission.next.compute_order"), "Move-only evidence requests the missing compute order")
			check(not chapter.completed_levels().get(&"two_orders", false), "Inspecting replay status grants no campaign completion")
			compute.test_set_signature = "stale-test-contract"
			var stale_status: Dictionary = main.catalog.completion_status(&"two_orders", [compute])
			check(stale_status.progress == 0 and main._completion_next_action(stale_status) == main._t(&"system.mission.next.two_orders"), "Stale contract cannot claim a previously measured order")
		check(main._completion_next_action({"reason": &"more_scales_required"}) == main._t(&"system.mission.next.scales"), "Existing scale reason has a full-test instruction without adding a scale task")
		check(main._completion_next_action({"reason": &"diagnosis_required"}).is_empty(), "Existing diagnosis feedback retains authority over diagnosis guidance")
		main.queue_free(); await settle()
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "system evidence guidance (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)
