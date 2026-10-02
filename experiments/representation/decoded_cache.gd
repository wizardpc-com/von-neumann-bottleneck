extends RefCounted
## Pure automatic decoded-block cache. LRU order is oldest first.
## A negative byte budget disables that constraint; slot capacity is always finite.
## put is transactional: rejected replacements preserve the previous cached value.
var _slot_capacity: int = 0
var _byte_budget: int = -1
var _used_bytes: int = 0
var _entries: Dictionary = {}
var _sizes: Dictionary = {}
var _lru: Array[int] = []

func configure(slot_capacity: int, byte_budget: int = -1) -> void:
	_slot_capacity = maxi(0, slot_capacity)
	_byte_budget = byte_budget
	_used_bytes = 0
	_entries.clear()
	_sizes.clear()
	_lru.clear()

func has(key: int) -> bool:
	return _entries.has(key)

func fetch(key: int) -> Array[int]:
	if not has(key): return []
	_touch(key)
	var values: Array[int] = []
	values.assign(_entries[key])
	return values

func put(key: int, values: Array[int], size_bytes: int) -> Array[int]:
	var evicted: Array[int] = []
	# An uncacheable block never evicts useful entries, including its old version.
	if _slot_capacity == 0 or size_bytes <= 0 or (_byte_budget >= 0 and size_bytes > _byte_budget):
		return evicted
	if has(key):
		_used_bytes -= int(_sizes[key])
		_entries.erase(key)
		_sizes.erase(key)
		_lru.erase(key)
	while _entries.size() >= _slot_capacity or (_byte_budget >= 0 and _used_bytes + size_bytes > _byte_budget):
		var victim: int = _lru.pop_front()
		evicted.append(victim)
		_used_bytes -= int(_sizes[victim])
		_entries.erase(victim)
		_sizes.erase(victim)
	_entries[key] = values.duplicate()
	_sizes[key] = size_bytes
	_used_bytes += size_bytes
	_touch(key)
	return evicted

func snapshot() -> Dictionary:
	var keys: Array[int] = []
	keys.assign(_entries.keys())
	keys.sort()
	return {"keys": keys, "lru": _lru.duplicate(), "used_bytes": _used_bytes,
		"slot_capacity": _slot_capacity, "byte_budget": _byte_budget, "sizes": _sizes.duplicate()}

func _touch(key: int) -> void:
	_lru.erase(key)
	_lru.append(key)
