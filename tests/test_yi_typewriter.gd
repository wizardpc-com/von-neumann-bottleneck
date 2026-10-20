extends SceneTree
## Yi's text output and trailing caret (规范 v0.3 §3, §8): the caret follows the
## last shown character through wrapping and explicit breaks, skipping only
## completes the passage, reread passages appear at once, reduced motion is
## complete, and closing leaves no caret behind. Layout is fixed up front.
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 4) -> void:
	for frame: int in frames: await process_frame

func make(width: float, font_size: int) -> Control:
	var host := Control.new(); host.size = Vector2(width, 400); root.add_child(host)
	var writer: Control = Typewriter.new()
	writer.font_size = font_size
	writer.position = Vector2.ZERO; writer.size = Vector2(width, 10)
	host.add_child(writer)
	return writer

func run() -> void:
	root.size = Vector2i(1280, 720)
	Typewriter.reset_seen()
	ProjectSettings.set_setting("game/reduced_motion", false)
	ProjectSettings.set_setting(Typewriter.SPEED_SETTING, "standard")
	var writer: Control = make(300.0, 17)
	await settle()
	var passage: String = "我们从一盏灯开始。\n把线路接上，再看看输入变化时会发生什么。"
	writer.play(passage)
	check(writer.is_playing() and writer.shown == 0, "A new passage starts from its first character")
	var full_height: float = writer.get_combined_minimum_size().y
	check(full_height > 0.0, "The full passage is laid out before any character appears")
	writer.shown = 5; writer.queue_redraw()
	var at_five: Rect2 = writer.caret_rect()
	writer.shown = 6
	var at_six: Rect2 = writer.caret_rect()
	check(at_six.position.x > at_five.position.x and is_equal_approx(at_six.position.y, at_five.position.y),
		"The caret moves right with the next character on the same line")
	check(is_equal_approx(writer.get_combined_minimum_size().y, full_height), "Revealing characters does not change the card height")
	var break_at: int = passage.find("\n") + 1
	writer.shown = break_at - 1
	var before_break: Rect2 = writer.caret_rect()
	writer.shown = break_at
	var after_break: Rect2 = writer.caret_rect()
	check(after_break.position.y > before_break.position.y and after_break.position.x < before_break.position.x,
		"After an explicit line break the caret starts the next line")
	writer.shown = passage.length()
	var at_end: Rect2 = writer.caret_rect()
	check(at_end.position.y > after_break.position.y, "A wrapped second paragraph places the caret on its actual last line")
	check(at_end.end.x <= writer.size.x + 0.5, "The caret never extends past the passage width")
	check(at_end.size.y >= 12.0 and at_end.size.y <= 27.0 and is_equal_approx(at_end.size.x * 2.0, at_end.size.y),
		"Body text uses the 1:2 caret near the text line height " + str(at_end.size))
	writer.shown = 0
	await create_timer(0.3).timeout
	check(writer.shown > 3 and writer.shown < passage.length(), "Output runs quickly but not instantly (%d)" % writer.shown)
	var completed: Array[bool] = []
	writer.finished.connect(func() -> void: completed.append(true))
	check(writer.complete_now(), "A skip completes the passage still appearing")
	check(writer.shown == passage.length() and not writer.is_playing(), "Skipping shows the whole passage")
	check(completed.size() == 1, "Completion is announced once")
	check(not writer.complete_now(), "A second skip is not consumed by the passage")
	check(writer.caret_rect() == at_end, "After skipping the caret sits at the end of the passage")

	# Clicking while text appears only completes it; the click is consumed.
	writer.play("另一段新的话，用来检查点击只补完文字。")
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
	writer._gui_input(click)
	check(not writer.is_playing() and writer.shown == writer.text.length(), "A click on the passage completes it")

	# Rereading a passage already shown in full appears at once.
	writer.play(passage)
	check(not writer.is_playing() and writer.shown == passage.length(), "A passage already read appears immediately")
	writer.play(passage, true)
	check(writer.is_playing(), "Replay can be requested explicitly")

	# Keyboard skip only applies inside the chosen focus scope.
	var scope := Button.new(); root.add_child(scope); scope.grab_focus()
	writer.skip_scope = scope
	writer.play("键盘跳过只补完文字。", true)
	await settle(1)
	var accept := InputEventAction.new(); accept.action = &"ui_accept"; accept.pressed = true
	writer._input(accept)
	check(not writer.is_playing(), "Enter inside the scope completes the passage")
	scope.queue_free()

	# English and mixed scripts keep whole characters.
	writer.play("Hello. I am Yi. We begin with one lamp — 一盏灯.", true)
	writer.shown = 9
	check(writer.shown_text() == "Hello. I ", "English output counts visible characters")

	# Reduced motion: complete text, steady caret, no running output.
	writer.set_reduced_motion(true)
	writer.play("减少动效时全文立即出现。", true)
	check(not writer.is_playing() and writer.shown == writer.text.length(), "Reduced motion shows the passage at once")
	check(not writer.is_processing(), "Reduced motion runs no blink or output timer")
	writer.reduced_motion_override = -1

	# Instant speed setting.
	ProjectSettings.set_setting(Typewriter.SPEED_SETTING, "instant")
	writer.play("立即显示。", true)
	check(not writer.is_playing(), "The instant speed setting skips output")
	ProjectSettings.set_setting(Typewriter.SPEED_SETTING, "standard")

	# Closing removes the caret and its timer.
	writer.play("关闭时光标收起。", true)
	writer.stop()
	check(writer.caret_rect() == Rect2() and not writer.is_processing(), "Stopping hides the caret and stops output")
	writer.play("隐藏时不计时。", true)
	writer.get_parent().hide(); await settle(1)
	check(not writer.is_processing(), "A hidden passage runs no timer")
	writer.get_parent().show(); await settle(1)
	check(writer.is_processing(), "Showing it again resumes")

	# Larger text picks the larger caret and narrower widths wrap more lines.
	var large: Control = make(240.0, 26)
	await settle()
	large.play("较大字号的正文也要跟随实际行末。", true)
	large.shown = large.text.length()
	var big: Rect2 = large.caret_rect()
	check(big.size.y > 27.0, "Large text uses the 32px caret " + str(big.size))
	check(big.position.y > 0.0, "Narrow large text wraps and the caret follows the last line")
	check(big.end.x <= large.size.x + 0.5, "The large caret stays inside the passage")
	print(("PASS: " if failures == 0 else "FAIL: ") + "yi typewriter %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
