# Simplified first screen — verified checkpoint

Runtime **5efc8ec**, Mac **free-alpha-5efc8ecb3d1f**, isolated profile **Home-5efc8ec**.
Supersedes the intermediate dashboard efc2d9d. User explicitly requested fewer
choices: homepage now has one Start/Continue primary plus Choose journey.
Language/settings/fullscreen remain in the header. Chapters, candidate stages,
New Game, handbook and reviews live on a separate fixed selection page; Escape
returns with focus restored. Readable type, static machine art and guarded save
warnings remain. No model, progression, save format or new content change.

- Frozen9 affected suites/import/isolation PASS,2110 source files exact and checkout
  clean: [receipt](regression/receipt.json), all full logs retained/inspected.
- Rendered16 actual frames, ordinary/candidate × zh/en ×1280x720/1600x900 ×home/selection:
  [images](rendered/), PASS5473checks, all individually inspected. No overflow,
  clipping, overlapping buttons or scroll needed; minimum font14/button40 retained.
- Export/import/licenses and identity PASS; actual Mac binary14 checks PASS:
  [manifest](package/manifest.json), [probe](package/probe.log).
- Actual native launch, Tab/Return selector, Escape/focus return, Shift+Tab/Return
  task-tree entry observed: [native evidence and limits](native/observation.md).
  Only own QA profiles archived, with byte identity; delivered profile fresh.

ZIP SHA256: `0aaab165a5fe3f14cbe01045ee122ddccefd3e5f8c46f9d4723d648c1b05c7dd`.
App: `build/free-alpha-5efc8ecb3d1f/macOS/Von-Neumann-Bottleneck.app`.
[Team route/Claude interfaces](../20261006-completion/TEAM_REVIEW.md) continue to
apply; homepage art is additionally isolated in `src/ui/hub_machine_art.gd`.

Intermediate failures and first-dashboard evidence are retained under intermediate:
observer internal-label mistake, rejected fullscreen-size capture, actual English
8px recovery overflow repaired with spacing, and first native capture limitation.
They are not final acceptance. The final three-suite live run is in targeted/.
No repeated full campaign, listening, unfamiliar-player or other-device acceptance.
Prior closure evidence remains specific to runtime10211e5 and is not relabeled.
