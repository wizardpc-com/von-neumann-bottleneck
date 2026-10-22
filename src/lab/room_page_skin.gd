extends RefCounted
## Presentation only. A page opened from a physical object in the laboratory
## is shown as the room's own frosted glass, the light world of the lab; the
## same page opened from the terminal keeps the dark terminal look.
## One family for every object: the same pale glass, hairlines and radius.
## Each object contributes only its accent, a faint tint and a top rule.
## Colours are remapped by role (ground, surface, line, secondary text, text,
## accent), so overrides set in code follow too. Every change is recorded on
## the control and undone by revert().

const BASE := {"bg": Color("eef1f3"), "surface": Color("f8fafb"), "line": Color("d2d9de"),
	"soft": Color("66737d"), "ink": Color("1d2830"), "radius": 8}
# Equal-lightness accents, readable as text on the pale glass.
# The handbook and the globe's journey review read as terminal material and
# keep its dark look, as does the journey board's map.
const ACCENTS := {
	"archive": Color("2b7f8c"), "works": Color("a3566e"),
	"achievements": Color("97691d"), "settings": Color("356f9e"),
	"feedback": Color("7656a3"),
}
const RULE_NAME := "RoomSkinRule"
const COLOR_ITEMS := ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
	"font_hover_pressed_color", "font_disabled_color", "font_placeholder_color", "font_selected_color",
	"font_uneditable_color", "font_readonly_color", "caret_color", "selection_color", "default_color",
	"font_outline_color", "title_color", "children_hl_line_color", "relationship_line_color",
	"parent_hl_line_color", "guide_color", "font_separator_color", "icon_normal_color"]
const STYLE_ITEMS := ["panel", "normal", "hover", "pressed", "focus", "disabled", "hover_pressed",
	"read_only", "background", "fill", "bg", "selected", "selected_focus", "cursor", "cursor_unfocused",
	"scroll", "grabber", "grabber_highlight", "grabber_pressed", "slider", "tab_selected",
	"tab_unselected", "tab_hovered", "button_pressed", "custom_button", "title_button_normal"]
const META := &"room_skin_restore"

static func has(id: String) -> bool:
	return ACCENTS.has(id)

static func skin(id: String) -> Dictionary:
	var result: Dictionary = BASE.duplicate()
	var accent: Color = ACCENTS.get(id, Color("2b7f8c"))
	result["accent"] = accent
	# A barely-there tint, so each object's glass is its own without changing family.
	result["bg"] = BASE.bg.lerp(accent, 0.035)
	result["surface"] = BASE.surface.lerp(accent, 0.02)
	return result

static func ground(id: String) -> Color:
	return skin(id).bg if has(id) else Color.BLACK

static func accent(id: String) -> Color:
	return ACCENTS.get(id, Color.WHITE)

static func apply(root: Control, id: String) -> void:
	if not has(id) or root == null: return
	var tokens: Dictionary = skin(id)
	_skin_control(root, tokens)
	for node: Node in root.find_children("*", "Control", true, false):
		_skin_control(node as Control, tokens)
	# The object's mark: one accent hairline across the top of its page.
	if root.get_node_or_null(RULE_NAME) == null:
		var rule := ColorRect.new(); rule.name = RULE_NAME
		rule.color = tokens.accent
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Top-level, so a container page does not stretch it over its content.
		rule.top_level = true
		rule.z_index = 50
		rule.set_meta(META, {"colors": {}, "styles": {}})
		root.add_child(rule)
		var place := func() -> void:
			if is_instance_valid(rule) and is_instance_valid(root):
				rule.global_position = root.global_position
				rule.size = Vector2(root.size.x, 2.0)
		place.call()
		root.resized.connect(place)

static func revert(root: Control) -> void:
	if root == null: return
	var rule: Node = root.get_node_or_null(RULE_NAME)
	if rule != null:
		root.remove_child(rule)
		rule.queue_free()
	var nodes: Array[Node] = root.find_children("*", "Control", true, false)
	nodes.push_front(root)
	for node: Node in nodes:
		var control := node as Control
		if not control.has_meta(META): continue
		var record: Dictionary = control.get_meta(META)
		for item: String in record.colors:
			var previous: Array = record.colors[item]
			if bool(previous[0]): control.add_theme_color_override(item, previous[1])
			else: control.remove_theme_color_override(item)
		for item: String in record.styles:
			var previous: Array = record.styles[item]
			if bool(previous[0]): control.add_theme_stylebox_override(item, previous[1])
			else: control.remove_theme_stylebox_override(item)
		if record.has("rect"): (control as ColorRect).color = record.rect
		for entry: Array in record.get("items", []):
			if is_instance_valid(entry[0]): (entry[0] as TreeItem).set_custom_color(int(entry[1]), entry[2])
		control.remove_meta(META)

static func _skin_control(control: Control, skin: Dictionary) -> void:
	if control == null or control.has_meta(META): return
	var record := {"colors": {}, "styles": {}}
	for item: String in COLOR_ITEMS:
		if not control.has_theme_color(item): continue
		var had: bool = control.has_theme_color_override(item)
		var before: Color = control.get_theme_color(item)
		record.colors[item] = [had, before]
		control.add_theme_color_override(item, role_color(before, skin, true))
	for item: String in STYLE_ITEMS:
		if not control.has_theme_stylebox(item): continue
		var box := control.get_theme_stylebox(item) as StyleBoxFlat
		if box == null: continue
		var had: bool = control.has_theme_stylebox_override(item)
		# An override, when present, is what get_theme_stylebox() returned.
		record.styles[item] = [had, box if had else null]
		var copy := box.duplicate() as StyleBoxFlat
		copy.bg_color = role_color(box.bg_color, skin, false)
		# An accent fill becomes a tint, so text keeps its contrast on it.
		if copy.bg_color.is_equal_approx(Color(skin.accent, box.bg_color.a)):
			copy.bg_color = Color(skin.accent, box.bg_color.a * 0.14)
		# One radius and hairline weight across the family.
		for corner: int in 4:
			if copy.get_corner_radius(corner) > 0: copy.set_corner_radius(corner, int(skin.radius))
		for side: int in 4:
			copy.set_border_width(side, mini(copy.get_border_width(side), 1 if item != "focus" else 2))
		copy.border_color = role_color(box.border_color, skin, false)
		copy.shadow_color = Color(skin.ink, box.shadow_color.a * 0.18)
		control.add_theme_stylebox_override(item, copy)
	if control is ColorRect:
		var rect := control as ColorRect
		record["rect"] = rect.color
		var mapped: Color = role_color(rect.color, skin, false)
		# A large accent backdrop becomes a tint; thin rules and bars keep the accent.
		if mapped.is_equal_approx(Color(skin.accent, rect.color.a)) and rect.size.x > 24.0 and rect.size.y > 24.0:
			mapped = Color(skin.accent, rect.color.a * 0.14)
		rect.color = mapped
	if control is Tree:
		record["items"] = _skin_tree_items((control as Tree).get_root(), skin)
	control.set_meta(META, record)

## Tree rows carry their own colours (handbook categories); remap those too.
static func _skin_tree_items(item: TreeItem, skin: Dictionary) -> Array:
	var changed: Array = []
	while item != null:
		for column: int in item.get_tree().columns:
			var color: Color = item.get_custom_color(column)
			if color != Color(0, 0, 0, 1) and color.a > 0.01:
				changed.append([item, column, color])
				item.set_custom_color(column, role_color(color, skin, true))
		item = item.get_next_in_tree()
	return changed

## Map one colour designed for the dark terminal onto the skin, by role.
## Cyan accents become the skin accent; other saturated hues (signal 0/1,
## widths, warnings) keep their meaning and only adjust for contrast.
static func role_color(color: Color, skin: Dictionary, text: bool) -> Color:
	if color.a <= 0.01: return color
	var light_ground: bool = skin.bg.get_luminance() > 0.5
	var lum: float = color.get_luminance()
	if color.s > 0.28 and color.v > 0.3:
		var hue: float = color.h * 360.0
		if hue > 165.0 and hue < 205.0:
			return Color(skin.accent, color.a)
		return Color(color.darkened(0.42) if light_ground and text else color, color.a)
	var role: Color
	if lum < 0.13: role = skin.bg
	elif lum < 0.24: role = skin.surface
	elif lum < 0.42: role = skin.line
	elif lum < 0.72: role = skin.soft
	else: role = skin.ink
	return Color(role, color.a)
