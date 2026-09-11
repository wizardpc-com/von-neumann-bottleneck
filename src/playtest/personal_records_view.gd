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
	_button(header,Localization.text(&"records.back_to_task_tree"),func() -> void: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE))
	var title := Label.new(); title.text=Localization.text(&"records.my_task_record"); title.add_theme_font_size_override("font_size",30); header.add_child(title)
	header.add_child(PlaytestMoments.make_button())
	data=PersonalRecords.snapshot()
	_label(box,Localization.text(&"records.d_d_complete_main_d_d_side_d_d_bonus_d_d") % [data.completed,data.total,data.main_completed,data.main_total,data.side_completed,data.side_total,data.bonus_completed,data.bonus_total])
	_label(box,Localization.text(&"records.progress_comes_from_local_saves_d_saved_designs_unrecorded_historica") % data.saved_schemes)
	region_choice=OptionButton.new(); region_choice.add_item(Localization.text(&"records.all_regions"))
	region_choice.set_item_metadata(0,-1)
	for region: Dictionary in data.regions:
		region_choice.add_item(Localization.text(StringName(region.title_key))+"   %d / %d" % [region.completed,region.total])
		region_choice.set_item_metadata(region_choice.item_count-1,region.id)
	region_choice.item_selected.connect(func(_index: int) -> void: _rows()); box.add_child(region_choice)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; box.add_child(scroll)
	content=VBoxContainer.new(); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",8); scroll.add_child(content)
	_rows()
	if not RemoteFeedback.endpoint_allowed(): return
	var fold := CheckButton.new(); fold.name="CommunityToggle"; fold.text=Localization.text(&"records.optional_community_connects_only_when_requested"); box.add_child(fold)
	var community := VBoxContainer.new(); community.hide(); box.add_child(community); fold.toggled.connect(func(value: bool) -> void: community.visible=value)
	_label(community,Localization.text(&"records.alpha_experimental_community_board_not_replay_verified_by_a_server_n"))
	var actions := HFlowContainer.new(); community.add_child(actions)
	_button(actions,Localization.text(&"records.community_task_statistics"),_fetch.bind("community/tasks"))
	_button(actions,Localization.text(&"records.chapter_4_capstone_board"),_fetch.bind("leaderboards"))
	_button(actions,Localization.text(&"records.submit_my_capstone_result"),func() -> void:
		var score: Dictionary = PersonalRecords.layout_score()
		if not RemoteFeedback.scores_enabled: online_status.text=Localization.text(&"records.first_allow_score_submission_in_feedback_settings")
		elif score.is_empty(): online_status.text=Localization.text(&"records.first_complete_the_chapter_4_capstone_in_game")
		else: online_status.text=Localization.text(&"records.result_queued_locally") if not RemoteFeedback.send_score(score).is_empty() else Localization.text(&"records.could_not_queue_check_feedback_settings"))
	var online_scroll := ScrollContainer.new(); online_scroll.custom_minimum_size.y=140; online_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; community.add_child(online_scroll)
	online_status=_label(online_scroll,Localization.text(&"records.no_service_configured_in_this_build_personal_records_always_work_off"))
	online_status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	online=HTTPRequest.new(); online.timeout=8; online.body_size_limit=131072; add_child(online); online.request_completed.connect(_received)
func _rows() -> void:
	for child: Node in content.get_children(): child.queue_free()
	for task: Dictionary in data.tasks:
		if region_choice.selected>0 and task.region!=region_choice.get_item_metadata(region_choice.selected): continue
		var panel := PanelContainer.new(); content.add_child(panel)
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation",14); panel.add_child(row)
		var title := _label(row,("✓  " if task.completed else "○  ")+task.title+(Localization.text(&"records.side") if task.optional else ""))
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.add_theme_color_override("font_color",Color("87dcc8") if task.completed else Color("bac7db"))
		var values: PackedStringArray = []
		for metric: String in task.record_metrics:
			if task.best.has(metric): values.append(Localization.text(StringName("records.metric."+metric)) % int(task.best[metric]))
		var score: String = " · ".join(values) if not values.is_empty() else "—"
		var metrics := _label(row,Localization.text(&"records.best_s_designs_d") % [score,task.saved_schemes])
		metrics.custom_minimum_size.x=300
		metrics.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_button(row,Localization.text(&"records.feedback"),func() -> void: PlaytestMoments.open_for_task(task.domain,task.id))
func _fetch(kind: String) -> void:
	if not RemoteFeedback.endpoint_allowed(): online_status.text=Localization.text(&"records.community_service_not_configured_offline_play_is_complete"); return
	request_kind=kind
	var url: String = RemoteFeedback.api_url(kind)
	if kind=="leaderboards":
		var catalog = preload("res://src/layout_chapter/layout_catalog.gd")
		url+="?level_id=chapter_4%2Fmixed&ruleset_version=layout-mixed-1&model_version=layout-memory-1&case_set_version="+("layout-v1:mixed"+JSON.stringify(catalog.cases("mixed"))).sha256_text()
	var err: Error = online.request(url)
	online_status.text=Localization.text(&"records.reading") if err==OK else Localization.text(&"records.request_not_started_try_later")
func _received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200: online_status.text=Localization.text(&"records.unavailable_local_progress_is_unaffected"); return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary: online_status.text=Localization.text(&"records.unreadable_response"); return
	if request_kind=="leaderboards":
		var lines: PackedStringArray = []
		for row: Dictionary in parsed.get("rows",[]): lines.append("#%d   %s   ·   %d" % [row.rank,row.player,row.total_cycles])
		online_status.text=Localization.text(&"records.experimental_board_fewer_cycles_is_better")+("\n".join(lines) if not lines.is_empty() else Localization.text(&"records.no_results_yet"))
	else:
		var tasks: Dictionary = parsed.get("tasks",{})
		var lines: PackedStringArray = []
		for task: Dictionary in data.tasks:
			if tasks.has(task.key):
				var row: Dictionary = tasks[task.key]
				lines.append(task.title+" · %d / %d" % [row.completions,row.starts]+(Localization.text(&"records.small_sample") if row.small_sample else ""))
		online_status.text=Localization.text(&"records.completed_started_ended_visits_consenting_players_only")+("\n".join(lines) if not lines.is_empty() else Localization.text(&"records.no_statistics_yet"))
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE)
func _button(parent: Node,text: String,callback: Callable) -> void:
	var button := Button.new(); button.text=text; button.custom_minimum_size.y=42; button.pressed.connect(callback); parent.add_child(button)
func _label(parent: Node,text: String) -> Label:
	var label := Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(label); return label
