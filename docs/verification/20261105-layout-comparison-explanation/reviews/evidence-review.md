# Round8 final evidence and documentation review

Reviewed 2026-11-05 for `/root` under
`.godot/collaboration/round8-review-followup.md`.

Read-only scope: final receipt, manifests, archived result/log/review files,
current status/architecture/testing/queue/audit documentation, and filesystem
hash/link checks. No source/test/documentation edit, Git operation, engine run,
native input or ordinary player-profile access was performed. This report is
the only file written for this assignment.

## Finding

**P3 — Mark the earlier queue priority as historical.**

`docs/exec-plans/active/README.md:25-30` still states, without a historical
qualifier, “下一优先级是完整探索循环的可理解性和跨条件复玩” and then says that
subsequent structural work follows the seventh-round result. The historical
marker is placed after that paragraph. The same active queue now explicitly
prioritizes comprehensive simulator computation/state/performance auditing in
lines8-14, following the user's newer direction. A future handoff reader can
therefore read two different next-priority instructions in the active queue.

Suggested bounded correction: label lines25-28 as the seventh round's
then-current next steps, or move the historical marker above that paragraph,
and make the marker defer to the latest explicit priority at the top. This is
a documentation clarification, not a runtime or verification blocker.

No other actionable evidence/documentation mismatch was found in the reviewed
snapshot. In particular, the receipt does not claim full-repository regression,
native acceptance, a proven repair for the original GPU nil, online score
authentication, or a global optimum.

## Binding and artifact checks

- Parsed `source-sha256.json` and recomputed every recorded hash against the
  current checkout, QA copy and playable copy. All matched. The manifest has
  **1225 entries total: 1224 byte-identical source/test/support files plus
  `project.godot`**, whose documented configuration differences are expected.
  The receipt's “1224 ...逐文件一致” is accurate.
- Inspected the actual project configuration differences: QA adds only the two
  custom-user-directory settings; playable adds those settings and selects
  `res://experiments/layout_strategy/lab.tscn`. The playable profile matches the
  receipt and launcher. No model or ordinary player-profile change is implied.
- Recomputed hashes, byte lengths and PNG header dimensions for all80 archived
  images. All match `frame-sha256.json`; no extra archived PNG was omitted.
  Exactly54 are final and26 are explicitly retained earlier captures.
  All referenced capture logs exist.
- Final54 comprise explanation12, structures14, original lab12, Notebook6 and
  challenges10. The final explanation/structures entries correctly bind to
  GPU081357Z; other final frames bind to GPU075637Z.
- English and Chinese visual review hashes cover27 and15 final frames
  respectively; the root final explanation report binds another6 final frames.
  The root report explicitly attests to the remaining6 original-lab Chinese
  frames. This review checked those report/artifact bindings, not their pixels.
  It does not independently repeat or enlarge the visual reviewers' acceptance.
- Checked313 local Markdown link targets across the current documentation,
  completed plan, receipt and archived review Markdown; none is missing. The old
  active Round8 plan is absent and the completed-plan links resolve.

Final core source hashes match the prior GPU recovery review:

| File | SHA256 |
| --- | --- |
| `experiments/layout_strategy/lab.gd` | `c88d8ef8e87dedc9fef185bebf120cc2c8e34dee70b069057d27a2cb13b5b7b4` |
| `experiments/layout_strategy/explanation.gd` | `3c6fa0ef67bcf56ef55cc0494cc4f771891cca436623c223ee258634d562b4be` |
| `experiments/layout_strategy/session.gd` | `46e06cc6586a3672a24f12bc575e495227eab3ff882b145d457c739e73a51055` |
| `tests/test_layout_strategy_explanation.gd` | `69c04d36165d427ac6dcff0c82e249f013d3a810f0d8493d4de818a61ea01ebb` |
| `tests/test_layout_strategy_explanation_ui.gd` | `8db5791581fd6a60d161b8e467387f4966e65d62fc81082ec4328957d4733410` |
| `tests/test_layout_strategy_structures_ui.gd` | `a72de1f22b9fc31bae971afad0a4fe0ab70ca2e62fa7bee3e4db2c767fa827da` |
| `tests/test_layout_strategy_session.gd` | `6d19542c26468ae09356224a8fb773308fe435a29db9c872c2ccbc7f7f22fb13` |

## Execution claims checked against archived results and logs

The **14 distinct related headless suites** are accurately described as
passing staged latest observations. The focus probe is excluded:

| Latest batch | Suites and recorded counts |
| --- | --- |
| 074417Z | model3449/223 measurements; Session78; explanation430/19 measurements; structures1247/88 measurements; goals75; workspace52; challenges65; original catalog680/56 measurements/112 code outcomes; legacy3810/141 designs/282 cases |
| 075427Z | original UI218; Notebook159; challenges250 |
| 081759Z | explanation UI453; structures UI304 |

Each latest result exits0 with an empty error list; its full test log agrees.
The five distinct GPU suites likewise have passing results: explanation481 and
captured structures348 at081357Z, original UI246/Notebook177/challenges282
at075637Z, plus the further fresh-profile noncapture structures320 at081926Z.
The latter's full log includes the before/after diagnostics and successful
visible ReplayChallenges creation in both locales, with no warnings/errors.

`logs/startup-result.json` now exists. It records the playable copy's
`--headless --quit-after 8` invocation exiting0, empty diagnostics and successful
launcher syntax validation. The corresponding startup log contains only the
Godot version line. All five archived import logs were checked for diagnostic
lines; no error or warning was found. This verifies the recorded smoke scope,
not native gameplay.

## Failures and acceptance boundaries retained correctly

- Pure073450Z retains both typed-array injection failures and the NaN JSON
  warning. The receipt distinguishes test-fixture correction from relaxing the
  reducer.
- UI074051Z retains eight failures. The receipt distinguishes the hidden-History
  focus fixture from the actual deferred SpinBox commit repair, and preserves
  the diagnostic probe.
- GPU075637Z retains the nil `retry_button` script error and process code−2;
  its later PASS342 line is explicitly invalid as acceptance. The receipt,
  CURRENT_STATE, testing guidance and GPU/visual reviews say that the cause is
  unconfirmed and that two later GPU runs did not reproduce it. They do not
  invent a product repair or treat the first run as passed.
- Native availability records `NOT_RUN`, locked Mac/failed automatic unlock at
  2026-11-05T07:05:02Z, no native input and no game process. The current receipt
  preserves native/export/Windows/newcomer/long-session limits.
- Current architecture and experiment documentation describe observational
  snapshot reduction, source event indexes, authoritative RAM/cache timing and
  preserved edit/persistence state consistently with the earlier contract and
  recovery reviews. Intermediate report hashes are snapshots of their stated
  review stage, not false final-source claims.
- No Git status, branch-tip, commit, push or unchanged-main verification was
  performed by this reviewer; root owns those final delivery checks.

Review ownership is released to root. The P3 queue wording can be corrected
without changing the frozen runtime or rerunning engine tests.

## Root resolution

Root changed active/README.md to explicitly label the Round7 follow-up paragraph as historical and defer to the current user-directed computation audit priority above. This documentation-only P3 is resolved; no runtime or verification source changed.
