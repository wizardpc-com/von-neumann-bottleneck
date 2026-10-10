# Creation state fixes (2026-10-08)

Base: `e46f8664e044c545a130e825363c72d77eca8513` on
`codex/compression-prediction-creation-20261008`; GitHub branch rechecked before edits.
Local review patch only: no commit, push, merge or deployment.

## Behavior

- A failed prediction-round switch preserves the entire previous frozen model,
  machine, hidden sequence, committed guess and event history. A valid switch
  replaces them together.
- RAW remains a lossless transport/comparison baseline, but cannot grant C1 or
  model-restoration permission. Only predictive transport can do that, including
  restored comparison evidence. Comparison validation still accepts RAW members.
- Keep is disabled unless the visible tracks are the current generated result and
  its recipe/output match the session generation. The handler enforces the same
  rule. Snapshot/replay browsing preserves the hidden draft but cannot save it;
  Generate makes the intended new result visible and saveable again.
- Playback and Step follow the current cell across pages. Manual page navigation
  pauses playback; resume returns to the cursor's page. End retains the last page.
- Cell inspection shows a bilingual context/count/prediction/outcome explanation
  followed by the raw audit record. It consumes recorded evidence without model
  execution or unrevealed targets. Position memorization and generation are labeled
  separately. G2's explicit example editing/retraining remains allowed.

## Fresh verification and limits

Environment: installed Godot **4.6.3**, whereas the repository pins **4.7.1**.
A minimal isolated project copied creation/candidate-session scripts and necessary
UI theme helpers only; its separate HOME/XDG profiles avoid player saves. The UI
harness substitutes system NotoSansCJK for the unavailable binary repository font.
Neither that font nor the harness project settings are part of the patch.

- `test_creation_contract.gd`: 162 checks, exit 0, no ERROR/FAIL.
- `test_creation_explanation.gd`: 61 checks, exit 0, no ERROR/FAIL.
- `test_creation_state_regressions.gd`: 20 controller checks, exit 0, no ERROR/FAIL.
- Independent restart fixture write/fork/read results are in the delivery logs.
- Existing `test_creation_workbench.gd`: 394 checks printed PASS, exit 0, **with
  pre-existing DSL parser constant-expression/dependency compile errors**. This
  is not a clean whole-project pass.

The new suites are conventional `test_` scripts and can run with the documented
isolated verifier on 4.7.1. Re-run the normal contract/workbench/navigation suites
and the restart wrapper there. No renderer screenshots, native mouse play,
original-font layout, human-learning or aesthetic acceptance was performed.

## Compatibility caution

A previously saved false `C1_restore` support whose codec is RAW now fails support
validation instead of re-granting progression. There is no automatic save migration
in this patch. Preserve those files and review recovery/migration before rollout;
normal RAW comparison evidence and protected recipes remain valid. No player save
was opened or modified during this work.
