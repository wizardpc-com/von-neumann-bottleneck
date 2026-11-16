extends SceneTree
## Raw-pixel review of the default room and terminal; no synthetic player works.
var failures: int = 0
var checks: int = 0
const Brand = preload("res://src/ui/brand_identity.gd")

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for frame: int in 12: await process_frame
func capture(label: String, dimensions: Vector2i) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var pixels: Image = root.get_texture().get_image()
	check(pixels.get_size() == dimensions, "Actual capture dimensions: " + label)
	DirAccess.make_dir_recursive_absolute("res://.godot/final-product-previews")
	check(pixels.save_png("res://.godot/final-product-previews/"+label+".png") == OK, "Save raw pixels: " + label)
func run() -> void:
	check(OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"), "Only isolated review data")
	if failures: quit(1); return
	ProjectSettings.set_setting("game/reduced_motion", true)
	ProjectSettings.set_setting("game/yi_text_speed", "instant")
	ProjectSettings.set_setting("game/edition", "game")
	check(Brand.symbol_texture() != null, "Configured symbol loads")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		check(Brand.wordmark_texture(locale) != null, "Bilingual configured wordmark loads")
		for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1280,800)]:
			var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
			root.add_child(hub)
			await settle()
			root.mode = Window.MODE_WINDOWED
			root.min_size = Vector2i.ZERO
			root.content_scale_size = dimensions
			root.size = dimensions
			await settle()
			var lab: Control = hub.laboratory
			check(lab.room != null, "Default uses integrated 3D laboratory")
			check(lab.room.find_child("StandbyBrandSymbol",true,false) != null, "Actual room glass displays replaceable brand")
			# Hub recreation intentionally remembers its last surface. Return through
			# the real route before calling this a room capture.
			lab.leave_terminal()
			await create_timer(0.6).timeout
			await settle()
			check(not lab.room_focus and not lab.terminal.is_visible_in_tree(), "Room capture shows the room, not the retained terminal")
			var tag: String = "%s-%dx%d" % [locale,dimensions.x,dimensions.y]
			await capture("room-"+tag, dimensions)
			lab.open_terminal()
			await create_timer(0.6).timeout
			await settle()
			var terminal: Control = lab.terminal
			check(not terminal.mode_picker.visible, "Game Edition menu is free of mode controls")
			for item: Control in [terminal.primary,terminal.secondary,terminal.brand_wordmark,terminal.edition_label]:
				check(item.is_visible_in_tree() and terminal.get_global_rect().encloses(item.get_global_rect()), "Terminal content visible: "+str(item.name)+tag)
			await capture("terminal-"+tag, dimensions)
			if dimensions == Vector2i(1280,720):
				lab.open_archive(); await settle()
				await capture("archive-"+tag, dimensions)
				lab.archive.close(); await settle()
				lab.works_requested.emit()
				await settle()
				await capture("works-"+tag, dimensions)
			hub.queue_free(); await settle()
	ProjectSettings.set_setting("game/edition", null)
	print(("PASS: " if failures == 0 else "FAIL: ")+"final product presentation %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
