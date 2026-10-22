extends SceneTree
## Level guide convergence (2026-10-21 brief §3–§6): one voice at a time.
## The step guide is docked above the canvas, help replaces its instruction,
## the full briefing is a reading layer, the half-adder guide reads real runs,
## the opening defers to a visible Mission line and to blocking layers, and
## Chapter 2's "now" line follows the actual draft and official result.
## Controller and layout observations; not native input or player comprehension.
const Opening = preload("res://src/ui/yi_opening.gd")
const GuideStage = preload("res://src/ui/guide_stage.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
var failures: int = 0
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("TaskNavigation").from_tree = false
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		var en: bool = locale == "en"
		Typewriter.reset_seen()
		await hardware_checks(locale, en)
		await opening_checks(locale)
		await locality_checks(locale, en)
	print(("PASS: " if failures == 0 else "FAIL: ") + "guide convergence %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func hardware_checks(locale: String, en: bool) -> void:
	root.get_node("TaskNavigation").pending = ""
	var bench: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench); current_scene = bench; await settle(12)
	bench._show_tutorial(true); await settle(12)
	var coach: Control = bench.tutorial_coach
	check(coach != null and coach.is_visible_in_tree(), locale + ": NOT opens with the docked guide")
	check(coach.get_parent() == bench.mission_summary_button.get_parent() and not bench.graph_stack.is_ancestor_of(coach), locale + ": the guide is docked in the layout, not floating on the canvas")
	check(not coach.get_global_rect().intersects(bench.graph_stack.get_global_rect()), locale + ": the guide never covers the canvas")
	var footer_bottom: float = (bench.desktop_window_buttons[&"task"] as Control).get_global_rect().end.y
	check(footer_bottom <= bench.get_global_rect().end.y, locale + ": the footer stays inside the workbench with the guide docked (%.0f)" % footer_bottom)
	check(bench.guide_highlight != null and bench.guide_highlight.target == bench.component_nodes.get(&"A_IN"), locale + ": the first step points at input A")
	check(coach.instruction.caret_visible(), locale + ": the step guidance ends with Yi's caret")

	# Help replaces the instruction in the strip; nothing else speaks.
	bench.hint_button.pressed.emit(); await settle(4)
	var card: Control = bench.yi_help_card
	check(card != null and card.visible and coach.help_slot.is_ancestor_of(card), locale + ": help opens inside the guide")
	check(not coach.instruction.visible, locale + ": the step text steps aside while help speaks")
	check(not bench.guide_highlight.visible or bench.guide_highlight.modulate.a == 0.0, locale + ": the highlight is quiet while help speaks")
	check(card.get_global_rect().end.x <= coach.get_global_rect().end.x + 1.0, locale + ": help fits the guide width")

	# The full briefing is a reading layer: help closes, the guide folds.
	coach.find_child("CoachBriefing", true, false).pressed.emit(); await settle(4)
	check(bench.mission_briefing_active and (bench.desktop_windows[&"task"] as Control).visible, locale + ": the full briefing opens from the guide")
	check(not card.visible and coach.reading and not coach.instruction.visible, locale + ": reading the briefing closes help and folds the guide")
	# Asking for help while reading closes the reading layer first.
	bench.hint_button.pressed.emit(); await settle(4)
	check(not bench.mission_briefing_active and card.visible and coach.help_slot.is_ancestor_of(card), locale + ": help replaces the briefing instead of stacking on it")
	check(not (bench.desktop_windows[&"task"] as Control).visible, locale + ": with the guide docked, no second task window remains")
	card.close(); await settle(2)
	check(coach.instruction.visible and not coach.reading, locale + ": closing help restores the current step, not the opening")

	# Settings and completion block guidance.
	bench.level_completion_overlay.present(&"tutorial", "", "", "", &"hardware_foundations"); await settle(2)
	check(GuideStage.blocked(self), locale + ": a completion card blocks level guidance")
	bench.level_completion_overlay.dismiss(); await settle(2)
	check(not GuideStage.blocked(self), locale + ": closing the completion card releases guidance")

	# Half adder: the guide reads the actual circuit and runs.
	bench._start_campaign_level(&"half_adder", false); await settle(12)
	coach = bench.tutorial_coach
	check(coach.visible and coach.case_table.visible and coach.case_table.cases.size() == 4, locale + ": half adder shows its four-case spec in the guide")
	check(coach.instruction.text.contains("A=1") and coach.instruction.text.contains("SUM"), locale + ": the first instruction points at the spec, not at gates")
	check(bench.guide_highlight.target == bench.component_nodes.get(&"SUM_OUT"), locale + ": the level's centre, the first unwired output, is highlighted")
	var bench_window: Control = bench.desktop_windows[&"test_bench"]
	var parts_window: Control = bench.desktop_windows[&"components"]
	check(bench_window.position.x < 40.0 and bench_window.size.y > bench.graph_stack.size.y * 0.8, locale + ": Test Bench is the full-height left rail")
	check(parts_window.get_rect().end.x > bench.graph_stack.size.x - 40.0 and parts_window.size.x <= 340.0, locale + ": Components is a compact right rail (%s)" % str(parts_window.get_rect()))
	check(bench.official_case_labels[3].is_visible_in_tree() and bench_window.get_global_rect().encloses(bench.official_case_labels[3].get_global_rect()), locale + ": all four case rows are visible without scrolling")
	bench._on_connection_request(&"A_IN", 0, &"OR_1", 0)
	bench._on_connection_request(&"B_IN", 0, &"OR_1", 1)
	bench._on_connection_request(&"OR_1", 0, &"SUM_OUT", 0)
	bench._refresh_guided_coach(); await settle(2)
	check(coach.instruction.text.contains("CARRY") and coach.instruction.text.contains("SUM"), locale + ": a half-wired board names the output still missing (%s)" % coach.instruction.text)
	var carry_gate := &"AND_1_COPY_002"
	bench._on_connection_request(&"A_IN", 0, carry_gate, 0)
	bench._on_connection_request(&"B_IN", 0, carry_gate, 1)
	bench._on_connection_request(carry_gate, 0, &"CARRY_OUT", 0)
	bench._refresh_guided_coach(); await settle(2)
	check(coach.last_states.find(false) == 1 and bench.guide_highlight.target == bench.bench_debug_button, locale + ": a wired board points at the debug run")
	# A real debug run of A=1, B=1 on the OR-based SUM differs in SUM only.
	bench.input_a_button.button_pressed = true
	bench.input_b_button.button_pressed = true
	bench._run_debug(); await settle(2)
	bench._refresh_guided_coach(); await settle(2)
	var trace_sum: int = int(bool(bench.current_trace.outputs.get(&"SUM", false)))
	check(trace_sum == 1 and coach.instruction.text.contains("SUM") and coach.instruction.text.contains("0") and coach.instruction.text.contains("1"), locale + ": the mismatch names SUM with expected 0 and the actual run's 1 (%s)" % coach.instruction.text)
	check(coach.case_table._column_state(3) == -1, locale + ": the spec column for 1 1 is marked as differing")
	check(not coach.instruction.text.contains("AND") and not coach.instruction.text.contains("NOT") and not coach.instruction.text.contains("XOR"), locale + ": the guide never names a gate to use")
	# Changing the circuit drops evidence that described the old board.
	bench._on_disconnection_request(&"OR_1", 0, &"SUM_OUT", 0); await settle(2)
	check(bench.guided_case_evidence.is_empty() and coach.case_table._column_state(3) == 0, locale + ": editing the board clears stale case evidence")
	bench._on_connection_request(&"OR_1", 0, &"SUM_OUT", 0)
	# The official cases: the first real mismatch, located on its row.
	bench._run_official()
	var deadline: int = Time.get_ticks_msec() + 20000
	while bench.official_sequence_active and Time.get_ticks_msec() < deadline:
		if bench.playback_running: bench._finish_playback()
		await process_frame
	await settle(4)
	bench._refresh_guided_coach(); await settle(2)
	check(not bench.official_passed and coach.instruction.text.contains("4"), locale + ": the official failure is reported with its case (%s)" % coach.instruction.text)
	check(bench.guide_highlight.target == bench.official_case_labels[3], locale + ": the guide points at the failing row")
	check(not coach.step_label.text.is_empty() and coach.last_states[1], locale + ": an official run counts as having tried a case")
	bench.queue_free(); await settle()


func opening_checks(locale: String) -> void:
	Opening.dismiss(); Opening.reset_shown(); await settle(2)
	var host := Control.new(); host.size = Vector2(400, 400)
	root.add_child(host)
	var context: Control = load("res://src/ui/journey_context_card.gd").new()
	host.add_child(context)
	context.set_task(&"chapter_2", &"access_order", locale == "en")
	await settle(2)
	var opening: CanvasLayer = Opening.present(self, &"chapter_2", &"access_order", true)
	await settle(4)
	check(not is_instance_valid(opening) or opening.is_queued_for_deletion(), locale + ": a visible Mission line takes the opening's place (no second card)")
	host.queue_free(); await settle(2)
	opening = Opening.present(self, &"chapter_2", &"distant_reads", true)
	await settle(4)
	check(is_instance_valid(opening) and opening.card.get_global_rect().position.y < 200.0, locale + ": without a Mission line the opening sits near the top, clear of bottom controls")
	var overlay: Control = load("res://src/ui/level_completion_overlay.gd").new()
	root.add_child(overlay); await settle(2)
	overlay.present(&"tutorial", "", "", "", &"hardware_foundations"); await settle(4)
	check(not is_instance_valid(opening) or opening.is_queued_for_deletion(), locale + ": a blocking layer ends the opening; it is not replayed")
	overlay.queue_free(); Opening.dismiss(); await settle(2)


func locality_checks(locale: String, en: bool) -> void:
	root.get_node("TaskNavigation").pending = ""
	var main: Control = load("res://src/ui/main.tscn").instantiate()
	root.add_child(main); current_scene = main; await settle(12)
	main._start_level(&"access_order"); await settle(8)
	var header: Control = main.chapter_title_label.get_parent().get_parent().get_parent()
	check(header.get_global_rect().size.y <= 56.0, locale + ": Chapter 2's navigation is one light line (%.0f px)" % header.get_global_rect().size.y)
	check(main.playback_label.text == main._t(&"trace.playback.empty"), locale + ": entering a task does not claim the input changed")
	check(main.journey_context.live_action.is_empty(), locale + ": a fresh task shows its own now line")
	var original: String = main.editor.get_line(0)
	main.editor.set_line(0, original + " ")
	main._on_program_changed(); await settle(2)
	check(main.journey_context.live_action.contains("应用程序" if not en else "Apply Program"), locale + ": an unapplied draft replaces the now line with Apply first (%s)" % main.journey_context.live_action)
	check(main.journey_context.live_label.visible and not main.journey_context.action_label.visible and main.journey_context.live_label.caret_visible(), locale + ": state guidance is written in Yi's voice with the caret")
	main.editor.set_line(0, original)
	main._on_program_changed(); await settle(2)
	check(main.journey_context.live_action.is_empty(), locale + ": restoring the applied program restores the task's own line")
	main.queue_free(); await settle()
