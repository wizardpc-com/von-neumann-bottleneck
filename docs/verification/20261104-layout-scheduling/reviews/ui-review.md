# Round 4 实验界面独立审查 — 2026-11-04

审查者：`/root/review_records_final`。范围为 `experiments/layout_strategy/lab.gd`、`lab.tscn`、`tests/test_layout_strategy_ui.gd` 和 Session/Settings/F8/退出保护调用链。只读源码审查，未运行 Godot，也未修改源文件或测试。

## 待修复：P2 — 退出确认期间的设置语言切换把焦点恢复到背后的运行按钮

位置：`experiments/layout_strategy/lab.gd:583-598`，关联 `request_quit()`、`cancel_quit()` 和 `_button()` 的焦点记录。

触发步骤：

1. 运行或编辑一次，使 Session 有需保留的工作。
2. 从某个编辑控件按 Escape，打开退出确认。`request_quit()` 用 WeakRef 保存原控件，随后聚焦 `KeepExploring`；通用 `_button()` 的回调把 `_last_focus` 改成 `"KeepExploring"`。
3. 在退出确认仍显示时按 F10，打开全局 Settings，再修改语言。
4. `WindowMode.reload_localized_scene()` 先清空旧 `settings_layer`，调用实验界面的原地重建，再延迟重开 Settings。实验的 `_restore_focus("KeepExploring")` 只在 `interface` 中寻找控件；退出按钮属于独立的 `exit_layer`，查找必然失败，于是退回 `run_button`，且没有检查退出确认仍然可见。
5. 新 Settings 记录其背后的焦点为 Run。关闭 Settings 后，仍可见的退出确认背后留下了 Run 焦点。之后空格/Enter 可由 Button 先处理，不能依赖 `_unhandled_key_input()` 中的退出分支阻止；取消退出时，重建前的编辑控件 WeakRef 也已失效，无法回到对应编辑控件。

这是当前控制流中的缺陷，不要求未来功能才会触发。已有 UI 测试分别覆盖普通设置语言切换、退出确认上的 F8，但没有覆盖“退出确认 → F10 → 语言切换 → 返回”的组合。

建议在退出确认可见时，把语言重建后的焦点恢复到该确认层，并独立保存确认前控件的稳定标识供取消后恢复；不要把确认按钮的 `_last_focus` 当作草稿编辑器原焦点。补充真实 viewport 输入回归，检查 Settings 返回后焦点仍在退出确认、按键不能运行/编辑背后方案、取消后恢复对应编辑控件。主线程仍需实际运行复现和验收；本审查没有宣称已实机复现。

## 其他审查结果

- 历史选中仅检查快照；恢复通过 Session 的单次 `edit()`，Undo/Redo 不制造实测记录。各 workload 独立保留草稿、历史和基准。
- 显示的 Q1、总周期、RAM 和复制空间来自真实快照；失败运行保留 -1 的未完成响应并显示为横线，不能设置为比较基准。旧快照与当前草稿的差异有明确提示。
- UI 没有正式结果、进度写入或 Game/Test 切换调用；Scene 的 QA 路径防护在创建实验时检查，真正的 autoload 前隔离仍依赖 launcher，由另一位审查者负责。
- `Session` 无文件或 autoload 依赖；当前比较要求正确且同条件结果；恢复、选择、基准和有限历史分工清晰。
- 已阅读 UI 测试全文。源码覆盖正常语言重建、真实 Settings/F8 路由、文本 Undo、退出/OS-close 取消、双语与两个尺寸，以及保护文件和正式状态不变性；检查数量或截图是否通过必须以主线程新鲜运行证据为准。
- 公开成本解释在审查期间已修正为分别说明 queried value 的 compute 和 emitted value 的 output；当前文本不再把 sum 的输入数量与输出数量混在一起。

视觉尺寸、GPU 布局、原生输入、截图完整性和最终源码/QA 绑定尚未由本审查验证。完成上述焦点修复后应重新检查这份报告的待修复项，不能把源码审查直接当作可玩验收。
