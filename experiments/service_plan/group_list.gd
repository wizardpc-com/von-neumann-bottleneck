extends ItemList
## Direct manipulation of existing groups; no scheduling or acceptance authority.
signal group_moved(source: int, target: int)
const STREAM_COLORS: Array[Color] = [Color("50d5ff"),Color("a79aff"),Color("65d8ad"),Color("edb96b")]
var icons: Dictionary = {}

func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	fixed_icon_size = Vector2i(28,12)

func stream_mask(group: Array) -> int:
	var mask: int = 0
	for id: int in group:
		if id >= 0 and id < 24: mask |= 1 << (id / 6)
	return mask

func group_icon(group: Array) -> Texture2D:
	var mask: int = stream_mask(group)
	if icons.has(mask): return icons[mask]
	var image := Image.create(28,12,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for stream: int in 4:
		var color: Color = STREAM_COLORS[stream] if mask & (1 << stream) else Color("263c49")
		image.fill_rect(Rect2i(stream*7,1,5,10),color)
	var texture := ImageTexture.create_from_image(image); icons[mask] = texture
	return texture

func drag_payload(index: int) -> Dictionary:
	if index < 0 or index >= item_count: return {}
	return {"service_group_source":get_instance_id(),"index":index,"label":get_item_text(index),"count":item_count}

func _get_drag_data(at_position: Vector2) -> Variant:
	var payload: Dictionary = drag_payload(get_item_at_position(at_position,true))
	if payload.is_empty(): return null
	var preview := Label.new(); preview.text = str(payload.label)
	set_drag_preview(preview)
	return payload

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("service_group_source",0) != get_instance_id(): return false
	var source: int = int(data.get("index",-1))
	if source < 0 or source >= item_count or int(data.get("count",-1)) != item_count: return false
	if str(data.get("label","")) != get_item_text(source): return false
	var target: int = get_item_at_position(at_position,true)
	return target >= 0 and target != source

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position,data): return
	group_moved.emit(int(data.index),get_item_at_position(at_position,true))
