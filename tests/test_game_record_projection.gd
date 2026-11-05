extends SceneTree
## Explicit fixture namespaces test read-only archive projection, not progression awards.
const LayoutCatalogType = preload("res://src/layout_chapter/layout_catalog.gd")
const OverlapCatalogType = preload("res://src/overlap_chapter/overlap_catalog.gd")
var failures: Array[String] = []
var checks: int = 0
var mode_events: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func settle() -> void:
	for frame: int in range(3): await process_frame

func capture_frame(name: String) -> void:
	if "--record-projection-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	# Wait for the existing terminal arrival before recording a static page.
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var directory: String = "res://.godot/comparable-records"
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = directory.path_join(name+".png")
	check(root.get_texture().get_image().save_png(path) == OK,"Save actual GPU archive frame "+name)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))

func task(rows: Array, key: String) -> Dictionary:
	for row: Dictionary in rows:
		if str(row.key) == key: return row
	return {}

func inventory(path: String) -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(path)
	if directory == null: return result
	for entry: String in directory.get_files(): result[entry] = FileAccess.get_sha256(path.path_join(entry))
	for entry: String in directory.get_directories():
		if entry in ["logs", "shader_cache"]: continue
		var children: Dictionary = inventory(path.path_join(entry))
		for child: String in children: result[entry + "/" + child] = children[child]
	return result

func namespaces() -> Dictionary:
	var snapshot: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	snapshot.erase("saved_at_utc")
	return {
		"game":snapshot,
		"system_test":root.get_node("SystemChapter").test_completed.duplicate(true),
		"locality_test":root.get_node("LocalityChapter").test_completed.duplicate(true),
		"overlap_test":root.get_node("OverlapChapter").test_solutions.duplicate(true),
		"layout_test":root.get_node("LayoutChapter").test_solutions.duplicate(true)
	}

func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	var mode: Node = root.get_node("GameMode")
	var nav: Node = root.get_node("TaskNavigation")
	var save: Node = root.get_node("GlobalSave")
	var system: Node = root.get_node("SystemChapter")
	var locality: Node = root.get_node("LocalityChapter")
	var overlap: Node = root.get_node("OverlapChapter")
	var layout: Node = root.get_node("LayoutChapter")
	var records: Node = root.get_node("PersonalRecords")
	save.configure_for_test("user://projection-save.json","user://projection-workbenches.json")
	save.game_player_content.completed_levels.clear()
	save.game_player_content.completed_levels[&"tutorial"] = true
	system.game_completed.clear(); system.test_completed.clear()
	system.game_completed[&"assembly"] = true
	system.test_completed[&"cpu_speed"] = true; system.test_completed[&"ram_wait"] = true
	locality.game_completed.clear(); locality.test_completed.clear()
	locality.game_completed[&"distant_reads"] = true; locality.test_completed[&"nearby_storage"] = true
	overlap.game_solutions.clear(); overlap.test_solutions.clear()
	overlap.game_solutions["arrival"] = OverlapCatalogType.reference_solution("arrival")
	overlap.test_solutions["buffers"] = OverlapCatalogType.reference_solution("buffers")
	layout.game_solutions.clear(); layout.test_solutions.clear()
	layout.game_solutions["fields"] = LayoutCatalogType.reference_solution("fields")
	layout.test_solutions["records"] = LayoutCatalogType.reference_solution("records")
	layout.test_solutions["hot_cold"] = LayoutCatalogType.reference_solution("hot_cold")
	# Historical scalar deliberately differs from the real saved design measurement.
	records.best["chapter_4/fields"] = {"cycles":987654,"ram_read_bytes":999999,"case_set_version":"old-cases"}
	mode.set_mode(&"test")
	mode.mode_changed.connect(func(_value: StringName) -> void: mode_events += 1)
	var state_before: Dictionary = namespaces()
	var disk_before: Dictionary = inventory("user://")
	var archive: Array[Dictionary] = nav.game_tasks()
	check(task(nav.tasks(),"chapter_1/cpu_speed").completed and not task(nav.tasks(),"chapter_1/assembly").completed,"Ordinary navigation retains current Test completion")
	for key: String in ["hardware_foundations/tutorial","chapter_1/assembly","chapter_2/distant_reads","chapter_3/arrival","chapter_4/fields"]:
		check(task(archive,key).completed,"Game archive retains Game completion in Test: "+key)
	for key: String in ["chapter_1/cpu_speed","chapter_1/ram_wait","chapter_2/nearby_storage","chapter_3/buffers","chapter_4/records","chapter_4/hot_cold"]:
		check(not task(archive,key).completed,"Game archive excludes temporary Test completion: "+key)
	var snapshot: Dictionary = records.snapshot(archive)
	check(snapshot.completed == 5,"Core archive counts only the five Game fixtures")
	var measured: Dictionary = task(snapshot.tasks,"chapter_4/fields")
	var expected_cycles: int = layout.cost(LayoutCatalogType.evaluate("fields",layout.game_solutions.fields))
	check(measured.record_kind == "replayed" and int(measured.best.cycles) == expected_cycles,"Current record comes from the actual saved recipe")
	check(int(measured.historical_best.cycles) == 987654,"Historical receipt remains separate from current remeasurement")
	var projected: Dictionary = task(archive,"chapter_1/assembly")
	projected.completed = false
	check(system.game_completed[&"assembly"],"A detached display row cannot mutate Game completion")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.size = Vector2i(960,720)
		root.content_scale_size = Vector2i(960,720)
		var compact_page = load("res://src/playtest/personal_records_view.tscn").instantiate()
		root.add_child(compact_page)
		await settle()
		var review_button: Button = compact_page.find_child("RecordReview",true,false)
		check(compact_page.get_global_rect().encloses(review_button.get_global_rect()),"Record-review action fits at 960px "+locale)
		check(compact_page.content.columns == 2 and compact_page.content.get_child_count() == 5,"Regional cards remain intact at 960px "+locale)
		await capture_frame("records-960-"+locale)
		compact_page.queue_free()
		await settle()
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	var page = load("res://src/playtest/personal_records_view.tscn").instantiate()
	root.add_child(page)
	await settle()
	check(page.data.completed == 5,"Record page uses Game completion even while Test is active")
	page._open_journal()
	var journal: Variant = page.journal
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		journal.open()
		journal.show_task("chapter_1/cpu_speed")
		check(journal.scope_label.visible and not journal.enter_button.disabled,"Archive labels Game scope while allowing original Test entry "+locale)
		check(not journal.earned(journal.selected_task()) and journal.civilization_fragment(journal.selected_task()).is_empty(),"Temporary Test completion creates no archive retrospective "+locale)
		journal.show_task("chapter_1/assembly")
		check(journal.earned(journal.selected_task()) and not journal.civilization_fragment(journal.selected_task()).is_empty(),"Actual Game completion retains its archive retrospective "+locale)
		journal.show_task("chapter_4/fields")
		check(journal.detail.text.contains(str(expected_cycles)) and journal.detail.text.contains("987654"),"Journal keeps current measurement and historical scalar distinct "+locale)
		check(journal.detail.text.contains("remeasured" if locale == "en" else "复测") and journal.detail.text.contains("historical review" if locale == "en" else "历史回顾"),"Both record sources are explicitly named "+locale)
		check(journal.detail.text.contains("RAM reads" if locale == "en" else "RAM 读取") and not journal.detail.text.contains("ram_read_bytes:"),"Primary metrics use localized names and bytes "+locale)
		check(journal.detail.text.contains("case_set_version: old-cases"),"Historical condition provenance survives "+locale)
		if "--record-projection-capture" in OS.get_cmdline_user_args():
			journal._refresh_tasks()
			journal.task_tree.scroll_to_item(journal.task_tree.get_selected(),true)
			await settle()
			(journal.detail.get_parent() as ScrollContainer).scroll_vertical = int(journal.detail.size.y)
		await capture_frame("journal-"+locale)
		var prior_status: String = records.storage_status
		for status: String in ["read_only","write_failed","ready"]:
			records.storage_status = status
			journal.open()
			page._refresh_record_notice()
			check(journal.record_storage_label.visible == (status != "ready") and page.record_storage_label.visible == (status != "ready"),"Storage notice appears only for an actual failure status "+locale+" "+status)
			if status != "ready":
				check(not journal.record_storage_label.text.is_empty() and journal.record_storage_label.text == page.record_storage_label.text,"Journal and record page expose the same localized save status "+locale+" "+status)
		records.storage_status = prior_status
		journal.open()
		page._refresh_record_notice()
	journal.close()
	check(mode.current_mode == &"test" and mode_events == 0,"Reading archives never switches mode")
	check(namespaces() == state_before,"Archive projection and browsing preserve all Game/Test state")
	check(inventory("user://") == disk_before,"Archive projection and browsing write no player or record bytes")
	community_context_checks(page)
	page.queue_free()
	await settle()
	mode.set_mode(&"game")
	var canvas: Control = load("res://src/campaign/task_tree_canvas.gd").new()
	root.add_child(canvas)
	canvas.configure(nav.tasks())
	var layout_task: Dictionary = task(nav.tasks(),"chapter_4/fields")
	check(canvas.record_caption(layout_task).contains(str(expected_cycles)) and not canvas.record_caption(layout_task).contains("999999"),"Map uses current measured cycles rather than historical RAM or a traffic-best claim")
	check(canvas.record_detail(layout_task).contains("Fastest saved passing design") and canvas.record_detail(layout_task).contains("peak scratch"),"Map explains the retained design objective and aggregation")
	mode.set_mode(&"test")
	check(canvas.record_caption(layout_task).is_empty() and canvas.record_detail(layout_task).is_empty(),"Test map does not borrow Game measurements")
	canvas.queue_free()
	await settle()
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"Game record projection %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func community_context_checks(page: Control) -> void:
	# Exercise response routing without configuring an endpoint or opening a socket.
	if not is_instance_valid(page.online_status):
		page.online_status = Label.new()
		page.add_child(page.online_status)
	var fetch: Button = Button.new()
	page.add_child(fetch)
	page.fetch_buttons.append(fetch)
	fetch.disabled = true
	page.request_kind = "community/tasks"
	page._fetch("leaderboards")
	check(page.request_kind == "community/tasks" and fetch.disabled,"A second fetch cannot replace the in-flight response context")
	var payload := {"tasks":{"hardware_foundations/tutorial":{"completions":2,"starts":3,"small_sample":false}}}
	page._received(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify(payload).to_utf8_buffer())
	check(page.request_kind.is_empty() and not fetch.disabled and page.online_status.text.contains("2 / 3"),"Original statistics response uses its own parser and releases controls")
	fetch.disabled = true; page.request_kind = "leaderboards"
	page._received(HTTPRequest.RESULT_CANT_CONNECT,0,PackedStringArray(),PackedByteArray())
	check(page.request_kind.is_empty() and not fetch.disabled,"Failed requests release the pending context and controls")
	page.request_kind = "leaderboards"
	page._received(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),'{"rows":[{"rank":1,"player":"Fixture","total_cycles":42}]}'.to_utf8_buffer())
	check(page.online_status.text.contains("Fixture") and page.online_status.text.contains("42"),"Leaderboard response retains the proper metric parser")
	page.request_kind = "leaderboards"
	page._received(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),'{"rows":[{"rank":"wrong","player":"Fixture","total_cycles":42}]}'.to_utf8_buffer())
	check(page.online_status.text == root.get_node("Localization").text(&"records.unreadable_response"),"Malformed response fields cannot invent scores")
