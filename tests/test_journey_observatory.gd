extends SceneTree
## Controller/geometry checks; completion fixtures are never player achievements.
var Observatory: Script
const SecondAct = preload("res://src/campaign/second_act_tasks.gd")
const Creation = preload("res://src/campaign/creation_tasks.gd")
var checks: int = 0
var failures: int = 0
var capture_enabled: bool = false
var capture_size := Vector2i(1280,720)
var captures: Array[Dictionary] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func key_press(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	# F8 uses the existing Input action poll, rather than viewport-only dispatch.
	if code == KEY_F8: Input.parse_input_event(event)
	else: root.push_input(event,true)
	await settle()
	event = InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = false
	if code == KEY_F8: Input.parse_input_event(event)
	else: root.push_input(event,true)
	await settle()
func check_host_route(host: Control, tester: bool) -> void:
	var route: String = host.scene_file_path+" "+root.get_node("Localization").current_locale()+" tester="+str(tester)
	var launcher: Button = host.find_child("OpenJourneyObservatory",true,false)
	launcher.grab_focus(); launcher.pressed.emit(); await settle()
	var observatory: Control = host.journey_observatory
	check(observatory != null and observatory.visible,"Actual Home/map launcher opens observatory")
	if observatory == null: return
	if tester and capture_enabled and DisplayServer.get_name() != "headless":
		await key_press(KEY_F8)
		check(root.get_node("OfflineFeedback").backdrop.visible and observatory.visible,"Actual F8 overlays the host's open observatory")
		await key_press(KEY_ESCAPE)
		var offline: Node = root.get_node("OfflineFeedback")
		check(not offline.backdrop.visible and observatory.visible,"First viewport Esc closes feedback, retaining observatory: "+route+" feedback="+str(offline.backdrop.visible)+" observatory="+str(observatory.visible)+" busy="+str(offline.busy)+" paused="+str(paused)+" status="+offline.status.text)
	await key_press(KEY_ESCAPE)
	check(not observatory.visible and root.gui_get_focus_owner() == launcher,"Viewport Esc returns to original Home/map launcher: "+route+" observatory="+str(observatory.visible))
	launcher.pressed.emit(); await settle()
	check(host.journey_observatory == observatory and observatory.visible,"Host reuses one observatory instance")
	observatory.close(); await settle()
func digest(data: PackedByteArray) -> String:
	var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(data); return hash.finish().hex_encode()
func disk_snapshot() -> Dictionary:
	var save: Node = root.get_node("GlobalSave")
	var paths: Array[String] = [save.storage_path,save.workbench_storage_path]
	for path: Variant in SecondAct.paths().values(): paths.append(str(path))
	paths.append(Creation.Session.launch_path([]))
	var result: Dictionary = {}
	for path: String in paths:
		result[path] = digest(FileAccess.get_file_as_bytes(path)) if FileAccess.file_exists(path) else "absent"
	return result
func save_snapshot() -> Dictionary:
	var data: Dictionary = root.get_node("GlobalSave")._save_snapshot(); data.erase("saved_at_utc"); return data
func capture(observatory: Control, name: String, scope: String) -> void:
	if not capture_enabled: return
	check(DisplayServer.get_name() != "headless","3D capture requires actual renderer")
	if DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var world: Image = observatory.viewport_3d.get_texture().get_image()
	check(not world.is_empty(),"Actual3D viewport texture is available")
	if world.is_empty(): return
	var colors: Dictionary = {}
	for y: int in range(0,world.get_height(),16):
		for x: int in range(0,world.get_width(),16): colors[world.get_pixel(x,y).to_html()] = true
	check(colors.size() > 5,"3D geometry produces a non-flat rendered texture")
	var folder: String = "res://.godot/observatory-captures"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"Capture directory exists")
	var frame: Image = root.get_texture().get_image()
	check(frame.get_size() == capture_size,"Actual observatory output dimensions")
	var frame_path: String = folder.path_join(name+".png")
	var world_path: String = folder.path_join(name+"-3d.png")
	check(frame.save_png(frame_path) == OK and world.save_png(world_path) == OK,"Frame and real3D texture saved")
	captures.append({"frame":frame_path,"frame_sha256":FileAccess.get_sha256(frame_path),"world":world_path,"world_sha256":FileAccess.get_sha256(world_path),"world_dimensions":[world.get_width(),world.get_height()],"scope":scope,"selected":observatory.selected_key,"view":observatory.view_choice.selected})
func run() -> void:
	Observatory = load("res://src/ui/journey_observatory.gd")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	capture_enabled = "--observatory-capture" in args
	for argument: String in args:
		if argument.begins_with("--capture-size="):
			var parts: PackedStringArray = argument.trim_prefix("--capture-size=").split("x")
			if parts.size() == 2: capture_size = Vector2i(int(parts[0]),int(parts[1]))
	check(capture_size.x >= 1280 and capture_size.y >= 720,"Supported capture size")
	if capture_enabled and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(capture_size); root.size = capture_size
	root.content_scale_size = capture_size; root.size = capture_size
	var nav: Node = root.get_node("TaskNavigation")
	var localization: Node = root.get_node("Localization")
	var initial_locale: String = localization.current_locale()
	var before_save: Dictionary = save_snapshot()
	var before_disk: Dictionary = disk_snapshot()
	var before_navigation := {"pending":nav.pending,"selected":nav.selected,"from_tree":nav.from_tree,"camera_saved":nav.camera_saved}
	var fixture := {"key":"hardware_foundations/tutorial","id":"tutorial","domain":"hardware_foundations","region":0,"title":"Fixture NOT · 非玩家成果","body":"Same task identity; rendering fixture only.","unlocked":true,"completed":false,"dependencies":[]}
	check(not Observatory.earned(fixture),"Accessible entrance does not create a completion lamp")
	check(Observatory.state_text(fixture,true,true).contains("Tester"),"Tester access remains visibly distinct")
	for status: String in ["unavailable","readonly","invalid"]:
		var unconfirmed: Dictionary = fixture.duplicate(true); unconfirmed.completed = true; unconfirmed.evidence_status = status
		check(not Observatory.earned(unconfirmed),"Unconfirmed/readonly support never lights a lamp:"+status)
	var temporary: Dictionary = fixture.duplicate(true); temporary.completed = true; temporary.progress_source = "session"
	check(not Observatory.earned(temporary),"Temporary exploration cannot claim permanent completion")
	var accepted: Dictionary = fixture.duplicate(true); accepted.completed = true
	check(Observatory.earned(accepted),"Actual accepted completion remains a separate state")
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		var host := Control.new(); host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(host)
		var launcher := Button.new(); launcher.text = "Original host"; host.add_child(launcher); launcher.grab_focus()
		var observatory: Control = Observatory.new(); host.add_child(observatory); await settle()
		observatory.open(); await settle()
		var actual: Array[Dictionary] = nav.journey_tasks()
		check(observatory.rows == actual,"Observatory snapshots the actual loaded task catalog:"+locale)
		check(observatory.viewport_3d.own_world_3d and observatory.camera is Camera3D,"Real isolated3D world and camera exist")
		check(root.get_visible_rect().encloses(observatory.enter_button.get_global_rect()),"Original-workbench action fits viewport:"+locale)
		await capture(observatory,locale+"-actual","Actual loaded saved data; no completion fixture")
		for region: int in observatory.region_choice.item_count:
			observatory.region_choice.select(region); observatory.region_choice.item_selected.emit(region); await settle()
			check(observatory.marker_buttons.size() == observatory.region_rows.size(),"Every real region task has a native selectable3D marker")
			for index: int in observatory.region_rows.size():
				observatory.marker_buttons[index].pressed.emit()
				check(observatory.selected_key == observatory.region_rows[index].key,"Lamp selects its real task identity")
				check(observatory.enter_button.disabled == not bool(observatory.region_rows[index].unlocked),"Access uses real eligibility, separately from lamps")
		for view: int in 3:
			observatory.view_choice.select(view); observatory.view_choice.item_selected.emit(view); await settle()
			check(observatory.camera.projection == Camera3D.PROJECTION_ORTHOGONAL,"Fixed view retains real3D projection")
			for marker: Button in observatory.marker_buttons:
				check(observatory.stage.get_global_rect().encloses(marker.get_global_rect()),"Native3D marker remains inside its visible stage")
			await capture(observatory,locale+"-actual-view"+str(view),"Actual loaded region; emitted fixed-view selection, not OS input")
		var fixtures: Array[Dictionary] = [fixture]
		observatory.refresh(fixtures); await settle()
		check(observatory.geometry.find_children("*","OmniLight3D",true,false).is_empty(),"Uncompleted fixture has no achievement light")
		await capture(observatory,locale+"-fixture-unearned","Controller fixture: not player progress; no accepted support")
		fixtures = [accepted]; observatory.refresh(fixtures); await settle()
		check(observatory.geometry.find_children("*","OmniLight3D",true,false).size() == 1,"Same fixture with accepted record changes the real3D light")
		await capture(observatory,locale+"-fixture-earned","Controller fixture only: same real task; accepted state is not earned by this test")
		observatory.selected_key = "unknown/missing"; observatory._enter()
		check(nav.pending == before_navigation.pending and nav.selected == before_navigation.selected,"Unknown entry cannot mutate navigation")
		observatory.close(); await settle()
		check(root.gui_get_focus_owner() == launcher,"Close restores original host focus")
		root.get_node("PlaytestData").set_feedback_visible(true,&"observatory-test")
		observatory.open(); check(not observatory.visible,"Feedback prevents opening/focus stealing")
		root.get_node("PlaytestData").set_feedback_visible(false,&"observatory-test")
		observatory.open()
		root.get_node("PlaytestData").set_feedback_visible(true,&"observatory-test")
		var escape := InputEventKey.new(); escape.keycode = KEY_ESCAPE; escape.pressed = true
		observatory._unhandled_key_input(escape); check(observatory.visible,"Esc belongs to topmost feedback first")
		root.get_node("PlaytestData").set_feedback_visible(false,&"observatory-test")
		observatory._unhandled_key_input(escape); check(not observatory.visible,"Esc closes observatory after feedback")
		host.queue_free(); await settle()
	check(save_snapshot() == before_save,"Browsing does not change serialized campaign save")
	check(disk_snapshot() == before_disk,"Browsing preserves original campaign/candidate file bytes")
	check({"pending":nav.pending,"selected":nav.selected,"from_tree":nav.from_tree,"camera_saved":nav.camera_saved} == before_navigation,"Open/close/region/view selection does not change transient navigation")
	var old_version: Variant = ProjectSettings.get_setting("application/config/version")
	var old_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester")
	var feedback_toolbar: Control = root.get_node("OfflineFeedback").toolbar
	var old_toolbar_visible: bool = feedback_toolbar.visible
	ProjectSettings.set_setting("application/config/version","playtest-NightFullJourneyExperience20261018-cf89a7612345")
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		for tester: bool in [false,true]:
			ProjectSettings.set_setting("playtest/offline_tester",tester); feedback_toolbar.visible = tester
			var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate(); root.add_child(hub); await settle()
			for control_name: String in ["HubBrowseJourney","OpenJourneyObservatory","OpenJourneyJournal","BuildIdentifier"]:
				var control: Control = hub.find_child(control_name,true,false)
				check(control != null and root.get_visible_rect().encloses(control.get_global_rect()),"Home action/identity fits:"+locale+str(tester)+control_name)
			var identity: Control = hub.find_child("BuildIdentifier",true,false)
			check(not tester or not identity.get_global_rect().intersects(feedback_toolbar.get_global_rect()),"Long build identity clears persistent F8 toolbar")
			await check_host_route(hub,tester)
			hub.queue_free(); await settle()
			var map: Control = load("res://src/campaign/task_tree.tscn").instantiate(); root.add_child(map); await settle()
			for control_name: String in ["OpenJourneyObservatory","OpenJourneyJournal","JourneyRegionChoice"]:
				var control: Control = map.find_child(control_name,true,false)
				check(control != null and root.get_visible_rect().encloses(control.get_global_rect()),"Map navigation fits:"+locale+str(tester)+control_name)
			await check_host_route(map,tester)
			map.queue_free(); await settle()
	ProjectSettings.set_setting("application/config/version",old_version)
	ProjectSettings.set_setting("playtest/offline_tester",old_tester); feedback_toolbar.visible = old_toolbar_visible
	localization.set_locale(initial_locale)
	if capture_enabled:
		var output := FileAccess.open("res://.godot/observatory-captures/receipt.json",FileAccess.WRITE)
		check(output != null,"Capture receipt available")
		if output != null:
			output.store_string(JSON.stringify({"test_source_sha256":FileAccess.get_sha256("res://tests/test_journey_observatory.gd"),"ui_source_sha256":FileAccess.get_sha256("res://src/ui/journey_observatory.gd"),"configured_build_commit":ProjectSettings.get_setting("application/config/build_commit","unconfigured source fixture"),"evidence_grade":"Rendered3D texture and emitted native-control actions, not OS/human acceptance","captures":captures},"\t")); output.close()
	if failures == 0: print("PASS: journey observatory ",checks," checks")
	else: print("FAIL: journey observatory ",failures,"/",checks)
	quit(0 if failures == 0 else 1)
