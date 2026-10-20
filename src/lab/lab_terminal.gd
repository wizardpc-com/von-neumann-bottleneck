extends Control
## The terminal screen inside the laboratory. It is the game's main menu: one
## clear next action, Yi's short message, and a small row of other functions.

signal action(id: String)

const Palette = preload("res://src/lab/lab_palette.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")

var english: bool = false
var response: Dictionary = {}
var state: Dictionary = {}
var _asleep: bool = true
var sleep_view: VBoxContainer
var awake_view: VBoxContainer
## Yi's passage: typed out with the trailing caret. System facts (progress,
## buttons, the header) stay in ordinary labels and appear at once.
var message: Typewriter
var _passage: String = ""
var primary: Button
var secondary: HBoxContainer
var archive_button: Button
var progress_label: Label
var cursor: Label
var header_label: Label
var language_button: Button
var sleep_hint: Label
var _time: float = 0.0
## Leaving the game is asked on this screen (Quit or Esc in the laboratory).
var quit_view: VBoxContainer
var quit_title: Label
var quit_note: Label
var quit_yes: Button
var quit_no: Button
var _confirming: bool = false
var echo: Label
var choices: HBoxContainer
var _dialogue: Array = []
var _beat: int = -1

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	theme = Theme.new()
	theme.default_font_size = 16
	_build()

func asleep() -> bool:
	return _asleep

func configure(values: Dictionary) -> void:
	state = values
	english = bool(values.get("english", false))
	response = values.get("response", {})
	if message != null: _compose()

func set_fragment_count(opened: int, unread: int) -> void:
	if archive_button == null: return
	archive_button.text = ("档案 %d" if not english else "Archive %d") % opened
	if unread > 0: archive_button.text += " ·" + ("新" if not english else "new")

func _build() -> void:
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 22)
	margin.add_theme_constant_override("margin_top", 16); margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	var stack := Control.new(); stack.mouse_filter = Control.MOUSE_FILTER_PASS; margin.add_child(stack)
	sleep_view = VBoxContainer.new(); sleep_view.name = "TerminalSleep"
	sleep_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sleep_view.alignment = BoxContainer.ALIGNMENT_CENTER
	sleep_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(sleep_view)
	# Standby is a power light, not Yi's text caret (that one only follows Yi's words).
	cursor = _label(sleep_view, "●", 14, Palette.ACCENT)
	cursor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sleep_hint = _label(sleep_view, "", 15, Palette.TERM_MUTED); sleep_hint.name = "SleepHint"
	sleep_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	awake_view = VBoxContainer.new(); awake_view.name = "TerminalAwake"
	awake_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	awake_view.add_theme_constant_override("separation", 9)
	awake_view.hide(); stack.add_child(awake_view)
	var header := HBoxContainer.new(); awake_view.add_child(header)
	header_label = _label(header, "", 13, Palette.TERM_MUTED); header_label.name = "TerminalHeader"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress_label = _label(header, "", 13, Palette.TERM_MUTED)
	progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	language_button = _button(header, "EN", "language", false); language_button.name = "TerminalLanguage"
	language_button.custom_minimum_size = Vector2(44, 24); language_button.add_theme_font_size_override("font_size", 12)
	var rule := ColorRect.new(); rule.color = Palette.with_alpha(Palette.TERM_EDGE, 0.9); rule.custom_minimum_size.y = 1
	awake_view.add_child(rule)
	# In a conversation, the player's chosen reply is echoed above Yi's answer.
	echo = _label(awake_view, "", 14, Palette.TERM_MUTED); echo.name = "PlayerReply"
	echo.hide()
	message = Typewriter.new(); message.name = "YiMessage"
	message.font_size = 17; message.font_color = Palette.TERM_TEXT; message.line_spacing = 5.0
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message.skip_scope = self
	awake_view.add_child(message)
	primary = _button(awake_view, "", "start", true); primary.name = "TerminalPrimary"
	primary.custom_minimum_size.y = 44; primary.add_theme_font_size_override("font_size", 17)
	secondary = HBoxContainer.new(); secondary.add_theme_constant_override("separation", 6)
	awake_view.add_child(secondary)
	var labels: Array = [["旅程地图", "Journey map", "journey"], ["档案", "Archive", "archive"], ["手册", "Handbook", "handbook"], ["设置", "Settings", "settings"], ["退出游戏", "Quit", "quit"]]
	for entry: Array in labels:
		var button := _button(secondary, "", str(entry[2]), false)
		button.name = "Terminal" + str(entry[2]).capitalize()
		button.set_meta("zh", entry[0]); button.set_meta("en", entry[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 32
		button.add_theme_font_size_override("font_size", 14)
		if str(entry[2]) == "archive": archive_button = button
		if str(entry[2]) == "quit": _style_quit(button)
	choices = HBoxContainer.new(); choices.name = "DialogueChoices"
	choices.add_theme_constant_override("separation", 8)
	choices.hide(); awake_view.add_child(choices)
	_build_quit_view(stack)
	_compose()

## Chapter-ending conversation (candidate copy in chapter_dialogues.gd):
## Yi speaks, the player picks a reply, Yi answers; the last beat is a hook.
## The normal menu returns when it ends. Nothing here changes progress.
func play_dialogue(beats: Array) -> void:
	if beats.is_empty(): return
	_dialogue = beats
	_beat = -1
	primary.hide(); secondary.hide(); choices.show()
	_next_beat()

func in_dialogue() -> bool:
	return not _dialogue.is_empty()

func _line(entry: Dictionary, key: String) -> String:
	return str(entry.get(key + ("_en" if english else "_zh"), entry.get("en" if english else "zh", "")))

func _next_beat() -> void:
	_beat += 1
	if _beat >= _dialogue.size():
		_end_dialogue(); return
	var beat: Dictionary = _dialogue[_beat]
	echo.hide()
	_say_then(str(beat.en if english else beat.zh), beat.get("replies", []))

func _say_then(passage: String, replies: Array) -> void:
	_passage = passage
	_set_choices([])
	message.play(_passage)
	var reveal := func() -> void:
		if replies.is_empty():
			var last: bool = _beat >= _dialogue.size() - 1
			_set_choices([{"text": ("回到终端" if not english else "Back to the terminal") if last else ("继续 ›" if not english else "Continue ›"), "next": true}])
		else:
			var options: Array = []
			for reply: Dictionary in replies: options.append({"text": str(reply.en if english else reply.zh), "reply": reply})
			_set_choices(options)
	if message.is_playing(): message.finished.connect(reveal, CONNECT_ONE_SHOT)
	else: reveal.call()

func _set_choices(options: Array) -> void:
	for child: Node in choices.get_children(): child.queue_free()
	var first: Button = null
	for option: Dictionary in options:
		var button := Button.new(); button.text = str(option.text)
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 40
		button.add_theme_font_size_override("font_size", 15)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_choice(button)
		if option.has("reply"):
			var reply: Dictionary = option.reply
			button.pressed.connect(func() -> void:
				echo.text = ("你：" if not english else "You: ") + str(reply.en if english else reply.zh)
				echo.show()
				_say_then(_line(reply, "answer"), []))
		else:
			button.pressed.connect(_next_beat)
		choices.add_child(button)
		if first == null: first = button
	if first != null: first.call_deferred("grab_focus")

func _end_dialogue() -> void:
	_dialogue = []
	_beat = -1
	echo.hide(); choices.hide()
	primary.show(); secondary.show()
	response = {}
	_compose()
	_focus_primary()

func _style_choice(node: Button) -> void:
	for pair: Array in [["normal", Palette.TERM_PANEL, Palette.ACCENT_DEEP], ["hover", Palette.TERM_SCREEN_LIFT, Palette.ACCENT], ["pressed", Palette.TERM_SCREEN, Palette.ACCENT], ["focus", Color.TRANSPARENT, Palette.ACCENT]]:
		var box := StyleBoxFlat.new()
		box.bg_color = pair[1]; box.border_color = pair[2]
		box.set_border_width_all(2 if str(pair[0]) == "focus" else 1); box.border_width_left = 3
		box.set_corner_radius_all(6); box.draw_center = str(pair[0]) != "focus"
		box.content_margin_left = 12; box.content_margin_right = 10
		node.add_theme_stylebox_override(str(pair[0]), box)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(color_name, Palette.TERM_TEXT)
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _build_quit_view(stack: Control) -> void:
	quit_view = VBoxContainer.new(); quit_view.name = "TerminalQuitConfirm"
	quit_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quit_view.alignment = BoxContainer.ALIGNMENT_CENTER
	quit_view.add_theme_constant_override("separation", 12)
	quit_view.hide(); stack.add_child(quit_view)
	quit_title = _label(quit_view, "", 22, Palette.TERM_TEXT); quit_title.name = "QuitTitle"
	quit_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quit_note = _label(quit_view, "", 15, Palette.TERM_MUTED); quit_note.name = "QuitNote"
	quit_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gap := Control.new(); gap.custom_minimum_size.y = 6; quit_view.add_child(gap)
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12); quit_view.add_child(row)
	quit_yes = _button(row, "", "quit_confirmed", false); quit_yes.name = "QuitYes"
	_style_quit(quit_yes)
	quit_no = _button(row, "", "quit_cancel", false); quit_no.name = "QuitNo"
	for button: Button in [quit_yes, quit_no]:
		button.custom_minimum_size = Vector2(170, 42); button.add_theme_font_size_override("font_size", 16)
	quit_yes.focus_neighbor_right = quit_yes.get_path_to(quit_no); quit_no.focus_neighbor_left = quit_no.get_path_to(quit_yes)

## Show the quit question on the screen, waking it if needed.
func ask_quit() -> void:
	_confirming = true
	_asleep = false
	var zh: bool = not english
	quit_title.text = "要退出游戏吗？" if zh else "Quit the game?"
	quit_note.text = "退出前会保存进度。按 Esc 回到实验室。" if zh else "Progress is saved before quitting. Esc returns to the laboratory."
	quit_yes.text = "是，退出" if zh else "Yes, quit"
	quit_no.text = "否，留下" if zh else "No, stay"
	sleep_view.hide(); awake_view.hide(); quit_view.show()
	quit_view.modulate.a = 1.0
	quit_yes.call_deferred("grab_focus")

func cancel_quit() -> void:
	if not _confirming: return
	_confirming = false
	quit_view.hide(); awake_view.show()
	if not message.caret_visible(): message.play(_passage)
	_focus_primary()

func confirming() -> bool:
	return _confirming

func _compose() -> void:
	_passage = ""
	_compose_text()
	# Yi speaks only while awake; on standby the passage waits for wake().
	if _asleep:
		message.prepare(_passage)
	elif message.text != _passage or not message.caret_visible():
		message.play(_passage)

func _compose_text() -> void:
	var zh: bool = not english
	sleep_hint.text = "壹 · 学习程序 · 待机\n点击屏幕，或按 Enter" if zh else "Yi · learning program · standby\nClick the screen or press Enter"
	header_label.text = "壹 · 学习程序" if zh else "Yi · learning program"
	language_button.text = "EN" if zh else "中文"
	progress_label.text = ("%d / %d" % [int(state.get("completed", 0)), int(state.get("total", 0))]) if int(state.get("total", 0)) > 0 else ""
	for button: Node in secondary.get_children():
		(button as Button).text = str(button.get_meta("en" if english else "zh"))
	set_fragment_count(int(state.get("fragments", 0)), 0)
	var navigation: Node = get_node_or_null("/root/TaskNavigation")
	var next_title: String = str(navigation.next_task_title()) if navigation != null else ""
	if bool(state.get("new_player", true)):
		_passage = "你好，我是壹。\n这台终端里有一套学习程序，留给愿意亲手弄明白计算的人。\n我们从一盏灯开始。" if zh else "Hello. I am Yi.\nThis terminal holds a learning program, left for anyone who wants to understand computing with their own hands.\nWe begin with one lamp."
		primary.text = "开始 · 接通第一条线路" if zh else "Begin · connect the first line"
		return
	var target_title: String = str(state.get("next_title", ""))
	if not target_title.is_empty() and str(state.get("next_key", "")) != str(navigation.next_task_key() if navigation != null else ""):
		primary.text = ("继续 · " if zh else "Continue · ") + _shorten(target_title, 18)
		next_title = target_title
	else:
		primary.text = (str(navigation.home_action_text()) if navigation != null else ("继续" if zh else "Continue"))
		if not next_title.is_empty(): primary.text += " · " + _shorten(next_title, 18)
	if not response.is_empty():
		var task: Dictionary = response.get("task", {})
		var title: String = str(task.get("title", ""))
		if bool(response.get("first_light", false)):
			_passage = "灯亮过，也灭过。两次都是对的。\n那条线是你接上的，不是我替你算出来的。\n档案架上多了一页，想看的时候可以去看。" if zh else "The lamp lit, and went dark. Both were correct.\nYou connected that line; I did not compute it for you.\nThere is a new page on the archive shelf when you want it."
			return
		if response.has("chapter"):
			_passage = str(response.chapter.en if english else response.chapter.zh)
			if int(response.get("fragments", 0)) > 0:
				_passage += "\n" + ("档案架上多了一页记录。" if zh else "A new record waits on the archive shelf.")
			return
		var lines_zh: Array[String] = ["「%s」完成了。\n这次结果来自你刚才搭起的结构，不是我的保佑。", "「%s」通过了。\n你可以回去再改它，也可以继续往前走。", "记下了：「%s」。\n下一步，通常比这一步多一个条件。"]
		var lines_en: Array[String] = ["\"%s\" is complete.\nThat result came from the structure you just built, not from my blessing.", "\"%s\" passes.\nYou can go back and refine it, or keep going.", "Recorded: \"%s\".\nThe next step usually adds one more condition."]
		var pick: int = absi(title.hash()) % lines_zh.size()
		_passage = (lines_en[pick] if english else lines_zh[pick]) % _shorten(title, 16)
		if int(response.get("fragments", 0)) > 0:
			_passage += "\n" + ("档案架上多了一页记录。" if zh else "A new record waits on the archive shelf.")
		return
	_passage = ("欢迎回来。\n下一项是「%s」。" if zh else "Welcome back.\nNext up: \"%s\".") % _shorten(next_title, 18)

func wake(instant: bool = false) -> void:
	if not _asleep:
		if not in_dialogue(): _focus_primary()
		return
	_asleep = false
	sleep_view.hide(); awake_view.show()
	if not instant and not bool(ProjectSettings.get_setting("game/reduced_motion", false)):
		awake_view.modulate.a = 0.0
		create_tween().tween_property(awake_view, "modulate:a", 1.0, 0.25)
	else:
		awake_view.modulate.a = 1.0
	# A chapter ending is answered with a short conversation, once.
	var beats: Array = response.get("dialogue", [])
	if not beats.is_empty():
		response.erase("dialogue")
		play_dialogue(beats)
		return
	message.play(_passage)
	_focus_primary()

func release_focus_inside() -> void:
	var owner_control: Control = get_viewport().gui_get_focus_owner()
	if owner_control != null and is_ancestor_of(owner_control): owner_control.release_focus()

func _focus_primary() -> void:
	if in_dialogue():
		if choices.get_child_count() > 0: (choices.get_child(0) as Control).call_deferred("grab_focus")
		return
	if primary != null and primary.is_visible_in_tree(): primary.call_deferred("grab_focus")

func _process(delta: float) -> void:
	_time += delta
	if cursor != null and _asleep:
		cursor.modulate.a = 0.75 if bool(ProjectSettings.get_setting("game/reduced_motion", false)) else 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * 3.2))

func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		if _confirming: return
		if _asleep: wake(); accept_event()
		elif message.complete_now(): accept_event()

func _style_quit(node: Button) -> void:
	# Leaving the game reads clearly apart from the other functions.
	for pair: Array in [["normal", Palette.QUIT_DEEP, Palette.with_alpha(Palette.QUIT, 0.7)], ["hover", Palette.QUIT_DEEP.lightened(0.08), Palette.QUIT], ["pressed", Palette.QUIT_DEEP.darkened(0.2), Palette.QUIT]]:
		var box: StyleBoxFlat = (node.get_theme_stylebox(str(pair[0])) as StyleBoxFlat).duplicate()
		box.bg_color = pair[1]; box.border_color = pair[2]
		node.add_theme_stylebox_override(str(pair[0]), box)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(color_name, Palette.QUIT)

func _shorten(text: String, limit: int) -> String:
	var clean: String = text.get_slice(" · ", 0) if text.length() > limit and text.find(" · ") > 0 else text
	return clean if clean.length() <= limit else clean.substr(0, limit - 1) + "…"

func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var node := Label.new(); node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func _button(parent: Node, text: String, id: String, strong: bool) -> Button:
	var node := Button.new(); node.text = text
	node.focus_mode = Control.FOCUS_ALL
	var fill: Color = Palette.ACCENT if strong else Palette.TERM_PANEL
	var edge: Color = Palette.ACCENT if strong else Palette.TERM_EDGE
	for pair: Array in [["normal", fill, edge], ["hover", fill.lightened(0.12) if strong else Palette.TERM_SCREEN_LIFT, Palette.ACCENT], ["pressed", fill.darkened(0.12), Palette.ACCENT], ["focus", Color.TRANSPARENT, Palette.ACCENT]]:
		var box := StyleBoxFlat.new()
		box.bg_color = pair[1]; box.border_color = pair[2]
		box.set_border_width_all(1 if str(pair[0]) != "focus" else 2)
		box.set_corner_radius_all(8 if strong else 6)
		box.content_margin_left = 10; box.content_margin_right = 10
		box.draw_center = str(pair[0]) != "focus"
		node.add_theme_stylebox_override(str(pair[0]), box)
	var ink: Color = Palette.TERM_SCREEN if strong else Palette.TERM_TEXT
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(color_name, ink)
	node.pressed.connect(func() -> void:
		if id == "quit_cancel": cancel_quit()
		else: action.emit(id))
	parent.add_child(node)
	return node
