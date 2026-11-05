extends SceneTree
## Real runs, bounded history and compound draft restoration in isolated profiles.
const Templates = preload("res://src/simulation/program_templates.gd")
const Dialogue = preload("res://src/lab/chapter_dialogues.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame: int in 4: await process_frame

func new_host() -> Control:
	var host: Control = load("res://src/ui/main.tscn").instantiate()
	root.add_child(host)
	await settle()
	host._start_level(&"capstone")
	await settle()
	return host

func measure(host: Control) -> void:
	host._run_simulation("Official Test Set")
	host.playback_running = false

func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	root.size = Vector2i(1280,800)
	var mode: Node = root.get_node("GameMode")
	var state: Node = root.get_node("LocalityChapter")
	mode.set_mode(&"game")
	for id: StringName in [&"assembly",&"cpu_speed",&"ram_wait",&"bus_width",&"bottleneck"]:
		root.get_node("SystemChapter").mark_completed(id)
	for id: StringName in [&"distant_reads",&"nearby_storage",&"cache_failure",&"access_order",&"working_set",&"blocking"]:
		state.mark_completed(id)
	var host: Control = await new_host()
	check(not host.restore_best_button.visible,"No invented best before the first run.")
	measure(host)
	check(host.current_trace.metrics.total_cycles == 642,"Baseline is the actual authored workload.")
	check(not host.restore_best_button.visible,"Undiagnosed capstone does not disclose an optimized design.")
	host._select_judgment(&"repeated_far_fetch")
	host._select_cache(4,true)
	measure(host)
	host._finish_playback()
	check(state.capstone_first_experiment_observed(),"Actual first single change is observed.")
	host._select_cache(1,true)
	host._select_block_lines(1,true)
	measure(host)
	var expected_metrics: Dictionary = host.current_trace.metrics.duplicate(true)
	var expected_signature: String = host.current_trace.canonical_signature()
	var expected_source: String = host.applied_program_source
	check(expected_metrics.total_cycles == 138 and expected_metrics.hardware_cost == 4,
		"Early best is a real 138-cycle, cost-4 experiment.")
	for index: int in 36:
		host._select_block_lines(0,true)
		host.editor.set_block_signals(true)
		host.editor.text = Templates.COLUMN_FIRST + "\n# Later trial %d\n" % index
		host.editor.set_block_signals(false)
		host._on_program_changed()
		host._apply_program()
		measure(host)
		check(host.current_trace.passed and host.current_trace.metrics.total_cycles == 642,
			"Later distinct trial %d is actually correct and slower." % index)
	check(host.run_history.size() == 8,"Recent UI history remains bounded.")
	check(state.receipts_for(&"capstone").size() == 12,"Live receipts remain bounded.")
	check(state.game_observations.capstone.size() == 32,"Saved recipes remain bounded.")
	check(host._best_history_record().cycles == 138 and host._best_history_record().cost == 4,
		"Recent trials cannot erase the fastest cheaper design.")
	check(host._capstone_observed_options().any(func(row: Dictionary) -> bool: return row.cycles == 138 and row.cost == 4),
		"Capstone alternatives still include the retained best.")
	host._show_capstone_summary()
	check(host.level_completion_overlay.visible and host.level_completion_overlay.summary_label.text.contains("138"),
		"Capstone conclusion still uses the retained measurement after overflow.")
	host.level_completion_overlay.dismiss()
	host._save_level_workspace()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.game_snapshot()))
	host.queue_free()
	await settle()
	state.restore_game(saved,true)
	host = await new_host()
	check(host._best_history_record().cycles == 138 and state.receipts_for(&"capstone").size() <= 12,
		"JSON restart replays best while keeping the live bound.")
	host._select_cache(2,true)
	host._select_block_lines(2,true)
	var applied: String = host.applied_program_source
	var invalid: String = "# 未完成的草稿 · keep this\nacc =\n"
	host.editor.set_block_signals(true)
	host.editor.text = invalid
	host.editor.set_caret_line(1)
	host.editor.set_caret_column(4)
	host.editor.set_block_signals(false)
	host._on_program_changed()
	var before: Dictionary = host._current_design_draft()
	var completion_before: Dictionary = state.completed_levels().duplicate(true)
	var observations_before: Dictionary = state.game_observations.duplicate(true)
	check(not host.restore_best_button.disabled,"A malformed draft can still load a known valid design.")
	host.restore_best_button.pressed.emit()
	check(host.editor.text == expected_source and host.applied_program_source == expected_source,
		"Restore recovers the exact source, not a traversal template.")
	check(host.current_cache_lines == 1 and host.current_block_lines == 1 and host.current_pass_count == 2,
		"Restore recovers the whole configuration.")
	check(host.current_trace == null and not host.current_goal_met and not host.playback_completed and not host.pending_completion_review,
		"Restoration requires fresh execution and observation.")
	check(state.completed_levels() == completion_before and state.game_observations == observations_before,
		"Restoring a recipe grants no progression and records no new measurement.")
	check(state.workspace_for(&"capstone").applied_source == expected_source,"Restored draft uses ordinary workspace persistence.")
	host.restore_best_button.pressed.emit()
	check(host.best_restore_previous == before,"Loading an already loaded best cannot erase the return draft.")
	measure(host)
	check(host.current_trace.metrics == expected_metrics and host.current_trace.canonical_signature() == expected_signature,
		"Fresh execution reproduces the original authoritative metrics and full trace.")
	host.undo_restore_best_button.pressed.emit()
	check(host.editor.text == invalid and host.applied_program_source == applied,
		"Return recovers invalid raw text separately from the applied program.")
	check(host.current_cache_lines == 2 and host.current_block_lines == 2 and host.current_pass_count == 2,
		"Return restores all previous configuration values.")
	check(host.current_trace == null and host.program_dirty and host.official_run_button.disabled,
		"Returned invalid draft cannot reuse a result or run without correction.")
	check(state.workspace_for(&"capstone").draft_source == invalid,"Recovered unfinished text survives workspace save.")
	check(state.completed_levels() == completion_before,"Returning a draft leaves completion unchanged.")
	check(not host.undo_restore_best_button.visible,"Return action is bounded to the previous load.")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		# Workbench locale is established at construction, as in normal navigation.
		host.queue_free()
		await settle()
		host = await new_host()
		host._open_instrument(&"profiler",true)
		await settle()
		check(host.best_design_label.text.contains("138") and not host.restore_best_button.text.begins_with("chapter2."),
			"Retained-best controls are translated in "+locale)
		check(host.instrument_windows[&"profiler"].visible and host.restore_best_button.is_visible_in_tree(),
			"Best restoration is accessible in the Profiler "+locale)
		if "--locality-best-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var path: String = "user://locality-best-"+locale+".png"
			check(root.get_texture().get_image().save_png(path) == OK,"Save actual GPU best-design controls "+locale)
			print("CAPTURE: "+ProjectSettings.globalize_path(path))
	var game_before: Dictionary = state.game_snapshot()
	mode.set_mode(&"test")
	host._start_level(&"capstone")
	check(not host.restore_best_button.visible and host.best_restore_previous.is_empty(),
		"Game best and return draft do not leak into Test.")
	measure(host)
	check(host._best_history_record().cycles == 642,"Test retains its own real experiment.")
	host._select_cache(4,true)
	host.restore_best_button.pressed.emit()
	check(host.current_cache_lines == 1 and host.current_trace == null,"Test can restore its own best without copying Game.")
	host.undo_restore_best_button.pressed.emit()
	check(host.current_cache_lines == 4,"Test return recovers only the Test draft.")
	check(state.game_snapshot() == game_before,"Test measurements, restore and return leave Game snapshot unchanged.")
	var dialogue: Dictionary = Dialogue._recorded_result(self,"chapter_2/capstone")
	check(not dialogue.is_empty() and JSON.stringify(dialogue).contains("138"),
		"Permanent chapter reflection reads the Game best while Test is active.")
	mode.set_mode(&"game")
	host._start_level(&"capstone")
	# Simulate an unfinished capstone with a previously measured multi-change design.
	state.game_completed.erase(&"capstone")
	state.game_capstone_first_experiment_observed = false
	host.selected_judgment = &""
	host._update_best_design_controls()
	var locked_before: Dictionary = host._current_design_draft()
	host._restore_best_design()
	check(host._current_design_draft() == locked_before,"Direct activation respects the diagnosis gate.")
	host._select_judgment(&"repeated_far_fetch")
	var compound: Dictionary = state.best_observation_for(&"capstone",&"game").recipe.duplicate(true)
	compound.source = Templates.ROW_FIRST
	check(not host._best_restore_allowed(compound),"A restore cannot skip the first single-variable experiment.")
	check(not state.game_completed.has(&"capstone"),"Gate checks and restore do not award unfinished completion.")
	host.queue_free()
	await settle()
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"locality best restore %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
