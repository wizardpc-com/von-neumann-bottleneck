extends Node
## A game-only evidence channel. Nothing here is passed to RemoteFeedback.
const Store = preload("res://src/playtest/offline_store.gd")
const Context = preload("res://src/playtest/offline_context.gd")
const CATEGORIES := ["confusion","control","bug","audiovisual","discovery","other"]
var store = Store.new()
var layer: CanvasLayer
var backdrop: ColorRect
var panel: PanelContainer
var toolbar: HBoxContainer
var note: TextEdit
var category: OptionButton
var history: OptionButton
var info: Label
var status: Label
var preview: TextureRect
var current: Dictionary = {}
var previous_focus: Control
var was_paused: bool = false
var restoring: bool = false
var busy: bool = false
var esc_down: bool = false
var last_export: String = ""
var export_dialog: FileDialog
var emergency_context: Dictionary = {}
var emergency_image: PackedByteArray = PackedByteArray()
var rescue_exported: bool = false

func enabled() -> bool:
	return bool(ProjectSettings.get_setting("playtest/offline_tester",false))

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if not InputMap.has_action("vnb_offline_feedback"):
		InputMap.add_action("vnb_offline_feedback")
		var shortcut := InputEventKey.new(); shortcut.physical_keycode=KEY_F8
		InputMap.action_add_event("vnb_offline_feedback",shortcut)
		var logical_shortcut := InputEventKey.new(); logical_shortcut.keycode=KEY_F8
		InputMap.action_add_event("vnb_offline_feedback",logical_shortcut)
	layer=CanvasLayer.new(); layer.layer=2000; layer.process_mode=Node.PROCESS_MODE_ALWAYS; add_child(layer)
	toolbar=HBoxContainer.new(); toolbar.name="OfflineTesterToolbar"; layer.add_child(toolbar)
	_button(toolbar,"现场反馈 · F8","Feedback · F8",open_panel)
	_button(toolbar,"导出全部反馈","Export all feedback",export_all)
	toolbar.visible=enabled()
	backdrop=ColorRect.new(); backdrop.color=Color(0,0,0,0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter=Control.MOUSE_FILTER_STOP; layer.add_child(backdrop); backdrop.hide()
	panel=PanelContainer.new(); panel.name="OfflineFeedbackPanel"; backdrop.add_child(panel)
	var theme := Theme.new(); theme.default_font_size=18
	preload("res://src/ui/instrument_theme.gd").apply_to(theme); panel.theme=theme
	var margin := MarginContainer.new(); panel.add_child(margin)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	var body := VBoxContainer.new(); margin.add_child(body)
	var heading := HBoxContainer.new(); body.add_child(heading)
	var title := Label.new(); title.text=_t("离线试玩反馈","Offline playtest feedback")
	title.set_meta("locale_pair",["离线试玩反馈","Offline playtest feedback"])
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; heading.add_child(title)
	_button(heading,"返回游戏 · Esc","Back · Esc",close_panel)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus=true; body.add_child(scroll)
	var content := VBoxContainer.new(); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",8); scroll.add_child(content)
	var privacy := Label.new(); privacy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	privacy.text=_t("自动保留游戏截图、当前方案、运行数据和操作记录；文字输入会自动保存。仅在本机，导出后请把一个 ZIP 发给维护者。文件可能包含作品和自由文字，请勿填写密码或私人信息。",
		"Game screenshots, designs, run data and action history stay on this device. Notes save as you type. Send the exported ZIP to the maintainer yourself. It can contain your work and free text; do not enter passwords or private information.")
	privacy.set_meta("locale_pair",["自动保留游戏截图、当前方案、运行数据和操作记录；文字输入会自动保存。仅在本机，导出后请把一个 ZIP 发给维护者。文件可能包含作品和自由文字，请勿填写密码或私人信息。","Game screenshots, designs, run data and action history stay on this device. Notes save as you type. Send the exported ZIP to the maintainer yourself. It can contain your work and free text; do not enter passwords or private information."])
	content.add_child(privacy)
	info=Label.new(); info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; content.add_child(info)
	preview=TextureRect.new(); preview.custom_minimum_size=Vector2(0,110)
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(preview)
	category=OptionButton.new(); category.name="OfflineFeedbackCategory"
	for index: int in CATEGORIES.size(): category.add_item(_category_text(index))
	content.add_child(category)
	category.item_selected.connect(func(_index: int) -> void: _edited())
	note=TextEdit.new(); note.name="OfflineFeedbackNote"; note.custom_minimum_size=Vector2(0,140)
	note.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	note.placeholder_text=_t("哪里卡住了？你想做什么、实际发生了什么？也可以只保存现场，稍后补充。","Where did you get stuck? What did you try, and what happened? You can also keep the scene now and add a note later.")
	content.add_child(note); note.text_changed.connect(_edited)
	var actions := HBoxContainer.new(); content.add_child(actions)
	_button(actions,"记下这条反馈","Mark feedback ready",func() -> void: _save_note(true))
	_button(actions,"记录新的现场","Capture another scene",capture_another)
	history=OptionButton.new(); history.name="OfflineFeedbackHistory"; history.fit_to_longest_item=false; content.add_child(history)
	history.item_selected.connect(func(index: int) -> void: _load_case(str(history.get_item_metadata(index))))
	var footer := HBoxContainer.new(); body.add_child(footer)
	_button(footer,"导出全部反馈（一个 ZIP）","Export all feedback (one ZIP)",export_all)
	_button(footer,"另存到…","Save ZIP as…",choose_export_path)
	_button(footer,"打开文件夹","Open folder",func() -> void:
		OS.shell_show_in_file_manager(last_export if not last_export.is_empty() else ProjectSettings.globalize_path(store.root)))
	status=Label.new(); status.name="OfflineFeedbackStatus"; status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(status)
	_connect_panel_input(backdrop)
	Localization.locale_changed.connect(func(_locale: String) -> void: _refresh_language(layer))
	_refresh_toolbar()

func _local_feedback_available(window: Window) -> bool:
	if not is_instance_valid(window) or window.is_queued_for_deletion(): return false
	var moments: Node = get_node_or_null("/root/PlaytestMoments")
	if moments==null: return false
	for reference: WeakRef in moments.entry_buttons:
		var button: Button = reference.get_ref()
		if not is_instance_valid(button) or button.is_queued_for_deletion() or not button.is_inside_tree(): continue
		if button.get_viewport()!=window or not button.is_visible_in_tree() or not button.can_process() or button.disabled or button.mouse_filter==Control.MOUSE_FILTER_IGNORE: continue
		var bounds: Rect2 = button.get_global_rect()
		var available: Rect2 = window.get_visible_rect()
		var ancestor: Node = button.get_parent()
		while ancestor!=null and ancestor!=window:
			if ancestor is Control and ancestor.clip_contents: available=available.intersection(ancestor.get_global_rect())
			ancestor=ancestor.get_parent()
		if bounds.has_area() and available.encloses(bounds): return true
	return false

func _refresh_toolbar() -> void:
	# Existing host entries open this same panel; its export actions stay available.
	toolbar.visible=get_tree().get_first_node_in_group("laboratory")==null and enabled() and not busy and not backdrop.visible and not _local_feedback_available(_focused_window(get_tree().root))

func _process(_delta: float) -> void:
	_refresh_toolbar()
	if not enabled(): return
	var size: Vector2 = backdrop.get_viewport().get_visible_rect().size
	toolbar.position=Vector2(maxf(8,size.x-toolbar.size.x-14),maxf(8,size.y-toolbar.size.y-10))
	if backdrop.visible:
		backdrop.size=size
		panel.position=Vector2(maxf(8,(size.x-780)/2),12)
		panel.size=Vector2(minf(780,size.x-16),maxf(250,size.y-24))
		if backdrop.has_meta("terminal_page"):
			panel.position=Vector2.ZERO
			panel.size=size
	# Polling also reaches embedded work/exhibition windows, whose input belongs to
	# a different viewport. It never installs an OS-wide keyboard hook.
	var choosing_file: bool = is_instance_valid(export_dialog) and export_dialog.visible
	if Input.is_action_just_pressed("vnb_offline_feedback") and not choosing_file:
		if backdrop.visible: close_panel()
		else: open_panel()
	var escape: bool = Input.is_physical_key_pressed(KEY_ESCAPE)
	if escape and not esc_down and backdrop.visible and not choosing_file and _focused_window(get_tree().root)==panel.get_viewport(): close_panel()
	esc_down=escape

func _input(event: InputEvent) -> void:
	if enabled() and backdrop.visible and not (is_instance_valid(export_dialog) and export_dialog.visible) and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		close_panel(); get_viewport().set_input_as_handled()

func open_panel(feedback_task: Dictionary = {}) -> void:
	if not get_tree().get_nodes_in_group("cinematic_playback").is_empty(): return
	if busy or backdrop.visible: return
	busy=true
	var context: Dictionary = Context.capture(get_tree())
	if not feedback_task.is_empty(): context["reported_task"]=feedback_task.duplicate(true)
	emergency_context=context
	rescue_exported=false
	var target_window: Window = _focused_window(get_tree().root)
	previous_focus=backdrop.get_viewport().gui_get_focus_owner() if backdrop.get_viewport() is SubViewport else target_window.gui_get_focus_owner()
	was_paused=get_tree().paused; get_tree().paused=true
	toolbar.hide(); backdrop.hide()
	# Finish a clean game frame before capturing, including immediate reopen after
	# another feedback panel. Simulation remains paused at the recorded scene.
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
	if not is_instance_valid(target_window) or not target_window.is_inside_tree() or target_window.is_queued_for_deletion():
		get_tree().paused=was_paused
		busy=false; _refresh_toolbar()
		if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
		return
	var image: Image = null
	if DisplayServer.get_name()!="headless": image=target_window.get_texture().get_image()
	emergency_image=image.save_png_to_buffer() if image!=null and not image.is_empty() else PackedByteArray()
	context["screenshot_viewport"]={"title":target_window.title,"size":{"x":target_window.size.x,"y":target_window.size.y},"is_root":target_window==get_tree().root}
	current=store.create_case(context,image)
	# Place the panel in the focused game viewport even when a work viewer is open.
	if layer.get_parent()!=target_window: layer.reparent(target_window)
	if target_window!=get_tree().root:
		if backdrop.has_meta("terminal_page"): backdrop.reparent(layer)
		var release: Callable = _release_window.bind(target_window)
		if not target_window.tree_exiting.is_connected(release): target_window.tree_exiting.connect(release,CONNECT_ONE_SHOT)
	backdrop.show(); toolbar.hide()
	PlaytestData.set_feedback_visible(true,&"offline")
	_restore_fields()
	_refresh_history()
	if current.is_empty(): status.text=_t("现场保存失败，请保持面板打开并尝试另存 ZIP：","Capture could not be saved. Keep the panel open and try Save ZIP as: ")+store.last_error
	elif current.screenshot_status!="captured": status.text=_t("现场已保存，但没有截图：","Scene saved without a screenshot: ")+str(current.screenshot_error)
	else: status.text=_t("现场与截图已保存在本机。文字会自动保存。","Scene and screenshot saved locally. Notes save as you type.")
	note.grab_focus(); busy=false

func open_for_task(chapter: String, level: String) -> void:
	open_panel(PlaytestData.task_feedback_context(chapter,level))

func close_panel() -> void:
	if not backdrop.visible or busy: return
	if not _save_note(false) and not rescue_exported: return
	backdrop.hide()
	if backdrop.has_meta("terminal_page"):
		var home: Node = get_tree().get_first_node_in_group("laboratory")
		if home != null and backdrop.get_parent() != home.terminal_pages.surface: backdrop.reparent(home.terminal_pages.surface)
	if layer.get_parent()!=self: layer.reparent(self)
	get_tree().paused=was_paused
	PlaytestData.set_feedback_visible(false,&"offline")
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	_refresh_toolbar()

func _release_window(window: Window) -> void:
	if not is_instance_valid(layer) or layer.get_parent()!=window: return
	# Return before closing: a refused draft save must leave a usable rescue panel.
	layer.reparent(self)
	close_panel()

func capture_another() -> void:
	if not _save_note(false): return
	close_panel()
	# Wait for the restored game to be rendered, excluding the feedback panel.
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
	open_panel()

func _save_note(reported: bool) -> bool:
	if restoring: return true
	if current.is_empty():
		status.text=_t("没有可写入的现场；请另存 ZIP 保留当前文字。","No writable incident; use Save ZIP as to preserve the current note.")
		return false
	var saved: Dictionary = store.save_note(current.id,note.text,CATEGORIES[category.selected],reported or current.get("status","")=="reported")
	if saved.is_empty():
		status.text=_t("保存失败，文字仍在面板中。请另存 ZIP：","Save failed; the note is still in this panel. Save ZIP as: ")+store.last_error
		return false
	current=saved
	status.text=_t("已自动保存 · ","Saved automatically · ")+str(current.id).left(8)
	if reported: _refresh_history()
	return true

func _edited() -> void:
	if restoring: return
	rescue_exported=false
	_save_note(false)

func _restore_fields() -> void:
	restoring=true
	note.text=str(current.get("note","")); category.select(maxi(0,CATEGORIES.find(str(current.get("category","other")))))
	var task: Dictionary = current.get("task",{})
	info.text=_t("现场：","Scene: ")+str(task.get("chapter_id","home"))+"/"+str(task.get("level_id",""))+" · "+str(current.get("captured_at_utc",""))
	preview.texture=null
	if current.get("screenshot_status","")=="captured":
		var image := Image.new()
		if image.load(store.root.path_join("cases").path_join(str(current.id)).path_join("screenshot.png"))==OK: preview.texture=ImageTexture.create_from_image(image)
	restoring=false

func _load_case(id: String) -> void:
	if not _save_note(false): return
	current=store.read_case(id); _restore_fields(); _refresh_history()
	emergency_context=Store._read_json(store.root.path_join("cases").path_join(id).path_join("context.json"))
	var png: String = store.root.path_join("cases").path_join(id).path_join("screenshot.png")
	emergency_image=FileAccess.get_file_as_bytes(png) if FileAccess.file_exists(png) else PackedByteArray()
	status.text=_t("已打开历史现场；原始截图和数据保持不变。","Opened a previous scene; its original screenshot and data are retained.")

func _refresh_history() -> void:
	if not is_instance_valid(history): return
	history.clear()
	for item: Dictionary in store.cases():
		var task: Dictionary = item.get("task",{})
		var label: String = str(item.captured_at_utc)+" · "+str(task.get("level_id","home"))+" · "+str(item.note).replace("\n"," ").left(32)
		history.add_item(label); history.set_item_metadata(history.item_count-1,item.id)
		if item.id==current.get("id",""): history.select(history.item_count-1)

func export_all(destination: String = "") -> void:
	if busy: return
	busy=true
	var note_saved: bool = _save_note(false) if backdrop.visible else true
	var extras: Dictionary = {"session/current-context.json":JSON.stringify(Context.capture(get_tree()),"\t").to_utf8_buffer()}
	if backdrop.visible:
		extras["session/panel-draft.json"]=JSON.stringify({"case_id":current.get("id",""),"note":note.text,"category":CATEGORIES[category.selected]},"\t").to_utf8_buffer()
		extras["session/captured-context.json"]=JSON.stringify(emergency_context,"\t").to_utf8_buffer()
		if not note_saved:
			var rescue_id: String = Store.new_id()
			var rescue: Dictionary = {"id":rescue_id,"related_case_id":current.get("id",""),"captured_at_utc":current.get("captured_at_utc",Store.now()),
				"updated_at_utc":Store.now(),"revision":0,"category":CATEGORIES[category.selected],"note":note.text,"status":"draft",
				"task":emergency_context.get("reported_task",emergency_context.get("task",{})),"build":current.get("build",Store.build_identity()),
				"screenshot_status":"captured" if not emergency_image.is_empty() else "unavailable",
				"screenshot_error":"" if not emergency_image.is_empty() else "No in-memory screenshot was available."}
			extras["cases/"+rescue_id+"/case.json"]=JSON.stringify(rescue,"\t").to_utf8_buffer()
			extras["cases/"+rescue_id+"/context.json"]=JSON.stringify(emergency_context,"\t").to_utf8_buffer()
			if not emergency_image.is_empty(): extras["cases/"+rescue_id+"/screenshot.png"]=emergency_image
	for filename: String in DirAccess.get_files_at(PlaytestData.storage_directory) if DirAccess.dir_exists_absolute(PlaytestData.storage_directory) else PackedStringArray():
		if filename.begins_with("session_") and filename.ends_with(".jsonl"):
			extras["sessions/"+filename]=PlaytestData.storage_directory.path_join(filename)
	if FileAccess.file_exists(PlaytestMoments.DRAFT_PATH): extras["legacy/feedback_drafts_v1.json"]=PlaytestMoments.DRAFT_PATH
	var save_paths: Dictionary = {"saves/core.json":GlobalSave.DEFAULT_STORAGE_PATH,"saves/hardware-workbenches.json":GlobalSave.DEFAULT_WORKBENCH_PATH,
		"saves/personal-records.json":PersonalRecords.PATH,"saves/creation-session.json":preload("res://experiments/creation/session.gd").default_path()}
	var candidate_paths: Dictionary = preload("res://src/campaign/second_act_tasks.gd").paths()
	for domain: String in candidate_paths: save_paths["saves/"+domain+"-session.json"]=candidate_paths[domain]
	for name: String in save_paths:
		var path: String = str(save_paths[name])
		if not path.is_empty() and FileAccess.file_exists(path): extras[name]=path
	extras["session/export-coverage.json"]=JSON.stringify({"saved_files":"standard game filenames and bound candidate profiles only; custom launch paths are excluded",
		"current_memory":"current-context.json; may contain unsaved changes","game_log_available":DirAccess.dir_exists_absolute("user://logs"),
		"missing_files":"not created or unavailable; no synthetic save is generated"},"\t").to_utf8_buffer()
	# Only the game's log is included. No remote outbox, identity, deletion secret,
	# arbitrary desktop file or environment variable is copied.
	for filename: String in DirAccess.get_files_at("user://logs") if DirAccess.dir_exists_absolute("user://logs") else PackedStringArray():
		if filename=="godot.log" or filename.begins_with("godot") and filename.ends_with(".log"):
			extras["logs/"+filename]="user://logs/"+filename
	last_export=store.export_bundle(destination,extras)
	if last_export.is_empty():
		var failure: String = store.last_error
		if not backdrop.visible:
			busy=false; open_panel(); busy=true
		status.text=_t("导出失败；本机记录未删除。可尝试另存到其他位置：","Export failed; local records were retained. Try Save ZIP as to another location: ")+failure
	else:
		rescue_exported=true
		if backdrop.visible: status.text=_t("已导出并核验。把这个 ZIP 发给维护者；本机原件仍保留：\n","Export verified. Send this ZIP to the maintainer; local originals remain:\n")+last_export
		OS.shell_show_in_file_manager(last_export)
	busy=false

func choose_export_path() -> void:
	if is_instance_valid(export_dialog): export_dialog.queue_free()
	export_dialog=FileDialog.new(); export_dialog.process_mode=Node.PROCESS_MODE_ALWAYS; export_dialog.access=FileDialog.ACCESS_FILESYSTEM
	export_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE; export_dialog.filters=PackedStringArray(["*.zip ; Offline playtest feedback"])
	export_dialog.current_file="VNB-feedback-"+Store.new_id().left(8)+".zip"
	layer.get_parent().add_child(export_dialog)
	export_dialog.file_selected.connect(func(path: String) -> void: export_all(path))
	export_dialog.popup_centered_ratio(0.8)

func _focused_window(node: Node) -> Window:
	for child: Node in node.get_children():
		if child==self or child==layer: continue
		var result: Window = _focused_window(child)
		if result!=null and result.has_focus() and result.visible: return result
	if node is Window and node.has_focus() and node.visible: return node
	return null if node!=get_tree().root else get_tree().root

func _button(parent: Node, zh: String, en: String, action: Callable) -> Button:
	var button := Button.new(); button.text=_t(zh,en); button.custom_minimum_size.y=36
	button.set_meta("locale_pair",[zh,en])
	button.pressed.connect(action); parent.add_child(button); return button

func _category_text(index: int) -> String:
	return _t(["理解/卡关","操作不顺","故障/错误","视听/布局","发现/建议","其他"][index],
		["Confusion / stuck","Controls","Bug / error","Visuals / audio","Discovery / suggestion","Other"][index])

func _t(zh: String, en: String) -> String:
	return en if Localization.current_locale()=="en" else zh

func _refresh_language(node: Node) -> void:
	if node.has_meta("locale_pair"):
		var pair: Array = node.get_meta("locale_pair")
		node.set("text",_t(str(pair[0]),str(pair[1])))
	for child: Node in node.get_children(): _refresh_language(child)
	if node==layer:
		for index: int in CATEGORIES.size(): category.set_item_text(index,_category_text(index))
		note.placeholder_text=_t("哪里卡住了？你想做什么、实际发生了什么？也可以只保存现场，稍后补充。","Where did you get stuck? What did you try, and what happened? You can also keep the scene now and add a note later.")

func _connect_panel_input(node: Node) -> void:
	if node is Control:
		node.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
				var viewport: Viewport = panel.get_viewport()
				viewport.set_input_as_handled(); close_panel())
	for child: Node in node.get_children(): _connect_panel_input(child)
