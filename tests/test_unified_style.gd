extends SceneTree
## Round 3 (2026-10-20): one style and one interaction pattern across levels.
## Every workbench gets the framed header and journey names; chapter 2–4 endings
## are answered with a short conversation on the lab terminal; every level after
## the prologue opens with one line from Yi that never takes focus or input.
const Dialogues = preload("res://src/lab/chapter_dialogues.gd")
const Opening = preload("res://src/ui/yi_opening.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame

func framed(scene: Node) -> bool:
	for node: Node in scene.find_children("*Chrome", "PanelContainer", true, false): return true
	return false

func button_texts(scene: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in scene.find_children("*", "Button", true, false): texts.append(str((node as Button).text))
	return texts

func run() -> void:
	root.size = Vector2i(1280, 720)
	Typewriter.reset_seen()
	ProjectSettings.set_setting("game/reduced_motion", false)
	root.get_node("GameMode").set_mode(&"test")
	var navigation: Node = root.get_node("TaskNavigation")
	navigation.from_tree = false
	var keys: Array[String] = []
	for row: Dictionary in navigation.journey_tasks(): keys.append(str(row.key))

	# Every workbench scene: framed header, Settings, journey names, no old map label.
	var scenes: Array = [
		["res://src/hardware_foundations/hardware_foundations.tscn", "序章"],
		["res://src/system_lab/system_lab.tscn", "第一章"],
		["res://src/ui/main.tscn", "第二章"],
		["res://src/overlap_chapter/overlap_chapter.tscn", "第三章"],
		["res://src/layout_chapter/layout_chapter.tscn", "第四章"],
		["res://experiments/representation_region/region.tscn", "第五章"],
		["res://experiments/service_plan/lab.tscn", "第六章"],
		["res://experiments/prediction/lab.tscn", "第七章"],
		["res://experiments/creation/workbench.tscn", "第八章"],
	]
	for entry: Array in scenes:
		if not ResourceLoader.exists(str(entry[0])): check(false, "Scene exists: " + str(entry[0])); continue
		var scene: Node = load(str(entry[0])).instantiate()
		root.add_child(scene); current_scene = scene; await settle(10)
		var name: String = str(entry[0]).get_file()
		if not is_instance_valid(scene):
			print("SCENE_LEFT ", name)
			check(false, name + " stayed open for inspection"); continue
		var labels: Array[String] = []
		for node: Node in scene.find_children("*", "Label", true, false): labels.append(str((node as Label).text))
		check(framed(scene) or name in ["hardware_foundations.tscn", "system_lab.tscn", "main.tscn"], name + ": header sits in the shared frame")
		check(labels.any(func(text: String) -> bool: return text.begins_with(str(entry[1]))), name + ": header names the chapter as " + str(entry[1]))
		check(scene.find_child("InLevelSettings", true, false) != null, name + ": Settings is reachable from the header")
		var texts: Array[String] = button_texts(scene)
		check(not ("任务地图" in texts) and not ("返回首页" in texts) and not ("任务树" in texts), name + ": old map/home labels are gone " + str(texts.filter(func(t: String) -> bool: return t in ["任务地图", "返回首页", "任务树"])))
		var quit: Button = scene.find_child("Quit", true, false) as Button
		if quit != null: check(quit.text == "退出游戏", name + ": quit is named 退出游戏")
		var fullscreen: Control = scene.find_child("FullscreenButton", true, false)
		check(fullscreen == null or not fullscreen.visible, name + ": no fullscreen button outside Settings")
		scene.queue_free(); await settle(4)

	# Second-act task buttons use the journey numbers.
	var region: Node = load("res://experiments/representation_region/region.tscn").instantiate()
	root.add_child(region); current_scene = region; await settle(10)
	var first_task: Button = region.find_child("Task0", true, false) as Button
	check(first_task != null and first_task.text.begins_with("5-1 "), "Representation tasks read 5-1 … (got %s)" % (first_task.text if first_task != null else "none"))
	check(region.find_children("*", "TechnicalBackdrop", true, false).size() > 0 or region.get_child(0) is Control and region.get_child(0).get_script() == preload("res://src/ui/technical_backdrop.gd"), "Representation draws the shared terminal backdrop")
	region.queue_free(); await settle(4)

	# Chapter conversations: only for chapter 2–4 endings, real keys, a hook last.
	for key: String in ["chapter_2/capstone", "chapter_3/synthesis", "chapter_4/mixed"]:
		var beats: Array = Dialogues.for_key(key)
		check(key in keys and beats.size() >= 2, key + " has a conversation")
		check(not (beats[-1] as Dictionary).has("replies"), key + " ends on a hook without replies")
		for beat: Dictionary in beats.slice(0, beats.size() - 1):
			check((beat.get("replies", []) as Array).size() == 2, key + ": each beat offers two replies")
	check(Dialogues.for_key("chapter_1/bottleneck").is_empty(), "Chapter 1 keeps its single reply")

	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub; await settle(12)
	var terminal: Control = hub.get_node("Laboratory").terminal
	terminal.configure({"english": false, "new_player": false, "completed": 40, "total": 60, "response": {"chapter": {"zh": "x", "en": "x"}, "dialogue": Dialogues.for_key("chapter_2/capstone")}})
	terminal.wake(true); await settle(2)
	check(terminal.in_dialogue() and not terminal.primary.visible and not terminal.secondary.visible, "Waking after a chapter ending starts the conversation instead of the menu")
	check(terminal.message.is_playing() and terminal.choices.get_child_count() == 0, "Replies wait until Yi has finished speaking")
	terminal.message.complete_now(); await settle(2)
	check(terminal.choices.get_child_count() == 2, "Two replies appear once Yi finishes")
	(terminal.choices.get_child(0) as Button).pressed.emit(); await settle(2)
	check(terminal.echo.visible and terminal.echo.text.begins_with("你："), "The chosen reply is echoed as the player's line")
	check(terminal.message.text.begins_with("对这台机器"), "Yi answers that reply")
	terminal.message.complete_now(); await settle(2)
	check(terminal.choices.get_child_count() == 1, "After an answer there is one way on")
	var guard: int = 0
	while terminal.in_dialogue() and guard < 12:
		guard += 1
		terminal.message.complete_now(); await settle(2)
		if terminal.choices.get_child_count() > 0: (terminal.choices.get_child(0) as Button).pressed.emit()
		await settle(2)
	check(not terminal.in_dialogue() and terminal.primary.visible and terminal.secondary.visible, "The menu returns when the conversation ends")
	check(not terminal.response.has("dialogue"), "A conversation plays once")
	hub.queue_free(); await settle(4)

	# Opening line: one per level per session, never on the prologue, never blocking.
	Opening.reset_shown()
	check(Opening.present(self, &"hardware_foundations", &"full_adder", true) == null, "The prologue keeps its step card instead")
	check(Opening.present(self, &"chapter_2", &"distant_reads") == null, "Headless runs skip the opening unless forced")
	var opening: CanvasLayer = Opening.present(self, &"chapter_2", &"distant_reads", true)
	await settle(3)
	check(opening != null and opening.is_inside_tree() and opening.body.text.contains("RAM"), "The opening says what this task asks for")
	check(opening.card.mouse_filter == Control.MOUSE_FILTER_IGNORE and opening.body.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The opening never takes pointer input")
	check(root.gui_get_focus_owner() == null or not opening.card.is_ancestor_of(root.gui_get_focus_owner()), "The opening never takes focus")
	check(opening.card.get_global_rect().end.y < opening.get_viewport().get_visible_rect().size.y - 40, "The opening floats above the bottom bar")
	Opening.dismiss(); await settle(2)
	check(not is_instance_valid(opening) or opening.is_queued_for_deletion(), "Leaving the level dismisses the opening")
	print(("PASS: " if failures == 0 else "FAIL: ") + "unified style %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
