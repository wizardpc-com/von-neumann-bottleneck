extends "res://scripts/proxy-player-paths.gd"
## Isolated Test entry; measured collection/copy/save/return use viewport input.
## Baselines are real public initial plans, not authored successful solutions.
const RepStore = preload("res://experiments/representation_region/session_store.gd")
const ServiceStore = preload("res://experiments/service_plan/session_store.gd")
const Keys = preload("res://src/campaign/second_act_tasks.gd")
var completed_loops: Array[String] = []

func fit_window() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	await settle(12)
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 60:
		DisplayServer.window_set_size(Vector2i(1280,720))
		root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable+1 if picture != null and picture.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,"Actual 1280x720 pixels stabilize before input")

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless" or "--recovery-capture" not in OS.get_cmdline_user_args(): return
	await reveal_capture_shelf()
	await settle(12)
	RenderingServer.force_draw(false)
	var picture: Image = root.get_texture().get_image()
	check(picture != null and picture.get_size() == Vector2i(1280,720),"Raw shelf-return frame remains 1280x720")
	if picture != null:
		check(picture.save_png(evidence_root+label+".png") == OK,"Save unmodified shelf-return viewport: "+label)

func reveal_capture_shelf() -> void:
	var choices: Control = ui.design_shelf.choices
	var restore: Control = ui.design_shelf.restore_button
	var ancestor: Node = choices.get_parent()
	var scroll: ScrollContainer
	while ancestor != null:
		if ancestor is ScrollContainer:
			scroll = ancestor as ScrollContainer
			break
		ancestor = ancestor.get_parent()
	for attempt: int in 60:
		var visible: Rect2 = root.get_visible_rect()
		if scroll != null: visible = visible.intersection(scroll.get_global_rect())
		if visible.encloses(choices.get_global_rect()) and visible.encloses(restore.get_global_rect()): break
		if scroll == null: break
		var direction: MouseButton = MOUSE_BUTTON_WHEEL_DOWN if restore.get_global_rect().end.y > visible.end.y else MOUSE_BUTTON_WHEEL_UP
		await click(visible.get_center(),direction)
	var actual_view: Rect2 = root.get_visible_rect()
	if scroll != null: actual_view = actual_view.intersection(scroll.get_global_rect())
	check(choices.is_visible_in_tree() and actual_view.encloses(choices.get_global_rect()),"Capture shows the complete saved-name selector inside its actual scroll viewport")
	check(restore.is_visible_in_tree() and actual_view.encloses(restore.get_global_rect()),"Capture shows the complete Copy action inside its actual scroll viewport")

func tab_click(tabs: TabContainer, index: int) -> void:
	var bar: TabBar = tabs.get_tab_bar()
	bar.ensure_tab_visible(index)
	await settle()
	var at: Vector2 = bar.get_global_transform()*bar.get_tab_rect(index).get_center()
	check(root.get_visible_rect().has_point(at),"Collection tab has a visible hit point")
	await click(at)
	check(tabs.current_tab == index,"Actual tab click opens the collection page")

func open_shelf(domain: String) -> void:
	if domain == "service":
		if not ui.evidence_tabs.tabs_visible:
			await press(ui.find_child("ToggleEvidenceTabs",true,false))
		await tab_click(ui.evidence_tabs,6)
	if not ui.design_shelf.content.visible:
		await press(ui.design_shelf.toggle)
	check(ui.design_shelf.content.is_visible_in_tree(),"Measured collection is visibly open")

func authority(domain: String) -> Dictionary:
	var records: Array = []
	for record: Dictionary in ui.history:
		if domain == "representation":
			var traces: Array[String] = []
			for trace: RefCounted in record.traces: traces.append(trace.canonical_signature())
			records.append({"task":record.task,"plan":record.plan.duplicate(true),"traces":traces})
		else: records.append(record.duplicate(true))
	return {"history":records,"supports":ui.support_plans.duplicate(true),
		"progress":ui.completed.duplicate() if domain == "representation" else ui.unlocked}

func reenter_from_map(task_key: String) -> bool:
	check(on_task_tree(),"Home reaches the actual journey-map scene")
	if not on_task_tree(): return false
	var tree = current_scene
	await press(tree.search); await key(KEY_A,true); await type_text(task_key); await key(KEY_ENTER)
	await settle()
	check(tree.canvas.positions.has(task_key),"Public map search locates the original task")
	if not tree.canvas.positions.has(task_key): return false
	var at: Vector2 = tree.canvas.global_position+tree.canvas.pan+(tree.canvas.positions[task_key]+tree.canvas.NODE_SIZE/2)*tree.canvas.magnification
	check(tree.canvas.get_global_rect().has_point(at),"Original task node has a visible hit point")
	await click(at)
	check(tree.selected.get("key","") == task_key and not tree.enter_button.disabled,"Viewport click selects the Test-access task without granting completion")
	if tree.selected.get("key","") != task_key or tree.enter_button.disabled: return false
	await press(tree.enter_button); await settle(16)
	return current_scene != null and not on_task_tree()

func exercise(domain: String, locale: String, route: String) -> void:
	var task_key: String = Keys.key_for(domain,0)
	var path: String = "user://shelf-return-"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	if domain == "representation": RepStore.PATH = path
	else: ServiceStore.PATH = path
	var nav: Node = root.get_node("TaskNavigation")
	check(nav.enter(task_key),"Isolated Test fixture enters "+task_key)
	await settle(16)
	ui = current_scene
	if ui == null: check(false,"Candidate host exists"); return
	await fit_window()
	check(ui.persistent_session and not ui.save_blocked,"Fresh candidate owns its isolated writer")
	# from_tree determines the existing public CandidateHome destination only.
	nav.from_tree = route == "map"
	await press(ui.run_button)
	check(ui.history.size() == 1,"Run produces exactly one actual measured baseline")
	if ui.history.is_empty(): return
	var original_plan = ui.plan.duplicate(true)
	var measured: Dictionary = authority(domain)
	await open_shelf(domain)
	await press(ui.design_shelf.design_name)
	await type_text(domain+" "+locale+" "+route)
	await press(ui.design_shelf.remember_button)
	check(ui.designs.size() == 1 and ui.designs[0].plan == original_plan,"Real measured baseline enters the named collection")
	var designs: Array = ui.designs.duplicate(true)
	if domain == "representation": await press(ui.rle_button)
	else: await edit_number(ui.slots,4)
	check(ui.plan != original_plan,"Viewport edit changes the draft before collection copy")
	await open_shelf(domain)
	await choose(ui.design_shelf.choices,0)
	await press(ui.design_shelf.restore_button)
	check(ui.plan == original_plan and ui.task == 0,"Actual collection Copy restores the original task and measured plan")
	check(authority(domain) == measured and ui.designs == designs,"Copy neither measures nor changes progress, protected support or collection")
	await press(ui.find_child("SaveSession",true,false))
	await settle()
	check(not ui.session_dirty and FileAccess.file_exists(path),"Explicit Save writes the copied draft and collection")
	var saved: PackedByteArray = FileAccess.get_file_as_bytes(path)
	await press(ui.find_child("CandidateHome",true,false)); await settle(20)
	if route == "laboratory":
		check(current_scene != null and current_scene.scene_file_path == "res://src/ui/prototype_hub.tscn","CandidateHome reaches the actual Laboratory host")
		if current_scene == null or current_scene.scene_file_path != "res://src/ui/prototype_hub.tscn": return
		await fit_window()
		await key(KEY_ENTER); await create_timer(1.5).timeout; await settle()
		var journey: Control = current_scene.laboratory.terminal.find_child("TerminalJourney",true,false)
		await press(journey); await settle(20)
	if not await reenter_from_map(task_key): check(false,"Actual map entry returns to candidate host"); return
	ui = current_scene
	await fit_window()
	check(ui.task == 0 and ui.plan == original_plan and ui.designs == designs and not ui.session_dirty,"Reentry restores the exact saved task, plan, named shelf and clean state")
	check(authority(domain) == measured,"Reentry revalidates without creating extra measured runs or completion")
	check(FileAccess.get_file_as_bytes(path) == saved,"Navigation and reentry do not rewrite the explicitly saved profile")
	await open_shelf(domain)
	check(ui.design_shelf.choices.item_count == 1 and ui.design_shelf.choices.get_item_text(0).contains(locale),"Reopened collection exposes the actual saved player label")
	await shot("shelf-return-"+domain+"-"+locale+"-"+route)
	completed_loops.append(domain+"/"+locale+"/"+route)
	ui.queue_free(); current_scene = null; await settle(12)

func _run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use the isolated verification runner."); quit(2); return
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("playtest/offline_tester",true)
	ProjectSettings.set_setting("game/reduced_motion",true)
	var original_rep: String = RepStore.PATH
	var original_service: String = ServiceStore.PATH
	var game: Dictionary = root.get_node("GlobalSave")._save_snapshot().game.duplicate(true)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for domain: String in ["representation","service"]:
			for route: String in ["map","laboratory"]: await exercise(domain,locale,route)
	RepStore.PATH = original_rep; ServiceStore.PATH = original_service
	check(completed_loops.size() == 8,"All bilingual/domain/map and Laboratory loops reach their final observation")
	check(root.get_node("GlobalSave")._save_snapshot().game == game,"Test collection loops preserve ordinary Game state")
	finish()

func finish() -> void:
	var file := FileAccess.open(evidence_root+"candidate-shelf-return.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope":"Real viewport collection/copy/save/map and Laboratory return; isolated Test access, not a Game playthrough","observations":observations,"failures":failures},"\t"))
		file.close()
	else: failures.append("Cannot save candidate shelf-return evidence")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"candidate shelf return %d checks, %d failures" % [observations.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
