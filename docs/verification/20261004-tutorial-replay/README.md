# Earned tutorial completion on replay

Baseline `6dfafb26d0d481b133cfb71ae716e4ef971d754f`, existing
`ray/representation-playloop-20261003` branch. Bounded presentation correction;
no simulation, valid solution, prerequisite, save schema or core40 changes.

## Native reproduction and change

Ordinary Game, fresh isolated profile, Linux cloud desktop, official Godot
`4.7.1.stable.official.a13da4feb`, 1364×1024, Chinese. Native pointer/keyboard
input connected A → NOT → LAMP, changed A, ran the circuit, removed its output
wire and reconnected it. All five actions earned completion normally.

The primary tree correctly showed the tutorial completed. Re-entering restored
the constructed circuit but displayed 0/5, unchecked requirements and a disabled
“Complete the 5 interactions” next action. Scene-local interaction flags reset;
the already-saved completion was intact.

Checklist, goal and next-action presentation now acknowledge existing earned
completion. Fresh tutorials still require all five interactions. No replay flags
or new run are fabricated, and only a newly earned completion invokes the existing
persistence/event/overlay path. Partial-checklist persistence is unchanged.

## Automated verification

The corrected baseline regression failed on the replay checklist, goal and next
action in both languages, with first-completion and save/load checks passing.
The initial test harness attempts had a scene-preload/autoload compile problem,
then missing explicit test save configuration; these were corrected before the
baseline comparison and are not acceptance evidence.

Focused run `20261004T194229Z-4cb99a48` passed import, isolation and six suites:
tutorial replay, prologue continuation, global save, hardware foundations UI,
hardware prologue UI and localization. The new suite exercises controller-driven
first completion, actual isolated save/load, fresh scenes in both languages,
preserved circuit signature, untouched current-session flags, replay editing,
no repeated overlay/cue, and the actual next button. These automated checks are
not native input. Independent read-only review found no blocker and requested an
explicit 4/5 gate assertion; it was added before the final full run.

Final full isolated run `20261004T194702Z-865bad91` passed all 64 conventional
suites, plus import and user-directory isolation (66 stages, exit 0). The final
production/test hashes match the imported source. Remote publication and exact-SHA
CI must be verified separately with the commit handoff.
All five workflow Python commands passed: branding, report-playtests, storage,
receiver and community. `git diff --check` passed.

## Native corrected-source acceptance

After normally closing the owned QA window, the same earned profile restarted on
the corrected source. No completion data or reference solution was injected.
Continue selected the completed tutorial. Re-entry immediately showed earned 5/5,
retained the circuit and exposed the enabled Half Adder action without a new
completion overlay. Removing/reconnecting a practice wire, changing A and running
again kept earned progress and did not repeat the completion overlay. Clicking
its next action opened the Half Adder briefing.

Returning through the hub, selecting English and revisiting the tutorial retained
the same 5/5 and enabled next action; that button again opened Half Adder. Native
session logs contain one tutorial-completion event in the original earning session
and zero in the corrected replay session. The final save still lists only tutorial
as completed. Both owned QA windows were normally closed and their absence checked.
Screenshots were inspected in computer-use history, not retained as image files.

Local QA profile save SHA-256 before corrected restart:
`ef142cf74fd48ae3b731ee72e3821fcb76a0ba73f5bedecfbf271310e7efbd3e`.
Final save SHA-256 after further native practice and navigation:
`cf7696719156094264735a9b0bc735faee823ffa2ddcba9a0b32f614a46be933`.

This is informed developer play of one return flow, not a fresh complete campaign
or novice-learning study. Windows/macOS, exports, minimum window/HiDPI and audio
acceptance were not tested. Native logs retain unsupported V-Sync and ALSA→Dummy
fallback; no game-script error was observed. No release, merge or deployment.
