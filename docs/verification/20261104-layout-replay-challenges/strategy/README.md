# Round6 structural and physical-layout research

Fresh research against the unchanged`layout-schedule-experiment-1` model.
Root executed both probes sequentially in the isolated Round6 QA copy with
Godot4.7.1.stable.official.a13da4feb. These finite samples do not certify global
optima, player understanding or the value of every possible physical layout.
The extra structures below are probe-only; the playable four tasks are unchanged.

## Structural probe

[Source](structural-probe.gd), [full log](structural-probe.log),
[raw results](structural-results.json), [unchanged model binding](model-sha256.json).
1475 candidates,48 selected repeat/JSON full-Trace executions,0 failed assertions;
measured probe elapsed24229.321ms.136 candidates examine8 structures with17
physical plans.1339 additional candidates examine220 distinct effective copied
one/two-field mappings with bounded scheduling controls.

Metrics below are **Q1 completion / total cycles / RAM bytes / copy bytes**:

| Structure | Candidates | Sample frontier classes | Representative observed metrics |
| --- | ---: | ---: | --- |
| One serial full scan |17|1|307 /307 /272 /0 |
| Two serial full scans |17|2|307 /614 /544 /0;557 /672 /500 /80 |
| Three serial full scans |17|2|307 /921 /816 /0;557 /787 /580 /80 |
| Current serial temperature control |17|2|307 /2456 /2176 /0;557 /1362 /980 /80 |
| Current mixed serial control |17|2|341 /2784 /2208 /0;825 /2404 /1624 /144 |
| Four temperature then four alarm scans |17|3|307 /2456 /2176 /0;557 /2130 /1748 /80;727 /1516 /1032 /144 |
| Repeated clustered sparse records |17|2|55 /880 /768 /0;465 /570 /356 /80 |
| Repeated spread sparse records |17|1|55 /880 /768 /0 |

Two serial full scans create a measured objective distinction under unchanged
operation costs. With Q1≤600 and copy≤80, actual`Goals.rank` selects direct for
total cycles614 and a retained temperature copy for RAM500B. The copy uses672
cycles and80B. This is a concrete basis for later structural conditions, with
no synthetic penalty or invalidation of an old score.

The split-fields structure also changes useful copied layout: field-major gives
727/1516/1032/144, while record-major gives791/2044/1560/144. The currently shipped
mixed serial workload favors record-major825/2404/1624/144 over field-major
841/2564/1784/144. Source task identities and notebook compatibility must be
designed before these probe structures become playable; do not replace existing
fixed task data behind an old identifier.

## Physical-layout coverage

The broader physical probe measures all220 distinct effective one/two-field maps
produced by copy blocks0..17, both selected-field orders and same/separate field
groups. It uses copy groups1/all ready jobs and query tile1; source-only controls
cover every legal query group. Counts are448/221/449/221 for
scan_batch/scan_serial/mixed_batch/mixed_serial, with5/2/7/2 sample frontier classes.
These agree with the previous finite frontier counts; the probe does not exhaust
all physical arrangements and query schedules.

The separate [copy-block source](copy-block-probe.gd),
[full log](copy-block-probe.log) and [raw results](copy-block-results.json) record
1140 actual evaluations,0 failed assertions,18943.953ms. It freshly measures the
prior16 frontier representatives, then two-field field-major copy blocks
0/1/2/3/4/5/6/7/8/9/12/16/17, groups1/all, query tiles1/4/17 in batch and17 in
serial. Candidate rows before final representative repeats are473/80/475/80.
No new metric tuple enters the combined sample frontiers; counts stay5/2/7/2.

Both probes check complete ordered output, event-based accounting, admission and
response causality. Selected repeated and JSON-roundtripped recipes reproduce
complete Trace identities. The measured algebra remains:

```text
total cycles = 2 * query values + outputs + 10 * copied words + 16 * fills
RAM bytes = 4 * copied words + 16 * fills
```

Decision: ship a replayable challenge loop over current conditions first. Do not
add a copy-block editor solely to increase option count. Preserve the measured
two-scan and split-fields designs for a separately identified structural
extension, retaining notebook/condition compatibility and rollback.
