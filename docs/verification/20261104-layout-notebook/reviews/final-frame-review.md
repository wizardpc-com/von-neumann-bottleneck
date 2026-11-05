# Round 5 final English raw-frame review

Reviewer: `/root/review_records_final`

**Result: prior P3 stale-selection wording finding is resolved. No actionable
remaining label or geometry defect was found in the nine final English frames.**

All nine current PNGs in
`docs/verification/20261104-layout-notebook/frames/` were opened again with
`view_image`, including frames whose bytes match the earlier capture. This
review did not reuse the previous visual conclusion without viewing them.
PNG header dimensions were also checked with Python's standard library.

## Correction verification

- Both Notebook sizes now show **“Draft differs from the selected run.”** when
  the grouped draft is present but the early-response recipe is selected. This
  accurately describes the visible draft/evidence relationship and resolves the
  finding in `/private/tmp/vnb-round5-frame-review.md`.
- Both Compare sizes now show **“Total rank”**, making the current comparison
  objective explicit. The longer header remains fully visible at 960×640.
- Source at `experiments/layout_strategy/lab.gd:536` selects “Total rank” or
  “RAM rank” from the current objective; lines566-571 distinguish empty selection,
  selected-run mismatch and a matching measurement. The final frames show the
  total-rank branch; the RAM-rank branch was source-inspected, not separately
  captured in this nine-frame set.

## Full frame pass

| Final frame | Raw dimensions | Review |
| --- | --- | --- |
| `layout-notebook-en-notebook-1280.png` | 1280×720 | Corrected draft status, objective/caps, measured values, actions and saved-scope text are readable. |
| `layout-notebook-en-notebook-960.png` | 960×640 | Corrected status fits; caps, all metric columns, name input and actions remain on-screen. Long name uses an ordinary visible ellipsis. |
| `layout-notebook-en-save-failure-960.png` | 960×640 | Failure explanation and all three choices fit; memory retention and focused Save-and-exit remain clear. |
| `layout-strategy-en-compare-1280.png` | 1280×720 | Total-rank heading, selected-run identity, signed comparison and controls fit. |
| `layout-strategy-en-compare-960.png` | 960×640 | Total-rank heading and all metrics remain readable without clipping. |
| `layout-strategy-en-evidence-1280.png` | 1280×720 | Event columns, selected-event description and scrollable details fit. |
| `layout-strategy-en-evidence-960.png` | 960×640 | Event controls and details fit; partial JSON at the bottom is within the visible scroll boundary. |
| `layout-strategy-en-public-960.png` | 960×640 | Workload/admission/Q1 definitions and costs wrap within the scroll panel. |
| `layout-strategy-en-quit-960.png` | 960×640 | Dirty-workspace explanation and three exit actions are unobstructed. |

This is static inspection of root-generated GPU evidence. It does not claim
native pointer/hover/scroll acceptance, a new engine run by this reviewer,
cross-platform rendering, export validation or persistence durability.
No implementation/test/image/Git files were changed. The original frame review
and its original evidence remain intact.

## Final source/frame binding

```text
c0d4c5003c67350291458caf1d181ee329c3ae9a0eec129d29716e500032dc2e  experiments/layout_strategy/lab.gd
b9f0176830366de16ccf73f702a9878ab07375158f126d0708c82885501deeaf  layout-notebook-en-notebook-1280.png
076ff440e76d09a54ccd3c956fa98611d55c2ebc2e4f837456bbf93bed5440f4  layout-notebook-en-notebook-960.png
0504cf8b64c1dd01e719e46e1c7066b8d2b734dd58df1aadf3e2c392bb754e43  layout-notebook-en-save-failure-960.png
d76959b1e0760df87c326c483b43c460f76c8c9aed4b18d69cb288e2cd49c2fb  layout-strategy-en-compare-1280.png
915cb96affc53c2c5e574636b2e4d4a84c4d334731816fa7cedbf19e3f0108f9  layout-strategy-en-compare-960.png
92506062578d7693bf1abb81c6343a607024aff09142ff5fd9e31a0084a1e6e2  layout-strategy-en-evidence-1280.png
e1ae10702af320590c9ef7928e9a972f779cabb546357c08a4c46c570fde7803  layout-strategy-en-evidence-960.png
77188b469c7c137704a39bc0799546a4bf6eac68b72d65373572ff3a65d03145  layout-strategy-en-public-960.png
8b78bf164f8daf2c0878214a0156a7a278be4a3f3c1febb3a3eaea5de611d9be  layout-strategy-en-quit-960.png
```
