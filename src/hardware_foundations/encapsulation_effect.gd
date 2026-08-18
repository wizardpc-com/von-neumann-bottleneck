class_name EncapsulationEffect
extends Control

var active: bool = false
var progress: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


func begin() -> void:
	active = true
	progress = 0.0
	show()
	queue_redraw()


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func finish() -> void:
	active = false
	hide()


func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.047, 0.071, 0.82), true)
	var center: Vector2 = size * 0.5
	var chip_size: Vector2 = Vector2(lerpf(360.0, 270.0, progress), lerpf(180.0, 145.0, progress))
	var chip_rect := Rect2(center - chip_size * 0.5, chip_size)
	for index: int in range(16):
		var angle: float = float(index) * TAU / 16.0
		var start: Vector2 = center + Vector2.from_angle(angle) * lerpf(390.0, 170.0, progress)
		var end: Vector2 = center + Vector2.from_angle(angle) * 145.0
		draw_line(start, end, Color(0.31, 0.84, 1.0, 0.2 + 0.65 * progress), 2.5, true)
		var spark: Vector2 = start.lerp(end, fmod(progress * 1.7 + float(index) * 0.07, 1.0))
		draw_circle(spark, 3.5, Color("67e8a5"))
	draw_rect(chip_rect, Color("172033"), true)
	draw_rect(chip_rect, Color("50d5ff"), false, 4.0, true)
	var pulse: float = sin(progress * PI * 4.0) * 0.5 + 0.5
	draw_rect(chip_rect.grow(10.0 + pulse * 7.0), Color(0.31, 0.84, 1.0, 0.18 * (1.0 - progress * 0.45)), false, 3.0, true)
	var title: String = "SEALING PLAYER TOPOLOGY" if progress < 0.72 else "HalfAdder CREATED"
	draw_string(ThemeDB.fallback_font, center + Vector2(-155.0, -12.0), title, HORIZONTAL_ALIGNMENT_CENTER, 310.0, 22, Color("e9f0fa"))
	draw_string(ThemeDB.fallback_font, center + Vector2(-145.0, 24.0), "A  B    →    SUM  CARRY", HORIZONTAL_ALIGNMENT_CENTER, 290.0, 16, Color("67e8a5"))
