extends Control
## A quiet ring around the control the guide is pointing at ("look here"). It
## follows the target's on-screen rectangle, breathes twice and fades, so a
## first-time action has a place without a permanent arrow. It never takes
## input, never moves the canvas, and steps aside while a reading layer or a
## blocking window is open. Reduced motion shows a steady ring instead.

const Palette = preload("res://src/lab/lab_palette.gd")
const GuideStage = preload("res://src/ui/guide_stage.gd")
const LIFE := 4.2
const FADE := 0.6

var target: Control
var _life: float = 0.0
var _suppressed: Callable


func _init() -> void:
	name = "GuideHighlight"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 140
	visible = false
	set_process(false)


## `suppressed` (optional) returns true while the owning scene wants guidance quiet.
func point_at(control: Control, suppressed: Callable = Callable()) -> void:
	if control == target and visible: return
	target = control
	_suppressed = suppressed
	_life = 0.0
	visible = control != null
	set_process(visible)
	_follow()


func clear() -> void:
	target = null
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_life += delta
	if _life > LIFE or not _follow():
		clear()
		return
	queue_redraw()


func _follow() -> bool:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree(): return false
	if GuideStage.blocked(get_tree()) or (_suppressed.is_valid() and bool(_suppressed.call())):
		modulate.a = 0.0
		return true
	var rect: Rect2 = target.get_global_rect().grow(5.0)
	global_position = rect.position
	size = rect.size
	var fade_in: float = clampf(_life / 0.2, 0.0, 1.0)
	var fade_out: float = clampf((LIFE - _life) / FADE, 0.0, 1.0)
	modulate.a = minf(fade_in, fade_out)
	return true


func _draw() -> void:
	var reduced: bool = bool(ProjectSettings.get_setting("game/reduced_motion", false))
	var breath: float = 1.0 if reduced else 0.55 + 0.45 * (0.5 + 0.5 * cos(_life * TAU / 1.4))
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_corner_radius_all(9)
	box.set_border_width_all(2)
	box.border_color = Palette.with_alpha(Palette.ACCENT, 0.9 * breath)
	box.shadow_color = Palette.with_alpha(Palette.ACCENT, 0.28 * breath)
	box.shadow_size = 0 if reduced else 6
	draw_style_box(box, Rect2(Vector2.ZERO, size))
