# Night experience candidate — 2026-10-18

Engineering scope completed2026-10-18: fixed Windows normal/tester packages,
independent reviews, scoped native observation and next-day evidence handoff.
Root owns the final documentation commit/push and review-PR delivery. Human and
broader platform acceptance remain separate open gates.

## Goal and authority

Deliver a runnable offline candidate connecting Home, a skippable/replayable Yi
introduction, an actual first construction, rule exploration, and the extended
journey. User explicitly authorized PR10 merge, delegated implementation/review,
new commits and substantial pushes to a new branch. No public Release, server,
account, domain, paid resource or destructive save migration is authorized.

PR10 merged normally as `bf8f61647c03c8bba868cc833b3832e274bd4aee` after its
four checks succeeded. Its tree equals reviewed head `78e8c98`. Original checkout
has an unexplained deletion of `tests/test_ui.gd`; it remains untouched there.
Implementation uses the separate `night-experience-20261018` worktree and
`codex/night-experience-20261018` branch. Existing packages/profiles stay intact.

## Scope and ownership

| Owner | Exclusive write scope |
| --- | --- |
| Controller | Navigation/map, build/QA scripts, integration, shared docs and evidence |
| Narrative worker | prototype_hub.gd, mission_narrative_catalog.gd, level_completion_overlay.gd; new intro content/UI and focused tests |
| Knowledge worker | terminology_handbook.gd, terminology_diagram.gd, focused learning tests |
| Visual worker | instrument_theme.gd, technical_backdrop.gd, ui_typography.gd; focused theme tests and asset interface document |

During R1 implementation, workers did not mutate Git or run Godot, and stayed
within their file scopes; the controller queued runtime checks. Later user
steering delegated sequential engine/export ownership to the narrative worker,
native observation to the knowledge worker, and final documentation/evidence to
the visual worker. Root retained all Git writes. Independent review follows
implementation, with each worker reviewing another scope.

## Invariants and decisions

- Godot 4.7.1; real simulation and earned completion remain authoritative.
- No new save schema, model, prerequisites, budget changes or automatic solutions.
- F8 remains available over introduction/help/completion; skip retains rules.
- Preserve compression/content prediction/creation and actual model preparation.
- Latest user/manual direction permits minimalist future styling and C/P/G;
  older constitutional roadmap/palette does not override those directions.
- Candidate dialogue and palette remain replaceable, pending human judgement.
- Separate model/headless, rendered/controller input, exported executable and
  native/human acceptance. Never relabel fixtures as human testing.

## Rounds and verification

1. R0: confirm baseline, preserve unrelated changes, collect fresh isolated
   baseline and rendered frames, engine/templates/config and known failures.
2. R1: implement introduction, interactive representative rules, shared theme
   and discoverable creation route. Run affected suites, inspect real rendering,
   review diff and commit a recoverable checkpoint.
3. R2: cross-review integration and deepen real completion/mid-game/journey
   continuity. Fix findings; exercise wrong inputs, alternative legal cases,
   repeat/replay, feedback nesting and three target window sizes/locales.
4. R3: full isolated regression and Python gates; freeze committed Windows
   package, verify identity and launch its EXE in isolated QA. Exercise C/P/G,
   saved work and cross-process feedback export/import. Independent final audit.
5. R4: evidence-driven repairs if needed, final checkpoint/push and next-day
   handoff with screenshots, exact package identity, <=5 human review questions
   and art/narrative replacement interfaces. Public publication stays pending.

Each round records actual commands/results, its checkpoint and next action here
or in the linked verification entry. Existing failed attempts remain evidence.

## Progress

- R0: remote PR/main checked live; PR10 merge completed; clean isolated worktree
  created. Fixed Windows editor and matching release export template found in
  sibling engine/template cache. Original deletion excluded from development.
- R1: Home/Yi/actual tutorial completion, six interactive rule illustrations,
  shared dark theme and C/P/G map shortcuts integrated. Baseline checks6/6 and
  actual bilingual homepage frames retained at `.godot/verification/20261017T182236Z-482dd67e/`.
  R1 affected suites include handbook1163 assertions, hub three window sizes,
  original continuation/feedback/tutorial checks; final focused6/6 at
  `.godot/verification/20261017T182957Z-bfe3a17f/` also exercises real viewport
  practice input. Themed focus/contrast and route240 checks passed.
- R1 failures retained: first direct renderer missed isolated APPDATA and failed
  before UI; correct isolated renderer passed4021 checks. Typed conditional-array
  errors in diagram/intro fixed; English720p list111px improved through compact
  spacing; temporary Prediction falsely introduced NOT, now gates on real task
  identity. Cross-audits: knowledge→narrative, narrative→visual/map,
  visual→knowledge. No claim of blind/native/human testing.
- R2: grouped full60 source/learning review identifies first-chapter missing
  evidence guidance; bounded UI implementation completed. Expanded rule controller
  checks are isolated fixtures, not earned tutorial or player comprehension.
- R2 complete: first-chapter Mission now explains baseline/comparison/application
  evidence using the existing catalog and actual current-baseline identity.
  Independent audit caught stale-context instructions; fixed and re-reviewed.
  Targeted import/isolation +5 suites passed7/7 at
  `.godot/verification/20261017T183506Z-8c774dd4/` (new guidance84 checks).
  Expanded rule viewport input passed in R1 final run. Python eleven commands now
  pass with workspace TEMP and explicitly allowed synthetic loopback; earlier
  temp/socket sandbox failures are retained separately. Baseline rendered
  map/handbook/creation passed; old Tutorial viewport ghost assertion failed1/248
  in the unchanged baseline, tracked separately from new implementation.
- R3 starting: source snapshot and fresh PNG manifests added to renderer after
  independent audit. Full regression, candidate rendered input and fixed export
  are next. No additional product scope is opened during integration.
- R3 packaging protection: accepted independent review of a fresh
  `OfflineTeammate-Night20261018` namespace, keeping Oct17 tester saves untouched
  by default. Default/custom/malformed profile and README identity checks passed
  `scripts/test-candidate-packaging.py`. Normal-progress package will use
  `NightExperience20261018`; both share the same frozen source. Actual ZIP
  extraction/embedded configuration and C/P/G restart probes added; actual
  execution remains the next gate, not inferred from the scripts.

## Final validation and recoverable checkpoints

- Frozen source: `7c4f9b58e4229864ccf29aa066de85a183d33924`.
- Full isolated Windows run at `20261017T183647Z-8abb2263` finished164/165:
  only `test_prediction_workbench_presentation` failed a hardcoded old palette.
  Its corrected1293 checks pass in final affected8/8 stages at
  `20261017T184909Z-b1c74d35`. Preserve the earlier full run as164/165.
- Eleven Python gates pass across initial/local-TEMP/loopback receipts;
  earlier environmental failures and interrupted maintenance remain recorded.
- Final renderer `cc79f97bdf50` binds source/PNG manifests. Mixed-locale completion
  and injected-map fixture counts are excluded from clean product-image claims.
  All15 rendered cases pass; final Tutorial248/248 follows actual draw completion.
- Both fixed Windows ZIPs exported/identity-checked/extracted/launched without
  retries. Tester `c9576e434284` passes32/32 first-experience checks and dependent
  `6af869c5a6cc` passes all60 foreground entries, real protected C/P/G work,
  byte-identical independent restart/recipe replay and final-only4 feedback cases
  across2 sessions. Normal `83c4a5084134` passes25/25; its C/P/G restart was not
  independently repeated. Actual package map/rules/scrolled-guidance frames
  replace misleading fixture interpretations in curated evidence.
- Exact frozen7c GitHub run39059649118 succeeds:165/165 Linux Godot stages and
  eleven Python commands. Metadata/head SHA and165 downloaded logs independently
  verified; this does not rewrite the earlier local Windows164/165 receipt.
- Checkpoints: `bf8f616` merged base → `913d51e` plan → `5b83ee6` first experience
  → `d270a16` evidence guidance → `9b2c624` save namespace → `5a7b673` palette/draw
  checks → `7c4f9b5` fixed packaging source. Use a separate checkout at a chosen
  commit; preserve the original unexplained `test_ui.gd` deletion and all player
  profiles. Runtime/model/save format remain unchanged after `d270a16`.
- `657e2a7` preserves the tested external package-frame/visibility controller;
  it does not change the fixed7c product or package bytes.
- Native Windows observation completes16/16 scoped checks on the unchanged tester:
  real tutorial drag/toggle/run/remove/reconnect, earned completion/F8, single-key
  note autosave, independent process restart and two normal exit0 results.
  Exact original note revision and workbench bytes survive. Prior-note history
  GUI restoration and long/Chinese text entry remain unverified; `Sky.type_text`
  did not insert while the ordinary `n` key succeeded. The native token is released.
- R4 engineering delivery is complete: exact package/CI/native receipts, four
  scoped image pairs, clean native completion, five human questions and recovery
  handoff. No new product scope remains; root performs final Git delivery.

## Unverified / remaining

Root's final commit/push/review-PR delivery follows this completed engineering
handoff. Both exported-controller receipts, native scope and curated evidence
are complete; native breadth is limited as recorded above.
Current Mac native, unfamiliar-player comprehension, subjective listening and
final art/narrative judgement remain outside automated acceptance. No public
Release is authorized. Full evidence and exact scope are consolidated in
`docs/verification/20261018-night-experience/README.md`.
