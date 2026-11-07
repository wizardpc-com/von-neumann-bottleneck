# 回归记录 · 2026-11-08 画面与交互轮

Windows，Godot 4.7.1 stable，`scripts/verify-project.py` 的独立工程副本，每次运行使用独立 APPDATA/LOCALAPPDATA。

## 全量

集成树 `dd0209b`（九项任务中的八项；W3 之后另行验证）：

```
python -X utf8 scripts/verify-project.py --godot <Godot_v4.7.1-stable_win64_console.exe>
```

结果：281 PASS / 4 FAIL（另 import、user_directory 通过）。四项失败均由本轮有意的界面改动引起，没有模拟、判定或存档差异：

| 套件 | 原因 | 处理 |
| --- | --- | --- |
| `test_journey_observatory` | W7 隐藏了地图的章节下拉行，观察站入口（经典大厅模式下可见）随之不可达，Esc 后焦点无法归还。**真实回归** | 观察站按钮与成长档案一起移入页头（`src/campaign/task_tree.gd`）；默认实验室模式下仍隐藏 |
| `test_creation_keyboard_focus` | W5 按设计隐藏单元下拉与语言按钮，测试仍走旧 Tab 链 | 测试改为从翻页按钮出发，检查焦点落在可见且可用的操作上；语言重建改为调用保留的 `toggle_language()` |
| `test_guide_convergence` | W8 把运行前回放提示改为“尚未运行”，测试只接受旧文案 | 两种文案都满足“进入任务不声称输入已改动”，测试接受二者 |
| `test_target_evidence_guidance` | W9 把超时差额放进判定标题、把“输出尚未通过核验”放进详情 | 测试改为检查标题中的 `result.over` 与详情中的未核验句 |

## 修复后定向复跑

上述四套，加上地图两套与第六章（W3）十二套，在包含全部九项与修复的工作树上：

```
--suite test_creation_keyboard_focus --suite test_guide_convergence --suite test_journey_observatory --suite test_target_evidence_guidance --suite test_task_tree_presentation --suite test_tree_relation_focus --suite test_service_player_input --suite test_service_plan --suite test_service_journey_input --suite test_service_learning_ui --suite test_service_commission_ui --suite test_service_design_shelf --suite test_service_undo_context --suite test_service_context_navigation --suite test_service_number_display --suite test_service_state_replay --suite test_service_state_replay_view --suite test_service_split_actions
```

结果：18/18 PASS（另 import、user_directory 通过）。

此前历史记录中的 `test_service_undo_context`、`test_prediction_record_source` 既有失败，本次全量与复跑中均通过。

## 各任务的 GPU／呈现检查

由各任务在自己的 worktree 中执行，命令与计数见各目录 README：W1 GPU 249/249；W2 呈现 2,329/0；W4 GPU 1,320/0；W5 GPU 工作台 461/0（CPG GPU 的 12 项焦点／Esc 失败在未改基线中完全相同）；W6 GPU 1,542/0；W8 呈现 2,497/0（`test_locality_chapter_ui` GPU 矩阵 12 项失败，未改基线 14 项且包含这 12 项）；W9 GPU 输入 47/47。集成后 Claude 另取地图、第二章、第四章与英文实验室画面复核。

## 未验证

原生键盘／IME、真人新手、高 DPI、导出包、Mac 实机、听感。
