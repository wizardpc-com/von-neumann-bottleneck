# Round11 pure Region rejection regression

Owner `audit_polish`, 2026-11-05. The only implemented repository file is:

`tests/test_representation_region_rejections.gd`

Ownership is **released to root** for actual import, execution, integration and
further edits. Root owns production changes, documentation, all Godot/native
runs and Git operations. No UID was invented.

Release SHA256:
`371c9dea028ebeae2437ecfae0f889c4cbd521741f31e83ee5f211f1e6b0dbcd`.
The file is299 lines. All four preloaded resources exist.

## Coverage

The suite calls only actual public `Region.run()`, `Base.run()`,
`Region.orders()` and `Region.meets()` plus the existing complete typed
snapshot helper. It creates no scene, profile, save, lease, progress record or
subprocess and does not rely on a stub or private rejection constructor.

There are63 preparation-specific negative cases:

- 51 parameter cases cover each missing field, nulls, wrong scalar/container
  types, integer bounds and direct float1.0/fractional values. Clients/encoder
  are tested for both online and offline requests. Float types are supplied
  directly in GDScript; no JSON integer-normalization path can hide them.
- 12 codec/load cases cover whole RAW, whole RLE and RAW8/RLE56 under both
  modes, using the actual short and eight-client public orders with encoder0.

Each case first checks that its actual Base service is otherwise valid. Thus
an unrelated Base rejection cannot masquerade as a preparation regression.
The rejected result must have:

- the exact Region identity, failed status and `preparation_machine` reason;
- the unchanged21-key metric shape;
- all14 numerical fields present as integer0;
- empty output/expected/block/access arrays, no events and no scalar result;
- every other top-level typed Trace field equal to a freshly constructed Trace;
- complete typed submitted provenance, no input mutation, supported full
  snapshot and exact full typed repeat equality;
- rejection by all five task acceptance gates, using each task's actual
  required evidence count.

There are11 compound-invalid Base-precedence cases: missing data, bad byte,
empty/malformed plan, float boundary, unknown codec, bad/float bandwidth,
out-of-range/float address and a later block exceeding scratch. All three
preparation parameters are also invalid. Each Region result is compared with
the actual complete Base result after changing only its `test_name` to the
Region identity. The scratch case explicitly retains the old first-block12B
partial storage metric and empty blocks; this prevents accidental normalization
of an out-of-scope Base failure.

Separate mutation checks prove deep detachment in both directions for nested
source bytes, addresses, metadata and plan. Later rejected calls, a successful
eight-client run, and mutation of that successful result's block/event data
cannot alter the retained rejected observation.

There are12 accepted-boundary cases: online/offline × clients1/8 ×
encoder1/8/65536. They retain real ordered outputs, scalar sums, event-cycle
accounting, exact typed repetition and immutable inputs. The larger positive
encoder confirms this patch has not introduced an arbitrary upper bound.
The separate32-trace frozen compatibility corpus is owned by `audit_scores`;
this suite does not replace its old/new full-result comparison.

## Expected negative control and runtime status

On the unchanged old Region runtime, the prep-negative cases should expose
the retained service metrics, arrays, scalar values and non-default top-level
result fields while still reaching the test's final FAIL marker. The new
production constructor should satisfy those assertions without changing any
Base delegation or valid-boundary result.

No engine was run by this agent. Parse/runtime success, exact executed check
count and old/new failure/pass counts are **pending root execution**.
The authored case counts above are source inventory, not runtime results.

Root should import this same fixture into the frozen old reference, retain its
full negative result, then run the identical fixture against the candidate.
Use the ordinary isolated verifier/round runner; the suite's final output is:

`PASS/FAIL: representation region rejections ... checks / ... failures (... rejected, ... delegated, ... valid boundary cases)`

## Static verification

Read the current Round11 plan/ownership, Region/Base/Trace implementations,
typed snapshot helper and relevant existing tests. Inspected the complete
authored test and root's current small Region constructor diff.

`git diff --no-index --check /dev/null tests/test_representation_region_rejections.gd`
emitted no whitespace diagnostics; exit1 denotes the new-file difference.
Independent text scan found no trailing whitespace and no file access,
directory access, scene change, autoload lookup or process invocation. Current
Git status was inspected; root's production/documentation changes were
preserved. No Godot/native run or Git mutation was performed.
