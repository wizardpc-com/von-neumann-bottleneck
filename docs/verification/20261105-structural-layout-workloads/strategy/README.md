# Two structural workloads, actual strategy choices

Root executed `probe.gd` in the integrated isolated Godot4.7.1 runtime.
See `invocation.json`, complete `probe.log` and machine-readable `results.json`.
The probe examined442 candidates and10 repeated/JSON full-Trace replays,
with7100 checks,0 failures,452 actual measurements and4348.020ms elapsed.

Each new workload uses the same17 immutable four-field records and unchanged
memory/cache/copy costs. The finite sample contains one source-only plan plus
220 distinct effective one/two-field physical maps per workload. It varies
selected fields, selected-field order, effective blocks0..17 and same/separate
field groups, with query group1 and tile17. It does not enumerate every legal
layout, and its frontier is not a certificate of global optimality.

| Workload | Representative in sampled frontier | Q1 cycles | Total cycles | RAM bytes | Allocated copy bytes |
| --- | --- | ---: | ---: | ---: | ---: |
| Two temperature scans | Direct source |307|614|544|0|
| Two temperature scans | Retain temperature |557|672|500|80|
| Temperature then alarm | Direct source |307|2456|2176|0|
| Temperature then alarm | Retain temperature |557|2130|1748|80|
| Temperature then alarm | Retain temperature/alarm by field |727|1516|1032|144|

The first workload has two nondominated metric classes in this sample. Under
the same Q1≤600/copy≤80 conditions, direct access wins total cycles while the
retained temperature copy wins RAM traffic by44B. Copying spends58 more cycles,
waits250 more cycles for Q1 and uses80B. Its optional starter binds the RAM
objective explicitly, so a player can improve that target without pretending
the slower total is an improvement in every metric.

The phased workload has three sampled frontier classes. Its ordered output is
`[363,363,363,363,8,8,8,8]`: four temperature sums, then four alarm sums.
The structural suite additionally measures the record-major temperature/alarm
copy at791/2044/1560/144. Field-major727/1516/1032/144 improves Q1 by64 cycles,
total by528 cycles and traffic by528B at the same allocation. Its optional
source-only starter binds total cycles, Q1≤800 and copy≤144. The research
`goal_winners` arrays separately use600/80 for both workloads; they must not
be mislabeled as the phased starter's800/144 envelope.

Every observed frontier representative repeats the exact full canonical Trace
both directly and after JSON round trip. The separate structural suite checks
88 measurements, including expected allocation failures, exact ordered outputs,
response causality, accounting, immutable inputs and ineffective serial tiling.
Original four conditions and formal campaign rules are unchanged.

These results establish concrete playable choices and repeatability. They do
not establish player comprehension, long-term fun, exhaustive optimality or
online score authenticity. Keep future structural changes under new condition
identities; values-only randomization previously did not change these costs.
