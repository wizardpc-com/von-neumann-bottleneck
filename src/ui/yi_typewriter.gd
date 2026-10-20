extends Control
## Yi's spoken text: fast character-by-character output with the trailing
## caret (assets/narrative/yi_text_caret_*.svg) right after the last shown
## character. The caret means "this passage is being written"; it is not Yi's
## avatar or logo, and it never appears on system facts, buttons or titles.
## Spec: briefs/team-input 壹的卡片与文字尾随光标交互规范 v0.3 §3 and §6.1.
##
## The control lays out the complete text first (so cards never grow while
## characters appear), then draws only the shown glyphs and places the caret
## from the shaped glyph advances of the actual wrapped line.

signal finished

const Palette = preload("res://src/lab/lab_palette.gd")
const CARETS := {
	16: preload("res://assets/narrative/yi_text_caret_16.svg"),
	24: preload("res://assets/narrative/yi_text_caret_24.svg"),
	32: preload("res://assets/narrative/yi_text_caret_32.svg"),
}
## Visible characters per second; "instant" shows the whole passage at once.
const SPEEDS := {"slow": 22.0, "standard": 35.0, "fast": 60.0, "instant": 0.0}
const SPEED_SETTING := "game/yi_text_speed"
const CARET_GAP := 3.0
const BLINK_PERIOD := 1.05

## Passages already shown in full this session; rereading shows them at once.
static var _seen: Dictionary = {}

var font: Font
var font_size: int = 17:
	set(value): font_size = value; _invalidate()
var font_color: Color = Palette.TERM_TEXT:
	set(value): font_color = value; queue_redraw()
var line_spacing: float = 4.0:
	set(value): line_spacing = value; _invalidate()
var center_lines: bool = false:
	set(value): center_lines = value; queue_redraw()
## When set, Enter/Space while the passage is still appearing only completes
## the text, as long as keyboard focus is inside this control.
var skip_scope: Control
## -1 follows the global setting; 0/1 forces reduced motion off/on.
var reduced_motion_override: int = -1

var text: String = ""
var shown: int = 0
var _playing: bool = false
var _caret_active: bool = false
var _progress: float = 0.0
var _speed: float = 35.0
var _blink: float = 0.0
var _paragraph := TextParagraph.new()
var _layout_width: float = -1.0
var _layout_dirty: bool = true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_process(false)
	set_process_input(false)


## Show `value` as Yi's passage. New passages appear at the configured speed;
## passages already read in full appear immediately unless `replay` is true.
func play(value: String, replay: bool = false) -> void:
	text = value
	_invalidate()
	_caret_active = not value.is_empty()
	_blink = 0.0
	_progress = 0.0
	_speed = speed_setting()
	var instant: bool = value.is_empty() or reduced_motion() or _speed <= 0.0 \
		or (not replay and _seen.has(value.hash()))
	if instant:
		shown = value.length()
		_playing = false
		_after_complete(false)
	else:
		shown = 0
		_playing = true
	_refresh_processing()
	queue_redraw()


## Lay out `value` without showing it yet (cards size themselves to the full
## passage before a delayed play()).
func prepare(value: String) -> void:
	text = value
	shown = 0
	_playing = false
	_caret_active = false
	_invalidate()
	_refresh_processing()


## Show the whole passage now with the caret at its end. Returns false when
## nothing was still appearing, so callers can treat the event as their own.
func complete_now() -> bool:
	if not _playing: return false
	shown = text.length()
	_playing = false
	_after_complete(true)
	_refresh_processing()
	queue_redraw()
	return true


## Close the passage: the caret disappears and any running output stops.
func stop() -> void:
	_playing = false
	_caret_active = false
	_refresh_processing()
	queue_redraw()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion_override = 1 if enabled else 0
	if enabled: complete_now()
	_refresh_processing()
	queue_redraw()


func is_playing() -> bool:
	return _playing


func caret_visible() -> bool:
	return _caret_active and not text.is_empty() and is_visible_in_tree()


func shown_text() -> String:
	return text.substr(0, shown)


func reduced_motion() -> bool:
	if reduced_motion_override >= 0: return reduced_motion_override == 1
	return bool(ProjectSettings.get_setting("game/reduced_motion", false))


static func speed_setting() -> float:
	return float(SPEEDS.get(str(ProjectSettings.get_setting(SPEED_SETTING, "standard")), 35.0))


## Forget which passages were read (tests and language reloads).
static func reset_seen() -> void:
	_seen.clear()


func _after_complete(emit_now: bool) -> void:
	_seen[text.hash()] = true
	if emit_now: finished.emit()
	else: finished.emit.call_deferred()


func _refresh_processing() -> void:
	var in_tree: bool = is_inside_tree() and is_visible_in_tree()
	set_process(in_tree and (_playing or (_caret_active and not reduced_motion())))
	set_process_input(in_tree and _playing and skip_scope != null)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if not is_equal_approx(size.x, _layout_width): _invalidate()
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_ENTER_TREE:
			_refresh_processing()
		NOTIFICATION_THEME_CHANGED:
			_invalidate()


func _process(delta: float) -> void:
	if _playing:
		_progress += delta * _speed
		var target: int = mini(text.length(), int(_progress))
		if target != shown:
			shown = target
			queue_redraw()
		if shown >= text.length():
			_playing = false
			_after_complete(true)
			_refresh_processing()
	else:
		_blink = fmod(_blink + delta, BLINK_PERIOD)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT and complete_now():
		accept_event()


func _input(event: InputEvent) -> void:
	if not _playing or skip_scope == null or not event.is_action_pressed("ui_accept") or event.is_echo(): return
	var owner_control: Control = get_viewport().gui_get_focus_owner()
	if owner_control == null or not (skip_scope == owner_control or skip_scope.is_ancestor_of(owner_control)): return
	if complete_now(): get_viewport().set_input_as_handled()


func _invalidate() -> void:
	_layout_dirty = true
	update_minimum_size()
	queue_redraw()


func _font() -> Font:
	return font if font != null else get_theme_font("font", "Label")


func _caret_height() -> float:
	var resolved: Font = _font()
	var line: float = resolved.get_height(font_size) if resolved != null else float(font_size) * 1.4
	# Even heights keep the 1:2 outline on whole pixels.
	return roundf(clampf(line * 0.92, 12.0, 34.0) * 0.5) * 2.0


func _caret_size() -> Vector2:
	var height: float = _caret_height()
	return Vector2(roundf(height * 0.5), height)


func _ensure_layout() -> void:
	if not _layout_dirty and is_equal_approx(size.x, _layout_width): return
	_layout_dirty = false
	_layout_width = size.x
	_paragraph.clear()
	# Reserve the caret's width so a full line never pushes it outside the box.
	_paragraph.width = maxf(24.0, size.x - _caret_size().x - CARET_GAP)
	_paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var resolved: Font = _font()
	if resolved != null and not text.is_empty():
		_paragraph.add_string(text, resolved, font_size)


func _get_minimum_size() -> Vector2:
	_ensure_layout()
	var height: float = 0.0
	var count: int = _paragraph.get_line_count()
	for line: int in count:
		height += _paragraph.get_line_ascent(line) + _paragraph.get_line_descent(line)
	if count > 1: height += line_spacing * float(count - 1)
	if count == 0 and _font() != null: height = _font().get_height(font_size)
	return Vector2(0.0, ceilf(height))


func _line_x(line: int) -> float:
	if not center_lines: return 0.0
	return floorf(maxf(0.0, (_paragraph.width - _paragraph.get_line_width(line)) * 0.5))


## Local rectangle of the trailing caret, or an empty Rect2 when hidden.
func caret_rect() -> Rect2:
	if not _caret_active or text.is_empty(): return Rect2()
	_ensure_layout()
	var count: int = _paragraph.get_line_count()
	if count == 0: return Rect2()
	# The caret follows the last shown character; after an explicit line break
	# it moves to the start of the following line.
	var anchor: int = maxi(0, shown - 1)
	var after_break: bool = shown > 0 and text.unicode_at(shown - 1) == 10
	if after_break: anchor = shown
	var y: float = 0.0
	var target_line: int = count - 1
	var target_y: float = 0.0
	for line: int in count:
		var line_range: Vector2i = _paragraph.get_line_range(line)
		if anchor >= line_range.x and anchor < line_range.y:
			target_line = line; target_y = y; break
		y += _paragraph.get_line_ascent(line) + _paragraph.get_line_descent(line) + line_spacing
		if line == count - 1: target_y = y - (_paragraph.get_line_ascent(line) + _paragraph.get_line_descent(line) + line_spacing)
	var x: float = _line_x(target_line)
	if not after_break or _paragraph.get_line_range(target_line).x < shown:
		x += _advance_until(_paragraph.get_line_rid(target_line), shown)
	var line_height: float = _paragraph.get_line_ascent(target_line) + _paragraph.get_line_descent(target_line)
	var caret: Vector2 = _caret_size()
	return Rect2(Vector2(roundf(x + CARET_GAP), roundf(target_y + (line_height - caret.y) * 0.5)), caret)


func _advance_until(line_rid: RID, limit: int) -> float:
	var total: float = 0.0
	for glyph: Dictionary in TextServerManager.get_primary_interface().shaped_text_get_glyphs(line_rid):
		if int(glyph.get("end", 0)) > limit: break
		total += float(glyph.get("advance", 0.0)) * float(maxi(1, int(glyph.get("repeat", 1))))
	return total


func _draw() -> void:
	if text.is_empty(): return
	_ensure_layout()
	var server: TextServer = TextServerManager.get_primary_interface()
	var canvas: RID = get_canvas_item()
	var y: float = 0.0
	for line: int in _paragraph.get_line_count():
		var line_range: Vector2i = _paragraph.get_line_range(line)
		var ascent: float = _paragraph.get_line_ascent(line)
		if line_range.x >= shown: break
		var pen := Vector2(_line_x(line), y + ascent)
		for glyph: Dictionary in server.shaped_text_get_glyphs(_paragraph.get_line_rid(line)):
			if int(glyph.get("end", 0)) > shown: break
			var advance: float = float(glyph.get("advance", 0.0))
			var font_rid: RID = glyph.get("font_rid", RID())
			for repeat: int in maxi(1, int(glyph.get("repeat", 1))):
				if font_rid.is_valid():
					server.font_draw_glyph(font_rid, canvas, int(glyph.get("font_size", font_size)),
						pen + glyph.get("offset", Vector2.ZERO), int(glyph.get("index", 0)), font_color)
				pen.x += advance
		y += ascent + _paragraph.get_line_descent(line) + line_spacing
	var caret: Rect2 = caret_rect()
	if caret.size.x <= 0.0: return
	var alpha: float = 1.0
	if not _playing and not reduced_motion():
		alpha = 0.32 + 0.68 * (0.5 + 0.5 * cos(TAU * _blink / BLINK_PERIOD))
	draw_texture_rect(_caret_texture(caret.size.y), caret, false, Color(1, 1, 1, alpha))


func _caret_texture(height: float) -> Texture2D:
	if height <= 18.0: return CARETS[16]
	if height <= 27.0: return CARETS[24]
	return CARETS[32]
