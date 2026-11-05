# Round9 workload semantic validation handoff

Owner: audit_polish. File ownership is RELEASED to root after this report.

## Delivered scope

Only `scripts/benchmarks/computation/workload_cases.gd` changed. It now exposes
`static func validate_case(spec: Dictionary, result: Variant) -> Array[String]`.
The function is intended for the runner's untimed checks, independent of exact
full-result snapshot comparison. It does not run scenes, create leases, write
profiles, repair model output or alter production simulation.

Current file: 749 lines.
SHA256: `bd7f061288e9a9cd181599dd94b200a2921b624de35b37bfc96379de14256db1`.

## Outcome checks

- Representation/Partition/Region: actual successful SimulationTrace, every
  requested source value in order, every consume event, every independent cold
  client's complete access count. The two Region plans also retain their public
  task3 acceptance outcomes (RAW joint-goal rejection, mixed-plan acceptance),
  as established by `tests/test_representation_region.gd`.
- Linear: all32 results/reference entries and output events, exact32-bit model
  mode preserves the actual reference. Quantized configurations are allowed to
  differ; no false exactness requirement is introduced.
- Persistent and Service: all24 unique request responses,24 compute/commit
  events, four final8-coordinate states, initial/final backing-store events and
  positive actual response cycles. Exact persistent configurations agree with
  their full reference scores and states; approximate state is not rejected
  merely because it differs from exact reference.
- Prediction: actual API success, all requested values independently obtained
  from the public address catalog, complete accesses/decisions/demand/policy
  events and a positive measured Off baseline.
- Service replay: one frame for every original event, exact original event and
  source index,24 final responses, correct accumulated transfer bytes and final
  backing states. Empty StateReplay output cannot pass by reproducing itself.
- Service codecs: all16 intended representation/stream pairs, actual nonempty
  packets, physical length-prefixed payload and exact pack/unpack results for
  the already-rounded inputs.
- Creation learning: valid model bound to declared examples/order, all actual
  sample reads and context count updates, one model emission, complete events
  reconciling cycles/ops/bytes against actual cost and machine memory.
- Creation transport: both successful encoder and receiver, packet retained,
  correct codec, exact complete source output, all input/recovered symbol events,
  one actual packet transfer and one packet validation. Each nested operation's
  event-derived cost is checked, as is the complete transport evidence.
- Creation generation: requested64/1024/4096 output lengths, unchanged seed prefix,
  valid symbols, exact declared recipe fields, all successor selections and
  feedback writes. Weighted generation requires the real sample and PRNG draw
  counts; max generation must not fabricate random draws.
- Creation Session: exact54-step workflow comprising two-symbol-prefix/22-step
  check-v2, denied early generation/reveal and duplicate commit, successful
  subsequent transitions, every causal reveal, complete prediction evidence,
  actual generation, four support receipts and **successful strict decode with
  full decoded data equal to the final Session profile**. It checks the final
  Session still has no path/lease/readable profile. No production/session setup
  repair was needed by the inspected public API contract.
- Expected failures match exact current contracts: preparation_machine, address,
  config, scratch_limit, invalid_address, stream_dependency, packet_integrity,
  memory_limit, generation_bounds and count. The documented Region malformed
  input metrics inconsistency is preserved rather than silently normalized.

These are outcome/operation checks, not hardcoded full performance snapshots.
Full deterministic event/state/float/byte parity remains the runner's task.

## Bounded adapter workflow additions

`workload_rejections` now calls `CreationCodec.decode` on the original valid
packet immediately after the intentionally damaged packet. The added
`decode_original` complete result must succeed and restore `[0,1,0,2]` with all
four recovered-write events. This proves a subsequent valid recovery path
actually runs; no bytes or metrics are manufactured. This changes that case's
work boundary, so reference and candidate must use this same final adapter and
the baseline must be frozen after the addition. All12 case IDs remain unchanged.

Per the latest explicit root assignment, `creation_generation_stress` also adds
one4096-symbol weighted request using the same training/model/machine/seed.
The generic validator requires all4096 outputs and4094 generated predictions,
samples and feedback writes. Complete original output/cost/recipe/events are
retained for the measured boundary differential; no summary-only replacement.

## Verification and requested root gate

Read the public implementations and relevant existing tests, inspected current
Git status and the full added validation logic. `git diff --no-index --check
/dev/null scripts/benchmarks/computation/workload_cases.gd` emitted no diagnostics;
exit1 reflects an added file. **No Godot, native execution or Git mutation was
performed by this agent.** Parser and actual semantic success remain unverified
until root's isolated run. Other adapters/harness/docs/new tests were preserved.

Suggested actual gate: all12 initial/repeated/JSON cases yield no validation
errors, then targeted bad-result probes reject an empty Service replay, a missing
response/output event, `decoded_profile.ok=false`, truncated Creation output and
an incorrect `decode_original.output`. Such probes should use fresh/detached
results outside timed measurements. Do not label baseline valid based solely on
snapshot equality; especially inspect full Session decode and all nested
Creation results.
