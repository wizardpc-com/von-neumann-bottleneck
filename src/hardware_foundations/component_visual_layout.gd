class_name ComponentVisualLayout
extends RefCounted
## Presentation only. Never use this record as simulation/progression evidence.
## V1 is frozen so old saved silhouettes do not change with later algorithms.
const SCHEMA: int = 1
const ALGORITHM: String = "layout-envelope-v1"
const COLUMNS: int = 12
const ROWS: int = 10
const MAX_COMPONENTS: int = 512
const MAX_COORDINATE: float = 1000000.0

static func freeze(source_signature: String, placements: Dictionary) -> Dictionary:
	if source_signature.is_empty() or placements.is_empty() or placements.size() > MAX_COMPONENTS:
		return {}
	for id: Variant in placements:
		if not (id is String or id is StringName): return {}
	var ids: Array = placements.keys()
	ids.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	var boxes: Array[Rect2] = []
	var bounds := Rect2()
	for id: Variant in ids:
		if String(id).is_empty() or not placements[id] is Dictionary:
			return {}
		var item: Dictionary = placements[id]
		for key: String in ["x", "y", "w", "h"]:
			if item.has(key) and not (item[key] is float or item[key] is int):
				return {}
		var x: float = float(item.get("x", 0.0))
		var y: float = float(item.get("y", 0.0))
		var w: float = float(item.get("w", 96.0))
		var h: float = float(item.get("h", 72.0))
		if not is_finite(x) or not is_finite(y) or not is_finite(w) or not is_finite(h):
			return {}
		if absf(x) > MAX_COORDINATE or absf(y) > MAX_COORDINATE or w <= 0.0 or h <= 0.0 or w > 4096.0 or h > 4096.0:
			return {}
		var box := Rect2(x, y, w, h)
		bounds = box if boxes.is_empty() else bounds.merge(box)
		boxes.append(box)
	# Normalize first, then snap small editing jitter before envelope quantization.
	# Snapping absolute world coordinates would make translation change the shape.
	var origin: Vector2 = bounds.position
	bounds = Rect2()
	for index: int in boxes.size():
		var box: Rect2 = boxes[index]
		box.position = (box.position-origin).snapped(Vector2(8,8))
		box.size = box.size.snapped(Vector2(8,8)).max(Vector2(8,8))
		boxes[index] = box
		bounds = box if index == 0 else bounds.merge(box)
	# Quantized occupied cells, sorted independently of dictionary insertion order.
	var occupied: Dictionary = {}
	for box: Rect2 in boxes:
		var start := Vector2i(floori((box.position.x-bounds.position.x)/bounds.size.x*COLUMNS), floori((box.position.y-bounds.position.y)/bounds.size.y*ROWS))
		var finish := Vector2i(ceili((box.end.x-bounds.position.x)/bounds.size.x*COLUMNS)-1, ceili((box.end.y-bounds.position.y)/bounds.size.y*ROWS)-1)
		for y: int in range(clampi(start.y,0,ROWS-1),clampi(finish.y,0,ROWS-1)+1):
			for x: int in range(clampi(start.x,0,COLUMNS-1),clampi(finish.x,0,COLUMNS-1)+1):
				occupied[y*COLUMNS+x] = true
	var cells: Array = occupied.keys()
	cells.sort()
	# A solid central spine guarantees one connected, grabbable body and label room.
	# Row envelopes preserve major left/right branches without thin wire-shaped tails.
	var bands: Array = []
	for y: int in ROWS:
		var left: int = 4
		var right: int = 7
		for x: int in COLUMNS:
			if occupied.has(y*COLUMNS+x):
				left = mini(left,x)
				right = maxi(right,x)
		bands.append([left,right+1])
	return {"visual_schema":SCHEMA,"visual_algorithm":ALGORITHM,"source_signature":source_signature,
		"layout_source":"verified_workbench","cells":cells,"bands":bands,
		"layout_digest":JSON.stringify(cells).sha256_text()}

static func is_valid(snapshot: Dictionary, source_signature: String) -> bool:
	if snapshot.get("visual_schema") != SCHEMA or snapshot.get("visual_algorithm") != ALGORITHM:
		return false
	if source_signature.is_empty() or snapshot.get("source_signature") != source_signature or snapshot.get("layout_source") != "verified_workbench":
		return false
	var bands: Variant = snapshot.get("bands")
	var cells: Variant = snapshot.get("cells")
	if not bands is Array or bands.size() != ROWS or not cells is Array or cells.is_empty() or cells.size() > ROWS*COLUMNS:
		return false
	var previous: int = -1
	var canonical_cells: Array[int] = []
	for cell: Variant in cells:
		if not (cell is int or cell is float) or not is_finite(float(cell)) or float(cell) < 0.0 or float(cell) >= ROWS*COLUMNS or float(cell) != float(int(cell)) or int(cell) <= previous:
			return false
		previous = int(cell)
		canonical_cells.append(previous)
	if String(snapshot.get("layout_digest","")) != JSON.stringify(canonical_cells).sha256_text():
		return false
	for row: int in ROWS:
		var band: Variant = bands[row]
		if not band is Array or band.size() != 2:
			return false
		for edge: Variant in band:
			if not (edge is int or edge is float) or not is_finite(float(edge)) or float(edge) < 0.0 or float(edge) > COLUMNS or float(edge) != float(int(edge)):
				return false
		if int(band[0]) < 0 or int(band[0]) > 4 or int(band[1]) < 8 or int(band[1]) > COLUMNS:
			return false
		var expected_left: int = 4
		var expected_right: int = 8
		for cell: Variant in cells:
			if int(cell) / COLUMNS == row:
				expected_left = mini(expected_left,int(cell) % COLUMNS)
				expected_right = maxi(expected_right,int(cell) % COLUMNS + 1)
		if int(band[0]) != expected_left or int(band[1]) != expected_right:
			return false
	return true

static func outline(snapshot: Dictionary, source_signature: String, rect: Rect2) -> PackedVector2Array:
	if not is_valid(snapshot,source_signature) or not rect.has_area():
		return PackedVector2Array()
	var bands: Array = snapshot.bands
	var points := PackedVector2Array()
	var unit: Vector2 = rect.size / Vector2(COLUMNS,ROWS)
	# Clockwise single x-monotone envelope. No holes, disconnected islands or spikes.
	for y: int in ROWS:
		_append_unique(points,rect.position+Vector2(float(bands[y][1])*unit.x,float(y)*unit.y))
		_append_unique(points,rect.position+Vector2(float(bands[y][1])*unit.x,float(y+1)*unit.y))
	for y: int in range(ROWS-1,-1,-1):
		_append_unique(points,rect.position+Vector2(float(bands[y][0])*unit.x,float(y+1)*unit.y))
		_append_unique(points,rect.position+Vector2(float(bands[y][0])*unit.x,float(y)*unit.y))
	return points

static func _append_unique(points: PackedVector2Array, point: Vector2) -> void:
	if points.is_empty() or not points[-1].is_equal_approx(point):
		points.append(point)
