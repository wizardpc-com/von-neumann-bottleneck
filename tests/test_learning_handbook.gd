extends SceneTree

var handbook_type: GDScript
const NarrativeType = preload("res://src/ui/mission_narrative_catalog.gd")
const LinkedTextType = preload("res://src/ui/linked_mission_text.gd")

var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	handbook_type = load("res://src/ui/terminology_handbook.gd")
	var handbook: Variant = handbook_type.new()
	root.add_child(handbook)
	await process_frame
	_check_diagram_models(handbook.detail_diagram)
	_check_signal_diagram_models(handbook.detail_diagram)
	var save: Node = root.get_node("GlobalSave")
	var system: Node = root.get_node("SystemChapter")
	var locality: Node = root.get_node("LocalityChapter")
	var localization: Node = root.get_node("Localization")
	var player_signature: String = save.game_player_content.canonical_signature()
	handbook.open_handbook()
	check(handbook.visible_term_ids.size() == 3 and not handbook.future_toggle.button_pressed, "Future subjects do not flood the initial table of contents.")
	handbook.open_handbook(&"cache")
	check(handbook.available_term_ids.size() == 21, "First-lesson specifications remain available behind the three recommended topics.")
	check(not handbook.is_term_unlocked(&"cache") and not handbook.detail_diagram.visible, "Opening a future term directly cannot reveal its diagram.")
	check(handbook.detail_body_label.text.contains(localization.text(&"terminology.locked.body", [handbook._lesson_title(&"cache")])), "Future topics explain the actual lesson that opens them.")
	check(save.game_player_content.canonical_signature() == player_signature, "Reading the handbook cannot mark lessons complete or install components.")
	var mapped: Array[StringName] = []
	for lesson: StringName in handbook_type.LESSON_TERMS:
		for term: StringName in handbook_type.LESSON_TERMS[lesson]:
			check(handbook_type.has_term(term) and term not in mapped, "Each mapped term exists exactly once: %s" % term)
			mapped.append(term)
	check(mapped.size() == handbook_type.TERMS.size(), "All existing terms have an explicit learning stage.")

	# These snapshots exercise availability policy only. End-to-end Game tests
	# separately earn these prerequisites by building and testing player circuits.
	for level: StringName in handbook.prologue_catalog.level_ids():
		_check_recommendations(handbook, "hardware", String(level))
		for locale: String in ["zh_CN", "en"]:
			localization.set_locale(locale)
			var pages: Array = NarrativeType.HARDWARE_PAGES.get(level, [])
			for page: Dictionary in pages:
				_check_required_links(handbook, localization.text(page[&"body"]), String(level))
		save.game_player_content.completed_levels[level] = true
		if level == &"tutorial":
			check(handbook.is_term_unlocked(&"half_adder") and handbook.is_term_unlocked(&"sr_latch"), "Tutorial opens both existing construction branches in the handbook.")
			check(not handbook.is_term_unlocked(&"alu") and not handbook.is_term_unlocked(&"cpu"), "Tutorial does not skip later construction stages.")
	system.prologue_ready = true
	for level: StringName in handbook.system_catalog.level_ids():
		_check_recommendations(handbook, "system", String(level))
		for locale: String in ["zh_CN", "en"]:
			localization.set_locale(locale)
			for key: StringName in NarrativeType.SYSTEM_PAGES[level]:
				_check_required_links(handbook, localization.text(key), String(level))
		system.game_completed[level] = true
	for level: StringName in handbook.locality_catalog.level_ids():
		_check_recommendations(handbook, "locality", String(level))
		for locale: String in ["zh_CN", "en"]:
			localization.set_locale(locale)
			for key: StringName in NarrativeType.LOCALITY_PAGES[level]:
				_check_required_links(handbook, localization.text(key), String(level))
		locality.game_completed[level] = true
	handbook.open_handbook()
	check(handbook.is_term_unlocked(&"data_layout") and not handbook.is_term_unlocked(&"copy_cost"), "Layout rules appear at entry; conversion waits for its task.")
	check(handbook.available_term_ids.size() == 93, "Original campaign completion opens 90 original terms, two Chapter 3 arrival terms and one Chapter 4 layout term, not later branch concepts.")
	check(not handbook.is_term_unlocked(&"prefetch"), "Entering Chapter 3 does not introduce the later prefetch branch early.")
	var overlap: Node = root.get_node("OverlapChapter")
	for level: String in preload("res://src/overlap_chapter/overlap_catalog.gd").IDS:
		_check_recommendations(handbook, "overlap", level)
		overlap.game_solutions[level] = {} # Availability fixture only, never a played solution.
	overlap.game_solutions.clear()
	for context: StringName in handbook_type.RECOMMENDED:
		check(handbook_type.RECOMMENDED[context].size() <= 3, "Each lesson recommends at most three subjects: "+String(context))
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN", "en"]:
		localization.set_locale(locale)
		_check_diagram_captions(handbook.detail_diagram, localization, locale)
		for term: Dictionary in handbook_type.TERMS:
			handbook.open_handbook(term["id"])
			await process_frame
			check(not handbook.detail_body_label.text.begins_with("terminology."), "Entry is translated: %s %s" % [locale, term["id"]])
			if term.has("diagram"):
				check(handbook.detail_diagram.visible, "Illustrated entry renders: %s %s" % [locale, term["id"]])
				var saved_before: String = save.game_player_content.canonical_signature()
				for step: int in range(handbook.detail_diagram.example_count()):
					handbook.detail_diagram.advance_example(1)
				check(handbook.detail_diagram.example_step == 0 and saved_before == save.game_player_content.canonical_signature(), "Illustrative steps wrap without modifying the player's content: "+String(term["id"]))
				if "--handbook-capture" in OS.get_cmdline_user_args() and term["id"] in [&"signal", &"binary", &"half_adder", &"sr_latch", &"register", &"junction", &"bit_width", &"data_layout", &"field_group", &"copy_cost", &"bounded_batch", &"multiplexer", &"alu", &"accumulator", &"cache"]:
					await RenderingServer.frame_post_draw
					var folder := "res://.godot/polish/handbook/"
					DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
					root.get_texture().get_image().save_png(folder + locale + "-" + String(term["id"]) + ".png")
	handbook.search_edit.text = "cache"
	handbook.open_handbook(&"bit")
	check(handbook.search_edit.text.is_empty() and handbook.term_tree.get_selected().get_metadata(0) == &"bit", "A Mission link clears stale search filters and opens the requested entry.")
	root.get_node("GameMode").set_mode(&"game")
	save.game_player_content.completed_levels.clear()
	system.prologue_ready = false
	system.game_completed.clear()
	locality.game_completed.clear()
	handbook.open_handbook(&"cpu")
	check(not handbook.is_term_unlocked(&"cpu"), "Handbook does not retain stale completion after progress changes.")
	print("Handbook checks: %d; failures: %d" % [checks, failures.size()])
	print("PASS: progressive learning handbook" if failures.is_empty() else "FAIL: progressive learning handbook")
	quit(0 if failures.is_empty() else 1)


func _check_required_links(handbook: Variant, text: String, level: String) -> void:
	for term: StringName in LinkedTextType.linked_term_ids(text):
		check(handbook.is_term_unlocked(term), "Required specification is readable before solving %s: %s" % [level, term])


func _check_recommendations(handbook: Variant, chapter: String, level: String) -> void:
	var context := StringName(chapter + ":" + level)
	check(handbook_type.RECOMMENDED.has(context), "Every playable lesson has focused guidance: " + String(context))
	for term: StringName in handbook_type.RECOMMENDED.get(context, []):
		check(handbook.is_term_unlocked(term), "Recommended knowledge is available before solving %s: %s" % [context, term])


func _check_diagram_models(diagram: Control) -> void:
	var view: Variant = diagram
	view.set_diagram(&"widths")
	check(view.example_count() == 3 and view.WIDTH_EXAMPLES == [1, 2, 4], "Width diagrams introduce the 2-bit selector/address width as well as scalar and 4-bit data.")
	for term: StringName in [&"layout_data_layout", &"layout_field_group"]:
		view.set_diagram(term)
		var first_addresses: Dictionary = view.layout_example_mapping().addresses.duplicate()
		for step: int in range(view.example_count()):
			var map: Dictionary = view.layout_example_mapping()
			var identities: Array[int] = []
			for cell: Dictionary in map.cells:
				identities.append(int(cell.record) * 4 + int(cell.field))
				check(int(cell.address) % 4 == 0 and int(cell.address) >= 0 and int(cell.address) < 32,
					"Every illustrated cell occupies a real aligned word inside the two-record mapping.")
				if term == &"layout_field_group":
					check((int(cell.address) < 16) == (int(cell.field) < 2), "The two example groups occupy separate actual memory lines.")
			identities.sort()
			check(identities == [0, 1, 2, 3, 4, 5, 6, 7] and int(map.bytes) == 32,
				"Rearranging the illustration preserves all fields and both record identities.")
			if step == 1:
				check(map.addresses != first_addresses, "Changing order visibly changes actual addresses, not just the caption.")
			view.advance_example(1)
	view.set_diagram(&"layout_bounded_batch")
	var covered_records: Array[int] = []
	var sizes: Array[int] = []
	var storage: Array[int] = []
	var fill_widths: Array[float] = []
	view.size.x = 420
	for step: int in range(view.example_count()):
		var batch: Dictionary = view.batch_example()
		sizes.append(int(batch.count))
		storage.append(int(batch.bytes))
		fill_widths.append(view.batch_storage_fill().size.x)
		for record: int in range(int(batch.first), int(batch.first) + int(batch.count)):
			covered_records.append(record)
		view.advance_example(1)
	check(covered_records == [0, 1, 2, 3, 4, 5, 6, 7, 8], "Batch illustration covers each example record once without inventing tail records.")
	check(sizes == [4, 4, 1] and storage == [64, 64, 16], "The tail uses its actual all-field mapping, rather than a full-batch space estimate.")
	check(is_equal_approx(fill_widths[0], fill_widths[1]) and is_equal_approx(fill_widths[2] * 4.0, fill_widths[0]), "The last batch visibly occupies one quarter of the full-batch storage outline.")
	view.set_diagram(&"layout_copy_cost")
	check(view.example_count() == 3, "Copy-cost steps are separate from the batching example.")


func _check_diagram_captions(diagram: Control, localization: Node, locale: String) -> void:
	var view: Variant = diagram
	var captions: Dictionary = {
		&"terminology.diagram.layout.legend": Vector2(14, 57),
		&"terminology.diagram.copy.step.0": Vector2(15, 73),
		&"terminology.diagram.copy.step.1": Vector2(15, 73),
		&"terminology.diagram.copy.step.2": Vector2(15, 73),
		&"terminology.diagram.batch.sequence": Vector2(14, 48),
	}
	for key: StringName in captions:
		var spec: Vector2 = captions[key]
		var text: String = localization.text(key)
		check(text != String(key), "Diagram caption is translated: %s %s" % [locale, key])
		var layout: Dictionary = view.wrapped_text_layout(Rect2(0, 0, 336, spec.y), text, int(spec.x))
		check(layout.measured.y <= spec.y and int(layout.font_size) >= 12,
			"Diagram caption fits its 248px illustration at narrow width without clipping: %s %s" % [locale, key])


func _check_signal_diagram_models(diagram: Control) -> void:
	var view: Variant = diagram
	var simulator: Variant = load("res://src/circuit/prologue_simulator.gd").new()
	view.set_diagram(&"multiplexer")
	for step: int in range(view.example_count()):
		var example: Dictionary = view.multiplexer_example()
		var inputs: Array[DigitalValue] = [DigitalValue.known(1, int(example.a)),
			DigitalValue.known(1, int(example.b)), DigitalValue.known(1, int(example.select))]
		var result: DigitalValue = simulator._mux2(inputs)
		check(result.width == 1 and result.value == int(example.output), "Both handbook MUX selections match the actual one-bit model.")
		view.advance_example(1)
	view.set_diagram(&"alu")
	var example: Dictionary = view.alu_example()
	var inputs: Array[DigitalValue] = []
	for port: String in ["a", "b", "cin", "op0", "op1"]:
		inputs.append(DigitalValue.known(1, int(example[port])))
	var outputs: Array[DigitalValue] = simulator._alu(inputs, 1)
	check(outputs[0].value == int(example.result) and outputs[1].value == int(example.carry),
		"The introductory ALU illustration separates the model's one-bit result and carry.")
	view.set_diagram(&"cache")
	for width: float in [336.0, 500.0, 720.0]:
		view.size.x = width
		var boxes: Dictionary = view.cache_example_boxes()
		var arrow: PackedVector2Array = view.cache_hit_arrow()
		check(arrow[0].x == boxes.cache.position.x and arrow[1].x == boxes.cpu.end.x and arrow[0].x > arrow[1].x,
			"A hit returns data from Cache to CPU, with no overlapping boxes at width %d." % int(width))
