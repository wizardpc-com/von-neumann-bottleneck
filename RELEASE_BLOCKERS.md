## 当前分发判断 · 2026-11-22

用户已将 `66e1bf0` 的四个离线包定为内部回退基线。新版源码与线上反馈接入分别验收；本轮的工作区改进尚未形成可交付的新包。

| 玩家或维护者需要完成的事 | 当前门禁 |
| --- | --- |
| 从教程进入独立谜题，读懂失败并修正，再用已做出的元件完成下一步 | 检查最新源码的半加器实测与期望、正式用例输入和改线后重新调试。首次玩家独立完成仍待观察。 |
| 在章节里尝试不同策略，看到差别并保留自己的选择 | 核对第 1 章自定义工作负载的调试判词、第 2 章同一缓存行重复取数、第 7 章历史记录归属与创造作品选择。以对应路径的实际画面和测量结果为据。 |
| 从未完成的任务提交意见，断网后继续游玩，重启后查到真实回执 | 工作区已有表单、队列和独立试用配置。新版本的隔离实测与最终平台实包需分别记录。已验收的公网入口只允许指定来源的合成测试；真人说明页目前只在仓库准备。 |
| 在目标电脑下载并启动，跨会话保存与恢复 | 继续按 Game/Test 与真实玩家/合成 QA 各自隔离。需以实际新包核对 Windows 原生、macOS、首次下载提示及保存；签名、公证和其他机型按实际证据披露。 |

[当前验收计划](docs/exec-plans/active/20261122-player-experience.md) · [反馈上线边界](docs/development/PLAYER_FEEDBACK_ROLLOUT.md) · [内部基线](docs/verification/20261122-player-release/README.md)

## Product closeout · 2026-11-16

The user authorizes final art selection, commit/push main and delivery of four
same-source Game/Test Windows/macOS archives. Earlier “no public release authority”
notes below describe their historical tasks, not this delivery authorization.
The current integration receipt is [here](docs/verification/20261116-final-product/README.md).

Four v0.6.0 archives are delivered from product source63584487c1af. Source/controller
checks, both actual exported Mac probes, representative native Mac tutorial/return,
and four-package architecture/icon/identity/hash checks passed. Native Windows input,
Intel Mac execution and downloaded first launch on another machine remain open.
Do not claim human sixty-task completion or other-machine first launch from agent
replay. Developer ID/notarization and Authenticode are unavailable in this build;
packages disclose their actual signing state. No online service is required or deployed.
The existing identical-parent/recipe Fork ambiguity remains documented without a
silent schema change. No known blocker may be hidden by a “release ready” label.

# Release acceptance gates

Current source and artifact: [CURRENT_STATE](docs/CURRENT_STATE.md).
These are remaining acceptance requirements, not instructions to add features.

## Team closeout — 2026-10-19

The current main includes the laboratory journey and retained Claude layout,
guidance and copy iterations. [Team handoff](docs/development/team-handoff.md) and
[current verification](docs/verification/20261019-team-closeout/README.md) define
the Windows offline team build. Its all-entrance profile retains normal Game
completion rules. This round does not authorize a public Release.

Human pointer experience, unfamiliar-player comprehension, high-DPI/other-machine
checks, Mac and final artistic decisions remain separate. The original reported
crash has no stack trace; tooltip/event regressions are verified with synthetic
viewport input and do not certify that original OS crash reproduction.

The dated sections below are historical and do not identify current branches.

## Night candidate gates — 2026-10-18

PR10 is merged at `bf8f616`; the new experience candidate remains a separate
review branch. The public download remains the October17 offline Pre-release.
Normal and all-entrance tester packages use distinct nightly profiles so neither
automatically opens the older tester saves. Exact current package identity,
controller/native scope and observed failures belong to the
[night verification record](docs/verification/20261018-night-experience/README.md).

Fixed7c Windows normal/tester ZIP identities, first real task and package map/rules
passed; tester additionally passed60 actual entrances, real C/P/G protected work,
restart/recipe replay and final-only4-case/2-session feedback import. This is
exported-controller acceptance. Ordinary C/P/G restart remains separate.
The unchanged tester additionally passes16 scoped native Windows OS-input checks:
real tutorial wiring/completion, F8/single-letter autosave, independent restart
and two normal exit0 results. Long/Chinese text input and old-note history GUI
restoration remain unverified; native C/P/G/full60 coverage is not claimed.
No60-task human-completion claim follows from entrance checks.

This round does not authorize public publication, server/domain changes or save
migration. Unfamiliar-player understanding, final narrative/art/subjective audio,
current Mac native behavior and another machine's first launch remain open.
Agent controller replay is separate from OS input and human playtesting.
Engineering handoff is complete; these remaining human/platform gates stay open.

## Earlier acceptance — 2026-10-17

The new offline teammate Windows candidate freezes `4df5bad46751`. All sixty
entrances and the final-only two-play screenshot/context ZIP acceptance passed.
It uses `OfflineTeammate`, has no receiver and can be distributed for
controlled testing without waiting for the cloud domain. The owner authorized
publication of [offline Pre-release v0.5.0-alpha.3-offline.1](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.5.0-alpha.3-offline.1);
it is published. The earlier online draft remains unpublished.
[Offline candidate evidence](docs/verification/20261017-offline-teammate/README.md).

Protected PR7 merged as `94b5bff`; main contains the complete sixty-task journey.
PR8 integrates feedback operations and a Windows Release draft. The owner explicitly
chose to wait for a working domain before the online draft's public release. The
published offline Windows download contains sixty task entrances; Alpha1 is older.

Actual private Windows EXE feedback at fixed `beca837894481165e6e04afe93f4e879645c1d29`
passed HTTPS delivery, same-ID private reporting, retry/deduplication, deletion and
an actually started restored receiver returning410. Restore held0 events/1 tombstone.
VPS service/data isolation, daily maintenance and private routes passed; no public
entry or offsite backup is active. [Current evidence](docs/verification/20261017-feedback-release/README.md).

| Gate | Status and required evidence |
| --- | --- |
| Offline teammate Windows collection | **PASS for fixed EXE capture/restart/export/import.** All60 entrances, final-only4 cases/4 screenshots/2 sessions, preservation, deduplication and importer/report tests passed. Windows native F8/text input observed. Generated report browser visual inspection remains NOT_RUN under the in-app local-file policy. |
| Localhost VPS receiver and maintenance | **PASS within private scope.** Separate services and daily timer enabled; actual delivery/report/backup/delete/restored-receiver410, private permissions, shared rate limit and unchanged original services/historical hashes passed. No public intake. |
| Public feedback domain and external entry | **Open by owner choice.** The planned domain is not purchased or resolved; hosting/filing requirements are unverified. Keep localhost. Future public use requires DNS, ports80/443, TLS and an external-machine acceptance run. A configured privacy URL alone is not such acceptance. |
| Windows online Pre-release | **Draft only by owner choice.** Fixed-source347e426 Windows offline draft and all4 uploaded digests verified; representative native restore/work/opinion/save/restart PASS. Publication waits for DNS/TLS/privacy/external acceptance; never bake a planned or localhost address into a player release. |
| Current Mac native interaction | **NOT_RUN for the `f26131049877` package.** Earlier native routes retain their own build attribution. Operate this package's navigation, editing, unfinished-task feedback, save and restart on a Mac. |
| Windows native execution | **Representative acceptance PASS at current offline347e426 and earlier f261310.** Existing64-cell saved-work source/phrase/step/play/pause/viewing controls, local opinion restoration, writable save and independent restart passed; both normal exits released their owned lease and saved fields stayed intact. Earlier d34a61d navigation/generation and8a919e2 restart evidence retain their own source attribution. Automatic Windows abandoned-lock recovery remains unsupported. A fresh later-region native full-route, extended focus loss and mixed-DPI stress remain open. |
| Other Mac / installation / signing | **Open.** Candidate is unnotarized; verify download, first launch and save on another machine, then choose formal signing/distribution requirements. |
| Display and focus | **Open.** Extended small-display/Retina/mixed-DPI and repeated focus loss during drag sessions require direct evidence. Earlier capture anomalies remain attributed to their recorded builds. |
| Unfamiliar-player understanding | **Open.** Unassisted entry, task choice, Hint comprehension, full-route pacing and concrete feedback. Known-answer replay and agent observations do not establish this. |
| Listening and artistic acceptance | **Open.** Independent listening and visual/narrative review of core and creative endings remain separate from technical checks. |

All forty original tasks repeated natively are additional coverage, not a mandatory
development gate. Existing original-core, Representation/Service and C/P/G native
observations are retained in their [dated verification records](docs/README.md).
They do not combine into a fabricated fresh full-route run.

The [2026-10-12 private HTTPS record](docs/verification/20261012-pre-release/README.md)
passed actual exported Windows feedback, retry/deduplication, deletion and a
tombstone-safe restored receiver against synthetic data. Its dedicated staging
was stopped, and it does not certify the new localhost deployment or public intake.
The [2026-10-13 creative candidate record](docs/verification/20261013-creation-expression/README.md)
retains its frozen build and test attribution despite the later PR merge.

Missing remote-access configuration belongs in the private local handoff. Do not
publish credentials, infrastructure targets or raw player data. Offline refusal or
network failure must continue to leave the game usable; opinions and statistics
require separate consent under the [feedback contract](docs/architecture/community-feedback.md).
