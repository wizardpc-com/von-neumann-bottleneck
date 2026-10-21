extends SceneTree
## Export data/geometry from production types. Review SVGs are not game screenshots.
const Component = preload("res://src/circuit/logic_component.gd")
const Style = preload("res://src/hardware_foundations/component_visual_style.gd")
const Layout = preload("res://src/hardware_foundations/component_visual_layout.gd")
const KINDS: Array[StringName] = [&"input",&"output",&"lamp",&"and",&"or",&"xor",&"not",&"nor",&"junction",&"half_adder",&"full_adder",&"mux4",&"alu1",&"sr_latch",&"register1",&"register4",&"decoder1_to_2",&"mux2_word",&"alu4",&"ram2x4",&"control",&"constant",&"tiny_computer"]
func _init() -> void: call_deferred("run")
func points_json(points: PackedVector2Array) -> Array:
	var result: Array = []
	for point: Vector2 in points: result.append([point.x,point.y])
	return result
func run() -> void:
	var directory: String = "res://.godot/component-visual-review"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): directory=argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var entries: Array = []
	for kind: StringName in KINDS:
		var part := Component.new(&"REFERENCE",kind,String(kind))
		entries.append({"kind":String(kind),"source":"src/circuit/logic_component.gd","family":String(Style.family(kind)),
			"accent":"#"+Style.accent(kind).to_html(false),"inputs":part.input_port_names,"outputs":part.output_port_names,
			"input_widths":part.input_port_widths,"output_widths":part.output_port_widths,
			"shell":points_json(Style.shell(kind,Rect2(0,0,240,160))),"system_device":false})
	for kind: StringName in [&"cpu",&"ram",&"bus"]:
		entries.append({"kind":String(kind),"source":"src/system_lab/system_device_surface.gd","family":String(Style.family(kind)),
			"accent":"#"+Style.accent(kind).to_html(false),"inputs":[],"outputs":[],"input_widths":[],"output_widths":[],
			"shell":points_json(Style.shell(kind,Rect2(0,0,240,160))),"system_device":true})
	var layouts := {"compact":{"A":{"x":0,"y":0},"B":{"x":120,"y":0}},
		"lower_branch":{"A":{"x":0,"y":0},"B":{"x":120,"y":160}}}
	var examples: Array = []
	for name: String in layouts:
		var snapshot: Dictionary = Layout.freeze("geometric-fixture-not-earned",layouts[name])
		examples.append({"name":name,"fixture":true,"snapshot":snapshot,"outline":points_json(Layout.outline(snapshot,"geometric-fixture-not-earned",Rect2(0,0,240,160)))})
	var file := FileAccess.open(directory.path_join("manifest.json"),FileAccess.WRITE)
	if file == null: push_error("Cannot write review manifest");quit(1);return
	file.store_string(JSON.stringify({"schema":1,"status":"review candidate, not graphical acceptance","entries":entries,"layout_fixtures":examples},"\t"))
	file.close()
	print("PASS: exported ",entries.size()," contract-derived visual entries and ",examples.size()," explicitly labelled geometric fixtures")
	quit(0)
