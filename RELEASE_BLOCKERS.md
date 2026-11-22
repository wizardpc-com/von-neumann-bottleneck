## 当前分发判断

`v0.6.1-playtest.2` 于 2026-11-22T17:12:38Z 作为 GitHub 公开试玩版发布。GitHub 已将本版本标为 Latest。四个 ZIP 均冻结于 `38538b66474591d5cae4db4d07ac1dfc452af1c4`。Game 按正常进度解锁，Test 采用独立存档并开放任务入口。两版均可拒绝或接受服务，首次同步后可从反馈打开自己的成绩。Test 另可离线记录和导出。[公开下载](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.6.1-playtest.2)。

尚未验证 Intel Mac、另一台 Mac 或实体 Windows 电脑下载后首次打开，以及玩家在真实网络上的长期使用。

[冻结 CI、平台实包、反馈与公开下载的验收记录](docs/verification/20261122-final-playtest/README.md)。

## 2026-11-22 · Playtest.1 历史门禁

`v0.6.1-playtest.1` 已于 2026-11-22 15:21:01 UTC 发布为公开预发行版。发布标签指向 `c4a09364748410370d605e55e610943b5c69a72b`，线上独立 VNB 接收器已加固至 `a9e8cae1cce98e349d60ae623e8205ed8d902c00`。用户已授权并完成 Ray VPS 现有 VNB TCP 8443 对全部 IPv4 的放行，其他 4 条规则保持原样。[公开发布](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.6.1-playtest.1)。

| 玩家或维护者需要完成的事 | 当前门禁 |
| --- | --- |
| 从未完成任务保存或发送意见，断网后重启查看回执 | 源码定向与双语图形通过，Mac Game 实包分档完成纯本机重启和合成回环发送、回执、去重与删除。VPS 专用演练库通过闭环和回退，正式库起始为空。 |
| 从一般玩家网络打开反馈说明和接收端 | **外网只读通过。** 首轮核对 TLS、健康、两份隐私页哈希与拒绝路径。加固切换后，GitHub 外网只读作业复跑通过。[首次外网作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45031785575/job/137236760014) · [加固后复验](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45031785575/attempts/2)。 |
| 在目标系统启动实际候选包并恢复进度或现场 | **四包通过平台实包验收。** Mac 两版使用隔离窗口运行，Game 日志保留退出前 `data.tree` 和退出时 GLES3 诊断。Windows 两版由托管机自动化无头运行并验证重启和反馈记录。Windows 图形交互、Intel Mac 和下载异机首启待验。[Windows 作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45031785575/job/137236759576)。 |
| 全量冻结 CI | **通过。** `c4a09364` 的 Godot 313/313 阶段和 Python 12/12 门禁均通过。[冻结工作流 45029324641](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45029324641/attempts/1)。 |
| VNB 正式环境加固 | **主机验收通过。** 1 GiB 正式库、3 GiB 运维卷，实际 UID 验证最小权限、限额跟随重挂载及 I/O 归属。原数据库与备份保留，恢复逻辑一致，10 个受保护单元快照一致。私有主机收据见 `.godot/vps-release-execution/hardening/a9e8cae1/OUTCOME.md`。 |
| 发布前 `main` 与维护测试 | **通过。** `82365914` 的 Godot 313/313 阶段、Python 13/13 门禁通过，含先前失败的 Ubuntu `server/test_maintenance.py`。[全量复验](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45034307120/attempts/1)。 |
| 公开下载 | **已发布并核验。** 无认证 API 确认公开预发行状态，四个 ZIP 的匿名 Range 读取通过，校验文件字节与本地一致，GitHub 摘要匹配冻结清单。 |

首次玩家独立理解和长时游玩留待真人试玩观察。内部回退包与历史验收仍按各自源码保留。

[公开发布证据](docs/verification/20261122-public-release/README.md) · [已完成计划](docs/exec-plans/completed/20261122-player-experience.md) · [反馈上线边界](docs/development/PLAYER_FEEDBACK_ROLLOUT.md) · [内部基线](docs/verification/20261122-player-release/README.md)

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
