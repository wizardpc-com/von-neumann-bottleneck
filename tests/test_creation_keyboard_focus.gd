extends SceneTree
## Viewport keyboard events verify navigation; Unit selection uses its UI callback.
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func key(code: Key, unicode: int = 0, command: bool = false) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.unicode = unicode; event.pressed = down
		event.meta_pressed = command and OS.get_name() == "macOS"
		event.ctrl_pressed = command and not event.meta_pressed
		root.push_input(event,true); await process_frame
	await settle()
func control(scene: Control, handle: String) -> Control:
	return scene.find_child(handle,true,false) as Control
func focused(handle: String) -> bool:
	var owner: Control = root.gui_get_focus_owner()
	return owner != null and owner.name == handle
func run() -> void:
	root.get_node("TaskNavigation").pending = ""
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	scene.session.close()
	var path: String = "user://creation-keyboard-focus/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	check(scene.session.open(path).writable,"Own isolated keyboard profile")
	scene.change_task(0); await settle()
	var data: Dictionary = scene.session.data.duplicate(true)
	control(scene,"Unit").grab_focus(); await key(KEY_TAB)
	check(focused("Previous"),"Tab skips unavailable Undo and Redo after Unit")
	check(control(scene,"UndoDraft").focus_mode == Control.FOCUS_NONE and control(scene,"RedoDraft").focus_mode == Control.FOCUS_NONE,"Unavailable history actions leave the Tab chain")
	control(scene,"Next").grab_focus(); await key(KEY_ENTER)
	check(scene.task == 1 and focused("Next"),"Viewport Enter on Next retains its rebuilt navigation focus")
	await key(KEY_ENTER)
	check(scene.task == 2 and focused("Next"),"A second Enter continues ordinary task navigation without a new Tab traversal")
	check(scene.session.data.model.is_empty() and scene.session.last_transport.is_empty() and scene.session.prediction.is_empty() and scene.session.generated.is_empty(),"Navigation restores focus without automatically learning or running")
	control(scene,"Previous").grab_focus(); await key(KEY_ENTER)
	check(scene.task == 1 and focused("Previous"),"Viewport Previous retains its rebuilt navigation focus")
	var unit := control(scene,"Unit") as OptionButton
	unit.grab_focus(); unit.select(6); unit.item_selected.emit(6); await settle()
	check(focused("Unit") and (control(scene,"DraftTabs") as TabContainer).current_tab == 2,"Unit callback preserves focus while choosing the target task tab")
	check((control(scene,"Generate") as Button).disabled and control(scene,"Generate").focus_mode == Control.FOCUS_NONE,"Unavailable Generate cannot receive Tab focus")
	var generated: Dictionary = scene.session.generated.duplicate(true)
	control(scene,"ToGenerate").grab_focus(); await key(KEY_TAB)
	check(not focused("Generate") and not focused("KeepCurrent"),"Viewport Tab skips unavailable generation and keeping actions")
	await key(KEY_ENTER)
	check(scene.session.generated == generated and scene.session.data.model.is_empty(),"Enter after skipping disabled generation cannot execute it")
	var tabs := control(scene,"DraftTabs") as TabContainer
	tabs.current_tab = 0; await settle()
	var input := control(scene,"CustomExample") as LineEdit
	input.text = "A B"; input.caret_column = input.text.length(); input.grab_focus()
	await key(KEY_Q,81)
	check(input.text == "A BQ" and scene.session.data.draft == data.draft,"Viewport typing stays in the unsubmitted sample and does not alter the draft")
	await key(KEY_Z,0,true)
	check(input.text == "A B" and scene.session.data.draft == data.draft,"Focused text retains its own Ctrl/Cmd+Z editing boundary")
	control(scene,"Language").grab_focus(); await key(KEY_ENTER)
	check(focused("Language") and (control(scene,"CustomExample") as LineEdit).text == "A B","Locale rebuild restores a valid button focus and retains unsubmitted text")
	# Two real edits leave Undo enabled after one restoration, so its focus is valid.
	scene.session.data.draft.seed += 1; scene.edit_draft()
	scene.session.data.draft.seed += 1; scene.edit_draft()
	var edited_seed: int = scene.session.data.draft.seed
	control(scene,"UndoDraft").grab_focus(); await key(KEY_ENTER)
	check(scene.session.data.draft.seed == edited_seed-1 and focused("UndoDraft"),"Viewport Undo restores one draft and its still-enabled focus")
	check(control(scene,"RedoDraft").focus_mode == Control.FOCUS_ALL,"Newly available Redo re-enters the Tab chain")
	var saved: Dictionary = scene._capture_editor_state()
	saved.focus = "Generate"; scene._restore_editor_state(saved)
	check(not focused("Generate"),"Editor restoration cannot focus a disabled action")
	tabs = control(scene,"DraftTabs") as TabContainer; tabs.current_tab = 2; await settle()
	saved.tabs.clear(); saved.focus = "CustomExample"; scene._restore_editor_state(saved)
	check(not focused("CustomExample"),"Editor restoration cannot focus a control in a hidden tab")
	# A new isolated fixture has exactly one history entry; exhaust both directions.
	scene.session.close(); check(scene.session.open(path+".single").writable,"Own isolated single-edit history")
	scene._clear_replaced_exploration(); scene.change_task(0)
	var original_seed: int = scene.session.data.draft.seed
	scene.session.data.draft.seed += 1; scene.edit_draft()
	check(scene.session.undo_stack.size() == 1,"One actual edit creates exactly one Undo step")
	control(scene,"UndoDraft").grab_focus(); await key(KEY_ENTER)
	check(scene.session.data.draft.seed == original_seed and not scene.session.can_undo() and scene.session.can_redo() and focused("RedoDraft"),"Exhausted Undo moves keyboard focus to its enabled Redo counterpart")
	await key(KEY_ENTER)
	check(scene.session.data.draft.seed == original_seed+1 and scene.session.can_undo() and not scene.session.can_redo() and focused("UndoDraft"),"Final Redo restores the edit and moves focus back to enabled Undo")
	scene.queue_free(); await settle()
	print("PASS: creation keyboard focus %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
