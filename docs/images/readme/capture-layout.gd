extends SceneTree
func _init() -> void: call_deferred("run")
func settle() -> void:
	for frame: int in range(15): await process_frame
func run() -> void:
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1600,1000); root.content_scale_size=Vector2i(1600,1000)
	await settle()
	assert(not root.get_node("GameMode").is_test_mode())
	assert(root.get_node("GlobalSave").load_game())
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		assert(root.get_node("TaskNavigation").enter("chapter_4/mixed"))
		await settle()
		var host: Control=current_scene
		assert(root.get_node("LayoutChapter").completed().has("mixed"))
		host._run_all()
		await settle()
		# Presentation only: keep the actual two orders and address view unobstructed.
		host.panels["mission"].hide()
		host.panels["manual"].hide()
		host.panels["tools"].position=Vector2(8,8);host.panels["tools"].size=Vector2(390,800)
		host.panels["memory"].position=Vector2(408,8);host.panels["memory"].size=Vector2(600,800)
		host.panels["trace"].position=Vector2(1018,8);host.panels["trace"].size=Vector2(550,800)
		await settle()
		var metrics: Array=[]
		for run: LayoutRun in host.runs: metrics.append(run.metrics)
		var report:=FileAccess.open("res://.godot/"+locale+"-layout-metrics.json",FileAccess.WRITE)
		report.store_string(JSON.stringify(metrics,"\t"));report.close()
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://.godot/"+locale+"-layout-showcase.png")==OK)
	print("PASS: ordinary Game saved QA design re-run and bilingual viewport capture")
	quit()
