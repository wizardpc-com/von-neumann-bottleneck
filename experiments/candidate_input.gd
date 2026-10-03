extends "res://experiments/viewport_input.gd"
## Shared viewport actuator only; no authored plans or pass conditions.
# Native popup focus may lag injected mouse input on macOS. Retry only UI keys;
# never select an item or emit its signal directly. Keep attempts in the log.
func choose(control: OptionButton, index: int) -> void:
	if control.selected == index: return
	var popup: PopupMenu = control.get_popup()
	popup.prefer_native_menu = false
	for attempt: int in 3:
		root.grab_focus()
		await create_timer(0.2).timeout
		if not popup.visible: await press(control)
		await create_timer(0.2).timeout
		if not popup.visible: continue
		popup.grab_focus()
		await create_timer(0.2).timeout
		await popup_key(popup, KEY_HOME)
		for i: int in range(control.item_count + 1):
			if popup.get_focused_item() == index: break
			await popup_key(popup, KEY_DOWN)
		print("MENU attempt=", attempt + 1, " focus=", popup.get_focused_item(), " want=", index)
		if popup.get_focused_item() == index:
			await popup_key(popup, KEY_ENTER)
		else:
			await popup_key(popup, KEY_ESCAPE)
		if control.selected == index and not popup.visible:
			check(true, "Visible selector accepts choice %d" % index)
			root.grab_focus(); await create_timer(0.2).timeout
			return
	check(false, "Visible selector accepts choice %d" % index)


func press(control: Control) -> void:
	root.grab_focus(); await create_timer(0.1).timeout
	await super.press(control)

func handle(name: String) -> Control:
	return ui.find_child(name, true, false) as Control

func number(control: SpinBox, value: int) -> void:
	await press(control.get_line_edit()); await key(KEY_A, true)
	await type_text(str(value)); await key(KEY_ENTER); await settle()

func tree_row(tree: Tree, index: int) -> void:
	await press(tree)
	var item: TreeItem = tree.get_root().get_first_child()
	for i: int in index: item = item.get_next()
	for attempt: int in 30:
		var area: Rect2 = tree.get_item_area_rect(item)
		if area.get_center().y >= 35 and area.get_center().y < tree.size.y - 8: break
		await click(tree.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN if area.get_center().y >= tree.size.y - 8 else MOUSE_BUTTON_WHEEL_UP)
	await click(tree.global_position + tree.get_item_area_rect(item).get_center())

func build_partition(proposal: Array) -> void:
	var observation: Dictionary = ui.public_observation()
	while observation.plan.size() > 1:
		await tree_row(handle("Blocks"), 0); await press(handle("Merge"))
		observation = ui.public_observation()
	for i: int in range(proposal.size()-1):
		await tree_row(handle("Blocks"), i)
		await number(handle("SplitAt"), int(proposal[i].end)); await press(handle("Split"))
	for i: int in proposal.size():
		await tree_row(handle("Blocks"), i)
		await press(handle("RLE" if proposal[i].codec == "rle" else "Raw"))
	check(ui.public_observation().plan == proposal, "Visible edits produce the proposed partition")

func set_prediction(proposal: Dictionary) -> void:
	var ranges: Dictionary = ui.public_observation().control_ranges
	for field: String in ["rule", "confidence", "lookahead", "cooldown"]:
		var name: String = {"rule":"Rule", "confidence":"Confidence", "lookahead":"Lookahead", "cooldown":"Cooldown"}[field]
		await choose(handle(name), ranges[field].find(proposal[field]))
	check(ui.public_observation().policy == proposal, "Visible controls produce the proposed causal rule")

func open_scene(path: String) -> void:
	change_scene_to_file(path); await settle(25); ui = current_scene

func prepare_window() -> void:
	await settle(); root.mode = Window.MODE_WINDOWED
	await create_timer(1.0).timeout; root.size = Vector2i(1600,900); await settle(10)

func item_row(list: ItemList, index: int) -> void:
	await press(list)
	for attempt: int in 40:
		var rect: Rect2 = list.get_item_rect(index)
		var center: Vector2 = rect.get_center() - Vector2(0,list.get_v_scroll_bar().value)
		if center.y >= 8 and center.y < list.size.y - 8: break
		await click(list.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN if center.y >= list.size.y-8 else MOUSE_BUTTON_WHEEL_UP)
	var point_at: Vector2 = list.get_item_rect(index).get_center() - Vector2(0,list.get_v_scroll_bar().value)
	await click(list.global_position + point_at)

func build_service(proposal: Dictionary) -> void:
	# Normalize to singleton groups by actual split edits, reorder by visible IDs,
	# then merge the requested groups. No model plan setter is used.
	var draft: Dictionary = ui.public_observation().draft
	var index: int = 0
	while index < draft.groups.size():
		if draft.groups[index].size() > 1:
			await item_row(ui.group_list,index); await number(ui.split_at,1); await press(ui.split_button)
		else: index += 1
		draft = ui.public_observation().draft
	var wanted: Array = []
	for group: Array in proposal.groups: wanted.append_array(group)
	for target: int in wanted.size():
		draft = ui.public_observation().draft
		var found: int = -1
		for i: int in draft.groups.size():
			if draft.groups[i][0] == wanted[target]: found = i; break
		if found == target: continue
		await item_row(ui.group_list,found); await number(ui.move_to,target+1); await press(ui.move_button)
	for i: int in proposal.groups.size():
		for j: int in range(1,proposal.groups[i].size()):
			await item_row(ui.group_list,i); await press(ui.merge_button)
	await number(ui.slots,int(proposal.slots))
	for stream: int in proposal.representations.size():
		for attempt: int in 4:
			if ui.public_observation().draft.representations[stream] == proposal.representations[stream]: break
			await press(ui.format_buttons[stream])
	check(ui.public_observation().draft == proposal,"Visible edits produce the proposed service plan")
