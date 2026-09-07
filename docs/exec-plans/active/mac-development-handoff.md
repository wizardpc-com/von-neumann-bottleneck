# Mac development handoff

## Scope

Publish the current original-game recovery and visual/learning improvements to the existing GitHub repository. Mac becomes the primary development and native-playtest machine; Windows remains the compatibility and exported-EXE verification machine. This request explicitly authorizes committing and pushing the reviewed game changes. It does not authorize history rewriting or player-data publication.

## Steps

1. Preserve the supplied index and working tree, inspect the remote and pending changes.
2. Add concise Mac setup/continuation guidance and a portable, isolated verification command. Preserve source resources, font license, tests, screenshots and representative verification evidence.
3. Verify from a fresh project copy, review the final publication set, commit and fast-forward push to the existing main branch.
4. Upload the existing uniquely identified Windows candidate as a GitHub prerelease asset, verify remote commit/asset identity, and report Mac/native acceptance gaps.

## Invariants

Original default progression, free editor, separate Hint levels, simulation, source validation and save contracts stay unchanged. Preserve historical comparison content. Do not upload .godot caches, workstation backups, credentials, telemetry or actual player saves. Do not upgrade Godot or invent a macOS verification result.

## Progress

- 2026-09-07: HEAD is 76ef116; remote main is d7aa2f1. The local intermediate commit contains only the retained eight-task game work despite its unrelated-looking title. It will be preserved as history.
- Backup `.godot/migration/20260907T094906/backup/` verifies 364 current workspace files and captures both binary patches, HEAD and status.
- Current candidate remains `polish-20260907T010358-76ef116`. Native Windows input was blocked by the lock screen; Mac playability is unverified.
- Mac handoff guidance, a portable isolated verification helper, preserved feedback screenshots and selected portable evidence are ready.
- Fresh-copy Windows verification passes resource import, actual user-directory isolation, all 20 conventional suites and 127 Tutorial GUI checks. Two tests now create/check their required output directories; no behavioral assertions were removed.
- Source review and publication checks found no unrelated pending files or credential signatures. Commit/push and GitHub prerelease upload are the remaining handoff operations.
