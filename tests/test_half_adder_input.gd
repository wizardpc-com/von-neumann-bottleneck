extends "res://tests/test_first_lesson_input.gd"
## Continues the earned first-lesson route with GUI wiring, a failing case,
## a correction and sealing. No reference loader or progress fixture is used.

func finish() -> void:
	if ui != null and ui.get("current_level_id") == &"half_adder" and failures.is_empty():
		await half_adder_flow()
	super.finish()

func half_adder_flow() -> void:
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
	await press(ui.official_button)
	await wait_playback()
	check(not ui.official_passed and ui.seal_button.disabled and not ui.completed_levels.get(&"half_adder", false), "Incorrect SUM cannot seal or complete half adder.")
	var failed_case: Dictionary = ui.official_report.cases[3]
	check(not failed_case.passed and failed_case.actual_sum and not failed_case.expected_sum and failed_case.actual_carry, "The real 1+1 case exposes SUM=1 instead of 0 while CARRY=1 is correct.")
	await settle()
	var failed_row: Label = ui.official_case_labels[3]
	check(failed_row.text.contains(text(&"hardware.cases.expected_outputs") % [0, 1]), "The failed row puts expected SUM and CARRY alongside the actual outputs.")
	var scroll: Node = failed_row.get_parent()
	while scroll != null and not scroll is ScrollContainer: scroll = scroll.get_parent()
	if scroll != null and not scroll.get_global_rect().encloses(failed_row.get_global_rect()):
		print("Failed row bounds: ", failed_row.get_global_rect(), " viewport: ", scroll.get_global_rect())
	check(scroll != null and scroll.get_global_rect().encloses(failed_row.get_global_rect()), "The full failed row, including expected values, stays visible at 720p.")
	await capture("half-adder-failed-11")
	await close_window(&"test_bench")
	await click(curve_point(&"SUM_OUT"), MOUSE_BUTTON_RIGHT)
	await wire(&"OR_1", &"AND_1")
	await wire(carry_gate, &"NOT_1")
	await wire(&"NOT_1", &"AND_1", 0, 1)
	await wire(&"AND_1", &"SUM_OUT")
	await press(ui.desktop_window_buttons[&"test_bench"])
	await press(ui.official_button)
	await wait_playback()
	check(ui.official_passed and ui.official_report.cases.size() == 4, "The player's corrected circuit passes all four original cases.")
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
