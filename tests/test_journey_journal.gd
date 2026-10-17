extends SceneTree
## Actual catalogs and saved files; model setup is disclosed controller input.
var Journal: Script
const Session = preload("res://experiments/creation/session.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const Review = preload("res://experiments/candidate_session/journey_review.gd")
const SecondAct = preload("res://src/campaign/second_act_tasks.gd")
var checks: int = 0
var failures: Array[String] = []


func _init() -> void: call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle() -> void:
	for frame: int in 6: await process_frame


func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()


func full_input_key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		Input.parse_input_event(event)
		await settle()


func inventory(path: String) -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(path)
	if directory == null: return result
	for name: String in directory.get_files(): result[name] = FileAccess.get_sha256(path.path_join(name))
	for name: String in directory.get_directories():
		if name in ["shader_cache", "logs"]: continue
		var children: Dictionary = inventory(path.path_join(name))
		for child: String in children: result[name + "/" + child] = children[child]
	return result


func check_inventory(before: Dictionary, after: Dictionary, message: String) -> void:
	var paths: Dictionary = before.duplicate()
	paths.merge(after)
	var changed: Array[String] = []
	for path: String in paths:
		var prior: String = str(before.get(path, "absent"))
		var current: String = str(after.get(path, "absent"))
		if prior == current: continue
		changed.append(path)
		print("INVENTORY_CHANGE ", JSON.stringify({"path":path, "before_sha256":prior, "after_sha256":current}))
	check(changed.is_empty(), message)


func write_raw(path: String, raw: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(raw)
	file.close()


func run() -> void:
	Journal = load("res://src/ui/journey_journal.gd")
	var save: Node = root.get_node("GlobalSave")
	var nav: Node = root.get_node("TaskNavigation")
	var localization: Node = root.get_node("Localization")
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test("user://journal-save.json", "user://journal-workbench.json")
	var prior_creation: Variant = ProjectSettings.get_setting("candidate/creation_enabled", false)
	ProjectSettings.set_setting("candidate/creation_enabled", true)
	var entered: bool = nav.enter("hardware_foundations/tutorial")
	check(entered, "Actual task navigation enters the tutorial host")
	if not entered:
		quit(1)
		return
	await settle()
	var host: Variant = current_scene
	var tutorial_ready: bool = is_instance_valid(host) and host.current_level_id == &"tutorial" and is_instance_valid(host.input_a_button)
	check(tutorial_ready, "Navigation selects tutorial and builds its real input control")
	if not tutorial_ready:
		quit(1)
		return
	if host.mission_briefing_active: host._start_building_from_briefing()
	await settle()
	var journal: Variant = Journal.new()
	host.add_child(journal)
	journal.open()
	check(journal.rows == nav.journey_tasks(), "Journal reads the actual launch catalog, not a synthetic sixty-row list")
	check(journal.core_records.total == nav.tasks().size(), "Existing core record summary retains its original scope")
	journal.show_task("hardware_foundations/tutorial")
	check(journal.civilization_fragment(journal.selected_task()).is_empty(), "Fresh tutorial cannot reveal a completion fragment")
	var initial: String = save.game_player_content.canonical_signature()
	var old_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester", false)
	ProjectSettings.set_setting("playtest/offline_tester", true)
	journal.open()
	check(save.game_player_content.canonical_signature() == initial, "Tester access does not grant earned progress")
	for row: Dictionary in journal.rows:
		check(not row.completed and journal.civilization_fragment(row).is_empty(), "Tester-open task stays unearned: " + str(row.key))
	ProjectSettings.set_setting("playtest/offline_tester", old_tester)
	journal.close()
	# Earn the original tutorial through its real controller/model, never a flag setter.
	host._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	host._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	host.input_a_button.button_pressed = true
	host._run_debug()
	host._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
	check(not host.completed_levels.get(&"tutorial", false), "Four real tutorial actions remain incomplete")
	host._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await settle()
	check(host.completed_levels.get(&"tutorial", false), "Real reconnect earns the source tutorial completion")
	host._dismiss_level_completion()
	host._save_active_workbench()
	check(save.save_game(true), "Earned source data saves before read-only review")
	var writer: Variant = Session.new()
	check(writer.open(Session.default_path()).writable, "Test setup owns an isolated creation profile")
	check(writer.train().ok and writer.transport([0, 1, 0, 2], "predictive").ok, "Setup learns and genuinely restores source data")
	writer.set_mode("predict"); writer.begin_prediction("practice")
	while not writer.prediction.finished: writer.commit_prediction(); writer.reveal_prediction()
	writer.set_mode("generate")
	check(writer.generate().ok and writer.save_work("Journal preserved work").ok, "Setup generates and saves an actual protected work")
	var original: Dictionary = writer.data.duplicate(true)
	writer.close()
	var content_before: String = save.game_player_content.canonical_signature()
	var board_before: Dictionary = host._capture_workbench_snapshot().duplicate(true)
	var disk_before: Dictionary = inventory("user://")
	for locale: String in ["zh_CN", "en"]:
		localization.set_locale(locale)
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1440, 900)]:
			root.size = dimensions; root.content_scale_size = dimensions
			await settle()
			journal.open()
			journal.show_task("hardware_foundations/tutorial")
			await settle()
			check(not journal.civilization_fragment(journal.selected_task()).is_empty(), "Real saved completion reveals a labeled retrospective")
			check(journal.detail.text.contains("Fiction candidate" if locale == "en" else "虚构候选"), "Fiction and retrospective status remain explicit")
			var best: Dictionary = root.get_node("PersonalRecords").best.get("hardware_foundations/tutorial", {})
			for identity: String in ["case_set_version", "model_version", "build_version", "source_commit"]:
				if best.has(identity): check(journal.detail.text.contains(identity + ": " + str(best[identity])), "Historical metric retains its existing source identity:" + identity)
			check(root.get_visible_rect().encloses(journal.close_button.get_global_rect()), "Journal return control fits " + str(dimensions))
			check(root.get_visible_rect().encloses(journal.task_tree.get_global_rect()), "Actual task browser fits " + str(dimensions))
			journal.help_button.grab_focus()
			await key(KEY_SPACE)
			check(journal.handbook.is_open(), "Keyboard opens the existing rule handbook")
			await key(KEY_ESCAPE)
			check(not journal.handbook.is_open() and journal.visible, "Escape closes help before the journal")
			check(root.gui_get_focus_owner() == journal.help_button, "Help dismissal restores journal focus")
			await key(KEY_TAB)
			check(root.gui_get_focus_owner() == journal.reflection_button, "Tab follows the explicit journal action order")
			await key(KEY_ESCAPE)
			check(not journal.visible, "Next Escape returns to the original host")
	journal.open()
	check(journal.saved_work_state.ok and journal.work_summary().contains("Journal preserved work"), "Saved-work view reads actual protected snapshots")
	journal.show_task("unknown/task")
	check(journal.selected_task().is_empty() and journal.enter_button.disabled, "Unknown identity cannot borrow another task's result or navigation")
	var navigation_before := {"pending":nav.pending, "selected":nav.selected, "from_tree":nav.from_tree}
	journal._enter_selected()
	check(journal.visible and {"pending":nav.pending, "selected":nav.selected, "from_tree":nav.from_tree} == navigation_before, "Unknown entry preserves journal and navigation")
	for row: Dictionary in nav.journey_tasks():
		if bool(row.unlocked): continue
		journal.show_task(str(row.key))
		# An obsolete UI snapshot cannot override the current catalog's lock.
		var obsolete: Dictionary = journal.selected_task()
		obsolete["unlocked"] = true
		journal._enter_selected()
		check(journal.visible and {"pending":nav.pending, "selected":nav.selected, "from_tree":nav.from_tree} == navigation_before, "Revoked/stale access preserves journal and navigation")
		break
	journal.show_task("hardware_foundations/tutorial")
	journal._open_help()
	check(journal.handbook.context_lesson == &"hardware:tutorial", "Core review uses its actual lesson context")
	journal.handbook.close_handbook()
	for row: Dictionary in journal.rows:
		if row.domain != "creation": continue
		journal.show_task(str(row.key)); journal._open_help()
		check(journal.handbook.context_lesson == &"" and not journal.handbook.recommended_toggle.button_pressed, "Candidate review clears previous core lesson and recommendations")
		check(journal.help_button.text.contains("General terms"), "Candidate help explicitly identifies general terms rather than task rules")
		journal.handbook.close_handbook()
		break
	for status: String in ["unavailable", "readonly", "read_only", "invalid"]:
		journal.show_task("hardware_foundations/tutorial")
		var stale: Dictionary = journal.selected_task().duplicate(true)
		stale.evidence_status = status
		var original_rows: Array[Dictionary] = journal.rows
		var stale_rows: Array[Dictionary] = [stale]
		journal.rows = stale_rows
		journal.show_task(str(stale.key))
		check(not Journal.earned(stale) and journal.civilization_fragment(stale).is_empty() and not journal.detail.text.contains("Capability supported"), "Invalidated completion snapshot cannot contradict its source note:" + status)
		journal.rows = original_rows
	journal.close()
	check(save.game_player_content.canonical_signature() == content_before and host._capture_workbench_snapshot() == board_before, "Journal never changes player content or circuit")
	check_inventory(disk_before, inventory("user://"), "Opening, help, browsing and closing write no profile, lease, history or migration bytes")
	# Real future/corrupt files are decoded by the existing domain readers.
	var base := "user://journal-invalid/"
	write_raw(base + "representation.json", '{"schema":999}')
	write_raw(base + "service.json", "broken-json")
	var pair_before: Dictionary = inventory(base)
	var pair: Dictionary = Review.read_pair(base + "representation.json", base + "service.json")
	check(pair.representation.status == "unavailable" and pair.service.status == "unavailable", "Actual unknown/corrupt saved pair is unconfirmed")
	for row: Dictionary in SecondAct.build(pair, true):
		check(not row.completed and journal.civilization_fragment(row).is_empty(), "Unconfirmed candidate record grants no retrospective: " + str(row.key))
	check_inventory(pair_before, inventory(base), "Saved-pair review performs no repair or writer acquisition")
	var future: Dictionary = original.duplicate(true)
	future.works[0].recipe = {"version":99,"model":"future representation","initial":"future context","model_id":"future-model-id"}
	future.works[0].training = {"cost":"future representation","machine":"future machine"}
	write_raw(Session.default_path(), JSON.stringify(future))
	var future_before: Dictionary = inventory("user://")
	journal.open()
	check(not journal.saved_work_state.ok and journal.saved_work_state.get("readonly_works", []).size() == 1, "Actual future work remains available read-only")
	check(journal.work_summary().contains("Journal preserved work") and journal.work_summary().contains("unconfirmed"), "Read-only work name is preserved without claiming valid evidence")
	for row: Dictionary in journal.rows:
		if row.domain == "creation": check(not row.completed and journal.civilization_fragment(row).is_empty(), "Future work cannot create completion history")
	journal.close()
	check_inventory(future_before, inventory("user://"), "Future profile and backup bytes survive journal browsing exactly")
	var protected_before_feedback := {"game":FileAccess.get_sha256(save.storage_path), "workbench":FileAccess.get_sha256(save.workbench_storage_path), "creation":FileAccess.get_sha256(Session.default_path())}
	journal.open()
	journal.show_task("hardware_foundations/tutorial")
	journal.help_button.grab_focus()
	await key(KEY_SPACE)
	check(journal.handbook.is_open(), "Nested existing handbook is active before F8")
	var handbook_focus: Control = root.gui_get_focus_owner()
	var feedback: Node = root.get_node("OfflineFeedback")
	ProjectSettings.set_setting("playtest/offline_tester", true)
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_F8; event.physical_keycode = KEY_F8; event.pressed = down
		Input.parse_input_event(event)
		await settle()
	check(feedback.backdrop.visible and paused and journal.visible and journal.handbook.is_open(), "Actual F8 action opens feedback above journal and handbook")
	var feedback_focus: Control = root.gui_get_focus_owner()
	journal.open()
	check(root.gui_get_focus_owner() == feedback_focus and journal.handbook.is_open(), "Opening journal during feedback cannot steal the top layer's focus")
	await key(KEY_ESCAPE)
	check(not feedback.backdrop.visible and not paused and journal.visible and journal.handbook.is_open(), "Feedback Escape preserves both journal layers")
	check(root.gui_get_focus_owner() == handbook_focus, "Feedback dismissal restores exact handbook focus")
	await key(KEY_ESCAPE)
	check(journal.visible and not journal.handbook.is_open() and root.gui_get_focus_owner() == journal.help_button, "Next actual Escape closes handbook and returns journal focus")
	await key(KEY_ESCAPE)
	check(not journal.visible, "Following Escape closes the journal")
	if DisplayServer.get_name() != "headless":
		await reflection_feedback_stack(journal, feedback)
	else:
		print("NOT_RUN: ThemeReflection/F8 focused-window stack requires a real renderer")
	check({"game":FileAccess.get_sha256(save.storage_path), "workbench":FileAccess.get_sha256(save.workbench_storage_path), "creation":FileAccess.get_sha256(Session.default_path())} == protected_before_feedback, "Both feedback channels preserve exact game, workbench and future creation profile bytes")
	check(save.game_player_content.canonical_signature() == content_before and host._capture_workbench_snapshot() == board_before, "Feedback and popup returns preserve earned content and the actual circuit")
	ProjectSettings.set_setting("playtest/offline_tester", old_tester)
	ProjectSettings.set_setting("candidate/creation_enabled", prior_creation)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "read-only journey journal (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)


func reflection_feedback_stack(journal: Control, feedback: Node) -> void:
	# Real Window, existing popup and full Input events; no native-OS claim.
	var moments: Node = root.get_node("PlaytestMoments")
	for tester: bool in [true, false]:
		ProjectSettings.set_setting("playtest/offline_tester", tester)
		journal.open()
		journal.reflection_button.grab_focus()
		await key(KEY_SPACE)
		var reflection: AcceptDialog = journal.reflection_dialog
		check(is_instance_valid(reflection) and reflection.visible, "Keyboard opens existing ThemeReflection popup:" + str(tester))
		if not is_instance_valid(reflection) or not reflection.visible: return
		await RenderingServer.frame_post_draw
		check(reflection.has_focus(), "ThemeReflection owns the focused Window before F8:" + str(tester))
		var popup_focus: Control = reflection.gui_get_focus_owner()
		check(is_instance_valid(popup_focus), "Real ThemeReflection has a return focus target:" + str(tester))
		var offline_before: Dictionary = inventory(feedback.store.root)
		await full_input_key(KEY_F8)
		if tester:
			check(feedback.backdrop.visible and paused and journal.visible and reflection.visible, "Tester F8 overlays and pauses ThemeReflection without closing either lower layer")
			check(feedback.layer.get_parent() == reflection and feedback.panel.get_viewport() == reflection, "Tester feedback uses the actual focused popup viewport")
			check(str(feedback.current.get("screenshot_status", "")) == "captured", "Renderer feedback captures the actual popup frame")
			await full_input_key(KEY_ESCAPE)
			check(not feedback.backdrop.visible and not paused and journal.visible and is_instance_valid(reflection) and reflection.visible, "First full Input Escape closes only tester feedback")
			if not is_instance_valid(reflection): return
			check(reflection.gui_get_focus_owner() == popup_focus, "Feedback returns the exact ThemeReflection control focus")
		else:
			check(moments.panel.visible and journal.visible and reflection.visible, "Ordinary F8 opens the existing PlaytestMoments panel above ThemeReflection")
			check(not feedback.backdrop.visible and not paused, "Ordinary feedback does not enable the offline tester channel or its pause contract")
			check(moments.panel.get_viewport() == reflection, "Ordinary feedback belongs to the actually focused popup viewport")
			check(reflection.get_visible_rect().encloses(moments.panel.get_global_rect()), "Ordinary feedback is operable inside the actual popup bounds")
			var normal_focus: Control = reflection.gui_get_focus_owner()
			check(is_instance_valid(normal_focus) and moments.panel.is_ancestor_of(normal_focus), "Ordinary feedback receives usable keyboard focus inside the popup")
			await full_input_key(KEY_TAB)
			var tab_focus: Control = reflection.gui_get_focus_owner()
			check(is_instance_valid(tab_focus) and moments.panel.is_ancestor_of(tab_focus) and tab_focus != normal_focus, "Actual Tab operates the ordinary feedback controls")
			await full_input_key(KEY_ESCAPE)
			check(not moments.panel.visible and journal.visible and is_instance_valid(reflection) and reflection.visible, "First ordinary Escape closes only PlaytestMoments feedback")
			check_inventory(offline_before, inventory(feedback.store.root), "Ordinary F8 creates no offline incident or screenshot channel")
			if not is_instance_valid(reflection): return
			check(reflection.gui_get_focus_owner() == popup_focus, "Ordinary feedback returns exact ThemeReflection focus")
		await full_input_key(KEY_ESCAPE)
		check(not is_instance_valid(reflection) and journal.visible, "Next full Input Escape dismisses ThemeReflection alone:" + str(tester))
		check(root.gui_get_focus_owner() == journal.reflection_button, "Popup dismissal restores the journal launcher focus:" + str(tester))
		await key(KEY_ESCAPE)
		check(not journal.visible, "Final viewport Escape returns from journal to host:" + str(tester))
	ProjectSettings.set_setting("playtest/offline_tester", false)
	journal.open()
	journal.reflection_button.grab_focus(); await key(KEY_SPACE)
	var departing: AcceptDialog = journal.reflection_dialog
	await full_input_key(KEY_F8)
	check(moments.panel.visible and moments.panel.get_viewport() == departing, "Lifecycle case starts with actual ordinary feedback inside the popup")
	departing.queue_free(); await settle()
	check(is_instance_valid(moments.layer) and moments.layer.get_parent() == moments and not moments.panel.visible, "Closing the popup returns the shared feedback layer before it can be destroyed")
	await key(KEY_ESCAPE)
	check(not journal.visible, "Destroyed popup leaves the journal closable")
	var host_focus: Control = root.gui_get_focus_owner()
	await full_input_key(KEY_F8)
	check(moments.panel.visible and moments.panel.get_viewport() == root, "Ordinary root-viewport F8 remains usable after popup destruction")
	var root_feedback_focus: Control = root.gui_get_focus_owner()
	check(is_instance_valid(root_feedback_focus) and moments.panel.is_ancestor_of(root_feedback_focus), "Root ordinary feedback owns a usable control focus")
	await full_input_key(KEY_ESCAPE)
	check(not moments.panel.visible and root.gui_get_focus_owner() == host_focus, "Root feedback Escape returns exact host focus")
	for originally_paused: bool in [false, true]:
		ProjectSettings.set_setting("playtest/offline_tester", true)
		paused = false
		journal.open()
		journal.reflection_button.grab_focus(); await key(KEY_SPACE)
		var tester_departing: AcceptDialog = journal.reflection_dialog
		paused = originally_paused
		await full_input_key(KEY_F8)
		check(feedback.backdrop.visible and feedback.layer.get_parent() == tester_departing and paused, "Tester lifecycle starts inside the actual popup with its prior pause state:" + str(originally_paused))
		tester_departing.queue_free(); await settle()
		var returned: bool = is_instance_valid(feedback.layer) and feedback.layer.get_parent() == feedback
		check(returned, "Destroying tester popup preserves and returns the shared offline layer:" + str(originally_paused))
		check(paused == originally_paused and not root.get_node("PlaytestData")._feedback_visible, "Tester popup destruction restores original pause and clears its feedback flag:" + str(originally_paused))
		if not returned:
			paused = false
			return
		check(not feedback.backdrop.visible, "Destroyed tester popup leaves no orphaned feedback panel")
		await full_input_key(KEY_F8)
		check(feedback.backdrop.visible and feedback.panel.get_viewport() == root, "Root tester F8 remains usable after popup destruction:" + str(originally_paused))
		await full_input_key(KEY_ESCAPE)
		check(not feedback.backdrop.visible and paused == originally_paused, "Recovered root tester feedback preserves the same original pause state:" + str(originally_paused))
		paused = false
		await key(KEY_ESCAPE)
		check(not journal.visible, "Tester popup destruction leaves the journal return usable")
	# Controller timing fixture: destroy the selected Window during the real
	# frame_post_draw wait, before an incident or screenshot may be created.
	for originally_paused: bool in [false, true]:
		paused = false
		journal.open()
		journal.reflection_button.grab_focus(); await key(KEY_SPACE)
		var capturing: AcceptDialog = journal.reflection_dialog
		var incidents_before: Dictionary = inventory(feedback.store.root)
		paused = originally_paused
		feedback.open_panel()
		check(feedback.busy and paused, "Capture timing fixture enters the real frame wait:" + str(originally_paused))
		capturing.queue_free(); await settle()
		check(not feedback.busy and not feedback.backdrop.visible and paused == originally_paused, "Canceled capture restores busy, panel and original pause state:" + str(originally_paused))
		check(not root.get_node("PlaytestData")._feedback_visible and feedback.layer.get_parent() == feedback, "Canceled capture leaves no owned feedback flag or orphaned layer")
		check_inventory(incidents_before, inventory(feedback.store.root), "A vanished capture target creates no incident or substitute root screenshot")
		await full_input_key(KEY_F8)
		check(feedback.backdrop.visible and feedback.panel.get_viewport() == root, "Root F8 remains usable after capture target vanishes:" + str(originally_paused))
		await full_input_key(KEY_ESCAPE)
		check(not feedback.backdrop.visible and paused == originally_paused, "Root feedback after canceled capture restores the prior pause state")
		paused = false
		await key(KEY_ESCAPE)
		check(not journal.visible, "Canceled capture keeps journal return available")
