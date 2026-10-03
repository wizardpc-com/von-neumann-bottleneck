extends RefCounted
## Authored workload authority. Never supplied to Predictor.
static func scenario(index: int) -> Dictionary:
	var streams: Array = [
		[0,4,8,12,16,20,24,28,32,36],
		[0,4,8,12,32,0,32,0,32,0,32,0],
		[0,8,0,8,0,8,0,8,0,8,0,8]]
	return {"name":["regular","changed","alternating"][clampi(index,0,2)],
		"addresses":streams[clampi(index,0,2)].duplicate(),"compute_gap":8,"cache_slots":2}

static func value_at(address: int) -> int:
	return (address * 7 + 11) % 256
