# Spatial UI and live player iteration

Status: **COMPLETED — 2026-09-13**. External release gates remain in RELEASE_BLOCKERS.md.

Goal: improve the game's visual finish, science-fiction character, spatial layering,
typography and presentation, iterating from rendered and native player feedback.
Keep reviewing related level content during those sessions and fix demonstrated
confusion or interaction problems. The goal spans all five existing regions.

Baseline: c0a05fa, clean tracked worktree; two untracked user plan files preserved.
No new chapters, prerequisite/rule changes, replacement mainline, save format changes,
server deployment, or new assets/dependencies requiring external services.
Deterministic simulation and traces, original free editing, floating instruments,
progressive independent Hint, all 40 tasks and privacy boundaries remain unchanged.

Stages (keep open until evidence covers the whole requested scope):
1. Shared visual vocabulary and entry: quiet spatial backdrop, restrained raised
   surfaces, preserved chapter emblems, stronger primary/secondary hierarchy;
   task-tree regions/nodes inherit the same layered visual language.
2. Native player sessions: Tutorial and construction branches/CPU, then representative
   tasks from Chapters 1–4; inspect Mission, component tools, simulations and feedback.
   Fix concrete layout, interaction and explanatory issues found while playing.
3. Iterate bilingual/minimum-window rendering and actual input; verify reduced motion,
   zoom/pan readability and persistent state; final source checks, candidate and
   explicit release gates. Windows and external novice evidence cannot be invented.

Affected files: shared InstrumentTheme/TechnicalBackdrop/ChapterEmblem, hub,
task-tree presentation; subsequent level files only where evidence warrants a fix.
Use existing procedural/vector rendering, font resources and short UiMotion reveals.
Decorative layers never accept mouse input or imply simulated timing/latency.
Use calm contrast and regional shapes/labels, not continuous blinking or excessive
full-border neon. Primary actions remain prominent without growing all UI text.

Verification: isolated verify-project.py; existing bilingual typography captures;
ordinary Game replay and computer use in an isolated QA user directory. Record
actual screenshot/operation observations, not only test counts. Inspect failed
intermediate captures and repair them; preserve precise source/package boundaries.
Stage commits follow the user's standing request; push main, never public release.

Progress 2026-09-13: source/doc baseline inspected. The flat shared surface/bright
perimeter hierarchy is the first visual issue. Native drag/pan was inconclusive
in the previous turn; keep that gate open and reassess using fresh input evidence.

Stage 1 source + native update: layered static scenery, raised panels and task-tree
region trays implemented. Narrow-card emblem overflow found in rendering and fixed.
Native Tutorial exposed H1 compact/expand replacing Hint with ordinary Mission;
fixed explicit readable Hint window and preserved content across fold/unfold.
Native H1, fold/unfold, H2 cancel and return inspected; final Chinese Tutorial
replay 212/0; full conventional suites and bilingual typography pass.
Native task-tree drag diagnosed a tool motion with mask=0/relative=0; do not remove
the existing safety cancellation. Related physical pan gate remains pending.

Next continuation: CPU and Chapters 1–4 actual screen/play sessions with isolated
earned saves; review shared floating instrument layers, task descriptions and
run feedback. Returning from Hint restores player topology but relays out default
instrument geometry: assess whether preserving the previous compact window state
would reduce disruption, without assuming a save-format change. This stage does
not resolve the full active goal or final candidate delivery.

English Tutorial follow-up also passed 212/0; rendered H1 explanation/actions
inspected. Stage 1 is ready for its reviewable commit. The remaining stage queue
above is intentionally still active; do not treat this checkpoint as goal completion.

Bilingual continuation: native Chapter 4 source play in Chinese and English confirms
that concatenated field/record labels (Battery10) need separation. The memory grid
also had a Chinese-only tooltip and fixed unwrapped captions. Separate field, source
record and value, wrap captions without scaling down text, keep four cells per real
16 B row, and allow horizontal scrolling only when that grid cannot fit. Long
floating titles trim with a full tooltip instead of expanding the window minimum.
Scope remains presentation and explanatory wording; mapping, costs and rules stay
unchanged. Verify both languages, resized diagrams, source identity/hit selection
and native run feedback before committing this stage.

Bilingual checkpoint verified: Chinese/English native 4-1 saved-design runs retain
49/73 cycles; memory caption height settling and tiny record labels were corrected
from checks/screens. Final typography, localization and layout-host checks pass;
ordinary Tutorial replay is 212/0 in each locale. See
[follow-up evidence](../../verification/20260913-bilingual-memory/README.md).
This closes the scoped bilingual memory/window pass. The broader CPU and Chapters
1–3 native iteration/final-candidate queue above remains open.

CPU/Chapter 1 native continuation: CPU seven-step program passed; Hint return
reopened hidden tools, expanded Mission and refitted the camera. Preserve transient
window geometry/visibility and camera across Hint, while retaining the documented
ADR 0015 history reset. A stale from_tree flag also redirected a chapter-card click
to the previous CPU map selection; clear that transient route on explicit card entry.
Native RAM-wait ran two 134-cycle cases, 268 total with 252 CPU-wait cycles. Add a
read-only compute/wait proportion bar using those metrics, respecting existing
Profiler reveal gates, and use subdued raised window surfaces with focused accents.
No metrics are added together twice; RAM service remains part of wait.

Desktop continuity checkpoint: final English full replay 633/0 and Chinese Tutorial
218/0. English long Mission text hid its page actions; they now follow section tabs.
Rendered Chapter 1 found a buried conclusion action and an English fullscreen
header overflow; both corrected. Final bilingual Profiler, typography, shared UI,
settings, card routing and release-convergence checks pass. Final computer-use
recheck is pending because the Mac is locked; do not claim that native gate closed.
See [desktop evidence](../../verification/20260913-desktop-continuity/README.md).

Chapter 2/3 continuation (native Mac still locked): baseline Test-mode render
fixtures show Chapter 2 Program exposes only a few code lines beneath reference
material and retains bright equal-weight window borders. Move code/apply/status
ahead of optional reference, preserve existing locked-baseline behavior, and align
window focus surfaces with Chapter 1. Chapter 3 timeline uses the theme font, names
the cycle axis, and identifies batch blocks with # labels; keep all trace geometry
and metrics authoritative. Verify rendered bilingual layouts and relevant suites
before this checkpoint; native verification remains open.


Chapter 2/3 readable-investigation checkpoint: native control is now available via
an isolated uniquely named QA copy of the official engine. Arrival and buffers were
solved through ordinary Game; buffers improved 40→28 with 12 overlap cycles and
survived restart. Chapter 2 capstone ran 642→210→138 with unchanged output. Its map
had overlapping sixth/seventh cards, now separated and checked natively in both
languages. Native task-tree drag exposed premature cancellation on zero motion
button-mask; final press/release capture now pans correctly, with outside release,
focus and fullscreen cancellation checks. The duplicate new translation key found
in rendering is corrected and guarded. See [checkpoint evidence](../../verification/20260913-readable-investigations/README.md).
The old locked-screen condition above is historical. Remaining CPU/Chapter 1
native rechecks, extended DPI/focus, candidate export and external platform gates
remain open; this checkpoint does not complete the broader plan.


Source-native closure of earlier rechecks: in the current isolated Game, CPU H1
return retains the hidden Parts window, compact Mission, Test Bench position and
zoomed camera. Rerunning the seven-step official program passes all seven cases.
Chapter 1 RAM-wait reruns both cases at 134 each; the visible time strip matches
16 compute + 252 wait = 268 total. Resizing the Profiler shorter keeps all current
metrics readable. No new rule or presentation change was needed for these checks.
Continue with final full replay and a newly frozen candidate; do not use source
success to close exported-package mouse or external platform gates.


Final closure: isolated full source verification and English ordinary Game replay
pass. Frozen `free-alpha-47a59d385103` contains the reviewed runtime; both archive
identities/hashes and the actual Mac release-binary probe pass. Native exported Game
now has reliable mouse control on this Mac: fresh-profile Tutorial was manually
completed, including palette drag/undo, wiring, practice run, deletion/reconnection.
Tree pan/zoom, normal quit/restart, Continue localization, saved wiring and persistent
English/reduced-motion settings were observed. Bilingual windowed layouts remain
readable. The post-play executable/PCK and archive hashes remain unchanged.
See [final evidence](../../verification/20260913-spatial-candidate/README.md).

All three scoped stages now have source and representative native evidence across
the five regions. External novice, Windows, another Mac and extended DPI/focus
acceptance remain explicit release gates, not unfinished replacement features.
No chapter, rules, progression, simulation or persistent format changed in this plan.
