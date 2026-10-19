extends SceneTree
## Real tutorial/work setup; synthetic state cases never become player achievements.
const Session = preload("res://experiments/creation/session.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var Observatory: Script
var checks: int = 0
var failures: Array[String] = []
var capture_enabled: bool = false
var captures: Array[Dictionary] = []
var sizes: Array[Vector2i] = [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1440,900)]

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame: int in 8: await process_frame

func key(code: Key) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down
		if code == KEY_F8: Input.parse_input_event(event)
		else: root.push_input(event,true)
		await settle()

func point_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	root.push_input(motion,true)
	await settle()

func click(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	await point_at(point)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.position = point; event.global_position = point; event.pressed = down
		root.push_input(event,true)
		await settle()

func rect_fields(rect: Rect2) -> Array[String]:
	return ["%.17f" % rect.position.x,"%.17f" % rect.position.y,"%.17f" % rect.size.x,"%.17f" % rect.size.y]

func pixel_bounds(rect: Rect2) -> Rect2i:
	return Rect2i(Vector2i(rect.position.floor()),Vector2i(rect.end.ceil()-rect.position.floor()))

func transform_fields(value: Transform3D) -> Array:
	var fields: Array = []
	for vector: Vector3 in [value.origin,value.basis.x,value.basis.y,value.basis.z]:
		fields.append(["%.17f" % vector.x,"%.17f" % vector.y,"%.17f" % vector.z])
	return fields

func inventory(path: String) -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(path)
	if directory == null: return result
	for filename: String in directory.get_files(): result[filename] = FileAccess.get_sha256(path.path_join(filename))
	for folder: String in directory.get_directories():
		if folder in ["logs","shader_cache","playtest_data","offline_playtest"]: continue
		result[folder+"/"] = true
		var children: Dictionary = inventory(path.path_join(folder))
		for child: String in children: result[folder+"/"+child] = children[child]
	return result

func protected_state() -> Dictionary:
	var disk: Dictionary = inventory("user://"); disk.erase("feedback_drafts_v1.json")
	var game: Dictionary = root.get_node("GlobalSave")._save_snapshot(); game.erase("saved_at_utc")
	var nav: Node = root.get_node("TaskNavigation")
	return {"disk":disk,"game":game,"best":root.get_node("PersonalRecords").best.duplicate(true),
		"lease":DirAccess.dir_exists_absolute(Lease.lock_path(Session.launch_path())),
		"recovery_lease":DirAccess.dir_exists_absolute(Lease.lock_path(Session.launch_path())+".recovering"),
		"nav":{"pending":nav.pending,"selected":nav.selected,"from_tree":nav.from_tree,
			"camera":nav.camera,"zoom":nav.zoom,"camera_saved":nav.camera_saved,"camera_view_size":nav.camera_view_size}}

func pick_region(observatory: Control, region: int) -> void:
	for index: int in observatory.region_choice.item_count:
		if int(observatory.region_choice.get_item_metadata(index)) == region:
			observatory.region_choice.select(index); observatory.region_choice.item_selected.emit(index)
			await settle(); return
	check(false,"Actual catalog contains region "+str(region))

func check_controls(observatory: Control, scope: String) -> void:
	for control: Control in [observatory.close_button,observatory.region_choice,observatory.view_choice,observatory.task_choice,
		observatory.inspect_button,observatory.overview_button,observatory.locate_button,observatory.enter_button]:
		check(control.is_visible_in_tree() and root.get_visible_rect().encloses(control.get_global_rect()),"Native action fits actual viewport: "+scope+" "+control.name)
	check(observatory.stage.clip_contents,"The actual stage clips its native marker descendants")
	for marker: Button in observatory.marker_buttons:
		check(marker.focus_mode == Control.FOCUS_NONE,"The task dropdown remains the keyboard alternative to spatial markers")
		if marker.visible:
			check(observatory.stage.get_global_rect().encloses(marker.get_global_rect()) and not marker.disabled,"Every visible spatial marker is inside its clipping stage and enabled: "+scope)
			check(marker.size.x >= marker.custom_minimum_size.x and marker.size.y >= marker.custom_minimum_size.y,"Visible marker retains its minimum pointer target: "+scope)
		else: check(marker.disabled,"Offstage/other-task labels cannot intercept pointer input: "+scope)

func check_unobstructed(observatory: Control) -> void:
	var floating_script: Script = load("res://src/ui/floating_instrument_panel.gd")
	for node: Control in root.find_children("*","Control",true,false):
		if node.get_script() == floating_script:
			check(not node.is_visible_in_tree(),"Original workbench floating panels cannot cover the Home observatory")
	for target: Control in [observatory.stage,observatory.task_choice,observatory.inspect_button,
		observatory.overview_button,observatory.locate_button,observatory.enter_button]:
		await point_at(target.get_global_rect().get_center())
		var hovered: Control = root.gui_get_hovered_control()
		check(hovered != null and observatory.is_ancestor_of(hovered),"Actual stage/sidebar pointer belongs to the Home observatory: "+target.name)

func capture(observatory: Control, name: String, scope: String) -> void:
	if not capture_enabled: return
	if DisplayServer.get_name() == "headless":
		check(false,"Apparatus capture requires an actual renderer"); return
	await check_unobstructed(observatory)
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	var world: Image = observatory.viewport_3d.get_texture().get_image()
	check(not world.is_empty() and frame.get_size() == root.size,"Real3D texture and exact window dimensions: "+name)
	if world.is_empty(): return
	var colors: Dictionary = {}
	for y: int in range(0,world.get_height(),16):
		for x: int in range(0,world.get_width(),16): colors[world.get_pixel(x,y).to_html()] = true
	check(colors.size()>5,"Actual apparatus texture contains rendered geometry: "+name)
	var folder: String = "res://.godot/observatory-apparatus-captures"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"Capture output is available")
	var path: String = folder.path_join(name+".png"); var texture_path: String = folder.path_join(name+"-3d.png")
	check(not FileAccess.file_exists(path) and not FileAccess.file_exists(texture_path),"Do not overwrite a previous apparatus frame: "+name)
	if FileAccess.file_exists(path) or FileAccess.file_exists(texture_path): return
	check(frame.save_png(path) == OK and world.save_png(texture_path) == OK,"Actual frame and3D texture write: "+name)
	captures.append({"frame":ProjectSettings.globalize_path(path),"frame_sha256":FileAccess.get_sha256(path),
		"world":ProjectSettings.globalize_path(texture_path),"world_sha256":FileAccess.get_sha256(texture_path),
		"pixels":[frame.get_width(),frame.get_height()],"scope":scope,"task":observatory.selected_key,
		"inspection":observatory.inspection_enabled,"view":observatory.view_choice.selected})

func state_cases(observatory: Control) -> void:
	var source: Dictionary = root.get_node("TaskNavigation").journey_tasks()[0].duplicate(true)
	check(source.key == "hardware_foundations/tutorial","State fixtures retain an actual task identity")
	for domain: String in ["hardware_foundations","chapter_1"]:
		var task: Dictionary = source.duplicate(true)
		if domain == "chapter_1":
			for actual: Dictionary in root.get_node("TaskNavigation").journey_tasks():
				if actual.domain == domain: task = actual.duplicate(true); break
		for state: String in ["unearned","tester","earned","unavailable","readonly","read_only","invalid","session"]:
			var fixture: Dictionary = task.duplicate(true)
			fixture.unlocked = state != "unearned"; fixture.completed = state not in ["unearned","tester"]
			fixture.erase("evidence_status"); fixture.erase("progress_source")
			if state in ["unavailable","readonly","read_only","invalid"]: fixture.evidence_status = state
			if state == "session": fixture.progress_source = "session"
			var fixtures: Array[Dictionary] = [fixture]; observatory.refresh(fixtures); await settle()
			var earned: bool = state == "earned"
			check(observatory.apparatus_nodes[0].get_meta("task_key") == task.key and observatory.apparatus_nodes[0].get_meta("earned") == earned,"Synthetic state maps only this source task, not player progress: "+domain+" "+state)
			check(observatory.geometry.find_children("*","OmniLight3D",true,false).size() == (1 if earned else 0),"Only legal earned state adds a record light: "+state)
			check(observatory.marker_buttons[0].text.begins_with("✓" if earned else "○"),"Record status has a non-color native symbol: "+state)
			check(observatory.enter_button.disabled == not fixture.unlocked,"Apparatus presentation does not grant task access: "+state)
			if state == "tester": check(Observatory.state_text(fixture,true,true).contains("Tester"),"Tester-open state does not masquerade as earned")
			if state in ["unavailable","readonly","read_only","invalid"]: check(observatory.task_status.text.contains("核验") or observatory.task_status.text.contains("verified"),"Unverifiable saved support stays explicit: "+state)
	var empty: Array[Dictionary] = []; observatory.refresh(empty); await settle()
	check(observatory.apparatus_nodes.is_empty() and observatory.inspect_button.disabled and observatory.overview_button.disabled,"Procedural apparatus needs no media; an empty catalog has no inspection target")
	observatory._set_inspection(true); observatory._enter()
	var actual_rows: Array[Dictionary] = root.get_node("TaskNavigation").journey_tasks()
	for task: Dictionary in actual_rows:
		if not bool(task.unlocked):
			var stale: Dictionary = task.duplicate(true); stale.unlocked = true
			var fixtures: Array[Dictionary] = [stale]; observatory.refresh(fixtures); await settle()
			var before: Dictionary = protected_state()
			observatory._enter()
			check(protected_state() == before,"A stale accessible snapshot cannot bypass current original task prerequisites")
			return
	check(false,"Ordinary fixture retains a locked task to test click-time eligibility")

func feedback_route(observatory: Control, launcher: Button, tester: bool) -> void:
	var feedback: Node = root.get_node("OfflineFeedback"); var moments: Node = root.get_node("PlaytestMoments")
	ProjectSettings.set_setting("playtest/offline_tester",tester); feedback.toolbar.visible = tester
	observatory.close(); launcher.grab_focus(); observatory.open(); await settle()
	observatory.inspect_button.grab_focus(); await key(KEY_SPACE)
	check(observatory.inspection_enabled and observatory.overview_button.has_focus(),"Keyboard inspection hands focus to the enabled overview action")
	var before: Dictionary = protected_state()
	await key(KEY_F8)
	check((feedback.backdrop.visible if tester else moments.panel.visible) and observatory.visible,"Real F8 opens the existing role feedback above the inspected apparatus")
	await key(KEY_ESCAPE)
	check(not (feedback.backdrop.visible if tester else moments.panel.visible) and observatory.visible and observatory.inspection_enabled,"First Escape closes only feedback, retaining the apparatus view")
	check(observatory.overview_button.has_focus(),"Feedback restores the exact framing-action focus")
	await key(KEY_ESCAPE)
	check(not observatory.visible and root.gui_get_focus_owner() == launcher,"Next Escape returns to the original launcher")
	check(protected_state() == before,"Feedback and framing preserve all saved work payloads, game, leases and navigation")
	observatory.open(); await settle()
	check(not observatory.inspection_enabled and observatory.rows == root.get_node("TaskNavigation").journey_tasks(),"Reopen starts in overview with fresh original data and reuses the same instance")

func run() -> void:
	preload("res://src/lab/lab_features.gd").classic = true # verifies the classic Home/tutorial surfaces
	preload("res://src/lab/lab_features.gd").core_journey = true
	Observatory = load("res://src/ui/journey_observatory.gd")
	if Observatory == null or not Observatory.can_instantiate():
		check(false,"Observatory compiles after autoloads"); quit(1); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	capture_enabled = "--observatory-apparatus-capture" in args
	for argument: String in args:
		if argument.begins_with("--capture-size="):
			var dimensions: PackedStringArray = argument.trim_prefix("--capture-size=").split("x")
			if dimensions.size() == 2: sizes.assign([Vector2i(int(dimensions[0]),int(dimensions[1]))])
	var nav: Node = root.get_node("TaskNavigation"); var save: Node = root.get_node("GlobalSave"); var locale: Node = root.get_node("Localization")
	var old_locale: String = locale.current_locale()
	var old_creation: Variant = ProjectSettings.get_setting("candidate/creation_enabled",false)
	var old_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester",false)
	var old_motion: Variant = ProjectSettings.get_setting("game/reduced_motion",false)
	var feedback: Node = root.get_node("OfflineFeedback"); var toolbar_visible: bool = feedback.toolbar.visible
	ProjectSettings.set_setting("candidate/creation_enabled",true); ProjectSettings.set_setting("playtest/offline_tester",false)
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test("user://apparatus-game.json","user://apparatus-board.json")
	check(nav.enter("hardware_foundations/tutorial"),"Real original tutorial navigation is available")
	await settle()
	var original_host: Variant = current_scene
	var ready: bool = is_instance_valid(original_host) and original_host.current_level_id == &"tutorial" and is_instance_valid(original_host.input_a_button)
	check(ready,"Actual tutorial controls are ready before original five-action setup")
	if not ready: quit(1); return
	if original_host.mission_briefing_active: original_host._start_building_from_briefing()
	original_host._on_connection_request(&"A_IN",0,&"NOT_1",0); original_host._on_connection_request(&"NOT_1",0,&"LAMP",0)
	original_host.input_a_button.button_pressed = true; original_host._run_debug()
	original_host._on_disconnection_request(&"NOT_1",0,&"LAMP",0)
	check(not save.game_player_content.completed_levels.get(&"tutorial",false),"Unfinished operation sequence cannot earn an apparatus record")
	original_host._on_connection_request(&"NOT_1",0,&"LAMP",0); await settle()
	check(save.game_player_content.completed_levels.get(&"tutorial",false),"Only actual tutorial completion supplies the earned main capture")
	original_host._dismiss_level_completion(); original_host._save_active_workbench(); check(save.save_game(true),"Original earned task and circuit are saved before browsing")
	var writer: Variant = Session.new()
	check(writer.open(Session.launch_path()).writable,"Only setup owns an isolated writer")
	check(writer.train().ok and writer.transport([0,1,0,2],"predictive").ok,"Protected work setup learns and losslessly restores real data")
	writer.set_mode("predict"); writer.begin_prediction("practice")
	while not writer.prediction.finished: writer.commit_prediction(); writer.reveal_prediction()
	writer.set_mode("generate")
	check(writer.generate().ok and writer.save_work("Observatory protected original").ok,"Setup saves a real generated work, not a byte placeholder")
	writer.close()
	print("SETUP: actual tutorial five controller actions and isolated C/P/G work; no synthetic completion fixture is persisted")
	check(change_scene_to_file("res://src/ui/prototype_hub.tscn") == OK,"Original tutorial exits through a normal scene change to Home")
	await settle()
	check(not is_instance_valid(original_host),"Previous tutorial host and its floating panels are released before browsing")
	if is_instance_valid(original_host): quit(1); return
	var host: Control = current_scene
	var launcher: Button
	var before: Dictionary = protected_state()
	var initial_authority: Dictionary = before.duplicate(true); initial_authority.erase("nav")
	for language: String in ["zh_CN","en"]:
		locale.set_locale(language)
		# Rebuild the real localized Home before resolving its lazy entry again.
		check(change_scene_to_file("res://src/ui/prototype_hub.tscn") == OK,"Localized Home loads through the original scene lifecycle")
		await settle(); host = current_scene
		launcher = host.find_child("OpenJourneyObservatory",true,false)
		check(launcher != null,"Actual Home offers its optional observatory launcher")
		if launcher == null: quit(1); return
		launcher.grab_focus(); launcher.pressed.emit(); await settle()
		var observatory: Control = host.journey_observatory
		check(is_instance_valid(observatory) and observatory.get_parent() == host and observatory.visible,"Actual Home lazy hook opens its own observatory instance")
		if not is_instance_valid(observatory): quit(1); return
		check(observatory.rows == nav.journey_tasks(),"New view opens the actual loaded task snapshot")
		for dimensions: Vector2i in sizes:
			check(dimensions.x>=1280 and dimensions.y>=720,"Supported apparatus comparison size")
			if capture_enabled and DisplayServer.get_name() != "headless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(dimensions)
			root.size = dimensions; root.content_scale_size = dimensions; await settle()
			ProjectSettings.set_setting("game/reduced_motion",true)
			for region: int in [0,1]:
				await pick_region(observatory,region)
				var kind: String = "hardware_board" if region == 0 else "system_modules"
				for index: int in observatory.region_rows.size():
					check(observatory.apparatus_nodes[index].get_meta("apparatus_kind") == kind and observatory.apparatus_nodes[index].get_meta("task_key") == observatory.region_rows[index].key,"Each distinct apparatus belongs to its actual source task")
				observatory.overview_button.pressed.emit(); await settle()
				var overview_pose: Transform3D = observatory.camera.transform
				var overview_size: float = observatory.camera.size
				var overview_geometry: Array = []
				for apparatus: Node3D in observatory.apparatus_nodes: overview_geometry.append(apparatus.transform)
				var overview_markers: Array = []
				for marker: Button in observatory.marker_buttons: overview_markers.append(marker.get_rect())
				if observatory.region_rows.size()>1:
					observatory.task_choice.select(1); observatory.task_choice.item_selected.emit(1); await settle()
				await click(observatory.marker_buttons[0])
				check(observatory.selected_key == observatory.region_rows[0].key,"Actual pointer selects the projected original task marker")
				var selected: String = observatory.selected_key
				check(observatory.task_body.text.contains(selected),"Inspection identifies its exact original task in native text")
				check_controls(observatory,language+str(dimensions)+kind+" overview")
				await capture(observatory,language+"-"+str(dimensions.x)+"x"+str(dimensions.y)+"-"+kind+"-overview","Actual catalog and real tutorial earned state; system records remain actual existing data")
				await click(observatory.inspect_button)
				check(observatory.inspection_enabled and observatory.camera.size < overview_size,"Actual Inspect action frames the selected apparatus")
				check_controls(observatory,language+str(dimensions)+kind+" inspect")
				for view: int in 3:
					observatory.view_choice.select(view); observatory.view_choice.item_selected.emit(view); await settle()
					check(observatory.selected_key == selected and observatory.camera.projection == Camera3D.PROJECTION_ORTHOGONAL,"Three presets retain the original selected task during inspection")
					for index: int in observatory.marker_buttons.size():
						var marker: Button = observatory.marker_buttons[index]
						var is_selected: bool = str(observatory.region_rows[index].key) == selected
						check(marker.visible == is_selected and marker.disabled == not is_selected,"Inspection hides and disables every other marker instead of projecting it over sidebar controls")
						check(observatory.apparatus_nodes[index].visible == is_selected,"Only selected geometry is visible in near view")
					check_controls(observatory,language+str(dimensions)+kind+" preset"+str(view))
					await click(observatory.marker_buttons[0])
					check(observatory.selected_key == selected,"Visible near-view marker remains pointer reachable")
				await capture(observatory,language+"-"+str(dimensions.x)+"x"+str(dimensions.y)+"-"+kind+"-inspect","Selected real task; abstract record apparatus, not saved circuit geometry or live measurement; three presets tested")
				observatory.view_choice.select(0); observatory.view_choice.item_selected.emit(0); await settle()
				await click(observatory.overview_button)
				check(not observatory.inspection_enabled and observatory.selected_key == selected and observatory.camera.transform == overview_pose and observatory.camera.size == overview_size,"Overview restores the exact original camera without changing task selection")
				for index: int in observatory.marker_buttons.size():
					var marker_rect: Rect2 = observatory.marker_buttons[index].get_rect()
					var apparatus_transform: Transform3D = observatory.apparatus_nodes[index].transform
					# Subpixel Control round-off must not move any occupied pixel.
					var restored: bool = marker_rect.is_equal_approx(overview_markers[index]) and pixel_bounds(marker_rect) == pixel_bounds(overview_markers[index]) and apparatus_transform == overview_geometry[index]
					if not restored:
						var marker: Button = observatory.marker_buttons[index]
						print("APPARATUS_RESTORE_DIFF: ",JSON.stringify({"locale":language,"window":[dimensions.x,dimensions.y],"kind":kind,
							"index":index,"task":observatory.region_rows[index].key,"selected":selected,"view":observatory.view_choice.selected,
							"rect_equal":marker_rect == overview_markers[index],"transform_equal":apparatus_transform == overview_geometry[index],
							"rect_before":rect_fields(overview_markers[index]),"rect_after":rect_fields(marker_rect),
							"transform_before":transform_fields(overview_geometry[index]),"transform_after":transform_fields(apparatus_transform),
							"camera_before":transform_fields(overview_pose),"camera_after":transform_fields(observatory.camera.transform),
							"camera_size_before":overview_size,"camera_size_after":observatory.camera.size,
							"root_size":[root.size.x,root.size.y],"stage_rect":rect_fields(observatory.stage.get_global_rect()),
							"subviewport_size":[observatory.viewport_3d.size.x,observatory.viewport_3d.size.y],
							"marker_text":marker.text,"marker_pressed":marker.button_pressed,"marker_hovered":marker.is_hovered(),
							"marker_visible":marker.visible,"marker_disabled":marker.disabled,
							"minimum_size":[marker.get_minimum_size().x,marker.get_minimum_size().y],
							"combined_minimum_size":[marker.get_combined_minimum_size().x,marker.get_combined_minimum_size().y],
							"font_size":marker.get_theme_font_size("font_size")}))
					check(restored,"Restored overview retains original geometry and projected marker rectangles")
				check(protected_state() == before,"Read-only region/view/near/overview preserve every actual saved work, game, lease and navigation byte")
		await state_cases(observatory)
		check(protected_state() == before,"Synthetic invalid/temporary/tester fixtures and invalid entry never mutate authoritative saves")
		observatory.refresh(nav.journey_tasks()); await settle()
		var located: Array[String] = []
		observatory.tree_requested.connect(func(task_key: String) -> void: located.append(task_key))
		var located_key: String = observatory.selected_key
		observatory._locate(); await settle()
		check(located == [located_key] and not is_instance_valid(observatory) and not is_instance_valid(host),"Locate emits the exact task and releases the previous Home and observatory")
		var map_ready: bool = is_instance_valid(current_scene) and current_scene.scene_file_path == nav.MAP_SCENE
		check(map_ready,"Actual Home Locate opens the original efficient task tree")
		if not map_ready: quit(1); return
		var located_map: Control = current_scene
		check(located_map.selected.get("key","") == located_key and nav.selected == located_key,"The real map and navigation select the exact requested task")
		check(nav.pending == before.nav.pending and nav.from_tree == before.nav.from_tree,"Locate leaves pending task and original return flag unchanged")
		check(nav.camera == located_map.canvas.pan and nav.zoom == located_map.canvas.magnification and nav.camera_saved and nav.camera_view_size == located_map.canvas.size,"Locate camera, zoom, saved flag and view size exactly match the original map canvas")
		var located_state: Dictionary = protected_state()
		var located_authority: Dictionary = located_state.duplicate(true); located_authority.erase("nav")
		check(located_authority == initial_authority,"Legitimate tree navigation preserves every initial game, work, best record, lease and recovery byte")
		# The original map Escape returns Home and clears only its return flag.
		var home_navigation: Dictionary = located_state.nav.duplicate(true); home_navigation.from_tree = false
		await key(KEY_ESCAPE)
		var home_ready: bool = is_instance_valid(current_scene) and current_scene.scene_file_path == "res://src/ui/prototype_hub.tscn"
		check(home_ready and not is_instance_valid(located_map),"Original map Escape releases the map and returns to a fresh Home")
		if not home_ready: quit(1); return
		var home_state: Dictionary = protected_state()
		var home_authority: Dictionary = home_state.duplicate(true); home_authority.erase("nav")
		check(home_authority == initial_authority and home_state.nav == home_navigation,"Map to Home changes only the documented navigation return flag, never saved authorities")
		before = home_state
		host = current_scene; launcher = host.find_child("OpenJourneyObservatory",true,false)
		check(launcher != null,"Returning Home resolves its actual observatory launcher again")
		if launcher == null: quit(1); return
		launcher.grab_focus(); launcher.pressed.emit(); await settle()
		observatory = host.journey_observatory
		check(is_instance_valid(observatory) and observatory.visible,"Returning Home opens a fresh lazy observatory before feedback checks")
		if not is_instance_valid(observatory): quit(1); return
		if capture_enabled and DisplayServer.get_name() != "headless":
			await feedback_route(observatory,launcher,false)
			await feedback_route(observatory,launcher,true)
		else: print("NOT_RUN: actual renderer ordinary/tester F8 and exact focus stack")
		ProjectSettings.set_setting("playtest/offline_tester",false); feedback.toolbar.visible = false
		observatory.close(); await settle()
		check(root.gui_get_focus_owner() == launcher,"Close returns focus to the original host")
		observatory.queue_free(); await settle()
	check(protected_state() == before,"All apparatus tests preserve original authorities including real C/P/G payload and empty lock directories")
	var final_authority: Dictionary = protected_state(); final_authority.erase("nav")
	check(final_authority == initial_authority,"Every initial saved authority remains exact across both localized Home and map lifecycles")
	launcher.grab_focus(); launcher.pressed.emit(); await settle()
	var final_view: Control = host.journey_observatory
	final_view.select_task("hardware_foundations/tutorial"); final_view._enter(); await settle()
	check(is_instance_valid(current_scene) and current_scene.scene_file_path == "res://src/hardware_foundations/hardware_foundations.tscn" and current_scene.current_level_id == &"tutorial" and not is_instance_valid(host),"Authorized Enter still opens the original task host, not a second world/progression system")
	ProjectSettings.set_setting("candidate/creation_enabled",old_creation); ProjectSettings.set_setting("playtest/offline_tester",old_tester)
	ProjectSettings.set_setting("game/reduced_motion",old_motion); feedback.toolbar.visible = toolbar_visible; locale.set_locale(old_locale)
	if capture_enabled:
		var path: String = "res://.godot/observatory-apparatus-captures/receipt.json"
		check(not FileAccess.file_exists(path),"Do not overwrite an earlier apparatus receipt")
		var output: FileAccess = null
		if not FileAccess.file_exists(path): output = FileAccess.open(path,FileAccess.WRITE)
		check(output != null,"Actual renderer receipt is writable")
		if output != null:
			output.store_string(JSON.stringify({"source_commit":ProjectSettings.get_setting("application/config/build_commit","unconfigured source fixture"),
				"ui_sha256":FileAccess.get_sha256("res://src/ui/journey_observatory.gd"),"test_sha256":FileAccess.get_sha256("res://tests/test_observatory_apparatus.gd"),
				"evidence_grade":"Actual rendered3D textures and controller/pointer input; not OS or newcomer acceptance", "checks":checks,"failures":failures,"captures":captures},"\t")); output.close()
	if failures.is_empty(): print("PASS: observatory apparatus ",checks," checks")
	else: print("FAIL: observatory apparatus ",failures.size(),"/",checks)
	quit(0 if failures.is_empty() else 1)
