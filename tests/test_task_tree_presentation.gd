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
		var center: Vector2=(scene.canvas.positions[nav.selected]+scene.canvas.NODE_SIZE/2)*scene.canvas.magnification+scene.canvas.pan
		check(center.distance_to(scene.canvas.size/2)<1,"Initial Continue target stays centered after bilingual container layout.")
		scene.size=Vector2(1400,900)
		for frame: int in range(4): await process_frame
		center=(scene.canvas.positions[nav.selected]+scene.canvas.NODE_SIZE/2)*scene.canvas.magnification+scene.canvas.pan
		check(center.distance_to(scene.canvas.size/2)<1,"Resizing preserves the centered task.")
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
		scene.queue_free(); await process_frame
	for message: String in failures: push_error(message)
	print("PASS: bilingual 40-task detail card bounds, unchanged gates, hover and canceled map gestures" if failures.is_empty() else "FAIL: task tree presentation")
	quit(0 if failures.is_empty() else 1)
