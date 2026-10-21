extends SceneTree
## Repeated real scene callbacks and root Esc. No native rendering/FPS claim.
var checks: int=0
var failures: int=0
var counts: Array[int]=[]
var orphans: Array[int]=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func settle(frames: int=8) -> void:
	for frame: int in frames:await process_frame
func escape() -> void:
	for down: bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.physical_keycode=KEY_ESCAPE;event.pressed=down
		root.push_input(event,true);await process_frame
	await settle()
func run() -> void:
	ProjectSettings.set_setting("playtest/offline_tester",false)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub);current_scene=hub;await settle(16)
	var lab: Control=hub.laboratory
	for cycle: int in 8:
		root.get_node("Localization").set_locale("en" if cycle%2 else "zh_CN")
		var reduced: bool=cycle<4
		ProjectSettings.set_setting("game/reduced_motion",reduced)
		root.size=Vector2i(1280,720) if cycle%2 else Vector2i(1600,900)
		root.content_scale_size=root.size
		await settle()
		for feature: String in ["archive","handbook","settings","works"]:
			lab.room.activated.emit(feature)
			if not reduced:await create_timer(1.1).timeout
			await settle()
			check(lab.terminal_pages.active(),"Repeated feature entry remains hosted in terminal: "+feature)
			check(lab.room.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Covered room stops rendering: "+feature)
			await escape()
			if not reduced:await create_timer(1.1).timeout
			await settle()
			check(not lab._room_blocked(),"Esc returns from feature without a stale modal: "+feature)
			lab._on_terminal_action("look")
			if not reduced:await create_timer(1.1).timeout
			await settle()
			check(not lab.room_focus and lab.room.visible and lab.room._interaction_enabled,"Room picking becomes available again: "+feature)
			check(not lab.terminal.confirming(),"Returning from a page does not accidentally ask to quit")
		await settle(24)
		counts.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		orphans.append(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	print("SOAK node_counts=",counts," orphan_counts=",orphans)
	# All readers have been warmed by cycle two. A repeated visit must not retain
	# another scene/card graph; exact observed counts are printed for audit.
	check(counts[-1]<=maxi(counts[2],counts[3])+2,"Repeated navigation does not accumulate retained scene nodes")
	check(orphans[-1]<=maxi(orphans[2],orphans[3]),"Repeated navigation does not accumulate orphan nodes")
	hub.queue_free();await settle()
	print("PASS: test_lab_navigation_soak " if failures==0 else "FAIL: test_lab_navigation_soak ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
