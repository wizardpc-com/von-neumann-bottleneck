extends "res://tests/test_layout_strategy_ui.gd"
## Real viewport input, locally replayed targets and independent target saving.
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const TargetStore = preload("res://experiments/layout_strategy/challenge_store.gd")
const WriterLease = preload("res://experiments/candidate_session/writer_lease.gd")

class LeaveProbe:
	extends "res://experiments/layout_strategy/lab.gd"
	var leave_count: int = 0
	func _finish_quit() -> void:
		leave_count += 1

func check(ok: bool, message: String) -> void:
	super.check(ok,message)
	if not ok: print("CHECK_FAIL ",checks,": ",message)

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()):
		push_error("Use isolated verification for scheduling challenge UI.")
		quit(1)
		return
	await settle()
	var official: Node = root.get_node("LayoutChapter")
	var game: Dictionary = official.game_snapshot().duplicate(true)
	var files: Dictionary = protected_files()
	var mode: StringName = root.get_node("GameMode").current_mode
	var clipboard: String = DisplayServer.clipboard_get() if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD) else ""
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await challenge_loop(locale)
		await stale_target(locale)
		await protected_target(locale)
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD): DisplayServer.clipboard_set(clipboard)
	check(official.game_snapshot() == game and protected_files() == files,"Experimental challenge UI preserves official data and completion")
	check(root.get_node("GameMode").current_mode == mode,"Experimental challenge UI never switches Game/Test")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy challenge UI %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func open_host(path: String) -> Control:
	var host := LeaveProbe.new()
	host.notebook_path = path.path_join("notebook.json")
	host.challenge_path = path.path_join("targets.json")
	root.add_child(host)
	current_scene = host
	await settle()
	await resize_viewport(Vector2i(1280,720))
	return host

func snapshot(host: Control) -> Dictionary:
	return {
		"workspace":host.workspace.snapshot().duplicate(true),
		"states":host.session._states.duplicate(true),
		"next_id":host.session._next_id,
		"kept_selection":host._kept_selection.duplicate(true),
	}

func popup_key(window: Window, code: Key, command: bool = false, unicode: int = 0) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.unicode = unicode
		event.meta_pressed = command and OS.get_name() == "macOS"
		event.ctrl_pressed = command and OS.get_name() != "macOS"
		event.pressed = down
		window.push_input(event,true)
		await process_frame
	await settle()

func popup_activate(window: Window, control: BaseButton) -> void:
	if window.main_page.visible and window.main_page.is_ancestor_of(control):
		window.main_scroll.ensure_control_visible(control)
		await settle()
	control.grab_focus()
	await settle()
	var ready: bool = window.visible and control.is_visible_in_tree() and not control.disabled \
		and window.gui_get_focus_owner() == control
	check(ready,"Challenge action has visible enabled keyboard focus: "+str(control.name))
	if ready: await popup_key(window,KEY_ENTER)

func import_preview(window: Window, text: String) -> void:
	if not window.main_page.visible:
		await popup_activate(window,window.back_button)
	await popup_activate(window,window.import_button)
	window.code_edit.text = text
	window.code_edit.text_changed.emit()
	await settle()
	await popup_activate(window,window.check_button)

func pending_number(control: SpinBox, text: String) -> void:
	var edit: LineEdit = control.get_line_edit()
	edit.grab_focus()
	# SpinBox refreshes its editor after focus changes. Prepare pending text only
	# after that refresh; submission below still uses actual viewport key input.
	await settle()
	edit.text = text
	edit.text_changed.emit(text)
	await settle()

func numeric_state(host: Control, control: SpinBox) -> String:
	var focused: Control = root.gui_get_focus_owner()
	return " [text=%s value=%s draft=%s runs=%d focus=%s]" % [
		control.get_line_edit().text,control.value,host.session.draft(),
		host.session.rows().size(),focused.get_path() if focused != null else "none"]

func numeric_input(host: Control, locale: String) -> void:
	var before: int = host.session.rows().size()
	var edit: LineEdit = host.query_group.get_line_edit()
	edit.grab_focus()
	await settle()
	edit.select_all()
	await key(KEY_2,false,false,50)
	await settle()
	check(edit.text == "2","Viewport text input prepares visible pending numeric text "+locale+numeric_state(host,host.query_group))
	check(host.session.draft().query_group == 1,"Typing a pending number has not yet edited the recipe "+locale+numeric_state(host,host.query_group))
	await key(KEY_ENTER,true)
	check(host.session.rows().size() == before+1 and host.session.selected_entry().plan.query_group == 2,
		"Focused numeric Cmd/Ctrl+Enter commits and runs exactly once "+locale+numeric_state(host,host.query_group))
	edit = host.record_tile.get_line_edit()
	edit.grab_focus()
	await settle()
	edit.select_all()
	await key(KEY_1,false,false,49)
	await settle()
	check(edit.text == "1","Viewport text input prepares the separate pending tile "+locale+numeric_state(host,host.record_tile))
	await key(KEY_KP_ENTER,true)
	var actual: Dictionary = host.session.selected_entry()
	check(host.session.rows().size() == before+2 and actual.plan.record_tile == 1,
		"Focused keypad Enter commits the separate query tile exactly once "+locale+numeric_state(host,host.record_tile))
	check(actual.correct and actual.metrics.first_request_cycles == 339 and actual.metrics.total_cycles == 1368,
		"Numeric shortcut measures real group2/tile1 metrics, not the previous draft "+locale+numeric_state(host,host.record_tile))
	await pending_number(host.query_group,"1+2")
	await key(KEY_ENTER,true)
	check(host.session.selected_entry().plan.query_group == 3 and int(host.query_group.value) == 3,
		"Numeric expression uses installed SpinBox submission before running "+locale+numeric_state(host,host.query_group))
	await pending_number(host.query_group,"999")
	await key(KEY_KP_ENTER,true)
	check(host.session.selected_entry().plan.query_group == 8 and int(host.query_group.value) == 8,
		"Out-of-range numeric text is visibly clamped before measurement "+locale+numeric_state(host,host.query_group))
	await pending_number(host.query_group,"invalid")
	var previous: Dictionary = host.session.draft()
	await key(KEY_ENTER,true)
	check(host.session.selected_entry().plan == previous and int(host.query_group.value) == previous.query_group and host.query_group.get_line_edit().text == str(previous.query_group),
		"Invalid numeric expression cannot create a different measured plan "+locale+numeric_state(host,host.query_group))
	before = host.session.rows().size()
	await pending_number(host.query_group,"3")
	await key(KEY_ENTER)
	check(host.session.draft().query_group == 3 and host.session.rows().size() == before,
		"Plain numeric Enter commits editing without running a plan "+locale+numeric_state(host,host.query_group))
	await pending_number(host.query_group,"2")
	await click(host.run_button)
	check(host.session.selected_entry().plan.query_group == 2 and host.session.selected_entry().metrics.total_cycles == 1368,
		"Mouse Run commits the pending visible numeric value "+locale+numeric_state(host,host.query_group))
	host.tabs.current_tab = 3
	await settle()
	await click(host.first_cap)
	await pending_number(host.first_limit,"350")
	before = host.session.rows().size()
	await key(KEY_ENTER,true)
	check(host.session.goal().first_limit == 350 and host.session.rows().size() == before+1,
		"Known Q1 cap editor commits before a single shortcut run "+locale+numeric_state(host,host.first_limit))
	await click(host.copy_cap)
	await pending_number(host.copy_limit,"0")
	await key(KEY_KP_ENTER,true)
	check(host.session.goal().copy_limit == 0 and int(host.copy_limit.value) == 0,
		"Known copy cap editor accepts an inclusive zero cap before running "+locale+numeric_state(host,host.copy_limit))
	var count: int = host.session.rows().size()
	var repeated := InputEventKey.new()
	repeated.keycode = KEY_ENTER
	repeated.pressed = true
	repeated.echo = true
	repeated.meta_pressed = OS.get_name() == "macOS"
	repeated.ctrl_pressed = OS.get_name() != "macOS"
	root.push_input(repeated,true)
	await settle()
	check(host.session.rows().size() == count,"Shortcut auto-repeat does not run again "+locale)
	host.notebook_name.grab_focus()
	await key(KEY_ENTER,true)
	check(host.session.rows().size() == count,"Notebook name editor cannot trigger a recipe run "+locale)
	var saved_plan: Dictionary = host.session.draft()
	host.query_group.get_line_edit().grab_focus()
	await key(KEY_F10)
	await settle()
	await key(KEY_ENTER,true)
	check(host.session.draft() == saved_plan and host.session.rows().size() == count,"Settings owns numeric Enter shortcuts "+locale)
	await key(KEY_ESCAPE)
	await settle()
	host.tabs.current_tab = 0
	await settle()

func challenge_loop(locale: String) -> void:
	var path: String = "user://challenge-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	var host: Control = await open_host(path)
	await numeric_input(host,locale)
	var selected: Dictionary = host.session.selected_entry()
	check(selected.plan.query_group == 2 and selected.plan.record_tile == 1,"Challenge fixture selects an actual improvable response "+locale)
	host.query_group.value = 3
	host.session.set_goal({"objective":"traffic","first_limit":-1,"copy_limit":-1})
	host.refresh()
	var state: Dictionary = snapshot(host)
	await click(host.challenge_button)
	var window: Window = host.challenge_window
	check(window.visible and window.exclusive and window.main_page.visible,"Challenges opens one exclusive secondary surface "+locale)
	await popup_activate(window,window.share_button)
	var shared: Dictionary = Code.inspect(window.code_edit.text)
	check(shared.ok and shared.envelope.plan.query_group == 2 and shared.envelope.goal.objective == "traffic",
		"Share remeasures selected input under personal goal even when draft differs "+locale)
	check(snapshot(host) == state,"Sharing changes no draft, Undo, selected evidence or notebook "+locale)
	await challenge_frame(host,window,locale+"-share-1280",false)
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		await popup_activate(window,window.copy_button)
		check(DisplayServer.clipboard_get() == shared.code,"Explicit copy exports the complete canonical code "+locale)
	await popup_key(window,KEY_ESCAPE)
	check(window.main_page.visible and window.gui_get_focus_owner() == window.share_button,"Code Escape returns to its share action "+locale)
	await popup_activate(window,window.starter_button)
	var starter: Dictionary = Code.starter("scan_batch")
	print("CHALLENGE_UI_DIAGNOSTIC ",JSON.stringify({
		"phase":"starter_preview","locale":locale,"visible":window.visible,
		"main":window.main_page.visible,"code":window.code_page.visible,
		"length":window.code_edit.text.length(),"accept_disabled":window.accept_button.disabled,
		"preview_ok":window._preview.get("ok",false),"message":window.code_message.text,
	}))
	check(not window.accept_button.disabled and window.code_edit.text == starter.code,"Opt-in starter is genuinely remeasured into a preview "+locale)
	check(snapshot(host) == state and not host.challenges.target("scan_batch").active,"Starter preview does not adopt or load a solution "+locale)
	await popup_activate(window,window.accept_button)
	var target: Dictionary = host.challenges.target("scan_batch")
	print("CHALLENGE_UI_DIAGNOSTIC ",JSON.stringify({
		"phase":"after_accept","locale":locale,"active":target.active,"saved":target.saved,
		"storage":host.challenges.storage_status,"reason":host.challenges.storage_reason,
		"main":window.main_page.visible,"code":window.code_page.visible,"verdict":host._challenge_verdict,
	}))
	check(target.active and target.saved and target.code == starter.code,"Explicit acceptance retains a real immutable target "+locale)
	check(snapshot(host) == state and not FileAccess.file_exists(host.notebook_path),"Accepting changes no exploration or notebook bytes "+locale)
	check(host._challenge_verdict.get("status","missing") == "improved" and host.challenge_summary.text.contains("350"),
		"Selected339/1368 response beats target2456 under its own350/0 rule "+locale)
	if not target.active:
		current_scene = null
		host.queue_free()
		await settle()
		return
	await popup_activate(window,window.reply_button)
	var reply: Dictionary = Code.inspect(window.code_edit.text)
	check(reply.ok and reply.envelope.goal == starter.envelope.goal and reply.envelope.plan == shared.envelope.plan,
		"Reply shares the measured attempt under original target goal, not personal RAM goal "+locale)
	await import_preview(window,starter.code)
	var approved: Dictionary = window._preview.duplicate(true)
	window.code_edit.text += "x"
	window.code_edit.text_changed.emit()
	await settle()
	check(window.accept_button.disabled,"Editing valid text immediately invalidates preview authority "+locale)
	window.show_preview(approved)
	window._accept()
	check(window.accept_button.disabled and host.challenges.target("scan_batch").code == starter.code,
		"A stale preview callback or direct confirm cannot accept edited text "+locale)
	await import_preview(window,Code.starter("scan_serial").code)
	check(window.accept_button.disabled and window.code_message.text.contains("serial" if host.english else "逐次"),
		"Foreign workload code identifies its required workload without switching "+locale)
	check(host.session.task_id == "scan_batch" and snapshot(host) == state,"Foreign preview leaves all exploration unchanged "+locale)
	await import_preview(window,starter.code)
	await challenge_modals(host,locale)
	await popup_activate(window,window.back_button)
	await challenge_frame(host,window,locale+"-target-1280",false)
	await popup_activate(window,window.close_button)
	host.session.set_goal({"objective":"traffic","first_limit":307,"copy_limit":0})
	host.refresh()
	check(host._challenge_verdict.get("status","missing") == "improved" and host.challenges.target("scan_batch").code == starter.code,
		"Personal objective and stricter307 cap cannot weaken or replace the accepted challenge rule "+locale)
	await resize_viewport(Vector2i(960,640))
	for control: Control in [host.run_button,host.history_table,host.challenge_button,host.challenge_summary]:
		fits(control,"Minimum active challenge "+str(control.name)+" "+locale)
	await challenge_frame(host,null,locale+"-active-960",false)
	await click(host.challenge_button)
	window = host.challenge_window
	window.size = Vector2i(720,540)
	await settle()
	check(window.get_visible_rect().encloses(window.code_edit.get_global_rect()) or window.main_page.visible,
		"Challenge window reaches its declared minimum surface "+locale)
	await import_preview(window,starter.code)
	for control: Control in [window.code_edit,window.code_message,window.check_button,window.accept_button,window.back_button]:
		check(window.get_visible_rect().grow(1).encloses(control.get_global_rect()),"Minimum code control fits "+str(control.name)+" "+locale)
	await challenge_frame(host,window,locale+"-import-960",true)
	await popup_activate(window,window.back_button)
	var draft: Dictionary = host.session.draft()
	await popup_activate(window,window.inspect_button)
	check(not window.visible and host.tabs.current_tab == 1 and host.session.draft() == draft,
		"Explicit target inspection selects genuine evidence without replacing draft "+locale)
	check(host.session.selected_entry().trace_id == starter.entry.trace_id,"Target evidence is a fresh matching canonical Trace "+locale)
	host.tabs.current_tab = 0
	await settle()
	await click(host.challenge_button)
	await popup_activate(window,window.restore_button)
	check(host.session.draft() == starter.entry.plan,"Explicit target restore applies the inspected recipe "+locale)
	host.run_button.grab_focus()
	await key(KEY_Z,true)
	check(host.session.draft() == draft,"One Undo recovers the exact pre-target draft "+locale)
	await failure_retry(host,window,path,locale)
	current_scene = null
	host.queue_free()
	await settle()

func challenge_modals(host: Control, locale: String) -> void:
	var window: Window = host.challenge_window
	window.code_edit.grab_focus()
	var code: String = window.code_edit.text
	var state: Dictionary = snapshot(host)
	var editor_id: int = window.code_edit.get_instance_id()
	await popup_key(window,KEY_X,false,120)
	await popup_key(window,KEY_Z,true)
	check(window.code_edit.text == code and snapshot(host) == state,"Code text Undo restores text without undoing a recipe "+locale)
	check(window.accept_button.disabled,"Text Undo does not resurrect an invalidated preview "+locale)
	await popup_activate(window,window.check_button)
	window.code_edit.grab_focus()
	await popup_key(window,KEY_ENTER,true)
	check(snapshot(host) == state,"Challenge code editor owns Command Enter; no hidden lab run "+locale)
	if window.code_edit.text != code:
		window.code_edit.text = code
		window.code_edit.text_changed.emit()
		await popup_activate(window,window.check_button)
		window.code_edit.grab_focus()
	await popup_key(window,KEY_F8)
	var moments: Node = root.get_node("PlaytestMoments")
	check(moments.panel.visible and moments.panel.get_viewport() == window,"F8 feedback opens within the challenge Window "+locale)
	await popup_key(window,KEY_ESCAPE)
	check(not moments.panel.visible and window.visible and window.code_page.visible and window.gui_get_focus_owner() == window.code_edit,
		"Feedback Escape preserves preview and exact code-editor focus "+locale)
	await popup_key(window,KEY_F10)
	await settle()
	var mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(mode.settings_layer) and not window.visible,"F10 deliberately suspends the challenge Window for Settings "+locale)
	if is_instance_valid(mode.settings_layer):
		var choice: OptionButton = mode.settings_layer.find_child("LanguageChoice",true,false)
		await choose(choice,1-choice.selected)
		check(is_instance_valid(mode.settings_layer) and current_scene == host,"Settings locale route retains the same experiment "+locale)
		await key(KEY_ESCAPE)
		await settle()
	check(window.visible and window.code_page.visible and window.code_edit.get_instance_id() == editor_id and window.code_edit.text == code,
		"Settings return keeps the exact editor, code and its text Undo history "+locale)
	check(window.gui_get_focus_owner() == window.code_edit and not window.accept_button.disabled and snapshot(host) == state,
		"Settings language return preserves checked preview, exploration and focus "+locale)
	root.get_node("Localization").set_locale(locale)
	host.reload_localized_scene()
	await settle()

func failure_retry(host: Control, window: Window, path: String, locale: String) -> void:
	var old_bytes: PackedByteArray = FileAccess.get_file_as_bytes(host.challenge_path)
	var goal: Dictionary = {"objective":"traffic","first_limit":350,"copy_limit":0}
	var proposal: Dictionary = Code.create("scan_batch",Model.starter_plan(),goal)
	var writer_path: String = host.challenge_path+".writer/challenges.json"
	var lease := WriterLease.new(writer_path)
	check(lease.owns(writer_path),"Hold a genuine competing target writer "+locale)
	await click(host.challenge_button)
	var state: Dictionary = snapshot(host)
	await import_preview(window,proposal.code)
	await popup_activate(window,window.accept_button)
	check(host.challenges.target("scan_batch").pending and not host.challenges.target("scan_batch").saved and host.challenges.is_dirty(),
		"Failed acceptance leaves the exact proposal temporary and unsaved "+locale)
	check(FileAccess.get_file_as_bytes(host.challenge_path) == old_bytes and snapshot(host) == state,
		"Failed target saving preserves original disk bytes and exploration "+locale)
	check(window.retry_button.visible and window.recover_button.visible and window.storage_label.text.contains("temporary" if host.english else "暂时"),
		"Temporary target offers exact retry and cooperative recovery "+locale)
	await popup_activate(window,window.recover_button)
	check(lease.owns(writer_path) and host.challenges.storage_reason == "busy","UI recovery cannot steal a live writer "+locale)
	await popup_activate(window,window.close_button)
	host.session.set_goal({"objective":"cycles","first_limit":900,"copy_limit":100})
	host.refresh()
	host.save_workspace()
	check(host.challenges.is_dirty() and FileAccess.get_file_as_bytes(host.challenge_path) == old_bytes,
		"Notebook save does not silently save targets or clear their pending state "+locale)
	host.query_group.value = 4
	await settle()
	host.request_quit()
	await settle()
	check(host.exit_overlay.visible and host.exit_target_retry.visible and host.exit_save.visible,
		"Exit separately exposes pending target retry and Notebook saving "+locale)
	host.exit_target_retry.grab_focus()
	var before_locale: Dictionary = snapshot(host)
	root.get_node("Localization").set_locale("en" if locale == "zh_CN" else "zh_CN")
	host.reload_localized_scene()
	await settle()
	check(root.gui_get_focus_owner() == host.exit_target_retry and snapshot(host) == before_locale and host.challenges.target("scan_batch").code == proposal.code,
		"Locale reload returns exact pending-target retry focus without saving or running "+locale)
	root.get_node("Localization").set_locale(locale)
	host.reload_localized_scene()
	await settle()
	await click(host.exit_save)
	check(host.leave_count == 0 and host.exit_overlay.visible and host.challenges.is_dirty(),
		"Saving Notebook from exit cannot discard an unsaved target proposal "+locale)
	lease.release()
	await click(host.exit_target_retry)
	check(not host.challenges.is_dirty() and host.challenges.target("scan_batch").code == proposal.code,
		"Explicit retry saves the exact original traffic goal despite unrelated personal edits "+locale)
	var written: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(host.challenge_path))
	check(written.targets.scan_batch == proposal.code and written.targets.scan_batch != Code.starter("scan_batch").code,
		"Disk actually changes to the proposed canonical code "+locale)
	check(host.session.goal().objective == "cycles" and host.session.goal().first_limit == 900,
		"Target retry leaves the personal goal untouched "+locale)
	await click(host.exit_cancel)
	await click(host.challenge_button)
	window = host.challenge_window
	await challenge_frame(host,window,locale+"-saved-retry-960",true)
	old_bytes = FileAccess.get_file_as_bytes(host.challenge_path)
	lease = WriterLease.new(writer_path)
	check(lease.owns(writer_path),"Reacquire actual writer for failed removal "+locale)
	state = snapshot(host)
	await popup_activate(window,window.clear_button)
	var removed: Dictionary = host.challenges.target("scan_batch")
	check(removed.code.is_empty() and removed.pending and FileAccess.get_file_as_bytes(host.challenge_path) == old_bytes,
		"Failed clear stays a pending removal while preserving the previous saved code "+locale)
	check(snapshot(host) == state and window.storage_label.text.contains("removal" if host.english else "清除"),
		"Pending-removal feedback is distinct from a temporary target and changes no exploration "+locale)
	lease.release()
	await popup_activate(window,window.retry_button)
	check(not host.challenges.is_dirty() and JSON.parse_string(FileAccess.get_file_as_string(host.challenge_path)).targets.is_empty(),
		"Retry commits the exact removal proposal "+locale)
	await popup_activate(window,window.close_button)
	check(path == host.challenge_path.get_base_dir(),"Challenge fixture remains within its isolated path "+locale)

func stale_target(locale: String) -> void:
	var path: String = "user://challenge-stale-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	var envelope: Dictionary = Code.starter("scan_batch").envelope.duplicate(true)
	envelope.model = "layout-schedule-older"
	var text: String = Code.PREFIX+JSON.stringify(envelope,"",true)
	var store := TargetStore.new()
	store.storage_path = path.path_join("targets.json")
	check(store.write({"version":2,"targets":{"scan_batch":text}}).ok,"Persist supported stale code without a scalar score "+locale)
	var host: Control = await open_host(path)
	await click(host.challenge_button)
	var window: Window = host.challenge_window
	check(not host.challenges.target("scan_batch").active and window.inspect_button.disabled and window.restore_button.disabled,
		"Stale retained target has no current rank, evidence or restore authority "+locale)
	await popup_activate(window,window.target_code_button)
	check(window.code_edit.text == text and not window.code_edit.editable,"Stale retained code stays exactly copyable "+locale)
	var state: Dictionary = snapshot(host)
	await popup_key(window,KEY_ESCAPE)
	await popup_key(window,KEY_ESCAPE)
	check(not window.visible and snapshot(host) == state,"Two-level Escape exits stale code and window without changing work "+locale)
	current_scene = null
	host.queue_free()
	await settle()

func protected_target(locale: String) -> void:
	var path: String = "user://challenge-protected-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	check(DirAccess.make_dir_recursive_absolute(path) == OK,"Create isolated future-version target fixture "+locale)
	var original: String = "{\"version\":99,\"targets\":{}}"
	var file := FileAccess.open(path.path_join("targets.json"),FileAccess.WRITE)
	check(file != null,"Open isolated protected target fixture "+locale)
	if file == null: return
	file.store_string(original)
	file.close()
	var host: Control = await open_host(path)
	check(host.challenges.storage_status == "read_only","Unsupported future target file is protected "+locale)
	var before: Dictionary = snapshot(host)
	await click(host.challenge_button)
	var window: Window = host.challenge_window
	await import_preview(window,Code.starter("scan_batch").code)
	await popup_activate(window,window.accept_button)
	var target: Dictionary = host.challenges.target("scan_batch")
	check(target.active and target.pending and not target.saved and host.challenges.storage_status == "read_only",
		"Valid acceptance over a protected file is an explicit temporary target "+locale)
	check(window.storage_label.text.contains("protected" if host.english else "保护") and window.storage_label.text.contains("temporary" if host.english else "本次"),
		"Pending proposal retains visible file-protection and temporary-state explanations "+locale)
	check(not window.retry_button.visible and not window.recover_button.visible,
		"Permanent protection offers no futile retry or stopped-writer recovery "+locale)
	host.retry_challenge_save()
	check(host.challenges.storage_status == "read_only" and host.challenges.target("scan_batch").code == target.code and FileAccess.get_file_as_string(host.challenge_path) == original,
		"Retry cannot erase protection, exact proposal or original bytes "+locale)
	check(snapshot(host) == before and window.storage_label.text.contains("protected" if host.english else "保护"),
		"Protected retry preserves exploration and still explains the true state "+locale)
	await popup_activate(window,window.close_button)
	host.request_quit()
	await settle()
	check(host.exit_overlay.visible and not host.exit_target_retry.visible and host.exit_question.text.contains("protected" if host.english else "保护"),
		"Exit names protected pending targets without a misleading retry action "+locale)
	host.exit_cancel.grab_focus()
	await key(KEY_ESCAPE)
	current_scene = null
	host.queue_free()
	await settle()

func challenge_frame(_host: Control, window: Window, suffix: String, minimum: bool) -> void:
	if "--layout-challenge-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image = window.get_texture().get_image() if window != null else root.get_texture().get_image()
	var expected: Vector2i = window.size if window != null else Vector2i(960,640) if minimum or suffix.ends_with("-960") else Vector2i(1280,720)
	check(image.get_size() == expected,"Challenge raw frame dimensions "+suffix+": "+str(image.get_size()))
	var path: String = "user://layout-challenge-"+suffix+".png"
	check(image.save_png(path) == OK,"Save challenge raw frame "+suffix)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))
