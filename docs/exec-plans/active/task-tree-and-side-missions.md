> **HISTORICAL / SUPERSEDED as an active queue.** Implementation history only.
> Current scope and remaining acceptance: [CURRENT_STATE](../../CURRENT_STATE.md) and [release blockers](../../../RELEASE_BLOCKERS.md).
> Older task counts and candidate identities below describe their dated iteration.

# 任务树、应用支线与可解释的本地试玩记录

2026-09-10；基线 `14d6275`。用户采用《整体设计审计》最近两轮讨论，授权在既有游戏上实现下列扩展，并要求分批 commit / push main、开发后原生试玩迭代。

## 范围与边界

新增五个可选任务：selector 后「四路择一」（64 组合）、latch 后「报警别消失」（清除优先时序）、half_adder 后「错了一位」（五位偶校验）、Chapter 1 ram_wait 后「只取一次，就够了」（固定硬件、两倍求和、请求数 N+1）、bottleneck 后「一笔预算，两张订单」（各自配置、同预算、真实模型标定）。新逻辑任务内部空白，行为判定，独立三级提示，不产生虚构封装奖励。

将现有 29 个任务及新增任务连接成总任务树；读取各域真实解锁状态，保留四个区域、现有关卡 ID、章节宿主、旧方案和原主线门槛。锁定节点可查看原因；支持搜索、缩放、平移、定位和返回视野。所有跳转由宿主再次验证。地图不是第二份进度存储。

三个附加目标：Chapter 2 capstone 低成本、Chapter 3 distance 无重复搬运、synthesis 两条实际执行的有效路线；不阻挡原通关。Chapter 3 可复制兼容的已有玩家方案到后续任务，必须重新测试，不覆盖来源。

本地记录增加 session / visit / run / case 关联、来源、版本、单调计时及前后台分段；完成是里程碑而非 visit 结束。分别记录失败、成功后优化和可选反馈。问卷独立于遥测开关，部分评分可提交；可随时标记感受并导出。多会话本地报告保留未知字段、未完成者和样本数，不把代理/自动测试算作真人数据。

不增加云端遥测、SDK、数据布局/地址映射新机制，不更改仿真常数、线延迟、缓存管理、旧任务判定、旧存档默认布局；不恢复八关版。不默认收集源码、键鼠轨迹、截图或个人路径。历史记录原样保留；新增持久字段采用可选字段和恢复重验。

## 实施与验证

1. P0：阅读、隔离基线验证、保留玩家目录；记录研究依据。
2. P1：全局导航适配器与总图，保留现有入口和宿主校验；独立提交。
3. P2：新任务内容/双语规格/渐进教学/提示，标定预算，测等价和反例；独立提交。
4. P3：附加目标和方案延续，保存恢复重验。
5. P4：记录、反馈及离线报告；覆盖旧日志、关闭遥测、未完成退出、切后台、完成后继续优化。
6. P5：Godot 4.7.1 隔离检查、普通 Game 原生操作、缩放/焦点/重启/导出；修复实际观察问题，更新证据、提交推送。

影响：content/prologue、system_lab、overlap_chapter、ui/prototype_hub 与导航、playtest、相关自动测试和文档。仿真输出仍唯一权威；显示和统计不能改变判定。预算和额外目标阈值先枚举真实运行再落地。

## 参考与具体采用

- [Turing Complete 官方](https://turingcomplete.game/)：发现能力后再实际使用；应用任务依附已获得的工具。
- [GameAnalytics progression events](https://docs.gameanalytics.com/events-metrics-and-filtering/event-types/progression-events/)：区分开始、失败、完成；本作进一步区别正确输出、性能目标与封装完成，不接入其服务。
- [Godot Time](https://docs.godotengine.org/en/stable/classes/class_time.html)：持续时间用单调时钟，UTC 只用于日期；后台与中断单列。

## 进展 / 未闭合项

- 2026-09-10：本地工作区干净；首次 fetch 遇 GitHub TLS 错误，待重试。隔离基线验证已启动。所有实施和原生验收尚待完成。
- Windows、新手理解与趣味性需要独立验收，不以 Mac 自动测试代替。

- P1–P3 已实现：34 节点总图、五条应用支线、三个附加目标、兼容任务方案复制。隔离运行 `20260909T172131Z-c437221f` 的 23 套检查全部通过。预算 24：计算目标 66 周期有 3 解，搬运目标 320 周期有 4 解，无共用达标配置。
- 原生已亲自拖放四个 XOR、完成九条连线并通过 parity 32 例，返回总图状态与视野保留。发现直达 Mission 被工具窗盖住并修复层级；复查待下一轮启动。其余新任务原生验收和 P4 仍在进行。
- 既有 overlap QA 档中的 CPU 方案未恢复，后续域因此关闭；另一个既有 exploration QA 档全部原主线进度只读重验通过。后续复制该已真实完成的 QA 档进行隔离试玩，不覆盖来源，也不注入参考解。

- P4 已实现：schema 2 的 visit/run/case、单调时间与来源、主动时刻反馈、部分评分与本地合并报告。最终完整隔离运行 `20260909T175025Z-08d6f144` 24 套检查全通过，末尾会话/焦点修正定向复查通过，Python 报告测试及合成导出 CLI 通过。
- P5 尚未完成：中文输入回放暴露两处落点假设（默认打开的元件台覆盖旧“空白”坐标），已修正回放操作但重跑待解锁。Mac computer use 返回锁屏阻挡，已请求用户解锁。真实原生证据目前仅包括新 parity 手工构建通过；其余新任务、最后 UI 修正、中文/英文回放和重启仍待继续。详细边界见[验证记录](../../verification/2026-09-10-task-tree/README.md)。
- 首次 GitHub TLS 失败已恢复，fetch 成功；远端 main 仍为本轮基线，准备按既有授权分批提交推送。本计划保持 active，不能将开发检查通过写成完整试玩/发布验收通过。
