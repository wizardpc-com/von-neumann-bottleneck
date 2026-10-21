extends SceneTree
## 2026-10-20 UI convergence (team UI brief + Yi caret spec v0.3):
## one naming scheme (序章 → 第一章, 1-1 / 1-4-1), Yi's typed passages in the
## terminal, step card and completion card, the non-modal help card, workbench
## buttons (no standing Fullscreen/Feedback), the quit emphasis and the Yi
## text-speed setting. Real scenes and the real 60-task journey; no saved solutions.
const Naming = preload("res://src/campaign/journey_naming.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
const Palette = preload("res://src/lab/lab_palette.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	Typewriter.reset_seen()
	ProjectSettings.set_setting("game/reduced_motion", false)
	ProjectSettings.set_setting(Typewriter.SPEED_SETTING, "standard")
	var navigation: Node = root.get_node("TaskNavigation")

	# Naming: chapters and task numbers follow the journey, not catalog prefixes.
	var rows: Array[Dictionary] = navigation.journey_tasks()
	var numbering: Dictionary = Naming.numbers(rows)
	var labels: Dictionary = {}
	for row: Dictionary in rows: labels[str(row.key)] = Naming.task_label(row, numbering)
	check(labels.size() == 60, "Every journey task gets one label")
	check(labels["hardware_foundations/tutorial"] == "序章·接线教程", "Prologue tasks read 序章·名称 (got %s)" % labels["hardware_foundations/tutorial"])
	check(labels["hardware_foundations/latch"] == "序章·SR 锁存器", "Every prologue task carries the same prefix")
	check(labels["chapter_1/assembly"] == "1-1 三器相连", "Main tasks read 1-1 名称 (got %s)" % labels["chapter_1/assembly"])
	check(labels["chapter_1/bottleneck"] == "1-5 循时寻因", "Main tasks count in journey order")
	check(labels["chapter_1/read_once"] == "1-3-1 一取再用", "A side task takes its parent's number (got %s)" % labels["chapter_1/read_once"])
	check(labels["chapter_1/two_orders"].begins_with("1-5-1 "), "Side tasks hang off the main task they branch from")
	check(labels["representation/mixed_scan"] == "5-1 混合扫描", "Older inline numbers are replaced (got %s)" % labels["representation/mixed_scan"])
	check(labels["creation/C1_restore"] == "8-1 让例外抵达", "Creation tasks follow the same scheme (got %s)" % labels["creation/C1_restore"])
	var unique: Dictionary = {}
	for value: Variant in labels.values(): unique[value] = true
	check(unique.size() == 60, "No two tasks share a label")
	check(Naming.chapter_ordinal(0) == "序章" and Naming.chapter_ordinal(1) == "第一章" and Naming.chapter_ordinal(10) == "第十章", "Chapters read 序章 → 第一章 … 第十章")
	check(Naming.chapter_title(1, "02 时间的去处") == "第一章 · 时间的去处", "Old 01/02 numbering is dropped from chapter names")

	# Journey map uses the same names everywhere.
	var tree: Control = load("res://src/campaign/task_tree.tscn").instantiate()
	root.add_child(tree); await settle(12)
	var title_found: bool = false
	for label: Node in tree.find_children("*", "Label", true, false):
		if (label as Label).text == "旅程地图": title_found = true
	check(title_found, "The map is titled 旅程地图")
	var chip: Button = tree.find_child("JourneyRegion1", true, false)
	check(chip != null and chip.text.begins_with("第一章"), "Chapter chips lead with 第一章")
	var region_titles: Array[String] = []
	for index: int in tree.region_choice.item_count: region_titles.append(tree.region_choice.get_item_text(index))
	check("序章 · 一线成机" in region_titles and "第二章 · 少走远路" in region_titles, "Chapter choice lists 序章 · … and 第二章 · … " + str(region_titles))
	var mapped: Dictionary = {}
	for row: Dictionary in tree.rows: mapped[str(row.key)] = str(row.title)
	check(mapped.get("chapter_1/read_once", "") == "1-3-1 一取再用", "Map nodes use the numbered label")
	check(tree.find_child("MomentFeedbackButton", true, false) != null, "The map keeps its feedback entry (it is not a workbench)")
	tree.queue_free(); await settle()

	# Terminal: Yi's greeting is typed; the caret trails the passage, not a header.
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); await settle(12)
	var terminal: Control = hub.get_node("Laboratory/LabWorld/LayerDesk/LabTerminal")
	check(terminal.message.caret_rect() == Rect2(), "No caret while the terminal is on standby")
	terminal.wake(); await settle(2)
	check(terminal.message.is_playing() and terminal.message.shown < terminal.message.text.length(), "Waking types Yi's greeting")
	check(terminal.message.caret_visible(), "The trailing caret appears with the passage")
	var accept := InputEventAction.new(); accept.action = &"ui_accept"; accept.pressed = true
	terminal.primary.grab_focus(); await settle(1)
	root.push_input(accept); await settle(2)
	check(not terminal.message.is_playing() and terminal.message.shown == terminal.message.text.length(), "Enter while typing only completes the passage")
	check(terminal.is_inside_tree() and hub.get_node("Laboratory").visible, "Completing the passage does not also start the journey")
	var caret: Rect2 = terminal.message.caret_rect()
	check(caret.size.y >= 20.0 and caret.size.y <= 27.0, "Terminal body text uses the 24px caret " + str(caret.size))
	check(caret.end.x <= terminal.message.size.x + 0.5 and caret.position.y > 0.0, "The caret sits after the last line, inside the passage")
	var quit_button: Button = terminal.find_child("TerminalQuit", true, false)
	check(quit_button != null and quit_button.text == "退出游戏", "The terminal names the quit action 退出游戏")
	check(quit_button != null and quit_button.get_theme_color("font_color") == Palette.QUIT, "Quit is set apart in a muted red")
	var journey_button: Button = terminal.find_child("TerminalJourney", true, false)
	check(journey_button != null and journey_button.text == "旅程地图", "The terminal opens the 旅程地图")
	hub.queue_free(); await settle()

	# Settings: Yi's text speed persists; quit is emphasised; fullscreen stays here.
	var window_mode: Node = root.get_node("WindowMode")
	window_mode.set_yi_text_speed("fast")
	check(str(ProjectSettings.get_setting(Typewriter.SPEED_SETTING, "")) == "fast" and is_equal_approx(Typewriter.speed_setting(), 60.0), "Text speed setting applies")
	var saved := ConfigFile.new(); saved.load("user://presentation.cfg")
	check(str(saved.get_value("display", "yi_text_speed", "")) == "fast", "Text speed is stored with presentation settings")
	window_mode.set_yi_text_speed("standard")
	var settings: Control = load("res://src/ui/prototype_hub.gd").new()
	settings.settings_only = true
	root.add_child(settings); await settle(8)
	check(settings.find_child("YiTextSpeed", true, false) != null, "Settings offers Yi's text speed")
	check(settings.find_child("OptionsFullscreenButton", true, false) != null, "Fullscreen remains in Settings")
	check(settings.options_quit_button.get_theme_color("font_color") == Palette.QUIT, "Settings quit is emphasised")
	check(settings.find_child("MomentFeedbackButton", true, false) != null, "Settings keeps a feedback entry")
	settings.queue_free(); await settle()

	# Workbench: no standing Fullscreen/Feedback; Yi's help card is non-modal.
	root.get_node("GameMode").set_mode(&"game")
	navigation.from_tree = false
	var bench: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench); current_scene = bench; await settle(12)
	bench.call("_show_tutorial", true); await settle(12)
	var fullscreen: Control = bench.find_child("FullscreenButton", true, false)
	check(fullscreen == null or not fullscreen.visible, "The workbench header has no fullscreen button")
	check(bench.find_child("InLevelSettings", true, false) != null, "The workbench keeps its Settings button")
	var feedback: Control = bench.find_child("MomentFeedbackButton", true, false)
	check(feedback == null or not feedback.is_visible_in_tree(), "The workbench has no standing feedback button outside tester builds")
	check(bench.phase_label.text == "序章·接线教程", "The workbench header uses the journey name (got %s)" % bench.phase_label.text)
	var before: String = JSON.stringify(bench.call("_capture_workbench_snapshot"))
	bench.hint_button.pressed.emit(); await settle(3)
	var card: Control = bench.yi_help_card
	check(card != null and card.visible and not bench.hint_mode, "Hint opens Yi's help card without leaving the board")
	check(card != null and card.body.is_playing() and card.body.caret_visible(), "Yi's help is typed with the trailing caret")
	check(card != null and not card.get_rect().intersects(bench.tutorial_coach.get_rect()), "The help card does not cover the step card")
	check(bench.get_viewport().gui_get_focus_owner() == null or not card.is_ancestor_of(bench.get_viewport().gui_get_focus_owner()), "The help card does not take keyboard focus")
	check(JSON.stringify(bench.call("_capture_workbench_snapshot")) == before, "Opening help leaves the player's board unchanged")
	card.option_selected.emit(&"self"); await settle(2)
	check(card.visible and card.body.text == "好。需要时我在。" and not card.options_row.visible, "Declining help gets one short reply")
	await create_timer(2.3).timeout
	check(not card.visible and not card.body.caret_visible(), "The card closes itself after declining and its caret is gone")
	var f1 := InputEventKey.new(); f1.keycode = KEY_F1; f1.physical_keycode = KEY_F1; f1.pressed = true
	bench._input(f1); await settle(2)
	check(card.visible, "F1 asks Yi for help")
	card.option_selected.emit(&"more"); await settle(4)
	check(bench.hint_mode and not card.visible, "More specific enters the existing read-only hint canvas")
	bench.call("_exit_hint_workbench"); await settle(4)
	check(JSON.stringify(bench.call("_capture_workbench_snapshot")) == before, "Leaving the hint canvas restores the same board")

	# Step card: the instruction is immediate, only Yi's short reply is typed.
	bench.set("tutorial_created_wire", true)
	bench.call("_update_tutorial_goal"); await settle(2)
	var coach: Control = bench.tutorial_coach
	check(not coach.instruction.text.is_empty() and coach.instruction is Label, "Step instructions stay in an ordinary, immediate label")
	check(coach.praise.text == "接上了。" and coach.praise.caret_visible(), "Yi's step reply is typed with the caret")
	bench.queue_free(); await settle()

	# Completion: the system result is immediate; Yi's reply follows, layout fixed.
	var overlay: Control = load("res://src/ui/level_completion_overlay.gd").new()
	root.add_child(overlay); await settle(2)
	overlay.present(&"tutorial", "Old title", "电路已经接通。", "Old chapter", &"hardware_foundations")
	await settle(2)
	check(overlay.level_label.text == "序章·接线教程" and overlay.chapter_label.text == "序章 · 一线成机", "The card names the task like the map (%s / %s)" % [overlay.level_label.text, overlay.chapter_label.text])
	check(overlay.summary_label.text == "电路已经接通。", "The system result is shown at once")
	check(overlay.yi_response_label.shown == 0 and not overlay.yi_response_label.caret_visible(), "Yi waits until the result has settled")
	var height: float = overlay.panel.size.y
	await create_timer(0.6).timeout
	check(overlay.yi_response_label.is_playing(), "Yi's reply then types out")
	check(is_equal_approx(overlay.panel.size.y, height), "Typing does not resize the card")
	root.push_input(accept); await settle(2)
	check(overlay.visible and not overlay.yi_response_label.is_playing(), "Enter while Yi types completes the reply and keeps the card")
	check(overlay.find_child("YiCompletionSpeaker", true, false) == null and not overlay.yi_response_label.text.begins_with("壹"), "The completion response has no speaker badge or attribution prefix")
	overlay.dismiss()
	check(not overlay.yi_response_label.caret_visible(), "Closing the card removes its caret")
	overlay.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "ui convergence %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
