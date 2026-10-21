extends SceneTree
## Actual rendering receipt; explicitly refuses the dummy headless display.
## Run in an isolated QA project, never with the player's normal save directory.
var destination: String = "res://.godot/immersive-captures"

func _init() -> void:
	call_deferred("capture")

func settle(seconds: float = 0.3) -> void:
	await create_timer(seconds).timeout
	await RenderingServer.frame_post_draw

func snap(name: String) -> void:
	await settle()
	var image: Image = root.get_texture().get_image()
	assert(image != null and not image.is_empty())
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
	DirAccess.make_dir_recursive_absolute(destination)
	root.size = Vector2i(1600,900)
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await settle(1.0)
	var lab: Control = hub.get_node("Laboratory")
	lab.set_process(false)
	lab.room.set_look(Vector2.ZERO)
	lab.room.set_zoom(0.0)
	await snap("01-arrival")
	lab.room.set_look(Vector2(-1,0)); await settle(0.7)
	await snap("02-left")
	lab.room.set_look(Vector2(1,0)); await settle(0.7)
	await snap("03-right")
	lab.room.set_look(Vector2.ZERO)
	lab.set_process(true)
	lab._on_room_action("terminal")
	await settle(1.0)
	await snap("04-terminal")
	for id: String in ["archive","handbook","settings","works","achievements"]:
		lab._on_room_action(id)
		await snap("panel-" + id)
		match id:
			"archive": lab.archive.close()
			"handbook": hub.terminology_handbook.close_handbook()
			"settings": hub._close_options_menu()
			"works": hub.journey_journal.close()
			"achievements": hub._close_hub_navigation()
		await settle()
	print("PASS: actual-render capture sequence; not human input or performance acceptance")
	quit()
