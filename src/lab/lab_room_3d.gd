extends SubViewportContainer
## Presentation-only room. No simulation, progression, or save authority.
signal activated(id: String)
signal hover_changed(id: String)

const LabState = preload("res://src/lab/lab_state.gd")
const DISPLAY_FONT = preload("res://assets/fonts/interface_regular.tres")
const WORK_COLORS := [Color("7fcbd6"), Color("f0c674"), Color("aab6e6"), Color("7fd8a4")]
const MODEL_PATH := "res://assets/lab/laboratory.glb"
const HOTSPOT_LAYER := 1 << 8
const BLOCKER_LAYER := 1 << 9
const OBSERVATION := Vector3(0.0, 4.35, 10.75)
const TARGET := Vector3(0.0, 2.55, -0.25)
const PREFIXES := {
	"Terminal |": "terminal", "Archive |": "archive", "Journey |": "journey",
	"Works |": "works", "Achievements |": "achievements", "Handbook |": "handbook",
	"Settings |": "settings", "Letter |": "feedback", "Status globe |": "globe",
}

var viewport: SubViewport
var camera: Camera3D
var model: Node3D
var _neutral_basis: Basis
var _look_target := Vector2.ZERO
var _look_current := Vector2.ZERO
var _zoom: float = 0.0
var _interaction_enabled: bool = true
var _pending_clicks: Array[Vector2] = []
var _hovered: String = ""
var _screen: MeshInstance3D
var standby_viewport: SubViewport
var _globe_player: AnimationPlayer
var _globe_material: BaseMaterial3D
var _globe_light: OmniLight3D
## Snapshot only: callers cannot mutate the renderer's authoritative input copy.
var display_state: Dictionary:
	get:
		return _display_state.duplicate(true)
var _display_state: Dictionary = {}
var _station_labels: Array[Label3D] = []
var _board_viewport: SubViewport
var _board_title: Label
var _board_total: Label
var _board_rows: Array[Dictionary] = []
var _works_title: Label3D
var _works_name: Label3D
var _work_pixels: Array[Label3D] = []
var _achievement_label: Label3D
var _colliders: Array[CollisionObject3D] = []
var _collider_meshes: Array[MeshInstance3D] = []
## Visible meshes per semantic object: camera travel aims at them, hover lights them.
var _region_meshes: Dictionary = {}
var _focus_point: Vector3 = TARGET
var _focus_fov: float = 12.0
# How far along the line to the object the camera travels at full zoom.
var _focus_dolly: float = 0.0
var _hover_material: StandardMaterial3D
var _hover_glow: float = 0.0
var _confirmation: Control
var _confirmation_parent: Node
var _screen_events: Array[InputEventMouse] = []
var _standby_text: Control
## Standby glass: what the terminal is about to offer, readable from the room.
var _standby_header: Label
var _standby_count: Label
var _standby_kicker: Label
var _standby_title: Label
var _standby_note: Label
var _standby_bar: ProgressBar
var _standby_prompt: Label
var _standby_info: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.positional_shadow_atlas_size = 4096
	add_child(viewport)
	mouse_exited.connect(func() -> void: _set_hover(""))
	var packed := load(MODEL_PATH) as PackedScene
	if packed == null:
		push_error("Laboratory model could not be loaded: " + MODEL_PATH)
		return
	model = packed.instantiate() as Node3D
	viewport.add_child(model)
	for node in model.find_children("*", "Camera3D", true, false):
		(node as Camera3D).current = false
	for node in model.find_children("*", "Light3D", true, false):
		(node as Light3D).visible = false
	camera = Camera3D.new()
	camera.name = "FixedObservationCamera"
	viewport.add_child(camera)
	camera.position = OBSERVATION
	camera.fov = _room_fov()
	camera.look_at(TARGET, Vector3.UP)
	_neutral_basis = camera.basis
	camera.current = true
	_screen = model.find_child("Terminal | single blank glass", true, false) as MeshInstance3D
	_setup_screen()
	_setup_environment()
	_setup_globe()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var mesh_name := str(mesh.name)
		# The imported artwork is a concept, never an earned player record.
		if mesh_name.begins_with("Journey |") and mesh_name != "Journey | blank panel":
			mesh.hide()
		if mesh_name.begins_with("Works |") and mesh_name not in ["Works | recessed surround", "Works | blue graphite recess", "Works | deep shelf", "Works | concealed upper diffuser"]:
			mesh.hide()
		if mesh_name.begins_with("Achievements |") and mesh_name not in ["Achievements | sculpted wall inset", "Achievements | ceramic inset", "Achievements | unprinted plaque"]:
			mesh.hide()
		_add_mesh_collision(mesh)
	_setup_status_displays()
	_hover_material = StandardMaterial3D.new()
	_hover_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hover_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hover_material.albedo_color = Color(0.0, 0.0, 0.0, 0.0)
	update_progress([], 0, 0, 0)

func set_look(normalized: Vector2) -> void:
	# Camera forward is -Z; screen Y grows downwards. Turn toward the pointer.
	_look_target = -normalized.clamp(Vector2(-1.0, -1.0), Vector2.ONE) * Vector2(12.0, 6.0)

func _room_fov() -> float:
	# Preserve the side-wall composition when the window is narrower than 16:9.
	var aspect: float = size.x / maxf(size.y, 1.0)
	return rad_to_deg(2.0 * atan((20.25 / 48.0) * maxf(1.0, (16.0 / 9.0) / maxf(aspect, 0.01))))

func set_zoom(amount: float) -> void:
	_zoom = clampf(amount, 0.0, 1.0)

## Aim later set_zoom() travel at one object. The terminal keeps the original
## straight push into the glass; other objects turn the camera toward themselves.
## The camera walks part of the way (a dolly, not a telephoto squeeze) and
## narrows its view until the object fills the frame.
func focus_on(id: String) -> void:
	_focus_point = TARGET
	_focus_dolly = 0.0
	_focus_fov = 12.0
	var bounds := region_bounds(id)
	var half_extent: float = tan(deg_to_rad(6.0)) * OBSERVATION.distance_to(TARGET)
	if id != "terminal":
		if not bounds.has_volume():
			return
		_focus_point = bounds.get_center()
		half_extent = maxf(bounds.size.x, bounds.size.y) * 0.5 * 1.25
	_focus_dolly = 0.42 if id == "terminal" else 0.5
	var distance: float = OBSERVATION.distance_to(_focus_point) * (1.0 - _focus_dolly)
	_focus_fov = clampf(rad_to_deg(2.0 * atan(half_extent / distance)), 8.0, 46.0)

## Projected bounds of one object, in this container's pixels, for the
## current camera. Empty when the object is unknown or behind the camera.
func region_screen_rect(id: String) -> Rect2:
	var bounds := region_bounds(id)
	if id == "terminal": return screen_rect()
	if camera == null or not bounds.has_volume(): return Rect2()
	var result := Rect2()
	for index in range(8):
		var point: Vector3 = bounds.get_endpoint(index)
		if camera.is_position_behind(point): return Rect2()
		var pixel := camera.unproject_position(point) * size / Vector2(viewport.size)
		result = Rect2(pixel, Vector2.ZERO) if index == 0 else result.expand(pixel)
	return result

func region_bounds(id: String) -> AABB:
	var result := AABB()
	var first: bool = true
	for mesh: MeshInstance3D in _region_meshes.get(id, []):
		if not mesh.is_visible_in_tree() or mesh.mesh == null:
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if not enabled:
		_pending_clicks.clear()
		_set_hover("")

func _process(delta: float) -> void:
	if camera == null:
		return
	var reduced := bool(ProjectSettings.get_setting("game/reduced_motion", false))
	if _globe_player != null:
		_globe_player.speed_scale = 0.0 if reduced else 1.0
	if reduced:
		_look_current = Vector2.ZERO
	else:
		_look_current = _look_current.lerp(_look_target, 1.0 - exp(-10.0 * delta))
	var looking: Basis = _neutral_basis * Basis(Vector3.UP, deg_to_rad(_look_current.x)) * Basis(Vector3.RIGHT, deg_to_rad(_look_current.y))
	var aim: Basis = Transform3D(Basis(), OBSERVATION).looking_at(_focus_point, Vector3.UP).basis
	# Turn toward the object early, walk toward it, and narrow the view last,
	# so the move reads as one step forward rather than a zoom lens.
	camera.basis = looking.slerp(aim, smoothstep(0.0, 0.55, _zoom))
	camera.position = OBSERVATION.lerp(_focus_point, _focus_dolly * smoothstep(0.0, 1.0, _zoom))
	var base_fov: float = _room_fov()
	camera.fov = base_fov * pow(_focus_fov / base_fov, smoothstep(0.15, 1.0, _zoom))
	var glow_target: float = 0.0 if _hovered.is_empty() or not _interaction_enabled else 1.0
	_hover_glow = glow_target if reduced else move_toward(_hover_glow, glow_target, delta * 6.0)
	# A warm lift that breathes slowly, like the object answering the pointer.
	var breathe: float = 1.0 if reduced else 0.82 + 0.18 * sin(Time.get_ticks_msec() * 0.0035)
	_hover_material.albedo_color = Color(0.16, 0.14, 0.11, _hover_glow * breathe)

## Return projected glass bounds in this container's local pixel coordinates.
func screen_rect() -> Rect2:
	if _screen == null or camera == null:
		return Rect2()
	var bounds := _screen.get_aabb()
	var result := Rect2()
	for index in range(8):
		var point: Vector3 = _screen.global_transform * bounds.get_endpoint(index)
		if camera.is_position_behind(point):
			return Rect2()
		var pixel := camera.unproject_position(point) * size / Vector2(viewport.size)
		if index == 0:
			result = Rect2(pixel, Vector2.ZERO)
		else:
			result = result.expand(pixel)
	return result

## Draw on the glass itself, so perspective, rounded corners and occlusion agree.
func _setup_screen() -> void:
	if _screen == null: return
	standby_viewport = SubViewport.new()
	standby_viewport.size = Vector2i(1024, 470)
	standby_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.add_child(standby_viewport)
	standby_viewport.disable_3d = true
	standby_viewport.handle_input_locally = false
	var background := ColorRect.new()
	background.color = Color("101f29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	standby_viewport.add_child(background)
	var localization: Node = get_node_or_null("/root/Localization")
	var english: bool = localization != null and localization.current_locale() == "en"
	var margin := MarginContainer.new(); margin.name = "StandbyGlass"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 64)
	margin.add_theme_constant_override("margin_top", 40); margin.add_theme_constant_override("margin_bottom", 38)
	standby_viewport.add_child(margin)
	_standby_text = margin
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var top := HBoxContainer.new(); column.add_child(top)
	_standby_header = _glass_label(top, "Yi · learning program" if english else "壹 · 学习程序", 26, Color("7f98a6"))
	_standby_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standby_count = _glass_label(top, "", 26, Color("7f98a6"))
	var rule := ColorRect.new(); rule.color = Color("2a4254"); rule.custom_minimum_size.y = 2; column.add_child(rule)
	var space := Control.new(); space.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(space)
	_standby_kicker = _glass_label(column, "", 28, Color("7fcbd6"))
	_standby_title = _glass_label(column, "", 54, Color("e2ebef"))
	_standby_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_standby_title.clip_text = true
	_standby_note = _glass_label(column, "", 26, Color("a9bccb"))
	_standby_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var space2 := Control.new(); space2.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(space2)
	_standby_bar = ProgressBar.new(); _standby_bar.show_percentage = false
	_standby_bar.custom_minimum_size.y = 8
	var track := StyleBoxFlat.new(); track.bg_color = Color("1b2e3c"); track.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new(); fill.bg_color = Color("7fcbd6"); fill.set_corner_radius_all(4)
	_standby_bar.add_theme_stylebox_override("background", track); _standby_bar.add_theme_stylebox_override("fill", fill)
	column.add_child(_standby_bar)
	_standby_prompt = _glass_label(column, "", 28, Color("b9dcd9"))
	_standby_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_standby(_standby_info if not _standby_info.is_empty() else {"english": english, "new_player": true})
	var bounds: AABB = _screen.get_aabb()
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/lab/lab_screen.gdshader")
	material.set_shader_parameter("display_texture", standby_viewport.get_texture())
	material.set_shader_parameter("screen_bounds", Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
	_screen.material_override = material

func _glass_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

## Presentation only: the same next task and counts the terminal itself offers.
## info: english, new_player, next_label, next_chapter, completed, total, just_done
func set_standby(info: Dictionary) -> void:
	_standby_info = info.duplicate()
	if _standby_title == null: return
	var english: bool = bool(info.get("english", false))
	var completed: int = int(info.get("completed", 0))
	var total: int = int(info.get("total", 0))
	_standby_header.text = "Yi · learning program" if english else "壹 · 学习程序"
	_standby_count.text = ("%d / %d" % [completed, total]) if total > 0 else ""
	_standby_bar.max_value = maxi(1, total)
	_standby_bar.value = completed
	_standby_bar.visible = total > 0
	var just_done: String = str(info.get("just_done", ""))
	if bool(info.get("new_player", false)):
		_standby_kicker.text = "First step" if english else "第一步"
		_standby_title.text = "Connect one wire" if english else "从一根线开始"
		_standby_note.text = "Connect it, run it, see why the lamp is on or off." if english else "接好、运行，再看看灯为什么亮或灭。"
	else:
		var chapter: String = str(info.get("next_chapter", ""))
		_standby_kicker.text = ("Next" if english else "下一项") + ((" · " + chapter) if not chapter.is_empty() else "")
		var title: String = str(info.get("next_label", ""))
		# The kicker already names the chapter (序章·半加器 → 半加器).
		for separator: String in [" · ", "·"]:
			if not chapter.is_empty() and title.begins_with(chapter + separator): title = title.trim_prefix(chapter + separator)
		_standby_title.text = title
		_standby_note.text = (("Just finished: " if english else "刚完成：") + just_done) if not just_done.is_empty() else ""
	_standby_note.visible = not _standby_note.text.is_empty()
	_standby_prompt.text = "Enter · open terminal" if english else "Enter · 打开终端"
	if standby_viewport != null and not confirmation_active():
		standby_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

## Reuse the terminal's controls on its actual glass, including perspective and occlusion.
func show_confirmation(view: Control) -> void:
	_confirmation_parent = view.get_parent()
	_confirmation = view
	_standby_text.hide()
	standby_viewport.size_2d_override = Vector2i(512, 235)
	standby_viewport.size_2d_override_stretch = true
	view.reparent(standby_viewport)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	standby_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_screen_events.clear()

func dismiss_confirmation() -> void:
	if not is_instance_valid(_confirmation): return
	_confirmation.reparent(_confirmation_parent)
	_confirmation.scale = Vector2.ONE
	_confirmation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirmation = null
	_confirmation_parent = null
	standby_viewport.size_2d_override = Vector2i.ZERO
	_standby_text.show()
	_screen_events.clear()
	standby_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func confirmation_active() -> bool:
	return is_instance_valid(_confirmation)

## The nearest visible surface must be the glass; the bezel and other objects block clicks.
func screen_position(pixel: Vector2) -> Vector2:
	if camera == null or _screen == null or not Rect2(Vector2.ZERO, size).has_point(pixel): return Vector2(-1, -1)
	var viewport_pixel := pixel * Vector2(viewport.size) / size.max(Vector2.ONE)
	var origin := camera.project_ray_origin(viewport_pixel)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(viewport_pixel) * 60.0, HOTSPOT_LAYER | BLOCKER_LAYER)
	query.collide_with_areas = true
	query.hit_back_faces = true
	var hit := model.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider.get_parent() != _screen: return Vector2(-1, -1)
	var point: Vector3 = _screen.to_local(hit.position)
	var bounds := _screen.get_aabb()
	var uv := (Vector2(point.x, point.y) - Vector2(bounds.position.x, bounds.position.y)) / Vector2(bounds.size.x, bounds.size.y)
	var resolution: Vector2i = standby_viewport.size_2d_override if confirmation_active() else standby_viewport.size
	return Vector2(uv.x, 1.0 - uv.y) * Vector2(resolution)

## Immediate test/API pick; call after the physics world has settled.
## Normal GUI input is queued instead, so physics space is never queried locked.
func activate_at(pixel: Vector2) -> String:
	var id := _pick(pixel)
	if not id.is_empty():
		activated.emit(id)
	return id

func _gui_input(event: InputEvent) -> void:
	if confirmation_active():
		if event is InputEventMouse:
			_screen_events.append(event.duplicate() as InputEventMouse)
			accept_event()
		return
	if not _interaction_enabled:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			_pending_clicks.append(button.position)
			accept_event()

func _physics_process(_delta: float) -> void:
	if camera == null:
		return
	# Hidden meshes, including hidden overhead geometry, must not occlude input.
	for index in range(_colliders.size()):
		var collider := _colliders[index]
		var mesh := _collider_meshes[index]
		var layer: int = HOTSPOT_LAYER if collider.has_meta("region") else BLOCKER_LAYER
		collider.collision_layer = layer if mesh.is_visible_in_tree() else 0
	if confirmation_active():
		var events: Array[InputEventMouse] = _screen_events.duplicate()
		_screen_events.clear()
		for event: InputEventMouse in events:
			var point := screen_position(event.position)
			# Forward outside releases too, so dragging off a button cannot leave it held.
			event.position = point
			event.global_position = point
			standby_viewport.push_input(event, true)
		return
	if not _interaction_enabled or not is_visible_in_tree():
		_pending_clicks.clear()
		_set_hover("")
		return
	var clicks: Array[Vector2] = _pending_clicks.duplicate()
	_pending_clicks.clear()
	for pixel in clicks:
		activate_at(pixel)
	_set_hover(_pick(get_local_mouse_position()))

func _pick(pixel: Vector2) -> String:
	if not _interaction_enabled or camera == null or not Rect2(Vector2.ZERO, size).has_point(pixel):
		return ""
	var viewport_pixel := pixel * Vector2(viewport.size) / size.max(Vector2.ONE)
	var origin := camera.project_ray_origin(viewport_pixel)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(viewport_pixel) * 60.0, HOTSPOT_LAYER | BLOCKER_LAYER)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	var hit: Dictionary = model.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	var collider := hit.get("collider") as CollisionObject3D
	return str(collider.get_meta("region", "")) if collider != null else ""

func _set_hover(id: String) -> void:
	if id != _hovered:
		for mesh: MeshInstance3D in _region_meshes.get(_hovered, []):
			mesh.material_overlay = null
		_hovered = id
		# The pointed-at object itself brightens; no floating label is needed.
		for mesh: MeshInstance3D in _region_meshes.get(_hovered, []):
			if id != "terminal": mesh.material_overlay = _hover_material
		hover_changed.emit(id)

func _add_mesh_collision(mesh: MeshInstance3D) -> void:
	if mesh.mesh == null:
		return
	var id: String = ""
	for prefix: String in PREFIXES:
		if str(mesh.name).begins_with(prefix):
			id = str(PREFIXES[prefix])
			break
	if not id.is_empty():
		var meshes: Array = _region_meshes.get(id, [])
		meshes.append(mesh)
		_region_meshes[id] = meshes
	if id.is_empty() and not _has_opaque_surface(mesh):
		return
	var shape := mesh.mesh.create_trimesh_shape()
	if shape == null:
		return
	shape.backface_collision = true
	var collider: CollisionObject3D
	if id.is_empty():
		collider = StaticBody3D.new()
	else:
		var area := Area3D.new()
		area.monitoring = false
		area.monitorable = false
		collider = area
		collider.set_meta("region", id)
	collider.collision_layer = (BLOCKER_LAYER if id.is_empty() else HOTSPOT_LAYER) if mesh.is_visible_in_tree() else 0
	collider.collision_mask = 0
	mesh.add_child(collider)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collider.add_child(collision)
	_colliders.append(collider)
	_collider_meshes.append(mesh)

func _has_opaque_surface(mesh: MeshInstance3D) -> bool:
	for index in range(mesh.mesh.get_surface_count()):
		var material := mesh.get_active_material(index) as BaseMaterial3D
		if material == null or material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			return true
	return false

## All values are read-only presentation inputs. No unlocks or awards are created.
func update_progress(stations: Array[Dictionary], completed: int, total: int, works_count: int, tasks: Array[Dictionary] = [], works: Array = [], english: bool = false) -> void:
	var first_light: bool = false
	for task: Dictionary in tasks:
		if str(task.get("key", "")) == "hardware_foundations/tutorial":
			first_light = bool(task.get("completed", false))
	if _globe_material != null: _globe_material.emission_enabled = first_light
	if _globe_light != null: _globe_light.visible = first_light
	var current_key: String = ""
	var navigation := get_node_or_null("/root/TaskNavigation") if is_inside_tree() else null
	if navigation != null and navigation.has_method("next_task_key"):
		current_key = str(navigation.call("next_task_key"))
	var station_states: Array[Dictionary] = []
	for index in range(LabState.STATIONS.size()):
		var definition: Dictionary = LabState.STATIONS[index]
		var progress: Dictionary = stations[index] if index < stations.size() else {}
		var station_total := maxi(0, int(progress.get("total", 0)))
		var done := clampi(int(progress.get("done", 0)), 0, station_total)
		var available: bool = false
		var current: bool = false
		var has_tasks: bool = false
		for task: Dictionary in tasks:
			if int(task.get("region", -1)) not in definition.regions:
				continue
			has_tasks = true
			var unlocked := bool(task.get("unlocked", false))
			available = available or unlocked
			if unlocked and not current_key.is_empty() and str(task.get("key", "")) == current_key:
				current = true
		var finished: bool = station_total > 0 and done == station_total
		var status: String = "completed" if finished else ("current" if current else ("available" if available else ("locked" if has_tasks else "unknown")))
		var title := str(progress.get("en" if english else "zh", definition.get("en" if english else "zh", "")))
		station_states.append({"index": index, "name": title, "done": done, "total": station_total,
			"available": available, "current": current, "locked": has_tasks and not available and not finished, "status": status})
	_refresh_board(station_states, maxi(0, completed), maxi(0, total), english)
	var count := maxi(0, works_count)
	var latest: Dictionary = works[-1] if count > 0 and not works.is_empty() and works[-1] is Dictionary else {}
	var latest_name := str(latest.get("name", ""))
	var output: Array = latest.get("output", []) if latest.get("output", []) is Array else []
	_display_state = {"stations": station_states, "works_count": count, "latest_name": latest_name,
		"latest_output": output.duplicate(), "completed": maxi(0, completed), "total": maxi(0, total), "current_key": current_key, "first_light": first_light}
	if _works_title != null:
		_works_title.text = ("Works  %d" if english else "作品  %d") % count
		if count == 0 or latest.is_empty():
			_works_name.text = ""
		else:
			_works_name.text = _fit_work_name(latest_name if not latest_name.is_empty() else ("Untitled" if english else "未命名"))
	for index in range(_work_pixels.size()):
		# Unlit cells read as an empty light-print matrix waiting for a saved work.
		var pixel := _work_pixels[index]
		pixel.modulate = WORK_COLORS[clampi(int(output[index]), 0, WORK_COLORS.size() - 1)] if index < output.size() else Color(0.55, 0.68, 0.76, 0.16)
	if _achievement_label != null:
		_achievement_label.text = ("Completed\n%d / %d" if english else "已完成\n%d / %d") % [maxi(0, completed), maxi(0, total)]

func _fit_work_name(value: String) -> String:
	var title_width: float = DISPLAY_FONT.get_string_size(_works_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _works_title.font_size).x * _works_title.pixel_size
	var available: float = maxf(0.0, (_works_name.position.x - _works_title.position.x - title_width - 0.14) / _works_name.pixel_size)
	if DISPLAY_FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, _works_name.font_size).x <= available:
		return value
	var clipped := value
	while not clipped.is_empty():
		clipped = clipped.left(clipped.length() - 1)
		if DISPLAY_FONT.get_string_size(clipped + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, _works_name.font_size).x <= available:
			return clipped + "…"
	return ""

func _setup_status_displays() -> void:
	var board := model.find_child("Journey | blank panel", true, false) as MeshInstance3D
	if board != null:
		_setup_board(board)
	var works_board := model.find_child("Works | blue graphite recess", true, false) as MeshInstance3D
	if works_board != null:
		var bounds := works_board.get_aabb()
		var front: float = bounds.end.z + 0.02
		# Title and name share one baseline across the top; the light-print
		# matrix fills the rest, centred.
		_works_title = _surface_label(works_board, Vector3(bounds.position.x + 0.16, bounds.end.y - 0.17, front), 0.0055, 30)
		_works_name = _surface_label(works_board, Vector3(bounds.end.x - 0.16, bounds.end.y - 0.17, front), 0.0055, 26)
		_works_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var pitch: float = (bounds.size.x - 0.6) / 7.0
		var rows_top: float = bounds.end.y - 0.42
		var row_pitch: float = minf(0.13, (rows_top - bounds.position.y - 0.12) / 3.0)
		for index in range(32):
			var point := Vector3(bounds.position.x + 0.3 + float(index % 8) * pitch, rows_top - floorf(float(index) / 8.0) * row_pitch, front)
			var pixel := _surface_label(works_board, point, 0.004, 28)
			pixel.text = "●"
			_work_pixels.append(pixel)
	var achievements := model.find_child("Achievements | ceramic inset", true, false) as MeshInstance3D
	if achievements != null:
		var bounds := achievements.get_aabb()
		_achievement_label = _surface_label(achievements, Vector3(bounds.position.x + 0.15, bounds.end.y - 0.30, bounds.end.z + 0.025), 0.006, 32)
		_achievement_label.modulate = Color("253949")

## The journey board is drawn like the terminal glass: a 2D sheet on the
## panel, so the current chapter can lead and the rest stay quiet.
func _setup_board(board: MeshInstance3D) -> void:
	var bounds := board.get_aabb()
	var aspect: float = bounds.size.x / maxf(bounds.size.y, 0.01)
	_board_viewport = SubViewport.new(); _board_viewport.name = "JourneyBoardSheet"
	# Kept within 1280×720 like the terminal glass.
	_board_viewport.size = Vector2i(roundi(680.0 * aspect), 680)
	_board_viewport.disable_3d = true
	_board_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.add_child(_board_viewport)
	var ground := ColorRect.new(); ground.color = Color("141c22")
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _board_viewport.add_child(ground)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 22); margin.add_theme_constant_override("margin_bottom", 18)
	_board_viewport.add_child(margin)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 4); margin.add_child(column)
	var top := HBoxContainer.new(); column.add_child(top)
	_board_title = _glass_label(top, "", 38, Color("e2ebef")); _board_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_total = _glass_label(top, "", 30, Color("8fa3ad"))
	_board_total.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	var rule := ColorRect.new(); rule.color = Color("2c3c47"); rule.custom_minimum_size.y = 3; column.add_child(rule)
	for index in range(LabState.STATIONS.size()):
		var strip := PanelContainer.new(); strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(strip)
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10)
		strip.add_child(row)
		var mark := _glass_label(row, "", 26, Color("5f707c")); mark.custom_minimum_size.x = 26
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; mark.size_flags_vertical = Control.SIZE_FILL
		var name_label := _glass_label(row, "", 30, Color("b8d0dc")); name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; name_label.size_flags_vertical = Control.SIZE_FILL
		name_label.clip_text = true; name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var count := _glass_label(row, "", 27, Color("8fa3ad"))
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.size_flags_vertical = Control.SIZE_FILL
		_board_rows.append({"strip": strip, "mark": mark, "name": name_label, "count": count})
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/lab/lab_screen.gdshader")
	material.set_shader_parameter("display_texture", _board_viewport.get_texture())
	material.set_shader_parameter("screen_bounds", Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
	board.material_override = material

func _refresh_board(stations: Array[Dictionary], completed: int, total: int, english: bool) -> void:
	if _board_viewport == null: return
	_board_title.text = "Journey" if english else "旅程"
	_board_total.text = "%d / %d" % [completed, total]
	# Colour carries the state: green done, amber current, pale open, dim locked.
	for index in range(mini(stations.size(), _board_rows.size())):
		var state: Dictionary = stations[index]
		var row: Dictionary = _board_rows[index]
		var status: String = str(state.status)
		var color: Color = {"completed": Color("8ed8c5"), "current": Color("f0c674"), "available": Color("c4d6e0")}.get(status, Color("5f707c"))
		var strip_box := StyleBoxFlat.new()
		strip_box.bg_color = Color(color, 0.14) if status == "current" else Color.TRANSPARENT
		strip_box.set_corner_radius_all(8); strip_box.content_margin_left = 8; strip_box.content_margin_right = 10
		(row.strip as PanelContainer).add_theme_stylebox_override("panel", strip_box)
		(row.mark as Label).text = {"completed": "✓", "current": "▸"}.get(status, "")
		(row.mark as Label).add_theme_color_override("font_color", color)
		(row.name as Label).text = str(state.name)
		(row.name as Label).add_theme_color_override("font_color", color)
		(row.count as Label).text = "%d/%d" % [int(state.done), int(state.total)]
		(row.count as Label).add_theme_color_override("font_color", color.darkened(0.15) if status != "locked" else Color("4f5e69"))
	_board_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

## Labels share the panel's physical transform, face its +Z front and depth-test
## normally. No billboarding/no-depth overlays, so walls still occlude them.
func _surface_label(surface: MeshInstance3D, position_3d: Vector3, pixel_scale: float, text_size: int) -> Label3D:
	var label := Label3D.new()
	label.font = DISPLAY_FONT
	label.font_size = text_size
	label.pixel_size = pixel_scale
	label.outline_size = 0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	label.shaded = false
	label.modulate = Color("c4dae4")
	label.position = position_3d
	surface.add_child(label)
	return label

func _setup_globe() -> void:
	var globe := model.find_child("Status globe | opal sphere", true, false) as MeshInstance3D
	_globe_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if globe == null: return
	var original := globe.get_active_material(0) as BaseMaterial3D
	if original != null:
		_globe_material = original.duplicate() as BaseMaterial3D
		_globe_material.emission_enabled = false
		_globe_material.emission = Color("bceee4")
		_globe_material.emission_texture = _globe_material.albedo_texture
		_globe_material.emission_energy_multiplier = 0.65
		globe.material_override = _globe_material
	_globe_light = OmniLight3D.new(); _globe_light.name = "FirstLight"
	_globe_light.light_color = Color("bceee4")
	_globe_light.light_energy = 1.1
	_globe_light.omni_range = 2.0
	_globe_light.visible = false
	model.add_child(_globe_light)
	_globe_light.global_position = globe.global_position
	# A small additive halo stays visible in the release renderer without whitening the map.
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.3, 1.0, 0.86, 0.65), Color(0.3, 1.0, 0.86, 0.0)])
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.width = 128; glow_texture.height = 128
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5); glow_texture.fill_to = Vector2(1.0, 0.5)
	var glow_material := StandardMaterial3D.new()
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glow_material.albedo_texture = glow_texture
	var halo := MeshInstance3D.new(); halo.name = "FirstLightHalo"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * globe.get_aabb().size.x * absf(globe.scale.x) * 2.0
	halo.mesh = quad; halo.material_override = glow_material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_globe_light.add_child(halo)
	if _globe_player == null: return
	var initial_rotation := globe.quaternion
	_globe_player.stop()
	# glTF's imported timeline has a 1/24 s offset. Preserve Africa's initial
	# pose and the fixed parent axial tilt; replace only the runtime rotation.
	var animation := Animation.new()
	animation.length = 24.0
	animation.loop_mode = Animation.LOOP_LINEAR
	var track := animation.add_track(Animation.TYPE_ROTATION_3D)
	var root := _globe_player.get_node(_globe_player.root_node)
	animation.track_set_path(track, root.get_path_to(globe))
	for index in range(97):
		animation.rotation_track_insert_key(track, float(index) * 0.25, initial_rotation * Quaternion(Vector3.UP, TAU * float(index) / 96.0))
	var library := AnimationLibrary.new()
	library.add_animation("earth_24s", animation)
	_globe_player.add_animation_library("runtime", library)
	_globe_player.play("runtime/earth_24s")
	_globe_player.seek(0.0, true)
	_globe_player.speed_scale = 0.0 if bool(ProjectSettings.get_setting("game/reduced_motion", false)) else 1.0

func _setup_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	# Warm white, continuing the light spilling round the door at the end of the opening film.
	sky_material.sky_top_color = Color(0.58, 0.58, 0.58)
	sky_material.sky_horizon_color = Color(0.93, 0.89, 0.82)
	sky_material.ground_bottom_color = Color(0.26, 0.24, 0.22)
	sky_material.ground_horizon_color = Color(0.72, 0.67, 0.60)
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.15, 0.17, 0.20)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.62
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.06
	# Only the ceiling strip and the screens bloom, softly.
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_strength = 0.9
	environment.glow_hdr_threshold = 0.95
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	world_environment.environment = environment
	viewport.add_child(world_environment)
	_add_light(Vector3(-3.5, 6.0, 4.0), Vector3(0, 1.2, 0), Color(1.0, 0.89, 0.74), 0.66, 75.0, 19.0, true)
	_add_light(Vector3(4.5, 5.5, 1.0), Vector3(0, 2, -1), Color(0.86, 0.91, 1.0), 0.26, 75.0, 18.0, true)
	_add_light(Vector3(0, 5.6, 1.5), Vector3(0, 1.4, 2.4), Color(1.0, 0.95, 0.86), 0.35, 48.0, 9.0, false)
	_add_light(Vector3(-1.2, 6.8, -8.6), Vector3(-1.2, 5.1, -11.7), Color(1.0, 0.90, 0.75), 0.8, 62.0, 10.0, false)

func _add_light(position_3d: Vector3, target: Vector3, color: Color, energy: float, angle: float, distance: float, shadows: bool) -> void:
	var light := SpotLight3D.new()
	light.position = position_3d
	light.light_color = color
	light.light_energy = energy
	light.spot_angle = angle
	light.spot_range = distance
	light.shadow_enabled = shadows
	# Shallow wall angles need enough bias to avoid striped self-shadowing.
	light.shadow_bias = 2.0
	light.shadow_normal_bias = 2.0
	viewport.add_child(light)
	light.look_at(target, Vector3.UP)
