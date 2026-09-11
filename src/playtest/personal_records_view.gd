extends Control
var content: VBoxContainer
var region_choice: OptionButton
var data: Dictionary
var online_status: Label
var online: HTTPRequest
var request_kind: String = ""
func _ready() -> void:
	var skin := Theme.new(); skin.default_font_size=20
	preload("res://src/ui/instrument_theme.gd").apply_to(skin); theme=skin
	var back := preload("res://src/ui/technical_backdrop.gd").new(); back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(back)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
	add_child(margin)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",16); margin.add_child(box)
	var header := HBoxContainer.new(); box.add_child(header)
	_button(header,_l("返回任务树","Back to task tree"),func() -> void: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE))
	var title := Label.new(); title.text=_l("我的任务记录","My task record"); title.add_theme_font_size_override("font_size",30); header.add_child(title)
	header.add_child(PlaytestMoments.make_button())
	data=PersonalRecords.snapshot()
	_label(box,_l("%d / %d 已完成   ·   主线 %d / %d   ·   支线 %d / %d   ·   附加目标 %d / %d", "%d / %d complete   ·   Main %d / %d   ·   Side %d / %d   ·   Bonus %d / %d") % [data.completed,data.total,data.main_completed,data.main_total,data.side_completed,data.side_total,data.bonus_completed,data.bonus_total])
	_label(box,_l("进度来自本机存档。保存方案 %d 份；未记录的历史成绩显示为 —，不会猜测。","Progress comes from local saves. %d saved designs; unrecorded historical scores show —.") % data.saved_schemes)
	region_choice=OptionButton.new(); region_choice.add_item(_l("全部区域","All regions"))
	var regions: Array[String] = [_l("序章 · 造出机器","Prologue · Build a machine"),_l("第一章 · 找出等待","Chapter 1 · Find the wait"),_l("第二章 · 减少搬运","Chapter 2 · Reduce transfers"),_l("第三章 · 安排到达","Chapter 3 · Arrange arrivals"),_l("第四章 · 摆对地方","Chapter 4 · Put data in place")]
	for i: int in range(5): region_choice.add_item(regions[i]+"   %d / %d" % [data.regions[i].completed,data.regions[i].total])
	region_choice.item_selected.connect(func(_index: int) -> void: _rows()); box.add_child(region_choice)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; box.add_child(scroll)
	content=VBoxContainer.new(); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",8); scroll.add_child(content)
	_rows()
	var fold := CheckButton.new(); fold.text=_l("可选社区 · 只在点击时访问网络","Optional community · connects only when requested"); box.add_child(fold)
	var community := VBoxContainer.new(); community.hide(); box.add_child(community); fold.toggled.connect(func(value: bool) -> void: community.visible=value)
	_label(community,_l("Alpha 实验性社区榜单，暂未服务端重放验证。与解锁、奖励无关。","Alpha experimental community board. Not replay-verified by a server; no unlocks or rewards."))
	var actions := HFlowContainer.new(); community.add_child(actions)
	_button(actions,_l("查看社区任务统计","Community task statistics"),_fetch.bind("community/tasks"))
	_button(actions,_l("查看第四章综合榜","Chapter 4 capstone board"),_fetch.bind("leaderboards"))
	_button(actions,_l("提交我的综合关成绩","Submit my capstone result"),func() -> void:
		var score: Dictionary = PersonalRecords.layout_score()
		if not RemoteFeedback.scores_enabled: online_status.text=_l("请先在反馈设置中单独同意成绩提交。","First allow score submission in feedback settings.")
		elif score.is_empty(): online_status.text=_l("先在 Game 完成第四章综合关。","First complete the Chapter 4 capstone in Game.")
		else: online_status.text=_l("成绩已加入本机待发队列。","Result queued locally.") if not RemoteFeedback.send_score(score).is_empty() else _l("未能加入队列；请检查反馈设置。","Could not queue; check feedback settings."))
	online_status=_label(community,_l("此构建未配置服务；个人任务记录始终可离线使用。","No service configured in this build; personal records always work offline."))
	online=HTTPRequest.new(); online.timeout=8; online.body_size_limit=131072; add_child(online); online.request_completed.connect(_received)
func _rows() -> void:
	for child: Node in content.get_children(): child.queue_free()
	for task: Dictionary in data.tasks:
		if region_choice.selected>0 and task.region!=region_choice.selected-1: continue
		var panel := PanelContainer.new(); content.add_child(panel)
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation",14); panel.add_child(row)
		var title := _label(row,("✓  " if task.completed else "○  ")+task.title+(_l(" · 支线"," · side") if task.optional else ""))
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.add_theme_color_override("font_color",Color("87dcc8") if task.completed else Color("bac7db"))
		var score: String = str(task.best.cycles)+_l(" 周期"," cycles") if task.best.has("cycles") else "—"
		var metrics := _label(row,_l("最佳 %s   ·   方案 %d","Best %s   ·   Designs %d") % [score,task.saved_schemes])
		metrics.autowrap_mode=TextServer.AUTOWRAP_OFF
		_button(row,_l("评价","Feedback"),func() -> void: PlaytestMoments.open_for_task(task.domain,task.id))
func _fetch(kind: String) -> void:
	if not RemoteFeedback.endpoint_allowed(): online_status.text=_l("尚未配置社区服务；仍可完整离线游玩。","Community service not configured; offline play is complete."); return
	request_kind=kind
	var url: String = RemoteFeedback.api_url(kind)
	if kind=="leaderboards":
		var catalog = preload("res://src/layout_chapter/layout_catalog.gd")
		url+="?level_id=chapter_4%2Fmixed&ruleset_version=layout-mixed-1&model_version=layout-memory-1&case_set_version="+("layout-v1:mixed"+JSON.stringify(catalog.cases("mixed"))).sha256_text()
	var err: Error = online.request(url)
	online_status.text=_l("正在读取…","Reading…") if err==OK else _l("请求未启动，请稍后再试。","Request not started; try later.")
func _received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200: online_status.text=_l("暂时无法读取；本机进度不受影响。","Unavailable; local progress is unaffected."); return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary: return
	if request_kind=="leaderboards":
		var lines: PackedStringArray = []
		for row: Dictionary in parsed.get("rows",[]): lines.append("#%d   %s   ·   %d" % [row.rank,row.player,row.total_cycles])
		online_status.text=_l("实验榜 · 周期越少越好\n","Experimental board · fewer cycles is better\n")+("\n".join(lines.slice(0,5)) if not lines.is_empty() else _l("暂无成绩。","No results yet."))
	else:
		var tasks: Dictionary = parsed.get("tasks",{})
		var lines: PackedStringArray = []
		for task: Dictionary in data.tasks:
			if tasks.has(task.key):
				var row: Dictionary = tasks[task.key]
				lines.append(task.title+" · %d / %d" % [row.completions,row.starts]+(_l("（小样本）"," (small sample)") if row.small_sample else ""))
		online_status.text=_l("已结束访问的完成 / 开始；仅同意分享者\n","Completed / started ended visits; consenting players only\n")+("\n".join(lines.slice(0,5)) if not lines.is_empty() else _l("暂无统计。","No statistics yet."))
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE)
func _button(parent: Node,text: String,callback: Callable) -> void:
	var button := Button.new(); button.text=text; button.custom_minimum_size.y=42; button.pressed.connect(callback); parent.add_child(button)
func _label(parent: Node,text: String) -> Label:
	var label := Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(label); return label
func _l(zh: String,en: String) -> String: return zh if TranslationServer.get_locale().begins_with("zh") else en
