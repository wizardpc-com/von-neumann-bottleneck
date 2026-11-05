# 同条件成绩与可恢复最佳实验 · 2026-11-04

独立分支 `codex/gameplay-systems-20261104`，基线 `b65a0bd`。本轮接续
[个人方案榜与挑战](../20261104-gameplay-systems/README.md)，保留完整 60 项
旅程、现有仿真、目标和成果判定。当前为本地源码增量，未提交、推送或发布。

## 可玩的改变

- 第二章持续保留相同任务条件下真实运行过的最快正确方案，周期相同时优先
  较低硬件成本。即使后面继续尝试并超过近期历史上限，也能在分析器中重新
  载入。保存的是可重放的配方；显示时重新执行模拟，不相信存档中的数字。
- “载入最快方案”同时恢复程序与配置，并使旧运行结果失效。必须再次运行
  才得到当前结果。“取回之前草稿”还原本次载入前的原始文字、已应用程序、
  配置及光标；尚未写完、无法解析的文字同样保留。返回快照限于本次关卡和
  模式，不绕过原诊断或首次单变量实验要求。
- 个人周期记录统一使用实际 `cycles` / `total_cycles`，不同任务、模型、
  用例与规则分别保留。两种订单分别比较；自定义调试程序、无效数字和未
  满足原判定的运行不能成为正式最低成绩。创造与临时预测不混入周期竞赛。
- 成长档案始终回顾 Game 成果，Test 只用于当前任务访问。第二／四章当前
  复测与历史摘要分开展示，地图明确说明最快已保存方案的指标范围。损坏、
  不支持或超出安全范围的个人日志进入只读保护；真实写入失败可见并可重试。

本轮不是服务器排行榜或防作弊系统。历史摘要只是客户端观察；本地配方
复算只说明当前客户端重现了该结果，不证明远端可信性。

## 实测例子

第二章 `capstone` 的原始方案实际为 **642 周期**。测试先得到
**138 周期／硬件成本 4** 的正确方案，再运行 36 份不同且较慢的有效程序。
近期 UI 仍只留 8 条、实时 receipt 仍限 12 条、持久 observation 仍限 32 条，
早期最佳没有丢失。经 JSON 保存／恢复后，载入并重新运行得到相同指标和
完整规范化 Trace。测试设置的前置成果只用于隔离入口，不冒充玩家通关。

## 验证状态

24 套相关无头检查分阶段的末次观察全部通过；不是最终全仓测试。
完整列表与逐次结果见 [`verification-summary.json`](verification-summary.json)。
最终运行代码固定于 `.godot/verification/20261104T203308Z-530aab9a/project`，
导入和隔离目录探针通过；以下九套相关检查均有该副本中的通过结果。

| 最终相关检查 | 结果 |
| --- | --- |
| `test_locality_best_observation` | 83 项通过 |
| `test_locality_best_restore` | 75/0 |
| `test_personal_record_conditions` | 97 项通过 |
| `test_game_record_projection` | 56/0，尺寸夹具修正后复跑 |
| `test_journey_journal` | 175 项通过；GPU 专属分支在下表另验 |
| `test_personal_records` | PASS |
| `test_playtest_feedback_ui` | PASS |
| `test_release_convergence` | PASS |
| `test_settings_feedback_layout` | 154/0 |

Apple M2、OpenGL Compatibility 下的最终图形检查：

| GPU 检查 | 结果与画面 |
| --- | --- |
| 最佳方案恢复 | 77/0，[中文](frames/locality-best-zh_CN.png) · [英文](frames/locality-best-en.png) |
| Game 成绩归档 | 60/0，[当前复测／历史摘要](frames/journal-zh_CN.png) · [英文](frames/journal-en.png) |
| 档案、回顾弹窗及 F8 焦点层次 | 256 项通过，[中文反馈](frames/feedback-popup-zh_CN.png) · [英文反馈](frames/feedback-popup-en.png) |
| 设置与反馈布局 | 154/0 |

九套无头检查使用：

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot \
  --suite test_locality_best_observation --suite test_locality_best_restore \
  --suite test_personal_record_conditions --suite test_game_record_projection \
  --suite test_personal_records --suite test_journey_journal \
  --suite test_playtest_feedback_ui --suite test_settings_feedback_layout \
  --suite test_release_convergence
```

图形检查在该副本中串行执行，每项先配置新的专用 QA 用户目录：

```sh
<Godot-4.7.1> --path <copy> --script res://tests/test_journey_journal.gd -- --capture-size=1280x800 --journal-feedback-capture
<Godot-4.7.1> --path <copy> --script res://tests/test_game_record_projection.gd -- --capture-size=1280x800 --record-projection-capture
<Godot-4.7.1> --path <copy> --script res://tests/test_locality_best_restore.gd -- --capture-size=1280x800 --locality-best-capture
<Godot-4.7.1> --path <copy> --script res://tests/test_settings_feedback_layout.gd -- --capture-size=1280x800
```

原始失败没有被覆盖。独立审查发现的嵌套损坏日志被静默丢弃后写回的问题，
已改为完整只读保护；97 项测试包含 25 类损坏／不支持记录的字节保留。
GPU 发现普通反馈面板在 650×480 回顾窗口中保留了未换行时的 3112 像素
高度；现按稳定最小尺寸重新收缩，中英文、首屏输入、滚动区与焦点均通过。
首个 GPU 命令未启用 capture 模式，窗口几何定时保存触发只读清单断言；
使用既有 `--capture-size` 隔离该预期写入，保持完整文件清单断言。
960 像素记录页测试也补齐了逻辑视口尺寸，避免仅改变物理窗口而仍按
1280 像素布局；最终使用真实两列布局。[960px 中文](frames/records-960-zh_CN.png) ·
[英文](frames/records-960-en.png)。

Mac 原生鼠标验收已准备独立 Test 现场，但 CUA 返回 Mac 锁定且自动解锁失败，
**没有执行第二轮原生点击**。已停止本任务的测试进程。
[`native-locality-probe.gd`](native-locality-probe.gd) 保留可重复的现场：
642 周期基线、138 周期最佳、未完成草稿；后续恢复／运行／取回动作必须
由实际 UI 输入触发。准备截图不算鼠标验收。

## 本地试玩

独立启动器：`.godot/comparable-records-preview-20261104.command`。使用上述
最终 QA 副本，专用存档为
`VonNeumannBottleneckChecks/20261104-round2/playable-preview`。它与首轮
启动器分别保留，默认进入普通 Game；可在实验室选择 Test，再从旅程进入
第二章或第四章测试新操作。启动器通过 `zsh -n` 检查。
普通项目入口也已用该独立目录做短暂 headless 启动，退出 0 且无错误诊断；
这只验证启动路径，不替代原生操作。

第二章：运行几份正确方案后打开“分析器”，载入最快方案，再运行并取回
此前草稿。第四章：“我的方案榜”保留首轮的多目标比较、命名方案和挑战。
个人记录页的“查看任务成绩”进入 Game 归档；当前仍在 Test 时，进入任务
继续遵守 Test 的访问规则。

## 兼容和回退

不改 GlobalSave 字段、任务 ID、进度格式、原成绩判定或模拟模型。第二章
仍使用已有工作区和 observation 字典；Test 方案只存在于 Test 命名空间。
恢复操作本身不记新成绩、不授予完成。

个人日志路径和 schema 1 的 `best` 兼容视图保留，新增可选 `conditions`
和 `legacy`。每个任务最多八组条件，三类容器合计最多 100 个任务键，文件
仍限 256 KiB。旧读者可读取 `best`；旧写者下一次保存会丢弃新增字段。
若回退代码且希望保留多条件历史，先保留该独立日志的副本。未知／损坏的
根结构与嵌套记录禁止自动覆盖，加载超限历史也不会静默截断后写回。

## 证据保存与边界

- `logs/` 保存隔离验证器输出、GPU 日志和原始失败；`reviews/` 保存实现
  交接、独立审查及修复说明。
- [`source-sha256.json`](source-sha256.json) 将 1130 个运行／测试／支持文件
  与最终 QA 副本逐字节匹配；工程设置只增加两个 QA 用户目录项。
  [`frame-sha256.json`](frame-sha256.json) 标识八张最终原始画面和一张失败
  诊断原图。静态归档截图等待既有进场动画结束，并滚动到真实成绩段落。
- 所有运行使用 Godot `4.7.1.stable.official.a13da4feb`、源码副本和
  `VonNeumannBottleneckChecks/...` 专用目录；没有访问或更改真实玩家数据。
- 创建重复 QA 副本时曾遇磁盘已满。未启动测试的失败副本有 `COPY-FAILED.md`。
  仅本任务生成的旧重复项目已在逐文件哈希核对、保存 `runtime-source.tar.gz`
  后清理；其日志和 `SOURCE-ARCHIVE.md` 保留。没有清理玩家目录或无关缓存。
- 未完成新导出包、其他平台、真人新手通关、长时间游玩、音效听感及第二轮
  原生输入验收；没有公开网络请求、上传成绩或服务器重放验收。
