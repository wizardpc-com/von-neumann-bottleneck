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
var inspect_button: Button
var overview_button: Button
var inspection_enabled: bool = false
var stage: Control
var viewport_3d: SubViewport
var camera: Camera3D
var geometry: Node3D
var markers: Control
var marker_buttons: Array[Button] = []
var positions: Array[Vector3] = []
var apparatus_nodes: Array[Node3D] = []
var previous_focus: Control
var english: bool = false

static func earned(task: Dictionary) -> bool:
	return bool(task.get("completed",false)) and str(task.get("progress_source","")) != "session" and str(task.get("evidence_status","")) not in ["unavailable","readonly","read_only","invalid"]

static func state_text(task: Dictionary, en: bool, tester: bool = false) -> String:
	if task.is_empty(): return "Task unavailable" if en else "任务不可确认"
	if str(task.get("progress_source","")) == "session": return "Temporary exploration · no permanent completion lamp" if en else "临时探索 · 不点亮永久成果灯"
	if str(task.get("evidence_status","")) in ["unavailable","readonly","read_only","invalid"]:
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
	stage.clip_contents = true
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
	var framing := HBoxContainer.new(); side.add_child(framing)
	inspect_button = _button(framing,"Inspect selected" if english else "近看所选装置",func() -> void: _set_inspection(true))
	inspect_button.name = "ObservatoryInspect"; inspect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_button = _button(framing,"Overview" if english else "还原全景",func() -> void: _set_inspection(false))
	overview_button.name = "ObservatoryOverview"; overview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	inspection_enabled = false
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
	if not task.is_empty():
		task_body.text += "\n\n"+("Source task: " if english else "来源任务：")+str(task.key)+"\n"+apparatus_description(task,english)
	if str(task.get("domain","")) == "creation" and not Creation.saved.get("readonly_works",[]).is_empty():
		task_body.text += "\n\n"+("Read-only works are retained. Visit the original workbench to inspect its recovery notice." if english else "只读作品仍被保留；请在原工作台查看恢复提示。")
	enter_button.disabled = task.is_empty() or not bool(task.get("unlocked",false))
	locate_button.disabled = task.is_empty()
	if task.is_empty(): inspection_enabled = false
	inspect_button.disabled = task.is_empty() or inspection_enabled
	overview_button.disabled = not inspection_enabled
	var controls: Array[Control] = [close_button,region_choice,view_choice,task_choice]
	if not inspect_button.disabled: controls.append(inspect_button)
	if not overview_button.disabled: controls.append(overview_button)
	if not locate_button.disabled: controls.append(locate_button)
	if not enter_button.disabled: controls.append(enter_button)
	for index: int in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index+controls.size()-1)%controls.size()])
	_position_camera()

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

func _set_inspection(enabled: bool) -> void:
	if PlaytestData._feedback_visible: return
	var framing_focused: bool = inspect_button.has_focus() or overview_button.has_focus()
	inspection_enabled = enabled
	select_task(selected_key)
	if framing_focused:
		if inspection_enabled: overview_button.grab_focus()
		elif not inspect_button.disabled: inspect_button.grab_focus()

static func apparatus_kind(task: Dictionary) -> String:
	match str(task.get("domain","")):
		"hardware_foundations": return "hardware_board"
		"chapter_1": return "system_modules"
	return "record_lamp"

static func apparatus_description(task: Dictionary, en: bool) -> String:
	match apparatus_kind(task):
		"hardware_board":
			return "Board and module shapes recall construction. They are not your saved circuit or live signals." if en else "板与模块回顾构造能力；这些抽象形状不是原电路，也不显示运行信号。"
		"system_modules":
			return "Three modules recall CPU, Bus and RAM. Shape and light mark records, not timing, traffic or energy." if en else "三组模块回顾CPU、Bus与RAM；装置和灯仅映射记录，不表示周期、流量或能耗。"
	return "The lamp recalls this task's earned record, not a physical measurement." if en else "灯台回顾本任务已有成果，不是物理测量。"

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.8
	if glow:
		material.emission_enabled = true; material.emission = color; material.emission_energy_multiplier = 1.1
	return material

func _mesh(shape: Mesh, point: Vector3, material: Material, parent: Node3D = null) -> void:
	var instance := MeshInstance3D.new(); instance.mesh = shape; instance.position = point
	instance.material_override = material
	if parent == null: geometry.add_child(instance)
	else: parent.add_child(instance)

func _box(parent: Node3D, extent: Vector3, point: Vector3, material: Material) -> void:
	var shape := BoxMesh.new(); shape.size = extent
	_mesh(shape,point,material,parent)

func _build_apparatus(task: Dictionary, point: Vector3) -> void:
	var complete: bool = earned(task)
	var apparatus := Node3D.new(); apparatus.name = "TaskApparatus"+str(apparatus_nodes.size()+1)
	apparatus.position = point; apparatus.set_meta("task_key",str(task.key))
	apparatus.set_meta("apparatus_kind",apparatus_kind(task)); apparatus.set_meta("earned",complete)
	geometry.add_child(apparatus); apparatus_nodes.append(apparatus)
	var base_material := _material(Color("324958"))
	var module_material := _material(Color("a3dcca") if complete else Color("506574"))
	match apparatus_kind(task):
		"hardware_board":
			_box(apparatus,Vector3(1.65,0.16,1.25),Vector3(0,0.15,0),base_material)
			for x: int in [-1,0,1]:
				_box(apparatus,Vector3(0.34,0.26,0.6),Vector3(x*0.48,0.36,0),module_material)
				for z: int in [-1,1]:
					_box(apparatus,Vector3(0.20,0.08,0.12),Vector3(x*0.48,0.3,z*0.39),base_material)
		"system_modules":
			_box(apparatus,Vector3(1.75,0.16,1.1),Vector3(0,0.15,0),base_material)
			for x: int in [-1,0,1]:
				_box(apparatus,Vector3(0.40,0.35+abs(x)*0.20,0.65),Vector3(x*0.58,0.5,0),module_material)
		_:
			var base := CylinderMesh.new(); base.top_radius = 0.48; base.bottom_radius = 0.62; base.height = 0.55
			_mesh(base,Vector3(0,0.2,0),base_material,apparatus)
	var pillar := CylinderMesh.new(); pillar.top_radius = 0.10; pillar.bottom_radius = 0.13; pillar.height = 0.50
	_mesh(pillar,Vector3(0,0.85,0),module_material,apparatus)
	var lamp := SphereMesh.new(); lamp.radius = 0.26; lamp.height = 0.52
	_mesh(lamp,Vector3(0,1.16,0),_material(Color("7fe4b7") if complete else Color("293c49"),complete),apparatus)
	if complete:
		# The raised record tab remains distinguishable without a glow or color cue.
		_box(apparatus,Vector3(0.48,0.10,0.18),Vector3(0,1.53,0),module_material)
		var light := OmniLight3D.new(); light.position = Vector3(0,1.35,0)
		light.light_color = Color("8ce8c4"); light.light_energy = 0.8; light.omni_range = 2; apparatus.add_child(light)

func _build_geometry() -> void:
	for child: Node in geometry.get_children(): geometry.remove_child(child); child.queue_free()
	for child: Node in markers.get_children(): markers.remove_child(child); child.queue_free()
	positions.clear(); marker_buttons.clear(); apparatus_nodes.clear()
	var depth: int = maxi(1,ceili(float(region_rows.size())/4.0))
	var floor_mesh := BoxMesh.new(); floor_mesh.size = Vector3(11,0.18,maxf(5,depth*2.5+1))
	_mesh(floor_mesh,Vector3(0,-0.2,0),_material(Color("142a35")))
	for index: int in region_rows.size():
		var task: Dictionary = region_rows[index]
		var point := Vector3((index%4-1.5)*2.5,0,(float(index/4)-(depth-1)*0.5)*2.5)
		var complete: bool = earned(task)
		_build_apparatus(task,point)
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
	var selected_index: int = -1
	for index: int in region_rows.size():
		if str(region_rows[index].key) == selected_key: selected_index = index
	if selected_index < 0: inspection_enabled = false
	var target := Vector3.ZERO
	if inspection_enabled: target = positions[selected_index]-Vector3(0,0.95,0)
	camera.size = 4.6 if inspection_enabled else maxf(11,depth*2.5+3)
	var viewpoints: Array[Vector3] = [Vector3(11,13,16),Vector3(-16,13,11),Vector3(0,23,0.1)]
	camera.position = target+viewpoints[view_choice.selected]
	camera.look_at(target)
	for index: int in apparatus_nodes.size(): apparatus_nodes[index].visible = not inspection_enabled or index == selected_index
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
		var inside: bool = Rect2(Vector2.ZERO,stage.size).encloses(Rect2(button.position,extent))
		button.visible = inside and not camera.is_position_behind(positions[index]) and (not inspection_enabled or str(region_rows[index].key) == selected_key)
		button.disabled = not button.visible
