extends Node
signal closed
const DRAFT_PATH := "user://feedback_drafts_v1.json"
const DRAFT_BYTES := 262144
const CATEGORIES := ["","confusion","control","bug","audiovisual","discovery","other"]
var drafts: Dictionary = {}
var drafts_blocked: bool = false
var category: OptionButton
var opinion_status: Label
var context_label: Label
var restoring_draft: bool = false
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
var receiver_label: Label
var ratings: Array[OptionButton] = []
var opinion: LineEdit
var remote_toggle: OptionButton
var remote_status: Label
var score_toggle: CheckButton
var saved_opinion: Dictionary = {}
var content_scroll: ScrollContainer
var entry_buttons: Array[WeakRef] = []

func _ready() -> void:
	_load_drafts()
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
	content_scroll=ScrollContainer.new(); content_scroll.follow_focus=true
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
	context_label=Label.new(); context_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(context_label)
	category=OptionButton.new(); category.name="FeedbackCategory"
	category.add_item(Localization.text(&"sharing.category"))
	for value: String in CATEGORIES.slice(1): category.add_item(Localization.text(StringName("sharing.category."+value)))
	box.add_child(category)
	category.item_selected.connect(func(_index: int) -> void: _store_draft())
	var rating_box := VBoxContainer.new(); rating_box.hide()
	for key: String in ["fun","clarity","continue"]:
		var choice := OptionButton.new()
		choice.set_meta("rating_key",key)
		choice.add_item(Localization.text(StringName("sharing.rating."+key))+Localization.text(&"sharing.no_rating"))
		for score: int in range(1,6): choice.add_item(str(score)+Localization.text(&"sharing.5"))
		ratings.append(choice); rating_box.add_child(choice)
		choice.item_selected.connect(func(_index: int) -> void: _store_draft())
	opinion=LineEdit.new(); opinion.max_length=240
	opinion.placeholder_text=Localization.text(&"sharing.opinion_even_before_passing_240_characters"); opinion.set_meta("locale_field",["placeholder_text","sharing.opinion_even_before_passing_240_characters"])
	box.add_child(opinion)
	opinion.text_changed.connect(func(_value: String) -> void: _store_draft())
	var opinion_actions := HBoxContainer.new(); box.add_child(opinion_actions)
	var save_opinion := Button.new(); save_opinion.text=Localization.text(&"sharing.keep_locally"); save_opinion.set_meta("locale_field",["text","sharing.keep_locally"])
	save_opinion.custom_minimum_size.y=40; save_opinion.size_flags_horizontal=Control.SIZE_EXPAND_FILL; opinion_actions.add_child(save_opinion)
	save_opinion.name="KeepFeedbackLocally"
	save_opinion.pressed.connect(_save_opinion)
	var send_opinion := Button.new(); send_opinion.name="SendTaskFeedback"
	send_opinion.text=Localization.text(&"sharing.send_feedback"); send_opinion.set_meta("locale_field",["text","sharing.send_feedback"])
	send_opinion.custom_minimum_size.y=40; send_opinion.size_flags_horizontal=Control.SIZE_EXPAND_FILL; opinion_actions.add_child(send_opinion); send_opinion.pressed.connect(_send_opinion)
	opinion_status=Label.new(); opinion_status.name="OpinionDeliveryStatus"; opinion_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(opinion_status)
	var rating_fold := CheckButton.new(); rating_fold.name="OptionalRatings"; rating_fold.text=Localization.text(&"sharing.optional_ratings"); rating_fold.set_meta("locale_field",["text","sharing.optional_ratings"])
	box.add_child(rating_fold); box.add_child(rating_box)
	rating_fold.toggled.connect(func(value: bool) -> void: rating_box.visible=value)
	var recovery := Button.new(); recovery.name="RecoverFeedbackDrafts"; recovery.visible=drafts_blocked
	recovery.text=Localization.text(&"sharing.recover_drafts"); recovery.set_meta("locale_field",["text","sharing.recover_drafts"])
	box.add_child(recovery)
	recovery.pressed.connect(func() -> void:
		if _recover_drafts(): recovery.hide(); _store_draft(); _remote_updated())
	var remote_fold := CheckButton.new(); remote_fold.text=Localization.text(&"sharing.optional_sharing_and_data_settings"); remote_fold.set_meta("locale_field",["text","sharing.optional_sharing_and_data_settings"])
	box.add_child(remote_fold)
	var remote_box := VBoxContainer.new(); remote_box.hide(); box.add_child(remote_box)
	remote_fold.toggled.connect(func(value: bool) -> void: remote_box.visible=value)
	var remote_info := Label.new(); remote_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	remote_info.text=Localization.text(&"sharing.local_by_default_sharing_uses_a_random_installation_id_no_account_de"); remote_info.set_meta("locale_field",["text","sharing.local_by_default_sharing_uses_a_random_installation_id_no_account_de"])
	remote_box.add_child(remote_info)
	var destination := Label.new(); receiver_label=destination; destination.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	destination.text=Localization.text(&"sharing.receiver")+(RemoteFeedback.endpoint if RemoteFeedback.endpoint_allowed() else Localization.text(&"sharing.not_configured_in_this_build_save_and_export_still_work"))
	remote_box.add_child(destination)
	var local_toggle := CheckButton.new(); local_toggle.text=Localization.text(&"sharing.record_local_play_actions_no_opinion_text"); local_toggle.set_meta("locale_field",["text","sharing.record_local_play_actions_no_opinion_text"]); local_toggle.button_pressed=PlaytestData.telemetry_enabled
	local_toggle.toggled.connect(func(value: bool) -> void: PlaytestData.set_local_recording(value); _save_preferences(value))
	remote_box.add_child(local_toggle)
	remote_toggle=OptionButton.new()
	for label: String in [Localization.text(&"sharing.local_only"),Localization.text(&"sharing.share_basic_statistics_one_summary_per_visit"),Localization.text(&"sharing.detailed_playtest_actions_and_runs")]: remote_toggle.add_item(label)
	remote_toggle.set_meta("locale_items",["sharing.local_only","sharing.share_basic_statistics_one_summary_per_visit","sharing.detailed_playtest_actions_and_runs"])
	remote_toggle.select(["local","basic","detailed"].find(RemoteFeedback.sharing_mode))
	remote_toggle.disabled=not RemoteFeedback.endpoint_allowed()
	remote_toggle.item_selected.connect(func(index: int) -> void: RemoteFeedback.set_sharing_mode(["local","basic","detailed"][index]))
	remote_box.add_child(remote_toggle)
	var tier_help := Label.new(); tier_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	tier_help.text=Localization.text(&"sharing.basic_sharing_starts_at_your_next_task_visit_time_completion_edit_co"); tier_help.set_meta("locale_field",["text","sharing.basic_sharing_starts_at_your_next_task_visit_time_completion_edit_co"])
	remote_box.add_child(tier_help)
	var cohort := OptionButton.new()
	for label: String in [Localization.text(&"sharing.experience_unspecified"),Localization.text(&"sharing.new_to_circuits"),Localization.text(&"sharing.some_experience"),Localization.text(&"sharing.experienced")]: cohort.add_item(label)
	cohort.set_meta("locale_items",["sharing.experience_unspecified","sharing.new_to_circuits","sharing.some_experience","sharing.experienced"])
	var cohorts: Array[String] = ["unspecified","new_to_circuits","some_experience","experienced"]
	cohort.select(maxi(0,cohorts.find(RemoteFeedback.background_cohort)))
	cohort.item_selected.connect(func(index: int) -> void: RemoteFeedback.background_cohort=cohorts[index]; RemoteFeedback._save_state())
	remote_box.add_child(cohort)
	var score_choice := CheckButton.new(); score_toggle=score_choice; score_choice.text=Localization.text(&"sharing.separately_allow_experimental_scores_no_designs"); score_choice.set_meta("locale_field",["text","sharing.separately_allow_experimental_scores_no_designs"])
	score_choice.disabled=not RemoteFeedback.endpoint_allowed(); score_choice.button_pressed=RemoteFeedback.scores_enabled
	score_choice.toggled.connect(func(value: bool) -> void: RemoteFeedback.set_scores_enabled(value))
	remote_box.add_child(score_choice)
	var designs := Label.new(); designs.text=Localization.text(&"sharing.public_designs_unsupported_never_uploaded"); designs.set_meta("locale_field",["text","sharing.public_designs_unsupported_never_uploaded"])
	designs.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; remote_box.add_child(designs)
	var retry := Button.new(); retry.text=Localization.text(&"sharing.retry_pending_records"); retry.set_meta("locale_field",["text","sharing.retry_pending_records"]); remote_box.add_child(retry); retry.disabled=not RemoteFeedback.endpoint_allowed(); retry.pressed.connect(RemoteFeedback.retry_pending)
	var remove := Button.new(); remove.text=Localization.text(&"sharing.stop_sharing_and_request_uploaded_data_deletion"); remove.set_meta("locale_field",["text","sharing.stop_sharing_and_request_uploaded_data_deletion"]); remote_box.add_child(remove); remove.disabled=not RemoteFeedback.endpoint_allowed()
	var confirm := ConfirmationDialog.new(); confirm.name="DeleteUploadsConfirm"; panel.add_child(confirm)
	confirm.ok_button_text=Localization.text(&"common.confirm")
	confirm.cancel_button_text=Localization.text(&"common.cancel")
	confirm.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	confirm.get_label().custom_minimum_size.x=500
	confirm.dialog_text=Localization.text(&"sharing.delete_uploads_for_this_installation_and_clear_its_pending_queue_loc"); confirm.set_meta("locale_field",["dialog_text","sharing.delete_uploads_for_this_installation_and_clear_its_pending_queue_loc"])
	remove.pressed.connect(func() -> void: confirm.popup_centered(Vector2i(540,180)))
	confirm.confirmed.connect(RemoteFeedback.delete_uploaded_data)
	remote_status=Label.new(); remote_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; remote_box.add_child(remote_status)
	RemoteFeedback.status_changed.connect(_remote_updated); _remote_updated()
	moment_box=VBoxContainer.new(); box.add_child(moment_box)
	var moment_heading := Label.new(); moment_heading.text=Localization.text(&"sharing.mark_a_specific_moment_optional"); moment_heading.set_meta("locale_field",["text","sharing.mark_a_specific_moment_optional"]); moment_box.add_child(moment_heading)
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
	entry_buttons=entry_buttons.filter(func(reference: WeakRef) -> bool: return reference.get_ref()!=null)
	entry_buttons.append(weakref(button))
	button.tooltip_text = _t("title")+" · F8"
	button.pressed.connect(toggle)
	return button


func toggle() -> void:
	if panel.visible: close(); return
	var actual: Dictionary = PlaytestData.current_task_context if not PlaytestData.current_task_context.is_empty() else PlaytestData.last_exit_context
	target=PlaytestData.task_feedback_context(str(actual.get("chapter_id","")),str(actual.get("level_id","")))
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
	_store_draft()
	panel.hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	PlaytestData.set_feedback_visible(false,&"moments")
	closed.emit()

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
	for reference: WeakRef in entry_buttons:
		var button: Button = reference.get_ref()
		if button != null:
			button.text=_t("button")
			button.tooltip_text=_t("title")+" · F8"
	_translate(panel)
	exit_reason.set_item_text(0,_t("exit_optional"))
	for index: int in range(1,exit_reason.item_count): exit_reason.set_item_text(index,_t("exit."+str(exit_reason.get_item_metadata(index))))
	for index: int in range(source_selector.item_count): source_selector.set_item_text(index,_t("source."+str(source_selector.get_item_metadata(index))))
	for rating: OptionButton in ratings:
		rating.set_item_text(0,Localization.text(StringName("sharing.rating."+str(rating.get_meta("rating_key"))))+Localization.text(&"sharing.no_rating"))
	receiver_label.text=Localization.text(&"sharing.receiver")+(RemoteFeedback.endpoint if RemoteFeedback.endpoint_allowed() else Localization.text(&"sharing.not_configured_in_this_build_save_and_export_still_work"))
	category.set_item_text(0,Localization.text(&"sharing.category"))
	for index: int in range(1,CATEGORIES.size()): category.set_item_text(index,Localization.text(StringName("sharing.category."+CATEGORIES[index])))
	_refresh_target_label()
	_remote_updated()
	status.text = ""

func _translate(node: Node) -> void:
	if node is ConfirmationDialog:
		# Built-in dialog buttons are internal children, outside the normal walk.
		node.ok_button_text=Localization.text(&"common.confirm")
		node.cancel_button_text=Localization.text(&"common.cancel")
	if node.has_meta("locale_field"):
		var field: Array = node.get_meta("locale_field")
		node.set(field[0],Localization.text(StringName(field[1])))
	if node is OptionButton and node.has_meta("locale_items"):
		var keys: Array = node.get_meta("locale_items")
		for index: int in range(keys.size()): node.set_item_text(index,Localization.text(StringName(keys[index])))
	if node.has_meta("translation"):
		if node is LineEdit: node.placeholder_text = _t(str(node.get_meta("translation")))
		else: node.set("text",_t(str(node.get_meta("translation"))))
	for child: Node in node.get_children(): _translate(child)

func open_for_task(chapter: String, level: String) -> void:
	_store_draft()
	if panel.visible: close()
	toggle()
	target=PlaytestData.task_feedback_context(chapter,level)
	_prepare_target()
func _refresh_target_label() -> void:
	var key: String = str(target.get("chapter_id",""))+"/"+str(target.get("level_id",""))
	var title: String = key
	for task: Dictionary in TaskNavigation.journey_tasks():
		if task.key==key: title=task.title; break
	target_label.text=Localization.text(&"sharing.feedback_for")+title if not target.get("level_id","").is_empty() else Localization.text(&"sharing.enter_a_task_to_rate_it_or_select_one_in_the_task_tree")
func _prepare_target() -> void:
	_refresh_target_label()
	var metadata: Dictionary = target
	context_label.text=Localization.text(&"sharing.attached_context")+" · "+str(metadata.get("build_version","development"))+" · "+str(metadata.get("task_version",""))+" · "+str(metadata.get("source",PlaytestData.source_kind))
	restoring_draft=true
	var draft: Dictionary = drafts.get(_target_key(),{})
	for index: int in ratings.size(): ratings[index].select(int(draft.get("ratings",[0,0,0])[index]))
	opinion.text=str(draft.get("opinion","")); category.select(maxi(0,CATEGORIES.find(str(draft.get("category","")))))
	saved_opinion=draft.get("saved_event",{}).duplicate(true); moment_sequence=-1
	restoring_draft=false
	_remote_updated()
	opinion.caret_column=clampi(int(draft.get("cursor",opinion.text.length())),0,opinion.text.length())
	content_scroll.scroll_vertical=maxi(0,int(draft.get("scroll",0)))
	call_deferred("_restore_draft_scroll",_target_key(),content_scroll.scroll_vertical)
	_update_context_controls()
func _update_context_controls() -> void:
	var current: Dictionary = PlaytestData.current_task_context if not PlaytestData.current_task_context.is_empty() else PlaytestData.last_exit_context
	var matches: bool = not current.is_empty() and current.get("chapter_id","")==target.get("chapter_id","") and current.get("level_id","")==target.get("level_id","")
	moment_box.visible=matches
	exit_reason.visible=matches and PlaytestData.current_task_context.is_empty() and not PlaytestData.last_exit_context.is_empty()
func _save_opinion() -> bool:
	var chapter: String = str(target.get("chapter_id",""))
	var level: String = str(target.get("level_id",""))
	var same: bool = _matches_saved_opinion()
	var saved: bool = same or PlaytestData.submit_level_feedback(StringName(chapter),StringName(level),ratings[0].selected,ratings[1].selected,ratings[2].selected,opinion.text,CATEGORIES[category.selected],target)
	status.text=Localization.text(&"sharing.saved_locally_revisions_are_retained_analysis_uses_the_latest_opinio") if saved else Localization.text(&"sharing.choose_a_task_and_provide_a_rating_or_opinion")
	if saved and not same: saved_opinion=PlaytestData.latest_level_feedback(chapter,level)
	_store_draft(); _remote_updated()
	return saved

func _send_opinion() -> void:
	if not _save_opinion(): return
	var id: String = RemoteFeedback.send_feedback(saved_opinion)
	_remote_updated()
	if id.is_empty(): opinion_status.text=Localization.text(StringName("sharing.state."+RemoteFeedback.status))

func _remote_updated() -> void:
	if is_instance_valid(opinion_status):
		var id: String = RemoteFeedback.feedback_id(saved_opinion) if _matches_saved_opinion() else ""
		var state: String = RemoteFeedback.feedback_state(id) if not id.is_empty() else "draft"
		opinion_status.text=Localization.text(StringName("sharing.state."+state))
		if not id.is_empty(): opinion_status.text += " · "+Localization.text(&"sharing.feedback_id")+id
		if drafts_blocked: opinion_status.text += "\n"+Localization.text(&"sharing.draft_unavailable")
	remote_status.text=Localization.text(StringName("sharing.status."+RemoteFeedback.status))+" · %d " % RemoteFeedback.queue.size()+Localization.text(&"sharing.pending")
	remote_toggle.select(maxi(0,["local","basic","detailed"].find(RemoteFeedback.sharing_mode)))
	if is_instance_valid(score_toggle): score_toggle.set_pressed_no_signal(RemoteFeedback.scores_enabled)
func _save_preferences(value: bool) -> void:
	var config := ConfigFile.new(); config.set_value("privacy","local_actions",value)
	config.save("user://feedback_preferences.cfg")

func _target_key() -> String:
	return str(target.get("chapter_id",""))+"/"+str(target.get("level_id",""))

func _store_draft() -> void:
	if restoring_draft or not is_instance_valid(opinion) or str(target.get("level_id","")).is_empty(): return
	var key: String = _target_key()
	if not drafts.has(key) and drafts.size() >= 64: drafts_blocked=true; return
	var values: Array[int] = []
	for rating: OptionButton in ratings: values.append(rating.selected)
	drafts[key]={"opinion":opinion.text.left(240),"ratings":values,"category":CATEGORIES[category.selected],"saved_event":saved_opinion.duplicate(true),"cursor":opinion.caret_column,"scroll":content_scroll.scroll_vertical}
	_remote_updated()
	if drafts_blocked: return
	var body: String = JSON.stringify({"version":1,"drafts":drafts})
	if body.to_utf8_buffer().size() > DRAFT_BYTES: drafts_blocked=true; return
	var file := FileAccess.open(DRAFT_PATH+".tmp",FileAccess.WRITE)
	if file == null: drafts_blocked=true; return
	file.store_string(body); file.flush(); file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(DRAFT_PATH+".tmp"),ProjectSettings.globalize_path(DRAFT_PATH)) != OK: drafts_blocked=true

func _load_drafts() -> void:
	if not FileAccess.file_exists(DRAFT_PATH): return
	var file := FileAccess.open(DRAFT_PATH,FileAccess.READ)
	if file == null or file.get_length() > DRAFT_BYTES: drafts_blocked=true; return
	var data: Variant = JSON.parse_string(file.get_as_text()); file.close()
	if not data is Dictionary or data.get("version") != 1 or not data.get("drafts") is Dictionary or data.drafts.size() > 64: drafts_blocked=true; return
	for key: Variant in data.drafts:
		var entry: Variant = data.drafts[key]
		if not key is String or key.length() > 130 or key.get_slice_count("/") != 2 or not entry is Dictionary or not entry.get("opinion") is String or entry.opinion.length() > 240 or not entry.get("ratings") is Array or entry.ratings.size() != 3 or entry.get("category") not in CATEGORIES or not entry.get("saved_event") is Dictionary:
			drafts_blocked=true; return
		for rating: Variant in entry.ratings:
			if not (rating is int or rating is float) or int(rating) != rating or rating < 0 or rating > 5: drafts_blocked=true; return
		var event: Dictionary = entry.saved_event
		if not event.is_empty() and (event.get("event") != "level_feedback" or not event.get("session_id") is String or not event.get("sequence") is float and not event.get("sequence") is int or not event.get("payload") is Dictionary or event.payload.get("chapter_id","")+"/"+event.payload.get("level_id","") != key):
			drafts_blocked=true; return
	drafts=data.drafts.duplicate(true)

func _recover_drafts() -> bool:
	if FileAccess.file_exists(DRAFT_PATH):
		var raw: String = FileAccess.get_file_as_string(DRAFT_PATH)
		var backup: String = DRAFT_PATH+".preserved-"+raw.sha256_text()+".json"
		if not FileAccess.file_exists(backup):
			if DirAccess.copy_absolute(ProjectSettings.globalize_path(DRAFT_PATH),ProjectSettings.globalize_path(backup)) != OK: return false
		if FileAccess.get_sha256(backup) != FileAccess.get_sha256(DRAFT_PATH): return false
	drafts_blocked=false
	return true

func _exit_tree() -> void:
	_store_draft()

func _matches_saved_opinion() -> bool:
	var same: bool = not saved_opinion.is_empty()
	var old: Dictionary = saved_opinion.get("payload",{})
	for index: int in ratings.size():
		var value: Variant = ratings[index].selected if ratings[index].selected > 0 else null
		if old.get(["fun","clarity","want_to_continue"][index]) != value: same=false
	if old.get("note","") != opinion.text.strip_edges() or old.get("category","") != CATEGORIES[category.selected]: same=false
	return same

func _restore_draft_scroll(key: String, value: int) -> void:
	if _target_key() == key and is_instance_valid(content_scroll): content_scroll.scroll_vertical=value
