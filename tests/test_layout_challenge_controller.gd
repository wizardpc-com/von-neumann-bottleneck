extends SceneTree
## Actual host integration, using only an isolated verifier profile.
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
const Code = preload("res://src/layout_chapter/layout_challenge_code.gd")
const Store = preload("res://src/layout_chapter/layout_challenge_store.gd")
var checks: int = 0
var failures: Array[String] = []
var directory: String
var state: Node
var mode: Node

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func settle() -> void:
	for frame: int in 8: await process_frame

func open_host(task: String) -> Control:
	root.get_node("TaskNavigation").pending = "chapter_4/"+task
	var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host)
	await settle()
	return host

func measured(task: String, design: Dictionary, title: String = "Measured target") -> Dictionary:
	var candidates: Array[Dictionary] = [{"id":"fixture","title":title,"design":design}]
	return Board.build_rows(task,candidates)[0]

func preview_code(host: Control, code: String) -> void:
	if host.score_window.code_page.visible: host.score_window.code_back_button.pressed.emit()
	host.score_window.import_button.pressed.emit()
	host.score_window.code_edit.text = code
	await settle()
	host.score_window.code_check_button.pressed.emit()
	await settle()

func full_input_key(key: Key) -> void:
	for pressed: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		await settle()

func feedback_stack(host: Control, locale: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var board: Window = host.score_window
	var moments: Node = root.get_node("PlaytestMoments")
	var previous_tester: bool = bool(ProjectSettings.get_setting("playtest/offline_tester",false))
	ProjectSettings.set_setting("playtest/offline_tester",false)
	var previous_size: Vector2i = board.size
	board.size = Vector2i(760,420)
	await settle()
	board.code_edit.grab_focus()
	await RenderingServer.frame_post_draw
	var text: String = board.code_edit.text
	var focus: Control = board.gui_get_focus_owner()
	check(board.has_focus(),"Actual challenge Window owns focus before F8 "+locale)
	await full_input_key(KEY_F8)
	check(moments.panel.visible and moments.panel.get_viewport() == board,"Ordinary F8 opens feedback within the focused challenge Window "+locale)
	check(board.code_page.visible and board.code_edit.text == text,"Feedback preserves the checked challenge text "+locale)
	check(board.get_visible_rect().encloses(moments.panel.get_global_rect()),"Feedback fits the challenge Window "+locale)
	await full_input_key(KEY_ESCAPE)
	check(not moments.panel.visible and board.visible and board.code_page.visible,"First Escape closes only feedback "+locale)
	check(board.gui_get_focus_owner() == focus and board.code_edit.text == text,"Feedback returns the exact challenge editor focus "+locale)
	board.size = previous_size
	await settle()
	ProjectSettings.set_setting("playtest/offline_tester",previous_tester)

func snapshot(host: Control) -> Dictionary:
	return {
		"design":host.design.duplicate(true), "undo":host.undo_stack.duplicate(true),
		"redo":host.redo_stack.duplicate(true), "case":host.case_index,
		"game":state.game_snapshot(), "test":state.test_solutions.duplicate(true),
		"drafts":state.test_drafts.duplicate(true), "named":state.test_named.duplicate(true),
		"stale":host.stale,
	}

func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run challenge controller checks through scripts/verify-project.py.")
		quit(1)
		return
	directory = "user://challenge-controller-"+Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(directory) == OK,"Create isolated challenge fixtures")
	root.get_node("GlobalSave").configure_for_test(directory.path_join("save.json"),directory.path_join("boards.json"))
	state = root.get_node("LayoutChapter")
	mode = root.get_node("GameMode")
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await transient_loop(locale)
	await persistent_loop()
	for message: String in failures: push_error(message)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"portable challenge controller %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func transient_loop(locale: String) -> void:
	mode.set_mode(&"test")
	state.test_solutions.clear()
	state.test_drafts.clear()
	state.test_named.clear()
	state.challenge_store = Store.new()
	state.challenge_store.storage_path = directory.path_join("game-"+locale+".json")
	var host: Control = await open_host("mixed")
	var packed: Dictionary = Catalog.reference_solution("mixed")
	var full: Dictionary = packed.duplicate(true)
	full.strategy = "full"
	host._remember()
	host.design.batch = 3
	host._changed()
	host._undo(false)
	await settle()
	var before: Dictionary = snapshot(host)
	host._open_scoreboard()
	await settle()
	host._share_score_design(measured("mixed",full),"cycles")
	check(host.score_window.code_page.visible and not host.score_window.code_edit.text.is_empty(),"Share produces a readable code "+locale)
	check(snapshot(host) == before,"Share preserves draft, Undo/Redo and progression "+locale)
	var encoded: Dictionary = Code.encode("mixed",full,"cycles")
	await preview_code(host,encoded.code)
	check(not host.score_window.code_pin_button.disabled,"A real qualifying code has a confirmable preview "+locale)
	check(snapshot(host) == before and host.personal_challenge.is_empty(),"Preview alone cannot set a target or mutate the draft "+locale)
	await feedback_stack(host,locale)
	var poisoned: String = String(encoded.code).replace("\"v\":1","\"cycles\":1,\"v\":1")
	check(poisoned != encoded.code,"Poison fixture adds a claimed metric")
	await preview_code(host,poisoned)
	check(host.score_window.code_pin_button.disabled and snapshot(host) == before,"Claimed metrics reject without state change "+locale)
	var wrong_task: Dictionary = Code.encode("fields",Catalog.reference_solution("fields"),"traffic")
	await preview_code(host,wrong_task.code)
	check(host.score_window.code_pin_button.disabled and snapshot(host) == before,"Wrong task rejects without navigation or mutation "+locale)
	check(host.score_window.code_message.text.contains(Catalog.title("fields")),"Wrong-task feedback identifies where this challenge belongs "+locale)
	await preview_code(host,encoded.code)
	host.score_window.code_pin_button.pressed.emit()
	check(snapshot(host) == before,"Confirmed target preserves the existing experiment and history "+locale)
	check(not host.score_window.visible and host.personal_challenge.objective == "cycles","Confirmed preview closes back to editing with its objective "+locale)
	check(not FileAccess.file_exists(state.challenge_store.storage_path),"Test pin writes no Game challenge file "+locale)
	host._open_scoreboard()
	await settle()
	check(host.score_window.rows.any(func(row: Dictionary) -> bool: return row.id == "challenge"),"Active target is visible as a remeasured recipe "+locale)
	host.score_window.order.select(2)
	host.score_window.order.item_selected.emit(2)
	check(host.personal_challenge.objective == "cycles","Sorting by scratch cannot change the target's cycle objective "+locale)
	host.score_window.dismiss()
	host._restore_scored_design(full)
	await settle()
	check(host.design == state.normalize(full) and host.stale,"Explicit target restore invalidates measurement "+locale)
	host._undo(false)
	await settle()
	check(host.design == before.design,"Restore is one Undo step back to the exact experiment "+locale)
	var stable_code: String = host.personal_challenge.code
	host.queue_free()
	await settle()
	host = await open_host("mixed")
	check(host.personal_challenge.get("code","") == stable_code,"Test target survives a task visit within its process "+locale)
	host.design = full.duplicate(true)
	host._changed()
	host._run_all()
	check(host.results.get_node("LayoutChallengeResult").text.contains("持平") or host.results.get_node("LayoutChallengeResult").text.contains("tied"),"Same real design ties after reopening "+locale)
	host.design = packed.duplicate(true)
	host._changed()
	host._run_all()
	var result: String = host.results.get_node("LayoutChallengeResult").text
	check((result.contains("成功") or result.contains("beaten")) and result.contains("3919") and result.contains("2495"),"Fresh all-case run actually beats the retained target "+locale)
	host.design = Catalog.starter_design()
	host._changed()
	host._run_all()
	result = host.results.get_node("LayoutChallengeResult").text
	check(result.contains("未达成") or result.contains("unfinished"),"Unqualified run never wins with a partial number "+locale)
	host._open_scoreboard()
	await settle()
	if "--layout-challenge-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		host._share_personal_challenge()
		await settle()
		await RenderingServer.frame_post_draw
		var path: String = "user://challenge-import-"+locale+".png"
		check(host.score_window.get_texture().get_image().save_png(path) == OK,"Capture real code page "+locale)
		print("CAPTURE: "+ProjectSettings.globalize_path(path))
		host.score_window.code_back_button.pressed.emit()
		await settle()
		await RenderingServer.frame_post_draw
		path = "user://challenge-target-"+locale+".png"
		check(host.score_window.get_texture().get_image().save_png(path) == OK,"Capture retained target and real measurements "+locale)
		print("CAPTURE: "+ProjectSettings.globalize_path(path))
	var saved_game: Dictionary = state.game_snapshot()
	var old_target: Dictionary = state.challenge_store.read_target("mixed",&"test")
	var unchanged: Dictionary = host.design.duplicate(true)
	mode.set_mode(&"game")
	host._import_challenge_target(encoded.code)
	host._set_personal_challenge(measured("mixed",packed),"space")
	host._restore_scored_design(packed)
	host._clear_personal_challenge()
	check(state.game_snapshot() == saved_game and host.design == unchanged,"Stale mode actions cannot mutate Game or the old draft "+locale)
	check(state.challenge_store.read_target("mixed",&"test") == old_target and not FileAccess.file_exists(state.challenge_store.storage_path),"Stale mode actions cannot move a target into Game "+locale)
	mode.set_mode(&"test")
	host._open_scoreboard()
	host._clear_personal_challenge()
	check(host.personal_challenge.is_empty() and state.challenge_store.read_target("mixed",&"test").entry.is_empty(),"Explicit clear removes only the target "+locale)
	host.queue_free()
	await settle()

func persistent_loop() -> void:
	root.get_node("Localization").set_locale("en")
	mode.set_mode(&"game")
	# Access fixtures only; no imported target is used to earn these prerequisites.
	root.get_node("LocalityChapter").game_completed[&"capstone"] = true
	state.game_drafts.clear()
	state.game_solutions.clear()
	state.challenge_store = Store.new()
	var path: String = directory.path_join("persistent.json")
	state.challenge_store.storage_path = path
	var host: Control = await open_host("fields")
	var fast: Dictionary = Catalog.reference_solution("fields")
	var original: Dictionary = snapshot(host)
	host._set_personal_challenge(measured("fields",fast),"traffic")
	check(FileAccess.file_exists(path) and host.status.text.contains("Target saved"),"Game target reaches its separate sidecar")
	check(snapshot(host) == original and state.game_solutions.is_empty(),"Persisted pin grants no completion and preserves the draft")
	var raw: String = FileAccess.get_file_as_string(path)
	var retained_code: String = host.personal_challenge.code
	host.queue_free()
	await settle()
	state.challenge_store = Store.new()
	state.challenge_store.storage_path = path
	host = await open_host("fields")
	check(host.personal_challenge.code == retained_code and host.personal_challenge.row.traffic == measured("fields",fast).traffic,"Fresh store and scene replay the actual target")
	check(state.game_solutions.is_empty(),"Restart target load cannot grant completion")
	check(DirAccess.make_dir_absolute(path+".tmp") == OK,"Create real temporary-write obstruction")
	host._set_personal_challenge(measured("fields",fast,"Retry target"),"space")
	check(host.personal_challenge.objective == "space" and host.status.text.contains("visit only"),"Write failure retains a visibly temporary active target")
	check(FileAccess.get_file_as_string(path) == raw,"Failed target replacement preserves original disk bytes")
	host.queue_free()
	await settle()
	host = await open_host("fields")
	check(host.personal_challenge.code == retained_code and host.personal_challenge.objective == "traffic","Reopening after failure restores the previously saved target")
	check(host.challenge_storage_message.contains("previously saved") and not host.challenge_storage_message.contains("visit only"),"Persisted fallback is not mislabeled as temporary")
	host._set_personal_challenge(measured("fields",fast,"Retry target"),"space")
	var retry_code: String = host.personal_challenge.code
	check(DirAccess.remove_absolute(path+".tmp") == OK,"Remove only test-created write obstruction")
	host._open_scoreboard()
	await settle()
	var item: TreeItem = host.score_window.table.get_root().get_first_child()
	while item != null:
		if item.get_metadata(0) == "challenge":
			item.select(0)
			host.score_window._selection_changed()
			break
		item = item.get_next()
	check(host.score_window.objective == "cycles" and host.personal_challenge.objective == "space","Retry fixture retains a different sort objective")
	host.score_window.challenge_button.pressed.emit()
	check(host.status.text.contains("Target saved"),"Identical target retry succeeds through ordinary pin")
	check(host.personal_challenge.code == retry_code,"Visible Keep target action retries the byte-exact original objective")
	var reopened = Store.new()
	reopened.storage_path = path
	var stored: Dictionary = reopened.read_target("fields",&"game")
	check(Code.inspect(stored.entry.code,"fields").challenge.objective == "space","Fresh store sees the recovered objective")
	var stale_envelope: Dictionary = Code.decode(stored.entry.code).challenge
	stale_envelope.model = "layout-memory-old"
	var stale_code: String = "VNB4C1:"+JSON.stringify(stale_envelope)
	host.queue_free()
	await settle()
	state.challenge_store = Store.new()
	var empty_path: String = directory.path_join("first-failed.json")
	state.challenge_store.storage_path = empty_path
	host = await open_host("fields")
	check(DirAccess.make_dir_absolute(empty_path+".tmp") == OK,"Obstruct a first target save")
	host._set_personal_challenge(measured("fields",fast),"cycles")
	check(not host.personal_challenge.is_empty(),"A first failed pin is available during its visit")
	host.queue_free()
	await settle()
	host = await open_host("fields")
	check(host.personal_challenge.is_empty() and host.challenge_storage_message.contains("no target was saved"),"Reopen after a first failed save does not claim an active target")
	check(DirAccess.remove_absolute(empty_path+".tmp") == OK,"Remove only empty-store fixture obstruction")
	host.queue_free()
	await settle()
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":1,"targets":{"fields":{"code":stale_code,"title":"Old target"}}}))
	file.close()
	state.challenge_store = Store.new()
	state.challenge_store.storage_path = path
	host = await open_host("fields")
	check(host.personal_challenge.is_empty() and host.challenge_state == "stale","Old condition remains stored without a current score")
	host._open_scoreboard()
	await settle()
	check(not host.score_window.rows.any(func(row: Dictionary) -> bool: return row.id == "challenge"),"Stale target does not enter current ranking")
	host._share_personal_challenge()
	check(host.score_window.code_edit.text == stale_code,"Original incompatible code stays available for recovery")
	host.queue_free()
	await settle()
