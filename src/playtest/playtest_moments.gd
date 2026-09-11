extends Node
## Voluntary local feedback available during a run and after an unfinished exit.
var panel: PanelContainer
var note: LineEdit
var status: Label
var moment_box: VBoxContainer
var exit_reason: OptionButton
var moment_sequence: int = -1
var last_export: String = ""
var source_selector: OptionButton
var previous_focus: Control
var target: Dictionary = {}
var target_label: Label
var ratings: Array[OptionButton] = []
var opinion: LineEdit
var remote_toggle: OptionButton
var remote_status: Label
var score_toggle: CheckButton
var saved_opinion: Dictionary = {}
var content_scroll: ScrollContainer

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1600
	add_child(layer)
	panel = PanelContainer.new()
	panel.name = "VoluntaryPlaytestFeedback"
	panel.position = Vector2(24,80)
	panel.custom_minimum_size = Vector2(560,0)
	var skin := Theme.new()
	skin.default_font_size = 20
	preload("res://src/ui/instrument_theme.gd").apply_to(skin)
	panel.theme = skin
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	content_scroll=ScrollContainer.new()
	content_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.custom_minimum_size=Vector2(500,550)
	var outer := VBoxContainer.new()
	margin.add_child(outer)
	outer.add_child(content_scroll)
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content_scroll.add_child(box)
	var heading := HBoxContainer.new()
	outer.add_child(heading)
	outer.move_child(heading,0)
	var title := Label.new()
	title.text = _t("title")
	title.set_meta("translation","title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_button(heading,"close",close)
	var privacy := Label.new()
	privacy.text = _t("privacy")
	privacy.set_meta("translation","privacy")
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(privacy)
	target_label=Label.new(); target_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	box.add_child(target_label)
	for key: String in ["fun","clarity","continue"]:
		var choice := OptionButton.new()
		choice.set_meta("rating_key",key)
		choice.add_item(_l({"fun":"有趣吗","clarity":"目标清楚吗","continue":"想继续玩吗"}[key],{"fun":"Fun","clarity":"Goal clarity","continue":"Want to continue"}[key])+_l(" · 暂不评分"," · no rating"))
		for score: int in range(1,6): choice.add_item(str(score)+_l(" / 5"," / 5"))
		ratings.append(choice); box.add_child(choice)
	opinion=LineEdit.new(); opinion.max_length=240
	opinion.placeholder_text=_l("本关意见（未通关也能写，最多 240 字）","Opinion, even before passing (240 characters)")
	box.add_child(opinion)
	var save_opinion := Button.new(); save_opinion.text=_l("保存本关评价到本机","Save task feedback locally")
	save_opinion.custom_minimum_size.y=40; box.add_child(save_opinion)
	save_opinion.pressed.connect(_save_opinion)
	var remote_fold := CheckButton.new(); remote_fold.text=_l("可选回传与数据设置","Optional sharing and data settings")
	box.add_child(remote_fold)
	var remote_box := VBoxContainer.new(); remote_box.hide(); box.add_child(remote_box)
	remote_fold.toggled.connect(func(value: bool) -> void: remote_box.visible=value)
	var remote_info := Label.new(); remote_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	remote_info.text=_l("默认只保存在本机。回传使用随机安装标识，不含账户、方案名称或电路。行为回传仅从同意后开始，约每 45 秒一批。意见须单独点击发送。服务端保留 30 天；关闭回传不影响游玩。", "Local by default. Sharing uses a random installation ID, no account, design name or circuit. Future actions only, batched about every 45 seconds. Opinions need a separate Send. Receiver retention: 30 days. Playing works without sharing.")
	remote_box.add_child(remote_info)
	var destination := Label.new(); destination.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	destination.text=_l("接收地址：","Receiver: ")+(RemoteFeedback.endpoint if RemoteFeedback.endpoint_allowed() else _l("此版本未配置，仍可本地保存和导出。","Not configured in this build; save and export still work."))
	remote_box.add_child(destination)
	var local_toggle := CheckButton.new(); local_toggle.text=_l("记录本机游玩操作（不含意见正文）","Record local play actions (no opinion text)"); local_toggle.button_pressed=PlaytestData.telemetry_enabled
	local_toggle.toggled.connect(func(value: bool) -> void: PlaytestData.set_local_recording(value); _save_preferences(value))
	remote_box.add_child(local_toggle)
	remote_toggle=OptionButton.new()
	for label: String in [_l("仅保存在本机","Local only"),_l("分享基础统计 · 每次访问一份汇总","Share basic statistics · one summary per visit"),_l("参与详细试玩 · 逐次操作与运行","Detailed playtest · actions and runs")]: remote_toggle.add_item(label)
	remote_toggle.select(["local","basic","detailed"].find(RemoteFeedback.sharing_mode))
	remote_toggle.disabled=not RemoteFeedback.endpoint_allowed()
	remote_toggle.item_selected.connect(func(index: int) -> void: RemoteFeedback.set_sharing_mode(["local","basic","detailed"][index]))
	remote_box.add_child(remote_toggle)
	var tier_help := Label.new(); tier_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	tier_help.text=_l("基础统计从下一次进入关卡开始：停留、完成、编辑次数和有限成绩。详细试玩额外分享逐次操作，不含电路或程序。切换分档会清空待发的行为记录。", "Basic sharing starts at your next task visit: time, completion, edit counts and bounded metrics. Detailed sharing adds individual actions, never circuits or programs. Changing mode clears pending action records.")
	remote_box.add_child(tier_help)
	var cohort := OptionButton.new()
	for label: String in [_l("经验背景 · 不提供","Experience · unspecified"),_l("刚接触电路","New to circuits"),_l("有一些经验","Some experience"),_l("比较熟悉","Experienced")]: cohort.add_item(label)
	var cohorts: Array[String] = ["unspecified","new_to_circuits","some_experience","experienced"]
	cohort.select(maxi(0,cohorts.find(RemoteFeedback.background_cohort)))
	cohort.item_selected.connect(func(index: int) -> void: RemoteFeedback.background_cohort=cohorts[index]; RemoteFeedback._save_state())
	remote_box.add_child(cohort)
	var score_choice := CheckButton.new(); score_toggle=score_choice; score_choice.text=_l("单独同意提交实验榜成绩（不含方案）","Separately allow experimental scores (no designs)")
	score_choice.disabled=not RemoteFeedback.endpoint_allowed(); score_choice.button_pressed=RemoteFeedback.scores_enabled
	score_choice.toggled.connect(func(value: bool) -> void: RemoteFeedback.set_scores_enabled(value))
	remote_box.add_child(score_choice)
	var designs := Label.new(); designs.text=_l("公开方案：此版本不支持，也不会上传。","Public designs: unsupported; never uploaded.")
	designs.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; remote_box.add_child(designs)
	var send := Button.new(); send.text=_l("发送刚保存的这条评价","Send the opinion I just saved"); remote_box.add_child(send); send.disabled=not RemoteFeedback.endpoint_allowed()
	send.pressed.connect(func() -> void:
		if saved_opinion.is_empty(): remote_status.text=_l("请先保存这条评价。","Save this opinion first.")
		else: RemoteFeedback.send_feedback(saved_opinion))
	var retry := Button.new(); retry.text=_l("重试等待回传的记录","Retry pending records"); remote_box.add_child(retry); retry.disabled=not RemoteFeedback.endpoint_allowed(); retry.pressed.connect(RemoteFeedback.retry_pending)
	var remove := Button.new(); remove.text=_l("关闭回传并请求删除已回传数据…","Stop sharing and request uploaded data deletion…"); remote_box.add_child(remove); remove.disabled=not RemoteFeedback.endpoint_allowed()
	var confirm := ConfirmationDialog.new(); panel.add_child(confirm)
	confirm.dialog_text=_l("删除此安装标识已回传的数据，并清空等待发送的记录。本机意见和游戏存档保留。确认？","Delete uploads for this installation and clear its pending queue? Local feedback and game saves stay available.")
	remove.pressed.connect(func() -> void: confirm.popup_centered(Vector2i(540,180)))
	confirm.confirmed.connect(RemoteFeedback.delete_uploaded_data)
	remote_status=Label.new(); remote_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; remote_box.add_child(remote_status)
	RemoteFeedback.status_changed.connect(_remote_updated); _remote_updated()
	moment_box=VBoxContainer.new(); box.add_child(moment_box)
	var moment_heading := Label.new(); moment_heading.text=_l("记录一个具体时刻（可选）","Mark a specific moment (optional)"); moment_box.add_child(moment_heading)
	var grid := GridContainer.new()
	grid.columns = 2
	moment_box.add_child(grid)
	for kind: String in ["stuck","blocked_action","understood","fun","following"]:
		_button(grid,kind,func() -> void:
			moment_sequence = PlaytestData.mark_moment(StringName(kind))
			status.text = _t("saved") if moment_sequence > 0 else _t("failed")+PlaytestData.last_error)
	note = LineEdit.new()
	note.placeholder_text = _t("note")
	note.set_meta("translation","note")
	note.max_length = 240
	moment_box.add_child(note)
	_button(moment_box,"save_note",func() -> void:
		var saved: bool = PlaytestData.add_moment_note(moment_sequence,note.text)
		status.text = _t("saved") if saved else _t("choose_first")
		if saved: note.clear())
	exit_reason = OptionButton.new()
	exit_reason.add_item(_t("exit_optional"))
	for reason: String in ["other_task","rest","unclear_goal","no_strategy","unexpected_operation","repetitive"]:
		exit_reason.add_item(_t("exit."+reason))
		exit_reason.set_item_metadata(exit_reason.item_count-1,reason)
	exit_reason.item_selected.connect(func(index: int) -> void:
		if index > 0: status.text = _t("saved") if PlaytestData.set_exit_reason(StringName(exit_reason.get_item_metadata(index))) else _t("failed"))
	box.add_child(exit_reason)
	var source := OptionButton.new()
	source_selector = source
	source.add_item(_t("source.unknown"))
	source.set_item_metadata(0,"unknown")
	for kind: String in ["external_player","developer","agent_native","automated"]:
		source.add_item(_t("source."+kind))
		source.set_item_metadata(source.item_count-1,kind)
	source.disabled = PlaytestData.source_kind in ["automated","agent_native"]
	for index: int in range(source.item_count):
		if source.get_item_metadata(index) == PlaytestData.source_kind: source.select(index)
	source.item_selected.connect(func(index: int) -> void: PlaytestData.source_kind = source.get_item_metadata(index))
	box.add_child(source)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	_button(actions,"export",func() -> void:
		last_export = PlaytestData.export_current_session()
		status.text = _t("exported") if not last_export.is_empty() else _t("failed")+PlaytestData.last_error)
	_button(actions,"folder",func() -> void:
		if not last_export.is_empty(): OS.shell_show_in_file_manager(last_export))
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 32
	outer.add_child(status)
	panel.hide()
	Localization.locale_changed.connect(func(_locale: String) -> void: _refresh_language())

func make_button() -> Button:
	var button := Button.new()
	button.name = "MomentFeedbackButton"
	button.text = _t("button")
	var refresh := _refresh_entry_language.bind(weakref(button))
	Localization.locale_changed.connect(refresh)
	button.tree_exiting.connect(func() -> void:
		if Localization.locale_changed.is_connected(refresh):
			Localization.locale_changed.disconnect(refresh))
	button.tooltip_text = _t("title")+" · F8"
	button.pressed.connect(toggle)
	return button

func _refresh_entry_language(_locale: String, reference: WeakRef) -> void:
	var button: Button = reference.get_ref()
	if button != null:
		button.text = _t("button")
		button.tooltip_text = _t("title")+" · F8"

func toggle() -> void:
	if panel.visible: close(); return
	target=PlaytestData.current_task_context.duplicate() if not PlaytestData.current_task_context.is_empty() else PlaytestData.last_exit_context.duplicate()
	_prepare_target()
	previous_focus = get_viewport().gui_get_focus_owner()
	panel.show()
	preload("res://src/ui/ui_motion.gd").reveal(panel)
	var choices: Array[Node] = panel.find_children("*","Button",true,false)
	if not choices.is_empty(): (choices[0] as Button).grab_focus()
	_update_context_controls()
	panel.position = Vector2(24,80)
	panel.size.x = minf(680,get_viewport().get_visible_rect().size.x-48)
	content_scroll.custom_minimum_size.y=minf(550,get_viewport().get_visible_rect().size.y-270)
	status.text = "" if PlaytestData.questionnaires_enabled() else _t("disabled")
	exit_reason.select(0)
	PlaytestData.set_feedback_visible(true,&"moments")

func close() -> void:
	panel.hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	PlaytestData.set_feedback_visible(false,&"moments")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			toggle(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and panel.visible:
			close(); get_viewport().set_input_as_handled()

func _button(parent: Node,key: String,action: Callable) -> Button:
	var button := Button.new()
	button.text = _t(key)
	button.set_meta("translation",key)
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _t(key: String) -> String: return Localization.text(StringName("moments."+key))

func _refresh_language() -> void:
	_translate(panel)
	exit_reason.set_item_text(0,_t("exit_optional"))
	for index: int in range(1,exit_reason.item_count): exit_reason.set_item_text(index,_t("exit."+str(exit_reason.get_item_metadata(index))))
	for index: int in range(source_selector.item_count): source_selector.set_item_text(index,_t("source."+str(source_selector.get_item_metadata(index))))
	status.text = ""

func _translate(node: Node) -> void:
	if node.has_meta("translation"):
		if node is LineEdit: node.placeholder_text = _t(str(node.get_meta("translation")))
		else: node.set("text",_t(str(node.get_meta("translation"))))
	for child: Node in node.get_children(): _translate(child)

func open_for_task(chapter: String, level: String) -> void:
	if panel.visible: close()
	toggle()
	target={"chapter_id":chapter,"level_id":level}
	_prepare_target()
func _prepare_target() -> void:
	var key: String = str(target.get("chapter_id",""))+"/"+str(target.get("level_id",""))
	var title: String = key
	for task: Dictionary in TaskNavigation.tasks():
		if task.key==key: title=task.title; break
	target_label.text=_l("评价对象：","Feedback for: ")+title if not target.get("level_id","").is_empty() else _l("进入一关后可评分；也可在任务树选中关卡后留下意见。","Enter a task to rate it, or select one in the task tree.")
	for rating: OptionButton in ratings: rating.select(0)
	opinion.clear(); saved_opinion.clear(); moment_sequence=-1
	content_scroll.scroll_vertical=0
	_update_context_controls()
func _update_context_controls() -> void:
	var current: Dictionary = PlaytestData.current_task_context if not PlaytestData.current_task_context.is_empty() else PlaytestData.last_exit_context
	var matches: bool = not current.is_empty() and current.get("chapter_id","")==target.get("chapter_id","") and current.get("level_id","")==target.get("level_id","")
	moment_box.visible=matches
	exit_reason.visible=matches and PlaytestData.current_task_context.is_empty() and not PlaytestData.last_exit_context.is_empty()
func _save_opinion() -> void:
	var chapter: String = str(target.get("chapter_id",""))
	var level: String = str(target.get("level_id",""))
	var saved: bool = PlaytestData.submit_level_feedback(StringName(chapter),StringName(level),ratings[0].selected,ratings[1].selected,ratings[2].selected,opinion.text)
	status.text=_l("已保存到本机。再次保存会保留修订记录，统计只采用本次游玩的最新评价。","Saved locally. Revisions are retained; analysis uses the latest opinion for this visit.") if saved else _l("请先选择关卡，并至少填写一项评分或意见。","Choose a task and provide a rating or opinion.")
	if saved: saved_opinion=PlaytestData.latest_level_feedback(chapter,level)
func _remote_updated() -> void:
	var labels: Dictionary = {
		"local_only":["仅本机保存","Local only"],"not_configured":["尚未配置接收地址；可保存和导出","No receiver configured; save and export available"],
		"pending":["等待回传","Queued"],"ready":["已同意，只记录今后的操作","Enabled for future actions"],"sending":["发送中，等待落盘回执","Sending; awaiting stored receipt"],
		"sent":["服务端已确认落盘","Receiver confirmed storage"],"failed_retryable":["暂未收到回执；记录仍在本机等待重试","No receipt yet; retained locally for retry"],
		"rejected":["服务端拒绝，已暂停重试；可导出反馈","Rejected; paused. Local export remains available"],"queue_full":["等待队列已满；本机记录仍可导出","Queue full; local records can still be exported"],
		"storage_error":["本机队列保存失败；尚不能确认发送","Local outbox could not be saved"],"deleted":["服务端已确认删除此安装的数据","Receiver confirmed deletion"],"deleting":["正在请求删除","Requesting deletion"],"delete_failed":["删除未获确认，请稍后重试","Deletion unconfirmed; retry later"]}
	var pair: Array = labels.get(RemoteFeedback.status,[RemoteFeedback.status,RemoteFeedback.status])
	remote_status.text=_l(str(pair[0]),str(pair[1]))+" · %d " % RemoteFeedback.queue.size()+_l("条等待","pending")
	remote_toggle.select(maxi(0,["local","basic","detailed"].find(RemoteFeedback.sharing_mode)))
	if is_instance_valid(score_toggle): score_toggle.set_pressed_no_signal(RemoteFeedback.scores_enabled)
func _save_preferences(value: bool) -> void:
	var config := ConfigFile.new(); config.set_value("privacy","local_actions",value)
	config.save("user://feedback_preferences.cfg")
func _l(zh: String,en: String) -> String: return zh if TranslationServer.get_locale().begins_with("zh") else en
