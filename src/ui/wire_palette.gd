class_name WirePalette
extends RefCounted

const DEFAULT_INDEX: int = 0
const COLORS: Array[Color] = [
	Color("7fcbd6"),
	Color("7fd8a4"),
	Color("f0c674"),
	Color("e8848c"),
	Color("aab6e6"),
	Color("f58fd2"),
	Color("79a8ff"),
	Color("d6e2f2"),
	Color("8b929d"),
]


static func normalized_index(value: Variant) -> int:
	var index: int = int(value)
	return index if index >= 0 and index < COLORS.size() else DEFAULT_INDEX


static func color(index: int) -> Color:
	return COLORS[normalized_index(index)]


static func key_label(index: int) -> String:
	return str(normalized_index(index) + 1)
