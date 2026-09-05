class_name LevelCompletionOverlay
extends Control

const UiTypographyType = preload("res://src/ui/ui_typography.gd")

signal continue_requested(level_id: StringName)
signal primary_action_requested(level_id: StringName)
signal return_requested(level_id: StringName)
signal feedback_submitted(
	chapter_id: StringName,
	level_id: StringName,
	fun_rating: int,
	clarity_rating: int,
	continue_rating: int,
	note: String
)
signal feedback_skipped(chapter_id: StringName, level_id: StringName)

const BACKDROP := Color("050a12", 0.82)
const SURFACE := Color("111a2a")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const PURPLE := Color("bc8cff")
const TEXT := Color("e9f0fa")

var current_level_id: StringName = &""
var current_chapter_id: StringName = &""
var music_cue_count: int = 0
var audio_enabled: bool = true
var questionnaire_enabled: bool = false
var panel: PanelContainer
var chapter_label: Label
var title_label: Label
var level_label: Label
var summary_label: Label
var continue_button: Button
var primary_action_button: Button
var return_button: Button
var feedback_box: VBoxContainer
var feedback_ratings: Dictionary[StringName, OptionButton] = {}
var feedback_note: LineEdit
var audio_player: AudioStreamPlayer
var audio_stop_timer: Timer


func _ready() -> void:
	name = "LevelCompletionOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2000
	_build_interface()
	hide()


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

	panel = PanelContainer.new()
	panel.name = "LevelCompletionPanel"
	panel.custom_minimum_size = Vector2(660.0, 430.0)
	panel.add_theme_stylebox_override("panel", _stylebox(SURFACE, GOOD, 16, 3))
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

	chapter_label = Label.new()
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_label.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	chapter_label.add_theme_color_override("font_color", PURPLE)
	column.add_child(chapter_label)

	title_label = Label.new()
	title_label.text = Localization.text(&"common.level_complete.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	title_label.add_theme_color_override("font_color", GOOD)
	column.add_child(title_label)

	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_label.add_theme_font_size_override("font_size", UiTypographyType.SUBTITLE_SIZE)
	level_label.add_theme_color_override("font_color", TEXT)
	column.add_child(level_label)

	var divider := HSeparator.new()
	column.add_child(divider)

	var learned := Label.new()
	learned.text = Localization.text(&"common.level_complete.learned")
	learned.add_theme_font_size_override("font_size", UiTypographyType.SUBTITLE_SIZE)
	learned.add_theme_color_override("font_color", ACCENT)
	column.add_child(learned)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_label.add_theme_font_size_override("font_size", UiTypographyType.BODY_SIZE)
	summary_label.add_theme_color_override("font_color", TEXT)
	column.add_child(summary_label)

	feedback_box = VBoxContainer.new()
	feedback_box.name = "LevelFeedbackBox"
	feedback_box.add_theme_constant_override("separation", 8)
	var feedback_title := Label.new()
	feedback_title.text = Localization.text(&"playtest.level_feedback.title")
	feedback_title.add_theme_font_size_override("font_size", UiTypographyType.SUBTITLE_SIZE)
	feedback_title.add_theme_color_override("font_color", PURPLE)
	feedback_box.add_child(feedback_title)
	var feedback_hint := Label.new()
	feedback_hint.text = Localization.text(&"playtest.level_feedback.hint")
	feedback_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_hint.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	feedback_hint.add_theme_color_override("font_color", ACCENT)
	feedback_box.add_child(feedback_hint)
	_add_rating_row(&"fun", &"playtest.level_feedback.fun")
	_add_rating_row(&"clarity", &"playtest.level_feedback.clarity")
	_add_rating_row(&"continue", &"playtest.level_feedback.continue")
	feedback_note = LineEdit.new()
	feedback_note.name = "LevelFeedbackNote"
	feedback_note.placeholder_text = Localization.text(&"playtest.level_feedback.note")
	feedback_note.max_length = 240
	feedback_note.custom_minimum_size.y = UiTypographyType.CONTROL_HEIGHT
	feedback_box.add_child(feedback_note)
	column.add_child(feedback_box)

	primary_action_button = Button.new()
	primary_action_button.name = "LevelCompletionPrimaryButton"
	primary_action_button.custom_minimum_size = Vector2(UiTypographyType.CONTINUE_WIDTH, UiTypographyType.CONTROL_HEIGHT)
	primary_action_button.add_theme_font_size_override("font_size", UiTypographyType.BUTTON_SIZE)
	primary_action_button.pressed.connect(_on_primary_action_pressed)
	primary_action_button.hide()
	continue_button = Button.new()
	continue_button.name = "LevelCompletionContinueButton"
	continue_button.text = Localization.text(&"common.level_complete.continue")
	continue_button.custom_minimum_size = Vector2(UiTypographyType.CONTINUE_WIDTH, UiTypographyType.CONTROL_HEIGHT)
	continue_button.add_theme_font_size_override("font_size", UiTypographyType.BUTTON_SIZE)
	continue_button.pressed.connect(_on_continue_pressed)
	return_button = Button.new()
	return_button.name = "LevelCompletionReturnButton"
	return_button.custom_minimum_size = Vector2(UiTypographyType.CONTINUE_WIDTH, UiTypographyType.CONTROL_HEIGHT)
	return_button.add_theme_font_size_override("font_size", UiTypographyType.BUTTON_SIZE)
	return_button.pressed.connect(_on_return_pressed)
	return_button.hide()
	var continue_center := CenterContainer.new()
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 14)
	action_row.add_child(primary_action_button)
	action_row.add_child(continue_button)
	action_row.add_child(return_button)
	continue_center.add_child(action_row)
	column.add_child(continue_center)

	audio_player = AudioStreamPlayer.new()
	audio_player.name = "CompletionMusicPlayer"
	audio_player.volume_db = -13.0
	add_child(audio_player)
	audio_stop_timer = Timer.new()
	audio_stop_timer.one_shot = true
	audio_stop_timer.wait_time = 0.86
	audio_stop_timer.timeout.connect(_stop_completion_cue)
	add_child(audio_stop_timer)


func present(
		level_id: StringName,
	level_title: String,
	summary: String,
	chapter: String,
	chapter_id: StringName = &""
	) -> void:
	current_level_id = level_id
	current_chapter_id = chapter_id
	chapter_label.text = chapter
	title_label.text = Localization.text(&"common.level_complete.title")
	level_label.text = level_title
	summary_label.text = summary
	continue_button.text = Localization.text(&"common.level_complete.continue")
	primary_action_button.hide()
	return_button.hide()
	feedback_box.visible = questionnaire_enabled
	panel.custom_minimum_size = Vector2(760.0, 650.0) if questionnaire_enabled else Vector2(660.0, 430.0)
	_reset_feedback()
	show()
	continue_button.grab_focus()
	_play_completion_cue()


func present_actions(
		level_id: StringName,
		level_title: String,
		summary: String,
		chapter: String,
		chapter_id: StringName,
		primary_text: String,
		secondary_text: String,
		return_text: String = ""
	) -> void:
	present(level_id, level_title, summary, chapter, chapter_id)
	feedback_box.hide()
	panel.custom_minimum_size = Vector2(700.0, 470.0)
	primary_action_button.text = primary_text
	primary_action_button.show()
	continue_button.text = secondary_text
	return_button.text = return_text
	return_button.visible = not return_text.is_empty()
	primary_action_button.grab_focus()


func dismiss() -> void:
	hide()
	current_level_id = &""
	current_chapter_id = &""
	_stop_completion_cue()


func _exit_tree() -> void:
	_stop_completion_cue()


func _stop_completion_cue() -> void:
	if audio_player == null:
		return
	if audio_stop_timer != null:
		audio_stop_timer.stop()
	audio_player.stop()
	audio_player.stream = null


func _on_continue_pressed() -> void:
	var finished_level: StringName = current_level_id
	var finished_chapter: StringName = current_chapter_id
	if questionnaire_enabled:
		var fun_rating: int = _rating_value(&"fun")
		var clarity_rating: int = _rating_value(&"clarity")
		var continue_rating: int = _rating_value(&"continue")
		if fun_rating > 0 and clarity_rating > 0 and continue_rating > 0:
			feedback_submitted.emit(
				finished_chapter, finished_level,
				fun_rating, clarity_rating, continue_rating, feedback_note.text
			)
		else:
			feedback_skipped.emit(finished_chapter, finished_level)
	dismiss()
	continue_requested.emit(finished_level)


func _on_primary_action_pressed() -> void:
	var finished_level: StringName = current_level_id
	dismiss()
	primary_action_requested.emit(finished_level)


func _on_return_pressed() -> void:
	var finished_level: StringName = current_level_id
	dismiss()
	return_requested.emit(finished_level)


func _add_rating_row(rating_id: StringName, label_key: StringName) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = Localization.text(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var selector := OptionButton.new()
	selector.name = "%sRating" % String(rating_id).to_pascal_case()
	selector.custom_minimum_size = Vector2(150.0, UiTypographyType.CONTROL_HEIGHT)
	selector.add_item(Localization.text(&"playtest.feedback.select"))
	selector.set_item_metadata(0, 0)
	for value: int in range(1, 6):
		selector.add_item(str(value))
		selector.set_item_metadata(value, value)
	row.add_child(selector)
	feedback_ratings[rating_id] = selector
	feedback_box.add_child(row)


func _reset_feedback() -> void:
	for selector: OptionButton in feedback_ratings.values():
		selector.select(0)
	if feedback_note != null:
		feedback_note.clear()


func _rating_value(rating_id: StringName) -> int:
	var selector: OptionButton = feedback_ratings.get(rating_id)
	if selector == null or selector.selected < 0:
		return 0
	return int(selector.get_item_metadata(selector.selected))


func _play_completion_cue() -> void:
	music_cue_count += 1
	if not audio_enabled or DisplayServer.get_name() == "headless":
		return
	_stop_completion_cue()
	audio_player.stream = _build_completion_stream()
	audio_player.play()
	audio_stop_timer.start()


func _build_completion_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var frequencies := PackedFloat32Array([523.25, 659.25, 783.99, 1046.50])
	var frame_count: int = int(float(stream.mix_rate) * 0.82)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var note_duration: float = 0.18
	var phase: float = 0.0
	for frame: int in range(frame_count):
		var elapsed: float = float(frame) / float(stream.mix_rate)
		var note_index: int = mini(int(elapsed / note_duration), frequencies.size() - 1)
		var local_time: float = fmod(elapsed, note_duration)
		var attack: float = minf(1.0, local_time / 0.018)
		var release: float = clampf((note_duration - local_time) / 0.055, 0.0, 1.0)
		var envelope: float = attack * release * (1.0 - elapsed / 1.05)
		phase += TAU * frequencies[note_index] / float(stream.mix_rate)
		var sample: float = sin(phase) * envelope * 0.14
		data.encode_s16(frame * 2, clampi(int(round(sample * 32767.0)), -32768, 32767))
	stream.data = data
	return stream


func _stylebox(
		fill: Color,
		border: Color,
		radius: int,
		border_width: int
	) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	return box
