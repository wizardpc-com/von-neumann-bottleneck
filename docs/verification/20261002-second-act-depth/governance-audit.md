# Governance audit, 2026-10-02 second-act depth

Audit performed 2026-10-03 against committed baseline `637bcd9`, with project configuration compared to `66cc10a`. This is static governance/resource evidence, separate from the root-owned engine regression and input replay. No simulation, saves, UID files or project configuration were changed in this work.

## Historical instruction archive

Moved the two supplied root files into [the historical archive](../../archive/20260910-five-chapter/README.md), prepended prominent HISTORICAL / COMPLETED / DO NOT USE AS CURRENT EXECUTION INSTRUCTION notices, and marked the unchanged-body design duplicate historical. COMPLETED refers only to superseded historical execution scope; it does not close every original promise or acceptance item. The dated implementation plan's genuine source reference and root-location statement now point to the archive. Embedded historical instructions were inspected as source material, never executed.

The prompt's original `docs/design/FIVE_CHAPTER_FREE_ALPHA_DEVELOPMENT_PLAN.md` path remains in the preserved body and now resolves to the marked historical duplicate. Other embedded root-relative paths are dated context, not archive-relative execution instructions. External historical citations were not refreshed.

Original-body SHA-256 values (verified byte-for-byte against `git show 637bcd9:<original root path>`):

- `CODEX_FIVE_CHAPTER_DEVELOPMENT_PROMPT.txt`: `4bce705b6ac1f1426e47f89d4949df4edd1108678ad3b1384d8cbbcf84488108`
- `FIVE_CHAPTER_FREE_ALPHA_DEVELOPMENT_PLAN.md`: `ab0390927efc1eca7d8556e048002249b3d3afd45150f29a2a0a2609c37c3dd6`

## UID and resource audit

The audit read tracked blobs with `git ls-tree -r --name-only 637bcd9` and `git show 637bcd9:<path>`, avoiding untracked files and concurrent agents' work. It indexed all `.uid` sidecars plus resource-header UID ownership, validated sidecar syntax and companion paths, checked duplicate owners, and resolved every serialized `ext_resource` path/UID pair. Exact findings and all 17 newly added UID values are in [machine-readable evidence](governance-audit.json).

- 167 tracked UID sidecars: zero malformed values, zero missing companion resources, zero duplicate UID owners.
- All 17 UID sidecars added between `66cc10a` and `637bcd9` match existing tracked GDScript companion files.
- All 12 serialized external resource references resolve to tracked paths. Zero UID/path mismatches or external UIDs without tracked owners.
- Adding sidecar identity alone does not change the companion script body; `637bcd9` changed no companion script in its UID addition set.

This is static reference validity, not a claim that every dynamically constructed resource path or import/export backend was exercised. Godot import and whole-project regression remain the integrator's verification scope. No UID repair was warranted.

## Project configuration comparison

`git diff 66cc10a 637bcd9 -- project.godot` shows only the movement of `config/icon` within `[application]` and `textures/vram_compression/import_etc2_astc` within `[rendering]`, plus a blank line deletion. Parsing every explicit section/key/value assignment yields the same 33 assignments and values in both commits, with zero added, removed or changed semantic settings. Main scene, autoload paths, engine feature declaration, renderer and compression values remain identical. No configuration repair was warranted.

## Verification and limits

Original-body preservation and local Markdown targets in the archive README, design duplicate and dated implementation plan were checked programmatically. `git diff --check` passed for this governance change. The final governance diff/status was reviewed while unrelated agents' modifications remained present. No runtime or production 40-task content changes were made. Current-state, documentation-map, framework and testing documentation remain integrator-owned; add an archive navigation link there if desired.
