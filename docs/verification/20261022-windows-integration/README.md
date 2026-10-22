# Windows integration verification — 2026-10-22

## Integrated behavior
The recovered component visuals, operation demonstrations and journey relations retain the docked guidance, real specification table and window design from the local guide-convergence changes. Demonstrations use a dark rounded pointer with a soft white outline, blue halo, light gesture path and click pulse, visually distinct from the player cursor. The compact guide does not grow when replay starts. Detailed gesture text is available on hover.

The first NOT lesson keeps its wiring step until both actual connections exist. The demonstration follows settled port positions and stops when modal UI, reading/help, resizing or guide folding interrupts it. Half-adder guidance refers to its existing components and the specification question.

## Provenance
- Recovery archive: `游戏最新代码恢复包_fddfefc_20261022.zip`, SHA-256 `9aec461049b97c7aeba8b5fb63f377a7523685156e555093a5894d2b2150210d`.
- Verified bundle SHA-256: `1da9c2d62cfb11f2914d46d4eebd11520444f85ad3cf6588bb050182ba520341`.
- Recovered commit: `fddfefc2d3f9ea907f0814570a1e88316ad78aa4`, tree `7ca3143b1741a974b681a408ca8dac19f1455955`, based on `a5965e3`.
- Local guide/window changes preserved as a binary patch and 120 byte-hashed untracked files before integration. Prior local and Linux verification folders remain historical evidence for their own trees.
- `source-manifest.json` identifies the final source used for Windows verification. The isolated snapshot modifies only Godot user-directory settings to protect player saves.

## Verification
- Full Windows run: 215 Godot suites plus import/user-directory gates (217 stages). Two legacy fixtures failed because they set only the wire-created flag without creating the two connections now required by the corrected guidance. Both fixtures now connect the actual graph; all five related suites and both gates passed in `focused-recheck`. No production behavior was weakened to satisfy the fixtures.
- Final pointer drawing change: three related suites and both isolation gates passed in `pointer-recheck`. This is a focused rerun, not a second full run.
- Chinese and English actual GPU viewport-input replays each passed 112 checks. The final rounded pointer received a further Chinese GPU replay: 112 checks, zero failures. `render-rounded/zh_CN-not-entry.png` is the final cursor appearance. Earlier render folders preserve the prior violet appearance as iteration evidence.
- Python: all 14 selected checks passed after rerunning four local HTTP suites outside the sandbox. Original WinError 10013 failures and the stopped blocked maintenance process are preserved in `python-final`; successful local-loopback retries are in `python-loopback-retry`.
- Native Windows input: the recovered baseline tutorial was completed through wiring, input toggle, F6, removal and reconnection. On the integrated build, terminal entry, first wire remaining on step 1, replay targeting the missing second wire, and both wires advancing to step 2 were observed directly. Native play was interrupted twice by physical Escape and later by concurrent user input; this is not a claim of a complete final native playthrough. The final shape-only change was checked by the GPU replay above.
- Independent source review found no concrete loss of either feature set. The 120 original new local files match their preservation hashes. The original local work is also preserved on `claude/guide-convergence-20261021` at `bbe7a77`.
- GPU: NVIDIA GeForce RTX 5070 Ti Laptop GPU, OpenGL compatibility renderer. No new final performance benchmark or exported binary acceptance is claimed.

The `half-adder-entry` replay image is captured after testing an empty palette search and recovery, so its status bar retains that preceding recovery message. It is not an untouched initial-entry screenshot.

## Scope
Automated viewport input is distinct from native mouse/keyboard play. Representative play does not establish all 60 tasks, newcomer comprehension, audio quality or exported-package acceptance. No release or new exported package is part of this source integration.
