extends "res://tests/test_first_lesson_input.gd"
## Continues the earned first-lesson route with GUI wiring, a failing case,
## a correction and sealing. No reference loader or progress fixture is used.

func finish() -> void:
	if ui != null and ui.get("current_level_id") == &"half_adder" and failures.is_empty():
		await half_adder_flow()
	super.finish()

func half_adder_flow() -> void:
	check(ui.graph.get_connection_list().is_empty() and ui.component_library.is_empty(),
		"Continuing from earned NOT starts Half Adder on an unsolved board with no reusable reward.")
	await close_window(&"task")
	await close_window(&"components")
	await close_window(&"test_bench")
	await frequency()
	var carry_gate := &"AND_1_COPY_002"
	await wire(&"A_IN", &"OR_1")
	await wire(&"B_IN", &"OR_1", 0, 1)
	await wire(&"OR_1", &"SUM_OUT")
	await wire(&"A_IN", carry_gate)
	await wire(&"B_IN", carry_gate, 0, 1)
	await wire(carry_gate, &"CARRY_OUT")
	await press(ui.desktop_window_buttons[&"test_bench"])
	var bench: Control = ui.desktop_windows[&"test_bench"]
	var try_11 := bench.find_child("TryCase3", true, false) as Button
	var scroll := ui.side_box.get_parent() as ScrollContainer
	var expected_11: String = text(&"hardware.cases.expected_outputs") % [0, 1]
	await press(try_11)
	await press(ui.bench_debug_button)
	await wait_playback()
	var wrong_trace: CircuitTrace = ui.current_trace
	check(wrong_trace != null and wrong_trace.is_valid()
		and wrong_trace.input_values[&"A"] and wrong_trace.input_values[&"B"]
		and wrong_trace.outputs[&"SUM"] and wrong_trace.outputs[&"CARRY"],
		"The first debug run actually measures SUM=1 and CARRY=1 for A=B=1.")
	var wrong_actual: String = text(&"hardware.result.half_adder") % [text(&"hardware.result.actual"), 1, 1]
	check(ui.debug_result_label.text.contains(wrong_actual)
		and ui.debug_result_label.text.contains(text(&"outcome.fail"))
		and ui.debug_result_label.text.contains(expected_11),
		"The bench compares the mismatched debug output with the puzzle specification.")
	check(scroll != null and scroll.get_global_rect().encloses(ui.debug_result_label.get_global_rect()),
		"The full debug comparison scrolls into view after selecting a case lower in the bench.")
	check(ui.official_report.is_empty() and ui.seal_button.disabled,
		"Debug diagnosis leaves the official report empty and Seal disabled.")
	check(ui.guided_debug_ran and ui.guided_case_evidence.has(3),
		"The coach records the measured 11 case on the original board.")
	await press(ui.input_b_button)
	check(ui.debug_result_label.text == text(&"hardware.cases.actual_empty"),
		"Changing the input clears the previous debug comparison.")
	await press(ui.official_button)
	await wait_playback()
	check(not ui.official_passed and ui.seal_button.disabled and not ui.completed_levels.get(&"half_adder", false), "Incorrect SUM cannot seal or complete half adder.")
	var failed_case: Dictionary = ui.official_report.cases[3]
	check(not failed_case.passed and failed_case.actual_sum and not failed_case.expected_sum and failed_case.actual_carry, "The real 1+1 case exposes SUM=1 instead of 0 while CARRY=1 is correct.")
	await settle()
	var failed_row: Label = ui.official_case_labels[3]
	check(failed_row.text.contains(expected_11), "The failed row puts expected SUM and CARRY alongside the actual outputs.")
	check(ui.selected_result_case == 3 and ui.input_a_button.text == "1" and ui.input_b_button.text == "1"
		and ui.debug_result_label.text.contains(expected_11) and ui.mismatch_markers.size() == 1,
		"Automatic failure inspection restores the exact failing input, comparison, and SUM marker.")
	if scroll != null and not scroll.get_global_rect().encloses(failed_row.get_global_rect()):
		print("Failed row bounds: ", failed_row.get_global_rect(), " viewport: ", scroll.get_global_rect())
	check(scroll != null and scroll.get_global_rect().encloses(failed_row.get_global_rect()), "The full failed row, including expected values, stays visible at 720p.")
	await capture("half-adder-failed-11")
	await close_window(&"test_bench")
	await click(curve_point(&"SUM_OUT"), MOUSE_BUTTON_RIGHT)
	check(ui.official_report.is_empty() and ui.debug_result_label.text == text(&"hardware.cases.actual_empty")
		and ui.mismatch_markers.is_empty(), "Editing the failing wire clears both stale comparison and official evidence.")
	await wire(&"OR_1", &"AND_1")
	await wire(carry_gate, &"NOT_1")
	await wire(&"NOT_1", &"AND_1", 0, 1)
	await wire(&"AND_1", &"SUM_OUT")
	check(not ui.guided_debug_ran and ui.guided_case_evidence.is_empty()
		and ui.tutorial_coach.last_states == [true, false, false],
		"Rewiring clears the previous case and returns the coach to the try step.")
	var bench_dock: Button = ui.desktop_window_buttons[&"test_bench"]
	check(not bench.visible and bench_dock.is_visible_in_tree() and ui.guide_highlight.target == bench_dock,
		"With the bench closed, the coach points to the dock button that reopens it.")
	await press(bench_dock)
	check(ui.bench_debug_button.is_visible_in_tree() and ui.guide_highlight.target == ui.bench_debug_button
		and ui.tutorial_coach.last_states == [true, false, false] and ui.guided_case_evidence.is_empty(),
		"Reopening the bench points to Debug and the corrected board is still untried.")
	await press(ui.bench_debug_button)
	await wait_playback()
	var corrected_actual: String = text(&"hardware.result.half_adder") % [text(&"hardware.result.actual"), 0, 1]
	check(ui.debug_result_label.text.contains(corrected_actual)
		and ui.debug_result_label.text.contains(text(&"outcome.pass")) and not ui.debug_result_label.text.contains(expected_11)
		and ui.input_a_button.button_pressed and ui.input_b_button.button_pressed and ui.seal_button.disabled,
		"Rerunning the same input confirms the correction before any official pass or seal.")
	await key(KEY_F4)
	check(ui.current_trace == null and ui.debug_result_label.text == text(&"hardware.cases.actual_empty")
		and ui.input_a_button.button_pressed and ui.input_b_button.button_pressed,
		"Reset clears the Half Adder comparison and keeps the selected input bits.")
	await capture("half-adder-reset")
	await press(bench.find_child("TryCase0", true, false) as Button)
	await wait_playback()
	check(not ui.input_a_button.button_pressed and not ui.input_b_button.button_pressed,
		"The all-pass run starts with debug input 00, distinct from its final case 11.")
	var observed: Array[int] = []
	var sample_case := func() -> void:
		if not ui.official_sequence_active or ui.official_sequence_index in observed:
			return
		var index: int = ui.official_sequence_index
		var trace: CircuitTrace = ui.current_trace
		var example: Dictionary = HalfAdderTestBench.OFFICIAL_CASES[index]
		observed.append(index)
		check(trace != null and trace.input_values[&"A"] == example.A and trace.input_values[&"B"] == example.B
			and inputs_show(trace) and ui.input_a_button.disabled and ui.input_b_button.disabled,
			"Official case %d displays both measured input bits and locks both toggles." % index)
	process_frame.connect(sample_case)
	await press(ui.official_button)
	await wait_playback()
	process_frame.disconnect(sample_case)
	check(observed == [0, 1, 2, 3], "The displayed-input check observed every official case during playback.")
	check(ui.official_passed and ui.official_report.cases.size() == 4, "The player's corrected circuit passes all four original cases.")
	check(ui.official_report.get("cases", []).size() == 4 and ui.current_trace != null
		and ui.current_trace == ui.official_report.cases[3].trace and inputs_show(ui.current_trace)
		and not ui.input_a_button.disabled and not ui.input_b_button.disabled,
		"The all-pass exit keeps the last measured input on the bench and unlocks both toggles.")
	check(not ui.completed_levels.get(&"half_adder", false), "Passing cases alone has not installed the reusable part.")
	check(ui.level_completion_overlay.title_label.text == text(&"hardware.completion.tests_passed"), "The pre-seal result is labelled Tests passed, distinct from completion.")
	await create_timer(3.0).timeout
	await capture("half-adder-tested-before-seal")
	await press(ui.level_completion_overlay.primary_action_button)
	await wait_playback()
	check(ui.completed_levels.get(&"half_adder", false) and ui.current_phase == &"sealed", "The explicit seal action earns completion and the reusable part.")
	check(ui.level_completion_overlay.title_label.text == text(&"common.level_complete.title"), "The completed part now receives the completion title.")
	await create_timer(3.0).timeout
	await capture("half-adder-sealed")
	await press(ui.level_completion_overlay.continue_button)
	await settle(12)
	var owned_half_adder: bool = false
	for card: Control in ui.component_palette_items.values():
		if card.get("component_kind") == &"half_adder" and card.get_meta("palette_owned", false):
			owned_half_adder = true
			break
	check(ui.current_level_id == &"full_adder" and owned_half_adder,
		"Continue opens Full Adder with the newly earned HalfAdder available for reuse.")

func inputs_show(trace: CircuitTrace) -> bool:
	var a: bool = trace.input_values[&"A"]
	var b: bool = trace.input_values[&"B"]
	return (ui.input_a_button.is_visible_in_tree() and ui.input_b_button.is_visible_in_tree()
		and ui.input_a_button.button_pressed == a and ui.input_b_button.button_pressed == b
		and ui.input_a_button.text == str(int(a)) and ui.input_b_button.text == str(int(b)))
