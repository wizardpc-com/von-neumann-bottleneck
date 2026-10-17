extends VBoxContainer
## A replay of an earned construction, never a circuit signal or an award.

const DURATION: float = 3.0

class PathCanvas extends Control:
	var progress: float = 0.0
	var illustration: Texture2D

	func _draw() -> void:
		if illustration != null and illustration.get_width() > 0 and illustration.get_height() > 0:
			var ratio: float = minf(size.x / illustration.get_width(), size.y / illustration.get_height())
			var image_size: Vector2 = illustration.get_size() * ratio
			draw_texture_rect(illustration, Rect2((size - image_size) * 0.5, image_size), false)
			return
		var points := PackedVector2Array([
			Vector2(size.x / 6.0, size.y * 0.5),
			Vector2(size.x * 0.5, size.y * 0.5),
			Vector2(size.x * 5.0 / 6.0, size.y * 0.5),
		])
		draw_polyline(points, Color("56747c"), 3.0, true)
		for point: Vector2 in points:
			draw_circle(point, 17.0, Color("152c38"))
			draw_arc(point, 17.0, 0.0, TAU, 40, Color("a3d7d6"), 2.0, true)
		# The output remains dark even when the retrospective path is complete.
		draw_circle(points[2], 9.0, Color("07131e"))
		var cursor: Vector2 = points[0].lerp(points[2], progress)
		draw_circle(cursor + Vector2(0, -28), 5.0, Color("e4d6a2"))

var english: bool = false
var earned: Callable
var preview_texture: Texture2D
var elapsed: float = 0.0
var playing: bool = false
var has_started: bool = false
var canvas: PathCanvas
var scene_body: VBoxContainer
var caption: Label
var play_button: Button
var skip_button: Button


func configure(use_english: bool, can_replay: Callable) -> void:
	english = use_english
	earned = can_replay


func _ready() -> void:
	name = "FirstLight"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = _copy("第一束光 · 可选虚构回顾", "First light · optional fictional retrospective")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	var note := Label.new()
	note.text = _copy("固定NOT示意回顾，不是当前电路截图；不授予新成果或补写日期。", "A fixed NOT illustration, not your current circuit capture; no new award or completion date.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 16)
	add_child(note)
	play_button = Button.new()
	play_button.text = _copy("播放约3秒回顾", "Play a 3-second retrospective")
	play_button.custom_minimum_size.y = 42
	play_button.pressed.connect(play)
	add_child(play_button)
	scene_body = VBoxContainer.new()
	scene_body.add_theme_constant_override("separation", 10)
	add_child(scene_body)
	canvas = PathCanvas.new()
	canvas.custom_minimum_size.y = 100
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_body.add_child(canvas)
	var terminals := HBoxContainer.new()
	scene_body.add_child(terminals)
	for text: String in [_copy("输入 1", "Input 1"), "NOT", _copy("输出 0 · 灯灭", "Output 0 · lamp off")]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 16)
		terminals.add_child(label)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 16)
	scene_body.add_child(caption)
	skip_button = Button.new()
	skip_button.text = _copy("跳到静态尾帧", "Skip to the static ending")
	skip_button.custom_minimum_size.y = 42
	skip_button.pressed.connect(skip)
	scene_body.add_child(skip_button)
	scene_body.hide()
	visible = _is_earned()


func _process(delta: float) -> void:
	var allowed: bool = _is_earned()
	if not allowed:
		hide()
		playing = false
		return
	if not playing: return
	if playback_paused(): return
	if bool(ProjectSettings.get_setting("game/reduced_motion", false)):
		skip()
		return
	elapsed = minf(DURATION, elapsed + delta)
	playing = elapsed < DURATION
	_refresh_scene()


func play() -> void:
	# Recheck the original authority at the moment of playback, including test mode.
	if not _is_earned() or not is_visible_in_tree() or _feedback_visible(): return
	has_started = true
	elapsed = 0.0
	playing = true
	scene_body.show()
	play_button.text = _copy("重播回顾", "Replay retrospective")
	if bool(ProjectSettings.get_setting("game/reduced_motion", false)):
		skip()
	else:
		_refresh_scene()


func skip() -> void:
	if not has_started: return
	elapsed = DURATION
	playing = false
	_refresh_scene()


func playback_paused() -> bool:
	return not is_visible_in_tree() or not get_window().has_focus() or _feedback_visible()


func _feedback_visible() -> bool:
	var playtest: Node = get_node_or_null("/root/PlaytestData")
	return playtest != null and bool(playtest.get("_feedback_visible"))


func _is_earned() -> bool:
	return earned.is_valid() and bool(earned.call())


func _refresh_scene() -> void:
	canvas.progress = elapsed / DURATION
	canvas.illustration = preview_texture
	canvas.queue_redraw()
	var lines: Array[String] = [_copy("你亲手搭起了一条可以检查的路径。", "You built a path that can be checked.")]
	if elapsed >= 1.0:
		lines.append(_copy("NOT：输入1 → 输出0。灯灭也可以是正确答案。", "NOT: input 1 → output 0. A dark lamp can be the correct answer."))
	if elapsed >= 2.0:
		lines.append(_copy("光点只回顾已完成的搭建，不表示电流、能耗或文明测量。", "The light revisits an earned construction; it is not current, energy use or a measurement of civilization."))
	caption.text = "\n".join(lines)


func _copy(zh: String, en: String) -> String:
	return en if english else zh


func _exit_tree() -> void:
	playing = false
