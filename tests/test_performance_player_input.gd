extends "res://scripts/proxy-player-paths.gd"
## Isolated Test-mode task entry; experiments and edits use viewport input.
## No prerequisite journey or human understanding is claimed.

func finish() -> void:
	var file := FileAccess.open(evidence_root + root.get_node("Localization").current_locale() + "-ui-observations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(observations, "\t"))
	print("Performance input checks: %d; failures: %d" % [observations.size(), failures.size()])
	if failures.is_empty(): print("PASS: focused performance player input")
	quit(0 if failures.is_empty() else 1)

func finish_trace() -> void:
	check(root.get_visible_rect().encloses(ui.finish_playback_button.get_global_rect()), "Finish playback remains inside the 720p viewport.")
	if ui.playback_running: await press(ui.finish_playback_button)
	await settle()
	check(not ui.playback_running, "The visible finish-playback action ends the presentation.")

func shot(label: String) -> void:
	if "--recovery-capture" in OS.get_cmdline_user_args():
		await create_timer(4.0).timeout
		await capture(label)

func only_tool(id: StringName) -> void:
	await close_tools()
	await open_tool(id)
	await settle()

func replace_loop_variable(line: int, column: int, value: String) -> void:
	await press(ui.editor)
	await key(KEY_HOME, true)
	for index: int in line: await key(KEY_DOWN)
	await key(KEY_HOME)
	await key(KEY_HOME)
	for index: int in column: await key(KEY_RIGHT)
	for index: int in 3: await key(KEY_RIGHT, false, true)
	await type_text(value)
	await settle()

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	change_scene_to_file("res://src/system_lab/system_lab.tscn")
	await settle(12)
	ui = current_scene
	ui._start_level(&"cpu_speed")
	await settle(12)
	await choose(ui.prediction_selector,1)
	await press(ui.prediction_lock_button)
	var prediction: StringName = ui.locked_prediction_id
	check(not prediction.is_empty(), "The player's initial prediction is locked before observing results.")
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	var chapter: Node = root.get_node("SystemChapter")
	var receipts: Array = chapter.receipts_for(&"cpu_speed")
	check(receipts.size() == 1 and receipts[0].all_passed and not chapter.completed_levels().get(&"cpu_speed",false), "One correct official baseline does not complete the comparison.")
	if receipts.is_empty():
		await finish()
		return
	var baseline = receipts[0]
	var signature: String = baseline.canonical_signature()
	await only_tool(&"mission")
	check(ui.mission_next_action_label.visible and ui.mission_next_action_label.text == ui._t(&"system.mission.next.comparison",[ui._part_kind_name(&"cpu")]), "The mission explains that the missing evidence is a second CPU configuration.")
	await shot("cpu-baseline")
	await only_tool(&"parts")
	await choose(ui.part_selectors[&"cpu"],1)
	check(baseline.canonical_signature() == signature and chapter.receipts_for(&"cpu_speed").size() == 1, "Changing the CPU does not rewrite the first recorded result.")
	await only_tool(&"test_bench")
	await press(ui.debug_run_button)
	await finish_trace()
	check(chapter.receipts_for(&"cpu_speed").size() == 1 and not chapter.completed_levels().get(&"cpu_speed",false), "A successful single-case debug run cannot supply the official comparison.")
	await shot("cpu-debug-not-complete")
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	receipts = chapter.receipts_for(&"cpu_speed")
	check(receipts.size() == 2 and chapter.completed_levels().get(&"cpu_speed",false), "The second controlled official run earns completion even when the initial prediction was wrong.")
	if receipts.size() != 2:
		await finish()
		return
	var after = receipts[1]
	check(after.metrics.cpu_compute_cycles * 4 == baseline.metrics.cpu_compute_cycles and after.metrics.cpu_wait_cycles == baseline.metrics.cpu_wait_cycles, "Four-times-faster arithmetic changes compute time while measured waiting stays the same.")
	check(after.metrics.total_cycles < baseline.metrics.total_cycles and after.metrics.total_cycles * 4 > baseline.metrics.total_cycles, "Actual total time decreases without becoming four times faster.")
	check(ui.locked_prediction_id == prediction and baseline.canonical_signature() == signature, "The original prediction and baseline remain visible evidence rather than being corrected after the fact.")
	await only_tool(&"history")
	check(ui.history_chart.visible and ui.history_chart.samples == [baseline.metrics,after.metrics], "The displayed comparison chart consumes the two actual recorded metrics.")
	check(ui.history_label.text.contains(str(baseline.metrics.total_cycles)) and ui.history_label.text.contains(str(after.metrics.total_cycles)), "The comparison text names both measured totals.")
	await shot("cpu-controlled-comparison")
	change_scene_to_file("res://src/ui/main.tscn")
	await settle(12)
	ui = current_scene
	ui._start_level(&"access_order")
	await settle(12)
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	check(ui.current_trace.passed and not ui.current_goal_met and ui.current_trace.metrics.total_cycles == 321, "The original column-first program is correct but misses the 105-cycle target.")
	check(not root.get_node("LocalityChapter").completed_levels().get(&"access_order",false), "Correct output alone does not complete access-order optimization.")
	check(ui.result_label.text.contains("321") and ui.result_label.text.contains("105"), "The failed-target result names the measured time and target.")
	await shot("access-order-over-target")
	var original: String = ui.applied_program_source
	await only_tool(&"program")
	await replace_loop_variable(2,4,"row")
	await replace_loop_variable(3,8,"col")
	check(ui.editor.text == original.replace("for col in range(4):\n    for row", "for row in range(4):\n    for col"), "Keyboard input changes only the two loop variables, preserving the computation.")
	check(ui.program_dirty and ui.applied_program_source == original and ui.official_run_button.disabled and not ui.apply_program_button.disabled, "The valid edit remains a draft; official execution waits for Apply.")
	check(ui.playback_label.text == ui.program_apply_label.text and ui.playback_label.text == ui._t(&"program.apply.draft_pending"), "Playback feedback asks for Apply while the formal run is disabled.")
	await shot("access-order-unapplied")
	await press(ui.apply_program_button)
	check(not ui.program_dirty and ui.DSLParserType.parse(ui.applied_program_source).traversal_pattern() == "row-first" and not ui.official_run_button.disabled, "Clicking Apply installs the edited row-first program.")
	check(ui.playback_label.text == ui._t(&"trace.playback.inputs_changed"), "After Apply, feedback can invite a new run.")
	await only_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()
	check(ui.current_trace.passed and ui.current_goal_met and ui.current_trace.metrics.total_cycles == 105, "The applied program actually reaches 105 cycles with correct output.")
	check(not root.get_node("LocalityChapter").completed_levels().get(&"access_order",false), "Qualifying results still wait for the original Review finding action.")
	await shot("access-order-target-met")
	await only_tool(&"profiler")
	check(ui.profiler_history_label.text.contains("321") and ui.profiler_history_label.text.contains("105"), "The profiler retains the real column-first versus row-first comparison.")
	check(not ui.capstone_compare_box.visible, "Access-order comparison does not expose capstone-only controls.")
	await press(ui.profiler_history_label)
	await shot("access-order-comparison")
	await only_tool(&"mission")
	await press(ui.mission_review_button)
	check(root.get_node("LocalityChapter").completed_levels().get(&"access_order",false) and ui.level_completion_overlay.visible, "Reviewing the actual result earns access-order completion.")
	await shot("access-order-completion")
	await finish()
