extends SceneTree
## Real generated works and disk readers; rendered Window input is a separate grade.
const Session = preload("res://experiments/creation/session.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")

class RefusingNotes:
	extends "res://src/playtest/offline_store.gd"
	func save_note(_id: String, _note: String, _category: String, _reported: bool) -> Dictionary:
		last_error = "Fixture: note write refused"
		return {}

var Journal: Script
var checks: int = 0
var failures: Array[String] = []
var capture: bool = false


func _init() -> void: call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle() -> void:
	for frame: int in 8: await process_frame


func key(code: Key, full_input: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		if full_input: Input.parse_input_event(event)
		else: root.push_input(event, true)
		await settle()


func inventory(path: String) -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(path)
	if directory == null: return result
	for name: String in directory.get_files(): result[name] = FileAccess.get_sha256(path.path_join(name))
	for name: String in directory.get_directories():
		if name in ["logs", "shader_cache", "playtest_data", "offline_playtest", "journey-work-captures"]: continue
		var children: Dictionary = inventory(path.path_join(name))
		for child: String in children: result[name + "/" + child] = children[child]
	return result


func protected_state() -> Dictionary:
	var disk: Dictionary = inventory("user://")
	# The ordinary feedback channel owns this existing voluntary note draft.
	disk.erase("feedback_drafts_v1.json")
	var game: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	game.erase("saved_at_utc")
	var nav: Node = root.get_node("TaskNavigation")
	return {"disk":disk, "game":game, "best":root.get_node("PersonalRecords").best.duplicate(true),
		"writer_lock_present":DirAccess.dir_exists_absolute(Lease.lock_path(Session.launch_path())),
		"writer_recovery_lock_present":DirAccess.dir_exists_absolute(Lease.lock_path(Session.launch_path()) + ".recovering"),
		"navigation":{"selected":nav.selected, "pending":nav.pending, "from_tree":nav.from_tree}}


func check_protected(before: Dictionary, message: String) -> void:
	var after: Dictionary = protected_state()
	if before != after:
		for path: String in before.disk:
			if before.disk[path] != after.disk.get(path, "absent"): print("PROTECTED_CHANGE: ", path, " ", before.disk[path], " -> ", after.disk.get(path, "absent"))
		for path: String in after.disk:
			if not before.disk.has(path): print("PROTECTED_NEW: ", path, " ", after.disk[path])
	check(before == after, message)


func write_raw(path: String, raw: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(raw); file.close()


func capture_frame(window: Window, name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path: String = "user://journey-work-captures/" + name + ".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	check(window.get_texture().get_image().save_png(path) == OK, "Actual saved-snapshot frame writes:" + name)


func open_work(journal: Control, index: int = 0) -> Variant:
	journal.work_selector.select(index)
	journal.work_view_button.grab_focus()
	if DisplayServer.get_name() == "headless": journal.work_view_button.pressed.emit()
	else: await key(KEY_SPACE, true)
	await settle()
	var exhibit: Variant = journal.work_focus
	check(is_instance_valid(exhibit), "Journal's actual view action opens the selected saved snapshot")
	return exhibit


func run() -> void:
	Journal = load("res://src/ui/journey_journal.gd")
	if Journal == null or not Journal.can_instantiate():
		check(false, "Journal compiles after autoloads are ready"); quit(1); return
	capture = DisplayServer.get_name() != "headless" and "--journey-work-capture" in OS.get_cmdline_user_args()
	var save: Node = root.get_node("GlobalSave")
	var nav: Node = root.get_node("TaskNavigation")
	var locale: Node = root.get_node("Localization")
	var old_creation: Variant = ProjectSettings.get_setting("candidate/creation_enabled", false)
	var old_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester", false)
	var old_motion: Variant = ProjectSettings.get_setting("game/reduced_motion", false)
	ProjectSettings.set_setting("candidate/creation_enabled", true)
	ProjectSettings.set_setting("playtest/offline_tester", false)
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test("user://journal-work-game.json", "user://journal-work-board.json")
	check(nav.enter("hardware_foundations/tutorial"), "Real navigation supplies the unchanged tutorial host")
	await settle()
	var host: Variant = current_scene
	var ready: bool = is_instance_valid(host) and host.current_level_id == &"tutorial"
	check(ready, "Actual tutorial is selected, without awarding its completion")
	if not ready: quit(1); return
	if host.mission_briefing_active: host._start_building_from_briefing()
	host._save_active_workbench()
	check(save.save_game(true), "Protected game and board are saved before the read-only fixture")
	var writer: Variant = Session.new()
	check(writer.open(Session.launch_path()).writable, "Setup owns only an isolated creation writer")
	check(writer.train().ok and writer.transport([0, 1, 0, 2], "predictive").ok, "Real C/P/G setup learns and restores its source")
	writer.set_mode("predict"); writer.begin_prediction("practice")
	while not writer.prediction.finished: writer.commit_prediction(); writer.reveal_prediction()
	writer.set_mode("generate")
	check(writer.generate().ok and writer.save_work("档案中的原作品 · Original saved signal").ok, "Real generator saves the first immutable work")
	check(writer.generate().ok and writer.save_work("第二件作品 · Second saved signal").ok, "Real generator saves a distinct second work")
	var source: Dictionary = writer.data.duplicate(true)
	writer.close()
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(Session.launch_path())), "Setup closes its writer before Journal reads")
	print("SETUP: actual isolated C/P/G works; viewer receives no replay receipt, writer or Session")
	var journal: Variant = Journal.new()
	host.add_child(journal)
	check(Files.read_session(Session.launch_path(), Session.decode).data.works == source.works, "Test expectation comes from the actual disk reader and original saved works")
	var before: Dictionary = protected_state()
	for language: String in ["zh_CN", "en"]:
		locale.set_locale(language)
		for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1440,900)]:
			root.size = dimensions; root.content_scale_size = dimensions; await settle()
			journal.open(); await settle()
			check(journal.work_selector.item_count == 2 and not journal.work_view_button.disabled, "Actual decoded saved works populate the selector")
			check(root.get_visible_rect().encloses(journal.work_selector.get_global_rect()) and root.get_visible_rect().encloses(journal.work_view_button.get_global_rect()), "Archive selection and view controls fit:" + language + str(dimensions))
			check(journal.work_note.text.contains("no generation replay" if language == "en" else "没有生成回放证据"), "Journal states snapshot-only scope before opening")
			var exhibit: Variant = await open_work(journal)
			if not is_instance_valid(exhibit): quit(1); return
			check(exhibit.work == source.works[0] and exhibit.canvas.output == source.works[0].output, "Viewer uses exact saved output and recipe without regeneration")
			check(exhibit.evidence.is_empty() and exhibit.explanation_button.disabled and exhibit.fork_button.disabled, "No replay receipt enables Locate or an editable fork")
			check(exhibit.request_fork.get_connections().is_empty() and exhibit.request_evidence.get_connections().is_empty(), "Journal connects no hidden write or replay actions")
			check(exhibit.origin_label.text.contains("no verified generation event" if language == "en" else "暂无可核对的生成事件"), "Actual WorkFocus does not invent generation events")
			check(exhibit.close_button.text == ("Back to journal" if language == "en" else "返回旅程档案"), "Viewer returns to its actual Journal origin")
			check(exhibit.find_child("JournalWorkProvenance", true, false).text == journal.work_note.text, "Viewer retains the archive's snapshot-only provenance while open")
			check(exhibit.get_visible_rect().encloses(exhibit.close_button.get_global_rect()) and exhibit.get_visible_rect().encloses(exhibit.play_button.get_global_rect()), "Original viewer controls fit the actual Window")
			await capture_frame(exhibit, language + "-" + str(dimensions.x) + "-snapshot")
			exhibit.select_cell(exhibit.work.output.size()-1)
			exhibit.mapping_choice.select(2); exhibit.sync_presentation(); await settle()
			check(exhibit.cursor == exhibit.work.output.size() and exhibit.canvas.selected == exhibit.cursor-1, "Read-only browsing retains the actual final saved cell")
			exhibit.motion_button.button_pressed = true
			exhibit.toggle_play()
			check(not exhibit.playing and exhibit.reduced_motion, "Existing reduced-motion viewing remains optional and static")
			if DisplayServer.get_name() == "headless": exhibit.dismiss(); await settle()
			else: await key(KEY_ESCAPE, true)
			check(not is_instance_valid(journal.work_focus) and journal.visible, "Viewer closes alone and retains Journal")
			check(root.gui_get_focus_owner() == journal.work_view_button, "Viewer dismissal returns the actual Journal action focus")
			journal.close()
	check_protected(before, "Two languages/three sizes/browsing/closing preserve every profile, transaction, lease, saved work, result and navigation byte")
	journal.open()
	var second: Variant = await open_work(journal, 1)
	if not is_instance_valid(second): quit(1); return
	check(second.work.id == source.works[1].id, "Selection opens the second real work, not a cached first snapshot")
	var same: Window = journal.work_focus
	journal._open_work()
	check(journal.work_focus == same, "Repeated open reuses the existing Window without stacking")
	second.dismiss(); await settle()
	journal.work_selector.select(1)
	var removed: Dictionary = source.duplicate(true)
	removed.works.remove_at(1)
	write_raw(Session.launch_path(), JSON.stringify(removed))
	var changed_before: Dictionary = protected_state()
	journal.work_view_button.pressed.emit(); await settle()
	check(not is_instance_valid(journal.work_focus) and journal.visible and journal.work_note.text.contains("changed"), "Click-time re-read rejects a removed id while preserving the Journal")
	check_protected(changed_before, "Stale selection does not overwrite or repair the changed profile")
	write_raw(Session.launch_path(), JSON.stringify(source))
	journal.open()
	journal.work_selector.set_item_metadata(0, "unknown-work-id")
	changed_before = protected_state()
	journal.work_view_button.pressed.emit(); await settle()
	check(not is_instance_valid(journal.work_focus) and journal.visible, "An unknown UI identity cannot borrow the first available work")
	check_protected(changed_before, "Unknown selection is rejected without changing saved works or navigation")
	await invalid_profiles(journal, source)
	write_raw(Session.launch_path(), JSON.stringify(source))
	journal.close()
	var feedback_before: Dictionary = protected_state()
	if DisplayServer.get_name() != "headless": await feedback_stack(journal)
	else: print("NOT_RUN: saved-work real Window F8/Esc/Tab/focus/destroy/refused-save; use --capture-size=1280x720 --journey-work-capture without --headless")
	check_protected(feedback_before, "Both feedback channels and lifetime guards preserve all saved authority and work bytes")
	check(not save.game_player_content.completed_levels.get(&"tutorial", false), "Viewing generated works never awards unrelated tutorial completion")
	journal.queue_free(); await settle()
	ProjectSettings.set_setting("candidate/creation_enabled", old_creation)
	ProjectSettings.set_setting("playtest/offline_tester", old_tester)
	ProjectSettings.set_setting("game/reduced_motion", old_motion)
	print(("PASS" if failures.is_empty() else "FAIL") + ": Journal saved-work review " + str(checks) + " checks; real saved-work fixture, no native-OS claim")
	quit(0 if failures.is_empty() else 1)


func invalid_profiles(journal: Control, source: Dictionary) -> void:
	var future: Dictionary = source.duplicate(true)
	future.works[0].recipe = {"version":99, "model":"future representation", "initial":"future context", "model_id":"future-model-id"}
	future.works[0].training = {"cost":"future representation", "machine":"future machine"}
	write_raw(Session.launch_path(), JSON.stringify(future))
	var before: Dictionary = protected_state()
	journal.open()
	check(not journal.saved_work_state.ok and not journal._saved_works().is_empty(), "Existing decoder exposes future-recipe output only as read-only recovery")
	check(journal.work_selector.get_item_text(0).contains("Read-only recovery") and journal.work_note.text.contains("unconfirmed"), "Recovery is visibly distinct from confirmed saved works")
	var recovery: Variant = await open_work(journal)
	if is_instance_valid(recovery):
		check(recovery.work.output == source.works[0].output and recovery.evidence.is_empty() and recovery.fork_button.disabled, "Unknown recipe displays only its original saved output with no permissions")
		check(recovery.recipe_label.text.contains("cannot be interpreted"), "Viewer preserves the original unknown-recipe explanation")
		check(recovery.title.contains("Read-only recovered") and recovery.find_child("JournalWorkProvenance", true, false).text.contains("unconfirmed"), "The open recovery Window retains its unconfirmed status")
		recovery.dismiss(); await settle()
	check_protected(before, "Future-recipe recovery view retains exact old profile and backup bytes")
	var damaged: Dictionary = source.duplicate(true)
	damaged.works[0].output[0] = (int(damaged.works[0].output[0])+1)%4
	for raw: String in [JSON.stringify({"version":999}), "broken-json", JSON.stringify(damaged)]:
		write_raw(Session.launch_path(), raw)
		before = protected_state()
		# JSON.parse_string prints for this deliberately malformed fixture.
		var printed_errors: bool = Engine.print_error_messages
		if raw == "broken-json": Engine.print_error_messages = false
		journal.open()
		Engine.print_error_messages = printed_errors
		check(journal.work_view_button.disabled and journal._saved_works().is_empty(), "Unknown schema or damaged evidence cannot invent available works")
		journal.work_view_button.pressed.emit(); await settle()
		check(not is_instance_valid(journal.work_focus), "Invalid saved input cannot open a previous cached work")
		journal.close()
		check_protected(before, "Unknown or damaged profile is never migrated, repaired, leased or rewritten")


func feedback_stack(journal: Control) -> void:
	var feedback: Node = root.get_node("OfflineFeedback")
	var moments: Node = root.get_node("PlaytestMoments")
	for tester: bool in [false, true]:
		ProjectSettings.set_setting("playtest/offline_tester", tester)
		journal.open()
		var exhibit: Variant = await open_work(journal)
		if not is_instance_valid(exhibit): return
		check(exhibit.has_focus(), "Actual saved-work Window is focused before feedback:" + str(tester))
		exhibit.play_button.grab_focus()
		await key(KEY_SPACE, true)
		var offline_before: Dictionary = inventory(feedback.store.root)
		await key(KEY_F8, true)
		check(not exhibit.playing, "Actual feedback action pauses snapshot playback")
		var panel: Control = feedback.panel if tester else moments.panel
		check(feedback.backdrop.visible if tester else moments.panel.visible, "F8 opens the expected existing feedback channel:" + str(tester))
		check(panel.get_viewport() == exhibit and exhibit.visible and journal.visible, "Feedback remains in the original viewer Window with Journal beneath it")
		var top_focus: Control = exhibit.gui_get_focus_owner()
		check(is_instance_valid(top_focus) and panel.is_ancestor_of(top_focus), "Feedback receives an actual operable focus target")
		await key(KEY_TAB, true)
		check(is_instance_valid(exhibit.gui_get_focus_owner()) and panel.is_ancestor_of(exhibit.gui_get_focus_owner()), "Actual Tab stays inside the feedback controls")
		await key(KEY_ESCAPE, true)
		check(not (feedback.backdrop.visible if tester else moments.panel.visible) and is_instance_valid(exhibit) and exhibit.visible and journal.visible, "First Escape closes only feedback and keeps both lower layers")
		if not is_instance_valid(exhibit): return
		check(exhibit.gui_get_focus_owner() == exhibit.play_button and not exhibit.playing, "Feedback returns exact viewer focus and preserves paused playback")
		if not tester: check(inventory(feedback.store.root) == offline_before, "Ordinary feedback creates no offline incidents")
		else: check(feedback.current.get("screenshot_status", "") == "captured", "Tester captures the actual saved-work popup")
		await key(KEY_ESCAPE, true)
		check(not is_instance_valid(exhibit) and journal.visible and root.gui_get_focus_owner() == journal.work_view_button, "Next Escape returns from viewer to the exact Journal launcher")
		await key(KEY_ESCAPE)
		check(not journal.visible, "Final Escape returns Journal to the original host")
		journal.open()
		exhibit = await open_work(journal)
		if not is_instance_valid(exhibit): return
		await key(KEY_F8, true)
		exhibit.queue_free(); await settle()
		check(is_instance_valid(feedback.layer if tester else moments.layer), "Destroying a feedback-owning viewer retains the shared layer")
		check(not root.get_node("PlaytestData")._feedback_visible and not paused, "Successful close during destruction clears only its own flags and pause")
		check(feedback.layer.get_parent() == feedback if tester else moments.layer.get_parent() == moments, "Destroyed viewer returns shared UI to its original owner")
		await key(KEY_F8, true)
		check((feedback.backdrop.visible if tester else moments.panel.visible) and (feedback.panel.get_viewport() == root if tester else moments.panel.get_viewport() == root), "Root feedback remains usable after the viewer Window is destroyed")
		await key(KEY_ESCAPE, true)
		check(not root.get_node("PlaytestData")._feedback_visible and not paused, "Recovered root feedback returns to the original pause state")
		journal.close()
	# Real refused-save fixture: a destroyed popup must retain root rescue, not lose notes.
	ProjectSettings.set_setting("playtest/offline_tester", true)
	journal.open()
	var departing: Variant = await open_work(journal)
	if not is_instance_valid(departing): return
	await key(KEY_F8, true)
	var original_store: RefCounted = feedback.store
	feedback.store = RefusingNotes.new()
	feedback.note.text = "Synthetic refusal fixture; preserve this draft"
	await key(KEY_ESCAPE, true)
	check(feedback.backdrop.visible and paused and is_instance_valid(departing), "Refused note save keeps the feedback rescue layer and viewer alive")
	departing.queue_free(); await settle()
	check(is_instance_valid(feedback.layer) and feedback.layer.get_parent() == feedback and feedback.backdrop.visible and paused, "Refused save during Window destruction keeps a usable root rescue layer")
	check(feedback.note.text == "Synthetic refusal fixture; preserve this draft", "Refused-save destruction retains exact synthetic note text")
	feedback.store = original_store
	feedback.close_panel(); await settle()
	check(not feedback.backdrop.visible and not paused and not root.get_node("PlaytestData")._feedback_visible, "Restored store closes the retained rescue and restores the original pause state")
	journal.close()
