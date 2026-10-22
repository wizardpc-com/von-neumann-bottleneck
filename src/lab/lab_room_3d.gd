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
## Snapshot only: callers cannot mutate the renderer's authoritative input copy.
var display_state: Dictionary:
	get:
		return _display_state.duplicate(true)
var _display_state: Dictionary = {}
var _station_labels: Array[Label3D] = []
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
	camera.fov = rad_to_deg(2.0 * atan(20.25 / 48.0))
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
	var base_fov: float = rad_to_deg(2.0 * atan(20.25 / 48.0))
	camera.fov = base_fov * pow(_focus_fov / base_fov, smoothstep(0.15, 1.0, _zoom))
	var glow_target: float = 0.0 if _hovered.is_empty() or not _interaction_enabled else 1.0
	_hover_glow = glow_target if reduced else move_toward(_hover_glow, glow_target, delta * 6.0)
	_hover_material.albedo_color = Color(0.13, 0.18, 0.21, _hover_glow)

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
	var background := ColorRect.new()
	background.color = Color("101f29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	standby_viewport.add_child(background)
	var text := Label.new()
	var localization: Node = get_node_or_null("/root/Localization")
	var english: bool = localization != null and localization.current_locale() == "en"
	text.text = "Yi\nOpen terminal · Enter" if english else "壹\n打开终端 · Enter"
	text.add_theme_font_override("font", DISPLAY_FONT)
	text.add_theme_font_size_override("font_size", 48)
	text.add_theme_color_override("font_color", Color("b9dcd9"))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	standby_viewport.add_child(text)
	var bounds: AABB = _screen.get_aabb()
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/lab/lab_screen.gdshader")
	material.set_shader_parameter("display_texture", standby_viewport.get_texture())
	material.set_shader_parameter("screen_bounds", Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
	_screen.material_override = material

## Immediate test/API pick; call after the physics world has settled.
## Normal GUI input is queued instead, so physics space is never queried locked.
func activate_at(pixel: Vector2) -> String:
	var id := _pick(pixel)
	if not id.is_empty():
		activated.emit(id)
	return id

func _gui_input(event: InputEvent) -> void:
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
		if index < _station_labels.size():
			# Colour carries the state: green done, amber current, pale open, dim locked.
			var label := _station_labels[index]
			label.text = "%s  %d/%d" % [title, done, station_total]
			label.modulate = Color("8ed8c5") if finished else (Color("f0c674") if current else (Color("b8d0dc") if available else Color("5f707c")))
	var count := maxi(0, works_count)
	var latest: Dictionary = works[-1] if count > 0 and not works.is_empty() and works[-1] is Dictionary else {}
	var latest_name := str(latest.get("name", ""))
	var output: Array = latest.get("output", []) if latest.get("output", []) is Array else []
	_display_state = {"stations": station_states, "works_count": count, "latest_name": latest_name,
		"latest_output": output.duplicate(), "completed": maxi(0, completed), "total": maxi(0, total), "current_key": current_key}
	if _works_title != null:
		_works_title.text = ("Works · %d" if english else "作品 · %d") % count
		if count == 0 or latest.is_empty():
			_works_name.text = ""
		else:
			_works_name.text = latest_name.substr(0, 24) if not latest_name.is_empty() else ("Untitled" if english else "未命名")
	for index in range(_work_pixels.size()):
		var pixel := _work_pixels[index]
		pixel.visible = index < output.size()
		if pixel.visible:
			pixel.modulate = WORK_COLORS[clampi(int(output[index]), 0, WORK_COLORS.size() - 1)]
	if _achievement_label != null:
		_achievement_label.text = ("Completed\n%d / %d" if english else "已完成\n%d / %d") % [maxi(0, completed), maxi(0, total)]

func _setup_status_displays() -> void:
	var board := model.find_child("Journey | blank panel", true, false) as MeshInstance3D
	if board != null:
		var bounds := board.get_aabb()
		for index in range(LabState.STATIONS.size()):
			var position_3d := Vector3(bounds.position.x + 0.08, bounds.end.y - 0.23 - float(index) * 0.25, bounds.end.z + 0.012)
			_station_labels.append(_surface_label(board, position_3d, 0.0055, 24))
	var works_board := model.find_child("Works | blue graphite recess", true, false) as MeshInstance3D
	if works_board != null:
		var bounds := works_board.get_aabb()
		var front: float = bounds.end.z + 0.02
		_works_title = _surface_label(works_board, Vector3(bounds.position.x + 0.13, bounds.end.y - 0.13, front), 0.0055, 32)
		_works_name = _surface_label(works_board, Vector3(bounds.position.x + 0.13, bounds.end.y - 0.34, front), 0.0055, 26)
		for index in range(32):
			var point := Vector3(bounds.position.x + 0.20 + float(index % 8) * 0.46, bounds.end.y - 0.52 - floorf(float(index) / 8.0) * 0.12, front)
			var pixel := _surface_label(works_board, point, 0.004, 28)
			pixel.text = "●"
			pixel.hide()
			_work_pixels.append(pixel)
	var achievements := model.find_child("Achievements | ceramic inset", true, false) as MeshInstance3D
	if achievements != null:
		var bounds := achievements.get_aabb()
		_achievement_label = _surface_label(achievements, Vector3(bounds.position.x + 0.15, bounds.end.y - 0.30, bounds.end.z + 0.025), 0.006, 32)
		_achievement_label.modulate = Color("253949")

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
	var globe := model.find_child("Status globe | opal sphere", true, false) as Node3D
	_globe_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if globe == null or _globe_player == null:
		return
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
	sky_material.sky_top_color = Color(0.33, 0.42, 0.57)
	sky_material.sky_horizon_color = Color(0.82, 0.85, 0.89)
	sky_material.ground_bottom_color = Color(0.16, 0.18, 0.23)
	sky_material.ground_horizon_color = Color(0.63, 0.63, 0.64)
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.15, 0.17, 0.20)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	viewport.add_child(world_environment)
	_add_light(Vector3(-3.5, 6.0, 4.0), Vector3(0, 1.2, 0), Color(1.0, 0.91, 0.78), 0.6, 75.0, 19.0, true)
	_add_light(Vector3(4.5, 5.5, 1.0), Vector3(0, 2, -1), Color(0.76, 0.87, 1.0), 0.3, 75.0, 18.0, true)
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
