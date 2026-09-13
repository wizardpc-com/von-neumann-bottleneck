# Maintaining the free Alpha

Current truth: [CURRENT_STATE](../CURRENT_STATE.md), [release blockers](../../RELEASE_BLOCKERS.md).
Keep five areas, 40 tasks and their existing save/verification rules. These recipes
are deliberately separate: replacing art must not change progression or consent.

## Replace the future logo and icon

1. Put final assets in `assets/branding/`. Edit only `brand.cfg`: `logo_zh`, `logo_en`,
   optional `symbol`, required `app_icon`, optional platform-native icon and revision.
2. Run `python3 scripts/check-branding.py`, then isolated `test_final_convergence`,
   localization and normal Godot import. Missing language logos fall back to that
   language's title; no alternative-language logo is silently substituted.
3. Inspect Chinese and English at the minimum window size. Logo is contained within
   360×64 logical pixels and ignores input. Check 16/32/48/64/128/256 icon variants.
4. Commit assets and build a new candidate with `build-free-candidate.py`. The builder
   reads that config, checks local assets and records revision in the manifest.
   Inspect EXE/taskbar and app/Dock on actual Windows/Mac; OS icon caching can lag.

Never change `application/config/name`, bundle identifier or the userdata directory
for an art replacement. The project icon setting is the existing fallback; the
runtime window and frozen export take their override from the single brand config.

## Configure the future receiver

Follow [server setup](../../server/README.md) and
[feedback architecture](../architecture/community-feedback.md). Choose a stable HTTPS
API root through the existing `application/feedback_endpoint` setting. Keep secrets
server-side. The current public candidate must retain an empty endpoint.

Before owner deployment, run synthetic `test_receiver.py`, `test_storage.py`,
`test_community.py`, `test-report-playtests.py`, `verify-feedback-local.py` and
`verify-community-local.py` against the isolated imported project. Migration must
retain client/deletion identities and tombstones, not just event rows. Verify backup,
restore, deletion, offline retry, and no backfill after a consent/endpoint change.

Basic summaries carry measured totals, not a made-up timeline. Reports separate
source, mode, task/model/case versions, build and declared batch/background. Unknown
legacy fields remain unknown. Community first-completion rates exclude already-done
visits and hide small samples; mixed versions do not share a rate or median.
Detailed queue pressure may discard lower-priority records; local diagnostics expose
eviction/rejection totals. Written feedback and scores retain independent consent.

DNS, HTTPS, retention policy, privacy page, provider purchase, account details and
public deployment belong to the owner. No online deployment is part of this update.

## Adjust one task

Start with the generated [task matrix](task-matrix.md). `TaskNavigation` and the five
catalogs remain the source of prerequisites and task identity. Update the relevant
catalog/cases, its existing evaluator, and both localization catalogs. Preserve
player drafts; replay receipts against current model/source identities instead of
trusting serialized scores. Change model/case/rules versions when their meaning changes.

Run the task's listed suite plus content/localization/tree/save tests. For an open
construction/optimization task, operate one valid alternative and one failing or
overspending attempt. Check Hint tiers independently and record actual results.
Regenerate the matrix in an isolated imported project:

```
Godot --headless --path <isolated-project> --script res://scripts/export-task-matrix.gd -- --output=<absolute-output.md>
```

Use the exact 4.7.1 executable, not a system engine of unknown version. Copy the output
into this directory after checking it. A generated row is not a native acceptance tick.

## Save failure and recovery

Chapter 1/2 drafts, applied programs and configuration are separate. Only an explicit
Apply replaces the applied program. Current-model observation recipes are replayed;
loading a draft never completes a task. An old-model draft is kept with a warning and
its previous configuration remains under `previous_version` in the local snapshot.

A normal save failure keeps the game open and offers an independent recovery JSON,
or an explicit quit without saving. Recovery includes progress and available in-memory
workbench data. It is a local support file and can contain full player designs; do not
upload it through telemetry. Copy original save files before any manual recovery.
A recovery JSON is not itself a normal save: inspect `progress` and workbench manifests
with the matching/current writer in an isolated profile, then test restart before
replacing the owner's files. It never bypasses a future-writer read-only guard.

## Freeze a candidate

Commit the verified runtime first. Run `build-free-candidate.py --godot <4.7.1> --commit
<full-commit>`. It exports the committed Git archive, sets the full content identity,
binds workspace fingerprints before bytecode export, and derives native numeric
versions from the commit's revision count. Full Git identity remains authoritative.
Existing candidate directories are immutable. Run `check-candidate-identity.py` and
`verify-mac-candidate.py` on the new output, then native installation/input checks.

CI runs existing synthetic contracts and isolated engine suites, never deployment.
Its first hosted run and every native platform gate remain explicit evidence items.
