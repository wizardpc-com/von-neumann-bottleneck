# Night experience candidate — 2026-10-18

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

Workers do not mutate Git, run Godot, edit translations/project settings, or touch
another owner's files. Controller queues Godot and owns commits/builds. Independent
review happens after implementation; a worker reviews another worker's changes.

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
  evidence guidance; bounded UI implementation underway. Expanded rule controller
  checks are isolated fixtures, not earned tutorial or player comprehension.

## Unverified / remaining

Baseline isolated checks/rendering, all implementation, new package acceptance,
current Mac native, unfamiliar-player comprehension and final art judgement.
