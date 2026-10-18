extends VBoxContainer
## Optional candidate dialogue over detached public observations, without run authority.
signal expansion_requested
signal evidence_requested(kind: String)
signal work_requested(id: String)

class ConnectionImage extends Control:
	var step: int = 0
	var media: Texture2D

	func _draw() -> void:
		if media != null and media.get_width() > 0 and media.get_height() > 0:
			var native := Vector2(media.get_width(),media.get_height())
			var fitted: Vector2 = native * minf(size.x/native.x,size.y/native.y)
			draw_texture_rect(media,Rect2((size-fitted)/2.0,fitted),false)
			return
		# A replaceable connection metaphor, not a fourth signal trace or an event replay.
		var colors: Array[Color] = [Color("50d5ff"),Color("ffc879"),Color("c5a6ff")]
		var center: Vector2 = size/2.0
		for index: int in 3:
			var point := center+Vector2((index-1)*90,0)
			if index < 2: draw_line(point+Vector2(18,0),point+Vector2(72,0),Color("6c8194"),2)
			draw_rect(Rect2(point-Vector2(17,17),Vector2(34,34)),colors[index].darkened(0.65))
			draw_rect(Rect2(point-Vector2(17,17),Vector2(34,34)),colors[index],false,3 if mini(step,2)==index else 1)

var records: Dictionary = {}
var current_draft: Dictionary = {}
var locatable: Dictionary = {}
var english: bool = false
# The fragment is manual and static in both motion settings.
var reduced_motion: bool = false
var media: Texture2D:
	set(value):
		media = value
		if is_instance_valid(image):
			image.media = value
			image.queue_redraw()
var toggle_button: Button
var body: VBoxContainer
var scope_label: Label
var identity_label: Label
var summary_label: Label
var response_label: Label
var detail_label: Label
var locate_button: Button
var image: ConnectionImage
var step_buttons: Array[Button] = []
var step: int = 0

func _ready() -> void:
	name = "CPGConnectionFragment"
	add_theme_constant_override("separation",6)
	toggle_button = Button.new()
	toggle_button.name = "ShowCPGConnection"
	toggle_button.toggle_mode = true
	toggle_button.custom_minimum_size.y = 36
	toggle_button.toggled.connect(func(expanded: bool) -> void:
		if feedback_active():
			toggle_button.set_pressed_no_signal(body.visible)
			return
		body.visible = expanded
		if expanded:
			expansion_requested.emit()
			if not get_tree().process_frame.is_connected(_reveal_reading_region):
				get_tree().process_frame.connect(_reveal_reading_region,CONNECT_ONE_SHOT))
	add_child(toggle_button)
	body = VBoxContainer.new()
	body.name = "CPGConnectionBody"
	body.add_theme_constant_override("separation",6)
	add_child(body)
	scope_label = _label(14)
	var choices := HFlowContainer.new()
	body.add_child(choices)
	for index: int in 4:
		var action := Button.new()
		action.name = "CPGConnectionStep%d"%index
		action.toggle_mode = true
		action.custom_minimum_size.y = 36
		action.pressed.connect(select_step.bind(index))
		choices.add_child(action)
		step_buttons.append(action)
	identity_label = _label(14)
	summary_label = _label(16)
	locate_button = Button.new()
	locate_button.name = "LocateCPGConnection"
	locate_button.custom_minimum_size.y = 36
	locate_button.pressed.connect(func() -> void:
		if feedback_active(): return
		if step == 3:
			if not records.get("work",{}).is_empty(): work_requested.emit(str(records.work.get("id","")))
		else:
			var kind: String = ["transport","prediction","generation"][step]
			if locatable.get(kind,false): evidence_requested.emit(kind))
	body.add_child(locate_button)
	image = ConnectionImage.new()
	image.custom_minimum_size.y = 58
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.media = media
	body.add_child(image)
	response_label = _label(16)
	detail_label = _label(14)
	collapse()
	_refresh()

func _label(font_size: int) -> Label:
	var result := Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",font_size)
	body.add_child(result)
	return result

func words(zh: String,en: String) -> String:
	return en if english else zh

func configure(observations: Dictionary,draft: Dictionary,can_locate: Dictionary,use_english: bool) -> void:
	records = observations.duplicate(true)
	current_draft = draft.duplicate(true)
	locatable = can_locate.duplicate(true)
	english = use_english
	_refresh()

func collapse() -> void:
	if not is_instance_valid(body): return
	var focused: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var return_focus: bool = focused != null and body.is_ancestor_of(focused)
	body.hide()
	toggle_button.set_pressed_no_signal(false)
	if return_focus and is_visible_in_tree() and not feedback_active(): toggle_button.grab_focus()

func feedback_active() -> bool:
	if not is_inside_tree(): return false
	var data: Node = get_node_or_null("/root/PlaytestData")
	var offline: Node = get_node_or_null("/root/OfflineFeedback")
	return (data != null and bool(data.get("_feedback_visible"))) or (offline != null and bool(offline.get("busy")))

func select_step(index: int) -> void:
	if feedback_active(): return
	step = clampi(index,0,3)
	_refresh()

func _owns_window_focus() -> bool:
	var window: Window = get_window()
	if not window.has_focus(): return false
	# Embedded modal windows can retain their native parent's has_focus().
	for child: Window in window.get_embedded_subwindows():
		if child.visible and child.has_focus(): return false
	return true

func _unhandled_key_input(event: InputEvent) -> void:
	if not body.is_visible_in_tree() or feedback_active() or not _owns_window_focus(): return
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE: return
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != toggle_button and (focused == null or not body.is_ancestor_of(focused)): return
	collapse()
	get_viewport().set_input_as_handled()

func _reveal_reading_region() -> void:
	if is_queued_for_deletion() or not is_inside_tree() or not _owns_window_focus(): return
	if not body.is_visible_in_tree() or feedback_active() or get_viewport().gui_get_focus_owner()!=toggle_button: return
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(summary_label)
			return
		ancestor = ancestor.get_parent()

func _symbols(symbols: Array) -> String:
	var names: PackedStringArray = []
	for value: Variant in symbols.slice(0,12): names.append(["A","B","C","D"][int(value)] if int(value) in range(4) else "?")
	return " ".join(names)+(words(" …（其余见原证据）"," … (more in original evidence)") if symbols.size()>12 else "")

func _cost(value: Dictionary) -> String:
	if value.is_empty(): return words("无该阶段实测。","No measurement for this stage.")
	return "%s ops · %s B · %s %s"%[str(value.get("cpu_ops",0)),str(value.get("transfer_bytes",0)),str(value.get("total_cycles",0)),words("周期","cycles")]

func _refresh() -> void:
	if not is_instance_valid(body): return
	toggle_button.text = words("C → P → G 回顾","C → P → G review")
	toggle_button.tooltip_text = words("可选回顾：只查看本次真实记录，不运行或保存。","Optional review: view actual observations from this visit; no run or save.")
	scope_label.text = words("候选壹回应 · 独立运行记录，不是共同历史或文明事件回放。","Candidate Yi response · separate run records, not a shared history or a civilization replay.")
	var titles: Array[String] = [words("C 复原","C Restore"),words("P 已揭晓","P Revealed"),words("G 回灌","G Feedback"),words("已保存作品","Saved work")]
	for index: int in 4:
		step_buttons[index].text = titles[index]
		step_buttons[index].set_pressed_no_signal(index==step)
	image.step = step
	image.queue_redraw()
	var kind: String = ["transport","prediction","generation","work"][step]
	var record: Dictionary = records.get(kind,{})
	locate_button.text = words("定位原作品列表","Locate original work list") if step==3 else words("定位当前原证据","Locate current original evidence")
	locate_button.disabled = record.is_empty() or (str(record.get("id","")).is_empty() if step==3 else not locatable.get(kind,false))
	locate_button.focus_mode = Control.FOCUS_NONE if locate_button.disabled else Control.FOCUS_ALL
	identity_label.text = ""
	if record.is_empty():
		summary_label.text = words("本次没有这一步的运行记录。旧权限或作品不补造 C/P/G 经历。","No observation for this step in this visit. Permissions and saved works do not invent C/P/G runs.")
		response_label.text = words("壹（候选）：这里留白，直到你真正运行。","Yi (candidate): This stays blank until you actually run it.")
		detail_label.text = words("原 next-step 与操作按钮继续负责下一步；回顾不执行操作。","The original next-step guide and controls still own the next action. This review runs nothing.")
		return
	if step==3:
		identity_label.text = words("原作品 ID：","Original work ID: ")+str(record.get("id",""))
		summary_label.text = words("保护输出 · %d 格；完整原配方保留。","Protected output · %d cells; the full original recipe remains.")%record.get("output",[]).size()
		response_label.text = words("壹（候选）：名字之外，还留着输出与做法。它不替我们证明一轮预测。","Yi (candidate): Beyond the name, the output and its recipe remain. They do not prove a prediction round.")
		detail_label.text = words("仅定位原列表及同一 ID，不再生或保存。原 View 按钮另行执行配方核验；未知配方仍只读原快照。","Only locate the original list and the same ID; no regeneration or save. The separate View action retains its recipe check. Unknown recipes remain original snapshots.")
		var generated: Dictionary = records.get("generation",{})
		if generated.is_empty():
			detail_label.text += words("\n本次没有这件作品的生成记录，更没有由配方补出的 C/P 经历。","\nNo generation for this work was observed in this visit; its recipe does not invent C/P history.")
		elif generated.get("recipe",{})!=record.get("recipe",{}) or generated.get("output",[])!=record.get("output",[]):
			detail_label.text += words("\n它与本次 G 记录不同；两份输出与配方各自保留。","\nIt differs from this visit's G record; each output and recipe remains separate.")
		return
	identity_label.text = words("原规则盒 ","Recorded rules ")+str(record.get("model_id","")).substr(0,12)+" · "+words("记录摘要 ","record digest ")+str(record.get("trace_signature","")).substr(0,8)+"\n"+_identity_scope()
	var lines: PackedStringArray = []
	if step==0:
		lines.append("%s · %s · %d → %d"%[str(record.get("codec","")),words("无损一致","exact restoration") if record.get("lossless",false) else words("未复原一致","restoration differs"),record.get("input",[]).size(),record.get("output",[]).size()])
		lines.append(_cost(record.get("cost",{})))
		response_label.text = words("壹（候选）：抵达的还是那段材料。包省不省，去原账本核对。","Yi (candidate): The same material arrived. Check the original ledger to see what its packet costs.")
		detail_label.text = words("公开输入：","Public input: ")+_symbols(record.get("input",[]))
		detail_label.text += "\n"+words("输入摘要：","Input digest: ")+JSON.stringify(record.get("input",[])).sha256_text().substr(0,12)
		if record.get("codec","")!="predictive": detail_label.text += words("\nRAW 原样搬运不构成规则盒预测复原证据。","\nRAW transport is not evidence of predictive restoration by a rule box.")
	elif step==1:
		var rows: Array = record.get("rows",[])
		lines.append("%s · %s %d · %s %s"%[str(record.get("kind","")),words("已揭晓","revealed"),rows.size(),words("本轮开始前已见","seen before this run"),str(record.get("seen",false))])
		if not record.get("pending",{}).is_empty(): lines.append(words("已提交猜测 ","Committed guess ")+_symbols([record.pending.symbol])+words(" · 真值未揭晓"," · truth is sealed"))
		elif not rows.is_empty(): lines.append(words("最后已揭晓：","Last revealed: ")+_symbols([rows[-1].predicted])+" → "+_symbols([rows[-1].truth]))
		else: lines.append(words("尚未揭晓；不填下一格。","Nothing revealed yet; the next cell stays blank."))
		response_label.text = words("壹（候选）：先留下猜测，再允许这一格的答案到来。","Yi (candidate): Leave a guess first, then let this cell's answer arrive.")
		detail_label.text = words("公开前缀：","Public prefix: ")+_symbols(record.get("prefix",[]))+"\n"+_cost(record.get("evidence",{}).get("cost",{}))
		if record.get("kind","") in ["training","memorize"]: detail_label.text += words("\n已见材料/背诵基线，不是未见表现。","\nSeen material / position-memory baseline; not unseen performance.")
	else:
		lines.append(words("实际回灌输出 · %d 格 · 无标准续篇","Actual feedback output · %d cells · no target continuation")%record.get("output",[]).size())
		lines.append(_cost(record.get("cost",{})))
		response_label.text = words("壹（候选）：这里没有标准续篇。只有这份实际输出，和产生它的做法。","Yi (candidate): There is no target continuation here. There is this actual output, and the recipe that produced it.")
		detail_label.text = words("原起始片段：","Recorded initial passage: ")+_symbols(record.get("recipe",{}).get("initial",[]))
		detail_label.text += "\n"+words("配方摘要：","Recipe digest: ")+JSON.stringify(record.get("recipe",{}),"",true).sha256_text().substr(0,12)
		if not records.get("work",{}).is_empty() and records.work.get("recipe",{})==record.get("recipe",{}) and records.work.get("output",[])==record.get("output",[]):
			detail_label.text += words("\n这份输出已绑定真实保存 ID：","\nThis output is bound to saved ID: ")+str(records.work.id)
	if record.get("draft",{})!=current_draft: lines.append(words("当前草稿已不同；这里保留原记录。","The current draft differs; this remains the recorded result."))
	summary_label.text = "\n".join(lines)
	detail_label.text += words("\n各阶段独立实测，不相加。定位只在原证据仍为同一份时可用。","\nStages are independently measured, never added together. Location is available only while the original evidence still matches.")

func _identity_scope() -> String:
	var models: Array = []
	var machines: Array = []
	for kind: String in ["transport","prediction","generation"]:
		var record: Dictionary = records.get(kind,{})
		if record.is_empty(): continue
		if not models.has(record.get("model_id","")): models.append(record.get("model_id",""))
		if not machines.has(record.get("machine",{})): machines.append(record.get("machine",{}))
	var result: String = words("各自输入独立", "independent inputs")
	if models.size()>1: result += words(" · 规则盒不同", " · different rules")
	if machines.size()>1: result += words(" · 机器不同", " · different machines")
	return result
