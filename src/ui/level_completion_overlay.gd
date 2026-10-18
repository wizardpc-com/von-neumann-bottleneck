class_name LevelCompletionOverlay
extends Control

const UiTypographyType = preload("res://src/ui/ui_typography.gd")
const MissionNarrativeCatalogType = preload("res://src/ui/mission_narrative_catalog.gd")

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

const Palette = preload("res://src/lab/lab_palette.gd")
const BACKDROP := Color(0.03, 0.05, 0.07, 0.62)
const SURFACE := Palette.TERM_PANEL
const ACCENT := Palette.ACCENT
const GOOD := Palette.GOOD
const PURPLE := Palette.TERM_MUTED
const TEXT := Palette.TERM_TEXT

# Quiet "earned" emblem: rings settle around a warm light when a result is earned.
class Emblem extends Control:
	var progress: float = 0.0
	func _draw() -> void:
		var center: Vector2 = size * 0.5
		var warm := Color("ffd27a")
		for ring: int in 3:
			var t: float = clampf(progress * 1.4 - ring * 0.2, 0.0, 1.0)
			draw_arc(center, 20.0 + ring * 9.0 + (1.0 - t) * 14.0, 0.0, TAU, 48, Color(0.56, 0.83, 0.86, 0.55 * t * (1.0 - ring * 0.28)), 1.5)
		draw_circle(center, 15.0, Color(warm, 0.18 * progress))
		draw_circle(center, 8.5 * clampf(progress * 1.6, 0.0, 1.0), warm)
		draw_circle(center, 14.0, Color(warm, 0.35 * clampf(progress * 1.6, 0.0, 1.0)), false, 1.5)

var emblem: Emblem

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
var yi_response_label: Label
var next_capability_label: Label
var feedback_toggle: Button
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
	visibility_changed.connect(func() -> void:
		if not visible: PlaytestData.set_feedback_visible(false,&"completion"))
	hide()


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + edge, 24)
	add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	frame.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(center)

	panel = PanelContainer.new()
	panel.name = "LevelCompletionPanel"
	panel.custom_minimum_size = Vector2(660.0, 430.0)
	var surface_box: StyleBoxFlat = _stylebox(SURFACE, Palette.ACCENT_DEEP, 18, 1)
	surface_box.shadow_color = Color(0, 0, 0, 0.4); surface_box.shadow_size = 26; surface_box.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", surface_box)
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

	emblem = Emblem.new(); emblem.name = "CompletionEmblem"
	emblem.custom_minimum_size = Vector2(0, 74); emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(emblem)
	chapter_label = Label.new()
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_label.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	chapter_label.add_theme_color_override("font_color", PURPLE)
	column.add_child(chapter_label)

	title_label = Label.new()
	title_label.text = Localization.text(&"common.level_complete.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	title_label.add_theme_color_override("font_color", GOOD)
	column.add_child(title_label)

	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_label.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	level_label.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
	level_label.add_theme_color_override("font_color", TEXT)
	column.add_child(level_label)

	var divider := HSeparator.new()
	column.add_child(divider)

	var learned := Label.new()
	learned.text = Localization.text(&"common.level_complete.learned")
	learned.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	learned.add_theme_color_override("font_color", Palette.TERM_MUTED)
	column.add_child(learned)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_label.add_theme_font_size_override("font_size", UiTypographyType.BODY_SIZE)
	summary_label.add_theme_color_override("font_color", TEXT)
	column.add_child(summary_label)
	yi_response_label = Label.new()
	yi_response_label.name = "YiCompletionResponse"
	yi_response_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	yi_response_label.add_theme_font_size_override("font_size", UiTypographyType.BODY_SIZE)
	yi_response_label.add_theme_color_override("font_color", Color("bfe3e6"))
	var yi_card := PanelContainer.new(); yi_card.name = "YiCompletionCard"
	var yi_box: StyleBoxFlat = _stylebox(Palette.TERM_SCREEN, Palette.ACCENT_DEEP, 10, 0)
	yi_box.border_width_left = 3
	yi_box.content_margin_left = 16; yi_box.content_margin_right = 16; yi_box.content_margin_top = 10; yi_box.content_margin_bottom = 10
	yi_card.add_theme_stylebox_override("panel", yi_box)
	yi_card.add_child(yi_response_label)
	column.add_child(yi_card)
	var next_panel := PanelContainer.new()
	next_panel.name = "NextCapability"
	next_panel.add_theme_stylebox_override("panel", _stylebox(Palette.TERM_SCREEN_LIFT, Palette.TERM_EDGE, 10, 1))
	next_capability_label = Label.new()
	next_capability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_capability_label.custom_minimum_size.y = 44.0
	next_capability_label.add_theme_color_override("font_color", Palette.TERM_MUTED)
	next_capability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_capability_label.add_theme_font_size_override("font_size", UiTypographyType.BODY_SIZE)
	var next_margin := MarginContainer.new()
	next_margin.add_theme_constant_override("margin_left", 16)
	next_margin.add_theme_constant_override("margin_right", 16)
	next_margin.add_theme_constant_override("margin_top", 10)
	next_margin.add_theme_constant_override("margin_bottom", 10)
	next_margin.add_child(next_capability_label)
	next_panel.add_child(next_margin)
	column.add_child(next_panel)
	feedback_toggle = Button.new()
	feedback_toggle.name = "ShowLevelFeedback"
	feedback_toggle.text = Localization.text(&"playtest.level_feedback.open")
	feedback_toggle.toggle_mode = true
	feedback_toggle.flat = true
	feedback_toggle.add_theme_font_size_override("font_size", UiTypographyType.CAPTION_SIZE)
	feedback_toggle.add_theme_color_override("font_color", Palette.TERM_MUTED)
	feedback_toggle.toggled.connect(func(expanded: bool) -> void:
		feedback_box.visible = expanded
		PlaytestData.set_feedback_visible(expanded,&"completion"))
	column.add_child(feedback_toggle)

	feedback_box = VBoxContainer.new()
	feedback_box.name = "LevelFeedbackBox"
	feedback_box.add_theme_constant_override("separation", 8)
	var feedback_title := Label.new()
	feedback_title.text = Localization.text(&"playtest.level_feedback.title")
	feedback_title.add_theme_font_size_override("font_size", UiTypographyType.SUBTITLE_SIZE)
	feedback_title.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
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
	audio_player.bus = &"Effects"
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
	var response: String = MissionNarrativeCatalogType.completion_response(chapter_id, level_id, Localization.current_locale() == "en")
	yi_response_label.text = ("壹　" if Localization.current_locale() != "en" else "Yi  ") + response
	yi_response_label.get_parent().visible = not response.is_empty()
	var next_key: StringName = MissionNarrativeCatalogType.next_capability_key(chapter_id, level_id)
	var context: Dictionary = MissionNarrativeCatalogType.task_context(chapter_id, level_id, Localization.current_locale() == "en")
	next_capability_label.text = Localization.text(next_key) if not next_key.is_empty() else str(context.get("connection", ""))
	next_capability_label.get_parent().get_parent().visible = not next_capability_label.text.is_empty()
	continue_button.text = Localization.text(&"common.level_complete.continue")
	primary_action_button.hide()
	return_button.hide()
	feedback_toggle.visible = questionnaire_enabled
	feedback_toggle.set_pressed_no_signal(false)
	feedback_box.hide()
	panel.custom_minimum_size = Vector2(760.0, 510.0) if questionnaire_enabled else Vector2(700.0, 470.0)
	_reset_feedback()
	show()
	_style_actions(continue_button)
	_animate_entry()
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
	feedback_toggle.hide()
	panel.custom_minimum_size = Vector2(700.0, 470.0)
	primary_action_button.text = primary_text
	primary_action_button.show()
	continue_button.text = secondary_text
	return_button.text = return_text
	return_button.visible = not return_text.is_empty()
	_style_actions(primary_action_button)
	primary_action_button.grab_focus()


## Emphasise one action; the rest read as secondary.
func emphasise(button: Button) -> void:
	_style_actions(button)
	button.grab_focus()


func _style_actions(strong: Button) -> void:
	for button: Button in [primary_action_button, continue_button, return_button]:
		var emphasised: bool = button == strong
		for pair: Array in [["normal", 0.0], ["hover", 0.1], ["pressed", -0.1], ["focus", 0.0]]:
			var fill: Color = Palette.ACCENT if emphasised else Palette.TERM_SCREEN_LIFT
			if float(pair[1]) > 0.0: fill = fill.lightened(float(pair[1]))
			elif float(pair[1]) < 0.0: fill = fill.darkened(-float(pair[1]))
			var edge: Color = Palette.ACCENT if emphasised or str(pair[0]) in ["hover", "focus"] else Palette.TERM_EDGE
			var box: StyleBoxFlat = _stylebox(fill, edge, 10, 2 if str(pair[0]) == "focus" else 1)
			box.content_margin_left = 18; box.content_margin_right = 18
			button.add_theme_stylebox_override(str(pair[0]), box)
		var ink: Color = Palette.TERM_SCREEN if emphasised else Palette.TERM_TEXT
		for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, ink)


func _animate_entry() -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.97, 0.97)
	emblem.progress = 0.0
	var reduced: bool = bool(ProjectSettings.get_setting("game/reduced_motion", false))
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.01 if reduced else 0.28)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.01 if reduced else 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_emblem_progress, 0.0, 1.0, 0.01 if reduced else 1.1).set_delay(0.0 if reduced else 0.12)


func _set_emblem_progress(value: float) -> void:
	emblem.progress = value
	emblem.queue_redraw()


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
		if fun_rating > 0 or clarity_rating > 0 or continue_rating > 0 or not feedback_note.text.strip_edges().is_empty():
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
