# v0.6.1-playtest.1 公开试玩 · 2026-11-22

2026-11-22 15:21:01 UTC，GitHub Release `454479788` 已作为公开预发行版发布，包含四个 ZIP 和 `SHA256SUMS.txt`。标签指向 `c4a09364748410370d605e55e610943b5c69a72b`。发布后，无认证 API 返回公开预发行状态，四个 ZIP 的匿名 Range 读取通过，校验文件字节与本地一致，GitHub 资产摘要与冻结清单一致。[公开下载与发布说明](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.6.1-playtest.1)。

- 游戏源码 `c4a09364748410370d605e55e610943b5c69a72b`，批次 `Players061-Release1`，Godot `4.7.1.stable.official.a13da4feb`，完整 60 项任务。
- 当前独立 VNB 接收器源码 `a9e8cae1cce98e349d60ae623e8205ed8d902c00`。首次切换使用 `d22a1fb69f83422181a8303faf6ffdd97c894fb9`，当时的部署归档 SHA-256 为 `7eadb394a78ba19a8092ae6e841e0f8fb9b00ae8ca1959866091ab042c520836`。

## 四包校验

| 平台与版本 | ZIP 文件 | 字节 | SHA-256 |
| --- | --- | ---: | --- |
| Windows x64 Game | `Von-Neumann-Bottleneck-Windows-vnb-game-release-v0.6.1-playtest.1-Players061-Release1-c4a093647484.zip` | 211972635 | `b56c56913bccfc948af7a715686429c118e61fe87a008d06ee138bc94b9323b8` |
| macOS Universal Game | `Von-Neumann-Bottleneck-macOS-vnb-game-release-v0.6.1-playtest.1-Players061-Release1-c4a093647484.zip` | 234406901 | `4ae4c59413276410c23a516b6d3ee0d59946a569a57fc8a71775189cdbe6a8d8` |
| Windows x64 Test | `Von-Neumann-Bottleneck-Windows-vnb-test-release-v0.6.1-playtest.1-Players061-Release1-c4a093647484.zip` | 211972258 | `a88871d53304a99238295bed1d3a33da8ec3431a823116b44f4f744f3f797319` |
| macOS Universal Test | `Von-Neumann-Bottleneck-macOS-vnb-test-release-v0.6.1-playtest.1-Players061-Release1-c4a093647484.zip` | 234406527 | `6f02a7a7dddf5b393c1efde2344d5265ce74103c554e6cd57c3fb86728d3a6f7` |

四个本地 ZIP 已重新计算 SHA-256，与交付清单及公开资产摘要一致。包内版本、存档档位、文件哈希和平台结构通过检查。Windows EXE 为 PE x64，未做 Authenticode 签名。Mac 包含 arm64 和 x86_64，ad-hoc 签名严格校验通过，未做 Apple 公证。构建收据在本地 `.godot/public-release-c4a093647484/`。

公开 `SHA256SUMS.txt` 的 SHA-256 为 `16bddaf3599112de9587c97d76803c308dfa6a0d4399897150efe59dbb5eab57`。匿名下载证据见本地 `.godot/player-release-c4a09364/anonymous-publication.json`。

## 玩家路径

- **Game** 保留 `EditionGame` 和正常进度，可离线游玩。未完成任务可点「反馈」或按 F8，保存本机草稿或主动发送单条意见。首次可选「仅本机」，自动统计单独选择。收到匹配确认才显示送达回执。意见包含任务、构建与随机安装标识，界面提供玩家隐私说明和删除入口。此构建未启用联网社区和评分分享。
- **Test** 使用独立的 `EditionTest`，开放任务入口，正式判定仍按实际操作。F8 离线保存截图与现场，玩家可导出 ZIP 后私下交给维护者。构建无联网接收器。
- **随包说明勘误**：更新说明中「离线反馈历史」适用于 Test。Game 可恢复本机意见草稿。[发布说明](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.6.1-playtest.1)。

## 源码与平台验收

| 范围 | 已验证结果与收据 |
| --- | --- |
| 全量冻结 CI | 两项作业均检出 `c4a09364748410370d605e55e610943b5c69a72b`。Godot 313/313 阶段通过，含 311 套无头、导入与用户目录隔离。Python 12/12 门禁通过。[工作流 45029324641](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45029324641/attempts/1) · [Godot 作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45029324641/job/137229185249) · [Python 作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45029324641/job/137229185073)。 |
| 发布前 `main` 全量 CI | 两项作业均检出 `823659143ff73e078d1c17775ec1e1310cbe7a5e`。Godot 313/313 阶段与 Python 13/13 门禁通过，包含此前失败的 `server/test_maintenance.py`。[工作流 45034307120](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45034307120/attempts/1) · [Godot 作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45034307120/job/137244515791) · [Python 作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45034307120/job/137244515591)。 |
| 冻结前源码 | 隔离导入、档位检查与 9 套定向无头通过，含释放页面的原始回归及 `test_release_convergence`。同一快照中英文 × 仅本机／基础同意四次图形检查均通过，保留 22 张 1280×720 原图。覆盖启动内嵌反馈、未完成任务入口、本机草稿、无自动发送及匹配模拟回执。`.godot/verification/20261122T134415Z-acfb9aed/results.json` 和其下 `public-game-fed2d74c/results.json`。 |
| Mac Game 四包候选中的实际 App | 原 ZIP、执行文件和 PCK 哈希固定。两个隔离进程验证仅本机选择、实际教程进度和意见跨重启恢复。另用隔离档和回环接收器验证断网 Send 入队、重启收到同 ID 回执、同 ID 重试仅一行、删除后零行且重放 410，保留本机意见与进度。部分进程在退出前记录 `data.tree` 为空，退出时记录 GLES3 资源诊断，断网阶段出现预期的连接失败。两条实包验收路径均通过。`.godot/mac-release-qa/{231909af517c,7c2644391057}/receipt.json`。 |
| Mac Test 四包候选中的实际 App | 隔离断网渲染两阶段，18 次进入、4 份现场截图，重启后可访问记录并导出现场 ZIP。`.godot/public-release-c4a093647484/test-smoke-44f691a8f0/receipt.json`。 |
| 冻结 Mac Game 持续运行 | 复用 `c4a09364` 的同一 ZIP 解出的 App，隔离断网，单进程渲染 20 分 3.9 秒，完成 40 轮任务往返和 201 次调试。故意损坏的隔离主存档从备份逐字节恢复并成功重开。热身后地图 56 次采样均为 405 个节点，采样孤立节点为 0。RSS 512.3–525.3 MiB，首末采样区间中位数差 +3.8 MiB。64,225 个帧间隔中 73 个 ≥100 ms，其中 72 个发生在进入工作台，热身后最慢 138.2 ms。本次未出现 `data.tree` 错误，退出仍有 GLES3 资源诊断。收据 `.godot/mac-sustained-c4a09364/run-7a7d8af8dd/receipt.json`，采样和恢复哈希见同目录 `measurements.json` 与 `runtime/recovery.json`。 |
| 较早 `2f20cef2` 离线 Mac 压力抽查 | Game 35 次操作与 9 条本机意见，Test 63 次工作台进入与 14 份截图现场，各三次进程启动含两次重启，受保护状态一致。最长单次进程约 45/53 秒。覆盖重复操作与重启，真人长时使用和内存趋势仍待观察。`.godot/verification/offline-stress-2f20cef2/run-ca1fffba/final-proof.json`。 |
| Windows Game/Test 实际 EXE | GitHub Windows 托管机无头运行两个原始 ZIP 的 EXE。验证逐程序网络隔离、重启与工作台字节保留。Game 在回环接收器不可达时持久化同一意见 ID，重启后确认 SQLite 恰有一条已回执意见。Test 重启恢复现场历史意见，核验本机导出 ZIP。包和包内文件哈希一致。[Windows 实包作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45031785575/job/137236759576)。 |

Mac 实包为脚本驱动的窗口运行。Windows 实包为自动化无头运行，鼠标、焦点、界面与系统安全提示仍待实际观察。Intel Mac、普通下载后的异机首启、真人独立通关与长时体验尚无本轮验收结论。

实包与外网工作流在 `eb0e5959b2ca1ad06fa2b582e009514be8036c43` 上两项作业全部通过，实际包仍为 `c4a093647484`。这轮任务结束后，主线程删除两个临时的 GitHub Actions 草稿资产 secrets，并重新确认两项均已不存在。初次运行在下载前遇到 403，后续等待超时的重跑保留原包字节并修正探针等待后通过。[通过记录 45031785575](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45031785575/attempts/1) · [首次 403 记录](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45029741127/attempts/1)。

## VNB 专用入口

1. 既有 `/32` 下完成独立线上演练。QA 来源被拒绝，合成意见同 ID 两次确认仅留一条，私有报告与 SQLite 一致。重复删除成功，重放 410，演练库最终 0 客户端／0 事件／1 删除墓碑。另以独立库演练备份、恢复及回退，历史路由恢复后玩家说明回到 404。
2. 切换到专用正式库后，只准入经四包清单核对的 Game 构建身份，初始 0 客户端／0 事件／0 删除墓碑。历史库保留原 2 条删除墓碑，服务隔离基线前后一致。专用接收器、维护定时器及 8443 边缘已启用。
3. 切换后在原 `/32` 只读核对 TLS、`/v1/health` 和两份隐私页返回 200，页面内容哈希与冻结文件一致，私有报告、社区和其他拒绝路径保持 404。正式库未作合成写入。
4. 用户明确授权并已完成 Ray VPS 云防火墙变更。仅将现有 VNB TCP 8443 规则的来源从 `/32` 扩为全部 IPv4（`0.0.0.0/0`），其余 4 条规则保持原样。13:58 UTC 的主机只读复核确认正式库为 0 客户端／0 事件／0 删除墓碑，10 个受保护服务单元的快照与基线一致。
5. GitHub 托管机从原 `/32` 外通过 HTTPS 只读核对正式健康、隐私页和拒绝路径。两份页面 SHA-256 与冻结源码相符，正式入口未写入合成数据。[外网只读作业](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45031785575/job/137236760014)。

| 外网读取的页面 | SHA-256 |
| --- | --- |
| `/privacy.html` | `d8ccef568aa3b564aadf159c009f8f54f294fdd8fb0c6ab004168900e827bef8` |
| `/privacy-player.html` | `d54374359a5d8473e0efdf8294424de967cc611ed89ab29fe7bab9c054f2e9db` |

### 加固上线 · 14:38 UTC

- 正式数据库与运维文件分别使用预先分配、固定容量的 1 GiB 和 3 GiB 专用卷。切换后根文件系统可用 29.96 GiB。重挂载后 live 设备号从 `7:0` 变为 `7:1`，ops 从 `7:1` 变为 `7:0`。启动门禁验证限额跟随实际设备号。接收器 UID `986` 与维护 UID `985` 的同进程探针各有 65,536 字节归到对应 loop 设备，同次在 `253:0` 上为 0 字节。
- 接收器被拒绝访问备份，非 root 维护服务对正式 DB/WAL/SHM 只有读取权限。原数据库与备份保留，原快照和维护 UID 新建的隔离快照均恢复出与线上一致的完整逻辑状态。正式库为 0 客户端／0 事件／0 删除墓碑，分诊操作 0 条。历史库保留 2 条墓碑。10 个受保护单元及监听器快照与基线一致。
- 首次健康探测早于监听就绪，执行回退并对照两套数据。复试等待监听就绪后切换成功，主机 TLS、健康及两份隐私页验证通过，维护任务退出码为 0。GitHub 加固后单独重跑的外网只读作业也已完成并通过。[外网复验 45031785575 第 2 次](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45031785575/attempts/2)。

加固主机收据和原始日志索引见 `.godot/vps-release-execution/hardening/a9e8cae1/OUTCOME.md`，同目录保留 `staging.log`、`cutover.log`、`final.log` 和 `receipt.log`。服务端 Ubuntu CI 曾在 `server/test_maintenance.py` 失败，修复后的发布前 `main` 已通过该项和全部 Python 门禁。[首次失败](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45033471198/job/137241941785) · [复验通过](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/45034307120/job/137244515591)。

VPS 私有收据在 `.godot/vps-release-execution/stage-d22a1fb6/`，放行后只读结果见其下 `firewall-readonly.vn6tQK/{time,public,host}.txt`，云规则记录见 `.godot/player-release-c4a09364/firewall-applied.jpg`。运维与回退步骤见[接收器运行手册](../../../server/deploy/RUNBOOK.md)。
