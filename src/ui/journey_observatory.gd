extends Control
## Optional spatial presentation. TaskNavigation and domain saves own all progress.
signal tree_requested(key: String)
const Creation = preload("res://src/campaign/creation_tasks.gd")
var rows: Array[Dictionary] = []
var region_rows: Array[Dictionary] = []
var selected_key: String = ""
var region_choice: OptionButton
var task_choice: OptionButton
var view_choice: OptionButton
var summary: Label
var task_title: Label
var task_status: Label
var task_body: Label
var enter_button: Button
var locate_button: Button
var close_button: Button
var stage: Control
var viewport_3d: SubViewport
var camera: Camera3D
var geometry: Node3D
var markers: Control
var marker_buttons: Array[Button] = []
var positions: Array[Vector3] = []
var previous_focus: Control
var english: bool = false

static func earned(task: Dictionary) -> bool:
	return bool(task.get("completed",false)) and str(task.get("progress_source","")) != "session" and str(task.get("evidence_status","")) not in ["unavailable","readonly","invalid"]

static func state_text(task: Dictionary, en: bool, tester: bool = false) -> String:
	if task.is_empty(): return "Task unavailable" if en else "任务不可确认"
	if str(task.get("progress_source","")) == "session": return "Temporary exploration · no permanent completion lamp" if en else "临时探索 · 不点亮永久成果灯"
	if str(task.get("evidence_status","")) in ["unavailable","readonly","invalid"]:
		return "! Saved accepted plan cannot be verified · lamp stays off" if en else "! 保存的达标方案暂无法核验 · 成果灯暂不亮"
	if earned(task): return "✓ Earned completion record · lamp on" if en else "✓ 已有合法完成记录 · 成果灯亮起"
	if tester and bool(task.get("unlocked",false)): return "○ Tester access · no earned completion" if en else "○ 测试入口开放 · 尚无完成记录"
	return ("○ Available · not completed" if en else "○ 可以进入 · 尚未完成") if bool(task.get("unlocked",false)) else ("Locked · existing prerequisites apply" if en else "未开放 · 沿用原任务前置")

func _ready() -> void:
	name = "JourneyObservatory"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 60
	var skin := Theme.new(); skin.default_font_size = 18
	preload("res://src/ui/instrument_theme.gd").apply_to(skin); theme = skin
	english = Localization.current_locale() == "en"
	var background := ColorRect.new(); background.color = Color("091119")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top"]: margin.add_theme_constant_override("margin_"+edge,24)
	margin.add_theme_constant_override("margin_bottom",64); add_child(margin)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",10); margin.add_child(column)
	var header := HBoxContainer.new(); column.add_child(header)
	var heading := _label(header,"Journey observatory · optional 3D study" if english else "旅程观察站 · 可选3D候选空间",28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button = _button(header,"Close · Esc" if english else "关闭 · Esc",close)
	_label(column,"Lamps recall earned work, not circuit signals or energy measurements. Browsing does not change your results." if english else "灯光回顾已有成果，不表示电路信号或能耗；浏览不会改变成绩。",16)
	var selectors := HBoxContainer.new(); column.add_child(selectors)
	region_choice = OptionButton.new(); region_choice.name = "ObservatoryRegion"
	region_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL; region_choice.custom_minimum_size.y = 42; selectors.add_child(region_choice)
	region_choice.item_selected.connect(_choose_region)
	view_choice = OptionButton.new(); view_choice.name = "ObservatoryView"
	for title: String in (["View · North","View · East","View · Overhead"] if english else ["视角 · 北侧","视角 · 东侧","视角 · 俯瞰"]): view_choice.add_item(title)
	view_choice.custom_minimum_size.y = 42; selectors.add_child(view_choice)
	view_choice.item_selected.connect(func(_index: int) -> void: _position_camera())
	summary = _label(column,"",16)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",20); column.add_child(body)
	stage = Control.new(); stage.name = "ObservatoryStage"; stage.custom_minimum_size = Vector2(400,240)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL; stage.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_child(stage)
	var surface := SubViewportContainer.new(); surface.name = "Observatory3D"
	surface.stretch = true; surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); stage.add_child(surface)
	viewport_3d = SubViewport.new(); viewport_3d.name = "WorldViewport"; viewport_3d.own_world_3d = true
	viewport_3d.size = Vector2i(800,480); viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED; surface.add_child(viewport_3d)
	var world := Node3D.new(); viewport_3d.add_child(world)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.current = true; world.add_child(camera)
	var environment := WorldEnvironment.new(); environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR; environment.environment.background_color = Color("0c1820")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b8d1dd"); environment.environment.ambient_light_energy = 0.7; world.add_child(environment)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-55,-25,0); light.light_energy = 1.1; world.add_child(light)
	geometry = Node3D.new(); geometry.name = "RecordGeometry"; world.add_child(geometry)
	markers = Control.new(); markers.name = "NativeNodeLabels"; markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	markers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); stage.add_child(markers)
	stage.resized.connect(func() -> void: call_deferred("_position_markers"))
	var side := VBoxContainer.new(); side.custom_minimum_size.x = 340; body.add_child(side)
	task_choice = OptionButton.new(); task_choice.name = "ObservatoryTask"; task_choice.custom_minimum_size.y = 42
	task_choice.clip_text = true; side.add_child(task_choice)
	task_choice.item_selected.connect(func(index: int) -> void: select_task(str(task_choice.get_item_metadata(index))))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; side.add_child(scroll)
	var text := VBoxContainer.new(); text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; text.add_theme_constant_override("separation",12); scroll.add_child(text)
	task_title = _label(text,"",23); task_status = _label(text,"",18); task_body = _label(text,"",17)
	locate_button = _button(side,"Locate in task tree" if english else "在高效任务树定位",_locate)
	enter_button = _button(side,"Return to original workbench" if english else "进入原工作台",_enter)
	_label(column,"Select numbered lamps or use the task list. View changes add no result; close returns to the same page." if english else "可点编号灯台或使用任务列表；切换视角不产生成果，关闭回到原页面。",14)
	hide()

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size); parent.add_child(label); return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size.y = 42
	button.pressed.connect(action); parent.add_child(button); return button

func open() -> void:
	if PlaytestData._feedback_visible or get_viewport().gui_is_dragging(): return
	previous_focus = get_viewport().gui_get_focus_owner()
	refresh(TaskNavigation.journey_tasks())
	show(); viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	close_button.grab_focus(); call_deferred("_position_markers")

func close() -> void:
	hide(); viewport_3d.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	previous_focus = null

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or PlaytestData._feedback_visible: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close(); get_viewport().set_input_as_handled()

func refresh(data: Array[Dictionary]) -> void:
	rows = data.duplicate(true); region_choice.clear()
	var regions: Array[int] = []
	var completed: int = 0
	for task: Dictionary in rows:
		if earned(task): completed += 1
		var region: int = int(task.region)
		if region in regions: continue
		regions.append(region)
		region_choice.add_item(str(task.get("region_title",Localization.text(StringName("tree.region."+str(region))))))
		region_choice.set_item_metadata(region_choice.item_count-1,region)
	summary.text = ("%d actual tasks · %d completion records · lit records stay distinct from accessible entrances" if english else "%d项真实任务 · %d项完成记录 · 灯光成果与可访问入口分别计算") % [rows.size(),completed]
	var index: int = 0
	for task: Dictionary in rows:
		if task.key == selected_key or (selected_key.is_empty() and task.key == TaskNavigation.selected):
			index = regions.find(int(task.region)); break
	if not regions.is_empty(): region_choice.select(index); _choose_region(index)
	else:
		region_rows.clear(); _build_geometry(); select_task("")

func _choose_region(index: int) -> void:
	region_rows.clear(); task_choice.clear()
	var region: int = int(region_choice.get_item_metadata(index))
	for task: Dictionary in rows:
		if int(task.region) != region: continue
		region_rows.append(task)
		task_choice.add_item(("✓ " if earned(task) else "○ ")+str(task.title))
		task_choice.set_item_metadata(task_choice.item_count-1,task.key)
	_build_geometry()
	var key: String = ""
	for task: Dictionary in region_rows:
		if task.key == selected_key: key = selected_key
	if key.is_empty() and not region_rows.is_empty(): key = str(region_rows[0].key)
	select_task(key)

func select_task(key: String) -> void:
	selected_key = key
	var task: Dictionary = {}
	for index: int in region_rows.size():
		var row: Dictionary = region_rows[index]
		if str(row.key) == key: task = row; task_choice.select(index)
		if index < marker_buttons.size(): marker_buttons[index].set_pressed_no_signal(str(row.key) == key)
	task_title.text = str(task.get("title","Task unavailable" if english else "任务不可确认"))
	task_status.text = state_text(task,english,TaskNavigation.offline_tester_enabled() or GameMode.is_test_mode())
	task_body.text = str(task.get("body",""))+"\n\n"+str(task.get("eligibility_note",""))
	if str(task.get("domain","")) == "creation" and not Creation.saved.get("readonly_works",[]).is_empty():
		task_body.text += "\n\n"+("Read-only works are retained. Visit the original workbench to inspect its recovery notice." if english else "只读作品仍被保留；请在原工作台查看恢复提示。")
	enter_button.disabled = task.is_empty() or not bool(task.get("unlocked",false))
	locate_button.disabled = task.is_empty()
	var controls: Array[Control] = [close_button,region_choice,view_choice,task_choice,locate_button]
	if not enter_button.disabled: controls.append(enter_button)
	for index: int in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index+controls.size()-1)%controls.size()])

func _locate() -> void:
	if locate_button.disabled: return
	var key: String = selected_key
	var current: Array[Dictionary] = TaskNavigation.journey_tasks()
	for task: Dictionary in current:
		if str(task.key) == key:
			close(); tree_requested.emit(key); return
	refresh(current)

func _enter() -> void:
	var current: Array[Dictionary] = TaskNavigation.journey_tasks()
	for task: Dictionary in current:
		if str(task.key) == selected_key and bool(task.unlocked):
			if TaskNavigation.enter(selected_key): close()
			return
	refresh(current)
	task_status.text = "Access changed; inspect the current task list." if english else "进入条件已变化；请检查当前任务列表。"

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.8
	if glow:
		material.emission_enabled = true; material.emission = color; material.emission_energy_multiplier = 1.1
	return material

func _mesh(shape: Mesh, point: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new(); instance.mesh = shape; instance.position = point
	instance.material_override = material; geometry.add_child(instance)

func _build_geometry() -> void:
	for child: Node in geometry.get_children(): geometry.remove_child(child); child.queue_free()
	for child: Node in markers.get_children(): markers.remove_child(child); child.queue_free()
	positions.clear(); marker_buttons.clear()
	var depth: int = maxi(1,ceili(float(region_rows.size())/4.0))
	var floor_mesh := BoxMesh.new(); floor_mesh.size = Vector3(11,0.18,maxf(5,depth*2.5+1))
	_mesh(floor_mesh,Vector3(0,-0.2,0),_material(Color("142a35")))
	for index: int in region_rows.size():
		var task: Dictionary = region_rows[index]
		var point := Vector3((index%4-1.5)*2.5,0,(float(index/4)-(depth-1)*0.5)*2.5)
		var complete: bool = earned(task)
		var base := CylinderMesh.new(); base.top_radius = 0.48; base.bottom_radius = 0.62; base.height = 0.55
		_mesh(base,point+Vector3(0,0.2,0),_material(Color("324958")))
		var pillar := CylinderMesh.new(); pillar.top_radius = 0.12; pillar.bottom_radius = 0.16; pillar.height = 0.65
		_mesh(pillar,point+Vector3(0,0.75,0),_material(Color("a3dcca") if complete else Color("506574"),complete))
		var lamp := SphereMesh.new(); lamp.radius = 0.26; lamp.height = 0.52
		_mesh(lamp,point+Vector3(0,1.16,0),_material(Color("7fe4b7") if complete else Color("293c49"),complete))
		if complete:
			var light := OmniLight3D.new(); light.position = point+Vector3(0,1.35,0)
			light.light_color = Color("8ce8c4"); light.light_energy = 0.8; light.omni_range = 2; geometry.add_child(light)
		positions.append(point+Vector3(0,1.6,0))
		var key: String = str(task.key)
		var marker := Button.new(); marker.name = "Lamp"+str(index+1); marker.toggle_mode = true
		marker.focus_mode = Control.FOCUS_NONE
		marker.text = ("✓" if complete else "○")+str(index+1); marker.custom_minimum_size = Vector2(52,34)
		marker.tooltip_text = str(task.title)+"\n"+state_text(task,english)
		marker.pressed.connect(func() -> void: select_task(key)); markers.add_child(marker); marker_buttons.append(marker)
	_position_camera()

func _position_camera() -> void:
	var depth: int = maxi(1,ceili(float(region_rows.size())/4.0))
	camera.size = maxf(11,depth*2.5+3)
	var viewpoints: Array[Vector3] = [Vector3(11,13,16),Vector3(-16,13,11),Vector3(0,23,0.1)]
	camera.position = viewpoints[view_choice.selected]; camera.look_at(Vector3.ZERO)
	call_deferred("_position_markers")

func _position_markers() -> void:
	if not is_inside_tree() or stage.size.x <= 0 or viewport_3d.size.x <= 0: return
	var scale_factor := stage.size/Vector2(viewport_3d.size)
	for index: int in marker_buttons.size():
		var button: Button = marker_buttons[index]
		var projected: Vector2 = camera.unproject_position(positions[index])*scale_factor
		# In overhead view height projects onto the same pixel as the sphere.
		var extent: Vector2 = button.get_combined_minimum_size()
		button.size = extent
		button.position = projected-Vector2(extent.x*0.5,extent.y+18)
