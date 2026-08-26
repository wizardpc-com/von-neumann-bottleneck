class_name LevelCompletionOverlay
extends Control

const UiTypographyType = preload("res://src/ui/ui_typography.gd")

signal continue_requested(level_id: StringName)

const BACKDROP := Color("050a12", 0.82)
const SURFACE := Color("111a2a")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const PURPLE := Color("bc8cff")
const TEXT := Color("e9f0fa")

var current_level_id: StringName = &""
var music_cue_count: int = 0
var audio_enabled: bool = true
var chapter_label: Label
var title_label: Label
var level_label: Label
var summary_label: Label
var continue_button: Button
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

	var panel := PanelContainer.new()
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

	continue_button = Button.new()
	continue_button.name = "LevelCompletionContinueButton"
	continue_button.text = Localization.text(&"common.level_complete.continue")
	continue_button.custom_minimum_size = Vector2(UiTypographyType.CONTINUE_WIDTH, UiTypographyType.CONTROL_HEIGHT)
	continue_button.add_theme_font_size_override("font_size", UiTypographyType.BUTTON_SIZE)
	continue_button.pressed.connect(_on_continue_pressed)
	var continue_center := CenterContainer.new()
	continue_center.add_child(continue_button)
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
		chapter: String
	) -> void:
	current_level_id = level_id
	chapter_label.text = chapter
	title_label.text = Localization.text(&"common.level_complete.title")
	level_label.text = level_title
	summary_label.text = summary
	continue_button.text = Localization.text(&"common.level_complete.continue")
	show()
	continue_button.grab_focus()
	_play_completion_cue()


func dismiss() -> void:
	hide()
	current_level_id = &""
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
	dismiss()
	continue_requested.emit(finished_level)


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
