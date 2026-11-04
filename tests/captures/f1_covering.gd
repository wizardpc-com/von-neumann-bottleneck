extends SceneTree
var directory := "res://.godot/f1/audit"
func _init() -> void: call_deferred("run")
func settle() -> void:
	for i: int in 12: await process_frame
func shot(label: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory+"/"+label+".png")
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.pressed = true
	root.push_input(event)
	await settle()
func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(directory)
	var nav := root.get_node("TaskNavigation")
	root.get_node("GameMode").set_mode(&"test")
	var routes := ["hardware_foundations/half_adder","chapter_1/assembly","chapter_2/distant_reads","chapter_3/arrival","chapter_4/fields","representation/mixed_scan","service/move_state","prediction/regular","creation/C1_restore"]
	for index: int in routes.size():
		if not nav.enter(routes[index]): push_error("Route failed: "+routes[index]); quit(1); return
		await settle()
		var host: Node = current_scene
		await shot(str(index)+"-entry")
		if host.has_method("_run_official"):
			host.call("_run_official")
			if index == 0:
				while host.official_sequence_active:
					if host.playback_running: host._finish_playback()
					await process_frame
		elif host.has_method("_run_all"): host.call("_run_all")
		elif host.has_method("_run_simulation"): host.call("_run_simulation","Official Test Set")
		elif host.has_method("run_current"): host.call("run_current")
		elif index == 8: host.call("transport","raw")
		await shot(str(index)+"-run")
		if index == 0:
			host._enter_hint_workbench(); await shot(str(index)+"-hint"); host._exit_hint_workbench()
		elif index == 3:
			host._request_hint(); await shot(str(index)+"-hint"); await key(KEY_ESCAPE)
		elif index == 4:
			host._hint_request(); await shot(str(index)+"-hint"); await key(KEY_ESCAPE)
		else: print("HINT_NA_OR_UNVERIFIED ",routes[index])
		await key(KEY_F10)
		await shot(str(index)+"-settings")
		await key(KEY_ESCAPE)
		print("CAPTURED ",routes[index])
	print("PASS: covering capture routes completed; captures do not assert geometry or earn missing targets")
	quit()
