extends PanelContainer
## The level guide, docked above the canvas (not floating over it): the goal in
## one line (a fact, shown at once), the one thing to do now (Yi's guidance,
## written out quickly with the trailing caret) and Yi's short reply when a
## real step completes. Asking for help replaces the instruction in this same strip; the
## full briefing hides the instruction while it is open. The canvas gets the
## remaining height, so the guide never covers ports, wires or Run.
## It mirrors the workbench's real state; it never marks a step itself.

signal briefing_requested
signal demonstration_requested
signal demonstration_skipped
signal case_selected(index: int)
signal collapse_changed(collapsed: bool)

const Palette = preload("res://src/lab/lab_palette.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
const CaseTable = preload("res://src/hardware_foundations/guide_case_table.gd")
const STEPS := [
	{"id": "wire", "zh_title": "接线", "en_title": "Wire",
		"zh": "从输入 A 右侧的圆点按住拖到 NOT 左侧的圆点，再从 NOT 右侧拖到灯。",
		"en": "Drag from the dot on the right of input A to the left dot of NOT, then from NOT's right dot to the lamp."},
	{"id": "input", "zh_title": "改变输入", "en_title": "Change the input",
		"zh": "两段线接好了。在左下角测试台点 A，切换 0 和 1。",
		"en": "Both wires are connected. Click A in the bottom-left test bench to switch between 0 and 1."},
	{"id": "run", "zh_title": "运行", "en_title": "Run",
		"zh": "先猜灯会亮还是灭，再按「运行练习电路」。NOT 把输入反过来：0 亮，1 灭。",
		"en": "Predict whether the lamp will light, then press Run. NOT flips the input: 0 lights it, 1 turns it off."},
	{"id": "remove", "zh_title": "拆一条线", "en_title": "Remove a wire",
		"zh": "按住右键划过任意一条线，把它拆掉。拆错了也没关系。",
		"en": "Hold the right mouse button and sweep across a wire to remove it. Mistakes are fine."},
	{"id": "reconnect", "zh_title": "接回去", "en_title": "Reconnect",
		"zh": "把刚才拆掉的线重新接上。接回去后，还可以换个输入再运行。",
		"en": "Reconnect the removed wire. Then you can try another input and run again."},
]

## Titles of the build guide; the instruction itself comes from the workbench's
## actual circuit and runs (show_guidance). The texts are the fallback only.
const BUILD_STEPS := [
	{"id": "wire", "zh_title": "搭电路", "en_title": "Build",
		"zh": "从右侧「元件」拖出门电路，接到每一个输出上。不确定时可以先只接一个输出试试。",
		"en": "Drag gates from Components on the right and wire every output. Unsure? Wire just one output first."},
	{"id": "debug", "zh_title": "试一试", "en_title": "Try it",
		"zh": "在左侧测试台换一组输入，运行调试用例。对照期望与实际输出，找出不一致的那一项。",
		"en": "Change an input case in Test Bench and run it. Compare expected and actual outputs to find a mismatch."},
	{"id": "official", "zh_title": "正式测试", "en_title": "Official test",
		"zh": "按「逐项运行正式用例」。全部通过后，这个电路就能封装成下一关可用的零件。",
		"en": "Run the official cases. When all pass, this circuit becomes a part you can reuse later."},
]
const BUILD_PRAISE_ZH := ["每个输出都有来源了。", "跑起来了。", "全部通过。"]
const BUILD_PRAISE_EN := ["Every output is wired.", "It runs.", "All cases pass."]
const TUTORIAL_PRAISE_ZH := ["接上了。", "输入变了。运行后再看灯。", "这次运行有结果了。", "拆掉了。", "又接好了。"]
const TUTORIAL_PRAISE_EN := ["Connected.", "Input changed. Run it.", "That run has a result.", "Removed.", "Connected again."]
const EXPANDED_HEIGHT := 76.0
const INSTRUCTION_HEIGHT := 44.0
const COLLAPSED_HEIGHT := 40.0

## Folding the guide is the player's choice for the session, across levels.
static var collapsed: bool = false

var steps: Array = STEPS
var praise_zh: Array = TUTORIAL_PRAISE_ZH
var praise_en: Array = TUTORIAL_PRAISE_EN
var goal_text: String = ""
var english: bool = false
var step_label: Label
var goal_label: Label
## Yi's current guidance: typed with the trailing caret; a passage already read
## in full reappears at once (Typewriter), so state refreshes never re-type.
var instruction: Typewriter
var instruction_well: Control
var _pending_guidance: String = ""
var _quiet: bool = false
var dots: Array[ColorRect] = []
var dots_row: HBoxContainer
## Yi's short reply when a real step completes. The step number and the
## instruction stay instantly readable; only Yi's words are typed out.
var praise: Typewriter
var praise_row: HBoxContainer
var praise_tween: Tween
var last_states: Array[bool] = []
var demonstration_button: Button
var demonstration_skip: Button
var operation_level: StringName = &""
## Where Yi's help card sits while the guide is showing (it replaces the instruction).
## A plain Control, not a container: wrapped help text measured at a narrow
## first-frame width must not stretch the docked strip (or push the footer).
var help_slot: Control
var case_table: CaseTable
var briefing_button: Button
var collapse_button: Button
## True while the full briefing (reading layer) is open.
var reading: bool = false
var _flash: Tween


func _ready() -> void:
	name = "TutorialCoach"
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.with_alpha(Palette.TERM_PANEL, 0.98)
	# Quiet edges; one accent bar on the left marks "the guide" (art spec §5).
	box.border_color = Palette.with_alpha(Palette.ACCENT_DEEP, 0.4); box.set_border_width_all(1)
	box.set_corner_radius_all(9)
	box.content_margin_left = 0; box.content_margin_right = 10; box.content_margin_top = 7; box.content_margin_bottom = 7
	add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new(); row.name = "GuideRow"
	row.add_theme_constant_override("separation", 14); add_child(row)
	var bar := ColorRect.new(); bar.name = "GuideAccent"
	bar.custom_minimum_size = Vector2(3, 0); bar.color = Palette.ACCENT_DEEP
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)

	var lead := VBoxContainer.new(); lead.name = "GuideLead"
	lead.custom_minimum_size.x = 188.0
	lead.clip_contents = true
	lead.alignment = BoxContainer.ALIGNMENT_CENTER
	lead.add_theme_constant_override("separation", 4)
	row.add_child(lead)
	dots_row = HBoxContainer.new(); dots_row.add_theme_constant_override("separation", 4); lead.add_child(dots_row)
	for index: int in 5:
		var dot := ColorRect.new(); dot.custom_minimum_size = Vector2(18, 4)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = Palette.TERM_EDGE; dots_row.add_child(dot); dots.append(dot)
	step_label = Label.new(); step_label.name = "CoachStep"
	step_label.add_theme_color_override("font_color", Palette.ACCENT)
	step_label.add_theme_font_size_override("font_size", 15)
	step_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lead.add_child(step_label)
	praise_row = HBoxContainer.new(); praise_row.add_theme_constant_override("separation", 6)
	praise_row.modulate.a = 0.0
	lead.add_child(praise_row)
	var tick := Label.new(); tick.text = "✓"
	tick.add_theme_color_override("font_color", Palette.GOOD); tick.add_theme_font_size_override("font_size", 14)
	praise_row.add_child(tick)
	praise = Typewriter.new(); praise.name = "CoachPraise"
	praise.font_size = 14; praise.font_color = Color("bfe3e6")
	praise.speed_scale = 2.2
	# One line beside the tick; the reply never wraps the lead column.
	praise.custom_minimum_size.x = 164.0
	praise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	praise_row.add_child(praise)

	var rule := ColorRect.new(); rule.custom_minimum_size = Vector2(1, 0)
	rule.color = Palette.with_alpha(Palette.TERM_EDGE, 0.9); rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(rule)

	var center := VBoxContainer.new(); center.name = "GuideCenter"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 2)
	row.add_child(center)
	goal_label = Label.new(); goal_label.name = "CoachGoal"
	goal_label.add_theme_color_override("font_color", Palette.TERM_MUTED)
	goal_label.add_theme_font_size_override("font_size", 13)
	goal_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	goal_label.visible = false
	center.add_child(goal_label)
	instruction = Typewriter.new(); instruction.name = "CoachInstruction"
	instruction.font_size = 16; instruction.font_color = Palette.TERM_TEXT; instruction.line_spacing = 3.0
	instruction.speed_scale = 2.2
	instruction.mouse_filter = Control.MOUSE_FILTER_PASS
	# A fixed two-line well: longer advice never changes the strip's height,
	# so the canvas below never moves while the player works.
	instruction_well = Control.new(); instruction_well.name = "CoachInstructionWell"
	instruction_well.custom_minimum_size.y = INSTRUCTION_HEIGHT
	instruction_well.clip_contents = true
	instruction_well.mouse_filter = Control.MOUSE_FILTER_PASS
	center.add_child(instruction_well)
	instruction_well.add_child(instruction)
	instruction.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	help_slot = Control.new(); help_slot.name = "GuideHelpSlot"
	help_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_slot.custom_minimum_size.y = EXPANDED_HEIGHT - 14.0
	help_slot.clip_contents = true
	center.add_child(help_slot)

	case_table = CaseTable.new()
	case_table.visible = false
	case_table.case_selected.connect(func(index: int) -> void: case_selected.emit(index))
	row.add_child(case_table)


	var action_column := VBoxContainer.new()
	action_column.add_theme_constant_override("separation", 4)
	action_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(action_column)
	var actions := HBoxContainer.new(); actions.name = "GuideActions"
	actions.add_theme_constant_override("separation", 4)
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_column.add_child(actions)
	briefing_button = Button.new(); briefing_button.name = "CoachBriefing"; briefing_button.flat = true
	briefing_button.add_theme_font_size_override("font_size", 13)
	briefing_button.add_theme_color_override("font_color", Palette.TERM_MUTED)
	briefing_button.add_theme_color_override("font_hover_color", Palette.ACCENT)
	briefing_button.pressed.connect(func() -> void: briefing_requested.emit())
	actions.add_child(briefing_button)
	collapse_button = Button.new(); collapse_button.name = "CoachCollapse"; collapse_button.flat = true
	collapse_button.custom_minimum_size = Vector2(30, 28)
	collapse_button.add_theme_font_size_override("font_size", 13)
	collapse_button.add_theme_color_override("font_color", Palette.TERM_MUTED)
	collapse_button.add_theme_color_override("font_hover_color", Palette.ACCENT)
	collapse_button.pressed.connect(func() -> void: set_collapsed(not collapsed))
	actions.add_child(collapse_button)
	var demo_actions := HBoxContainer.new()
	demo_actions.add_theme_constant_override("separation", 4)
	action_column.add_child(demo_actions)
	demonstration_button = Button.new(); demonstration_button.name = "CoachDemonstration"
	demonstration_button.add_theme_font_size_override("font_size", 13)
	demonstration_button.pressed.connect(func() -> void: demonstration_requested.emit())
	demo_actions.add_child(demonstration_button)
	demonstration_skip = Button.new(); demonstration_skip.name = "CoachSkipDemonstration"
	demonstration_skip.add_theme_font_size_override("font_size", 13)
	demonstration_skip.flat = true
	demonstration_skip.visible = false
	demonstration_skip.pressed.connect(func() -> void: demonstration_skipped.emit())
	demo_actions.add_child(demonstration_skip)
	_refresh_labels()
	_apply_shape()


func set_english(value: bool) -> void:
	english = value
	if case_table != null: case_table.english = value
	if is_node_ready(): _refresh_labels()


func _refresh_labels() -> void:
	demonstration_button.text = "看操作演示" if not english else "Show gesture"
	demonstration_skip.text = "停止演示" if not english else "Stop demo"
	# Reserve both controls so replay does not move the guide or spec columns.
	demonstration_button.get_parent().custom_minimum_size.x = demonstration_button.get_combined_minimum_size().x + demonstration_skip.get_combined_minimum_size().x + 4.0
	set_operation_lesson(operation_level)
	briefing_button.text = "完整说明" if not english else "Full briefing"
	briefing_button.tooltip_text = "打开任务的完整说明；阅读时步骤提示先收起。" if not english else "Open the full briefing; the step guide steps aside while you read."
	collapse_button.text = ("展开" if collapsed else "收起") if not english else ("Show" if collapsed else "Hide")
	collapse_button.tooltip_text = "收起后只保留一行目标；求助入口不变。" if not english else "Folded, the guide keeps one line; Hint stays available."


## Switch between the first lesson and the build → try → test guide.
func use_steps(build_guide: bool, goal: String = "") -> void:
	if praise_tween != null: praise_tween.kill()
	praise.stop()
	_release_guidance()
	praise_row.modulate.a = 0.0
	steps = BUILD_STEPS if build_guide else STEPS
	praise_zh = BUILD_PRAISE_ZH if build_guide else TUTORIAL_PRAISE_ZH
	praise_en = BUILD_PRAISE_EN if build_guide else TUTORIAL_PRAISE_EN
	goal_text = goal
	goal_label.text = (("目标 · " if not english else "Goal · ") + goal) if not goal.is_empty() else ""
	goal_label.tooltip_text = goal
	last_states.clear()
	set_cases([])
	for index: int in dots.size(): dots[index].visible = index < steps.size()
	_apply_shape()


## The spec table beside the instruction (empty hides it).
func set_cases(cases: Array) -> void:
	case_table.set_cases(cases)
	case_table.visible = not cases.is_empty() and not collapsed
	if cases.is_empty(): case_table.set_evidence({}, -1)


func set_case_evidence(evidence: Dictionary, selected_index: int) -> void:
	case_table.set_evidence(evidence, selected_index)


func update_states(states: Array[bool]) -> void:
	var newly: int = _mark_states(states)
	var next: int = states.find(false)
	if next < 0:
		if steps == STEPS:
			step_label.text = "五步都完成了" if not english else "All five steps done"
			_say("五个操作都做到了。还可以换个输入再运行：NOT 会把 0 变成 1，把 1 变成 0。" if not english else "All five actions are done. Try the other input and run again: NOT turns 0 into 1 and 1 into 0.")
		else:
			step_label.text = "完成了" if not english else "Done"
			_say("可以封装它，继续下一项。" if not english else "Seal it and move on.")
	else:
		var step: Dictionary = steps[next]
		step_label.text = _step_title(next, str(step.en_title if english else step.zh_title))
		_say(str(step.en if english else step.zh))
	_after_change(newly)


## The build guide: the step reached by the real circuit (`states`) with an
## instruction composed by the workbench from its actual circuit and runs.
func show_guidance(states: Array[bool], title: String, text: String) -> void:
	var newly: int = _mark_states(states)
	var next: int = states.find(false)
	step_label.text = title if next < 0 else _step_title(next, title)
	_say(text)
	_after_change(newly)


## Only a changed passage is written out again; the same advice stays put.
## When a step has just been earned, Yi's short reply speaks first and the
## next guidance is written after it, so only one line is ever appearing.
func _say(text: String) -> void:
	if instruction.text == text: return
	instruction.tooltip_text = text
	_pending_guidance = text
	instruction.prepare(text)


func _release_guidance() -> void:
	if _pending_guidance.is_empty(): return
	var text: String = _pending_guidance
	_pending_guidance = ""
	instruction.play(text)
	if collapsed or reading: instruction.complete_now()


func _step_title(index: int, title: String) -> String:
	return ("第 %d / %d 步 · %s" if not english else "Step %d / %d · %s") % [index + 1, steps.size(), title]


func _mark_states(states: Array[bool]) -> int:
	var newly: int = -1
	for index: int in states.size():
		if states[index] and (last_states.size() <= index or not last_states[index]) and not last_states.is_empty():
			newly = index
	last_states = states.duplicate()
	var next: int = states.find(false)
	demonstration_button.disabled = next < 0
	for index: int in dots.size():
		if index >= states.size(): continue
		dots[index].color = Palette.ACCENT if states[index] else (Palette.with_alpha(Palette.ACCENT, 0.4) if index == next else Palette.TERM_EDGE)
	return newly


func _after_change(newly: int) -> void:
	if newly < 0 or newly >= praise_zh.size():
		_release_guidance()
		return
	praise.play(str(praise_en[newly] if english else praise_zh[newly]), true)
	if praise.is_playing():
		if not praise.finished.is_connected(_release_guidance): praise.finished.connect(_release_guidance, CONNECT_ONE_SHOT)
	else: _release_guidance()
	if praise_tween != null: praise_tween.kill()
	praise_tween = create_tween()
	praise_row.modulate.a = 1.0
	praise_tween.tween_interval(2.6)
	praise_tween.tween_property(praise_row, "modulate:a", 0.0, 0.6)
	praise_tween.tween_callback(praise.stop)
	if bool(ProjectSettings.get_setting("game/reduced_motion", false)): return
	if _flash != null: _flash.kill()
	_flash = create_tween()
	_flash.tween_property(self, "modulate", Color(1.1, 1.18, 1.15), 0.12)
	_flash.tween_property(self, "modulate", Color.WHITE, 0.4)


## Yi's help takes the instruction's place in the strip (one voice at a time).
func host_help(card: Control) -> void:
	if card.get_parent() != help_slot:
		if card.get_parent() != null: card.get_parent().remove_child(card)
		help_slot.add_child(card)
	if card.has_method("set_embedded"): card.set_embedded(true)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not card.visibility_changed.is_connected(_apply_shape): card.visibility_changed.connect(_apply_shape)
	_apply_shape()


func help_open() -> bool:
	for child: Node in help_slot.get_children():
		if child is CanvasItem and (child as CanvasItem).visible: return true
	return false


## A blocking layer (result card, Settings) is now speaking: finish any line
## at once and put the carets away. The text stays readable underneath.
func quiet() -> void:
	_release_guidance()
	instruction.complete_now()
	instruction.stop()
	praise.stop()
	if praise_tween != null: praise_tween.kill()
	praise_row.modulate.a = 0.0
	_quiet = true


## The blocking layer closed: the current line returns at once, caret and all.
func wake() -> void:
	if not _quiet: return
	_quiet = false
	if not instruction.text.is_empty(): instruction.play(instruction.text)


## While the full briefing is open the guide keeps only its goal line and
## stops talking; closing the briefing restores the current state.
func set_reading(value: bool) -> void:
	if reading == value: return
	reading = value
	if reading:
		if praise_tween != null: praise_tween.kill()
		praise.stop()
		_release_guidance()
		praise_row.modulate.a = 0.0
		for child: Node in help_slot.get_children():
			if child.has_method("close"): child.close()
	_apply_shape()


func set_collapsed(value: bool) -> void:
	if collapsed == value: return
	collapsed = value
	_refresh_labels()
	_apply_shape()
	collapse_changed.emit(collapsed)


func _apply_shape() -> void:
	if instruction == null: return
	var folded: bool = collapsed or reading
	var helping: bool = help_open() and not reading
	custom_minimum_size.y = COLLAPSED_HEIGHT if folded else EXPANDED_HEIGHT
	dots_row.visible = not folded
	praise_row.visible = not folded
	# Folded, the strip keeps the goal line; the guidance returns when unfolded.
	goal_label.visible = not goal_label.text.is_empty() and (folded or not helping)
	instruction.visible = not helping and not folded
	instruction_well.visible = instruction.visible
	demonstration_button.visible = not folded and not helping
	demonstration_skip.visible = demonstration_skip.visible and not folded and not helping
	case_table.visible = not case_table.cases.is_empty() and not folded
	help_slot.visible = helping
	# Reading: one quiet line that says where the guide went.
	if reading:
		goal_label.visible = true
		if goal_label.text.is_empty(): goal_label.text = "正在阅读完整说明" if not english else "Reading the full briefing"
	# Docked in a container: ask the parent to re-sort; never reset_size(),
	# which would shrink the strip to its minimum width until the next sort.
	update_minimum_size()


func set_operation_lesson(level_id: StringName) -> void:
	operation_level = level_id
	var lesson: Dictionary = preload("res://src/hardware_foundations/operation_curriculum.gd").lesson(level_id,english)
	demonstration_button.tooltip_text = str(lesson.get("text", ""))
	_apply_shape()
