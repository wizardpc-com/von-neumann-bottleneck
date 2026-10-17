extends VBoxContainer
## A foldout inside Mission, with no progression, modal or input-event authority.
const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
var toggle: Button
var details: VBoxContainer
var context_label: Label
var action_label: Label
var verify_label: Label
var evidence_label: Label
var last_task: String = ""
var english: bool = false

func _init() -> void:
	name = "JourneyContextCard"
	add_theme_constant_override("separation", 6)
	action_label = _label(""); action_label.name = "JourneyCurrentAction"; add_child(action_label)
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
	toggle.text = "壹 · 语境与前后承接" if not english else "Yi · Context and connection"
	if earned:
		toggle.text += (" · 本次发现" if not english else " · session finding") if chapter == &"prediction" else (" · 已有记录" if not english else " · earned record")
	action_label.text = ("现在：" if not english else "Now: ") + str(data.action)
	verify_label.text = ("核验：" if not english else "Verify: ") + str(data.verify)
	var lines: Array[String] = [str(data.intent)]
	if earned:
		var earned_title: String = "已有验收记录（当前草稿另验）：" if not english else "Earned record (recheck the current draft): "
		if chapter == &"prediction": earned_title = "本次临时发现：" if not english else "Temporary session finding: "
		lines.append(earned_title + str(data.completion))
	lines.append(("卡住时：" if not english else "If stuck: ") + str(data.failure))
	lines.append(("前后承接：" if not english else "Connection: ") + str(data.connection))
	lines.append(str(data.scope))
	context_label.text = "\n\n".join(lines)

func draft_changed() -> void:
	if evidence_label == null: return
	evidence_label.text = "当前草稿已改变；旧记录仍归原方案，重新运行后再看当前结果。" if not english else "The draft changed. Older records remain bound to their original plan; rerun to inspect the current result."

func measurement_recorded() -> void:
	if evidence_label == null: return
	evidence_label.text = "运行状态与结果请看原测试台／证据记录；只有原合同确认的结果才算通过。" if not english else "Read run status and results in the existing test/evidence view; only the original contract can confirm acceptance."
