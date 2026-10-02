extends RefCounted
## Read-only presentation intervals. Does not retain a Trace or write to simulation.
var compute: Array[Vector2] = []
var transfer: Array[Vector2] = []
var total: float = 0.0

func configure(events: Array, domain: StringName, duration: float) -> void:
	compute.clear(); transfer.clear()
	total = maxf(0.0, duration)
	for event: Variant in events:
		if event.duration <= 0: continue
		var interval := Vector2(maxf(0, event.cycle), minf(total, event.cycle + event.duration))
		if interval.y <= interval.x: continue
		if event.kind == &"compute": compute.append(interval)
		if (domain == &"system" and event.kind in [&"read_data", &"write_data"]) or (domain == &"overlap" and event.kind == &"transfer"):
			transfer.append(interval)
	compute = _union(compute)
	transfer = _union(transfer)

func sample(cycle: float, window: float = 8.0) -> Vector3:
	# Trailing simulation window: no future activity is announced ahead of playback.
	var end: float = clampf(cycle, 0.0, total)
	var begin: float = maxf(0.0, end - maxf(0.001, window))
	var span: float = end - begin
	if span <= 0.0: return Vector3.ZERO
	var c: float = _length(compute, begin, end)
	var t: float = _length(transfer, begin, end)
	var overlap: float = 0.0
	for a: Vector2 in compute:
		for b: Vector2 in transfer:
			overlap += maxf(0.0, minf(end, minf(a.y, b.y)) - maxf(begin, maxf(a.x, b.x)))
	return Vector3(c / span, t / span, overlap / span)

static func _length(intervals: Array[Vector2], begin: float, end: float) -> float:
	var result := 0.0
	for interval: Vector2 in intervals:
		result += maxf(0.0, minf(end, interval.y) - maxf(begin, interval.x))
	return result

static func _union(intervals: Array[Vector2]) -> Array[Vector2]:
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var result: Array[Vector2] = []
	for interval: Vector2 in intervals:
		if result.is_empty() or interval.x > result[-1].y:
			result.append(interval)
		else:
			result[-1].y = maxf(result[-1].y, interval.y)
	return result
