# Notebook goal evidence — 2026-11-04 local

Both probes executed the unchanged production
`layout-schedule-experiment-1` in the new isolated QA copy
`.godot/verification/20261105T021829Z-18f99d78/project`. No fixture inputs or
scores were inserted into ordinary player data or default notebook entries.

The expanded probe completed2046 candidates, including40 expected copy-allocation
failures,56 repeat/JSON executions and16 pairs of values-only variations
(2134 total evaluations). It took34342.070ms and reported no assertion failures.
The declared finite sample includes1995 combinations over the four shipped
workloads and51 combinations over three unshipped structural workload probes.
See [raw log](probe.log), [probe](round5-strategy-probe.gd) and
[all measurements](strategy-results.json).

| Workload | Candidate combinations | Nondominated metric classes in sample |
| --- | ---: | ---: |
| scan_batch | 914 | 5 |
| scan_serial | 27 | 2 |
| mixed_batch | 1027 | 7 |
| mixed_serial | 27 | 2 |
| unshipped sparse clustered serial | 17 | 2 |
| unshipped sparse dispersed serial | 17 | 1 |
| unshipped separate hot-field serial | 17 | 3 |

The checks include actual output/write counts, real copy allocation, complete
ordered outputs, public Q1 completion, causal admission/response events, both
cost-accounting identities and selected complete Trace repeatability. Numeric
data variations changed outputs and condition identities, but not metrics in
the16 tested pairs. The source has no value-dependent scheduling path, so numeric
randomization alone would not create new performance strategies.

The separate [root envelope probe](round5-root-probe.gd) measured1292 declared
combinations and exited0. Its [results](root-results.json) select the least total
cycles among that sample under explicit Q1/copy caps:

| Condition | Q1 cap | Copy cap B | Chosen sample plan | Q1 / total / RAM B / copy B |
| --- | ---: | ---: | --- | --- |
| scan_batch | 350 | 0 | group2, tile1, no copy | 339 / 1368 / 1088 / 0 |
| scan_batch | 400 | 0 | group3, tile1, no copy | 371 / 1096 / 816 / 0 |
| scan_batch | 450 | 0 | group4, tile1, no copy | 403 / 824 / 544 / 0 |
| scan_batch | 600 | 0 | group8, tile1, no copy | 531 / 552 / 272 / 0 |
| scan_serial | 350 | 0 | direct | 307 / 2456 / 2176 / 0 |
| scan_serial | 600 | 80 | retained temperature | 557 / 1362 / 980 / 80 |
| mixed_serial | 350 | 0 | direct | 341 / 2784 / 2208 / 0 |
| mixed_serial | 900 | 160 | retained hot pair | 825 / 2404 / 1624 / 144 |

These results justify an editable response/space requirement over existing real
strategies. They do not justify fake costs, raising formal campaign thresholds
or calling a sampled winner globally optimal. No measured entry meeting a cap
means only that the available sample has no qualifying entry.

The broader probe still does not exhaust every UI copy-field click order or the
full model recipe domain. The unshipped probes remain research observations;
this increment adds retention and player-defined goals to the four existing
conditions, with no workload generator or model-rule change.
