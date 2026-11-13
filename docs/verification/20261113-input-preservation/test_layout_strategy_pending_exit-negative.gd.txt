extends "res://tests/test_layout_strategy_notebook_ui.gd"
## A fresh editor's unsubmitted text must participate in the real close guard.
func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()):
		push_error("Use an isolated verification profile."); quit(1); return
	await settle()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var path: String = "user://pending-exit-%s-%d/notebook.json" % [locale,Time.get_ticks_usec()]
		var host: Control = await open_notebook(path)
		check(not host.session.has_work() and not host.workspace.is_dirty(),"Fresh workspace starts clean "+locale)
		var edit: LineEdit = host.query_group.get_line_edit()
		edit.grab_focus()
		await settle()
		edit.select_all()
		await key(KEY_2,false,false,50)
		await settle()
		check(edit.text == "2" and host.session.draft().query_group == 1,"Real typing remains pending before OS close "+locale)
		host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await settle()
		check(host.leave_count == 0 and host.exit_overlay.visible,"OS close guards fresh pending numeric work "+locale)
		check(host.session.draft().query_group == 2 and host.workspace.is_dirty(),"Close commits visible input before loss decision "+locale)
		check(host.session.rows().is_empty(),"Closing never simulates a run "+locale)
		if host.exit_overlay.visible:
			check(host.exit_question.text.contains("未保存") if locale == "zh_CN" else host.exit_question.text.contains("unsaved"),"Guard describes unsaved work "+locale)
			host.cancel_quit()
			await settle()
			check(root.gui_get_focus_owner() == edit,"Cancel returns to originating numeric editor "+locale)
			host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
			await settle()
			host.save_and_exit()
			check(host.leave_count == 1 and FileAccess.file_exists(path),"Save and exit writes notebook before leaving "+locale)
			if FileAccess.file_exists(path):
				var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				check(saved.states.scan_batch.draft.query_group == 2,"Saved notebook contains typed value "+locale)
		host.queue_free()
		current_scene = null
		await settle()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"pending numeric exit %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
