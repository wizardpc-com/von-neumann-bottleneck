extends "res://tests/test_recovery_game_input.gd"
## Isolated controller scenarios, not a player-earned campaign. Each displayed
## result below comes from an actual simulation with the original task contracts.
const Overlap = preload("res://src/overlap_chapter/overlap_catalog.gd")

func shot(label: String) -> void:
	if "--recovery-capture" in OS.get_cmdline_user_args():
		await create_timer(6.0).timeout
		await capture(label)

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	change_scene_to_file("res://src/ui/main.tscn")
	await settle(12)
	var locality: Control = current_scene
	locality._start_level(&"capstone")
	locality._run_simulation("Official Test Set")
	locality._finish_playback()
	check(locality.current_trace.metrics.total_cycles == 642, "The capstone begins with its actual 642-cycle baseline.")
	locality._select_judgment(&"repeated_far_fetch")
	locality._select_cache(4, true)
	locality._run_simulation("Official Test Set")
	locality._finish_playback()
	locality._select_cache(1, true)
	locality._select_block_lines(1, true)
	locality._run_simulation("Official Test Set")
	locality._finish_playback()
	check(locality.current_trace.metrics.total_cycles == 138 and locality.current_trace.metrics.hardware_cost == 4, "The later software arrangement reaches 138 cycles at cost 4.")
	locality._show_capstone_summary()
	await settle()
	var summary: String = locality.level_completion_overlay.summary_label.text
	check(locality.level_completion_overlay.visible and summary.contains("642") and summary.contains("138"), "The visible summary retains measured baseline and selected recorded result.")
	check(summary.contains("recorded" if root.get_node("Localization").current_locale() == "en" else "已记录"), "The best-result claim explicitly stays within recorded arrangements.")
	check(root.get_visible_rect().encloses(locality.level_completion_overlay.panel.get_global_rect()), "The measured capstone summary fits the 720p viewport.")
	await shot("capstone-recorded-best")
	change_scene_to_file("res://src/overlap_chapter/overlap_chapter.tscn")
	await settle(12)
	var overlap: Control = current_scene
	overlap._open_level("buffers")
	await settle()
	var fixture: Dictionary = Overlap.reference_solution("buffers")
	overlap.board = fixture.board.duplicate(true)
	overlap._render_board(overlap.graph, overlap.board, false)
	overlap.editor.text = fixture.program
	overlap._run_official()
	await settle()
	check(overlap.trace.passed and overlap.trace.metrics.total_cycles == 28 and overlap.trace.metrics.overlap == 12, "The disclosed buffer fixture produces a real 28-cycle run with 12 overlapping cycles.")
	check(overlap.completion.visible and not overlap.completion.summary_label.text.contains("12"), "Static completion copy leaves the measured overlap number in the results and timeline.")
	check(root.get_visible_rect().encloses(overlap.completion.panel.get_global_rect()), "The buffer completion fits the 720p viewport.")
	await shot("buffers-completion")
	await finish()
