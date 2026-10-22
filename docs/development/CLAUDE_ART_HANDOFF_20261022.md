# Claude 接手：美术与界面优化（2026-10-22）

## 接手基线

开发目录：`E:/VNB/game`。当前代码基线为 main 的 `bfb2ce4de6074a4454c708ae47557f809931bd2b`，已推送并通过 GitHub API 核对远端 SHA。本交接后续只补充文档，不改变此代码基线。Codex 已释放代码、Git 与 Godot 执行所有权；用户将让 Claude 接手继续优化美术设计等内容。

先读 `AGENTS.md`、`docs/CURRENT_STATE.md`、本文件和 `.godot/collaboration/handoff.md`，再核对实时 Git 状态。不要从旧 Claude 分支或恢复包重新覆盖 main。

## 当前已整合内容

- dot 的恢复提交 `fddfefc`：元件视觉与封装视觉记录、操作演示、旅程关系等；包括其基线上的实验室与终端更新。
- Claude 本地修改：画布上方停靠引导条、真实规格表、求助与完整说明的层级、统一窗口设计和相关章节界面调整。整合时优先采用 Claude 的布局，双方功能均保留。
- 首关接线：必须接齐 A→NOT、NOT→LAMP 才进入下一步；仅接第一根线不会提前宣告完成。演示端点随实际端口位置更新，避免入场重排后指针偏离。
- 演示指针：用户最后选定深色圆角箭头、柔白描边、淡蓝光晕，参考 ChatGPT 操作电脑的指针。保留轻量路径与点击反馈，区别于玩家指针；只演示，不接线、不移动真实鼠标、不授予进度。
- 引导条展开演示时高度不变；移除额外悬浮说明，操作细节放在悬停提示中。阅读、求助、设置、阻断层、折叠或窗口变化会中断演示。
- 半加器文案保留 A=1、B=1 的规格问题，指引使用已有元件，避免误导玩家必须先添加元件。

## 用户最近明确的偏好

1. Claude 的已有设计优先级更高；保留双方功能。
2. “Avoid unnecessary secondary labels and descriptions. Let the layout do the explaining.” 不用多余副标签与解释文字补救布局。
3. 修改与优化保持最小必要范围，不做无关重构。
4. 演示指针按最终参考风格继续使用；不要退回之前的紫色实心标准箭头。
5. 后续美术优化不默认授权改变玩法、仿真、判定、任务 ID、存档或作品合同。实验室与终端的既有风格约束仍需阅读；新的视觉方向按用户后续要求推进。

## 验证结果与边界

证据入口：[`../verification/20261022-windows-integration/README.md`](../verification/20261022-windows-integration/README.md)。

- Windows 全量执行 215 套 Godot 测试，加导入及用户目录检查，共 217 阶段。两套旧测试只设置接线标记，未建立两条连接；更新夹具后相关五套及两项隔离检查全部通过。没有为迁就测试放宽真实接线要求。
- 最终指针绘制修改后，操作演示、首关输入、引导布局三套及两项隔离检查通过。
- 中文与英文真实 GPU 视口输入回放各 112 项通过；最终圆角指针又完成中文 112 项回放。包含首关、半加器错误用例、修正、正式验证和显式封装。
- 14 项 Python 检查通过；四项本地 HTTP 测试需在允许回环访问的环境复跑。原始沙箱失败与成功复跑均有记录。
- 原生键鼠试玩完成过恢复基线首关；整合版本直接观察到实验室进入、第一根线保持步骤 1、演示第二根线、接齐后进入步骤 2。因用户 Esc/并行操作中断，不宣称完成最终版本全流程原生试玩。
- 没有新导出安装包，没有全 60 关人工通关，没有最终性能基准或音频验收。旧 Linux 性能数据不能代表这台 Windows 独显机器。

最终指针截图：[`render-rounded/zh_CN-not-entry.png`](../verification/20261022-windows-integration/render-rounded/zh_CN-not-entry.png)。`render-zh`、`render-en` 保留较早紫色指针迭代证据；不要误当最终视觉。回放的 `half-adder-entry` 截图拍在空搜索恢复测试之后，顶部残留的是上一操作状态，并非未经操作的初始入场画面。

## 美术接手建议（待做，不是已验收结果）

- 先在 1280×720 和较大窗口检查最终实际画面，再决定小范围修改；重点核对元件端口辨识度、停靠引导与规格表的留白、浮动窗口的层次和遮挡。
- 保留“同一时刻一个引导声音”、求助/说明层级、真实用例反馈、键盘快捷键和窗口恢复入口。
- 最终整合版完整原生试玩、初次玩家理解、音频和导出包验证仍可补做。若修改美术，不要把旧截图或旧测试成绩直接当作新版本验收。
- 优先复用现有场景和功能边界；不要因为审美调整重做仿真或存档逻辑。

## 代码入口与测试

主要文件：
- `src/hardware_foundations/tutorial_coach.gd`：停靠引导、说明、演示按钮。
- `src/hardware_foundations/operation_demonstration.gd`：演示指针和手势绘制。
- `src/hardware_foundations/hardware_foundations.gd`：真实操作状态、端口锚点和引导协调。
- `src/hardware_foundations/guide_case_table.gd`：规格表。
- `src/ui/floating_instrument_panel.gd`、`instrument_theme.gd`、`workbench_chrome.gd`：窗口与统一视觉。
- `src/ui/guide_stage.gd`、`guide_highlight.gd`：引导层级与高亮。
- `src/lab/`：实验室、终端及旅程展示；架构以 `ARCHITECTURE.md` 为准。

本机引擎为 `E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe`。用 `scripts/verify-project.py` 的隔离副本与存档验证。典型针对性命令：

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe --suite test_operation_demonstration --suite test_first_lesson_input --suite test_operation_coach_layout --suite test_guide_convergence --suite test_ui_convergence
```

按改动范围追加相关测试；真实显示回放与原生试玩另做，遵守单一执行所有者和顺序运行规则。不得使用或覆盖玩家正常存档。

## Git 与保留内容

- GitHub main 要求线性历史；普通 merge commit 会被拒绝。本轮推送的是已整合的线性提交，没有强推或修改远端规则。
- 本地 `claude/guide-convergence-20261021` 的 `bbe7a77` 保存原 Claude 改动；`codex/windows-playtest-20261022` 的 `1edb775` 保存相同最终代码树及双方合并历史。不要将该 merge commit 再推到 main。
- `E:/VNB/backups/dot-recovery-fddfefc-20261022` 保存恢复包、原始本地补丁、120 个新增文件及哈希。保留这些材料，不需重新导入。
- `E:/VNB/windows-playtest-20261022` 是本轮 QA/整合工作树；日常开发继续在 `E:/VNB/game`。其他已有工作树与玩家存档未清理。
- 本交接不自动开启 Claude 会话或发送消息，用户负责启动下一轮。
