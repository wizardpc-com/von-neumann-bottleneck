extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame: int in 8:
		await process_frame

func history(main: Control) -> String:
	main._refresh_history()
	return main.history_label.get_parsed_text()

func lock_prediction(main: Control) -> void:
	main.prediction_selector.select(1)
	main._lock_prediction()

func select_part(main: Control, kind: StringName, index: int) -> void:
	main.part_selectors[kind].select(index)
	main._on_part_selected(index, kind)

func run() -> void:
	# Controller fixtures use isolated Test progress, never native-play provenance.
	var game_mode: Node = root.get_node("GameMode")
	var chapter: Node = root.get_node("SystemChapter")
	game_mode.set_mode(&"test")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		chapter.reset_test_progress()
		var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
		root.add_child(main)
		await settle()
		for setup: Array in [[&"cpu_speed", &"cpu", 21, 30], [&"ram_wait", &"ram", 30, 39], [&"bus_width", &"bus", 30, 39]]:
			var level: StringName = setup[0]
			var kind: StringName = setup[1]
			var before_cost: int = setup[2]
			var after_cost: int = setup[3]
			main._start_level(level)
			await settle()
			check(main.part_selectors[kind].disabled, locale + ": baseline part stays locked")
			check(history(main).contains(main._t(&"system.history.empty")), locale + ": no run means no cost evidence")
			main._run_official()
			check(chapter.receipts_for(level).is_empty(), locale + ": prediction remains required")
			lock_prediction(main)
			main._run_official()
			main._finish_playback()
			await settle()
			var receipts: Array = chapter.receipts_for(level)
			check(receipts.size() == 1 and receipts[0].all_passed, locale + ": one real baseline receipt")
			var baseline_signature: String = receipts[0].canonical_signature()
			check(int(receipts[0].metrics.hardware_cost) == before_cost, locale + ": receipt cost is machine cost, not the sum across cases")
			var baseline_text: String = history(main)
			var case_count: int = 1 if level == &"bus_width" else 2
			check(receipts[0].total_cases == case_count, locale + ": fixture uses the actual official case count")
			check(baseline_text.contains(main._t(&"system.history.metric_scope", [case_count])), locale + ": baseline explains summed timings and per-machine cost")
			check(baseline_text.contains(main._t(&"system.history.recorded_cost", [before_cost])), locale + ": baseline shows run-recorded cost")
			check(not bool(chapter.completed_levels().get(level, false)), locale + ": cost display does not complete comparison")
			select_part(main, kind, 1)
			check(history(main) == baseline_text, locale + ": unrun hardware selection never rewrites recorded cost")
			check(receipts[0].canonical_signature() == baseline_signature, locale + ": selecting hardware preserves receipt identity")
			main._run_debug_case()
			main._finish_playback()
			check(history(main) == baseline_text and chapter.receipts_for(level).size() == 1, locale + ": debug run is not official cost comparison")
			main._run_official()
			main._finish_playback()
			await settle()
			receipts = chapter.receipts_for(level)
			check(receipts.size() == 2 and receipts[1].all_passed, locale + ": official changed endpoint adds measured evidence")
			check(int(receipts[1].metrics.hardware_cost) == after_cost, locale + ": changed receipt retains actual cost")
			var comparison_text: String = history(main)
			check(comparison_text.contains(main._t(&"system.history.metric_scope", [case_count])), locale + ": comparison explains the scope of both measured endpoints")
			check(comparison_text.contains(main._t(&"system.history.cost_delta", [before_cost, after_cost, "+9"])), locale + ": comparison shows actual cost delta")
			check(bool(chapter.completed_levels().get(level, false)), locale + ": original completion rule still accepts higher-cost endpoint")
			check(receipts[0].canonical_signature() == baseline_signature, locale + ": presentation does not mutate baseline")
			select_part(main, kind, 0)
			check(history(main) == comparison_text, locale + ": unrun return to baseline does not relabel measured After cost")
			var applied: String = main.applied_program_source
			main.editor.text = applied + "\ninvalid draft"
			main._on_program_changed()
			main._run_official()
			check(main.official_run_button.disabled and chapter.receipts_for(level).size() == 2, locale + ": draft remains unapplied and cannot earn evidence")
			check(history(main) == comparison_text, locale + ": unapplied draft preserves measured cost history")
			main.editor.text = applied
			main._on_program_changed()
			# Repeating an identical receipt keeps the existing deduplicated comparison.
			main._run_official()
			main._finish_playback()
			check(history(main) == comparison_text and chapter.receipts_for(level).size() == 2, locale + ": identical reruns preserve receipt deduplication and the original comparison")
		main._start_level(&"bottleneck")
		await settle()
		main._run_official()
		main._finish_playback()
		var final_receipt = main.latest_receipt
		var final_text: String = history(main)
		check(final_receipt.total_cases == 3, locale + ": final observation covers all three workloads")
		check(final_text.contains(main._t(&"system.history.metric_scope", [3])), locale + ": final observation explains the three-case sum")
		check(final_text.contains("已记录的观测" if locale == "zh_CN" else "RECORDED OBSERVATION"), locale + ": recorded observation does not claim to measure unrun selections")
		check(int(final_receipt.metrics.total_cycles) == 2352 and int(final_receipt.metrics.hardware_cost) == 21, locale + ": summed timings preserve one-machine cost")
		check(not bool(chapter.completed_levels().get(&"bottleneck", false)), locale + ": scope disclosure does not bypass diagnosis")
		for index: int in main.diagnosis_selector.item_count:
			if main.diagnosis_selector.get_item_metadata(index) == final_receipt.diagnosed_bottleneck:
				main.diagnosis_selector.select(index)
		main._confirm_diagnosis()
		var final_signature: String = final_receipt.canonical_signature()
		select_part(main, &"ram", 2)
		var retained_text: String = history(main)
		check(retained_text.contains(main._t(&"system.history.metric_scope", [3])), locale + ": unrun final hardware change retains recorded three-case scope")
		check(retained_text.contains(main._t(&"system.history.observation", [main._machine_summary(final_receipt)])), locale + ": unrun selection does not relabel the recorded machine")
		check(retained_text.contains(main._t(&"system.history.baseline_metrics", [2352, 1848])) and retained_text.contains(main._t(&"system.history.recorded_cost", [21])), locale + ": unrun selection retains measured total, wait and cost")
		check(final_receipt.canonical_signature() == final_signature, locale + ": unrun selection preserves official receipt identity")
		main._run_debug_case()
		main._finish_playback()
		check(history(main).contains(main._t(&"system.history.metric_scope", [3])), locale + ": one-case debug does not relabel official three-case evidence")
		check(final_receipt.canonical_signature() == final_signature, locale + ": debug preserves the recorded receipt")
		main._run_official()
		main._finish_playback()
		check(history(main).contains(main._t(&"system.history.metric_scope", [3])), locale + ": new official measurement retains correct scope")
		check(int(main.latest_receipt.metrics.total_cycles) == 1680 and int(main.latest_receipt.metrics.hardware_cost) == 27, locale + ": new official observation uses measured configuration")
		main.queue_free()
		await settle()
	if failures.is_empty():
		print("PASS: %d bilingual system cost-evidence checks" % checks)
		quit(0)
	else:
		print("FAIL: %d / %d system cost-evidence checks" % [failures.size(), checks])
		quit(1)
