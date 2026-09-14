extends SceneTree
## Presentation captures only. Synthetic setup is not a native player acceptance.
func _init() -> void: call_deferred("run")
func settle() -> void:
	for frame: int in range(8): await process_frame
func snap(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/"+file+".png")
func run() -> void:
	assert(str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("VonNeumannBottleneckChecks/"))
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1600,900)
	root.content_scale_size=Vector2i(1600,900)
	root.get_node("Localization").set_locale("zh_CN")
	var main: Control=load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(main)
	await settle()
	main._start_campaign_level(&"tutorial", false)
	await settle()
	for panel: Control in main.desktop_windows.values(): panel.hide()
	main._focus_circuit(true)
	await settle()
	var graph: GraphEdit=main.graph
	var source: GraphNode=main.component_nodes[&"A_IN"]
	var target: GraphNode=main.component_nodes[&"NOT_1"]
	graph.begin_builtin_connection_preview(source.name,0,true)
	graph.builtin_connection_pointer=graph.displayed_port_position(target,0,false)
	graph.queue_redraw()
	await snap("preview-valid")
	graph.builtin_connection_pointer=graph.displayed_port_position(target,0,true)
	graph.queue_redraw()
	await snap("preview-rejected")
	graph.end_builtin_connection_preview()
	graph.begin_builtin_connection_preview(target.name,0,false)
	graph.builtin_connection_pointer=graph.displayed_port_position(source,0,true)
	graph.queue_redraw()
	await snap("preview-reverse")
	graph.builtin_connection_pointer=graph.displayed_port_position(source,0,true)+Vector2(0,90)
	graph.draft_motion=1.0
	graph.set_process(false)
	graph.queue_redraw()
	await snap("preview-moving")
	graph.draft_motion=0.0
	graph.queue_redraw()
	await snap("preview-still")
	print("PASS: wire preview frame captures")
	quit()
