# Round8 English original-frame review

Reviewer: `/root/audit_scores`. This is a read-only visual review under
`.godot/collaboration/round8-visual-review.md`. I opened all27 original English
PNG files with `view_image`; hashes/dimensions below identify the actual files
and are not a substitute for that pixel inspection. No source edits, engine
launches, CUA input, Git mutations or ordinary player-data access occurred.
I authored the pure reducer, but did not author the presenter or these captures;
this is independent visual inspection of the presenter, not independent review
of my own reducer implementation.

## Result and important invocation boundary

**No actionable pixel defect was found in the27 reviewed frames.** The new
explanation's numbers, selected/baseline identities, original-event scope,
readability, controlled overflow and dialog states are consistent in the frames.

The structures suite invocation is nevertheless **not a passing runtime result**.
Its `results.json` entry has code−2 / passed=false. Its complete log records
`Invalid access to property or key 'retry_button' on a base object of type 'Nil'`
at `tests/test_layout_strategy_structures_ui.gd:443` in `empty_legacy_targets`,
after all14 bilingual CAPTURE lines. Its subsequent `PASS ...342 checks,
0 failures` footer does not override that script error. Root was notified.
The7 English structure frames show the earlier rendered states only. They do
not establish that invocation completed correctly or that the failing route
passed. A repaired rerun requires its own result and, where replaced, new images.

The other four completed GPU results inspected here are exit0 with empty errors:
explanation481/0, original lab246/0, Notebook177/0 and challenge282/0.
These are root-owned executions read by this reviewer. Logs report Godot
4.7.1.stable.official.a13da4feb and OpenGL4.1 Metal90.5 on Apple M2.

## Observed frames

- **Explanation,6 frames.** At1280×720, the cycle/RAM table visibly shows
  preparation442vs0, query228vs612, output2vs2 and total672vs614, with+58 total
  cycles; RAM340vs0 preparation,160vs544 query and500vs544 total, with−44B.
  `Selected #2 − baseline #1` and both effective plans are visible. At960×640,
  the summary uses a vertical scroll table while retaining selectors, source
  labels, direction, explanation and both event-navigation buttons. The cache
  lens visibly separates17 preparation read lookups,0 hits,17 misses and17
  writes. The baseline event view explicitly says `Baseline #1`, retains the
  current copied draft, and labels the original query scope. Fill rows show
  RAM16B; Evict shows RAM0B while raw detail retains event-byte semantics.
  Request timing shows Q1 completion557vs307 (+250), Q2 admission557vs307,
  completion672vs614 (+58), elapsed115vs307 (−192), plus the explicit warning
  not to sum overlapping elapsed intervals. Partial first/last table rows are
  inside the visible scrolling region, not hidden controls. The failed-run raw
  view remains inspectable as run#3 with admitted/error events and no invented
  successful comparison.
- **Original lab,6 frames.** Compare and Evidence remain usable at1280×720 and
  960×640. Grouped source531/552/272/0 versus direct307/2456/2176/0 and the
  +224/−1904/−1904/0 tradeoff are visible. Explain is beside the existing restore,
  baseline and challenge actions. Raw memory events and detail have separate
  scroll surfaces. Public request order/cost text wraps within its reader. The
  exit guard is centered, legible and offers Keep exploring, Save and exit,
  Discard and exit without clipped labels.
- **Notebook,3 frames.** The goal, caps, kept-plan measurements and save controls
  are readable at both sizes. The intentionally long bilingual plan title is
  ellipsized in the960 table; its measurement columns remain distinct. This is
  ordinary bounded table text, not overlap. The save-failure/exit guard visibly
  explains another writer owns storage and changes remain in memory; its three
  actions are readable. No new overflow or misleading saved-success message
  is visible.
- **Challenge,5 frames.** Share code is readable with an explicit fixed-goal
  caption and actual339/1368/1088/0 measurement. Saved target350/0 and selected
  improvement−1088cycles are distinct from the personal goal. The960 main view
  preserves selected historical-run/draft-differs text and target status.
  Import720×540 has the code reader, measured preview, Preview and measure,
  Replace target and Back. Saved-retry state distinguishes saved target RAM
  objective from the personal total-cycle goal900/100. Popup original sizes
  are820×580 or720×540; filename suffixes are fixture labels, not an assertion
  that every popup is1280×720/960×640.
- **Structures,7 earlier rendered frames from the failed invocation.** Pair
  table/notebook show the actual614/544 versus672/500 choice and600/80 caps.
  The phased table shows727/1516/1032/144 versus791/2044/1560/144 and−64/−528/
  −528/0 differences. Starter popup states800/144 and measured direct work.
  Invalid retained group8 remains visible for a two-job serial condition, with
  explanatory text, no measurement row and disabled Explain. Legacy Notebook
  says copy unsaved/original remains; protected-target popup says temporary and
  original protected with disabled share actions before a run. All inspected
  controls/messages fit their main-window or popup viewport.

No screenshot demonstrates native mouse/key acceptance, beginner comprehension,
long-session usability, exported/cross-platform operation or remote score trust.
No inference of passing structures runtime is made from its correct-looking
screenshots. Source/screenshot binding and final repaired gates remain root's
integration responsibility.

## Exact capture inventory

Batch/log root:
`/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/verification/20261105T070528Z-49a63b5c/gpu/20261105T075637Z`

Capture profile root (the table paths are relative to this exact absolute root):
`/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round8/20261105T075637Z`

Count:6 explanation+6 lab+3 Notebook+5 challenge+7 structures=27 original English
frames,27 unique paths. Each was inspected visually before this inventory was
written; no image was resized, cropped or regenerated.

| Original relative path | Actual PNG dimensions | SHA-256 |
| --- | --- | --- |
| `test_layout_strategy_explanation_ui/layout-explanation-en-costs-1280.png` | 1280×720 | `165057425bc71f11a6e6f84bc1f6bc86f6bf7105e86886efbc758b0e4fd852fa` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-costs-960.png` | 960×640 | `48d049162a6f64f95562312d99ce1f55018c18a109312f19a9e8b77293ee2e4e` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-cache-960.png` | 960×640 | `8c8087cc7cb70c7d60780fb8b6c3bea639842ac9885e88b5259f8b5d627d67fd` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-baseline-events-960.png` | 960×640 | `9197dcb0a2d2f07eaf0687e4cd024beb1fbf8b52d3f3ee06b6254dfe2ca6d220` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-requests-960.png` | 960×640 | `cf9414638c9631b28cdbbb6cb80f7ad875fd1cece6d8d36f3a399fbc171d920b` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-failed-events-960.png` | 960×640 | `5c7ab7c4a485a8053e7fc25e007eb72f8dfb9b2a7e604617ca4c25780bff4af3` |
| `test_layout_strategy_ui/layout-strategy-en-evidence-1280.png` | 1280×720 | `40c3281c11c9e917fe317f3169077c266a43cade4bd4754db54ead3a7b46b46c` |
| `test_layout_strategy_ui/layout-strategy-en-compare-1280.png` | 1280×720 | `c62c671e1ce750e04b390e84e54d7d89bf4d61e99eb55a29576c029d3b1388f2` |
| `test_layout_strategy_ui/layout-strategy-en-compare-960.png` | 960×640 | `3ff02f1f455f8c1a7c3be4c33c703766672a1b1ce8bb5608ece51f16bb5053b9` |
| `test_layout_strategy_ui/layout-strategy-en-evidence-960.png` | 960×640 | `31a346820c4a0ce4dab6d225e584131c14328f569dc95ccc5de1a9ba7ab15f67` |
| `test_layout_strategy_ui/layout-strategy-en-public-960.png` | 960×640 | `77188b469c7c137704a39bc0799546a4bf6eac68b72d65373572ff3a65d03145` |
| `test_layout_strategy_ui/layout-strategy-en-quit-960.png` | 960×640 | `8b78bf164f8daf2c0878214a0156a7a278be4a3f3c1febb3a3eaea5de611d9be` |
| `test_layout_strategy_notebook_ui/layout-notebook-en-notebook-1280.png` | 1280×720 | `b9f0176830366de16ccf73f702a9878ab07375158f126d0708c82885501deeaf` |
| `test_layout_strategy_notebook_ui/layout-notebook-en-notebook-960.png` | 960×640 | `076ff440e76d09a54ccd3c956fa98611d55c2ebc2e4f837456bbf93bed5440f4` |
| `test_layout_strategy_notebook_ui/layout-notebook-en-save-failure-960.png` | 960×640 | `0504cf8b64c1dd01e719e46e1c7066b8d2b734dd58df1aadf3e2c392bb754e43` |
| `test_layout_strategy_challenge_ui/layout-challenge-en-share-1280.png` | 820×580 | `6ea8bb93c48c0033930b91c1279b6793b0448e2b26720750a1a8e7fbaecb7465` |
| `test_layout_strategy_challenge_ui/layout-challenge-en-target-1280.png` | 820×580 | `561410352d7d6f2f0f1e111ade03b8e72b8864b5c6cd0fc533839cadb1238ee8` |
| `test_layout_strategy_challenge_ui/layout-challenge-en-active-960.png` | 960×640 | `c5c1cbc4d210ea58e0413e42008e32bd54474215e456e6486dc7217d54418496` |
| `test_layout_strategy_challenge_ui/layout-challenge-en-import-960.png` | 720×540 | `13cf0e0a4ba7d167306accbf95f3be36baccd8eec9f2044e2a21981460d78135` |
| `test_layout_strategy_challenge_ui/layout-challenge-en-saved-retry-960.png` | 820×580 | `e0cd104befdead8155d82e3ff58cd6755932f92a489e8cb33f7078ecacd247d0` |
| `test_layout_strategy_structures_ui/layout-structures-en-pair-1280.png` | 1280×720 | `3efffe6991e78727499175feaca773cff3a526d1464ff8118981f9a4a5575dfb` |
| `test_layout_strategy_structures_ui/layout-structures-en-pair-notebook-960.png` | 960×640 | `93a80f15f3cf487396040e809b82ffec185aa2737fd0be3065801d5a58a92fc7` |
| `test_layout_strategy_structures_ui/layout-structures-en-phased-960.png` | 960×640 | `73840c2ae397f6ab60e8504de983e626c7d0a8ed7fc7156c4dd9fe6027f61131` |
| `test_layout_strategy_structures_ui/layout-structures-en-phased-starter-720.png` | 720×540 | `7f7a4d594c0534770abb12f7c99964661ab5d1b46f97acf6a08d6ed7f9589fdb` |
| `test_layout_strategy_structures_ui/layout-structures-en-invalid-draft-960.png` | 960×640 | `337db5ea9dff2bf418e9c97dd06d1e0819253d3574603cf902b35965c9f5b72b` |
| `test_layout_strategy_structures_ui/layout-structures-en-legacy-copy-960.png` | 960×640 | `8c88bcbf4ef57c74e671eb65e2b2d2bf3df3daad649048c820d8b848abc978cb` |
| `test_layout_strategy_structures_ui/layout-structures-en-protected-source-720.png` | 720×540 | `d5cf307a2ff562f8546bfeba6e8297ad55ece4647ab21d0fe3059919bdf7912d` |

## Completed log identities

| Log | SHA-256 | Recorded result |
| --- | --- | --- |
| `test_layout_strategy_explanation_ui.log` | `96feaafdbc6e432ce42e87e938aa058c0264825854692f9ec75b30d0ecbf5540` | code 0; passed true |
| `test_layout_strategy_ui.log` | `d96a84483f1d27b2edf5faab5844cc642455281b047a10f865a5b80b4f6c35a1` | code 0; passed true |
| `test_layout_strategy_notebook_ui.log` | `4bf91f3370628f738d83d5d0b5904ad7d732b1102d0bf7aa89a95c52eabb9dd6` | code 0; passed true |
| `test_layout_strategy_challenge_ui.log` | `9f555272718c1888ee357f73c3f1ce438fd25d96a5cca6f80244fca38db5c999` | code 0; passed true |
| `test_layout_strategy_structures_ui.log` | `a041d400907601b12b7bc66bb973c776fa5730bba5a6c0be07c8e011acdc8e5d` | code -2; passed false |

## Fresh rereview — GPU20261105T081357Z

Per `.godot/collaboration/round8-review-followup.md`, I read both completed
latest logs and `results.json`, then opened all6 English explanation and7
English structure originals from this new batch with `view_image`. The initial
report and failed-invocation evidence above remain unchanged.

**No actionable pixel defect was found in these13 freshly inspected frames.**
The explanation retains correct phase/traffic/cache numbers, both run IDs,
selected-minus-baseline direction, actual baseline event identity and raw failed
run access. The request-timing frame now begins with the full selected
`Q1 · admission` row at0/0/0 rather than retaining the prior lower scroll offset.
The bottom partial row is inside the scrollable table; controls and the elapsed
explanation remain outside and visible. Costs/cache views retain their original
readable headers, values and navigation controls at960×640 and1280×720.

The seven current structure frames retain the observed pair/phased metrics,
600/80 and800/144 caps, explicit invalid-group8 state, earlier Notebook copy
status, and protected temporary target wording. Main-window960×640 controls
and720×540 popup controls/messages are readable. No clipped actionable control,
misidentified baseline, false saved status or numeric disagreement is visible.

The inspected new results record **structures348 checks /0 failures** and
**explanation481 checks /0 failures**, each exit0 with empty errors. The
structures log's `EMPTY_TARGET_BEFORE/AFTER` diagnostics show a visible enabled
Challenges action and a nonnull `ReplayChallenges` window after the click in
both locales. Root added diagnostics and an explicit nonnull assertion/guard;
there was no identified product repair for the original nil. Therefore the
correct conclusion is **the first error was not reproduced in this rerun;
its cause remains unconfirmed**, not that a proven underlying defect was fixed.
Any further root-run repetition is outside this addendum until separately read.

Fresh batch/log root:
`/Users/yrq/Documents/冯诺伊曼瓶颈/.godot/verification/20261105T070528Z-49a63b5c/gpu/20261105T081357Z`

Fresh capture profile root (relative paths below):
`/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round8/20261105T081357Z`

| Original relative path | Actual PNG dimensions | SHA-256 |
| --- | --- | --- |
| `test_layout_strategy_structures_ui/layout-structures-en-pair-1280.png` | 1280×720 | `3efffe6991e78727499175feaca773cff3a526d1464ff8118981f9a4a5575dfb` |
| `test_layout_strategy_structures_ui/layout-structures-en-pair-notebook-960.png` | 960×640 | `93a80f15f3cf487396040e809b82ffec185aa2737fd0be3065801d5a58a92fc7` |
| `test_layout_strategy_structures_ui/layout-structures-en-phased-960.png` | 960×640 | `73840c2ae397f6ab60e8504de983e626c7d0a8ed7fc7156c4dd9fe6027f61131` |
| `test_layout_strategy_structures_ui/layout-structures-en-phased-starter-720.png` | 720×540 | `7f7a4d594c0534770abb12f7c99964661ab5d1b46f97acf6a08d6ed7f9589fdb` |
| `test_layout_strategy_structures_ui/layout-structures-en-invalid-draft-960.png` | 960×640 | `337db5ea9dff2bf418e9c97dd06d1e0819253d3574603cf902b35965c9f5b72b` |
| `test_layout_strategy_structures_ui/layout-structures-en-legacy-copy-960.png` | 960×640 | `8c88bcbf4ef57c74e671eb65e2b2d2bf3df3daad649048c820d8b848abc978cb` |
| `test_layout_strategy_structures_ui/layout-structures-en-protected-source-720.png` | 720×540 | `d5cf307a2ff562f8546bfeba6e8297ad55ece4647ab21d0fe3059919bdf7912d` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-costs-1280.png` | 1280×720 | `165057425bc71f11a6e6f84bc1f6bc86f6bf7105e86886efbc758b0e4fd852fa` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-costs-960.png` | 960×640 | `48d049162a6f64f95562312d99ce1f55018c18a109312f19a9e8b77293ee2e4e` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-cache-960.png` | 960×640 | `8c8087cc7cb70c7d60780fb8b6c3bea639842ac9885e88b5259f8b5d627d67fd` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-baseline-events-960.png` | 960×640 | `9197dcb0a2d2f07eaf0687e4cd024beb1fbf8b52d3f3ee06b6254dfe2ca6d220` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-requests-960.png` | 960×640 | `a91c8b41aec5e32c3b65373311ed430e809276a65b13a0b2c3f6758e5e1a3050` |
| `test_layout_strategy_explanation_ui/layout-explanation-en-failed-events-960.png` | 960×640 | `5c7ab7c4a485a8053e7fc25e007eb72f8dfb9b2a7e604617ca4c25780bff4af3` |

| New completed log | SHA-256 | Recorded result |
| --- | --- | --- |
| `test_layout_strategy_structures_ui.log` | `78ed5972efc61aba069343ef82385ccb37741494b61887d0048ef6fb8e5c59d2` | code 0; passed true |
| `test_layout_strategy_explanation_ui.log` | `96414e5e3f68dc3258c0b9383dff3d126fc9f8339e574a0d83f3d2ef4bf65409` | code 0; passed true |

This rereview is still rendered-script evidence. Native input, newcomer
comprehension, export and cross-platform acceptance remain unverified. No source
or test file was edited and no engine, CUA or Git mutation was performed here.
