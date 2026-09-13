# Native player follow-up — 2026-09-14

Baseline `ca04e05`, Godot 4.7.1. Ordinary Game in a separate QA project/profile;
no original player saves changed and no completion setters used. The deep profile
contains previously earned progress. This round continues the bounded final plan.

## Player observations and changes

- Chapter 2 completed capstone: physically typed an unsupported draft. It stayed
  unapplied, survived map return, English→Chinese change, normal quit and restart.
  Fixed legacy editor unlock and pinned Mission footer now observed in the native UI.
- Returning to the tree moved the selected task offscreen. Preserve the last valid
  canvas dimensions across scene reconstruction; skip temporary zero-size layouts.
  Native re-entry now retains the selected node and test covers a manually panned view.
- Unsupported source showed both a syntax error and "Program is empty". Hide the
  redundant empty-program message only in presentation when other errors exist.
  Truly empty drafts retain the empty message; parser/model fingerprints unchanged.
- Chapter 1 optional task displayed 6/5. Header denominator now comes from its actual
  seven-task catalog in both languages. Native restored task displays 6/7.
- Clicking a covered tool first hid it unseen, requiring a second click. All five
  hosts now share recall behavior: raise/restore covered or minimized tools, while
  an unobscured visible tool retains toggle-to-close. Native Chapter 1 Mission/Program
  and Chapter 3 Mission/timeline recall succeed with one click.

## Actual player results

Chapter 1 `read_once`: removed the second load line by keyboard, applied the modified
source and ran all official cases. 5/5 passed. The 16-input case takes 270 cycles,
17 memory requests; small cases show 30 cycles/2 requests and 62 cycles/4 requests.
Opened the conclusion, returned to the tree, normally quit/restarted and recovered
both the edited program and earned completion. No reference solution was injected.

Chapter 3 `buffers`: reran the previously earned board via "Run all tasks".
28 total cycles, 16 compute, 24 transport, 12 overlap; output 46/46. Inspected the
actual transport/compute timeline and recalled Mission from underneath it.

Chapter 4 `mixed`: reran the saved batch-copy layout with temperature/alarm and batch
size four. Both orders pass: A 1364 cycles, 448 B reads/136 B writes; B 1131 cycles,
512 B reads/136 B writes, both peak 32 B. Switched source/temporary memory views and
inspected record/field/value labels and four-record copy. These are reruns of a saved
player layout, not a claim to have newly solved every Chapter 4 task this turn.

Windowed source at the enforced minimum: attempted further shrinking, controls remain
inside the window; returned fullscreen and navigated again. F10 opens shared settings
from the map and Chapter 4; settings have visible Resume/Quit controls. This does not
replace extended mixed-DPI/focus stress or another device's installation checks.

## Automated checks

`20260913T155504Z-e37e8331`: tree presentation, tree and locality UI pass. A new
empty-editor assertion initially needed its change callback invoked after programmatic
assignment; corrected test passes (`targeted-1789314956`).
`20260913T160135Z-5561acad`: all 37 existing suites pass. New floating-tool test first
hit a test-only native-class name collision, then a preload-before-autoload boundary.
Load the panel after autoload initialization; final added suite passes in
`targeted-1789315479`. No runtime/simulation change was needed for these test fixtures.

Final exported-candidate mouse walkthrough remains to be recorded below.
