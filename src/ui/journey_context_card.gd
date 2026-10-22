extends VBoxContainer
## A foldout inside Mission, with no progression, modal or input-event authority.
const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
var toggle: Button
var details: VBoxContainer
var context_label: Label
var action_label: Label
var verify_label: Label
var evidence_label: Label
var last_task: String = ""
var english: bool = false
## The catalog's "now" line, and a state-derived replacement while one applies.
var base_action: String = ""
var live_action: String = ""
var _emphasis: Tween
## State-derived guidance is Yi's voice: written with the trailing caret in
## place of the task's own "now" line, which returns when it no longer applies.
var live_label: Typewriter

func _init() -> void:
	name = "JourneyContextCard"
	add_theme_constant_override("separation", 6)
	action_label = _label(""); action_label.name = "JourneyCurrentAction"; add_child(action_label)
	live_label = Typewriter.new(); live_label.name = "JourneyLiveGuidance"
	live_label.font_size = 16; live_label.font_color = Color("ffd27a"); live_label.line_spacing = 3.0
	live_label.speed_scale = 2.2
	live_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	live_label.hide()
	add_child(live_label)
	verify_label = _label(""); verify_label.name = "JourneyVerification"; add_child(verify_label)
	action_label.add_theme_font_size_override("font_size", 16)
	verify_label.add_theme_font_size_override("font_size", 16)
	toggle = Button.new()
	toggle.name = "JourneyContextToggle"
	toggle.toggle_mode = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toggle.custom_minimum_size.y = 40
	add_child(toggle)
	details = VBoxContainer.new(); details.name = "JourneyContextDetails"
	details.add_theme_constant_override("separation", 6)
	add_child(details)
	context_label = _label(""); details.add_child(context_label)
	evidence_label = _label(""); details.add_child(evidence_label)
	toggle.toggled.connect(func(expanded: bool) -> void: details.visible = expanded)
	details.hide()

func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func set_task(chapter: StringName, level: StringName, use_english: bool, earned: bool = false) -> void:
	var data: Dictionary = Catalog.task_context(chapter, level, use_english)
	visible = not data.is_empty()
	if data.is_empty(): return
	var changed: bool = last_task != str(data.task_id) or english != use_english
	english = use_english
	last_task = str(data.task_id)
	if changed:
		toggle.set_pressed_no_signal(false); details.hide()
		evidence_label.text = "当前方案仍须按原任务核验。" if not english else "Check the current plan under the existing task contract."
	toggle.text = "再了解一点" if not english else "A closer look"
	if earned:
		toggle.text += (" · 本次发现" if not english else " · session finding") if chapter == &"prediction" else (" · 已有记录" if not english else " · earned record")
	base_action = str(data.action)
	if changed: live_action = ""
	_show_action()
	verify_label.text = ("怎样算完成：" if not english else "Done when: ") + str(data.verify)
	var lines: Array[String] = [str(data.intent)]
	if earned:
		var earned_title: String = "已有验收记录（当前草稿另验）：" if not english else "Earned record (recheck the current draft): "
		if chapter == &"prediction": earned_title = "本次临时发现：" if not english else "Temporary session finding: "
		lines.append(earned_title + str(data.completion))
	lines.append(("卡住时：" if not english else "If stuck: ") + str(data.failure))
	lines.append(("前后承接：" if not english else "Connection: ") + str(data.connection))
	lines.append(str(data.scope))
	context_label.text = "\n\n".join(lines)

func _show_action() -> void:
	var now: String = live_action if not live_action.is_empty() else base_action
	action_label.text = ("现在：" if not english else "Now: ") + now
	action_label.visible = live_action.is_empty()
	live_label.visible = not live_action.is_empty()
	if live_action.is_empty(): live_label.stop()
	elif live_label.text != action_label.text: live_label.play(action_label.text)


## The scene's actual state can replace the "now" line with the one thing that
## applies at this moment (apply the draft first, run again...). Empty restores
## the task's own line. Presentation only.
func set_live_action(text: String) -> void:
	if live_action == text: return
	live_action = text
	if not base_action.is_empty(): _show_action()


func shows_action(passage: String) -> bool:
	return action_label.is_visible_in_tree() and not base_action.is_empty() and passage.strip_edges() == base_action.strip_edges()


## The level's opening points here instead of opening a second card.
func emphasize() -> void:
	if _emphasis != null: _emphasis.kill()
	if bool(ProjectSettings.get_setting("game/reduced_motion", false)): return
	action_label.modulate = Color(1.35, 1.35, 1.2)
	_emphasis = create_tween()
	_emphasis.tween_interval(0.5)
	_emphasis.tween_property(action_label, "modulate", Color.WHITE, 1.2)


func draft_changed() -> void:
	if evidence_label == null: return
	evidence_label.text = "草稿已改变，请重新运行；旧记录仍对应原方案。" if not english else "The draft changed. Run it again; older records still describe the previous plan."

func measurement_recorded() -> void:
	if evidence_label == null: return
	evidence_label.text = "查看测试台／运行记录，确认还有哪一项未达标。" if not english else "Check the test bench or run record for any unmet targets."
