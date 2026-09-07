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
- Source review and publication checks found no unrelated pending files or credential signatures. Third-party font license whitespace is preserved verbatim with a path-specific Git whitespace attribute; other staged whitespace checks pass.
- Published source commit `1fef90db8debf45d69dd3973026a09763ce6fbbe` to the existing main branch by normal fast-forward. GitHub's 401 file blob IDs match the local committed tree.
- Published prerelease `playtest-polish-20260907T010358` at that source commit. Both the Windows ZIP and build manifest report uploaded, and GitHub's SHA-256 digests exactly match the local artifacts. The ZIP is 56,337,399 bytes with SHA-256 `3d93d4947328c51dab68b5f23ff3835b5b6084c775ab1c006219b6f51ecb7d03`.
- Rechecked all 21 actual player files against their protected hashes: unchanged. Local caches, backups and private player files were not published. No shared history or tag was rewritten.
- Migration delivery is complete. The separate visual-learning acceptance plan remains active on Mac: native input, Retina/High DPI, beginner understanding and release readiness are not yet verified.
