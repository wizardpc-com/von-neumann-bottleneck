# Round7 Chinese regression raw-frame review

Reviewer `/root/audit_scores`, 2026-11-05. Read-only assignment from
`.godot/collaboration/round7-visual-review.md`. No source/test edit, engine run,
native input or Git operation was performed. Only this report was written.

**No actionable visual issue was found in the14 assigned original Chinese
frames.** Every listed PNG was opened directly with `view_image`; inspection
was based on original pixels, not DOM, layout metrics, a montage or generated
replacement images. No image was modified.

## Scope and observed layout

- Original scheduling UI:6 Chinese frames. The1280×720 and960×640 comparison
  views preserve all metric columns, selection visibility and main controls.
  The shown531/552/272/0 versus307/2456/2176/0 results and Q1+224/total−1904/
  RAM−1904/copy0 delta read consistently. Evidence tables keep selection and
  event details distinct; long JSON continues in a visibly scrollable pane.
  The public reader states that Q1 is the first submitted request and describes
  actual costs and bounded copy allocation. The exit dialog has three fully
  visible choices with a clear keyboard-focus outline.
- Notebook UI:3 Chinese frames. Goal selector, Q1/copy limits, saved state,
  rank, save/load/remove and naming controls remain visible at960×640. The
  long bilingual retained name is deliberately ellipsized within its name
  column; it does not collide with numbers or hide a primary action. The
  failure exit dialog distinguishes another writer from an actual save and
  states that changes remain in memory; its three actions fit the modal.
- Challenge UI:5 Chinese frames. Selected code has readable light text over a
  blue selection. Exported personal conditions and the accepted challenge's
  conditions are visually separate. The saved target and measured−1088-cycle
  improvement are readable in the popup and root view. The720×540 import
  popup wraps the code and keeps preview/retest, replace target and back
  controls fully visible. The retry-completed frame clearly says the target
  is saved and shows its RAM objective separately from the personal cycle
  objective. The contextual starter remains inside the visible popup.

Disabled copy choices in source-only mode remain visibly dormant and the
nearby text explains that their choices are retained. The scrollable event
text and long-name ellipsis above are intentional overflow presentation,
not evidence of a clipped required control. No overlapping text, illegible
selection, off-frame primary action or contradictory visible saved state was
observed in this bounded capture set.

Root owns the seven new Chinese `structures_ui` frames; the English reviewer
owns all English frames. Neither is included in this14-frame conclusion.

## Complete batch and execution evidence

Batch: `.godot/verification/20261105T051242Z-1f038f6c/gpu/20261105T061535Z`.
The final `results.json` contains all four requested suites with exit0,
`passed=true`, and no recorded errors. The three original suite logs were
read, including their completed result lines:

| Original suite | Observed result | Chinese frames reviewed |
| --- | --- | ---: |
| `test_layout_strategy_ui` |246 checks,0 failures |6 |
| `test_layout_strategy_notebook_ui` |177 checks,0 failures |3 |
| `test_layout_strategy_challenge_ui` |282 checks,0 failures |5 |

The logs identify Godot4.7.1 and OpenGL4.1 Metal Compatibility on Apple M2.
This is root-scripted GPU evidence. It is not native mouse/keyboard acceptance,
exported-package acceptance, cross-platform evidence or newcomer testing.
A screenshot establishes visibility and legibility, not that an action was
manually activated; the separate scripted suites own their interaction checks.

## Exact original files inspected

File suffixes refer to the root capture scenario, not always the actual popup
size. The PNG dimensions below are read from the original headers; in
particular the import popup is720×540, while ordinary challenge popups are
820×580.

| Original absolute PNG path | Actual pixels | SHA256 |
| --- | --- | --- |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_ui/layout-strategy-zh_CN-evidence-1280.png` | 1280×720 | `caa4ca0e9924478040174d4f6728b9a3be7f86dd0b5d0ba8d798146ff39fd557` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_ui/layout-strategy-zh_CN-compare-1280.png` | 1280×720 | `201aadf3555a1f8a1522d9766214b14d0ce55a242781ac3bf4bf7d75bf94442b` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_ui/layout-strategy-zh_CN-compare-960.png` | 960×640 | `ab4fd7ade40a447545736e5cafdd188eabdc263d4fc1a815ba25037a2ca954fc` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_ui/layout-strategy-zh_CN-evidence-960.png` | 960×640 | `492b79eacf23701601ad8f5f0d6f8b03caa38d6121a921d2db177892e53f14c3` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_ui/layout-strategy-zh_CN-public-960.png` | 960×640 | `2249df6dc150786a6b91705fb876b97816efa5e08b682ffafbf5c679d23abedd` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_ui/layout-strategy-zh_CN-quit-960.png` | 960×640 | `e2870e19285cdc432e5450509b320c68d69397f7dc1c30ed505c6b3544996455` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_notebook_ui/layout-notebook-zh_CN-notebook-1280.png` | 1280×720 | `921177e2ecf70e495ead559be7dec8110275a742ed3b8a95c9feae39d83a990d` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_notebook_ui/layout-notebook-zh_CN-notebook-960.png` | 960×640 | `b35f1c2bff9d99a09049fd29f66fd6063fc0810e52486e25247e3be5bbd79334` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_notebook_ui/layout-notebook-zh_CN-save-failure-960.png` | 960×640 | `5728b777289e45b592d8c41e58b8bace0a4887499e0b4d6898d84977f3b52b53` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_challenge_ui/layout-challenge-zh_CN-share-1280.png` | 820×580 | `87b7b0827310e375328accc3dd5840588de9c00efa6e34a23b0e1468fb7db0c5` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_challenge_ui/layout-challenge-zh_CN-target-1280.png` | 820×580 | `505e72caeb691d06d91c357699e9f9aca5583497d07cc1298fa4ca119e54b3e0` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_challenge_ui/layout-challenge-zh_CN-active-960.png` | 960×640 | `c5d0cb982f02e6deb00f0de487087fe3aa372f98cea96d63b93d9eaf28e7c3e4` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_challenge_ui/layout-challenge-zh_CN-import-960.png` | 720×540 | `2af580bf4cc8bee260c4f2f587662cfd7bb1bdcc25304559895671e09349a7ac` |
| `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261105-round7/20261105T061535Z/test_layout_strategy_challenge_ui/layout-challenge-zh_CN-saved-retry-960.png` | 820×580 | `0a9c16c0ede7f2f00becf737391648b39c00c07687ee35685fc4410da3df0920` |

All14 expected Chinese CAPTURE paths from the three completed original logs
are listed above exactly once. Review complete; no source repair requested.
