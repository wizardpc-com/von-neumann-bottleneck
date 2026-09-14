extends SceneTree
## Isolated imported project plus a COPY of earned synthetic QA saves only.
func _init() -> void: call_deferred("run")
func settle() -> void:
	for frame: int in range(18): await process_frame
func snap(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.godot/"+name+".png")==OK)
func run() -> void:
	assert(str(ProjectSettings.get_setting("application/config/custom_user_dir_name","")).begins_with("VonNeumannBottleneckChecks/"))
	assert(not root.get_node("GameMode").is_test_mode())
	assert(root.get_node("GlobalSave").load_game())
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1600,1000); root.content_scale_size=Vector2i(1600,1000)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		assert(root.get_node("TaskNavigation").enter("hardware_foundations/cpu"))
		await settle()
		var cpu: Control=current_scene
		# Script mode disables automatic workbench loading. Explicitly read the
		# copied QA store, then use the normal level loader, never a reference answer.
		cpu.workbench_store=load("res://src/hardware_foundations/circuit_workbench_store.gd").new("user://hardware_workbenches_v1.json")
		cpu._start_prologue_level(&"cpu",false)
		await settle()
		assert(cpu.graph.get_connection_list().size()>0)
		for panel: Control in cpu.desktop_windows.values(): panel.hide()
		cpu._focus_circuit(true)
		await snap(locale+"-cpu")
		assert(root.get_node("TaskNavigation").enter("chapter_3/buffers"))
		await settle()
		var overlap: Control=current_scene
		overlap._run_official()
		await settle()
		assert(overlap.trace.passed)
		for panel: Control in overlap.panels.values(): panel.hide()
		overlap.panels.program.show(); overlap.panels.trace.show()
		overlap.panels.program.position=Vector2(8,8); overlap.panels.program.size=Vector2(460,720)
		overlap.panels.trace.position=Vector2(490,8); overlap.panels.trace.size=Vector2(1060,720)
		overlap.playing=false
		await snap(locale+"-buffers")
		var metrics:=FileAccess.open("res://.godot/"+locale+"-buffers.json",FileAccess.WRITE)
		metrics.store_string(JSON.stringify(overlap.trace.metrics,"\t")); metrics.close()
		assert(root.get_node("TaskNavigation").enter("hardware_foundations/tutorial"))
		await settle()
		await snap(locale+"-compact-mission")
		print("CHROME ",locale," ",current_scene.graph_stack.global_position.y," MISSION ",current_scene.desktop_windows[&"task"].size," DESKTOP ",current_scene.graph_stack.size)
	print("PASS: copied earned CPU workbench, actual buffer run, compact Mission captures")
	quit()
