extends SceneTree
## Actual rendering receipt; explicitly refuses the dummy headless display.
## Run in an isolated QA project, never with the player's normal save directory.
var destination: String = "res://.godot/immersive-captures"
var measurements: Array[Dictionary] = []
var capture_size := Vector2i(1600, 900)

func measure(label: String, room: Node) -> void:
	var samples: Array[float] = []
	await settle(1.0)
	var previous: int = Time.get_ticks_usec()
	for frame in range(180):
		if label == "look-around": room.set_look(Vector2(sin(float(frame) * TAU / 180.0), 0.0))
		# Keep the same 60 FPS budget even if an evidence tool takes OS focus.
		Engine.max_fps = 60
		await RenderingServer.frame_post_draw
		var now: int = Time.get_ticks_usec()
		samples.append(float(now - previous) / 1000.0)
		previous = now
	samples.sort()
	var total: float = 0.0
	for value: float in samples: total += value
	measurements.append({"state": label, "frames": samples.size(),
		"mean_ms": total / samples.size(), "p50_ms": samples[90], "p95_ms": samples[171],
		"p99_ms": samples[178], "max_ms": samples[-1], "fps": 1000.0 * samples.size() / total,
		"room_rendering": room.visible,
		"draw_calls": room.viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME) if room.visible else 0,
		"primitives": room.viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME) if room.visible else 0})

func _init() -> void:
	call_deferred("capture")

func settle(seconds: float = 0.3) -> void:
	await create_timer(seconds).timeout
	await RenderingServer.frame_post_draw

func snap(name: String) -> void:
	await settle()
	var image: Image = root.get_texture().get_image()
	assert(image != null and not image.is_empty())
	assert(image.get_size() == capture_size)
	var error: Error = image.save_png(destination.path_join(name + ".png"))
	assert(error == OK)
	print("CAPTURE ", destination.path_join(name + ".png"))

func capture() -> void:
	if not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)):
		push_error("Use an isolated QA project with a custom user directory; player saves must not be used for capture.")
		quit(2)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Rendered acceptance requires a real display/rendering backend; no screenshots produced.")
		quit(2)
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="): destination = argument.trim_prefix("--evidence-dir=")
		if argument.begins_with("--capture-size="):
			var parts := argument.trim_prefix("--capture-size=").split("x")
			capture_size = Vector2i(int(parts[0]), int(parts[1]))
	DirAccess.make_dir_recursive_absolute(destination)
	root.size = capture_size
	root.content_scale_size = capture_size
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await settle(1.0)
	var lab: Control = hub.get_node("Laboratory")
	lab.set_process(false)
	lab.room.set_look(Vector2.ZERO)
	lab.room.set_zoom(0.0)
	await snap("01-arrival")
	await measure("arrival", lab.room)
	lab.terminal.hide()
	lab.room.set_look(Vector2(-1,0)); await settle(0.7)
	await snap("02-left")
	lab.room.set_look(Vector2(1,0)); await settle(0.7)
	await snap("03-right")
	await measure("look-around", lab.room)
	lab.room.set_look(Vector2.ZERO)
	lab.set_process(true)
	lab._on_room_action("terminal")
	await settle(1.0)
	await snap("04-terminal")
	await measure("terminal", lab.room)
	for id: String in ["archive","handbook","settings","works","achievements"]:
		lab._on_room_action(id)
		await settle(1.0)
		await snap("panel-" + id)
		match id:
			"archive": lab.archive.close()
			"handbook": hub.terminology_handbook.close_handbook()
			"settings": hub._close_options_menu()
			"works": hub.journey_journal.close()
			"achievements": hub._close_hub_navigation()
		await settle()
	hub._open_journey_journal()
	await settle()
	hub.journey_journal.reflection_button.pressed.emit()
	await snap("panel-review")
	root.get_node("PlaytestMoments").toggle()
	await snap("panel-feedback")
	root.get_node("PlaytestMoments").close()
	hub.journey_journal.reflection_dialog.hide()
	hub.journey_journal.close()
	var receipt := {"engine": Engine.get_version_info(), "adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "size": [capture_size.x, capture_size.y],
		"locale": root.get_node("Localization").current_locale(), "frame_limit": 60,
		"scope": "Rendered wall-frame samples after warmup; not GPU-only timing or native input", "measurements": measurements}
	var file := FileAccess.open(destination.path_join("performance.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "\t"))
	print("PASS: actual-render captures and bounded frame-time samples; native input is separate")
	quit()
