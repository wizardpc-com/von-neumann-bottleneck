extends "res://tests/test_recovery_game_input.gd"
## Agent-authored viewport proxy, not native OS or human beginner evidence.
var path_notes: Array[Dictionary] = []
var resume_stage: String = ""
var qa_default_profile: bool = false
var qa_workbench_store: RefCounted

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
	check(is_instance_valid(control) and index >= 0 and index < control.item_count,"Requested selector and item are available")
	if not is_instance_valid(control) or index < 0 or index >= control.item_count: return
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

func bind_qa_workbench_store() -> void:
	# The automated host deliberately uses an in-memory store. Retain its public
	# blank seed in one QA-only disk store across the newly instantiated scenes.
	# No snapshot is applied to the graph and no completion state is supplied.
	if qa_workbench_store == null:
		qa_workbench_store = preload("res://src/hardware_foundations/circuit_workbench_store.gd").new(root.get_node("GlobalSave").workbench_storage_path)
	qa_workbench_store.ensure_default(ui.active_workbench_namespace,ui.current_level_id,ui.workbench_seed_snapshot)
	ui.workbench_store = qa_workbench_store
	check(qa_workbench_store.disk_write_allowed,"QA circuit store allows real player designs to persist")

func enter_level(id: StringName) -> void:
	await super.enter_level(id)
	if is_instance_valid(ui) and current_scene == ui and ui.current_level_id == id: bind_qa_workbench_store()
	if id == &"load_store" and is_instance_valid(ui) and current_scene == ui and ui.current_level_id == id:
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

func journey_from_current() -> bool:
	if on_task_tree(): return true
	ui = current_scene
	var target: Control
	if ui.name == "PrototypeHub": target = ui.find_child("HubBrowseJourney",true,false)
	elif ui.name == "SystemLab": target = ui.find_child("ChapterMapButton",true,false)
	elif ui.name == "Main": target = ui.find_child("Chapter2MapButton",true,false)
	elif ui.name == "OverlapChapterWorkbench": target = named_button(ui,text(&"overlap.map"))
	elif ui.name == "LayoutWorkbench": target = named_button(ui,local_caption("任务树","Task tree"))
	check(target != null,"Current stage offers its real journey return action")
	if target == null: return false
	await press(target)
	await settle(8)
	check(on_task_tree(),"Stage return restores the unified journey tree")
	return on_task_tree()

func stage_task(task_key: String, scene_name: String) -> bool:
	if not failures.is_empty(): return false
	if not await journey_from_current(): return false
	if not await enter_task(task_key): return false
	ui = current_scene
	check(ui.name == scene_name,"Exact stage workspace opened: "+task_key)
	return ui.name == scene_name

func system_return() -> bool:
	if ui.level_completion_overlay.visible:
		await press(ui.level_completion_overlay.continue_button)
		if is_instance_valid(ui) and current_scene == ui and ui.playtest_feedback_overlay.visible:
			await press(ui.playtest_feedback_overlay.skip_button)
	else:
		await press(ui.find_child("ChapterMapButton",true,false))
	await settle(8)
	check(on_task_tree(),"Completed system task returns through its visible journey action")
	return on_task_tree()

func system_path() -> void:
	for level: StringName in [&"assembly",&"cpu_speed",&"ram_wait",&"bus_width",&"bottleneck"]:
		if root.get_node("SystemChapter").completed_levels().get(level,false): continue
		if not await stage_task("chapter_1/"+String(level),"SystemLab"): return
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
		check(ui.latest_receipt != null,"System comparison produced an authoritative receipt: "+String(level))
		if ui.latest_receipt == null: return
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
		if not root.get_node("SystemChapter").completed_levels().get(level,false): return
		if not await system_return(): return
	for required: StringName in [&"assembly",&"cpu_speed",&"ram_wait",&"bus_width",&"bottleneck"]:
		check(root.get_node("SystemChapter").completed_levels().get(required,false),"System stage retains every required earned result: "+String(required))

func locality_run() -> void:
	await open_tool(&"test_bench")
	await press(ui.official_run_button)
	await finish_trace()

func locality_path() -> void:
	for level: StringName in [&"distant_reads",&"nearby_storage",&"cache_failure",&"access_order",&"working_set",&"blocking",&"capstone"]:
		if root.get_node("LocalityChapter").completed_levels().get(level,false): continue
		if not await stage_task("chapter_2/"+String(level),"Main"): return
		await capture(String(level)+"-entry")
		if level == &"nearby_storage":
			await open_tool(&"cache")
			await press(ui.cache_card_buttons[1])
		if level == &"access_order":
			await open_tool(&"program")
			await press(ui.row_strategy_button)
			await press(ui.apply_program_button)
		await locality_run()
		check(ui.current_trace != null,"Locality experiment produced an authoritative trace: "+String(level))
		if ui.current_trace == null: return
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
		if not root.get_node("LocalityChapter").completed_levels().get(level,false): return
		check(ui.level_completion_overlay.visible,"Earned locality review exposes its explicit continue action")
		if not ui.level_completion_overlay.visible: return
		await press(ui.level_completion_overlay.continue_button)
		await settle(8)
		check(on_task_tree(),"Locality completion restores the unified journey tree")
		if not on_task_tree(): return
	for required: StringName in [&"distant_reads",&"nearby_storage",&"cache_failure",&"access_order",&"working_set",&"blocking",&"capstone"]:
		check(root.get_node("LocalityChapter").completed_levels().get(required,false),"Locality stage retains every required earned result: "+String(required))

func finish() -> void:
	var core_extension: bool = resume_stage in ["","construction","system","locality"] and not "--interaction-only" in OS.get_cmdline_user_args()
	if failures.is_empty() and core_extension:
		if resume_stage != "locality": await system_path()
		if failures.is_empty(): await locality_path()
	if core_extension:
		for required: StringName in [&"assembly",&"cpu_speed",&"ram_wait",&"bus_width",&"bottleneck"]:
			check(root.get_node("SystemChapter").completed_levels().get(required,false),"Complete QA route earns every system task: "+String(required))
		for required: StringName in [&"distant_reads",&"nearby_storage",&"cache_failure",&"access_order",&"working_set",&"blocking",&"capstone"]:
			check(root.get_node("LocalityChapter").completed_levels().get(required,false),"Complete QA route earns every locality task: "+String(required))
	var save: Node = root.get_node("GlobalSave")
	check(save.save_game(),"Actual UI-earned Game sources and chapter receipts are persisted to the QA profile")
	check(FileAccess.file_exists(save.storage_path),"QA Game save exists for an independent restart")
	check(FileAccess.file_exists(save.workbench_storage_path),"QA source circuits exist for independent provenance revalidation")
	var file := FileAccess.open(evidence_root+"path-notes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(path_notes,"\t"))
	await super.finish()

func _run() -> void:
	# Both profiles are inside an isolated QA user directory; never bind a player
	# profile. qa-default may contain a byte-for-byte copy of an earlier QA run.
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/"):
		check(false,"Proxy requires an isolated QA user-data directory")
		await super.finish()
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--resume="): resume_stage = arg.trim_prefix("--resume=")
		if arg == "--proxy-profile=qa-default": qa_default_profile = true
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test(save.DEFAULT_STORAGE_PATH if qa_default_profile else "user://proxy-save.json",save.DEFAULT_WORKBENCH_PATH if qa_default_profile else "user://proxy-workbenches.json")
	var has_profile: bool = FileAccess.file_exists(save.storage_path) or FileAccess.file_exists(save.storage_path+save.BACKUP_SUFFIX)
	if has_profile:
		check(save.load_game(),"QA profile loads and revalidates actual earned sources")
	else:
		check(resume_stage.is_empty(),"A resume stage requires an existing UI-earned QA profile")
	if not failures.is_empty(): await super.finish(); return
	if resume_stage.is_empty():
		await super._run()
		return
	check(resume_stage in ["construction","system","locality","overlap","layout"],"Resume names a supported player path stage")
	if not failures.is_empty(): await super.finish(); return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600,900)
	await create_timer(1.0).timeout
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await settle(8)
	check(not root.get_node("GameMode").is_test_mode(),"Resume uses only previously UI-earned Game save")
	if not await journey_from_current(): await super.finish(); return
	if resume_stage == "construction":
		for level: StringName in [&"alu",&"ram"]:
			await enter_level(level)
			if not is_instance_valid(ui) or current_scene != ui or ui.current_level_id != level: break
			# --script workbenches start in memory. Rebuild through real port gestures
			# rather than loading a reference or manufacturing earned progress.
			if level == &"alu":
				await connect_actions([["A_IN","AND_1"],["B_IN","AND_1",0,1],["A_IN","OR_1"],["B_IN","OR_1",0,1],["A_IN","NOT_1"],["A_IN","FULL_ADDER"],["B_IN","FULL_ADDER",0,1],["CIN_IN","FULL_ADDER",0,2],["AND_1","MUX"],["OR_1","MUX",0,1],["FULL_ADDER","MUX",0,2],["NOT_1","MUX",0,3],["OP0_IN","MUX",0,4],["OP1_IN","MUX",0,5],["MUX","RESULT_OUT"],["FULL_ADDER","CARRY_OUT",1,0]])
			else:
				await connect_actions([["ADDR_IN","DECODER"],["WRITE_IN","DECODER",0,1],["DATA_IN","REG_0"],["DATA_IN","REG_1"],["DECODER","REG_0",0,1],["DECODER","REG_1",1,1],["REG_0","MUX"],["REG_1","MUX",0,1],["ADDR_IN","MUX",0,2],["MUX","OUT"]])
			await investigation(String(level))
			await super.official_and_seal()
			if not on_task_tree(): check(false,"Construction resume returns to journey"); break
		if failures.is_empty(): await load_store_bridge()
	elif resume_stage in ["system","locality"]:
		pass # finish explicitly runs the requested stage and its locality continuation.
	elif resume_stage == "overlap": await overlap_path()
	elif resume_stage == "layout": await layout_path()
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
	var a: GraphNode=ui.graph.get_node_or_null(from)
	var b: GraphNode=ui.graph.get_node_or_null(to)
	check(a != null and b != null,"Requested overlap endpoints exist: "+from+" → "+to)
	if a == null or b == null: return
	await drag(a.get_global_transform()*a.get_output_port_position(output),b.get_global_transform()*b.get_input_port_position(input))
	check(ui.graph.is_node_connected(from,output,to,input),"Visible overlap wire "+from+" → "+to)

func overlap_path() -> void:
	if not await stage_task("chapter_3/arrival","OverlapChapterWorkbench"): return
	check(not root.get_node("OverlapChapter").completed().has("arrival") and not root.get_node("OverlapChapter").completed().has("buffers"),"Overlap failure/unlock replay requires an untouched QA branch")
	if not failures.is_empty(): return
	await overlap_run("arrival-read-before-ready")
	check(not root.get_node("OverlapChapter").completed().has("arrival"),"Early consume failure cannot earn arrival")
	await overlap_tool("program")
	await replace_program("fetch A 0\nwork 4\nready A\nconsume A\nidle")
	await overlap_run("arrival-ready-evidence")
	check(root.get_node("OverlapChapter").completed().has("arrival"),"Arrival earned through typed program")
	if not root.get_node("OverlapChapter").completed().has("arrival"): return
	await press(ui.completion.continue_button)
	await settle(8)
	if not await stage_task("chapter_3/buffers","OverlapChapterWorkbench"): return
	await capture("buffers-empty-board")
	for id: String in ui.panels:
		if id != "toolbox" and ui.panels[id].visible: await press(ui.panels[id].find_child("CloseButton",true,false))
	var palette: Control
	for item: Node in ui.panels.toolbox.find_children("*","",true,false):
		if item.get_script()==preload("res://src/hardware_foundations/component_palette_item.gd"): palette=item; break
	check(palette != null,"Buffer palette exists for real placement")
	if palette == null: return
	for at: Vector2 in [Vector2(510,320),Vector2(510,580)]: await drag(palette.get_global_rect().get_center(),at)
	check(ui.board.nodes.has("A") and ui.board.nodes.has("B"),"Two buffers are placed by palette drag")
	if not ui.board.nodes.has("A") or not ui.board.nodes.has("B"): return
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
	if not root.get_node("OverlapChapter").completed().has("buffers"): return
	await press(ui.completion.continue_button)

func select_task(task: String) -> bool:
	if not await stage_task(task,"LayoutWorkbench"): return false
	await capture(task.replace("/","-")+"-tree-entry")
	return true

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
	if not await select_task("chapter_4/fields"): return
	check(ui.level=="fields","Fields prerequisite selected through task tree")
	await press(named_button(ui,text(&"layout.mission.begin")))
	await layout_run("fields-record-order")
	await layout_tools()
	await choose(layout_options()[0],1)
	await layout_run("fields-by-field")
	check(root.get_node("LayoutChapter").completed().has("fields"),"Fields earned by visible ordering choice")
	if not root.get_node("LayoutChapter").completed().has("fields"): return
	await layout_button("任务树","Task tree")
	if not await select_task("chapter_4/relocation"): return
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
	bind_qa_workbench_store()
	await super.named_design()
