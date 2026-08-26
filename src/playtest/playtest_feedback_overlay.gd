class_name PlaytestFeedbackOverlay
extends Control

const UiTypographyType = preload("res://src/ui/ui_typography.gd")

signal chapter_feedback_submitted(
	chapter_id: StringName,
	best_level_id: StringName,
	worst_level_id: StringName,
	confusing_point: String,
	surprising_point: String,
	pace_rating: int
)
signal demo_feedback_submitted(
	satisfaction_rating: int,
	difficulty_rating: int,
	length_feeling: StringName,
	favorite_content: String,
	change_or_remove: String,
	continue_interest_rating: int
)
signal feedback_skipped(scope: StringName, subject_id: StringName)
signal export_requested
signal open_export_folder_requested(export_path: String)
signal finished(scope: StringName, subject_id: StringName)

const BACKDROP := Color("050a12", 0.86)
const SURFACE := Color("111a2a")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const PURPLE := Color("bc8cff")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")

var questionnaire_enabled: bool = false
var current_scope: StringName = &""
var current_subject_id: StringName = &""
var title_label: Label
var subtitle_label: Label
var form_box: VBoxContainer
var submit_button: Button
var skip_button: Button
var finish_button: Button
var export_handoff_box: VBoxContainer
var export_button: Button
var open_export_folder_button: Button
var export_status_label: Label
var exported_path: String = ""
var best_level_selector: OptionButton
var worst_level_selector: OptionButton
var chapter_pace_selector: OptionButton
var confusing_edit: LineEdit
var surprising_edit: LineEdit
var demo_ratings: Dictionary[StringName, OptionButton] = {}
var length_selector: OptionButton
var favorite_edit: LineEdit
var change_edit: LineEdit


func _ready() -> void:
	name = "PlaytestFeedbackOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2100
	_build_interface()
	hide()


func present_chapter(chapter_id: StringName, levels: Array[Dictionary]) -> bool:
	if not questionnaire_enabled or chapter_id.is_empty() or levels.is_empty():
		return false
	current_scope = &"chapter"
	current_subject_id = chapter_id
	title_label.text = Localization.text(&"playtest.chapter_feedback.title")
	subtitle_label.text = Localization.text(&"playtest.chapter_feedback.subtitle")
	_clear_form()
	_hide_export_handoff()
	best_level_selector = _add_level_selector(&"ChapterBestLevel", &"playtest.chapter_feedback.best", levels)
	worst_level_selector = _add_level_selector(&"ChapterWorstLevel", &"playtest.chapter_feedback.worst", levels)
	confusing_edit = _add_text_field(&"ChapterConfusingPoint", &"playtest.chapter_feedback.confusing")
	surprising_edit = _add_text_field(&"ChapterSurprisingPoint", &"playtest.chapter_feedback.surprising")
	chapter_pace_selector = _add_rating_selector(&"ChapterPaceRating", &"playtest.chapter_feedback.pace")
	_connect_required_selector(best_level_selector)
	_connect_required_selector(worst_level_selector)
	_connect_required_selector(chapter_pace_selector)
	_refresh_submit_state()
	show()
	best_level_selector.grab_focus()
	return true


func present_demo() -> bool:
	if not questionnaire_enabled:
		return false
	current_scope = &"demo"
	current_subject_id = &"demo"
	title_label.text = Localization.text(&"playtest.demo_feedback.title")
	subtitle_label.text = Localization.text(&"playtest.demo_feedback.subtitle")
	_clear_form()
	_hide_export_handoff()
	demo_ratings.clear()
	demo_ratings[&"satisfaction"] = _add_rating_selector(&"DemoSatisfactionRating", &"playtest.demo_feedback.satisfaction")
	demo_ratings[&"difficulty"] = _add_rating_selector(&"DemoDifficultyRating", &"playtest.demo_feedback.difficulty")
	length_selector = _add_length_selector()
	favorite_edit = _add_text_field(&"DemoFavoriteContent", &"playtest.demo_feedback.favorite")
	change_edit = _add_text_field(&"DemoChangeContent", &"playtest.demo_feedback.change")
	demo_ratings[&"continue"] = _add_rating_selector(&"DemoContinueRating", &"playtest.demo_feedback.continue")
	for selector: OptionButton in demo_ratings.values():
		_connect_required_selector(selector)
	_connect_required_selector(length_selector)
	_refresh_submit_state()
	show()
	(demo_ratings[&"satisfaction"] as OptionButton).grab_focus()
	return true


func dismiss() -> void:
	hide()
	current_scope = &""
	current_subject_id = &""
	exported_path = ""


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "PlaytestFeedbackPanel"
	panel.custom_minimum_size = Vector2(790.0, 650.0)
	panel.add_theme_stylebox_override("panel", _stylebox(SURFACE, PURPLE, 16, 3))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	title_label.add_theme_color_override("font_color", GOOD)
	column.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_color_override("font_color", MUTED)
	column.add_child(subtitle_label)
	column.add_child(HSeparator.new())
	form_box = VBoxContainer.new()
	form_box.name = "PlaytestFeedbackForm"
	form_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form_box.add_theme_constant_override("separation", 10)
	column.add_child(form_box)
	export_handoff_box = VBoxContainer.new()
	export_handoff_box.name = "PlaytestExportHandoff"
	export_handoff_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	export_handoff_box.add_theme_constant_override("separation", 14)
	column.add_child(export_handoff_box)
	var export_note := Label.new()
	export_note.text = Localization.text(&"playtest.export.handoff.note")
	export_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	export_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	export_note.add_theme_color_override("font_color", MUTED)
	export_handoff_box.add_child(export_note)
	export_button = Button.new()
	export_button.name = "PlaytestExportButton"
	export_button.text = Localization.text(&"playtest.export.button")
	export_button.tooltip_text = Localization.text(&"playtest.export.tooltip")
	export_button.custom_minimum_size = Vector2(300.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	export_button.pressed.connect(func() -> void: export_requested.emit())
	export_handoff_box.add_child(export_button)
	open_export_folder_button = Button.new()
	open_export_folder_button.name = "PlaytestOpenExportFolderButton"
	open_export_folder_button.text = Localization.text(&"playtest.export.open_folder")
	open_export_folder_button.custom_minimum_size = Vector2(300.0, UiTypographyType.TOOL_BUTTON_HEIGHT)
	open_export_folder_button.pressed.connect(_request_open_export_folder)
	export_handoff_box.add_child(open_export_folder_button)
	export_status_label = Label.new()
	export_status_label.name = "PlaytestExportStatus"
	export_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	export_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	export_status_label.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	export_status_label.add_theme_color_override("font_color", MUTED)
	export_handoff_box.add_child(export_status_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	skip_button = Button.new()
	skip_button.name = "PlaytestFeedbackSkipButton"
	skip_button.text = Localization.text(&"playtest.feedback.skip")
	skip_button.custom_minimum_size = Vector2(160.0, UiTypographyType.CONTROL_HEIGHT)
	skip_button.pressed.connect(_skip)
	actions.add_child(skip_button)
	submit_button = Button.new()
	submit_button.name = "PlaytestFeedbackSubmitButton"
	submit_button.text = Localization.text(&"playtest.feedback.submit")
	submit_button.custom_minimum_size = Vector2(190.0, UiTypographyType.CONTROL_HEIGHT)
	submit_button.pressed.connect(_submit)
	actions.add_child(submit_button)
	finish_button = Button.new()
	finish_button.name = "PlaytestExportContinueButton"
	finish_button.text = Localization.text(&"playtest.export.continue")
	finish_button.custom_minimum_size = Vector2(190.0, UiTypographyType.CONTROL_HEIGHT)
	finish_button.pressed.connect(_finish_demo_handoff)
	actions.add_child(finish_button)
	column.add_child(actions)
	_hide_export_handoff()


func _clear_form() -> void:
	for child: Node in form_box.get_children():
		child.queue_free()
	best_level_selector = null
	worst_level_selector = null
	chapter_pace_selector = null
	confusing_edit = null
	surprising_edit = null
	length_selector = null
	favorite_edit = null
	change_edit = null
	demo_ratings.clear()
	form_box.show()


func _add_level_selector(name_value: StringName, label_key: StringName, levels: Array[Dictionary]) -> OptionButton:
	var selector := _selector_row(name_value, label_key)
	for level: Dictionary in levels:
		selector.add_item(String(level.get("label", level.get("id", ""))))
		selector.set_item_metadata(selector.item_count - 1, String(level.get("id", "")))
	return selector


func _add_rating_selector(name_value: StringName, label_key: StringName) -> OptionButton:
	var selector := _selector_row(name_value, label_key)
	for value: int in range(1, 6):
		selector.add_item(str(value))
		selector.set_item_metadata(selector.item_count - 1, value)
	return selector


func _add_length_selector() -> OptionButton:
	var selector := _selector_row(&"DemoLengthFeeling", &"playtest.demo_feedback.length")
	for data: Array in [
		[&"too_short", &"playtest.demo_feedback.length.too_short"],
		[&"about_right", &"playtest.demo_feedback.length.about_right"],
		[&"too_long", &"playtest.demo_feedback.length.too_long"],
	]:
		selector.add_item(Localization.text(StringName(data[1])))
		selector.set_item_metadata(selector.item_count - 1, String(data[0]))
	return selector


func _selector_row(name_value: StringName, label_key: StringName) -> OptionButton:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = Localization.text(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var selector := OptionButton.new()
	selector.name = name_value
	selector.custom_minimum_size = Vector2(250.0, UiTypographyType.CONTROL_HEIGHT)
	selector.add_item(Localization.text(&"playtest.feedback.select"))
	selector.set_item_metadata(0, null)
	row.add_child(selector)
	form_box.add_child(row)
	return selector


func _add_text_field(name_value: StringName, label_key: StringName) -> LineEdit:
	var edit := LineEdit.new()
	edit.name = name_value
	edit.placeholder_text = Localization.text(label_key)
	edit.max_length = 240
	edit.custom_minimum_size.y = UiTypographyType.CONTROL_HEIGHT
	form_box.add_child(edit)
	return edit


func _connect_required_selector(selector: OptionButton) -> void:
	selector.item_selected.connect(func(_index: int) -> void: _refresh_submit_state())


func _refresh_submit_state() -> void:
	if submit_button == null:
		return
	if current_scope == &"chapter":
		submit_button.disabled = not (
			_selector_has_value(best_level_selector)
			and _selector_has_value(worst_level_selector)
			and _selector_has_value(chapter_pace_selector)
		)
	elif current_scope == &"demo":
		submit_button.disabled = not _selector_has_value(length_selector)
		for selector: OptionButton in demo_ratings.values():
			submit_button.disabled = submit_button.disabled or not _selector_has_value(selector)
	else:
		submit_button.disabled = true


func _selector_has_value(selector: OptionButton) -> bool:
	return selector != null and selector.selected > 0 and selector.get_item_metadata(selector.selected) != null


func _selected_id(selector: OptionButton) -> StringName:
	return StringName(selector.get_item_metadata(selector.selected)) if _selector_has_value(selector) else &""


func _selected_rating(selector: OptionButton) -> int:
	return int(selector.get_item_metadata(selector.selected)) if _selector_has_value(selector) else 0


func _submit() -> void:
	if submit_button.disabled:
		return
	var scope: StringName = current_scope
	var subject_id: StringName = current_subject_id
	if scope == &"chapter":
		chapter_feedback_submitted.emit(
			subject_id,
			_selected_id(best_level_selector),
			_selected_id(worst_level_selector),
			confusing_edit.text,
			surprising_edit.text,
			_selected_rating(chapter_pace_selector)
		)
	elif scope == &"demo":
		demo_feedback_submitted.emit(
			_selected_rating(demo_ratings[&"satisfaction"]),
			_selected_rating(demo_ratings[&"difficulty"]),
			_selected_id(length_selector),
			favorite_edit.text,
			change_edit.text,
			_selected_rating(demo_ratings[&"continue"])
		)
		_show_demo_export_handoff()
		return
	dismiss()
	finished.emit(scope, subject_id)


func _skip() -> void:
	var scope: StringName = current_scope
	var subject_id: StringName = current_subject_id
	feedback_skipped.emit(scope, subject_id)
	if scope == &"demo":
		_show_demo_export_handoff()
		return
	dismiss()
	finished.emit(scope, subject_id)


func show_export_result(export_path: String, error_message: String = "") -> void:
	exported_path = export_path
	if export_path.is_empty():
		export_status_label.text = Localization.text(&"playtest.export.failed", [error_message])
		export_status_label.add_theme_color_override("font_color", Color("ff6b7d"))
		open_export_folder_button.hide()
	else:
		export_status_label.text = Localization.text(&"playtest.export.success", [export_path])
		export_status_label.add_theme_color_override("font_color", GOOD)
		open_export_folder_button.show()


func _show_demo_export_handoff() -> void:
	title_label.text = Localization.text(&"playtest.export.handoff.title")
	subtitle_label.text = Localization.text(&"playtest.export.handoff.subtitle")
	form_box.hide()
	skip_button.hide()
	submit_button.hide()
	finish_button.show()
	export_handoff_box.show()
	export_button.grab_focus()


func _hide_export_handoff() -> void:
	if export_handoff_box == null:
		return
	exported_path = ""
	export_status_label.text = ""
	export_handoff_box.hide()
	open_export_folder_button.hide()
	skip_button.show()
	submit_button.show()
	finish_button.hide()


func _request_open_export_folder() -> void:
	if not exported_path.is_empty():
		open_export_folder_requested.emit(exported_path)


func _finish_demo_handoff() -> void:
	var scope: StringName = current_scope
	var subject_id: StringName = current_subject_id
	dismiss()
	finished.emit(scope, subject_id)


func _stylebox(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	return box
