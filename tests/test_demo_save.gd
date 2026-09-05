extends SceneTree

const Foundations = preload("res://src/demo/demo_foundations.gd")
const PerformanceTask = preload("res://src/demo/demo_performance.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func _run() -> void:
	var progress: Node = root.get_node("DemoProgress")
	var mode: Node = root.get_node("GameMode")
	progress.storage_path = "res://.godot/redesign/save-test-%d.json" % Time.get_ticks_usec()
	progress.writes_enabled = true
	var legacy_path := "res://.godot/redesign/legacy-named-workbenches-fixture.json"
	write(legacy_path, '{"named": "旧方案-保留", "version": 1}')
	var legacy_before := FileAccess.get_sha256(legacy_path)
	var circuit := Foundations.restore(Foundations.initial("dp_select"))
	circuit.connect_ports(&"A", 0, &"MUX", 0)
	circuit.connect_ports(&"B", 0, &"MUX", 1)
	circuit.connect_ports(&"SEL", 0, &"MUX", 2)
	circuit.connect_ports(&"MUX", 0, &"OUT", 0)
	var design := Foundations.snapshot(circuit)
	var receipt := Foundations.run("dp_select", 0, design)
	progress.remember("dp_select", 0, design)
	progress.record_run(receipt)
	check(progress.enter("dp_store", 0), "Verified P-1 unlocks staged storage.")
	progress.remember("dp_store", 0, Foundations.initial("dp_store"))
	check(progress.save_game(), "Atomic primary save writes successfully.")
	progress.game = progress._empty()
	check(progress.load_game() and progress.stage_complete("dp_select", 0), "Restart replays component behavior and restores completion.")
	check(progress.game["current"] == "dp_store" and progress.draft("dp_store", 0) == Foundations.initial("dp_store"), "Current stage and unfinished circuit survive restart.")
	var accepted: Dictionary = progress.accepted_design("dp_select", 0)
	progress.remember("dp_select", 0, Foundations.initial("dp_select"))
	check(progress.stage_complete("dp_select", 0) and progress.accepted_design("dp_select", 0) == accepted, "Trying an empty design does not destroy historical accepted design.")
	check(progress.save_game(), "Backup rotation succeeds.")
	write(progress.storage_path, '{"interrupted":')
	write(progress.storage_path + ".tmp", '{"incomplete":')
	check(progress.load_game() and progress.recovered, "Partial primary and temp recover from previous valid backup.")
	check(progress.save_game() and progress.stage_complete("dp_select", 0), "Recovered save can be safely written without losing backup.")
	var before := FileAccess.get_sha256(progress.storage_path)
	mode.set_mode(&"test")
	progress.remember("dp_select", 0, Foundations.initial("dp_select"))
	progress.record_run(receipt)
	check(not progress.save_game() and before == FileAccess.get_sha256(progress.storage_path), "Test never writes Game evidence or drafts.")
	mode.set_mode(&"game")
	check(progress.accepted_design("dp_select", 0) == accepted, "Returning to Game restores its independent state.")
	var future := '{"schema":99,"content":"future","payload":"preserve"}'
	write(progress.storage_path, future)
	check(not progress.load_game() and not progress.writes_enabled, "Future schema fails closed even with an older backup.")
	check(not progress.save_game() and FileAccess.get_file_as_string(progress.storage_path) == future, "Unknown save bytes are never overwritten.")
	progress.writes_enabled = true
	progress.storage_path += ".missing-source"
	progress.game["completed"]["dp_select:0"]["design"].erase("provenance")
	progress.save_game()
	check(progress.load_game() and not progress.stage_complete("dp_select", 0), "Missing component origin is not fabricated during replay.")
	check(progress.game["completed"].has("dp_select:0"), "Unverifiable evidence remains retained as pending history.")
	check(legacy_before == FileAccess.get_sha256(legacy_path), "Independent legacy named workbench bytes are untouched.")
	var row := PerformanceTask.initial("d2_order")
	row["source"] = PerformanceTask.ROW_SOURCE
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(row))
	check(PerformanceTask.run("d2_order", 0, row)["signature"] == PerformanceTask.run("d2_order", 0, serialized)["signature"], "Performance draft JSON roundtrip preserves replay identity.")
	progress.storage_path += ".bad-shape"
	var malformed: Dictionary = {"schema": 1, "content": "demo-route-v1", "game": progress._empty()}
	malformed["game"]["drafts"]["d1_cpu:0"] = {"source": []}
	write(progress.storage_path, JSON.stringify(malformed))
	write(progress.storage_path + ".bak", "broken backup")
	before = FileAccess.get_sha256(progress.storage_path)
	check(not progress.load_game() and not progress.writes_enabled, "Malformed draft shapes and corrupt backups fail before UI use.")
	check(not progress.save_game() and before == FileAccess.get_sha256(progress.storage_path), "Malformed draft bytes remain protected.")
	malformed["game"] = progress._empty()
	for layout: Variant in ["not a layout", {"A": ["bad", 20]}, {"missing-part": [10, 20]}]:
		var bad_design := Foundations.initial("dp_select")
		bad_design["layout"] = layout
		malformed["game"]["drafts"]["dp_select:0"] = bad_design
		write(progress.storage_path, JSON.stringify(malformed))
		check(not progress.load_game(), "Malformed circuit layout cannot reach the live editor.")
	progress.writes_enabled = false
	if failures.is_empty():
		print("PASS: mainline save replay, staged resume, backup recovery, future/corrupt protection, pending provenance and Game/Test isolation")
	quit(0 if failures.is_empty() else 1)
