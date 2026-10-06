extends Control

const GameModeSelectorType = preload("res://src/ui/game_mode_selector.gd")
const FullscreenButtonType = preload("res://src/ui/fullscreen_button.gd")
const TerminologyHandbookType = preload("res://src/ui/terminology_handbook.gd")
const UiTypographyType = preload("res://src/ui/ui_typography.gd")

const BACKGROUND := Color("09101d")
const PANEL := Color("172033")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const DANGER := Color("ff6b7d")
const PURPLE := Color("bc8cff")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")

var mode_selector: GameModeSelectorType
var mode_description_label: Label
var fullscreen_button: FullscreenButtonType
var save_actions: Control
var save_recovery_label: Label
var continue_button: Button
var new_game_button: Button
var new_game_overlay: Control
var new_game_clear_workbenches: CheckBox
var new_game_status: Label
var new_game_confirm_button: Button
var system_entry_button: Button
var layout_entry_button: Button
var overlap_entry_button: Button
var locality_entry_button: Button
var terminology_handbook: TerminologyHandbookType
var options_overlay: Control
var options_resume_button: Button
var options_fullscreen_button: Button
var options_export_button: Button
var options_export_status: Label
var options_open_export_folder_button: Button
var latest_export_path: String = ""
var options_quit_button: Button
var options_previous_focus: Control
var candidate_journey: bool = false
var completion_story_page: int = 0
var completion_story_pages: Array[Dictionary] = []
var settings_only: bool = false
var navigation_overlay: Control
var navigation_previous_focus: Control
signal settings_closed


func _ready() -> void:
	candidate_journey = candidate_journey or "--candidate-journey" in OS.get_cmdline_user_args() or preload("res://experiments/candidate_session/context.gd").configured_journey()
	_build_theme()
	if settings_only:
		_build_options_menu()
		WindowMode.window_mode_changed.connect(_on_window_mode_changed)
		_open_options_menu()
		return
	_build_interface()
	call_deferred("_consume_review_intent")
	GameMode.mode_changed.connect(_on_game_mode_changed)
	SystemChapter.progression_changed.connect(_refresh_locality_entry)
	LocalityChapter.progression_changed.connect(_refresh_overlap_entry)
	LocalityChapter.progression_changed.connect(_refresh_layout_entry)
	WindowMode.window_mode_changed.connect(_on_window_mode_changed)
	_refresh_mode_description()
	if WindowMode.reopen_settings:
		WindowMode.reopen_settings=false; call_deferred("_open_options_menu")
	var choice := preload("res://src/playtest/sharing_first_choice.gd").new(); add_child(choice)
	var arguments: PackedStringArray = GameMode.capture_arguments()
	if "--capture-new-game" in arguments:
		call_deferred("_open_new_game_confirmation")
	elif "--capture-options" in arguments:
		call_deferred("_open_options_menu")
	elif "--capture-terminology" in arguments:
		terminology_handbook.call_deferred("open_handbook", &"accumulator")
	elif "--capture-hardware" in arguments:
		get_tree().call_deferred("change_scene_to_file", "res://src/hardware_foundations/hardware_foundations.tscn")
	elif "--capture-system" in arguments or "--capture-system-run" in arguments or "--capture-system-map" in arguments:
		get_tree().call_deferred("change_scene_to_file", "res://src/system_lab/system_lab.tscn")
	elif (
		"--capture-chapter2-map" in arguments
		or "--capture-chapter2-capstone" in arguments
		or "--capture-demo" in arguments
		or "--capture-profiler" in arguments
		or "--capture-workspace" in arguments
		or "--capture-program-draft" in arguments
		or "--capture-row" in arguments
		or "--capture-playtest-export" in arguments
	):
		get_tree().call_deferred("change_scene_to_file", "res://src/ui/main.tscn")


func _input(event: InputEvent) -> void:
	if settings_only and _is_escape_press(event):
		_close_options_menu()
		get_viewport().set_input_as_handled()
		return
	if terminology_handbook != null and terminology_handbook.handle_escape(event):
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_escape_press(event):
		return
	if new_game_overlay != null and new_game_overlay.visible:
		_close_new_game_confirmation()
	elif options_overlay.visible:
		_close_options_menu()
	elif navigation_overlay != null and navigation_overlay.visible:
		_close_hub_navigation()
	else:
		_open_options_menu()
	get_viewport().set_input_as_handled()


func _build_theme() -> void:
	var hub_theme := Theme.new()
	hub_theme.default_font_size = UiTypographyType.BODY_SIZE
	for control_type: String in ["Label", "Button", "OptionButton"]:
		hub_theme.set_color("font_color", control_type, TEXT)
	hub_theme.set_constant("separation", "VBoxContainer", 14)
	hub_theme.set_constant("separation", "HBoxContainer", 18)
	hub_theme.set_stylebox("panel", "PanelContainer", _stylebox(PANEL, 14, 1, Color("293650")))
	hub_theme.set_stylebox("normal", "Button", _stylebox(Color("26334a"), 9, 1, Color("354866")))
	hub_theme.set_stylebox("hover", "Button", _stylebox(Color("30435f"), 9, 2, ACCENT))
	hub_theme.set_stylebox("pressed", "Button", _stylebox(Color("17283e"), 9, 2, ACCENT))
	preload("res://src/ui/instrument_theme.gd").apply_to(hub_theme)
	theme = hub_theme


func _build_interface() -> void:
	var background := preload("res://src/ui/technical_backdrop.gd").new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# The surface is a fixed viewport layout. Only dialogs contain scrollable prose.
	var surface := MarginContainer.new(); surface.name = "HubSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: surface.add_theme_constant_override("margin_"+edge,20)
	add_child(surface)
	var content := VBoxContainer.new(); content.name = "HubContent"
	content.add_theme_constant_override("separation",10); surface.add_child(content)
	_build_hub_header(content)
	_build_tree_entry(content)
	var navigation_content := _build_hub_navigation()
	if candidate_journey:
		var stages := HBoxContainer.new(); stages.name = "CandidateStages"
		stages.add_theme_constant_override("separation",12); navigation_content.add_child(stages)
		for domain: String in ["representation","service","prediction"]:
			var column := VBoxContainer.new(); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			stages.add_child(column)
			match domain:
				"representation": _build_candidate_entry(column)
				"service": _build_service_candidate_entry(column)
				"prediction": _build_prediction_entry(column)
	var cards := HBoxContainer.new(); cards.name = "ChapterCards"
	cards.add_theme_constant_override("separation",12); navigation_content.add_child(cards)
	cards.add_child(_build_card(Localization.text(&"hub.hardware.title"),Localization.text(&"hub.hardware.eyebrow"),Localization.text(&"hub.hardware.description"),Localization.text(&"hub.hardware.play"),GOOD,"res://src/hardware_foundations/hardware_foundations.tscn"))
	cards.add_child(_build_card(Localization.text(&"hub.system.title"),Localization.text(&"hub.system.eyebrow"),Localization.text(&"hub.system.description"),Localization.text(&"hub.system.open"),WARNING,"res://src/system_lab/system_lab.tscn",&"system"))
	cards.add_child(_build_card(Localization.text(&"hub.locality.title"),Localization.text(&"hub.locality.eyebrow"),Localization.text(&"hub.locality.description"),Localization.text(&"hub.locality.open"),ACCENT,"res://src/ui/main.tscn",&"locality"))
	cards.add_child(_build_card(Localization.text(&"overlap.title"),Localization.text(&"overlap.hub.eyebrow"),Localization.text(&"overlap.map_goal"),Localization.text(&"overlap.map"),PURPLE,"res://src/overlap_chapter/overlap_chapter.tscn",&"overlap"))
	cards.add_child(_build_card(Localization.text(&"layout.hub.title"),Localization.text(&"layout.hub.eyebrow"),Localization.text(&"layout.hub.description"),Localization.text(&"layout.hub.open"),Color("f4a6cb"),"res://src/layout_chapter/layout_chapter.tscn",&"layout"))
	_build_hub_footer(navigation_content)
	terminology_handbook = TerminologyHandbookType.new(); terminology_handbook.standalone_entry = false; add_child(terminology_handbook)
	_build_options_menu()
	_build_new_game_confirmation()
	_refresh_save_actions()


func _build_hub_header(content: VBoxContainer) -> void:
	var row := HBoxContainer.new(); row.name = "HubHeader"
	row.add_theme_constant_override("separation",24); content.add_child(row)
	var title := Label.new(); title.text = Localization.text(&"game.title")
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_font_override("font",UiTypographyType.HEADING_FONT)
	title.add_theme_color_override("font_color",Color("bdceda"))
	var brand: Control = preload("res://src/ui/brand_identity.gd").title_slot(Localization.current_locale(),title)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL; brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Optional owner artwork uses the same compact header as the text fallback.
	for texture: TextureRect in brand.find_children("*","TextureRect",true,false):
		texture.custom_minimum_size = Vector2(minf(texture.custom_minimum_size.x,300),40)
	row.add_child(brand)
	var actions := HBoxContainer.new(); actions.name = "HeaderActions"
	actions.add_theme_constant_override("separation",10); row.add_child(actions)
	mode_selector = GameModeSelectorType.new(); mode_selector.name = "GameModeSelector"; mode_selector.show_label = false
	actions.add_child(mode_selector)
	mode_description_label = Label.new(); mode_description_label.hide(); content.add_child(mode_description_label)
	var language := OptionButton.new(); language.name = "HubLanguageChoice"
	language.custom_minimum_size = Vector2(150,42)
	language.add_item("简体中文"); language.add_item("English")
	language.select(0 if Localization.current_locale() == "zh_CN" else 1)
	language.item_selected.connect(func(index: int) -> void:
		if Localization.set_preferred_locale(["zh_CN","en"][index]): WindowMode.call_deferred("reload_localized_scene",false,false))
	actions.add_child(language)
	var settings := Button.new(); settings.name = "HubSettings"
	settings.text = "设置" if Localization.current_locale() != "en" else "Settings"
	settings.tooltip_text = Localization.text(&"hub.settings.settings_esc")
	settings.custom_minimum_size = Vector2(100,42); settings.pressed.connect(_open_options_menu); actions.add_child(settings)
	fullscreen_button = FullscreenButtonType.new(); actions.add_child(fullscreen_button)
	fullscreen_button.custom_minimum_size.y = 42


func _build_tree_entry(content: VBoxContainer) -> void:
	var panel := PanelContainer.new(); panel.name = "TaskTreeEntry"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame: StyleBoxFlat = InstrumentTheme.surface(Color("0e202d"),Color("365463"),10)
	frame.content_margin_left = 24; frame.content_margin_right = 24
	frame.content_margin_top = 16; frame.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel",frame); content.add_child(panel)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",28); panel.add_child(row)
	var primary := VBoxContainer.new(); primary.name = "HubMainAction"
	primary.add_theme_constant_override("separation",8)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL; primary.size_flags_stretch_ratio = 1.45
	primary.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(primary)
	var heading := Label.new(); heading.text = "你的旅程" if Localization.current_locale() != "en" else "Your journey"
	heading.add_theme_font_size_override("font_size",30); heading.add_theme_font_override("font",UiTypographyType.HEADING_FONT)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; primary.add_child(heading)
	var description := Label.new(); description.text = "构造机器，看清等待，再改变安排。" if Localization.current_locale() != "en" else "Build, measure, and change the arrangement."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color",MUTED); primary.add_child(description)
	if candidate_journey: _build_completion_route(primary)
	var button := Button.new(); button.name = "TaskTree"
	button.text = ("核心任务树" if Localization.current_locale() != "en" else "Core task tree") if candidate_journey else ("开始旅程" if Localization.current_locale() != "en" else "Start journey")
	button.custom_minimum_size.y = 48 if not candidate_journey else 42
	button.pressed.connect(func() -> void:
		if not candidate_journey and not GlobalSave.continue_scene_path().is_empty(): _continue_game()
		else: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE))
	if not candidate_journey:
		InstrumentTheme.primary(button); button.add_theme_color_override("font_focus_color",Color("071823")); primary.add_child(button)
	var secondary := HBoxContainer.new(); secondary.name = "HubSecondaryActions"
	secondary.add_theme_constant_override("separation",10); primary.add_child(secondary); secondary.hide()
	if candidate_journey: secondary.add_child(button)
	_build_save_actions(secondary)
	var browse := Button.new(); browse.name = "HubBrowseJourney"
	browse.text = "选择旅程" if Localization.current_locale() != "en" else "Choose a journey"
	browse.custom_minimum_size.y = 42; browse.pressed.connect(_open_hub_navigation); primary.add_child(browse)
	var recovery := HBoxContainer.new(); recovery.name = "HubRecovery"
	recovery.add_theme_constant_override("separation",10); primary.add_child(recovery)
	save_recovery_label = Label.new(); save_recovery_label.name = "SaveRecoveryNotice"
	save_recovery_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_recovery_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	save_recovery_label.add_theme_font_size_override("font_size",14); recovery.add_child(save_recovery_label)
	var details := Button.new(); details.name = "SaveRecoveryDetails"
	details.text = "查看详情" if Localization.current_locale() != "en" else "View notice"
	details.custom_minimum_size.y = 42; details.pressed.connect(_show_recovery_notice); recovery.add_child(details)
	var illustration := VBoxContainer.new(); illustration.name = "HubMachine"
	illustration.custom_minimum_size.x = 300; illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illustration.add_theme_constant_override("separation",8); row.add_child(illustration)
	var art := preload("res://src/ui/hub_machine_art.gd").new()
	art.name = "HubMachineArt"; art.size_flags_vertical = Control.SIZE_EXPAND_FILL; illustration.add_child(art)
	var opening := Label.new(); opening.text = Localization.text(&"theme.opening")
	opening.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opening.add_theme_font_size_override("font_size",14); opening.add_theme_color_override("font_color",MUTED)
	illustration.add_child(opening)
	call_deferred("_focus_tree_entry",button)


func _build_hub_navigation() -> VBoxContainer:
	navigation_overlay = Control.new(); navigation_overlay.name = "HubNavigation"
	navigation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	navigation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP; navigation_overlay.z_index = 800
	add_child(navigation_overlay)
	var background := ColorRect.new(); background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); navigation_overlay.add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,20)
	navigation_overlay.add_child(margin)
	var content := VBoxContainer.new(); content.name = "HubNavigationContent"
	content.add_theme_constant_override("separation",16); margin.add_child(content)
	var header := HBoxContainer.new(); content.add_child(header)
	var title := Label.new(); title.text = "选择旅程" if Localization.current_locale() != "en" else "Choose a journey"
	title.add_theme_font_size_override("font_size",30); title.add_theme_font_override("font",UiTypographyType.HEADING_FONT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	var close := Button.new(); close.name = "HubNavigationClose"
	close.text = "返回 · Esc" if Localization.current_locale() != "en" else "Back · Esc"
	close.custom_minimum_size = Vector2(132,42); close.pressed.connect(_close_hub_navigation); header.add_child(close)
	var core := PanelContainer.new(); core.name = "HubNavigationCore"
	core.add_theme_stylebox_override("panel",InstrumentTheme.surface(Color("101e2b"),Color("365463"),8)); content.add_child(core)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",16); core.add_child(row)
	var label := Label.new(); label.text = "核心旅程" if Localization.current_locale() != "en" else "Core journey"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size",18); row.add_child(label)
	var secondary := find_child("HubSecondaryActions",true,false) as HBoxContainer
	secondary.reparent(row); secondary.show()
	if not candidate_journey:
		var tree := Button.new(); tree.name = "HubCoreTreeEntry"
		tree.text = "核心任务树" if Localization.current_locale() != "en" else "Core task tree"
		tree.custom_minimum_size.y = 42
		tree.pressed.connect(func() -> void: get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE))
		secondary.add_child(tree); secondary.move_child(tree,0)
	navigation_overlay.hide()
	return content


func _open_hub_navigation() -> void:
	if navigation_overlay == null or navigation_overlay.visible: return
	navigation_previous_focus = get_viewport().gui_get_focus_owner()
	(get_node("HubSurface") as Control).hide()
	navigation_overlay.show()
	(navigation_overlay.find_child("HubNavigationClose",true,false) as Button).grab_focus()


func _close_hub_navigation() -> void:
	if navigation_overlay == null or not navigation_overlay.visible: return
	navigation_overlay.hide()
	(get_node("HubSurface") as Control).show()
	if is_instance_valid(navigation_previous_focus) and navigation_previous_focus.is_visible_in_tree(): navigation_previous_focus.grab_focus()
	else: (find_child("HubBrowseJourney",true,false) as Button).grab_focus()
	navigation_previous_focus = null


func _focus_tree_entry(button: Button) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(button) or options_overlay.visible or new_game_overlay.visible or (navigation_overlay != null and navigation_overlay.visible): return
	var recommended := find_child("RecommendedJourneyAction",true,false) as Button
	if candidate_journey and recommended != null: recommended.grab_focus()
	else: button.grab_focus()


func _build_save_actions(content: BoxContainer) -> void:
	var row := HBoxContainer.new(); row.name = "SaveActions"
	row.add_theme_constant_override("separation",10); content.add_child(row); save_actions = row
	continue_button = Button.new(); continue_button.name = "ContinueButton"
	continue_button.text = Localization.text(&"hub.save.continue")
	continue_button.custom_minimum_size = Vector2(132,42); continue_button.pressed.connect(_continue_game); row.add_child(continue_button)
	new_game_button = Button.new(); new_game_button.name = "NewGameButton"
	new_game_button.text = Localization.text(&"hub.save.new_game")
	new_game_button.custom_minimum_size = Vector2(132,42); new_game_button.pressed.connect(_open_new_game_confirmation); row.add_child(new_game_button)


func _build_hub_footer(content: VBoxContainer) -> void:
	var row := HBoxContainer.new(); row.name = "HubFooter"
	row.add_theme_constant_override("separation",10); content.add_child(row)
	var english: bool = Localization.current_locale() == "en"
	var reflection := Button.new(); reflection.name = "ThemeReflectionButton"
	reflection.text = "核心成果" if not english else "Core achievements"
	reflection.custom_minimum_size.y = 42; reflection.pressed.connect(_open_theme_reflection); row.add_child(reflection)
	if candidate_journey:
		var story := Button.new(); story.name = "CompletionStory"
		story.text = "旅程回顾" if not english else "Journey review"
		story.custom_minimum_size.y = 42; story.pressed.connect(show_completion_story); row.add_child(story)
		var evidence := Button.new(); evidence.name = "SavedSecondActReview"
		evidence.text = "已保存成果明细" if not english else "Saved evidence"
		evidence.custom_minimum_size.y = 42; evidence.pressed.connect(show_candidate_review); row.add_child(evidence)
		var route := Button.new(); route.name = "RecommendedJourneyInfo"
		route.text = "旅程说明" if not english else "Route details"
		route.custom_minimum_size.y = 42; route.pressed.connect(_show_route_info); row.add_child(route)
	var handbook := Button.new(); handbook.name = "HubTerminologyButton"
	handbook.text = Localization.text(&"terminology.button")
	handbook.custom_minimum_size.y = 42
	handbook.pressed.connect(func() -> void: terminology_handbook.open_handbook())
	row.add_child(handbook)
	var note := Label.new(); note.name = "BuildIdentifier"
	note.text = ("内部评审 · " if not english else "Internal review · ") if candidate_journey else ""
	note.text += String(ProjectSettings.get_setting("application/config/version",""))
	note.add_theme_font_size_override("font_size",14); note.add_theme_color_override("font_color",MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(note)


func _show_recovery_notice() -> void:
	if GlobalSave.recovery_notice.is_empty(): return
	var old := get_node_or_null("SaveRecoveryReview")
	if old != null: remove_child(old); old.queue_free()
	var dialog := AcceptDialog.new(); dialog.name = "SaveRecoveryReview"
	dialog.title = "存档提示" if Localization.current_locale() != "en" else "Save notice"
	dialog.dialog_text = Localization.text(GlobalSave.recovery_notice)
	if not GlobalSave.recovery_details.is_empty(): dialog.dialog_text += "\n\n"+GlobalSave.recovery_details
	dialog.dialog_autowrap = true; dialog.get_label().custom_minimum_size.x = 540
	add_child(dialog); dialog.popup_centered(Vector2i(580,240))


func _show_route_info() -> void:
	var old := get_node_or_null("RecommendedJourneyInfoReview")
	if old != null: remove_child(old); old.queue_free()
	var english: bool = Localization.current_locale() == "en"
	var dialog := AcceptDialog.new(); dialog.name = "RecommendedJourneyInfoReview"
	dialog.title = "旅程说明" if not english else "Route details"
	dialog.dialog_text = "造出机器 → 看见等待 → 局部性 → 时序与位置（两路并行）→ 核心收束 → 表示 → 服务 → 扩展收束。\n\n推荐顺序不增加解锁条件。应用支线、预测与追加委托可选。核心、表示、服务分别保存；预测仅保留本次会话。" if not english else "Build a machine → Discover waiting → Locality → Timing and placement (parallel paths) → Core ending → Representation → Service → Extended ending.\n\nRecommendations add no prerequisites. Applications, Prediction and commissions are optional. Core, Representation and Service save independently; Prediction lasts for this session."
	if candidate_review_paths().is_empty(): dialog.dialog_text += "\n\n当前启动未绑定候选存档；第二幕默认仅本次会话。使用命名候选包才能确认保存与继续。" if not english else "\n\nThis launch is not bound to a candidate profile; second-act work is session-only by default. Use a named candidate package to confirm saved continuation."
	dialog.dialog_autowrap = true; dialog.get_label().custom_minimum_size.x = 580
	add_child(dialog); dialog.popup_centered(Vector2i(620,310))


func _build_new_game_confirmation() -> void:
	new_game_overlay = Control.new()
	new_game_overlay.name = "NewGameConfirmationOverlay"
	new_game_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	new_game_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	new_game_overlay.z_index = 1200
	add_child(new_game_overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color("050a12", 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	new_game_overlay.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_game_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "NewGameConfirmationPanel"
	panel.custom_minimum_size = Vector2(660.0, 390.0)
	panel.add_theme_stylebox_override("panel", _stylebox(PANEL, 16, 2, DANGER))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.text = Localization.text(&"hub.save.new_game.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	title.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
	title.add_theme_color_override("font_color", DANGER)
	column.add_child(title)
	var body := Label.new()
	body.text = Localization.text(&"hub.save.new_game.body")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", MUTED)
	column.add_child(body)
	new_game_clear_workbenches = CheckBox.new()
	new_game_clear_workbenches.name = "ClearGameWorkbenchesCheckBox"
	new_game_clear_workbenches.text = Localization.text(&"hub.save.new_game.clear_workbenches")
	column.add_child(new_game_clear_workbenches)
	new_game_status = Label.new()
	new_game_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_game_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_game_status.add_theme_color_override("font_color", DANGER)
	column.add_child(new_game_status)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(actions)
	var cancel := Button.new()
	cancel.name = "NewGameCancelButton"
	cancel.text = Localization.text(&"hub.save.new_game.cancel")
	cancel.custom_minimum_size = Vector2(210.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	cancel.pressed.connect(_close_new_game_confirmation)
	actions.add_child(cancel)
	new_game_confirm_button = Button.new()
	new_game_confirm_button.name = "NewGameConfirmButton"
	new_game_confirm_button.text = Localization.text(&"hub.save.new_game.confirm")
	new_game_confirm_button.custom_minimum_size = Vector2(210.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	new_game_confirm_button.add_theme_color_override("font_color", DANGER)
	new_game_confirm_button.pressed.connect(_confirm_new_game)
	actions.add_child(new_game_confirm_button)
	new_game_overlay.hide()


func _build_options_menu() -> void:
	options_overlay=Control.new(); options_overlay.name="ChapterOptionsOverlay"
	options_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_overlay.mouse_filter=Control.MOUSE_FILTER_STOP; options_overlay.z_index=1100; add_child(options_overlay)
	var backdrop := ColorRect.new(); backdrop.color=Color("050a12",0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); options_overlay.add_child(backdrop)
	var panel := preload("res://src/ui/movable_dialog_panel.gd").new(); panel.name="ChapterOptionsPanel"
	panel.add_theme_stylebox_override("panel",InstrumentTheme.panel(PANEL,ACCENT,8)); options_overlay.add_child(panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",14); panel.add_child(column)
	_settings_label(column,"hub.options.title",28)
	panel.setup(column.get_child(0), Vector2(760, 780))
	var scroll := ScrollContainer.new(); scroll.name="SettingsScroll"; scroll.follow_focus=true
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	var body := VBoxContainer.new(); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12); scroll.add_child(body)
	_settings_label(body,"settings.interface",23)
	var language := OptionButton.new(); language.name="LanguageChoice"
	language.add_item("简体中文"); language.add_item("English")
	language.select(0 if Localization.current_locale()=="zh_CN" else 1)
	language.item_selected.connect(func(index: int) -> void:
		if Localization.set_preferred_locale(["zh_CN","en"][index]): call_deferred("_reload_settings_locale"))
	body.add_child(language)
	_settings_label(body,"settings.display",23)
	options_fullscreen_button=_options_button(""); options_fullscreen_button.name="OptionsFullscreenButton"
	options_fullscreen_button.pressed.connect(WindowMode.toggle_fullscreen); body.add_child(options_fullscreen_button)
	var reduced := CheckButton.new(); reduced.name="ReducedMotion"
	reduced.text=Localization.text(&"hub.settings.reduce_interface_motion")
	reduced.button_pressed=bool(ProjectSettings.get_setting("game/reduced_motion",false))
	reduced.toggled.connect(WindowMode.set_reduced_motion); body.add_child(reduced)
	var frame_choice := OptionButton.new(); frame_choice.name="FrameLimit"
	for key: String in ["60","120","display"]: frame_choice.add_item(Localization.text(StringName("hub.settings.frame_"+key)))
	frame_choice.select(maxi(0,[60,120,0].find(WindowMode.frame_limit)))
	frame_choice.item_selected.connect(func(index: int) -> void: WindowMode.set_frame_limit([60,120,0][index]))
	body.add_child(frame_choice)
	_settings_label(body,"hub.settings.background_rendering_uses_less_power_simulation_scores_are_unchan")
	_settings_label(body,"settings.audio",23)
	var sound := CheckButton.new(); sound.name="SoundEnabled"; sound.text=Localization.text(&"settings.sound")
	sound.button_pressed=WindowMode.sound_enabled; body.add_child(sound)
	var volume := HSlider.new(); volume.name="SoundVolume"; volume.max_value=100; volume.step=1
	volume.value=roundf(WindowMode.sound_volume*100); volume.custom_minimum_size.y=32
	volume.editable=WindowMode.sound_enabled; body.add_child(volume)
	var volume_label := Label.new(); volume_label.text="%d%%" % volume.value; body.add_child(volume_label)
	sound.toggled.connect(func(value: bool) -> void: WindowMode.set_sound(value,volume.value/100); volume.editable=value)
	volume.value_changed.connect(func(value: float) -> void: WindowMode.set_sound(sound.button_pressed,value/100); volume_label.text="%d%%" % value)
	var ambience := CheckButton.new(); ambience.name="AmbienceEnabled"
	ambience.text=Localization.text(&"settings.ambience")
	ambience.button_pressed=WindowMode.ambience_enabled; body.add_child(ambience)
	var ambience_volume := HSlider.new(); ambience_volume.name="AmbienceVolume"
	ambience_volume.max_value=100; ambience_volume.step=1; ambience_volume.value=WindowMode.ambience_volume*100
	ambience_volume.custom_minimum_size.y=32; body.add_child(ambience_volume)
	var ambience_percent := Label.new(); ambience_percent.text="%d%%" % ambience_volume.value; body.add_child(ambience_percent)
	var steady := CheckButton.new(); steady.name="AmbienceReducedDynamics"
	steady.text=Localization.text(&"settings.ambience.steady")
	steady.button_pressed=WindowMode.ambience_reduced_dynamics; body.add_child(steady)
	var update_ambience := func() -> void: WindowMode.set_ambience(ambience.button_pressed,ambience_volume.value/100,steady.button_pressed)
	ambience.toggled.connect(func(_value: bool) -> void: update_ambience.call())
	ambience_volume.value_changed.connect(func(value: float) -> void: update_ambience.call(); ambience_percent.text="%d%%" % value)
	steady.toggled.connect(func(_value: bool) -> void: update_ambience.call())
	_settings_label(body,"settings.ambience.help")
	_settings_label(body,"settings.privacy",23)
	_settings_label(body,"settings.privacy_hint")
	body.add_child(PlaytestMoments.make_button())
	_settings_label(body,"settings.support",23)
	var build := Label.new(); build.text=str(ProjectSettings.get_setting("application/config/version",""))
	build.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(build)
	options_export_button=_options_button(Localization.text(&"playtest.export.button")); options_export_button.name="OptionsExportPlaytestButton"
	options_export_button.pressed.connect(_export_playtest_data); body.add_child(options_export_button)
	var diagnostics := _options_button(Localization.text(&"settings.diagnostics")); diagnostics.name="ExportDiagnostics"
	diagnostics.pressed.connect(func() -> void:
		latest_export_path=preload("res://src/ui/support_diagnostics.gd").export_local()
		options_export_status.text=Localization.text(&"settings.export_failed" if latest_export_path.is_empty() else &"settings.export_ready")
		options_open_export_folder_button.visible=not latest_export_path.is_empty())
	body.add_child(diagnostics)
	_settings_label(body,"settings.diagnostics_hint")
	var logs := _options_button(Localization.text(&"settings.open_logs")); body.add_child(logs)
	logs.pressed.connect(func() -> void: OS.shell_open(ProjectSettings.globalize_path("user://")))
	options_export_status=Label.new(); options_export_status.name="OptionsExportStatus"
	options_export_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_child(options_export_status)
	options_open_export_folder_button=_options_button(Localization.text(&"playtest.export.open_folder"))
	options_open_export_folder_button.pressed.connect(_open_latest_export_folder)
	options_open_export_folder_button.hide(); body.add_child(options_open_export_folder_button)
	options_open_export_folder_button.visibility_changed.connect(_refresh_settings_focus)
	var reset := _options_button(Localization.text(&"settings.reset")); reset.name="ResetPresentation"; body.add_child(reset)
	var confirm := ConfirmationDialog.new(); confirm.name="ResetPresentationConfirm"
	confirm.title=Localization.text(&"settings.reset"); confirm.dialog_text=Localization.text(&"settings.reset_hint")
	confirm.ok_button_text=Localization.text(&"common.confirm")
	confirm.cancel_button_text=Localization.text(&"common.cancel")
	confirm.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; confirm.get_label().custom_minimum_size.x=480
	add_child(confirm)
	reset.pressed.connect(func() -> void: confirm.popup_centered(Vector2i(520,180)))
	confirm.confirmed.connect(func() -> void: WindowMode.reset_presentation(); call_deferred("_reload_settings_locale"))
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation",14); column.add_child(footer)
	options_resume_button=_options_button(Localization.text(&"hub.options.resume")); options_resume_button.name="OptionsResumeButton"
	options_resume_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	options_resume_button.pressed.connect(_close_options_menu); footer.add_child(options_resume_button)
	options_quit_button=_options_button(Localization.text(&"hub.options.quit")); options_quit_button.name="OptionsQuitButton"
	options_quit_button.pressed.connect(_quit_game); footer.add_child(options_quit_button)
	resized.connect(_fit_settings_panel); _fit_settings_panel()
	_refresh_options_fullscreen_label(); options_overlay.hide()

func _settings_label(parent: Node, key: String, font_size: int=18) -> void:
	var label := Label.new(); label.text=Localization.text(StringName(key))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",ACCENT if font_size>=23 else TEXT); parent.add_child(label)

func _fit_settings_panel() -> void:
	var panel: Control = options_overlay.find_child("ChapterOptionsPanel",true,false)
	panel.call("fit_to_bounds")

func _reload_settings_locale() -> void:
	WindowMode.reload_localized_scene(settings_only)


func _options_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = UiTypographyType.TOOL_BUTTON_HEIGHT
	button.add_theme_font_size_override("font_size", UiTypographyType.BUTTON_SIZE)
	return button


func _open_options_menu() -> void:
	if options_overlay == null or options_overlay.visible or (new_game_overlay != null and new_game_overlay.visible):
		return
	options_previous_focus = get_viewport().gui_get_focus_owner()
	_refresh_options_fullscreen_label()
	options_overlay.show()
	_refresh_settings_focus()
	options_resume_button.grab_focus()


func _refresh_settings_focus() -> void:
	if not is_instance_valid(options_overlay) or not options_overlay.is_visible_in_tree(): return
	var controls: Array[Control] = []
	for node: Node in options_overlay.find_children("*","Control",true,false):
		if node.focus_mode==Control.FOCUS_ALL and node.is_visible_in_tree(): controls.append(node)
	for index: int in range(controls.size()):
		controls[index].focus_next=controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous=controls[index].get_path_to(controls[(index-1+controls.size())%controls.size()])


func _close_options_menu() -> void:
	if options_overlay == null or not options_overlay.visible:
		return
	options_overlay.hide()
	options_resume_button.release_focus()
	if is_instance_valid(options_previous_focus) and options_previous_focus.is_visible_in_tree():
		options_previous_focus.grab_focus()
	options_previous_focus = null
	if settings_only: settings_closed.emit()


func _quit_game() -> void:
	GlobalSave.request_quit()


func _continue_game() -> void:
	TaskNavigation.prepare_continue()
	var scene_path: String = GlobalSave.continue_scene_path()
	if not scene_path.is_empty():
		get_tree().change_scene_to_file(scene_path)


func _open_new_game_confirmation() -> void:
	if new_game_overlay == null or new_game_overlay.visible:
		return
	new_game_status.text = ""
	new_game_clear_workbenches.button_pressed = false
	new_game_overlay.show()
	new_game_confirm_button.grab_focus()


func _close_new_game_confirmation() -> void:
	if new_game_overlay == null or not new_game_overlay.visible:
		return
	new_game_overlay.hide()
	new_game_confirm_button.release_focus()
	if new_game_button != null:
		new_game_button.grab_focus()


func _confirm_new_game() -> void:
	var result: Dictionary = GlobalSave.start_new_game(new_game_clear_workbenches.button_pressed)
	_refresh_save_actions()
	if not bool(result.get("ok", false)):
		new_game_status.text = Localization.text(&"hub.save.new_game.error", [String(result.get("error", ""))])
		return
	get_tree().change_scene_to_file("res://src/hardware_foundations/hardware_foundations.tscn")


func _export_playtest_data() -> void:
	var export_path: String = PlaytestData.export_current_session()
	latest_export_path = export_path
	if export_path.is_empty():
		options_export_status.text = Localization.text(&"playtest.export.failed", [PlaytestData.last_error])
		options_export_status.add_theme_color_override("font_color", DANGER)
		options_open_export_folder_button.hide()
	else:
		options_export_status.text = Localization.text(&"playtest.export.success", [export_path])
		options_export_status.add_theme_color_override("font_color", GOOD)
		options_open_export_folder_button.show()


func _open_latest_export_folder() -> void:
	if not latest_export_path.is_empty():
		OS.shell_show_in_file_manager(latest_export_path)


func _on_window_mode_changed(_fullscreen: bool) -> void:
	_refresh_options_fullscreen_label()


func _refresh_options_fullscreen_label() -> void:
	if options_fullscreen_button == null:
		return
	options_fullscreen_button.text = Localization.text(
		&"window.fullscreen.exit" if WindowMode.is_fullscreen() else &"window.fullscreen.enter"
	)


func _is_escape_press(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	return key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE


func _on_game_mode_changed(_mode: StringName) -> void:
	_refresh_overlap_entry()
	_refresh_mode_description()
	_refresh_save_actions()
	_refresh_system_entry()
	_refresh_locality_entry()


func _refresh_save_actions() -> void:
	if save_recovery_label != null:
		var has_notice: bool = not GameMode.is_test_mode() and not GlobalSave.recovery_notice.is_empty()
		save_recovery_label.get_parent().visible = has_notice
		save_recovery_label.visible = has_notice
		var english: bool = Localization.current_locale() == "en"
		var notices: Dictionary = {
			&"save.recovery.complete": ["存档恢复已完成", "Save recovery complete"],
			&"save.recovery.partial": ["部分成果未能恢复 · 查看详情", "Some work could not be restored"],
			&"save.recovery.failed": ["恢复未完成 · 自动保存已暂停", "Recovery incomplete · autosave paused"],
			&"save.recovery.newer": ["需新版打开 · 当前禁止写入", "Newer game required · writing disabled"]
		}
		save_recovery_label.text = notices.get(GlobalSave.recovery_notice,["存档提示", "Save notice"])[1 if english else 0]
		save_recovery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		save_recovery_label.tooltip_text = Localization.text(GlobalSave.recovery_notice)+"\n"+GlobalSave.recovery_details if has_notice else ""
		save_recovery_label.mouse_filter = Control.MOUSE_FILTER_PASS
		save_recovery_label.add_theme_color_override("font_color", GOOD if GlobalSave.recovery_notice == &"save.recovery.complete" else WARNING)
	if save_actions == null: return
	save_actions.visible = not GameMode.is_test_mode()
	if continue_button == null: return
	var can_continue: bool = not GlobalSave.continue_scene_path().is_empty()
	if not candidate_journey:
		var primary := find_child("TaskTree",true,false) as Button
		if primary != null: primary.text = ("继续旅程" if Localization.current_locale() != "en" else "Continue journey") if can_continue else ("开始旅程" if Localization.current_locale() != "en" else "Start journey")
	continue_button.disabled = not can_continue
	continue_button.tooltip_text = "" if can_continue else Localization.text(&"hub.save.continue_unavailable")


func _refresh_mode_description() -> void:
	if mode_description_label == null:
		return
	mode_description_label.text = Localization.text(
		&"mode.test.description" if GameMode.is_test_mode() else &"mode.game.description"
	)
	mode_description_label.add_theme_color_override(
		"font_color", WARNING if GameMode.is_test_mode() else MUTED
	)


func _build_card(title: String, eyebrow: String, description: String, button_text: String, color: Color, scene_path: String, entry_id: StringName = &"") -> Control:
	var english: bool = Localization.current_locale() == "en"
	var chapter: String = "hardware" if entry_id.is_empty() else String(entry_id)
	var captions: Dictionary = {
		"hardware": ["序章 · 造出机器", "Prologue · Construction", "信号成为计算", "Make a machine"],
		"system": ["第一章 · 系统", "1 · System", "看见等待", "Find the waiting"],
		"locality": ["第二章 · 局部性", "2 · Locality", "复用每次搬运", "Reuse each fetch"],
		"overlap": ["第三章 · 时序", "3 · Timing", "让工作重叠", "Overlap the work"],
		"layout": ["第四章 · 位置", "4 · Placement", "改变数据安排", "Arrange the data"]
	}
	var panel := PanelContainer.new(); panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.tooltip_text = title+"\n"+eyebrow+"\n"+description
	panel.add_theme_stylebox_override("panel",InstrumentTheme.surface(Color("101e2b"),Color(color,0.4),8))
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",4); panel.add_child(column)
	var index := Label.new(); index.text = captions[chapter][1 if english else 0]
	index.add_theme_font_size_override("font_size",14); index.add_theme_color_override("font_color",color)
	index.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(index)
	var headline := Label.new(); headline.text = captions[chapter][3 if english else 2]
	headline.add_theme_font_size_override("font_size",18); headline.add_theme_font_override("font",UiTypographyType.HEADING_FONT)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(headline)
	var button := Button.new(); button.name = "ChapterEntry_"+String(entry_id)
	button.text = button_text; button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 42; button.pressed.connect(_open_chapter.bind(scene_path)); column.add_child(button)
	match entry_id:
		&"system": system_entry_button = button; _refresh_system_entry()
		&"locality": locality_entry_button = button; _refresh_locality_entry()
		&"overlap": overlap_entry_button = button; _refresh_overlap_entry()
		&"layout": layout_entry_button = button; _refresh_layout_entry()
	return panel

func _refresh_layout_entry() -> void:
	if layout_entry_button == null: return
	layout_entry_button.disabled=not LayoutChapter.chapter_unlocked()
	layout_entry_button.text=Localization.text(&"layout.hub.open") if not layout_entry_button.disabled else ("完成第二章综合任务" if Localization.current_locale() != "en" else "Complete Chapter 2 capstone")
	layout_entry_button.tooltip_text = Localization.text(&"layout.hub.description") if not layout_entry_button.disabled else layout_entry_button.text

func _refresh_overlap_entry() -> void:
	if overlap_entry_button == null: return
	overlap_entry_button.disabled = not OverlapChapter.chapter_unlocked()
	overlap_entry_button.text = Localization.text(&"overlap.map") if not overlap_entry_button.disabled else ("完成第二章综合任务" if Localization.current_locale() != "en" else "Complete Chapter 2 capstone")
	overlap_entry_button.tooltip_text = Localization.text(&"overlap.map_goal") if not overlap_entry_button.disabled else overlap_entry_button.text


func _refresh_system_entry() -> void:
	if system_entry_button == null:
		return
	var unlocked: bool = GameMode.is_test_mode() or SystemChapter.prologue_ready
	system_entry_button.disabled = not unlocked
	system_entry_button.text = Localization.text(&"hub.system.open") if unlocked else Localization.text(&"hub.system.locked_action")
	system_entry_button.tooltip_text = "" if unlocked else Localization.text(&"hub.system.locked")


func _refresh_locality_entry() -> void:
	if locality_entry_button == null:
		return
	var unlocked: bool = LocalityChapter.chapter_unlocked()
	locality_entry_button.disabled = not unlocked
	locality_entry_button.text = Localization.text(&"hub.locality.open") if unlocked else Localization.text(&"hub.locality.locked_action")
	locality_entry_button.tooltip_text = "" if unlocked else Localization.text(&"hub.locality.locked")


func _stylebox(color: Color, radius: int, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.border_color = border_color
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	box.content_margin_top = 14.0
	box.content_margin_bottom = 14.0
	return box


func _open_chapter(scene_path: String) -> void:
	# A chapter card starts a fresh navigation route, independent of the last
	# task entered from the global tree. Progress and Continue stay untouched.
	TaskNavigation.from_tree = false
	TaskNavigation.pending = ""
	get_tree().change_scene_to_file(scene_path)


func _open_theme_reflection() -> void:
	if get_node_or_null("ThemeReflection") != null: return
	var reflection = preload("res://src/ui/theme_reflection.gd").new()
	var keys: Array[StringName] = _core_reflection_keys()
	reflection.configure(keys,Localization.text)
	if candidate_journey and &"theme.ending" in keys:
		var next: Button = reflection.add_button("下一段：改变承载" if Localization.current_locale() != "en" else "Next: a different representation", false, "representation")
		next.name = "CoreToRepresentation"
		reflection.custom_action.connect(func(action: StringName) -> void:
			if action == &"representation":
				reflection.hide(); reflection.queue_free(); _show_completion_bridge())
	add_child(reflection)
	reflection.popup_centered(Vector2i(640,500))


func _candidate_stage(content: VBoxContainer, node_name: String, heading: String, accent: Color, entry_name: String, caption: String, scene_path: String, details: String) -> void:
	var panel := PanelContainer.new(); panel.name = node_name; panel.tooltip_text = details
	panel.add_theme_stylebox_override("panel",InstrumentTheme.surface(Color("101e2b"),Color(accent,0.35),8)); content.add_child(panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",6); panel.add_child(column)
	var title := Label.new(); title.text = heading; title.add_theme_font_size_override("font_size",18)
	title.add_theme_font_override("font",UiTypographyType.HEADING_FONT); title.add_theme_color_override("font_color",accent)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(title)
	var entry := Button.new(); entry.name = entry_name; entry.text = caption; entry.custom_minimum_size.y = 42
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; entry.tooltip_text = details; column.add_child(entry)
	entry.pressed.connect(func() -> void: get_tree().call_deferred("change_scene_to_file",scene_path))

func _build_candidate_entry(content: VBoxContainer) -> void:
	var english: bool = Localization.current_locale() == "en"
	var details: String = "同一份信息，不同的承载方式。完成已有五份任务；推荐在核心收束后继续，也可独立进入。" if not english else "The same information, carried differently. Complete five existing tasks. Recommended after the core ending; independent entry remains available."
	details += (" 未绑定候选档，默认仅本次会话。" if not english else " No candidate profile is bound; session-only by default.") if candidate_review_paths().is_empty() else (" 方案独立保存，可退出并继续。" if not english else " Plans save independently; quit and resume.")
	_candidate_stage(content,"RepresentationCandidateEntry","表示 · 改变承载" if not english else "Representation",PURPLE,"EnterRepresentationCandidate",(("表示（仅本次会话）" if not english else "Representation (session only)") if candidate_review_paths().is_empty() else ("进入 / 继续表示" if not english else "Enter / resume Representation")),"res://experiments/representation_region/region.tscn",details)

func _build_service_candidate_entry(content: VBoxContainer) -> void:
	var english: bool = Localization.current_locale() == "en"
	var details: String = "让历史服务后来的请求。三份合同探索搬运、响应与表示；表示与预测不是进入前置。" if not english else "Let history serve later requests. Three contracts explore traffic, responses and representation. Representation and Prediction are not prerequisites."
	details += (" 未绑定候选档，默认仅本次会话。" if not english else " No candidate profile is bound; session-only by default.") if candidate_review_paths().is_empty() else (" 方案独立保存，可退出并继续。" if not english else " Plans save independently; quit and resume.")
	_candidate_stage(content,"ServiceCandidateEntry","服务 · 留住历史" if not english else "Service",GOOD,"EnterServiceCandidate",(("服务（仅本次会话）" if not english else "Service (session only)") if candidate_review_paths().is_empty() else ("进入 / 继续服务" if not english else "Enter / resume Service")),"res://experiments/service_plan/lab.tscn",details)

func _build_prediction_entry(content: VBoxContainer) -> void:
	var english: bool = Localization.current_locale() == "en"
	_candidate_stage(content,"PredictionCandidateEntry","预测 · 可选探索" if not english else "Prediction · optional",WARNING,"EnterPredictionCandidate","进入预测（本次会话）" if not english else "Explore Prediction (session only)","res://experiments/prediction/lab.tscn","独立的临时探索，不是表示或服务的进入前置。" if not english else "A separate temporary exploration; not a prerequisite for Representation or Service.")

# Review only explicitly bound candidate profiles, never campaign user files.
func candidate_review_paths() -> Dictionary:
	var context: Script = preload("res://experiments/candidate_session/context.gd")
	var primary: String = str(ProjectSettings.get_setting("candidate/primary_domain",""))
	var profile: String = str(ProjectSettings.get_setting("candidate/profile",""))
	var directory: String = OS.get_user_data_dir().replace("\\","/").simplify_path()
	if not primary in ["representation","service"] or profile.is_empty() or profile.length() > 40: return {}
	for character: String in profile:
		if not character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-": return {}
	if not directory.ends_with("/VonNeumannBottleneckCandidates/"+primary+"/"+profile): return {}
	return {"representation":context.resolve_path("representation",primary,profile,directory),"service":context.resolve_path("service",primary,profile,directory)}

func show_candidate_review() -> void:
	if not candidate_journey: return
	var english: bool = Localization.current_locale() == "en"
	var paths: Dictionary = candidate_review_paths()
	var result: Dictionary = {}
	if not paths.is_empty():
		result = preload("res://experiments/candidate_session/journey_review.gd").read_pair(paths.representation,paths.service)
	var old := get_node_or_null("SavedJourneyReview") as AcceptDialog
	if old != null: remove_child(old); old.queue_free()
	var dialog := AcceptDialog.new(); dialog.name = "SavedJourneyReview"
	dialog.title = "第二幕 · 已保存方案回顾" if not english else "Second act · Saved plan review"
	dialog.ok_button_text = "回到旅程入口" if not english else "Back to journey entries"
	var lines: Array[String] = ["此处重新验收同一候选档的已保存方案；未保存的窗口变化不在这份回顾中。两个阶段各用自己的机器和合同，指标分别看。" if not english else "Revalidate saved plans in this candidate profile. Unsaved window changes are outside this review. Each stage uses its own machine and contracts; compare its metrics separately."]
	if paths.is_empty():
		lines.append("当前启动未绑定隔离候选档，无法确认第二幕成果。请从带命名profile的候选入口启动。" if not english else "This launch is not bound to an isolated candidate profile. Start a named candidate profile to review its saved work.")
	else:
		for domain: String in ["representation","service"]:
			var item: Dictionary = result[domain]
			var title: String = ("表示" if not english else "Representation") if domain == "representation" else ("持续状态与服务" if not english else "Persistent state and service")
			lines.append("")
			lines.append(title+" · "+str(item.completed.size())+" / "+("5" if domain == "representation" else "3"))
			match str(item.status):
				"empty": lines.append("尚无已保存方案。进入该阶段，运行自己的方案并保存后再回顾。" if not english else "No saved plans yet. Enter this stage, measure your own plan, then Save before reviewing.")
				"unavailable": lines.append(("无法确认：" if not english else "Cannot confirm: ")+str(item.error)+("。请进入原阶段检查恢复提示；此处不会替你恢复。" if not english else ". Enter the stage to inspect its recovery notice; this review does not recover files."))
				"partial": lines.append("已有实测达标方案；其余任务仍可从原工作台继续。" if not english else "Some measured plans meet their contracts. Continue the remaining tasks in their workbench.")
				"complete": lines.append("这一阶段的全部合同已由保存的方案重新验收。" if not english else "Saved plans revalidate all contracts in this stage.")
			for evidence: Dictionary in item.evidence:
				if domain == "representation":
					var cycles: Array[String] = []
					for metrics: Dictionary in evidence.metrics: cycles.append(str(metrics.total_cycles))
					lines.append(("任务" if not english else "Task ")+str(int(evidence.task)+1)+" · "+" / ".join(cycles)+("周期（各订单）" if not english else " cycles (per order)"))
				else:
					var m: Dictionary = evidence.metrics
					lines.append(("合同%d · %d周期 · 状态%dB · 首响应%s · 分数/状态误差%s / %s" if not english else "Contract%d · %d cycles · state%dB · first%s · score/state error%s / %s") % [int(evidence.task)+1,m.total_cycles,m.state_read_bytes+m.state_write_bytes,str(m.first_stream_cycles),String.num_scientific(m.max_error),String.num_scientific(m.max_state_error)])
		if bool(result.complete):
			lines.append("")
			lines.append("你安排了信息的承载，也让会改变的历史继续服务后来的请求。两段第二幕候选体验在此收束；可回看自己的方案，也可自由尝试追加委托或预测。A Thought Within the World。" if not english else "You arranged how information travels and kept changing history useful for later requests. These two second-act candidate journeys close here. Revisit your plans, or optionally explore commissions and prediction. A Thought Within the World.")
		else:
			lines.append("第二幕的联合回顾尚未成立；各阶段已有的独立结尾仍可回看。" if not english else "The combined second-act review is not earned yet; each earned stage ending remains available.")
	var scroll := ScrollContainer.new(); scroll.name = "SavedJourneyReviewScroll"
	scroll.custom_minimum_size = Vector2(740,360); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog.add_child(scroll)
	var text := Label.new(); text.name = "SavedJourneyReviewContent"; text.text = "\n\n".join(lines)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(text)
	var refresh: Button = dialog.add_button("刷新已保存方案" if not english else "Refresh saved plans",false,"refresh")
	refresh.name = "RefreshSavedJourneyReview"
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"refresh": show_candidate_review())
	add_child(dialog); dialog.popup_centered(Vector2i(780,480))

func _consume_review_intent() -> void:
	var intent: String = preload("res://experiments/candidate_session/navigation_intent.gd").take_review()
	if intent == "core": _open_theme_reflection()
	elif intent == "journey" and candidate_journey: show_completion_story()

# Recommendations are presentation only; the existing task tree owns prerequisites.
static func recommended_stage(core_finished: bool, review: Dictionary) -> String:
	if bool(review.get("complete", false)) and str(review.get("representation", {}).get("status", "")) == "complete" and str(review.get("service", {}).get("status", "")) == "complete": return "review"
	if not core_finished: return "core"
	if str(review.get("representation", {}).get("status", "unavailable")) != "complete": return "representation"
	if str(review.get("service", {}).get("status", "unavailable")) != "complete": return "service"
	return "review" if bool(review.get("complete", false)) else "service"

func _core_reflection_keys() -> Array[StringName]:
	var hardware: Dictionary = {} if GameMode.is_test_mode() else GlobalSave.game_player_content.completed_levels
	return preload("res://src/ui/theme_reflection.gd").milestones(hardware, SystemChapter.completed_levels(), LocalityChapter.completed_levels(), OverlapChapter.completed(), LayoutChapter.completed())

func _saved_completion_review() -> Dictionary:
	var paths: Dictionary = candidate_review_paths()
	if paths.is_empty(): return {}
	return preload("res://experiments/candidate_session/journey_review.gd").read_pair(paths.representation, paths.service)

func _build_completion_route(content: VBoxContainer) -> void:
	var english: bool = Localization.current_locale() == "en"
	var column := VBoxContainer.new(); column.name = "RecommendedJourney"
	column.add_theme_constant_override("separation",6); content.add_child(column)
	var route := Label.new(); route.name = "RecommendedJourneyRoute"
	route.text = "核心 → 表示 → 服务 → 回顾" if not english else "Core → Representation → Service → Review"
	route.add_theme_font_size_override("font_size",14); route.add_theme_color_override("font_color",MUTED)
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(route)
	var core_finished: bool = &"theme.ending" in _core_reflection_keys()
	var review: Dictionary = _saved_completion_review()
	var progress := Label.new(); progress.name = "RecommendedJourneyProgress"
	var pieces: Array[String] = [("核心已收束" if core_finished else "核心待继续") if not english else ("Core earned" if core_finished else "Core open")]
	for domain: String in ["representation","service"]:
		var label: String = ("表示" if domain == "representation" else "服务") if not english else ("Rep" if domain == "representation" else "Service")
		var item: Dictionary = review.get(domain,{})
		pieces.append(label+("待确认" if not english else " unconfirmed") if str(item.get("status","unavailable")) == "unavailable" else label+" %d/%d" % [item.get("completed",[]).size(),5 if domain == "representation" else 3])
	progress.text = " · ".join(pieces); progress.add_theme_font_size_override("font_size",14)
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(progress)
	var stage: String = recommended_stage(core_finished,review)
	var action := Button.new(); action.name = "RecommendedJourneyAction"; action.custom_minimum_size.y = 48
	var captions: Dictionary = {"core":["继续旅程" if not GlobalSave.continue_scene_path().is_empty() else "开始旅程","Continue journey" if not GlobalSave.continue_scene_path().is_empty() else "Start journey"],"representation":["下一段：改变信息的承载","Next: change how information is carried"],"service":["下一段：让历史服务新的请求","Next: let history serve new requests"],"review":["回看这一段旅程","Revisit this journey"]}
	action.text = captions[stage][1 if english else 0]; action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	InstrumentTheme.primary(action); action.add_theme_color_override("font_focus_color",Color("071823")); column.add_child(action)
	action.pressed.connect(func() -> void:
		match stage:
			"core":
				if GlobalSave.continue_scene_path().is_empty(): get_tree().change_scene_to_file(TaskNavigation.MAP_SCENE)
				else: _continue_game()
			"representation": _show_completion_bridge()
			"service": get_tree().change_scene_to_file("res://experiments/service_plan/lab.tscn")
			"review": show_completion_story()
	)

func _show_completion_bridge() -> void:
	if not candidate_journey: return
	var old := get_node_or_null("CompletionBridge")
	if old != null: remove_child(old); old.queue_free()
	var english: bool = Localization.current_locale() == "en"
	var page: Dictionary = preload("res://experiments/candidate_session/completion_presentation.gd").bridge(english)
	var dialog := ConfirmationDialog.new(); dialog.name = "CompletionBridge"; dialog.title = str(page.title)
	dialog.ok_button_text = "进入表示" if not english else "Enter Representation"
	dialog.cancel_button_text = "稍后再来" if not english else "Later"
	var text := Label.new(); text.text = str(page.body); text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if candidate_review_paths().is_empty():
		text.text += "\n\n此启动未绑定候选存档，默认仅本次会话。请用命名候选包保存并继续。" if not english else "\n\nThis launch is not bound to a candidate profile; it is session-only by default. Use a named candidate package to save and resume."
	text.custom_minimum_size = Vector2(560, 170); dialog.add_child(text)
	dialog.confirmed.connect(func() -> void: get_tree().call_deferred("change_scene_to_file", "res://experiments/representation_region/region.tscn"))
	add_child(dialog); dialog.popup_centered(Vector2i(620, 290))

func show_completion_story() -> void:
	if not candidate_journey: return
	var english: bool = Localization.current_locale() == "en"
	completion_story_pages = preload("res://experiments/candidate_session/completion_presentation.gd").pages(_saved_completion_review(), english)
	completion_story_page = 0
	var old := get_node_or_null("CompletionStoryDialog")
	if old != null: remove_child(old); old.queue_free()
	var dialog := AcceptDialog.new(); dialog.name = "CompletionStoryDialog"
	dialog.title = "A Thought Within the World"
	dialog.ok_button_text = "返回旅程" if not english else "Back to journey"
	var scroll := ScrollContainer.new(); scroll.name = "StoryScroll"
	scroll.custom_minimum_size = Vector2(620, 300); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; dialog.add_child(scroll)
	var body := Label.new(); body.name = "StoryText"; body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(body)
	var previous: Button = dialog.add_button("上一页" if not english else "Previous", true, "previous"); previous.name = "StoryPrevious"
	var next: Button = dialog.add_button("下一页" if not english else "Next", false, "next"); next.name = "StoryNext"
	var detail: Button = dialog.add_button("成果明细" if not english else "Evidence", false, "evidence"); detail.name = "StoryEvidence"
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"evidence": dialog.hide(); show_candidate_review(); return
		completion_story_page = clampi(completion_story_page + (1 if action == &"next" else -1), 0, completion_story_pages.size() - 1)
		_refresh_completion_story())
	add_child(dialog); _refresh_completion_story(); dialog.popup_centered(Vector2i(670, 420))

func _refresh_completion_story() -> void:
	if completion_story_pages.is_empty(): return
	var dialog := get_node("CompletionStoryDialog") as AcceptDialog
	var page: Dictionary = completion_story_pages[completion_story_page]
	(dialog.find_child("StoryText", true, false) as Label).text = "%d / %d   %s\n\n%s" % [completion_story_page + 1, completion_story_pages.size(), page.title, page.body]
	(dialog.find_child("StoryPrevious", true, false) as Button).disabled = completion_story_page == 0
	(dialog.find_child("StoryNext", true, false) as Button).disabled = completion_story_page == completion_story_pages.size() - 1
	(dialog.get_node("StoryScroll") as ScrollContainer).scroll_vertical = 0
