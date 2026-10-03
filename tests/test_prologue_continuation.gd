extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func run() -> void:
	root.get_node("GameMode").set_mode(&"game")
	var main: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(main)
	await process_frame; await process_frame
	main.completed_levels = {&"tutorial":true}
	main._start_campaign_level(&"tutorial")
	for frame: int in 5: await process_frame
	check(not main.mission_briefing_active and main.mission_compact,"Replay keeps the canvas clear with a compact reopenable mission")
	check(main.desktop_windows[&"test_bench"].size.y >= 320,"Replay retains usable test-bench input space without the briefing layout")
	main._reopen_mission(); await process_frame
	check(main.mission_briefing_active,"Replay rules remain available through Mission")
	main.completed_levels.clear(); main._start_campaign_level(&"tutorial"); await process_frame
	check(main.mission_briefing_active,"First visit still presents the complete rules")
	main.completed_levels = {&"tutorial":true}
	check(main._next_campaign_level(&"tutorial") == &"half_adder","First completion retains the normal arithmetic route")
	main.completed_levels = {&"tutorial":true,&"half_adder":true,&"full_adder":true,&"alu":true}
	check(main._next_campaign_level(&"alu") == &"latch","Arithmetic-first route starts unfinished storage")
	main.completed_levels[&"latch"] = true; main.completed_levels[&"register"] = true; main.completed_levels[&"ram"] = true
	var before: Dictionary = main.completed_levels.duplicate(true)
	check(main._next_campaign_level(&"alu") == &"cpu","Storage-first then ALU goes to unlocked CPU, not completed latch")
	check(main._next_campaign_level(&"tutorial") == &"cpu","Replaying earlier tasks continues to the remaining core task")
	check(main.completed_levels == before,"Choosing next task never fabricates completion")
	main.completed_levels.erase(&"alu")
	check(main._next_campaign_level(&"ram") == &"alu","Storage-first still points to missing arithmetic prerequisite")
	main.completed_levels[&"alu"] = true; main.completed_levels[&"cpu"] = true
	check(main._next_campaign_level(&"alu") == &"load_store","Already completed CPU is skipped without skipping bridge")
	main.completed_levels[&"load_store"] = true
	check(main._next_campaign_level(&"alu").is_empty(),"Completed core returns to map rather than forcing replay")
	check(main._next_campaign_level(&"unknown").is_empty(),"Unknown task does not enter arbitrary progression")
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(320,220)
	root.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 400
	column.add_child(spacer)
	var investigation = load("res://src/hardware_foundations/construction_investigation.gd").new()
	investigation.configure(&"alu",func(key: StringName) -> String: return String(key))
	column.add_child(investigation)
	for frame: int in 3: await process_frame
	(investigation.get_child(0) as Button).button_pressed = true
	for frame: int in 5: await process_frame
	var first: Control = investigation.find_child("Preset0",true,false)
	check(scroll.scroll_vertical > 0 and scroll.get_global_rect().encloses(first.get_global_rect()),"Opening a below-fold experiment reveals its first input choice")
	scroll.queue_free()
	main.queue_free(); await process_frame
	print("PASS: prologue continuation" if failures.is_empty() else "FAIL: prologue continuation")
	quit(0 if failures.is_empty() else 1)
