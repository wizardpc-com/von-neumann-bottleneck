extends SceneTree
const Cache = preload("res://experiments/representation/decoded_cache.gd")
const Model = preload("res://experiments/representation/model.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func invariant_errors(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for key: int in state.lru:
		if seen.has(key): errors.append("duplicate_lru")
		seen[key] = true
	var ordered_keys: Array[int] = []
	ordered_keys.assign(seen.keys())
	ordered_keys.sort()
	if ordered_keys != state.keys: errors.append("membership")
	var size_keys: Array[int] = []
	size_keys.assign(state.sizes.keys())
	size_keys.sort()
	if size_keys != state.keys: errors.append("size_membership")
	if state.keys.size() > int(state.slot_capacity): errors.append("slots")
	var bytes: int = 0
	for key: int in state.sizes:
		if int(state.sizes[key]) <= 0: errors.append("entry_size")
		bytes += int(state.sizes[key])
	if bytes != int(state.used_bytes): errors.append("byte_sum")
	if int(state.byte_budget) >= 0 and bytes > int(state.byte_budget): errors.append("budget")
	return errors

func valid(state: Dictionary, label: String) -> void:
	check(invariant_errors(state).is_empty(), label + " cache invariants")

func literal_sequence() -> void:
	var cache := Cache.new()
	cache.configure(2)
	var accesses: Array[int] = [0, 1, 0, 2, 1, 2]
	var orders: Array = [[0], [0, 1], [1, 0], [0, 2], [2, 1], [1, 2]]
	var hits: Array[bool] = [false, false, true, false, false, true]
	var victims: Array = [[], [], [], [1], [0], []]
	for i: int in accesses.size():
		var key: int = accesses[i]
		var before: Dictionary = cache.snapshot()
		check(cache.has(key) == hits[i], "independent literal hit sequence %d" % i)
		check(cache.snapshot() == before, "membership probe is observational")
		var evicted: Array[int] = []
		if cache.has(key): check(cache.fetch(key) == [key], "hit returns value")
		else: evicted = cache.put(key, [key], 4)
		check(evicted == victims[i], "oldest victim selection %d" % i)
		check(cache.snapshot().lru == orders[i], "literal LRU after access %d" % i)
		valid(cache.snapshot(), "literal access %d" % i)
	var absent_before: Dictionary = cache.snapshot()
	check(cache.fetch(99).is_empty() and cache.snapshot() == absent_before, "missing get leaves state intact")

func byte_budget() -> void:
	var cache := Cache.new()
	cache.configure(4, 10)
	check(cache.put(0, [0], 3).is_empty(), "first byte entry")
	check(cache.put(1, [1], 3).is_empty(), "second byte entry")
	check(cache.put(2, [2], 4).is_empty(), "budget exactly filled")
	valid(cache.snapshot(), "filled bytes")
	cache.fetch(0)
	check(cache.snapshot().lru == [1, 2, 0], "byte cache hit promotes oldest")
	check(cache.put(3, [3], 7) == [1, 2], "variable block evicts multiple oldest entries")
	check(cache.snapshot().lru == [0, 3] and cache.snapshot().used_bytes == 10, "multi-eviction exact bytes")
	valid(cache.snapshot(), "variable block")
	check(cache.put(0, [9], 5) == [3], "replacement removes old size before selecting victims")
	check(cache.snapshot().used_bytes == 5 and cache.fetch(0) == [9], "replacement value and bytes")
	valid(cache.snapshot(), "replacement")
	var before: Dictionary = cache.snapshot()
	cache.put(0, [8], 11)
	cache.put(8, [8], 0)
	check(cache.snapshot() == before and cache.fetch(0) == [9], "oversize and invalid inserts preserve useful cache")
	var values: Array[int] = [7]
	cache.put(7, values, 5)
	values[0] = 99
	var fetched: Array[int] = cache.fetch(7)
	fetched[0] = 88
	check(cache.fetch(7) == [7], "input and output arrays cannot mutate cached data")
	var detached: Dictionary = cache.snapshot()
	detached.lru.clear()
	detached.sizes.clear()
	valid(cache.snapshot(), "detached snapshot")
	cache.configure(0, 10)
	cache.put(1, [1], 1)
	check(cache.snapshot().keys.is_empty(), "zero slots disables retention")
	cache.configure(2, 0)
	cache.put(1, [1], 1)
	check(cache.snapshot().keys.is_empty(), "zero bytes disables retention")

func timestamp_oracle(capacity: int, budget: int) -> void:
	var cache := Cache.new()
	cache.configure(capacity, budget)
	# Independent reference chooses minimum last-use timestamp; it has no LRU list.
	var last_use: Dictionary = {}
	var sizes: Dictionary = {}
	for step: int in 80:
		var key: int = (step * 7 + step / 3) % 7
		var bytes: int = 1 + key % 4
		var was_hit: bool = last_use.has(key)
		check(cache.has(key) == was_hit, "timestamp oracle hit at %d" % step)
		var expected_victims: Array[int] = []
		if was_hit:
			check(cache.fetch(key) == [key], "timestamp oracle value")
		else:
			var used: int = 0
			for stored: int in sizes: used += int(sizes[stored])
			while last_use.size() >= capacity or (budget >= 0 and used + bytes > budget):
				var victim: int = -1
				var oldest: int = step + 1
				for resident: int in last_use:
					if int(last_use[resident]) < oldest:
						oldest = int(last_use[resident])
						victim = resident
				expected_victims.append(victim)
				used -= int(sizes[victim])
				sizes.erase(victim)
				last_use.erase(victim)
			check(cache.put(key, [key], bytes) == expected_victims, "timestamp oracle victim order")
			sizes[key] = bytes
		last_use[key] = step
		var expected_order: Array[int] = []
		expected_order.assign(last_use.keys())
		expected_order.sort_custom(func(a: int, b: int) -> bool: return int(last_use[a]) < int(last_use[b]))
		check(cache.snapshot().lru == expected_order, "timestamp oracle complete resident order")
		valid(cache.snapshot(), "timestamp access %d" % step)

func model_accesses() -> void:
	var spec: Dictionary = Model.scenario(0)
	spec.addresses = [0, 4, 0, 8, 4, 8]
	var config: Dictionary = {"codec": "raw", "block": 4, "cache": 2}
	var trace: RefCounted = Model.run(spec, config)
	var orders: Array = [[0], [0, 1], [1, 0], [0, 2], [2, 1], [1, 2]]
	var hits: Array[bool] = [false, false, true, false, false, true]
	var victims: Array = [[], [], [], [1], [0], []]
	var index: int = 0
	var previous: Array = []
	var clock: int = 0
	for event: RefCounted in trace.events:
		check(event.cycle == clock and event.duration >= 0, "event clock continuity")
		clock += event.duration
		if event.kind != &"consume": continue
		valid(event.details.cache_before, "model before")
		valid(event.details.cache_after, "model after")
		check(event.details.cache_before.lru == previous, "per-access state continuity")
		check(event.details.cache_after.lru == orders[index], "model literal resident order")
		check(event.details.cache_hit == hits[index] and event.details.evicted == victims[index], "model literal hit/victim")
		previous = orders[index]
		index += 1
	check(index == 6 and trace.metrics.cache_hits == 2 and trace.metrics.cache_misses == 4, "model independent access totals")
	check(trace.passed and trace.metrics.outputs == [5, 5, 5, 5, 5, 5], "model actual decoded bytes")
	check(trace.metrics.total_cycles == 38 and clock == 38 and trace.metrics.traffic_bytes == 16, "independent raw costs 4*(4 request + 4 transfer)+6 consume")
	check(trace.canonical_signature() == Model.run(spec, config).canonical_signature(), "determinism includes every cache snapshot")
	config.cache = 1
	var one: RefCounted = Model.run(spec, config)
	check(one.metrics.cache_misses == 6 and one.metrics.cache_hits == 0 and one.metrics.total_cycles == 54, "one-slot eviction independently predicted")
	for event: RefCounted in one.events:
		if event.kind == &"consume": valid(event.details.cache_after, "one-slot model")
	# Tail bytes are actual decoded size, not nominal slot reservation.
	spec.data = [3, 3, 3, 2, 9]
	spec.addresses = [4, 0, 4]
	config.codec = "rle"
	var tail: RefCounted = Model.run(spec, config)
	check(tail.metrics.outputs == [9, 3, 9], "tail decode and eviction")
	for event: RefCounted in tail.events:
		if event.kind == &"consume":
			valid(event.details.cache_after, "tail model")
			check(event.details.cache_after.used_bytes == (1 if event.address == 4 else 4), "tail resident byte accounting")

func detector_sensitivity() -> void:
	var good: Dictionary = {"keys": [0], "lru": [0], "sizes": {0: 4}, "used_bytes": 4, "slot_capacity": 1, "byte_budget": 4}
	check(invariant_errors(good).is_empty(), "detector accepts known-good state")
	var mutation: Dictionary = good.duplicate(true)
	mutation.lru = []
	check(invariant_errors(mutation).has("membership"), "detector catches missing miss insertion")
	mutation = good.duplicate(true)
	mutation.lru = [0, 0]
	check(invariant_errors(mutation).has("duplicate_lru"), "detector catches duplicate recency")
	mutation = good.duplicate(true)
	mutation.slot_capacity = 0
	mutation.byte_budget = 3
	mutation.used_bytes = 5
	var errors: Array[String] = invariant_errors(mutation)
	check(errors.has("slots") and errors.has("budget") and errors.has("byte_sum"), "detector catches capacity and byte accounting regressions")

func run() -> void:
	literal_sequence()
	byte_budget()
	for capacity: int in [1, 2, 4]: timestamp_oracle(capacity, -1)
	timestamp_oracle(4, 5)
	model_accesses()
	detector_sensitivity()
	print("PASS: representation cache %d checks; per-access invariants, independent victims, byte budget and costs" % checks if failures.is_empty() else "FAIL: representation cache")
	quit(0 if failures.is_empty() else 1)
