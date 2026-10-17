extends SceneTree
## QA-only palette comparison on the real tutorial, never a global theme setting.
const HARDWARE := "res://src/hardware_foundations/hardware_foundations.tscn"
const OUTPUT := "res://.godot/workbench-palette-captures"
const DARK_ISLANDS := ["res://src/hardware_foundations/component_palette_item.gd", "res://src/ui/signal_level_button.gd"]
var palette: Script
var failures: Array[String] = []
var checks: int = 0
var captures: Array[Dictionary] = []
var pairs: Array[Dictionary] = []
var rendered: bool = false

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 8: await process_frame

func run() -> void:
	palette = load("res://src/ui/instrument_theme.gd")
	rendered = "--workbench-theme-capture" in OS.get_cmdline_user_args()
	check(not rendered or DisplayServer.get_name() != "headless", "Requested comparison requires a real renderer")
	if DisplayServer.get_name() == "headless":
		rendered = false
		print("NOT_RUN: full-workbench rendered dark/light comparison (headless)")
	root.mode = Window.MODE_WINDOWED
	var previous_motion: Variant = ProjectSettings.get_setting("game/reduced_motion", false)
	ProjectSettings.set_setting("game/reduced_motion", true)
	root.get_node("GameMode").set_mode(&"game")
	for locale: String in ["zh_CN", "en"]:
		await compare_locale(locale)
	ProjectSettings.set_setting("game/reduced_motion", previous_motion)
	if rendered:
		check(captures.size() == 12, "Two real palettes × two languages × three sizes produce twelve frames")
		var file := FileAccess.open(OUTPUT.path_join("receipt.json"), FileAccess.WRITE)
		check(file != null, "Comparison receipt opens")
		if file != null:
			file.store_string(JSON.stringify({"checks": checks, "failures": failures, "sources": source_hashes(),
				"engine": Engine.get_version_info().string, "captures": captures, "pairs": pairs,
				"grade": "Real tutorial controller actions; QA-local candidate colors; not OS input, newcomer testing or a production light theme",
				"protected_scope": "Existing save/session/transaction files; this tutorial fixture creates no CPG work payload",
				"retained_dark_instruments": "Signal input and component thumbnails stay dark; original circuit symbols and ports appear over the candidate gray canvas"}, "\t"))
			file.close()
	print(("PASS" if failures.is_empty() else "FAIL") + ": real frozen-workbench palette comparison (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)

func compare_locale(locale: String) -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await settle()
	var save: Node = root.get_node("GlobalSave")
	var navigation: Node = root.get_node("TaskNavigation")
	root.get_node("Localization").set_locale(locale)
	save.configure_for_test("user://palette-%s-save.json" % locale, "user://palette-%s-workbench.json" % locale)
	check(navigation.enter("hardware_foundations/tutorial"), "Original task navigation opens tutorial: " + locale)
	await settle()
	var host: Variant = current_scene
	if host == null or host.scene_file_path != HARDWARE or host.current_level_id != &"tutorial":
		check(false, "Actual tutorial host is ready: " + locale); return
	check(not host.completed_levels.get(&"tutorial", false), "Fresh comparison earns its own tutorial through original operations")
	if host.mission_briefing_active: host._start_building_from_briefing()
	await settle()
	host._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	host._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	host.input_a_button.button_pressed = true
	host._run_debug()
	check(host.current_trace != null and host.current_trace.is_valid() and host.current_trace.outputs.get(&"LAMP", true) == false,
		"Original model confirms A=1 gives NOT output0")
	host._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
	check(not host.completed_levels.get(&"tutorial", false), "Four tutorial actions do not grant completion")
	host._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await settle()
	check(host.completed_levels.get(&"tutorial", false), "Real reconnect earns the original tutorial")
	host._dismiss_level_completion()
	host._stop_playback()
	host._show_desktop_window(&"task")
	host._save_active_workbench()
	check(save.save_game(true), "Actual earned work saves before read-only palette changes")
	print("SETUP: original tutorial controller actions earned completion; subsequent colors are QA presentation only: " + locale)
	var original_theme: Theme = host.theme
	var original_graph_theme: Theme = host.graph.theme
	var original_handbook_theme: Theme = host.terminology_handbook.theme
	var backdrops: Array[Node] = []
	for node: Node in host.find_children("*", "Control", true, false):
		var script: Script = node.get_script()
		if script != null and script.resource_path == "res://src/ui/technical_backdrop.gd": backdrops.append(node)
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1440,900)]:
		root.size = dimensions; root.content_scale_size = dimensions
		await settle()
		# The outer margin is empty; settle hover removal before capturing live controls.
		root.warp_mouse(Vector2(2, 2))
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(2, 2); motion.global_position = motion.position
		root.push_input(motion, true)
		await settle()
		(host.side_box.get_parent() as ScrollContainer).ensure_control_visible(host.input_a_button)
		host.pause_button.grab_focus()
		await settle()
		var originals: Array[Dictionary] = []
		collect_overrides(host, host.graph, originals)
		check(within_clip(host.input_a_button) and within_clip(host.pause_button), "Signal input and playback controls stay accessible at " + str(dimensions))
		for window: Control in host.desktop_windows.values():
			if window.visible: check(root.get_visible_rect().encloses(window.get_global_rect()), "Visible instrument stays inside actual comparison viewport")
		var before: Dictionary = authority(host)
		var layout: Dictionary = controls(host)
		var dark_hash: String = await capture_frame(host, locale, dimensions, "dark", before)
		var candidate: Theme = original_theme.duplicate(true)
		palette.apply_to(candidate, true)
		host.theme = candidate
		var handbook_candidate: Theme = original_handbook_theme.duplicate()
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
			handbook_candidate.set_color(state, "Button", candidate.get_color(state, "Button"))
		host.terminology_handbook.theme = handbook_candidate
		# Preserve custom signal drawing and native port geometry.
		host.graph.theme = original_theme
		for backdrop: Node in backdrops: backdrop.set("light", true)
		for record: Dictionary in originals:
			var control: Control = record.node
			for property: String in record.colors: control.set(property, light_ink(record.colors[property]))
			for property: String in record.styles:
				var box: StyleBoxFlat = record.styles[property].duplicate(true)
				if box.bg_color.a > 0.0: box.bg_color = Color("d2e6e8") if box.bg_color.get_luminance() > 0.2 else Color("f6f8f7")
				if box.border_color.a > 0.0: box.border_color = Color("6c858d")
				box.shadow_color = Color(0.1, 0.2, 0.2, 0.15)
				control.set(property, box)
		await settle()
		check(authority(host) == before, "QA colors preserve complete model/save/navigation authority: " + locale + str(dimensions))
		check(controls(host) == layout, "QA colors preserve all visible control text, states, focus and exact rectangles: " + locale + str(dimensions))
		check(within_clip(host.input_a_button) and within_clip(host.pause_button), "Candidate palette retains the original accessible controls")
		var entry: Button = host.terminology_handbook.entry_button
		var ink: float = entry.get_theme_color("font_color").srgb_to_linear().get_luminance()
		var fill: float = (entry.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.srgb_to_linear().get_luminance()
		check((maxf(ink, fill) + 0.05) / (minf(ink, fill) + 0.05) >= 4.5, "Candidate Handbook entry text remains readable on its actual normal fill")
		var light_hash: String = await capture_frame(host, locale, dimensions, "light-candidate", before)
		if rendered: check(dark_hash != light_hash, "Candidate palette produces a visibly different real full-workbench frame")
		pairs.append({"locale": locale, "size": str(dimensions), "state_sha256": JSON.stringify(before).sha256_text(),
			"layout_sha256": JSON.stringify(layout).sha256_text(), "same_authority": authority(host) == before,
			"same_text_states_rectangles": controls(host) == layout, "dark_sha256": dark_hash, "light_sha256": light_hash})
		host.theme = original_theme; host.graph.theme = original_graph_theme
		host.terminology_handbook.theme = original_handbook_theme
		for backdrop: Node in backdrops: backdrop.set("light", false)
		for record: Dictionary in originals:
			for property: String in record.colors: record.node.set(property, record.colors[property])
			for property: String in record.styles: record.node.set(property, record.styles[property])
		await settle()
		check(authority(host) == before, "Restoring dark presentation preserves the frozen tutorial")
	current_scene = null; host.queue_free(); await settle()

func collect_overrides(node: Node, graph: Node, result: Array[Dictionary]) -> void:
	if node == graph: return
	var script: Script = node.get_script()
	if script != null and script.resource_path in DARK_ISLANDS: return
	if node is Control:
		var colors: Dictionary = {}; var styles: Dictionary = {}
		for property: Dictionary in node.get_property_list():
			var name: String = str(property.name)
			if name.begins_with("theme_override_colors/") and node.get(name) is Color: colors[name] = node.get(name)
			if name.begins_with("theme_override_styles/") and node.get(name) is StyleBoxFlat: styles[name] = node.get(name)
		result.append({"node": node, "colors": colors, "styles": styles})
	for child: Node in node.get_children(): collect_overrides(child, graph, result)

func light_ink(original: Color) -> Color:
	if original.a < 0.1: return original
	var hue: float = original.h
	if original.s < 0.16: return Color("223840")
	if hue < 0.06 or hue > 0.92: return Color("96314c")
	if hue < 0.18: return Color("795014")
	if hue < 0.48: return Color("205e49")
	if hue < 0.67: return Color("245e6d")
	return Color("654684")

func authority(host: Variant) -> Dictionary:
	var save: Node = root.get_node("GlobalSave")
	var navigation: Node = root.get_node("TaskNavigation")
	var state: Dictionary = save._save_snapshot(); state.erase("saved_at_utc")
	var disk: Dictionary = {}
	var paths: Array[String] = [save.storage_path, save.workbench_storage_path]
	var second: Script = load("res://src/campaign/second_act_tasks.gd")
	var creation: Script = load("res://experiments/creation/session.gd")
	var files: Script = load("res://experiments/candidate_session/files.gd")
	for path: Variant in second.paths().values(): paths.append(str(path))
	paths.append(creation.launch_path())
	for path: String in paths:
		disk[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
		for transaction: String in files.transaction_paths(path): disk[transaction] = FileAccess.get_sha256(transaction)
	return {"game": state, "disk": disk, "personal_records": root.get_node("PersonalRecords").best.duplicate(true),
		"pending": navigation.pending, "selected": navigation.selected, "from_tree": navigation.from_tree,
		"circuit": host._circuit_from_graph().canonical_signature(), "workbench": host._capture_workbench_snapshot(),
		"graph_view": [host.graph.zoom, host.graph.scroll_offset],
		"input_a": host.input_a_button.button_pressed, "result": host.debug_result_label.text,
		"completed": host.completed_levels.duplicate(true), "playback_running": host.playback_running,
		"playback_index": host.playback_index, "trace_caption": host.trace_caption_label.text}

func controls(host: Node) -> Dictionary:
	var result: Dictionary = {}
	for node: Node in host.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree(): continue
		var data: Dictionary = {"rect": control.get_global_rect(), "focus": control.has_focus()}
		if control is Label or control is RichTextLabel or control is Button or control is LineEdit: data.text = control.get("text")
		if control is BaseButton: data.merge({"disabled": control.disabled, "pressed": control.button_pressed})
		if control is OptionButton: data.selected = control.selected
		if control is Range: data.value = control.value
		if control is GraphNode: data.title = control.title
		result[str(host.get_path_to(control))] = data
	return result

func within_clip(control: Control) -> bool:
	if not control.is_visible_in_tree(): return false
	var clip: Rect2 = root.get_visible_rect()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents: clip = clip.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return clip.grow(1).encloses(control.get_global_rect())

func source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in ["res://project.godot", "res://tests/test_workbench_palette_comparison.gd", HARDWARE,
		"res://src/hardware_foundations/hardware_foundations.gd", "res://src/ui/instrument_theme.gd", "res://src/ui/technical_backdrop.gd"]:
		result[path] = FileAccess.get_sha256(path)
	return result

func capture_frame(host: Control, locale: String, dimensions: Vector2i, treatment: String, frozen: Dictionary) -> String:
	if not rendered: return ""
	await settle(); RenderingServer.force_draw(false); await process_frame
	var image: Image = root.get_texture().get_image()
	check(image != null and image.get_size() == dimensions, "Actual full-workbench capture dimensions")
	if image == null: return ""
	check(DirAccess.make_dir_recursive_absolute(OUTPUT) == OK, "Capture folder exists")
	var path: String = OUTPUT.path_join("hardware-tutorial-%s-%dx%d-%s.png" % [locale, dimensions.x, dimensions.y, treatment])
	check(not FileAccess.file_exists(path), "New comparison never overwrites earlier evidence")
	if FileAccess.file_exists(path): return ""
	check(image.save_png(path) == OK, "Actual native-control workbench frame saved")
	check(authority(host) == frozen, "Rendering does not change the frozen tutorial authority")
	var digest: String = FileAccess.get_sha256(path)
	captures.append({"path": path, "sha256": digest, "locale": locale, "size": str(image.get_size()),
		"treatment": treatment, "state_sha256": JSON.stringify(frozen).sha256_text()})
	return digest
