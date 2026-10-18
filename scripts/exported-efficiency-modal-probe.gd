extends "./night-package-probe.gd"
## Exported game-mode controller in a cloned accepted QA namespace; not native input.
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const CreationSession = preload("res://experiments/creation/session.gd")
var root: Window
var capture: bool = true
var ordered_checks: Array[Dictionary] = []

func check(ok: bool, label: String) -> void:
	ordered_checks.append({"label":label,"passed":ok})
	super.check(ok,label)

func fixture_settle() -> void:
	for frame: int in 8: await get_tree().process_frame

func fixture_key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = down
	Input.parse_input_event(event)

func fixture_stroke(code: Key) -> void:
	fixture_key(code, true); await fixture_settle(); fixture_key(code, false); await fixture_settle()

func fully_visible(control: Control) -> bool:
	if not control.is_visible_in_tree(): return false
	var visible_rect: Rect2 = control.get_viewport().get_visible_rect()
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents:
			visible_rect = visible_rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return control.size.x > 0 and control.size.y > 0 and visible_rect.grow(1).encloses(control.get_global_rect())

func protected_state() -> Dictionary:
	var disk: Dictionary = {}
	for path: String in ["user://savegame_v1.json", "user://savegame_v1.json.bak", "user://hardware_workbenches_v1.json", CreationSession.launch_path()]:
		disk[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	var game: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	game.erase("saved_at_utc")
	var nav: Node = root.get_node("TaskNavigation")
	var chapter: Node = root.get_node("SystemChapter")
	var receipts: Array[String] = []
	for record: Variant in chapter.receipts_for(&"cpu_speed"): receipts.append(record.canonical_signature())
	return {"disk":disk,"game":game,"best":root.get_node("PersonalRecords").best.duplicate(true),
		"completed":chapter.completed_levels().duplicate(true),"receipts":receipts,
		"lease":DirAccess.dir_exists_absolute(Lease.lock_path(CreationSession.launch_path())),
		"recovery_lease":DirAccess.dir_exists_absolute(Lease.lock_path(CreationSession.launch_path())+".recovering"),
		"nav":{"selected":nav.selected,"pending":nav.pending,"from_tree":nav.from_tree}}

func capture_frame(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path: String = "user://efficiency-fragment-captures/"+name+".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	check(root.get_texture().get_image().save_png(path) == OK, "Actual efficiency frame saved: "+name)

func begin_history(main: Control) -> void:
	main._dismiss_level_completion()
	for id: StringName in main.instrument_windows: main._close_instrument(id)
	main._open_instrument(&"history")
	var scroll: ScrollContainer = main.history_chart.get_parent().get_parent()
	scroll.scroll_vertical = 0
	main.efficiency_fragment.collapse()
	await fixture_settle()

func feedback_stack(main: Control, tester: bool, suffix: String) -> void:
	var diagnostic_host: WeakRef = weakref(main)
	check(bool(ProjectSettings.get_setting("playtest/offline_tester",false)) == tester,"Actual exported package retains its original feedback role")
	var offline: Node = root.get_node("OfflineFeedback")
	offline.toolbar.visible = tester
	var moments: Node = root.get_node("PlaytestMoments")
	var fragment: Variant = main.efficiency_fragment
	await begin_history(main)
	check(ProjectSettings.get_setting("playtest/offline_tester",false) == tester and not offline.toolbar.visible, "Current role uses the actual local feedback entry without a duplicate footer: "+suffix)
	fragment.toggle_button.grab_focus(); await fixture_stroke(KEY_SPACE)
	fragment.step_buttons[1].grab_focus(); await fixture_stroke(KEY_SPACE)
	fragment.step_buttons[1].pressed.emit()
	var exact_focus: Control = root.gui_get_focus_owner()
	var original_state: Dictionary = protected_state()
	var requested_step: int = fragment.step
	var scroll: ScrollContainer = main.history_chart.get_parent().get_parent()
	var requested_scroll: int = scroll.scroll_vertical
	var previous_pause: bool = get_tree().paused
	fixture_key(KEY_F8, true)
	# Parsed input is accepted in the next dispatch cycle; tester capture then awaits post_draw.
	await get_tree().process_frame
	await RenderingServer.frame_pre_draw
	check(fragment._feedback_active(), "Real F8 establishes feedback or capture-busy priority before drawing")
	if tester:
		check(offline.busy, "Actual tester capture-busy boundary is observed before frame_post_draw")
		check(not root.get_node("PlaytestData")._feedback_visible and not offline.panel.is_visible_in_tree(), "Busy capture is tested before the tester overlay takes focus")
	check(fragment.step == requested_step and fragment.visual_blend < 1.0, "Accepted F8 interrupts the original unfinished observation")
	check(scroll.scroll_vertical == requested_scroll, "Accepting feedback does not scroll the original observation")
	var original_step: int = fragment.step
	var original_blend: float = fragment.visual_blend
	var original_scroll: int = scroll.scroll_vertical
	print("EFFICIENCY_ACCEPTED_INPUT: ",JSON.stringify({"scope":suffix,"process_frame":Engine.get_process_frames(),
		"draw_frame":Engine.get_frames_drawn(),"active":fragment._feedback_active(),"busy":offline.busy,
		"feedback_flag":root.get_node("PlaytestData")._feedback_visible,"paused":get_tree().paused,
		"step":original_step,"blend":original_blend,"scroll":original_scroll}))
	fragment._select_step(2)
	check(fragment.step == original_step, "A capture-busy or open feedback cannot advance the candidate fragment")
	fixture_key(KEY_F8, false); await fixture_settle()
	var panel: Control = offline.panel if tester else moments.panel
	check((offline.backdrop.visible if tester else moments.panel.visible) and panel.is_visible_in_tree() and panel.get_viewport() == root, "Actual role-specific F8 panel opens in the history viewport")
	check(panel.is_ancestor_of(root.gui_get_focus_owner()), "Feedback owns the real keyboard focus")
	check(fragment.visual_blend == original_blend and scroll.scroll_vertical == original_scroll and fragment.step == original_step, "Feedback suspends local fading and never scrolls or advances the original observation")
	check(get_tree().paused if tester else get_tree().paused == previous_pause, "Role-specific feedback retains its original pause contract")
	if tester:
		check(not offline.current.is_empty() and offline.current.get("screenshot_status", "") == "captured", "Tester records an actual pre-overlay efficiency scene")
	await capture_frame(suffix+"-feedback")
	await fixture_stroke(KEY_ESCAPE)
	check(not (offline.backdrop.visible if tester else moments.panel.visible) and not panel.is_visible_in_tree() and fragment.body.visible and not main.map_host.visible, "First Escape closes feedback only, retaining the expanded history fragment")
	check(not offline.toolbar.visible, "Closing either role keeps the duplicate footer away from original controls: "+suffix)
	check(root.gui_get_focus_owner() == exact_focus and get_tree().paused == previous_pause, "Feedback returns exact fragment focus and restores the original pause state")
	await fixture_stroke(KEY_ESCAPE)
	check(not fragment.body.visible and root.gui_get_focus_owner() == fragment.toggle_button and not main.map_host.visible, "Second Escape collapses only the genuinely focused fragment")
	check(protected_state() == original_state, "Fragment and both feedback channels preserve original game, workbench, works, leases, receipts and navigation")
	await fixture_stroke(KEY_ESCAPE)
	exported_host_diagnostic("after_third_escape",diagnostic_host)
	var navigation: Node = get_node("/root/TaskNavigation")
	var scene: Node = get_tree().current_scene
	check(is_instance_valid(scene) and scene.scene_file_path == "res://src/campaign/task_tree.tscn" and navigation.selected == "chapter_1/cpu_speed" and navigation.pending.is_empty() and not is_instance_valid(diagnostic_host.get_ref()), "After fragment collapse Escape follows the actual exported journey route and releases its old Host")
	exported_host_diagnostic("after_actual_exported_return",diagnostic_host)

func embedded_focus_boundary(main: Control, locale: String) -> void:
	if not capture: return
	await begin_history(main)
	var fragment: Variant = main.efficiency_fragment
	var scroll: ScrollContainer = main.history_chart.get_parent().get_parent()
	var before: Dictionary = protected_state()
	DirAccess.make_dir_recursive_absolute("user://efficiency-fragment-captures")
	fragment.toggle_button.grab_focus(); await fixture_settle()
	scroll.scroll_vertical = 0; await fixture_settle()
	check(scroll.scroll_vertical == 0, "The real History positive control starts at scroll zero")
	fragment.toggle_button.button_pressed = true; await fixture_settle()
	print("EFFICIENCY_REVEAL_POSITIVE_CONTROL: ",JSON.stringify({"locale":locale,"scroll_before":0,"scroll_after":scroll.scroll_vertical,
		"scroll_max":scroll.get_v_scroll_bar().max_value,"scroll_page":scroll.get_v_scroll_bar().page,
		"viewport_rect":str(root.get_visible_rect()),"scroll_rect":str(scroll.get_global_rect()),
		"source_rect":str(fragment.source_label.get_global_rect()),"step_rect":str(fragment.step_buttons[0].get_global_rect()),
		"metric_rect":str(fragment.metric_label.get_global_rect())}))
	check(scroll.scroll_vertical > 0 and fully_visible(fragment.source_label) and fully_visible(fragment.step_buttons[0]) and fully_visible(fragment.metric_label), "Without another Window, actual expansion moves the reading region and reveals its source, step and metric")
	check(root.get_texture().get_image().save_png("user://efficiency-fragment-captures/"+locale+"-modal-positive.png") == OK,"Exported actual positive reveal frame: "+locale)
	fragment.collapse(); await fixture_settle()
	scroll.scroll_vertical = 0; await fixture_settle()
	var pending_scroll: int = scroll.scroll_vertical
	check(pending_scroll == 0, "Modal negative control uses the same real scroll-zero starting point")
	fragment.toggle_button.button_pressed = true
	check(get_tree().process_frame.is_connected(fragment._reveal_body), "Actual efficiency expansion schedules one pending reveal before Window focus moves")
	fragment._select_step(1)
	var held_blend: float = fragment.visual_blend
	var held_step: int = fragment.step
	check(fragment.body.visible and held_blend < 1.0, "Focus boundary begins with a real expanded unfinished observation")
	var blocker := AcceptDialog.new()
	blocker.title = "QA efficiency focus boundary"
	root.add_child(blocker)
	var other := Button.new(); other.text = "Other window"; blocker.add_child(other)
	blocker.popup_centered(Vector2i(240,100)); blocker.grab_focus(); other.grab_focus(); await fixture_settle()
	var root_focus: Control = root.gui_get_focus_owner()
	var blocker_focus: Control = blocker.gui_get_focus_owner()
	var embedded: Array[String] = []
	for window: Window in root.get_embedded_subwindows(): embedded.append(str(window.get_path()))
	print("EFFICIENCY_WINDOW_FOCUS_DIAGNOSTIC: ",JSON.stringify({"locale":locale,
		"root":{"has_focus":root.has_focus(),"visible":root.visible,"window_id":root.get_window_id(),"embedded":root.is_embedded()},
		"blocker":{"has_focus":blocker.has_focus(),"visible":blocker.visible,"window_id":blocker.get_window_id(),"embedded":blocker.is_embedded(),"transient":blocker.transient,"exclusive":blocker.exclusive},
		"root_focus_owner":str(root_focus.get_path()) if is_instance_valid(root_focus) else "none",
		"blocker_focus_owner":str(blocker_focus.get_path()) if is_instance_valid(blocker_focus) else "none",
		"embedded_windows":embedded,"listed_embedded":root.get_embedded_subwindows().has(blocker),
		"scroll_before":pending_scroll,"scroll_after":scroll.scroll_vertical,"blend_before":held_blend,"blend_after":fragment.visual_blend,
		"scroll_max":scroll.get_v_scroll_bar().max_value,"scroll_page":scroll.get_v_scroll_bar().page,
		"scroll_rect":str(scroll.get_global_rect()),"source_rect":str(fragment.source_label.get_global_rect()),"metric_rect":str(fragment.metric_label.get_global_rect()),
		"step_before":held_step,"step_after":fragment.step,"feedback_active":fragment._feedback_active()}))
	check(blocker.visible and blocker.has_focus() and blocker_focus == other and (root.get_embedded_subwindows().has(blocker) if blocker.is_embedded() else not root.has_focus()), "Actual modal owns its Other button with the real embedded or native focus semantics")
	if blocker.is_embedded(): print("NOT_RUN: native OS focus loss; efficiency boundary uses a focused embedded modal Window")
	check(scroll.scroll_vertical == pending_scroll, "Pending efficiency reveal cannot scroll its original reading region while another Window owns focus")
	check(fragment.visual_blend == held_blend and fragment.step == held_step, "Another focused Window pauses the unfinished efficiency observation")
	var escape := InputEventKey.new(); escape.keycode = KEY_ESCAPE; escape.pressed = true
	main._unhandled_key_input(escape)
	var authority_unchanged: bool = protected_state() == before
	print("EFFICIENCY_MODAL_ESCAPE_RESULT: ",JSON.stringify({"locale":locale,"body_visible":fragment.body.visible,"authority_unchanged":authority_unchanged,"map_visible":main.map_host.visible}))
	check(fragment.body.visible and authority_unchanged, "An unfocused efficiency Host cannot collapse its fragment or change authority")
	check(not main.map_host.visible,"The actual modal Host Escape does not open its map")
	check(root.get_texture().get_image().save_png("user://efficiency-fragment-captures/"+locale+"-modal-negative.png") == OK,"Exported actual focused modal frame: "+locale)
	blocker.queue_free(); await fixture_settle()
	fragment.collapse()
	check(protected_state() == before, "Modal focus and its natural destruction preserve the original complete authority")

func prepare_cpu(output: String, tester: bool):
	var chapter: Node = get_node("/root/SystemChapter")
	var host: Variant = await measured_host("res://src/system_lab/system_lab.tscn","chapter_1/assembly")
	if host==null: return
	if not measured_require(host.current_level_id==&"assembly","Measured real hardware gate permits System assembly"): return
	host._auto_connect(); host._run_official(); host._finish_playback(); await settle()
	if not measured_require(host.graph.get_connection_list().size()==6 and host.latest_receipt!=null and host.latest_receipt.all_passed and chapter.completed_levels().get(&"assembly",false),"Measured original six-route assembly passes official cases before CPU entry"): return
	experience["measured_assembly_preparation"]={"receipt_signature":host.latest_receipt.canonical_signature(),"metrics":host.latest_receipt.metrics.duplicate(true),"topology_signature":host._topology_from_graph().canonical_signature(),"program_signature":host.latest_receipt.program_signature,"test_set_signature":host.latest_receipt.test_set_signature,"source":host.applied_program_source,"parts":host.selected_part_ids.duplicate(true)}
	host._dismiss_level_completion(); host._start_level(&"cpu_speed"); await settle()
	if not measured_require(host.current_level_id==&"cpu_speed" and host.prediction_selector.item_count>1 and host.part_selectors[&"cpu"].item_count>1,"Measured CPU task is legally initialized before any selection"): return
	host.prediction_selector.select(1); host._lock_prediction()
	host._run_official(); host._finish_playback(); await settle()
	if not measured_require(chapter.receipts_for(&"cpu_speed").size()==1 and not chapter.completed_levels().get(&"cpu_speed",false) and not host.efficiency_fragment.visible,"Measured single actual reference run supplies no comparison"): return
	host.part_selectors[&"cpu"].select(1); host._on_part_selected(1,&"cpu")
	host._run_official(); host._finish_playback(); await settle()
	var receipts: Array = chapter.receipts_for(&"cpu_speed")
	if not measured_require(receipts.size()==2 and receipts[0].all_passed and receipts[1].all_passed and chapter.completed_levels().get(&"cpu_speed",false),"Measured owned CPU pair is accepted only after two real official model runs"): return
	if receipts.size()!=2: host.queue_free(); await settle(); return
	var fragment: Variant = host.efficiency_fragment
	if not measured_require(fragment.before.metrics==receipts[0].metrics and fragment.after.metrics==receipts[1].metrics and not fragment.body.visible,"Measured fragment derives exactly the original pair without autoplay"): return
	check(host.history_chart.samples[0]==receipts[0].metrics and host.history_chart.samples[1]==receipts[1].metrics,"Measured original comparison chart retains the same two actual samples")
	host._dismiss_level_completion()
	for id: StringName in host.instrument_windows: host._close_instrument(id)
	host._open_instrument(&"history"); await settle()
	experience["measured_cpu_prepared"] = measured_flush()
	experience["measured_cpu_pair"]={"before":host._efficiency_record(receipts[0]),"after":host._efficiency_record(receipts[1]),"scope":"real game-mode official CPU runs after controller-wired and officially sealed hardware; QA solved setup, not unaided player progress"}
	return host

func exported_host_diagnostic(stage: String, reference: WeakRef, requested_locale: String = "", locale_result: Variant = null) -> void:
	var main: Variant = reference.get_ref()
	var valid: bool = is_instance_valid(main)
	var inside: bool = valid and main.is_inside_tree()
	var scene: Node = get_tree().current_scene
	var chapter: Node = get_node("/root/SystemChapter")
	var nav: Node = get_node("/root/TaskNavigation")
	var cpu_receipts: Array[Dictionary] = []
	for receipt: Variant in chapter.receipts_for(&"cpu_speed"):
		if receipt != null: cpu_receipts.append({"signature":receipt.canonical_signature(),"program_signature":receipt.program_signature,"test_set_signature":receipt.test_set_signature,"all_passed":receipt.all_passed})
	var state: Dictionary = {"valid":valid,"inside_tree":inside,"queued":main.is_queued_for_deletion() if valid else null}
	if inside:
		var level: StringName = main.current_level_id
		var program: String = main.applied_program.canonical_signature() if main.applied_program != null and main.applied_program.is_valid() else ""
		var test_set: String = main.catalog.test_set_signature(level) if not level.is_empty() else ""
		var filtered: Array = []
		var receipt_rows: Array[Dictionary] = []
		for receipt: Variant in chapter.receipts_for(level):
			if receipt == null: continue
			var accepted: bool = receipt.all_passed and receipt.test_set_signature == test_set and (program.is_empty() or receipt.program_signature == program)
			receipt_rows.append({"signature":receipt.canonical_signature(),"accepted_by_history_filter":accepted})
			if accepted: filtered.append(receipt)
		var kind := StringName(main.current_level_definition.get("comparison_kind",&"none"))
		var pair: Array = main._latest_controlled_pair(filtered,kind)
		var fragment: Variant = main.efficiency_fragment
		var records: Dictionary = {}
		if is_instance_valid(fragment):
			for endpoint: String in ["before","after"]:
				var record: Dictionary = fragment.get(endpoint)
				records[endpoint] = {"level_id":record.get("level_id"),"source":record.get("source"),"program_signature":record.get("program_signature"),"test_set_signature":record.get("test_set_signature"),"topology_signature":record.get("topology_signature"),"part_ids":record.get("part_ids")}
		state.merge({"path":str(main.get_path()),"current_level":String(level),"comparison_kind":String(kind),
			"map_visible":main.map_host.visible if is_instance_valid(main.map_host) else null,"lab_visible":main.lab_host.visible if is_instance_valid(main.lab_host) else null,
			"cpu_unlocked":main.catalog.is_unlocked(&"cpu_speed",chapter.completed_levels(),chapter.prologue_ready,get_node("/root/GameMode").is_test_mode() or nav.offline_tester_enabled()),
			"current_program_signature":program,"current_test_set_signature":test_set,"current_level_receipts":receipt_rows,"filtered_count":filtered.size(),"controlled_pair_size":pair.size(),
			"fragment_valid":is_instance_valid(fragment),"fragment_english":fragment.english if is_instance_valid(fragment) else null,
			"fragment_visible":fragment.is_visible_in_tree() if is_instance_valid(fragment) else null,"fragment_pair_valid":fragment._valid_pair(fragment.before,fragment.after) if is_instance_valid(fragment) else null,"fragment_records":records})
	print("EXPORTED_EFFICIENCY_HOST_DIAGNOSTIC: ",JSON.stringify({"stage":stage,"requested_locale":requested_locale,"set_locale_return":locale_result,
		"actual_locale":get_node("/root/Localization").current_locale(),"ticks_msec":Time.get_ticks_msec(),"process_frame":Engine.get_process_frames(),"draw_frame":Engine.get_frames_drawn(),
		"current_scene":{"valid":is_instance_valid(scene),"inside_tree":scene.is_inside_tree() if is_instance_valid(scene) else false,"path":scene.scene_file_path if is_instance_valid(scene) else null},
		"host":state,"cpu_receipts":cpu_receipts,"prologue_ready":chapter.prologue_ready,"navigation":{"from_tree":nav.from_tree,"pending":nav.pending}}))

func run() -> void:
	root = get_tree().root
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var output: String = str(ProjectSettings.get_setting("qa_night/output",""))
	if output.is_empty() or not OS.get_environment("APPDATA").replace("\\","/").contains("/.godot/exported-efficiency-modal/"):
		get_tree().quit(2); return
	get_tree().current_scene = null
	var seed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("seed.json")))
	var tester: bool = bool(ProjectSettings.get_setting("playtest/offline_tester",false))
	var profile: String = str(ProjectSettings.get_setting("candidate/profile",""))
	var save: Node = get_node("/root/GlobalSave")
	if not measured_require(profile == ("OfflineTeammate-CreationLinks20261018" if tester else "CreationLinks20261018") and tester == bool(seed.tester),"Exported efficiency retains its exact original role and profile"): return
	if not measured_require(DisplayServer.get_name() != "headless" and save.loaded_save and save.disk_write_allowed and not get_node("/root/GameMode").is_test_mode(),"Exported efficiency loads its own accepted seed in original game mode"): return
	if not measured_require(OS.has_feature("free_candidate") and get_node("/root/TaskNavigation").journey_tasks().size() == 60 and OS.get_user_data_dir().replace("\\","/").ends_with("/VonNeumannBottleneckCandidates/representation/"+profile),"Exported focus fixture uses the actual PCK and exact embedded namespace"): return
	if not measured_require(get_node("/root/RemoteFeedback").endpoint.is_empty() and not get_node("/root/RemoteFeedback").enabled,"Exported focus fixture retains the original empty receiver and disabled upload"): return
	var before: Dictionary = protected_snapshot()
	if not measured_require(measured_json_equal(before.game_state,seed.initial_game_state) and measured_original_work(seed),"Exported efficiency loaded seed and whole original work remain exact"): return
	var official: Array[Dictionary] = []
	var remote: Script = load("res://src/playtest/remote_feedback.gd")
	get_node("/root/PlaytestData").official_result.connect(func(event: Dictionary) -> void: official.append({"event":event.duplicate(true),"safe":remote.minimal_context(event)}))
	var initial_best: Dictionary = get_node("/root/PersonalRecords").best.duplicate(true)
	if not await measured_hardware(seed): return
	var main: Variant = await prepare_cpu(output,tester)
	if not measured_require(is_instance_valid(main) and failures.is_empty(),"Exported efficiency has a legally prepared live System Host"): return
	experience["measured_targets"] = {"status":"NOT_RUN_FOCUS_SCOPE" if tester else "NOT_RUN_NORMAL_LOCKED","scope":"No Layout or Overlap execution in this focus-only fixture, for either role"}
	check(root.get_visible_rect().size == Vector2(1280,720),"Exported modal fixture uses the original explicit 1280 by 720 logical test window")
	var original_locale: String = get_node("/root/Localization").current_locale()
	var role_snapshots: Array[Dictionary] = []
	var diagnostic_main: WeakRef = weakref(main)
	var chapter: Node = get_node("/root/SystemChapter")
	var original_receipt_signatures: Array[String] = []
	for receipt: Variant in chapter.receipts_for(&"cpu_speed"): original_receipt_signatures.append(receipt.canonical_signature())
	var production_resources: Dictionary = {}
	for locale: String in ["zh_CN","en"]:
		exported_host_diagnostic("before_set_locale",diagnostic_main,locale)
		var locale_accepted: bool = get_node("/root/Localization").set_locale(locale)
		exported_host_diagnostic("after_set_locale_before_history",diagnostic_main,locale,locale_accepted)
		main = await measured_host("res://src/system_lab/system_lab.tscn","chapter_1/cpu_speed")
		if not measured_require(is_instance_valid(main) and main.is_inside_tree() and get_tree().current_scene == main and main.current_level_id == &"cpu_speed", "Actual exported locale reenters its live original CPU Host: "+locale): return
		diagnostic_main = weakref(main)
		var current_receipt_signatures: Array[String] = []
		for receipt: Variant in chapter.receipts_for(&"cpu_speed"): current_receipt_signatures.append(receipt.canonical_signature())
		check(current_receipt_signatures == original_receipt_signatures and current_receipt_signatures.size() == 2,"Actual locale reentry retains the exact two original official receipts: "+locale)
		var resources: Dictionary = {"fragment":main.efficiency_fragment.get_script().resource_path,"host":main.get_script().resource_path}
		if production_resources.is_empty(): production_resources = resources.duplicate(true)
		check(resources == production_resources,"Both locale Hosts load the same original PCK production scripts: "+locale)
		exported_host_diagnostic("after_actual_locale_reentry",diagnostic_main,locale,locale_accepted)
		main._refresh_history()
		exported_host_diagnostic("after_original_refresh_history",diagnostic_main,locale,locale_accepted)
		check(main.efficiency_fragment.english == (locale == "en"),"Actual exported fragment uses the requested language: "+locale)
		await fixture_settle()
		var role_before: bool = bool(ProjectSettings.get_setting("playtest/offline_tester",false))
		var role_had_setting: bool = ProjectSettings.has_setting("playtest/offline_tester")
		var role_original_value: Variant = ProjectSettings.get_setting("playtest/offline_tester",null)
		await embedded_focus_boundary(main,locale)
		if not failures.is_empty(): get_tree().quit(1); return
		await feedback_stack(main,tester,locale+"-exported-"+("tester" if tester else "ordinary"))
		role_snapshots.append({"locale":locale,"before":{"has_setting":role_had_setting,"value":role_original_value},"after":{"has_setting":ProjectSettings.has_setting("playtest/offline_tester"),"value":ProjectSettings.get_setting("playtest/offline_tester",null)}})
		check(ProjectSettings.has_setting("playtest/offline_tester") == role_had_setting and ProjectSettings.get_setting("playtest/offline_tester",null) == role_original_value and bool(ProjectSettings.get_setting("playtest/offline_tester",false)) == role_before and role_before == tester,"Exported efficiency fixture never changes the original package role or setting presence: "+locale)
		if not failures.is_empty(): get_tree().quit(1); return
	get_node("/root/Localization").set_locale(original_locale)
	check(not is_instance_valid(diagnostic_main.get_ref()) and get_tree().current_scene.scene_file_path == "res://src/campaign/task_tree.tscn","Both locale feedback routes finish at the real map without retaining a dead Host")
	experience["measured_system_workspaces"] = {"assembly":chapter.workspace_for(&"assembly"),"cpu_speed":chapter.workspace_for(&"cpu_speed")}
	var final: Dictionary = measured_flush()
	if final.is_empty(): return
	check(measured_original_work(seed) and not get_node("/root/GameMode").is_test_mode(),"Exported focus preparation and review preserve the original CPG session and game-mode boundary")
	var receipt: Dictionary = {"checks":checks,"role_snapshots":role_snapshots,"logical_viewport":var_to_str(root.get_visible_rect().size),"physical_frame":var_to_str(root.get_texture().get_image().get_size()),"check_calls":ordered_checks.size(),"ordered_checks":ordered_checks,"failures":failures,"source_commit":ProjectSettings.get_setting("application/config/build_commit",""),
		"build_id":ProjectSettings.get_setting("application/config/version",""),"profile":profile,"tester":tester,
		"exe_sha256":FileAccess.get_sha256(OS.get_executable_path()),"controller_sha256":FileAccess.get_sha256(get_script().resource_path),
		"base_controller_sha256":FileAccess.get_sha256(get_script().resource_path.get_base_dir().path_join("night-package-probe.gd")),
		"fixture_source_sha256":seed.fixture_source_sha256,"parent_controller_sha256":seed.parent_controller_sha256,"protected_before":before,
		"prepared_cpu":experience.measured_cpu_prepared,"prepared_final":final,"initial_best":initial_best,"official_events":official,
		"original_work":seed.original_saved_work.work,"original_work_session_sha256":FileAccess.get_sha256(CreationSession.launch_path()),
		"creation_recovery_lock":measured_state().creation_recovery_lock,"extended_experience":experience,
		"production_resources":production_resources,
		"evidence_grade":"actual PCK game-mode focus fixture in cloned accepted data, legal official hardware preparation; not canonical whole-suite or native input"}
	var file := FileAccess.open(output.path_join("measured-evidence.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt,"\t",true,true)); file.close()
	print(("PASS" if failures.is_empty() else "FAIL")+": Exported efficiency modal evidence")
	get_tree().quit(0 if failures.is_empty() else 1)
