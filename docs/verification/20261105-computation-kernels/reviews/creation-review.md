# Round9 independent Creation change review

Reviewer: `/root/review_records_final`
Date: 2026-11-05
Scope: `experiments/creation/model.gd`, `experiments/creation/codec.gd`, and new `tests/test_creation_computation_kernel.gd`.
Conclusion: **No actionable defect found in the reviewed change.** This is a source review, not runtime or performance acceptance.

I read the implementation handoff, complete current runtime files and the complete new test. I compared both runtime files with the frozen files under:

`.godot/verification/20261105T090809Z-3273d2f7/project/`

The recorded reference-workload invocation names this same QA project. Root's separate source-binding evidence identifies it as base `2748138d166855e86a5496ce60ca37a8389d4ce7`; this reviewer did not run Git to independently reconstruct that commit.

Reviewed boundary findings:

- Public `Model.predict` at line174 still validates the complete model before the complete prefix. `generate` at line204 still validates model, entire initial sequence, machine and generation bounds in the previous order. `Codec.encode` at line8 retains source/machine/model checks and the existing unknown-codec error override; RAW continues to ignore the unused model. `Codec.decode` at line58 preserves machine/header/integrity/length/model/padding/memory validation order. Removed validations were repeated checks inside an already validated synchronous operation.
- The new helper at `model.gd:181` reads symbols only through `slice(prefix_end-size, prefix_end)`, where `size <= min(order,prefix_end)` and validated order is0..2. The four runtime call paths supply the current complete prefix length or the encoder's current index. No unobserved source suffix enters the context, row selection, fallback or decision events.
- Current trusted helper callers establish the required alphabet and bounds. Generation begins with a fully validated seed and appends a symbol selected from four validated counts or the unchanged uniform fallback. The receiver first reconstructs a validated model from the packet and then appends only successful two-bit literal reads or validated predictor symbols. Packet length and generation length remain bounded by4096. Neither runtime file introduces a yield, signal callback, external callback, thread, persistent cache or shared scratch object during those operations.
- The helper preserves the previous linear row traversal, fallback traversal, smallest-symbol tie rule, uniform fallback and every decision-event construction. All event phases/indexes, seed/feedback writes, PRNG draws/rejection draws, residual bits, packet construction, accounting and cost-resolution loops outside the replaced calls are unchanged. No native/platform-dependent representation was introduced.
- Reusing `_serialize(model)` after successful validation preserves the accepted bytes. The decoder's direct digest of carried `model_bytes` is equivalent to the old reserialization identity for accepted packets: `from_bytes` checks the exact fixed header/reserved byte, bounded order/row count, complete row lengths, no trailing bytes, legal context symbols, strictly canonical row ordering and nonzero bounded uint16 counts. Its reconstructed source digest, order, row contexts/counts and row count serialize to those same bytes. Empty examples and parent are intentionally absent from the existing wire serialization. This claim is about local canonical identity, not authenticity or remote anti-cheat.
- Result ownership remains local: sliced contexts contain validated integers; returned counts and row-context evidence are duplicated; generated output begins from a duplicated seed; recipes retain deep copies; the decoder constructs a fresh packet-derived model. The new helper has no stored state that can survive a failed or later different call.
- Modeled memory formulas and failure return shapes are unchanged. The implementation does not claim that modeled `peak_bytes` measures actual host allocations, and reducing host prefix copies does not silently reduce game costs.

The new regression suite addresses the changed trust boundary with full public-input rejection, old-history invalid symbols, model mutation between calls, error precedence, order0/1/2 contexts, suffix independence, fallback/ties, max/weighted decisions, event/recipe detachment, exact versus insufficient modeled memory, resealed malformed packet/model/padding rejection, and packet-only decoding after sender-model mutation. Public-predict versus helper comparisons share the same new kernel, so they are not an independent old/new correctness oracle; the test and handoff explicitly rely on root's frozen full-result differential corpus for that purpose. I found no test assertion that justifies weakening the production contract.

Residual verification limits:

- No Godot/native process, benchmark, test suite or Git command was run by this reviewer.
- New GDScript parsing, all test results, every retained snapshot, complete old/new differential equality, and measured speed effects remain root's separate execution evidence.
- The helper is internal by convention; GDScript does not enforce privacy. All current runtime call sites were inspected. New future callers must establish the same preconditions.
- The existing circuit failed-step recovery defect reported by root is outside these files and is not resolved or certified by this review.

Reviewed current hashes, matching the implementation handoff:

- `model.gd`: `62d619f56f5f2765743ca55520a7a2a0e779374aa9763030270aa4d2019edabc`
- `codec.gd`: `77bcb75ae9d0cbdfaef20a32722b365bf5942d48d72c8742cc94237553f7be13`
- `test_creation_computation_kernel.gd`: `9be1d7d1ed277ad52eb71c860c1a86d13c613ca455745849c895eaac5110ae5b`

Frozen comparison hashes:

- `model.gd`: `a4b498823f54a9dffa31cc54b476946325bcace4885fb03ddf8f5ed97fe5f5ff`
- `codec.gd`: `51a061e8bace27d12b404acc9548956f553caac4083da1cf2bb7e4258a213c9f`

Only this review report was written. No runtime, benchmark or test source was changed.
