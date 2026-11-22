# v0.6.1-playtest.1 内部冻结包 · 2026-11-22

三份构建清单记录同一源码 `2f20cef2d8c36a38c8458c84c2a50afea52b44b0`、引擎 `4.7.1.stable.official.a13da4feb` 和 60 项任务。逐个读取本地 ZIP 的字节数并重算 SHA-256，六项均与各自的 `manifest.json` 一致。另核对了每个 ZIP 平台目录内 `BUILD-MANIFEST.json` 的平台、源码、构建 ID、批次和存档名称。

## 构建身份

本地清单路径为 `build/<构建 ID>/manifest.json`，ZIP 与清单位于同一目录。

| 用途 | 构建 ID | 批次 | 存档 |
| --- | --- | --- | --- |
| Game，按前置条件解锁，离线 | `vnb-game-v0.6.1-playtest.1-Playtest061-Game-2f20cef2d8c3` | `Playtest061-Game` | `EditionGame` |
| Test，全部任务入口，离线 | `vnb-test-v0.6.1-playtest.1-Playtest061-Test-2f20cef2d8c3` | `Playtest061-Test` | `EditionTest` |
| Test Pilot，全部任务入口，配置联网意见反馈 | `vnb-test-pilot-v0.6.1-playtest.1-PlayerFeedbackPilot-Wave1-2f20cef2d8c3` | `PlayerFeedbackPilot-Wave1` | `EditionTestPilot` |

三份清单均记录 `upload_default=false`、`public_release=false` 和 `external_ready=false`。离线两版的接收端为空。Pilot 的默认意见来源为 `external_player`，接收地址为 `https://feedback.yanruiqing.com:8443/v1`，玩家隐私说明地址为 `https://feedback.yanruiqing.com:8443/privacy-player.html`。

## ZIP 实测值

| ZIP 文件名 | 字节 | SHA-256 |
| --- | ---: | --- |
| `Von-Neumann-Bottleneck-Windows-vnb-game-v0.6.1-playtest.1-Playtest061-Game-2f20cef2d8c3.zip` | 211970876 | `50b17c2f53aa7103991f0cdf90d15d2ad91bdc1a4b81b44da6028463a775d25e` |
| `Von-Neumann-Bottleneck-macOS-vnb-game-v0.6.1-playtest.1-Playtest061-Game-2f20cef2d8c3.zip` | 234404781 | `2d2f20bedfee179431de868bebb29daf7e1510cdaff6555b5527df247888a2e0` |
| `Von-Neumann-Bottleneck-Windows-vnb-test-v0.6.1-playtest.1-Playtest061-Test-2f20cef2d8c3.zip` | 211970928 | `55775f61f89fa0c2eccadc9ac3844f9707ddc02c2d39b8e4aa52e5648786a02c` |
| `Von-Neumann-Bottleneck-macOS-vnb-test-v0.6.1-playtest.1-Playtest061-Test-2f20cef2d8c3.zip` | 234404839 | `b1e0277c12722bf77164f27c7e6010d3dedb38aa336c56eec391e8d6cba96b9b` |
| `Von-Neumann-Bottleneck-Windows-vnb-test-pilot-v0.6.1-playtest.1-PlayerFeedbackPilot-Wave1-2f20cef2d8c3.zip` | 211971560 | `eb7817d1f62589d7f578a69fd6435219f3cafeae6a038877c57050fa76af17ab` |
| `Von-Neumann-Bottleneck-macOS-vnb-test-pilot-v0.6.1-playtest.1-PlayerFeedbackPilot-Wave1-2f20cef2d8c3.zip` | 234405965 | `b3fdd2838bcd36eae0e5cb4fb22868ec0c206c575b271d407cabbb8dfced8b27` |

## 后续验收

- **实机操作**：在 Windows 干净账户从 Explorer 首启，检查系统提示、真实鼠标和 F8 输入、保存后重开；另验 macOS 异机下载首启、Intel Mac 和不同 DPI。真人首关理解与长时试玩仍需观察。[源码回归与操作证据](README.md)
- **小范围联网试玩**：先确认获准的参与者、来源网络及玩家隐私说明，再从该网络用 Wave1 显式发送意见，按同一回执核对私有报表中的任务、批次和来源，并验证删除。既有 8443 限源记录属于合成验收。[历史限源验收](../20261122-feedback-connectivity/README.md) · [玩家反馈接入条件](../../development/PLAYER_FEEDBACK_ROLLOUT.md)

## Mac 联网试玩包实包复验

同一 Wave1 ZIP 在 Apple Silicon 上解包，核对应用和 PCK 的 SHA-256 后，在禁止联网的环境读取内嵌 8443 地址与 Test 身份。实际发送阶段仅允许连接本机临时接收器，测试来源为 `automated`。意见在接收器离线时入队，重开后取回同一 ID 的回执。重发后 SQLite 中有 1 条意见，删除后有 0 条意见和 1 条删除墓碑，旧意见再次发送返回 HTTP 410。合成作品跨进程字节一致，配方重放通过。详细记录位于本地 `.godot/mac-test-pilot-qa/ef970d9c85c0/receipt.json` 和同目录的 `runtime/`。
