extends "res://experiments/candidate_input.gd"
## Real selector input edits a single stream without measuring or earning work.
const Lab = preload("res://experiments/service_plan/lab.gd")
const Model = preload("res://experiments/service_plan/model.gd")
const Store = preload("res://experiments/service_plan/session_store.gd")

func format_choice(stream: int) -> OptionButton:
	return ui.find_child("Format"+char(65+stream),true,false) as OptionButton

func choose_last_with_mouse(choice: OptionButton) -> void:
	var popup: PopupMenu = choice.get_popup()
	popup.prefer_native_menu = false
	await press(choice)
	check(popup.visible and popup.is_embedded() and popup.item_count == 4,"Mouse opens the four-row embedded encoding menu")
	if not popup.visible or not popup.is_embedded() or popup.item_count != 4: return
	# These four unwrapped rows have equal height. Use the observed popup size,
	# including its actual upward placement, and dispatch into the root viewport.
	var at: Vector2 = Vector2(popup.position) + Vector2(popup.size.x * 0.5,popup.size.y * 0.875)
	await point(at)
	await click(at)
	check(not popup.visible and choice.selected == 3,"A second mouse click selects the last encoding and closes the menu")

func reselect_current(choice: OptionButton) -> void:
	var popup: PopupMenu = choice.get_popup()
	popup.prefer_native_menu = false
	await press(choice)
	check(popup.visible,"The current encoding can be inspected in its real menu")
	if not popup.visible: return
	popup.grab_focus(); await create_timer(0.2).timeout; await settle()
	await popup_key(popup,KEY_HOME)
	for index: int in range(choice.item_count + 1):
		if popup.get_focused_item() == choice.selected: break
		await popup_key(popup,KEY_DOWN)
	check(popup.get_focused_item() == choice.selected,"The current encoding has real menu focus before Enter")
	if popup.get_focused_item() != choice.selected:
		await popup_key(popup,KEY_ESCAPE)
		return
	await popup_key(popup,KEY_ENTER)
	check(not popup.visible,"Reselecting the current encoding closes its menu")

func keyboard_open_cancel(choice: OptionButton, context: String) -> void:
	var popup: PopupMenu = choice.get_popup()
	popup.prefer_native_menu = false
	for code: Key in [KEY_SPACE,KEY_ENTER]:
		var before: String = JSON.stringify([ui.plan,ui.undo_stack,ui.redo_stack,ui.history,ui.support_plans,ui.session_dirty])
		choice.grab_focus(); await settle()
		await key(code)
		check(popup.visible,context+": a complete Space/Enter keypress opens the encoding menu")
		if popup.visible:
			popup.grab_focus(); await create_timer(0.2).timeout; await settle()
			await popup_key(popup,KEY_ESCAPE)
			check(not popup.visible,context+": Escape closes the keyboard-opened encoding menu")
		check(JSON.stringify([ui.plan,ui.undo_stack,ui.redo_stack,ui.history,ui.support_plans,ui.session_dirty]) == before,context+": keyboard opening and cancellation preserve draft, Undo/Redo, evidence and save state")

func multi_selection() -> void:
	ui.group_list.deselect_all()
	for index: int in [4,6,5]:
		ui.group_list.select(index,false)
		ui.group_list.multi_selected.emit(index,true)

func selection_preserved(context: String) -> void:
	check(ui.selected_group == 5 and ui.group_list.get_selected_items() == PackedInt32Array([4,5,6]),context+": encoding choices retain every selected group and the active group")

func settle_window(context: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for frame: int in 60:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable + 1 if picture != null and picture.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,context+": actual rendered window settles at 1280x720")

func capture_choices(context: String) -> void:
	await settle_window(context+" capture")
	for stream: int in 4:
		var choice := ui.find_child("Format"+char(65+stream),true,false) as OptionButton
		check(choice != null and choice.is_visible_in_tree() and root.get_visible_rect().encloses(choice.get_global_rect()),context+": encoding selector fits 1280x720")
	if DisplayServer.get_name() != "headless" and "--service-encoding-capture" in OS.get_cmdline_user_args():
		await settle(); RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		check(picture.get_size() == Vector2i(1280,720),context+": selector capture retains actual 1280x720 pixels")
		check(picture.save_png(evidence_root+context+".png") == OK,context+": selector screenshot saved")
		var choice: OptionButton = format_choice(0)
		var popup: PopupMenu = choice.get_popup()
		popup.prefer_native_menu = false
		await press(choice); await settle()
		check(popup.visible,context+": actual four-choice encoding menu is open")
		if popup.visible:
			RenderingServer.force_draw(false)
			# A PopupMenu can own a separate viewport; retain its real pixels
			# separately rather than compositing it onto the workbench capture.
			var menu_picture: Image = popup.get_texture().get_image()
			check(menu_picture != null and menu_picture.get_width() > 0,context+": actual popup pixels are available")
			if menu_picture != null: check(menu_picture.save_png(evidence_root+context+"-menu.png") == OK,context+": actual menu screenshot saved")
			popup.grab_focus(); await create_timer(0.2).timeout; await settle()
			await popup_key(popup,KEY_ESCAPE)
			check(not popup.visible,context+": inspecting the menu cancels without an edit")

func _run() -> void:
	if not "VonNeumannBottleneckChecks" in OS.get_user_data_dir():
		push_error("Requires isolated QA profiles"); quit(2); return
	preload("res://src/lab/lab_features.gd").core_journey = true
	root.get_node("GameMode").set_mode(&"game")
	root.get_node("TaskNavigation").pending = ""
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	ProjectSettings.set_setting("game/reduced_motion",true)
	var original_path: String = Store.PATH
	var earned_before: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	for locale: String in ["zh_CN","en"]:
		for persistent: bool in [false,true]:
			root.get_node("Localization").set_locale(locale)
			Store.PATH = "user://service-encoding-"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
			var scene := Lab.new(); scene.persistent_session = persistent
			root.add_child(scene); current_scene = scene; ui = scene; await settle()
			var context: String = locale+("-saved" if persistent else "-temporary")
			await settle_window(context)
			var selectors_exist: bool = true
			for stream: int in 4:
				var choice := scene.find_child("Format"+char(65+stream),true,false) as OptionButton
				check(choice != null,context+": Direct encoding selection is supported; old cyclic Buttons are unsupported")
				if choice == null: selectors_exist = false; continue
				check(choice.item_count == 4 and choice.selected == 0,context+": selector initially reflects the RAW64 draft")
				for index: int in 4:
					check(choice.get_item_text(index) == char(65+stream)+": "+Model.REPRESENTATIONS[index].to_upper(),context+": ordered encoding labels retain stream identity")
			if not selectors_exist:
				scene.queue_free(); await settle(); continue
			scene.run_current()
			var recording: String = JSON.stringify(scene.history[0])
			var supports: Dictionary = scene.support_plans.duplicate(true)
			var initial: Dictionary = scene.plan.duplicate(true)
			multi_selection()
			await choose_last_with_mouse(format_choice(0))
			check(scene.plan.representations == ["rle8","raw64","raw64","raw64"] and scene.undo_stack.size() == 1,context+": selecting RLE8 directly is exactly one edit")
			selection_preserved(context)
			scene.undo(); await settle()
			check(scene.plan == initial and format_choice(0).selected == 0 and scene.redo_stack.size() == 1,context+": one Undo restores RAW64 and synchronizes the selector")
			var redo: String = JSON.stringify(scene.redo_stack)
			var dirty_before: bool = scene.session_dirty
			await keyboard_open_cancel(format_choice(0),context)
			await reselect_current(format_choice(0))
			check(scene.plan == initial and scene.undo_stack.is_empty() and JSON.stringify(scene.redo_stack) == redo and scene.session_dirty == dirty_before,context+": reselecting the current encoding is a no-op that preserves Redo")
			selection_preserved(context)
			scene.redo(); await settle()
			check(scene.plan.representations[0] == "rle8" and format_choice(0).selected == 3,context+": Redo restores the actual selected encoding")
			await choose(format_choice(1),2)
			check(scene.plan.representations == ["rle8","raw8","raw64","raw64"] and scene.undo_stack.size() == 2,context+": a second stream changes independently with one additional edit")
			selection_preserved(context)
			var before_rebuild: Dictionary = scene.plan.duplicate(true)
			var undo_before: int = scene.undo_stack.size()
			var writer_before: RefCounted = scene.writer_lease
			scene.toggle_language(); await settle()
			check(scene.plan == before_rebuild and scene.undo_stack.size() == undo_before and scene.writer_lease == writer_before and scene.persistent_session == persistent,context+": language rebuild only presents the existing draft and preserves save ownership")
			check(format_choice(0).selected == 3 and format_choice(1).selected == 2,context+": language rebuild displays both current encodings without applying another edit")
			selection_preserved(context)
			scene.toggle_language(); await settle()
			await capture_choices(context)
			selection_preserved(context)
			check(scene.history.size() == 1 and JSON.stringify(scene.history[0]) == recording and scene.support_plans == supports,context+": selection, Undo/Redo and rebuild never run or rewrite measured evidence or award work")
			check(scene.public_observation().actions.has("set_format") and not scene.public_observation().actions.has("cycle_format"),context+": public actions describe direct selection")
			if persistent:
				scene.save_session()
				check(not scene.session_dirty and Store.read_session().draft == scene.plan,context+": explicit save retains the ordinary recipe unchanged")
			scene.queue_free(); await settle()
	Store.PATH = original_path
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == earned_before,"Encoding UI changes never modify earned circuit content")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"service encoding choice %d checks, %d failures" % [observations.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
