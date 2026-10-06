extends Control
## Candidate plan editor. Opt-in isolated sessions never affect campaign saves.
const Model = preload("res://experiments/representation_region/model.gd")
const Catalog = preload("res://experiments/representation_region/catalog.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const SessionStore = preload("res://experiments/representation_region/session_store.gd")
const WriterRetry = preload("res://experiments/candidate_session/writer_retry.gd")
const Designs = preload("res://experiments/candidate_session/designs.gd")
const DesignShelf = preload("res://experiments/candidate_session/design_shelf.gd")
var writer_lease: RefCounted
var recovery_state: Dictionary = {}
var support_plans: Dictionary = {}
var persistent_session: bool = false
var save_blocked: bool = false
var session_notice: String = ""
var session_version: String = ""
var session_dirty: bool = false
var previous_auto_quit: bool = true
var leave_to_hub: bool = false
var leave_scene: String = ""
var leave_from_review: bool = false
var candidate_journey: bool = false
var drafts: Dictionary = {}
var english: bool = false
var task: int = 0
var plan: Array[Dictionary] = Model.initial_plan()
var undo_stack: Array[Array] = []
var redo_stack: Array[Array] = []
var history: Array[Dictionary] = []
var designs: Array[Dictionary] = []
var design_shelf: VBoxContainer
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
var recorded_plan_label: Label
var result: Label
var order_comparison: Tree
var metric_details: Label
var trace_details_group: VBoxContainer
var details_expanded: bool = false
var mission: Label
var draft_label: Label
var status: Label
var visible_trace: Trace

func _ready() -> void:
	var localization := get_node_or_null("/root/Localization")
	if localization != null: english = localization.current_locale() == "en"
	theme = Theme.new()
	InstrumentTheme.apply_to(theme)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var packaged_journey: bool = SessionStore.Context.configured_journey()
	candidate_journey = candidate_journey or packaged_journey
	persistent_session = persistent_session or packaged_journey
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english = true
		if arg == "--candidate-save": persistent_session = true
		if arg == "--candidate-journey": candidate_journey = true
	if persistent_session:
		add_to_group("candidate_quit_owners")
		previous_auto_quit = get_tree().auto_accept_quit
		get_tree().auto_accept_quit = false
		writer_lease = SessionStore.Lease.new(SessionStore.PATH)
		restore_session()
		if not writer_lease.held:
			save_blocked = true
			session_notice = text2("此候选档已由另一窗口占用，或上次未正常关闭；本窗口禁止保存。", "Another window owns this profile, or its previous session stopped unexpectedly; saving is blocked.")

	var requested: int = get_node("/root/TaskNavigation").take_pending("representation")
	if requested >= 0: change_task(requested)
	else: build()
	get_node("/root/TaskNavigation").remember_candidate_visit("representation",task)

func toggle_language() -> void:
	english = not english
	var localization := get_node_or_null("/root/Localization")
	if localization != null: localization.set_locale("en" if english else "zh_CN")
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
	make_button("中文 / EN",top,toggle_language,"Language")
	if candidate_journey: make_button(text2("任务地图", "Task map") if get_node("/root/TaskNavigation").from_tree else text2("返回首页", "Home"),top,request_hub,"CandidateHome")
	make_button(text2("区域回顾", "Region review"),top,show_closure,"RegionClosure")
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
		add_recovery_controls(editor)
	status = make_label(text2("选择区间，再分割/合并或改变该块表示。","Select a block, then split/merge or change its codec."),editor,14)
	var completed_review := make_button(text2("成果回顾与下一步" if candidate_journey else "回顾五份成果", "Review and next step" if candidate_journey else "Review five achievements"),editor,show_closure,"CompletedRegionReview")
	InstrumentTheme.primary(completed_review)
	var evidence_scroll := ScrollContainer.new(); evidence_scroll.name = "EvidenceScroll"; evidence_scroll.custom_minimum_size.x = 430; evidence_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(evidence_scroll)
	var evidence := VBoxContainer.new(); evidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL; evidence_scroll.add_child(evidence)
	make_label(text2("实际运行记录（选择旧记录复查）","Recorded runs (select an older run to inspect)"),evidence,17)
	history_list = ItemList.new(); history_list.name = "History"; history_list.custom_minimum_size.y = 90; evidence.add_child(history_list); history_list.item_selected.connect(select_run)
	var support_button := make_button(text2("取回本任务保留的达标方案", "Restore this task’s protected successful plan"),evidence,restore_support,"RestoreSupport")
	support_button.disabled = not support_plans.has(task)
	reuse_button = make_button(text2("从选中方案继续试", "Try a variation of this plan"),evidence,reuse_recorded_plan,"ReusePlan")
	reuse_button.tooltip_text = text2("复制自己的旧方案到对应任务草稿；旧记录不变，覆盖的草稿可撤销。", "Copy your recorded plan into its task draft. The record stays unchanged; Undo restores the previous draft.")
	design_shelf = DesignShelf.new(); design_shelf.name = "DesignShelf"
	design_shelf.connect("remember_requested",remember_design)
	design_shelf.connect("restore_requested",restore_design)
	design_shelf.connect("remove_requested",remove_design)
	evidence.add_child(design_shelf)
	recorded_plan_label = make_label("",evidence,13); recorded_plan_label.name = "RecordedPlan"
	result = make_label("",evidence,17); result.name = "PrimaryMetrics"
	order_comparison = Tree.new(); order_comparison.name = "OrderComparison"
	order_comparison.columns = 5; order_comparison.hide_root = true; order_comparison.column_titles_visible = true
	order_comparison.custom_minimum_size.y = 104
	for i: int in 5: order_comparison.set_column_title(i,[text2("订单 / 结果", "Order / result"),text2("准备", "Prepare"),text2("服务", "Serve"),text2("实际空间B", "Stored B"),text2("搬运B", "Traffic B")][i])
	order_comparison.set_column_expand(0,true)
	for i: int in range(1,5): order_comparison.set_column_expand(i,false); order_comparison.set_column_custom_minimum_width(i,58)
	evidence.add_child(order_comparison)
	order_comparison.item_selected.connect(func() -> void:
		var item: TreeItem = order_comparison.get_selected()
		if item != null:
			var index: int = int(item.get_metadata(0))
			order_choice.select(index); show_trace(index))
	order_choice = OptionButton.new(); order_choice.name = "RecordedOrder"; evidence.add_child(order_choice)
	order_choice.item_selected.connect(func(i: int) -> void: show_trace(i))
	var playback_row := HBoxContainer.new(); evidence.add_child(playback_row)
	trace_player = preload("res://experiments/representation_region/trace_player.gd").new()
	trace_player.name = "TracePlayer"
	trace_play = make_button(text2("回放真实事件", "Replay recorded events"),playback_row,trace_player.toggle_play,"TracePlay")
	trace_play.custom_minimum_size.x = 220
	trace_step = make_button(text2("下一事件", "Next event"),playback_row,trace_player.step,"TraceStep")
	trace_play.disabled = true; trace_step.disabled = true
	trace_player.playing_changed.connect(func(value: bool) -> void: trace_play.text = text2("暂停回放", "Pause replay") if value else text2("回放真实事件", "Replay recorded events"))
	trace_player.event_selected.connect(select_replay_event)
	evidence.add_child(trace_player)
	var detail_button := make_button(text2("展开 / 收起成本与事件细节", "Show / hide cost and event details"),evidence,func() -> void:
		details_expanded = not details_expanded
		trace_details_group.visible = details_expanded,"ToggleTraceDetails")
	detail_button.tooltip_text = text2("细节来自选中记录；展开不运行也不修改方案。", "Details belong to the selected recording; expanding does not run or edit a plan.")
	trace_details_group = VBoxContainer.new(); trace_details_group.name = "TraceDetailGroup"
	trace_details_group.visible = details_expanded; evidence.add_child(trace_details_group)
	metric_details = make_label("",trace_details_group,13); metric_details.name = "CostBreakdown"
	events = Tree.new(); events.name = "Events"; events.columns = 3; events.column_titles_visible = true; events.hide_root = true; events.custom_minimum_size.y = 190; events.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i: int in 3: events.set_column_title(i,[text2("起点","Start"),text2("周期","Cycles"),text2("事件","Event")][i])
	trace_details_group.add_child(events)
	details = RichTextLabel.new(); details.name = "TraceDetails"; details.custom_minimum_size.y = 150; details.size_flags_vertical = Control.SIZE_EXPAND_FILL; trace_details_group.add_child(details)
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
	get_node("/root/TaskNavigation").remember_candidate_visit("representation",task)
	if persistent_session: session_notice = text2("当前任务选择未保存；退出前点击保存。", "Current task selection is unsaved; save before quitting.")
	var saved: Dictionary = drafts.get(task,{"plan":Model.initial_plan(),"undo":[],"redo":[],"selection":0})
	plan.assign(saved.plan); undo_stack.assign(saved.undo); redo_stack.assign(saved.redo); selected_block = int(saved.selection)
	build()

func refresh_tasks() -> void:
	var earned_review: bool = representation_review_evidence().size() == 5
	var closure := find_child("RegionClosure",true,false) as Button
	if closure != null: closure.disabled = not earned_review
	var completion_action := find_child("CompletedRegionReview",true,false) as Button
	if completion_action != null: completion_action.visible = earned_review
	var support_button := find_child("RestoreSupport",true,false) as Button
	if support_button != null: support_button.disabled = not support_plans.has(task)
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
	if task == 4:
		var stored_b: int = 0
		for block: Dictionary in Model.block_evidence(Catalog.asset(5),plan): stored_b += int(block.stored_bytes)
		draft_label.text = text2("当前草稿：%d块 · 实际空间：资产A %dB / 资产B %dB\n两份资产共用划分与表示；运行后比较各订单服务成本。", "Current draft: %d blocks · actual storage: Asset A %dB / Asset B %dB\nBoth assets use the same partition and codecs; run to compare order service costs.") % [plan.size(),stored,stored_b]
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
	refresh_recorded_plan_label()
	refresh_design_shelf()
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
	if accepted: support_plans[task] = plan.duplicate(true)
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
		status.text = text2("五份任务均已达标。下方可回顾自己的成果；保存方案与比较记录后继续，也可留在这里探索。", "All five tasks met. Review your achievements below; save your plans and comparisons to continue, or keep exploring here.")
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
	refresh_design_shelf()

func select_run(index: int) -> void:
	if index < 0 or index >= history.size(): return
	selected_run = index; var row: Dictionary = history[index]
	history_list.select(index); history_list.ensure_current_is_visible()
	refresh_recorded_plan_label()
	refresh_design_shelf()
	order_choice.clear()
	for i: int in row.traces.size():
		var trace: Trace = row.traces[i]
		var badge: String = text2("达标", "Met") if order_within_limits(int(row.task),i,trace) else text2("未达标", "Unmet")
		order_choice.add_item("[%s] %s" % [badge,str(trace.metrics.spec.name)])
	refresh_order_comparison(row)
	var first_unmet: int = 0
	for i: int in row.traces.size():
		if not order_within_limits(int(row.task),i,row.traces[i]): first_unmet = i; break
	order_choice.select(first_unmet); show_trace(first_unmet)

func refresh_order_comparison(record: Dictionary) -> void:
	order_comparison.clear()
	var root_row: TreeItem = order_comparison.create_item()
	for i: int in record.traces.size():
		var trace: Trace = record.traces[i]
		var m: Dictionary = trace.metrics
		var item: TreeItem = order_comparison.create_item(root_row)
		item.set_metadata(0,i)
		var met: bool = order_within_limits(int(record.task),i,trace)
		item.set_text(0,"[%s] %s" % [text2("达标", "Met") if met else text2("未达标", "Unmet"),str(m.spec.name)])
		item.set_tooltip_text(0,str(m.spec.name)+"\n"+goal_text(Catalog.goals(int(record.task))[i]))
		for column: int in range(1,5): item.set_text(column,str(m[["preparation_cycles","service_cycles","stored_bytes","traffic_bytes"][column-1]]))
		item.set_custom_color(0,Color("62dca7") if met else Color("f2ba70"))

func prior_comparable_trace(run_index: int, spec: Dictionary) -> Dictionary:
	# Compare recorded evidence only, never drafts or a later run.
	if run_index < 0 or run_index >= history.size(): return {}
	var task_index: int = int(history[run_index].task)
	for previous: int in range(run_index-1,-1,-1):
		var recorded: Dictionary = history[previous]
		if int(recorded.task) != task_index: continue
		for trace: Trace in recorded.traces:
			if trace.metrics.get("spec",{}) == spec:
				return {"run_index":previous,"trace":trace}
	return {}

func show_trace(index: int) -> void:
	var row: Dictionary = history[selected_run]
	if index < 0 or index >= row.traces.size(): return
	visible_trace = row.traces[index]
	var m: Dictionary = visible_trace.metrics
	var met: bool = order_within_limits(int(row.task),index,visible_trace)
	result.text = text2("记录#%d · %s · %s\n准备 %d周期 + 服务 %d周期 = 总计 %d周期\n实际空间 %dB · 服务搬运 %dB", "Run #%d · %s · %s\nPrepare %d cycles + serve %d cycles = total %d cycles\nActual storage %dB · service traffic %dB") % [selected_run+1,m.spec.name,text2("达标", "Met") if met else text2("未达标", "Unmet"),m.preparation_cycles,m.service_cycles,m.total_cycles,m.stored_bytes,m.traffic_bytes]
	if m.spec.online:
		result.text += text2("\n包含保留源%dB；本订单%d位客户共用一次准备、各自冷缓存。", "\nIncludes retained source %dB; this order’s %d clients share one preparation, each with a cold cache.") % [m.source_storage_bytes,m.spec.clients]
	metric_details.text = text2("准备读%dB / 写%dB · 编码%dops（%d周期）\n解码%d周期 · 请求%d周期 · 消费%d周期 · hit/miss %d/%d · cache峰值%dB\n所有阶段搬运%dB · 准备后端存储峰值%dB（不含恢复缓冲）\n逻辑表示%dB；实际空间取自记录。", "Prepare read%dB / write%dB · encode%dops (%d cycles)\nDecode%dcycles · requests%dcycles · consume%dcycles · hit/miss %d/%d · cache peak%dB\nAll-phase traffic%dB · preparation backing-storage peak%dB (excludes recovery scratch)\nLogical representation%dB; actual storage comes from the recording.") % [m.source_read_bytes,m.prepared_write_bytes,m.encode_ops,m.encode_cycles,m.decode_cycles,m.request_cycles,m.consume_cycles,m.cache_hits,m.cache_misses,m.peak_cache_bytes,m.total_traffic_bytes,m.peak_preparation_bytes,m.representation_bytes]
	var comparison: Dictionary = prior_comparable_trace(selected_run,m.spec)
	if comparison.is_empty():
		metric_details.text += text2("\n暂无更早的同任务、同规格订单记录可比较。", "\nNo earlier same-task, same-spec order recording to compare.")
	else:
		var prior: Trace = comparison.trace
		var before: Dictionary = prior.metrics
		metric_details.text += text2("\n比较来源：记录#%d → #%d · %s（同任务、同规格）\n本次减去旧记录：准备%+d、服务%+d、总计%+d周期\n实际空间%+dB · 服务搬运%+dB · 全阶段搬运%+dB", "\nComparison source: run #%d → #%d · %s (same task and spec)\nCurrent minus prior: prepare%+d, serve%+d, total%+d cycles\nActual storage%+dB · service traffic%+dB · all-phase traffic%+dB") % [int(comparison.run_index)+1,selected_run+1,m.spec.name,int(m.preparation_cycles)-int(before.preparation_cycles),int(m.service_cycles)-int(before.service_cycles),int(m.total_cycles)-int(before.total_cycles),int(m.stored_bytes)-int(before.stored_bytes),int(m.traffic_bytes)-int(before.traffic_bytes),int(m.total_traffic_bytes)-int(before.total_traffic_bytes)]
	var limit_feedback: String = constraint_feedback(int(row.task),row.traces)
	if not limit_feedback.is_empty(): result.text += "\n" + limit_feedback
	var comparison_row: TreeItem = order_comparison.get_root().get_first_child()
	while comparison_row != null:
		if int(comparison_row.get_metadata(0)) == index:
			if order_comparison.get_selected() != comparison_row: comparison_row.select(0)
			break
		comparison_row = comparison_row.get_next()

	events.clear(); var root_row: TreeItem = events.create_item()
	var replay_events: Array = []
	for event: RefCounted in visible_trace.events:
		var item: TreeItem = events.create_item(root_row); item.set_text(0,str(event.cycle)); item.set_text(1,str(event.duration)); item.set_text(2,"%s @%d" % [str(event.kind),event.address]); item.set_metadata(0,{"kind":str(event.kind),"duration":event.duration,"details":event.details.duplicate(true)})
		item.set_metadata(1,replay_events.size()); replay_events.append(event.to_dictionary())
	if root_row.get_first_child() != null: events.scroll_to_item(root_row.get_first_child())
	trace_player.configure(replay_events,english)
	trace_play.disabled = replay_events.is_empty(); trace_step.disabled = replay_events.is_empty()
	details.text = text2("选中事件查看实际字节、恢复输出、缓存前后和驱逐。\n记录方案：", "Select an event for actual bytes, restored values, cache before/after and evictions.\nRecorded plan: ")+plan_text(row.plan)

func refresh_recorded_plan_label() -> void:
	if not is_instance_valid(recorded_plan_label): return
	if selected_run < 0 or selected_run >= history.size(): recorded_plan_label.text = ""; return
	var row: Dictionary = history[selected_run]
	var matches: bool = int(row.task) == task and row.plan == plan
	var prefix: String = text2("记录方案（与草稿一致）：", "Recorded plan (matches draft): ") if matches else text2("记录方案（与当前草稿不同）：", "Recorded plan (differs from current draft): ")
	recorded_plan_label.text = text2("记录#%d · 任务%d · 不变的实测依据\n", "Run #%d · task %d · immutable measured evidence\n") % [selected_run+1,int(row.task)+1] + prefix+plan_text(row.plan)

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
	recovery_state = saved if saved.get("error") == "recovery" else {}
	if not saved.ok:
		save_blocked = true
		session_notice = text2("已有候选存档无法安全读取，已保留原文件并禁止覆盖。", "Existing candidate save could not be safely read; original preserved, saving blocked.")
		return
	session_version = str(saved.get("digest", ""))
	if saved.get("empty",false):
		session_notice = text2("独立候选档：退出前点击保存。撤销栈仅在本次会话保留。", "Isolated candidate profile: save before quitting. Undo stacks are session-only.")
		return
	designs.assign(saved.get("designs",[]).duplicate(true))
	for i: int in 5:
		drafts[i] = {"plan":saved.drafts[i].duplicate(true),"undo":[],"redo":[],"selection":0}
	task = int(saved.task); plan.assign(saved.drafts[task])
	for run: Dictionary in saved.runs:
		var traces: Array[Trace] = []
		for spec: Dictionary in Model.orders(int(run.task)): traces.append(Model.run(spec,run.plan))
		var accepted: bool = Model.meets(int(run.task),traces)
		history.append({"task":int(run.task),"plan":run.plan.duplicate(true),"traces":traces,"accepted":accepted})
		completed[int(run.task)] = completed[int(run.task)] or accepted
		if accepted: support_plans[int(run.task)] = run.plan.duplicate(true)
	for support: Dictionary in saved.supports:
		var traces: Array[Trace] = []
		for spec: Dictionary in Model.orders(int(support.task)): traces.append(Model.run(spec,support.plan))
		if Model.meets(int(support.task),traces):
			support_plans[int(support.task)] = support.plan.duplicate(true)
			completed[int(support.task)] = true
	selected_run = history.size()-1
	session_notice = text2("已恢复草稿；%d条对照按相同模型重新计算。未授予主线进度。", "Drafts restored; %d comparisons recomputed with the matching model. No campaign progress granted.") % history.size()

func save_session() -> void:
	if not persistent_session or save_blocked: return
	var saved_drafts: Array = []
	for i: int in 5:
		saved_drafts.append(plan.duplicate(true) if i == task else drafts.get(i,{"plan":Model.initial_plan()}).plan.duplicate(true))
	var runs: Array = []
	for run: Dictionary in history: runs.append({"task":int(run.task),"plan":run.plan.duplicate(true)})
	var raw: String = SessionStore.encode(task,saved_drafts,runs,support_records(),designs)
	var error: Error = SessionStore.write_session(raw, SessionStore.PATH, session_version, writer_lease)
	if error == OK:
		session_version = raw.sha256_text()
		session_dirty = false
	session_notice = text2("已保存独立候选档；同一配置再次启动可继续。", "Saved isolated candidate profile; reopen the same profile to continue.") if error == OK else text2("保存失败，未覆盖已有存档；请保留当前窗口。", "Save failed without overwriting the existing save; keep this window open.")
	status.text = session_notice
	if error != OK: refresh_recovery_controls()

func mark_session_dirty() -> void:
	if not persistent_session: return
	session_dirty = true
	session_notice = ""

func refresh_design_shelf() -> void:
	if design_shelf == null: return
	var selected_record: Dictionary = {}
	if selected_run >= 0 and selected_run < history.size():
		selected_record = {"task":int(history[selected_run].task),"plan":history[selected_run].plan.duplicate(true)}
	design_shelf.call("refresh",designs,selected_record,english)

func remember_design(name: String) -> void:
	if selected_run < 0 or selected_run >= history.size(): return
	var measured: Dictionary = history[selected_run]
	var remembered: Dictionary = Designs.remember(designs,{"task":int(measured.task),"plan":measured.plan},name)
	if not remembered.ok:
		status.text = text2("收藏已满：最多保留24份不同方案，可先移出一份。", "Collection is full: keep at most 24 distinct designs; remove one first.") if remembered.get("error") == "limit" else text2("未收藏：名称须为1–48个字且不含控制字符。", "Design not kept: use 1–48 characters without control characters.")
		return
	if remembered.designs == designs: return
	designs.assign(remembered.designs)
	mark_session_dirty(); refresh_design_shelf()
	status.text = text2("已命名收藏选中的实测方案；退出前保存。当前草稿和旧记录保留。", "Selected measured plan kept by name; save before leaving. Your draft and recording are preserved.")

func restore_design(index: int) -> void:
	if index < 0 or index >= designs.size(): return
	var recorded: Dictionary = designs[index].duplicate(true)
	if int(recorded.task) != task: change_task(int(recorded.task))
	var restored: Array[Dictionary] = []; restored.assign(recorded.plan)
	edit_plan(restored)
	status.text = text2("已取回“%s”到原任务草稿；可撤销恢复原草稿。尚未运行。", "“%s” restored to its original task draft; Undo restores the previous draft. It has not been run.") % str(recorded.name)

func remove_design(index: int) -> void:
	if index < 0 or index >= designs.size(): return
	designs.remove_at(index)
	mark_session_dirty(); refresh_design_shelf()
	status.text = text2("已从本窗口移除收藏；保存后生效，实测记录保留。", "Design removed in this window; Save makes the change persistent. Recorded runs are preserved.")

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

func request_hub() -> void:
	leave_from_review = false
	leave_scene = "res://src/ui/prototype_hub.tscn"
	leave_to_hub = true
	request_leave()

func request_quit() -> void:
	leave_from_review = false
	leave_scene = ""
	leave_to_hub = false
	request_leave()

func request_service() -> void:
	if not candidate_journey or representation_review_evidence().size() != 5: return
	leave_scene = "res://experiments/service_plan/lab.tscn"
	leave_to_hub = false
	request_leave()

func finish_leave() -> void:
	if leave_to_hub and get_node("/root/TaskNavigation").return_to_tree(): return
	if leave_scene == "res://experiments/service_plan/lab.tscn":
		call_deferred("_finish_service_leave")
		return
	if not leave_scene.is_empty(): get_tree().call_deferred("change_scene_to_file",leave_scene)
	elif leave_to_hub: get_tree().call_deferred("change_scene_to_file","res://src/ui/prototype_hub.tscn")
	else: get_tree().quit()

func _finish_service_leave() -> void:
	if not get_node("/root/TaskNavigation").enter_candidate("service",0): cancel_leave()

func resume_region_review() -> void:
	leave_from_review = false
	leave_scene = ""
	leave_to_hub = false
	var guard := get_node_or_null("UnsavedSessionDialog") as ConfirmationDialog
	if guard != null: guard.hide()
	var review := get_node_or_null("RegionReview") as AcceptDialog
	if review != null: review.popup_centered(Vector2i(740,460))

func cancel_leave() -> void:
	if leave_from_review: resume_region_review()
	else:
		leave_scene = ""
		leave_to_hub = false

func request_leave() -> void:
	if not persistent_session or not session_dirty:
		finish_leave()
		return
	if get_node_or_null("UnsavedSessionDialog") != null:
		(get_node("UnsavedSessionDialog") as ConfirmationDialog).popup_centered()
		return
	var dialog := ConfirmationDialog.new()
	dialog.name = "UnsavedSessionDialog"
	dialog.title = text2("保存这次探索？", "Save this exploration?")
	dialog.dialog_text = text2("草稿或对照记录有未保存的变化。", "Drafts or comparison records have unsaved changes.")
	dialog.ok_button_text = text2("保存并离开", "Save and leave")
	dialog.cancel_button_text = text2("继续编辑", "Keep editing")
	dialog.add_button(text2("不保存离开", "Leave without saving"),true,"discard")
	dialog.canceled.connect(cancel_leave)
	dialog.confirmed.connect(func() -> void:
		save_session()
		if not session_dirty: finish_leave()
		else: cancel_leave())
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard": finish_leave())
	add_child(dialog)
	dialog.popup_centered(Vector2i(520,180))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and persistent_session: request_quit()

func _exit_tree() -> void:
	if writer_lease != null: writer_lease.release()
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

func support_records() -> Array:
	var records: Array = []
	for id: int in support_plans: records.append({"task":id,"plan":support_plans[id].duplicate(true)})
	return records

func restore_support() -> void:
	if not support_plans.has(task): return
	var restored: Array[Dictionary] = []; restored.assign(support_plans[task].duplicate(true))
	edit_plan(restored)

func add_recovery_controls(parent: Node) -> void:
	if writer_lease == null or not writer_lease.held:
		make_button(text2("重新检查写入权（保留本窗口探索）", "Recheck writer ownership (keep this exploration)"),parent,retry_writer.bind(false),"RetryWriter")
		make_button(text2("重新读取已保存候选档", "Reload saved candidate profile"),parent,func() -> void: confirm_recovery(retry_writer.bind(true)),"ReloadCandidate")
		var stopped: String = SessionStore.Lease.stopped_owner(SessionStore.PATH)
		if not stopped.is_empty():
			make_button(text2("恢复已停止窗口的写入权", "Recover stopped window’s writer ownership"),parent,func() -> void: confirm_recovery(func() -> void: recover_writer(stopped)),"RecoverWriter")
		return
	if recovery_state.is_empty(): return
	make_label(text2("检测到中断或损坏。选择要恢复的快照；全部原文件会保留。", "Interrupted or damaged save. Choose a snapshot; all original files will be preserved."),parent)
	for choice: Dictionary in recovery_state.get("choices",[]):
		var source: String = choice.path
		var kind: String = text2("主档", "Main") if source == SessionStore.PATH else (text2("上次保存", "Previous save") if source.ends_with(".bak") else text2("未完成安装", "Interrupted install"))
		var recovery_button := make_button(text2("恢复 ", "Recover ")+kind+" · T"+str(int(choice.task)+1)+" · "+str(choice.digest).substr(0,8),parent,func() -> void: confirm_recovery(func() -> void: recover_candidate(source)),"RecoverSnapshot")
		recovery_button.tooltip_text = source.get_file()

func retry_writer(reload_saved: bool = false) -> void:
	if not persistent_session or (writer_lease != null and writer_lease.owns(SessionStore.PATH)): return
	var expected: String = session_version
	if reload_saved:
		var disk: Dictionary = SessionStore.read_session()
		if not disk.ok: recovery_failed(); return
		expected = str(disk.get("digest",""))
	var acquired: Dictionary = WriterRetry.attempt(SessionStore.PATH,expected,SessionStore.read_session)
	if not acquired.ok:
		save_blocked = true
		refresh_recovery_controls()
		session_notice = text2("尚未取得写入权；当前探索仍保留。关闭占用窗口后可重试；若磁盘存档已变化，须确认重新读取才能替换本窗口探索。", "Writer ownership was not acquired; your exploration is retained. Retry after the owning window closes. If the disk save changed, confirm Reload to replace this window’s exploration.")
		if acquired.reason == "unreadable": session_notice = text2("候选档无法安全读取；保持禁止覆盖。请检查恢复快照，或保留当前窗口。", "Candidate save cannot be read safely; overwriting remains blocked. Review recovery snapshots or keep this window open.")
		status.text = session_notice
		return
	writer_lease = acquired.lease
	if reload_saved:
		reload_recovered_session()
		return
	save_blocked = false; recovery_state.clear()
	session_notice = text2("已取得写入权；本窗口的草稿、记录和未保存探索均保留，现在可以保存。", "Writer ownership acquired; this window’s draft, recordings and unsaved exploration are retained. You can now save.")
	build(); status.text = session_notice

func recover_writer(expected_token: String) -> void:
	var acquired: Dictionary = SessionStore.Lease.recover_and_acquire(SessionStore.PATH,expected_token)
	if acquired.error != OK: recovery_failed(); return
	writer_lease = acquired.lease
	reload_recovered_session()

func recover_candidate(source: String) -> void:
	if SessionStore.recover_session(source,str(recovery_state.get("fingerprint","")),SessionStore.PATH,writer_lease) != OK: recovery_failed(); return
	reload_recovered_session()

func reload_recovered_session() -> void:
	save_blocked = false; session_dirty = false; history.clear(); support_plans.clear(); designs.clear()
	completed = [false,false,false,false,false]; drafts.clear(); undo_stack.clear(); redo_stack.clear()
	task = 0; plan = Model.initial_plan(); selected_block = 0; selected_run = -1
	preview_order = 0; visible_trace = null
	restore_session(); build()

# Revalidate protected recipes, including after recovery; booleans are not evidence.
func representation_review_evidence() -> Array[Dictionary]:
	var evidence: Array[Dictionary] = []
	for id: int in 5:
		if not support_plans.has(id): return []
		var traces: Array[Trace] = []
		for spec: Dictionary in Model.orders(id): traces.append(Model.run(spec,support_plans[id]))
		if not Model.meets(id,traces): return []
		var metrics: Array[Dictionary] = []
		for trace: Trace in traces: metrics.append(trace.metrics.duplicate(true))
		evidence.append({"task":id,"metrics":metrics})
	return evidence

func show_closure() -> void:
	var evidence: Array[Dictionary] = representation_review_evidence()
	if evidence.size() != 5: return
	var existing := get_node_or_null("RegionReview") as AcceptDialog
	if existing != null: remove_child(existing); existing.queue_free()
	var review := AcceptDialog.new(); review.name = "RegionReview"
	review.title = text2("表示区域 · 你的方案已回应五份任务", "Representation · Your plans answered all five tasks")
	var lines: Array[String] = [text2("同一份信息，有了不同的承载方式。你已让它在存储、访问、准备和重复服务的约束下，完整抵达请求者。", "The same information now has different ways to travel. Your plans delivered it under storage, access, preparation and repeated-service constraints."), ""]
	for id: int in 5:
		var cycles: Array[String] = []
		for metrics: Dictionary in evidence[id].metrics: cycles.append(str(metrics.total_cycles))
		lines.append(Catalog.title(id,english)+" · "+" / ".join(cycles)+text2(" 周期", " cycles"))
	lines.append("")
	lines.append(text2("这些结果来自保留的达标方案；你仍可回看、取回并尝试不同取舍。这段旅程到此可以收束，不需要等待服务或预测内容。", "These results come from your protected successful plans. Revisit, restore and explore other trade-offs whenever you like. This journey can close here, without waiting for service or prediction content."))
	if not persistent_session:
		lines.append(text2("当前为临时会话，方案与记录不会在退出后保留。", "This is a temporary session; plans and records are not retained after leaving."))
	else:
		lines.append(text2("本次变化尚未保存；离开前请保存。", "This session has unsaved changes; save before leaving.") if session_dirty else text2("已保存的方案可在同一候选档继续。", "Saved plans can be resumed in this candidate profile."))
	if candidate_journey:
		lines.append(text2("下一段：静态信息有了合适的承载方式；现在，让会更新的历史继续留在系统中，并安排何时回应。服务使用另一台公开机器，表示方案不会自动移过去。", "Next: you have arranged how fixed information travels. Now retain changing history and decide when to respond. Service uses its own public machine; representation plans do not transfer automatically."))
		var continuation: Button = review.add_button(text2("继续：历史与回应", "Continue: history and responses"),false,"service")
		continuation.name = "ContinueServiceCandidate"
		review.custom_action.connect(func(action: StringName) -> void:
			if action != &"service": return
			leave_from_review = true; review.hide(); request_service())
	var scroll := ScrollContainer.new(); scroll.name = "RegionReviewScroll"
	scroll.custom_minimum_size = Vector2(700,320); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	review.add_child(scroll)
	var content := Label.new(); content.name = "RegionReviewContent"; content.text = "\n".join(lines)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(content)
	review.ok_button_text = text2("回到我的工作台", "Back to my workbench")
	add_child(review); review.popup_centered(Vector2i(740,460))

func confirm_recovery(action: Callable) -> void:
	if not session_dirty: action.call(); return
	var existing := get_node_or_null("ReplaceUnsavedRecovery") as ConfirmationDialog
	if existing != null: existing.popup_centered(); return
	var dialog := ConfirmationDialog.new(); dialog.name = "ReplaceUnsavedRecovery"
	dialog.title = text2("替换本窗口的未保存探索？", "Replace this window’s unsaved exploration?")
	dialog.dialog_text = text2("恢复将重新读取磁盘快照，替换本窗口尚未保存的草稿和记录。磁盘原文件仍会保留。", "Recovery reloads the disk snapshot, replacing this window’s unsaved draft and runs. Original disk files remain preserved.")
	dialog.ok_button_text = text2("恢复所选快照", "Recover selected snapshot")
	dialog.confirmed.connect(func() -> void: action.call(); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog); dialog.popup_centered(Vector2i(560,200))

func refresh_recovery_controls() -> void:
	var disk: Dictionary = SessionStore.read_session()
	recovery_state = disk if disk.get("error") == "recovery" else {}
	if not disk.ok: save_blocked = true
	build() # Only rebuild controls: current draft, history and supports stay intact.

func recovery_failed() -> void:
	refresh_recovery_controls()
	status.text = text2("恢复未执行：文件或写入权已变化。当前草稿仍保留；请检查快照后重试，或保留窗口。", "Recovery was not performed: files or ownership changed. Your current draft is retained; review the snapshots and retry, or keep this window open.")
