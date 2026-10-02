extends SceneTree
const Continuity = preload("res://src/system_lab/system_baseline_continuity.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _run() -> void:
	var chapter: Node = root.get_node("SystemChapter")
	root.get_node("GameMode").set_mode(&"test")
	chapter.reset_test_progress()
	var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(main)
	for frame: int in 5: await process_frame
	main._start_level(&"ram_wait")
	await process_frame
	check(main.reuse_baseline_button.disabled, "No observation means no reusable baseline")
	var catalog: SystemLevelCatalog = main.catalog
	var parts: Dictionary = {&"cpu": &"cpu_fast", &"ram": &"ram_slow", &"bus": &"bus_8"}
	var previous: SystemRunReceipt = catalog.replay_observation(&"cpu_speed", catalog.PROGRAM_SUM, parts)
	check(previous.all_passed, "Source fixture uses real simulations")
	chapter.record_receipt(&"cpu_speed", previous)
	main._refresh_comparison_part_lock()
	check(not main.reuse_baseline_button.disabled, "Matching machine and workload expose optional reuse")
	main.reuse_baseline_button.pressed.emit()
	check(chapter.receipts_for(&"ram_wait").is_empty(), "Reuse cannot bypass prediction")
	main.prediction_selector.select(1)
	main._on_prediction_selected(1)
	main._lock_prediction()
	var previous_signature: String = previous.canonical_signature()
	previous.metrics.total_cycles = 1
	main.reuse_baseline_button.pressed.emit()
	check(chapter.receipts_for(&"ram_wait").is_empty(), "Revalidation rejects tampered source metrics")
	previous.metrics.total_cycles = catalog.replay_observation(&"cpu_speed", catalog.PROGRAM_SUM, parts).metrics.total_cycles
	check(previous.canonical_signature() == previous_signature, "Source fixture restored exactly")
	main.reuse_baseline_button.pressed.emit()
	var receipts: Array = chapter.receipts_for(&"ram_wait")
	check(receipts.size() == 1 and receipts[0].level_id == &"ram_wait", "Target gets its own re-simulated observation")
	check(receipts.size() == 1 and receipts[0].test_set_signature == catalog.test_set_signature(&"ram_wait") and receipts[0].metrics == previous.metrics, "Target identity and real metrics are retained")
	check(not main.part_selectors[&"ram"].disabled and not chapter.completed_levels().get(&"ram_wait",false), "Reuse opens the changed endpoint without granting completion")
	check(not main.playback_running, "Reuse does not repeat the baseline animation")
	check(previous.canonical_signature() == previous_signature, "Source observation remains immutable")
	var changed: SystemTopology = main._topology_from_graph()
	changed.set_part(&"RAM",catalog.part(&"ram_fast"))
	check(Continuity.matching_source(catalog,[previous],main.applied_program,changed) == null, "Different machine cannot reuse the baseline")
	var changed_catalog := SystemLevelCatalog.new("different-cpu", "different-ram")
	var changed_receipt: SystemRunReceipt = changed_catalog.replay_observation(&"cpu_speed", catalog.PROGRAM_SUM, parts)
	check(Continuity.matching_source(catalog,[changed_receipt],main.applied_program,main._topology_from_graph()) == null, "Changed provenance cannot reuse the baseline")
	main.editor.text += "\n# draft"
	check(main._previous_baseline() == null, "Unapplied drafts cannot reuse observations")
	main._start_level(&"bus_width")
	check(not main.reuse_baseline_button.visible and main._previous_baseline() == null, "Different copy workload does not inherit sum evidence")
	main.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: exact baseline continuity, revalidation, provenance and evidence boundaries")
	else:
		for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
