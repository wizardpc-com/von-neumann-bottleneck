class_name LinkedMissionText
extends RichTextLabel

signal term_requested(term_id: StringName)

const TERM_COLOR := Color("50d5ff")


func _ready() -> void:
	bbcode_enabled = false
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_clicked.connect(_on_meta_clicked)


func set_linked_text(source: String, centered: bool = false) -> void:
	clear()
	push_paragraph(HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT)
	var cursor: int = 0
	while cursor < source.length():
		var marker_start: int = source.find("[[", cursor)
		if marker_start < 0:
			add_text(source.substr(cursor))
			break
		add_text(source.substr(cursor, marker_start - cursor))
		var marker_end: int = source.find("]]", marker_start + 2)
		if marker_end < 0:
			add_text(source.substr(marker_start))
			break
		var marker: String = source.substr(marker_start + 2, marker_end - marker_start - 2)
		var separator: int = marker.find("|")
		if separator <= 0 or separator == marker.length() - 1:
			add_text(source.substr(marker_start, marker_end + 2 - marker_start))
		else:
			var term_id := StringName(marker.substr(0, separator))
			var display_text: String = marker.substr(separator + 1)
			push_color(TERM_COLOR)
			push_underline()
			push_meta(term_id)
			add_text(display_text)
			pop()
			pop()
			pop()
		cursor = marker_end + 2
	pop()


static func linked_term_ids(source: String) -> Array[StringName]:
	var result: Array[StringName] = []
	var cursor: int = 0
	while cursor < source.length():
		var marker_start: int = source.find("[[", cursor)
		if marker_start < 0:
			break
		var marker_end: int = source.find("]]", marker_start + 2)
		if marker_end < 0:
			break
		var marker: String = source.substr(marker_start + 2, marker_end - marker_start - 2)
		var separator: int = marker.find("|")
		if separator > 0:
			var term_id := StringName(marker.substr(0, separator))
			if term_id not in result:
				result.append(term_id)
		cursor = marker_end + 2
	return result


static func plain_text(source: String) -> String:
	var output := ""
	var cursor: int = 0
	while cursor < source.length():
		var marker_start: int = source.find("[[", cursor)
		if marker_start < 0:
			output += source.substr(cursor)
			break
		output += source.substr(cursor, marker_start - cursor)
		var marker_end: int = source.find("]]", marker_start + 2)
		if marker_end < 0:
			output += source.substr(marker_start)
			break
		var marker: String = source.substr(marker_start + 2, marker_end - marker_start - 2)
		var separator: int = marker.find("|")
		output += marker.substr(separator + 1) if separator > 0 else marker
		cursor = marker_end + 2
	return output


func _on_meta_clicked(meta: Variant) -> void:
	term_requested.emit(StringName(meta))
