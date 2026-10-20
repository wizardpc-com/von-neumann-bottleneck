# 实验室关卡入口与 Esc 修复（2026-10-20）

基于 `claude/terminal-polish-20261020` 的
`257da16424dfce7a7bfed69a9622a324ba257b22`。

## 行为

- 尚未取得关卡完成记录时，电脑的「开始 · 接通第一条线路」明确进入
  `hardware_foundations/tutorial`。从作品墙或地图访问其他关卡不会改变这个入口。
- 实验室按其显示的任务键进入关卡；明确指定的目标不再回退到另一项上次访问记录。
  作品墙仍直接进入 `creation/G3_keep`（界面编号 10-3）。
- 压缩／内容预测／创造工作台，以及表示、服务、地址预测工作台，Esc 使用各自已有的
  返回和离开保护流程。文本编辑、设置和确认弹窗先处理自己的按键；取消离开保留当前草稿。
- 第四章先关闭只读提示，再从关卡返回地图；章节入口返回实验室。
  地图和新增 Esc 处理忽略按住按键产生的重复事件，切换场景前消费事件。

仿真、判定、任务 ID、存档格式和作品合同不变。修复按用户要求交付到
`codex/navigation-closeout-20261020` 分支；不合并主线或导出游戏包。

## 检查范围

新增 `test_lab_terminal_routing`：真实场景切换与 viewport Enter/Esc，中英文覆盖
作品墙／旅程板进入后返回实验室再点电脑；检查第四章提示层和地图返回。
第四章前置访问是明确注入的测试模式，不授予完成记录。

新增 `test_workbench_escape`：中英文 viewport F10/Esc，覆盖四个工作台的
设置、按键重复、离开确认、取消保留、文字编辑和未提交样例。探针仅覆盖最终离开操作，
离开前的保护和输入路由均使用生产实现。

测试使用独立项目副本和用户目录。自动化 viewport 输入与有渲染的运行均不等于
Windows 原生键鼠操作、导出包或真人完整旅程验收。

## 已执行验证

- Godot `4.7.1.stable.official.a13da4feb`，Windows。
- 完整 headless 回归：**182/182 套件通过**；导入和用户目录隔离检查均通过。
  `test_recovery_game_input` 为独立 GUI 套件，本轮未运行。
- 新增用例：`test_lab_terminal_routing` **37/37**，`test_workbench_escape` **58/58**。
- 上述两项使用 OpenGL 实际渲染、1280×720 窗口再次运行，**2/2 套件通过**。
  仍为合成 viewport 输入；完整命令和结果保存在 `rendered/results.json`，对应日志在同目录。
- 8 个运行文件与 2 个新增测试的 SHA-256 与测试副本全部一致。
- `git diff --check` 通过。

命令：`python -X utf8 scripts/verify-project.py --godot E:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`。
执行时 `TEMP`、`TMP` 指向 `E:\VNB\temp`。

本地完整日志：`.godot/verification/20261020T134737Z-f2c2be88/`，
套件结果为 `results.json`，源码身份为 `source_identity.json`。
