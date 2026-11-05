# Comparable records and recoverable best experiments

Date: 2026-11-04. Owner: Codex root. Branch: `codex/gameplay-systems-20261104`.
Starting point is the uncommitted first gameplay increment on `b65a0bd`;
its dated verification remains historical and is preserved.

## Player outcome

Continuing to experiment should not discard a player's fastest correct design.
Personal results must use the metric actually produced and must distinguish
different rules or workloads. Chapter 2 should let players resume their retained
best experiment without retyping it, preserve their current draft for undo, and
require a fresh run after restoration.

## Findings and selected changes

- `PersonalRecords._observe` compares `cycles`, but later domains emit
  `total_cycles`. Missing values currently become zero, and missing case identity
  is compared as `"unspecified"` without being retained.
- The separate local result signal lacks the default identity attached to ordinary
  event records. Fix this while retaining telemetry-independent local observation.
- Locality receipts are bounded to 12 and saved observations to 32. Current eviction
  preserves teaching checkpoints and recent experiments, but not the fastest
  correct experiment. UI history can consequently forget its earlier best.
- Keep fastest correct experiments per exact workload, along with existing teaching
  checkpoints and recent work. Replay saved recipes with the existing simulator;
  saved numbers are never authority.
- Add an explicit restore-best action and a reversible restore operation within the
  existing Profiler/history area. Preserve raw unfinished text and configuration.
  Respect level choices, capstone diagnosis and first-experiment gates.

Three agents audit metrics/producers, locality retention, and record presentation.
Root will finalize file ownership before edits and alone runs Godot/Git.

## Compatibility and rollback

No simulation, target, campaign prerequisite or completion-rule change. No common
cross-domain aggregate score. Personal journals remain presentation-only.
Existing global-save observation arrays and workspace structure are retained;
Test observations remain transient and separated from Game.

No automatic reinterpretation of unknown historical metrics as comparable current
records. New current measurements can replace a display record under explicit
conditions; creation remains historical observation rather than cost competition.
Legacy records remain readable without manufacturing a missing model/workload.
The presentation-only personal journal retains its path, schema 1 and `best`
projection. Optional bounded `conditions` and `legacy` fields preserve distinct
workloads and old summaries. This does not alter the global player save. An older
reader can still read `best`; an older writer will drop those new journal fields
on its next write. Rollback therefore retains a copy of this journal if continued
multi-condition history is wanted. Unknown/future or corrupt files are write
protected; no automatic repair overwrites them.

Rollback removes the new readers/restore action and returns to the prior eviction
policy. Existing saved recipes stay ordinary observation/workspace dictionaries,
readable by the earlier implementation; no player-data deletion or migration is
required. More extensive storage changes need a separate impact review.

## Verification

Use Godot 4.7.1 isolated copies/profiles, sequentially. Tests must exercise real
simulator outputs, exceed both retention bounds, reopen through JSON, preserve
checkpoints, isolate pass counts and modes, reject stale models, and prove restored
drafts/undo cannot grant completion.

Record tests cover `cycles`/`total_cycles`, worsening and improving observations,
model/case changes, unknown metadata, telemetry disabled, legacy reload and
non-comparable creation results. Run relevant journal/map, playtest, workspaces,
locality UI, save, localization and previous-increment regressions. Inspect actual
Mac GPU presentation/input within the reported acceptance scope.

## Progress

- Current branch/status/handoff and relevant implementations/contracts re-read.
- First increment preserved. Three read-only audits completed and retained under
  `/private/tmp/vnb-round2-*-audit.md` for integration.
- Round-2 baseline: personal records, release convergence, chapter workspaces and
  locality trace presentation passed at `20261104T194517Z-89654450`.
- Disjoint ownership assigned: record contracts/producers; locality state/retention;
  archive Game projection/presentation; root main UI, translations and integration.
- Implementation complete within this bounded increment. Root integrated and
  reviewed all three implementation workstreams; agents released their files.
- Independent final review found nested corrupt journal entries could be silently
  removed before a later write. Full validation now protects original bytes;
  the expanded real-measurement/persistence suite passes 97 checks.
- GPU acceptance exposed a pre-wrap feedback panel height retained in a small
  review Window. A deferred refit fixes that existing path; bilingual geometry,
  input visibility, Tab/Escape and focus return pass.
- Final runtime QA copy: `20261104T203308Z-530aab9a`. Import/profile pass; retained
  best83, restore75, conditions97, projection56, journal175 and four related suites
  have passing final observations. The projection fixture was corrected to resize
  the logical viewport with the physical window, then rerun successfully.
- GPU: restore77, projection60, journal/feedback256, settings/feedback154 pass.
  Original images, full failures/fixes, reviews and 1130-file source match are in
  `docs/verification/20261104-comparable-records/README.md`.
- 24 related headless suites have passing latest staged observations. This is not
  a final full-repository regression, exported package or cross-platform claim.
- Native round-2 input was not executed because the Mac was locked. Only isolated
  fixture preparation ran, then root stopped the owned process. It remains an
  explicit acceptance limitation, together with newcomer play and long sessions.
- No commits, staging, push, release or real-player-data access. The broader user
  goal continues; challenge persistence/sharing and bounded model experiments
  remain in the gameplay audit queue, with disputed prior designs preserved.
