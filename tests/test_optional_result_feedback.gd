extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("SystemChapter").reset_test_progress()
	var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(main)
	for frame: int in 5: await process_frame
	main._start_level(&"read_once")
	main._run_official(); await process_frame
	check(main.latest_receipt.all_passed and main.latest_receipt.passed_cases == 5,"Starter retains all five correct outputs")
	check(not main.catalog.completion_status(&"read_once",[main.latest_receipt]).complete,"Starter misses authoritative objective")
	var card: Node = main.official_result_box.get_child(0)
	check(card.get_child(0).get_theme_color("font_color") == main.GOOD,"Correct output remains green")
	var budget: Label = card.get_node("RequestBudget")
	check(budget.text.contains("33") and budget.text.contains("17") and budget.get_theme_color("font_color") == main.WARNING,"33 over 17 is a separate warning")
	check(main.test_status_label.text.contains("5 / 5") and main.test_status_label.text.contains("17") and main.status_label.text == main._t(&"system.application.read_once.summary_unmet"),"Current result explains both correctness and concrete request limit with a compact header")
	check(main.test_status_label.get_theme_color("font_color") == main.WARNING,"Correct but target-unmet summary is not success-green")
	for i: int in main.latest_official_traces.size():
		var case_budget: Label = main.official_result_box.get_child(i).get_node("RequestBudget")
		var limit: int = main._active_cases()[i].input.size() + 1
		check(case_budget.text.contains(str(limit)) and case_budget.get_theme_color("font_color") == main.WARNING,"Each repeated-load case shows its own exceeded request cap")
	var starter_signature: String = main.latest_receipt.canonical_signature()
	main._stop_playback()
	main.editor.text = main.catalog.PROGRAM_REPEATED.replace("    value = load(INPUT[i])\n    acc += value\n    value = load(INPUT[i])","    value = load(INPUT[i])\n    acc += value")
	main._run_official()
	check(main.latest_receipt.case_metrics[0].memory_requests == 33,"Unapplied draft does not replace official result")
	check(main.latest_receipt.canonical_signature() == starter_signature,"Blocked Run preserves the exact receipt")
	main._apply_program(); main._run_official(); await process_frame
	check(main.catalog.completion_status(&"read_once",[main.latest_receipt]).complete,"Applied reuse reaches authoritative objective")
	budget = main.official_result_box.get_child(0).get_node("RequestBudget")
	check(budget.text.count("17") == 2 and budget.get_theme_color("font_color") == main.GOOD,"Exact 17-request boundary is green")
	check(main.test_status_label.get_theme_color("font_color") == main.GOOD and not main.test_status_label.text.contains("N+1"),"Success summary reflects current target")
	main._stop_playback(); main.editor.text = main.catalog.PROGRAM_REPEATED
	main._apply_program(); main._run_official(); await process_frame
	check(main.test_status_label.get_theme_color("font_color") == main.WARNING and main.test_status_label.text.contains("17"),"Previously completed task still warns on a new over-budget run")
	check(root.get_node("SystemChapter").completed_levels().get(&"read_once",false),"Presentation does not revoke previously earned completion")
	main._stop_playback(); main.editor.text = "acc = 16\nstore(OUTPUT[0], acc)"
	main._apply_program(); main._run_official(); await process_frame
	check(not main.latest_receipt.all_passed and main.test_status_label.get_theme_color("font_color") == main.BAD,"Wrong output retains failure semantics")
	main._stop_playback(); main._start_level(&"cpu_speed")
	var prior: String = main.status_label.text
	main._refresh_read_once_result()
	check(main.status_label.text == prior,"Core task feedback remains untouched")
	main._start_level(&"two_orders"); main._run_official(); await process_frame
	check(main.official_result_box.get_child(0).get_node_or_null("RequestBudget") == null,"Other application retains its own target presentation")
	main.queue_free(); await process_frame
	print("PASS: optional result feedback" if failures.is_empty() else "FAIL: optional result feedback")
	quit(0 if failures.is_empty() else 1)
