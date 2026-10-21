extends SceneTree
const Demo = preload("res://src/hardware_foundations/operation_demonstration.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var demo: Control = Demo.new()
	root.add_child(demo)
	demo.size = Vector2(1280,720)
	check(demo.mouse_filter == Control.MOUSE_FILTER_IGNORE and demo.focus_mode == Control.FOCUS_NONE,"Illustration never steals mouse or keyboard")
	demo.demonstrate(PackedVector2Array([Vector2(100,100),Vector2(300,200)]),"Drag",false)
	check(demo.running and demo.visible,"Explicit replay starts demo")
	demo.elapsed = 0.0
	check(demo.pointer_position().is_equal_approx(Vector2(100,100)),"Pointer starts at actual supplied anchor")
	demo.elapsed = demo.duration
	check(demo.pointer_position().is_equal_approx(Vector2(300,200)),"Pointer ends at supplied destination")
	demo._process(2.0)
	check(not demo.running and not demo.visible,"One demonstration stops, never loops forever")
	demo.demonstrate(PackedVector2Array([Vector2(10,10),Vector2(40,40)]),"Static",true)
	var first: Vector2 = demo.pointer_position()
	demo.elapsed = 2
	check(demo.pointer_position()==first,"Reduced motion keeps pointer static")
	demo.stop()
	check(demo.path.is_empty() and not demo.running,"Skip removes the illustration")
	demo.demonstrate(PackedVector2Array([Vector2(NAN,10)]),"Bad")
	check(not demo.running,"Invalid geometry fails closed")
	for curve: PackedVector2Array in [PackedVector2Array([Vector2(0,0),Vector2(100,0)]),PackedVector2Array([Vector2(20,0),Vector2(20,100)]),PackedVector2Array([Vector2(0,0),Vector2(100,100)])]:
		var cut: PackedVector2Array=Demo.wire_cut_path(curve)
		check(cut.size()==2,"Every nonzero wire has a cut demonstration")
		check(Geometry2D.segment_intersects_segment(cut[0],cut[1],curve[0],curve[1])!=null,"Cut gesture crosses horizontal, vertical and diagonal wires")
		check(absf((cut[1]-cut[0]).normalized().dot((curve[1]-curve[0]).normalized()))<0.001,"Cut gesture is perpendicular, not parallel to the wire")
	check(Demo.wire_cut_path(PackedVector2Array([Vector2.ZERO,Vector2.ZERO])).is_empty(),"Zero-length wire does not invent a direction")
	check(Demo.wire_cut_path(PackedVector2Array([Vector2.ZERO,Vector2(NAN,0)])).is_empty(),"Invalid wire geometry fails closed")
	demo.queue_free(); await process_frame
	print("PASS: test_operation_demonstration " if failures==0 else "FAIL: test_operation_demonstration ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
