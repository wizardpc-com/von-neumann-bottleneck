extends "res://tests/test_layout_strategy_ui.gd"
## Bound product access plus the existing numeric/save/discard guard and dispatch.
class EditionProbe:
	extends "res://experiments/layout_strategy/lab.gd"
	var product: bool = true
	var home_count: int = 0
	var quit_count: int = 0
	func product_profile() -> bool:
		return product
	func _return_to_laboratory() -> void:
		home_count += 1
	func _quit_application() -> void:
		quit_count += 1

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()):
		push_error("Use an isolated verification profile."); quit(1); return
	await settle()
	var game_before: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	for edition: String in ["game", "test"]:
		var profile: String = "EditionGame" if edition == "game" else "EditionTest"
		var path: String = "/qa/VonNeumannBottleneckCandidates/representation/"+profile
		check(Lab.edition_profile(path,edition,"representation",profile),"Exact product profile accepted "+edition)
		check(Lab.edition_profile(path.replace("/","\\"),edition,"representation",profile),"Windows separators accepted "+edition)
		check(not Lab.edition_profile(path,edition,"service",profile),"Wrong primary rejected "+edition)
		check(not Lab.edition_profile(path,"test" if edition == "game" else "game","representation",profile),"Other edition rejected "+edition)
		check(not Lab.edition_profile(path,"","representation",profile),"Unbound source profile rejected "+edition)
		check(not Lab.edition_profile(path+"-other",edition,"representation",profile),"Similar profile suffix rejected "+edition)
		check(not Lab.edition_profile(path+"/..",edition,"representation",profile),"Traversal out of profile rejected "+edition)
		check(not Lab.edition_profile("/ordinary/player",edition,"representation",profile),"Ordinary player directory rejected "+edition)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await departure_loop(locale)
	var standalone: Control = await open_probe("standalone",false)
	check(standalone.exit_button.text == "Exit","Standalone keeps Exit label")
	standalone.request_exit()
	check(standalone.quit_count == 1 and standalone.home_count == 0,"Standalone clean Exit still quits")
	standalone.queue_free(); current_scene = null
	await settle()
	check(root.get_node("LayoutChapter").game_snapshot() == game_before,"Scheduling product routes never award campaign results")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy edition %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func open_probe(label: String, product: bool = true) -> Control:
	var host := EditionProbe.new()
	host.product = product
	var prefix: String = "user://edition-scheduling-%s-%d/" % [label,Time.get_ticks_usec()]
	host.notebook_path = prefix+"notebook.json"
	host.challenge_path = prefix+"challenges.json"
	root.add_child(host); current_scene = host
	await settle()
	await resize_viewport(Vector2i(1280,720))
	return host

func type_group(host: Control, value: int) -> void:
	var editor: LineEdit = host.query_group.get_line_edit()
	editor.grab_focus()
	await settle()
	editor.select_all()
	await key(KEY_2 if value == 2 else KEY_3,false,false,50 if value == 2 else 51)
	await settle()

func departure_loop(locale: String) -> void:
	var host: Control = await open_probe(locale)
	check(host.exit_button.text == ("实验室" if locale == "zh_CN" else "Laboratory"),"Product header returns to laboratory "+locale)
	await type_group(host,2)
	check(host.session.draft().query_group == 1,"Numeric input remains pending "+locale)
	host.exit_button.pressed.emit()
	await settle()
	check(host.exit_overlay.visible and host.session.draft().query_group == 2,"Return commits pending input before guard "+locale)
	check(host.home_count == 0 and host.quit_count == 0,"Guard prevents premature departure "+locale)
	check(host.session.rows().is_empty(),"Departure does not invent a run "+locale)
	check(host.exit_save.text == ("保存并返回" if locale == "zh_CN" else "Save and return"),"Return guard identifies destination "+locale)
	check(host.exit_question.text.contains("返回实验室" if locale == "zh_CN" else "Returning to the laboratory"),"Return question names its destination "+locale)
	host.cancel_quit()
	await settle()
	check(root.gui_get_focus_owner() == host.query_group.get_line_edit(),"Cancel returns numeric focus "+locale)
	host.request_exit()
	host.save_and_exit()
	check(host.home_count == 1 and host.quit_count == 0,"Save dispatches to laboratory only "+locale)
	check(FileAccess.file_exists(host.notebook_path),"Return saves notebook "+locale)
	var before: String = FileAccess.get_file_as_string(host.notebook_path)
	var saved: Dictionary = JSON.parse_string(before)
	check(saved.states.scan_batch.draft.query_group == 2,"Saved notebook retains visible value "+locale)
	host.exit_overlay.hide()
	await type_group(host,3)
	host.request_exit()
	host._confirm_quit()
	check(host.home_count == 2 and host.quit_count == 0,"Discard dispatches to laboratory "+locale)
	check(FileAccess.get_file_as_string(host.notebook_path) == before,"Discard leaves committed notebook bytes intact "+locale)
	host.exit_overlay.hide()
	host.request_exit()
	check(host.exit_overlay.visible,"Unsaved return guard can be reopened "+locale)
	host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(host.exit_save.text == ("保存并退出" if locale == "zh_CN" else "Save and exit"),"OS close replaces return intent with quit "+locale)
	host._confirm_quit()
	check(host.quit_count == 1 and host.home_count == 2,"OS close really dispatches quit, not laboratory "+locale)
	host.queue_free(); current_scene = null
	await settle()
