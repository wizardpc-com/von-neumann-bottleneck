extends Control
var cache: bool = false
func _ready() -> void:
	custom_minimum_size = Vector2(94,54)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var color := Color("50d5ff") if cache else Color("ba92ff")
	var middle: float = size.y * 0.5
	var body := Rect2(22,5,maxf(25,size.x-44),maxf(24,size.y-10))
	draw_rect(body,Color(color,0.14))
	draw_rect(body,color,false,2)
	for offset: int in [-2,2]:
		draw_line(Vector2(1,middle+offset),Vector2(22,middle+offset),color,1.5)
		draw_line(Vector2(size.x-22,middle+offset),Vector2(size.x-1,middle+offset),color,1.5)
	if cache:
		for row: int in range(3):
			draw_rect(Rect2(body.position+Vector2(6,6+row*10),Vector2(body.size.x-12,6)),Color(color,0.65 if row==0 else 0.25))
	else:
		draw_line(body.position+Vector2(8,body.size.y/2),body.end-Vector2(8,body.size.y/2),color,3)
