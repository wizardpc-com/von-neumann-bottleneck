extends Control
## Visual cycle budget for one measured run: compute time, time spent waiting for
## data, and the task's cycle limit. Values come straight from the trace metrics.

const Palette = preload("res://src/lab/lab_palette.gd")

var total: int = 0
var waiting: int = 0
var limit: int = 0
var english: bool = false
var _reveal: float = 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_run(total_cycles: int, wait_cycles: int, limit_cycles: int, use_english: bool) -> void:
	total = maxi(0, total_cycles); waiting = clampi(wait_cycles, 0, total); limit = maxi(0, limit_cycles)
	english = use_english
	visible = total > 0
	tooltip_text = _caption()
	_reveal = 0.0
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		_reveal = value; queue_redraw(), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _caption() -> String:
	var compute: int = total - waiting
	var text: String = ("计算 %d · 等数据 %d" if not english else "compute %d · waiting %d") % [compute, waiting]
	if limit > 0:
		text += ("  ·  上限 %d" if not english else "  ·  limit %d") % limit
	return text

func _draw() -> void:
	if total <= 0: return
	var font: Font = get_theme_default_font()
	var scale_max: float = float(maxi(total, limit)) * 1.08
	var bar := Rect2(0, 8, size.x, 18)
	draw_rect(bar, Palette.TERM_SCREEN)
	var compute_width: float = bar.size.x * float(total - waiting) / scale_max * _reveal
	var wait_width: float = bar.size.x * float(waiting) / scale_max * _reveal
	draw_rect(Rect2(bar.position, Vector2(compute_width, bar.size.y)), Palette.ACCENT)
	var wait_rect := Rect2(bar.position + Vector2(compute_width, 0), Vector2(wait_width, bar.size.y))
	draw_rect(wait_rect, Palette.with_alpha(Palette.SIGNAL_ON, 0.75))
	# Hatching marks waiting as "nothing computed".
	var x: float = wait_rect.position.x
	while x < wait_rect.end.x:
		draw_line(Vector2(x, wait_rect.end.y), Vector2(minf(x + 8.0, wait_rect.end.x), wait_rect.position.y), Palette.with_alpha(Palette.TERM_SCREEN, 0.35), 1.0)
		x += 7.0
	if limit > 0:
		var limit_x: float = bar.size.x * float(limit) / scale_max
		var over: bool = total > limit
		draw_line(Vector2(limit_x, 0), Vector2(limit_x, bar.end.y + 8), Color("e8848c") if over else Palette.GOOD, 3.0)
		draw_string(font, Vector2(limit_x + 4, bar.end.y + 18), ("上限 %d" if not english else "limit %d") % limit, HORIZONTAL_ALIGNMENT_LEFT, 120, 13, Palette.TERM_MUTED)
	var compute: int = total - waiting
	draw_string(font, Vector2(0, bar.end.y + 18), ("计算 %d" if not english else "compute %d") % compute, HORIZONTAL_ALIGNMENT_LEFT, 140, 13, Palette.ACCENT)
	if waiting > 0:
		draw_string(font, Vector2(clampf(compute_width + 4.0, 90.0, size.x - 120.0), bar.end.y + 36), ("等数据 %d 周期" if not english else "waiting %d cycles") % waiting, HORIZONTAL_ALIGNMENT_LEFT, 160, 13, Palette.SIGNAL_ON)
