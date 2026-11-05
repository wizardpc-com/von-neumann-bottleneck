extends SceneTree
const Snapshot = preload("res://scripts/benchmarks/computation/snapshot.gd")
var checks: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	var source: Dictionary = {"events":[{"state":[1,2,3]}],"integer":9223372036854775807}
	var before: Variant = Snapshot.freeze(source)
	check(Snapshot.supported(before),"ordinary nested evidence is complete")
	source.events[0].state[0] = 9
	check(before != Snapshot.freeze(source),"snapshot detaches nested state")
	check(Snapshot.freeze(1) != Snapshot.freeze(1.0),"integer and float are distinct")
	var negative_zero: float = PackedByteArray([0,0,0,0,0,0,0,128]).decode_double(0)
	check(Snapshot.freeze(0.0) != Snapshot.freeze(negative_zero),"float sign bits retained")
	check(Snapshot.canonical("x") != Snapshot.canonical(&"x"),"StringName type retained")
	check(Snapshot.freeze(9223372036854775807)["@int"] == "9223372036854775807","int64 precision retained")
	var typed: Array[int] = [1,2]
	var untyped: Array = [1,2]
	check(Snapshot.freeze(typed) != Snapshot.freeze(untyped),"array element contract retained")
	var typed_map: Dictionary[String,int] = {"x":1}
	check(Snapshot.freeze(typed_map) != Snapshot.freeze({"x":1}),"dictionary type contract retained")
	var object := RefCounted.new()
	check(not Snapshot.supported(Snapshot.freeze({"nested":object})),"unsupported nested object rejected")
	var cycle: Array = []
	cycle.append(cycle)
	check(not Snapshot.supported(Snapshot.freeze(cycle)),"cyclic evidence rejected")
	cycle.clear()
	print(("PASS: " if failures == 0 else "FAIL: ")+"computation snapshot checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
