extends SceneTree

const C = preload("res://src/layout_chapter/layout_catalog.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func settle() -> void:
	for frame: int in range(6): await process_frame

func select_row(board: Window, id: String) -> void:
	var item: TreeItem = board.table.get_root().get_first_child()
	while item != null:
		if item.get_metadata(0) == id:
			item.select(0)
			board._selection_changed()
			return
		item = item.get_next()
	check(false,"Expected row "+id)

func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	var state: Node = root.get_node("LayoutChapter")
	var mode: Node = root.get_node("GameMode")
	mode.set_mode(&"test")
	root.size = Vector2i(1280,720)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		state.challenge_store = preload("res://src/layout_chapter/layout_challenge_store.gd").new()
		state.test_solutions.clear()
		state.test_named.clear()
		state.test_drafts.clear()
		var saved: Dictionary = C.reference_solution("fields")
		state.save_named("fields","My fast layout",saved)
		state.game_named["fields"] = {"Private Game design":saved.duplicate(true)}
		var game_before: Dictionary = state.game_snapshot()
		root.get_node("TaskNavigation").pending = "chapter_4/fields"
		var host = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
		root.add_child(host)
		await settle()
		var original: Dictionary = host.design.duplicate(true)
		host.score_button.pressed.emit()
		await settle()
		var board: Window = host.score_window
		check(board.visible and board.exclusive,"Open rankings as an exclusive window "+locale)
		check(board.rows.size() == 2 and state.test_solutions.is_empty(),"Comparison neither imports Game schemes nor awards progress "+locale)
		check(board.table.get_global_rect().end.x <= board.size.x,"Rankings fit the window "+locale)
		check(board.restore_button.get_global_rect().end.y <= board.size.y,"Restore action stays visible "+locale)
		select_row(board,"named:My fast layout")
		check(not board.challenge_button.disabled and not board.restore_button.disabled,"Saved passing design enables challenge and restore "+locale)
		board.challenge_button.pressed.emit()
		check(not board.visible and not host.personal_challenge.is_empty(),"Pin a personal target without changing draft "+locale)
		check(host.design == original and state.test_solutions.is_empty(),"Pinning leaves design and completion unchanged "+locale)
		host._run_all()
		check(host.results.has_node("LayoutChallengeResult") and not host.results.get_node("LayoutChallengeResult").text.contains("成功") and not host.results.get_node("LayoutChallengeResult").text.contains("beaten"),"Failing official cases cannot beat a target "+locale)
		host._open_scoreboard()
		await settle()
		select_row(board,"named:My fast layout")
		board.restore_button.pressed.emit()
		await settle()
		check(host.design == state.normalize(saved) and host.stale,"Restore becomes an unverified draft "+locale)
		host._undo(false)
		await settle()
		check(host.design == original,"Undo restores the exact prior experiment "+locale)
		host._undo(true)
		await settle()
		host._run_all()
		check(host.results.get_node("LayoutChallengeResult").text.contains("持平") or host.results.get_node("LayoutChallengeResult").text.contains("tied"),"An equal measurement is a tie, not a new record "+locale)
		host._open_scoreboard()
		await settle()
		board.name_edit.text = "Kept experiment"
		board._request_save()
		check(state.test_named.fields.has("Kept experiment"),"Board saves through existing named scheme storage "+locale)
		var preserved: Dictionary = state.test_named.fields["Kept experiment"].duplicate(true)
		host.design.recipe = C.starter_design().recipe
		board.name_edit.text = "Kept experiment"
		board._request_save()
		check(state.test_named.fields["Kept experiment"] == preserved,"A repeated name cannot silently replace a kept scheme "+locale)
		check(state.game_snapshot() == game_before,"All Test actions preserve Game data "+locale)
		if "--layout-score-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			host._open_scoreboard()
			await settle()
			await RenderingServer.frame_post_draw
			var path: String = "user://layout-scores-"+locale+".png"
			check(board.get_texture().get_image().save_png(path) == OK,"Save actual GPU rankings frame "+locale)
			print("CAPTURE: "+ProjectSettings.globalize_path(path))
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		board.push_input(escape)
		await settle()
		check(not board.visible and is_instance_valid(host),"Escape closes only rankings "+locale)
		host.queue_free()
		await settle()
	await challenge_success_checks()
	await persistent_save_checks()
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout rankings UI %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func challenge_success_checks() -> void:
	var state: Node = root.get_node("LayoutChapter")
	var packed: Dictionary = C.reference_solution("mixed")
	var full: Dictionary = packed.duplicate(true)
	full.strategy = "full"
	var small: Dictionary = packed.duplicate(true)
	small.batch = 1
	state.save_named("mixed","Full copy",full)
	state.save_named("mixed","Packed",packed)
	root.get_node("TaskNavigation").pending = "chapter_4/mixed"
	var host = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host)
	await settle()
	host._open_scoreboard()
	await settle()
	var board: Window = host.score_window
	select_row(board,"named:Full copy")
	board.challenge_button.pressed.emit()
	host.design = packed.duplicate(true)
	host._changed()
	host._run_all()
	var result: String = host.results.get_node("LayoutChallengeResult").text
	check(result.contains("beaten") and result.contains("3919") and result.contains("2495"),"Real all-case faster layout beats pinned cycle target")
	host._open_scoreboard()
	await settle()
	board.order.select(2)
	board.order.item_selected.emit(2)
	select_row(board,"named:Packed")
	board.challenge_button.pressed.emit()
	host.design = small.duplicate(true)
	host._changed()
	host._run_all()
	result = host.results.get_node("LayoutChallengeResult").text
	check(result.contains("beaten") and result.contains("32 → 16"),"Space challenge uses actual peak scratch while requiring all cases to pass")
	if "--layout-score-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		host._open_scoreboard()
		await settle()
		await RenderingServer.frame_post_draw
		var path: String = "user://layout-scores-mixed-en.png"
		check(board.get_texture().get_image().save_png(path) == OK,"Save actual GPU objective tradeoffs")
		print("CAPTURE: "+ProjectSettings.globalize_path(path))
	host.queue_free()
	await settle()

func persistent_save_checks() -> void:
	var mode: Node = root.get_node("GameMode")
	var state: Node = root.get_node("LayoutChapter")
	var save: Node = root.get_node("GlobalSave")
	var directory: String = "user://score-save-"+Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(directory) == OK,"Create isolated persistent ranking fixture")
	save.configure_for_test(directory.path_join("save.json"),directory.path_join("boards.json"))
	mode.set_mode(&"game")
	root.get_node("LocalityChapter").game_completed[&"capstone"] = true
	state.game_drafts.clear()
	state.game_named.clear()
	root.get_node("TaskNavigation").pending = "chapter_4/fields"
	var host = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host)
	await settle()
	host._open_scoreboard()
	await settle()
	host._save_score_design("On disk")
	var persisted: Variant = JSON.parse_string(FileAccess.get_file_as_string(save.storage_path))
	check(persisted is Dictionary and persisted.game.layout.named.fields.has("On disk"),"Game board save reaches existing on-disk schema")
	var expected: Dictionary = host.design.duplicate(true)
	host.score_window.dismiss()
	state.restore_game(persisted.game.layout,false)
	check(state.game_named.fields["On disk"] == expected,"Existing loader restores named recipe without a progression grant")
	check(state.game_solutions.is_empty(),"Loading draft comparison data cannot award completion")
	# A directory at the temporary-file location creates a real write failure.
	check(DirAccess.make_dir_absolute(save.storage_path+".tmp") == OK,"Create isolated write obstruction")
	host._open_scoreboard()
	await settle()
	host.score_window.name_edit.text = "Recover this"
	host.score_window._request_save()
	await settle()
	check(state.game_named.fields.has("Recover this") and not host.score_window.visible,"Failed disk write preserves recipe and releases ranking modal")
	check(is_instance_valid(save._failure_dialog) and save._failure_dialog.visible,"Existing recovery dialog remains accessible after ranking save failure")
	check(host.status.text.contains("writing failed"),"Failure cannot claim a persisted score design")
	save._failure_dialog.hide()
	check(DirAccess.remove_absolute(save.storage_path+".tmp") == OK,"Remove only the test-created obstruction")
	host._open_scoreboard()
	await settle()
	check(host.score_window.name_edit.text == "Recover this","Failed save retains the name for player retry")
	host.score_window._request_save()
	check(host.score_window.name_edit.text.is_empty() and host.score_window.note.text.contains("Design kept"),"Same-name same-design retry succeeds through the player save action")
	persisted = JSON.parse_string(FileAccess.get_file_as_string(save.storage_path))
	check(persisted.game.layout.named.fields.has("Recover this"),"Retry preserves the newly named scheme")
	host.queue_free()
	await settle()
