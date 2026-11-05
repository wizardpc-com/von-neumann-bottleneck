# Round 5 English raw-frame review

Reviewer: `/root/review_records_final`

Inspected all **nine** final English PNGs under
`docs/verification/20261104-layout-notebook/frames/` with `view_image`.
PNG headers independently confirm the declared 1280×720 and 960×640 sizes.
No image was resized or edited. No engine, native UI or Git operation was run.

## Finding

**[P3] Distinguish a different selected run from an unmeasured draft.**

Source: `experiments/layout_strategy/lab.gd:563`; selection predicate:
`experiments/layout_strategy/session.gd:189-191`.

Both `layout-notebook-en-notebook-1280.png` and
`layout-notebook-en-notebook-960.png` display **“Draft has not been measured.”**
while the current group8/tile1 draft has already been measured and retained as
“分组 / Grouped” in the same visible table (Q1 531, total 552, RAM 272, copy 0).
The player has selected the other retained recipe, so the selected evidence
differs from the draft. The notebook's nearby “Keep run #4's recipe; the draft
differs” correctly describes that state; the left-side status incorrectly says
the draft was never measured.

The existing fixture establishes this exact path: it measures and keeps the
grouped draft at notebook UI test lines105-109, inspects the early-response
recipe, restores it, then Undoes back to the already measured grouped draft at
lines145-153. `session.is_stale()` only means selected-plan mismatch or no
selection; it does not search historical measurements.

Suggested bounded correction: keep “not measured” for an empty selection if
desired, but use “Draft differs from the selected run” / “草稿与所选运行不同”
for the nonempty stale-selection case. A narrow assertion on this existing
selection/Undo fixture can prevent the false wording from returning. No metric,
simulation or save-format change is needed.

This visual finding supplements the earlier source-only integration review.
No other actionable label or geometry issue was found in these frames.

## Frame inspection

| Frame | Raw size | Observed result |
| --- | --- | --- |
| `layout-notebook-en-notebook-1280.png` | 1280×720 | Goal/objective, measured columns, saved-state scope and actions fit. Stale-selection status finding above. |
| `layout-notebook-en-notebook-960.png` | 960×640 | Goal controls, table metrics, actions, name field and save scope remain readable and on-screen. Long recipe name uses a visible ellipsis; full name is available in the source-defined tooltip. Same status finding. |
| `layout-notebook-en-save-failure-960.png` | 960×640 | Failure guard wraps its explanation, states changes remain in memory, and shows all three exit choices without overlap; Save-and-exit focus is visible. |
| `layout-strategy-en-compare-1280.png` | 1280×720 | Actual values, selected-run identity, baseline marker and signed comparison are readable; controls fit. |
| `layout-strategy-en-compare-960.png` | 960×640 | All six table columns and comparison values remain visible; no action is clipped. |
| `layout-strategy-en-evidence-1280.png` | 1280×720 | Event table and selected-event identity are readable; the detail panel is visibly scrollable. |
| `layout-strategy-en-evidence-960.png` | 960×640 | Event table, selector and detail panel fit. Partial JSON at the scroll viewport boundary is ordinary scroll content, not a missing control. |
| `layout-strategy-en-public-960.png` | 960×640 | Q1 definition, admission contract and memory-cost explanation wrap within the scroll panel. Remaining content is available below the visible scroll boundary. |
| `layout-strategy-en-quit-960.png` | 960×640 | Dirty-workspace explanation and all three actions fit; modal focus is visible. |

Static frames cannot verify actual hover, scrolling, pointer behavior or
cross-platform rendering. Root's GPU tests and separate native acceptance retain
those boundaries.

## Reviewed frame SHA-256

```text
f337b5488a71ae2f9ea341635bad6aaf4d4483b446484522f77497343b117f5b  layout-notebook-en-notebook-1280.png
86bf7e6f7230be89d77a610e381513e4a7b6e370a501de1fe4e9f9b2b4e3d0e0  layout-notebook-en-notebook-960.png
f5480dad2080d92beb78e1e33f0d741aa6a4f926f43ec4037beb3ee470bcca5c  layout-notebook-en-save-failure-960.png
66f28f3c90b14590212d9568faa75964b17f47b6d9d547efd59b600f7cf71f90  layout-strategy-en-compare-1280.png
b6d6638fd60ada0a371a42dc872b821eb2b2db7f0847da83158bcbe423870d15  layout-strategy-en-compare-960.png
92506062578d7693bf1abb81c6343a607024aff09142ff5fd9e31a0084a1e6e2  layout-strategy-en-evidence-1280.png
e1ae10702af320590c9ef7928e9a972f779cabb546357c08a4c46c570fde7803  layout-strategy-en-evidence-960.png
77188b469c7c137704a39bc0799546a4bf6eac68b72d65373572ff3a65d03145  layout-strategy-en-public-960.png
8b78bf164f8daf2c0878214a0156a7a278be4a3f3c1febb3a3eaea5de611d9be  layout-strategy-en-quit-960.png
```
