class_name SavedContentPreview
extends Control
## Read-only previews from supplied saved data. No restore, reward, simulation or write API.
const COLORS := [Color("7fcbd6"),Color("f0c674"),Color("aab6e6"),Color("b6d6c5")]
var content_kind: StringName = &""
var content_name: String = ""
var source_id: String = ""
var symbols: Array[int] = []
var positions: Dictionary = {}
var wires: Array[Dictionary] = []
var english: bool = false
var confirmed_source: bool = false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(160,70)

func clear_content() -> void:
	content_kind=&"";content_name="";source_id=""
	symbols.clear();positions.clear();wires.clear();confirmed_source=false
	queue_redraw()

func configure_work(work: Dictionary, confirmed: bool) -> bool:
	clear_content()
	var identifier: Variant=work.get("id","")
	if not (identifier is String or identifier is StringName): return false
	var output: Variant=work.get("output")
	if not output is Array or output.is_empty() or output.size()>65536 or String(work.get("id","")).is_empty(): return false
	for value: Variant in output:
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0.0 or float(value)>3.0 or float(value)!=float(int(value)):
			clear_content();return false
		symbols.append(int(value))
	content_kind=&"work";source_id=String(work.id);content_name=String(work.get("name",""))
	confirmed_source=confirmed
	queue_redraw();return true

func configure_plan(snapshot: Dictionary, plan_name: String) -> bool:
	clear_content()
	var layout: Variant=snapshot.get("layout")
	var components: Variant=snapshot.get("components")
	if not layout is Dictionary or not components is Array or components.is_empty() or components.size()>512: return false
	for component: Variant in components:
		if not component is Dictionary: clear_content();return false
		var id: String=String(component.get("id",""))
		var point: Variant=layout.get(id)
		if id.is_empty() or positions.has(id) or not point is Dictionary: clear_content();return false
		var x: Variant=point.get("x");var y: Variant=point.get("y")
		if not (x is int or x is float) or not (y is int or y is float): clear_content();return false
		if not is_finite(float(x)) or not is_finite(float(y)) or absf(float(x))>1000000 or absf(float(y))>1000000: clear_content();return false
		positions[id]=Vector2(float(x),float(y))
	var wire_list: Variant = snapshot.get("wires",[])
	if not wire_list is Array or wire_list.size()>4096: clear_content();return false
	for wire: Variant in wire_list:
		if not wire is Dictionary: clear_content();return false
		var from: String=String(wire.get("from_node",wire.get("from","")))
		var to: String=String(wire.get("to_node",wire.get("to","")))
		if not positions.has(from) or not positions.has(to): clear_content();return false
		wires.append({"from":from,"to":to})
	content_kind=&"plan";content_name=plan_name;confirmed_source=true
	queue_redraw();return true

func preview_symbols() -> Array[int]:
	return symbols.slice(0,32)

func _draw() -> void:
	if content_kind.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),Color("14232e"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("41576b"),false,1.0)
	var area:=Rect2(8,22,maxf(1,size.x-16),maxf(1,size.y-30))
	var label: String=("作品" if not english else "Work") if content_kind==&"work" else ("方案" if not english else "Plan")
	if not confirmed_source: label += " · " + ("只读恢复" if not english else "Recovery")
	if content_kind==&"work":
		label += " · %d/%d" % [mini(32,symbols.size()),symbols.size()]
		draw_string(get_theme_default_font(),Vector2(8,15),label,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,11,Color("a8bdcc"))
		var preview: Array[int]=preview_symbols()
		for lane: int in 4:
			var y: float=area.position.y+(float(lane)+0.5)*area.size.y/4.0
			draw_line(Vector2(area.position.x,y),Vector2(area.end.x,y),Color(COLORS[lane],0.13),1.0)
		for index: int in preview.size():
			var at:=Vector2(area.position.x+(float(index)+0.5)*area.size.x/float(preview.size()),area.position.y+(float(preview[index])+0.5)*area.size.y/4.0)
			draw_circle(at,2.0,COLORS[preview[index]])
	else:
		draw_string(get_theme_default_font(),Vector2(8,15),label,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,11,Color("a8bdcc"))
		var bounds:=Rect2();var first: bool=true
		for point: Vector2 in positions.values():
			bounds=Rect2(point,Vector2.ONE) if first else bounds.expand(point)
			first=false
		var scale_factor: float=minf(area.size.x/maxf(1,bounds.size.x+10),area.size.y/maxf(1,bounds.size.y+10))
		var centered: Vector2=area.get_center()-bounds.get_center()*scale_factor
		for wire: Dictionary in wires:
			draw_line(centered+positions[wire.from]*scale_factor,centered+positions[wire.to]*scale_factor,Color("567e92"),1.0,true)
		for point: Vector2 in positions.values():
			var at: Vector2=centered+point*scale_factor
			draw_rect(Rect2(at-Vector2(3,2),Vector2(6,4)),Color("b8cbd8"))
