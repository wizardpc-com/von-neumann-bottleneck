extends SceneTree
## Presenter/viewport checks. Codec, storage and actual host authority have their
## own suites; the bounded text here is deliberately an unparsed UI fixture.
const BoardWindow = preload("res://src/layout_chapter/layout_scoreboard_window.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const InstrumentThemeScript = preload("res://src/ui/instrument_theme.gd")
var checks: int = 0
var failures: Array[String] = []
var fixture_code: String = "VNB4C1:" + "x".repeat(4089)

class Underlay:
	extends Control
	var shortcuts: int = 0
	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.is_command_or_control_pressed() and event.keycode == KEY_Z):
			shortcuts += 1

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func settle() -> void:
	for frame: int in range(8): await process_frame

func key(window: Window, code: Key, unicode: int = 0, command: bool = false, shift: bool = false) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.unicode = unicode
		event.pressed = down
		event.ctrl_pressed = command and OS.get_name() != "macOS"
		event.meta_pressed = command and OS.get_name() == "macOS"
		event.shift_pressed = shift
		window.push_input(event,true)
		await process_frame

func select_row(board: Window, id: String) -> void:
	var item: TreeItem = board.table.get_root().get_first_child()
	while item != null:
		if item.get_metadata(0) == id:
			item.select(0)
			board._selection_changed()
			return
		item = item.get_next()
	check(false,"Expected fixture row "+id)

func fits(board: Window, control: Control, context: String) -> void:
	var rect: Rect2 = control.get_global_rect()
	check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= board.size.x + 1 and rect.end.y <= board.size.y + 1,
		context+" fits actual "+str(board.size)+" window: "+str(rect))

func capture(board: Window, suffix: String) -> void:
	if "--layout-challenge-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var path: String = "user://layout-challenge-"+suffix+".png"
	check(board.get_texture().get_image().save_png(path) == OK,"Save actual challenge Window frame "+suffix)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))

func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var mode: Node = root.get_node("GameMode")
	mode.set_mode(&"test")
	var state: Node = root.get_node("LayoutChapter")
	var game_before: Dictionary = state.game_snapshot()
	var test_before: Dictionary = {
		"drafts":state.test_drafts.duplicate(true),"named":state.test_named.duplicate(true),
		"solutions":state.test_solutions.duplicate(true),"bonuses":state.test_bonuses.duplicate(true)}
	var clipboard_before: String = DisplayServer.clipboard_get() if DisplayServer.get_name() != "headless" else ""
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await exercise(locale,clipboard_before)
	check(state.game_snapshot() == game_before,"Presenter actions do not change Game progress, drafts or named designs")
	check(state.test_drafts == test_before.drafts and state.test_named == test_before.named and state.test_solutions == test_before.solutions and state.test_bonuses == test_before.bonuses,
		"Presenter actions do not change Test progress, drafts or named designs")
	if DisplayServer.get_name() != "headless": DisplayServer.clipboard_set(clipboard_before)
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout challenge window %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func exercise(locale: String, clipboard_before: String) -> void:
	var underlay := Underlay.new()
	underlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var skin := Theme.new()
	skin.default_font_size = 18
	InstrumentThemeScript.apply_to(skin)
	underlay.theme = skin
	root.add_child(underlay)
	var opener := Button.new()
	opener.text = "Fixture opener"
	underlay.add_child(opener)
	var board: Window = BoardWindow.new()
	board.level_id = "mixed"
	underlay.add_child(board)
	var events: Dictionary = {"shared":{},"share_objective":"","checks":0,"pinned":"","clear":0,"dismiss":0,"target_share":0}
	board.dismissed.connect(func() -> void:
		events.dismiss += 1
		opener.grab_focus())
	board.share_requested.connect(func(row: Dictionary, objective: String) -> void:
		events.shared = row.duplicate(true)
		events.share_objective = objective
		board.show_code(fixture_code,"Fixture · "+locale))
	board.share_target_requested.connect(func() -> void:
		events.target_share += 1
		board.show_code(str(board.target_state.code),"Retained target fixture"))
	board.clear_challenge_requested.connect(func() -> void: events.clear += 1)
	board.import_target_requested.connect(func(code: String) -> void: events.pinned = code)
	board.import_requested.connect(func(code: String) -> void:
		events.checks += 1
		board.show_import_result({
			"ok":code == fixture_code,"code":fixture_code if code == fixture_code else "",
			"message":"可设为目标" if locale == "zh_CN" and code == fixture_code else "Target ready" if code == fixture_code else "无法读取挑战码" if locale == "zh_CN" else "Could not read this code",
			"row":events.shared,"objective":"space"}))
	var fixture_rows: Array[Dictionary] = [
		{"id":"current","title":"Current fixture","design":Catalog.starter_design()},
		{"id":"named:passing","title":"Target fixture","design":Catalog.reference_solution("mixed")}]
	board.refresh(fixture_rows)
	board.popup_centered(Vector2i(1040,560))
	await settle()
	check(board.visible and board.exclusive and board.table_page.visible and not board.code_page.visible,"Ranking entry stays exclusive and begins on the table "+locale)
	select_row(board,"named:passing")
	check(not board.share_button.disabled and not board.challenge_button.disabled,"Passing real fixture permits sharing and targeting "+locale)
	var row_before: Dictionary = board.selected_row().duplicate(true)
	board.order.select(2)
	board.order.item_selected.emit(2)
	board.share_button.pressed.emit()
	await settle()
	check(board.code_page.visible and not board.table_page.visible and not board.code_edit.editable,"Share uses the same Window and selectable read-only code "+locale)
	check(events.shared == row_before and events.share_objective == "space","Share preserves the selected measured row and chosen objective "+locale)
	check(board.code_edit.text == fixture_code and board.code_edit.text.to_utf8_buffer().size() == 4096,"Maximum allowed code remains complete in the presenter "+locale)
	if DisplayServer.get_name() != "headless":
		check(DisplayServer.clipboard_get() == clipboard_before,"Opening share never writes or reads an automatic paste "+locale)
		board.code_copy_button.pressed.emit()
		check(DisplayServer.clipboard_get() == fixture_code,"Explicit Copy places the complete text on the real clipboard "+locale)
		DisplayServer.clipboard_set(clipboard_before)
	await key(board,KEY_ESCAPE)
	await settle()
	check(board.visible and board.table_page.visible and board.gui_get_focus_owner() == board.share_button,"Code Escape returns focus to Share without closing the board "+locale)
	var target: Dictionary = {"state":"active","title":"温".repeat(40),"objective":"space","code":fixture_code,"row":row_before.duplicate(true),
		"storage_message":"目标本次有效；保存失败，重试。" if locale == "zh_CN" else "Target active for this visit; saving failed. Retry."}
	board.set_target_state(target)
	target.title = "Caller mutation"
	target.row.cycles = -123
	check(board.target_state.title != target.title and board.target_state.row.cycles != -123,"Target presentation state is deeply detached "+locale)
	var target_caption: String = board.target_label.text
	board.order.select(0)
	board.order.item_selected.emit(0)
	check(board.target_state.objective == "space" and board.target_label.text == target_caption,"Table sort never changes the pinned objective "+locale)
	board.popup_centered(Vector2i(760,420))
	await settle()
	check(board.size == Vector2i(760,420),"Table supports its actual minimum Window size "+locale)
	for control: Control in [board.table,board.order,board.name_edit,board.restore_button,board.challenge_button,board.share_button,board.import_button,board.target_code_button,board.clear_target_button,board.target_storage_note]:
		fits(board,control,"Table "+str(control.name)+" "+locale)
	await capture(board,locale+"-table")
	board.target_code_button.pressed.emit()
	await settle()
	check(events.target_share == 1 and board.code_page.visible,"Retained target code has a discoverable share entry "+locale)
	board.code_back_button.pressed.emit()
	await settle()
	check(board.gui_get_focus_owner() == board.target_code_button,"Code Back returns to the target-code action "+locale)
	board.clear_target_button.pressed.emit()
	check(events.clear == 1 and board.target_state.state == "active","Clear requests host action without altering target state itself "+locale)
	board.import_button.pressed.emit()
	await settle()
	check(board.code_edit.text.is_empty() and board.code_edit.editable and board.code_pin_button.disabled and board.code_check_button.disabled,"Import starts empty with no stale confirmation "+locale)
	if DisplayServer.get_name() != "headless": check(DisplayServer.clipboard_get() == clipboard_before,"Import entry leaves clipboard unchanged "+locale)
	board.close_button.grab_focus()
	await key(board,KEY_TAB)
	check(board.gui_get_focus_owner() == board.code_edit,"Tab enters the code editor "+locale)
	await key(board,KEY_TAB)
	check(board.gui_get_focus_owner() == board.code_back_button,"Tab skips unavailable Check and Set target "+locale)
	await key(board,KEY_TAB,0,false,true)
	check(board.gui_get_focus_owner() == board.code_edit,"Shift-Tab returns to the editor "+locale)
	await key(board,KEY_A,97)
	await key(board,KEY_B,0x4e2d)
	var edited: String = board.code_edit.text
	check(edited.contains("a") and edited.contains("中"),"Code editor receives ordinary and committed Unicode text "+locale)
	await key(board,KEY_Z,0,true)
	check(board.code_edit.text != edited,"Built-in TextEdit Undo remains available inside the modal "+locale)
	check(underlay.shortcuts == 0,"Modal text Undo and Escape do not reach underlying workbench "+locale)
	board.code_edit.select_all()
	board.code_edit.insert_text_at_caret("invalid")
	await settle()
	board.code_check_button.grab_focus()
	await key(board,KEY_ENTER)
	await settle()
	check(events.checks == 1 and board.code_pin_button.disabled and not board.code_message.text.is_empty(),"Explicit Check displays failure and cannot pin "+locale)
	board.code_edit.select_all()
	board.code_edit.insert_text_at_caret(fixture_code)
	await settle()
	board.code_check_button.pressed.emit()
	check(events.checks == 2 and not board.code_pin_button.disabled and board.code_message.text.contains(str(row_before.traffic)),"Checked preview exposes real supplied metrics and enables confirmation "+locale)
	check(board.code_pin_button.text == ("替换目标" if locale == "zh_CN" else "Replace target"),"Replacing the one retained target is explicit "+locale)
	board.code_edit.insert_text_at_caret(" ")
	await settle()
	check(board.code_pin_button.disabled,"Any text edit invalidates an earlier valid preview "+locale)
	board._pin_import()
	check(events.pinned.is_empty(),"Invalidated preview cannot confirm by calling the action "+locale)
	board.show_import_result({"ok":true,"code":fixture_code,"message":"Late reply","row":row_before,"objective":"space"})
	check(board.code_pin_button.disabled,"An older import reply cannot validate edited text "+locale)
	board.code_edit.select_all()
	board.code_edit.insert_text_at_caret(fixture_code)
	await settle()
	board.code_check_button.pressed.emit()
	board.code_pin_button.grab_focus()
	await key(board,KEY_ENTER)
	check(events.pinned == fixture_code and board.visible,"Import confirmation emits the checked code and leaves outcome to the host "+locale)
	for control: Control in [board.code_edit,board.code_message,board.code_check_button,board.code_pin_button,board.code_back_button,board.close_button]:
		fits(board,control,"Code "+str(control.name)+" "+locale)
	await capture(board,locale+"-import")
	if DisplayServer.get_name() != "headless":
		DisplayServer.clipboard_set(fixture_code)
		board.code_edit.grab_focus()
		board.code_edit.select_all()
		await key(board,KEY_V,0,true)
		check(board.code_edit.text == fixture_code,"Actual clipboard paste preserves the full challenge text "+locale)
		DisplayServer.clipboard_set(clipboard_before)
	board.code_edit.grab_focus()
	await key(board,KEY_ESCAPE)
	await settle()
	check(board.table_page.visible and board.gui_get_focus_owner() == board.import_button,"Import Escape returns to its initiating control "+locale)
	board.set_target_state({"state":"stale","title":"Old target","objective":"cycles","code":fixture_code,"storage_message":""})
	check(board.target_code_button.visible and not board.target_code_button.disabled and board.target_label.text.contains("Old target"),"Inactive retained target remains identifiable and shareable "+locale)
	board.target_code_button.pressed.emit()
	await settle()
	check(not board.code_edit.editable and board.code_edit.text == fixture_code,"Stale code is displayed unchanged without presenter revalidation "+locale)
	for control: Control in [board.code_edit,board.code_message,board.code_copy_button,board.code_back_button]:
		fits(board,control,"Share "+str(control.name)+" "+locale)
	await capture(board,locale+"-share")
	board.code_back_button.pressed.emit()
	board.set_target_state({"state":"none","storage_message":""})
	await settle()
	check(not board.target_code_button.is_visible_in_tree() and not board.target_storage_note.visible,"Cleared state removes only target-specific presentation "+locale)
	await key(board,KEY_ESCAPE)
	await settle()
	check(not board.visible and events.dismiss == 1 and root.gui_get_focus_owner() == opener,"Table Escape dismisses exactly once and restores host focus "+locale)
	check(underlay.shortcuts == 0,"All code and table Escape events stay within the Window "+locale)
	underlay.queue_free()
	await settle()
