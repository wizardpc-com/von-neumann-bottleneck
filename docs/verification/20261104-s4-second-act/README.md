# S4 — 表示与服务主舞台

表示章节固定展示完整 64 字节板，将回放控制与真实缓存事件放在成本条旁；新运行自动播放真实记录，分块/地址高亮与成本填充跟随记录事件。修改草稿后不会把旧记录高亮画到不同方案上。

服务章节将四条流的外存、驻留、首响应及事件标题移到全宽舞台；空状态只显示待测通道。运行后自动展示回放与实测结果；更多证据标签、整组定点移动收起。任务说明可独立滚动，保存与运行同排。两章的语言入口使用设置，退出沿用原处理函数并移出导航栏；回顾在返回入口之前。影片函数及触发条件未改。

## 对照截图

每张原始帧为 1280×720；共 10 张 PNG。`before-*` 为编辑前，`after-*` 为最终版本。

| 配对 | 路线与时刻 |
| --- | --- |
| `before-rep.png` / `after-rep.png` | representation/mixed_scan，进入后 2 秒 |
| `before-rep-3s.png` / `after-rep-3s.png` | 同路线，点击运行后 3 秒 |
| `before-svc.png` / `after-svc.png` | service/move_state，进入后 2 秒 |
| `before-svc-3s.png` / `after-svc-3s.png` | 同路线，点击运行后 3 秒 |
| `before-routes.png` / `after-routes.png` | 原像素拼接：左上 prepare_once、右上 one_plan、左下表示英文、右下服务英文 |

完整原始截图（含运行后 +1 秒）、命令脚本及输出留在 `.godot/s4/`。重放：`python -X utf8 .godot/s4/capture.py accepted`。脚本逐个设置全新的 APPDATA/LOCALAPPDATA，使用测试模式：@2 进入、@4 入口截图、@5 点击运行（表示 180,642；服务 145,694）、@6/+1s、@8/+3s、@9 退出。英文使用 `--locale=en`。上述 before/after 时序及点击坐标相同。

## 验证

Godot 4.7.1 stable，Windows；最终相关证据合并为 **33 套件：32 PASS，1 个已复现基线 FAIL**。下面列出每个套件自己的检查数（没有数值的套件只报告自身 PASS）。

复现初次全集命令（PowerShell，在本工作树）：

```powershell
$env:APPDATA="$PWD/.godot/s4/qa-profile"; $env:LOCALAPPDATA=$env:APPDATA
$suites=Get-ChildItem tests -Name '*.gd' | Where-Object {$_ -match '^test_(representation|service|second_act|chapter5|completion_service)'} | ForEach-Object {[IO.Path]::GetFileNameWithoutExtension($_)}
$qaArgs=@('-X','utf8','scripts/verify-project.py','--godot','E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
foreach($suite in ($suites+@('test_global_save','test_mode_access'))) {$qaArgs+=@('--suite',$suite)}
& python @qaArgs
```

修正后重跑命令：同一 verifier，表示使用 `--suite test_representation_visual --suite test_representation_workbench_presentation`；服务使用 `--suite test_completion_service_clarity` 加 `Get-ChildItem tests -Name 'test_service*.gd'` 转成逐项 `--suite`。对应最终日志在 `.godot/verification/`：`20261104T103333Z-cf7f1786`（未受后续布局调整影响的套件）、`20261104T103635Z-6a6ed6ee`（表示最终视觉/布局）、`20261104T104221Z-712a5006`（服务最终全部套件）。逐项来源记录在 `.godot/s4/combined-results.json`。

| 套件 | 结果 | 原始汇总 |
| --- | --- | --- |
| `test_chapter5_cinematic` | PASS | PASS: chapter5 cinematic 13 checks, 0 failures |
| `test_completion_service_clarity` | PASS | PASS: test_completion_service_clarity 101 checks, 0 failures |
| `test_global_save` | PASS | PASS: minimal global Save/Continue, provenance reconciliation, chapter gates, New Game, and mode isolation tests passed |
| `test_mode_access` | PASS | PASS: mode access 14 checks; free_candidate=false |
| `test_representation_cache` | PASS | PASS: representation cache 1395 checks; per-access invariants, independent victims, byte budget and costs |
| `test_representation_closure_navigation` | PASS | PASS: test_representation_closure_navigation 55 checks, 0 failures |
| `test_representation_design_shelf` | PASS | PASS: test_representation_design_shelf 38 checks, 0 failures |
| `test_representation_edit_context` | PASS | PASS: test_representation_edit_context 39 checks, 0 failures |
| `test_representation_plan` | PASS | PASS: representation plan 10403 checks |
| `test_representation_player_input` | PASS | PASS: representation preparation player input |
| `test_representation_region` | PASS | PASS: test_representation_region: 3329 checks, 0 failures |
| `test_representation_restored_notice` | PASS | PASS: test_representation_restored_notice 64 checks, 0 failures |
| `test_representation_session` | PASS | PASS: test_representation_session 47 checks, 0 failures |
| `test_representation_visual` | PASS | PASS: test_representation_visual 264 checks, 0 failures |
| `test_representation_workbench_presentation` | PASS | PASS: test_representation_workbench_presentation 9303 checks, 0 failures |
| `test_second_act_content` | PASS | PASS: independent second-act content review 69 |
| `test_second_act_experiments` | PASS | PASS: second-act codecs, measured tradeoffs, inference quality and isolated UI |
| `test_second_act_independent` | PASS | PASS: independent algebraic state and representation cost oracles |
| `test_second_act_navigation` | PASS | PASS: test_second_act_navigation 26 checks, 0 failures |
| `test_service_commission_ui` | PASS | PASS: test_service_commission_ui 27 checks, 0 failures |
| `test_service_commissions` | PASS | PASS: test_service_commissions 212 checks, 0 failures |
| `test_service_context_navigation` | PASS | PASS: test_service_context_navigation 21 checks, 0 failures |
| `test_service_design_shelf` | PASS | PASS: test_service_design_shelf 48 checks, 0 failures |
| `test_service_journey_input` | PASS | Journey input checks: 15; failures: 0; PASS: service journey input |
| `test_service_learning_ui` | PASS | PASS: test_service_learning_ui 51 checks, 0 failures |
| `test_service_number_display` | PASS | PASS: test_service_number_display 24 checks, 0 failures |
| `test_service_plan` | PASS | PASS: service plan (7268) |
| `test_service_player_input` | PASS | PASS: service player input |
| `test_service_session` | PASS | PASS: test_service_session 63 checks, 0 failures |
| `test_service_split_actions` | PASS | PASS: Service split actions: 30 checks, 0 failures |
| `test_service_state_replay` | PASS | PASS: test_service_state_replay 3118 checks, 0 failures |
| `test_service_state_replay_view` | PASS | PASS: test_service_state_replay_view 71 checks, 0 failures |
| `test_service_undo_context` | FAIL (baseline) | FAIL: test_service_undo_context 96 checks, 16 failures |

基线失败：`test_service_undo_context` 的 16 项撤销/选择上下文断言。将隔离验证副本中两个所属实验目录的 `.gd` 全部恢复为 `git show HEAD:<path>` 后，以同一引擎、全新 APPDATA/LOCALAPPDATA 运行 `--headless --path <isolated-project> --script res://tests/test_service_undo_context.gd`，同为 96 检查 / 16 失败。脚本 `.godot/s4/baseline-check.py`，输出 `.godot/s4/baseline-undo.log`。未修改这项既有行为。

## 限制与交接

- 没有需要改变模拟/指标/判定/存档的提案；这些文件未改。未提交、合并或推送。
- 现有返回处理函数根据进入来源返回地图或实验室，保留该行为；没有额外添加与它并列的独立“实验室”按钮。独立出口需先明确导航语义与未保存保护。
- 服务主舞台仍回放已有首响应时间范围；后续全部响应与写回可在更多证据/历史去向逐事件查看。表示 5-5 的资产 A 固定可见，第二份资产 B 仍在说明滚动区。
- 已查看中文、英文 GPU 截图；未做人类新手理解度、完整旅程、物理鼠标/键盘或导出包验收。Godot 的证书库读取警告属环境输出，未作为测试通过依据。

## Round 2 - stage first

Representation now opens with the byte board, followed by a compact order card with all order names and targets. The card tooltip retains the complete machine/preparation rules. A closer look retains purpose, action, completion criteria, asset legend and raw bytes. The right column groups verdict, cost strip and replay above history/plans; detailed record prose appears once in the foldout.

Service has a compact three-column scrollable group sequence with the existing A-D marks, a top task card and a larger lane stage. The coloured result headline uses the existing measured-feedback function. Peak/quality metrics remain below the stage. Quit is visible beside Run/Save in both screens and calls the unchanged leave handler.

### Round 2 evidence

Ten additional PNGs, twenty total. Before/after pairs: `r2-before-rep.png` / `r2-after-rep.png`, `r2-before-rep-3s.png` / `r2-after-rep-3s.png`, `r2-before-svc.png` / `r2-after-svc.png`, `r2-before-svc-3s.png` / `r2-after-svc-3s.png`. English: `r2-after-rep-en.png`, `r2-after-svc-en.png`; `--locale=en` works. prepare_once and one_plan also captured in scratch.

All routes retain entry @2, entry shot @4, Run @5, post-run shot @8, quit @9. The click follows the relocated Run button: representation before 180,642 / after 180,458; service before 145,694 / after 145,522. Replay snapshots may differ by one event because capture and render clocks are independent; recorded results do not change. Raw logs, intermediate attempts and replay scripts are in `.godot/s4b/` (`capture.py`, `capture-service.py`). Each launch uses fresh APPDATA/LOCALAPPDATA there. Chosen final captures are accepted-rep*, proof-svc*.

### Round 2 verification

Full Round 1 selection plus two Settings neighbours was rerun. Exact full command (PowerShell, worktree root):

```powershell
$env:APPDATA="$PWD/.godot/s4b/end-qa-profile"; $env:LOCALAPPDATA=$env:APPDATA
$suites=Get-ChildItem tests -Name '*.gd' | Where-Object {$_ -match '^test_(representation|service|second_act|chapter5|completion_service)'} | ForEach-Object {[IO.Path]::GetFileNameWithoutExtension($_)}
$qaArgs=@('-X','utf8','scripts/verify-project.py','--godot','E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
foreach($suite in ($suites+@('test_global_save','test_mode_access','test_recovery_settings_language','test_late_settings_localization'))) {$qaArgs+=@('--suite',$suite)}
& python @qaArgs
```

Final layout recheck: same verifier with `--suite test_completion_service_clarity --suite test_service_plan --suite test_service_journey_input --suite test_service_session --suite test_representation_workbench_presentation`. Sources: `.godot/verification/20261104T110421Z-fdddb6fc` and `20261104T111513Z-de79136c`; a final purpose-label identity recheck uses the direct command `& <Godot> --headless --path <worktree> --script res://tests/test_representation_workbench_presentation.gd`, with fresh `.godot/s4b/purpose-final-profile` APPDATA/LOCALAPPDATA. Consolidated results follow below; intermediate failures remain in scratch.

GUI input probe: `& <Godot> --path <worktree> --script res://.godot/s4b/quit_input.gd`, with fresh `.godot/s4b/quit-final-profile` APPDATA/LOCALAPPDATA. `.godot/s4b/quit-final.log`: 12 checks, 0 failures. Viewport mouse clicks open Quit and Cancel; Tab reaches Quit; dirty drafts remain. The persistent/dirty fixture is explicit: ordinary temporary Service Test mode intentionally has no persistence guard. Both in-level Language buttons are hidden. Existing Settings language paths pass their dedicated suites; existing toggle handlers remain callable.

HEAD-source comparison repeated in the retained isolated `.godot/verification/20261104T102918Z-5fcb1d6f/project`: representation edit context is 39 checks / 0 failures on both HEAD source and current. The Round 1 failure is service undo context: 96 checks / 16 failures on both HEAD source and current. Logs: `.godot/s4b/baseline-test_representation_edit_context.log` and `baseline-test_service_undo_context.log`.

### Dependency and limits

`src/lab/cinematic_artifact.gd`: copied from integration, not owned. Byte-for-byte from `E:/VNB/temp/claude-experience-20261104/wt/int/src/lab/cinematic_artifact.gd`; SHA-256 `e00867eaea969e3a30442bccff29ac875ef46dcc7d4f15dbb02c3e07b5dd02ed`. Do not integrate the local copy as S4 work. The requested awaited call follows movie.queue_free inside the existing non-null branch. Chapter5 cinematic suite passes; integration-only test_b2_bridges was not copied/run. Lead must verify the full artifact route in integration.

No proposals needing impact analysis. No simulation, judgement, task IDs or save fields changed. No commit/merge/push. No human comprehension/full-journey/export acceptance claimed. Windows certificate-store warnings occur throughout and are excluded from test success claims. English entry shots can include transient Yi guidance; bilingual layout suites check permanent controls.

### Consolidated Round 2 suite results

35 suites: 34 PASS; 1 reproduced baseline FAIL. The purpose-label identity rerun supersedes the corresponding intermediate assertion failure. Full source map: `.godot/s4b/combined-round2.json`.

| Suite | Result | Exact test summary |
| --- | --- | --- |
| `test_chapter5_cinematic` | PASS | PASS: chapter5 cinematic 13 checks, 0 failures |
| `test_completion_service_clarity` | PASS | PASS: test_completion_service_clarity 101 checks, 0 failures |
| `test_global_save` | PASS | PASS: minimal global Save/Continue, provenance reconciliation, chapter gates, New Game, and mode isolation tests passed |
| `test_late_settings_localization` | PASS | PASS: late Settings localization 511 checks, 0 failures |
| `test_mode_access` | PASS | PASS: mode access 14 checks; free_candidate=false |
| `test_recovery_settings_language` | PASS | PASS: recovery Settings language 754 checks, 0 failures |
| `test_representation_cache` | PASS | PASS: representation cache 1395 checks; per-access invariants, independent victims, byte budget and costs |
| `test_representation_closure_navigation` | PASS | PASS: test_representation_closure_navigation 55 checks, 0 failures |
| `test_representation_design_shelf` | PASS | PASS: test_representation_design_shelf 38 checks, 0 failures |
| `test_representation_edit_context` | PASS | PASS: test_representation_edit_context 39 checks, 0 failures |
| `test_representation_plan` | PASS | PASS: representation plan 10403 checks |
| `test_representation_player_input` | PASS | Representation input checks: 72; failures: 0 / PASS: representation preparation player input |
| `test_representation_region` | PASS | PASS: test_representation_region: 3329 checks, 0 failures |
| `test_representation_restored_notice` | PASS | PASS: test_representation_restored_notice 64 checks, 0 failures |
| `test_representation_session` | PASS | PASS: test_representation_session 47 checks, 0 failures |
| `test_representation_visual` | PASS | PASS: test_representation_visual 264 checks, 0 failures |
| `test_representation_workbench_presentation` | PASS | PASS: test_representation_workbench_presentation 9303 checks, 0 failures |
| `test_second_act_content` | PASS | PASS: independent second-act content review 69 |
| `test_second_act_experiments` | PASS | PASS: second-act codecs, measured tradeoffs, inference quality and isolated UI |
| `test_second_act_independent` | PASS | PASS: independent algebraic state and representation cost oracles |
| `test_second_act_navigation` | PASS | PASS: test_second_act_navigation 26 checks, 0 failures |
| `test_service_commission_ui` | PASS | PASS: test_service_commission_ui 27 checks, 0 failures |
| `test_service_commissions` | PASS | PASS: test_service_commissions 212 checks, 0 failures |
| `test_service_context_navigation` | PASS | PASS: test_service_context_navigation 21 checks, 0 failures |
| `test_service_design_shelf` | PASS | PASS: test_service_design_shelf 48 checks, 0 failures |
| `test_service_journey_input` | PASS | Journey input checks: 15; failures: 0 / PASS: service journey input |
| `test_service_learning_ui` | PASS | PASS: test_service_learning_ui 51 checks, 0 failures |
| `test_service_number_display` | PASS | PASS: test_service_number_display 24 checks, 0 failures |
| `test_service_plan` | PASS | PASS: service plan (7268) |
| `test_service_player_input` | PASS | PASS: service player input |
| `test_service_session` | PASS | PASS: test_service_session 63 checks, 0 failures |
| `test_service_split_actions` | PASS | PASS: Service split actions: 30 checks, 0 failures |
| `test_service_state_replay` | PASS | PASS: test_service_state_replay 3118 checks, 0 failures |
| `test_service_state_replay_view` | PASS | PASS: test_service_state_replay_view 71 checks, 0 failures |
| `test_service_undo_context` | FAIL (baseline) | FAIL: test_service_undo_context 96 checks, 16 failures |
