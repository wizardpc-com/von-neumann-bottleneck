extends PanelContainer
## A small, non-modal "ask Yi" card at the edge of the workbench (规范 v0.3
## §4 B). Yi answers in a sentence or two with the trailing caret; the player
## can ask for more, decline, or close it. It never blocks the canvas, never
## takes keyboard focus on its own, and never edits, runs or completes anything.

signal option_selected(id: StringName)
signal closed

const Palette = preload("res://src/lab/lab_palette.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")

var english: bool = false
var body: Typewriter
var options_row: HBoxContainer
var close_button: Button
var _close_tween: Tween


func _ready() -> void:
	name = "YiHelpCard"
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 130
	custom_minimum_size.x = 360
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.with_alpha(Palette.TERM_SCREEN, 0.97)
	box.border_color = Palette.ACCENT_DEEP; box.set_border_width_all(1); box.border_width_left = 3
	box.set_corner_radius_all(10)
	box.shadow_color = Color(0, 0, 0, 0.3); box.shadow_size = 10; box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 16; box.content_margin_right = 12; box.content_margin_top = 10; box.content_margin_bottom = 12
	add_theme_stylebox_override("panel", box)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 8); add_child(column)
	var header := HBoxContainer.new(); column.add_child(header)
	header.alignment = BoxContainer.ALIGNMENT_END
	close_button = Button.new(); close_button.name = "YiHelpClose"; close_button.flat = true
	close_button.text = "×"; close_button.custom_minimum_size = Vector2(28, 24)
	close_button.add_theme_color_override("font_color", Palette.TERM_MUTED)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	body = Typewriter.new(); body.name = "YiHelpText"
	body.font_size = 16; body.font_color = Palette.TERM_TEXT; body.line_spacing = 4.0
	column.add_child(body)
	options_row = HBoxContainer.new(); options_row.name = "YiHelpOptions"
	options_row.add_theme_constant_override("separation", 8)
	column.add_child(options_row)
	hide()


## Open the card with Yi's passage and the player's possible replies, each
## {id, zh, en}. Re-opening while visible replaces the passage.
func present(passage: String, options: Array) -> void:
	if _close_tween != null: _close_tween.kill()
	modulate.a = 1.0
	close_button.tooltip_text = "关闭 · Esc" if not english else "Close · Esc"
	_set_options(options)
	show()
	body.play(passage)


## Yi's short closing reply, then the card leaves by itself.
func say_and_close(passage: String, seconds: float = 1.6) -> void:
	_set_options([])
	body.play(passage)
	if _close_tween != null: _close_tween.kill()
	_close_tween = create_tween()
	_close_tween.tween_interval(seconds)
	_close_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_close_tween.tween_callback(close)


func close() -> void:
	if not visible: return
	if _close_tween != null: _close_tween.kill()
	body.stop()
	hide()
	modulate.a = 1.0
	closed.emit()


func _set_options(options: Array) -> void:
	for child: Node in options_row.get_children(): child.queue_free()
	for option: Dictionary in options:
		var button := Button.new()
		button.name = "YiHelp_" + str(option.id)
		button.text = str(option.en if english else option.zh)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 14)
		button.custom_minimum_size.y = 32
		var id: StringName = StringName(str(option.id))
		button.pressed.connect(func() -> void: option_selected.emit(id))
		options_row.add_child(button)
	options_row.visible = not options.is_empty()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		close()
		get_viewport().set_input_as_handled()
