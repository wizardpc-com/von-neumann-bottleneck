extends SceneTree
## Real map controls; browsing must not grant model supports or campaign progress.
var failures: int = 0
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame

func run() -> void:
	var nav: Node = root.get_node("TaskNavigation")
	var before: Array[Dictionary] = nav.tasks()
	var keys: Array[String] = []
	for key: String in ["candidate/journey_enabled","candidate/creation_enabled","playtest/offline_tester"]:
		ProjectSettings.set_setting(key,true)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1440,900)]:
			root.mode = Window.MODE_WINDOWED
			root.size = dimensions; root.content_scale_size = dimensions
			var scene: Control = load("res://src/campaign/task_tree.tscn").instantiate()
			root.add_child(scene); await settle()
			var creation_chips: Array[Node] = scene.creation_route.get_children().filter(func(node: Node) -> bool: return str(node.name).begins_with("CreationRegion"))
			check(scene.creation_route.visible and creation_chips.size() == 3 and scene.creation_route.get_child_count() == 11,"All regions, including the three creation regions, are immediately visible")
			check(scene.journey_scope.text.contains(str(scene.rows.size())),"Scope counts the actual loaded catalog")
			check(scene.journey_scope.text.contains("Completed") if locale == "en" else scene.journey_scope.text.contains("已完成"),"Scope reports earned completion separately from open entrances")
			var selected_before: String = nav.selected
			for child: Node in creation_chips:
				var button := child as Button
				check(root.get_visible_rect().encloses(button.get_global_rect()),"Region shortcut fits "+str(dimensions)+locale)
				button.pressed.emit(); await settle()
				check(scene.list_view.visible and not scene.detail_view.visible,"Shortcut opens the chapter task list")
				check(nav.selected == selected_before,"Browsing keeps the actual selected workbench")
				check(scene.list_scroll.size.y >= 120,"Chapter list retains usable height "+str(dimensions)+locale+" "+str(scene.list_scroll.size))
				check(root.get_visible_rect().encloses(scene.detail_panel.get_global_rect()),"Chapter panel fits viewport")
				for entry: Node in scene.list_rows.get_children():
					var key: String = str(entry.get_meta("task_key"))
					check(key.begins_with("creation/"),"Shortcut shows real creation tasks only")
					if key not in keys: keys.append(key)
				var first: Button = scene.list_rows.get_child(0)
				first.pressed.emit(); await settle()
				check(scene.selected.key == first.get_meta("task_key") and not scene.enter_button.disabled,"Real task can be selected for entry")
				check(root.get_visible_rect().encloses(scene.enter_button.get_global_rect()),"Enter action remains on screen")
				selected_before = nav.selected
			if "--route-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
				RenderingServer.force_draw(false); await process_frame
				DirAccess.make_dir_recursive_absolute("res://.godot/route-captures")
				check(root.get_texture().get_image().save_png("res://.godot/route-captures/%s-%dx%d.png" % [locale,dimensions.x,dimensions.y]) == OK,"Actual route frame saved")
			scene.queue_free(); await settle()
	check(keys.size() == 9,"All actual C/P/G tasks are discoverable without dragging")
	var after: Array[Dictionary] = nav.tasks()
	for index: int in before.size():
		check(before[index].completed == after[index].completed and before[index].dependencies == after[index].dependencies,"Browsing never changes earned progress or prerequisites")
	preload("res://src/lab/lab_features.gd").core_journey = true
	ProjectSettings.set_setting("candidate/creation_enabled",false)
	var ordinary: Control = load("res://src/campaign/task_tree.tscn").instantiate()
	root.add_child(ordinary); await settle()
	check(ordinary.creation_route.get_children().all(func(node: Node) -> bool: return not str(node.name).begins_with("CreationRegion")),"Disabled creation candidate has no dead shortcut")
	ordinary.queue_free(); await settle()
	print("PASS: " if failures == 0 else "FAIL: ","test_creation_route_access ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
