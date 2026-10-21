extends "res://tests/test_performance_player_input.gd"
## Actual scheduling edits; isolated task access does not prove prerequisites.

func finish() -> void:
	var file := FileAccess.open(evidence_root + "overlap-ui-observations.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t"))
	print("Overlap input checks: %d; failures: %d" % [observations.size(),failures.size()])
	if failures.is_empty(): print("PASS: overlap player input")
	quit(0 if failures.is_empty() else 1)

func schedule(source: String) -> void:
	await overlap_tool("program")
	await replace_program(source)
	check(ui.trace_stale and ui.locate_issue_button.disabled,"Editing disables navigation into stale run evidence.")
	await press(named_button(ui.panels.program,text(&"overlap.run")))
	await settle()

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("game/reduced_motion",true)
	var entered: bool = root.get_node("TaskNavigation").enter("chapter_3/arrival")
	check(entered,"Test mode opens the untouched arrival task.")
	if not entered:
		await finish()
		return
	await settle(16)
	ui = current_scene
	await press(named_button(ui.dock,text(&"overlap.run")))
	check(ui.trace.metrics.error == "not_ready" and ui.trace.metrics.error_line == 3,"The public starter stops at its actual early consume line.")
	await shot("arrival-before-ready")
	await press(ui.locate_issue_button)
	check(ui.editor.get_caret_line() == 2 and ui.panels.program.visible,"Locate focuses the source line responsible for the recorded stop.")
	await schedule("work 4")
	check(ui.trace.metrics.error == "incomplete" and ui.metrics.text.contains("0 / 1") and ui.metrics.text.contains("4 / "),"Completed independent work cannot substitute for the missing data batch.")
	await shot("arrival-batch-missing")
	await schedule("fetch A 0\nready A\nconsume A\nidle")
	check(ui.trace.result_value == 7 and ui.trace.expected_value == 7 and ui.trace.metrics.error == "incomplete","Waiting fixes data readiness and output, but missing independent work still fails.")
	check(not root.get_node("OverlapChapter").completed().has("arrival"),"Correct data output alone cannot complete arrival.")
	check(ui.metrics.text.contains("1 / 1") and ui.metrics.text.contains("0 / ") and ui.metrics.text.contains("exactly 4" if root.get_node("Localization").current_locale() == "en" else "恰好 4"),"The failed record explains completed batches and the missing exact independent workload.")
	await shot("arrival-work-missing")
	await schedule("fetch A 0\nwork 5\nready A\nconsume A\nidle")
	check(ui.trace.metrics.error == "incomplete" and ui.trace.metrics.total_cycles == 10,"Five independent cycles still fail the exact work requirement even within the time budget.")
	check(ui.metrics.text.contains("5 / ") and ui.metrics.text.contains("exactly 4" if root.get_node("Localization").current_locale() == "en" else "恰好 4"),"The same feedback distinguishes excess work from missing work.")
	await shot("arrival-work-excess")
	await schedule("fetch A 0\nready A\nconsume A\nidle\nwork 4")
	check(ui.trace.passed and ui.trace.metrics.total_cycles == 14 and not root.get_node("OverlapChapter").completed().has("arrival"),"Exact work after data processing is valid but four cycles too slow.")
	check(ui.metrics.text.contains("14") and ui.metrics.text.contains("10") and ui.metrics.text.contains("4"),"The measured time gap is visible in the result.")
	await shot("arrival-work-late")
	await schedule("fetch A 0\nwork 4\nready A\nconsume A\nidle")
	check(ui.trace.passed and ui.trace.metrics.total_cycles == 10 and ui.trace.metrics.overlap == 4,"Moving the same independent work into transfer time yields the real10-cycle run with4 overlapping cycles.")
	check(root.get_node("OverlapChapter").completed().has("arrival") and ui.completion.visible,"Only the actual valid and timely run earns completion.")
	await shot("arrival-work-overlaps")
	await finish()
