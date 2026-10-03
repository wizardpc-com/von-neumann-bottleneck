extends ItemList
## Direct manipulation of existing groups; no scheduling or acceptance authority.
signal group_moved(source: int, target: int)

func _init() -> void:
	focus_mode = Control.FOCUS_ALL

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
