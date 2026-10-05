extends VBoxContainer
## Static prefix replay of one copied measurement. Never runs or decodes a plan.
signal frame_changed(source_index: int)
const Projector = preload("res://experiments/service_plan/state_replay.gd")
const Presenter = preload("res://experiments/service_plan/event_presenter.gd")
var current_source_index: int = -1
var frames: Array[Dictionary] = []
var frame_position: int = -1
var english: bool = false
var source_caption: Label
var event_caption: Label
var state_content: VBoxContainer
var step_buttons: Array[Button] = []
var measured_plan: Dictionary = {}

func words(zh: String, en: String) -> String: return en if english else zh

func _init() -> void:
	custom_minimum_size = Vector2(0,240)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func _ready() -> void:
	if source_caption == null: build_controls()

func text_label(text: String, parent: Node) -> Label:
	var node := Label.new(); node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node

func build_controls() -> void:
	for child: Node in get_children(): remove_child(child); child.queue_free()
	step_buttons.clear()
	source_caption = text_label("",self); source_caption.name = "StateSource"
	var controls := HBoxContainer.new(); add_child(controls)
	var names: Array[String] = ["StateStart","StatePrevious","StateNext","StateEnd"]
	var captions: Array[String] = [words("起点","Start"),words("上一步","Previous"),words("下一步","Next"),words("终点","End")]
	for index: int in 4:
		var button := Button.new(); button.name = names[index]; button.text = captions[index]
		button.custom_minimum_size.y = 32; controls.add_child(button); step_buttons.append(button)
		button.pressed.connect(func() -> void:
			match index:
				0: select_frame(0,true)
				1: select_frame(frame_position-1,true)
				2: select_frame(frame_position+1,true)
				3: select_frame(frames.size()-1,true)
		)
	event_caption = text_label("",self); event_caption.name = "StateEvent"
	var scroll := ScrollContainer.new(); scroll.name = "StateScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y = 80
	add_child(scroll)
	state_content = VBoxContainer.new(); state_content.name = "StateLocations"
	state_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(state_content)
	refresh_view()

func configure(record: Dictionary, en: bool = false, source_index: int = -1) -> void:
	english = en; frames.clear(); measured_plan.clear(); frame_position = -1; current_source_index = -1
	var metrics: Variant = record.get("metrics")
	var events: Variant = record.get("events")
	if metrics is Dictionary and metrics.get("error") is String and str(metrics.error).is_empty() and events is Array and not events.is_empty():
		if metrics.get("plan") is Dictionary:
			measured_plan = metrics.plan.duplicate(true)
			frames = Projector.build(events)
	build_controls()
	if not frames.is_empty(): show_source_index(source_index)

func show_source_index(index: int) -> void:
	if frames.is_empty(): select_frame(-1); return
	var selected: int = 0
	for position: int in frames.size():
		if int(frames[position].source_index) > index: break
		selected = position
	select_frame(selected)

func select_frame(position: int, notify_selection: bool = false) -> void:
	frame_position = clampi(position,0,frames.size()-1) if not frames.is_empty() else -1
	current_source_index = int(frames[frame_position].source_index) if frame_position >= 0 else -1
	refresh_view()
	if notify_selection: frame_changed.emit(current_source_index)

func state_text(entry: Dictionary, resident: bool) -> String:
	if not bool(entry.get("present",false)): return words("未驻留","Not resident") if resident else words("尚无记录","Not recorded")
	var bytes: int = int(entry.get("bytes",0))
	var result: String = str(bytes)+" B"
	if resident: result += words(" · 已更新，待写回"," · dirty, pending write") if bool(entry.get("dirty",false)) else words(" · 无待写回变化"," · clean, backed")
	var values: Array = entry.get("state",[]) if entry.get("state",[]) is Array else []
	result += "\n" + (JSON.stringify(values) if not values.is_empty() else words("数值尚未记录（未解码）","Numerical state not recorded (not decoded)"))
	var request: int = int(entry.get("last_request",-1))
	if request >= 0: result += "\n"+words("最近请求：","Last request: ")+char(65+request/6)+str(request%6)
	return result

func refresh_view() -> void:
	if source_caption == null: return
	for child: Node in state_content.get_children(): state_content.remove_child(child); child.queue_free()
	for index: int in step_buttons.size(): step_buttons[index].disabled = frames.is_empty() or (frame_position <= 0 if index < 2 else frame_position >= frames.size()-1)
	if frames.is_empty():
		source_caption.text = words("尚无有效实测记录；状态位置不会由草稿预测。","No valid measured record; draft state locations are not predicted.")
		event_caption.text = ""
		return
	var groups: Variant = measured_plan.get("groups",[])
	var formats: Variant = measured_plan.get("representations",[])
	source_caption.text = words("所选实测方案：","Selected measured plan: ")+str(groups.size() if groups is Array else 0)+words("组 · 驻留槽"," groups · slots ")+str(measured_plan.get("slots","?"))+" · "+str(formats)
	var frame: Dictionary = frames[frame_position]; var event: Dictionary = frame.event
	event_caption.text = Presenter.title(event,english)+" · "+words("事件","event ")+str(current_source_index+1)+" · "+words("起始周期","start cycle ")+str(event.get("cycle","?"))+" · "+words("本事件周期","event cycles ")+str(event.get("duration","?"))
	text_label(words("事件执行后的状态；索引选择最近的前帧，无前帧则显示首帧。驻留字节是解码空间，外存字节含目录。","State after this event; source selection uses the nearest preceding frame, or the first frame if none precedes it. Resident bytes are decoded space; backing bytes include the directory."),state_content)
	for stream: int in 4:
		text_label(char(65+stream)+words(" · 外存 ↔ 驻留状态 → 已返回结果"," · Backing ↔ Resident state → Returned results"),state_content)
		var grid := GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation",12); state_content.add_child(grid)
		var resident: Dictionary = frame.residents[stream]
		var backing: Dictionary = frame.backing[stream]
		text_label(state_text(backing,false),grid)
		text_label(state_text(resident,true),grid)
		var outputs: Array[String] = []
		for response: Dictionary in frame.responses:
			if int(response.get("stream",-1)) == stream:
				var request: int = int(response.get("request_id",-1))
				outputs.append(char(65+stream)+str(request%6)+": "+words("分数 ","score ")+str(response.get("score","?"))+words(" · 误差 "," · error ")+str(response.get("error","?")))
		text_label("\n".join(outputs) if not outputs.is_empty() else words("尚未返回","No response yet"),grid)
	text_label(words("截至本事件累计状态读","State read through this event: ")+str(frame.state_read_bytes)+" B · "+words("写","write ")+str(frame.state_write_bytes)+" B",state_content)
	text_label(Presenter.summary(event,english),state_content)
	var details: Dictionary = event.get("details",{}) if event.get("details",{}) is Dictionary else {}
	if str(event.get("kind","")) == "compute":
		for key: String in ["before","after"]:
			if details.get(key) is Array:
				text_label((words("更新前：","Before update: ") if key == "before" else words("更新后：","After update: "))+JSON.stringify(details[key]),state_content)
