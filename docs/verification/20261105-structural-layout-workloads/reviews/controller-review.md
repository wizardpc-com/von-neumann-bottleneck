# Round7 independent controller and frozen-fixture review

Reviewer `/root/audit_scores`; read-only follow-up after releasing all model/
codec ownership. Only this report was written. No project edit, Godot/native
run, save mutation or Git mutation was performed.

**No actionable source finding was identified in the reviewed controller
changes.** The migration metadata, saved/dirty/protected semantics and use of
the frozen observations match the current contract. Runtime acceptance of the
new integrated code remains pending; this is not a passing-test claim.

## Reviewed source and evidence

Read both complete controllers, both corresponding existing controller suites
and diffs, the new controller upgrade/catalog parity suites, the frozen fixture,
its producer, corrected complete log and result receipt. Read the store paths
that produce/retain origin/copy_pending and handle first-copy/no-op/failure/
recovery; inspected the dedicated store-upgrade coverage to distinguish a
controller gap from behavior already checked at the store boundary.

| Reviewed file | SHA256 at review |
| --- | --- |
| `experiments/layout_strategy/workspace.gd` | `9aab908753308433f41723474245a2d77190722fbb3c2e469b229454d5a7c25b` |
| `experiments/layout_strategy/challenges.gd` | `2e97bc9ad7adbe3093cb86d825d3cbc1c60c4f250685ea291d21202a483c3ee7` |
| `tests/test_layout_strategy_upgrade.gd` | `4e98a7316ddba8527fe2cf5826ed830dfbf3777abe01d6be113e79dc2870ba73` |
| `tests/test_layout_strategy_catalog_parity.gd` | `64ba2de8d5528b43602582c7d7c99007c0d722ee5a282cdbd621df6615fd969b` |
| `tests/test_layout_strategy_workspace.gd` | `7645609696b70cd81ba58863e5205376d695edd7ae4ff40794ba87afc2f3647c` |
| `tests/test_layout_strategy_challenges.gd` | `7bc249cb54dcd0b155ba3f1bf23dfecd59262c24f6bb49cdbb9eff9a389a165f` |

## Controller state review

- `workspace.gd:20–48` passes explicit legacy override to Store, observes its
  metadata before restoration, adopts only a successful snapshot and establishes
  saved assurance only for an actual current payload. The initial `_committed`
  snapshot is a comparison baseline, not a claim that v2 exists.
- `workspace.gd:50–68` creates independent defaults for six task contexts and
  preserves the active task after snapshotting. `copy_pending` alone makes a
  valid legacy workspace dirty; detected read-only protection suppresses cached
  saved assurance. Existing transient runs/Undo are not copied into persistence.
- `workspace.gd:70–79,155–164` observes every write/recovery result. A failed
  first copy retains origin/pending metadata; success updates `_committed` and
  `_has_saved` only after Store reports actual commit. Recovery itself does not
  clear pending-copy work. Existing keep/remove proposal semantics remain.
- `challenges.gd:18–48` keeps loaded legacy codes active after real inspection
  but reports them pending/unsaved until current commit. A valid empty legacy
  map has controller-level `copy_pending` even though there is no individual
  target to mark pending. This matches the frozen API.
- `challenges.gd:59–101` continues to save the exact proposed full target map,
  including replacement/removal, through its independent Store. Accept/clear
  cannot save the Notebook. Both `_targets != _committed` and pending migration
  participate in dirty state. Saved metadata survives neither an outstanding
  proposal nor detected read-only conflict.
- `challenges.gd:104–134` reconstructs current attempt output/metrics/events
  and verifies complete Trace identity before comparing. Stored row numbers
  remain non-authoritative; new task IDs cannot compare with an old condition.

Protected legacy files adopt no partial state at the Store boundary, so fresh
controllers start with empty/default temporary proposals and no saved claim.
If the user subsequently creates a temporary plan or target, existing proposal
comparison makes that work dirty without overwriting protected bytes.

The Store result contract includes origin/copy_pending on failure and recovery.
Replacing handcrafted failure dictionaries with `_failed("write")` in both
existing controller test doubles is correct: it keeps these metadata semantics
under the same implementation as real refusals rather than silently resetting
them through `_observe()` defaults.

## Fixture strength and source provenance

`tests/fixtures/layout_strategy/legacy-scheduling-v1.json` is193217 bytes,
SHA256 `d32b7c69a76d2a8a941f7f433a44f2206f6a05a7248c9bb40add54b445e5c289`.
It contains exact four normalized tasks,56 observations (17/11/17/11 for
scan_batch/scan_serial/mixed_batch/mixed_serial),112 code outcomes and both
actual canonical v1 input strings.

The Notebook string is4519 UTF-8 bytes, version1, active scan_serial, with all
four states and two named recipes per state. The target string is1753 bytes,
version1, with all four task-matching canonical codes. Thus the main controller
upgrade test starts with actual saved values rather than constructing a
current-shaped object and merely changing its version number.

I read the corrected freeze producer, full log and
`.godot/collaboration/round7-frozen-baseline-result.json`: it reports exit0 at
2026-11-05T05:51:16.179226Z under the isolated
`VonNeumannBottleneckChecks/20261105-round7/frozen-baseline-corrected` profile.
The producer obtains real Model/Code results, writes both input files through
the old Stores, then records their actual strings.

I independently compared the still-frozen QA Model, Goals, codec and both
Stores with Git object `e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8`; all five files
are byte-identical. This supports the historical origin of the fixture without
claiming I ran the producer. QA path:
`.godot/verification/20261105T051242Z-1f038f6c/project`.

`test_layout_strategy_catalog_parity.gd:39–64` checks the captured base, exact
task dictionaries, case/plan identities, complete canonical Trace hash, all
metrics, ordered actual/expected outputs, export eligibility/reasons and exact
canonical code strings. Expected observations are not recomputed from new code.
The fixture includes failed allocation outcomes as well as successful plans.
The56 representatives are a declared bounded compatibility sample, not an
exhaustive enumeration of all valid recipes.

## Test coverage review

`test_layout_strategy_upgrade.gd:38–68` covers actual v1 read/no-v2-write,
pending-copy truth, old inputs, empty transient/new task state, preserving
Notebook state during new-target preview, unchanged first target-copy commit
and independent sidecar saves. Lines69–98 retain two real new recipes, change
the personal objective, verify the resulting rank reversal, retain target
rules and compare against a remeasured full Trace after reopening. The
`kept_rows()[0]` expectation is valid because `Workspace.kept_rows()` returns
`Goals.rank(...)`, with the saved traffic goal selecting the actual copied run.
Lines99–108 check authoritative empty v2, no v1 target resurrection and
unchanged formal progress.

The current controller regression preserves explicit failed replacement/
removal retry and external-conflict/deletion cases; Workspace adds an assertion
that conflict withdraws saved assurance. The dedicated store-upgrade suite
separately covers pending metadata through actual I/O refusal, source/destination
changes, empty first copy, live/stopped writer handling and independent
partial migration. There is no need to invent a controller-level storage
abstraction to repeat that logic.

The core controller upgrade test is a happy-path integration check. It does
not itself establish real separate-process recovery or frozen-old-runtime
rollback, which remain explicit root acceptance steps. The native/UI/renderer
and full six-condition retained-capacity gates also remain separate.

## Handoff

Source review is complete and released. Run the updated controllers,
`test_layout_strategy_upgrade`, `test_layout_strategy_catalog_parity` and the
store-upgrade suite in a synchronized isolated QA copy, then inspect complete
logs. No new source repair is requested by this review. Do not interpret this
static conclusion as a parser/test/runtime pass or as cross-platform acceptance.
