extends SceneTree
## Actual official System-model runs in isolated Test mode; not a player-built prologue.
const Fragment = preload("res://src/ui/efficiency_fragment.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const CreationSession = preload("res://experiments/creation/session.gd")
var failures: Array[String] = []
var checks: int = 0
var capture: bool = false

func _init() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame: int in 8: await process_frame

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = down
	Input.parse_input_event(event)

func stroke(code: Key) -> void:
	key(code, true); await settle(); key(code, false); await settle()

func fully_visible(control: Control) -> bool:
	if not control.is_visible_in_tree(): return false
	var visible_rect: Rect2 = control.get_viewport().get_visible_rect()
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents:
			visible_rect = visible_rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return control.size.x > 0 and control.size.y > 0 and visible_rect.grow(1).encloses(control.get_global_rect())

func phase_trace(tag: String, scope: String, fragment: Control, offline: Node, moments: Node, scroll: ScrollContainer) -> void:
	var focus: Control = root.gui_get_focus_owner()
	print("EFFICIENCY_INPUT_PHASE: ",JSON.stringify({"tag":tag,"scope":scope,
		"process_frame":Engine.get_process_frames(),"draw_frame":Engine.get_frames_drawn(),
		"f8_physical":Input.is_physical_key_pressed(KEY_F8),"f8_key":Input.is_key_pressed(KEY_F8),
		"f8_action":Input.is_action_pressed("vnb_offline_feedback"),"f8_just_pressed":Input.is_action_just_pressed("vnb_offline_feedback"),
		"accumulated_input":Input.use_accumulated_input,"root_focus":root.has_focus(),"paused":paused,
		"feedback_flag":root.get_node("PlaytestData")._feedback_visible,"offline_enabled":offline.enabled(),"busy":offline.busy,
		"offline_backdrop":offline.backdrop.visible,"offline_panel_tree":offline.panel.is_visible_in_tree(),
		"moments_panel":moments.panel.visible,"moments_panel_tree":moments.panel.is_visible_in_tree(),
		"fragment_can_process":fragment.can_process(),"fragment_step":fragment.step,"fragment_blend":fragment.visual_blend,
		"scroll":scroll.scroll_vertical,"focus":str(focus.get_path()) if focus != null else "none"}))

func phase_count(tag: String, counters: Dictionary, scope: String, fragment: Control, offline: Node, moments: Node, scroll: ScrollContainer) -> void:
	counters[tag] = int(counters.get(tag,0)) + 1
	if counters[tag] <= 4: phase_trace(tag,scope,fragment,offline,moments,scroll)

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
	await settle()

func component_boundaries(first: Dictionary, second: Dictionary) -> void:
	var fragment: Variant = Fragment.new()
	root.add_child(fragment); await settle()
	var original: Dictionary = first.duplicate(true)
	fragment.set_pair(first, second, false)
	first.metrics.total_cycles += 100
	first.part_ids.cpu = "unrun-change"
	check(fragment.before == original, "Caller mutation cannot reinterpret the detached original record")
	first = original.duplicate(true)
	fragment.set_pair(second, first, true)
	fragment._select_step(0)
	check(fragment.metric_label.text.contains("Δ +") and fragment.response_label.text.contains("not presented as an improvement"), "Reversed real lawful endpoints honestly show slower computation")
	fragment._select_step(1)
	check(first.metrics.cpu_wait_cycles == second.metrics.cpu_wait_cycles and fragment.response_label.text.contains("did not change"), "Real unchanged waiting is an observation rather than a fabricated gain")
	var frozen: Dictionary = fragment.before.duplicate(true)
	for invalid: String in ["single", "failed", "program", "tests", "fixed-part", "other-task", "mixed-mode"]:
		var a: Dictionary = first.duplicate(true)
		var b: Dictionary = second.duplicate(true)
		match invalid:
			"single": b = a.duplicate(true)
			"failed": b.all_passed = false
			"program": b.program_signature = "different-program"
			"tests": b.test_set_signature = "different-tests"
			"fixed-part": b.part_ids.ram = "different-fixed-ram"
			"other-task": b.level_id = "ram_wait"
			"mixed-mode": b.source = "game"
		fragment.set_pair(a,b,true)
		check(not fragment.visible and fragment.before.is_empty(), "Unsupported pair clears only presentation: "+invalid)
	fragment.set_pair(first,second,false)
	fragment.toggle_button.button_pressed = true
	fragment._select_step(2)
	fragment.set_pair(first,second,true)
	check(not fragment.body.visible and fragment.metric_label.text.begins_with("Compute") and fragment.source_label.text.contains("Test records"), "Same-instance language change resets candidate text without earned claims")
	fragment.media = ImageTexture.new()
	check(fragment.image.media != null and fragment.image.media.get_width() == 0, "Empty Texture2D reaches the safe procedural fallback")
	fragment.media = null
	fragment.reduced_motion = true
	fragment._select_step(2)
	check(fragment.visual_blend == 1.0 and fragment.before == first and frozen == second, "Reduced motion and optional media preserve both measured records")
	fragment.clear_pair()
	check(not fragment.visible and fragment.before.is_empty() and fragment.after.is_empty(), "Missing evidence cannot leave a previous pair displayed")
	fragment.queue_free(); await settle()

func feedback_stack(main: Control, tester: bool, suffix: String) -> void:
	ProjectSettings.set_setting("playtest/offline_tester", tester)
	var offline: Node = root.get_node("OfflineFeedback")
	var moments: Node = root.get_node("PlaytestMoments")
	var fragment: Variant = main.efficiency_fragment
	await begin_history(main)
	fragment.toggle_button.grab_focus(); await stroke(KEY_SPACE)
	fragment.step_buttons[1].grab_focus(); await stroke(KEY_SPACE)
	fragment.step_buttons[1].pressed.emit()
	var exact_focus: Control = root.gui_get_focus_owner()
	var original_state: Dictionary = protected_state()
	var original_step: int = fragment.step
	var original_blend: float = fragment.visual_blend
	var scroll: ScrollContainer = main.history_chart.get_parent().get_parent()
	var original_scroll: int = scroll.scroll_vertical
	var previous_pause: bool = paused
	var phase_counts: Dictionary = {}
	var on_process: Callable = phase_count.bind("process",phase_counts,suffix,fragment,offline,moments,scroll)
	var on_pre: Callable = phase_count.bind("pre_draw",phase_counts,suffix,fragment,offline,moments,scroll)
	var on_post: Callable = phase_count.bind("post_draw",phase_counts,suffix,fragment,offline,moments,scroll)
	process_frame.connect(on_process)
	RenderingServer.frame_pre_draw.connect(on_pre)
	RenderingServer.frame_post_draw.connect(on_post)
	phase_trace("before_parse",suffix,fragment,offline,moments,scroll)
	key(KEY_F8, true)
	phase_trace("after_parse",suffix,fragment,offline,moments,scroll)
	# Offline F8 is polled in _process; its clean-frame capture awaits post_draw.
	await RenderingServer.frame_pre_draw
	phase_trace("original_predraw_assert",suffix,fragment,offline,moments,scroll)
	check(fragment._feedback_active(), "Real F8 establishes feedback or capture-busy priority before drawing")
	if tester: check(offline.busy, "Actual tester capture-busy boundary is observed before frame_post_draw")
	fragment._select_step(2)
	check(fragment.step == original_step, "A capture-busy or open feedback cannot advance the candidate fragment")
	key(KEY_F8, false); await settle()
	phase_trace("after_original_settle",suffix,fragment,offline,moments,scroll)
	process_frame.disconnect(on_process)
	RenderingServer.frame_pre_draw.disconnect(on_pre)
	RenderingServer.frame_post_draw.disconnect(on_post)
	var panel: Control = offline.panel if tester else moments.panel
	check((offline.backdrop.visible if tester else moments.panel.visible) and panel.is_visible_in_tree() and panel.get_viewport() == root, "Actual role-specific F8 panel opens in the history viewport")
	check(panel.is_ancestor_of(root.gui_get_focus_owner()), "Feedback owns the real keyboard focus")
	check(fragment.visual_blend == original_blend and scroll.scroll_vertical == original_scroll and fragment.step == original_step, "Feedback suspends local fading and never scrolls or advances the original observation")
	check(paused if tester else paused == previous_pause, "Role-specific feedback retains its original pause contract")
	if tester:
		check(not offline.current.is_empty() and offline.current.get("screenshot_status", "") == "captured", "Tester records an actual pre-overlay efficiency scene")
	await capture_frame(suffix+"-feedback")
	await stroke(KEY_ESCAPE)
	check(not (offline.backdrop.visible if tester else moments.panel.visible) and not panel.is_visible_in_tree() and fragment.body.visible and not main.map_host.visible, "First Escape closes feedback only, retaining the expanded history fragment")
	check(root.gui_get_focus_owner() == exact_focus and paused == previous_pause, "Feedback returns exact fragment focus and restores the original pause state")
	await stroke(KEY_ESCAPE)
	check(not fragment.body.visible and root.gui_get_focus_owner() == fragment.toggle_button and not main.map_host.visible, "Second Escape collapses only the genuinely focused fragment")
	check(protected_state() == original_state, "Fragment and both feedback channels preserve original game, workbench, works, leases, receipts and navigation")
	await stroke(KEY_ESCAPE)
	check(main.map_host.visible, "After fragment collapse Escape resumes the original host return path")
	main._start_level(&"cpu_speed"); await settle()

func rendered_matrix(main: Control, locale: String) -> void:
	var fragment: Variant = main.efficiency_fragment
	var original_state: Dictionary = protected_state()
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1600,1000)]:
		root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
		await settle(); await begin_history(main)
		var suffix: String = locale+"-"+str(dimensions.x)+"x"+str(dimensions.y)
		check(fully_visible(fragment.toggle_button) and fully_visible(main.history_chart), "Default history exposes candidate entry and the unchanged original comparison: "+suffix)
		await capture_frame(suffix+"-collapsed")
		fragment.toggle_button.grab_focus(); await stroke(KEY_SPACE)
		check(fragment.body.visible and fully_visible(fragment.step_buttons[0]) and fully_visible(fragment.metric_label), "Real expansion reveals original identity and operative observation without QA scrolling: "+suffix)
		check(fully_visible(fragment.source_label), "Expanded original record identity lies within all ancestor clips: "+suffix)
		check(fragment.metric_label.get_theme_font_size("font_size") == 16 and fragment.response_label.get_theme_font_size("font_size") == 16, "Core observations retain 16px body text")
		await capture_frame(suffix+"-expanded")
		fragment.step_buttons[2].grab_focus(); await stroke(KEY_SPACE)
		check(root.gui_get_focus_owner() == fragment.step_buttons[2] and fragment.step == 2, "Choosing a step retains a valid focused control")
		var scroll: ScrollContainer = main.history_chart.get_parent().get_parent()
		# Deep optional material is reached through the actual original ScrollContainer.
		scroll.ensure_control_visible(fragment.chart_button); await settle()
		check(fully_visible(fragment.chart_button), "The original chart has a reachable explicit return action: "+suffix)
		fragment.chart_button.grab_focus(); await stroke(KEY_SPACE)
		check(not fragment.body.visible and fully_visible(main.history_chart) and fully_visible(fragment.toggle_button), "Return restores the original same-scale bars and entry: "+suffix)
		fragment.media = ImageTexture.new()
		fragment.reduced_motion = true
		fragment.toggle_button.grab_focus(); await stroke(KEY_SPACE)
		fragment.step_buttons[1].grab_focus(); await stroke(KEY_SPACE)
		check(fragment.visual_blend == 1.0 and fragment.body.visible, "Empty media and reduced motion leave real observations operable: "+suffix)
		await capture_frame(suffix+"-static-fallback")
		fragment.media = null; fragment.reduced_motion = false
		fragment.collapse()
	check(protected_state() == original_state, "All window, media, language and observation choices preserve the authoritative state")
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
	await feedback_stack(main,false,locale+"-ordinary")
	await feedback_stack(main,true,locale+"-tester")

func run() -> void:
	capture = "--efficiency-fragment-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var old_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester",false)
	root.get_node("GameMode").set_mode(&"test")
	var chapter: Node = root.get_node("SystemChapter")
	for locale: String in ["zh_CN", "en"]:
		ProjectSettings.set_setting("playtest/offline_tester",false)
		root.get_node("Localization").set_locale(locale)
		chapter.reset_test_progress()
		var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
		main.process_mode = Node.PROCESS_MODE_PAUSABLE
		root.add_child(main); await settle()
		main._start_level(&"cpu_speed"); await settle()
		check(not main.efficiency_fragment.visible, "A new CPU task has no invented comparison fragment")
		main.prediction_selector.select(1); main._lock_prediction()
		main._run_official(); main._finish_playback(); await settle()
		check(chapter.receipts_for(&"cpu_speed").size() == 1 and not chapter.completed_levels().get(&"cpu_speed",false) and not main.efficiency_fragment.visible, "First real correct official baseline remains incomplete and has no pair")
		main.part_selectors[&"cpu"].select(1); main._on_part_selected(1,&"cpu")
		main._run_debug_case(); main._finish_playback(); await settle()
		check(chapter.receipts_for(&"cpu_speed").size() == 1 and not main.efficiency_fragment.visible, "An unrun selector and debug trace cannot supply an official second record")
		main._run_official(); main._finish_playback(); await settle()
		var receipts: Array = chapter.receipts_for(&"cpu_speed")
		check(receipts.size() == 2 and receipts[0].all_passed and receipts[1].all_passed and chapter.completed_levels().get(&"cpu_speed",false), "The actual catalog accepts two real controlled official observations")
		var fragment: Variant = main.efficiency_fragment
		check(fragment.visible and not fragment.body.visible and fragment.before.metrics == receipts[0].metrics and fragment.after.metrics == receipts[1].metrics, "Host consumes exactly its existing selected pair and does not autoplay")
		check(main.history_chart.samples[0] == receipts[0].metrics and main.history_chart.samples[1] == receipts[1].metrics, "The pre-existing chart retains the same original sample dictionaries")
		var bound: Dictionary = fragment.after.duplicate(true)
		var state: Dictionary = protected_state()
		main.part_selectors[&"cpu"].select(0); main._on_part_selected(0,&"cpu"); main._refresh_history()
		check(fragment.after == bound and protected_state() == state, "Unrun current controls never relabel the recorded after endpoint or change authoritative state")
		check(fragment.source_label.text.contains("当前草稿不同") if locale == "zh_CN" else fragment.source_label.text.contains("Current draft differs"), "A changed current draft is explicitly distinct from the original comparison")
		fragment._select_step(1)
		check(fragment.source_label.text.contains("当前草稿不同") if locale == "zh_CN" else fragment.source_label.text.contains("Current draft differs"), "Changing the observation step retains the current-draft provenance warning")
		main._run_official(); main._finish_playback(); await settle()
		check(chapter.receipts_for(&"cpu_speed").size() == 2 and fragment.after == bound, "A deduplicated rerun of the older CPU does not invent a new latest pair or relabel After")
		main.editor.text = main.applied_program_source + "\ninvalid draft"
		main._on_program_changed()
		check(fragment.after == bound and (fragment.source_label.text.contains("当前草稿不同") if locale == "zh_CN" else fragment.source_label.text.contains("Current draft differs")), "Unapplied edited code preserves old record identity and explains its stale context")
		main.editor.text = main.applied_program_source; main._on_program_changed()
		main.part_selectors[&"cpu"].select(1); main._on_part_selected(1,&"cpu")
		await component_boundaries(main._efficiency_record(receipts[0]),main._efficiency_record(receipts[1]))
		check(fragment.source_label.text.contains("测试记录") if locale == "zh_CN" else fragment.source_label.text.contains("Test records"), "Reference controller evidence stays distinct from ordinary earned history")
		if DisplayServer.get_name() != "headless": await rendered_matrix(main,locale)
		else: print("NOT_RUN: renderer clip/focus/F8/Escape; run this suite without headless and with --capture-size=1280x720 --efficiency-fragment-capture")
		main._start_level(&"ram_wait"); await settle()
		check(not fragment.visible and fragment.before.is_empty(), "Leaving CPU clears the candidate instead of leaking it into another task")
		main.queue_free(); await settle()
	ProjectSettings.set_setting("playtest/offline_tester",old_tester)
	print(("PASS" if failures.is_empty() else "FAIL")+": efficiency fragment "+str(checks)+" checks; real official System-model controller fixtures, not player-built prologue or native input")
	quit(0 if failures.is_empty() else 1)
