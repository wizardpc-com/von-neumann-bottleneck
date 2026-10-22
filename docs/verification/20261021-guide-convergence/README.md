# 关卡引导收敛 · 验证记录（2026-10-21）

对应[交接](../../development/GUIDE_CONVERGENCE_HANDOFF_20261021.md)。固定 Godot 4.7.1 stable（Windows console），所有运行使用隔离的 APPDATA／用户目录，未使用玩家存档。

## 自动测试

| 检查 | 结果 | 说明 |
|---|---|---|
| 新增 `tests/test_guide_convergence.gd` | 70 项通过（中英，渲染与 headless 各一次） | 引导条停靠且不覆盖画布；求助替换当前一步；完整说明为阅读层；说明打开时求助先收起说明；结算卡阻断引导；半加器按真实运行写出缺失输出、调试不符（SUM 期望 0 实际 1）、正式失败第 4 组并高亮失败行；不点名门电路；改线清空旧证据；开场让位给可见任务卡、避开底部、遇阻断层离场；第二章单行顶栏、回放栏中性、未应用草稿替换「现在」并可恢复 |
| `test_half_adder_input`（真实视口输入：NOT 五步 → 半加器失败 → 改线 → 通过 → 封装） | 中英各 82 项通过，渲染 | 日志见 `logs/`，截图见 `screenshots/after/` |
| 受影响套件批次（16 套） | 14 通过、2 失败 → 修复后通过 | `test_hint_input` 两项与 `test_ui_convergence` 一项断言旧布局（求助卡浮在画布、与步骤卡并列）；按新规则更新为「求助在停靠引导条内、不被工具窗遮挡、不覆盖画布」，并修复一处 `move_child` 报错和引导条宽度被 `reset_size()` 压缩的真实缺陷 |
| 完整回归 `scripts/verify-project.py` | 205/205 通过（导入、用户目录隔离与 203 个 headless 套件，含新套件） | `logs/full-regression-results.json`；隔离副本 `.godot/verification/20261021T084021Z-0499f132`。`test_recovery_game_input` 按惯例只在 `--gui` 下运行，本轮未单独运行，但其子类 `test_half_adder_input` 的真实输入路线已在中英文渲染下通过 |
| 回归后的一处小改（第四章关卡名字号与颜色） | 第四章 7 个布局套件、`test_unified_style`、新套件全部通过 | `logs/layout-recheck-results.json` |

## 画面

`gallery.html` 给出前后对照。`screenshots/before/` 为 main `472890a` 的开发路由截图；`screenshots/after/` 包含开发路由截图（`route-*`，测试模式下顶栏多一个“测试模式”选择框）与真实输入回放截图（`zh_CN-*`、`en-*`）。均为 1280×720 实际渲染。

## 未验证

- 第四章关卡名在该章主题下仍比第一、二章显得小，可在后续视觉精修中统一。
- 1920×1080、系统缩放、放大字体；减少动效只在自动测试中开启。
- 表示、服务、预测、创造工作台只确认顶栏未被破坏，没有按新规则改动其引导。
- 原生键鼠、导出包和真人理解测试均未进行。
