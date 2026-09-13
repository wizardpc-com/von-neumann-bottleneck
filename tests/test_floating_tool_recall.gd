extends SceneTree
var failures: Array[String]=[]
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	var panel_type: Script=load("res://src/ui/floating_instrument_panel.gd")
	var workspace:=Control.new();root.add_child(workspace);workspace.size=Vector2(1200,800)
	var first: Control=panel_type.new();workspace.add_child(first);first.setup(&"first","First")
	var second: Control=panel_type.new();workspace.add_child(second);second.setup(&"second","Second")
	await process_frame
	first.position=Vector2(20,20);first.size=Vector2(350,250)
	second.position=Vector2(100,40);second.size=Vector2(350,250)
	check(not first.should_hide_on_toggle(),"Covered tool is recalled, not hidden")
	check(second.should_hide_on_toggle(),"Visible front tool retains toggle-to-close")
	second.hide();check(first.should_hide_on_toggle(),"Hidden tools cannot block closing")
	second.show();second.position=Vector2(700,20)
	check(first.should_hide_on_toggle(),"An unrelated non-overlapping tool does not block toggle")
	first.set_minimized(true)
	check(not first.should_hide_on_toggle(),"Minimized tool must be recalled")
	first.show_instrument();check(not first.minimized and first.visible,"Recall restores tool content")
	first.hide();check(not first.should_hide_on_toggle(),"Hidden tool must open")
	workspace.queue_free();await process_frame
	for message: String in failures:push_error(message)
	print("PASS: covered, minimized, visible and separate tool recall" if failures.is_empty() else "FAIL: floating tool recall")
	quit(0 if failures.is_empty() else 1)
