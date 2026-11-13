extends "res://tests/test_recovery_game_input.gd"
## Only departure is intercepted; all editing and confirmation use viewport input.
class LeaveProbe:
	extends "res://experiments/creation/workbench.gd"
	var leave_calls: int = 0
	func finish_leave() -> void: leave_calls += 1

func field(handle: String) -> LineEdit:
	return ui.find_child(handle,true,false) as LineEdit

func action(handle: String) -> void:
	await press(ui.find_child(handle,true,false))

func enter(handle: String, value: String) -> void:
	await press(field(handle))
	await key(KEY_A,true)
	await type_text(value)
	await settle()
	check(field(handle).text == value,"Keyboard enters exact text in "+handle)

func dialog_press(dialog: ConfirmationDialog, accept: bool) -> void:
	await settle()
	var target: Button = dialog.get_ok_button() if accept else dialog.get_cancel_button()
	await click(Vector2(dialog.position)+target.get_global_rect().get_center())
	await settle()

func custom_guard() -> ConfirmationDialog:
	return ui.find_child("PendingCustomExampleProtection",true,false) as ConfirmationDialog

func fit_capture_window() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() == "headless" or "--recovery-capture" not in OS.get_cmdline_user_args():
		await settle()
		return
	var stable: int = 0
	for attempt: int in 60:
		DisplayServer.window_set_size(Vector2i(1280,720))
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var frame: Image = root.get_texture().get_image()
		stable = stable+1 if frame != null and frame.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,"Actual creation viewport settles at 1280x720")
	await settle()

func shot(label: String, dialog: Window = null) -> void:
	if DisplayServer.get_name() == "headless" or "--recovery-capture" not in OS.get_cmdline_user_args(): return
	await fit_capture_window()
	await settle(12)
	RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image() if dialog == null else dialog.get_texture().get_image()
	var dimensions: Vector2i = Vector2i(1280,720) if dialog == null else dialog.size
	check(frame != null and frame.get_size() == dimensions,"Capture retains actual viewport dimensions: "+label)
	var locale: String = root.get_node("Localization").current_locale()
	if frame != null:
		check(frame.save_png(evidence_root+locale+"-"+label+".png") == OK,"Capture the actual unmodified viewport: "+label)

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.get_node("TaskNavigation").pending = ""
		ui = load("res://experiments/creation/workbench.tscn").instantiate()
		ui.set_script(LeaveProbe)
		root.add_child(ui)
		await settle(12)
		await fit_capture_window()
		ui.session.close()
		var path: String = "user://pending-example-input/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
		check(ui.session.open(path).writable,"Acquire isolated writable example profile")
		ui.change_task(0)
		await settle()
		check(ui.session.save() == OK,"Save clean baseline")
		var before: Dictionary = ui.session.data.duplicate(true)
		var saved_bytes: String = FileAccess.get_file_as_string(path)
		for text: String in ["C D C","A X"]:
			await enter("CustomExample",text)
			await action("Journey")
			var guard: ConfirmationDialog = custom_guard()
			check(guard != null and guard.visible and ui.leave_calls == 0,"Clean departure protects unadded legal and invalid example text")
			if guard != null and guard.visible:
				if text == "C D C": await shot("custom-example-protection",guard)
				await dialog_press(guard,false)
				check(field("CustomExample").text == text and field("CustomExample").has_focus(),"Cancel returns focus and exact unadded text")
				if text == "C D C": await shot("custom-example-cancel-focus")
			check(ui.session.data == before and FileAccess.get_file_as_string(path) == saved_bytes,"Pending example does not alter draft or persisted format")
		# Save draft keeps transient text; Escape from the button takes the leave route.
		await action("SaveDraft")
		await key(KEY_ESCAPE)
		var saved_guard: ConfirmationDialog = custom_guard()
		check(saved_guard != null and saved_guard.visible and ui.leave_calls == 0,"Escape after Save draft still protects the unadded text")
		if saved_guard != null and saved_guard.visible: await dialog_press(saved_guard,false)
		check(field("CustomExample").text == "A X" and ui.session.data == before,"Saving and canceling departure never adds the pending example")
		# Rebuilds preserve pending text, including read-only presentation.
		ui.toggle_language(); await settle()
		ui.toggle_language(); await settle()
		check(field("CustomExample").text == "A X","Language rebuild preserves pending custom text")
		ui.writable = false
		ui.rebuild_editor_preserving_inputs(); await settle()
		ui._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		var readonly_guard: ConfirmationDialog = custom_guard()
		check(readonly_guard != null and readonly_guard.visible,"OS-close route protects pending custom text in read-only state")
		if readonly_guard != null and readonly_guard.visible: await dialog_press(readonly_guard,false)
		ui.writable = true
		ui.rebuild_editor_preserving_inputs(); await settle()
		# Explicit Add is still required and clears the pending field.
		await enter("CustomExample","D C D")
		await action("AddExample")
		check(field("CustomExample").text.is_empty() and ui.session.data.draft.examples.back() == [3,2,3],"Explicit Add alone commits the new passage")
		# A changed collection invalidates the old binding, even with an unchanged editor.
		await action("EditExample0")
		await enter("CustomExample","D D")
		await action("AddExample")
		await action("EditExample0")
		await enter("SampleEditText","D C C")
		await action("ApplySampleEdit")
		check(ui.session.data.draft.examples[0] == [3,2,2] and ui.sample_edit_index == -1,"Reselecting unchanged text rebinds a changed collection before replacement")
		# Pending text can recover after unrelated additions by explicitly reselecting its source.
		await action("EditExample0")
		await enter("SampleEditText","B C B")
		await enter("CustomExample","C C")
		await action("AddExample")
		await action("ApplySampleEdit")
		check(ui.session.data.draft.examples[0] == [3,2,2] and field("SampleEditText").text == "B C B","Changed collection first rejects stale replacement without losing text")
		var caret: int = field("SampleEditText").caret_column
		await action("EditExample0")
		check(field("SampleEditText").text == "B C B" and field("SampleEditText").caret_column == caret,"Explicit same-source reselection renews binding without changing pending text or caret")
		# A second collection mutation must invalidate even the renewed binding.
		ui.session.data.draft.examples.append([0,3]); ui.edit_draft()
		await action("ApplySampleEdit")
		check(ui.session.data.draft.examples[0] == [3,2,2] and ui.sample_edit_index == 0,"A later collection mutation still rejects replacement after rebinding")
		await action("EditExample0")
		await action("ApplySampleEdit")
		check(ui.session.data.draft.examples[0] == [1,2,1] and ui.sample_edit_index == -1,"Pending text can be explicitly rebound then replaced after unrelated additions")
		# Rebinding never authorizes a changed source or invalid pending symbols.
		await action("EditExample0")
		await enter("SampleEditText","D B")
		ui.session.data.draft.examples[0] = [2,2,3]; ui.edit_draft()
		await action("EditExample0")
		await action("ApplySampleEdit")
		check(ui.session.data.draft.examples[0] == [2,2,3] and field("SampleEditText").text == "D B","Reselecting a changed source cannot redirect pending replacement")
		await action("CancelSampleEdit")
		await action("EditExample0")
		await enter("SampleEditText","A X")
		ui.session.data.draft.examples.append([3,0]); ui.edit_draft()
		await action("EditExample0")
		await action("ApplySampleEdit")
		check(ui.session.data.draft.examples[0] == [2,2,3] and field("SampleEditText").text == "A X","Explicit rebinding still rejects invalid pending symbols")
		await action("CancelSampleEdit")
		check(ui.session.save() == OK,"Save committed example for reselection checks")
		await action("EditExample0")
		for text: String in ["C D C","A X"]:
			await enter("SampleEditText",text)
			await action("EditExample0")
			check(field("SampleEditText").text == text and ui.sample_edit_index == 0,"Reselecting same passage preserves pending text")
			await action("EditExample1")
			check(field("SampleEditText").text == text and ui.sample_edit_index == 0 and field("SampleEditText").has_focus(),"Cross-passage selection keeps pending text and focuses its original editor")
			if text == "C D C": await shot("sample-reselection-preserved")
		await action("CancelSampleEdit")
		await action("EditExample1")
		check(ui.sample_edit_index == 1,"Explicit cancellation allows another passage")
		await action("CancelSampleEdit")
		await action("EditExample0")
		await action("EditExample1")
		check(ui.sample_edit_index == 1,"Unchanged passage switches without a guard")
		# Three pending text types chain before the ordinary dirty-draft guard.
		await enter("SampleEditText","B X")
		await enter("CustomExample","C X")
		(ui.find_child("DraftTabs",true,false) as TabContainer).current_tab = 2
		await settle()
		await enter("Initial","D X")
		ui.session.data.draft.seed += 1; ui.edit_draft()
		var calls: int = ui.leave_calls
		ui.request_leave(true); await settle()
		check(ui.sample_leave_dialog.visible,"Edited passage remains first in the departure chain")
		await dialog_press(ui.sample_leave_dialog,true)
		var chained: ConfirmationDialog = custom_guard()
		check(chained != null and chained.visible and ui.leave_calls == calls,"Discarding edited passage still protects the unadded example")
		if chained != null and chained.visible: await dialog_press(chained,true)
		check(ui.initial_leave_dialog.visible,"Discarding unadded example still protects invalid Initial")
		if ui.initial_leave_dialog.visible: await dialog_press(ui.initial_leave_dialog,true)
		check(ui.leave_dialog.visible and ui.leave_calls == calls,"Discarding transient text still asks about dirty draft")
		if ui.leave_dialog.visible: await dialog_press(ui.leave_dialog,false)
		check(field("CustomExample").text.is_empty() and ui.session.dirty and ui.leave_calls == calls,"Explicit text discard leaves unsaved draft open on cancellation")
		check(ui.session.save() == OK,"Clean profile before final custom-only discard")
		(ui.find_child("DraftTabs",true,false) as TabContainer).current_tab = 0
		await settle()
		await enter("CustomExample","B C")
		ui._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST); await settle()
		var final_guard: ConfirmationDialog = custom_guard()
		if final_guard != null and final_guard.visible: await dialog_press(final_guard,true)
		check(ui.leave_calls == calls+1 and not ui.leaving_to_hub,"Explicit custom-text discard continues original OS-close route")
		ui.queue_free(); await settle()
	await finish()
