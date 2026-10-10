# Creation evidence workbench — local v2 candidate

2026-10-08. Local implementation based on
`e46f8664e044c545a130e825363c72d77eca8513`. GitHub's branch was rechecked at
12:45 UTC and still matched. No commit, push, merge or deployment was performed.
This is a cumulative patch including the earlier state fixes, not a replacement
for the original source branch or a published build.

## Player-visible additions

- Locked RAW/predictive comparison executes both codecs on one source/model/machine.
  An immutable ledger totals actual event cycles, operations and traffic by encode,
  transfer, decode and output. Packet bytes and cycles have separate linear scales;
  failures are labeled rather than drawn as free. Learning and its historical
  machine are separate, with a from-scratch cost note. Six pairs remain in the
  current session; later edits do not rewrite their conditions.
- Causal inspection shows the actually matched context, four recorded counts,
  prediction and observed correction. Raw JSON is opt-in. Retraining shows actual
  before/after rule counts. A/B lanes retain their own evidence identity; encoder
  guesses use sender truth as context and decoder evidence uses recovered truth.
- Pinning a real generated A fixes seed, initial passage and length while preparing
  B. Actual recipe changes and first divergence are shown; random-only/multiple
  changes are not described as a controlled effect, and identical output is valid.
  The player can keep either actual result with its matching recipe. No aesthetic
  score or new G2 completion rule was introduced.
- Expand evidence gives the evidence page a larger reading region; Back to signal
  retains the selected position/page. The 1280×720 headless Control layout measured
  53 px collapsed and 353 px expanded in both languages. New comparison opens the
  ledger, while generation, snapshot playback and divergence locating show the
  signal again. These measurements do not establish visual quality.
- Focus on work is a read-only modal view of saved output, with full scrollable
  cells (up to 4096), work identity, supported recipe/source/rules and a clear return.
  Unsupported recipe/model/sampler/PRNG versions show the saved output and IDs only.
  Viewing does not generate, change a draft or save; background presentation pauses
  at its position until returning.

## State and persistence corrections

- Rejected prediction switches keep their original pending guess, hidden sequence,
  model, machine and event state together.
- RAW does not earn model-restoration permission or C1. Existing valid RAW cost
  comparison members remain valid. Older false RAW-C1 profiles open with validated
  works read-only, an explanation and a redo hint; the original bytes are untouched.
  No automatic migration grants replacement evidence.
- Saving is restricted to the visible generated result. Snapshot and recipe replay
  refresh their own provenance, costs, rules and events. A snapshot has no invented
  current trace borrowed from a different model.
- Failed save/CAS retries roll back in-memory works, supports and dirty state;
  retries do not consume the twelve-work limit. The redundant second UI save was
  removed. Underlying transactional recovery/archiving is unchanged.

## Verification boundaries

Installed engine: Godot 4.6.3; repository requirement: 4.7.1. All tests use isolated
HOME/XDG profiles, never player saves. The clean minimal harness loads only the
candidate and required UI helpers. System NotoSansCJK substitutes for an unavailable
binary font in test copies only; neither font nor project settings is in this patch.

Final per-suite results and source hashes are in the delivery manifest/logs. Focused
coverage includes actual event conservation, sealed predictions, rejected switches,
A/B lane mouse-hit routing, snapshot/replay attribution, repeated CAS failure and
successful retry, read-only legacy bytes, supported/future recipe versions, focus
open/close/Escape/reopen, whole-output reachability, and return→compare→save.
Independent review reproduced three integration defects and a future-version gap;
all were fixed and independently rechecked.

The full project's workbench/navigation/scene-route checks retain the known old
DSL-parser constant-expression compile errors on 4.6.3. PASS markers from those
runs are reported separately; they are not a clean project certification. The route
check uses actual Tutorial→journey→compression→prediction→generation→cancel/save
return→reopen→Tutorial scenes and confirms no original campaign completion changes.

## Follow-up acceptance

1. Apply/review on the exact base or consciously reconcile newer branch changes.
2. Run the repository's normal isolated verifier with official 4.7.1, then its
   independent restart fixture. `test_creation_route_flow` requires full autoloads.
3. Inspect original-font rendering at minimum size and both locales, modal keyboard
   focus, all detail tabs, long work names and full-output scrolling with real input.
4. Keep backups and define an explicit migration/recovery policy before rolling out
   to players with erroneous legacy RAW-C1 evidence. This patch preserves but does
   not silently convert their progress.
5. Assess novice comprehension and artistic experience separately. G2's historical
   stored-completion semantics are intentionally unchanged; the stronger A/B
   explanation is observational, not a new gate or persistent support type.
