extends SceneTree
## Viewport input proves constrained addresses remain player choices, not edits.
const Model = preload("res://experiments/representation_region/model.gd")
var checks: int = 0
var failures: int = 0
var ui
var capture: bool = false
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 5: await process_frame
func fit_window(dimensions: Vector2i) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = dimensions; root.content_scale_size = dimensions
	if not capture:
		await settle()
		return
	var stable: int = 0
	for attempt: int in 60:
		root.size = dimensions; root.content_scale_size = dimensions
		DisplayServer.window_set_size(dimensions)
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var frame: Image = root.get_texture().get_image()
		stable = stable + 1 if frame != null and frame.get_size() == dimensions else 0
		if stable >= 5: break
	check(stable >= 5,"Rendered window stabilizes at requested dimensions")
	await settle()
func screenshot(label: String) -> void:
	if not capture: return
	await fit_window(Vector2i(1280,720))
	RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image()
	check(frame != null and frame.get_size() == Vector2i(1280,720),"Screenshot retains actual 1280x720 pixels")
	if frame == null: return
	var folder: String = "res://.godot/representation-split-captures"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"Capture directory available")
	check(frame.save_png(folder.path_join(label+".png")) == OK,"Unmodified viewport capture saved: "+label)
func key(code: Key, command: bool = false) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		event.ctrl_pressed = command and OS.get_name() != "macOS"
		event.meta_pressed = command and OS.get_name() == "macOS"
		root.push_input(event,true); await process_frame
func click(control: Control) -> void:
	check(root.get_visible_rect().encloses(control.get_global_rect()),"Clicked control fits the viewport: "+str(control.name))
	var at: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at
	root.push_input(motion,true)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at; event.global_position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		root.push_input(event,true); await process_frame
	await settle()
func enter_address(value: String, submit: bool = true) -> void:
	await click(ui.split_at.get_line_edit())
	await key(KEY_A,true)
	for character: String in value:
		var event := InputEventKey.new(); event.unicode = character.unicode_at(0); event.pressed = true
		root.push_input(event,true); await process_frame
	if submit: await key(KEY_ENTER)
	await settle()
func select_block(index: int) -> void:
	await click(ui.blocks)
	await key(KEY_HOME)
	for i: int in index: await key(KEY_DOWN)
	await settle()
	check(ui.selected_block == index,"Viewport tree navigation selects requested block")
func range_is(first: int,last: int,value: int) -> void:
	check(ui.split_at.min_value == first and ui.split_at.max_value == last and ui.split_at.value == value,"Split input uses selected block interior and retains/clamps pending value")
	check(ui.split_range.text == "%d–%d" % [first,last] and not ui.split_button.disabled,"Legal interval is visible beside enabled Split")
func layout(context: String) -> void:
	for id: String in ["SplitAt","SplitRange","Split","Merge"]:
		var control := ui.find_child(id,true,false) as Control
		check(control != null and control.is_visible_in_tree() and root.get_visible_rect().encloses(control.get_global_rect()),context+": control is visible inside window: "+id)
	check(ui.split_at.get_parent().size.y <= 44,context+": split row keeps normal height")
	check(not ui.split_range.get_global_rect().intersects(ui.split_button.get_global_rect()),context+": range/reason does not overlap Split")
	var font: Font = ui.split_range.get_theme_font("font")
	check(font.get_string_size(ui.split_range.text,HORIZONTAL_ALIGNMENT_LEFT,-1,ui.split_range.get_theme_font_size("font_size")).x <= ui.split_range.size.x,context+": full reason fits without clipping")
func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile.")
		quit(2)
		return
	capture = "--representation-split-capture" in OS.get_cmdline_user_args()
	if capture and DisplayServer.get_name() == "headless":
		push_error("--representation-split-capture requires a rendering display.")
		quit(2)
		return
	var localization: Node = root.get_node("Localization")
	var original_locale: String = localization.current_locale()
	var nav: Node = root.get_node("TaskNavigation")
	var original_pending: String = nav.pending
	nav.pending = ""
	ProjectSettings.set_setting("game/reduced_motion",true)
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		ui = load("res://experiments/representation_region/region.tscn").instantiate()
		root.add_child(ui)
		await fit_window(Vector2i(1280,720))
		var range_control := ui.find_child("SplitRange",true,false) as Label
		check(range_control != null,"Split has a visible local range/reason control")
		if range_control == null:
			# Negative control must fail assertions, never missing-property script errors.
			await click(ui.split_button)
			print("OLD SPLIT left: value=",ui.split_at.value," disabled=",ui.split_button.disabled," plan=",ui.plan)
			check(ui.split_at.value > ui.plan[0].start and ui.split_at.value < ui.plan[0].end and not ui.split_button.disabled,"After splitting, pending address is inside selected left block")
			await select_block(1)
			print("OLD SPLIT right: value=",ui.split_at.value," disabled=",ui.split_button.disabled)
			check(ui.split_at.value > ui.plan[1].start and ui.split_at.value < ui.plan[1].end and not ui.split_button.disabled,"Selecting right block makes a valid pending split available")
			ui.queue_free(); await settle()
			continue
		range_is(1,63,16)
		ui.run_current()
		var trace: String = ui.history[0].traces[0].canonical_signature()
		await click(ui.split_button)
		check(ui.plan.size() == 2 and ui.plan[0].end == 16,"Only explicit Split partitions at the pending address")
		range_is(1,15,15)
		var before: Array = ui.plan.duplicate(true)
		var undo_count: int = ui.undo_stack.size()
		await select_block(1)
		range_is(17,63,17)
		await screenshot(locale+"-legal-range")
		check(ui.plan == before and ui.undo_stack.size() == undo_count and ui.history.size() == 1 and ui.history[0].traces[0].canonical_signature() == trace,"Selection/range refresh never edits draft, undo history or recorded evidence")
		await enter_address("40")
		range_is(17,63,40)
		check(ui.plan == before,"Typing a valid multi-digit address does not split automatically")
		ui.refresh_actions(); range_is(17,63,40)
		localization.set_locale("en" if locale == "zh_CN" else "zh_CN")
		ui.reload_localized_scene(); await settle(); range_is(17,63,40)
		localization.set_locale(locale)
		ui.reload_localized_scene(); await settle(); range_is(17,63,40)
		await click(ui.split_button)
		var split_plan: Array = ui.plan.duplicate(true)
		check(ui.plan.size() == 3 and ui.plan[1].end == 40 and ui.plan[2].start == 40,"Viewport text entry and explicit click use the player's chosen cut")
		await click(ui.undo_button); range_is(17,63,39)
		check(ui.plan == before,"Undo restores original two blocks")
		await click(ui.redo_button); range_is(17,39,39)
		check(ui.plan == split_plan,"Redo restores exact chosen split without input clamping edits")
		ui.change_task(1); await settle(); range_is(1,63,16)
		ui.change_task(0); await settle(); range_is(17,39,17)
		check(ui.plan == split_plan,"Returning to task preserves draft and selected block with valid input")
		ui.edit_plan(Model.split(Model.initial_plan(),0,1))
		await select_block(0)
		check(ui.split_button.disabled and not ui.split_at.editable and ui.split_range.text == ("Only 1 byte" if locale == "en" else "仅1字节"),"Single-byte block visibly explains unavailable split")
		layout(locale+" single byte")
		await screenshot(locale+"-single-byte")
		var eight: Array[Dictionary] = []
		for i: int in 8: eight.append({"start":i*8,"end":(i+1)*8,"codec":"raw"})
		ui.edit_plan(eight); await settle()
		check(ui.split_button.disabled and not ui.split_at.editable and ui.split_range.text == ("8-block limit" if locale == "en" else "已达8块"),"Eight-block cap has visible local reason")
		layout(locale+" limit 1280x720")
		await screenshot(locale+"-block-limit")
		await fit_window(Vector2i(1600,900)); layout(locale+" limit 1600x900")
		await fit_window(Vector2i(1280,720))
		ui.undo(); await settle()
		await select_block(1)
		check(not ui.split_button.disabled and ui.split_at.editable,"Leaving unavailable block restores input and Split")
		check(ui.history.size() == 1 and ui.history[0].traces[0].canonical_signature() == trace,"All editor operations preserve prior authoritative evidence")
		layout(locale+" enabled")
		# Independent fixture: clicking Split must commit the text on focus loss.
		ui.edit_plan(Model.initial_plan()); await settle()
		var undo_before_click: int = ui.undo_stack.size()
		var history_before_click: int = ui.history.size()
		check(ui.split_at.value != 40,"Direct-click fixture begins with a different committed address")
		await enter_address("40",false)
		check(ui.plan == Model.initial_plan() and ui.undo_stack.size() == undo_before_click,"Unsubmitted text leaves the draft and Undo untouched")
		await click(ui.split_button)
		check(ui.plan.size() == 2 and ui.plan[0].end == 40 and ui.plan[1].start == 40,"Clicking Split without Enter uses freshly typed 40 rather than the old address")
		check(ui.undo_stack.size() == undo_before_click+1,"Direct mouse submission adds exactly one undoable split")
		check(ui.history.size() == history_before_click and ui.history[0].traces[0].canonical_signature() == trace,"Direct mouse submission preserves recorded evidence")
		ui.queue_free(); await settle()
	localization.set_locale(original_locale); nav.pending = original_pending
	print("Representation split input checks: %d; failures: %d" % [checks,failures])
	if failures == 0: print("PASS: representation split input")
	quit(0 if failures == 0 else 1)
