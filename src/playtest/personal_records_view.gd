extends Control
var content: GridContainer
var data: Dictionary
var online_status: Label
var online: HTTPRequest
var request_kind: String = ""
var fetch_buttons: Array[Button] = []
var journal: JourneyJournal
var record_storage_label: Label
func _ready() -> void:
	var skin := Theme.new(); skin.default_font_size=20
	preload("res://src/ui/instrument_theme.gd").apply_to(skin); theme=skin
	var back := preload("res://src/ui/technical_backdrop.gd").new(); back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(back)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
	add_child(margin)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",16); margin.add_child(box)
	var header := HBoxContainer.new(); box.add_child(header)
	_button(header,Localization.text(&"records.back_to_task_tree"),func() -> void: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE))
	var title := Label.new(); title.text=Localization.text(&"records.my_task_record"); title.add_theme_font_size_override("font_size",30); header.add_child(title)
	var review_button: Button = _button(header,_copy("查看任务成绩","Review task results"),_open_journal)
	review_button.name="RecordReview"
	header.add_child(PlaytestMoments.make_button())
	data=PersonalRecords.snapshot(TaskNavigation.game_tasks())
	var overview := PanelContainer.new(); box.add_child(overview)
	var summary := HBoxContainer.new(); summary.add_theme_constant_override("separation",28); overview.add_child(summary)
	var count := _label(summary,"%d / %d" % [data.completed,data.total])
	count.name="CompletionTotal"; count.autowrap_mode=TextServer.AUTOWRAP_OFF
	count.add_theme_font_size_override("font_size",52)
	var detail := VBoxContainer.new(); detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL; summary.add_child(detail)
	_label(detail,Localization.text(&"records.board.completed")).add_theme_font_size_override("font_size",24)
	_label(detail,Localization.text(&"records.board.breakdown") % [data.main_completed,data.main_total,data.side_completed,data.side_total,data.bonus_completed,data.bonus_total])
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; box.add_child(scroll)
	content=GridContainer.new(); content.name="RegionCards"; content.columns=3
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("h_separation",16); content.add_theme_constant_override("v_separation",16); scroll.add_child(content)
	for region: Dictionary in data.regions: _region_card(region)
	resized.connect(_fit_columns); _fit_columns()
	_label(box,Localization.text(&"records.board.local_note"))
	if GameMode.is_test_mode(): _label(box,_copy("游戏模式档案 · 测试模式的临时成果不计入。","Game archive · temporary Test results are excluded."))
	record_storage_label=_label(box,"")
	record_storage_label.name="RecordsStorageNotice"
	record_storage_label.mouse_filter=Control.MOUSE_FILTER_PASS
	_refresh_record_notice()
	if not RemoteFeedback.endpoint_allowed(): return
	var fold := CheckButton.new(); fold.name="CommunityToggle"; fold.text=Localization.text(&"records.optional_community_connects_only_when_requested"); box.add_child(fold)
	var community := VBoxContainer.new(); community.hide(); box.add_child(community); fold.toggled.connect(func(value: bool) -> void: community.visible=value)
	_label(community,Localization.text(&"records.alpha_experimental_community_board_not_replay_verified_by_a_server_n"))
	var actions := HFlowContainer.new(); community.add_child(actions)
	fetch_buttons.append(_button(actions,Localization.text(&"records.community_task_statistics"),_fetch.bind("community/tasks")))
	fetch_buttons.append(_button(actions,Localization.text(&"records.chapter_4_capstone_board"),_fetch.bind("leaderboards")))
	_button(actions,Localization.text(&"records.submit_my_capstone_result"),func() -> void:
		var score: Dictionary = PersonalRecords.layout_score()
		if not RemoteFeedback.scores_enabled: online_status.text=Localization.text(&"records.first_allow_score_submission_in_feedback_settings")
		elif score.is_empty(): online_status.text=Localization.text(&"records.first_complete_the_chapter_4_capstone_in_game")
		else: online_status.text=Localization.text(&"records.result_queued_locally") if not RemoteFeedback.send_score(score).is_empty() else Localization.text(&"records.could_not_queue_check_feedback_settings"))
	var online_scroll := ScrollContainer.new(); online_scroll.custom_minimum_size.y=140; online_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; community.add_child(online_scroll)
	online_status=_label(online_scroll,Localization.text(&"records.no_service_configured_in_this_build_personal_records_always_work_off"))
	online_status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	online=HTTPRequest.new(); online.timeout=8; online.body_size_limit=131072; add_child(online); online.request_completed.connect(_received)
func _fit_columns() -> void:
	if is_instance_valid(content): content.columns=3 if size.x>=1250.0 else (2 if size.x>=840.0 else 1)

func _open_journal() -> void:
	_refresh_record_notice()
	if not is_instance_valid(journal):
		journal = preload("res://src/ui/journey_journal.gd").new()
		add_child(journal)
	journal.open()
	if not TaskNavigation.selected.is_empty(): journal.show_task(TaskNavigation.selected)

func _refresh_record_notice() -> void:
	record_storage_label.text=JourneyJournal.record_storage_note(PersonalRecords.storage_status,Localization.current_locale()=="en")
	record_storage_label.visible=not record_storage_label.text.is_empty()
	record_storage_label.tooltip_text=PersonalRecords.last_error

func _region_card(region: Dictionary) -> void:
	var colors: Array = preload("res://src/campaign/task_tree_canvas.gd").COLORS
	var accent: Color = colors[posmod(int(region.id),colors.size())]
	var panel := PanelContainer.new(); panel.name="Region%d" % region.id
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",InstrumentTheme.panel(Color("11212d"),Color(accent,0.55),6))
	content.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",10); panel.add_child(box)
	var title := _label(box,Localization.text(StringName(region.title_key)))
	title.add_theme_font_size_override("font_size",23)
	title.add_theme_color_override("font_color",Color("ecf3fa"))
	var emblem := ChapterEmblem.new(); emblem.accent=accent
	var domains: Dictionary = {"hardware_foundations":&"hardware","chapter_1":&"system","chapter_2":&"locality","chapter_3":&"overlap","chapter_4":&"layout"}
	for task: Dictionary in data.tasks:
		if task.region==region.id:
			emblem.chapter=domains.get(str(task.domain),&"hardware"); break
	box.add_child(emblem)
	var count := _label(box,"%d / %d" % [region.completed,region.total])
	count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; count.add_theme_font_size_override("font_size",32)
	var progress := ProgressBar.new(); progress.max_value=maxi(1,region.total); progress.value=region.completed
	progress.show_percentage=false; progress.custom_minimum_size.y=6
	progress.add_theme_stylebox_override("background",InstrumentTheme.panel(Color("07141d"),Color.TRANSPARENT,3))
	progress.add_theme_stylebox_override("fill",InstrumentTheme.panel(accent,Color.TRANSPARENT,3))
	box.add_child(progress)

func _fetch(kind: String) -> void:
	if not request_kind.is_empty(): return
	if not RemoteFeedback.endpoint_allowed(): online_status.text=Localization.text(&"records.community_service_not_configured_offline_play_is_complete"); return
	if kind not in ["community/tasks","leaderboards"]: return
	var url: String = RemoteFeedback.api_url(kind)
	if kind=="leaderboards":
		var catalog = preload("res://src/layout_chapter/layout_catalog.gd")
		url+="?level_id=chapter_4%2Fmixed&ruleset_version=layout-mixed-1&model_version=layout-memory-1&case_set_version="+("layout-v1:mixed"+JSON.stringify(catalog.cases("mixed"))).sha256_text()
	var err: Error = online.request(url)
	if err==OK:
		request_kind=kind
		for button: Button in fetch_buttons: button.disabled=true
	online_status.text=Localization.text(&"records.reading") if err==OK else Localization.text(&"records.request_not_started_try_later")
func _received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var completed_kind: String = request_kind
	request_kind=""
	for button: Button in fetch_buttons: button.disabled=false
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200: online_status.text=Localization.text(&"records.unavailable_local_progress_is_unaffected"); return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary: online_status.text=Localization.text(&"records.unreadable_response"); return
	if completed_kind=="leaderboards":
		if not parsed.get("rows") is Array: online_status.text=Localization.text(&"records.unreadable_response"); return
		var lines: PackedStringArray = []
		for row: Variant in parsed.rows:
			if not row is Dictionary or not row.get("player") is String or not _numeric_fields(row,["rank","total_cycles"]):
				online_status.text=Localization.text(&"records.unreadable_response"); return
			lines.append("#%d   %s   ·   %d" % [row.rank,row.player,row.total_cycles])
		online_status.text=Localization.text(&"records.experimental_board_fewer_cycles_is_better")+("\n".join(lines) if not lines.is_empty() else Localization.text(&"records.no_results_yet"))
	elif completed_kind=="community/tasks":
		if not parsed.get("tasks") is Dictionary: online_status.text=Localization.text(&"records.unreadable_response"); return
		var tasks: Dictionary = parsed.tasks
		var lines: PackedStringArray = []
		for task: Dictionary in data.tasks:
			if tasks.has(task.key):
				var row: Variant = tasks[task.key]
				if not row is Dictionary or not _numeric_fields(row,["completions","starts"]):
					online_status.text=Localization.text(&"records.unreadable_response"); return
				lines.append(task.title+" · %d / %d" % [row.completions,row.starts]+(Localization.text(&"records.small_sample") if row.get("small_sample",false) else ""))
		online_status.text=Localization.text(&"records.completed_started_ended_visits_consenting_players_only")+("\n".join(lines) if not lines.is_empty() else Localization.text(&"records.no_statistics_yet"))
	else: online_status.text=Localization.text(&"records.unreadable_response")

func _numeric_fields(row: Dictionary, fields: Array[String]) -> bool:
	for field: String in fields:
		if typeof(row.get(field)) not in [TYPE_INT,TYPE_FLOAT]: return false
		var value: float = float(row[field])
		if not is_finite(value) or value<0.0 or value!=floor(value): return false
	return true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE)
func _button(parent: Node,text: String,callback: Callable) -> Button:
	var button := Button.new(); button.text=text; button.custom_minimum_size.y=42; button.pressed.connect(callback); parent.add_child(button)
	return button
func _label(parent: Node,text: String) -> Label:
	var label := Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(label); return label
func _copy(zh: String,en: String) -> String:
	return en if Localization.current_locale()=="en" else zh
