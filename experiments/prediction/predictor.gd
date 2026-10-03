extends RefCounted
## Causal bounded state. No stream, scenario, next address, cache or evaluator input.
const HISTORY_LIMIT: int = 8
var _history: Array[int] = []
var _policy: Dictionary = {}
var _previous_guess: int = -1
var _cooldown: int = 0

func configure(policy: Dictionary) -> void:
	_policy = policy.duplicate(true)
	_history.clear(); _previous_guess = -1; _cooldown = 0

func observe(address: int) -> Dictionary:
	var mismatch: bool = _previous_guess >= 0 and _previous_guess != address
	if mismatch: _cooldown = int(_policy.get("cooldown",0))
	_history.append(address)
	if _history.size() > HISTORY_LIMIT: _history.pop_front()
	var decision: Dictionary = {"history":_history.duplicate(),"guess":-1,"reason":"insufficient_history","mismatch":mismatch,"cooldown":_cooldown}
	_previous_guess = -1
	var rule: String = str(_policy.get("rule","off"))
	if rule == "off": decision.reason = "disabled"; return decision
	if _cooldown > 0:
		_cooldown -= 1; decision.reason = "cooldown"; return decision
	var period: int = 2 if rule == "two_stride" else 1
	var confidence: int = int(_policy.get("confidence",1))
	var needed: int = period * confidence
	if _history.size() < needed + 1: return decision
	var deltas: Array[int] = []
	for i: int in range(1,_history.size()): deltas.append(_history[i]-_history[i-1])
	for offset: int in needed:
		if deltas[deltas.size()-1-offset] != deltas[deltas.size()-1-(offset % period)]:
			decision.reason = "unstable_history"; return decision
	var next_delta: int = deltas[deltas.size()-period]
	var guess: int = address + next_delta * int(_policy.get("lookahead",1))
	decision.reason = "out_of_range" if guess < 0 or guess > 124 or guess % 4 != 0 else "history_rule"
	if decision.reason == "history_rule": decision.guess = guess; _previous_guess = guess
	return decision
