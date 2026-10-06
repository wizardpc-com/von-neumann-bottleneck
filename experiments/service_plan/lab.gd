extends Control
## Editable plan presenter. Never supplies authoritative numerical results.
const QualityEvidence = preload("res://experiments/service_plan/quality_evidence.gd")
const EventPresenter = preload("res://experiments/service_plan/event_presenter.gd")
const Model = preload("res://experiments/service_plan/model.gd")
const StateReplayView = preload("res://experiments/service_plan/state_replay_view.gd")
const Briefing = preload("res://experiments/service_plan/briefing.gd")
const Commissions = preload("res://experiments/service_plan/commissions.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const SessionStore = preload("res://experiments/service_plan/session_store.gd")
const WriterRetry = preload("res://experiments/candidate_session/writer_retry.gd")
var writer_lease: RefCounted
var recovery_state: Dictionary = {}
var support_plans: Dictionary = {}
var candidate_journey: bool = false
var leave_to_hub: bool = false
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
var commission_mode: int = -1
var commission_choice: OptionButton
var commission_brief: Label
var commission_result: RichTextLabel
var commission_ack: Button
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
var state_source: Label
var state_replay: VBoxContainer
var measured_source: Label
var summary: Label
var detail: RichTextLabel
var selected_event_index: int = -1
var event_raw: bool = false
var event_raw_button: Button
var event_source: Label
var tree: Tree

func tr2(zh: String, en: String) -> String: return en if english else zh
func _ready() -> void:
	theme = Theme.new(); InstrumentTheme.apply_to(theme)
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
		previous_auto_quit = get_tree().auto_accept_quit; get_tree().auto_accept_quit = false
		writer_lease = SessionStore.Lease.new(SessionStore.PATH)
		restore_session()
		if not writer_lease.held:
			save_blocked = true
			notice_key = "locked"

	build()

func label(text: String, parent: Node, size: int = 15) -> Label:
	var node := Label.new(); node.text = text; node.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size); parent.add_child(node); return node
func button(text: String, parent: Node, action: Callable, id: String = "") -> Button:
	var node := Button.new(); node.text = text; node.name = id if not id.is_empty() else "Action"
	node.custom_minimum_size.y = 32; node.pressed.connect(action); parent.add_child(node); return node

func mission_text() -> String:
	if commission_mode >= 0:
		return Commissions.title(commission_mode,english)+tr2(" · 可选返修委托\n24份请求与机器不变；编辑自己的方案，运行，再按委托公开规格验收。可随时回到任务3与原结尾。", " · Optional follow-up\nSame24 requests and machine. Edit your plan, measure, then check the public specification. Task3 and the original ending remain available.")
	var common: String = tr2("4条流×6次请求；同流保序，每组输入先到、整组算完再响应。脏淘汰和最终flush必须写回。\n", "4 streams × 6 requests; preserve each stream's order. Read group inputs, compute whole group, then respond. Dirty eviction and final flush write back.\n")
	var goals: Array[String] = [tr2("1 · 少搬状态：总≤1420周期，状态读写≤600B，峰值≤350B；分数/最终状态必须精确。", "1 · Move less state: total≤1420 cycles, state reads+writes≤600B, peak≤350B; exact scores/final states."), tr2("2 · 及时服务：总≤1420周期，每流首响应≤320周期；分数/最终状态必须精确。", "2 · Prompt service: total≤1420 cycles, every stream first response≤320; exact scores/final states."), tr2("3 · 同一服务方案：总≤1420，首响应≤320，状态读写≤320B；分数/最终状态误差≤0.02。", "3 · One service plan: total≤1420, first responses≤320, state reads+writes≤320B; score/final-state errors≤0.02.")]
	return common + goals[task] + tr2("\n硬容量512B；decoded状态64B/流，权重64B，最大组72B/项，另计真实编码临时空间。", "\nHard512B: decoded contexts64B/stream, weights64B, largest group72B/request, plus actual encoded temporary bytes.")

func guidance_text() -> String:
	if commission_mode == 0: return tr2("先对照各流首响应与状态重新载入事件；少驻留并不等于少搬运。", "Compare first responses and state reload events. Less residency does not guarantee less traffic.")
	if commission_mode > 0: return tr2("区分累计状态流量与最终写回档案。误差由真实递归计算与编码产生。", "Distinguish cumulative state traffic from the final flushed archive. Recurrence and encoding produce actual errors.")
	var stages: Array[String] = [
		tr2("观察：历史留在驻留槽或外存。对照状态读写与复用事件，再试分组。", "Observe: history lives in resident slots or backing storage. Compare state transfers and reuse, then vary grouping."),
		tr2("观察：集中处理省搬运，但别人何时得到回答？对照四条流的首响应。", "Observe: concentrating work saves transfers, but who waits? Compare all four first responses."),
		tr2("观察：同一编排换表示，会改变字节、编码费用和误差。对照真实成本与质量。", "Observe: the same schedule with different storage changes bytes, codec costs and error. Compare measured cost and quality.")]
	return stages[task]

func hint_text() -> String:
	return "Hint1 · " + guidance_text()

func build() -> void:
	var previous_tab: int = evidence_tabs.current_tab if is_instance_valid(evidence_tabs) else 0
	for child: Node in get_children(): remove_child(child); child.queue_free()
	format_buttons.clear(); task_buttons.clear()
	var background := ColorRect.new(); background.color = Color("0b1720"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin); var page := VBoxContainer.new(); page.add_theme_constant_override("separation", 6); margin.add_child(page)
	var header := HBoxContainer.new(); page.add_child(header)
	var title := label(tr2("服务方案 · 谁先得到下一次结果？", "Service plan · Who gets the next result?"), header, 22); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_button = button("中文 / EN", header, func() -> void: english = not english; build(), "Language")
	if candidate_journey: button(tr2("返回首页", "Home"),header,request_hub,"CandidateHome")
	button(tr2("服务回顾", "Service review"),header,show_closure,"ServiceClosure")
	button(tr2("退出", "Quit"), header, request_quit, "Quit")
	var stages := HBoxContainer.new(); page.add_child(stages)
	for index: int in 3:
		var node: Button = button(tr2("任务%d" % (index + 1), "Task%d" % (index + 1)), stages, func() -> void: change_task(index), "Task%d" % (index + 1))
		node.disabled = index > unlocked; task_buttons.append(node)
	hint_button = button(tr2("看一个线索", "A clue"), stages, func() -> void: hint_open = not hint_open; refresh_mission(), "Hint1")
	button(tr2("服务入门", "Service introduction"), stages, show_briefing, "ServiceIntroduction")
	data_button = button(tr2("公开数据 / 成本", "Public data / costs"), stages, show_public_data, "PublicData")
	button(tr2("追加委托", "Follow-up commissions"),stages,func() -> void: start_commission(maxi(commission_mode,0)),"ServiceCommissions")
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
		add_recovery_controls(editor)
	var evidence := VBoxContainer.new(); evidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(evidence)
	var history_header := HBoxContainer.new(); evidence.add_child(history_header)
	label(tr2("实测历史 · 不随草稿改变", "Measured history · independent of drafts"), history_header).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_button = button(tr2("恢复为草稿", "Restore draft"), history_header, restore_history, "Restore")
	button(tr2("精度依据", "Quality evidence"),history_header,show_quality_evidence,"QualityEvidence")
	var support_button := button(tr2("达标方案", "Successful plan"),history_header,restore_support,"RestoreSupport")
	support_button.disabled = not support_plans.has(task)
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
	build_commissions()
	var state_panel := VBoxContainer.new(); state_panel.name = "StateHistory"; evidence_tabs.add_child(state_panel)
	evidence_tabs.set_tab_title(5,tr2("历史去向", "State journey"))
	state_source = label("",state_panel,13); state_source.name = "StateMeasuredSource"
	state_replay = StateReplayView.new(); state_replay.name = "StateReplay"
	state_replay.size_flags_vertical = Control.SIZE_EXPAND_FILL; state_panel.add_child(state_replay)
	state_replay.configure({},english)
	state_replay.frame_changed.connect(select_state_event)
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
	event_source = label("",event_panel,13)
	event_raw_button = button("",event_panel,func() -> void: event_raw = not event_raw; refresh_event_detail(),"ToggleRawEvent")
	tree = Tree.new(); tree.name = "Trace"; tree.columns = 3; tree.column_titles_visible = true; tree.hide_root = true
	tree.set_column_title(0, tr2("周期", "Cycle")); tree.set_column_title(1, tr2("费用", "Cost")); tree.set_column_title(2, tr2("事件", "Event")); tree.size_flags_vertical = Control.SIZE_EXPAND_FILL; tree.custom_minimum_size.y = 80; event_panel.add_child(tree)
	tree.set_column_expand(0,false); tree.set_column_custom_minimum_width(0,65)
	tree.set_column_expand(1,false); tree.set_column_custom_minimum_width(1,65)
	tree.item_selected.connect(func() -> void:
		selected_event_index = tree.get_selected().get_index(); refresh_event_detail()
		state_replay.show_source_index(selected_event_index))
	detail = RichTextLabel.new(); detail.name = "Details"; detail.custom_minimum_size.y = 130; detail.scroll_active = true; event_panel.add_child(detail)
	refresh_event_detail(); refresh_public_data(); refresh_groups(); refresh_history(); refresh_actions(); refresh_comparison()
	if selected_history >= 0 and selected_history < history.size(): history_list.select(selected_history); select_run(selected_history); history_list.call_deferred("ensure_current_is_visible")
	evidence_tabs.current_tab = previous_tab if previous_tab != 4 or (commission_mode >= 0 and has_service_closure()) else 0
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
	var quality_button := find_child("QualityEvidence",true,false) as Button
	if quality_button != null: quality_button.disabled = selected_history < 0 or selected_history >= history.size() or not str(history[selected_history].metrics.error).is_empty()
	var support_button := find_child("RestoreSupport",true,false) as Button
	if support_button != null: support_button.disabled = not support_plans.has(task)
	var closure := find_child("ServiceClosure",true,false) as Button
	if closure != null: closure.disabled = not has_service_closure()
	var extra := find_child("ServiceCommissions",true,false) as Button
	if extra != null: extra.disabled = not has_service_closure()
	if evidence_tabs != null and evidence_tabs.get_tab_count() > 4: evidence_tabs.set_tab_disabled(4,not has_service_closure())
	refresh_commission()
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
	selected_history = history.size() - 1; selected_event_index = -1
	if Model.accepted(active_trace.metrics, task):
		unlocked = maxi(unlocked, mini(task + 1, 2))
		support_plans[task] = plan.duplicate(true)
	for index: int in 3: task_buttons[index].disabled = index > unlocked
	refresh_history(); history_list.select(selected_history); history_list.call_deferred("ensure_current_is_visible"); select_run(selected_history); refresh_actions()
func refresh_history() -> void:
	history_list.clear()
	for index: int in history.size():
		var m: Dictionary = history[index].metrics
		if not str(m.error).is_empty():
			history_list.add_item(("%d · T%d · " % [index+1,history[index].task+1])+tr2("未运行 · ", "Not run · ")+str(m.error)); continue
		history_list.add_item("%d · T%d · %dcyc · state%dB · first%s" % [index + 1, history[index].task + 1, m.total_cycles, m.state_read_bytes + m.state_write_bytes, str(m.first_stream_cycles)])
func invalid_feedback(metrics: Dictionary) -> String:
	var error: String = str(metrics.error)
	if error == "stream_dependency":
		var steps: Array[int] = [0,0,0,0]
		var groups: Array = metrics.plan.groups
		for index: int in groups.size():
			for id: int in groups[index]:
				var stream: int = id / 6; var step: int = id % 6
				if step != steps[stream]:
					return tr2("未运行：第%d组的%s%d需要先完成%s%d；同一条流必须按顺序执行。可移动、拆组或撤销。", "Not run: group%d has %s%d before required %s%d. Preserve each stream's order; move, split or undo.") % [index+1,char(65+stream),step,char(65+stream),steps[stream]]
				steps[stream] += 1
	if error == "scratch_limit": return tr2("未运行：工作区预检超过512B；尝试拆小最大组或减少状态槽，再运行测量。", "Not run: workspace preflight exceeds512B; split the largest group or reduce context slots, then measure.")
	return tr2("未运行，方案格式无效：", "Not run; invalid plan format: ")+error

func measured_feedback(metrics: Dictionary, contract: int) -> String:
	if contract < 0 or contract > 2: return tr2("未知任务。", "Unknown task.")
	if not str(metrics.error).is_empty(): return invalid_feedback(metrics)
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
	var witness: Dictionary = QualityEvidence.build(metrics)
	var tolerance: float = 0.02 if contract == 2 else 0.000000001
	for key: String in ["max_error","max_state_error"]:
		if float(metrics[key]) > tolerance:
			var name: String = tr2("分数误差", "Score error") if key == "max_error" else tr2("最终状态误差", "Final-state error")
			var point: Dictionary = witness.get("score" if key == "max_error" else "state",{})
			if not point.is_empty(): name += " ("+QualityEvidence.identity(point,key == "max_error")+")"
			failures.append(name+" "+String.num_scientific(float(metrics[key]))+" / "+String.num_scientific(tolerance))
	return " · ".join(failures) if not failures.is_empty() else tr2("证据未满足当前任务。", "Evidence does not meet this task.")

func select_run(index: int) -> void:
	if index != selected_history: selected_event_index = -1
	selected_history = index; var record: Dictionary = history[index]; var m: Dictionary = record.metrics
	refresh_measured_source(); refresh_comparison()
	status.text = Commissions.feedback(m,commission_mode,english) if commission_mode >= 0 else measured_feedback(m,task)
	response_chart.configure(m.first_stream_cycles if str(m.error).is_empty() else [],0 if task == 0 else 320,english)
	response_step.disabled = response_chart.first_responses.is_empty()
	response_play.disabled = response_step.disabled or bool(ProjectSettings.get_setting("game/reduced_motion",false))
	summary.text = tr2("总%d周期 · 全部%dB · 状态读写%dB · 峰值%dB\n费用 请求%d / 搬运%d / 运算%d / 提交%d / 编码%d\nA/B/C/D首响应%s · 读%d / 写%d (flush%d)\n分数误差%.6f · 最终状态误差%.6f · 外存%d→%dB", "Total%dcyc · all%dB · state%dB · peak%dB\nCosts request%d / transfer%d / compute%d / commit%d / codec%d\nA/B/C/D first%s · reads%d / writes%d (flush%d)\nScore error%.6f · state error%.6f · backing%d→%dB") % [m.total_cycles, m.traffic_bytes, m.state_read_bytes + m.state_write_bytes, m.peak_bytes, m.request_cycles, m.transfer_cycles, m.compute_cycles, m.commit_cycles, m.codec_cycles, str(m.first_stream_cycles), m.state_reads, m.state_writes, m.flush_writes, m.max_error, m.max_state_error, m.initial_backing_bytes, m.final_backing_bytes]
	if not str(m.error).is_empty(): summary.text = invalid_feedback(m)+"\n"+tr2("没有性能或精度结果：该方案在执行前被拒绝。修改草稿后重新运行；历史记录保留。", "No performance or quality result: this plan was rejected before execution. Edit and rerun; history is retained.")
	tree.clear(); var root_item: TreeItem = tree.create_item()
	for event: Dictionary in record.events:
		var row: TreeItem = tree.create_item(root_item); row.set_text(0, str(event.cycle)); row.set_text(1, str(event.duration)); row.set_text(2, EventPresenter.title(event,english)); row.set_tooltip_text(2,str(event.kind)); row.set_metadata(0, event.duplicate(true))
	if selected_event_index >= 0 and selected_event_index < root_item.get_child_count():
		root_item.get_child(selected_event_index).select(0); tree.call_deferred("ensure_cursor_is_visible")
	state_replay.configure(record,english,selected_event_index)
	refresh_event_detail(); refresh_actions()

func select_state_event(source_index: int) -> void:
	selected_event_index = source_index
	var root_item: TreeItem = tree.get_root()
	if root_item != null and source_index >= 0 and source_index < root_item.get_child_count():
		root_item.get_child(source_index).select(0)
	refresh_event_detail()

func refresh_event_detail() -> void:
	if detail == null: return
	event_raw_button.text = tr2("返回事件说明", "Show explanation") if event_raw else tr2("查看原始事件 JSON", "Show raw event JSON")
	var item: TreeItem = tree.get_selected()
	if item == null:
		detail.text = tr2("选择一条实测事件，查看流身份、搬运原因与费用。", "Select a measured event for its stream, cause and cost.")
		return
	var event: Dictionary = item.get_metadata(0)
	detail.text = JSON.stringify(event,"  ") if event_raw else EventPresenter.summary(event,english)

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
		measured_source.text = tr2("尚无实测来源。", "No measured source yet.")
		if event_source != null: event_source.text = measured_source.text
		if state_source != null: state_source.text = measured_source.text
		return
	var measured: Dictionary = history[selected_history].metrics.plan
	var formats: Array[String] = []
	for stream: int in 4: formats.append(char(65+stream)+":"+str(measured.representations[stream]).to_upper())
	measured_source.text = tr2("实测来源：%d组 / %d状态槽 · ", "Measured source: %d groups / %d slots · ") % [measured.groups.size(),measured.slots]+"  ".join(formats)
	if measured != plan: measured_source.text += tr2("\n草稿与此记录不同；上方是记录所用方案。", "\nDraft differs from this record; the source above belongs to the measurement.")

	if event_source != null: event_source.text = measured_source.text
	if state_source != null: state_source.text = measured_source.text

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
	if index < 0 or index > unlocked or (index == task and commission_mode < 0): return
	commission_mode = -1
	task = index; mark_session_dirty(); build()

func mark_session_dirty() -> void:
	if persistent_session: session_dirty = true; notice_key = "dirty"

func session_notice() -> String:
	match notice_key:
		"writer-reacquired": return tr2("已取得写入权；本窗口的草稿、记录和未保存探索均保留，现在可以保存。", "Writer ownership acquired; this window’s draft, recordings and unsaved exploration are retained. You can now save.")
		"writer-retry-failed": return tr2("尚未取得写入权；当前探索仍保留。关闭占用窗口后可重试；若磁盘存档已变化，须确认重新读取才能替换本窗口探索。", "Writer ownership was not acquired; your exploration is retained. Retry after the owning window closes. If the disk save changed, confirm Reload to replace this window’s exploration.")
		"writer-unreadable": return tr2("候选档无法安全读取；保持禁止覆盖。请检查恢复快照，或保留当前窗口。", "Candidate save cannot be read safely; overwriting remains blocked. Review recovery snapshots or keep this window open.")
		"locked": return tr2("此候选档已由另一窗口占用，或上次未正常关闭；本窗口禁止保存。", "Another window owns this profile, or its previous session stopped unexpectedly; saving is blocked.")
		"blocked": return tr2("已有候选存档无法安全读取；已保留原文件并禁止覆盖。", "Existing candidate save cannot be read safely; original preserved, overwriting blocked.")
		"new": return tr2("独立候选档；退出前保存本次探索。", "Isolated candidate profile; save this exploration before quitting.")
		"restored": return tr2("已恢复草稿；%d条记录按同一模型重算。未授予主线进度。", "Draft restored; %d records recomputed under the same model. No campaign progress granted.") % history.size()
		"saved": return tr2("已保存独立候选档；同一配置可继续。", "Isolated candidate profile saved; reopen the same profile to continue.")
		"failed": return tr2("保存失败，已有存档未被覆盖；请保留当前窗口。", "Save failed without overwriting the existing save; keep this window open.")
		"dirty": return tr2("草稿或记录尚未保存；退出前请保存。", "Draft or records are unsaved; save before quitting.")
	return ""

func restore_session() -> void:
	var saved: Dictionary = SessionStore.read_session()
	recovery_state = saved if saved.get("error") == "recovery" else {}
	if not saved.ok: save_blocked = true; notice_key = "blocked"; return
	session_version = str(saved.get("digest",""))
	if saved.get("empty",false): notice_key = "new"; return
	plan = saved.draft.duplicate(true)
	for record: Dictionary in saved.runs:
		var trace: Trace = Model.run(record.plan)
		var events: Array[Dictionary] = []
		for event: RefCounted in trace.events: events.append(event.to_dictionary().duplicate(true))
		history.append({"task":int(record.task),"metrics":trace.metrics.duplicate(true),"events":events,"signature":trace.canonical_signature()})
		if Model.accepted(trace.metrics,int(record.task)):
			unlocked = maxi(unlocked,mini(int(record.task)+1,2))
			support_plans[int(record.task)] = record.plan.duplicate(true)
	for support: Dictionary in saved.supports:
		if Model.accepted(Model.run(support.plan).metrics,int(support.task)):
			support_plans[int(support.task)] = support.plan.duplicate(true)
			unlocked = maxi(unlocked,mini(int(support.task)+1,2))
	task = mini(int(saved.task),unlocked); selected_history = history.size()-1
	notice_key = "restored"

func save_session() -> void:
	if not persistent_session or save_blocked: return
	var records: Array = []
	for record: Dictionary in history: records.append({"task":int(record.task),"plan":record.metrics.plan.duplicate(true)})
	var raw: String = SessionStore.encode(task,plan,records,support_records())
	var error: Error = SessionStore.write_session(raw,SessionStore.PATH,session_version,writer_lease)
	if error == OK: session_version = raw.sha256_text(); session_dirty = false
	notice_key = "saved" if error == OK else "failed"; status.text = session_notice()
	if error != OK: refresh_recovery_controls()

func request_hub() -> void:
	leave_to_hub = true
	request_leave()

func request_quit() -> void:
	leave_to_hub = false
	request_leave()

func finish_leave() -> void:
	if leave_to_hub: get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn")
	else: get_tree().quit()

func request_leave() -> void:
	if not persistent_session or not session_dirty: finish_leave(); return
	var existing := get_node_or_null("UnsavedServiceDialog") as ConfirmationDialog
	if existing != null: existing.popup_centered(Vector2i(520,180)); return
	var dialog := ConfirmationDialog.new(); dialog.name = "UnsavedServiceDialog"
	dialog.title = tr2("保存本次探索？", "Save this exploration?")
	dialog.dialog_text = tr2("草稿或比较记录有未保存的变化。", "The draft or comparisons have unsaved changes.")
	dialog.ok_button_text = tr2("保存并离开", "Save and leave"); dialog.cancel_button_text = tr2("继续编辑", "Keep editing")
	dialog.add_button(tr2("不保存离开", "Leave without saving"),true,"discard")
	dialog.confirmed.connect(func() -> void:
		save_session()
		if not session_dirty: finish_leave())
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard": finish_leave())
	add_child(dialog); dialog.popup_centered(Vector2i(520,180))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and persistent_session: request_quit()

func _exit_tree() -> void:
	if writer_lease != null: writer_lease.release()
	if persistent_session: get_tree().auto_accept_quit = previous_auto_quit

func support_records() -> Array:
	var records: Array = []
	for id: int in support_plans: records.append({"task":id,"plan":support_plans[id].duplicate(true)})
	return records

func restore_support() -> void:
	if not support_plans.has(task): return
	edit(support_plans[task].duplicate(true),0); slots.set_value_no_signal(plan.slots)

func add_recovery_controls(parent: Node) -> void:
	if writer_lease == null or not writer_lease.held:
		button(tr2("重新检查写入权（保留本窗口探索）", "Recheck writer ownership (keep this exploration)"),parent,retry_writer.bind(false),"RetryWriter")
		button(tr2("重新读取已保存候选档", "Reload saved candidate profile"),parent,func() -> void: confirm_recovery(retry_writer.bind(true)),"ReloadCandidate")
		var stopped: String = SessionStore.Lease.stopped_owner(SessionStore.PATH)
		if not stopped.is_empty():
			button(tr2("恢复已停止窗口的写入权", "Recover stopped window’s writer ownership"),parent,func() -> void: confirm_recovery(func() -> void: recover_writer(stopped)),"RecoverWriter")
		return
	if recovery_state.is_empty(): return
	label(tr2("检测到中断或损坏。选择要恢复的快照；全部原文件会保留。", "Interrupted or damaged save. Choose a snapshot; all original files will be preserved."),parent)
	for choice: Dictionary in recovery_state.get("choices",[]):
		var source: String = choice.path
		var kind: String = tr2("主档", "Main") if source == SessionStore.PATH else (tr2("上次保存", "Previous save") if source.ends_with(".bak") else tr2("未完成安装", "Interrupted install"))
		var recovery_button := button(tr2("恢复 ", "Recover ")+kind+" · T"+str(int(choice.task)+1)+" · "+str(choice.digest).substr(0,8),parent,func() -> void: confirm_recovery(func() -> void: recover_candidate(source)),"RecoverSnapshot")
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
		notice_key = "writer-unreadable" if acquired.reason == "unreadable" else "writer-retry-failed"
		refresh_recovery_controls(); status.text = session_notice()
		return
	writer_lease = acquired.lease
	if reload_saved:
		reload_recovered_session()
		return
	save_blocked = false; recovery_state.clear(); notice_key = "writer-reacquired"
	build(); status.text = session_notice()

func recover_writer(expected_token: String) -> void:
	var acquired: Dictionary = SessionStore.Lease.recover_and_acquire(SessionStore.PATH,expected_token)
	if acquired.error != OK: recovery_failed(); return
	writer_lease = acquired.lease
	reload_recovered_session()

func recover_candidate(source: String) -> void:
	if SessionStore.recover_session(source,str(recovery_state.get("fingerprint","")),SessionStore.PATH,writer_lease) != OK: recovery_failed(); return
	reload_recovered_session()

func reload_recovered_session() -> void:
	save_blocked = false; session_dirty = false; history.clear(); support_plans.clear()
	unlocked = 0; commission_mode = -1; undo_stack.clear(); redo_stack.clear()
	restore_session(); build()

func confirm_recovery(action: Callable) -> void:
	if not session_dirty: action.call(); return
	var existing := get_node_or_null("ReplaceUnsavedRecovery") as ConfirmationDialog
	if existing != null: existing.popup_centered(); return
	var dialog := ConfirmationDialog.new(); dialog.name = "ReplaceUnsavedRecovery"
	dialog.title = tr2("替换本窗口的未保存探索？", "Replace this window’s unsaved exploration?")
	dialog.dialog_text = tr2("恢复将重新读取磁盘快照，替换本窗口尚未保存的草稿和记录。磁盘原文件仍会保留。", "Recovery reloads the disk snapshot, replacing this window’s unsaved draft and runs. Original disk files remain preserved.")
	dialog.ok_button_text = tr2("恢复所选快照", "Recover selected snapshot")
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
	status.text = tr2("恢复未执行：文件或写入权已变化。当前草稿仍保留；请检查快照后重试，或保留窗口。", "Recovery was not performed: files or ownership changed. Your current draft is retained; review the snapshots and retry, or keep this window open.")

# Review derives only from independently protected, currently accepted plans.
# Recent history, current draft and the last unlocked task are not completion evidence.
func service_review_evidence() -> Array[Dictionary]:
	var evidence: Array[Dictionary] = []
	for id: int in 3:
		if not support_plans.has(id): return []
		var trace: Trace = Model.run(support_plans[id])
		if not Model.accepted(trace.metrics,id): return []
		evidence.append(trace.metrics.duplicate(true))
	return evidence

func has_service_closure() -> bool:
	return service_review_evidence().size() == 3

func show_closure() -> void:
	var evidence: Array[Dictionary] = service_review_evidence()
	if evidence.size() != 3: return
	var existing := get_node_or_null("ServiceReview") as AcceptDialog
	if existing != null: remove_child(existing); existing.queue_free()
	var review := AcceptDialog.new(); review.name = "ServiceReview"; review.dialog_autowrap = true
	review.title = tr2("服务 · 你的方案回应了三份合同", "Service · Your plans answered all three contracts")
	var lines: Array[String] = [tr2("历史被留下、搬运并再次使用；请求者在不同时间收到结果。你构造的服务在公开成本与质量要求下完成了工作。", "History was retained, moved and reused; requesters received results at different times. Your service completed its work under the public cost and quality requirements."), ""]
	for id: int in 3:
		var m: Dictionary = evidence[id]
		lines.append(tr2("合同%d · %d周期 · 状态%dB · 峰值%dB", "Contract%d · %d cycles · state%dB · peak%dB") % [id+1,m.total_cycles,m.state_read_bytes+m.state_write_bytes,m.peak_bytes])
		lines.append(tr2("A/B/C/D首响应%s · 分数误差%s · 状态误差%s", "A/B/C/D first%s · score error%s · state error%s") % [str(m.first_stream_cycles),String.num_scientific(m.max_error),String.num_scientific(m.max_state_error)])
	lines.append("")
	lines.append(tr2("结果由保留的达标方案按当前模型重算。可继续取回方案，尝试不同取舍。A Thought Within the World。", "Results are recomputed from your protected successful plans under the current model. Restore them and explore other trade-offs. A Thought Within the World."))
	if session_dirty:
		lines.append(tr2("本次变化尚未保存；离开前请保存。", "This session has unsaved changes; save before leaving."))
	elif persistent_session:
		lines.append(tr2("已保存的方案可在同一候选档继续。", "Saved plans can be resumed in this candidate profile."))
	else:
		lines.append(tr2("本次为临时实验；退出后不会保留。", "This trial is temporary; quitting does not retain it."))
	var scroll := ScrollContainer.new(); scroll.name = "ServiceReviewScroll"
	scroll.custom_minimum_size = Vector2(720,360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	review.add_child(scroll)
	var content := Label.new(); content.name = "ServiceReviewContent"
	content.text = "\n".join(lines); content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	review.ok_button_text = tr2("回到我的工作台", "Back to my workbench")
	add_child(review); review.popup_centered(Vector2i(760,480))

# Optional follow-ups reuse saved plan recipes; no new task IDs or completion flags.
func build_commissions() -> void:
	var scroll := ScrollContainer.new(); scroll.name = "Commissions"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; evidence_tabs.add_child(scroll)
	var panel := VBoxContainer.new(); panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(panel)
	evidence_tabs.set_tab_title(4,tr2("追加委托", "Follow-ups"))
	commission_choice = OptionButton.new(); commission_choice.name = "CommissionChoice"
	for id: int in 3: commission_choice.add_item(Commissions.title(id,english),id)
	commission_choice.selected = maxi(commission_mode,0); panel.add_child(commission_choice)
	commission_choice.item_selected.connect(start_commission)
	commission_brief = label("",panel,15); commission_brief.name = "CommissionBrief"
	var notice := label(tr2("规格切换不改测量。成绩来自选中的实测记录，草稿须重新运行。保存沿用候选档，委托选择仅在本窗口；重开后可重新选择并验收保留的记录（最近80条）。", "Changing specifications does not change measurements. Check the selected record; run edited drafts again. Candidate Save retains recipes, with the latest80 records. Specification selection lasts for this window; reselect it after restart to check retained records."),panel,13)
	notice.name = "CommissionPersistence"
	commission_result = RichTextLabel.new(); commission_result.name = "CommissionResult"
	commission_result.fit_content = true; commission_result.scroll_active = false; commission_result.custom_minimum_size.y = 100
	panel.add_child(commission_result)
	commission_ack = button(tr2("交付这份实测方案", "Hand over this measured plan"),panel,acknowledge_commission,"CommissionAcknowledge")
	button(tr2("取回选中记录为草稿", "Restore selected record as draft"),panel,restore_history,"CommissionRestore")
	evidence_tabs.tab_changed.connect(func(index: int) -> void:
		if index == 4 and commission_mode < 0: start_commission(commission_choice.selected))
	refresh_commission()

func start_commission(id: int) -> void:
	if id < 0 or id > 2 or not has_service_closure(): return
	if task != 2: task = 2; mark_session_dirty()
	commission_mode = id; commission_choice.select(id); evidence_tabs.current_tab = 4
	refresh_mission(); refresh_commission()
	if selected_history >= 0 and selected_history < history.size(): select_run(selected_history)

func refresh_commission() -> void:
	if commission_brief == null: return
	var id: int = maxi(commission_mode,0)
	commission_brief.text = Commissions.briefing(id,english)
	commission_ack.disabled = true
	if not has_service_closure():
		commission_result.text = tr2("先完成原三份合同；服务回顾成立后，可自由接这些委托。", "Complete the original three contracts first. These commissions become available after your service review is earned."); return
	if selected_history < 0 or selected_history >= history.size():
		commission_result.text = tr2("尚无实测记录；先运行自己的方案。", "No measurement yet. Run your own plan first."); return
	var m: Dictionary = history[selected_history].metrics
	var lines: Array[String] = [tr2("记录%d · 以此记录的方案验收，未运行草稿不算。", "Record%d · Check this record's plan; unrun drafts do not count.") % (selected_history+1),Commissions.feedback(m,id,english)]
	if str(m.error).is_empty():
		lines.append(tr2("%d槽 · %d周期 · A/B/C/D首响应%s\n最终档案%dB（含目录与最终写回）· 累计状态读写%dB\n分数误差%s · 最终状态误差%s", "%d slots · %d cycles · A/B/C/D first%s\nFinal archive%dB (including directory and final flush) · cumulative state traffic%dB\nScore error%s · final-state error%s") % [m.plan.slots,m.total_cycles,str(m.first_stream_cycles),m.final_backing_bytes,m.state_read_bytes+m.state_write_bytes,String.num_scientific(m.max_error),String.num_scientific(m.max_state_error)])
	if m.plan != plan: lines.append(tr2("当前草稿与记录不同；交付的是记录中的方案。", "Current draft differs; handoff uses the recorded plan."))
	commission_result.text = "\n\n".join(lines)
	commission_ack.disabled = commission_mode < 0 or not Commissions.accepted(m,id)

func acknowledge_commission() -> void:
	if commission_mode < 0 or not has_service_closure() or selected_history < 0 or selected_history >= history.size(): return
	var m: Dictionary = history[selected_history].metrics
	if not Commissions.accepted(m,commission_mode): return
	var old := get_node_or_null("CommissionDelivery") as AcceptDialog
	if old != null: remove_child(old); old.queue_free()
	var review := AcceptDialog.new(); review.name = "CommissionDelivery"; review.dialog_autowrap = true
	review.title = Commissions.title(commission_mode,english)
	var text: String = tr2("这份实测方案已满足所选委托。相同请求，在不同驻留与档案规格下需要不同安排。\n\n", "This measured plan meets the selected commission. The same requests call for different arrangements under different residency and archive requirements.\n\n")+commission_result.text+"\n\n"+(session_notice() if persistent_session else tr2("临时实验；退出后不保留。", "Temporary trial; quitting does not retain it."))
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(680,320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; review.add_child(scroll)
	var content := Label.new(); content.name = "CommissionDeliveryContent"; content.text = text
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(content)
	review.ok_button_text = tr2("继续我的探索", "Continue exploring")
	add_child(review); review.popup_centered(Vector2i(720,480))

# A reopenable rules/operations guide; never edits a recipe or supplies a solution.
func show_briefing() -> void:
	var existing := get_node_or_null("ServiceBriefing") as AcceptDialog
	if existing != null: remove_child(existing); existing.queue_free()
	var dialog := AcceptDialog.new(); dialog.name = "ServiceBriefing"
	dialog.title = tr2("服务入门 · 留下历史，再回答", "Service introduction · Retain history, then respond")
	dialog.ok_button_text = tr2("回到我的方案", "Back to my plan")
	var tabs := TabContainer.new(); tabs.name = "BriefingPages"
	tabs.custom_minimum_size = Vector2(680,320); dialog.add_child(tabs)
	for page: Dictionary in Briefing.pages(english):
		var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(scroll); tabs.set_tab_title(tabs.get_tab_count()-1,page.title)
		var text := Label.new(); text.text = page.body; text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(text)
	add_child(dialog); dialog.popup_centered(Vector2i(720,430))

func show_quality_evidence() -> void:
	if selected_history < 0 or selected_history >= history.size(): return
	var record: Dictionary = history[selected_history]
	var tolerance: float = float(Commissions.spec(commission_mode).tolerance) if commission_mode >= 0 else (0.02 if task == 2 else 0.000000001)
	var evidence: Dictionary = QualityEvidence.build(record.metrics,record.events)
	var existing := get_node_or_null("MeasuredQualityReview") as AcceptDialog
	if existing != null: remove_child(existing); existing.queue_free()
	var review := AcceptDialog.new(); review.name = "MeasuredQualityReview"
	review.title = tr2("记录%d · 精度依据", "Measurement%d · Quality evidence") % (selected_history+1)
	var content := RichTextLabel.new(); content.name = "QualityContent"
	content.custom_minimum_size = Vector2(660,260); content.scroll_active = true
	content.text = measured_source.text+"\n\n"+QualityEvidence.text(evidence,tolerance,english)
	review.add_child(content); review.ok_button_text = tr2("回到实测记录", "Back to measurement")
	add_child(review); review.popup_centered(Vector2i(700,330))
