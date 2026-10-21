# Immersive laboratory homepage

## Goal and scope
Integrate the reviewed independent laboratory geometry as the real homepage on a new branch from 472890a. Keep the terminal, archive, task journey, saved works/achievements, handbook, settings and offline feedback connected to existing owners. Provide restrained fixed-position look-around and reliable return/focus transitions. Preserve the classic homepage option.

## Non-goals / invariants
No simulation, progression, task availability, save format or external feedback destination changes. No fabricated progress or works. No user save reads in QA. Preserve the dirty guide branch and existing user changes. No force push. No claim that headless tests establish rendering/performance.

## Affected files
Existing lab homepage/controller, one new room renderer and GLB asset with attribution, focused tests, verification receipt and architecture/testing notes. Reuse existing overlays and routes rather than duplicate them.

## Steps
1. Inspect existing routes/guards and tests; establish matching engine and display.
2. Add self-contained 3D room presentation behind existing functional overlays; map semantic hotspots, occlusion and input focus.
3. Preserve exact globe initial pose and 24-second loop, real journey/work state, accessibility and reduced-motion behavior.
4. Iterate actual rendered captures and focused integration tests; run affected regressions.
5. Inspect diff, refresh remote SHA, commit/push only new branch and verify published commit.

## Progress / decisions
2026-10-22: the user authorized graphical testing, corrections and delivery to main, then explicitly required removing the room shortcut toolbar and confining all homepage features to the physical terminal. Work proceeds in `E:/VNB/immersive-lab-qa`, based on candidate 25876d2, preserving the separate guide checkout. The terminal owns a bounded viewport for the existing feature controllers and their embedded confirmations; settings and handbook become docked pages. Global settings/feedback entries must use that same screen. Verify native input, bilingual renders, target frame times, full local regression and remote CI before closeout.

2026-10-21: clean clone and remote baseline verified; independent v10 GLB is source art. Reuse existing lab controller and terminal because they already own task routes and departures. Official Godot 4.7.1 was downloaded after approval and verified against the vendor SHA512 checksum. Existing Xorg/dummy cannot start within the available execution sandbox; no display listener was opened. The installed engine supports headless only with the dummy renderer, so no rendered acceptance or performance claim is made.

## Open gates
Actual graphically rendered review, target engine availability, route regressions, push verification. Target-device performance/human comprehension remain separate from automated checks.

2026-10-21: two isolated test rounds completed. Round 1 exposed a null World3D lookup and the terminal waking invisibly; both were corrected. Round 2 passed all five existing affected suites; the new 73-check suite exposed a QA viewport scaling mismatch. Independent review additionally requested actual station/work display state, recentering before departures and bilingual terminal bounds checks; these are being addressed before publication.

2026-10-21: final fourth isolated run passed import, directory isolation and all 10 selected regression suites; immersive-specific coverage is 166 assertions. True station/work displays, wall occlusion, keyboard recovery and bilingual screen bounds are covered. The earlier laboratory wake test now waits for the deliberate 0.6-second recenter/reveal interval. Full logs are in the integration receipt. Independent static review found no remaining blocker to publishing a candidate.

Status: implementation and selected automated gates complete; graphical acceptance remains blocked by the available display environment. Keep this plan active for rendered review, target performance and merge decision. Do not treat the candidate push as release approval.

2026-10-21 15:00 UTC: follow-up input regression found initial OS pointer (0,0) caused unintended camera drift. Fixed by requiring actual pointer motion, restored original eight-frame wake assertion, and passed eight isolated input/route suites including 167 immersive assertions. This supersedes the earlier test-wait workaround. CI last observed Python success/Godot in progress; further read denied, so remote terminal state is unverified. See input-followup receipt.

2026-10-21 15:10 UTC: detail pass reproduced and repaired Archive keyboard return focus and reduced-motion no-destination fallback. Broad eight-suite run passed, then final modal-focus guard passed three focused suites with 188 immersive assertions. Repeated input, hover clearing and rotated ESC are covered without changing passing behavior. No rendering/CI-read claim added.

2026-10-21 15:20 UTC: read-only cloud display check still found no usable graphical service. Reproduced global F10 layer blocking gap and empty Archive initial focus omission, corrected four production lines. Eight final suites passed; immersive coverage301checks includingviewportF10/ESC andfiveaspectratios×two languages. No speculative layout or focus-cycle change. See modal-polish receipt.

2026-10-22: user refined the presentation: all primary functions belong in a full-screen terminal; room-mode screen content must follow physical perspective. Replace projected 2D screen overlays with a material on the actual glass for the standby display. Opening it switches to a uniformly scaled full-screen workspace; Esc closes pages, then returns to the room. Suspend room rendering while the workspace is open. Validate tilted standby text, fullscreen layout, navigation and nested feedback with actual rendering.
