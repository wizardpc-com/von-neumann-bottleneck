extends Control
## Session-only plan editor. Trace receipts remain immutable when the draft changes.
const Model = preload("res://experiments/representation/plan_model.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
var english: bool = false
var task: int = 0
var plan: Array[Dictionary] = Model.initial_plan()
var undo_stack: Array[Array] = []
var redo_stack: Array[Array] = []
var history: Array[Dictionary] = []
var completed: Array[bool] = [false,false,false]
var selected_block: int = 0
var selected_run: int = -1
var task_buttons: Array[Button] = []
var blocks: Tree
var split_at: SpinBox
var split_button: Button
var merge_button: Button
var raw_button: Button
var rle_button: Button
var undo_button: Button
var redo_button: Button
var run_button: Button
var history_list: ItemList
var order_choice: OptionButton
var events: Tree
var details: RichTextLabel
var result: Label
var mission: Label
var draft_label: Label
var status: Label
var visible_trace: Trace

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english = true
	build()

func text2(zh: String, en: String) -> String: return en if english else zh

func make_label(text: String, parent: Node, size: int = 16) -> Label:
	var node := Label.new(); node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",size); parent.add_child(node)
	return node

func make_button(text: String, parent: Node, action: Callable, handle: String) -> Button:
	var node := Button.new(); node.text = text; node.name = handle
	node.custom_minimum_size.y = 38; node.pressed.connect(action); parent.add_child(node)
	return node

func build() -> void:
	for child: Node in get_children(): remove_child(child); child.queue_free()
	task_buttons.clear()
	var bg := ColorRect.new(); bg.color = Color("0b1720")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,16)
	add_child(margin)
	var page := VBoxContainer.new(); page.add_theme_constant_override("separation",8); margin.add_child(page)
	var top := HBoxContainer.new(); page.add_child(top)
	var title := make_label(text2("表示工坊 · 划块，选择表示，再运行","Representation workshop · Partition, encode, run"),top,24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	make_button("中文 / EN",top,func() -> void: english = not english; build(),"Language")
	make_button(text2("退出","Quit"),top,func() -> void: get_tree().quit(),"Quit")
	make_label(text2("隔离实验 · 无主线进度或存档 · 周期来自模型 · 编码离线，测量从已存资产开始","Isolated experiment · no campaign progress or saves · model cycles · offline encoding; runs begin with stored assets"),page,13)
	var nav := HBoxContainer.new(); page.add_child(nav)
	for i: int in 3:
		var b := make_button([text2("1 · 混合扫描","1 · Mixed scan"),text2("2 · 两个热点","2 · Two hotspots"),text2("3 · 同一方案，两份订单","3 · One plan, two orders")][i],nav,func() -> void: change_task(i),"Task"+str(i))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; task_buttons.append(b)
	mission = make_label(mission_text(),page,16)
	var body := HSplitContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.split_offset = 590; page.add_child(body)
	var editor := VBoxContainer.new(); editor.custom_minimum_size.x = 480; editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(editor)
	make_label(text2("不可变资产（十进制字节，地址0–63）","Immutable asset (decimal bytes, addresses 0–63)"),editor,17)
	var data := Label.new(); data.name = "Asset"; data.custom_minimum_size.y = 108
	data.autowrap_mode = TextServer.AUTOWRAP_OFF
	data.add_theme_font_size_override("font_size",16)
	var values: Array[int] = Model.asset()
	var data_rows: Array[String] = []
	for start: int in range(0,64,16): data_rows.append("%02d–%02d: %s" % [start,start+15,str(values.slice(start,start+16))])
	data.text = "\n".join(data_rows)
	editor.add_child(data)
	draft_label = make_label("",editor,14)
	blocks = Tree.new(); blocks.name = "Blocks"; blocks.columns = 4; blocks.hide_root = true; blocks.column_titles_visible = true
	for i: int in 4: blocks.set_column_title(i,[text2("区间 [起点,终点)","Range [start,end)"),text2("表示","Codec"),text2("存储B","Stored B"),text2("载荷+目录","Payload + directory")][i])
	blocks.custom_minimum_size.y = 150; blocks.size_flags_vertical = Control.SIZE_EXPAND_FILL; editor.add_child(blocks)
	blocks.item_selected.connect(func() -> void:
		var row: TreeItem = blocks.get_selected()
		if row != null: selected_block = int(row.get_metadata(0)); refresh_actions())
	var edit := HBoxContainer.new(); editor.add_child(edit)
	var split_label: Label = make_label(text2("分割地址","Split at"),edit,14)
	split_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	split_label.custom_minimum_size.x = 80
	split_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	split_at = SpinBox.new(); split_at.name = "SplitAt"; split_at.min_value = 1; split_at.max_value = 63; split_at.value = 16; split_at.custom_minimum_size.x = 85; edit.add_child(split_at)
	split_at.value_changed.connect(func(_v: float) -> void: refresh_actions())
	split_button = make_button(text2("分割","Split"),edit,func() -> void: edit_plan(Model.split(plan,selected_block,int(split_at.value))),"Split")
	merge_button = make_button(text2("合并右块","Merge right"),edit,func() -> void: edit_plan(Model.merge(plan,selected_block)),"Merge")
	var codec_row := HBoxContainer.new(); editor.add_child(codec_row)
	raw_button = make_button(text2("选中块 → 原始","Selected → Raw"),codec_row,func() -> void: edit_plan(Model.represent(plan,selected_block,"raw")),"Raw")
	rle_button = make_button(text2("选中块 → RLE","Selected → RLE"),codec_row,func() -> void: edit_plan(Model.represent(plan,selected_block,"rle")),"RLE")
	undo_button = make_button(text2("撤销","Undo"),codec_row,undo,"Undo")
	redo_button = make_button(text2("重做","Redo"),codec_row,redo,"Redo")
	make_label(text2("最多8块；合并保留左块表示。每块4B地址目录；RLE另有2B原长头和(count,value)对。解码操作=输出字节+run数。","At most 8 blocks; merging keeps the left codec. Every block has a 4B address directory. RLE adds a 2B length header and (count,value) pairs. Decode work=output bytes+runs."),editor,13)
	run_button = make_button(text2("运行当前方案 · 保存对照","Run current plan · record comparison"),editor,run_current,"Run")
	status = make_label(text2("选择区间，再分割/合并或改变该块表示。","Select a block, then split/merge or change its codec."),editor,14)
	var evidence := VBoxContainer.new(); evidence.custom_minimum_size.x = 430; evidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(evidence)
	make_label(text2("实际运行记录（选择旧记录复查）","Recorded runs (select an older run to inspect)"),evidence,17)
	history_list = ItemList.new(); history_list.name = "History"; history_list.custom_minimum_size.y = 90; evidence.add_child(history_list); history_list.item_selected.connect(select_run)
	result = make_label("",evidence,14)
	order_choice = OptionButton.new(); order_choice.name = "RecordedOrder"; evidence.add_child(order_choice)
	order_choice.item_selected.connect(func(i: int) -> void: show_trace(i))
	events = Tree.new(); events.name = "Events"; events.columns = 3; events.column_titles_visible = true; events.hide_root = true; events.custom_minimum_size.y = 115; events.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i: int in 3: events.set_column_title(i,[text2("起点","Start"),text2("周期","Cycles"),text2("事件","Event")][i])
	evidence.add_child(events)
	details = RichTextLabel.new(); details.name = "TraceDetails"; details.custom_minimum_size.y = 125; details.size_flags_vertical = Control.SIZE_EXPAND_FILL; evidence.add_child(details)
	events.item_selected.connect(func() -> void:
		var row: TreeItem = events.get_selected()
		if row != null: details.text = event_text(row.get_metadata(0)))
	refresh_plan(); refresh_history(); refresh_tasks()
	if selected_run >= 0 and selected_run < history.size(): select_run(selected_run)

func mission_text() -> String:
	var shared: String = text2("链路1B/cycle · 解码8ops/cycle · 请求4cycles · 每次消费1cycle。", "Link 1B/cycle · decode 8ops/cycle · request 4cycles · consume 1cycle.")
	return [text2("逐字节扫描0…63：总周期≤136，资产存储≤60B。重复区间与变化区间共用一个表示，会怎样？\n自动LRU缓存64B；恢复缓冲硬上限64B。", "Scan bytes 0…63: total≤136 cycles, stored asset≤60B. What happens when runs and changing bytes share one codec?\nAutomatic LRU cache 64B; recovery scratch limit 64B."),
	text2("请求0,63,0,63,0,63：总周期≤36，本次搬运≤16B，资产存储≤68B。\n自动LRU缓存只有32B；块放不下仍可读取，但不会缓存。先看大块的复访与过量读取。", "Read 0,63,0,63,0,63: total≤36 cycles, traffic≤16B, stored asset≤68B.\nAutomatic LRU cache is 32B; oversized blocks can be read but cannot stay cached. Inspect large-block revisits and overfetch."),
	text2("同一份划块与表示，分别运行两份订单：扫描≤136周期，热点≤36周期/搬运≤16B，存储≤60B。\n扫描cache64B；热点cache32B。比较旧记录：哪里省了字节，哪里多了请求和恢复工作？", "One partition and codec plan, two orders: scan≤136 cycles; hotspots≤36 cycles/traffic≤16B; stored≤60B.\nScan cache64B; hotspot cache32B. Compare runs: where did bytes decrease, and requests or recovery work increase?")][task] + "\n" + shared

func change_task(index: int) -> void:
	if index < 0 or index > 2 or index > 0 and not completed[index-1]: return
	task = index; mission.text = mission_text(); refresh_tasks()
	status.text = text2("保留当前方案；新订单需要重新运行。","Current plan retained; run it against the new order.")

func refresh_tasks() -> void:
	for i: int in task_buttons.size():
		task_buttons[i].disabled = i > 0 and not completed[i-1]
		task_buttons[i].modulate = Color("89e5be") if completed[i] else Color.WHITE

func edit_plan(next: Array[Dictionary]) -> void:
	if next == plan: return
	undo_stack.append(plan.duplicate(true)); redo_stack.clear(); plan = next.duplicate(true)
	selected_block = clampi(selected_block,0,plan.size()-1); refresh_plan()
	status.text = text2("方案已变。旧运行仍是原方案的结果；请重新运行。","Draft changed. Recorded results still belong to their original plans; run again.")

func undo() -> void:
	if undo_stack.is_empty(): return
	redo_stack.append(plan.duplicate(true)); plan.assign(undo_stack.pop_back()); selected_block = mini(selected_block,plan.size()-1); refresh_plan()
	status.text = text2("已撤销；旧结果不变。","Undone; recorded results preserved.")

func redo() -> void:
	if redo_stack.is_empty(): return
	undo_stack.append(plan.duplicate(true)); plan.assign(redo_stack.pop_back()); selected_block = mini(selected_block,plan.size()-1); refresh_plan()
	status.text = text2("已重做；请重新运行。","Redone; run again.")

func refresh_plan() -> void:
	blocks.clear(); var root_row: TreeItem = blocks.create_item()
	var evidence: Array[Dictionary] = Model.block_evidence(Model.asset(),plan)
	var stored: int = 0
	for i: int in evidence.size():
		var block: Dictionary = evidence[i]; stored += int(block.stored_bytes)
		var row: TreeItem = blocks.create_item(root_row); row.set_metadata(0,i)
		row.set_text(0,"[%d, %d)" % [block.start,block.end]); row.set_text(1,str(block.codec)); row.set_text(2,str(block.stored_bytes)); row.set_text(3,"%d + %d" % [block.payload_bytes,block.metadata_bytes])
		row.set_tooltip_text(0,JSON.stringify(block,"  "))
		if i == selected_block: row.select(0)
	draft_label.text = text2("当前草稿：%d块 · 实际编码后存储%dB · 所有字节恰好覆盖一次","Current draft: %d blocks · actual encoded storage %dB · every byte covered exactly once") % [plan.size(),stored]
	refresh_actions()

func refresh_actions() -> void:
	if split_at == null: return
	var block: Dictionary = plan[selected_block]
	split_button.disabled = plan.size() >= Model.MAX_BLOCKS or int(split_at.value) <= int(block.start) or int(split_at.value) >= int(block.end)
	merge_button.disabled = selected_block + 1 >= plan.size()
	raw_button.disabled = block.codec == "raw"; rle_button.disabled = block.codec == "rle"
	undo_button.disabled = undo_stack.is_empty(); redo_button.disabled = redo_stack.is_empty()

func run_current() -> void:
	var traces: Array[Trace] = []
	for spec: Dictionary in Model.orders(task): traces.append(Model.run(spec,plan))
	var accepted: bool = Model.meets(task,traces)
	history.append({"task":task,"plan":plan.duplicate(true),"traces":traces,"accepted":accepted})
	if history.size() > 100: history.pop_front()
	completed[task] = completed[task] or accepted
	selected_run = history.size()-1; refresh_history(); history_list.select(selected_run); select_run(selected_run); refresh_tasks()
	status.text = text2("全部公开约束成立；可以继续比较，也可打开下一任务。","All public constraints met; keep comparing or open the next task.") if accepted else text2("尚未满足全部约束。看流量、请求、解码与缓存事件再修改。","Limits not all met. Inspect traffic, requests, decode and cache events before editing.")

func refresh_history() -> void:
	history_list.clear()
	for i: int in history.size():
		var row: Dictionary = history[i]; var times: Array[String] = []
		for trace: Trace in row.traces: times.append(str(trace.metrics.total_cycles))
		history_list.add_item("#%d · %s · %s cycles · %dB" % [i+1,text2("达标","Met") if row.accepted else text2("未达标","Unmet")," / ".join(times),int(row.traces[0].metrics.stored_bytes)])
		history_list.set_item_tooltip(i,JSON.stringify(row.plan,"  "))

func select_run(index: int) -> void:
	if index < 0 or index >= history.size(): return
	selected_run = index; var row: Dictionary = history[index]
	order_choice.clear()
	for trace: Trace in row.traces: order_choice.add_item(text2("扫描","Scan") if trace.metrics.spec.name == "scan" else text2("热点","Hotspots"))
	order_choice.select(0); show_trace(0)

func show_trace(index: int) -> void:
	var row: Dictionary = history[selected_run]
	if index < 0 or index >= row.traces.size(): return
	visible_trace = row.traces[index]
	var m: Dictionary = visible_trace.metrics
	result.text = text2("记录#%d（任务%d）：%d周期 = 请求%d + 搬运%d + 解码%d + 消费%d\n存储%dB · 搬运%dB · 未请求而恢复%d个不同字节 · hit/miss %d/%d · 驱逐%d · cache峰值%dB", "Run #%d (task%d): %d cycles = request%d + transfer%d + decode%d + consume%d\nStored%dB · traffic%dB · %d distinct restored-but-unrequested bytes · hit/miss %d/%d · evictions%d · cache peak%dB") % [selected_run+1,int(row.task)+1,m.total_cycles,m.request_cycles,m.transfer_cycles,m.decode_cycles,m.consume_cycles,m.stored_bytes,m.traffic_bytes,m.overfetch_values,m.cache_hits,m.cache_misses,m.evictions,m.peak_cache_bytes]
	if selected_run > 0:
		var old: Dictionary = history[selected_run-1]
		for prior: Trace in old.traces:
			if prior.metrics.spec == m.spec:
				result.text += text2("\n对同订单上一记录：周期%+d，搬运%+dB，存储%+dB", "\nVersus prior same-order run: cycles%+d, traffic%+dB, stored%+dB") % [int(m.total_cycles)-int(prior.metrics.total_cycles),int(m.traffic_bytes)-int(prior.metrics.traffic_bytes),int(m.stored_bytes)-int(prior.metrics.stored_bytes)]
	events.clear(); var root_row: TreeItem = events.create_item()
	for event: RefCounted in visible_trace.events:
		var item: TreeItem = events.create_item(root_row); item.set_text(0,str(event.cycle)); item.set_text(1,str(event.duration)); item.set_text(2,"%s @%d" % [str(event.kind),event.address]); item.set_metadata(0,{"kind":str(event.kind),"duration":event.duration,"details":event.details.duplicate(true)})
	details.text = text2("选中事件查看实际字节、恢复输出、缓存前后和驱逐。\n记录方案：", "Select an event for actual bytes, restored values, cache before/after and evictions.\nRecorded plan: ")+plan_text(row.plan)

func plan_text(recorded: Array) -> String:
	var lines: Array[String] = []
	for block: Dictionary in recorded:
		lines.append("[%d, %d) %s" % [block.start,block.end,block.codec])
	return " · ".join(lines)

func cache_text(cache: Dictionary) -> String:
	return text2("%dB/%dB，LRU旧→新 %s", "%dB/%dB, LRU old→new %s") % [cache.used_bytes,cache.byte_budget,str(cache.lru)]

func event_text(event: Dictionary) -> String:
	var d: Dictionary = event.details
	var line: String = "%s · %d cycles · %s %d · %s %d\n" % [event.kind,event.duration,text2("地址","address"),d.address,text2("块","block"),d.block]
	if event.kind == "consume":
		line += text2("实际输出 = %d · %s\n缓存前：%s\n缓存后：%s\n驱逐块：%s", "Actual output = %d · %s\nCache before: %s\nCache after: %s\nEvicted blocks: %s") % [d.value,text2("命中","hit") if d.hit else text2("未命中","miss"),cache_text(d.cache_before),cache_text(d.cache_after),str(d.evicted)]
		if not d.cached: line += text2("\n该块超出缓存预算，使用后丢弃。","\nBlock exceeds cache budget and is discarded after use.")
	elif event.kind == "transfer":
		line += text2("区间%s · %s · 搬运%dB = 载荷%dB + 目录%dB\n目录字节：%s\n实际载荷字节：%s", "Range%s · %s · transferred%dB = payload%dB + directory%dB\nDirectory bytes: %s\nActual payload bytes: %s") % [str(d.range),d.codec,d.bytes,d.payload_bytes,d.metadata_bytes,str(d.directory),str(d.encoded)]
	elif event.kind == "decode":
		line += text2("解码%d次操作，真正恢复：\n%s", "Decode %d operations; actual restored bytes:\n%s") % [d.ops,str(d.decoded)]
	else:
		line += text2("区间%s · %s\n缓存前：%s", "Range%s · %s\nCache before: %s") % [str(d.range),d.codec,cache_text(d.cache_before)]
	return line
