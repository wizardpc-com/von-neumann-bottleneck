extends SceneTree
## Real Hub integration and imported room geometry. Run only in the isolated verifier.
## Opens existing readers/settings/feedback without submitting, resetting, quitting,
## or entering a task. Scene-changing Start/Journey remain covered by navigation suites.
const LabHome = preload("res://src/lab/lab_home.gd")
const Room = preload("res://src/lab/lab_room_3d.gd")
signal navigation_noop
var checks: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle(frames: int = 8) -> void:
	for frame: int in frames:
		await process_frame

func check_blocked(lab: LabHome, label: String) -> void:
	lab._process_immersive_room(0.016)
	check(lab._room_blocked(), label + " blocks room actions")
	check(lab.terminal_pages.active(), label + " is hosted inside the terminal")
	check(not lab.room._interaction_enabled and lab.room_input_shield.visible, label + " shields 3D picking")
	lab.room.activated.emit("settings")
	if label != "Settings":
		check(not bool(lab.get_parent().get("options_overlay").visible), label + " does not leak into Settings")

func check_returned(lab: LabHome, label: String) -> void:
	# A page opened from a room object closes back to that object in the room.
	lab._process_immersive_room(0.016)
	check(not lab._room_blocked() and not lab.room_focus and not lab.terminal.visible, label + " returns to the room, not the terminal")
	check(lab.room._interaction_enabled and lab.room.visible, label + " returns to an interactive room")
	check(not lab.room_input_shield.visible and lab.is_visible_in_tree(), label + " returns to the laboratory")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var prior_reduced: bool = bool(ProjectSettings.get_setting("game/reduced_motion", false))
	var prior_offline: bool = bool(ProjectSettings.get_setting("playtest/offline_tester", false))
	ProjectSettings.set_setting("game/reduced_motion", true)
	# Ordinary feedback at an empty home context opens without recording an incident.
	ProjectSettings.set_setting("playtest/offline_tester", false)
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await settle(16)
	var lab := hub.get_node_or_null("Laboratory") as LabHome
	check(lab != null, "The real Hub owns Laboratory")
	if lab == null:
		finish(hub, prior_reduced, prior_offline)
		return
	var room: Room = lab.room
	check(room != null and room.is_visible_in_tree(), "The laboratory contains the real 3D room")
	if room == null:
		finish(hub, prior_reduced, prior_offline)
		return
	check(lab.get_node_or_null("RoomShortcuts") == null, "No screen-space toolbar is built")
	check(lab.terminal_pages.viewport.gui_embed_subwindows, "Terminal contains embedded option menus and confirmations")
	check(ResourceLoader.exists(Room.MODEL_PATH), "The checked-in laboratory GLB is loadable")
	check(room.model != null and room.model.scene_file_path == Room.MODEL_PATH, "The room instantiates the production GLB")
	check(room.viewport != null and room.viewport.own_world_3d, "The room owns an isolated World3D")
	check(room.camera != null and room.camera.current, "A fixed observation camera is active")
	check(lab.get_node_or_null("LabWorld/LayerDesk/LabTerminal") == lab.terminal, "The existing terminal path and controller are retained")
	check(not (hub.get_node("HubSurface") as Control).visible, "The classic homepage stays hidden")
	if room.model == null or room.camera == null:
		finish(hub, prior_reduced, prior_offline)
		return

	var semantic_counts: Dictionary = {}
	for collider: CollisionObject3D in room._colliders:
		var id: String = str(collider.get_meta("region", ""))
		if not id.is_empty(): semantic_counts[id] = int(semantic_counts.get(id, 0)) + 1
	for id: String in ["terminal", "archive", "journey", "works", "achievements", "handbook", "settings", "feedback", "globe"]:
		check(int(semantic_counts.get(id, 0)) > 0, "Imported mesh colliders include semantic region " + id)
	check(semantic_counts.size() == 9, "The room has exactly nine semantic collider identities")

	ProjectSettings.set_setting("game/reduced_motion", false)
	lab._process_immersive_room(1.0)
	room._process(1.0)
	check(not lab.room_pointer_seen and room._look_current.is_equal_approx(Vector2.ZERO), "Without a real pointer motion, ordinary arrival stays neutral instead of looking at OS position zero")
	room.set_look(Vector2(1.0, -1.0))
	room._process(1.0)
	var forward: Vector3 = -room.camera.basis.z
	check(forward.dot(room._neutral_basis.x) > 0.0, "Moving the pointer right turns the camera right")
	check(forward.dot(room._neutral_basis.y) > 0.0, "Moving the pointer up turns the camera up")
	room.set_look(Vector2.ZERO)
	room._process(10.0)
	ProjectSettings.set_setting("game/reduced_motion", true)

	# Semantic activation intentionally tests the genuine room-to-Hub signal route;
	# geometric picking is verified separately below, not claimed for each object.
	room.activated.emit("terminal")
	await settle(3)
	check(lab.room_focus and not lab.terminal.asleep(), "Terminal activation wakes the existing menu")
	room.activated.emit("look")
	await settle(3)
	check(not lab.room_focus, "Look around exits terminal focus without leaving the room")

	room.activated.emit("archive")
	await settle(3)
	check(lab.archive.visible and lab.archive.get_node_or_null("ArchivePaper") != null, "Archive opens its terminal reader")
	check_blocked(lab, "Archive")
	lab.archive.close()
	await settle(3)
	check_returned(lab, "Archive")

	room.activated.emit("handbook")
	await settle(3)
	check(hub.terminology_handbook.is_open(), "Handbook opens the existing rules reader")
	check_blocked(lab, "Handbook")
	hub.terminology_handbook.close_handbook()
	await settle(3)
	check_returned(lab, "Handbook")

	room.activated.emit("settings")
	await settle(3)
	check(hub.options_overlay.visible, "Settings opens the existing Hub overlay")
	check_blocked(lab, "Settings")
	room.activated.emit("archive")
	check(not lab.archive.visible, "Settings blocks archive activation")
	hub.call("_close_options_menu")
	await settle(3)
	check_returned(lab, "Settings")

	room.activated.emit("works")
	await settle(3)
	check(is_instance_valid(hub.journey_journal) and hub.journey_journal.visible, "Works opens the existing saved-work journal")
	check_blocked(lab, "Works")
	if is_instance_valid(hub.journey_journal): hub.journey_journal.close()
	await settle(3)
	check_returned(lab, "Works")

	room.activated.emit("achievements")
	await settle(3)
	check(hub.navigation_overlay.visible, "Achievements opens the existing achievements/save page")
	check_blocked(lab, "Achievements")
	hub.call("_close_hub_navigation")
	await settle(3)
	check_returned(lab, "Achievements")
	check(not (hub.get_node("HubSurface") as Control).visible, "Closing achievements does not reveal the classic homepage")
	var settings_launcher := lab.terminal.find_child("TerminalSettings",true,false) as Button
	lab._on_room_action("terminal")
	await settle(3)
	for cycle in range(3):
		settings_launcher.grab_focus()
		settings_launcher.pressed.emit()
		await settle(3)
		hub.find_child("HubManageProgress", true, false).pressed.emit()
		await settle(3)
		hub.call("_close_hub_navigation")
		await settle(3)
		check(lab.terminal.primary.has_focus(), "Management returns to the terminal primary action, cycle %d" % cycle)

	var moments: Node = root.get_node("PlaytestMoments")
	room.activated.emit("feedback")
	await settle(3)
	check(bool(moments.get("panel").visible), "Feedback letter opens the existing voluntary feedback panel")
	check_blocked(lab, "Feedback")
	# No opinion, rating, save, send or export is invoked. Empty home context means
	# the ordinary close guard has no task draft to write.
	check(str(moments.get("target").get("level_id", "")).is_empty(), "Home feedback has no task-specific draft target")
	moments.call("close")
	await settle(3)
	check_returned(lab, "Feedback")

	await check_global_settings(lab)
	await check_interaction_details(lab)

	# Freeze only presentation input so deterministic camera/ray assertions cannot
	# depend on the host machine's pointer position or an ongoing focus tween.
	lab.set_process(false)
	room.set_process(false)
	room.set_zoom(0.0)
	room.set_look(Vector2(1.0, 1.0))
	room._process(1.0)
	check(room._look_current == Vector2.ZERO and room.camera.basis.is_equal_approx(room._neutral_basis), "Reduced motion keeps the observation camera neutral")
	var player: AnimationPlayer = room._globe_player
	check(player != null and player.has_animation("runtime/earth_24s"), "The globe uses its explicit runtime animation")
	if player != null and player.has_animation("runtime/earth_24s"):
		var animation: Animation = player.get_animation("runtime/earth_24s")
		check(is_equal_approx(animation.length, 24.0) and animation.loop_mode == Animation.LOOP_LINEAR, "The globe makes a continuous 24-second revolution")
		check(is_zero_approx(player.speed_scale), "Reduced motion pauses globe rotation")
		var globe := room.model.find_child("Status globe | opal sphere", true, false) as Node3D
		check(globe != null, "The animated globe exists in the imported model")
		if globe != null:
			var center: Vector3 = globe.global_position
			for second: float in [0.0, 6.0, 12.0, 18.0, 23.999]:
				player.seek(second, true)
				check(globe.global_position.is_equal_approx(center), "Globe center does not drift at %.3f seconds" % second)
		ProjectSettings.set_setting("game/reduced_motion", false)
		room._process(0.0)
		check(is_equal_approx(player.speed_scale, 1.0), "Normal motion resumes globe rotation")
		ProjectSettings.set_setting("game/reduced_motion", true)
		room._process(0.0)
	room.set_interaction_enabled(true)
	await physics_frame
	await physics_frame
	print("LAYOUT room=", room.size, " viewport=", room.viewport.size, " glass=", room.screen_rect(), " terminal=", lab.terminal.get_global_rect())
	check(room.size.is_equal_approx(Vector2(1280, 720)), "Geometry checks use the exact 1280 by 720 room")
	for pixel: Vector2 in [Vector2(1218, 234), Vector2(63, 243)]:
		check(room._pick(pixel).is_empty(), "Unrelated wall pixel %s cannot activate a semantic object" % pixel)
	room.set_interaction_enabled(false)
	check(room.activate_at(room.size * 0.5).is_empty(), "Disabled room refuses immediate API picks")
	check_display_state(lab)
	await check_terminal_layout(lab)
	await check_room_aspects(room)
	finish(hub, prior_reduced, prior_offline)

func finish(hub: Control, prior_reduced: bool, prior_offline: bool) -> void:
	ProjectSettings.set_setting("game/reduced_motion", prior_reduced)
	ProjectSettings.set_setting("playtest/offline_tester", prior_offline)
	if is_instance_valid(hub): hub.queue_free()
	print(("PASS: " if failures == 0 else "FAIL: ") + "immersive lab %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check_terminal_layout(lab: LabHome) -> void:
	var room: Room = lab.room
	var original_state: Dictionary = lab.terminal.state.duplicate(true)
	# Exercise both localized terminal compositions without persisting a locale
	# preference or reloading the real Hub underneath this integration test.
	ProjectSettings.set_setting("game/reduced_motion", true)
	lab.room_focus = true
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1280, 800), Vector2i(1440, 1080), Vector2i(1920, 900)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle(8)
		for use_english: bool in [false, true]:
			var state: Dictionary = original_state.duplicate(true)
			state["english"] = use_english
			state["new_player"] = true
			state["response"] = {}
			lab.terminal.configure(state)
			lab.terminal.wake(true)
			lab.terminal.message.complete_now()
			lab._process_immersive_room(1.0)
			room._process(1.0)
			lab._process_immersive_room(1.0)
			await settle(8)
			var bounds: Rect2 = lab.terminal.get_global_rect()
			var label: String = "%dx%d %s" % [dimensions.x, dimensions.y, "en" if use_english else "zh"]
			print("LAYOUT focused ", label, " glass=", room.screen_rect(), " terminal=", bounds)
			check(lab.terminal.is_visible_in_tree(), label + " aligned focused terminal is visible")
			var controls: Array[Control] = [lab.terminal.primary, lab.terminal.secondary, lab.terminal.language_button]
			for child: Node in lab.terminal.secondary.get_children():
				if child is Control: controls.append(child as Control)
			for control: Control in controls:
				var rect: Rect2 = control.get_global_rect()
				print("LAYOUT control ", label, " ", control.name, "=", rect)
				check(control.is_visible_in_tree(), label + " exposes " + str(control.name))
				check(bounds.grow(1.0).encloses(rect), label + " keeps " + str(control.name) + " within the terminal clip (1 px tolerance)")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	lab.terminal.configure(original_state)
	await settle(8)
	# Directly step presentation updates: no real-time duration, host cursor or
	# scene-changing _enter call participates in this alignment assertion.
	ProjectSettings.set_setting("game/reduced_motion", false)
	lab.room_focus = false
	room.set_look(Vector2(0.75, 0.25))
	room._process(1.0)
	lab._process_immersive_room(0.0)
	check(room._look_current.length() > 0.25 and not lab.terminal.visible, "Sideways observation hides the flat terminal UI")
	lab.room_focus = true
	lab._process_immersive_room(0.0)
	check(lab.terminal.visible and not room.visible, "Opening the terminal reveals the full-screen menu independently of camera angle")
	check(room._look_target.is_equal_approx(Vector2.ZERO), "Terminal focus requests neutral camera alignment")
	for step: int in range(90):
		lab._process_immersive_room(1.0 / 60.0)
		room._process(1.0 / 60.0)
	lab._process_immersive_room(0.0)
	check(room._look_current.length() < 0.25 and lab.terminal.visible, "Focus reveals the menu once the camera has returned to center")
	await settle(3)
	check(lab.terminal.primary.has_focus(), "Returning front-on restores keyboard focus to the primary action")
	ProjectSettings.set_setting("game/reduced_motion", true)
	lab.room_focus = false
	lab._process_immersive_room(1.0)
	room.set_zoom(0.0)
	room.set_look(Vector2.ZERO)
	room._process(1.0)
	lab._sync_room_terminal()


func check_room_aspects(room: Room) -> void:
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1440, 1080), Vector2i(1920, 900)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle(8)
		ProjectSettings.set_setting("game/reduced_motion", true)
		room.set_zoom(0.0)
		room._process(0.0)
		for id: String in ["archive", "journey"]:
			var bounds: Rect2 = room.region_screen_rect(id)
			print("ROOM_BOUNDS ", dimensions, " ", id, " ", bounds)
			check(bounds.has_area() and Rect2(Vector2.ZERO, room.size).grow(1.0).encloses(bounds), "%s keeps %s fully framed at rest" % [dimensions, id])
		await check_surface_reachability(room)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await settle(8)


func check_surface_reachability(room: Room) -> void:
	var expected: Array[String] = ["terminal", "archive", "journey", "works", "achievements", "handbook", "settings", "feedback", "globe"]
	var evidence: Dictionary = {}
	room.set_interaction_enabled(true)
	room.set_zoom(0.0)
	ProjectSettings.set_setting("game/reduced_motion", false)
	# Each hit uses production triangle geometry and both blocker/hotspot layers.
	# Never emit activation here: this must not open panels or enter another scene.
	for observation: Vector2 in [Vector2.ZERO, Vector2(-0.5, 0.0), Vector2(0.5, 0.0)]:
		room.set_look(observation)
		room._process(2.0)
		await physics_frame
		await physics_frame
		var counts: Dictionary = {}
		for y: int in range(6, int(room.size.y), 12):
			for x: int in range(6, int(room.size.x), 12):
				var pixel := Vector2(x, y)
				var id: String = room._pick(pixel)
				if id.is_empty(): continue
				counts[id] = int(counts.get(id, 0)) + 1
				if not evidence.has(id):
					evidence[id] = {"pixel": pixel, "look_degrees": room._look_current, "source": "12px grid"}
		print("RAY_GRID look_degrees=", room._look_current, " hits=", counts)
		# Narrow objects can fall between samples. A projected mesh center is only
		# a candidate pixel: it counts exclusively when a real occlusion-tested ray
		# returns the exact semantic region, never merely because it projects.
		for index: int in range(room._colliders.size()):
			var collider: CollisionObject3D = room._colliders[index]
			var id: String = str(collider.get_meta("region", ""))
			if id.is_empty() or evidence.has(id): continue
			var mesh: MeshInstance3D = room._collider_meshes[index]
			var center: Vector3 = mesh.global_transform * mesh.get_aabb().get_center()
			if room.camera.is_position_behind(center): continue
			var pixel: Vector2 = room.camera.unproject_position(center) * room.size / Vector2(room.viewport.size)
			if Rect2(Vector2.ZERO, room.size).has_point(pixel) and room._pick(pixel) == id:
				evidence[id] = {"pixel": pixel, "look_degrees": room._look_current, "source": str(mesh.name) + " center surface ray"}
		if evidence.size() == expected.size(): break
	for id: String in expected:
		print("RAY_REACH ", id, " ", evidence.get(id, "NO VERIFIED SURFACE HIT; toolbar alone is not geometric reachability"))
		check(evidence.has(id), "%s real visible triangle ray reaches %s at neutral or bounded side view" % [room.size, id])
	ProjectSettings.set_setting("game/reduced_motion", true)
	room.set_look(Vector2.ZERO)
	room._process(0.0)


func check_display_state(lab: LabHome) -> void:
	var room: Room = lab.room
	var real: Dictionary = room.display_state
	check(real.stations.size() == lab.station_progress.size(), "Room displays every real journey station")
	check(real.completed == lab.completed_keys.size() and real.total == LabHome.LabState.tasks().size(), "Room task totals come from the real navigation state")
	check(real.works_count == lab.works.size(), "Room saved-work count comes from the real local session")
	var rows: Array[Dictionary] = []
	for index: int in range(11):
		rows.append({"zh":"测试站%d" % index,"en":"Fixture %d" % index,"done":2 if index == 0 else 0,"total":2})
	var tasks: Array[Dictionary] = [
		{"key":"fixture/done","region":0,"unlocked":true,"completed":true},
		{"key":"fixture/open","region":1,"unlocked":true,"completed":false},
		{"key":"fixture/locked","region":2,"unlocked":false,"completed":false},
	]
	room.update_progress(rows,2,22,1,tasks,[{"name":"Explicit local QA work","output":[0,1,2,3]}],true)
	var fixture: Dictionary = room.display_state
	check(fixture.stations.size() == 11, "The station display is not limited to the imported decorative nine cells")
	check(fixture.stations[0].status == "completed", "A fully completed station is displayed as completed")
	check(fixture.stations[1].status == "available", "An unlocked unfinished station is displayed as available")
	check(fixture.stations[2].status == "locked", "A genuinely locked station is displayed as locked")
	check(fixture.stations[3].status == "unknown", "Absent task evidence is not invented as a locked station")
	check(fixture.latest_name == "Explicit local QA work" and fixture.latest_output == [0,1,2,3], "The works wall uses the supplied real output, not a decorative concept")
	fixture.stations[0].done = 999
	check(room.display_state.stations[0].done == 2, "Display state is returned as an isolated read-only copy")
	var long_name: String = "宽".repeat(48)
	room.update_progress(rows,2,22,9999,tasks,[{"name":long_name,"output":[0,1,2,3]}],true)
	var title: Label3D = room._works_title
	var name_label: Label3D = room._works_name
	var title_end: float = title.position.x + title.font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.font_size).x * title.pixel_size
	var name_start: float = name_label.position.x - name_label.font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_label.font_size).x * name_label.pixel_size
	check(title.text == "Works  9999" and name_label.text.ends_with("…"), "Long fullwidth work names are ellipsized beside an English title and large count")
	check(name_start - title_end >= 0.139, "Work title and measured name retain a physical gap")
	check(room.display_state.latest_name == long_name, "Ellipsizing the work wall preserves its full read-only source name")
	room.update_progress(rows,0,22,0,tasks,[],false)
	check(room.display_state.works_count == 0 and room.display_state.latest_name.is_empty() and room.display_state.latest_output.is_empty(), "An empty collection has explicit empty data and no sample work")
	room.update_progress(lab.station_progress,lab.completed_keys.size(),LabHome.LabState.tasks().size(),lab.works.size(),LabHome.LabState.tasks(),lab.works,lab.english)


func check_interaction_details(lab: LabHome) -> void:
	var room: Room = lab.room
	ProjectSettings.set_setting("game/reduced_motion", false)
	lab.room_focus = false
	room.set_look(Vector2(1.0,0.0))
	room._process(1.0)
	lab._process_immersive_room(0.0)
	check(not lab.terminal.visible, "Rotated look-around hides the flat terminal")
	lab.escape()
	await create_timer(0.8).timeout
	check(lab.terminal.confirming() and room.confirmation_active() and room.visible and not lab.terminal.visible, "ESC keeps confirmation on the physical screen in the visible room")
	check(room.standby_viewport.gui_get_focus_owner() == lab.terminal.quit_no, "Physical quit confirmation focuses No")
	lab.escape()
	await settle(3)
	check(not lab.terminal.confirming() and not lab.room_focus and not room.confirmation_active(), "Second ESC restores the original room")
	lab.open_terminal()
	await create_timer(0.9).timeout
	var opener: Button = lab.terminal.archive_button
	for cycle: int in 3:
		opener.grab_focus()
		opener.pressed.emit()
		await settle(3)
		lab._on_room_hover("archive")
		lab._process_immersive_room(0.0)
		check(lab.room_hover.text.is_empty(), "Modal clears underlying hover hint")
		check(lab.archive.visible, "Keyboard archive opens cycle %d" % cycle)
		var modal_focus: Control = lab.terminal_pages.viewport.gui_get_focus_owner()
		check(modal_focus != null and lab.archive.is_ancestor_of(modal_focus), "Fresh archive places initial keyboard focus inside its modal")
		lab.archive.close_button.grab_focus()
		await send_key(KEY_TAB)
		modal_focus = lab.terminal_pages.viewport.gui_get_focus_owner()
		check(modal_focus != null and lab.archive.is_ancestor_of(modal_focus), "Archive Tab cannot escape into the underlying terminal")
		lab.archive.close_button.grab_focus()
		check(lab.terminal_pages.viewport.gui_get_focus_owner() == lab.archive.close_button, "Archive accepts keyboard navigation inside its modal")
		lab.archive.close()
		await settle(3)
		check(root.gui_get_focus_owner() == opener, "Archive close restores its terminal launcher cycle %d" % cycle)
	ProjectSettings.set_setting("game/reduced_motion", true)
	lab._process_immersive_room(0.0)
	var departures: Array[int] = [0]
	var count_departure := func() -> void: departures[0] += 1
	navigation_noop.connect(count_departure)
	lab._enter(navigation_noop)
	lab._enter(navigation_noop)
	lab._on_room_action("settings")
	check(not lab.get_parent().options_overlay.visible, "Repeated input cannot open Settings during departure")
	await create_timer(0.75).timeout
	check(not lab.zooming and is_zero_approx(lab.passage.progress) and is_equal_approx(lab.terminal.modulate.a,1.0), "Reduced-motion failed navigation returns immediately without a return tween")
	check(departures[0] == 1, "Repeated departure emits the navigation route only once")
	navigation_noop.disconnect(count_departure)
	await create_timer(0.6).timeout
	# Global feedback shortcut may open independently while a route is pending.
	lab._enter(navigation_noop)
	var moments: Node = root.get_node("PlaytestMoments")
	moments.call("toggle")
	await settle(3)
	var feedback_focus: Control = lab.terminal_pages.viewport.gui_get_focus_owner()
	check(feedback_focus != null and moments.panel.is_ancestor_of(feedback_focus), "Feedback takes keyboard focus during a pending route")
	await create_timer(0.75).timeout
	check(not lab.zooming and lab.terminal_pages.viewport.gui_get_focus_owner() == feedback_focus, "Fallback does not steal focus from a globally opened feedback modal")
	moments.call("close")
	await settle(3)


func check_global_settings(lab: LabHome) -> void:
	var manager: Node = root.get_node("WindowMode")
	ProjectSettings.set_setting("game/reduced_motion", false)
	lab.room_focus = false
	lab.room.set_look(Vector2(1.0, 0.0))
	lab.room._process(1.0)
	lab._process_immersive_room(0.0)
	lab._on_room_action("terminal")
	while lab.zooming: await process_frame
	await send_key(KEY_F10)
	await settle(8)
	lab._process_immersive_room(0.016)
	check(not is_instance_valid(manager.settings_layer) and lab.get_parent().options_overlay.visible, "F10 opens terminal settings without an independent layer")
	check(lab._room_blocked() and not lab.room._interaction_enabled, "Global settings shields laboratory background interactions")
	lab.room.activated.emit("archive")
	check(not lab.archive.visible, "Global settings cannot leak through to Archive")
	if lab.archive.visible: lab.archive.close()
	var host: Node = lab.get_parent().options_overlay
	for step: int in 90:
		lab._process_immersive_room(1.0 / 60.0)
		lab.room._process(1.0 / 60.0)
	await settle(3)
	var owner: Control = lab.terminal_pages.viewport.gui_get_focus_owner()
	check(owner != null and host.is_ancestor_of(owner), "Recenter cannot steal keyboard focus from F10 settings")
	await send_key(KEY_ESCAPE)
	await settle(8)
	lab._process_immersive_room(0.016)
	check(not is_instance_valid(manager.settings_layer) and not lab._room_blocked(), "Closing global settings restores the laboratory")
	ProjectSettings.set_setting("game/reduced_motion", true)


func send_key(code: Key, shifted: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		event.shift_pressed = shifted
		root.push_input(event, true)
		await process_frame
	await settle(3)
