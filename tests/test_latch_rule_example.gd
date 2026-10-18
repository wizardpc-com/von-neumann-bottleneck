extends SceneTree
## Isolated rule browsing after five real tutorial actions; renderer input is controller evidence.

const Simulator = preload("res://src/circuit/prologue_simulator.gd")
const Catalog = preload("res://src/hardware_foundations/prologue_level_catalog.gd")
const Component = preload("res://src/circuit/logic_component.gd")
const Circuit = preload("res://src/circuit/logic_circuit.gd")
const Session = preload("res://experiments/creation/session.gd")
var checks: int = 0
var failures: Array[String] = []
var capture: bool = false
var captures: Array[Dictionary] = []


func _init() -> void: call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle() -> void:
	for frame: int in 6: await process_frame


func inventory(path: String) -> Dictionary:
	var directory := DirAccess.open(path)
	if directory == null: return {"exists":false}
	var files: Dictionary = {}
	var directories: Array[String] = []
	for name: String in directory.get_files(): files[name] = FileAccess.get_sha256(path.path_join(name))
	for name: String in directory.get_directories():
		directories.append(name)
		files[name + "/"] = inventory(path.path_join(name))
	directories.sort()
	return {"exists":true,"files":files,"directories":directories}


func protected_state(host: Control) -> String:
	var save: Node = root.get_node("GlobalSave")
	var snapshot: Dictionary = save._save_snapshot()
	snapshot.erase("saved_at_utc")
	var files: Dictionary = {}
	for path: String in [save.storage_path, save.storage_path+".bak", save.workbench_storage_path]:
		files[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	var nav: Node = root.get_node("TaskNavigation")
	return JSON.stringify({"game":snapshot,"circuit":host._capture_workbench_snapshot(),
		"files":files,"creation":inventory(Session.default_path().get_base_dir()),
		"nav":{"selected":nav.selected,"pending":nav.pending,"from_tree":nav.from_tree,"last":nav.last_visited_task}},"",true)


func visible_rect(rect: Rect2, node: Control) -> bool:
	if not node.is_visible_in_tree() or not root.get_visible_rect().encloses(rect): return false
	var ancestor: Node = node
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents and not ancestor.get_global_rect().encloses(rect): return false
		ancestor = ancestor.get_parent()
	return true


func key(code: Key, full: bool = false) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code; event.physical_keycode=code; event.pressed=down
		if full: Input.parse_input_event(event)
		else: root.push_input(event,true)
		await settle()


func click(button: Button) -> void:
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position=point; root.push_input(motion,true)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true)
		await process_frame
	await settle()


func capture_frame(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path := "user://latch-rule-captures/"+name+".png"
	check(not FileAccess.file_exists(path),"A rule frame never overwrites existing evidence: "+name)
	if FileAccess.file_exists(path): return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	check(root.get_texture().get_image().save_png(path)==OK,"Actual handbook frame saves: "+name)
	captures.append({"path":ProjectSettings.globalize_path(path),"sha256":FileAccess.get_sha256(path)})


func model_checks(view: Variant) -> void:
	view.set_diagram(&"sr_latch")
	check(view.example_count()==5,"SRLatch uses precisely the five official steps")
	var catalog := Catalog.new()
	var definition: Dictionary = catalog.definition(&"latch")
	var circuit: LogicCircuit = catalog.reference_circuit(&"latch")
	var original: String = circuit.canonical_signature()
	var report: Dictionary = Simulator.new().run_sequence(circuit,definition.official_steps,true)
	check(report.passed and circuit.canonical_signature()==original,"The original isolated five-step circuit passes without changing its topology")
	var expected_q: Array[int] = [0,0,1,1,0]
	var held: Array[Dictionary] = []
	for index: int in 5:
		var row: Dictionary = view.latch_example()
		var official: Dictionary = report.steps[index]
		check(row.s==official.inputs[&"S"] and row.r==official.inputs[&"R"] and row.q==expected_q[index] and row.nq==1-expected_q[index],
			"Displayed inputs and outputs match the real official sequence at step "+str(index+1))
		check(row.before_q==null if index==0 else row.before_q==expected_q[index-1],"Only the first Reset has unspecified prior Q; later steps inherit the preceding legal output")
		if row.s==0 and row.r==0: held.append(row.duplicate(true))
		row.q=9
		check(view.latch_example().q==expected_q[index],"A returned display snapshot cannot mutate the cached model values")
		view.advance_example(1)
	check(held.size()==2 and held[0].q==0 and held[1].q==1,"Identical 00 input holds distinct values after Reset and Set")
	check(view.example_step==0,"Five forward selections wrap to Reset")
	view.advance_example(-1)
	check(view.example_step==4,"The existing previous-example action wraps backwards")
	view.set_diagram(&"register")
	check(view.example_count()==1 and not view.has_logic_inputs() and not view.input_instruction.visible,"Register keeps its original static presentation")
	view.set_diagram(&"sr_latch")
	check(view.example_step==0 and view.latch_example().before_q==null,"Changing a term restarts the isolated sequence")
	# The primitive model rejects stable 11; no retained output is promoted to a valid state.
	var invalid := Circuit.new()
	for component: LogicComponent in [Component.new(&"S",&"input","S",&"S",true), Component.new(&"R",&"input","R",&"R",true),
		Component.new(&"L",&"sr_latch","SRLatch"),Component.new(&"Q",&"output","Q",&"Q",true)]: invalid.add_component(component)
	for wire: Array in [[&"S",0,&"L",0],[&"R",0,&"L",1],[&"L",0,&"Q",0]]:
		check(invalid.connect_ports(wire[0],wire[1],wire[2],wire[3]).is_empty(),"The invalid-input model fixture has valid isolated wiring")
	var result: PrologueSimulationResult = Simulator.new().evaluate(invalid,{&"S":1,&"R":1})
	check(not result.is_valid() and result.error_specs.any(func(spec: Dictionary) -> bool: return spec.key==&"circuit.error.invalid_latch_state"),
		"Stable 11 has a real model error rather than a fabricated stored Q")


func run() -> void:
	capture=DisplayServer.get_name()!="headless" and "--latch-rule-capture" in OS.get_cmdline_user_args()
	var localization: Node = root.get_node("Localization")
	var save: Node = root.get_node("GlobalSave")
	var nav: Node = root.get_node("TaskNavigation")
	check(not root.get_node("GameMode").is_test_mode(),"Rule browsing starts in ordinary Game mode")
	save.configure_for_test("user://latch-rule-save.json","user://latch-rule-workbench.json")
	check(nav.enter("hardware_foundations/tutorial"),"Original navigation enters the tutorial")
	await settle()
	var host: Variant = current_scene
	check(is_instance_valid(host) and host.current_level_id==&"tutorial","The actual tutorial is ready")
	if not is_instance_valid(host) or host.current_level_id!=&"tutorial": quit(1); return
	var handbook: Variant = host.terminology_handbook
	handbook.open_handbook(&"sr_latch"); await settle()
	check(not handbook.is_term_unlocked(&"sr_latch") and not handbook.detail_diagram.visible,"A fresh ordinary profile cannot reveal a future diagram or earn its prerequisite by browsing")
	handbook.close_handbook()
	if host.mission_briefing_active: host._start_building_from_briefing()
	host._on_connection_request(&"A_IN",0,&"NOT_1",0)
	host._on_connection_request(&"NOT_1",0,&"LAMP",0)
	host.input_a_button.button_pressed=true; host._run_debug()
	host._on_disconnection_request(&"NOT_1",0,&"LAMP",0)
	check(not save.game_player_content.completed_levels.get(&"tutorial",false),"Four tutorial actions still grant no completion")
	host._on_connection_request(&"NOT_1",0,&"LAMP",0); await settle()
	check(save.game_player_content.completed_levels.get(&"tutorial",false),"Only the original fifth tutorial action earns the prerequisite")
	host._dismiss_level_completion(); host._save_active_workbench()
	check(save.save_game(true),"The actual tutorial circuit is saved before read-only rules")
	var before: String = protected_state(host)
	var view: Variant = handbook.detail_diagram
	model_checks(view)
	check(protected_state(host)==before,"Isolated model examples grant no components, completion or persistent changes")
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1440,900)]:
			root.size=dimensions; root.content_scale_size=dimensions
			handbook.open_handbook(&"sr_latch"); await settle()
			check(handbook.is_term_unlocked(&"sr_latch") and view.example_step==0 and handbook.diagram_isolation_label.visible,"Actual handbook opens the earned rule at Reset with isolation text")
			var scroll: ScrollContainer = handbook.detail_scroll_container
			var next: Button = handbook.diagram_controls.get_child(1)
			var previous: Button = handbook.diagram_controls.get_child(0)
			for index: int in 5:
				check(view.example_step==index and view.latch_example().q==[0,0,1,1,0][index],"The original forward button selects the correct logical step")
				check(view.input_instruction.text.contains("S="+str(view.latch_example().s)) and view.rule_label.text.contains("S=R=1"),"Native text retains actual inputs and the invalid-input rule")
				check(view.input_instruction.get_minimum_size().y<=view.input_instruction.size.y and view.rule_label.get_minimum_size().y<=view.rule_label.size.y,"The two native wrapped captions fit their own reading areas without shrinking")
				# This is deliberate navigation of the original manual scroll, not automatic reveal.
				scroll.scroll_vertical=int(view.position.y); await settle()
				var reading := Rect2(view.get_global_rect().position+Vector2(12,8),Vector2(view.size.x-24,166))
				check(visible_rect(reading,view),"Inputs, prior state and real outputs are reachable together through the original scroll")
				check(visible_rect(handbook.close_button.get_global_rect(),handbook.close_button),"The original Close action stays accessible")
				await capture_frame(locale+"-"+str(dimensions.x)+"-step-"+str(index+1))
				scroll.ensure_control_visible(next); await settle()
				check(visible_rect(next.get_global_rect(),next),"The original next-example button is reachable")
				if capture:
					if index%2==0: await click(next)
					else: next.grab_focus(); await key(KEY_SPACE)
				else: next.pressed.emit(); await settle()
			check(view.example_step==0,"Actual forward input wraps at the final Reset")
			if capture: await click(previous)
			else: previous.pressed.emit(); await settle()
			check(view.example_step==4,"The original previous button reaches the final Reset")
			scroll.ensure_control_visible(view.rule_label); await settle()
			check(visible_rect(view.rule_label.get_global_rect(),view.rule_label),"The complete rule, invalid input and nonphysical-time explanation remain scroll-accessible")
			await capture_frame(locale+"-"+str(dimensions.x)+"-rules")
			check(protected_state(host)==before,"Every rule page preserves the player's exact circuit, save, work, leases and navigation")
			if capture and locale=="zh_CN" and dimensions.x==1280:
				scroll.ensure_control_visible(next); await settle(); next.grab_focus()
				var held: Dictionary = view.latch_example()
				await key(KEY_F8,true)
				var tester: bool = bool(ProjectSettings.get_setting("playtest/offline_tester",false))
				var panel: Control = root.get_node("OfflineFeedback").panel if tester else root.get_node("PlaytestMoments").panel
				check(panel.is_visible_in_tree() and handbook.is_open(),"The original role feedback opens above the state rule")
				await key(KEY_ESCAPE)
				check(not panel.is_visible_in_tree() and handbook.is_open() and view.latch_example()==held,"First Escape closes only feedback and preserves the selected rule")
				check(root.gui_get_focus_owner()==next,"Feedback returns the exact existing next-example focus")
				await key(KEY_ESCAPE)
				check(not handbook.is_open(),"Next Escape returns to the existing circuit host")
			else: handbook.close_button.pressed.emit(); await settle()
			handbook.open_handbook(&"sr_latch"); await settle()
			check(view.example_step==0 and view.latch_example().before_q==null,"Closing and reopening returns to the unspecified-before-Reset start")
			handbook.close_handbook()
			check(protected_state(host)==before,"Closing the rule cannot save a demonstration into the player's project")
	# Locale refresh restarts the selected example through the existing handbook route.
	handbook.open_handbook(&"sr_latch"); view.advance_example(3)
	localization.set_locale("zh_CN" if localization.current_locale()=="en" else "en"); await settle()
	check(view.example_step==0 and view.rule_label.text.contains("S=R=1"),"An open language switch refreshes native rule text and restarts the example")
	handbook.close_handbook()
	check(protected_state(host)==before,"All ordinary browsing and locale changes preserve authority")
	if not capture: print("NOT_RUN: latch-rule renderer/pointer/Space/F8; use --latch-rule-capture without --headless")
	if capture:
		var path := "user://latch-rule-captures/receipt.json"
		check(not FileAccess.file_exists(path),"Rule capture receipt is new")
		if not FileAccess.file_exists(path):
			var file := FileAccess.open(path,FileAccess.WRITE)
			check(file!=null,"Rule capture receipt opens for writing")
			if file != null: file.store_string(JSON.stringify({"checks":checks,"failures":failures,"frames":captures},"",true)); file.close()
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"SRLatch isolated five-step handbook (%d checks)"%checks)
	quit(0 if failures.is_empty() else 1)
