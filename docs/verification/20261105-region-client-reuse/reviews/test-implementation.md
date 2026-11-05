# Round12 pure cold-client regression

Owner `/root/audit_polish`, 2026-11-05. The assigned new file is complete and
**released to root** for import, execution and integration:

`tests/test_representation_region_clients.gd`

414 lines; SHA256
`81ecc4c60be75c646fa97daabe4e1b17c14187568d51eb7de36b1b864c4c38c6`.
No UID was invented. No existing source, test, harness, production setting or
durable documentation was edited by this agent. A small ignored coordination
note records the requested independent test-source review.

## Contract oracle

Forty bounded valid combinations cover whole RAW, whole RLE and mixed
revisits with clients1/2/4/8 in both modes, plus empty requests, cache0,
uncacheable blocks and zero latency at clients1/8 in both modes.

The test does not reproduce the preparation model. A separately executed
one-client public Region result supplies the preparation prefix and its
one-time storage/preparation fields. The expected service suffix really calls
`Base.run()` independently for every client. Only each disposable Base event's
absolute cycle and client metadata are added; all other fields and types stay
unchanged. Complete expected Region evidence is compared through the existing
typed Snapshot helper. There are162 such independent Base service executions
if all40 cases complete, plus a separate Base-failure oracle.

This checks all emitted event fields/types, sequential timing and actual fresh
Event identity, every access/cache snapshot, ordered outputs and scalar totals.
Summed service metrics derive from the independently executed Base results.
Overfetch and peak cache retain one-service values; they are not multiplied.
Independent source indexing also checks every logical result. Empty requests
retain preparation while emitting no client service; cache0/too-small cache
remain all misses; zero-duration request events stay present.

It checks input preservation, full typed repeated results, and preservation of
the retained original through the subsequent execution. A vector-length guard
reports a missing access as a test failure before indexing the cold starts.

## Explicit mutation coverage

Value snapshots normalize alias topology, so four additional fixtures
(online/offline × clients2/8) actively edit real returned evidence:

- First and last clients' request ranges/cache-before arrays and maps,
  transfer encoded bytes/directory, decoded values, consume eviction/cache-after
  arrays/maps, Event scalar and typed route arrays.
- Online preparation source values, encoded values/bytes and write payload/
  directory, while protecting all other events and metric surfaces.
- A metric block's values/payload/directory against every other block and event;
  a metric access against every other access, client and consume event.
- Returned source/plan provenance, including nested metadata, against the
  caller and all other result surfaces, then the reverse caller mutations.
- A separately retained identical result and a fresh future run after the
  earlier result was deliberately mutated.

The exclusion helper captures every script-variable field except the precise
edited object; it preserves other rows inside the edited metric collection.
This tests current finite array/dictionary detachment without claiming general
object-graph/cyclic-input equivalence.

One final flow retains a successful online eight-client result through a
different offline RAW success, compound Base rejection and valid-Base
preparation rejection. It compares the entire delegated Base failure, preserves
Round11's clean preparation failure, mutates later returned evidence and checks
that a fresh successful call still matches the retained original.

## Verification and handoff limits

Inspected the current Region/Base/Event/Cache/Snapshot implementations,
previous Region/rejection tests, active plan and current ownership record.
Inspected the new source and whitespace check:

`git diff --no-index --check /dev/null tests/test_representation_region_clients.gd`

No whitespace diagnostics. All three preload paths exist. The40/162 counts are
static enumeration expectations, not reported runtime acceptance. Current
status was inspected and other collaborators' changes were preserved.

**No Godot execution, parse validation, runtime pass, benchmark, native input
or Git mutation was performed by this agent.** Root should run this exact file
on the independently frozen
`.godot/verification/20261105T130540Z-round12-reference/project` and on the
candidate, preserving actual complete logs and exit status. The test itself has
no scene/profile lookup, process call, file operation or completion write.

The one-client preparation control intentionally shares the real public
preparation implementation. It is a scoped oracle for unchanged preparation
across client counts, not an independent proof of codec/preparation formulas.
Existing model/compatibility suites and frozen old/new complete snapshots
remain required. The test's normalized snapshots alone are not an arbitrary
alias-graph proof; the explicit mutations cover the stated current surfaces.

Independent source review was requested and root has appended the current
review assignment. Its readable report target is
`/private/tmp/vnb-round12-client-source-review.md`.
All test ownership is now released; any further edits require coordination
with root.
