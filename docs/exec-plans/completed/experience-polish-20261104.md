# Experience polish round — 2026-11-04 (completed 2026-11-05)

Owner: Claude (lead: design, allocation, review, integration). Implementation: GPT-6.1 Sol tasks in separate worktrees with disjoint file ownership. Baseline: `main` `0ba32e2` (equal to `origin/main` on 2026-11-04).

## Goal

Polish the existing 60-task journey for playability, visual quality, operation feedback, level continuity and immersion. No new tasks or feature count growth.

## Non-goals without a prior impact analysis approved by the user

Simulation rules, task IDs, formal pass/fail judgement, save format, and the authenticity of player results (no fabricated or animation-derived data). Sol tasks must report proposals in these areas and must not implement them.

## Baseline audit (Claude, 2026-11-04, Chinese 1280×720, Test mode, isolated APPDATA)

Captures: workspace `temp/claude-experience-20261104/runs/` (outside the repository).

| Area | Observed problem | Priority |
| --- | --- | --- |
| Prologue workbench | Test bench (~290 px) and component panel (~255 px) float over the canvas; CPU level opens three overlapping windows (test bench, task, components) that hide nearly all of the circuit. | Blocks operation |
| Prologue CPU | Dense composite parts at default zoom; small port labels. | Blocks operation |
| Chapter 2 run | Machine graph shrinks to ~9 px text between side panels; replay is 144 events at 2 Hz (~72 s) with a small dot on a wire; cache contents, hit/miss and the RAM access pattern are not drawn; the only strong evidence is the compute/wait bar. | Core concept legibility |
| Chapter 2 compare | Before/after of a change is not visible on the machine itself. | Core loop |
| Prediction (ch7) | Form-like page (dropdowns + empty text panels); no visual of the address stream before or during a run; style differs from other workbenches. | Style + legibility |
| Creation (ch8–10) | Dense: 3 left tabs, 7 lower tabs, 7–8 action buttons, long instructional paragraphs; main display empty state is three lines of placeholder text; in-level red “退出游戏” and language switch differ from other workbenches. | Style + overload |
| Cross-cutting | Native TextEdit input anomaly (2026-10-28: injected text ignored, then Godot TextEdit line −1 error after Ctrl+Shift+Up) not root-caused; save recovery accepted only by scripted checks. | Blocks operation |

## Batch 1 allocation (disjoint ownership)

| Task | Worktree / branch | Owned files | Focus |
| --- | --- | --- | --- |
| S1 Prologue wiring & sealing | `wt/s1` · `claude/ux-s1-prologue-20261104` | `src/hardware_foundations/**`, `src/ui/floating_instrument_panel.gd`, `src/ui/instrument_dock.gd`, prologue tests | Panel occlusion, dense operation, signal run feedback from real trace, sealing moment |
| S2 Chapter 2 performance | `wt/s2` · `claude/ux-s2-locality-20261104` | `src/ui/main.gd`, `src/ui/main.tscn`, `src/locality_chapter/**`, `src/ui/trace_overlay.gd`, `src/ui/cycle_budget_bar.gd`, ch2 tests | Cache/RAM/bus visual from trace, replay pacing, before/after comparison |
| S3 Prediction, creation, ending | `wt/s3` · `claude/ux-s3-late-20261104` | `experiments/prediction/**`, `experiments/creation/**`, their tests | Style unification, real stream visual, declutter, ending link to saved work |
| B2 Yi/CG/transition bridges + lab style | `wt/b2` · `claude/ux-b2-bridges-20261104` | `src/lab/**`, `src/ui/{level_completion_overlay,cinematic_player,terminal_passage,journey_journal,yi_*}.gd` | Yi chapter-end lines cite real records; post-CG view of the player's own artefact; lab/terminal instrument style |
| S4 Representation & service | `wt/s4` · `claude/ux-s4-second-act-20261104` | `experiments/representation_region/**`, `experiments/service_plan/**` | Visible byte board / state lanes from real events; declutter; shared chrome convention |
| L1 Laboratory home | `wt/l1` · `claude/ux-l1-lab-home-20261104` | `src/lab/{lab_room_3d,lab_home,lab_palette,lab_features,lab_state,room_page_skin}.gd`, `lab_screen.gdshader`, `assets/lab/**` | Owner request 2026-11-04: objects that read as their function, room reflects real progress (works frames, plaques, chapter rack), warmer light and quiet idle motion; B2b keeps lab_terminal/pages/dialogues/artifact/archive |
| D1 Native text input & recovery diagnosis | `wt/d1` · `claude/ux-d1-input-20261104` | none (diagnosis; may add only a temp repro script outside `src/`) | Root cause + proposed fix + impact |

Shared files: `localization/*.po` — tasks append new keys only, in one delimited block per task; Claude merges. `docs/CURRENT_STATE.md`, `.godot/collaboration/handoff.md`, this plan: Claude only. Each task writes evidence to `docs/verification/20261104-<task>/`.

## Verification per batch

Same dev-capture route before (baseline worktree) and after; relevant `scripts/verify-project.py` suites; Claude re-runs captures and suites after integration and inspects the diff.

## Progress

- 2026-11-04: baseline audit, plan, batch-1 allocation; S1/S2/S3/D1 launched, then B2 launched in parallel (disjoint files) at the owner's request to keep optimizing.

- 2026-11-04 round-1 reviews (Claude): S1 accepted CPU entry/wire target/seal leads, sent S1b (real-trace propagation, failing output marker, seal payoff, no reframe fights). S2 accepted trace-driven cache/RAM/bus view, 8 Hz pacing, session comparison; sent S2b (keep result panel, header overflow pushing 设置 off-screen — pre-existing, constants-derived grid, comparison placement). S3 accepted request cards + 更多工具; sent S3b (full-width timeline, progress-aware idle diagram, chrome, text cuts, remove unused PO keys). D1: no runtime defect found; keycode-only injection inserts nothing (likely the 10-28 "text ignored" artefact); `line -1` unreproduced and stays open; hard-kill loses only edits inside the autosave window (system 2 s, ch3 0.7 s) — recommend no cadence change; sent D1b (stale HubBrowseJourney GUI probe, close-request flush check). B2 accepted record-quoting Yi lines; sent B2b (visual artefact card, Yi voice, ch3/ch4 numbers). S4 launched.
- Round-2 reviews: S1b accepted (failure marker on canvas, wave propagation from real trace, seal condenses the player's circuit, palette arrival). S2b accepted (docked result + coloured deltas, header elision, constants-derived grid); Claude fixed EN arrow. S3b accepted; Claude restored the three task-specific first-experiment prompts (S3b had replaced them with one line wrong for 7-2) as short panel lines + full prompt in the empty timeline, after the full text overflowed 720 px. D1b accepted (stale GUI recovery probe fixed 764/0; window-close flush verified in system/ch3/ch4; process matrix 18/18; tests renamed; testing.md entry). B2b accepted (post-film card with the player's part thumbnails / five representation tiles; Yi voice). Claude wired the prologue post-film call; chapter 5 call delegated to S4b (owner of region.gd). M1 accepted. L1 round 1 insufficient → L1b art pass. S4 round 1 partial → S4b. S5 launched (ch1/3/4).
- A1 audit (read-only): no event sounds besides the completion melody and creation symbol tones; ch4 never shows its completion card; completion timing inconsistent; seal/budget bar/lab subtitles ignore reduced motion. Queued as final cross-cutting F1 on the integration worktree after S4b/S5/L1b land.
- Integration worktree `wt/int` (branch claude/ux-integration-20261104): S1, S2, S3, B2, D1, M1 applied. Suites so far: prologue/ch2 15/15 PASS; creation/prediction PASS except `test_prediction_record_source` (1/28, reproduced on 0ba32e2 by S3b; to confirm in final run).
- Round-3 merges: S4b (byte board first, compact order card, single result block; service compact group strip and coloured over-limit headline; chapter-5 post-film call wired), S5b (ch4 bubble clear of toolbar, per-order headline, transferred rows tinted with bytes, ch1 compute/wait bar, ch3 coloured headline), L1c (lamp/globe/rack separated, neutral desk, rack indicators and cable, taller works frames, single hover feedback). Broad integration run: 33 suites, one flaky check in test_b2_bridges (one-frame wait after parsed Enter) — test hardened to wait ≤5 frames, production unchanged; rerun PASS. Snapshot before F1: temp patches/int-before-f1.patch (46 files, +1496/−193).
- Owner request 2026-11-04 (later): settings/display pages + animation and covering effects. P1 launched (pages family, hide internal build ids, empty-state previews, one modal backdrop, opaque full pages, motion). F1 launched on the integration worktree (completion consistency, restrained cues helper, reduced motion everywhere, covering audit, real-flow prologue post-film card).
- Final round: P1/P1b accepted (one page family, internal build ids behind 诊断信息, empty-state previews, opaque full pages, focus return). F1 accepted (ui_cue helper at real event sites, first-completion card vs repeat cue, ch4 completion card, prologue seal-ready separated, reduced motion for seal/budget bar/subtitles, 0.88 modal backdrop, real earned-machine post-film card 73/0). Claude: ch4 Hint layer marked as a guide blocker so Yi's opening line steps aside.
- Full verifier on the integration: 237/12; ten regressions passed on 0ba32e2 (Tab chains after header moves, ch2 run reframing hiding finish-playback, creation browsing selection, evidence tabs hidden before save, ch3 tool reframing, capstone completion overlay, Esc menu label). R1 fixed them, mostly in production (restoring protected behaviour); test updates only where layout deliberately moved, with behavioural intent kept. Final: 247 PASS / 2 FAIL — the two failures (`test_prediction_record_source` 1/28, `test_service_undo_context` 16/96) reproduce identically on 0ba32e2. Record: ../../verification/20261104-experience-polish/final-regression.md.
- 2026-11-05: owner authorized finishing the remaining required rounds and pushing all changes to main.

## Proposals awaiting the owner

- S3: per-request wasted-fetch attribution in prediction needs extra model output (simulation-side) — not implemented.
- D1: immediate text retention / pending-save indicator would change autosave semantics — Claude recommends keeping current cadence.

## Open questions

- Owner previously rejected redesigning the 0/1 level display (LED bits/slide switch/glowing lamp); S1 keeps original signal/bit visuals.
