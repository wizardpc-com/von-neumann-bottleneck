extends "res://experiments/viewport_input.gd"
## Actuator + declared task fixtures. Policy sees only collected public UI text.
## Test mode supplies prerequisite library, never target answer wires/programs.
const Policy=preload("res://experiments/evidence_proxy/policy.gd")
var journal: Array[Dictionary]=[]
var public_evidence: String=""

func visible_text(node: Node) -> String:
	var parts: PackedStringArray=[]
	if node is Control and not node.is_visible_in_tree(): return ""
	if node is Label or node is RichTextLabel or node is Button: parts.append(node.text)
	if node is Tree:
		var item: TreeItem=node.get_root()
		if item!=null: parts.append(tree_text(item,node))
	for child: Node in node.get_children():
		var value: String=visible_text(child)
		if not value.is_empty(): parts.append(value)
	return "\n".join(parts)

func tree_text(item: TreeItem,tree: Tree) -> String:
	var out: String=""
	if Rect2(Vector2.ZERO,tree.size).intersects(tree.get_item_area_rect(item)):
		for c: int in tree.columns: out+=item.get_text(c)+" "
	for child: TreeItem in item.get_children(): out+="\n"+tree_text(child,tree)
	return out

func record(task: String,obs: Dictionary,decision: Dictionary) -> void:
	journal.append({"task":task,"fixture":"Test-mode blank starter; prerequisite library only","observation":obs,"decision":decision})
	var file:=FileAccess.open(evidence_root+"unknown-answer-journal.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(journal,"\t"))
	print("POLICY ",task," ",decision)

func tool(id: StringName) -> void:
	await press(ui.instrument_open_buttons[id])
	if not ui.instrument_windows[id].visible: await press(ui.instrument_open_buttons[id])

func close_tools() -> void:
	for window: Control in ui.instrument_windows.values():
		if window.visible: await press(window.find_child("CloseButton",true,false))

func locality_run() -> void:
	await close_tools(); await tool(&"test_bench")
	await press(ui.official_run_button)
	await press(ui.finish_playback_button)
	public_evidence=visible_text(ui.instrument_windows[&"test_bench"])
	await tool(&"profiler")
	public_evidence+="\n"+visible_text(ui.instrument_windows[&"profiler"])
	await capture(String(ui.current_level_id)+"-profiler-"+str(journal.size()))

func locality(task: String) -> void:
	change_scene_to_file("res://src/ui/main.tscn"); await settle(15); ui=current_scene
	# Fixture navigation uses the same map button; target remains untouched starter.
	await press(ui.chapter_map.level_buttons[StringName(task)])
	await capture(task+"-mission")
	public_evidence=""
	for page: int in 8:
		public_evidence+="\n"+visible_text(ui.instrument_windows[&"mission"])
		if not ui.mission_continue_button.is_visible_in_tree() or ui.mission_continue_button.disabled: break
		await press(ui.mission_continue_button)
	var policy:=Policy.new()
	for attempt: int in 10:
		var actions: Array=[{"id":"run","kind":"run","label":ui.official_run_button.text}]
		await close_tools(); await tool(&"blocking")
		for group: int in ui.block_card_buttons:
			var control: Button=ui.block_card_buttons[group]
			if control.is_visible_in_tree() and not control.disabled:
				actions.append({"id":"group:"+str(group),"kind":"trial","label":control.text})
		var obs: Dictionary={"evidence":public_evidence,"actions":actions}
		var decision: Dictionary=policy.decide(obs); record(task,obs,decision)
		if decision.id=="stop": break
		if str(decision.id).begins_with("group:"):
			await press(ui.block_card_buttons[int(str(decision.id).get_slice(":",1))])
		await locality_run()
		if ui.level_completion_overlay.visible:
			await capture(task+"-completion")
			# Public completion is observation; no progress or receipt is read.
			record(task,{"evidence":visible_text(ui.level_completion_overlay),"actions":[]},{"id":"stop","reason":"Visible completion; solver has not read hidden criteria."})
			break
	await capture(task+"-stop")

func construction(task: String) -> void:
	change_scene_to_file("res://src/hardware_foundations/hardware_foundations.tscn"); await settle(15); ui=current_scene
	await press(ui.campaign_level_buttons[StringName(task)])
	public_evidence=""
	for page: int in 10:
		if not ui.mission_briefing_active: break
		public_evidence+="\n"+visible_text(ui.mission_briefing_panel)
		await capture(task+"-mission-"+str(page))
		await press(ui.mission_briefing_continue_button)
	var policy:=Policy.new()
	for attempt: int in 4:
		var actions: Array=[{"id":"run","kind":"run","label":"Run visible starter"},{"id":"h1","kind":"hint1","label":"Hint1"}]
		var obs: Dictionary={"evidence":public_evidence,"actions":actions}
		var decision: Dictionary=policy.decide(obs); record(task,obs,decision)
		if decision.id=="stop": break
		if decision.id=="run":
			await press(ui.desktop_window_buttons[&"test_bench"])
			if not ui.desktop_windows[&"test_bench"].visible: await press(ui.desktop_window_buttons[&"test_bench"])
			await press(ui.clock_period_control.get_line_edit()); await key(KEY_A,true); await type_text("120"); await key(KEY_ENTER)
			await press(ui.official_button)
			for wait_frame: int in 1800:
				if not ui.official_button.disabled: break
				await process_frame
			check(not ui.official_button.disabled,"Official playback finishes before hint")
			public_evidence=visible_text(ui.desktop_windows[&"test_bench"])
		else:
			await press(ui.hint_button); await settle()
			check(ui.hint_level==1,"Only first-tier hint consumed")
			public_evidence=visible_text(ui)
		await capture(task+"-"+str(decision.id))

func buffers() -> void:
	change_scene_to_file("res://src/overlap_chapter/overlap_chapter.tscn"); await settle(15); ui=current_scene
	await press(ui.map_view.level_buttons[&"buffers"])
	public_evidence=visible_text(ui.panels["mission"])
	await capture("buffers-mission")
	var policy:=Policy.new()
	for attempt: int in 4:
		var obs: Dictionary={"evidence":public_evidence,"actions":[{"id":"run","kind":"run","label":"Run"},{"id":"h1","kind":"hint1","label":"Hint1"}]}
		var decision: Dictionary=policy.decide(obs); record("buffers",obs,decision)
		if decision.id=="stop": break
		await press(named_button(ui.dock,text(&"overlap.run") if decision.id=="run" else text(&"overlap.hint")))
		await settle(20)
		if decision.id=="h1":
			check(ui.hint_level==1,"Buffers first-tier hint only")
			public_evidence=visible_text(ui.hint_overlay)
		else: public_evidence=visible_text(ui.status)+"\n"+visible_text(ui.panels["trace"])
		await capture("buffers-"+str(decision.id))

func _run() -> void:
	await settle()
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1600,900)
	root.get_node("Localization").set_locale("en")
	root.get_node("GameMode").set_mode(&"test")
	await construction("alu")
	await construction("cpu")
	await locality("blocking")
	await locality("capstone")
	await buffers()
	print("PASS: bounded proxy audit recorded " if failures.is_empty() else "FAIL: proxy actuator ",journal.size()," decisions; stalls are not solves")
	quit(0 if failures.is_empty() else 1)
