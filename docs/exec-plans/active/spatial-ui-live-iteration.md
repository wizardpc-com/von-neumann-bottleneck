# Spatial UI and live player iteration

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
