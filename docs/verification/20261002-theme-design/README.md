# 主题设计审计与2-6试点验证

2026-10-02，Godot `4.7.1.stable.official.a13da4feb`，macOS Apple M2。
源码起点 `98f2e47`，本轮局部未提交改动；不是公开包验收。

## 实现与模型结果

2-6 开放现有模拟器支持的0/1/2/4行工作组，仍固定一行Cache、两轮、按行访问和145周期目标。双语Mission改为提出实验问题；工作组面板局部滚动。未改变模拟器、正式数据、完成条件或存档schema。

| 每组行数 | 结果正确 | 周期 | miss | RAM字节 | 达标 |
| --- | --- | --- | --- | --- | --- |
| 0（整轮） | 是 | 210 | 8 | 128 | 否 |
| 1 | 是 | 138 | 4 | 64 | 是 |
| 2 | 是 | 210 | 8 | 128 | 否 |
| 4 | 是 | 210 | 8 | 128 | 否 |

[calibration.json](calibration.json) 来自 [probe-theme-design.gd](../../../scripts/probe-theme-design.gd)，覆盖24个第二章组合及20个第三/四章参考案例；每个组合/案例重复运行的canonical signature一致。所有模拟结果正确；性能是否达标单独按目标解释，不把正确等同过关。该枚举仅覆盖列出的策略，不宣称任意DSL程序的全局最优。

## 自动验证

- [第一轮套件结果](baseline-suites.json)：import、隔离用户目录、9套相关检查全通过。包括 simulation、locality_chapter_ui、content_registry、localization、chapter_workspaces、prologue_simulation、system_lab_simulation、overlap_simulation、layout_simulation。
- [最终UI结果](final-ui-suites.json)：增加ScrollContainer后重新导入，locality_chapter_ui与localization均通过。
- locality UI新增真实按钮signal路径：选择2/4行，运行，验证结果正确但210周期/8miss；完成播放和请求finding都不授予完成或提前解锁Blocking术语；随后1行仍按原有复盘流程通过。
- 最终隔离副本默认Game入口 `--headless --quit-after 5` 启动退出0，无脚本错误，见 [smoke.txt](smoke.txt)。
- 这类控制器/信号测试不是物理鼠标操作；原测试中使用的fixture进度不是Game通关证据。
- 原始全日志留在 `.godot/verification/20261002T112024Z-2b960487/` 与 `.godot/verification/20261002T112121Z-2b9b3c1e/`。检查了完整套件日志，不只看进程退出码。

第一轮沙箱导入因无法创建独立Application Support数据目录失败（`20261002T111942Z-9424d6c9`）；获工具授权后重跑上述隔离验证通过。不是产品脚本失败。

## 渲染检查

[capture.gd](capture.gd) 只用于隔离Test模式，检查工作组最后一项滚入窗口后可选择，保存中英文Mission和选项。使用仓库已有 `--capture-size=1280x720` 模式，绕开Mac默认全屏与Retina最小尺寸策略。早期未指定capture模式的尺寸不一致，不作为小窗口通过证据；最终日志见 [capture.txt](capture.txt)。

图像：[中文选项](zh_CN-groups.png)、[英文选项](en-groups.png)、[中文Mission](zh_CN-mission.png)、[英文Mission](en-mission.png)。这是Godot真实渲染与控制器检查，非原生鼠标/真人体验证明。Mission原有滚动和页间导航保留。

## 兼容性影响与发布门槛

`LocalityChapter.workspace_version()` 的文件指纹包括整个关卡目录；所以仅改变可选组大小也会让以前第二章配置和观察记录过期。现有机制保留draft source；再次保存保留previous_version；旧观察不能重放为新证据。已有完成标记不因这项指纹直接清空，已通关capstone仍可编辑。`test_chapter_workspaces`验证了这些版本保护边界，但本轮未用真实历史玩家档做升级/重启验收。

因此这是供评审和试玩的本地试点。发布前应单列“内容选项变化兼容性”工作包：在复制的旧档上验证配置恢复、草稿、历史基线和进度；决定是否需要精确的兼容迁移。不能直接删除catalog指纹或信任旧metrics来消除提示。本轮不修改这一存档机制。

## 复现

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --suite test_simulation --suite test_locality_chapter_ui --suite test_content_registry --suite test_localization --suite test_chapter_workspaces --suite test_prologue_simulation --suite test_system_lab_simulation --suite test_overlap_simulation --suite test_layout_simulation
```

使用脚本打印的隔离项目路径替换下方 `<isolated-project>`；不要换成实际玩家项目路径。

```sh
godot --headless --path <isolated-project> --script res://scripts/probe-theme-design.gd
godot --path <isolated-project> --windowed --resolution 1280x720 --script res://docs/verification/20261002-theme-design/capture.gd -- --capture-size=1280x720
```

尚未完成：本轮40关原生通关、双语正常Game端到端、真人新手理解/趣味、实际音频试听、旧玩家档升级、Windows实机及新导出包。声音和其他重点节点仅完成设计规格，不宣称已经实现。
