class_name EncapsulationEffect
extends Control

const UiTypographyType = preload("res://src/ui/ui_typography.gd")

var active: bool = false
var progress: float = 0.0
var component_name: StringName = &""
var module_label: Label
var _content: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 10)
	add_child(_content)
	_add_label(Localization.text(&"hardware.encapsulation.title"), UiTypographyType.BODY_SIZE, Color("50d5ff"))
	module_label = _add_label("", UiTypographyType.TITLE_SIZE, Color("e9f0fa"))
	module_label.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
	_add_label(Localization.text(&"hardware.encapsulation.description"), UiTypographyType.CAPTION_SIZE, Color("9caec0"))
	resized.connect(_layout_content)
	hide()


func begin(sealed_name: StringName) -> void:
	component_name = sealed_name
	module_label.text = String(component_name)
	active = true
	progress = 0.0
	_layout_content()
	show()
	queue_redraw()


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	_layout_content()
	queue_redraw()


func finish() -> void:
	active = false
	hide()


func _add_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_content.add_child(label)
	return label


func _chip_size() -> Vector2:
	return Vector2(minf(lerpf(460.0, 410.0, progress), maxf(220.0, size.x - 48.0)), 200.0)


func _layout_content() -> void:
	if _content == null:
		return
	_content.size = _chip_size() - Vector2(48.0, 40.0)
	_content.position = (size - _content.size) * 0.5


func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.047, 0.071, 0.82), true)
	var center: Vector2 = size * 0.5
	var chip_size: Vector2 = _chip_size()
	var chip_rect := Rect2(center - chip_size * 0.5, chip_size)
	var ray_limit: float = maxf(0.0, minf(size.x, size.y) * 0.5 - 12.0)
	for index: int in range(16):
		var angle: float = float(index) * TAU / 16.0
		var start: Vector2 = center + Vector2.from_angle(angle) * minf(lerpf(390.0, 170.0, progress), ray_limit)
		var end: Vector2 = center + Vector2.from_angle(angle) * 145.0
		draw_line(start, end, Color(0.31, 0.84, 1.0, 0.2 + 0.65 * progress), 2.5, true)
		var spark: Vector2 = start.lerp(end, fmod(progress * 1.7 + float(index) * 0.07, 1.0))
		draw_circle(spark, 3.5, Color("67e8a5"))
	draw_rect(chip_rect, Color("172033"), true)
	draw_rect(chip_rect, Color("50d5ff"), false, 4.0, true)
	var pulse: float = sin(progress * PI * 4.0) * 0.5 + 0.5
	draw_rect(chip_rect.grow(10.0 + pulse * 7.0), Color(0.31, 0.84, 1.0, 0.18 * (1.0 - progress * 0.45)), false, 3.0, true)
