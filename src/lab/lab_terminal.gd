extends Control
## The terminal screen inside the laboratory. It is the game's main menu: one
## clear next action, Yi's short message, and a small row of other functions.

signal action(id: String)

const Palette = preload("res://src/lab/lab_palette.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
const Naming = preload("res://src/campaign/journey_naming.gd")

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
var mode_picker: VBoxContainer
var game_mode_button: Button
var test_mode_button: Button
var mode_note: Label
var secondary: HFlowContainer
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
var dialogue_skip: Button
var _dialogue: Array = []
var _beat: int = -1
var _reply: Dictionary = {}
var _reveal_choices: Callable

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
	state["fragments"] = opened
	state["fragments_unread"] = unread
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
	dialogue_skip = _button(header, "", "dialogue_skip", false)
	dialogue_skip.name = "DialogueSkip"
	dialogue_skip.add_theme_font_size_override("font_size", 12)
	dialogue_skip.hide()
	language_button = _button(header, "EN", "language", false); language_button.name = "TerminalLanguage"
	language_button.custom_minimum_size = Vector2(44, 24); language_button.add_theme_font_size_override("font_size", 12)
	var rule := ColorRect.new(); rule.color = Palette.with_alpha(Palette.TERM_EDGE, 0.9); rule.custom_minimum_size.y = 1
	awake_view.add_child(rule)
	# In a conversation, the player's chosen reply is echoed above Yi's answer.
	echo = _label(awake_view, "", 14, Palette.TERM_MUTED); echo.name = "PlayerReply"
	echo.hide()
	message = Typewriter.new(); message.name = "YiMessage"
	message.font_size = 17; message.font_color = Palette.TERM_TEXT; message.line_spacing = 5.0
	message.custom_minimum_size.y = 96
	message.skip_scope = self
	awake_view.add_child(message)
	var breath := Control.new(); breath.custom_minimum_size.y = 10; breath.mouse_filter = Control.MOUSE_FILTER_IGNORE
	awake_view.add_child(breath)
	# What to do next is one card under Yi's words, not a slab across the screen.
	var actions := HBoxContainer.new(); actions.name = "TerminalActions"
	actions.add_theme_constant_override("separation", 20)
	awake_view.add_child(actions)
	primary = _button(actions, "", "start", true); primary.name = "TerminalPrimary"
	_style_task_card(primary)
	mode_picker = VBoxContainer.new(); mode_picker.name = "TerminalModePicker"
	mode_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_picker.add_theme_constant_override("separation", 6)
	actions.add_child(mode_picker)
	var mode_buttons := HBoxContainer.new(); mode_buttons.add_theme_constant_override("separation", 6)
	mode_picker.add_child(mode_buttons)
	var mode_group := ButtonGroup.new()
	game_mode_button = _button(mode_buttons, "", "mode_game", false); game_mode_button.name = "TerminalGameMode"
	test_mode_button = _button(mode_buttons, "", "mode_test", false); test_mode_button.name = "TerminalTestMode"
	for button: Button in [game_mode_button, test_mode_button]:
		button.toggle_mode = true; button.button_group = mode_group
		button.custom_minimum_size.y = 34
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
	mode_note = _label(mode_picker, "", 13, Palette.TERM_MUTED); mode_note.name = "TerminalModeNote"
	get_node("/root/GameMode").mode_changed.connect(_sync_mode_choice)
	var rest := Control.new(); rest.name = "TerminalRest"; rest.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	awake_view.add_child(rest)
	var footer_rule := ColorRect.new(); footer_rule.name = "TerminalFooterRule"
	footer_rule.color = Palette.with_alpha(Palette.TERM_EDGE, 0.6); footer_rule.custom_minimum_size.y = 1
	footer_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	awake_view.add_child(footer_rule)
	secondary = HFlowContainer.new(); secondary.add_theme_constant_override("h_separation", 4); secondary.add_theme_constant_override("v_separation", 2)
	awake_view.add_child(secondary)
	var labels: Array = [["旅程地图", "Journey map", "journey"], ["档案", "Archive", "archive"], ["手册", "Handbook", "handbook"], ["设置", "Settings", "settings"], ["作品", "Works", "works"], ["成就", "Achievements", "achievements"], ["反馈", "Feedback", "feedback"], ["返回房间 · Esc", "Back to room · Esc", "look"], ["退出游戏", "Quit", "quit"]]
	for entry: Array in labels:
		var button := _button(secondary, "", str(entry[2]), false)
		button.name = "Terminal" + str(entry[2]).capitalize()
		button.set_meta("zh", entry[0]); button.set_meta("en", entry[1])
		button.size_flags_horizontal = Control.SIZE_FILL
		button.custom_minimum_size.y = 32
		button.add_theme_font_size_override("font_size", 14)
		_style_link(button, Palette.QUIT if str(entry[2]) == "quit" else Palette.TERM_MUTED)
		if str(entry[2]) == "archive": archive_button = button
	choices = HBoxContainer.new(); choices.name = "DialogueChoices"
	choices.add_theme_constant_override("separation", 8)
	choices.hide(); awake_view.add_child(choices)
	_build_quit_view(stack)
	_compose()

## Reading or skipping never changes the completion behind this response.
func play_dialogue(beats: Array, beat: int = 0, reply: Dictionary = {}) -> void:
	if beats.is_empty(): return
	_dialogue = beats
	_beat = beat
	_reply = reply
	primary.hide(); mode_picker.hide(); secondary.hide(); choices.show()
	dialogue_skip.text = "返回" if not english else "Back"
	dialogue_skip.tooltip_text = "跳过本段，回到终端" if not english else "Skip this conversation and return to the terminal"
	dialogue_skip.show()
	dialogue_skip.grab_focus()
	message.skip_scope = choices
	_show_beat()

func language_checkpoint() -> Dictionary:
	return {"response": response.duplicate(true), "dialogue": _dialogue.duplicate(true),
		"beat": _beat, "reply": _reply.duplicate(true)}

func restore_language(checkpoint: Dictionary) -> void:
	response = checkpoint.response
	state["response"] = response
	_compose()
	if checkpoint.dialogue.is_empty():
		wake(true)
		return
	_asleep = false
	sleep_view.hide(); awake_view.show()
	play_dialogue(checkpoint.dialogue, int(checkpoint.beat), checkpoint.reply)

func in_dialogue() -> bool:
	return not _dialogue.is_empty()

func _line(entry: Dictionary, key: String) -> String:
	return str(entry.get(key + ("_en" if english else "_zh"), entry.get("en" if english else "zh", "")))

func _next_beat() -> void:
	_beat += 1
	_reply = {}
	_show_beat()

func _show_beat() -> void:
	if _beat >= _dialogue.size():
		_end_dialogue(); return
	var beat: Dictionary = _dialogue[_beat]
	if _reply.is_empty():
		echo.hide()
		_say_then(str(beat.en if english else beat.zh), beat.get("replies", []))
	else:
		echo.text = ("你：" if not english else "You: ") + str(_reply.en if english else _reply.zh)
		echo.show()
		_say_then(_line(_reply, "answer"), [])

func _say_then(passage: String, replies: Array) -> void:
	if _reveal_choices.is_valid() and message.finished.is_connected(_reveal_choices):
		message.finished.disconnect(_reveal_choices)
	_passage = passage
	_set_choices([])
	message.play(_passage)
	_reveal_choices = func() -> void:
		if replies.is_empty():
			var last: bool = _beat >= _dialogue.size() - 1
			_set_choices([{"text": ("回到终端" if not english else "Back to the terminal") if last else ("继续 ›" if not english else "Continue ›"), "next": true}])
		else:
			var options: Array = []
			for reply: Dictionary in replies: options.append({"text": str(reply.en if english else reply.zh), "reply": reply})
			_set_choices(options)
	if message.is_playing(): message.finished.connect(_reveal_choices, CONNECT_ONE_SHOT)
	else: _reveal_choices.call()

func _set_choices(options: Array) -> void:
	for child: Node in choices.get_children(): child.queue_free()
	var first: Button = null
	for option: Dictionary in options:
		var button := Button.new(); button.text = str(option.text)
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_FILL
		button.custom_minimum_size.y = 40
		button.add_theme_font_size_override("font_size", 15)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_choice(button)
		if option.has("reply"):
			var reply: Dictionary = option.reply
			button.pressed.connect(func() -> void:
				_reply = reply
				_show_beat())
		else:
			button.pressed.connect(_next_beat)
		choices.add_child(button)
		if first == null: first = button
	if first != null: first.call_deferred("grab_focus")

func _end_dialogue() -> void:
	if _reveal_choices.is_valid() and message.finished.is_connected(_reveal_choices):
		message.finished.disconnect(_reveal_choices)
	_dialogue = []
	_beat = -1
	_reply = {}
	echo.hide(); choices.hide(); dialogue_skip.hide()
	message.skip_scope = self
	_set_choices([])
	primary.show(); mode_picker.show(); secondary.show()
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
	quit_no.call_deferred("grab_focus")

func cancel_quit() -> void:
	if not _confirming: return
	_confirming = false
	quit_view.hide(); awake_view.show()
	if not message.caret_visible(): message.play(_passage)
	action.emit("quit_cancelled")
	_focus_primary()

func confirming() -> bool:
	return _confirming

func _compose() -> void:
	_passage = ""
	_compose_text()
	_sync_task_card()
	# Yi speaks only while awake; on standby the passage waits for wake().
	if _asleep:
		message.prepare(_passage)
	elif message.text != _passage or not message.caret_visible():
		message.play(_passage)

func _compose_text() -> void:
	var zh: bool = not english
	_sync_mode_choice()
	mode_note.text = "游戏：按前置推进，保留自己的成果。\n测试：各关可进入，临时元件与进度隔离。" if zh else "Game: follow prerequisites and keep your own work.\nTest: visit any task with separate, temporary components and progress."
	game_mode_button.tooltip_text = "适合首次游玩：亲手完成前置，逐步构建与保存自己的成果。" if zh else "For a first playthrough: earn prerequisites, build and save your own work."
	test_mode_button.tooltip_text = "适合快速试玩：直接查看各章节，使用临时参考元件；测试成果不会成为游戏模式的通关记录。" if zh else "For a quick preview: visit any chapter with temporary reference components. Test results do not become Game-mode achievements."
	sleep_hint.text = "壹 · 学习程序 · 待机\n点击屏幕，或按 Enter" if zh else "Yi · learning program · standby\nClick the screen or press Enter"
	header_label.text = "壹 · 学习程序" if zh else "Yi · learning program"
	language_button.text = "EN" if zh else "中文"
	progress_label.text = ("%d / %d" % [int(state.get("completed", 0)), int(state.get("total", 0))]) if int(state.get("total", 0)) > 0 else ""
	for button: Node in secondary.get_children():
		(button as Button).text = str(button.get_meta("en" if english else "zh"))
	set_fragment_count(int(state.get("fragments", 0)), int(state.get("fragments_unread", 0)))
	var navigation: Node = get_node_or_null("/root/TaskNavigation")
	var next_title: String = str(state.get("next_title", ""))
	if next_title.is_empty() and navigation != null: next_title = str(navigation.resume_title())
	primary.tooltip_text = next_title
	if bool(state.get("new_player", true)):
		_passage = "你好，我是壹。\n从一根线开始吧。接好、运行，再看看灯为什么亮或灭。\n需要时，我会在这里。" if zh else "Hello. I am Yi.\nStart with one wire. Connect it, run it, and see why the lamp is on or off.\nI am here when you need me."
		primary.text = "开始 · 接通第一条线路" if zh else "Begin · connect the first line"
		return
	if not str(state.get("next_title", "")).is_empty() and str(state.get("next_key", "")) != str(navigation.next_task_key() if navigation != null else ""):
		primary.text = "继续" if zh else "Continue"
	else:
		primary.text = (str(navigation.home_action_text()) if navigation != null else ("继续" if zh else "Continue"))
	if not next_title.is_empty(): primary.text += "\n" + Naming.plain_title(next_title)
	if not response.is_empty():
		var task: Dictionary = response.get("task", {})
		var title: String = str(task.get("title", ""))
		if bool(response.get("first_light", false)):
			_passage = "你接好、运行过，也拆开重接过了。\n还想试试的话，换个输入再运行，看看灯的变化。\n档案架上多了一页，随时可以看。" if zh else "You connected, ran, disconnected and reconnected it.\nTry the other input and run again to see the lamp change.\nThere is a new page on the archive shelf whenever you want it."
			return
		if response.has("chapter"):
			_passage = str(response.chapter.en if english else response.chapter.zh)
			if int(response.get("fragments", 0)) > 0:
				_passage += "\n" + ("档案架上多了一页记录。" if zh else "A new record waits on the archive shelf.")
			return
		_passage = ("「%s」完成了。\n你可以回去再改它，也可以继续往前走。" if zh else "\"%s\" is complete.\nYou can return to try another approach, or keep going.") % Naming.plain_title(title)
		if int(response.get("fragments", 0)) > 0:
			_passage += "\n" + ("档案架上多了一页记录。" if zh else "A new record waits on the archive shelf.")
		return
	_passage = ("欢迎回来。\n下一项是「%s」。" if zh else "Welcome back.\nNext up: \"%s\".") % Naming.plain_title(next_title)

func _sync_mode_choice(_mode: StringName = &"") -> void:
	var testing: bool = get_node("/root/GameMode").is_test_mode()
	game_mode_button.set_pressed_no_signal(not testing)
	test_mode_button.set_pressed_no_signal(testing)
	game_mode_button.text = ("✓ " if not testing else "") + ("游戏模式" if not english else "Game mode")
	test_mode_button.text = ("✓ " if testing else "") + ("测试模式" if not english else "Test mode")

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
		else: dialogue_skip.call_deferred("grab_focus")
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

## The task card: dark glass with an accent edge; the kicker and the task
## title are separate lines drawn over the button, which keeps its full text.
func _style_task_card(node: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Palette.TERM_SCREEN_LIFT.lightened(0.04 if state == "hover" else 0.0) if state != "pressed" else Palette.TERM_PANEL
		box.border_color = Palette.ACCENT if state in ["hover", "focus"] else Palette.with_alpha(Palette.ACCENT_DEEP, 0.75)
		box.set_border_width_all(1); box.border_width_left = 4
		box.set_corner_radius_all(10)
		box.draw_center = state != "focus"
		box.content_margin_left = 22; box.content_margin_right = 22
		node.add_theme_stylebox_override(state, box)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(color_name, Color.TRANSPARENT)
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	node.custom_minimum_size = Vector2(520, 78)
	var lines := VBoxContainer.new(); lines.name = "CardLines"
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lines.offset_left = 24; lines.offset_right = -70
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override("separation", 2)
	node.add_child(lines)
	var kicker := _label(lines, "", 14, Palette.ACCENT); kicker.name = "CardKicker"
	kicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _label(lines, "", 22, Palette.TERM_TEXT); title.name = "CardTitle"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	var enter := _label(node, "Enter ↵", 13, Palette.TERM_MUTED); enter.name = "CardEnter"
	enter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	enter.offset_left = -78; enter.offset_right = -18; enter.offset_top = -10; enter.offset_bottom = 10
	enter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _sync_task_card() -> void:
	var kicker: Label = primary.get_node_or_null("CardLines/CardKicker")
	var title: Label = primary.get_node_or_null("CardLines/CardTitle")
	if kicker == null or title == null: return
	var text: String = primary.text
	var split: int = text.find("
")
	if split < 0: split = text.find(" · ")
	if split < 0:
		kicker.text = ""; title.text = text
	else:
		kicker.text = text.substr(0, split).strip_edges()
		title.text = text.substr(split + (1 if text[split] == "
" else 3)).strip_edges()
	kicker.visible = not kicker.text.is_empty()

## Everything else reads as quiet text; it lifts only under the pointer or focus.
func _style_link(node: Button, ink: Color) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Palette.TERM_SCREEN_LIFT if state in ["hover", "pressed"] else Color.TRANSPARENT
		box.border_color = Palette.ACCENT if state == "focus" else Color.TRANSPARENT
		box.set_border_width_all(1 if state == "focus" else 0)
		box.set_corner_radius_all(6)
		box.draw_center = state != "focus"
		box.content_margin_left = 10; box.content_margin_right = 10
		node.add_theme_stylebox_override(state, box)
	node.add_theme_color_override("font_color", ink)
	node.add_theme_color_override("font_focus_color", ink)
	node.add_theme_color_override("font_hover_color", Palette.TERM_TEXT if ink != Palette.QUIT else Palette.QUIT.lightened(0.15))
	node.add_theme_color_override("font_pressed_color", Palette.TERM_TEXT)

func _style_quit(node: Button) -> void:
	# Leaving the game reads clearly apart from the other functions.
	for pair: Array in [["normal", Palette.QUIT_DEEP, Palette.with_alpha(Palette.QUIT, 0.7)], ["hover", Palette.QUIT_DEEP.lightened(0.08), Palette.QUIT], ["pressed", Palette.QUIT_DEEP.darkened(0.2), Palette.QUIT]]:
		var box: StyleBoxFlat = (node.get_theme_stylebox(str(pair[0])) as StyleBoxFlat).duplicate()
		box.bg_color = pair[1]; box.border_color = pair[2]
		node.add_theme_stylebox_override(str(pair[0]), box)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(color_name, Palette.QUIT)

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
		elif id == "dialogue_skip": _end_dialogue()
		else: action.emit(id))
	parent.add_child(node)
	return node
