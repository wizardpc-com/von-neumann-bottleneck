# 上午延长轮状态 2026-10-22

用户将独立云电脑优化延长至北京时间 11:00 左右，并要求 Markdown 汇报。
上午功能提交 `f40bf89` 修复原生试玩发现的 F6 教学同步和关闭工具面板后演示无反馈；
六个针对性套件已通过；10:20 完成本轮 214 个套件的单次不中断全量回归，
连同导入与用户目录检查共 216/216 阶段通过。9 项 Python 检查通过。
从同一已通过快照重新导出候选程序，见 [全量结果](morning-full/results.json)
和 [包回执](morning-full/package-receipt.json)。此前 09:20 状态保留为历史记录。

现在已有局部 Linux 原生鼠标/键盘试玩证据，不能再把“没有图形环境”当作当前状态。
半加器、全加器、SR 锁存器和一位寄存器均通过真实连接、正式测试和显式封装；
仍不是全部 60 项任务、Windows 性能或音效验收。
详见 [原生试玩记录](linux-desktop-smoke.md) 与 [上午针对性检查](morning-focused/results.json)。

实际渲染发现云端 llvmpipe 房间约 2.8–2.9 FPS，终端约 60 FPS；
两组降低画质的隔离试验不足以达到流畅目标，未并入生产版本。
详见 [真实渲染与低负载对照](morning-render/README.md)。

GitHub 上传取消后的重新授权仍未收到；本地提交不代表 main 已更新。

以下为逐轮历史记录，阅读时以每节日期及验证范围为准。

---

# Overnight candidate — work in progress

Baseline main: a5965e3725638cb87e93ffb0a05b95abe12c4dba.
Branch: codex/component-visual-v2-20261022.
Owner: Ray, cloud computer only; no delegated implementation.
Deadline requested: 2026-10-22 09:20 Beijing.

This is a candidate, not a release or a claim of competition readiness.
The original Windows fullscreen-terminal acceptance belongs to the baseline;
its FPS measurements do not certify this candidate or the cloud environment.

## Current scoped work
- Non-interactive virtual mouse demonstration anchored to real ports/controls.
  Watching never creates wires, changes inputs, or awards completion. Actual
  input interrupts it; one-shot first lesson, replay, stop and reduced motion.
- Distributed prologue operation curriculum and shorter first-lesson reading.
- Direct prerequisite/downstream/recommendation tracing on the existing map.
- Independent frozen visual layout at successful sealing. Existing signatures,
  official verification and dependency invalidation remain authoritative.
- Shared low-saturation component families, distinct selected outline and system
  CPU waiting marker. No decorative fake CPU pins.

## Verification evidence (not final)
Focused runs are under .godot/verification and retained locally. First pure
layout and sealing/save tests passed; eight guide/tree suites had one new-test
compile failure due to early autoload preload, repaired to runtime load.
Full regression captured at 17:52 UTC completed at 18:13 UTC: all 208 executed
Godot suites plus import and isolated-user-directory checks passed (210 stages).
The native GUI recovery test is deliberately excluded by the headless verifier.
Source edits after capture were checked in focused regressions. New persistence
fixture setup and JSON numeric equality assertions were repaired; the latest
persistence/UI rerun at 18:21 UTC passes. A second full isolated regression started
at 18:26 UTC and finished at 18:48 UTC: all 210 executed Godot suites plus
import/user-directory checks passed (212 stages). Changes made after that capture
are now undergoing 11 targeted suites; this full pass does not cover those edits.

## Known limits
No DISPLAY/Wayland service in this cloud executor. Prior rejected display-service
operations are not retried. Headless input/layout tests are not screenshots,
native desktop play or FPS measurement. SVG/PNG design previews will be explicitly
labelled, not passed off as rendered game frames. Visual review remains open.
Main integration is authorized at the final 09:20 delivery, subject to fresh
validation and latest-head reconciliation. No public release, external feedback
submission or competition upload.

## Save compatibility design
The new reusable `visual_snapshot` is an additive presentation field, excluded
from `canonical_signature()` and generated-wrapper metadata. Restore first runs
existing source/provenance/official verification, then validates the optional
visual record. Unknown schema, wrong source, non-finite or out-of-range occupancy,
wrong checksum and malformed envelopes fall back to the standard family shape.
Old versions may discard the optional visual extension when rewriting a save;
they retain the unchanged logical component. No old layout is reconstructed from
current workbench coordinates and falsely presented as historical placement.

## Learning distribution
NOT retains wire/input/run/remove/reconnect. The optional long edit/undo page is
introduced with FullAdder; pan/zoom with Register. Each registered prologue task
has a separate short operation focus. These are instructional content, not new
completion requirements. Full curriculum and pointer acceptance still need a
newcomer review; automated interaction checks cannot establish comprehension.

## Not yet done
- The virtual pointer currently demonstrates the first NOT wiring/input/run/remove
  gestures and generic placement/testing. Later per-level operation tips are
  distributed text, not yet a separately animated demonstration for every skill.
- Layout-derived visuals currently cover frozen snapshots, canvas rows and palette
  previews. A real saved-work preview is integrated into the Journal. The separate plan
  preview helper is tested but not yet connected to a plan browser; full Handbook
  review remains open.
- Candidate SVG export is a design-review pipeline, not actual Godot rendering.
  The manifest exports 26 current interface contracts and two explicitly labelled
  geometric fixtures. 54 SVGs and PNGs were generated and the default contact sheet
  inspected. Broken lead endpoints in the review renderer were corrected to use
  polygon intersections. System devices have no invented ports. The preview
  renderer does not establish actual gameplay appearance or style acceptance.
- Overall fun, pacing, all-level newcomer understanding and final submission
  readiness require review beyond these automated checks.

### Existing library boundary
The existing game keeps one active definition per named reward (for example
HalfAdder), not a new unrestricted multi-version component factory. Resealing the
same logical reward deliberately updates that definition's frozen presentation;
instances resolving that current definition use the same shape. Merely moving or
renaming a workbench does not update it. This candidate does not claim simultaneous
independent historical visual versions for identical reward identities. Supporting
that would require a separately reviewed instance-presentation identity design,
without adding visual fields to signed LogicComponent properties.

## Additional graphical route check
A local Web-export/browser route was investigated without changing the display
service or security settings. The installed Chromium could not create its local
process socket in the restricted executor. A sandbox-enabled isolated-profile
launch under the permitted escalation mechanism failed before browser startup
because the environment wrapper could not initialize. No browser play or WebGL
result was obtained; no sandbox disabling or restricted-path access was attempted.
Official 4.7.1 export templates were downloaded from the verified Godot release
and SHA512-checked against its checksum manifest. Only Web and Windows templates
were extracted into the cloud tools directory for reproducible packaging.
Packaging alone will not establish native or web gameplay acceptance.

## First checkpoint (18:52 UTC)
Post-capture focused run passed 10/11 suites; the only failure was compact dialog
height. Duplicate copy was removed, then UI/exploration/hint suites all passed.
The compact-size assertion was retained unchanged. Shared row geometry has 850
passing boundary/triangulation/hit-test checks. The 60-task bilingual map review
exports current production positions and connections, not rendered game frames.
Source hashes identify this checkpoint; later changes require new verification.

## Later regression and usability fixes
The 20:20 UTC snapshot passed 213 headless suites plus import and user-directory
checks (215 stages). A matching Windows x86_64 embedded-PCK export was generated
and structurally checked, but has not been played natively. Subsequent focused
runs verify guide completion evidence, wire-cut geometry, offscreen demo fallback,
1,055 layout checks, and 851 component geometry checks.

The expanded task-detail panel exposed an English 1280×720 usability failure:
its scroll viewport collapsed to 2 px. Secondary actions were combined into one
row and typography/spacing adjusted without removing content or weakening tests.
The 20:54 UTC isolated run passes all three map suites, including focus-scroll
navigation to incoming recommendations and suggested successors. A fresh full
regression is still required for the combined candidate.

## Combined candidate at 21:46 UTC
Snapshot `20261021T212049Z-b54114ec`, corresponding to local source checkpoint
`7314ccc`, passed all 213 suites plus import and isolated-user-directory checks.
The fifth-regression source manifest compares 58 changed source/test/tool files
byte-for-byte with that tested snapshot. Every one of the sixty tasks retains at
least 100 px of detail-reading space in both languages at 1280×720.

A Windows x86_64 executable was exported from this exact snapshot using the
verified official 4.7.1 release template. Its embedded PCK also booted for 120
frames under the matching Linux headless engine with exit 0 and no errors, in a
fresh isolated user-data directory. This checks exported startup/resource loading,
not Windows execution, graphical interaction, performance, or player enjoyment.
Package SHA256: `7bd0665aac83177447ec74c0f8f3d9286b45830d3f73f599acbed404f16b6357`.

Publication is not complete. The GitHub tree-upload operation was cancelled;
no remote branch or main update is claimed. Local commits and a verified recovery
bundle preserve the work while renewed upload approval is pending.

The same exported PCK also passed first-tutorial input (46 checks), bilingual map
navigation/layout (3,308), creation save input (40), and terminal navigation soak
(162) under the Linux headless host. Across eight navigation cycles there were
1,489 nodes and zero orphan nodes each time. A global-save fixture failed when
using its source-tree res:// scratch path in the packed application; changing
only that fixture directory to isolated user:// passed all unchanged assertions.
The source test now uses user:// as well. Failed and corrected outcomes are both
recorded in packed-checks.json. These remain controller/input-event checks, not
native mouse, GPU rendering, Windows performance, or a fresh human playthrough.

An additional accepted-test-mode core-path fixture exercises the ending-review
footer, then visits all sixty tasks in both locales. All 369 assertions pass,
including >=100 px task-reading space, on-screen review controls, and unchanged
real game progress. The isolated source global-save suite also passes with its
corrected user:// fixture namespace. These are supplemental tests after the full
snapshot; production source and the exported package have not changed.

## Final supplemental coverage at 23:51 UTC
After a cloud execution-environment restart interrupted an additional full run,
the remaining suites were completed in two isolated batches. The combined record
covers all 214 current headless suites, with 1,025 source/test/tool files checked
byte-for-byte identical across the three snapshots. This is combined coverage,
not an uninterrupted full run. The earlier completed 213-suite full snapshot and
its Windows package remain valid; subsequent changes are tests and evidence only.
