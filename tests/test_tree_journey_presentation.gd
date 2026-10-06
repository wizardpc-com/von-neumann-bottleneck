extends SceneTree
## Pure evidence-adapter fixtures plus real map controls. No earned player progress.
const Adapter = preload("res://src/campaign/second_act_tasks.gd")
const Layout = preload("res://src/campaign/task_tree_layout.gd")
var failures: int = 0
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func indexed(rows: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows: result[row.key] = row
	return result
func snapshot() -> Dictionary:
	var result: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	result.erase("saved_at_utc"); return result
func capture_map(name: String) -> void:
	if not "--journey-map-capture" in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless","Map capture requires rendering")
	if DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	var picture: Image = root.get_texture().get_image()
	var folder: String = "res://.godot/journey-map-captures"
	check(picture.get_size() == Vector2i(1280,720),"Actual map capture dimensions")
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"Capture directory")
	check(picture.save_png(folder.path_join(name+".png")) == OK,"Map image saved")
func run() -> void:
	var nav: Node = root.get_node("TaskNavigation")
	var before: Dictionary = snapshot()
	var core: Array[Dictionary] = nav.tasks()
	check(core.size() == 40,"Existing campaign authority remains exactly40 tasks")
	var empty: Dictionary = {"representation":{"status":"empty","completed":[]},"service":{"status":"empty","completed":[]},"complete":false}
	var rows: Array[Dictionary] = Adapter.build(empty,false)
	check(rows.size() == 11,"Same-map adapter exposes actual5+3+3 tasks")
	if rows.size() != 11: quit(1); return
	var by_key: Dictionary = indexed(rows)
	for key: String in ["representation/mixed_scan","representation/cross_assets","service/move_state","prediction/regular","prediction/alternating"]:
		check(by_key.has(key),"Stable real task identity: "+key)
	for row: Dictionary in rows:
		check(not row.completed,"Empty saved evidence grants no completion: "+row.key)
		if row.domain == "representation" or row.domain == "prediction": check(row.unlocked,"Independent legal entry remains available: "+row.key)
	check(by_key["service/move_state"].unlocked and not by_key["service/prompt_response"].unlocked and not by_key["service/one_plan"].unlocked,"Service retains its own initial contract gate")
	var late: Dictionary = empty.duplicate(true)
	late.service = {"status":"partial","completed":[2]}
	var late_rows: Dictionary = indexed(Adapter.build(late,false))
	check(late_rows["service/one_plan"].unlocked and late_rows["service/one_plan"].completed,"Existing late accepted support remains valid without invented prior receipts")
	check(not late_rows["service/move_state"].completed,"Late support does not fabricate another contract's completion")
	for row: Dictionary in rows:
		if row.domain == "prediction": check(row.optional and row.progress_source == "session","Prediction is optional and never permanent progress")
		if row.domain in ["representation","service"]:
			check(not row.dependencies.has("chapter_4/mixed"),"Recommended second act does not lock independent existing content")
	var all_rows: Array[Dictionary] = core.duplicate(true); all_rows.append_array(rows)
	var all_keys: Dictionary = indexed(all_rows)
	check(all_keys.size() == 51,"All51 domain-qualified identities are unique")
	var layout: Dictionary = Layout.build(all_rows)
	check(layout.errors.is_empty() and layout.positions.size() == 51 and layout.regions.size() == 8,"Unified layout contains all eight real regions")
	check(layout.positions == Layout.build(all_rows).positions,"Unified layout is deterministic")
	var keys: Array = layout.positions.keys()
	for i: int in keys.size():
		var rect := Rect2(layout.positions[keys[i]],Layout.NODE_SIZE)
		check(Rect2(Vector2.ZERO,layout.size).encloses(rect),"Node within world: "+keys[i])
		for j: int in range(i+1,keys.size()): check(not rect.intersects(Rect2(layout.positions[keys[j]],Layout.NODE_SIZE)),"Distinct task nodes never overlap")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.content_scale_size = Vector2i(1280,720); root.size = Vector2i(1280,720)
		if "--journey-map-capture" in OS.get_cmdline_user_args():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			await create_timer(1.0).timeout
			root.size = Vector2i(1280,720); DisplayServer.window_set_size(Vector2i(1280,720))
			await create_timer(0.4).timeout
		var scene: Control = load("res://src/campaign/task_tree.tscn").instantiate()
		nav.camera_saved = false; nav.selected = "hardware_foundations/tutorial"
		root.add_child(scene); await settle()
		# Explicit fixture rows exercise presentation without bypassing production enablement.
		scene.rows = nav.tasks(); scene.rows.append_array(Adapter.build(empty,locale == "en"))
		scene.canvas.configure(scene.rows); await settle()
		for row: Dictionary in scene.rows:
			scene._select(row.key); scene.canvas.locate(row.key); await settle()
			check(scene.detail_title.text == row.title and scene.enter_button.disabled == not row.unlocked,"Map detail reflects selected task and real eligibility: "+row.key)
			check(root.get_visible_rect().encloses(scene.detail_panel.get_global_rect()),"Task detail within minimum window: "+locale+row.key)
			check(scene.detail_panel.get_global_rect().encloses(scene.enter_button.get_global_rect()),"Enter remains reachable: "+row.key)
			var center: Vector2 = (scene.canvas.positions[row.key]+Layout.NODE_SIZE/2)*scene.canvas.magnification+scene.canvas.pan
			check(Rect2(Vector2.ZERO,scene.canvas.size).has_point(center),"Every selected task can be located on map: "+row.key)
			if row.key in ["representation/mixed_scan","service/move_state","prediction/regular"]: await capture_map(locale+"-"+row.domain)
		var after_core: Array[Dictionary] = nav.tasks()
		check(after_core.size() == core.size(),"Presentation keeps original40 task identities")
		for i: int in core.size():
			for field: String in ["key","dependencies","unlocked","completed"]: check(after_core[i][field] == core[i][field],"Presentation never changes core authority: "+field)
		scene.queue_free(); await settle()
	check(snapshot() == before,"Map and fixture review write no campaign progress")
	print("PASS: " if failures == 0 else "FAIL: ","test_tree_journey_presentation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
