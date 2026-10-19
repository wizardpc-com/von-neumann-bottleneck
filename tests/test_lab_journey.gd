extends SceneTree
## Laboratory home, terminal entry, archive data and the focused first lesson.
## Uses actual scenes and the real journey catalog; no saved solutions.
const LabHome = preload("res://src/lab/lab_home.gd")
const Fragments = preload("res://src/lab/archive_fragments.gd")
const LabState = preload("res://src/lab/lab_state.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	var navigation: Node = root.get_node("TaskNavigation")
	var rows: Array[Dictionary] = navigation.journey_tasks()
	check(rows.size() == 60, "Source project opens the full 60-task journey by default (got %d)" % rows.size())
	var keys: Array[String] = []
	for row: Dictionary in rows: keys.append(str(row.key))
	for fragment: Dictionary in Fragments.FRAGMENTS:
		check(str(fragment.requires) in keys, "Archive fragment %s opens from a real task" % fragment.id)
	check(Fragments.unlocked([]).is_empty(), "No archive page is open before any completion")
	check(Fragments.unlocked(["hardware_foundations/tutorial"]).size() == 1, "The first lesson opens exactly the first page")
	check(LabState.station_progress(rows).size() == 11, "Journey board has one station per region")

	# Home is the laboratory; the classic surface stays built but hidden.
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); await settle(12)
	var lab: Control = hub.get_node_or_null("Laboratory")
	check(lab != null and lab.visible, "Home shows the laboratory")
	var surface: Control = hub.get_node_or_null("HubSurface")
	check(surface != null and not surface.visible, "Classic surface is hidden behind the laboratory")
	var terminal: Control = lab.get_node("LabWorld/LayerDesk/LabTerminal") if lab != null else null
	check(terminal != null and terminal.asleep(), "Terminal starts on standby")
	if terminal != null:
		terminal.wake(true); await settle()
		check(not terminal.asleep() and terminal.primary.is_visible_in_tree(), "Waking shows the primary action")
		check("壹" in terminal.message.text or "Yi" in terminal.message.text, "Yi greets a new player on the terminal")
		check(not terminal.primary.text.is_empty(), "Primary action names the next step")
		var shelf: Button = lab.get_node("LabWorld/LayerMid/ArchiveShelf")
		shelf.pressed.emit(); await settle()
		var archive: Control = lab.get_node("LabArchive")
		check(archive.visible, "Archive shelf opens the reader")
		check(archive.get_node_or_null("ArchivePaper") != null, "Reader uses the room's light paper surface")
		archive.close(); await settle()
		check(not archive.visible, "Reader closes back to the lab")
	hub.queue_free(); await settle()

	# Standalone lab emits navigation requests instead of changing scenes itself.
	var standalone: Control = LabHome.new()
	root.add_child(standalone); await settle(12)
	var requested: Array[String] = []
	standalone.start_requested.connect(func(key: String) -> void: requested.append("start:" + key))
	standalone.journey_requested.connect(func() -> void: requested.append("journey"))
	# A second visit pulls back out of the screen first; input waits for that move.
	await create_timer(1.2).timeout
	standalone.terminal.wake(true); await settle()
	standalone.terminal.primary.pressed.emit()
	await create_timer(1.2).timeout
	check(requested.size() == 1 and requested[0].begins_with("start:"), "Primary terminal action requests the next task after the zoom " + str(requested))
	var after_tutorial: Array[Dictionary] = []
	for row: Dictionary in rows:
		var copy: Dictionary = row.duplicate()
		if copy.key == "hardware_foundations/tutorial": copy.completed = true
		if copy.key == "hardware_foundations/half_adder": copy.unlocked = true
		after_tutorial.append(copy)
	var next_key: String = standalone._next_task(after_tutorial, ["hardware_foundations/tutorial"])
	check(next_key != "hardware_foundations/tutorial", "After the first lesson the lab never suggests replaying it (got %s)" % next_key)
	for key: String in standalone.CHAPTER_RESPONSES:
		check(key in keys, "Chapter response %s belongs to a real task" % key)
	standalone.queue_free(); await settle()

	# Focused first lesson: circuit, step coach and test bench only.
	var bench: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench); await settle(12)
	bench.call("_show_tutorial", true); await settle(12)
	check(bench.call("_tutorial_focus"), "Unearned first lesson uses focus mode")
	check(bench.tutorial_coach != null and bench.tutorial_coach.visible, "Step coach is visible")
	check(not bench.editor_toolbar.visible, "Editing toolbar waits until the lesson is earned")
	check(not (bench.desktop_windows[&"components"] as Control).visible, "Component window is hidden for the prebuilt first circuit")
	check(not (bench.desktop_windows[&"task"] as Control).visible, "Six-page briefing does not cover the canvas")
	check((bench.desktop_windows[&"test_bench"] as Control).visible, "Test bench stays available")
	check(bench.tutorial_coach.step_label.text.contains("1 / 5") or bench.tutorial_coach.step_label.text.contains("1 / 5"), "Coach starts at step 1 / 5")
	bench.set("tutorial_created_wire", true)
	bench.call("_update_tutorial_goal"); await settle()
	check(bench.tutorial_coach.step_label.text.contains("2 / 5"), "Coach follows the real interaction flags")
	bench.tutorial_coach.briefing_requested.emit(); await settle()
	check((bench.desktop_windows[&"task"] as Control).visible, "Full briefing remains one click away")
	bench.queue_free(); await settle()

	print(("PASS: " if failures == 0 else "FAIL: ") + "lab journey %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
