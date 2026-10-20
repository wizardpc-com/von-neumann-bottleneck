extends Control
## The threshold between the two worlds. Leaving the laboratory, the terminal
## screen collapses into one line of light ("enter"); the next terminal-world
## scene opens out of that same line ("arrive"). Presentation only: it never
## blocks input for longer than its own short animation and is skipped under
## reduced motion.

const Palette = preload("res://src/lab/lab_palette.gd")
const ARRIVE_WINDOW_MS := 4000

## Set by the laboratory just before it changes scene; the next terminal-world
## backdrop that appears soon after plays the arrival.
static var pending_arrival_msec: int = -1
## Last terminal-world scene that left the tree, for in-terminal scene switches.
static var last_exit_msec: int = -1
static var last_exit_scene: int = 0
const SWITCH_WINDOW_MS := 1500

var mode: StringName = &"enter"
var progress: float = 0.0:
	set(value): progress = value; queue_redraw()


static func mark_departure() -> void:
	pending_arrival_msec = Time.get_ticks_msec()


static func take_pending_arrival() -> bool:
	var pending: bool = pending_arrival_msec >= 0 and Time.get_ticks_msec() - pending_arrival_msec <= ARRIVE_WINDOW_MS
	pending_arrival_msec = -1
	return pending


static func mark_terminal_exit(scene: Node) -> void:
	last_exit_msec = Time.get_ticks_msec()
	last_exit_scene = scene.get_instance_id() if scene != null else 0


static func take_switch(scene: Node) -> bool:
	var switching: bool = last_exit_msec >= 0 and Time.get_ticks_msec() - last_exit_msec <= SWITCH_WINDOW_MS \
		and scene != null and scene.get_instance_id() != last_exit_scene
	if switching: last_exit_msec = -1
	return switching


## Plays the arrival over `host`'s whole viewport, then frees itself.
## `quick` is the in-terminal scene switch: shorter, from a dimmer line.
static func play_arrival(host: Node, quick: bool = false) -> void:
	if bool(ProjectSettings.get_setting("game/reduced_motion", false)) or DisplayServer.get_name() == "headless": return
	var layer := CanvasLayer.new(); layer.layer = 95; layer.name = "TerminalArrival"
	var passage: Control = load("res://src/ui/terminal_passage.gd").new()
	passage.mode = &"switch" if quick else &"arrive"
	passage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(passage)
	host.add_child.call_deferred(layer)
	passage.ready.connect(func() -> void:
		var tween := passage.create_tween()
		tween.tween_property(passage, "progress", 1.0, 0.34 if quick else 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_callback(layer.queue_free))


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center_y: float = size.y * 0.5
	if mode == &"enter":
		# The lit screen narrows to a single bright line.
		var p: float = clampf(progress, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Palette.with_alpha(Palette.TERM_SCREEN, clampf(p * 1.6, 0.0, 1.0)))
		var band: float = lerpf(size.y * 0.5, 1.5, ease(p, 0.35))
		var glow: Color = Palette.with_alpha(Palette.ACCENT, 0.10 * p)
		draw_rect(Rect2(0, center_y - band - 18.0, size.x, band * 2.0 + 36.0), glow)
		var width: float = lerpf(size.x, size.x * 0.62, p)
		draw_rect(Rect2((size.x - width) * 0.5, center_y - 1.0, width, 2.0), Palette.with_alpha(Palette.ACCENT, p))
		return
	if mode == &"switch":
		# A quick re-open: the screen dims, then opens from the centre line.
		var t: float = clampf(progress, 0.0, 1.0)
		var opened: float = ease(t, 0.45)
		var cover: float = center_y * (1.0 - opened)
		draw_rect(Rect2(0, 0, size.x, cover), Palette.with_alpha(Palette.TERM_SCREEN, 0.92))
		draw_rect(Rect2(0, size.y - cover, size.x, cover), Palette.with_alpha(Palette.TERM_SCREEN, 0.92))
		for edge: float in [cover, size.y - cover]:
			draw_rect(Rect2(0, edge - 1.0, size.x, 2.0), Palette.with_alpha(Palette.ACCENT, 0.55 * (1.0 - opened)))
		return
	# Arrival: the line spreads, then the dark parts open up and down.
	var q: float = clampf(progress, 0.0, 1.0)
	var spread: float = clampf(q / 0.25, 0.0, 1.0)
	var open: float = ease(clampf((q - 0.18) / 0.82, 0.0, 1.0), 0.4)
	var half: float = center_y * (1.0 - open)
	draw_rect(Rect2(0, 0, size.x, half), Palette.TERM_SCREEN)
	draw_rect(Rect2(0, size.y - half, size.x, half), Palette.TERM_SCREEN)
	var line_alpha: float = 1.0 - open
	var width: float = lerpf(size.x * 0.62, size.x, spread)
	for edge: float in [half, size.y - half]:
		draw_rect(Rect2((size.x - width) * 0.5, edge - 1.0, width, 2.0), Palette.with_alpha(Palette.ACCENT, line_alpha))
		draw_rect(Rect2(0, edge - 10.0, size.x, 20.0), Palette.with_alpha(Palette.ACCENT, 0.06 * line_alpha))
