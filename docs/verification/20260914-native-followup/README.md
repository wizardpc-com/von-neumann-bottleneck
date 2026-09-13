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

## Frozen candidate and remaining boundary

Final content: `3b0afc5a4234`; candidate `free-alpha-3b0afc5a4234`.
Both archives and all file hashes/packaged notes pass identity checks. Actual Mac
release runtime probe passes, including 40 tasks, Game-only features, empty/off remote
endpoint and exact source/export workspace fingerprints (`package-qa/76c32bae8fe7`).

The QA-only copy uses a unique app identity and isolated fresh user directory. Its
actual Chinese hub visibly shows the correct candidate ID, one initially available
region, locked later regions and disabled Continue. App discovery stalled for about
27 minutes before returning the visible window. Both mouse entry attempts returned
`noWindowsAvailable`, including after accessibility Raise. The screenshot remains a
normal hub. This is not sufficient evidence of a game input bug, nor of a successful
candidate mouse walkthrough. No speculative game change was made to work around it.

Source-native interaction/restart checks are complete as recorded above; the final
export's mouse/quit/Continue path remains pending manual verification on this Mac.
Windows native, another Mac installation and extended DPI/focus/newcomer checks remain
separate. The user requested stopping changes once no further major issues are found;
implementation stops here, with the candidate and explicit acceptance boundaries.


| Platform | ZIP SHA-256 |
|---|---|
| macOS | `7dafc172660ca896b215b62ccf91923b48b9e4c46f08222b360034e4a7687139` |
| Windows | `eff8b3e2c8b25f1dc3caee8ea2b5cab0d79bdc86a9606cf231c4a2215e4b17be` |

Final hosted CI passes, including all 38 Godot suites and Python contracts:
https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/34767778611
Original player data remains byte-identical across all 18 backed-up files.
The candidate QA process was stopped from its idle hub after the control-tool
failure; this does not count as an in-game quit/restart test.
