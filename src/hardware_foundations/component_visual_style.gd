class_name ComponentVisualStyle
extends RefCounted
## Shared presentation vocabulary, never a source of port or simulation semantics.
const SURFACE := Color("192b40")
const TEXT := Color("d7e9f6")
const SELECTED := Color("f0f5ff")
const FAMILY_COLORS := {
	"logic": Color("a9c5d7"), "arithmetic":Color("7fcbd6"),
	"storage":Color("aab6e6"), "routing":Color("f0c674"),
	"observe":Color("a8cadb"), "system":Color("bacbd9")
}
static func family(kind: StringName) -> StringName:
	match kind:
		&"input",&"output",&"lamp",&"constant",&"junction": return &"observe"
		&"and",&"or",&"xor",&"not",&"nor": return &"logic"
		&"half_adder",&"full_adder",&"alu1",&"alu4": return &"arithmetic"
		&"sr_latch",&"register1",&"register4",&"ram2x4",&"ram": return &"storage"
		&"mux4",&"mux2_word",&"decoder1_to_2",&"control",&"bus": return &"routing"
	return &"system"
static func accent(kind: StringName) -> Color:
	return FAMILY_COLORS[family(kind)]
static func outline_color(kind: StringName, selected: bool, hovered: bool = false) -> Color:
	return SELECTED if selected else accent(kind).lightened(0.18) if hovered else accent(kind)
static func shell(kind: StringName, rect: Rect2) -> PackedVector2Array:
	var x: float=rect.position.x;var y: float=rect.position.y
	var w: float=rect.size.x;var h: float=rect.size.y
	var c: float=minf(10.0,minf(w,h)*0.18)
	match kind:
		&"mux4",&"mux2_word":
			return PackedVector2Array([Vector2(x,y),Vector2(x+w,y+c),Vector2(x+w,y+h-c),Vector2(x,y+h)])
		&"decoder1_to_2":
			return PackedVector2Array([Vector2(x,y+c),Vector2(x+w,y),Vector2(x+w,y+h),Vector2(x,y+h-c)])
		&"alu1",&"alu4":
			return PackedVector2Array([Vector2(x,y),Vector2(x+w-c,y),Vector2(x+w,y+h/2),Vector2(x+w-c,y+h),Vector2(x,y+h),Vector2(x+c,y+h/2)])
	return PackedVector2Array([Vector2(x+c,y),Vector2(x+w-c,y),Vector2(x+w,y+c),Vector2(x+w,y+h-c),Vector2(x+w-c,y+h),Vector2(x+c,y+h),Vector2(x,y+h-c),Vector2(x,y+c)])
