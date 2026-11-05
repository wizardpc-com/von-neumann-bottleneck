# Round12 client-service source review

Reviewer: `/root/review_records_final`, 2026-11-05.
Scope: the minimal Region service reuse, independent-client regression,
eight-case public workload sweep and separate diagnostic timing helper.
This is a read-only source review supplemented by examination of the root's
shared diagnostic snapshot. The reviewer did not run Godot, alter Git, access
ordinary player profiles or edit runtime/test/harness files.

## Current conclusion

No actionable source finding remains after the root's two-line oracle
correction below. The corrected test was narrowly rechecked at SHA256
`435e5c06de2b4541b22af60135920c6ee3abe05cdc9ce4841d1e88d44f4d82f6`.
Reverting only the two explicit StringName insertions in memory reproduces
the earlier reviewed file hash exactly, confirming that no other test code
changed. A fresh frozen/candidate Godot rerun remains required.

## Finding identified and corrected

**P2 — the independent test oracle inserted `client` with the wrong key type
(resolved in current source).**

In the initially released
`tests/test_representation_region_clients.gd:129` and `:136`, the oracle
added `event.details["client"]` and `access["client"]`. These were String keys.
The existing Region wrapper inserts `d.client` and `copied.client`
(`experiments/representation_region/model.gd:52,57`), producing StringName
keys. The full typed Snapshot intentionally distinguishes those types.
Consequently, every nonempty client-service comparison failed even on the
unchanged frozen implementation. The preparation-only empty-request cases do
not exercise either assignment.

This was a test-construction defect, not evidence of a production behavior
regression. Root changed exactly those two oracle assignments to `[&"client"]`.
The independent actual Base executions, full typed Snapshot, production
implementation and expected semantics remain intact. Rerun this same
corrected test on both the frozen and candidate runtimes.

Evidence:

- Root's latest `.godot/collaboration/round12-clients.md` records the released
  test's frozen-reference run: 900 checks, 36 failures, all nonempty complete
  oracle comparisons; no parse/script failure. This is root-owned runtime
  evidence, not an engine run by this reviewer.
- The shared `.godot/collaboration/round12-client-oracle-probe.json` shows
  `{"@string_name":"client"}` in actual event/access dictionary keys and
  `"client"` in the expected keys.
- A read-only Python inspection changed exactly eight expected `client` key
  representations in that probe and re-sorted the already-normalized
  dictionary pairs. The complete actual/expected typed value trees then
  matched; no event, metric, scalar, array type or other key was changed.
  This diagnoses the captured probe only and does not replace a Godot rerun.
- Probe SHA256:
  `ae469a0971cf2ba6cd972d0857ccf00d0b67c3043743af26daa47557bf208862`.

The earlier static draft conclusion missed this String/StringName distinction.
This finding and the narrow correction recheck supersede that conclusion.
Root made the correction; the reviewer has not changed the test.

## Other reviewed behavior

No other actionable source defect was found in the reviewed candidate.

The production diff against the frozen Round11 Region implementation is
exactly the replacement of the per-client repeated `Base.run(spec, plan)`
with the initial call's `service`, plus two explanatory comments. The initial
Base execution, Base-first rejection priority, clean preparation rejection,
preparation events, metric initialization and downstream client materialization
remain unchanged.

Base is deterministic and synchronous for these identical inputs, creates a
fresh decoded cache per actual call, and has no client-specific input, clock,
randomness, callbacks or external state in the examined path. Region reads the
completed service, creates every final Event through the existing emission
path, and deep-copies each client's details/access evidence. Existing
single-service `overfetch_values` and `peak_cache_bytes` remain unchanged;
the ten existing summed service metrics, outputs and event durations retain
their original aggregation order. There is no cross-run cache or new saved
metric authority.

Apart from the key-type defect above, the new regression uses actual
independent Base runs for every client. A real one-client Region call supplies
the unchanged preparation prefix and one-time storage/preparation fields.
It compares the complete typed Trace and separately checks source-derived
output order, event identities/timing, cold starts and meaningful edge cases.
The 40 combinations include clients 1/2/4/8, both preparation modes, mixed
revisits, empty requests, disabled/undersized caches and zero request latency.
The released access-vector size guard prevents an invalid result from being
indexed during the cold-start checks.

The explicit destructive mutation probes preserve all script-variable
surfaces except the exact deliberately mutated event, metric field or row.
They cover nested event/cache/block/access evidence, caller/result provenance,
separately retained calls and later successful or failed calls. The exclusion
helper shallow-copies the top metrics dictionary before removing a surface,
so the comparison helper itself does not mutate the trace. These probes
supplement typed snapshots, which do not preserve alias topology.

The workload adapter adds eight separate full public Region results:
online authored 64-address RLE scan and an explicitly named offline
192-address mixed-codec revisit fixture, each at clients 1/2/4/8.
Both retain input provenance, integer/type restoration and the existing full
semantic validator. Additional validation checks cold first accesses,
online preparation/hits and offline hits/evictions. Existing case semantics,
runner, Snapshot, comparator and evidence sealer remain unchanged.

The diagnostic helper validates actual Base services and the complete
materialized service suffix against the real complete Region oracle. It
removes only the preparation-event prefix for that comparison; absolute event
cycles, top-level fields, all metrics and container types remain. The helper
uses the same dot assignments as production for client tags, so the test's
String-key defect is not present in its materialization path.

It preserves immutable template/seed/input/retained evidence across samples
and cases, checks actual semantic failure status, requires isolated profiles,
records seven samples with declared fixed counts and handles aborted runs or
receipt-write errors as failures. Those source checks do not establish that
the script parses or completes; the root's actual logs, exit codes and sealed
receipts remain required.

## Timing interpretation clarification — resolved

The reviewer requested explicit disclosure that `_independent_services()`
retains all N complete Base results per invocation, unlike the production
wrapper's first/current service references. The owner added this to both the
source comment and exported `timing_scope` metadata at the reviewed hash.
No timing algorithm was changed for this clarification.

The two diagnostic boundaries include complete Trace allocation or client
evidence materialization, respectively. They exclude template/oracle/seed
construction, snapshots, hashes and export. They are not additive attribution,
pure arithmetic/allocation measurements, peak-heap evidence or public
Region/Run-button speed ratios. Adoption requires actual complete public API
measurements, with client1 and unchanged Base controls reported separately.

## Source identities

| File | SHA256 |
| --- | --- |
| `experiments/representation_region/model.gd` | `71c5a91016a00163b9a3be2f64ca90030f8992469866977521ed5858814ae6d3` |
| `tests/test_representation_region_clients.gd` (corrected) | `435e5c06de2b4541b22af60135920c6ee3abe05cdc9ce4841d1e88d44f4d82f6` |
| `scripts/benchmarks/computation/workload_cases.gd` | `6a480e5215efcf01fc9cdb037d5ff18e68f4c1679ef8ba0f906ebf908eec4c17` |
| `scripts/benchmarks/computation/region_profile.gd` | `566619295630a372d1c7a21c9a0551cff464db34303f93a902d4f5c71155e0de` |

The two harness hashes match the owner's released benchmark report.
The initially released test hash was
`81ecc4c60be75c646fa97daabe4e1b17c14187568d51eb7de36b1b864c4c38c6`.
Any later changes require a narrow source recheck before applying this review
to new bytes. Reviewer retains no implementation ownership. Parse/runtime
acceptance, performance benefit, native/GPU interaction and cross-platform
execution are not established by this report.
