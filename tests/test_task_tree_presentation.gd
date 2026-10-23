extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	var localization: Node = root.get_node("Localization")
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		var nav: Node=root.get_node("TaskNavigation"); nav.camera_saved=false; nav.selected="hardware_foundations/tutorial"
		var scene: Control = load("res://src/campaign/task_tree.tscn").instantiate(); root.add_child(scene)
		scene.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); scene.size=Vector2(1280,720)
		for frame: int in range(4): await process_frame
		# The Continue target is framed inside its chapter: fully visible, and a
		# first task does not leave half the view empty left of the route.
		var target := Rect2(scene.canvas.positions[nav.selected]*scene.canvas.magnification+scene.canvas.pan,scene.canvas.NODE_SIZE*scene.canvas.magnification)
		check(Rect2(Vector2.ZERO,scene.canvas.size).encloses(target),"Initial Continue target is fully visible after bilingual container layout.")
		var tray: Rect2 = scene.canvas.region_rects[0]
		var tray_left: float = tray.position.x*scene.canvas.magnification+scene.canvas.pan.x
		check(tray.size.x*scene.canvas.magnification <= scene.canvas.size.x or (tray_left >= -1.0 and tray_left <= 40.0),"A first task frames its chapter from the left edge.")
		var framed_center: Vector2=(scene.canvas.size/2-scene.canvas.pan)/scene.canvas.magnification
		scene.size=Vector2(1400,900)
		for frame: int in range(4): await process_frame
		var after: Vector2=(scene.canvas.size/2-scene.canvas.pan)/scene.canvas.magnification
		check(after.distance_to(framed_center)<1,"Resizing preserves the framed map point.")
		scene.size=Vector2(1280,720)
		for row: Dictionary in scene.rows:
			scene._select(row.key)
			for frame: int in range(2): await process_frame
			var bounds := Rect2(Vector2.ZERO,scene.size)
			check(bounds.encloses(scene.detail_panel.get_global_rect()),"Detail card stays inside minimum viewport: "+locale+" "+row.key)
			check(scene.detail_panel.get_global_rect().encloses(scene.enter_button.get_global_rect()),"Enter remains inside the fixed card footer: "+row.key)
			check(not scene.canvas.get_global_rect().intersects(scene.detail_panel.get_global_rect()),"Map and task card have separate bounds.")
			check(scene.detail_title.text==row.title and scene.enter_button.disabled==not row.unlocked,"Visual hierarchy preserves titles and gates.")
		var canvas: Control = scene.canvas
		canvas._set_hover("")
		canvas.overview()
		var view_bounds:=Rect2(Vector2.ZERO,canvas.size)
		for row: Dictionary in scene.rows:
			check(view_bounds.encloses(Rect2(canvas.positions[row.key]*canvas.magnification+canvas.pan,canvas.NODE_SIZE*canvas.magnification)),"Overview contains every chapter including the ending: "+row.key)
		check(canvas.relation_focus_key().is_empty(),"Overview does not dim the whole route around an offscreen or tiny selected task")
		var before_zoom: float=canvas.magnification
		canvas._zoom_at(canvas.size/2,1.12)
		check(is_equal_approx(canvas.magnification,before_zoom*1.12),"First overview zoom does not jump to an old hard-coded minimum")
		canvas.locate(scene.rows[0].key)
		var motion := InputEventMouseMotion.new()
		motion.position=canvas.positions[scene.rows[0].key]*canvas.magnification+canvas.pan+Vector2(20,20)
		canvas._gui_input(motion)
		check(canvas.hovered_key==scene.rows[0].key,"Task hover identifies the real node.")
		var press := InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=Vector2(40,40)
		canvas._gui_input(press)
		var pan_before: Vector2=canvas.pan
		motion.position=Vector2(90,90); motion.relative=Vector2(50,50); motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		canvas._gui_input(motion)
		check(canvas.dragging and canvas.pan==pan_before+Vector2(50,50),"Holding the mouse still pans the map normally.")
		pan_before=canvas.pan; motion.button_mask=0
		motion.position+=Vector2(50,50)
		canvas._gui_input(motion)
		check(canvas.dragging and canvas.pan==pan_before+Vector2(50,50),"Captured motion without a button mask must continue the pressed map gesture.")
		var release := InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT
		release.position=canvas.get_global_transform_with_canvas()*Vector2(-20,-20)
		canvas._input(release)
		pan_before=canvas.pan
		canvas._gui_input(motion)
		check(not canvas.dragging and canvas.pan==pan_before,"Explicit release outside the map cannot leave sticky panning.")
		canvas._gui_input(press); canvas.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not canvas.dragging and canvas.hovered_key.is_empty(),"Focus loss cancels map gesture and hover.")
		canvas._gui_input(press); root.get_node("WindowMode").window_mode_changing.emit()
		check(not canvas.dragging,"Fullscreen transition cancels map drag.")
		# Keep a manually panned center across destruction/recreation, not only resize.
		var world_center: Vector2=(canvas.size/2-canvas.pan)/canvas.magnification
		scene.queue_free(); await process_frame
		scene=load("res://src/campaign/task_tree.tscn").instantiate();root.add_child(scene)
		scene.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);scene.size=Vector2(1280,720)
		for frame: int in range(4): await process_frame
		check(((scene.canvas.size/2-scene.canvas.pan)/scene.canvas.magnification).distance_to(world_center)<1,"Returning from a task preserves the map center through intermediate container sizes")
		scene.queue_free();await process_frame
	for message: String in failures: push_error(message)
	print("PASS: bilingual 40-task detail card bounds, unchanged gates, hover and canceled map gestures" if failures.is_empty() else "FAIL: task tree presentation")
	quit(0 if failures.is_empty() else 1)
