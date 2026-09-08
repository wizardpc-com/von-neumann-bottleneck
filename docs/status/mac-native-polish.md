# Mac native play and workbench polish

Baseline display build label: `mac-polish-20260907T085543Z-f15c175` (unchanged by the palette follow-up). This continues latest main `0ad0bff` using
Godot `4.7.1.stable.official.a13da4feb` on Apple M2. The original construction
campaign and both later system chapters remain the default Game route. The
historical Windows package is unchanged; this source has not been accepted as
a new Windows release.

## Changes grounded in play

- Editing and playback occupy separate toolbar rows. Primary test/seal actions,
  restrained instrument accents, dark signal faces and consistent typography
  make the current action and circuit easier to distinguish.
- Mission specifications have compact headings, aligned Half Adder truth-table
  cells and reachable navigation. Map titles wrap within bounded nodes in both
  languages. LOAD/STORE now invites observation of the already wired computer.
- Test actions stay below the scrolling cases. Switching levels resets that
  scroll; inspecting a component preserves other instrument positions and sizes.
- Mac pointer motion with an empty button mask no longer cancels a physically
  held drag. Focus loss ends gestures. Completion and Handbook input cannot
  change the board behind them. Hardware shortcut hints show Command on Mac.
- Wide terminals show complete authoritative values rather than Boolean 1.
  Hexadecimal padding puts zeros before digits A–F: four-bit 12 is `0xC`, not
  `0xC0`. Simulation values, timing and signatures are unchanged.
- The Handbook keeps its 89 topics, 29 illustrated entries and existing unlock
  policy, with a progress rail and signal drawings matching the canvas. Its
  binary diagram consistently shows `1101 = 8 + 4 + 0 + 1 = 13`.

The images below are actual Godot renderer captures from isolated verification;
they are not native computer-use screenshots. The binary image uses the Handbook
availability test fixture (89 topics), not earned player progress.

![Half Adder mission and instrument hierarchy](../images/mac-polish-mission.png)

![Complete word values on the CPU data path](../images/mac-polish-cpu.png)

![Binary weights and matching sum](../images/mac-polish-binary.png)

## Native ordinary Game evidence

These observations used the Mac computer-use surface, entering ordinary Game.
They are separate from Godot viewport-event replay and unit fixtures. No Test
bootstrap, reference-wire insertion or completion setter earned this progress.

| Native activity | Observed result |
| --- | --- |
| Tutorial | Five required actions completed; port wiring, input toggle, precise right-click erase, Command+Z and Command+Shift+Z |
| Half Adder | Alternate player-built topology, four official cases passed and sealed; body drag/undo and a midpoint branch creating JUNCTION_001 |
| Full Adder / ALU | Eight / 32 official cases passed and sealed; ALU H1, H2 and H3 separately requested with confirmations, returning to the empty player design before building |
| Latch / Register / RAM | Five temporal cases each passed; both stored words maintained their own values; RAM used Shift+Home at 77% before accurate port drags |
| CPU | 19 manual wires, A/B/C/D interface stages, all seven instructions passed; TinyComputer sealed |
| LOAD/STORE | The sealed player computer passed all seven fixed program steps; original map marks every prologue lesson complete |
| Handbook and focus | 59/89 topics open after the bridge; Command+A replaces CPU search with Cache; future Cache shows only its unlock condition; Escape returns focus to Handbook entry |
| Modal and numeric input | Number 3 behind completion leaves wire color unchanged; Command+A in playback frequency replaces the value without editing the board |
| Retina/window | Built-in Liquid Retina, 2940×1912 backing / 1470×956 logical display (2×); F11 and native window zoom used, native capture at 1336×768 |

The native arithmetic, storage and CPU continuation used commit `f15c175`.
Its incorrect pre-fix word displays were observed and led to the subsequent
presentation correction. The original player files were copied intact into
`.godot/mac-playtest/cpu-native-save-backup/` before ending the process. Earlier
backups and failed verification logs remain available locally.

## Restart defect and approval boundary

A native restart exposed a pre-existing save defect: `Array[StringName].sort()`
can produce a different component order in a new Godot process. That changes
source signatures and the default seed fingerprint, causing a correct sealed
Half Adder to be rejected and the default workbench to be reset. A read-only
probe of the original saved circuit still passes all four official cases.
Same-process save tests did not expose this problem.

A compatible deterministic-order correction and one-time legacy fingerprint
migration were proposed. Because the user explicitly reserved data changes for
approval, no conversion, signature relaxation or player-save cleanup has been
applied. The complete native progress backup is retained. This issue prevents a
claim of reliable restart continuity until the compatibility fix is authorized
and validated across separate processes.

## Verification and remaining acceptance

Fresh verification uses `scripts/verify-project.py`, a copied project and a
unique Mac player directory for every case, checked by an actual path probe.
- English full Game: `.godot/verification/20260907T085708Z-82f678ac/`, all
  20 suites and 502 viewport-input checks pass.
- Chinese full Game: `.godot/verification/20260907T090007Z-ab01f760/`, all
  20 suites and 502 viewport-input checks pass.
- Final Handbook copy/render check: `.godot/mac-playtest/postfix-handbook.log`,
  558 checks, zero failures; localization and actual directory probe also pass.
- Subsequent native ordinary Game in a fresh isolated directory: Tutorial
  completed again, Command+C/V creates a component and Command+Z removes it;
  Half Adder specification/nav fits the native capture, and its test action stays stationary while
  case rows scroll. This does not replace the earlier original-directory CPU play.

- Final small fixes: `.godot/verification/20260907T091751Z-b7310af3/`, all 20
  suites and 142 Tutorial viewport-input checks pass. This targeted run follows
  the complete bilingual mainline passes above.
- Final native: corrected first Retina window fallback is visibly larger than
  the earlier 800-pixel-wide capture. F11 entered fullscreen; the visible exit
  button restored the window size. Rapid consecutive F11 produced an unstable
  capture, so that gesture is not counted as a clean round-trip pass. The final
  binary diagram and hexadecimal explanation were read in the native Handbook.
- Final original-checkout import is clean. Player-file hashes before/after that
  import match; the original CPU progress backup remains untouched.

The [verification summary](../verification/2026-09-07-mac-native-polish/summary.json)
records source commit `d8c752f`, exact run IDs, pass counts and evidence limits.
The [active plan](../exec-plans/active/mac-native-polish.md) retains intermediate
failures and remaining work.

Do not infer novice comprehension, physical trackpad comfort, mixed-monitor DPI,
Windows EXE behavior or release readiness from the passing suites, automated
replays or agent play. Those are distinct acceptance activities. Existing seed
coordinates, free construction, independent Hint levels, simulation semantics,
source provenance checks and save formats remain unchanged.

## Display API reference

The Mac default window correction uses the documented
[Godot 4.7 display scale](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html#class-displayserver-method-screen-get-scale)
only for the initial fallback size; previously remembered window rectangles stay
in pixels. Usable-screen bounds still constrain the result. Physical multi-screen
behavior needs a separate native check.

## 17:38 screenshot follow-up: component palette

The user's word-MUX/decoder screenshot exposed an actual remaining defect:
unnamed `[1]` port labels overlapped the function glyph and a single port row
collapsed into a narrow rectangular preview. Bounds-only tests missed it.

- A dedicated whole-module miniature now reuses the canvas function glyph and
  family colors, with a readable body silhouette, actual pin count and distinct
  one-bit/word lead widths. The full canvas and placement ghost are unchanged.
- Cards now provide localized names, short purposes, and real input/output counts
  with the maximum port width. Text uses Labels with measured ellipsis instead
  of clipped custom drawing. Placement instructions are shorter.
- Fresh isolated import, directory probe and all 20 suites passed in
  `.godot/verification/20260907T095336Z-b7454d8a/`. The subsequently added internal
  geometry checks also passed in the isolated prologue UI suite. All 19 component
  types were rendered and inspected in Chinese and English; these are catalog
  fixtures, not earned campaign progress.
- Native ordinary Game entered Tutorial with a new isolated save and displayed
  the new cards. It exposed two next fixes: the default palette height hides NOT
  below the fold, and a native card drag arms placement without dropping a gate.
  This round is therefore not a complete native-editing pass.
- The native tool initially confused identical Godot window titles and retained
  a stale menu capture. An independent temporary app identity and window title,
  checked against periodic read-only viewport captures, resolved identification.
  The editor was preserved. The temporary app/capture helper is not product code.

## Native palette follow-through

The next native pass reproduced the two palette issues above and corrected them:

- First opening now sizes the palette against the settled Retina desktop. All
  three Tutorial cards are visible without scrolling, while later player window
  moves and resizes are retained.
- A held native press whose motion omits its button mask can start the normal
  Godot drag payload/preview. A drag preview explicitly preserves its configured
  symbol and labels instead of losing runtime fields through Node.duplicate().
- Drop hit testing and positioning use the release event. Native captured input
  can differ from the physical OS cursor; using that cursor had misplaced the
  item or prevented the drop entirely. Drops over floating instruments cancel.
  A successful drag places one component and returns to editing. Clicking a card
  still supports repeated placement, and each placement remains one undo step.

Fresh ordinary Game, with a unique isolated save and no reference insertion:

| Native action | Observed result |
| --- | --- |
| Tutorial palette | AND, OR and NOT fully visible; localized card text and whole silhouettes readable |
| Drag AND onto canvas | Exactly one component at release position; no extra placement ghost |
| Command+Z / Shift+Command+Z | Removed, restored and removed the dragged component |
| Drag AND onto Test Bench | Cancelled without adding a component behind the window |
| Click NOT, place twice, right-click | Two components placed; placement ended; two undos restored the board |
| Tutorial construction | Manually wired, toggled input, deleted/reconnected a wire; earned 5/5 completion |
| Half Adder construction | Read the two specification pages, manually wired 12 connections; all four official cases passed, sealed, continued to Full Adder |
| Newly unlocked Half Adder card | Readable miniature; drag produced the complete two-input/two-output module; undo restored the initial Full Adder board |
| Handbook | 36/89 terms available; CPU remained locked behind its original prerequisite; Command+A changed CPU search to binary; Escape returned focus to Handbook |
| Retina/window | F11 restored a readable window and returned to fullscreen; component and wire state retained |

The last native system capture after returning to fullscreen has an anomalous
thin strip at its top edge. The read-only Godot viewport capture is clean. This
separates the observed capture discrepancy from game rendering; it does not
establish stable rapid fullscreen switching or physical mixed-monitor behavior.
The test app used a separate temporary bundle identity so the user's editor
session could remain open. No test capture helper is part of the game.

CPU was manually completed in the earlier native round recorded above, not
manually replayed in this palette follow-up. The final automated mainline replay
covers CPU again, and must be reported separately from native play. Save-format
and restart compatibility work remains pending the previously requested approval.

Final follow-up verification uses the exact current runtime/assets/tests copied
in `.godot/verification/20260907T105450Z-7953228f/`: import, actual directory
probe and all 20 suites pass; Chinese and English ordinary Game each pass **528
checks with zero failures**, including CPU and LOAD/STORE. Native observations
above remain a separate evidence stream. The [summary](../verification/2026-09-07-mac-palette-polish/summary.json)
records source hashes, unique player directories and remaining limits. Final
[Chinese](../verification/2026-09-07-mac-palette-polish/palette-zh_CN.png) and
[English](../verification/2026-09-07-mac-palette-polish/palette-en.png) catalog
renders show all 19 card types; they do not represent campaign unlocks.

## Further dragging feedback: cancellation lifetime

The next report led to two concrete failures beyond completed-drop tests. A held
palette drag followed by Escape cleared the canvas ghost but retained Godot's
payload, so the later release still placed an item. Application focus-out also
left repeated placement armed. The held screenshot showed a second card preview
overlapping the actual component ghost.

Cancellation now ends both the palette payload and placement state; focus-out
uses the same cancellation. The canvas owns the only snapped component preview,
and invalid positions over floating instruments hide it. Click-repeat, drag-once,
normal/missing-mask input, free editing and undo semantics are retained.

The [evidence summary](../verification/2026-09-07-palette-cancellation/summary.json)
records two failing baseline probes, the passing repair and before/after frames.
Fresh isolated import/probe and all 20 suites pass in
`.godot/verification/20260907T120142Z-bf175db9/`; the current ordinary Game setup
replay passes 567 checks with zero failures. Final native computer-use verifies
valid drop/undo, invalid Test Bench drop, Escape followed by a harmless canvas
click, and focus cancellation when raising the user's existing editor. The
editor remains open. A held Escape is viewport-input evidence, not a separate
native held-mouse claim.

The ongoing [all-level review](../exec-plans/active/campaign-playability-review.md)
tracks content assessment and pending major-design decisions separately.

## Campaign playability review and presentation follow-up (2026-09-07)

The complete 21-level review is in
[Campaign playability review](../design/campaign-playability-review.md). Public
Turing Complete developer notes and first-person player accounts inform questions
about discovery, reuse and cognitive jumps; they are not measured player consensus.

At source 8bceafe, Mac computer use completed every Chapter 1 and Chapter 2 level
in ordinary Game. The prologue prerequisites were earned by a separate, explicitly
identified viewport-input setup. Native results include the 316→268 CPU,
268→124 RAM and 144→96 Bus comparisons, and Chapter 2's final 642→138 cycles at
cost 4 after a 2-line Cache experiment failed to improve performance.

The follow-up fixes readable, bounded test windows, literal source-code subscripts,
misleading target/selection/history labels and mission navigation. Mission copy
retains specifications but stops giving observation answers in the operation step.
Chapter 1 can end the presentation early without changing its Trace or receipt.
No level IDs, prerequisites, official cases, targets, saved provenance or
simulation model were changed. Program-template developer comments remain because
raw source participates in existing receipt signatures; compatibility work is
still pending user approval.

All 20 fresh suites and the English 567-check ordinary Game replay pass in
`.godot/verification/20260907T131713Z-ad1da3c4/`. Updated-source native screenshots
and final result are recorded in the linked verification summary once rechecked.

Final native recheck caught and fixed the longest-case dropdown expanding a
window off screen. The final 20 suites pass in
`.godot/verification/20260907T132435Z-04e03a80/`; the final Chinese preparation
replay passes 567 checks. Native full-value expansion reached the last byte and
Finish Trace preserved every official result. See the
[verification summary](../verification/2026-09-07-campaign-playability/summary.json).

### Correct module identity during encapsulation

During current-source Game replay, the CPU sealing artwork still displayed
`HalfAdder CREATED` and `A B → SUM CARRY`, hard-coded for every module. The effect
now receives the actual earned `seal_name`, presents it in a real accessible Label,
and uses bilingual copy and the shared type hierarchy. The animated rays are
bounded by the workbench. Sealing duration, topology validation, installation,
save/provenance and next-level behavior are unchanged.

Chinese ordinary Game replay passes 574 checks with zero failures in
`.godot/verification/20260907T134039Z-e6d28ca3/`, including seven checks and captures
of the actual sealing identity. CPU and RAM images were inspected. The final
English run passes all 20 suites and 574 replay checks with zero failures in
`.godot/verification/20260907T134316Z-181439eb/`, including the final ray-boundary
follow-up. Its CPU frame was inspected for the actual TinyComputer name, English
subtitle fit and contained rays. Exact sources and images are recorded in the
[verification summary](../verification/2026-09-07-encapsulation-identity/summary.json).
These animation captures are from viewport-input replay, not claimed as a second
manual CPU construction or a first-time human playtest.

## Visual signal notation (2026-09-07)

The user's DATA/WRITE screenshot showed role labels crowded inside input bodies,
hexadecimal values without a visible bit count, and indistinguishable word and
single-bit terminal presentation. The new notation moves terminal names above the
body, shows decimal values and one cell per bit, and explicitly labels widths:
amber 1 bit, violet 2 bits, blue 4 bits. Module port labels use the same width
colors. Counts, digits and filled/empty cells carry meaning independently of color;
existing red/green signal endpoints and player-selected wire colors remain distinct.

The first Mission page explains the widths present in that lesson before building.
The Handbook explains positional weights and hexadecimal notation, and the CPU
instruction table pairs decimal values with their two-bit codes. Test Bench word
inputs keep their existing SpinBox contract and show synchronized bit cells. Inputs
and debug Run precede storage-state reports; the initial prologue bench is taller.
Existing port positions, canonical circuit data, state transitions, official cases,
progression and independent hints are unchanged. Initial view framing reserves
space at the screen edge without moving saved components.

The native checks and fresh isolated verification are recorded in
[visual-signal evidence](../verification/2026-09-07-visual-signals/summary.json).
This is a presentation and interaction increment, not release acceptance or an
approval to migrate existing save signatures.

Completed 2026-09-08: the final exact source passes all 20 isolated suites and
581 English ordinary Game input checks. Native Tutorial hand-wiring verifies both
1→0 and 0→1 with the single-cell toggle. Native RAM debug separately verifies
writing 4 and holding it while the input changes to 12; CPU width and instruction
explanations were inspected. Chinese replay passed 581 checks before the final
toggle-only drawing change. Windows and first-time human acceptance remain open.

## Distinct scalar wires and multi-bit buses (2026-09-08)

One-bit connections now use thin solid cables and round pins; multi-bit connections
use wider centered ribbons and hollow square sockets. Drafts, reverse-input drags,
branch/reconnect previews, network hover, causal playback and component leads share
the notation. First Mission guides show actual line/pin samples beside bit counts.
User wire colors, original curve/picking geometry and 24px port footprints remain.

Draft review exposed a pre-existing status bug: compatible-target enumeration wrote
errors for unrelated ports. Enumeration is now read-only; actual hovered incompatible
ports still report their diagnostic. Reverse drafts read the selected input width.

Final Godot 4.7.1 source passes all 20 isolated suites and 593 ordinary Game checks
in each language. Native RAM checks separately cover an actual 4-to-1 rejection,
reverse data connection, bus branching, Command-Z/Command-Shift-Z, decimal input
focus, debug output 12/1100, 91%/150% framing and fullscreen. The native partial RAM
circuit is not a claimed official solution. No gameplay, save or progression change.
See [evidence and reference sources](../verification/2026-09-08-scalar-bus/summary.json).
Windows, physical trackpad and first-time human acceptance remain unperformed.
