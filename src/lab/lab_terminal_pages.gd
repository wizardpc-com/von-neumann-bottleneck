extends SubViewportContainer
## Existing feature controllers share the full-screen terminal workspace.
var resolution := Vector2i(1280, 720)
var viewport: SubViewport
var surface: Control
var pages: Array[CanvasItem] = []
var indicators: Array[CanvasItem] = []

func _ready() -> void:
	name = "TerminalPages"
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(resolution)
	stretch = true
	clip_contents = true
	viewport = SubViewport.new()
	viewport.name = "TerminalViewport"
	viewport.size = resolution
	viewport.size_2d_override = resolution
	viewport.size_2d_override_stretch = true
	viewport.gui_embed_subwindows = true
	viewport.handle_input_locally = false
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)

	surface = Control.new()
	surface.name = "TerminalSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.theme = theme
	viewport.add_child(surface)
	surface.child_entered_tree.connect(_watch_windows)
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func mount(page: CanvasItem, indicator: CanvasItem = null) -> void:
	if page in pages: return
	page.set_meta("terminal_page", true)
	pages.append(page)
	indicators.append(indicator if indicator != null else page)
	page.reparent(surface)
	if page is Control: page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for panel: Node in page.find_children("*", "PanelContainer", true, false):
		if panel.has_method("dock"): panel.dock()

func active() -> bool:
	for indicator: CanvasItem in indicators:
		if is_instance_valid(indicator) and indicator.visible: return true
	for child: Node in surface.get_children():
		if child is Window and child.visible: return true
	return false

func align_to(rect: Rect2, revealed: bool) -> void:
	position = rect.position
	# Render at physical pixels even when the root canvas is scaled for fullscreen.
	var pixel_scale: Vector2 = get_viewport().get_stretch_transform().get_scale().max(Vector2.ONE)
	scale = Vector2.ONE / pixel_scale
	size = rect.size.max(Vector2.ONE) * pixel_scale
	var ui_scale: float = minf(rect.size.x / 1280.0, rect.size.y / 720.0)
	var next_resolution := Vector2i((rect.size / ui_scale).round())
	if resolution != next_resolution:
		resolution = next_resolution
		viewport.size_2d_override = resolution
		for window: Window in viewport.get_embedded_subwindows(): _fit_window(window)
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if active() else SubViewport.UPDATE_DISABLED
	# Pages rise out of the dark screen instead of cutting in.
	var settled: bool = not revealed or bool(ProjectSettings.get_setting("game/reduced_motion", false))
	modulate.a = (1.0 if revealed else 0.0) if settled else move_toward(modulate.a, 1.0, get_process_delta_time() * 6.0)
	mouse_filter = Control.MOUSE_FILTER_STOP if revealed else Control.MOUSE_FILTER_IGNORE

func _watch_windows(node: Node) -> void:
	if node.child_entered_tree.is_connected(_watch_windows): return
	node.child_entered_tree.connect(_watch_windows)
	for child: Node in node.get_children(): _watch_windows(child)
	if node is Window and not node is Popup:
		node.gui_embed_subwindows = true
		node.borderless = true
		node.unresizable = true
		node.visibility_changed.connect(_fit_window.bind(node), CONNECT_DEFERRED)

func _fit_window(window: Window) -> void:
	if not window.visible: return
	# Native exclusivity blocks input to the parent SubViewportContainer.
	window.exclusive = false
	window.position = Vector2i.ZERO
	window.size = resolution
	window.grab_focus()
