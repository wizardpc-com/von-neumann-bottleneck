# Round4 playable UI implementation

Owner: audit_polish. Initial implementation READY FOR ROOT VERIFICATION.
Ownership of the following three files is RELEASED to root:

- experiments/layout_strategy/lab.gd
- experiments/layout_strategy/lab.tscn
- tests/test_layout_strategy_ui.gd

No other source, model, session, tests, docs or translations edited by this agent.
No Godot execution or Git mutation performed. Root should inspect current files;
model/session were being developed concurrently and were only read.

## Implemented behavior

- Standalone bilingual scene rejects non-QA profile paths. It does not change
  GameMode, register a task, call an official-result sink or grant completion.
  Isolation still must be configured by the launcher before autoload startup.
- Fresh Model.starter_plan() and Session.new(); no optimized recipe injection.
- Four publicly identified workloads, per-workload draft/history via Session.
  Query group and record tile are independent from physical copying. Serial
  group is fixed; one ordered job disables ineffective tiling. UI initially caps
  tile choices at actual record count while retaining any existing larger draft.
- None/full copy, four field choices, record/field-major destination presets.
  None retains dormant fields/recipe. One copied field disables ineffective
  destination ordering. Unsupported restored recipes display as retained custom
  layouts without being silently replaced. At least one copy field is required.
- Run button and keyboard Command/Control+Enter execute actual Session model.
  History shows actual Q1 response, total cycles, RAM read+write, copy scratch
  and correctness/failure. Unfinished Q1 is an em dash, not zero.
- Selecting history only inspects it. Explicit Restore is Session's one-step
  undoable edit; Set comparison chooses a valid baseline. Signed independent
  deltas distinguish tradeoff/better/worse/tied, with no fabricated weighted score.
- Comparison, Evidence and Public workload tabs. Evidence reads immutable actual
  event dictionaries; filter requests/responses, transfers or all events, select
  details/output witnesses. Public view exposes each job in submission order,
  batch/serial readiness, concrete records, memory costs, copy-only space scope,
  independent model version and condition digest.
- In-place reload_localized_scene() preserves Session, tabs, event filter/selection
  and corresponding control focus. Settings uses its existing route. Text-edit
  focus retains built-in Undo. F8/Settings/exclusive modals block draft shortcuts.
- Existing Settings and F8 are reused. No claim that the old offline-context
  adapter captures this new experiment's recipe; no official telemetry context
  is forged.
- Window minimum set to960x640 while the standalone scene is alive. Top Run,
  Undo, Redo, language, Settings and Exit remain outside the body. Session-only
  lifetime is explained once. Exit and OS-close protect actual work with a
  two-button guard, initially Keep exploring; Cancel restores exact focus.
  Escape never navigates to the campaign hub. Existing candidate_quit_owners
  prevents GlobalSave from preempting this session guard. Previous auto-quit and
  minimum-window settings restore when scene leaves.

## New test

`test_layout_strategy_ui` instantiates the actual scene and Session in an isolated
profile and uses real viewport mouse/key dispatch for buttons, text Undo, global
Settings, ordinary F8, and departure. It verifies:

- starter307/2456 and grouped531/552 results, honest signed tradeoff;
- immutable inspection, Restore/Undo/Redo and no invented runs;
- serial isolation, physical copy557/1362/80, real oversized-copy failure;
- dormant choice retention and per-workload state;
- direct and real Settings language rebuilds preserving work/focus;
- F8/Settings modal input ordering; feedback over exit guard;
- OS-close guard and cancellation;
- Chinese/English1280x720 and960x640 control bounds;
- no official Game/Test state, GameMode, protected save/challenge/record changes.

Optional user argument `--layout-strategy-capture` records six checked raw frames
per language to the isolated user directory: evidence1280, compare1280,
compare960, evidence960, public960 and quit960. Use the existing deterministic
`--capture-size=1280x720` GPU launch flag to suppress unrelated presentation
geometry persistence. Tests change root logical size alongside physical size.

## Verification performed here

- git diff --check: PASS on the current shared checkout.
- All three owned files: UTF-8 read, final newline, no trailing whitespace.
- Reviewed the authored source and Session/Model/Settings/F8 integration seams.
- Godot parser, headless/GPU suite, captures and native input: NOT RUN by agent.
  Fresh root execution is required before any working/completed claim.

Root may integrate/fix these three files now. audit_polish is available for a
focused follow-up, but will not edit them again without a new assignment.
