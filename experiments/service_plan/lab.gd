extends Control
## Editable plan presenter. Never supplies authoritative numerical results.
const Model = preload("res://experiments/service_plan/model.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const SessionStore = preload("res://experiments/service_plan/session_store.gd")
var persistent_session: bool = false
var session_dirty: bool = false
var save_blocked: bool = false
var session_version: String = ""
var notice_key: String = ""
var previous_auto_quit: bool = true
var plan: Dictionary = Model.initial_plan()
var history: Array[Dictionary] = []
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var english: bool = false
var task: int = 0
var unlocked: int = 0
var hint_open: bool = false
var selected_group: int = 0
var selected_history: int = -1
var active_trace: Trace
var group_list: ItemList
var history_list: ItemList
var split_at: SpinBox
var move_to: SpinBox
var move_button: Button
var slots: SpinBox
var format_buttons: Array[Button] = []
var task_buttons: Array[Button] = []
var run_button: Button
var language_button: Button
var undo_button: Button
var redo_button: Button
var merge_button: Button
var split_button: Button
var up_button: Button
var down_button: Button
var hint_button: Button
var data_button: Button
var restore_button: Button
var mission: Label
var status: Label
var evidence_tabs: TabContainer
var public_raw: bool = false
var public_raw_button: Button
var public_detail: RichTextLabel
var response_play: Button
var response_step: Button
var response_chart: Control
var comparison_baseline: Dictionary = {}
var comparison_chart: Control
var comparison_detail: Label
var pin_button: Button
var clear_pin_button: Button
var measured_source: Label
var summary: Label
var detail: RichTextLabel
var tree: Tree

func tr2(zh: String, en: String) -> String: return en if english else zh
func _ready() -> void:
	theme = Theme.new(); InstrumentTheme.apply_to(theme)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english = true
		if arg == "--candidate-save": persistent_session = true
	if persistent_session:
		add_to_group("candidate_quit_owners")
		previous_auto_quit = get_tree().auto_accept_quit; get_tree().auto_accept_quit = false
		restore_session()
	build()

func label(text: String, parent: Node, size: int = 15) -> Label:
	var node := Label.new(); node.text = text; node.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size); parent.add_child(node); return node
func button(text: String, parent: Node, action: Callable, id: String = "") -> Button:
	var node := Button.new(); node.text = text; node.name = id if not id.is_empty() else "Action"
	node.custom_minimum_size.y = 32; node.pressed.connect(action); parent.add_child(node); return node

func mission_text() -> String:
	var common: String = tr2("4条流×6次请求；同流保序，每组输入先到、整组算完再响应。脏淘汰和最终flush必须写回。\n", "4 streams × 6 requests; preserve each stream's order. Read group inputs, compute whole group, then respond. Dirty eviction and final flush write back.\n")
	var goals: Array[String] = [tr2("1 · 少搬状态：总≤1420周期，状态读写≤600B，峰值≤350B；分数/最终状态必须精确。", "1 · Move less state: total≤1420 cycles, state reads+writes≤600B, peak≤350B; exact scores/final states."), tr2("2 · 及时服务：总≤1420周期，每流首响应≤320周期；分数/最终状态必须精确。", "2 · Prompt service: total≤1420 cycles, every stream first response≤320; exact scores/final states."), tr2("3 · 同一服务方案：总≤1420，首响应≤320，状态读写≤320B；分数/最终状态误差≤0.02。", "3 · One service plan: total≤1420, first responses≤320, state reads+writes≤320B; score/final-state errors≤0.02.")]
	return common + goals[task] + tr2("\n硬容量512B；decoded状态64B/流，权重64B，最大组72B/项，另计真实编码临时空间。", "\nHard512B: decoded contexts64B/stream, weights64B, largest group72B/request, plus actual encoded temporary bytes.")

func hint_text() -> String:
	return tr2("Hint1 · 查看state_read/write是否同流反复出现，以及D的首响应。合组会省请求，但整组算完才返回。A/B每维相同，C/D每维变化；对照encoded字节和codec费用再选表示。", "Hint1 · Inspect repeated state reads/writes and D's first response. Merging saves setup, but delays responses until the group completes. A/B repeat coordinates; C/D vary. Compare actual encoded bytes and codec costs before choosing storage.")

func build() -> void:
	for child: Node in get_children(): remove_child(child); child.queue_free()
	format_buttons.clear(); task_buttons.clear()
	var background := ColorRect.new(); background.color = Color("0b1720"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin); var page := VBoxContainer.new(); page.add_theme_constant_override("separation", 6); margin.add_child(page)
	var header := HBoxContainer.new(); page.add_child(header)
	var title := label(tr2("服务方案 · 谁先得到下一次结果？", "Service plan · Who gets the next result?"), header, 22); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_button = button("中文 / EN", header, func() -> void: english = not english; build(), "Language")
	button(tr2("退出", "Quit"), header, request_quit, "Quit")
	var stages := HBoxContainer.new(); page.add_child(stages)
	for index: int in 3:
		var node: Button = button(tr2("任务%d" % (index + 1), "Task%d" % (index + 1)), stages, func() -> void: change_task(index), "Task%d" % (index + 1))
		node.disabled = index > unlocked; task_buttons.append(node)
	hint_button = button(tr2("看一个线索", "A clue"), stages, func() -> void: hint_open = not hint_open; refresh_mission(), "Hint1")
	data_button = button(tr2("公开数据 / 成本", "Public data / costs"), stages, show_public_data, "PublicData")
	mission = label("", page, 14); refresh_mission()
	status = label(tr2("构造组和顺序，选择逐流表示，再测量。实验进度只在内存。", "Construct groups/order and per-stream storage, then measure. Lab progress is session-only."), page, 14)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation", 14); page.add_child(body)
	var editor := VBoxContainer.new(); editor.custom_minimum_size.x = 430; body.add_child(editor)
	label(tr2("服务组（可拖动）· 从上到下执行", "Drag service groups · execute top to bottom"), editor)
	group_list = preload("res://experiments/service_plan/group_list.gd").new(); group_list.name = "Groups"; group_list.size_flags_vertical = Control.SIZE_EXPAND_FILL; group_list.custom_minimum_size.y = 100; editor.add_child(group_list)
	group_list.tooltip_text = tr2("四格依次代表A/B/C/D；亮格表示组内包含该流。可拖动整组，运行核验同流保序。", "Four marks represent A/B/C/D; lit marks show streams present. Drag whole groups; Run validates stream order.")
	group_list.group_moved.connect(func(source: int, target: int) -> void: edit(Model.move(plan,source,target-source),target))
	group_list.item_selected.connect(func(index: int) -> void: selected_group = index; refresh_actions())
	var motion := HBoxContainer.new(); editor.add_child(motion)
	up_button = button(tr2("上移", "Move up"), motion, func() -> void: edit(Model.move(plan, selected_group, -1), selected_group - 1), "MoveUp")
	down_button = button(tr2("下移", "Move down"), motion, func() -> void: edit(Model.move(plan, selected_group, 1), selected_group + 1), "MoveDown")
	merge_button = button(tr2("合并下一组", "Join next"), motion, func() -> void: edit(Model.merge(plan, selected_group), selected_group), "Merge")
	var destination := HBoxContainer.new(); editor.add_child(destination)
	label(tr2("移到第几组", "Move to group"), destination, 14)
	move_to = SpinBox.new(); move_to.name = "MoveTarget"; move_to.min_value = 1; move_to.max_value = plan.groups.size(); move_to.value = 1; destination.add_child(move_to)
	move_button = button(tr2("移动整组", "Move group"), destination, func() -> void: edit(Model.move(plan, selected_group, int(move_to.value) - 1 - selected_group), int(move_to.value) - 1), "MoveTo")
	var splits := HBoxContainer.new(); editor.add_child(splits)
	label(tr2("第几项后拆", "Split after item"), splits, 14)
	split_at = SpinBox.new(); split_at.name = "SplitBoundary"; split_at.min_value = 1; split_at.max_value = 23; split_at.value = 1; splits.add_child(split_at)
	split_button = button(tr2("拆成两组", "Split group"), splits, func() -> void: edit(Model.split(plan, selected_group, int(split_at.value)), selected_group), "Split")
	var capacity := HBoxContainer.new(); editor.add_child(capacity)
	label(tr2("自动LRU状态槽", "Automatic LRU slots"), capacity)
	slots = SpinBox.new(); slots.name = "Slots"; slots.min_value = 1; slots.max_value = 4; slots.value = plan.slots; capacity.add_child(slots)
	slots.value_changed.connect(func(value: float) -> void:
		var next: Dictionary = plan.duplicate(true); next.slots = int(value); edit(next, selected_group))
	label(tr2("逐流存储 · 点击切换RAW64→RLE64→RAW8→RLE8", "Storage per stream · click RAW64→RLE64→RAW8→RLE8"), editor, 13)
	var formats := HBoxContainer.new(); editor.add_child(formats)
	for stream: int in 4:
		var format: Button = button("", formats, func() -> void:
			var current: int = Model.REPRESENTATIONS.find(plan.representations[stream]); edit(Model.represent(plan, stream, Model.REPRESENTATIONS[(current + 1) % 4]), selected_group), "Format" + char(65 + stream))
		format.size_flags_horizontal = Control.SIZE_EXPAND_FILL; format_buttons.append(format)
	var actions := HBoxContainer.new(); editor.add_child(actions)
	undo_button = button(tr2("撤销", "Undo"), actions, undo, "Undo")
	redo_button = button(tr2("重做", "Redo"), actions, redo, "Redo")
	run_button = button(tr2("运行并记录", "Run and record"), actions, run_current, "Run")
	InstrumentTheme.primary(run_button,Color("50d5ff"))
	if persistent_session:
		var save := button(tr2("保存本次探索", "Save this exploration"),editor,save_session,"SaveSession")
		save.disabled = save_blocked; InstrumentTheme.primary(save,Color("62dca7"))
	var evidence := VBoxContainer.new(); evidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(evidence)
	var history_header := HBoxContainer.new(); evidence.add_child(history_header)
	label(tr2("实测历史 · 不随草稿改变", "Measured history · independent of drafts"), history_header).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_button = button(tr2("恢复为草稿", "Restore draft"), history_header, restore_history, "Restore")
	history_list = ItemList.new(); history_list.name = "History"; history_list.custom_minimum_size.y = 64; evidence.add_child(history_list); history_list.item_selected.connect(select_run)
	evidence_tabs = TabContainer.new(); evidence_tabs.name = "EvidenceTabs"; evidence_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL; evidence.add_child(evidence_tabs)
	var overview := VBoxContainer.new(); overview.name = "Overview"; evidence_tabs.add_child(overview)
	var event_panel := VBoxContainer.new(); event_panel.name = "Events"; evidence_tabs.add_child(event_panel)
	var public_panel := VBoxContainer.new(); public_panel.name = "PublicData"; evidence_tabs.add_child(public_panel)
	public_raw_button = button("",public_panel,func() -> void: public_raw = not public_raw; refresh_public_data(),"ToggleRawPublicData")
	public_detail = RichTextLabel.new(); public_detail.name = "PublicDataView"; public_detail.custom_minimum_size.y = 150; public_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL; public_panel.add_child(public_detail)
	evidence_tabs.set_tab_title(0,tr2("结果概览", "Overview")); evidence_tabs.set_tab_title(1,tr2("逐条事件", "Events")); evidence_tabs.set_tab_title(2,tr2("公开数据", "Public data"))
	measured_source = label("",overview,13)
	summary = label(tr2("尚未运行。所有目标公开；数值从实际Trace产生。", "No measured run yet. Goals are public; results come from actual Trace."), overview, 14)
	var comparison_panel := VBoxContainer.new(); comparison_panel.name = "Comparison"; evidence_tabs.add_child(comparison_panel)
	evidence_tabs.set_tab_title(3,tr2("对照比较", "Compare"))
	var compare_row := HBoxContainer.new(); comparison_panel.add_child(compare_row)
	pin_button = button(tr2("以此记录为对照", "Pin this measurement"),compare_row,pin_comparison,"PinComparison")
	clear_pin_button = button(tr2("清除对照", "Clear comparison"),compare_row,func() -> void: comparison_baseline.clear(); refresh_comparison(),"ClearComparison")
	comparison_detail = label("",comparison_panel,14)
	comparison_chart = preload("res://experiments/service_plan/comparison_chart.gd").new(); comparison_chart.name = "ComparisonChart"; comparison_panel.add_child(comparison_chart)
	response_chart = preload("res://experiments/service_plan/response_chart.gd").new(); response_chart.name = "ResponseChart"
	overview.add_child(response_chart); response_chart.configure([],0 if task == 0 else 320,english)
	var replay_row := HBoxContainer.new(); overview.add_child(replay_row)
	response_play = button(tr2("回放首响应顺序", "Replay first responses"),replay_row,response_chart.toggle_play,"ResponsePlay")
	response_play.custom_minimum_size.x = 220
	response_step = button(tr2("下一响应", "Next response"),replay_row,response_chart.step_response,"ResponseStep")
	response_play.disabled = true; response_step.disabled = true
	response_chart.playback_changed.connect(func(value: bool) -> void: response_play.text = tr2("暂停回放", "Pause replay") if value else tr2("回放首响应顺序", "Replay first responses"))
	tree = Tree.new(); tree.name = "Trace"; tree.columns = 3; tree.column_titles_visible = true; tree.hide_root = true
	tree.set_column_title(0, tr2("周期", "Cycle")); tree.set_column_title(1, tr2("费用", "Cost")); tree.set_column_title(2, tr2("事件", "Event")); tree.size_flags_vertical = Control.SIZE_EXPAND_FILL; tree.custom_minimum_size.y = 80; event_panel.add_child(tree)
	tree.item_selected.connect(func() -> void:
		var item: TreeItem = tree.get_selected()
		if item != null: detail.text = JSON.stringify(item.get_metadata(0), "  "))
	detail = RichTextLabel.new(); detail.name = "Details"; detail.custom_minimum_size.y = 110; detail.scroll_active = true; event_panel.add_child(detail)
	refresh_public_data(); refresh_groups(); refresh_history(); refresh_actions(); refresh_comparison()
	if selected_history >= 0 and selected_history < history.size(): history_list.select(selected_history); select_run(selected_history)
	if persistent_session and not notice_key.is_empty(): status.text = session_notice()

func refresh_mission() -> void: mission.text = mission_text() + ("\n" + hint_text() if hint_open else "")
func refresh_groups() -> void:
	group_list.clear()
	for index: int in plan.groups.size():
		var tokens: PackedStringArray = []
		for id: int in plan.groups[index]: tokens.append(char(65 + id / 6) + str(id % 6))
		group_list.add_item("%02d   [ %s ]" % [index + 1, "  ".join(tokens)],group_list.group_icon(plan.groups[index]))
	selected_group = clampi(selected_group, 0, plan.groups.size() - 1); group_list.select(selected_group); group_list.ensure_current_is_visible()
	refresh_measured_source()
	move_to.max_value = plan.groups.size()
	for stream: int in 4: format_buttons[stream].text = char(65 + stream) + ": " + str(plan.representations[stream]).to_upper()
func refresh_actions() -> void:
	up_button.disabled = selected_group == 0; down_button.disabled = selected_group == plan.groups.size() - 1
	merge_button.disabled = down_button.disabled; split_button.disabled = plan.groups[selected_group].size() < 2
	undo_button.disabled = undo_stack.is_empty(); redo_button.disabled = redo_stack.is_empty(); restore_button.disabled = selected_history < 0
func edit(next: Dictionary, selection: int) -> void:
	if next == plan: return
	mark_session_dirty()
	undo_stack.append(plan.duplicate(true)); redo_stack.clear(); plan = next.duplicate(true); selected_group = selection
	refresh_groups(); refresh_actions(); status.text = tr2("草稿已改；历史不变。运行时核验同流保序和512B容量。", "Draft changed; history preserved. Run validates stream dependencies and512B scratch.")
func undo() -> void:
	if undo_stack.is_empty(): return
	mark_session_dirty()
	redo_stack.append(plan.duplicate(true)); plan = undo_stack.pop_back(); slots.set_value_no_signal(plan.slots); refresh_groups(); refresh_actions()
func redo() -> void:
	if redo_stack.is_empty(): return
	mark_session_dirty()
	undo_stack.append(plan.duplicate(true)); plan = redo_stack.pop_back(); slots.set_value_no_signal(plan.slots); refresh_groups(); refresh_actions()
func run_current() -> void:
	mark_session_dirty()
	active_trace = Model.run(plan); var events: Array[Dictionary] = []
	for event: RefCounted in active_trace.events: events.append(event.to_dictionary().duplicate(true))
	history.append({"task": task, "metrics": active_trace.metrics.duplicate(true), "events": events, "signature": active_trace.canonical_signature()})
	if history.size() > 80: history.pop_front()
	selected_history = history.size() - 1
	if Model.accepted(active_trace.metrics, task): unlocked = maxi(unlocked, mini(task + 1, 2))
	for index: int in 3: task_buttons[index].disabled = index > unlocked
	refresh_history(); history_list.select(selected_history); history_list.call_deferred("ensure_current_is_visible"); select_run(selected_history); refresh_actions()
func refresh_history() -> void:
	history_list.clear()
	for index: int in history.size():
		var m: Dictionary = history[index].metrics
		history_list.add_item("%d · T%d · %dcyc · state%dB · first%s" % [index + 1, history[index].task + 1, m.total_cycles, m.state_read_bytes + m.state_write_bytes, str(m.first_stream_cycles)])
func measured_feedback(metrics: Dictionary, contract: int) -> String:
	if contract < 0 or contract > 2: return tr2("未知任务。", "Unknown task.")
	if not str(metrics.error).is_empty(): return tr2("拒绝：", "Rejected: ")+str(metrics.error)
	if Model.accepted(metrics,contract): return tr2("当前任务约束成立；可以继续比较自己的其他方案。", "Current task limits met; keep comparing your own alternatives.")
	var failures: Array[String] = []
	var budgets: Array[Dictionary] = [{"name":tr2("总周期", "Total cycles"),"actual":int(metrics.total_cycles),"limit":1420}]
	if contract == 0:
		budgets.append({"name":tr2("峰值空间B", "Peak space B"),"actual":int(metrics.peak_bytes),"limit":350})
	if contract != 1:
		budgets.append({"name":tr2("状态读写B", "State traffic B"),"actual":int(metrics.state_read_bytes)+int(metrics.state_write_bytes),"limit":600 if contract == 0 else 320})
	if contract > 0:
		budgets.append({"name":tr2("最晚首响应周期", "Latest first response"),"actual":int(metrics.all_streams_first_cycle),"limit":320})
	for budget: Dictionary in budgets:
		if budget.actual > budget.limit: failures.append(tr2("%s %d / 上限%d，超出%d", "%s %d / limit%d, over by%d") % [budget.name,budget.actual,budget.limit,budget.actual-budget.limit])
	var tolerance: float = 0.02 if contract == 2 else 0.000000001
	for key: String in ["max_error","max_state_error"]:
		if float(metrics[key]) > tolerance:
			var name: String = tr2("分数误差", "Score error") if key == "max_error" else tr2("最终状态误差", "Final-state error")
			failures.append(name+" "+String.num_scientific(float(metrics[key]))+" / "+String.num_scientific(tolerance))
	return " · ".join(failures) if not failures.is_empty() else tr2("证据未满足当前任务。", "Evidence does not meet this task.")

func select_run(index: int) -> void:
	selected_history = index; var record: Dictionary = history[index]; var m: Dictionary = record.metrics
	refresh_measured_source(); refresh_comparison()
	status.text = measured_feedback(m,task)
	response_chart.configure(m.first_stream_cycles if str(m.error).is_empty() else [],0 if task == 0 else 320,english)
	response_step.disabled = response_chart.first_responses.is_empty()
	response_play.disabled = response_step.disabled or bool(ProjectSettings.get_setting("game/reduced_motion",false))
	summary.text = tr2("总%d周期 · 全部%dB · 状态读写%dB · 峰值%dB\n费用 请求%d / 搬运%d / 运算%d / 提交%d / 编码%d\nA/B/C/D首响应%s · 读%d / 写%d (flush%d)\n分数误差%.6f · 最终状态误差%.6f · 外存%d→%dB", "Total%dcyc · all%dB · state%dB · peak%dB\nCosts request%d / transfer%d / compute%d / commit%d / codec%d\nA/B/C/D first%s · reads%d / writes%d (flush%d)\nScore error%.6f · state error%.6f · backing%d→%dB") % [m.total_cycles, m.traffic_bytes, m.state_read_bytes + m.state_write_bytes, m.peak_bytes, m.request_cycles, m.transfer_cycles, m.compute_cycles, m.commit_cycles, m.codec_cycles, str(m.first_stream_cycles), m.state_reads, m.state_writes, m.flush_writes, m.max_error, m.max_state_error, m.initial_backing_bytes, m.final_backing_bytes]
	tree.clear(); var root_item: TreeItem = tree.create_item()
	for event: Dictionary in record.events:
		var row: TreeItem = tree.create_item(root_item); row.set_text(0, str(event.cycle)); row.set_text(1, str(event.duration)); row.set_text(2, event.kind); row.set_metadata(0, event.details.duplicate(true))
	detail.text = JSON.stringify({"plan": m.plan, "final_states": m.final_states}, "  "); refresh_actions()
func pin_comparison() -> void:
	if selected_history < 0 or selected_history >= history.size(): return
	var metrics: Dictionary = history[selected_history].metrics
	if not str(metrics.error).is_empty(): return
	comparison_baseline = metrics.duplicate(true); refresh_comparison()

func refresh_comparison() -> void:
	if comparison_detail == null: return
	var valid: bool = selected_history >= 0 and selected_history < history.size() and str(history[selected_history].metrics.error).is_empty()
	pin_button.disabled = not valid; clear_pin_button.disabled = comparison_baseline.is_empty()
	comparison_chart.configure(comparison_baseline,history[selected_history].metrics if valid else {},english)
	comparison_chart.visible = valid and not comparison_baseline.is_empty()
	if comparison_baseline.is_empty():
		comparison_detail.text = tr2("选择一条实测记录作为对照，再选择另一条查看变化。对照仅保留在本次窗口。", "Pin one measured record, then select another to compare. The pinned baseline lasts for this window only."); return
	if not valid:
		comparison_detail.text = tr2("保留对照；当前记录未完成有效测量。", "Baseline retained; current record has no valid measurement."); return
	var m: Dictionary = history[selected_history].metrics
	var b: Dictionary = comparison_baseline
	comparison_detail.text = tr2("误差对照→当前：分数%s→%s；状态%s→%s", "Error pinned→current: score%s→%s; state%s→%s") % [String.num_scientific(b.max_error),String.num_scientific(m.max_error),String.num_scientific(b.max_state_error),String.num_scientific(m.max_state_error)]

func refresh_measured_source() -> void:
	if measured_source == null: return
	if selected_history < 0 or selected_history >= history.size():
		measured_source.text = tr2("尚无实测来源。", "No measured source yet."); return
	var measured: Dictionary = history[selected_history].metrics.plan
	var formats: Array[String] = []
	for stream: int in 4: formats.append(char(65+stream)+":"+str(measured.representations[stream]).to_upper())
	measured_source.text = tr2("实测来源：%d组 / %d状态槽 · ", "Measured source: %d groups / %d slots · ") % [measured.groups.size(),measured.slots]+"  ".join(formats)
	if measured != plan: measured_source.text += tr2("\n草稿与此记录不同；上方是记录所用方案。", "\nDraft differs from this record; the source above belongs to the measurement.")

func restore_history() -> void:
	if selected_history < 0: return
	edit(history[selected_history].metrics.plan.duplicate(true), 0); slots.set_value_no_signal(plan.slots)
func public_vector(values: Array) -> String:
	if values.size() == 8:
		var bytes: PackedByteArray = Model.pack(values,"raw64")
		var repeated: bool = true
		for i: int in range(1,8):
			if bytes.slice(i*8,(i+1)*8) != bytes.slice(0,8): repeated = false; break
		if repeated: return JSON.stringify(values[0])+" ×8"
	return JSON.stringify(values)

func refresh_public_data() -> void:
	var streams: Array = []
	for stream: int in 4:
		var values: Array = []
		for step: int in 6: values.append(Model.input(stream,step))
		streams.append({"stream":char(65+stream),"initial":Model.initial(stream),"inputs":values})
	var costs: String = tr2("每请求24次运算；链路4B/周期；请求启动4周期。\n打包/解包8次操作；RLE另加8值+run数，以8ops/周期处理。RLE64按8字节整值分run，RLE8按字节分run。Q8每次更新另加8次舍入操作。RAW64无损；Q8实际舍入。\n", "24 operations per request; link4B/cycle; setup4cycles.\nPack/unpack8 operations; RLE adds8 values+run count at8ops/cycle. RLE64 uses8-byte value runs; RLE8 uses byte runs. Q8 adds8 rounding operations per update. RAW64 is lossless; Q8 really rounds.\n")
	public_raw_button.text = tr2("返回易读视图", "Readable view") if public_raw else tr2("查看完整原始JSON", "Full raw JSON")
	if public_raw:
		public_detail.text = costs+JSON.stringify({"streams":streams,"weights":Model.WEIGHTS},"  ")
		return
	var lines: Array[String] = [costs,tr2("权重：", "Weights: ")+JSON.stringify(Model.WEIGHTS),tr2("×8表示8个字节级一致的float64值；完整数组仍可在原始视图查看。", "×8 means8 byte-identical float64 values; raw view retains every array element.")]
	for stream: Dictionary in streams:
		lines.append("\n"+tr2("流 ", "Stream ")+str(stream.stream))
		lines.append(tr2("初始状态：", "Initial state: ")+public_vector(stream.initial))
		for step: int in stream.inputs.size(): lines.append(tr2("请求%d：", "Request%d: ") % step+public_vector(stream.inputs[step]))
	public_detail.text = "\n".join(lines)

func show_public_data() -> void:
	refresh_public_data(); evidence_tabs.current_tab = 2

func public_observation() -> Dictionary:
	var public_data: Array = []
	for stream: int in 4:
		var inputs: Array = []
		for step: int in 6: inputs.append({"id": stream * 6 + step, "token": char(65 + stream) + str(step), "values": Model.input(stream, step)})
		public_data.append({"stream": char(65 + stream), "initial": Model.initial(stream), "requests": inputs})
	var observations: Array = []
	for record: Dictionary in history:
		var m: Dictionary = record.metrics
		observations.append({"task": record.task, "plan": m.plan.duplicate(true), "metrics": m.duplicate(true), "trace": record.events.duplicate(true)})
	return {"mission": mission_text(), "hint1": hint_text(), "public_data": public_data, "weights": Model.WEIGHTS.duplicate(), "task": task, "unlocked": unlocked, "draft": plan.duplicate(true), "selected_group": selected_group, "formats": Model.REPRESENTATIONS.duplicate(), "streams": [{"name": "A", "coordinates": "repeated"}, {"name": "B", "coordinates": "repeated"}, {"name": "C", "coordinates": "varied"}, {"name": "D", "coordinates": "varied"}], "rules": {"stream_steps": 6, "all_ready": 0, "link_bytes_per_cycle": 4, "setup_cycles": 4, "decoded_context_bytes": 64, "scratch_bytes": 512, "compute_ops": 24}, "measured": observations, "actions": ["select_group", "merge", "split", "move_up", "move_down", "move_to", "set_slots", "cycle_format", "undo", "redo", "run", "restore", "task", "hint", "data"]}

func change_task(index: int) -> void:
	if index == task or index < 0 or index > unlocked: return
	task = index; mark_session_dirty(); build()

func mark_session_dirty() -> void:
	if persistent_session: session_dirty = true; notice_key = "dirty"

func session_notice() -> String:
	match notice_key:
		"blocked": return tr2("已有候选存档无法安全读取；已保留原文件并禁止覆盖。", "Existing candidate save cannot be read safely; original preserved, overwriting blocked.")
		"new": return tr2("独立候选档；退出前保存本次探索。", "Isolated candidate profile; save this exploration before quitting.")
		"restored": return tr2("已恢复草稿；%d条记录按同一模型重算。未授予主线进度。", "Draft restored; %d records recomputed under the same model. No campaign progress granted.") % history.size()
		"saved": return tr2("已保存独立候选档；同一配置可继续。", "Isolated candidate profile saved; reopen the same profile to continue.")
		"failed": return tr2("保存失败，已有存档未被覆盖；请保留当前窗口。", "Save failed without overwriting the existing save; keep this window open.")
		"dirty": return tr2("草稿或记录尚未保存；退出前请保存。", "Draft or records are unsaved; save before quitting.")
	return ""

func restore_session() -> void:
	var saved: Dictionary = SessionStore.read_session()
	if not saved.ok: save_blocked = true; notice_key = "blocked"; return
	session_version = str(saved.get("digest",""))
	if saved.get("empty",false): notice_key = "new"; return
	plan = saved.draft.duplicate(true)
	for record: Dictionary in saved.runs:
		var trace: Trace = Model.run(record.plan)
		var events: Array[Dictionary] = []
		for event: RefCounted in trace.events: events.append(event.to_dictionary().duplicate(true))
		history.append({"task":int(record.task),"metrics":trace.metrics.duplicate(true),"events":events,"signature":trace.canonical_signature()})
		if Model.accepted(trace.metrics,int(record.task)): unlocked = maxi(unlocked,mini(int(record.task)+1,2))
	task = mini(int(saved.task),unlocked); selected_history = history.size()-1
	notice_key = "restored"

func save_session() -> void:
	if not persistent_session or save_blocked: return
	var records: Array = []
	for record: Dictionary in history: records.append({"task":int(record.task),"plan":record.metrics.plan.duplicate(true)})
	var raw: String = SessionStore.encode(task,plan,records)
	var error: Error = SessionStore.write_session(raw,SessionStore.PATH,session_version)
	if error == OK: session_version = raw.sha256_text(); session_dirty = false
	notice_key = "saved" if error == OK else "failed"; status.text = session_notice()

func request_quit() -> void:
	if not persistent_session or not session_dirty: get_tree().quit(); return
	var existing := get_node_or_null("UnsavedServiceDialog") as ConfirmationDialog
	if existing != null: existing.popup_centered(Vector2i(520,180)); return
	var dialog := ConfirmationDialog.new(); dialog.name = "UnsavedServiceDialog"
	dialog.title = tr2("保存本次探索？", "Save this exploration?")
	dialog.dialog_text = tr2("草稿或比较记录有未保存的变化。", "The draft or comparisons have unsaved changes.")
	dialog.ok_button_text = tr2("保存并退出", "Save and quit"); dialog.cancel_button_text = tr2("继续编辑", "Keep editing")
	dialog.add_button(tr2("不保存退出", "Quit without saving"),true,"discard")
	dialog.confirmed.connect(func() -> void:
		save_session()
		if not session_dirty: get_tree().quit())
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard": get_tree().quit())
	add_child(dialog); dialog.popup_centered(Vector2i(520,180))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and persistent_session: request_quit()

func _exit_tree() -> void:
	if persistent_session: get_tree().auto_accept_quit = previous_auto_quit
