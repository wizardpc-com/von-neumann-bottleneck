# Candidate lifecycle and representation journey — 2026-10-04

## Source and boundaries

Baseline: `6709dda235f1d368b6d12353c4ef054cedd4380f`, existing
`ray/representation-playloop-20261003` branch. This milestone repairs candidate
persistence and closes the existing representation journey; it does not merge,
release, change VPS production, register new formal content or change core40 saves.

The tested source is fixed by [452-file SHA-256 manifest](source-sha256.json).
The native imported copy is `ab88295795af`, prepared from that exact source.
Only the two documented custom-user-directory settings differ in its project file.
The final source-run build's adjacent `BUILD-MANIFEST.json` records its exact Git
commit and checks every runtime file against this manifest. Source/native operation
and standalone export are explicitly different: this milestone delivers a runnable
Linux **source-run** candidate with the installed Godot 4.7.1 runtime, not a signed
Windows/macOS package or Linux template export.

## Automated evidence

Final full verifier: `20261004T112039Z-f648052f`, Godot
`4.7.1.stable.official.a13da4feb`, Linux. **62/62 stages pass**: import, isolated
user-directory probe and 60 conventional suites (not the separate ordinary-Game
GUI replay). [Machine-readable results](regression-results.json),
[complete retained logs](regression-logs.zip), [Python gates](python-gates.txt).
All five required Python commands pass: branding, report-playtests, server storage,
receiver and community contracts. Server checks use synthetic local data; they
are not VPS/Docker/Caddy/public deployment acceptance.

Focused lifecycle suite: **201 checks / 0 failures**. It covers first save and
replacement with an existing backup, interruption after temporary write, validation,
archive, main-to-backup and install, explicit recovery, repeat save, corrupt/future
main, unknown replacement field, changed recovery fingerprints, partial archived
copies, profile-wide lease ownership, separate-process exclusion, actual abrupt
termination and competing recovery claimants. Foreign boot/PID-namespace identity
is refused. The support/journey suite passes **35 checks / 0 failures**, including
all five representation and three service successes, 105/85 further failed runs,
restart, preserved successful supports, independent unfinished drafts, protected
plan retrieval, hub entry scope, region review and unsaved recovery/return-home.
Existing session, model, layout and localization regressions also remain green.

## Independent safety review and real counterexamples

Independent reviewer reproduced two concrete edge failures before closure:

1. An interrupted archive copy left a partial hash-named snapshot. Recovery had two
   valid candidates but returned `ERR_FILE_CORRUPT`. The final implementation copies
   to a unique partial, verifies it, then installs; damaged old archives are retained
   under quarantine names. The original isolated repro now recovers successfully.
2. Releasing the stale-owner recovery gate before reacquisition could let two
   claimants both fail safely, leaving no writer. The final combined operation holds
   the gate through acquisition; no ownerless gap remains. Independent re-review
   found no double-live-writer breach.

The reviewer also required recovery choices to refresh after an in-window save
failure. Both scenes now rebuild only controls and keep the draft/history; selecting
recovery asks before replacing unsaved exploration. Scene regression directly
exercises service; equivalent representation code was reviewed, with its existing
session tests still passing. This is a stated coverage boundary, not a claim of
exhaustive interleaving/power-failure proof.

## Native input evidence

Native cloud Linux source-run QA, Chinese, 1364×1024 fullscreen, 2026-10-04
11:13–11:30 UTC. All interactions used actual pointer/keyboard input, not controller
method calls or injected progress. Named profile `audit-native-20261004-1113` is
isolated from real player saves. Known-solution assistant input is not novice
understanding, enjoyment, subjective sound or release acceptance.

- Hub → representation; R1 first failed at166cycles/80B, then a three-block
  RLE/RAW/RLE plan passed134cycles/52B. Home prompted for unsaved work; cancel kept
  editing, then Save-and-leave returned to the hub. Relaunch restored both records,
  draft and checkmark.
- R2 passed34cycles/52B; R3 passed113/38cycles and26B; R4 passed105/888cycles and76B;
  R5 passed130/36cycles and48B. Each was constructed through the existing controls.
  R4 short order reported preparation88 + service17, source-read56B/write12B,
  57 encode operations, and76B preparation peak.
- Region review showed all five measured costs and correctly warned before saving.
  Explicit save, Home, candidate Exit and new-process relaunch preserved selected
  R5, all five checkmarks, six history records and the exact48B draft.
- Changing R5's first block to RAW produced a62B draft while the48B old record stayed
  labeled as different. Restore protected successful plan recovered the exact48B
  draft; another explicit save and review showed saved/resumable status.

[Retained synthetic native QA save and raw logs](native-qa-evidence.zip). Final save
SHA-256: `367eb2e6c94caebe6c7020230be5715434ffeb3b3378b44eeeae8d8c84f77131`.
It has schema2, selected task4 (zero-based), six recent runs and five protected
supports. Raw playtest logs do not encode every pointer action. Screenshots were
rendered/inspected in tool history; **no durable screenshot files were captured**,
so this record does not imply a screenshot archive. The application log records
unsupported V-Sync and ALSA→Dummy fallback; no listening claim is made. A bound
Alt+F4 input did not close the window; the verified clean quit used candidate Exit.
No blocker was observed on this native path.

## Remaining bounds

- Filesystem/PID recovery is tested on Linux only. Windows/macOS clean lease paths
  are not native-tested; stopped-owner recovery remains disabled there.
- Foreign/unknown ownership, interrupted owner creation or a crashed recovery gate
  conservatively block writes. Preserve the profile and review ownership before
  an operator moves a lock aside; never clear saves to test.
- No claim of power-loss fsync durability, network filesystem or multi-host support.
- Already-evicted successes from old schema1 cannot be invented. Retained schema1
  evidence migrates only on explicit save, with original bytes preserved.
- The existing deployment templates remain a separate delivery responsibility.
- No outside players, recording/data collection, subjective listening, public release,
  main merge, new models, task quota or altered core ending are part of this work.
