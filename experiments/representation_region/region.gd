extends Control
## Candidate plan editor. Opt-in isolated sessions never affect campaign saves.
const Model = preload("res://experiments/representation_region/model.gd")
const Catalog = preload("res://experiments/representation_region/catalog.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const SessionStore = preload("res://experiments/representation_region/session_store.gd")
var persistent_session: bool = false
var save_blocked: bool = false
var session_notice: String = ""
var session_version: String = ""
var session_dirty: bool = false
var previous_auto_quit: bool = true
var drafts: Dictionary = {}
var english: bool = false
var task: int = 0
var plan: Array[Dictionary] = Model.initial_plan()
var undo_stack: Array[Array] = []
var redo_stack: Array[Array] = []
var history: Array[Dictionary] = []
var completed: Array[bool] = [false,false,false,false,false]
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
var reuse_button: Button
var byte_boards: Array[Control] = []
var public_order_choice: OptionButton
var preview_order: int = 0
var trace_player: Control
var trace_play: Button
var trace_step: Button
var order_choice: OptionButton
var events: Tree
var details: RichTextLabel
var result: Label
var mission: Label
var draft_label: Label
var status: Label
var visible_trace: Trace

func _ready() -> void:
	theme = Theme.new()
	InstrumentTheme.apply_to(theme)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english = true
		if arg == "--candidate-save": persistent_session = true
	if persistent_session:
		previous_auto_quit = get_tree().auto_accept_quit
		get_tree().auto_accept_quit = false
		restore_session()
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
	byte_boards.clear()
	var bg := ColorRect.new(); bg.color = Color("0b1720")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,16)
	add_child(margin)
	var page := VBoxContainer.new(); page.add_theme_constant_override("separation",8); margin.add_child(page)
	var top := HBoxContainer.new(); page.add_child(top)
	var title := make_label(text2("表示候选区 · 构造方案，比较真实服务","Candidate representation region · Build, measure, compare"),top,24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	make_button("中文 / EN",top,func() -> void: english = not english; build(),"Language")
	make_button(text2("退出","Quit"),top,request_quit,"Quit")
	make_label(text2("隔离候选 · 不改变主线存档 · 周期来自模型 · 五份任务 · 推荐按编号探索 · 第4任务计入在线准备","Isolated candidate · no campaign save changes · model cycles · five freely accessible tasks · recommended numbered order · task4 includes preparation"),page,13)
	var nav := HBoxContainer.new(); page.add_child(nav)
	for i: int in 5:
		var b := make_button(Catalog.title(i,english),nav,func() -> void: change_task(i),"Task"+str(i))
		b.add_theme_font_size_override("font_size",13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; task_buttons.append(b)
	mission = make_label(mission_text(),page,14); mission.name = "Mission"
	var hint := make_button(text2("看一个线索（不揭示方案）","A clue, not a solution"),page,func() -> void: status.text = Catalog.hint(task,english),"Hint1")
	hint.tooltip_text = Catalog.hint(task,english)
	var body := HSplitContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.name = "WorkspaceSplit"; body.split_offset = 40; page.add_child(body)
	var edit_scroll := ScrollContainer.new(); edit_scroll.name = "EditorScroll"; edit_scroll.custom_minimum_size.x = 530; edit_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(edit_scroll)
	var editor := VBoxContainer.new(); editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL; edit_scroll.add_child(editor)
	make_label(text2("公开资产（十进制字节，地址0–63）","Public assets (decimal bytes, addresses 0–63)"),editor,17)
	var data := Label.new(); data.name = "Asset"; data.custom_minimum_size.y = 104 if task != 4 else 210
	data.autowrap_mode = TextServer.AUTOWRAP_OFF
	data.add_theme_font_size_override("font_size",13)
	var values: Array[int] = Model.asset(task)
	var data_rows: Array[String] = []
	for start: int in range(0,64,16): data_rows.append("%02d–%02d: %s" % [start,start+15,str(values.slice(start,start+16))])
	if task == 4:
		data_rows.append(text2("资产B：","Asset B:"))
		var second: Array[int] = Catalog.asset(5)
		for start: int in range(0,64,16): data_rows.append("%02d–%02d: %s" % [start,start+15,str(second.slice(start,start+16))])
	data.text = "\n".join(data_rows)
	make_label(text2("同值同色 · 顶边蓝=RAW，绿=RLE · 点击字节选中分块", "Equal bytes share a color · blue top=RAW, green=RLE · click a byte to select its block"),editor,13)
	public_order_choice = OptionButton.new(); public_order_choice.name = "PublicOrderPreview"
	public_order_choice.add_item(text2("不标记请求", "No request markers"))
	for public_order: Dictionary in Catalog.orders(task): public_order_choice.add_item(str(public_order.name))
	preview_order = mini(preview_order,public_order_choice.item_count-1)
	public_order_choice.select(preview_order)
	public_order_choice.item_selected.connect(func(index: int) -> void: preview_order = index; refresh_request_preview())
	editor.add_child(public_order_choice)
	make_label(text2("金色底线=该订单请求地址；悬停×次数（每位客户），不表示缓存命中", "Gold underline=requested address; hover × count per client, not cache hits"),editor,12)
	for asset_index: int in (2 if task == 4 else 1):
		if task == 4: make_label(text2("资产A" if asset_index == 0 else "资产B", "Asset A" if asset_index == 0 else "Asset B"),editor,14)
		var board = preload("res://experiments/representation_region/byte_board.gd").new()
		board.name = "ByteBoard"+str(asset_index)
		board.block_selected.connect(func(index: int) -> void: selected_block = index; refresh_plan())
		editor.add_child(board); byte_boards.append(board)
	make_button(text2("展开/收起原始字节列表", "Show/hide the raw byte list"),editor,func() -> void: data.visible = not data.visible,"ToggleAssetList")
	data.visible = false
	editor.add_child(data)
	draft_label = make_label("",editor,14)
	blocks = Tree.new(); blocks.name = "Blocks"; blocks.columns = 4; blocks.hide_root = true; blocks.column_titles_visible = true
	for i: int in 4: blocks.set_column_title(i,[text2("区间 [起点,终点)","Range [start,end)"),text2("表示","Codec"),text2("存储B","Stored B"),text2("载荷+目录","Payload + directory")][i])
	blocks.custom_minimum_size.y = 190; blocks.size_flags_vertical = Control.SIZE_EXPAND_FILL; editor.add_child(blocks)
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
	InstrumentTheme.primary(run_button)
	if persistent_session:
		var save_button := make_button(text2("保存本次方案与对照", "Save drafts and comparisons"),editor,save_session,"SaveSession")
		save_button.disabled = save_blocked
		InstrumentTheme.primary(save_button,Color("62dca7"))
	status = make_label(text2("选择区间，再分割/合并或改变该块表示。","Select a block, then split/merge or change its codec."),editor,14)
	var evidence_scroll := ScrollContainer.new(); evidence_scroll.name = "EvidenceScroll"; evidence_scroll.custom_minimum_size.x = 430; evidence_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(evidence_scroll)
	var evidence := VBoxContainer.new(); evidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL; evidence_scroll.add_child(evidence)
	make_label(text2("实际运行记录（选择旧记录复查）","Recorded runs (select an older run to inspect)"),evidence,17)
	history_list = ItemList.new(); history_list.name = "History"; history_list.custom_minimum_size.y = 90; evidence.add_child(history_list); history_list.item_selected.connect(select_run)
	reuse_button = make_button(text2("从选中方案继续试", "Try a variation of this plan"),evidence,reuse_recorded_plan,"ReusePlan")
	reuse_button.tooltip_text = text2("复制自己的旧方案到对应任务草稿；旧记录不变，覆盖的草稿可撤销。", "Copy your recorded plan into its task draft. The record stays unchanged; Undo restores the previous draft.")
	result = make_label("",evidence,14)
	order_choice = OptionButton.new(); order_choice.name = "RecordedOrder"; evidence.add_child(order_choice)
	order_choice.item_selected.connect(func(i: int) -> void: show_trace(i))
	var playback_row := HBoxContainer.new(); evidence.add_child(playback_row)
	trace_player = preload("res://experiments/representation_region/trace_player.gd").new()
	trace_player.name = "TracePlayer"
	trace_play = make_button(text2("回放真实事件", "Replay recorded events"),playback_row,trace_player.toggle_play,"TracePlay")
	trace_step = make_button(text2("下一事件", "Next event"),playback_row,trace_player.step,"TraceStep")
	trace_play.disabled = true; trace_step.disabled = true
	trace_player.playing_changed.connect(func(value: bool) -> void: trace_play.text = text2("暂停回放", "Pause replay") if value else text2("回放真实事件", "Replay recorded events"))
	trace_player.event_selected.connect(select_replay_event)
	evidence.add_child(trace_player)
	events = Tree.new(); events.name = "Events"; events.columns = 3; events.column_titles_visible = true; events.hide_root = true; events.custom_minimum_size.y = 190; events.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i: int in 3: events.set_column_title(i,[text2("起点","Start"),text2("周期","Cycles"),text2("事件","Event")][i])
	evidence.add_child(events)
	details = RichTextLabel.new(); details.name = "TraceDetails"; details.custom_minimum_size.y = 150; details.size_flags_vertical = Control.SIZE_EXPAND_FILL; evidence.add_child(details)
	events.item_selected.connect(func() -> void:
		var row: TreeItem = events.get_selected()
		if row != null:
			details.text = event_text(row.get_metadata(0))
			var index: int = int(row.get_metadata(1))
			if trace_player.current != index: trace_player.seek(index))
	refresh_plan(); refresh_history(); refresh_tasks()
	if not session_notice.is_empty(): status.text = session_notice
	if selected_run >= 0 and selected_run < history.size(): select_run(selected_run)

func goal_text(goals: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in goals:
		var label: String = str(key)
		match key:
			"total_cycles": label = text2("总周期", "total cycles")
			"stored_bytes": label = text2("存储B", "stored B")
			"traffic_bytes": label = text2("服务搬运B", "service traffic B")
		parts.append("%s≤%d" % [label,goals[key]])
	return ", ".join(parts)

func order_within_limits(task_index: int, index: int, trace: Trace) -> bool:
	# Presentation diagnosis only. Model.meets remains completion authority.
	var specs: Array[Dictionary] = Catalog.orders(task_index)
	var goals: Array[Dictionary] = Catalog.goals(task_index)
	if index < 0 or index >= goals.size() or not trace.passed: return false
	if trace.metrics.get("spec",{}) != specs[index]: return false
	for metric: String in goals[index]:
		if not trace.metrics.has(metric) or int(trace.metrics[metric]) > int(goals[index][metric]): return false
	return true

func constraint_feedback(task_index: int, traces: Array) -> String:
	var failures: Array[String] = []
	var goals: Array[Dictionary] = Catalog.goals(task_index)
	if traces.size() != goals.size(): return text2("运行证据不完整。", "Run evidence is incomplete.")
	for i: int in traces.size():
		var trace: Trace = traces[i]
		if not trace.passed:
			failures.append(text2("订单%d：输出或输入校验未通过。", "Order %d: output or input validation failed.") % [i+1])
			continue
		for metric: String in goals[i]:
			var actual: int = int(trace.metrics.get(metric, -1))
			var limit: int = int(goals[i][metric])
			if actual <= limit: continue
			var label: String = text2("总周期", "cycles") if metric == "total_cycles" else (text2("存储", "storage") if metric == "stored_bytes" else text2("服务搬运", "service traffic"))
			var unit: String = "" if metric == "total_cycles" else "B"
			failures.append(text2("订单%d：%s超出%d%s（实际%d / 上限%d）。", "Order %d: %s exceeds the limit by %d%s (actual %d / limit %d).") % [i+1,label,actual-limit,unit,actual,limit])
	return "\n".join(failures)

func mission_text() -> String:
	var lines: Array[String] = []
	for i: int in Model.orders(task).size():
		var spec: Dictionary = Model.orders(task)[i]
		lines.append("%s: %s · cache%dB · clients%d · %s" % [spec.name,str(spec.addresses) if spec.addresses.size() < 10 else "0…63",spec.cache_bytes,spec.clients,goal_text(Catalog.goals(task)[i])])
	lines.append(text2("链路1B/周期；请求4周期；编码/解码8ops/周期；消费1周期；恢复上限64B。各订单同一方案、缓存从空开始。", "Link1B/cycle; request4; encode/decode8ops/cycle; consume1; scratch64B. Same plan for all orders, each starts cold."))
	if task == 3: lines.append(text2("在线准备：RAW引用64B源，只写4B目录；RLE读取原区间、编码、写载荷+目录。存储/峰值包含保留的64B源。八位客户共用一次准备。", "Online preparation: RAW references the retained64B source and writes4B directory; RLE reads source, encodes, writes payload+directory. Storage/peak include64B source. Eight clients share preparation."))
	return "\n".join(lines)

func change_task(index: int) -> void:
	if index < 0 or index >= 5: return
	if index != task: mark_session_dirty()
	drafts[task] = {"plan":plan.duplicate(true),"undo":undo_stack.duplicate(true),"redo":redo_stack.duplicate(true),"selection":selected_block}
	task = index
	if persistent_session: session_notice = text2("当前任务选择未保存；退出前点击保存。", "Current task selection is unsaved; save before quitting.")
	var saved: Dictionary = drafts.get(task,{"plan":Model.initial_plan(),"undo":[],"redo":[],"selection":0})
	plan.assign(saved.plan); undo_stack.assign(saved.undo); redo_stack.assign(saved.redo); selected_block = int(saved.selection)
	build()

func refresh_tasks() -> void:
	for i: int in task_buttons.size():
		task_buttons[i].disabled = false
		task_buttons[i].text = Catalog.title(i,english) + (" ✓" if completed[i] else "")

func edit_plan(next: Array[Dictionary]) -> void:
	if next == plan: return
	mark_session_dirty()
	undo_stack.append(plan.duplicate(true)); redo_stack.clear(); plan = next.duplicate(true)
	selected_block = clampi(selected_block,0,plan.size()-1); refresh_plan()
	status.text = text2("方案已变。旧运行仍是原方案的结果；请重新运行。","Draft changed. Recorded results still belong to their original plans; run again.")

func undo() -> void:
	if undo_stack.is_empty(): return
	mark_session_dirty()
	redo_stack.append(plan.duplicate(true)); plan.assign(undo_stack.pop_back()); selected_block = mini(selected_block,plan.size()-1); refresh_plan()
	status.text = text2("已撤销；旧结果不变。","Undone; recorded results preserved.")

func redo() -> void:
	if redo_stack.is_empty(): return
	mark_session_dirty()
	undo_stack.append(plan.duplicate(true)); plan.assign(redo_stack.pop_back()); selected_block = mini(selected_block,plan.size()-1); refresh_plan()
	status.text = text2("已重做；请重新运行。","Redone; run again.")

func refresh_plan() -> void:
	blocks.clear(); var root_row: TreeItem = blocks.create_item()
	var evidence: Array[Dictionary] = Model.block_evidence(Model.asset(task),plan)
	var stored: int = 0; var online_writes: int = 0
	for i: int in evidence.size():
		var block: Dictionary = evidence[i]; stored += int(block.stored_bytes)
		online_writes += int(block.stored_bytes) if block.codec == "rle" else 4
		var row: TreeItem = blocks.create_item(root_row); row.set_metadata(0,i)
		row.set_text(0,"[%d, %d)" % [block.start,block.end]); row.set_text(1,str(block.codec)); row.set_text(2,str(block.stored_bytes)); row.set_text(3,"%d + %d" % [block.payload_bytes,block.metadata_bytes])
		row.set_tooltip_text(0,JSON.stringify(block,"  "))
		if i == selected_block: row.select(0)
	draft_label.text = text2("当前草稿：%d块 · 实际编码后存储%dB · 所有字节恰好覆盖一次","Current draft: %d blocks · actual encoded storage %dB · every byte covered exactly once") % [plan.size(),stored]
	if task == 3: draft_label.text += text2("；保留源后实际存储/准备峰值%dB", "; retained-source storage/preparation peak%dB") % [64+online_writes]
	refresh_actions()

func refresh_request_preview() -> void:
	var orders: Array[Dictionary] = Catalog.orders(task)
	for board: Control in byte_boards:
		var addresses: Array = []
		if preview_order > 0 and preview_order <= orders.size():
			var order: Dictionary = orders[preview_order-1]
			if board.values == order.data: addresses = order.addresses
		board.set_requests(addresses)

func refresh_actions() -> void:
	if split_at == null: return
	for i: int in byte_boards.size():
		byte_boards[i].configure(Model.asset(task) if i == 0 else Catalog.asset(5),plan,selected_block)
	refresh_request_preview()
	var block: Dictionary = plan[selected_block]
	split_button.disabled = plan.size() >= Model.MAX_BLOCKS or int(split_at.value) <= int(block.start) or int(split_at.value) >= int(block.end)
	merge_button.disabled = selected_block + 1 >= plan.size()
	raw_button.disabled = block.codec == "raw"; rle_button.disabled = block.codec == "rle"
	undo_button.disabled = undo_stack.is_empty(); redo_button.disabled = redo_stack.is_empty()

func run_current() -> void:
	mark_session_dirty()
	var traces: Array[Trace] = []
	for spec: Dictionary in Model.orders(task): traces.append(Model.run(spec,plan))
	var accepted: bool = Model.meets(task,traces)
	history.append({"task":task,"plan":plan.duplicate(true),"traces":traces,"accepted":accepted})
	if history.size() > 100: history.pop_front()
	completed[task] = completed[task] or accepted
	selected_run = history.size()-1; refresh_history(); history_list.select(selected_run); history_list.call_deferred("ensure_current_is_visible"); select_run(selected_run); refresh_tasks()
	status.text = text2("全部公开约束成立；可以继续比较，也可打开下一任务。","All public constraints met; keep comparing or open the next task.") if accepted else text2("尚未满足全部约束。看流量、请求、解码与缓存事件再修改。","Limits not all met. Inspect traffic, requests, decode and cache events before editing.")
	if not accepted:
		status.text = constraint_feedback(task,traces)
		for i: int in traces.size():
			if not order_within_limits(task,i,traces[i]):
				order_choice.select(i); show_trace(i); break
	elif not completed.has(false):
		status.text = text2("五份任务均已达标。保存你的方案与比较记录，或继续探索不同取舍。", "All five tasks met. Save your plans and comparisons, or explore different trade-offs.")
	elif task == 4:
		status.text = text2("本任务已达标。可以回看之前的任务，或继续比较其他方案。", "This task is met. Revisit earlier tasks or keep comparing alternatives.")

func refresh_history() -> void:
	history_list.clear()
	reuse_button.disabled = selected_run < 0 or selected_run >= history.size()
	for i: int in history.size():
		var row: Dictionary = history[i]; var times: Array[String] = []
		for trace: Trace in row.traces: times.append(str(trace.metrics.total_cycles))
		history_list.add_item("#%d · T%d · %s · %s cycles · %dB" % [i+1,int(row.task)+1,text2("达标","Met") if row.accepted else text2("未达标","Unmet")," / ".join(times),int(row.traces[0].metrics.stored_bytes)])
		history_list.set_item_tooltip(i,JSON.stringify(row.plan,"  "))

func select_run(index: int) -> void:
	if index < 0 or index >= history.size(): return
	selected_run = index; var row: Dictionary = history[index]
	history_list.select(index); history_list.ensure_current_is_visible()
	order_choice.clear()
	for i: int in row.traces.size():
		var trace: Trace = row.traces[i]
		var badge: String = text2("达标", "Met") if order_within_limits(int(row.task),i,trace) else text2("未达标", "Unmet")
		order_choice.add_item("[%s] %s" % [badge,str(trace.metrics.spec.name)])
	order_choice.select(0); show_trace(0)

func show_trace(index: int) -> void:
	var row: Dictionary = history[selected_run]
	if index < 0 or index >= row.traces.size(): return
	visible_trace = row.traces[index]
	var m: Dictionary = visible_trace.metrics
	result.text = text2("记录#%d（任务%d）：%d周期 = 准备%d + 服务%d\n存储%dB · 服务搬运%dB · 准备读%dB/写%dB · 编码%dops\n解码%d周期 · 请求%d · 消费%d · hit/miss %d/%d · cache峰值%dB", "Run#%d (task%d): %d cycles = prepare%d + serve%d\nStored%dB · service traffic%dB · prepare read%dB/write%dB · encode%dops\nDecode%dcycles · requests%d · consume%d · hit/miss %d/%d · cache peak%dB") % [selected_run+1,int(row.task)+1,m.total_cycles,m.preparation_cycles,m.service_cycles,m.stored_bytes,m.traffic_bytes,m.source_read_bytes,m.prepared_write_bytes,m.encode_ops,m.decode_cycles,m.request_cycles,m.consume_cycles,m.cache_hits,m.cache_misses,m.peak_cache_bytes]

	result.text += text2("\n所有阶段总搬运%dB · 准备后端存储峰值%dB（不含恢复缓冲）", "\nAll-phase traffic%dB · preparation backing-storage peak%dB (excludes recovery scratch)") % [m.total_traffic_bytes,m.peak_preparation_bytes]
	if selected_run > 0:
		var old: Dictionary = history[selected_run-1]
		for prior: Trace in old.traces:
			if prior.metrics.spec == m.spec:
				result.text += text2("\n对同订单上一记录：周期%+d，搬运%+dB，存储%+dB", "\nVersus prior same-order run: cycles%+d, traffic%+dB, stored%+dB") % [int(m.total_cycles)-int(prior.metrics.total_cycles),int(m.traffic_bytes)-int(prior.metrics.traffic_bytes),int(m.stored_bytes)-int(prior.metrics.stored_bytes)]
	var limit_feedback: String = constraint_feedback(int(row.task),row.traces)
	if not limit_feedback.is_empty(): result.text += "\n" + limit_feedback
	events.clear(); var root_row: TreeItem = events.create_item()
	var replay_events: Array = []
	for event: RefCounted in visible_trace.events:
		var item: TreeItem = events.create_item(root_row); item.set_text(0,str(event.cycle)); item.set_text(1,str(event.duration)); item.set_text(2,"%s @%d" % [str(event.kind),event.address]); item.set_metadata(0,{"kind":str(event.kind),"duration":event.duration,"details":event.details.duplicate(true)})
		item.set_metadata(1,replay_events.size()); replay_events.append(event.to_dictionary())
	if root_row.get_first_child() != null: events.scroll_to_item(root_row.get_first_child())
	trace_player.configure(replay_events,english)
	trace_play.disabled = replay_events.is_empty(); trace_step.disabled = replay_events.is_empty()
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
	if event.kind.begins_with("prepare_") or event.kind == "encode":
		return line + JSON.stringify(d,"  ")
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

func public_observation() -> Dictionary:
	var assets: Array[Array] = []; var addresses: Array[Array] = []
	for spec: Dictionary in Model.orders(task): assets.append(spec.data.duplicate()); addresses.append(spec.addresses.duplicate())
	var measured: Array[Dictionary] = []
	for row: Dictionary in history:
		if int(row.task) != task: continue
		var runs: Array[Dictionary] = []
		for trace: Trace in row.traces:
			var event_rows: Array[Dictionary] = []
			for event: RefCounted in trace.events: event_rows.append(event.to_dictionary())
			runs.append({"metrics":trace.metrics.duplicate(true),"events":event_rows})
		measured.append({"plan":row.plan.duplicate(true),"accepted":row.accepted,"runs":runs})
	return {"task":task,"mission":mission_text(),"hint":Catalog.hint(task,english),"assets":assets,"orders":addresses,"plan":plan.duplicate(true),"latest":measured[-1] if not measured.is_empty() else {},"measured":measured,"accepted":completed[task],"public_goals":Catalog.goals(task).duplicate(true),"controls":{"split_min":1,"split_max":63,"max_blocks":8},"machine":Model.orders(task).map(func(spec: Dictionary) -> Dictionary: return {"cache_bytes":spec.cache_bytes,"bandwidth":spec.bandwidth,"latency":spec.latency,"decoder":spec.decoder,"encoder":spec.encoder,"clients":spec.clients,"online":spec.online})}

func restore_session() -> void:
	var saved: Dictionary = SessionStore.read_session()
	if not saved.ok:
		save_blocked = true
		session_notice = text2("已有候选存档无法安全读取，已保留原文件并禁止覆盖。", "Existing candidate save could not be safely read; original preserved, saving blocked.")
		return
	session_version = str(saved.get("digest", ""))
	if saved.get("empty",false):
		session_notice = text2("独立候选档：退出前点击保存。撤销栈仅在本次会话保留。", "Isolated candidate profile: save before quitting. Undo stacks are session-only.")
		return
	for i: int in 5:
		drafts[i] = {"plan":saved.drafts[i].duplicate(true),"undo":[],"redo":[],"selection":0}
	task = int(saved.task); plan.assign(saved.drafts[task])
	for run: Dictionary in saved.runs:
		var traces: Array[Trace] = []
		for spec: Dictionary in Model.orders(int(run.task)): traces.append(Model.run(spec,run.plan))
		var accepted: bool = Model.meets(int(run.task),traces)
		history.append({"task":int(run.task),"plan":run.plan.duplicate(true),"traces":traces,"accepted":accepted})
		completed[int(run.task)] = completed[int(run.task)] or accepted
	selected_run = history.size()-1
	session_notice = text2("已恢复草稿；%d条对照按相同模型重新计算。未授予主线进度。", "Drafts restored; %d comparisons recomputed with the matching model. No campaign progress granted.") % history.size()

func save_session() -> void:
	if not persistent_session or save_blocked: return
	var saved_drafts: Array = []
	for i: int in 5:
		saved_drafts.append(plan.duplicate(true) if i == task else drafts.get(i,{"plan":Model.initial_plan()}).plan.duplicate(true))
	var runs: Array = []
	for run: Dictionary in history: runs.append({"task":int(run.task),"plan":run.plan.duplicate(true)})
	var raw: String = SessionStore.encode(task,saved_drafts,runs)
	var error: Error = SessionStore.write_session(raw, SessionStore.PATH, session_version)
	if error == OK:
		session_version = raw.sha256_text()
		session_dirty = false
	session_notice = text2("已保存独立候选档；同一配置再次启动可继续。", "Saved isolated candidate profile; reopen the same profile to continue.") if error == OK else text2("保存失败，未覆盖已有存档；请保留当前窗口。", "Save failed without overwriting the existing save; keep this window open.")
	status.text = session_notice

func mark_session_dirty() -> void:
	if not persistent_session: return
	session_dirty = true
	session_notice = ""

func reuse_recorded_plan() -> void:
	if selected_run < 0 or selected_run >= history.size(): return
	var record_index: int = selected_run
	var recorded: Dictionary = history[record_index]
	if int(recorded.task) != task: change_task(int(recorded.task))
	var copied: Array[Dictionary] = []
	copied.assign(recorded.plan.duplicate(true))
	if copied == plan:
		status.text = text2("当前草稿已是这份方案；直接修改或运行即可。", "This plan is already your draft; edit or run it directly.")
		return
	edit_plan(copied)
	status.text = text2("已取回方案#%d；可以改一点再运行。旧记录保留，原草稿可撤销恢复。", "Plan #%d is ready to vary and run. Its old record is preserved; Undo can restore the previous draft.") % [record_index+1]

func request_quit() -> void:
	if not persistent_session or not session_dirty:
		get_tree().quit()
		return
	if get_node_or_null("UnsavedSessionDialog") != null:
		(get_node("UnsavedSessionDialog") as ConfirmationDialog).popup_centered()
		return
	var dialog := ConfirmationDialog.new()
	dialog.name = "UnsavedSessionDialog"
	dialog.title = text2("保存这次探索？", "Save this exploration?")
	dialog.dialog_text = text2("草稿或对照记录有未保存的变化。", "Drafts or comparison records have unsaved changes.")
	dialog.ok_button_text = text2("保存并退出", "Save and quit")
	dialog.cancel_button_text = text2("继续编辑", "Keep editing")
	dialog.add_button(text2("不保存退出", "Quit without saving"),true,"discard")
	dialog.confirmed.connect(func() -> void:
		save_session()
		if not session_dirty: get_tree().quit())
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard": get_tree().quit())
	add_child(dialog)
	dialog.popup_centered(Vector2i(520,180))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and persistent_session: request_quit()

func _exit_tree() -> void:
	if persistent_session: get_tree().auto_accept_quit = previous_auto_quit

func select_replay_event(index: int) -> void:
	if events == null or events.get_root() == null: return
	var row: TreeItem = events.get_root().get_first_child()
	var cursor: int = 0
	while row != null:
		if cursor == index:
			if events.get_selected() != row: row.select(0)
			events.ensure_cursor_is_visible()
			return
		row = row.get_next(); cursor += 1
