# 全屏终端验收 — 2026-10-22

## 最终行为

- 房间没有左上角功能栏。待机文字通过材质绘制在实际玻璃网格上，透视、上下缩放、圆角和遮挡随模型一致变化。
- 点击终端或按 Enter 进入全屏终端。主操作保持突出；设置、档案、手册、作品、成就、反馈及其确认页面都留在终端内。
- Esc 先关闭最上层页面，再返回终端，最后返回房间；在房间按 Esc 或选择“退出游戏”才询问退出。取消不会退出游戏。
- 页面保持等比缩放，并按物理像素渲染。全屏终端期间停止渲染房间；回房间恢复渲染和物件交互。
- 任务、仿真、存档格式、解锁条件及反馈发送权限不变。测试使用独立用户目录。

## 实际图形与输入

Windows / Godot 4.7.1 stable / OpenGL Compatibility / NVIDIA RTX 5070 Ti Laptop / 驱动 596.36。

- 真实图形回归：57 项通过，包含四种窗口比例、1440p 物理像素、F10、F8、普通与离线反馈、嵌套回顾、暂停恢复和逐层 Esc。日志见 [rendered-input.txt](terminal-evidence/rendered-input.txt)。
- 原生鼠标键盘试玩：点击实体终端 → 设置 → F11 全屏/窗口 → Esc 返回终端 → Esc 房间 → Enter 重入 → 中英文切换 → 作品 → 回顾 → F8 → Esc 回顾 → Esc 作品。没有发送反馈。试玩暴露的反馈底部透出旧页问题已修复，最终图形回归额外断言整页覆盖。
- 实际渲染保存四组共 44 张 PNG：中英文各 1280×720 / 1600×900，包含待机、左右环顾、终端和七个功能页面。终端截图保留真实打字动画时刻。
- 原生试玩关注操作流程；图形回归同时覆盖最终反馈覆盖和物理分辨率修正。均不代表陌生玩家理解度或其他 GPU 的验收。

| 画面 | 中文 | English |
| --- | --- | --- |
| 720p 主界面 | [终端](terminal-evidence/zh_CN-1280x720/04-terminal.png) | [Terminal](terminal-evidence/en-1280x720/04-terminal.png) |
| 900p 主界面 | [终端](terminal-evidence/zh_CN-1600x900/04-terminal.png) | [Terminal](terminal-evidence/en-1600x900/04-terminal.png) |
| 房间透视 | [左视角](terminal-evidence/zh_CN-1600x900/02-left.png) | [Right view](terminal-evidence/en-1600x900/03-right.png) |
| 设置 | [设置](terminal-evidence/zh_CN-1600x900/panel-settings.png) | [Settings](terminal-evidence/en-1600x900/panel-settings.png) |
| 手册 | [手册](terminal-evidence/zh_CN-1600x900/panel-handbook.png) | [Handbook](terminal-evidence/en-1600x900/panel-handbook.png) |
| 反馈 | [反馈](terminal-evidence/zh_CN-1600x900/panel-feedback.png) | [Feedback](terminal-evidence/en-1600x900/panel-feedback.png) |

## 帧时间

60 FPS 上限，每组待机、环顾和终端各预热 1 秒后采样 180 帧，共 2160 帧。
四组平均 59.98–60.02 FPS；P95 为 17.25–17.69 ms。这是当前机器的渲染帧间隔，包含帧率限制，不是 GPU 单独耗时或无上限性能承诺。进入全屏终端后，房间 viewport 更新关闭；记录中的房间 draw calls 为 0。
原始数据位于每组的 `performance.json`。

## 回归与交付

实现提交：`e2e5aca618915dbdc1a3839fe79d5d049362a3c7`。
Windows 隔离回归在用户要求减少测试、尽快收尾后停止：已完成 194 项，其中 193 项通过，1 项旧断言把光标尺寸固定为旧字号。该断言已改为检查当前文字行高及 1:2 比例，并单独复核通过（57 项断言，见 [caret-recheck.txt](terminal-evidence/caret-recheck.txt)，提交 `3e1d312a9ae95f56b1443e021be141c1c03fa6a8`）；原始部分结果保留在 `terminal-evidence/windows-partial-results.json`。尚未执行的检查不计为通过。

测试定位修正提交为 `a5d395f46f5618fe465d0c110647784fb6e1fd3e`。[远端 CI](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/39640813691) 最后观察仍在运行；交付按用户要求不等待全量 CI，不声称全量通过。main 推送后的最终状态以仓库 Actions 为准。

实现与回归文件 SHA256 见 [tested-source-sha256.json](terminal-evidence/tested-source-sha256.json)。原 `E:/VNB/game` 工作目录的 140 个已登记未提交文件经逐一 SHA256 核对保持不变；本轮独立工作树为 `E:/VNB/immersive-lab-qa`。
