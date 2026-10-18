extends Control
## The laboratory home: a small, bright room with one dark terminal at its
## centre. Layers are drawn in code (replaceable by art: see LAB_ART below) and
## shift slightly with the pointer to give a limited "turn your head" view.
## The terminal screen hosts the real menu; entering zooms into that screen.
##
## The lab is presentation only. Progress comes from TaskNavigation; the lab's
## own record (LabState) only remembers which completions it already answered.

signal start_requested(task_key: String)
signal journey_requested
signal settings_requested
signal quit_requested
signal handbook_requested
signal new_game_requested

const Palette = preload("res://src/lab/lab_palette.gd")
const LabState = preload("res://src/lab/lab_state.gd")
const Fragments = preload("res://src/lab/archive_fragments.gd")
const TerminalType = preload("res://src/lab/lab_terminal.gd")
const ArchiveType = preload("res://src/lab/lab_archive.gd")
const DESIGN := Vector2(1600, 900)
# Optional art overrides. Drop a PNG at these paths (1600×900, transparent where
# the drawn layer should show) and it is used instead of the code-drawn layer.
const LAB_ART := {
	"back": "res://assets/lab/lab-back.png",
	"mid": "res://assets/lab/lab-mid.png",
	"desk": "res://assets/lab/lab-desk.png",
}
const SCREEN_RECT := Rect2(536, 300, 528, 318)
const MONITOR_RECT := Rect2(518, 282, 564, 354)
const PARALLAX := {"back": 7.0, "mid": 13.0, "desk": 20.0, "front": 30.0}

class Painter extends Control:
	var paint: Callable
	func _draw() -> void:
		if paint.is_valid(): paint.call(self)

var english: bool = false
var world: Control
var layers: Dictionary = {}
var terminal: TerminalType
var archive: ArchiveType
var caption: Label
var fade: ColorRect
var base_scale: float = 1.0
var base_offset: Vector2 = Vector2.ZERO
var look: Vector2 = Vector2.ZERO
var look_target: Vector2 = Vector2.ZERO
var time: float = 0.0
var zooming: bool = false
var lamp_level: float = 0.0
var lamp_target: float = 0.0
var station_progress: Array[Dictionary] = []
var station_flash: Dictionary = {}
var fragments_open: int = 0
var fragments_unread: int = 0
var shelf_flash: float = 0.0
var hover_terminal: bool = false
var hover_shelf: bool = false
var hover_board: bool = false
var art: Dictionary = {}
var next_key: String = ""
var reduced_motion: bool = false

func _ready() -> void:
	english = Localization.current_locale() == "en"
	reduced_motion = bool(ProjectSettings.get_setting("game/reduced_motion", false))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	for key: String in LAB_ART:
		if ResourceLoader.exists(LAB_ART[key]): art[key] = load(LAB_ART[key])
	var backdrop := ColorRect.new(); backdrop.name = "LabBackdrop"
	backdrop.color = Palette.LAB_SIDE_DEEP; backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(backdrop)
	world = Control.new(); world.name = "LabWorld"; world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.size = DESIGN; add_child(world)
	_add_layer("back", _paint_back)
	_add_layer("mid", _paint_mid)
	_add_layer("desk", _paint_desk)
	_add_layer("front", _paint_front)
	_build_hotspots()
	terminal = TerminalType.new(); terminal.name = "LabTerminal"
	terminal.position = SCREEN_RECT.position; terminal.size = SCREEN_RECT.size
	layers.desk.add_child(terminal)
	terminal.action.connect(_on_terminal_action)
	caption = Label.new(); caption.name = "LabCaption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", Palette.LAB_INK)
	caption.add_theme_color_override("font_outline_color", Palette.with_alpha(Palette.LAB_LIGHT, 0.85))
	caption.add_theme_constant_override("outline_size", 6)
	caption.anchor_left = 0.0; caption.anchor_right = 1.0; caption.anchor_top = 1.0; caption.anchor_bottom = 1.0
	caption.offset_top = -86; caption.offset_bottom = -52
	caption.modulate.a = 0.0; caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	archive = ArchiveType.new(); archive.name = "LabArchive"; archive.hide()
	add_child(archive)
	archive.closed.connect(_refresh_archive_counts)
	fade = ColorRect.new(); fade.name = "LabFade"; fade.color = Palette.TERM_SCREEN
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); fade.modulate.a = 0.0
	add_child(fade)
	resized.connect(_fit)
	_fit()
	_read_progress()
	call_deferred("_arrive")

func _add_layer(key: String, painter: Callable) -> void:
	var layer := Painter.new(); layer.name = "Layer" + key.capitalize()
	layer.paint = painter; layer.size = DESIGN; layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(layer); layers[key] = layer

func _build_hotspots() -> void:
	# Invisible buttons over the drawn shelf and board keep them keyboard/mouse reachable.
	var shelf := Button.new(); shelf.name = "ArchiveShelf"; shelf.flat = true
	shelf.position = Vector2(60, 250); shelf.size = Vector2(150, 330)
	shelf.tooltip_text = "档案架" if not english else "Archive shelf"
	shelf.focus_mode = Control.FOCUS_NONE
	shelf.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); shelf.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	shelf.add_theme_stylebox_override("pressed", StyleBoxEmpty.new()); shelf.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	shelf.pressed.connect(open_archive)
	shelf.mouse_entered.connect(func() -> void: hover_shelf = true)
	shelf.mouse_exited.connect(func() -> void: hover_shelf = false)
	layers.mid.add_child(shelf)
	var board := Button.new(); board.name = "JourneyBoard"; board.flat = true
	board.position = Vector2(1385, 230); board.size = Vector2(160, 330)
	board.tooltip_text = "旅程板 · 打开任务树" if not english else "Journey board · open the task tree"
	board.focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "focus"]: board.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	board.pressed.connect(func() -> void: _enter(journey_requested))
	board.mouse_entered.connect(func() -> void: hover_board = true)
	board.mouse_exited.connect(func() -> void: hover_board = false)
	layers.mid.add_child(board)

func _fit() -> void:
	if world == null: return
	base_scale = maxf(size.x / DESIGN.x, size.y / DESIGN.y)
	base_offset = (size - DESIGN * base_scale) * 0.5
	if not zooming:
		world.scale = Vector2.ONE * base_scale
		world.position = base_offset

func _process(delta: float) -> void:
	time += delta
	if not zooming and size.x > 0.0:
		var mouse: Vector2 = get_local_mouse_position()
		var inside: bool = Rect2(Vector2.ZERO, size).has_point(mouse)
		look_target = ((mouse / size) - Vector2(0.5, 0.5)) * 2.0 if inside else Vector2.ZERO
		look_target = look_target.clamp(Vector2(-1, -1), Vector2(1, 1))
	var follow: float = 0.0 if reduced_motion else clampf(delta * 3.0, 0.0, 1.0)
	look = look.lerp(Vector2.ZERO if reduced_motion else look_target, follow)
	for key: String in PARALLAX:
		layers[key].position = -look * float(PARALLAX[key])
	var screen_world: Rect2 = Rect2(SCREEN_RECT.position + layers.desk.position, SCREEN_RECT.size)
	var mouse_world: Vector2 = (get_local_mouse_position() - world.position) / world.scale.x
	hover_terminal = screen_world.grow(16).has_point(mouse_world) and not archive.visible
	lamp_level = move_toward(lamp_level, lamp_target, delta * 0.7)
	shelf_flash = maxf(0.0, shelf_flash - delta * 0.25)
	for key: Variant in station_flash.keys():
		station_flash[key] = maxf(0.0, float(station_flash[key]) - delta * 0.3)
	for layer: Control in layers.values(): layer.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if zooming or archive.visible: return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if terminal.asleep():
			terminal.wake(); get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT and hover_terminal and terminal.asleep():
		terminal.wake(); accept_event()

# --- progress and environmental response ----------------------------------

func _read_progress() -> void:
	var rows: Array[Dictionary] = LabState.tasks()
	var completed: Array[String] = LabState.completed_keys(rows)
	station_progress = LabState.station_progress(rows)
	var answered: Array[String] = LabState.seen()
	var first_visit_ever: bool = answered.is_empty() and completed.is_empty()
	var fresh: Array[String] = []
	for key: String in completed:
		if not key in answered: fresh.append(key)
	lamp_target = 1.0 if "hardware_foundations/tutorial" in completed else 0.0
	# The first lamp only warms up in front of the player the first time.
	lamp_level = lamp_target if not "hardware_foundations/tutorial" in fresh else 0.0
	_refresh_archive_counts()
	var new_fragments: Array[Dictionary] = Fragments.newly_unlocked(answered, completed)
	var response: Dictionary = {}
	if not fresh.is_empty():
		var latest: Dictionary = {}
		for row: Dictionary in rows:
			if str(row.key) in fresh: latest = row
		for index: int in station_progress.size():
			for row: Dictionary in rows:
				if str(row.key) in fresh and int(row.region) in LabState.STATIONS[index].regions:
					station_flash[index] = 1.0
		if not new_fragments.is_empty(): shelf_flash = 1.0
		response = {"task": latest, "fresh": fresh.size(), "fragments": new_fragments.size(),
			"first_light": "hardware_foundations/tutorial" in fresh}
	next_key = _next_task(rows, fresh)
	var next_title: String = ""
	for row: Dictionary in rows:
		if str(row.key) == next_key: next_title = str(row.title)
	terminal.configure({
		"next_key": next_key,
		"next_title": next_title,
		"english": english,
		"new_player": completed.is_empty(),
		"first_visit": first_visit_ever,
		"returning": LabState.visits() > 0,
		"response": response,
		"completed": completed.size(),
		"total": rows.size(),
		"fragments": fragments_open,
	})
	LabState.mark_seen(completed)

func _refresh_archive_counts() -> void:
	var completed: Array[String] = LabState.completed_keys(LabState.tasks())
	var unlocked: Array[Dictionary] = Fragments.unlocked(completed)
	var read: Array[String] = LabState.read_fragments()
	fragments_open = unlocked.size()
	fragments_unread = 0
	for fragment: Dictionary in unlocked:
		if not str(fragment.id) in read: fragments_unread += 1
	if terminal != null: terminal.set_fragment_count(fragments_open, fragments_unread)

func _arrive() -> void:
	var returning: bool = LabState.note_visit() > 1
	var response: Dictionary = terminal.response
	if returning:
		# Coming back out of the terminal: start inside the screen and pull back.
		zooming = true
		_apply_zoom(1.0); fade.modulate.a = 1.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(fade, "modulate:a", 0.0, 0.35)
		tween.tween_method(_apply_zoom, 1.0, 0.0, 0.0 if reduced_motion else 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tween.finished
		zooming = false
		terminal.wake(true)
	else:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.6)
	if response.is_empty():
		if not returning: _show_caption("实验室。终端在等你。" if not english else "The laboratory. The terminal is waiting.", 4.0)
		return
	await get_tree().create_timer(0.4).timeout
	if bool(response.get("first_light", false)):
		_show_caption("桌上的灯亮了。" if not english else "The lamp on the desk is lit.", 4.5)
	elif int(response.get("fragments", 0)) > 0:
		_show_caption("档案架上多了一页记录。" if not english else "A new page has arrived on the archive shelf.", 4.5)
	else:
		_show_caption("旅程板上又亮起了一格。" if not english else "Another cell lights up on the journey board.", 4.0)

func _show_caption(text: String, seconds: float) -> void:
	caption.text = text
	var tween := create_tween()
	tween.tween_property(caption, "modulate:a", 1.0, 0.5)
	tween.tween_interval(seconds)
	tween.tween_property(caption, "modulate:a", 0.0, 0.8)

# --- terminal actions and the zoom transition ----------------------------

func _on_terminal_action(id: String) -> void:
	if zooming: return
	match id:
		"start": _enter(start_requested, next_key)
		"journey": _enter(journey_requested)
		"archive": open_archive()
		"settings": settings_requested.emit()
		"handbook": handbook_requested.emit()
		"new_game": new_game_requested.emit()
		"quit": quit_requested.emit()
		"language":
			Localization.set_locale("en" if not english else "zh_CN")
			get_tree().reload_current_scene()

func open_archive() -> void:
	if zooming: return
	archive.present(english)

func _enter(signal_to_emit: Signal, argument: Variant = null) -> void:
	if zooming: return
	zooming = true
	caption.modulate.a = 0.0
	terminal.release_focus_inside()
	var tween := create_tween().set_parallel(true)
	var duration: float = 0.05 if reduced_motion else 0.75
	tween.tween_method(_apply_zoom, 0.0, 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade, "modulate:a", 1.0, duration * 0.45).set_delay(duration * 0.6)
	await tween.finished
	var tree: SceneTree = get_tree()
	if argument == null: signal_to_emit.emit()
	else: signal_to_emit.emit(argument)
	# If navigation did not leave this scene (e.g. nothing to open), come back out.
	await tree.create_timer(0.6).timeout
	if is_instance_valid(self) and is_inside_tree():
		var back := create_tween().set_parallel(true)
		back.tween_property(fade, "modulate:a", 0.0, 0.3)
		back.tween_method(_apply_zoom, 1.0, 0.0, 0.5)
		await back.finished
		zooming = false

func _apply_zoom(amount: float) -> void:
	var screen := Rect2(SCREEN_RECT.position + layers.desk.position, SCREEN_RECT.size)
	var full_scale: float = maxf(size.x / screen.size.x, size.y / screen.size.y) * 1.04
	var eased: float = clampf(amount, 0.0, 1.0)
	# Interpolate scale geometrically so the push-in feels like one camera move.
	var scale_now: float = base_scale * pow(full_scale / base_scale, eased)
	world.scale = Vector2.ONE * scale_now
	var center_base: Vector2 = base_offset + screen.get_center() * base_scale
	var center_now: Vector2 = center_base.lerp(size * 0.5, eased)
	world.position = center_now - screen.get_center() * scale_now

# --- drawing --------------------------------------------------------------

func _quad(canvas: CanvasItem, points: Array, colors: Array) -> void:
	var packed := PackedVector2Array(points)
	var tints := PackedColorArray(colors if colors.size() == points.size() else [colors[0], colors[0], colors[0], colors[0]])
	canvas.draw_polygon(packed, tints)

static func _left_wall(u: float, v: float) -> Vector2:
	var x: float = lerpf(0.0, 250.0, u)
	return Vector2(x, lerpf(lerpf(0.0, 90.0, u), lerpf(900.0, 560.0, u), v))

static func _right_wall(u: float, v: float) -> Vector2:
	var x: float = lerpf(1350.0, 1600.0, u)
	return Vector2(x, lerpf(lerpf(90.0, 0.0, u), lerpf(560.0, 900.0, u), v))

func _paint_back(canvas: Control) -> void:
	if art.has("back"):
		canvas.draw_texture_rect(art.back, Rect2(Vector2.ZERO, DESIGN), false); return
	# Ceiling with one long soft light panel.
	_quad(canvas, [Vector2(-60, -40), Vector2(1660, -40), Vector2(1350, 90), Vector2(250, 90)],
		[Palette.LAB_CEILING, Palette.LAB_CEILING, Palette.LAB_WALL_TOP, Palette.LAB_WALL_TOP])
	_quad(canvas, [Vector2(560, 22), Vector2(1040, 22), Vector2(1010, 58), Vector2(590, 58)],
		[Palette.LAB_LIGHT, Palette.LAB_LIGHT, Palette.LAB_LIGHT, Palette.LAB_LIGHT])
	for ring: int in 4:
		canvas.draw_rect(Rect2(590 - ring * 26, 58 + ring * 4, 420 + ring * 52, 10), Palette.with_alpha(Palette.LAB_LIGHT, 0.10 - ring * 0.02))
	# Back wall.
	_quad(canvas, [Vector2(250, 90), Vector2(1350, 90), Vector2(1350, 560), Vector2(250, 560)],
		[Palette.LAB_WALL_TOP, Palette.LAB_WALL_TOP, Palette.LAB_WALL, Palette.LAB_WALL])
	# Panel seams give the wall a built, maintained surface.
	for x: float in [430.0, 1170.0]:
		canvas.draw_line(Vector2(x, 92), Vector2(x, 558), Palette.with_alpha(Palette.LAB_LINE, 0.35), 1.0)
	canvas.draw_line(Vector2(250, 468), Vector2(1350, 468), Palette.with_alpha(Palette.LAB_LINE, 0.28), 1.0)
	# A wide frosted window onto a quiet city.
	var window := Rect2(520, 128, 560, 196)
	_quad(canvas, [window.position, Vector2(window.end.x, window.position.y), window.end, Vector2(window.position.x, window.end.y)],
		[Palette.LAB_SKY_TOP, Palette.LAB_SKY_TOP, Palette.LAB_SKY_LOW, Palette.LAB_SKY_LOW])
	var towers := [[548, 70, 18], [590, 120, 26], [640, 92, 20], [700, 150, 34], [770, 110, 22], [820, 170, 40], [890, 128, 24], [945, 96, 30], [1010, 140, 22], [1050, 84, 18]]
	for tower: Array in towers:
		var h: float = float(tower[1]); var w: float = float(tower[2])
		canvas.draw_rect(Rect2(float(tower[0]), window.end.y - h, w, h), Color(0.78, 0.86, 0.9, 0.55))
		canvas.draw_circle(Vector2(float(tower[0]) + w * 0.5, window.end.y - h), w * 0.5, Color(0.78, 0.86, 0.9, 0.55))
	canvas.draw_rect(Rect2(window.position.x, window.end.y - 26, window.size.x, 26), Color(0.84, 0.9, 0.92, 0.6))
	for i: int in range(1, 4):
		var mx: float = window.position.x + window.size.x * i / 4.0
		canvas.draw_line(Vector2(mx, window.position.y), Vector2(mx, window.end.y), Palette.LAB_TRIM, 3.0)
	canvas.draw_rect(window, Palette.LAB_TRIM, false, 5.0)
	canvas.draw_rect(Rect2(window.position.x - 10, window.end.y, window.size.x + 20, 8), Palette.DESK_EDGE)
	# Title plaque, part of the room rather than a menu header.
	var font: Font = get_theme_default_font()
	canvas.draw_string(font, Vector2(282, 168), "冯·诺依曼瓶颈" if not english else "Von Neumann Bottleneck", HORIZONTAL_ALIGNMENT_LEFT, 230, 26 if not english else 20, Palette.LAB_INK)
	canvas.draw_string(font, Vector2(283, 196), "A Thought Within the World", HORIZONTAL_ALIGNMENT_LEFT, 230, 13, Palette.LAB_INK_SOFT)
	canvas.draw_line(Vector2(283, 208), Vector2(470, 208), Palette.with_alpha(Palette.LAB_LINE, 0.6), 1.0)
	# Floor far band.
	_quad(canvas, [Vector2(250, 560), Vector2(1350, 560), Vector2(1660, 940), Vector2(-60, 940)],
		[Palette.LAB_FLOOR_FAR, Palette.LAB_FLOOR_FAR, Palette.LAB_FLOOR_NEAR, Palette.LAB_FLOOR_NEAR])
	for i: int in range(1, 7):
		var t: float = float(i) / 7.0
		var y: float = lerpf(560.0, 940.0, t * t)
		canvas.draw_line(Vector2(lerpf(250.0, -60.0, t * t), y), Vector2(lerpf(1350.0, 1660.0, t * t), y), Palette.with_alpha(Palette.LAB_LINE, 0.18), 1.0)
	# Window light falling on the floor.
	_quad(canvas, [Vector2(560, 562), Vector2(1040, 562), Vector2(1180, 700), Vector2(430, 700)],
		[Palette.with_alpha(Palette.LAB_LIGHT, 0.35), Palette.with_alpha(Palette.LAB_LIGHT, 0.35), Palette.with_alpha(Palette.LAB_LIGHT, 0.0), Palette.with_alpha(Palette.LAB_LIGHT, 0.0)])

func _paint_mid(canvas: Control) -> void:
	if art.has("mid"):
		canvas.draw_texture_rect(art.mid, Rect2(Vector2.ZERO, DESIGN), false)
	else:
		_quad(canvas, [Vector2(-60, -60), Vector2(250, 90), Vector2(250, 560), Vector2(-60, 960)],
			[Palette.LAB_SIDE_DEEP, Palette.LAB_SIDE, Palette.LAB_SIDE, Palette.LAB_SIDE_DEEP])
		_quad(canvas, [Vector2(1350, 90), Vector2(1660, -60), Vector2(1660, 960), Vector2(1350, 560)],
			[Palette.LAB_SIDE, Palette.LAB_SIDE_DEEP, Palette.LAB_SIDE_DEEP, Palette.LAB_SIDE])
		canvas.draw_line(Vector2(250, 90), Vector2(250, 560), Palette.with_alpha(Palette.LAB_LINE, 0.5), 1.5)
		canvas.draw_line(Vector2(1350, 90), Vector2(1350, 560), Palette.with_alpha(Palette.LAB_LINE, 0.5), 1.5)
	_paint_shelf(canvas)
	_paint_board(canvas)

func _paint_shelf(canvas: Control) -> void:
	# Archive shelf on the left wall: one cell per fragment, lit when opened.
	var u0: float = 0.28; var u1: float = 0.82; var v0: float = 0.26; var v1: float = 0.66
	var frame_color: Color = Palette.LAB_TRIM if not hover_shelf else Palette.ACCENT_DEEP
	_quad(canvas, [_left_wall(u0, v0), _left_wall(u1, v0), _left_wall(u1, v1), _left_wall(u0, v1)],
		[Palette.LAB_SIDE_DEEP, Palette.LAB_TRIM, Palette.LAB_TRIM, Palette.LAB_SIDE_DEEP])
	var outline := PackedVector2Array([_left_wall(u0, v0), _left_wall(u1, v0), _left_wall(u1, v1), _left_wall(u0, v1), _left_wall(u0, v0)])
	canvas.draw_polyline(outline, frame_color, 2.0 if not hover_shelf else 3.0)
	var count: int = Fragments.FRAGMENTS.size()
	var rows: int = int(ceil(count / 2.0))
	for index: int in count:
		var column: int = index % 2; var row: int = index / 2
		var cu0: float = lerpf(u0, u1, 0.08 + column * 0.46); var cu1: float = cu0 + (u1 - u0) * 0.38
		var cv0: float = lerpf(v0, v1, 0.06 + row * 0.88 / rows); var cv1: float = cv0 + (v1 - v0) * 0.88 / rows * 0.72
		var lit: bool = index < fragments_open
		var color: Color = Palette.with_alpha(Palette.LAB_LINE, 0.55)
		if lit:
			var unread_pulse: float = 0.0
			if index >= fragments_open - fragments_unread: unread_pulse = 0.25 + 0.25 * sin(time * 2.4)
			color = Palette.with_alpha(Palette.ACCENT_DEEP, 0.55 + unread_pulse + shelf_flash * 0.3)
		_quad(canvas, [_left_wall(cu0, cv0), _left_wall(cu1, cv0), _left_wall(cu1, cv1), _left_wall(cu0, cv1)], [color])
		var handle: Vector2 = (_left_wall(cu0, (cv0 + cv1) * 0.5) + _left_wall(cu1, (cv0 + cv1) * 0.5)) * 0.5
		canvas.draw_line(handle + Vector2(-5, 0), handle + Vector2(5, 0), Palette.LAB_LIGHT if lit else Palette.LAB_TRIM, 2.0)
	var label_at: Vector2 = _left_wall(u0, v0) + Vector2(2, -12)
	var font: Font = get_theme_default_font()
	var text: String = ("档案架 · %d 页" if not english else "Archive · %d") % fragments_open
	if fragments_unread > 0: text += ("  · %d 新" if not english else "  · %d new") % fragments_unread
	canvas.draw_string(font, label_at, text, HORIZONTAL_ALIGNMENT_LEFT, 180, 15, Palette.LAB_INK if hover_shelf else Palette.LAB_INK_SOFT)

func _paint_board(canvas: Control) -> void:
	# Journey board on the right wall: eleven stations, top to bottom.
	var u0: float = 0.12; var u1: float = 0.78; var v0: float = 0.17; var v1: float = 0.71
	_quad(canvas, [_right_wall(u0, v0), _right_wall(u1, v0), _right_wall(u1, v1), _right_wall(u0, v1)],
		[Palette.TERM_PANEL, Palette.TERM_BODY, Palette.TERM_BODY, Palette.TERM_PANEL])
	var outline := PackedVector2Array([_right_wall(u0, v0), _right_wall(u1, v0), _right_wall(u1, v1), _right_wall(u0, v1), _right_wall(u0, v0)])
	canvas.draw_polyline(outline, Palette.ACCENT if hover_board else Palette.TERM_EDGE, 3.0 if hover_board else 2.0)
	var font: Font = get_theme_default_font()
	canvas.draw_string(font, _right_wall(u0, v0) + Vector2(2, -12), "旅程板" if not english else "Journey", HORIZONTAL_ALIGNMENT_LEFT, 140, 15, Palette.LAB_INK if hover_board else Palette.LAB_INK_SOFT)
	var count: int = station_progress.size()
	var points: Array[Vector2] = []
	for index: int in count:
		var t: float = (index + 0.5) / float(maxi(count, 1))
		points.append(_right_wall(lerpf(u0, u1, 0.2), lerpf(v0, v1, 0.04 + t * 0.92)))
	for index: int in range(1, points.size()):
		var done_before: bool = station_progress[index - 1].done > 0
		canvas.draw_line(points[index - 1], points[index], Palette.with_alpha(Palette.ACCENT, 0.6 if done_before else 0.16), 2.0)
	for index: int in points.size():
		var station: Dictionary = station_progress[index]
		var fraction: float = float(station.done) / float(maxi(1, int(station.total)))
		var flash: float = float(station_flash.get(index, 0.0))
		var radius: float = 6.5 + flash * 3.0 * (0.5 + 0.5 * sin(time * 6.0))
		if flash > 0.0:
			canvas.draw_circle(points[index], 14.0 * flash + 7.0, Palette.with_alpha(Palette.ACCENT, 0.28 * flash))
		canvas.draw_circle(points[index], radius + 2.5, Palette.TERM_BEZEL)
		canvas.draw_arc(points[index], radius, 0.0, TAU, 24, Palette.with_alpha(Palette.TERM_MUTED, 0.45), 1.5)
		if fraction > 0.0:
			canvas.draw_arc(points[index], radius, -PI / 2.0, -PI / 2.0 + TAU * fraction, 24, Palette.ACCENT, 2.5)
			canvas.draw_circle(points[index], 3.0, Palette.SIGNAL_ON if fraction >= 1.0 else Palette.ACCENT)
		var label_color: Color = Palette.with_alpha(Palette.TERM_TEXT, 0.92 if fraction > 0.0 else 0.55)
		canvas.draw_string(font, points[index] + Vector2(15, 5), str(station.en if english else station.zh), HORIZONTAL_ALIGNMENT_LEFT, 80, 13, label_color)
		if int(station.total) > 0:
			canvas.draw_string(font, points[index] + Vector2(64, 5), "%d/%d" % [int(station.done), int(station.total)], HORIZONTAL_ALIGNMENT_LEFT, 50, 11, Palette.with_alpha(Palette.TERM_MUTED, 0.8))

func _paint_desk(canvas: Control) -> void:
	if art.has("desk"):
		canvas.draw_texture_rect(art.desk, Rect2(Vector2.ZERO, DESIGN), false)
		_paint_screen_glow(canvas)
		return
	# Floor shadow, legs, desk slab.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(300, 860), Vector2(1300, 860), Vector2(1240, 900), Vector2(360, 900)]), Palette.DESK_SHADOW)
	for x: float in [360.0, 1210.0]:
		_quad(canvas, [Vector2(x, 760), Vector2(x + 30, 760), Vector2(x + 30, 880), Vector2(x, 880)], [Palette.DESK_EDGE, Palette.DESK_EDGE, Palette.LAB_TRIM, Palette.LAB_TRIM])
	_quad(canvas, [Vector2(420, 640), Vector2(1180, 640), Vector2(1270, 736), Vector2(330, 736)],
		[Palette.DESK_TOP, Palette.DESK_TOP, Palette.LAB_LIGHT, Palette.LAB_LIGHT])
	_quad(canvas, [Vector2(330, 736), Vector2(1270, 736), Vector2(1270, 762), Vector2(330, 762)], [Palette.DESK_EDGE])
	canvas.draw_line(Vector2(330, 736), Vector2(1270, 736), Palette.LAB_LIGHT, 2.0)
	# Desk lamp: the "first light" responds to the first real completion.
	_paint_lamp(canvas)
	# Small plant: someone looks after this room.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(1110, 676), Vector2(1158, 676), Vector2(1150, 716), Vector2(1118, 716)]), Palette.DESK_EDGE)
	for leaf: Array in [[1120, 640, -0.5], [1134, 628, 0.0], [1148, 640, 0.5], [1128, 652, -0.9], [1142, 652, 0.9]]:
		var center := Vector2(float(leaf[0]), float(leaf[1]))
		var direction := Vector2.UP.rotated(float(leaf[2]))
		var normal := direction.orthogonal() * 7.0
		canvas.draw_colored_polygon(PackedVector2Array([center + direction * 26.0, center + normal, center - direction * 14.0 + Vector2(0, 20), center - normal]), Palette.LAB_PLANT)
	# Terminal: body, stand, keyboard.
	_paint_screen_glow(canvas)
	_quad(canvas, [Vector2(774, 630), Vector2(826, 630), Vector2(838, 656), Vector2(762, 656)], [Palette.TERM_BODY])
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(728, 656), Vector2(872, 656), Vector2(886, 668), Vector2(714, 668)]), Palette.TERM_BEZEL)
	_rounded(canvas, MONITOR_RECT.grow(2), Palette.TERM_EDGE, 20)
	_rounded(canvas, MONITOR_RECT, Palette.TERM_BODY, 18)
	_rounded(canvas, SCREEN_RECT.grow(4), Palette.TERM_BEZEL, 11)
	var wake_glow: float = 0.0
	if terminal != null and terminal.asleep(): wake_glow = 0.10 + 0.08 * sin(time * 2.2)
	_rounded(canvas, SCREEN_RECT, Palette.TERM_SCREEN.lerp(Palette.ACCENT_DEEP, wake_glow + (0.08 if hover_terminal else 0.0)), 9)
	canvas.draw_circle(Vector2(MONITOR_RECT.get_center().x, MONITOR_RECT.end.y - 9), 2.5, Palette.with_alpha(Palette.ACCENT, 0.6 if terminal != null and not terminal.asleep() else 0.25))
	_quad(canvas, [Vector2(648, 676), Vector2(952, 676), Vector2(980, 712), Vector2(620, 712)], [Palette.TERM_BODY])
	for row: int in 3:
		var y: float = 683.0 + row * 9.0
		var inset: float = 6.0 + row * 7.0
		canvas.draw_line(Vector2(654 - inset * 0.6 + 14, y), Vector2(946 + inset * 0.6 - 14, y), Palette.with_alpha(Palette.TERM_MUTED, 0.25), 1.0)

func _paint_screen_glow(canvas: Control) -> void:
	var awake: bool = terminal != null and not terminal.asleep()
	var strength: float = 0.11 if awake else 0.05
	if hover_terminal: strength += 0.05
	for ring: int in 5:
		_rounded(canvas, MONITOR_RECT.grow(18.0 + ring * 22.0), Palette.with_alpha(Palette.ACCENT, strength * (1.0 - ring / 5.0) * 0.5), 40 + ring * 20)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(600, 645), Vector2(1000, 645), Vector2(1090, 730), Vector2(510, 730)]), Palette.with_alpha(Palette.ACCENT, strength * 0.6))

func _paint_lamp(canvas: Control) -> void:
	var base := Vector2(404, 694)
	var joint := Vector2(380, 584)
	var head := Vector2(440, 520)
	if lamp_level > 0.0:
		for ring: int in 5:
			canvas.draw_circle(head + Vector2(2, 14), 26.0 + ring * 18.0, Palette.with_alpha(Palette.LAB_WARM, 0.16 * lamp_level * (1.0 - ring / 5.0)))
		canvas.draw_colored_polygon(PackedVector2Array([head + Vector2(-20, 12), head + Vector2(26, 6), Vector2(520, 716), Vector2(352, 720)]), Palette.with_alpha(Palette.LAB_WARM, 0.42 * lamp_level))
		for ring: int in 4:
			canvas.draw_circle(Vector2(436, 712), 60.0 + ring * 24.0, Palette.with_alpha(Palette.LAB_WARM, 0.16 * lamp_level * (1.0 - ring / 4.0)))
	canvas.draw_colored_polygon(PackedVector2Array([base + Vector2(-34, 6), base + Vector2(34, 6), base + Vector2(26, -6), base + Vector2(-26, -6)]), Palette.LAB_INK_SOFT)
	canvas.draw_line(base + Vector2(0, -6), joint, Palette.LAB_INK_SOFT, 5.0)
	canvas.draw_line(joint, head, Palette.LAB_INK_SOFT, 5.0)
	canvas.draw_circle(joint, 5.0, Palette.LAB_INK)
	var shade := PackedVector2Array([head + Vector2(-26, 2), head + Vector2(-8, -20), head + Vector2(30, -6), head + Vector2(26, 14)])
	canvas.draw_colored_polygon(shade, Palette.LAB_INK.lerp(Palette.LAB_INK_SOFT, 0.4))
	canvas.draw_circle(head + Vector2(2, 12), 7.0, Palette.LAB_TRIM.lerp(Palette.SIGNAL_ON, lamp_level))

func _paint_front(canvas: Control) -> void:
	# Soft vignette keeps focus on the desk.
	for ring: int in 6:
		var alpha: float = 0.035 * (6 - ring) / 6.0
		canvas.draw_rect(Rect2(Vector2(-80, -80) + Vector2(ring, ring) * 26.0, DESIGN + Vector2(160, 160) - Vector2(ring, ring) * 52.0), Color(0.2, 0.27, 0.31, alpha), false, 26.0)

func _rounded(canvas: CanvasItem, rect: Rect2, color: Color, radius: int) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	canvas.draw_style_box(box, rect)


# After a completion, suggest the next open task instead of reopening a finished one.
func _next_task(rows: Array[Dictionary], fresh: Array[String]) -> String:
	var navigation: Node = get_node_or_null("/root/TaskNavigation")
	var target: String = str(navigation.next_task_key()) if navigation != null else ""
	var target_done: bool = false
	for row: Dictionary in rows:
		if str(row.key) == target: target_done = bool(row.completed)
	if not target_done and not target.is_empty(): return target
	var start: int = 0
	for index: int in rows.size():
		if str(rows[index].key) in fresh or str(rows[index].key) == target: start = index
	for offset: int in rows.size():
		var row: Dictionary = rows[(start + offset) % rows.size()]
		if bool(row.unlocked) and not bool(row.completed) and not bool(row.get("optional", false)): return str(row.key)
	return target
