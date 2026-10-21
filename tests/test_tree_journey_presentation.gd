extends SceneTree
## Pure evidence-adapter fixtures plus real map controls. No earned player progress.
const Adapter = preload("res://src/campaign/second_act_tasks.gd")
const Creation = preload("res://src/campaign/creation_tasks.gd")
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
	check(indexed(all_rows).size() == 51,"Original 40 plus second-act 11 retain unique identities")
	var creation: Array[Dictionary] = Creation.build(false)
	check(creation.size() == 9,"Actual creation adapter exposes the nine C/P/G candidates")
	if creation.size() != 9: quit(1); return
	all_rows.append_array(creation)
	var all_keys: Dictionary = indexed(all_rows)
	check(all_keys.size() == 60,"All60 domain-qualified identities are unique")
	var layout: Dictionary = Layout.build(all_rows)
	check(layout.errors.is_empty() and layout.positions.size() == 60 and layout.regions.size() == 11,"Unified layout contains all 60 real nodes and 11 regions")
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
		scene.rows.append_array(Creation.build(locale == "en"))
		scene.canvas.configure(scene.rows); await settle()
		var menu_regions: Array[int] = []
		for index: int in scene.region_choice.item_count: menu_regions.append(int(scene.region_choice.get_item_metadata(index)))
		for row: Dictionary in scene.rows:
			var region: int = int(row.region)
			if region in menu_regions: continue
			menu_regions.append(region)
			scene.region_choice.add_item(str(row.get("region_title",root.get_node("Localization").text(StringName("tree.region."+str(region))))))
			scene.region_choice.set_item_metadata(scene.region_choice.item_count-1,region)
		check(scene.rows.size() == 60 and scene.region_choice.item_count == 12,"Fixture map exposes all sixty tasks and whole-journey plus eleven chapter choices: "+locale)
		for row: Dictionary in scene.rows:
			scene._select(row.key); scene.canvas.locate(row.key); await settle()
			check(scene.detail_title.text == row.title and scene.enter_button.disabled == not row.unlocked,"Map detail reflects selected task and real eligibility: "+row.key)
			check(root.get_visible_rect().encloses(scene.detail_panel.get_global_rect()),"Task detail within minimum window: "+locale+row.key)
			check(scene.detail_panel.get_global_rect().encloses(scene.enter_button.get_global_rect()),"Enter remains reachable: "+row.key)
			var center: Vector2 = (scene.canvas.positions[row.key]+Layout.NODE_SIZE/2)*scene.canvas.magnification+scene.canvas.pan
			check(Rect2(Vector2.ZERO,scene.canvas.size).has_point(center),"Every selected task can be located on map: "+row.key)
			var expected_next: Array[String]=[]
			for next_row: Dictionary in scene.rows:
				if str(row.key) in next_row.dependencies: expected_next.append(str(next_row.key))
			var actual_next: Array[String]=[]
			for link: Node in scene.downstream_rows.get_children(): actual_next.append(str(link.get_meta("task_key")))
			check(actual_next==expected_next,"Downstream links exactly follow hard dependencies: "+row.key)
			check(scene.downstream_heading.visible==not expected_next.is_empty(),"No invented downstream tasks: "+row.key)
			if row.key == "chapter_3/arrival":
				check(scene.prerequisite_rows.get_child_count() == 1 and str(scene.prerequisite_rows.get_child(0).get_meta("task_key")) == "chapter_2/capstone","Core hard prerequisite stays a clickable, distinct relation")
			if row.key == "service/prompt_response":
				check(scene.eligibility_heading.visible and scene.eligibility_rows.get_child_count() == 1 and str(scene.eligibility_rows.get_child(0).get_meta("task_key")) == "service/move_state","Locked Service contract explains saved-work eligibility and earlier-contract navigation")
			if row.key == "creation/C1_restore":
				check(scene.detail_kind.text.contains("创作") or scene.detail_kind.text.contains("Creation"),"C/P/G detail identifies creation content")
				check(scene.recommendation_rows.get_child_count() == 1 and str(scene.recommendation_rows.get_child(0).get_meta("task_key")) == "representation/cross_assets","C/P/G recommendation remains a clickable relation, not a prerequisite")
			if row.key in ["representation/mixed_scan","service/move_state","prediction/regular"]: await capture_map(locale+"-"+row.domain)
			if row.key in ["creation/C1_restore","creation/P1_commit","creation/G1_feedback"]: await capture_map(locale+"-"+row.id)
		for index: int in scene.region_choice.item_count:
			if int(scene.region_choice.get_item_metadata(index)) == 8:
				scene.region_choice.select(index)
				scene.region_choice.item_selected.emit(index)
				break
		await settle()
		var list_rect: Rect2 = scene.list_scroll.get_global_rect()
		var first_entry := scene.list_rows.get_child(0) as Button
		var first_visible: Rect2 = list_rect.intersection(first_entry.get_global_rect())
		check(scene.list_view.visible and scene.list_rows.get_child_count() == 3 and (scene.list_summary.text.contains("压缩") or scene.list_summary.text.contains("Compression")),"Compression chapter lists its three tasks: "+locale)
		check(root.get_visible_rect().encloses(list_rect) and list_rect.size.y >= 120 and first_visible.size.y >= 40,"Chapter list has usable scroll height and a visible clickable entry at 1280x720: "+locale)
		await capture_map(locale+"-compression-chapter-list")
		scene.search.text="creation/"; scene._on_search_changed(scene.search.text); await settle()
		list_rect=scene.list_scroll.get_global_rect()
		first_entry=scene.list_rows.get_child(0) as Button
		first_visible=list_rect.intersection(first_entry.get_global_rect())
		check(scene.list_view.visible and scene.list_rows.get_child_count() == 9 and (scene.list_title.text.contains("搜索") or scene.list_title.text.contains("Search")),"Global search exposes all nine clickable C/P/G candidates: "+locale)
		check(root.get_visible_rect().encloses(list_rect) and list_rect.size.y >= 120 and first_visible.size.y >= 40,"Search results retain a usable clickable area at 1280x720: "+locale)
		await capture_map(locale+"-creation-search")
		var last_entry := scene.list_rows.get_child(8) as Button
		scene.list_scroll.scroll_vertical=int(scene.list_scroll.get_v_scroll_bar().max_value); await settle()
		check(scene.list_scroll.get_global_rect().intersection(last_entry.get_global_rect()).size.y >= 40,"Last C/P/G search result is reachable by scrolling: "+locale)
		scene.list_scroll.scroll_vertical=0; await settle()
		first_entry.pressed.emit(); await settle()
		check(scene.selected.key == "creation/C1_restore" and scene.detail_view.visible and scene.search.text == "creation/","Search result opens the actual task without clearing the query: "+locale)
		var relation := scene.recommendation_rows.get_child(0) as Button
		scene.detail_scroll.scroll_vertical=int(scene.detail_scroll.get_v_scroll_bar().max_value); await settle()
		check(scene.detail_scroll.get_global_rect().intersects(relation.get_global_rect()),"Recommended relation remains visible in the scrolled detail panel: "+locale)
		relation.pressed.emit(); await settle()
		check(scene.selected.key == "representation/cross_assets","Recommended relation selects and locates the actual prior task: "+locale)
		var after_core: Array[Dictionary] = nav.tasks()
		check(after_core.size() == core.size(),"Presentation keeps original40 task identities")
		for i: int in core.size():
			for field: String in ["key","dependencies","unlocked","completed"]: check(after_core[i][field] == core[i][field],"Presentation never changes core authority: "+field)
		scene.queue_free(); await settle()
	check(snapshot() == before,"Map and fixture review write no campaign progress")
	print("PASS: " if failures == 0 else "FAIL: ","test_tree_journey_presentation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
