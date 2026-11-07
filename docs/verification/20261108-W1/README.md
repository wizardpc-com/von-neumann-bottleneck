# W1 · 第四章布局工作台

范围：只改两份 UI、布局/反馈测试与末尾追加的三条中英字符串。模拟器、目录、状态、排名、资格、挑战码与存储源码均未改；无提交或分支操作。

## Round 2 · Claude review

榜单背后沿用 `LevelCompletionOverlay.BACKDROP`（0.88 alpha），随窗口显隐同步撤下遮罩。表格按行数保留至少五行的常规空间，上限八行；最小窗口按剩余高度收缩并滚动，底部操作紧随表格。结果标题仅保留订单与状态，指标条保留数字，下一行只显示首个超标项及差额，通过时省略。完整合同说明仍在详情中。

工具栏下的提示保留：入口提示编辑与运行，编辑后要求重跑，运行后提示检查结果或探索其他方案，定位后报告已选中的原事件。它随状态变化并说明下一步操作。

fields 运行、榜单、relocation 运行的 after 图片已更新；六张独立中英文原图为 `round2-{zh_CN,en}-{fields-run,rankings,relocation-run}.png`。入口 fields/mixed 沿用第一轮截图。[精确 GPU 与截图命令、逐次独立 APPDATA](round2-commands.json)。临时输出继续使用沙箱可写的 worktree 内 `.godot/`。

初次固定五行高度在 760×420 且显示目标说明时挤出了操作区；失败证据保留于 `.godot/verification/20261107T164333Z-b71628c7/`。最终版本重新运行完整 13 套测试，全部 PASS，另 import/user_directory 通过。
## 截图

以下五对为相同任务、初始 Test 草稿和操作。before 为修改前的 1280×720 中文原图；after 为最终中文（左）/英文（右）各 1280×720 原图的无缩放拼接，总宽 2560。均在入关卡 9 秒后拍摄；运行后 2 秒拍摄，榜单再等待 2 秒。

| 路线 | 修改前 | 修改后（中 / 英） |
| --- | --- | --- |
| fields 稳定入口 | [before-fields.png](before-fields.png) | [after-fields.png](after-fields.png) |
| fields 运行全部订单 | [before-run.png](before-run.png) | [after-run.png](after-run.png) |
| fields 我的方案榜 | [before-rankings.png](before-rankings.png) | [after-rankings.png](after-rankings.png) |
| mixed 稳定入口 | [before-mixed.png](before-mixed.png) | [after-mixed.png](after-mixed.png) |
| relocation 运行后 A/B | [before-relocation.png](before-relocation.png) | [after-relocation.png](after-relocation.png) |

## Owner-review trade-offs

- 之前：可拖动/最小化/关闭/缩放的外观，切换又覆盖几何。之后：固定左侧单选工具/任务/记录，地址区始终可见；移除内存开关和所有虚假窗口控件。编辑栏宽 400、记录栏宽 560（1600 逻辑宽）；记录不再从左侧跳到右侧。
- 之前：混合按钮顺序，运行在中间。之后：左侧视图与编辑，右侧参考与榜单，运行固定最右。
- 之前：每单三排全宽操作、比较另占多行。之后：状态底色、真实指标条、首个合同差额、单行操作；上次比较的完整数字差值留在详情内。列表使用余下高度，详情展开时仍可滚动。
- 之前：系统窗框与内部关闭重复。之后：沿用独占 Window 行为，采用无边框主题表面、一个内部关闭；表格数值保持右对齐，当前草稿/目标行以不同既有调色板颜色区分。

反馈：只有可比完整订单齐全、至少一个受跟踪指标严格改善、每单状态不退步且周期/RAM总流量/临时峰值均不变差才播放 improve；混合取舍没有正向颜色。原 pass/fail 分支保留。新增六个布局/反馈边界断言。

## 验证

最终隔离证据：`.godot/verification/20261107T164532Z-63a75dbf/`。13 套测试全部 PASS，另 import 与 user_directory 通过（15/15）；逐套信息见 [suite-summary.txt](suite-summary.txt) 与 [headless-results.json](headless-results.json)。有数字总数的十套合计 898 检查；其余三套不打印计数，不推算总数。

PowerShell（从 worktree 根运行）：

```powershell
$env:APPDATA="$PWD\.godot\w1-data\finalchecks\roaming"
$env:LOCALAPPDATA="$PWD\.godot\w1-data\finalchecks\local"
python -X utf8 scripts/verify-project.py --godot 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --suite test_layout_ui --suite test_layout_scoreboard --suite test_layout_scoreboard_ui --suite test_layout_challenge_code --suite test_layout_challenge_store --suite test_layout_challenge_controller --suite test_layout_challenge_window --suite test_layout_navigation --suite test_layout_preview_selection --suite test_layout_trace_storage --suite test_layout_simulation --suite test_layout_recipe_sources --suite test_target_evidence_guidance
```

Round 2 GPU 检查在同一最终隔离副本、每次独立 APPDATA 下依次执行，榜单 UI **47/47**、挑战窗口 **120/120**、挑战控制器 **82/82**，共 **249/249**，零失败。`git diff --check` 通过。

精确命令：

```powershell
$env:APPDATA="$PWD\.godot\w1-data\gpu-final\roaming"
$env:LOCALAPPDATA="$PWD\.godot\w1-data\gpu-final\local"
$qaProject="$PWD\.godot\verification\20261107T164532Z-63a75dbf\project"
foreach ($suiteName in @('test_layout_scoreboard_ui','test_layout_challenge_window','test_layout_challenge_controller')) {
  & 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path $qaProject --script "res://tests/$suiteName.gd" -- --layout-score-capture --layout-challenge-capture
}
```

截图复跑：`.godot/w1-capture.py` 保留精确调用；等价 fields 路线如下（其余任务替换 task key，mixed 只取入口，relocation 取运行后）：

```powershell
$env:APPDATA="$PWD\.godot\w1-data\review\roaming"
$env:LOCALAPPDATA="$PWD\.godot\w1-data\review\local"
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" -- --test-mode --locale=en --dev-enter=chapter_4/fields@2 "--dev-shot=$PWD/.godot/review-fields.png@9" --dev-click=1210,65@10 "--dev-shot=$PWD/.godot/review-run.png@12" --dev-click=1100,65@13 "--dev-shot=$PWD/.godot/review-rankings.png@15" --dev-quit=16
```

修改前运行按钮位置为 `400,65`，榜单 `650,65`。所有玩家目录均隔离。沙箱仅允许本 worktree 写入，所以临时输出位于本地忽略的 `.godot/`，没有使用外侧的指定 tmp 目录。

## 限制

Round 2 已目视检查六张中英文原图（运行、榜单、relocation）；第一轮入口截图保留，未见越界/裁切；新增小字为 17 逻辑像素（1280 窗口约 13.6 px）。Windows 根证书读取警告为环境噪音，判定文件 15/15 PASS。未进行真人新手测试、全旅程实玩或听觉验收；较窄窗口不在本轮验收范围。未请求任何模拟/成绩/存储影响改动；Proposals needing impact analysis：无。
