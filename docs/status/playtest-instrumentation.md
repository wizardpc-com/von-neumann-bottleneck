# 本地试玩记录与反馈

2026-09-10：原构建序章及三个章节、34 个任务使用同一套本地观察器。八关运行版本已退役。记录不参与仿真、通关、解锁或存档重验；源码和操作规则仍由各章节负责。

## 玩家怎样使用

每个工作台及总任务树都有「反馈」按钮，也可按 F8。主动标记「卡住了」「想做但做不到」「突然懂了」「这里有趣」「只是在照做」，立即保存当时任务、访问、最近一次运行的关联；随后可补一条不超过 240 字的说明。返回地图后可选填上次离开的原因，不强行认定玩家放弃。

完成关卡的评分保持折叠，章节问卷仍可跳过。所有问卷任选一项即可提交，未答分数保存为 null。反馈面板能导出当前会话 JSON 并打开文件夹；不会上传。关闭自动记录 `--disable-playtest-telemetry` 后，主动反馈仍可独立使用；`--disable-playtest-feedback` 关闭问卷。

## 版本 2 的含义

- session 是一次启动（异常中断可恢复）的匿名记录，不等于一个独立玩家。
- visit 是进入任务到离开；完成只是里程碑，完成后调整仍在同一次 visit。
- run 只在正式仿真实际执行后产生； case_outcome 关联真实 case、指标和测试集版本。编译、未应用程序、无效拓扑等阻止运行的事件单列，不制造失败运行。
- 前台、后台、反馈时间使用单调时钟分段，最多每 10 秒刷新。异常退出后未刷新尾段及中断间隔未知，不跨进程相减。旧 schema 1 的 duration 保留为旧墙钟时间，不冒充有效前台时长。
- 区分错误输出、输出正确但目标未满足、目标达成和进度完成；失败后的下一次运行计作重试，通关后的优化单列。
- Hint 请求、确认、取消、实际展示分开；修改记录具体操作，撤销、重做、放置取消和连接拒绝另记结果。手动打开与自动展开的工具标记来源。
- 地图记录可用、实际进入视口、查看详情、进入任务；进入视口不等于玩家看过或理解。
- source 为 external_player / developer / agent_native / automated / unknown。默认 unknown；玩家可在反馈里说明来源。代理和自动检查不进入真人分组。普通本轮原生验证使用 `--playtest-source=agent_native`。

事件包含匿名 session、sequence、visit、run、case、日期、进程单调时间、构建与任务版本。配置/程序仅记录摘要和正式指标，不记录完整程序、Notebook、键鼠轨迹、截图、机器身份或账号。只有玩家主动填写的反馈字段保存文字。

## 保存、恢复与导出

`user://playtest_data/session_<id>.jsonl` 每条即时刷新；`active_session.json` 用于异常恢复。读取 schema 1/2，坏尾行单独计数，旧日志保留。导出到 `user://playtest_data/exports/`。导出是主动操作，发布仓库不得包含真实玩家的日志、反馈或存档。

## 汇总多个自愿提供的导出

```sh
python3 scripts/report-playtests.py --output /tmp/vnb-report /path/to/export-a.json /path/to/export-b.json
python3 -m unittest discover -s tests -p test_playtest_report.py
```

生成独立 `report.html` 和 `report.json`：任务路线、访问与尝试、时刻反馈三个视图；HTML 可筛选来源。按 session + sequence 去重，旧来源保持 unknown。报告显示样本数、完成/进入的 n/N、前台时长中位数与范围，也保留未完成访问、每次运行及案例、Hint 和反馈时间线。

统计仅用于形成待验证的问题，不能直接推导流失、注意力或设计因果。无开始记录的完成不会进入“完成/开始”分子；无曝光记录的进入不会假定看过地图。历史缺字段保留未知。

## 验证边界

`test_playtest_data`、`test_playtest_visits`、`test_playtest_feedback_ui` 及 Python 报告测试覆盖记录恢复、关闭自动记录、部分评分、焦点计时、完成后优化、坏尾行、重复导出及 HTML 文本转义。实际交互、导出与重启结果见本轮任务树验证记录；Windows 和真正新玩家的反馈另行验收。
