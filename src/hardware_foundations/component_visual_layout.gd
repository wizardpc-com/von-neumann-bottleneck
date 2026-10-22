class_name ComponentVisualLayout
extends RefCounted
## Presentation only. Never use this record as simulation/progression evidence.
## Versioned geometry keeps saved silhouettes stable across algorithm changes.
const SCHEMA: int = 1
const ALGORITHM: String = "layout-envelope-v2"
const LEGACY_ALGORITHM: String = "layout-envelope-v1"
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
	# Preserve relative aspect while fitting inside a one-cell margin. Quantize in
	# normalized cells so zoom, translation and world-unit scale cannot distort it.
	var scale: float = minf(float(COLUMNS-2)/bounds.size.x,float(ROWS-2)/bounds.size.y)
	var padding: Vector2 = (Vector2(COLUMNS,ROWS)-bounds.size*scale)*0.5
	var occupied: Dictionary = {}
	for box: Rect2 in boxes:
		var start: Vector2 = ((box.position-bounds.position)*scale+padding).snapped(Vector2(0.25,0.25))
		var finish: Vector2 = ((box.end-bounds.position)*scale+padding).snapped(Vector2(0.25,0.25))
		# A tiny real component must survive quarter-cell quantization.
		var first := Vector2i(clampi(floori(start.x),0,COLUMNS-1),clampi(floori(start.y),0,ROWS-1))
		var last := Vector2i(clampi(maxi(first.x,ceili(finish.x)-1),0,COLUMNS-1),clampi(maxi(first.y,ceili(finish.y)-1),0,ROWS-1))
		for y: int in range(first.y,last.y+1):
			for x: int in range(first.x,last.x+1):
				occupied[y*COLUMNS+x] = true
	var cells: Array = occupied.keys()
	cells.sort()
	var bands: Array = _bands_for(cells,ALGORITHM)
	return {"visual_schema":SCHEMA,"visual_algorithm":ALGORITHM,"source_signature":source_signature,
		"layout_source":"verified_workbench","cells":cells,"bands":bands,
		"layout_digest":JSON.stringify(cells).sha256_text()}

static func is_valid(snapshot: Dictionary, source_signature: String) -> bool:
	var algorithm: Variant = snapshot.get("visual_algorithm")
	if snapshot.get("visual_schema") != SCHEMA or not algorithm is String or algorithm not in [ALGORITHM,LEGACY_ALGORITHM]:
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
	if not snapshot.get("layout_digest") is String or snapshot.layout_digest != JSON.stringify(canonical_cells).sha256_text():
		return false
	var expected: Array = _bands_for(canonical_cells,algorithm)
	for row: int in ROWS:
		var band: Variant = bands[row]
		if not band is Array or band.size() != 2:
			return false
		for edge: Variant in band:
			if not (edge is int or edge is float) or not is_finite(float(edge)) or float(edge) < 0.0 or float(edge) > COLUMNS or float(edge) != float(int(edge)):
				return false
		if int(band[0]) != expected[row][0] or int(band[1]) != expected[row][1]:
			return false
	return true

static func _bands_for(cells: Array, algorithm: String) -> Array:
	var bands: Array = []
	for row: int in ROWS:
		# The middle island protects name/icon space. Elsewhere a two-cell spine
		# connects sparse source islands without the legacy full-height wide fill.
		var legacy: bool = algorithm == LEGACY_ALGORITHM
		var label_row: bool = row >= 3 and row <= 7
		var left: int = 4 if legacy else (3 if label_row else 5)
		var right: int = 8 if legacy else (9 if label_row else 7)
		for cell: Variant in cells:
			if int(cell) / COLUMNS == row:
				left = mini(left,int(cell) % COLUMNS)
				right = maxi(right,int(cell) % COLUMNS+1)
		bands.append([left,right])
	return bands

static func outline(snapshot: Dictionary, source_signature: String, rect: Rect2) -> PackedVector2Array:
	if not is_valid(snapshot,source_signature) or not rect.has_area() or not rect.position.is_finite() or not rect.size.is_finite():
		return PackedVector2Array()
	var bands: Array = snapshot.bands
	var points := PackedVector2Array()
	# Match the piecewise-linear band interpolation used by both canvas rows
	# and palette thumbnails. A review/export must not invent a stepped outline.
	for y: int in ROWS:
		_append_unique(points,rect.position+Vector2(float(bands[y][1])/COLUMNS*rect.size.x,float(y)/float(ROWS-1)*rect.size.y))
	for y: int in range(ROWS-1,-1,-1):
		_append_unique(points,rect.position+Vector2(float(bands[y][0])/COLUMNS*rect.size.x,float(y)/float(ROWS-1)*rect.size.y))
	return points

static func _append_unique(points: PackedVector2Array, point: Vector2) -> void:
	if points.is_empty() or not points[-1].is_equal_approx(point):
		points.append(point)
