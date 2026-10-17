extends SceneTree
## Controller/model integration, separate from native input and player comprehension.
const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
const Card = preload("res://src/ui/journey_context_card.gd")
const SecondAct = preload("res://src/campaign/second_act_tasks.gd")
const CreationTasks = preload("res://src/campaign/creation_tasks.gd")
const Representation = preload("res://experiments/representation_region/model.gd")
var checks: int = 0
var failures: Array[String] = []
var captured_domains: Dictionary = {}
var captures: Array[Dictionary] = []

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func open_host(path: String, pending: String = "") -> Control:
	root.get_node("TaskNavigation").pending = pending
	var scene: Control = load(path).instantiate()
	root.add_child(scene); await settle()
	return scene
func release(scene: Control) -> void:
	scene.queue_free(); await settle()
func card_is(scene: Control, task_id: String) -> void:
	var card: Variant = scene.journey_context
	check(is_instance_valid(card) and card.last_task == task_id, "Real host consumes context for " + task_id)
	if not is_instance_valid(card): return
	var action: Control = scene.next_step_label if task_id.begins_with("creation/") else card.action_label
	check(action.visible and card.verify_label.visible and not card.details.visible, "Action and verification precede optional context: " + task_id)
	check(not card.context_label.text.contains("Earned record") and not card.context_label.text.contains("已有验收记录"), "Fresh access is not an earned record: " + task_id)
	await capture_host_context(scene)
func changed(scene: Control) -> void:
	check(scene.journey_context.evidence_label.text.contains("draft changed" if scene.journey_context.english else "草稿已改变"), "An edit identifies the current draft without reinterpreting earlier evidence")

func run() -> void:
	var navigation: Node = root.get_node("TaskNavigation")
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test("user://full-journey-narrative-save.json", "user://full-journey-narrative-workbench.json")
	root.get_node("GameMode").set_mode(&"test")
	var before: Dictionary = save._save_snapshot(); before.erase("saved_at_utc")
	ProjectSettings.set_setting("playtest/offline_tester", true)
	var rows: Array[Dictionary] = navigation.tasks()
	rows.append_array(SecondAct.build({}, false))
	rows.append_array(CreationTasks.build(false, PackedStringArray(["--creation-profile=user://full-journey-unearned.json"])))
	check(rows.size() == 60 and Catalog.TASK_CONTEXTS.size() == rows.size(), "Context identities match the actual forty core and twenty candidate contracts")
	for row: Dictionary in rows:
		for english: bool in [false, true]:
			var context: Dictionary = Catalog.task_context(StringName(row.domain), StringName(row.id), english)
			check(context.get("task_id", "") == str(row.key), "Actual catalog identity is represented: " + str(row.key))
			for field: String in ["intent", "action", "verify", "connection", "completion", "scope", "failure"]:
				check(not str(context.get(field, "")).is_empty(), "Bilingual contract field exists: " + str(row.key) + "/" + field)
	check(Catalog.task_context(&"unknown", &"tutorial", false).is_empty(), "Unknown domain cannot borrow tutorial meaning")
	check(Catalog.task_context(&"creation", &"tutorial", true).is_empty(), "Unknown level cannot borrow another domain's earned response")
	var detached := Card.new()
	detached.set_task(&"chapter_3", &"synthesis", true)
	check(detached.action_label.text.contains("Buffer") and detached.action_label.text.contains("Cache"), "Synthesis preserves both modeled routes")
	detached.set_task(&"creation", &"G2_intent", true)
	check(detached.verify_label.text.contains("Direct Keep") and detached.verify_label.text.contains("does not require comparison"), "G2 preserves direct Keep independently from comparison")
	detached.set_task(&"prediction", &"regular", true, true)
	check(detached.context_label.text.contains("Temporary session finding") and not detached.context_label.text.contains("Earned record"), "Temporary address prediction never claims persistent growth")
	detached.set_task(&"creation", &"C1_restore", false)
	detached.draft_changed(); detached.set_task(&"creation", &"C1_restore", true)
	check(detached.evidence_label.text == "Check the current plan under the existing task contract." and detached.action_label.text.begins_with("Now: "), "Same-card locale change resets earlier draft guidance in the new language")
	detached.measurement_recorded(); detached.set_task(&"creation", &"C1_restore", false)
	check(detached.evidence_label.text == "当前方案仍须按原任务核验。" and detached.verify_label.text.begins_with("核验："), "Reverse locale change resets run guidance without inventing evidence state")
	detached.set_task(&"unknown", &"unknown", true)
	check(not detached.visible, "Unknown contract hides the contextual presentation")
	detached.free()
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		root.get_node("SystemChapter").reset_test_progress()
		var hardware: Control = await open_host("res://src/hardware_foundations/hardware_foundations.tscn", "hardware_foundations/tutorial")
		hardware._start_campaign_level(&"tutorial", false); await settle()
		await card_is(hardware, "hardware_foundations/tutorial")
		hardware._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
		hardware._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
		hardware.input_a_button.button_pressed = true; hardware._run_debug()
		hardware._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
		check(not hardware.completed_levels.get(&"tutorial", false), "Incomplete tutorial cannot reveal an earned capability")
		hardware._on_connection_request(&"NOT_1", 0, &"LAMP", 0); await settle()
		check(hardware.completed_levels.get(&"tutorial", false) and hardware.journey_context.context_label.text.contains("Earned record" if locale == "en" else "已有验收记录"), "Original five tutorial actions refresh their real earned response")
		check(hardware.level_completion_overlay.yi_response_label.text.contains("NOT"), "Actual completion overlay consumes the same task response")
		await release(hardware)
		var system: Control = await open_host("res://src/system_lab/system_lab.tscn")
		system._start_level(&"cpu_speed"); await settle(); await card_is(system, "chapter_1/cpu_speed")
		system.prediction_selector.select(1); system._lock_prediction()
		system._run_official(); system._finish_playback(); await settle()
		check(not root.get_node("SystemChapter").completed_levels().get(&"cpu_speed", false) and not system.journey_context.context_label.text.contains("Earned record" if locale == "en" else "已有验收记录"), "One correct baseline remains incomplete in the real host")
		var signature: String = root.get_node("SystemChapter").receipts_for(&"cpu_speed")[0].canonical_signature()
		system.part_selectors[&"cpu"].select(1); system._on_part_selected(1, &"cpu"); changed(system)
		system._run_official(); system._finish_playback(); await settle()
		check(root.get_node("SystemChapter").completed_levels().get(&"cpu_speed", false) and system.journey_context.context_label.text.contains("Earned record" if locale == "en" else "已有验收记录"), "Second controlled run, not narrative access, earns the actual comparison")
		check(root.get_node("SystemChapter").receipts_for(&"cpu_speed")[0].canonical_signature() == signature, "Presentation retains original baseline identity")
		var wire: Dictionary = system.graph.get_connection_list()[0]
		system._on_disconnection_request(StringName(wire.from_node),int(wire.from_port),StringName(wire.to_node),int(wire.to_port)); changed(system)
		check(root.get_node("SystemChapter").receipts_for(&"cpu_speed")[0].canonical_signature() == signature, "Real wire edit marks the draft without relabeling a previously accepted comparison")
		system._start_level(&"assembly"); system._auto_connect()
		system.editor.text = "value = 0\nstore(OUTPUT[0], value)"; system._apply_program()
		system._run_official(); system._finish_playback(); await settle()
		check(not system.latest_receipt.all_passed and not root.get_node("SystemChapter").completed_levels().get(&"assembly", false), "Wrong output retains its original rejection")
		check(system.status_label.text == system.test_status_label.text, "The original failure remains visible alongside contextual guidance")
		await release(system)
		var locality: Control = await open_host("res://src/ui/main.tscn")
		locality._start_level(&"distant_reads"); await settle(); await card_is(locality, "chapter_2/distant_reads")
		locality._invalidate_current_run("controller edit"); changed(locality)
		locality._start_level(&"nearby_storage"); await settle(); await card_is(locality, "chapter_2/nearby_storage")
		await release(locality)
		var overlap: Control = await open_host("res://src/overlap_chapter/overlap_chapter.tscn")
		overlap._open_level("arrival"); await settle(); await card_is(overlap, "chapter_3/arrival")
		overlap._changed(); changed(overlap)
		var kept_position := Vector2(24,24)
		overlap.panels["mission"].position = kept_position; await settle()
		check(overlap.panels["mission"].position == kept_position, "An instrument already inside the workspace retains its player position")
		overlap.panels["toolbox"].position.x = overlap.workspace.size.x - 10; await settle()
		check(overlap.workspace.get_global_rect().encloses(overlap.panels["toolbox"].get_global_rect()), "A horizontally out-of-bounds tools instrument refits into the workspace")
		overlap._open_level("synthesis"); await settle(); await card_is(overlap, "chapter_3/synthesis")
		await release(overlap)
		var layout: Control = await open_host("res://src/layout_chapter/layout_chapter.tscn", "chapter_4/fields")
		await card_is(layout, "chapter_4/fields"); layout._changed(false); changed(layout)
		await release(layout)
		var representation: Control = await open_host("res://experiments/representation_region/region.tscn")
		await card_is(representation, "representation/mixed_scan")
		representation.run_current()
		check(not representation.support_plans.has(0), "Over-budget raw starter produces no accepted support")
		var partition: Array[Dictionary] = [{"start":0,"end":16,"codec":"rle"},{"start":16,"end":64,"codec":"raw"}]
		representation.edit_plan(partition); changed(representation); representation.run_current(); await settle()
		check(representation.support_plans.has(0) and representation.journey_context.context_label.text.contains("Earned record" if locale == "en" else "已有验收记录"), "Actual accepted representation refreshes its earned capability")
		var old_trace: String = representation.history[0].traces[0].canonical_signature()
		representation.edit_plan(Representation.initial_plan()); changed(representation)
		check(representation.support_plans.has(0) and representation.history[0].traces[0].canonical_signature() == old_trace, "Editing retains earned recipe and failed measurement without relabeling either")
		representation.change_task(1); await settle(); await card_is(representation, "representation/interior_hotspots")
		await release(representation)
		var service: Control = await open_host("res://experiments/service_plan/lab.tscn")
		await card_is(service, "service/move_state")
		var plan: Dictionary = service.plan.duplicate(true); plan.slots = 2; service.edit(plan, 0); changed(service)
		service.run_current(); await settle()
		check(not service.history.is_empty(), "Original service measurement remains the source of numerical evidence")
		service.change_task(1); await settle(); await card_is(service, "service/prompt_response")
		await release(service)
		var prediction: Control = await open_host("res://experiments/prediction/lab.tscn")
		await card_is(prediction, "prediction/regular"); prediction.run_current()
		check(not prediction.goal_met(0), "Off baseline alone creates no temporary success")
		(prediction.find_child("Rule", true, false) as OptionButton).select(1)
		prediction.edit_policy(); changed(prediction); prediction.run_current(); await settle()
		check(prediction.goal_met(0) and prediction.journey_context.context_label.text.contains("Temporary session finding" if locale == "en" else "本次临时发现"), "Real useful prediction is labeled as a session finding")
		prediction.change_task(1); await settle(); await card_is(prediction, "prediction/changed")
		await release(prediction)
		var creation: Control = await open_host("res://experiments/creation/workbench.tscn")
		creation.session.close()
		var opened: Dictionary = creation.session.open("user://full-journey-creation-" + locale + ".json")
		check(opened.get("writable", false), "Creation fixture owns an isolated candidate profile")
		creation.task = 0; creation.build(); await settle(); await card_is(creation, "creation/C1_restore")
		creation.train_model(); creation.transport("predictive"); await settle()
		check(creation.session.data.supports.has("C1_restore") and creation.journey_context.context_label.text.contains("Earned record" if locale == "en" else "已有验收记录"), "Real learned predictive restoration reveals C1 capability")
		var supports: Dictionary = creation.session.data.supports.duplicate(true)
		creation.session.data.draft.seed += 1; creation.edit_draft(); changed(creation)
		check(creation.session.data.supports == supports, "A draft edit does not fabricate or rewrite prior accepted support")
		creation.change_task(7); await settle(); await card_is(creation, "creation/G2_intent")
		await release(creation)
	var after: Dictionary = save._save_snapshot(); after.erase("saved_at_utc")
	check(after == before, "Context, Test-mode controller work and temporary prediction do not modify ordinary campaign progress")
	await check_card_layout()
	if not captures.is_empty():
		var receipt := FileAccess.open("res://.godot/full-journey-context-captures/receipt.json", FileAccess.WRITE)
		receipt.store_string(JSON.stringify({"grade":"rendered host UI with disclosed controller/signal actions, not native input", "captures":captures}, "\t")); receipt.close()
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "full journey narrative (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)

func check_card_layout() -> void:
	var canvas := Control.new(); canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(canvas)
	var scroll := ScrollContainer.new(); scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus = true; canvas.add_child(scroll)
	var card := Card.new(); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(card)
	for locale: String in ["zh_CN", "en"]:
		for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1440,900)]:
			root.size = dimensions; root.content_scale_size = dimensions
			card.set_task(&"creation", &"G2_intent", locale == "en")
			await settle()
			check(root.get_visible_rect().encloses(card.action_label.get_global_rect()) and root.get_visible_rect().encloses(card.verify_label.get_global_rect()), "Direct first action and verification fit " + locale + " " + str(dimensions))
			card.toggle.grab_focus(); card.toggle.button_pressed = true; await settle()
			check(card.details.visible and root.gui_get_focus_owner() == card.toggle, "Context expands without taking input focus")
			card.set_task(&"creation", &"G3_keep", locale == "en")
			check(not card.details.visible and not card.toggle.button_pressed, "A changed contract collapses prior context")
	canvas.queue_free(); await settle()

func capture_host_context(scene: Control) -> void:
	if not "--full-journey-capture" in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless", "Host capture requires a real renderer")
	if DisplayServer.get_name() == "headless": return
	var card: Variant = scene.journey_context
	var action: Control = scene.next_step_label if card.last_task.begins_with("creation/") else card.action_label
	if "--service-context-capture" in OS.get_cmdline_user_args() and not card.last_task.begins_with("service/"): return
	if "--hardware-en-capture" in OS.get_cmdline_user_args() and (not card.english or not card.last_task.begins_with("hardware_foundations/")): return
	if "--service-context-capture" in OS.get_cmdline_user_args():
		scene.hint_open = true; scene.refresh_mission(); scene.run_current(); scene.pin_comparison(); await settle()
	var domain_key: String = str(card.english) + "/" + card.last_task.get_slice("/", 0)
	if captured_domains.has(domain_key): return
	captured_domains[domain_key] = true
	var ancestor: Node = card
	while ancestor != null and ancestor != scene:
		var parent: Node = ancestor.get_parent()
		if parent is TabContainer: parent.current_tab = ancestor.get_index()
		if ancestor.has_method("show_instrument"):
			ancestor.call("show_instrument"); ancestor.call("set_minimized", false)
		ancestor = parent
	var folder: String = "res://.godot/full-journey-context-captures"
	check(DirAccess.make_dir_recursive_absolute(folder) == OK, "Host capture folder exists")
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1440,900)]:
		root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
		await settle()
		if card.last_task.begins_with("chapter_1/"):
			for button: Button in scene.instrument_open_buttons.values(): check(within_clip(button), "System instrument launcher fits after toolbar wrapping: " + button.text)
			for panel: Control in scene.instrument_windows.values():
				if panel.visible: check(root.get_visible_rect().encloses(panel.get_global_rect()), "Visible System instrument fits after toolbar resize")
		if card.last_task.begins_with("chapter_3/"):
			for panel: Control in scene.panels.values():
				if panel.visible: check(root.get_visible_rect().encloses(panel.get_global_rect()), "Visible Overlap instrument fits after viewport resize")
		ancestor = card.get_parent()
		while ancestor != null and ancestor != scene:
			if ancestor is ScrollContainer: ancestor.scroll_vertical = 0
			ancestor = ancestor.get_parent()
		await settle(); RenderingServer.force_draw(false); await process_frame
		var prefix: String = card.last_task.replace("/", "-") + ("-en-" if card.english else "-zh-") + "%dx%d" % [dimensions.x,dimensions.y]
		var default_path: String = folder.path_join(prefix + "-default.png")
		check(root.get_texture().get_image().save_png(default_path) == OK, "Actual default Mission/evidence frame captured")
		check(within_clip(action) and within_clip(card.verify_label), "Default Mission exposes the current action and verification without scrolling: " + domain_key + " " + str(dimensions))
		ancestor = card.get_parent()
		while ancestor != null and ancestor != scene:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(card.verify_label)
			ancestor = ancestor.get_parent()
		await settle(); RenderingServer.force_draw(false); await process_frame
		check(within_clip(action) and within_clip(card.verify_label), "Located host guidance remains within its actual viewport and scroll clip: " + domain_key)
		var path: String = folder.path_join(prefix + ".png")
		check(root.get_texture().get_image().save_png(path) == OK, "Real Mission/evidence context captured: " + path)
		if "--service-context-capture" in OS.get_cmdline_user_args():
			check(within_clip(scene.response_chart), "Service first-response evidence remains within its actual scroll clip beside guidance")
			if dimensions == Vector2i(1280,720):
				for tab: int in 4:
					scene.evidence_tabs.current_tab = tab; await settle()
					var evidence: Array = [scene.measured_source,scene.summary,scene.response_chart,scene.response_play,scene.response_step] if tab == 0 else ([scene.event_source,scene.event_raw_button,scene.tree,scene.detail] if tab == 1 else ([scene.public_detail] if tab == 2 else [scene.pin_button,scene.comparison_detail,scene.comparison_chart]))
					for item: Control in evidence: check(within_clip(item), "Service Hint-enabled tab evidence stays within actual clip: " + str(tab))
					RenderingServer.force_draw(false); await process_frame
					check(root.get_texture().get_image().save_png(folder.path_join(prefix + "-hint-tab%d.png" % tab)) == OK, "Service Hint-enabled evidence tab captured")
				scene.evidence_tabs.current_tab = 0; await settle()
		captures.append({"file":path,"sha256":FileAccess.get_sha256(path),"default_file":default_path,"default_sha256":FileAccess.get_sha256(default_path),"task":card.last_task,"scene":scene.scene_file_path,"locale":"en" if card.english else "zh_CN","dimensions":str(dimensions),"action_source":"existing next_step_label" if card.last_task.begins_with("creation/") else "JourneyContextCard.action_label","action_rect":str(action.get_global_rect()),"verify_rect":str(card.verify_label.get_global_rect()),"font_size":card.verify_label.get_theme_font_size("font_size")})

func within_clip(control: Control) -> bool:
	if not control.is_visible_in_tree(): return false
	var clip: Rect2 = root.get_visible_rect()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents: clip = clip.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return clip.grow(1).encloses(control.get_global_rect())
