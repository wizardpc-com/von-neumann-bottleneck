extends CanvasLayer
## The opening of a level: Yi says, once per level per session, what this task
## asks for (MissionNarrativeCatalog's "now" line), typed with the trailing
## caret. It floats above the bottom bar, never takes focus or pointer input
## (moving the pointer over it fades it away) and leaves by itself.
## The prologue is excluded: its step card already opens each level.

const Palette = preload("res://src/lab/lab_palette.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
const STAY_SECONDS := 5.0
const SKIPPED_CHAPTERS := [&"hardware_foundations"]

static var _shown: Dictionary = {}
static var _current: CanvasLayer

var card: PanelContainer
var body: Typewriter
var _life: float = 0.0
var _closing: bool = false
var _player_acted: bool = false


func _input(event: InputEvent) -> void:
	# A click or key press means the player has started; the card leaves early.
	if (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed() and _life > 0.6:
		_player_acted = true


## Present the opening for a level. Returns the card (or null when skipped).
static func present(tree: SceneTree, chapter_id: StringName, level_id: StringName, force: bool = false) -> CanvasLayer:
	if tree == null or chapter_id in SKIPPED_CHAPTERS: return null
	if not force and DisplayServer.get_name() == "headless": return null
	var key: String = "%s/%s" % [chapter_id, level_id]
	if _shown.has(key) and not force: return null
	var localization: Node = tree.root.get_node_or_null("Localization")
	var english: bool = localization != null and str(localization.current_locale()) == "en"
	var context: Dictionary = Catalog.task_context(chapter_id, level_id, english)
	if context.is_empty(): return null
	_shown[key] = true
	if is_instance_valid(_current): _current.queue_free()
	var layer: CanvasLayer = load("res://src/ui/yi_opening.gd").new()
	layer.name = "YiOpening"
	_current = layer
	tree.root.add_child.call_deferred(layer)
	layer.ready.connect(func() -> void: layer.say(str(context.action), english), CONNECT_ONE_SHOT)
	return layer


static func reset_shown() -> void:
	_shown.clear()


func _init() -> void:
	layer = 90
	card = PanelContainer.new(); card.name = "YiOpeningCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Invisible until it has measured its text (no full-height first frame).
	card.modulate.a = 0.0
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.with_alpha(Palette.TERM_SCREEN, 0.95)
	box.border_color = Palette.ACCENT_DEEP; box.set_border_width_all(1); box.border_width_left = 3
	box.set_corner_radius_all(10)
	box.shadow_color = Color(0, 0, 0, 0.3); box.shadow_size = 10; box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 16; box.content_margin_right = 16; box.content_margin_top = 9; box.content_margin_bottom = 11
	card.add_theme_stylebox_override("panel", box)
	add_child(card)
	var column := VBoxContainer.new(); column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4); card.add_child(column)
	body = Typewriter.new(); body.name = "YiOpeningText"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.font_size = 16; body.font_color = Palette.TERM_TEXT; body.line_spacing = 4.0
	column.add_child(body)


func say(passage: String, _english: bool) -> void:
	body.play(passage)
	_place()


func _place() -> void:
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var width: float = clampf(viewport.x * 0.42, 420.0, 620.0)
	card.custom_minimum_size.x = width
	card.size = Vector2(width, 0)
	card.reset_size()
	card.position = Vector2((viewport.x - width) * 0.5, viewport.y - card.size.y - 72.0)


func _process(delta: float) -> void:
	if card == null or _closing: return
	_place()
	_life += delta
	var mouse: Vector2 = card.get_global_mouse_position()
	var hovered: bool = card.get_global_rect().grow(8).has_point(mouse)
	var reduced: bool = bool(ProjectSettings.get_setting("game/reduced_motion", false))
	# Never in the way: hovering shows what is underneath.
	if _life < 0.08: return
	var target_alpha: float = 0.15 if hovered else 1.0
	card.modulate.a = target_alpha if reduced else move_toward(card.modulate.a, target_alpha, delta * 4.0)
	if _player_acted or (_life > STAY_SECONDS and not body.is_playing()):
		_closing = true
		if reduced:
			queue_free()
			return
		var tween := create_tween()
		tween.tween_property(card, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)


## Leaving the level takes its opening line with it.
static func dismiss() -> void:
	if is_instance_valid(_current): _current.queue_free()
	_current = null
