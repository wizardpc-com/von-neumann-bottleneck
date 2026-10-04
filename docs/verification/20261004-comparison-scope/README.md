# Read measured timing and cost on the same scale

Baseline `63057c277c2c4b20b9b8acc1450bb1139b00e9c7`, existing
`ray/representation-playloop-20261003` branch. Presentation-only follow-up to
[recorded hardware cost](../20261004-performance-cost/README.md).

## Native finding

Developer-informed Linux cloud play used official Godot 4.7.1 at 1364×1024.
A copy of the previously UI-earned profile continued through RAM, Bus and the
final bottleneck investigation. The source profile remains byte-identical.
No reference circuit, injected solution or completion setter was used.

- RAM: two cases each changed 134 → 62 cycles. History showed the combined
  268 → 124, CPU WAIT 252 → 108, and machine cost 30 → 39.
- Bus: one case changed 144 → 96 cycles, data-transfer time 64 → 16,
  with machine cost 30 → 39.
- Final: the 4/16/64 workloads took 112/448/1792 cycles, sum 2352,
  with CPU WAIT 88/352/1408, sum 1848, and machine cost 21.
  An incorrect CPU diagnosis revealed the breakdown without completion;
  RAM's 57% share supported the corrected diagnosis and earned Chapter 2 access.
- After diagnosis, a Fast RAM experiment measured 1680 total cycles and cost 27.
  An unrun part selection retained the previous official evidence correctly.

The gap was the scope of those numbers: History never explained why its 268
was twice the Test Bench's 134 while hardware cost remained 30. The final
single-machine heading also said “CURRENT EVIDENCE” even after selecting an
unrun alternative.

## Change

History now states the number of official cases per run, that cycle figures
are summed, and that cost is per machine. The count comes from the same stored
receipt as the displayed comparison endpoint or observation. The final label
now says “RECORDED OBSERVATION” / “已记录的观测”. No timing, comparison pairing,
receipt deduplication, prediction, diagnosis, completion or save rule changed.
All five regions and 40 tasks remain intact.

## Verification

- `test_system_cost_evidence`: 158 bilingual checks pass, including one-, two-
  and three-case scope, recorded cost, unrun selection, one-case debug, unapplied
  drafts, duplicate reruns and diagnosis boundaries. The final suite against
  baseline runtime fails 22 checks, exit 1, at the missing scope/caption.
- An early test asserted equality of the whole final History after a part change.
  Independent review and the focused run caught that existing invalidation clears
  active workload rows. The test now checks the retained receipt-backed caption,
  scope, totals, wait, cost and signature without changing runtime invalidation.
- Full isolated run `20261004T224852Z-38cd4e79`: 69 conventional suites plus
  import/user-directory isolation pass (71 stages). All five Python CI commands
  pass, as do isolated normal / Test / reset startup smokes. Independent final
  review found no blocker. Runtime, localization and test source identity is checked against the
  actual imported full-suite copy.
- The first verifier launch omitted writable Linux XDG directories and failed
  environment import. The corrected isolated invocation passed; that failed
  launch is not counted as runtime acceptance.
- Native restart preserved earned RAM/Bus/final completion and Chapter 2 access.
  Fresh official measurements repopulated History. English RAM baseline and
  comparison, Chinese RAM comparison, and the final three-case recorded
  observation in both languages were inspected. Language reload retained in-session evidence.
  Unrun Eco CPU selected cost 24 while History kept the measured Balanced CPU /
  Fast RAM observation at 1680 cycles and cost 27. Both owned native sessions
  were saved and closed through Quit Game.

## Limits and next observation

This is informed Linux source QA, not novice comprehension, Windows/macOS,
exported-package, HiDPI or audio acceptance. The native environment retains its
unsupported V-Sync and ALSA-to-Dummy warnings. No merge, release or deployment.

The earned profile can now continue the Chapter 2 handoff. Separately, long English
completion feedback and optional chapter-map subtitles appeared to extend beyond
compact desktop bounds during baseline play; reproduce and scope that existing
layout issue before any follow-up change.
