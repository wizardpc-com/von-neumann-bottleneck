# Round9 Creation computation kernel handoff

Owner: audit_polish. All three assigned files are RELEASED to root.

## Scope and behavior

Changed only `experiments/creation/model.gd`, `experiments/creation/codec.gd`
and new `tests/test_creation_computation_kernel.gd`. Benchmark adapters remain
untouched after their frozen baseline. Root owns actual engine runs, UID import,
independent review, final docs and Git.

`Model.predict` retains its existing full model validation followed by full
prefix validation and exactly the same error precedence. It then calls the
internal `_predict_validated(model, symbols, prefix_end)` helper. The helper is
the original linear row traversal/event construction with an explicit prefix
end; it only slices contexts of length0..order (maximum2). It does not index
rules, suppress events or change fallback/tie handling.

`Model.generate` validates its incoming model, complete initial sequence and
machine exactly as before. Within the synchronous operation, newly generated
symbols remain in the four-symbol alphabet, so it can use the trusted helper
without revalidating the growing output or unchanged model. Its already-valid
model is serialized once and its digest is reused by model_load, recipe and
result. All random draws/rejection draws, sample selection, feedback events,
memory formula and cost summarization code remain unchanged.

Predictive `Codec.encode` retains its original whole-source/machine/model checks
and codec/error precedence. It reuses canonical model bytes and calls the helper
with the original source plus the current index, avoiding each whole-prefix
copy. The entire source has been validated before this loop; the helper reads
only contexts ending at the current prefix position.

`Codec.decode` still validates machine, header, checksum, lengths, carried model,
padding and memory before processing. `from_bytes` remains the strict model
boundary. Literals are two-bit values and predicted symbols come from validated
counts; only those legal symbols enter subsequent prefixes. The model_load ID
uses the same strictly accepted canonical model bytes carried in the packet.
`from_bytes` rejects noncanonical row order/trailing/malformed fields, and the
new test checks carried bytes equal public canonical reserialization. No sender
model or external training state enters the decoder.

No global cache, cross-call memoization, pooling, threading, native dependency,
format/version/identity changes, profile writes or save conversion are added.
This is intended to preserve every result/cost/state/event exactly; only the
frozen old/new differential can establish that acceptance.

## Assumptions and risks

- The helper is internal by underscore convention (GDScript does not enforce
  private access). Its documented preconditions are a validated unchanged model,
  valid symbols in `[0,prefix_end)`, and `0 <= prefix_end <= symbols.size()`.
  Only `predict`, `generate`, encoder and decoder use it in runtime code.
- Calls are synchronous with no awaits, callbacks or externally exposed mutable
  scratch state during execution. All returned arrays/events are constructed
  or detached as before. A future asynchronous caller would need a fresh design
  review rather than borrowing this trust boundary.
- Raw codec paths remain independent of unused predictive model validation.
  Public mutated inputs are revalidated on every new operation.
- The decoder byte-derived ID is equivalent only because the unchanged
  `from_bytes` accepts canonical encodings; the test and frozen corpus must
  verify this. Any full-evidence difference blocks integration.
- Rollback is the two runtime files from base2748138; no data migration or score
  invalidation is involved. No performance improvement is claimed by this
  child agent before root measures the candidate.

## New meaningful regression suite

`test_creation_computation_kernel.gd` exercises actual learning and public APIs:

- Order0/1/2 bounded-prefix versus strict-public prediction, every output field
  and event, unused valid suffix independence, two-step fallback, tie selection
  and the valid empty-example/uniform fallback model.
- Max and weighted generation, complete same-input deterministic results, actual
  event accounting and each generated decision versus the public predictor.
  Every feedback write/sampler/PRNG operation remains present.
- RAW and predictive full packet transport, all encoder/receiver decisions versus
  the public predictor, canonical receiver identity and retained detailed costs.
  Additional cache capacities0/1/21 exercise actual resolved cache events.
- Invalid symbols far outside the last two contexts, float-typed symbols, full
  sequence limits, mutated counts/examples/unknown fields/self-parent and error
  precedence across public prediction/generation/encoding. Failed calls followed
  by valid calls must recover; RAW must retain its existing model independence.
- Event/context/count/recipe detachment across later different models, returned
  result edits and original seed edits; fresh valid model identity per call.
- Exact generation/receiver memory bounds versus one byte below, preserving
  actual required-byte evidence.
- Corrupt checksum, valid-checksum empty carried row/unknown order, nonzero RAW
  padding, packet-only decoding after mutating the original sender model, and
  recovery after rejected packets.

The suite does not clone the former predictor or PRNG implementation. Public
prediction comparisons check the operational boundaries and event preservation;
the independent frozen base corpus remains the old/new correctness oracle.

## Verification status and commands for root

`git diff --check` passed; new test's `git diff --no-index --check /dev/null ...`
emitted no diagnostics (exit1 is added-file status). Inspected full runtime diff,
new test and current Git status. Other agents' docs/harness/test changes were
preserved. **No Godot/native process or Git mutation was run by this agent.**
Parser/test/differential/speed results remain pending root's isolated execution.

Suggested focused command under the existing verified isolated runner:

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --suite test_creation_computation_kernel --suite test_creation_contract --suite test_creation_state_regressions --suite test_creation_prediction_memory --suite test_creation_cost_ledger --suite test_creation_evidence_identity --suite test_creation_preparation_binding
```

Root should compare the final unchanged benchmark corpus against
`.godot/computation-benchmarks/20261105T093116Z-reference-workload/` with identical
iteration counts/host/harness, including4096 weighted output/recipe/cost/full
Trace. Do not update the frozen reference to make a mismatch pass. Capture
candidate microprofile only after complete evidence parity passes.

## Released file hashes

- `experiments/creation/model.gd`: `62d619f56f5f2765743ca55520a7a2a0e779374aa9763030270aa4d2019edabc`
- `experiments/creation/codec.gd`: `77bcb75ae9d0cbdfaef20a32722b365bf5942d48d72c8742cc94237553f7be13`
- `tests/test_creation_computation_kernel.gd`: `9be1d7d1ed277ad52eb71c860c1a86d13c613ca455745849c895eaac5110ae5b`
