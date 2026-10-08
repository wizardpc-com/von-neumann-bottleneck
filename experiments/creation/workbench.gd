extends Control
## One persistent draft; UI presents frozen model results and revealed prefixes.
const WorkFocus = preload("res://experiments/creation/work_focus.gd")
const Session = preload("res://experiments/creation/session.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
const Model = preload("res://experiments/creation/model.gd")
const CostLedger = preload("res://experiments/creation/cost_ledger.gd")
const CostLedgerView = preload("res://experiments/creation/cost_ledger_view.gd")
const CausalPanel = preload("res://experiments/creation/causal_panel.gd")
const CreationComparison = preload("res://experiments/creation/comparison.gd")
const Explanation = preload("res://experiments/creation/explanation.gd")
const SignalView = preload("res://experiments/creation/signal_view.gd")
const Typography = preload("res://src/ui/ui_typography.gd")
var work_focus: Window
var work_focus_return: Control
var session = Session.new()
var english: bool = false
var task: int = 0
var source_kind: int = 0
var codec: String = "predictive"
var latest: Dictionary = {}
# A restored draft has no current run; rebuilds must not resurrect a saved work.
var suppress_snapshot_fallback: bool = false
var records: Array[Dictionary] = []
var comparison: Array[Dictionary] = []
var pinned_creation: Dictionary = {}
var compared_creation: Dictionary = {}
var creation_report: Dictionary = {}
var creation_caption: Label
var playing: bool = false
var playback_elapsed: float = 0
var previous_auto_quit: bool = true
var leaving_to_hub: bool = false
var status_text: String = ""
var evidence_expanded: bool = false
var evidence_toggle: Button
var signal_area: VBoxContainer
var signal_view: Control
var status: Label
var provenance: Label
var machine_strip: Label
var measured_summary: Label
var saved_work_closure: HFlowContainer
var saved_work_caption: Label
var kept_work: Dictionary = {}
var causal_panel: VBoxContainer
var causal_tabs: TabContainer
var focused_cell: int = -1
var focused_lane: int = 2
var focused_source: String = ""
var observation_anchor: Dictionary = {}
var inspected_context: Array = []
var inspected_counts: Array = []
var restoring_observation: bool = false
var inspector: Label
var costs: Label
var events: Tree
var rules: Tree
var works: ItemList
var name_input: LineEdit
var task_choice: OptionButton
var commit_button: Button
var reveal_button: Button
var continue_prediction_button: Button
var mismatch_prediction_button: Button
var run_button: Button
var feedback_button: Button
var play_button: Button
var train_button: Button
var selected_examples: Label
var examples_list: VBoxContainer
var event_page: int = 0
var event_caption: Label
var prediction_recipe: Dictionary = {}
var writable: bool = true
var recovery_choices: Array = []
var recovery_fingerprint: String = ""
var transport_comparisons: Array[Dictionary] = []
var selected_cost_comparison: int = -1
var cost_comparison_page: VBoxContainer
var cost_comparison_choice: OptionButton
var cost_comparison_status: Label
var cost_comparison_view: Control
var cost_comparison_details: Label
var recovery_dialog: ConfirmationDialog
var writer_dialog: ConfirmationDialog
var leave_dialog: ConfirmationDialog

func text2(zh: String, en: String) -> String:
	return en if english else zh

func _ready() -> void:
	var localization := get_node_or_null("/root/Localization")
	if localization != null: english = localization.current_locale() == "en"
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--locale=en": english = true
	var opened: Dictionary = session.open(Session.launch_path())
	writable = bool(opened.get("writable",false))
	recovery_choices = opened.get("choices",[]).duplicate(true)
	recovery_fingerprint = str(opened.get("fingerprint",""))
	status_text = text2("草稿与作品使用独立候选档。先选择样例，学习你的规则盒。","Drafts and works use an isolated candidate profile. Choose examples and learn your rule box.") if opened.get("ok",false) else str(opened.get("error",session.error))
	if not writable: status_text = text2("当前候选档只读：可回看受保护快照；保存被禁用，原文件不会被覆盖。","Candidate profile is read-only: protected snapshots remain playable; saving is disabled and the original file stays intact.")+" "+str(opened.get("error",session.error))
	if opened.get("error", "") == "raw_restore_readonly":
		status_text = text2("旧候选档把 RAW 误记为模型复原，现以只读方式打开。已验证作品可回看，原文件不会改写；请保留备份，在新的候选档重新学习并发送预测包来取得复原证据。", "This older profile counted RAW as model restoration. It is now read-only: validated works remain viewable and the original file is untouched. Keep a backup; learn and send a predictive packet in a fresh candidate profile to earn restoration evidence.")

	task = clampi(int(session.data.get("task",0)),0,8)
	var navigation := get_node_or_null("/root/TaskNavigation")
	if navigation != null:
		var requested: int = navigation.take_pending("creation")
		if requested >= 0: task = clampi(requested,0,8)
		navigation.remember_candidate_visit("creation",task)
	previous_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	add_to_group("candidate_quit_owners")
	var skin := Theme.new()
	InstrumentTheme.apply_to(skin)
	skin.default_font_size = 14
	for control: String in ["Label","Button","OptionButton","Tree","ItemList","LineEdit"]:
		skin.set_color("font_color",control,Color("e9f0fa"))
	for control: String in ["VBoxContainer","HBoxContainer"]: skin.set_constant("separation",control,8)
	skin.set_stylebox("panel","Tree",InstrumentTheme.panel(Color("0b1722")))
	theme = skin
	build()

func _exit_tree() -> void:
	session.close()
	get_tree().auto_accept_quit = previous_auto_quit

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: request_leave(false)

func label(value: String, parent: Node, font_size: int = 14) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",font_size)
	parent.add_child(node)
	return node

func button(value: String, handle: String, parent: Node, action: Callable) -> Button:
	var node := Button.new()
	node.name = handle
	node.text = value
	node.custom_minimum_size.y = 36
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func panel(parent: Node, handle: String) -> VBoxContainer:
	var surface := PanelContainer.new()
	surface.name = handle
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(surface)
	var column := VBoxContainer.new()
	surface.add_child(column)
	return column

func tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.name = "Page"+str(tabs.get_tab_count())
	tabs.add_child(node)
	tabs.set_tab_title(tabs.get_tab_count()-1,title)
	return node

func scroll_column(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.focus_mode = Control.FOCUS_ALL
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return column

func build() -> void:
	playing = false
	if task == 8 and not suppress_snapshot_fallback and latest.is_empty() and not session.data.works.is_empty():
		var saved: Dictionary = session.data.works[-1]
		latest = {"kind":"snapshot","output":saved.output.duplicate(),"work":saved.duplicate(true)}
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	add_child(preload("res://src/ui/technical_backdrop.gd").new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Preserve the signal and evidence minima at 720px while keeping horizontal gutters.
	for edge: String in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,12)
	for edge: String in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,6)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation",2)
	margin.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	var title: Label = label(text2("光纹工作台 · 压缩 → 预测 → 创造","Signal workbench · compress → predict → create"),header,22)
	title.add_theme_font_override("font",Typography.HEADING_FONT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("中文 / EN","Language",header,toggle_language)
	button(text2("保存草稿","Save draft"),"SaveDraft",header,save_draft).disabled = not writable
	button(text2("返回旅程","Journey"),"Journey",header,func() -> void: request_leave(true))
	button(text2("退出","Quit"),"Quit",header,func() -> void: request_leave(false))
	if not writable: _build_writer_controls(page)
	var navigation := HBoxContainer.new()
	page.add_child(navigation)
	task_choice = OptionButton.new()
	task_choice.name = "Unit"
	task_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i: int in Catalog.IDS.size():
		var completed: bool = session.data.get("supports",{}).has(Catalog.IDS[i])
		task_choice.add_item(("✓ " if completed else "")+Catalog.title(i,english))
	task_choice.select(task)
	task_choice.item_selected.connect(change_task)
	navigation.add_child(task_choice)
	button(text2("撤销","Undo"),"UndoDraft",navigation,func() -> void: restore_draft_history(false))
	button(text2("重做","Redo"),"RedoDraft",navigation,func() -> void: restore_draft_history(true))
	button(text2("上一单元","Previous"),"Previous",navigation,func() -> void: change_task(maxi(0,task-1)))
	button(text2("下一单元","Next"),"Next",navigation,func() -> void: change_task(mini(8,task+1)))
	var mission: Label = label(Catalog.goal(task,english),page,14)
	mission.name = "Mission"
	mission.custom_minimum_size.y = 42
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	var left: VBoxContainer = panel(body,"SharedMachine")
	(left.get_parent() as Control).custom_minimum_size.x = 358
	(left.get_parent() as Control).size_flags_horizontal = Control.SIZE_FILL
	label(text2("同一台机器 · 同一个规则盒","One machine · one rule box"),left,17)
	var edit_tabs := TabContainer.new()
	edit_tabs.name = "DraftTabs"
	edit_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit_tabs.use_hidden_tabs_for_min_size = false
	left.add_child(edit_tabs)
	_build_examples(scroll_column(tab(edit_tabs,text2("样例与记忆","Examples / history"))))
	_build_machine(scroll_column(tab(edit_tabs,text2("机器与材料","Machine / material"))))
	_build_generation(scroll_column(tab(edit_tabs,text2("创作配方","Creation recipe"))))
	if task >= 6: edit_tabs.current_tab = 2
	if task == 2: edit_tabs.current_tab = 1
	train_button = button(text2("从当前样例学习","Learn selected examples"),"Train",left,train_model)
	label(text2("修改草稿不会暗改已学模型。点「学习」才建立新版本；每段样例独立，不首尾拼接。","Draft edits do not change learned rules. Learn explicitly to make a new version; examples are independent."),left,12)
	var right: VBoxContainer = panel(body,"SignalEvidence")
	right.add_theme_constant_override("separation",4)
	var evidence_header := HBoxContainer.new()
	right.add_child(evidence_header)
	provenance = label("",evidence_header,12)
	provenance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evidence_toggle = button(text2("展开证据","Expand evidence"),"ReturnToSignal",evidence_header,func() -> void: set_evidence_expanded(false))
	evidence_toggle.visible = evidence_expanded
	provenance.name = "Provenance"
	machine_strip = label("",right,11)
	machine_strip.name = "MachineResources"
	machine_strip.add_theme_color_override("font_color",Color("a9bbc9"))
	measured_summary = label("",right,12)
	measured_summary.name = "LiveMeasurementSummary"
	saved_work_closure = HFlowContainer.new()
	saved_work_closure.name = "SavedWorkClosure"
	right.add_child(saved_work_closure)
	saved_work_caption = label("",saved_work_closure,13)
	saved_work_caption.custom_minimum_size = Vector2(180,36)
	saved_work_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	saved_work_caption.clip_text = true
	saved_work_caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button(text2("观看完整作品","View full saved work"),"ViewKeptWork",saved_work_closure,view_kept_work)
	button(text2("修改此作品","Edit this work"),"ContinueCreation",saved_work_closure,continue_creation)
	signal_area = VBoxContainer.new()
	signal_area.name = "SignalPresentation"
	signal_area.add_theme_constant_override("separation",4)
	right.add_child(signal_area)
	signal_view = SignalView.new()
	signal_view.name = "SignalView"
	signal_view.english = english
	signal_view.cell_selected.connect(inspect_cell)
	signal_area.add_child(signal_view)
	var playback := HBoxContainer.new()
	signal_area.add_child(playback)
	play_button = button(text2("播放","Play"),"Play",playback,toggle_playback)
	button(text2("单步","Step"),"PlaybackStep",playback,step_playback)
	button("◀","PageBack",playback,func() -> void: browse_page(-1))
	button("▶","PageForward",playback,func() -> void: browse_page(1))
	var playback_note: Label = label(text2("只回放已发生输出，暂停不改变模拟。","Playback only; pause never changes simulation."),playback,12)
	playback_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playback_note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button(text2("展开证据","Expand evidence"),"ExpandEvidence",playback,func() -> void: set_evidence_expanded(true))
	var inspection_scroll := ScrollContainer.new()
	inspection_scroll.name = "InspectionScroll"
	inspection_scroll.custom_minimum_size.y = 32
	inspection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inspection_scroll.focus_mode = Control.FOCUS_ALL
	signal_area.add_child(inspection_scroll)
	inspector = label(text2("点选一格查看真实来源。A ● / B ■ / C ▲ / D ◇","Select a cell to trace its source. A ● / B ■ / C ▲ / D ◇"),inspection_scroll,12)
	inspector.name = "CellInspector"
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var evidence_tabs := TabContainer.new()
	causal_tabs = evidence_tabs
	evidence_tabs.name = "EvidenceTabs"
	# Keep the candidate row visible beneath the tab bar at the base viewport.
	evidence_tabs.custom_minimum_size.y = 88
	evidence_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	evidence_tabs.use_hidden_tabs_for_min_size = false
	right.add_child(evidence_tabs)
	costs = label("",scroll_column(tab(evidence_tabs,text2("实测与对照","Measurements"))),13)
	costs.name = "Costs"
	var event_tab: VBoxContainer = tab(evidence_tabs,text2("事件","Events"))
	var event_nav := HBoxContainer.new()
	event_tab.add_child(event_nav)
	button("◀","EventPrevious",event_nav,func() -> void: event_page = maxi(0,event_page-1); refresh())
	button("▶","EventNext",event_nav,func() -> void: event_page += 1; refresh())
	event_caption = label("",event_nav,12)
	event_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	events = _tree(event_tab,[text2("阶段 · 操作","Phase · operation"),text2("运算","Ops"),"B",text2("周期","Cycles")])
	events.name = "Events"
	events.item_selected.connect(inspect_event)
	rules = _tree(tab(evidence_tabs,text2("学得规则","Learned rules")),[text2("上下文","Context"),"A","B","C","D"])
	rules.name = "Rules"
	rules.item_selected.connect(inspect_rule)
	_build_works(scroll_column(tab(evidence_tabs,text2("作品与配方","Works / recipes"))))
	_build_cost_comparison(evidence_tabs)
	causal_panel = CausalPanel.new()
	causal_panel.english = english
	causal_panel.name = text2("因果详情","Cause details")
	evidence_tabs.add_child(causal_panel)
	if task == 8: evidence_tabs.current_tab = 3
	elif task in [1,2]: evidence_tabs.current_tab = cost_comparison_page.get_index()
	var actions := HFlowContainer.new()
	actions.name = "ModeActions"
	right.add_child(actions)
	_build_actions(actions)
	status = label(status_text,page,13)
	status.name = "Status"
	status.custom_minimum_size.y = 30
	_build_leave_dialog()
	_build_recovery_dialog()
	refresh()
	refresh_tracks()
	set_evidence_expanded(evidence_expanded)

func _tree(parent: Node, titles: Array) -> Tree:
	var node := Tree.new()
	node.hide_root = true
	node.columns = titles.size()
	node.column_titles_visible = true
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.custom_minimum_size.y = 82
	for i: int in titles.size():
		node.set_column_title(i,str(titles[i]))
		if i > 0:
			node.set_column_expand(i,false)
			node.set_column_custom_minimum_width(i,58)
	parent.add_child(node)
	return node

func _choice(parent: Node, caption: String, handle: String, titles: Array, index: int, action: Callable) -> OptionButton:
	label(caption,parent,13)
	var node := OptionButton.new()
	node.name = handle
	node.custom_minimum_size.y = 34
	for title: Variant in titles: node.add_item(str(title))
	node.select(index)
	node.item_selected.connect(action)
	parent.add_child(node)
	return node

func _build_examples(parent: Node) -> void:
	_choice(parent,text2("记住最近几项","History length"),"Order",[text2("0 · 不看上下文","0 · no context"),"1","2"],int(session.data.draft.order),func(index: int) -> void:
		session.data.draft.order = index
		edit_draft())
	label(text2("选择公开样例，或加入你自己的一段。已揭晓检查不会自动回灌。","Select public examples or add your own passage. Revealed checks never enter training automatically."),parent,12)
	selected_examples = label("",parent,12)
	selected_examples.name = "SelectedExamples"
	examples_list = VBoxContainer.new()
	parent.add_child(examples_list)
	for i: int in 5:
		var sample: Array = Catalog.sample(i)
		var choice := CheckBox.new()
		choice.name = "Example"+str(i)
		choice.text = (Catalog.SAMPLE_NAMES_EN if english else Catalog.SAMPLE_NAMES_ZH)[i]
		choice.button_pressed = sample in session.data.draft.examples
		choice.toggled.connect(func(enabled: bool) -> void:
			var examples: Array = session.data.draft.examples
			if enabled and not sample in examples and examples.size() >= 16:
				choice.set_pressed_no_signal(false)
				set_status(text2("最多选择16段样例；请先移除一段。","Select at most 16 examples; remove one first."))
				return
			if enabled and not sample in examples: examples.append(sample.duplicate())
			if not enabled: examples.erase(sample)
			edit_draft())
		parent.add_child(choice)
		label(Catalog.symbols(sample),parent,11)
	label(text2("自己的样例（A B C D，最多96项）","Your example (A B C D; max 96)"),parent,12)
	var entry := LineEdit.new()
	entry.name = "CustomExample"
	entry.placeholder_text = "A B A C A B A D"
	parent.add_child(entry)
	button(text2("加入样例","Add example"),"AddExample",parent,func() -> void:
		var parsed: Dictionary = Catalog.parse_symbols(entry.text)
		if not parsed.ok or parsed.symbols.is_empty():
			set_status(text2("样例需包含合法符号：","Example needs legal symbols: ")+str(parsed.get("error","empty")))
			return
		if session.data.draft.examples.size() >= 16:
			set_status(text2("最多选择16段样例；请先移除一段。","Select at most 16 examples; remove one first."))
			return
		session.data.draft.examples.append(parsed.symbols)
		edit_draft()
		entry.clear())
	button(text2("清空所选样例","Clear selection"),"ClearExamples",parent,func() -> void:
		session.data.draft.examples = []
		edit_draft()
		rebuild_editor_preserving_inputs())
	label(text2("准备费用来自实际读取、计数更新与模型写入，可在事件页查看。","Preparation pays for actual sample reads, count updates and model writes; inspect Events."),parent,12)

func _build_machine(parent: Node) -> void:
	if task == 2:
		var conditions = preload("res://experiments/creation/condition_examples.gd")
		label(conditions.hint(english),parent,12)
		for index: int in 2:
			button(conditions.title(index,english),"MachineCondition"+str(index),parent,func() -> void: apply_machine_condition(index))
	for spec: Array in [["cpu_ops_per_cycle",text2("计算吞吐 · 运算/周期","Compute · ops/cycle"),[1,4,16,64]],["bytes_per_cycle",text2("通道带宽 · 字节/周期","Bus · bytes/cycle"),[1,4,16,64]],["request_cycles",text2("每次请求开销 · 周期","Request overhead · cycles"),[0,2,16,64]],["cache_rows",text2("自动LRU规则行缓存","Automatic LRU rule rows"),[0,2,4,8,21]],["memory_bytes",text2("有限内存 · 字节","Memory · bytes"),[256,1024,8192,65536]]]:
		var key: String = spec[0]
		var values: Array = spec[2]
		var selected: int = values.find(int(session.data.draft.machine[key]))
		if selected < 0:
			values = values.duplicate()
			values.append(int(session.data.draft.machine[key]))
			selected = values.size()-1
		_choice(parent,spec[1],key,values,selected,func(index: int) -> void:
			session.data.draft.machine[key] = values[index]
			edit_draft())
	label(text2("顺序执行：学习 / 编码 / 搬运 / 解码或预测 / 输出。固定请求费用和缓存命中来自同一公开模型。","Sequential execution: learn / encode / move / decode or predict / output. Request overhead and cache hits use the same public model."),parent,12)
	_choice(parent,text2("压缩端公开原文","Public compression source"),"Source",[text2("规律与四处例外 · 1536项","Pattern + four exceptions · 1536"),text2("近随机 · 1536项","Near-random · 1536"),text2("短片段 · 12项","Short passage · 12")],source_kind,func(index: int) -> void:
		source_kind = index
		latest = {}
		refresh_tracks()
		refresh_cost_comparison()
		set_status(text2("原文已改变；旧实测仍按原条件保留。","Source changed; prior measurements retain their original conditions.")))
	label(text2("这是新三章的有界执行层。旧电路与旧成绩保留，新层周期不与旧模拟排名。","This is the bounded execution layer for these chapters. Original circuits and records remain; cycles are not ranked across different simulators."),parent,12)

func apply_machine_condition(index: int) -> void:
	session.data.draft.machine = preload("res://experiments/creation/condition_examples.gd").machine(index)
	edit_draft()
	rebuild_editor_preserving_inputs()
	set_status(text2("机器条件已应用。原文、规则盒与旧实测保持；请运行对照。","Machine condition applied. Source, rules and prior measurements remain; run a comparison."))

func valid_initial_input() -> bool:
	var input := find_child("Initial",true,false) as LineEdit
	return input == null or bool(Catalog.parse_symbols(input.text).ok)

func _build_generation(parent: Node) -> void:
	label(text2("起始上下文（A B C D，空段也允许）","Initial context (A B C D; empty is allowed)"),parent,13)
	var initial := LineEdit.new()
	initial.name = "Initial"
	initial.text = Catalog.symbols(session.data.draft.initial)
	parent.add_child(initial)
	initial.text_changed.connect(func(value: String) -> void:
		var parsed: Dictionary = Catalog.parse_symbols(value)
		if parsed.ok:
			session.data.draft.initial = parsed.symbols
			edit_draft()
		else:
			session.generated = {}
			latest = {}
			refresh_tracks()
			refresh()
			set_status(text2("起始片段格式不合法：","Invalid initial context: ")+str(parsed.error)))
	_choice(parent,text2("采样规则","Sampling"),"Sampler",[text2("按学得计数比例选择","Weighted learned counts"),text2("最大后继 · 稳定平局","Maximum · stable ties")],0 if session.data.draft.sampler == "weighted" else 1,func(index: int) -> void:
		session.data.draft.sampler = "weighted" if index == 0 else "max"
		edit_draft())
	for spec: Array in [["seed",text2("独立随机种子","Independent random seed"),1,2147483646],["length",text2("总长度 · 包含起始片段","Total length · includes initial context"),8,256]]:
		label(spec[1],parent,13)
		var spin := SpinBox.new()
		var key: String = spec[0]
		spin.name = key.capitalize()
		spin.min_value = spec[2]
		spin.max_value = spec[3]
		spin.step = 1
		spin.value = int(session.data.draft[key])
		spin.value_changed.connect(func(value: float) -> void:
			session.data.draft[key] = int(value)
			edit_draft())
		parent.add_child(spin)
	_build_creation_comparison(parent)
	label(text2("输出只回灌上下文，不自动训练。选择意图和作品，不用隐藏审美分数。语言、播放和窗口状态不改变输出。","Output updates context only; it never trains itself. You choose intent and works, without a hidden beauty score. Locale, playback and window state cannot change output."),parent,12)

func _build_works(parent: Node) -> void:
	works = ItemList.new()
	works.name = "Works"
	works.size_flags_vertical = Control.SIZE_EXPAND_FILL
	works.custom_minimum_size.y = 70
	parent.add_child(works)
	var actions := HBoxContainer.new()
	parent.add_child(actions)
	button(text2("播放快照","Play snapshot"),"PlayWork",actions,play_work)
	button(text2("专注看作品","Focus on work"),"FocusWork",actions,focus_work)
	button(text2("配方再生核对","Replay recipe"),"ReplayWork",actions,replay_work)
	button(text2("从此分叉","Fork"),"ForkWork",actions,fork_work)
	name_input = LineEdit.new()
	name_input.name = "WorkName"
	name_input.placeholder_text = text2("为这份实际输出命名","Name this actual output")
	parent.add_child(name_input)
	button(text2("确认并保存当前作品","Confirm and save this work"),"KeepWork",parent,keep_work).disabled = not writable
	label(text2("快照原样保护。再生核对不覆盖它；分叉创建新草稿，不改旧作品。","Snapshots stay intact. Recipe checks never overwrite them; forking makes a new draft."),parent,12)

func _build_actions(parent: Node) -> void:
	commit_button = null
	reveal_button = null
	continue_prediction_button = null
	mismatch_prediction_button = null
	feedback_button = null
	if task < 3:
		run_button = button(text2("发送预测包并复原","Send predictive packet"),"Transport",parent,func() -> void: transport("predictive"))
		InstrumentTheme.primary(run_button)
		button(text2("同原文 RAW 对照","RAW comparison"),"Raw",parent,func() -> void: transport("raw"))
		button(text2("锁定条件 · 两种传输对照","Locked codec comparison"),"CompareTransport",parent,compare_transport)
		if session.data.get("mode","compress") != "compress": button(text2("接回有原文的传输","Reconnect original"),"ToCompress",parent,func() -> void: switch_mode("compress"))
		button(text2("接到未见输入 →","Connect sealed input →"),"ToPredict",parent,func() -> void: switch_mode("predict"))
	elif task < 6:
		button(text2("接到未见输入","Connect sealed input"),"ToPredict",parent,func() -> void: switch_mode("predict"))
		(find_child("ToPredict",true,false) as Button).disabled = session.data.get("mode","") == "predict"
		button(text2("练习","Practice"),"Practice",parent,func() -> void: begin_prediction("practice"))
		if task == 5: button(text2("训练片段对照","Training passage"),"TrainingPassage",parent,func() -> void: begin_prediction("training"))
		if task == 5: button(text2("固定位置背诵基线","Position-memory baseline"),"Memorize",parent,func() -> void: begin_prediction("memorize"))
		button(text2("冻结检查","Frozen check"),"Check",parent,func() -> void: begin_prediction("check"))
		commit_button = button(text2("先提交预测","Commit guess"),"Commit",parent,commit_prediction)
		InstrumentTheme.primary(commit_button)
		reveal_button = button(text2("再揭晓真值","Reveal truth"),"Reveal",parent,reveal_prediction)
		var continuation := HBoxContainer.new()
		parent.add_child(continuation)
		continue_prediction_button = button(text2("执行余段","Run remainder"),"ContinuePrediction",continuation,func() -> void: continue_prediction(false))
		mismatch_prediction_button = button(text2("到下一失配","Until mismatch"),"PredictionUntilMismatch",continuation,func() -> void: continue_prediction(true))
		var continuation_hint: String = text2("先亲手提交并揭晓一格；余段仍逐格先提交再揭晓，失配可停下追因。","Commit and reveal one cell yourself first. Continuation commits before every reveal; stop at a mismatch to trace its cause.")
		continue_prediction_button.tooltip_text = continuation_hint
		mismatch_prediction_button.tooltip_text = continuation_hint
	else:
		if task == 8:
			name_input.get_parent().remove_child(name_input)
			name_input.custom_minimum_size = Vector2(200,36)
			name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			parent.add_child(name_input)
		feedback_button = button(text2("断开真值 · 接上回灌","Disconnect truth · feedback"),"ToGenerate",parent,func() -> void: switch_mode("generate"))
		run_button = button(text2("按我的配方生成","Generate my recipe"),"Generate",parent,generate_work)
		InstrumentTheme.primary(run_button)
		if task == 7: button(text2("钉住 A", "Pin A"),"PinCreationAQuick",parent,pin_creation_a)
		var keep: Button = button(text2("保存这份作品","Keep this work"),"KeepCurrent",parent,keep_work)
		keep.disabled = not writable
		if task == 8: InstrumentTheme.primary(keep)

func toggle_language() -> void:
	var editor_state: Dictionary = _capture_editor_state()
	var previous_focus: int = focused_cell
	var previous_page: int = signal_view.page
	english = not english
	var localization := get_node_or_null("/root/Localization")
	if localization != null: localization.set_locale("en" if english else "zh_CN")
	build()
	_restore_editor_state(editor_state)
	if previous_focus >= 0 and previous_focus < signal_view.output_length():
		signal_view.page = previous_page
		inspect_cell(previous_focus,focused_lane)

func change_task(index: int) -> void:
	var editor_state: Dictionary = _capture_editor_state()
	# Valid recipe values rebuild from the authoritative draft. Only unsubmitted
	# text survives navigation; each task still chooses its intended initial tab.
	if valid_initial_input(): editor_state.inputs.erase("Initial")
	editor_state.tabs.clear()
	editor_state.erase("focus")
	evidence_expanded = false
	task = clampi(index,0,8)
	session.data.task = task
	session.dirty = true
	var navigation := get_node_or_null("/root/TaskNavigation")
	if navigation != null: navigation.remember_candidate_visit("creation",task)
	build()
	_restore_editor_state(editor_state)

func set_status(value: String) -> void:
	status_text = value
	if is_instance_valid(status): status.text = value

func failure_text(result: Dictionary) -> String:
	var code: String = str(result.get("error","unknown"))
	if code == "work_limit": return text2("作品库已满（12件）。本次生成仍保留在草稿中。", "The collection is full (12 works). This generation remains in the draft.")
	if code == "name": return text2("作品名称须包含1–80个字符。", "A work name must contain 1–80 characters.")
	var messages: Dictionary = {"restore_first":text2("请先用当前模型成功复原一次原文。","Restore a source successfully with the current model first."),"predict_first":text2("请先用当前模型完成一次提交／揭晓，再接上回灌。","Complete a commit/reveal stream with the current model before connecting feedback."),"mode":text2("请先主动连接本章的输入模式。","Connect this chapter's input mode explicitly."),"memory_limit":text2("这台机器内存不足；提高公开内存预算或减少样例/输出。","This machine lacks memory; increase its public budget or reduce examples/output."),"work_index":text2("先在作品列表选中一件作品。","Select a work from the collection first."),"generate_first":text2("配方已改变。请运行新的生成，再确认保存。","The recipe changed. Generate again before confirming a saved work."),"training_bounds":text2("选择1–16段合法样例，再学习。","Select 1–16 valid examples before learning.")}
	return str(messages.get(code,code))+(" ("+str(result.required_bytes)+" B)" if result.has("required_bytes") else "")

func edit_draft() -> void:
	session.mark_dirty()
	set_status(text2("草稿已改；已学模型和已保存作品保留。样例或记忆改变后需主动重新学习。","Draft changed; learned rules and saved works remain. Learn again explicitly after changing examples or history."))
	refresh()

func train_model() -> void:
	var previous_model: Dictionary = session.data.model.duplicate(true)
	var result: Dictionary = session.train()
	if not result.get("ok",false):
		set_status(text2("学习未完成：","Learning failed: ")+failure_text(result))
		return
	latest = result.duplicate(true)
	latest.kind = "training"
	latest.rule_changes = Explanation.rule_changes(previous_model,result.model)
	event_page = 0
	records.append({"kind":"training","model_id":Model.identity(result.model),"order":int(result.model.order),"source_id":str(result.model.source_digest),"cost":result.cost.duplicate(true)})
	set_status(text2("新模型来自所选样例。准备费用与计数更新均已记录。","New rules were learned from selected examples. Preparation cost and count updates are recorded."))
	refresh()
	refresh_tracks()
	var training_summary: String = Explanation.training(latest.rule_changes,english)
	if not observation_anchor.is_empty():
		var context: Array = observation_anchor.get("context",[])
		var before_counts: Array = observation_anchor.get("counts",[]).duplicate()
		var after_counts: Array = []
		for row: Dictionary in result.model.get("rows",[]):
			if row.context == context: after_counts = row.counts.duplicate()
		training_summary = text2("保留第 %d 格观察：上次上下文 [%s]，规则计数 %s → %s。空数组表示没有可核对计数；新运行会展示实际采用的上下文。", "Retained cell %d: previous context [%s], rule counts %s → %s. An empty array means no recorded counts. The next run shows the context actually used.")%[int(observation_anchor.cell)+1,Catalog.symbols(context),str(before_counts),str(after_counts)]+"\n"+training_summary
	causal_panel.show_evidence(training_summary,{"rule_changes":latest.rule_changes})
	causal_tabs.current_tab = causal_panel.get_index()

func transport(chosen_codec: String) -> void:
	var result: Dictionary = session.transport(Catalog.source(source_kind),chosen_codec)
	if not result.get("ok",false):
		latest = {}
		set_status(text2("发送未完成：","Transport failed: ")+failure_text(result))
		refresh()
		refresh_tracks()
		return
	codec = chosen_codec
	latest = result.duplicate(true)
	latest.kind = "transport"
	latest.source = Catalog.source(source_kind)
	latest.codec = chosen_codec
	event_page = 0
	records.append({"kind":"transport","codec":chosen_codec,"source_kind":source_kind,"source_id":JSON.stringify(latest.source).sha256_text(),"source_length":latest.source.size(),"model_id":str(result.get("model_id","")),"machine":session.data.draft.machine.duplicate(true),"cost":result.cost.duplicate(true),"metrics":result.metrics.duplicate(true)})
	if bool(result.get("lossless",false)):
		session.complete(Catalog.IDS[task] if task < 3 else "C1_restore",{"model_id":result.get("model_id",""),"codec":chosen_codec,"lossless":true,"cost":result.cost.duplicate(true),"metrics":result.metrics.duplicate(true)})
	set_status(text2("包已抵达，接收端独立复原。原文逐项一致：","Packet arrived; receiver restored independently. Exact equality: ")+str(result.get("lossless",false)))
	if task in [1,2] and not session.data.supports.has(Catalog.IDS[task]):
		set_status(status_text+" · "+(text2("同条件再运行另一codec，才形成字节对照。","Run the other codec under the same conditions for a byte comparison.") if task == 1 else text2("保持原文/模型/codec，改机器再运行，才形成成本对照。","Keep source/model/codec; change the machine and rerun for a cost comparison.")))
	refresh()
	refresh_tracks()

func switch_mode(mode: String) -> void:
	var result: Dictionary = session.set_mode(mode)
	if not result.get("ok",false):
		set_status(text2("连接尚未建立：","Connection not ready: ")+failure_text(result))
		return
	latest = {}
	set_status(text2("同一规则盒接到未揭晓输入；下一格必须先提交。","The same rule box is connected to sealed input; commit before revealing.") if mode == "predict" else text2("标准下一段已断开；自己的输出成为下一次输入。","The standard continuation is disconnected; your output becomes the next input."))
	change_task(3 if mode == "predict" else 6 if mode == "generate" else 0)

func begin_prediction(kind: String) -> void:
	var result: Dictionary = session.begin_prediction(kind)
	if not result.get("ok",false):
		set_status(text2("预测未开始：","Prediction did not start: ")+failure_text(result))
		return
	# A different prediction method/passage has a different evidence domain.
	# Same-source reruns retain their inspected cell; cross-domain runs do not.
	if observation_anchor.get("identity",{}).get("kind","") == "prediction" and str(observation_anchor.get("identity",{}).get("passage","")) != kind:
		observation_anchor.clear()
		focused_cell = -1
	latest = session.prediction_evidence()
	latest.kind = "prediction"
	prediction_recipe = {"model_id":session.prediction.model_id,"order":int(session.data.model.order),"kind":kind,"machine":session.data.draft.machine.duplicate(true)}
	var messages: Dictionary = {"check":text2("冻结检查已开始；此模型保持不变。","Frozen check started; this model remains fixed."),"practice":text2("练习开始。先提交预测，再揭晓。","Practice started. Commit a guess, then reveal."),"training":text2("这是已见训练片段回看，不能当未见表现。","This replays seen training data; it is not unseen performance."),"memorize":text2("背诵基线：只取首个训练样例的同位置，越界用A；同族检查从不同相位开始。","Position baseline reads the first training example at the same index (A beyond it); the check starts at a different phase.")}
	set_status(str(messages.get(kind,kind)))
	refresh()
	refresh_tracks()

func commit_prediction() -> void:
	var result: Dictionary = session.commit_prediction()
	if not result.get("ok",false):
		set_status(str(result.get("error","unknown")))
		return
	latest = session.prediction_evidence()
	latest.kind = "prediction"
	set_status(text2("预测已提交，真值尚未进入界面。现在可揭晓。","Prediction committed; truth has not entered the UI. Reveal when ready."))
	refresh()
	refresh_tracks(true)

func reveal_prediction() -> void:
	var result: Dictionary = session.reveal_prediction()
	if not result.get("ok",false):
		set_status(str(result.get("error","unknown")))
		return
	latest = session.prediction_evidence()
	latest.kind = "prediction"
	if session.prediction.get("finished",false):
		session.complete(Catalog.IDS[task],{"model_id":session.prediction.model_id,"kind":session.prediction.kind,"hits":session.prediction.hits,"total":session.prediction.total,"seen":session.prediction.seen})
		var measured: Dictionary = prediction_recipe.duplicate(true)
		measured.kind = "prediction"
		measured.check_kind = session.prediction.kind
		measured.hits = int(session.prediction.hits)
		measured.total = session.prediction.rows.size()
		measured.seen = bool(session.prediction.seen)
		measured.cost = result.cost.duplicate(true)
		records.append(measured)
	set_status(text2("真值已抵达；修正只在揭晓后标记。","Truth arrived; corrections appear only after reveal."))
	if task == 4 and session.prediction.get("finished",false) and not session.data.supports.has("P2_memory"):
		set_status(text2("这轮已完成。保持样例、机器和片段类型，改记忆后重新学习并预测，才构成记忆对照。","Run completed. Keep examples, machine and passage kind; learn another history length and predict again for a memory comparison."))
	refresh()
	refresh_tracks(true)

func can_continue_prediction() -> bool:
	return not session.prediction.is_empty() and not bool(session.prediction.get("finished",false)) and not session.prediction.get("rows",[]).is_empty() and session.prediction.get("pending",{}).is_empty()

func continue_prediction(stop_on_mismatch: bool = false) -> void:
	# This convenience action uses the same authoritative commit/reveal path.
	# No future input is read by the UI; a pending manual guess must be revealed first.
	if not can_continue_prediction(): return
	playing = false
	play_button.text = text2("播放","Play")
	var starting_rows: int = session.prediction.rows.size()
	while not session.prediction.get("finished",false):
		commit_prediction()
		if session.prediction.get("pending",{}).is_empty(): return
		reveal_prediction()
		if not session.prediction.get("pending",{}).is_empty(): return
		var row: Dictionary = session.prediction.rows[-1]
		if stop_on_mismatch and not bool(row.correct):
			inspect_cell(int(row.index),2)
			signal_view.cursor = int(row.index)
			signal_view.follow_cursor()
			set_status(text2("停在第 %d 格失配：预测与真值都已揭晓。点选因果，或继续余段。","Stopped at mismatch in cell %d: guess and truth are revealed. Trace its cause or continue.")%[int(row.index)+1])
			return
	if task != 4 or session.data.supports.has("P2_memory"):
		set_status(text2("余段完成：逐格提交／揭晓 %d 格。规则盒未训练；可进入回灌创造。","Remainder completed: %d cells committed/revealed. Rules were not retrained; continue to feedback creation.")%[session.prediction.rows.size()-starting_rows])

func generate_work() -> void:
	if not valid_initial_input():
		set_status(text2("请先修正起始片段（用空格分隔 A B C D）。","Correct the initial passage first (space-separated A B C D)."))
		return
	var result: Dictionary = session.generate()
	if not result.get("ok",false):
		set_status(text2("生成未完成：","Generation failed: ")+failure_text(result))
		return
	latest = result.duplicate(true)
	latest.kind = "generation"
	set_evidence_expanded(false)
	if not pinned_creation.is_empty():
		compared_creation = session.generated.duplicate(true)
		creation_report = CreationComparison.compare(pinned_creation,compared_creation)
	event_page = 0
	comparison.append(result.duplicate(true))
	if comparison.size() > 2: comparison.pop_front()
	session.complete("G1_feedback",{"model_id":result.get("model_id",""),"length":result.output.size(),"feedback":"generated","cost":result.cost.duplicate(true)})
	set_status(text2("这份输出来自你的学得模型和回灌。可以比较、命名，再选择留下。","This output came from your learned model and feedback. Compare, name, and choose what to keep."))
	if not pinned_creation.is_empty():
		set_status(text2("B 已生成，A 保持原样。实测页列出配方变化；创作配方页可定位首次分歧、保留 A/B 或继续改。", "B generated; A stays fixed. Measurements lists recipe changes; Creation recipe lets you locate the first difference, keep A/B or edit again."))
	refresh()
	refresh_tracks()

func selected_work() -> int:
	var indices: PackedInt32Array = works.get_selected_items()
	return int(indices[0]) if not indices.is_empty() else -1

func can_keep_visible_work() -> bool:
	if not valid_initial_input(): return false
	if task >= 3 and task < 6 and not session.prediction.is_empty(): return false
	return writable and latest.get("kind", "") == "generation" and not session.generated.is_empty() and latest.get("output", []) == session.generated.get("output", []) and latest.get("recipe", {}) == session.generated.get("recipe", {})

func refresh_keep_actions() -> void:
	for id: String in ["KeepWork", "KeepCurrent"]:
		var action := find_child(id,true,false) as Button
		if action != null:
			action.disabled = not can_keep_visible_work()
			action.tooltip_text = text2("仅保存当前可见的新生成结果；回看快照后请重新生成。", "Save the visible new generation only; generate again after viewing a snapshot.")

func keep_work() -> void:
	if not can_keep_visible_work():
		set_status(text2("当前显示的不是可保存的新生成结果。请先生成，再命名保存。", "The visible output is not a new generation to save. Generate first, then name and keep it."))
		return
	if name_input.text.strip_edges().is_empty():
		var tabs := find_child("EvidenceTabs",true,false) as TabContainer
		if tabs != null: tabs.current_tab = 3
		set_status(text2("在「作品与配方」页填写名称，再确认保存。","Enter a name in Works / recipes, then confirm."))
		name_input.grab_focus()
		return
	var result: Dictionary = session.save_work(name_input.text)
	if not result.get("ok",false):
		set_status(text2("作品未保存：","Work was not saved: ")+failure_text(result))
		return
	set_status(text2("已留下这件作品及完整配方。新的东西在这套系统中发生了。","This work and its full recipe are kept. Something new happened within this system."))
	kept_work = result.work.duplicate(true)
	refresh()
	works.select(session.data.works.size()-1)

func play_work() -> void:
	var result: Dictionary = session.play_work(selected_work())
	if not result.get("ok",false):
		set_status(str(result.get("error","select_work")))
		return
	latest = {"kind":"snapshot","output":result.output.duplicate(),"work":result.work.duplicate(true)}
	set_evidence_expanded(false)
	set_status(text2("直接播放保护快照，不调用当前模型。","Playing the protected snapshot directly; current rules are not executed."))
	event_page = 0
	refresh()
	refresh_tracks()

func replay_work() -> void:
	var result: Dictionary = session.replay_work(selected_work())
	set_status(text2("完整配方再生核对：","Full recipe replay: ")+(text2("与保护快照相同。","matches the protected snapshot.") if result.get("matches",false) else text2("未能核对；原快照保留。","could not verify; original snapshot stays intact.")+" "+str(result.get("error",""))))
	if result.get("ok",false):
		latest = result.duplicate(true)
		latest.kind = "replay"
		latest.work = session.data.works[selected_work()].duplicate(true)
		set_evidence_expanded(false)
		event_page = 0
		refresh()
		refresh_tracks()

func fork_work() -> void:
	var editor_state: Dictionary = _capture_editor_state()
	var invalid_initial: bool = not valid_initial_input()
	var result: Dictionary = session.fork_work(selected_work())
	if not result.get("ok",false):
		set_status(str(result.get("error","select_work")))
		return
	_clear_active_draft_presentation()
	set_status(text2("从已保存配方建立新草稿。旧作品继续保留。","A new draft starts from the saved recipe. The old work remains protected."))
	build()
	if not invalid_initial: editor_state.inputs.erase("Initial")
	_restore_editor_state(editor_state)

func save_draft() -> void:
	var saved: Error = session.save()
	set_status(text2("草稿与作品已保存。","Draft and works saved.") if saved == OK else text2("保存失败：","Save failed: ")+str(session.error))
	refresh()

func refresh() -> void:
	refresh_keep_actions()
	_refresh_creation_comparison()
	for handle: String in ["UndoDraft","RedoDraft"]:
		var action := find_child(handle,true,false) as Button
		if action != null: action.disabled = not writable or (not session.can_undo() if handle == "UndoDraft" else not session.can_redo())
	if not is_instance_valid(provenance): return
	var model: Dictionary = session.data.get("model",{})
	var model_id: String = "—" if model.is_empty() else Model.identity(model).substr(0,12)
	var mode: String = str(session.data.get("mode","compress"))
	var machine: Dictionary = session.data.draft.machine
	machine_strip.text = "%s · CPU %s %s · RAM %s B · %s %s %s · %s %s B/%s + %s %s"%[text2("当前机器","Current machine"),str(machine.cpu_ops_per_cycle),text2("运算/周期","ops/cycle"),str(machine.memory_bytes),text2("自动缓存","auto cache"),str(machine.cache_rows),text2("规则行","rule rows"),text2("通道","bus"),str(machine.bytes_per_cycle),text2("周期","cycle"),str(machine.request_cycles),text2("周期/请求","cycles/request")]
	measured_summary.text = live_measurement_text()
	saved_work_closure.visible = not kept_work.is_empty()
	(find_child("ContinueCreation",true,false) as Button).disabled = not writable
	saved_work_caption.text = text2("已留下：","Kept: ")+str(kept_work.get("name",""))
	var names: Dictionary = {"compress":text2("原文→包→恢复","source→packet→restore"),"predict":text2("已见→提交→真值","seen→commit→truth"),"generate":text2("输出→上下文","output→context")}
	provenance.text = "%s · %s · %s %s · %s"%[names.get(mode,mode),text2("当前草稿模型","current draft model"),model_id,text2("（冻结）","(frozen)"),text2("未保存草稿","unsaved draft") if session.dirty else text2("已保存","saved")]
	if not writable: provenance.text += " · "+text2("只读档","read-only profile")
	if latest.get("kind","") in ["snapshot","replay"]:
		var saved_id: String = str(latest.get("work",{}).get("recipe",{}).get("model_id","")).substr(0,12)
		provenance.text += " · "+text2("保护快照 ","protected snapshot ")+str(latest.get("work",{}).get("name",""))+(" ["+saved_id+"]" if saved_id != model_id else "")
	for i: int in Catalog.IDS.size():
		task_choice.set_item_text(i,("✓ " if session.data.supports.has(Catalog.IDS[i]) else "")+Catalog.title(i,english))
	if commit_button != null:
		commit_button.disabled = session.prediction.is_empty() or bool(session.prediction.get("finished",false)) or not session.prediction.get("pending",{}).is_empty()
		reveal_button.disabled = session.prediction.get("pending",{}).is_empty()
		continue_prediction_button.disabled = not can_continue_prediction()
		mismatch_prediction_button.disabled = not can_continue_prediction()
	if feedback_button != null: feedback_button.disabled = mode == "generate"
	if task >= 6: run_button.disabled = mode != "generate" or not valid_initial_input()
	var example_lines := PackedStringArray()
	var examples: Array = session.data.draft.examples
	example_lines.append(text2("实际所选 ","Actual selection: ")+str(examples.size())+text2(" 段（展开样例不会改变它们）"," passages"))
	selected_examples.text = "\n".join(example_lines)
	for child: Node in examples_list.get_children():
		examples_list.remove_child(child)
		child.queue_free()
	for i: int in examples.size():
		var row := HBoxContainer.new()
		examples_list.add_child(row)
		var passage: Label = label(str(i+1)+": "+Catalog.symbols(examples[i]),row,11)
		passage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button("×","RemoveExample"+str(i),row,func() -> void:
			session.data.draft.examples.remove_at(i)
			session.mark_dirty()
			rebuild_editor_preserving_inputs())
	rules.clear()
	var root: TreeItem = rules.create_item()
	var displayed_rules: Dictionary = latest.get("recipe",latest.get("work",{}).get("recipe",{})).get("model",model)
	for row: Dictionary in displayed_rules.get("rows",[]):
		var item: TreeItem = rules.create_item(root)
		item.set_text(0,Catalog.symbols(row.context) if not row.context.is_empty() else text2("全局回退","global fallback"))
		for i: int in 4: item.set_text(i+1,str(row.counts[i]))
		item.set_metadata(0,row.duplicate(true))
	events.clear()
	root = events.create_item()
	var recorded: Array = [] if latest.get("kind","") == "snapshot" else latest.get("events",session.data.get("training",{}).get("events",[]))
	event_page = clampi(event_page,0,maxi(0,ceili(float(recorded.size())/200)-1))
	var first: int = event_page*200
	event_caption.text = "%s %d–%d / %d"%[text2("实际事件","actual events"),mini(first+1,recorded.size()),mini(first+200,recorded.size()),recorded.size()]
	for event: Dictionary in recorded.slice(first,mini(first+200,recorded.size())):
		var item: TreeItem = events.create_item(root)
		item.set_text(0,str(event.get("phase",""))+" · "+str(event.get("kind","")))
		item.set_text(1,str(event.get("ops",0)))
		item.set_text(2,str(event.get("bytes",0)))
		item.set_text(3,str(event.get("cycles",0)))
		item.set_metadata(0,event.duplicate(true))
	var selection: int = selected_work()
	works.clear()
	for work: Dictionary in session.data.get("works",[]):
		works.add_item(str(work.get("name",""))+" · "+str(work.get("recipe",{}).get("model_id","")).substr(0,10))
	if selection >= 0 and selection < works.item_count: works.select(selection)
	elif task == 8 and works.item_count > 0: works.select(works.item_count-1)
	costs.text = measurement_text()
	refresh_cost_comparison()
	if is_instance_valid(status): status.text = status_text

func measurement_text() -> String:
	var lines := PackedStringArray()
	var saved_work: Dictionary = latest.get("work",{})
	var training: Dictionary = saved_work.get("training",{}).get("cost",{}) if not saved_work.is_empty() else session.data.get("training",{}).get("cost",{})
	if not training.is_empty(): lines.append(text2("已记录准备（不每次重收）：","Recorded preparation (not charged again): ")+cost_text(training))
	var model: Dictionary = latest.get("recipe",saved_work.get("recipe",{})).get("model",session.data.get("model",{}))
	if latest.get("kind","") == "snapshot":
		lines.append(text2("已保存快照没有逐步事件或本次运行成本；可用「配方再生核对」重新测量。", "Saved snapshots have no step trace or current run cost; use Replay recipe to measure them."))
	if not model.is_empty(): lines.append(text2("规则盒规范字节：","Canonical rule bytes: ")+str(Model.canonical_bytes(model).size())+" B")
	if latest.get("kind","") == "prediction":
		var observed: Dictionary = session.prediction
		lines.append("%s · %s · %d / %d"%[str(observed.get("kind","")),text2("已揭晓命中/总数","revealed hits/total"),int(observed.get("hits",0)),observed.get("rows",[]).size()])
		if not observed.get("rows",[]).is_empty(): lines.append(cost_text(observed.rows[-1].cost))
		lines.append(text2("本轮开始前，检查答案已见：","Check answers seen before this run: ")+str(observed.get("seen",false)))
		lines.append(text2("这只统计已揭晓部分，下一格还未知。","Only revealed observations are counted; the next cell is unknown."))
	elif latest.has("cost"):
		lines.append(text2("当前运行：","Current run: ")+cost_text(latest.cost))
		var metrics: Dictionary = latest.get("metrics",{})
		if not metrics.is_empty():
			lines.append("%s %s B = %s %s + %s %s + %s %s + %s %s"%[text2("真实包","Packet"),str(metrics.packet_bytes),text2("头部","header"),str(metrics.header_bytes),text2("模型","model"),str(metrics.model_bytes),text2("负载","payload"),str(metrics.payload_bytes),text2("校验","checksum"),str(metrics.checksum_bytes)])
			lines.append("%s %s · %s %s bit · %s %s bit"%[text2("真正修正","Corrections"),str(metrics.mismatches),text2("负载","payload"),str(metrics.payload_bits),text2("填充","padding"),str(metrics.padding_bits)])
		var phases: Dictionary = {}
		for event: Dictionary in latest.get("events",[]):
			var phase: String = str(event.get("phase",""))
			phases[phase] = int(phases.get(phase,0))+int(event.get("cycles",0))
		var phase_names: Dictionary = {"prepare":text2("准备","prepare"),"encode":text2("编码","encode"),"transfer":text2("搬运","transfer"),"decode":text2("解码","decode"),"generate":text2("生成","generate"),"output":text2("输出","output")}
		var phase_parts := PackedStringArray()
		for phase: String in phases: phase_parts.append(str(phase_names.get(phase,phase))+": "+str(phases[phase]))
		lines.append(text2("顺序阶段周期：","Sequential phase cycles: ")+" / ".join(phase_parts))
	if not records.is_empty():
		lines.append(text2("独立实测对照（条件冻结）：","Measured comparisons (frozen conditions):"))
		for record: Dictionary in records.slice(maxi(0,records.size()-4)):
			if record.kind == "transport":
				lines.append("%s · N=%d · %s · CPU %s / bus %s / cache %s / req %s · %s"%[record.codec,record.source_length,str(record.source_id).substr(0,8),str(record.machine.cpu_ops_per_cycle),str(record.machine.bytes_per_cycle),str(record.machine.cache_rows),str(record.machine.request_cycles),cost_text(record.cost)])
			elif record.kind == "prediction":
				lines.append("%s · %s %s · %s · %d / %d · %s %s · %s"%[record.check_kind,text2("记忆","history"),str(record.order),str(record.model_id).substr(0,8),record.hits,record.total,text2("已见检查","seen check"),str(record.seen),cost_text(record.cost)])
			else:
				lines.append(text2("学习","learning")+" · "+str(record.model_id).substr(0,8)+" · "+text2("记忆 ","history ")+str(record.order)+" · "+cost_text(record.cost))
	if not pinned_creation.is_empty():
		lines.append(text2("钉住 A / 最近生成的 B 对照：","Pinned A / latest generated B comparison:")+"\n"+CreationComparison.caption(creation_report,english))
	if comparison.size() == 2:
		lines.append(text2("两份生成实测：","Two measured drafts: ")+(text2("输出不同","outputs differ") if comparison[0].output != comparison[1].output else text2("输出相同；变化不保证新结果。","outputs match; a change does not guarantee new output.")))
		for i: int in 2:
			var recipe: Dictionary = comparison[i].recipe
			lines.append("%d · %s · %s %s · %s %s · %s"%[i+1,str(recipe.model_id).substr(0,12),text2("记忆","history"),str(recipe.model.order),text2("种子","seed"),str(recipe.seed),str(recipe.sampler)])
	lines.append(text2("周期来自顺序事件；包字节与含规则行读写的总搬运字节分列。重复与高熵均不判作品美感。","Cycles come from sequential events; packet size is distinct from total traffic including rule accesses. Neither repetition nor high entropy judges beauty."))
	return "\n".join(lines)

func live_measurement_text() -> String:
	# The same detached result owns the operation/traffic totals shown in detail.
	# Draft controls and presentation time never reconstruct measurement values.
	var kind: String = str(latest.get("kind",""))
	if kind == "snapshot":
		return text2("保护快照 · %d 格 · 无本次运算／搬运实测", "Saved snapshot · %d cells · no current ops / traffic measurement")%latest.get("output",[]).size()
	var cost: Dictionary = latest.get("cost",{})
	if cost.is_empty(): return text2("尚无本次实测 · 运行后查看搬运、运算与结果。", "No current measurement · run to see traffic, operations and result.")
	var result: String = ""
	var origin: String = text2("实测", "Measured")
	if kind == "transport":
		result = text2("无损一致", "exact restoration") if latest.get("lossless",false) else text2("恢复不一致", "restoration differs")
	elif kind == "prediction":
		var observed: Dictionary = session.prediction
		result = text2("已揭晓 %d · 命中 %d", "revealed %d · hits %d")%[observed.get("rows",[]).size(),int(observed.get("hits",0))]
		if not observed.get("pending",{}).is_empty(): result += text2(" · 下一格已提交，未揭晓", " · next committed, sealed")
	elif kind == "training":
		origin = text2("学习实测", "Learning measurement")
		result = text2("%d 行规则", "%d rule rows")%latest.get("model",{}).get("rows",[]).size()
	elif kind == "replay":
		origin = text2("本次配方再生实测", "Current recipe replay")
		result = text2("与快照一致", "matches snapshot") if latest.get("matches",false) else text2("与快照不同", "differs from snapshot")
	elif kind == "generation": result = text2("生成 %d 格 · 无标准答案", "generated %d cells · no target")%latest.get("output",[]).size()
	return "%s · %s ops · %s B · %s %s · %s"%[origin,str(cost.get("cpu_ops",0)),str(cost.get("transfer_bytes",0)),str(cost.get("total_cycles",0)),text2("周期", "cycles"),result]

func cost_text(cost: Dictionary) -> String:
	return "%s %s · %s ops · %s B · %s %s B"%[str(cost.get("total_cycles",0)),text2("周期","cycles"),str(cost.get("cpu_ops",0)),str(cost.get("transfer_bytes",0)),text2("峰值","peak"),str(cost.get("peak_bytes",0))]

func refresh_tracks(preserve_focus: bool = false) -> void:
	if not is_instance_valid(signal_view): return
	var previous_page: int = signal_view.page
	refresh_keep_actions()
	_refresh_creation_comparison()
	var kind: String = str(latest.get("kind",""))
	# Learning has no new output cells. Keep the detached observation anchor until
	# a new visible run can revisit it; never predict a future cell to fill it in.
	if kind == "training" and not observation_anchor.is_empty():
		focused_cell = -1
		signal_view.set_tracks([[],[],[]],[text2("重新学习 · 尚未产生新输出", "Relearned · no new output yet"),"",""])
		inspector.text = text2("观察位置 %d 已保留，运行同一输入后继续追因。", "Observation at cell %d is retained. Run the same input to revisit its cause.")%[int(observation_anchor.cell)+1]
		return
	var tracks: Array = [[],[],[]]
	var captions: Array = ["","",""]
	var marks: Array = []
	if kind == "prediction" or (task >= 3 and task < 6 and not session.prediction.is_empty()):
		var prefix: Array = session.prediction.get("prefix",[]).duplicate()
		var guesses: Array = []
		for row: Dictionary in session.prediction.get("rows",[]):
			while guesses.size() < int(row.index): guesses.append(-1)
			guesses.append(int(row.predicted))
			if not row.correct: marks.append(int(row.index))
		var pending: Dictionary = session.prediction.get("pending",{})
		if not pending.is_empty():
			while guesses.size() < prefix.size(): guesses.append(-1)
			guesses.append(int(pending.symbol))
		tracks = [prefix,guesses,prefix]
		captions = [text2("已揭晓真值 · 下一格仍封住","Revealed truth · next cell remains sealed"),text2("已提交预测 · ? 是起始上下文","Committed predictions · ? marks initial context"),text2("揭晓后修正 · 下划线是失配","Corrections after reveal · underline = mismatch")]
	elif kind in ["generation","snapshot","replay"]:
		var output: Array = latest.get("output",[])
		var initial: Array = latest.get("recipe",latest.get("work",{}).get("recipe",{})).get("initial",[])
		tracks = [comparison[0].get("output",[]) if comparison.size() == 2 and kind == "generation" else [],initial.duplicate(),output]
		captions = [text2("前一份实测草稿（若有）","Previous measured draft (if any)"),text2("起始片段 · 不存在标准下一段","Initial passage · no standard continuation"),text2("你的实际光纹 · 可以留下","Your actual signal · yours to keep")]
		if kind == "generation" and not pinned_creation.is_empty():
			tracks = [pinned_creation.output,initial.duplicate(),output]
			captions = [text2("A · 已钉住的实际输出","A · pinned actual output"),text2("起始片段 · 无标准答案","Initial passage · no target answer"),text2("当前输出 · 下划线仅标记与 A 不同","Current output · underline = differs from A")]
			marks = CreationComparison.compare(pinned_creation,latest).get("mismatches",[])
	elif kind == "transport":
		var predicted: Array = []
		for event: Dictionary in latest.get("events",[]):
			if event.get("phase","") == "encode" and event.has("predicted"):
				var index: int = int(event.get("index",predicted.size()))
				while predicted.size() < index: predicted.append(-1)
				predicted.append(int(event.predicted))
				if event.has("correction") or event.get("match",true) == false: marks.append(index)
		tracks = [latest.source,predicted,latest.output]
		captions = [text2("发送端原文 · 可见材料","Sender original · public material"),text2("编码时的规则猜测","Rule guesses during encoding"),text2("接收端只凭包恢复","Receiver restored from packet only")]
	elif task < 3:
		tracks[0] = Catalog.source(source_kind)
		captions = [text2("发送端原文 · 尚未发送","Sender original · not sent yet"),text2("规则猜测 · 等待运行","Rule guesses · awaiting run"),text2("接收端 · 等待合法包","Receiver · awaiting a valid packet")]
	elif str(session.data.mode) == "generate":
		captions = [text2("当前配方尚无新输出","No new output from this recipe"),text2("起始片段 · 等待生成","Initial passage · awaiting generation"),text2("点击「按我的配方生成」重新运行","Run again with Generate my recipe")]
	elif str(session.data.mode) == "predict":
		captions = [text2("尚未开启本轮预测","No prediction round has started"),text2("同一规则盒已接到未见输入","Same rules connected to unseen input"),text2("选择练习或冻结检查，然后先提交再揭晓","Choose practice or a frozen check, then commit before reveal")]
	else:
		captions = [text2("还没有已发生输出","No output has occurred"),text2("同一模型等待连接","Same model awaits connection"),text2("按模式按钮建立实际路径","Connect the actual path with the mode button")]
	signal_view.set_tracks(tracks,captions,marks)
	if restore_observation():
		return
	if preserve_focus and focused_cell >= 0 and focused_cell < signal_view.output_length():
		signal_view.page = previous_page
		inspect_cell(focused_cell,focused_lane)
	else:
		focused_cell = -1
		inspector.text = text2("点选一格查看真实来源。A ● / B ■ / C ▲ / D ◇","Select a cell to trace its source. A ● / B ■ / C ▲ / D ◇")
		if is_instance_valid(causal_panel): causal_panel.clear_evidence()

func displayed_generation(lane: int) -> Dictionary:
	if latest.get("kind","") == "generation" and lane == 0:
		if not pinned_creation.is_empty(): return pinned_creation
		if comparison.size() == 2: return comparison[0]
	return latest

func observation_identity(lane: int = 2) -> Dictionary:
	var kind: String = str(latest.get("kind",""))
	if kind == "transport": return {"kind":kind,"source":latest.get("source",[]).duplicate()}
	if kind == "prediction":
		var passage: String = str(session.prediction.get("kind",""))
		var identity: Dictionary = {"kind":kind,"passage":passage}
		# Training replay is public source material and can change with the examples.
		# Practice/check identities use only their public kind, never sealed symbols.
		if passage == "training": identity.source = latest.get("recipe",{}).get("model",{}).get("examples",[]).slice(0,1).duplicate(true)
		return identity
	if kind == "generation":
		var visible: Dictionary = displayed_generation(lane)
		var identity: Dictionary = {"kind":kind,"initial":visible.get("recipe",{}).get("initial",[]).duplicate()}
		if lane == 0: identity.reference = JSON.stringify([visible.get("recipe",{}),visible.get("output",[])]).sha256_text()
		return identity
	return {}

func restore_observation() -> bool:
	if observation_anchor.is_empty(): return false
	var identity: Dictionary = observation_identity(int(observation_anchor.lane))
	if identity.is_empty() or identity.get("kind","") != observation_anchor.identity.get("kind",""): return false
	var lane: int = clampi(int(observation_anchor.lane),0,2)
	var visible: int = signal_view.lanes[lane].size()
	if visible == 0: return false
	var equivalent: bool = identity == observation_anchor.identity
	var wanted: int = int(observation_anchor.cell)
	var index: int = mini(wanted,visible-1)
	playing = false
	if is_instance_valid(play_button): play_button.text = text2("播放", "Play")
	restoring_observation = true
	inspect_cell(index,lane)
	restoring_observation = false
	# Clamp the page to the currently revealed cells, even while a later focus is
	# waiting for a new prediction stream to reveal the same position.
	signal_view.page = int(observation_anchor.page)
	signal_view.turn_page(0)
	if not equivalent:
		var notice: String = text2("输入已改变：此格是最近可见位置，不是同输入因果对照。", "Input changed: this is the nearest visible cell, not a same-input causal comparison.")
		inspector.text += " · "+notice
		causal_panel.summary_label.text += "\n"+notice
		observation_anchor = {"cell":index,"lane":lane,"page":signal_view.page,"identity":identity.duplicate(true),"context":inspected_context.duplicate(),"counts":inspected_counts.duplicate()}
	elif index != wanted:
		inspector.text += text2(" · 第 %d 格尚未揭晓；揭晓后恢复原焦点。", " · Cell %d is still sealed; focus returns after reveal.")%[wanted+1]
	return true

func show_cause(index: int, summary: String, record: Dictionary, counts: Array = [], context: Array = []) -> void:
	focused_cell = index
	inspected_context = context.duplicate(); inspected_counts = counts.duplicate()
	if not observation_anchor.is_empty() and (not restoring_observation or index == int(observation_anchor.cell)):
		observation_anchor.context = context.duplicate(); observation_anchor.counts = counts.duplicate()
	signal_view.selected = index
	signal_view.selected_lane = focused_lane
	signal_view.context_count = context.size()
	signal_view.context_lane = 0 if latest.get("kind","") == "prediction" else focused_lane
	if latest.get("kind","") == "transport": signal_view.context_lane = 2 if focused_lane == 2 else 0
	signal_view.queue_redraw()
	inspector.text = focused_source+" · "+Explanation.selection(index,record,context,english)
	causal_panel.show_evidence(text2("第 %d 格 · ","Cell %d · ")%[index+1]+focused_source+"\n"+summary,record,counts)
	causal_tabs.current_tab = causal_panel.get_index()

func inspect_cell(index: int, lane: int = 2) -> void:
	if not restoring_observation:
		var identity: Dictionary = observation_identity(lane)
		if not identity.is_empty(): observation_anchor = {"cell":index,"lane":lane,"page":signal_view.page,"identity":identity.duplicate(true)}
	focused_lane = lane
	focused_source = text2("当前输出", "Current output")
	var visible: Dictionary = latest
	if latest.get("kind","") == "generation" and lane == 0:
		if not pinned_creation.is_empty():
			visible = pinned_creation
			focused_source = "A"
		elif comparison.size() == 2:
			visible = comparison[0]
			focused_source = text2("前一份草稿", "Previous draft")
	elif latest.get("kind","") == "transport":
		focused_source = text2("接收端解码", "Receiver decode") if lane == 2 else text2("发送端编码", "Sender encode")
	if latest.get("kind","") == "prediction":
		var memorize: bool = session.prediction.get("kind","") == "memorize"
		for row: Dictionary in session.prediction.get("rows",[]):
			if int(row.index) == index:
				show_cause(index,Explanation.prediction(row,session.prediction.prefix.slice(0,index),memorize,english),row,[] if memorize else row.counts,row.context)
				return
		var pending: Dictionary = session.prediction.get("pending",{})
		if index == session.prediction.get("prefix",[]).size() and not pending.is_empty():
			show_cause(index,Explanation.prediction(pending,session.prediction.prefix,memorize,english),pending,[] if memorize else pending.counts,pending.context)
			return
	var selected_decision: Dictionary = {}
	for event: Dictionary in visible.get("events",[]):
		if latest.get("kind","") == "transport" and event.get("phase","") != ("decode" if lane == 2 else "encode"): continue
		if event.get("kind","") == "successor_select" and event.get("index",-1) == index: selected_decision = event
		if int(event.get("index",-1)) == index and event.get("kind","") in ["residual_write","residual_read","feedback_write","seed_write","literal_write","literal_read"]:
			var counts: Array = event.get("counts",selected_decision.get("counts",[]))
			var prefix: Array = visible.get("output",[]).slice(0,index)
			show_cause(index,Explanation.cell(event,[selected_decision],prefix,english),event,counts,event.get("before_context",event.get("context",[])))
			return
	show_cause(index,text2("此格来自当前可见快照；没有可核对的逐步规则记录。","This cell is from the visible snapshot; no step-by-step rule record is available."),{})

func inspect_rule() -> void:
	var row: TreeItem = rules.get_selected()
	if row == null: return
	observation_anchor.clear()
	var record: Dictionary = row.get_metadata(0)
	focused_cell = -1
	signal_view.selected = -1
	signal_view.context_count = 0
	signal_view.queue_redraw()
	inspector.text = text2("已选冻结规则 · 不会因草稿编辑而改变","Selected frozen rule · draft edits do not change it")
	causal_panel.show_evidence(Explanation.rule_text(record,english)+"\n"+text2("这些计数来自所显示结果的冻结模型（尚无结果时为当前已学模型）。更改草稿不会重写这些记录。","These counts belong to the displayed result’s frozen model, or the learned draft when no result is shown. Draft edits never rewrite this evidence."),record,record.counts)
	causal_tabs.current_tab = causal_panel.get_index()

func inspect_event() -> void:
	var row: TreeItem = events.get_selected()
	if row == null: return
	observation_anchor.clear()
	var record: Dictionary = row.get_metadata(0)
	focused_cell = -1
	signal_view.selected = -1
	signal_view.context_count = 0
	signal_view.queue_redraw()
	inspector.text = text2("已选事件 · 依据见因果详情","Selected event · see Cause details")
	causal_panel.show_evidence(str(record.get("phase",""))+" · "+str(record.get("kind",""))+" · "+str(record.get("ops",0))+" ops / "+str(record.get("bytes",0))+" B / "+str(record.get("cycles",0))+text2(" 周期"," cycles"),record,record.get("counts",[]))
	causal_tabs.current_tab = causal_panel.get_index()

func browse_page(direction: int) -> void:
	# Browsing pauses the presentation so automatic following cannot fight the user.
	playing = false
	play_button.text = text2("播放","Play")
	signal_view.turn_page(direction)

func toggle_playback() -> void:
	playing = not playing
	if playing:
		if signal_view.cursor < 0: signal_view.cursor = 0
		signal_view.follow_cursor()
	play_button.text = text2("暂停","Pause") if playing else text2("播放","Play")

func step_playback() -> void:
	playing = false
	play_button.text = text2("播放","Play")
	signal_view.cursor = mini(signal_view.output_length()-1,signal_view.cursor+1)
	signal_view.follow_cursor()

func _process(delta: float) -> void:
	if is_instance_valid(work_focus) and work_focus.visible: return
	if not playing or not is_instance_valid(signal_view): return
	playback_elapsed += delta
	if playback_elapsed >= 0.22:
		playback_elapsed = 0
		signal_view.cursor += 1
		if signal_view.cursor >= signal_view.output_length():
			signal_view.cursor = -1
			playing = false
			play_button.text = text2("播放","Play")
		signal_view.follow_cursor()

func _build_leave_dialog() -> void:
	leave_dialog = ConfirmationDialog.new()
	leave_dialog.name = "LeaveProtection"
	leave_dialog.title = text2("草稿尚未保存","Unsaved draft")
	leave_dialog.dialog_text = text2("保存当前草稿与作品后离开，或明确放弃未保存修改。已保存作品继续受保护。","Save drafts and works before leaving, or explicitly discard unsaved edits. Saved works remain protected.")
	leave_dialog.ok_button_text = text2("保存后离开","Save and leave")
	leave_dialog.cancel_button_text = text2("继续编辑","Keep editing")
	leave_dialog.add_button(text2("放弃草稿修改后离开","Discard edits and leave"),true,"discard")
	leave_dialog.confirmed.connect(func() -> void:
		if session.save() == OK: finish_leave()
		else: set_status(text2("保存失败，继续保留当前草稿：","Save failed; draft remains open: ")+session.error))
	leave_dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard": finish_leave())
	add_child(leave_dialog)

func request_leave(to_hub: bool) -> void:
	leaving_to_hub = to_hub
	if session.dirty: leave_dialog.popup_centered(Vector2i(560,230))
	else: finish_leave()

func finish_leave() -> void:
	if leaving_to_hub:
		var navigation := get_node_or_null("/root/TaskNavigation")
		if navigation != null and navigation.return_to_tree(): return
		get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn")
	else: get_tree().quit()

func _build_writer_controls(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.name = "WriterControls"
	parent.add_child(row)
	button(text2("重试保存权限","Retry writer"),"RetryWriter",row,func() -> void: retry_writer())
	button(text2("重载已存档","Reload saved"),"ReloadSaved",row,func() -> void: confirm_writer(true))
	var stopped: String = Session.Lease.stopped_owner(session.path)
	if not stopped.is_empty():
		button(text2("恢复已停止窗口的权限","Recover stopped writer"),"RecoverWriter",row,func() -> void: confirm_writer(false,stopped))
	if not recovery_choices.is_empty():
		button(text2("选择恢复副本","Choose recovery copy"),"RecoverProfile",row,func() -> void: recovery_dialog.popup_centered(Vector2i(620,280)))
	label(text2("只读探索可保留；重载需确认。","Read-only exploration is retained; reload requires confirmation."),row,12).size_flags_horizontal = Control.SIZE_EXPAND_FILL

func confirm_writer(reload_saved: bool, stopped: String = "") -> void:
	writer_dialog = ConfirmationDialog.new()
	writer_dialog.name = "WriterProtection"
	writer_dialog.title = text2("确认重载存档" if reload_saved else "确认恢复写入权限", "Confirm saved reload" if reload_saved else "Confirm writer recovery")
	writer_dialog.dialog_text = text2("重载会替换本窗口未保存的草稿、结果和对照；受保护作品从存档重新读取。", "Reload replaces this window's unsaved draft, results and comparisons. Protected works are reread from the saved profile.") if reload_saved else text2("仅恢复已经确认停止的窗口权限，保留当前探索；已变动的存档仍需另行确认重载。", "Recover only the exact owner confirmed stopped, retaining this exploration. A changed saved profile still needs a separate confirmed reload.")
	writer_dialog.ok_button_text = text2("确认重载" if reload_saved else "恢复权限", "Reload saved" if reload_saved else "Recover writer")
	writer_dialog.cancel_button_text = text2("保留当前探索", "Keep current exploration")
	writer_dialog.confirmed.connect(func() -> void: retry_writer(reload_saved,stopped))
	writer_dialog.canceled.connect(writer_dialog.queue_free)
	add_child(writer_dialog)
	writer_dialog.popup_centered(Vector2i(620,240))

func retry_writer(reload_saved: bool = false, stopped: String = "") -> void:
	var editor_state: Dictionary = _capture_editor_state()
	# Re-query the owner when explicit reload is confirmed: normal retry itself
	# never reclaims another window and never replaces this live draft.
	if reload_saved and stopped.is_empty(): stopped = Session.Lease.stopped_owner(session.path)
	var result: Dictionary = session.retry_writer(reload_saved) if stopped.is_empty() else session.recover_writer(stopped,reload_saved)
	writable = bool(result.get("writable",false))
	var reason: String = str(result.get("reason",""))
	if reason == "recovery":
		recovery_choices = result.get("choices",[]).duplicate(true)
		recovery_fingerprint = str(result.get("fingerprint",""))
		status_text = text2("写入权限已取得；事务未完成，请明确选择校验副本后再保存。", "Writer acquired; installation is interrupted. Choose a validated recovery copy before saving.")
	elif writable:
		recovery_choices.clear(); recovery_fingerprint = ""
		if reload_saved: _clear_replaced_exploration()
		status_text = text2("已重载存档；原探索已按确认替换。", "Saved profile reloaded; the previous exploration was replaced as confirmed.") if reload_saved else text2("已取得写入权限，当前草稿与探索结果保留。", "Writer acquired; this draft and exploration results are retained.")
	else:
		var messages: Dictionary = {
			"busy":text2("另一窗口仍持有权限，或无法确认已停止。请关闭该窗口后重试；当前探索保留。", "Another window owns this profile, or its stopped state cannot be confirmed. Close that window and retry; this exploration is retained."),
			"changed":text2("存档已改变；当前探索保留。若要采用新存档，请点「重载已存档」并确认。", "The saved profile changed; this exploration is retained. Choose Reload saved and confirm to adopt it."),
			"unreadable":text2("存档版本或内容无法安全写入；原字节保留。若有校验副本，请选择恢复副本。", "The saved version or contents cannot be safely written; original bytes remain. Choose a validated recovery copy if available.")}
		status_text = str(messages.get(reason,reason))
	build()
	if not reload_saved or not writable: _restore_editor_state(editor_state)

func _capture_editor_state() -> Dictionary:
	var saved: Dictionary = {"inputs":{},"tabs":{},"work":works.get_selected_items(),"page":signal_view.page}
	for handle: String in ["WorkName","CustomExample","Initial"]:
		var input := find_child(handle,true,false) as LineEdit
		if input != null: saved.inputs[handle] = input.text
	for handle: String in ["DraftTabs","EvidenceTabs"]:
		var tabs := find_child(handle,true,false) as TabContainer
		if tabs != null: saved.tabs[handle] = tabs.current_tab
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus != null: saved.focus = str(focus.name)
	return saved

func rebuild_editor_preserving_inputs() -> void:
	var editor_state: Dictionary = _capture_editor_state()
	build()
	_restore_editor_state(editor_state)

func restore_draft_history(redo: bool) -> void:
	if not writable: return
	var editor_state: Dictionary = _capture_editor_state()
	var invalid_initial: bool = not valid_initial_input()
	var result: Dictionary = session.redo_draft() if redo else session.undo_draft()
	if not result.get("ok",false):
		set_status(text2("无法恢复草稿：","Draft cannot be restored: ")+str(result.get("error","")))
		refresh()
		return
	if not invalid_initial: editor_state.inputs.erase("Initial")
	_clear_active_draft_presentation()
	build()
	_restore_editor_state(editor_state)
	set_status(text2("已重做草稿；旧作品和实测保留，请重新运行。" if redo else "已撤销草稿；旧作品和实测保留，请重新运行。", "Draft redone; saved works and measurements remain. Run again." if redo else "Draft undone; saved works and measurements remain. Run again.")+(text2(" 起始栏仍有未提交文本。", " Initial still contains unsubmitted text.") if invalid_initial else ""))

func _clear_active_draft_presentation() -> void:
	suppress_snapshot_fallback = true
	latest.clear(); kept_work.clear(); comparison.clear()
	pinned_creation.clear(); compared_creation.clear(); creation_report.clear()
	prediction_recipe.clear(); observation_anchor.clear()
	inspected_context.clear(); inspected_counts.clear()
	focused_cell = -1; focused_source = ""; focused_lane = 2; event_page = 0

func _restore_editor_state(saved: Dictionary) -> void:
	for handle: String in saved.get("inputs",{}):
		var input := find_child(handle,true,false) as LineEdit
		if input != null: input.text = str(saved.inputs[handle])
	for handle: String in saved.get("tabs",{}):
		var tabs := find_child(handle,true,false) as TabContainer
		if tabs != null: tabs.current_tab = clampi(int(saved.tabs[handle]),0,tabs.get_tab_count()-1)
	for index: int in saved.get("work",[]):
		if index < works.item_count: works.select(index)
	signal_view.page = int(saved.get("page",0)); signal_view.turn_page(0)
	refresh()
	var handle: String = str(saved.get("focus",""))
	if not handle.is_empty():
		var focus := find_child(handle,true,false) as Control
		if focus != null: focus.grab_focus()

func _clear_replaced_exploration() -> void:
	suppress_snapshot_fallback = false
	latest.clear(); records.clear(); comparison.clear()
	kept_work.clear()
	pinned_creation.clear(); compared_creation.clear(); creation_report.clear()
	transport_comparisons.clear(); selected_cost_comparison = -1
	prediction_recipe.clear(); observation_anchor.clear()
	focused_cell = -1; focused_source = ""; focused_lane = 2
	event_page = 0; task = clampi(int(session.data.task),0,8)
	var navigation := get_node_or_null("/root/TaskNavigation")
	if navigation != null: navigation.remember_candidate_visit("creation",task)

func _build_recovery_dialog() -> void:
	if recovery_choices.is_empty(): return
	recovery_dialog = ConfirmationDialog.new()
	recovery_dialog.name = "RecoveryProtection"
	recovery_dialog.title = text2("确认恢复候选档","Confirm candidate recovery")
	recovery_dialog.ok_button_text = text2("恢复所选副本","Restore selected copy")
	recovery_dialog.cancel_button_text = text2("继续只读","Remain read-only")
	var column := VBoxContainer.new()
	recovery_dialog.add_child(column)
	label(text2("仅恢复下列已经校验的副本。原文件字节继续保全；当前临时草稿将被所选副本替换，不会自动回退未知版本。","Restore only a validated copy below. Original bytes stay preserved; the selected copy replaces this temporary draft. Unknown versions never fall back automatically."),column,14)
	var choice := OptionButton.new()
	choice.name = "RecoveryChoice"
	for candidate: Dictionary in recovery_choices:
		choice.add_item(str(candidate.path).get_file()+" · "+Catalog.title(int(candidate.get("task",0)),english)+" · "+str(candidate.digest).substr(0,12))
		choice.set_item_metadata(choice.item_count-1,str(candidate.path))
	column.add_child(choice)
	recovery_dialog.confirmed.connect(func() -> void:
		var result: Error = session.recover(str(choice.get_item_metadata(choice.selected)),recovery_fingerprint)
		if result != OK:
			set_status(text2("恢复未完成，原始字节继续保留：","Recovery failed; original bytes remain preserved: ")+str(result))
			return
		writable = session.lease != null and session.lease.owns(session.path)
		recovery_choices = []
		recovery_fingerprint = ""
		_clear_replaced_exploration()
		set_status(text2("已明确恢复所选副本；原文件已保全。","The selected copy was explicitly restored; original bytes remain preserved."))
		build())
	add_child(recovery_dialog)

func _build_cost_comparison(tabs: TabContainer) -> void:
	cost_comparison_page = tab(tabs,text2("成本账本","Cost ledger"))
	cost_comparison_page.name = "CostLedgerPage"
	var content: VBoxContainer = scroll_column(cost_comparison_page)
	var controls := HBoxContainer.new()
	content.add_child(controls)
	cost_comparison_choice = OptionButton.new()
	cost_comparison_choice.name = "CostComparisonHistory"
	cost_comparison_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(cost_comparison_choice)
	cost_comparison_choice.item_selected.connect(func(index: int) -> void:
		selected_cost_comparison = index
		refresh_cost_comparison())
	button(text2("运行对照","Run comparison"),"RunCostComparison",controls,compare_transport)
	cost_comparison_status = label("",content,12)
	cost_comparison_status.name = "CostComparisonStatus"
	cost_comparison_view = CostLedgerView.new()
	cost_comparison_view.name = "CostComparisonBars"
	content.add_child(cost_comparison_view)
	cost_comparison_details = label("",content,12)
	cost_comparison_details.name = "CostComparisonDetails"

func compare_transport() -> void:
	# This synchronous action runs both codecs before any editor input can change
	# source, frozen model or machine; results carry copies of those conditions.
	var source: Array = Catalog.source(source_kind)
	var model: Dictionary = session.data.model.duplicate(true)
	var machine: Dictionary = session.data.draft.machine.duplicate(true)
	var preparation: Dictionary = session.data.training.get("cost",{}).duplicate(true)
	var raw: Dictionary = session.transport(source,"raw")
	var predictive: Dictionary = session.transport(source,"predictive")
	var measured: Dictionary = CostLedger.capture(source,model,machine,preparation,raw,predictive,session.data.training.get("machine",{}))
	transport_comparisons.append(measured)
	if transport_comparisons.size()>6: transport_comparisons.pop_front()
	selected_cost_comparison = transport_comparisons.size()-1
	if predictive.get("ok",false):
		latest = predictive.duplicate(true)
		latest.kind = "transport"
		latest.source = source.duplicate()
		latest.codec = "predictive"
		session.complete(Catalog.IDS[task] if task < 3 else "C2_cost")
	elif raw.get("ok",false):
		latest = raw.duplicate(true)
		latest.kind = "transport"
		latest.source = source.duplicate()
		latest.codec = "raw"
	else: latest = {}
	event_page = 0
	set_status(text2("同原文、同模型、同机器的两次真实传输已记录；失败项不会画成零成本。", "Two real transports under the same source, model and machine are recorded; failed runs are not shown as free."))
	refresh()
	refresh_tracks()
	var tabs := find_child("EvidenceTabs",true,false) as TabContainer
	if tabs != null: tabs.current_tab = cost_comparison_page.get_index()
	set_evidence_expanded(true)

func refresh_cost_comparison() -> void:
	if not is_instance_valid(cost_comparison_choice): return
	cost_comparison_choice.clear()
	for index: int in transport_comparisons.size():
		var measured: Dictionary = transport_comparisons[index]
		cost_comparison_choice.add_item("#%d · N=%d · CPU %d / bus %d / req %d"%[index+1,measured.source_length,measured.machine.cpu_ops_per_cycle,measured.machine.bytes_per_cycle,measured.machine.request_cycles])
	selected_cost_comparison = clampi(selected_cost_comparison,-1,transport_comparisons.size()-1)
	var snapshot: Dictionary = {}
	if selected_cost_comparison >= 0:
		cost_comparison_choice.select(selected_cost_comparison)
		snapshot = transport_comparisons[selected_cost_comparison]
	cost_comparison_choice.disabled = snapshot.is_empty()
	cost_comparison_status.text = text2("两种codec锁定同原文、同模型和同机器。最多保留本次会话最近6组；学习费用单列。", "Both codecs use one source, model and machine. The latest 6 pairs stay in this session; learning is separate.")
	if not snapshot.is_empty():
		cost_comparison_status.text += "\n"+ (text2("与当前条件一致。", "Matches current conditions.") if CostLedger.matches(snapshot,Catalog.source(source_kind),session.data.model,session.data.draft.machine) else text2("条件已改变：这里保留上次实测，运行对照才会增加新结果。", "Conditions changed: this remains the recorded result. Run comparison to add new evidence."))
	cost_comparison_view.show_snapshot(snapshot,english)
	cost_comparison_details.text = CostLedger.describe(snapshot,english)

func set_evidence_expanded(expanded: bool) -> void:
	evidence_expanded = expanded
	if not is_instance_valid(signal_area) or not is_instance_valid(evidence_toggle): return
	if expanded:
		playing = false
		play_button.text = text2("播放","Play")
	signal_area.visible = not expanded
	evidence_toggle.visible = expanded
	evidence_toggle.text = text2("回到光纹","Back to signal") if expanded else text2("展开证据","Expand evidence")
	evidence_toggle.tooltip_text = text2("只改变阅读区域；保留已选格、页码、草稿和实测。", "Reading space only; selected cell, page, draft and measurements stay intact.")

func _build_creation_comparison(parent: Node) -> void:
	label(text2("受控对照 · 先生成，再钉住 A", "Controlled comparison · generate, then pin A"),parent,14)
	label(text2("钉住后锁定种子、起始片段和长度。到「样例与记忆」只增删一段样例，再学习、生成 B。A 保持不变；此临时对照不随草稿保存。", "Pinning locks seed, initial passage and length. In Examples / history, add or remove one passage, learn, then generate B. A stays fixed. This temporary comparison is not saved with the draft."),parent,12)
	var actions := HFlowContainer.new()
	parent.add_child(actions)
	button(text2("钉住当前输出为 A", "Pin current output as A"),"PinCreationA",actions,pin_creation_a)
	button(text2("结束对照", "End comparison"),"ClearCreationComparison",actions,clear_creation_comparison)
	creation_caption = label("",parent,12)
	creation_caption.name = "CreationComparisonCaption"
	var decisions := HFlowContainer.new()
	parent.add_child(decisions)
	button(text2("定位首次分歧", "First difference"),"CreationFirstDifference",decisions,show_creation_difference)
	button(text2("保留 A…", "Keep A…"),"KeepCreationA",decisions,func() -> void: choose_creation_result(false))
	button(text2("保留 B…", "Keep B…"),"KeepCreationB",decisions,func() -> void: choose_creation_result(true))
	button(text2("继续改", "Keep editing"),"EditCreationB",decisions,func() -> void:
		var tabs := find_child("DraftTabs",true,false) as TabContainer
		if tabs != null: tabs.current_tab = 0
		set_status(text2("A 仍保持原样。修改一段样例后重新学习，再生成 B。", "A stays fixed. Change one example, learn again, then generate B.")))

func _refresh_creation_comparison() -> void:
	var pinned: bool = not pinned_creation.is_empty()
	if is_instance_valid(creation_caption):
		creation_caption.text = CreationComparison.caption(creation_report,english) if pinned else text2("还没有钉住 A。", "No A pinned yet.")
		if pinned and not compared_creation.is_empty():
			var visible: String = "A" if latest.get("recipe",{}) == pinned_creation.recipe and latest.get("output",[]) == pinned_creation.output else "B" if latest.get("recipe",{}) == compared_creation.recipe and latest.get("output",[]) == compared_creation.output else text2("其他视图","another view")
			creation_caption.text += "\n"+text2("当前显示：", "Currently showing: ")+visible
	for id: String in ["Initial","Seed","Length"]:
		var control := find_child(id,true,false)
		if control is LineEdit: control.editable = not pinned
		elif control is SpinBox: control.editable = not pinned
	var available: Dictionary = {"PinCreationA":can_keep_visible_work() and not pinned,"PinCreationAQuick":can_keep_visible_work() and not pinned,"ClearCreationComparison":pinned,"KeepCreationA":pinned and writable,"KeepCreationB":not compared_creation.is_empty() and writable,"CreationFirstDifference":int(creation_report.get("first_difference",-1)) >= 0,"EditCreationB":pinned}
	for id: String in available:
		var action := find_child(id,true,false) as Button
		if action != null: action.disabled = not available[id]

func pin_creation_a() -> void:
	if not pinned_creation.is_empty():
		set_status(text2("A 已钉住。若要换一个 A，请先结束本次对照。", "A is already pinned. End this comparison before choosing a new A."))
		return
	if not can_keep_visible_work():
		set_status(text2("先生成当前配方，再钉住实际输出。", "Generate the current recipe before pinning its actual output."))
		return
	pinned_creation = session.generated.duplicate(true)
	compared_creation.clear()
	creation_report.clear()
	set_status(text2("A 已钉住。种子、起始片段和长度已锁定；只改一段样例，再学习并生成 B。", "A is pinned. Seed, initial passage and length are locked; change one example, learn and generate B."))
	refresh()
	refresh_tracks()

func clear_creation_comparison() -> void:
	pinned_creation.clear()
	compared_creation.clear()
	creation_report.clear()
	set_status(text2("临时对照已结束；当前草稿和已保存作品保留。", "Temporary comparison ended; the current draft and saved works remain."))
	refresh()
	refresh_tracks()

func show_creation_difference() -> void:
	var index: int = int(creation_report.get("first_difference",-1))
	if index < 0 or compared_creation.is_empty(): return
	set_evidence_expanded(false)
	latest = compared_creation.duplicate(true)
	latest.kind = "generation"
	playing = false
	if task < 6: change_task(7)
	refresh()
	refresh_tracks()
	signal_view.cursor = index
	signal_view.selected = index
	signal_view.follow_cursor()
	inspect_cell(index)
	play_button.text = text2("播放","Play")
	set_status(text2("已定位 A 与 B 首次分歧：第 ", "Located first A/B difference: cell ")+str(index+1)+text2(" 格。差异不是正确或优劣判断。", ". Difference is not a correctness or quality judgment."))

func choose_creation_result(use_b: bool) -> void:
	var chosen: Dictionary = compared_creation if use_b else pinned_creation
	if chosen.is_empty() or not writable: return
	# Selecting an actual run restores its complete recipe, never relabels the
	# other run's output with the current controls. Saved works are untouched.
	var title: String = name_input.text
	var recipe: Dictionary = chosen.recipe
	session.data.model = recipe.model.duplicate(true)
	session.data.draft = {"machine":recipe.machine.duplicate(true),"examples":recipe.model.examples.duplicate(true),"order":int(recipe.model.order),"initial":recipe.initial.duplicate(),"length":int(recipe.length),"seed":int(recipe.seed),"sampler":recipe.sampler}
	session.data.training = chosen.training.duplicate(true)
	session.data.parent_work = chosen.parent_work
	session.data.mode = "generate"
	session.mark_dirty()
	session.generated = chosen.duplicate(true)
	latest = chosen.duplicate(true)
	latest.kind = "generation"
	change_task(8)
	name_input.text = title
	keep_work()

func focus_work() -> void:
	if is_instance_valid(work_focus): return
	var result: Dictionary = session.play_work(selected_work())
	if not result.get("ok",false):
		set_status(text2("先在作品列表选中一件已保存作品。", "Select a saved work first."))
		return
	show_saved_work(result.work)

func view_kept_work() -> void:
	if kept_work.is_empty(): return
	show_saved_work(kept_work)

func continue_creation() -> void:
	if not writable or kept_work.is_empty(): return
	var index: int = -1
	for i: int in session.data.works.size():
		if session.data.works[i].id == kept_work.get("id",""): index = i; break
	var editor_state: Dictionary = _capture_editor_state()
	var invalid_initial: bool = not valid_initial_input()
	var result: Dictionary = session.fork_work(index)
	if not result.get("ok",false):
		set_status(text2("无法继续修改作品：", "Cannot continue this work: ")+failure_text(result))
		return
	_clear_active_draft_presentation()
	build()
	if not invalid_initial: editor_state.inputs.erase("Initial")
	_restore_editor_state(editor_state)
	set_status(text2("从已保存作品建立可撤销的新草稿；旧作品原样保留。", "An undoable draft starts from the saved work; the protected work stays intact."))

func show_saved_work(work: Dictionary) -> void:
	if is_instance_valid(work_focus): return
	work_focus_return = get_viewport().gui_get_focus_owner()
	work_focus = WorkFocus.new()
	work_focus.name = "SavedWorkFocus"
	work_focus.theme = theme
	work_focus.configure(work,english)
	work_focus.dismissed.connect(func() -> void:
		if is_instance_valid(work_focus_return): work_focus_return.grab_focus())
	add_child(work_focus)
	work_focus.popup_centered_clamped(Vector2i(1080,620),0.92)
