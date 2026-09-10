class_name LayoutRecipe
extends RefCounted
## A bounded logical-to-physical mapping, independent of display coordinates.
const FIELD_COUNT: int = 4
const WORD_BYTES: int = 4
const LINE_BYTES: int = 16
const MAX_RECORDS: int = 64

static func record_major() -> Dictionary:
	return {"groups":[{"fields":[0,1,2,3],"order":"record"}],"block":0}

static func field_major() -> Dictionary:
	return {"groups":[{"fields":[0,1,2,3],"order":"field"}],"block":0}

static func error(recipe: Dictionary) -> String:
	if not recipe.get("groups") is Array or recipe.groups.is_empty() or recipe.groups.size()>4: return "groups"
	var block: Variant = recipe.get("block",0)
	if not _integer(block) or int(block)<0 or int(block)>MAX_RECORDS: return "block"
	var seen: Array[int] = []
	for value: Variant in recipe.groups:
		if not value is Dictionary or not value.get("fields") is Array or value.fields.is_empty(): return "groups"
		if value.get("order","") not in ["record","field"]: return "order"
		for field: Variant in value.fields:
			if not _integer(field) or int(field)<0 or int(field)>=FIELD_COUNT or seen.has(int(field)): return "fields"
			seen.append(int(field))
	return "" if seen.size() == FIELD_COUNT else "fields"

static func normalized(recipe: Dictionary) -> Dictionary:
	if not error(recipe).is_empty(): return {}
	var groups: Array[Dictionary] = []
	for group: Dictionary in recipe.groups:
		var fields: Array[int] = []
		for field: Variant in group.fields: fields.append(int(field))
		groups.append({"fields":fields,"order":String(group.order)})
	return {"groups":groups,"block":int(recipe.get("block",0))}

static func mapping(recipe: Dictionary, count: int, base: int = 0, subset: Array = [0,1,2,3]) -> Dictionary:
	if not error(recipe).is_empty() or count<1 or count>MAX_RECORDS or base<0 or base%LINE_BYTES != 0: return {}
	var addresses: Dictionary = {}
	var cells: Array[Dictionary] = []
	var offset: int = base
	var block: int = int(recipe.get("block",0))
	if block == 0: block = count
	for group: Dictionary in recipe.groups:
		var fields: Array[int] = []
		for field: Variant in group.fields:
			if subset.has(int(field)): fields.append(int(field))
		if fields.is_empty(): continue
		offset = align_line(offset)
		for start: int in range(0,count,block):
			var stop: int = mini(start+block,count)
			if group.order == "record":
				for record: int in range(start,stop):
					for field: int in fields:
						addresses[record*FIELD_COUNT+field] = offset
						cells.append({"record":record,"field":field,"address":offset})
						offset += WORD_BYTES
			else:
				for field: int in fields:
					for record: int in range(start,stop):
						addresses[record*FIELD_COUNT+field] = offset
						cells.append({"record":record,"field":field,"address":offset})
						offset += WORD_BYTES
	return {"addresses":addresses,"cells":cells,"bytes":align_line(offset)-base,"base":base}

static func align_line(value: int) -> int:
	return ceili(float(value)/LINE_BYTES)*LINE_BYTES

static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))
