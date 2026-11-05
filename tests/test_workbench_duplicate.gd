extends SceneTree
## Actual controller/menu and isolated disk transactions; no player saves.

const Store = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
const Bench = preload("res://src/circuit/half_adder_test_bench.gd")
var checks: int = 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle(frames: int = 8) -> void:
	for frame: int in range(frames):
		await process_frame


func normalized(snapshot: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(snapshot, "", true, true))


func measured_signatures(ui: Control) -> Array[String]:
	var report: Dictionary = Bench.new().run_official(ui._circuit_from_graph())
	check(report.passed, "The complete copied circuit passes all real official inputs")
	var signatures: Array[String] = []
	for result: Dictionary in report.cases:
		signatures.append(result.trace.canonical_signature())
	return signatures


func duplicate_from_menu(ui: Control, name: String) -> void:
	ui._refresh_workbench_menu()
	var menu: PopupMenu = ui.workbench_menu_button.get_popup()
	var item_id: int = -1
	for index: int in menu.item_count:
		var metadata: Variant = menu.get_item_metadata(index)
		if metadata is Dictionary and metadata.get("action") == &"duplicate":
			item_id = menu.get_item_id(index)
			break
	check(item_id >= 0, "The plan menu exposes Duplicate current design")
	if item_id < 0:
		return
	menu.id_pressed.emit(item_id)
	check(ui.workbench_name_dialog.visible and ui.new_workbench_duplicate, "The duplicate menu opens the existing naming dialog in copy mode")
	check(ui.workbench_seed_preview.visible, "The copy dialog previews the current design")
	ui.workbench_name_edit.text = name
	ui.workbench_name_edit.text_submitted.emit(name)
	await settle()


func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run workbench duplication through scripts/verify-project.py with an isolated profile.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	ProjectSettings.set_setting("game/reduced_motion", true)
	var directory: String = "user://workbench-duplicate-" + Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(directory) == OK, "Create an isolated duplicate fixture")
	var path: String = directory.path_join("boards.json")
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test(directory.path_join("game.json"), path)
	check(root.get_node("GameMode").set_mode(&"test"), "Begin in the separate Test namespace")
	var game_before: Dictionary = save._save_snapshot().game.duplicate(true)
	var ui: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(ui)
	await settle()
	ui.workbench_store = Store.new(path)
	ui._start_campaign_level(&"half_adder", false)
	await settle()
	ui._set_active_wire_color(3)
	for wire: Dictionary in ui._half_adder_reference_wires():
		ui._on_connection_request(wire.from_node, wire.from_port, wire.to_node, wire.to_port)
	ui._on_begin_node_move()
	ui.component_nodes[&"AND_1"].position_offset += Vector2(47.0, 31.0)
	ui._on_end_node_move()
	await settle()
	var source: Dictionary = ui._capture_workbench_snapshot()
	var signatures: Array[String] = measured_signatures(ui)
	ui.official_button.pressed.emit()
	for frame: int in range(160):
		if not ui.official_sequence_active:
			break
		await process_frame
	check(ui.official_passed and not ui.official_report.is_empty(), "Source has actual official evidence before copying")
	ui._dismiss_level_completion()
	await duplicate_from_menu(ui, "Circuit B")
	check(ui.active_workbench_name == "Circuit B" and not ui.workbench_name_dialog.visible, "Named copy becomes the active editable design")
	check(ui._capture_workbench_snapshot() == source, "Copy retains every component, wire, position and cable color")
	check(not ui.official_passed and ui.official_report.is_empty() and ui.passing_topology_signature.is_empty(), "Copy requires fresh verification instead of inheriting the source verdict")
	check(ui.wire_history.is_empty() and ui.redo_history.is_empty(), "Copy starts its own editor history")
	check(measured_signatures(ui) == signatures, "Copied circuit produces identical deterministic results, metrics and event traces")
	check(ui.workbench_store.workbench_snapshot(&"test", &"half_adder", "default") == source, "Original is saved before activating the copy")
	var persisted: RefCounted = Store.new(path)
	check(persisted.active_name(&"test", &"half_adder") == "Circuit B"
		and persisted.workbench_snapshot(&"test", &"half_adder", "default") == normalized(source)
		and persisted.active_snapshot(&"test", &"half_adder") == normalized(source), "Independent store reopen restores both original and copied designs")

	ui._on_disconnection_request(&"AND_1_COPY_002", 0, &"CARRY_OUT", 0)
	await settle()
	var changed: Dictionary = ui._capture_workbench_snapshot()
	check(changed != source, "Editing the copied circuit changes its own topology")
	check(ui.workbench_store.workbench_snapshot(&"test", &"half_adder", "default") == source, "Editing the copy leaves the source snapshot untouched")
	check(ui._switch_workbench("default"), "Switch back to the original design")
	await settle()
	check(ui._capture_workbench_snapshot() == source and measured_signatures(ui) == signatures, "Switching back restores original geometry, wires and simulation")
	check(not ui._create_named_workbench("Circuit B", false, true), "Copy refuses an existing name")
	check(ui.active_workbench_name == "default" and ui._capture_workbench_snapshot() == source, "Duplicate-name refusal keeps the original active and intact")
	ui._hide_new_workbench_dialog()

	var disk_before: String = FileAccess.get_file_as_string(path)
	check(DirAccess.make_dir_absolute(path + Store.TEMP_SUFFIX) == OK, "Inject a real temporary-file write failure")
	ui.component_nodes[&"AND_1"].position_offset += Vector2(32.0, 16.0)
	var unsaved: Dictionary = ui._capture_workbench_snapshot()
	check(not ui._create_named_workbench("Cannot save", false, true), "Copy refuses to switch when the source cannot be saved")
	check(ui.active_workbench_name == "default" and ui._capture_workbench_snapshot() == unsaved
		and not "Cannot save" in ui.workbench_store.workbench_names(&"test", &"half_adder"), "Failed copy preserves current work without a phantom named design")
	check(FileAccess.get_file_as_string(path) == disk_before, "Failed copy leaves durable original and copy bytes unchanged")
	check(DirAccess.remove_absolute(path + Store.TEMP_SUFFIX) == OK, "Remove only the fixture write obstruction")
	check(ui._save_active_workbench(), "Original saves successfully after storage recovery")
	check(ui._create_named_workbench("Seeded"), "Existing seeded creation remains available")
	await settle()
	check(ui._capture_workbench_snapshot() == ui.workbench_seed_snapshot, "Seeded creation keeps its original fresh-inventory behavior")
	check(ui._create_named_workbench("Blank", true), "Existing blank creation remains available")
	await settle()
	check(ui._capture_workbench_snapshot() == ui._fixed_terminal_snapshot(ui.workbench_seed_snapshot), "Blank creation keeps only its fixed interfaces")
	ui._start_campaign_level(&"tutorial", false)
	await settle()
	ui._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	ui._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await settle()
	var test_tutorial: Dictionary = ui._capture_workbench_snapshot()
	await duplicate_from_menu(ui, "Circuit B")
	check(save._save_snapshot().game == game_before, "Test duplication and editing grant no Game rewards")

	check(root.get_node("GameMode").set_mode(&"game"), "Switch through the real Game/Test guard")
	ui._start_campaign_level(&"tutorial", false)
	await settle()
	ui._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	await settle()
	var game_source: Dictionary = ui._capture_workbench_snapshot()
	await duplicate_from_menu(ui, "Circuit B")
	check(ui.active_workbench_namespace == &"game" and ui._capture_workbench_snapshot() == game_source, "Game can independently use the same copy name in the same task")
	check(ui.workbench_store.workbench_snapshot(&"test", &"tutorial", "Circuit B") == test_tutorial, "Game copying preserves the distinct Test circuit for the same task and name")
	check(ui.workbench_store.workbench_snapshot(&"test", &"half_adder", "Circuit B") == changed, "Game copy never modifies the Test design")
	check(save._save_snapshot().game == game_before, "Naming a Game copy grants no completion or components")
	ui.queue_free()
	await settle()
	for suffix: String in ["", Store.TEMP_SUFFIX, Store.BACKUP_SUFFIX]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	print("PASS: workbench duplicate %d checks" % checks if failures.is_empty() else "FAIL: workbench duplicate %d/%d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
