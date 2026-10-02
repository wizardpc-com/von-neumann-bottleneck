extends "res://tests/test_recovery_game_input.gd"
## Agent-authored viewport proxy, not native OS or human beginner evidence.
var path_notes: Array[Dictionary] = []

func note(task: String, decision: String, evidence: String) -> void:
	path_notes.append({"task":task,"decision":decision,"evidence":evidence})
	print("PATH: ",task," · ",decision," · ",evidence)
	var record := FileAccess.open(evidence_root+"path-notes.json",FileAccess.WRITE)
	record.store_string(JSON.stringify(path_notes,"\t"))

func popup_key(popup: PopupMenu, code: Key) -> void:
	for down: bool in [true,false]:
		if not is_instance_valid(popup): return
		var event := InputEventKey.new()
		event.keycode=code; event.physical_keycode=code; event.pressed=down
		event.window_id=popup.get_window_id()
		Input.parse_input_event(event)
		await process_frame
	await settle(2)

func choose(control: OptionButton, index: int) -> void:
	var popup: PopupMenu=control.get_popup()
	# macOS native menus cannot receive viewport-injected events; use the
	# same PopupMenu items in its Godot-rendered mode for this proxy only.
	popup.prefer_native_menu = false
	await press(control)
	check(popup.visible,"Visible choice menu opened")
	await popup_key(popup,KEY_HOME)
	for i: int in range(control.item_count+1):
		if popup.get_focused_item()==index: break
		await popup_key(popup,KEY_DOWN)
	print("MENU: ",control.name," focus=",popup.get_focused_item()," want=",index)
	await popup_key(popup,KEY_ENTER)
	if is_instance_valid(control): check(control.selected == index,"Visible selector accepts choice %d" % index)

func edit_number(control: SpinBox, value: int) -> void:
	await press(control.get_line_edit())
	await key(KEY_A,true)
	await type_text(str(value))
	await key(KEY_ENTER)

func debug_inputs(values: Dictionary) -> void:
	for signal_name: String in values:
		var control: Control = ui.prologue_input_controls[StringName(signal_name)]
		if control is CheckButton:
			if control.button_pressed != bool(values[signal_name]): await press(control)
		else: await edit_number(control,values[signal_name])
	await press(named_button(ui,text(&"hardware.cases.run_debug")))
	await wait_playback()

func investigation(level: String) -> void:
	if not ui.desktop_windows[&"test_bench"].visible: await press(ui.desktop_window_buttons[&"test_bench"])
	await press(named_button(ui,text(&"investigation.open")))
	await capture(level+"-experiment-question")
	await press(named_button(ui,text(&"investigation.reset")))
	if level == "alu":
		for op: int in range(4):
			await debug_inputs({"A":1,"B":0,"CIN":0,"OP0":op%2,"OP1":op/2})
			note(level,"A=1 B=0 CIN=0; OP="+str(op),ui.construction_investigation.evidence.text)
	elif level == "ram":
		for values: Dictionary in [{"ADDR":0,"DATA":7,"WRITE":1},{"ADDR":1,"DATA":9,"WRITE":1},{"ADDR":0,"DATA":2,"WRITE":1},{"ADDR":1,"WRITE":0}]:
			await debug_inputs(values)
			note(level,str(values),ui.construction_investigation.evidence.text)
		check(ui.prologue_live_result.observed_values[&"OUT"].value==9,"Changing address zero preserves independently read address one")
	else:
		for values: Dictionary in [{"OP":0,"ARG":4,"ADDR":1},{"OP":3},{"OP":0,"ARG":13,"ADDR":0},{"OP":3},{"OP":2,"ADDR":1}]:
			await debug_inputs(values)
			note(level,str(values),ui.construction_investigation.evidence.text)
		check(ui.prologue_live_result.observed_values[&"ACC"].value==4,"Player-built CPU reads back memory independently of last immediate")
	await press(ui.construction_investigation.evidence)
	await capture(level+"-experiment-evidence")
	await press(named_button(ui,text(&"investigation.reset")))
	check(ui.construction_investigation.observations.is_empty() and ui.playback_batches.is_empty(),"Visible reset clears evidence and playback")
	await capture(level+"-reset")

func official_and_seal() -> void:
	if ui.current_level_id in [&"alu",&"ram"]: await investigation(String(ui.current_level_id))
	await super.official_and_seal()

func enter_level(id: StringName) -> void:
	await super.enter_level(id)
	if id == &"load_store":
		await investigation("load_store")
		await close_window(&"test_bench")

func open_tool(id: StringName) -> void:
	await press(ui.instrument_open_buttons[id])
	if not ui.instrument_windows[id].visible: await press(ui.instrument_open_buttons[id])

func close_tools() -> void:
	for id: StringName in ui.instrument_windows:
		var panel: Control = ui.instrument_windows[id]
		if panel.visible: await press(panel.find_child("CloseButton",true,false))

func finish_trace() -> void:
	await press(ui.finish_playback_button)
	await settle()

func system_path() -> void:
	ui=current_scene
	for level: StringName in [&"assembly",&"cpu_speed",&"ram_wait",&"bus_width",&"bottleneck"]:
		if root.get_node("SystemChapter").completed_levels().get(level,false): continue
		await press(ui.map_view.level_buttons[level])
		await capture(String(level)+"-entry")
		await press(ui.find_child("AutoWireButton",true,false))
		if level in [&"cpu_speed",&"ram_wait",&"bus_width"] and ui.locked_prediction_id.is_empty():
			await choose(ui.prediction_selector,1)
			await press(ui.prediction_lock_button)
		await open_tool(&"test_bench")
		if level == &"ram_wait" and ui.reuse_baseline_button.visible and not ui.reuse_baseline_button.disabled:
			await press(ui.reuse_baseline_button)
		else:
			await open_tool(&"test_bench")
			await press(ui.official_run_button)
			await finish_trace()
		if level in [&"cpu_speed",&"ram_wait",&"bus_width"]:
			var kind: StringName = {&"cpu_speed":&"cpu",&"ram_wait":&"ram",&"bus_width":&"bus"}[level]
			await open_tool(&"parts")
			await choose(ui.part_selectors[kind],1)
			await open_tool(&"test_bench")
			await press(ui.official_run_button)
			await finish_trace()
		if level == &"bottleneck":
			await open_tool(&"test_bench")
			await choose(ui.diagnosis_selector,0)
			await press(ui.diagnosis_button)
			await capture("bottleneck-first-diagnosis")
			var index: int=0
			for i: int in ui.diagnosis_selector.item_count:
				if ui.diagnosis_selector.get_item_metadata(i)==ui.latest_receipt.diagnosed_bottleneck: index=i
			await choose(ui.diagnosis_selector,index)
			await press(ui.diagnosis_button)
		if level == &"bus_width": await open_tool(&"history")
		note(String(level),"Controlled official comparison",JSON.stringify(ui.latest_receipt.metrics))
		await capture(String(level)+"-evidence")
		check(root.get_node("SystemChapter").completed_levels().get(level,false),"System Game route earned "+String(level))
		if ui.level_completion_overlay.visible: await press(ui.level_completion_overlay.return_button)
		else: await press(ui.find_child("ChapterMapButton",true,false))
	await press(named_button(ui,text(&"common.prototype_hub")))
	await press(current_scene.locality_entry_button)

func locality_run() -> void:
	await open_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()

func locality_path() -> void:
	ui=current_scene
	for level: StringName in [&"distant_reads",&"nearby_storage",&"cache_failure",&"access_order",&"working_set",&"blocking",&"capstone"]:
		if root.get_node("LocalityChapter").completed_levels().get(level,false): continue
		await press(ui.chapter_map.level_buttons[level])
		await capture(String(level)+"-entry")
		if level == &"nearby_storage":
			await open_tool(&"cache")
			await press(ui.cache_card_buttons[1])
		if level == &"access_order":
			await open_tool(&"program")
			await press(ui.row_strategy_button)
			await press(ui.apply_program_button)
		await locality_run()
		if level in [&"distant_reads",&"cache_failure",&"working_set"]:
			await open_tool(&"mission")
			var judgment: StringName = {&"distant_reads":&"repeated_ram",&"cache_failure":&"replacement",&"working_set":&"does_not_fit"}[level]
			if level == &"working_set":
				for candidate: StringName in ui.mission_judgment_buttons:
					if candidate!=judgment:
						await press(ui.mission_judgment_buttons[candidate]); break
				await capture("working_set-wrong-explanation")
			await press(ui.mission_judgment_buttons[judgment])
		if level == &"blocking":
			for group: int in [4,2,1]:
				await open_tool(&"blocking")
				await press(ui.block_card_buttons[group])
				await locality_run()
				note("blocking","Group "+str(group),JSON.stringify(ui.current_trace.metrics))
				await capture("blocking-group-"+str(group))
		if level == &"capstone":
			await open_tool(&"mission")
			await press(ui.mission_judgment_buttons[&"more_cpu_math"])
			await capture("capstone-wrong-diagnosis")
			await press(ui.mission_judgment_buttons[&"repeated_far_fetch"])
			await open_tool(&"cache")
			await press(ui.cache_card_buttons[4])
			await locality_run()
			note("capstone","One lever: four-line cache",JSON.stringify(ui.current_trace.metrics))
			await capture("capstone-hardware-solution")
			await open_tool(&"cache")
			await press(ui.cache_card_buttons[1])
			await open_tool(&"blocking")
			await press(ui.block_card_buttons[1])
			await locality_run()
			await open_tool(&"profiler")
			await capture("capstone-cost-comparison")
		note(String(level),"Observed before review",JSON.stringify(ui.current_trace.metrics))
		await capture(String(level)+"-evidence")
		await open_tool(&"mission")
		await press(ui.mission_finish_button if level == &"capstone" else ui.mission_review_button)
		check(root.get_node("LocalityChapter").completed_levels().get(level,false),"Locality Game route earned "+String(level))
		await press(ui.level_completion_overlay.continue_button)
		if level == &"capstone": return
		if not ui.chapter_map_host.visible:
			await press(ui.find_child("Chapter2MapButton",true,false))

func finish() -> void:
	if failures.is_empty() and current_scene.name == "SystemLab": await system_path()
	if failures.is_empty() and current_scene.name == "Main": await locality_path()
	var file := FileAccess.open(evidence_root+"path-notes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(path_notes,"\t"))
	await super.finish()

func _run() -> void:
	# Harness-only disk isolation. No solution, receipt or completion is supplied.
	assert(OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/"))
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test("user://proxy-save.json", "user://proxy-workbenches.json")
	save.load_game()
	var resume: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--resume="): resume=arg.trim_prefix("--resume=")
	if resume.is_empty():
		await super._run()
		return
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1600,900)
	await create_timer(1.0).timeout
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await settle(8)
	check(not root.get_node("GameMode").is_test_mode(),"Resume uses only previously UI-earned Game save")
	if resume == "construction":
		await press(named_button(current_scene,text(&"hub.hardware.play")))
		ui=current_scene
		for level: StringName in [&"alu",&"ram"]:
			await enter_level(level)
			await investigation(String(level))
			await press(ui.desktop_window_buttons[&"task"])
			await press(named_button(ui,text(&"hardware.prologue.back_map")))
		await load_store_bridge()
	elif resume == "system":
		check(not current_scene.system_entry_button.disabled,"UI-earned prologue survives restart")
		await press(current_scene.system_entry_button)
	elif resume == "locality": await press(current_scene.locality_entry_button)
	elif resume == "overlap":
		await press(current_scene.overlap_entry_button)
		await overlap_path()
	elif resume == "layout":
		await press(current_scene.layout_entry_button)
		await layout_path()
	await finish()

func replace_program(source: String) -> void:
	await press(ui.editor)
	await key(KEY_A,true)
	await key(KEY_BACKSPACE)
	var lines: PackedStringArray = source.strip_edges().split("\n")
	for i: int in lines.size():
		await type_text(lines[i])
		if i < lines.size()-1: await key(KEY_ENTER)
	check(ui.editor.text.strip_edges()==source.strip_edges(),"Program typed through CodeEdit matches intended experiment")

func overlap_tool(id: String) -> void:
	await press(named_button(ui.dock,text(StringName("overlap."+id))))
	if not ui.panels[id].visible: await press(named_button(ui.dock,text(StringName("overlap."+id))))

func overlap_run(tag: String) -> void:
	await press(named_button(ui.dock,text(&"overlap.run")))
	await capture(tag)
	note(ui.level,tag,ui.metrics.text)

func overlap_wire(from: String, to: String, output: int, input: int) -> void:
	var a: GraphNode=ui.graph.get_node(from)
	var b: GraphNode=ui.graph.get_node(to)
	await drag(a.get_global_transform()*a.get_output_port_position(output),b.get_global_transform()*b.get_input_port_position(input))
	check(ui.graph.is_node_connected(from,output,to,input),"Visible overlap wire "+from+" → "+to)

func overlap_path() -> void:
	ui=current_scene
	await press(ui.map_view.level_buttons[&"arrival"])
	await overlap_run("arrival-read-before-ready")
	check(not root.get_node("OverlapChapter").completed().has("arrival"),"Early consume failure cannot earn arrival")
	await overlap_tool("program")
	await replace_program("fetch A 0\nwork 4\nready A\nconsume A\nidle")
	await overlap_run("arrival-ready-evidence")
	check(root.get_node("OverlapChapter").completed().has("arrival"),"Arrival earned through typed program")
	await press(ui.completion.continue_button)
	await press(ui.map_view.level_buttons[&"buffers"])
	await capture("buffers-empty-board")
	for id: String in ui.panels:
		if id != "toolbox" and ui.panels[id].visible: await press(ui.panels[id].find_child("CloseButton",true,false))
	var palette: Control
	for item: Node in ui.panels.toolbox.find_children("*","",true,false):
		if item.get_script()==preload("res://src/hardware_foundations/component_palette_item.gd"): palette=item; break
	for at: Vector2 in [Vector2(510,320),Vector2(510,580)]: await drag(palette.get_global_rect().get_center(),at)
	check(ui.board.nodes.has("A") and ui.board.nodes.has("B"),"Two buffers are placed by palette drag")
	await press(ui.panels.toolbox.find_child("CloseButton",true,false))
	for name: String in ["A","B"]:
		await overlap_wire("TRANSFER",name,0,0)
		await overlap_wire(name,"COMPUTE",0,0)
		await overlap_wire(name,"COMPUTE",1,1)
		await overlap_wire(name,"TRANSFER",2,0)
	await overlap_run("buffers-serial-two-parts")
	check(not root.get_node("OverlapChapter").completed().has("buffers"),"Adding a second buffer alone is not an overlapping schedule")
	await overlap_tool("program")
	await replace_program("fetch A 0\nfetch B 1\nready A\nconsume A\nfree A\nfetch A 2\nready B\nidle\nconsume B\nfree B\nfetch B 3\nready A\nidle\nconsume A\nready B\nidle\nconsume B\nidle")
	await overlap_run("buffers-overlap-evidence")
	check(root.get_node("OverlapChapter").completed().has("buffers"),"Buffers passed from GUI wiring and typed schedule")
	await press(ui.completion.continue_button)

func select_task(task: String) -> void:
	var tree: Control=current_scene
	await press(tree.search)
	await key(KEY_A,true)
	await type_text(task)
	await key(KEY_ENTER)
	await capture(task.replace("/","-")+"-tree")
	check(not tree.enter_button.disabled,"Requested task is earned and available: "+task)
	await press(tree.enter_button)
	ui=current_scene

func local_caption(zh: String, en: String) -> String:
	return zh if root.get_node("Localization").current_locale()=="zh_CN" else en

func layout_button(zh: String,en: String) -> void:
	await press(named_button(ui,local_caption(zh,en)))

func layout_tools() -> void:
	await layout_button("布局工具","Layout tools")
	if not ui.panels.tools.visible: await layout_button("布局工具","Layout tools")

func layout_options() -> Array[OptionButton]:
	var result: Array[OptionButton]=[]
	for item: Node in ui.tools_box.find_children("*","OptionButton",true,false): result.append(item)
	return result

func layout_run(tag: String) -> void:
	await layout_button("运行全部订单","Run all cases")
	var metrics: Array=[]
	for run: RefCounted in ui.runs: metrics.append(run.metrics)
	note(ui.level,tag,JSON.stringify(metrics))
	await capture(tag)

func layout_path() -> void:
	ui=current_scene
	if ui.level != "fields":
		await layout_button("任务树","Task tree")
		await select_task("chapter_4/fields")
	check(ui.level=="fields","Fields prerequisite selected through task tree")
	await press(named_button(ui,text(&"layout.mission.begin")))
	await layout_run("fields-record-order")
	await layout_tools()
	await choose(layout_options()[0],1)
	await layout_run("fields-by-field")
	check(root.get_node("LayoutChapter").completed().has("fields"),"Fields earned by visible ordering choice")
	await layout_button("任务树","Task tree")
	await select_task("chapter_4/relocation")
	await press(named_button(ui,text(&"layout.mission.begin")))
	await layout_run("relocation-direct-both")
	await layout_tools()
	await choose(layout_options()[0],1)
	await choose(layout_options()[1],1)
	await choose(layout_options()[2],1)
	await layout_run("relocation-copy-repeated-only")
	check(root.get_node("LayoutChapter").completed().has("relocation"),"Independent order choices count actual preparation and queries")

func named_design() -> void:
	# The stock --script harness disables workbench writes. Enable only this QA
	# store so the real sealed circuits can be revalidated after process restart.
	ui.workbench_store.storage_path = "user://proxy-workbenches.json"
	await super.named_design()
