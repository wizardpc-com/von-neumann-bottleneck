extends RefCounted
## Read-only, caller-awaited return from a cinematic. No progression or save writes.

static func present_prologue(host: Node, library: Dictionary) -> void:
	if host.get_node("/root/GameMode").is_test_mode(): return
	var state: Node = host.get_node("/root/SystemChapter")
	if not state.prologue_ready: return
	var sources: Array[String] = []
	var parts: Array = []
	for key: StringName in [&"TinyComputer", &"ALU4", &"Register4", &"RAM2x4"]:
		var part: Variant = library.get(key)
		if part == null or part.source_signature.is_empty(): return
		parts.append(part)
		if key != &"RAM2x4": sources.append(part.source_signature)
	sources.sort()
	if "|".join(sources).sha256_text() != state.cpu_source_signature or library[&"RAM2x4"].source_signature != state.ram_source_signature: return
	await _present(host, host.get_node("/root/Localization").text(&"b2.artifact.machine"), parts, [], "")


static func present_representation(host: Node) -> void:
	if host.get_node("/root/GameMode").is_test_mode(): return
	var evidence: Array[Dictionary] = host.representation_review_evidence()
	if evidence.size() != 5: return
	var english: bool = host.get_node("/root/Localization").current_locale() == "en"
	var pages: Array[Dictionary] = preload("res://experiments/candidate_session/completion_presentation.gd").pages({"representation":{"status":"complete","completed":[0,1,2,3,4],"evidence":evidence}}, english)
	var note: String = ""
	if not host.persistent_session:
		note = host.get_node("/root/Localization").text(&"b2.artifact.temporary")
	elif host.session_dirty:
		note = host.get_node("/root/Localization").text(&"b2.artifact.unsaved")
	await _present(host, pages[1].title, [], evidence, note)


class ArtifactCard extends Control:
	signal dismissed
	func _input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			dismissed.emit()
		elif event is InputEventKey:
			get_viewport().set_input_as_handled()


static func _label(parent: Node, text: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


static func _surface() -> StyleBoxFlat:
	var palette = preload("res://src/lab/lab_palette.gd")
	var style := StyleBoxFlat.new()
	style.bg_color = palette.TERM_PANEL
	style.border_color = palette.ACCENT_DEEP
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.border_width_top = 3
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


static func _present(host: Node, title: String, parts: Array, evidence: Array[Dictionary], note: String) -> void:
	var card := ArtifactCard.new()
	card.name = "CinematicArtifact"
	card.theme = Theme.new()
	preload("res://src/ui/instrument_theme.gd").apply_to(card.theme)
	card.z_index = 2000
	preload("res://src/ui/guide_stage.gd").mark_blocker(card)
	host.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.05, 0.07, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "ArtifactPanel"
	panel.custom_minimum_size.x = 1040 if parts.is_empty() else 760
	panel.add_theme_stylebox_override("panel", _surface())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	_label(column, title, 28)
	column.add_child(HSeparator.new())
	var row: BoxContainer = VBoxContainer.new() if parts.is_empty() else HBoxContainer.new()
	row.name = "ArtifactTiles"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	for part: ReusableComponent in parts.slice(1):
		var tile := VBoxContainer.new()
		tile.custom_minimum_size.x = 208
		row.add_child(tile)
		var image := preload("res://src/hardware_foundations/circuit_module_thumbnail.gd").new()
		image.configure_thumbnail(part.behavior_kind, part.input_widths, part.output_widths)
		var visual = preload("res://src/hardware_foundations/component_visual_layout.gd")
		if visual.is_valid(part.visual_snapshot, part.source_signature):
			image.visual_bands = part.visual_snapshot.bands.duplicate(true)
		image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tile.add_child(image)
		_label(tile, String(part.component_name))
	if not parts.is_empty():
		_label(column, host.get_node("/root/Localization").text(&"b2.artifact.became") % String(parts[0].component_name), 22)
	var localization: Node = host.get_node("/root/Localization")
	for result: Dictionary in evidence:
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(984, 0)
		var style := _surface()
		style.bg_color = preload("res://src/lab/lab_palette.gd").TERM_SCREEN
		style.border_color = preload("res://src/lab/lab_palette.gd").TERM_EDGE
		style.border_width_top = 1
		style.content_margin_left = 16; style.content_margin_right = 16
		style.content_margin_top = 10; style.content_margin_bottom = 10
		tile.add_theme_stylebox_override("panel", style)
		row.add_child(tile)
		var content := HBoxContainer.new()
		tile.add_child(content)
		var task := _label(content, localization.text(&"b2.artifact.task") % (int(result.task) + 1), 22)
		task.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		task.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var values := VBoxContainer.new()
		values.add_theme_constant_override("separation", 8)
		content.add_child(values)
		for index: int in result.metrics.size():
			var metrics: Dictionary = result.metrics[index]
			var order := _label(values, "%s · %d B · %s" % [localization.text(&"b2.artifact.order") % (index + 1), metrics.stored_bytes, localization.text(&"b2.artifact.cycles") % metrics.total_cycles], 20)
			order.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	if not note.is_empty():
		var boundary := _label(column, note, 18)
		boundary.name = "ArtifactBoundary"
	var dismiss := Button.new()
	dismiss.name = "ArtifactDismiss"
	dismiss.text = host.get_node("/root/Localization").text(&"b2.artifact.continue")
	dismiss.add_theme_font_size_override("font_size", 20)
	dismiss.custom_minimum_size = Vector2(240,48)
	dismiss.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preload("res://src/ui/instrument_theme.gd").primary(dismiss)
	column.add_child(dismiss)
	dismiss.pressed.connect(func() -> void: card.dismissed.emit())
	dismiss.grab_focus()
	preload("res://src/ui/ui_motion.gd").reveal(panel)
	await card.dismissed
	card.queue_free()
