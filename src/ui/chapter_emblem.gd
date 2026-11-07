class_name ChapterEmblem
extends Control

# Journey accents share the palette's pastel range; identity never encodes status.
const REGION_SYMBOLS := [&"hardware", &"system", &"locality", &"overlap", &"layout", &"representation", &"service", &"address", &"compression", &"content", &"creation"]
const REGION_COLORS := [Color("91d5ad"), Color("e4c57e"), Color("86d2dd"), Color("b9c1ed"), Color("e6b5ce"), Color("adc5ed"), Color("87d6c2"), Color("d0cc8e"), Color("d8bde4"), Color("a4d0de"), Color("dac294")]
var map_icon: bool = false
var chapter: StringName = &"hardware"
var accent := Color("7fcbd6")


func _ready() -> void:
	custom_minimum_size.y = 24.0 if map_icon else 108.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


static func region_accent(region: int) -> Color:
	return REGION_COLORS[posmod(region, REGION_COLORS.size())]

static func draw_region(host: CanvasItem, region: int, at: Vector2, extent: float, ink: Color) -> void:
	host.draw_set_transform(at, 0, Vector2.ONE * extent / 32.0)
	var stroke: float = 2.0
	match posmod(region, 11):
		0:
			host.draw_polyline(PackedVector2Array([Vector2(-11,-10),Vector2(-11,10),Vector2(6,0),Vector2(-11,-10)]),ink,stroke,true)
			host.draw_circle(Vector2(10,0),3,ink,false,stroke,true)
		1:
			for x: int in [-11,0,11]: host.draw_rect(Rect2(x-4,-8,8,16),ink,false,stroke)
			host.draw_line(Vector2(-7,0),Vector2(7,0),ink,stroke,true)
		2:
			host.draw_rect(Rect2(-12,-10,24,20),ink,false,stroke)
			for x: int in [-7,0,7]: host.draw_line(Vector2(x,-6),Vector2(x,6),ink,stroke,true)
		3:
			for lane: int in 2:
				for col: int in 3: host.draw_rect(Rect2(-13+col*9+lane*3,-9+lane*11,7,6),ink)
		4:
			for row: int in 2:
				for col: int in 3: host.draw_rect(Rect2(-12+col*9,-9+row*11,6,7),ink,false,stroke)
		5:
			host.draw_rect(Rect2(-12,-10,9,20),ink,false,stroke)
			for y: int in [-7,0,7]: host.draw_line(Vector2(2,y),Vector2(12,y),ink,stroke,true)
		6:
			host.draw_polyline(PackedVector2Array([Vector2(-13,-6),Vector2(11,-6),Vector2(5,-12)]),ink,stroke,true)
			host.draw_polyline(PackedVector2Array([Vector2(13,6),Vector2(-11,6),Vector2(-5,12)]),ink,stroke,true)
		7:
			host.draw_polyline(PackedVector2Array([Vector2(-12,9),Vector2(-4,9),Vector2(-4,1),Vector2(4,1),Vector2(4,-7),Vector2(12,-7)]),ink,stroke,true)
			host.draw_circle(Vector2(12,-7),3,ink)
		8:
			for side: int in [-1,1]:
				host.draw_polyline(PackedVector2Array([Vector2(side*12,-10),Vector2(side*4,0),Vector2(side*12,10)]),ink,stroke,true)
			host.draw_line(Vector2(-1,-10),Vector2(-1,10),ink,stroke,true)
		9:
			for x: int in [-11,-3,5]: host.draw_rect(Rect2(x,-8,5,16),ink,false,stroke)
			host.draw_line(Vector2(13,-8),Vector2(13,8),Color(ink,0.4),stroke,true)
		10:
			host.draw_arc(Vector2.ZERO,11,-PI*0.8,PI*0.8,24,ink,stroke,true)
			host.draw_polyline(PackedVector2Array([Vector2(-12,1),Vector2(-9,8),Vector2(-3,4)]),ink,stroke,true)
			host.draw_circle(Vector2.ZERO,3,ink)
	host.draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if map_icon:
		draw_region(self, REGION_SYMBOLS.find(chapter), size/2, minf(size.x,size.y)-4, accent)
		return
	# Keep the complete artwork inside narrow cards rather than joining a neighbor's
	# leads. Only this decorative illustration scales; its text remains screen sized.
	var artwork_scale: float = minf(1.0,size.x/260.0)
	draw_set_transform(Vector2(size.x*0.5,(108.0-108.0*artwork_scale)*0.5),0,Vector2.ONE*artwork_scale)
	var center := Vector2(0.0, 52.0)
	var outline := Color(accent, 0.55)
	for index: int in range(5):
		var x: float = center.x - 44.0 + index * 22.0
		draw_line(Vector2(x, 5.0), Vector2(x, 23.0), outline, 2.0, true)
		draw_line(Vector2(x, 81.0), Vector2(x, 99.0), outline, 2.0, true)
	var chip := Rect2(center - Vector2(66.0, 29.0), Vector2(132.0, 58.0))
	# Small stacked plates give every chapter's existing symbol the same depth.
	var base: StyleBoxFlat = InstrumentTheme.panel(Color("08131e"),Color(accent,0.13),5)
	draw_style_box(base,Rect2(chip.position+Vector2(0,9),chip.size))
	draw_style_box(InstrumentTheme.surface(Color("132a36"), outline,5), chip)
	draw_line(chip.position+Vector2(10,2),chip.position+Vector2(chip.size.x-10,2),Color(accent,0.55),1,true)
	for side: float in [-1.0,1.0]:
		var at := center+Vector2(side*57,-21)
		draw_circle(at,1.6,Color(accent,0.45),true)
	for side: int in [-1, 1]:
		for index: int in range(3):
			var start := Vector2(center.x + side * 67.0, 34.0 + index * 18.0)
			var corner := start + Vector2(side * (22.0 + index * 12.0), 0.0)
			var end := corner + Vector2(side * 10.0, (index - 1) * 12.0)
			draw_polyline(PackedVector2Array([start, corner, end]), Color(accent, 0.35), 1.5, true)
			draw_circle(end, 3.0, accent if index == 1 else outline, false, 1.5, true)
	match chapter:
		&"layout":
			var colors: Array[Color] = [Color("7fd8a4"),Color("7fcbd6"),Color("f0c674"),Color("aab6e6")]
			for row: int in range(2):
				for col: int in range(4):
					var at := center+Vector2(-50+col*26,-19+row*22)
					draw_rect(Rect2(at,Vector2(20,15)),Color(colors[col] if row==0 else colors[0],0.7))
		&"hardware":
			var triangle := PackedVector2Array([center + Vector2(-22, -16), center + Vector2(-22, 16), center + Vector2(8, 0), center + Vector2(-22, -16)])
			draw_polyline(triangle, accent, 2.5, true)
			draw_circle(center + Vector2(14, 0), 5.0, accent, false, 2.0, true)
			draw_line(center + Vector2(20, 0), center + Vector2(40, 0), accent, 2.0, true)
		&"system":
			for index: int in range(3):
				var origin := center + Vector2(-47.0 + index * 35.0, -14.0)
				draw_rect(Rect2(origin, Vector2(25.0, 28.0)), accent, false, 2.0)
				if index < 2:
					draw_line(origin + Vector2(26.0, 14.0), origin + Vector2(35.0, 14.0), accent, 2.0)
		&"overlap":
			for lane: int in range(2):
				var lane_color := Color("7fcbd6") if lane == 0 else accent
				for batch: int in range(3):
					var cell := Rect2(center + Vector2(-50+batch*29+lane*13,-19+lane*23),Vector2(24,15))
					draw_rect(cell,Color(lane_color,0.6),true)
					draw_rect(cell,lane_color,false,1)
		_:
			for row: int in range(2):
				for column: int in range(5):
					var cell := Rect2(center + Vector2(-45.0 + column * 19.0, -17.0 + row * 19.0), Vector2(14.0, 14.0))
					draw_rect(cell, Color(accent, 0.75 if row == 0 else 0.15), true)
					draw_rect(cell, outline, false, 1.0)
