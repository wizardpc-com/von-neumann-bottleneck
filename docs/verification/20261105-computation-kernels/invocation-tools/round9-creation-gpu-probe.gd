extends "res://tests/test_creation_playable_loop.gd"
## Diagnostic only: observe the original press route without retries or signals.
func press(scene: Control, id: String) -> void:
	var action := control(scene, id) as Button
	var fired: Array[int] = [0]
	var gui_buttons: Array[String] = []
	if action != null:
		action.pressed.connect(func() -> void: fired[0] += 1)
		action.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				gui_buttons.append(str(event.pressed)+":"+str(event.position)))
		print("PROBE before ",id," rect=",action.get_global_rect(),
			" viewport=",root.get_visible_rect()," root=",root.size,
			" visible=",action.is_visible_in_tree()," disabled=",action.disabled)
	await super.press(scene, id)
	print("PROBE after ",id," pressed=",fired[0]," gui=",gui_buttons,
		" learned=",not scene.session.data.model.is_empty(),
		" comparisons=",scene.transport_comparisons.size())
	if fired[0] == 0:
		RenderingServer.force_draw(false)
		await process_frame
		var image: Image = root.get_texture().get_image()
		var path: String = "user://failed-click.png"
		if image != null:
			print("PROBE capture=",ProjectSettings.globalize_path(path),
				" save=",image.save_png(path)," size=",image.get_size())
		push_error("Original viewport click did not activate "+id)
		quit(1)
		await process_frame
