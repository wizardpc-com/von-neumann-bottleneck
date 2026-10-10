extends SceneTree
## Actual official UI runs and task-tree re-entry retain the measured Before source.
var checks: int = 0
var failures: Array[String] = []

func _init() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 6: await process_frame

func run() -> void:
	var mode: Node = root.get_node("GameMode")
	var system: Node = root.get_node("SystemChapter")
	var state: Node = root.get_node("LocalityChapter")
	var nav: Node = root.get_node("TaskNavigation")
	mode.set_mode(&"game")
	# Fixture access only: every receipt under review is produced by actual runs.
	for id: StringName in [&"assembly",&"cpu_speed",&"ram_wait",&"bus_width",&"bottleneck"]:
		system.mark_completed(id)
	for id: StringName in [&"distant_reads",&"nearby_storage",&"cache_failure",&"access_order",&"working_set",&"blocking"]:
		state.mark_completed(id)
	check(nav.enter("chapter_2/capstone"),"Real tree router opens the capstone")
	await settle()
	var main = current_scene
	check(main != null and main.current_level_id == &"capstone","Host consumes the exact capstone selection")
	if main == null or main.current_level_id != &"capstone": quit(1); return
	main._run_simulation("Official Test Set")
	var baseline: Dictionary = main.run_history[0].duplicate(true)
	check(baseline.cycles == 642,"Before begins with the actual authored 642-cycle run")
	main._select_judgment(&"repeated_far_fetch")
	check(main.editor.editable,"Actual supported diagnosis opens the experiment controls")
	main._select_cache(4,true)
	main._run_simulation("Official Test Set")
	main._finish_playback()
	check(state.capstone_first_experiment_observed(),"First one-lever experiment is actually observed before combinations")
	for configuration: Array in [[1,1],[1,2],[1,4],[2,0],[2,1],[2,2],[2,4]]:
		main._select_cache(configuration[0],true)
		main._select_block_lines(configuration[1],true)
		main._run_simulation("Official Test Set")
	check(state.receipts_for(&"capstone").size() == 9,"Nine distinct configurations produce nine genuine official receipts")
	check(main.run_history.size() == main.RUN_HISTORY_LIMIT and main.run_history[0] == baseline,"Live bounded history retains the original measured Before")
	var before_line: String = main._t(&"chapter2.history.before",[main._history_config_text(baseline)])
	var latest: Dictionary = main.run_history[-1].duplicate(true)
	var delta_line: String = main._t(&"chapter2.history.total_delta",[baseline.cycles,latest.cycles,main._signed_number(latest.cycles-baseline.cycles),main._signed_percent(roundi(float(latest.cycles-baseline.cycles)*100.0/float(baseline.cycles)))])
	check(main.profiler_history_label.text.contains(before_line) and main.profiler_history_label.text.contains(delta_line),"Before configuration and measured cycle delta are visible before departure")
	main._show_chapter_map()
	await settle()
	check(current_scene != null and current_scene.scene_file_path == nav.MAP_SCENE,"Actual departure returns to the shared task tree")
	check(nav.enter("chapter_2/capstone"),"Actual tree router reopens the capstone")
	await settle(); main = current_scene
	check(main.run_history.size() == main.RUN_HISTORY_LIMIT and main.run_history[0] == baseline,"Restored bounded history preserves the same baseline record")
	check(main.run_history[-1] == latest,"Restoration retains the actual latest experiment")
	main._select_judgment(&"repeated_far_fetch")
	main._update_history_label()
	check(main.profiler_history_label.text.contains(before_line) and main.profiler_history_label.text.contains(delta_line),"Re-entry preserves the same Before configuration and cycle comparison")
	# A paired observation remains owned by its previous task, with no capstone data.
	main._start_level(&"distant_reads")
	main._run_simulation("Official Test Set")
	var observation: Dictionary = main.run_history[-1].duplicate(true)
	main._start_level(&"nearby_storage")
	check(main.run_history.size() == 1 and main.run_history[0] == observation,"A different task still inherits its own real observation as Before")
	main._run_simulation("Official Test Set")
	check(main.run_history.size() == 2 and main.run_history[0] == observation,"Paired Before remains unchanged when its actual After is measured")
	print("PASS: locality restored baseline %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
