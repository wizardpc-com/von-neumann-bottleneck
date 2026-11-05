# Round 4 界面修复复核 — 2026-11-04

审查者：`/root/review_records_final`。依据当前 `.godot/collaboration/round4-tasks.md` 的只读任务，复核实验界面、界面测试、Session 集成，以及主线程的最新隔离收据。

**结论：此前退出确认/设置语言切换的 P2 已修复；本次复核未发现新的可执行缺陷。** 历史选择期间同步删除发信号 TreeItem 的问题也已从生产调用路径中移除。此结论不代表原生输入、导出包或全仓测试均已验收。

本审查未运行 Godot、操作 Git、修改源码或测试；仅读取当前实现、现有运行日志和隔离 QA 截图，写出本报告。

## 焦点修复

`lab.gd` 新增独立 `_exit_focus_id`。`request_quit()` 在聚焦确认按钮之前保存原编辑控件标识；取消确认时，如果原 WeakRef 因语言重建失效，则通过该稳定标识恢复对应新控件。

`_restore_focus()` 在退出确认可见时先查找退出层，仅接受两个确认按钮，否则回到 Keep exploring。它不再把仍在显示的确认层后方 Run 当作语言重建后的默认焦点。现有 Settings 重建顺序因此能保存正确的确认层返回焦点。

新增 `exit_settings_inputs()` 确实由每种语言的主流程调用。它从数字编辑器进入 OS-close guard，随后通过 F10/实际 Settings 语言路线重建，再用 Escape 返回并断言确认层焦点；最后发送 Space，验证只取消确认、回到新数字编辑控件，且 Session 身份、方案与历史不变。这里没有直接调用取消函数替代关键键盘操作，也没有在断言之前人为修复状态。

此前 `/private/tmp/vnb-round4-ui-review.md` 的 P2 应标记为已关闭。

## 历史选中修复

`_history_selected()` 现在调用 `_refresh_history(false)`，只刷新快照说明、恢复/基准按钮、比较及证据；不清空发出 `item_selected` 的历史 Tree。真正重建历史列表仍在运行、编辑、恢复或显式基准更新等入口执行，并以 `_syncing` 阻止程序性选择再入。

测试的 `select_history()` 现在使用实际 Tree 焦点和 viewport Up/Down 输入，逐次重新获取当前选中行，检查 Session 选中身份。它不再通过手动发信号或反复调用宿主 handler 掩盖原问题。当前 UI 的行顺序按递增运行 ID，有限步数与方向选择适用于这组恢复测试。

## 核对到的新鲜运行证据

QA 根目录：

`.godot/verification/20261105T005513Z-6cc70bb5`

已阅读以下 results 和完整原始日志：

- `headless/20261105T011302Z/results.json` 和 `test_layout_strategy_ui.log`：退出码 0，errors 空，**210 checks / 0 failures**。
- `gpu/20261105T011406Z/results.json` 和 `test_layout_strategy_ui.log`：退出码 0，errors 空，**222 checks / 0 failures**；日志明确为 Godot 4.7.1 stable、Apple M2 OpenGL。
- GPU 日志记录了双语共 12 张截图的成功保存。这里只把日志作为保存证据，没有声称逐一目检了全部 12 张。

已独立目检三张 960×640 原图：英文 Compare、英文 Quit、中文 Evidence。主要运行/撤销/语言/设置/退出入口、比较指标及按钮位于画面内，退出确认两项动作完整，事件与详情有明确滚动区域；这三张未见新的遮挡或截断缺陷。

这些均为隔离 QA 的脚本化 viewport/GPU 证据，不是 Mac 原生鼠标键盘验收。

## 当前源码绑定

以下四个当前工作区文件与上述 QA `project/` 副本逐字节一致：

```text
a5a87f4e5183c0f767eade4077c641b52bb8573a35abe935c4ca853d110a4ae3  experiments/layout_strategy/lab.gd
6d94418964144051ac4895da143abb2aa9ebf6d814fb87e5f8242d78b36d6364  experiments/layout_strategy/lab.tscn
3164d7c9c2a75e19410ae179d1626774e3f78e16836c2ba70415d3d9fb605d88  tests/test_layout_strategy_ui.gd
6601c2eecfeffcae2c94d3d3d7f427dfc179917cfd3eb71a24b349e0548c0087  experiments/layout_strategy/session.gd
```

初始失败与中间失败日志仍保留在相应 QA/headless 目录；本报告引用的是修复后最新两次 UI 收据，未把它们改写成一次无失败的开发过程。最终完整源清单、启动及其他平台/导出包验收仍由主线程按其交接范围说明。
