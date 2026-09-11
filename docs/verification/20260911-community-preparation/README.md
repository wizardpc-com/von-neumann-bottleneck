# Community preparation evidence

2026-09-11, Godot 4.7.1, Mac Apple Silicon, no public service or real identity data.

- Baseline main 8eee3b3; two user-owned root planning files preserved untracked.
- Stage 1 b0e0bc2: migration, backup/restore/merge and tombstone checks pass.
- Stage 2 449b17b: consent tiers and visit reducer. Initial isolated conventional
  run `20260911T052853Z-f655f5b7` passed all then-existing suites; targeted new
  summary test also passed after additions.
- Stage 3 f1532d0: personal record page and community/experimental score API.
  `20260911T053828Z-458ce981` passed all conventional suites at that checkpoint.
  Personal-record targeted test passed after adding independent local result signal.
- [Actual loopback lifecycle](loopback-result.json): three queued records become
  one event, one opinion and one score after restart and duplicate delivery. The
  score is evaluated by a development client fixture: 2495 total cycles, 960 B reads,
  272 B writes, 32 B peak; server only checks fields. Source automated, mode test.
  Deletion persists while offline, then removes all three records on restart.
- Expanded pass `20260911T054532Z-eb38452d` initially exposed incorrect reuse of a
  circuit-graph signal on the separate SystemGraphEdit. That failed check is retained;
  it is not acceptance. The first-chapter interface has been restored for the rerun.

Native observations and final reruns are added below as performed. Automatic input
replay is not novice or Windows acceptance. Docker/Caddy/systemd binaries are absent
on this Mac, so their supplied configuration examples have not been executed here.

## Final native pass and corrections

Ordinary Game, separate `community-native-20260911` QA profile, Mac M2 / Godot
4.7.1, native computer use. No actual player profile was opened or replaced.

- Chinese hub → task tree → records: all 40 tasks, 33 main / 7 optional, five
  bonus objectives, five regional filters. Unfinished-task opinion saved locally;
  unconfigured remote controls stay unavailable and no network queue is created.
- Manually finished the original Tutorial: an invalid output-to-output drag,
  three successful connections, one explicit erasure, Cmd-Z, Cmd-Shift-Z and one
  practice run. [Recorded summary](native-tutorial-summary.json) matches those
  actions: one rejection, one undo/redo each, one debug run, zero formal tests.
  Completion unlocked the existing arithmetic/storage roots and records became
  1/40 with one saved workbench. English restart preserved this result.
- F11/window resizing, record-list scroll, feedback Escape/focus restoration and
  settings were exercised. Reduced motion and 120 FPS persist together across
  restart. Physical Retina scale comparisons and Windows native remain open.
- Native map Escape exposed a null viewport after scene removal; input is now
  consumed before transition. Targeted real-scene regression passes.
- English cards initially pushed the fifth region offscreen and later crowded
  the footer. Wrapped headings/buttons, smaller card titles and adjusted padding
  now show all five cards and footer in the native window. English records and
  settings also inspected. Locale changes revealed a freed feedback-button
  callback; bindings now disconnect on scene exit and the rerun is clean.
- Third-chapter endpoint movement now validates before replacing a wire and is
  one undo transaction; rejecting a target cannot destroy the original wire.

## Final checks and limits

After the documented initial failure, targeted System Lab, overlap UI, task tree,
personal records, localization, playtest data/visits/summary, remote transport,
feedback UI and bilingual display preference checks pass. Logs are retained in
`.godot/community-final-checks/`. Expanded ordinary Game Chinese input replay
reported 602 checks with zero failures; it is automated replay, not native player
acceptance. Storage tests include atomic DDL rollback; community HTTP tests pass.
Final loopback run `8d4ff603-3a39-43e4-bd39-4a48fb0b15c4` passes against the final
consent validator. The server does not run Godot. Exit phases finish without waiting
for an unavailable server; confirmed deletion leaves no event rows and a tombstone.

The current native pass covers the changed UI and Tutorial transactions, not a new
full 40-task playthrough. Prior five-region acceptance remains in its dated record.
No public service, credentials, identity, purchase, DNS or Steam action occurred.
Docker/Linux service startup, public load/latency, actual Windows rendering and
external beginner comprehension are not established by these checks.

## Frozen delivery

Content `6942a61ccdbc20d713bc6a85acf244c05a0387df`, output
`build/free-alpha-20260911T062216Z-6942a61c/`, Godot 4.7.1. Both export logs
have no errors/warnings; archives pass ZIP CRC and include per-file manifests.
[Archive hashes](candidate-manifest.json) and [package checks](package-checks.json)
are retained here. Actual Mac release binary probe passes in a copied QA app:
40 tasks, Game-only, developer captures disabled, default remote off, no test/server
resources, isolated userdata. Windows file is x86-64 PE GUI; it was not executed
on Windows. These package checks do not claim a native exported full playthrough.
