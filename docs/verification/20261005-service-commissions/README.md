# Optional Service follow-up candidate content — 2026-10-05

Two optional commissions extend the earned three-contract Service workbench.
One-slot duty changes residency and request-order decisions. Archive handoff lets
players choose lossless or compact quality requirements while checking the actual
final archive, separately from cumulative state traffic. The original ending,
core40, model/workload, candidate schema2 and Prediction route remain unchanged.

[Plan](../../exec-plans/completed/service-followup-commissions.md) ·
[Run and save instructions](../../../experiments/service_plan/README.md) ·
[Exact results, receipts, observations and image SHA-256](results.json)

## Scope and source

Baseline `ecda15f`. Implementation `7f056c2`; runtime entry/recovery correction
`4b73826`. Subsequent commits change the QA actuator and evidence only: `0c6752c`,
`16a417f`, `87f9a91`. No runtime implementation changed after `4b73826`.
The root coordinated Git/Godot/GUI serially; a service subagent owned only the new
catalog/test, and a different subagent performed a read-only integration review.
Pre-existing collaborator files were not staged or committed.

All tests use the pinned official4.7.1 stable engine on Apple M2. Production player
saves are never read or written. The final viewport profile is
`VonNeumannBottleneckCandidates/service/commissionQA-20261005-final`.

## Fresh verification

| Layer | Frozen source | Result |
|---|---|---|
| Full committed-source regression | `7f056c2` |74/74 checks PASS: import, isolation probe,72 conventional suites;1767 files matched; clean before/after |
| Entry/recovery correction | `4b73826` |Affected UI27 and session63 checks PASS, plus import/isolation and source parity |
| Chinese visible editing/Save/Home/re-entry | `16a417f` |305 checks,0 failures;1280×720 window, default1600×900 canvas |
| Independent English restart | `87f9a91` |31 checks,0 failures; true1280×720 canvas/window, original ending and all three specifications revalidate |
| Plain native Mac app | `87f9a91` |Saved9 records visible; Cmd-Q exits0; native pointer BLOCKED |
| Exported candidate package | — |NOT_RUN; matching export templates absent |

Full frozen receipt:
`.godot/committed-verification/20261005T195912Z-a09be06a/receipt.json`.
Correction receipt:
`.godot/committed-verification/20261005T200129Z-710e4769/receipt.json`.
GUI logs: `.godot/commission-zh-final.log`, `.godot/commission-en-resume.log`.
Both GUI copies match all1767 tracked source files, with only the documented
launcher custom-user-directory and candidate context settings differing.

Known-answer plans are authored in QA only. Actions go through actual viewport
GUI dispatch; no accepted/completed flag, model plan setter or reference loader is
used for these acceptance paths. This establishes rendered interaction and process
resume, not native OS pointer input or novice comprehension.

Native CUA saw the plain saved workbench. Clicking the visible follow-up entry
returned `Computer Use server error -10005: noWindowsAvailable`. We did not alter
security permissions or count this as native pointer acceptance. Cmd-Q then exited
the tested candidate normally, with no runtime errors in
`.godot/commission-os-native.log`.

## New measured decisions

| Own measured recipe | Cycles | First A/B/C/D | Final archive | Relevant result |
|---|---:|---|---:|---|
| One slot, mixed lossless, initial responses then stream tails |1412|78/147/227/318|158B|Duty passes with zero error;632B cumulative state traffic does not pass the original final contract |
| Four slots, interleaved mixed lossless |1280|78/136/205/274|158B|Lossless archive passes; duty fails its one-slot requirement |
| Four slots, interleaved RAW8 |1236|76/132/188/244|40B|Compact archive passes with actual nonzero error |
| Four slots, interleaved RLE8 |1256|77/134/194/254|52B|Another compact solution;104B cumulative state traffic; score error≈0.004695, final-state error≈0.006158 |

The archive variants are alternatives: lossless≤160B with both errors≤1e-9, or
compact≤64B with both errors≤0.02. Both require≤1420 cycles and every first response
≤320. There is no mandatory low-precision story answer. A selected measurement
remains explicit when its draft changes; handoff acknowledges the recorded plan.

## Failure evidence and repair

The initial4b73826 viewport run FAILED when the root-coordinate actuator missed
Continue in an embedded dialog, blocking later controls. The0c6752c retry also
FAILED its newly added close assertion. Neither is acceptance evidence.
A short isolated dialog probe located the missing embedded-window position offset;
the repaired probe closes through an actual Continue click.16a417f verifies closure
before every later action. Failed logs remain locally preserved and are enumerated
in results.json; no assertion or gameplay budget was weakened.

## Screens and remaining gates

[One-slot duty](one-slot-zh.png) · [Lossless archive](lossless-archive-zh.png) ·
[Compact archive](compact-archive-zh.png) · [Measured handoff](handoff-zh.png) ·
[English minimum canvas after restart](restored-en-minimum.png).

Optional selection is window state; saved recipes can be rechecked after restart.
The existing latest80-record retention applies, so optional commissions have no
permanent badge. Original protected three-contract support is unchanged.

Native pointer/newcomer play, packaged acceptance and audio remain unverified.
The approved push is still blocked by missing local GitHub HTTPS authentication;
all commits remain on `codex/mac-second-act-20261005`, with no main merge or history
rewrite. Next: authenticate Git, push this branch, and get a bounded unfamiliar-player
pass through the existing service journey/commissions before deciding on an extra
state introduction or formal registration. This iteration stops at these two requests.
