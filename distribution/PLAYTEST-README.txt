冯·诺依曼瓶颈 — 电路视觉与学习引导试玩版
构建：polish-20260907T010358-76ef116

解压后双击 Von-Neumann-Bottleneck.exe，无需安装 Godot。
默认进入章节选择，点击“硬件基础”开始原序章；已有进度可以继续。
路线：接线教程 → 算术/存储两条分支 → CPU → LOAD/STORE → 第 1 章 → 第 2 章。
“八关对照版本”保留独立进度，不会替代或解锁原构建路线。

元件主体可选中、拖动；从端口、已有线段或接点拉线可以分支。
模块名、方向箭头和位宽标在元件上；较粗的线表示多位总线。悬停线路可查看同一网络。
交叉不自动连接，分支有接点。右键精确擦除；Ctrl+Z 撤销，Ctrl+Y 重做。
支持框选、Shift 多选、Ctrl+C/V。测试端子不能复制，Delete 保留它们；右键擦除可以撤销。
滚轮缩放，中键拖动平移。可移动、收起或关闭各工具窗，底部入口可找回。
Home 或“聚焦”放大选中元件；未选中时显示全部。Shift+Home 始终显示整张电路。
上方短目标可以展开任务说明。任务有规格和 Previous/Next，不默认显示解法。
任务页签可直接查看真值表、指令表、模块和分段检查；“开始搭建”随时回到画布。
半加器测试台可点击 00/01/10/11 选输入，再运行当前输入。完整测试的要求保持不变。
Hint 打开独立只读画布。H2、H3 各需再次请求和确认，H3 明确警告完整参考答案。
返回提示前的方案会保留名称、拓扑、位置和线色；撤销/重做与剪贴板按原规则清空。
运行当前输入与完整测试保持分开；播放频率 Hz 只改变演示速度。
通过后自行选择封装或继续，不会自动跳关。右上角按钮切换全屏。
通关页显示下一项能力；本关反馈默认折叠，需要时再展开填写。

本版采用统一的深色仪表界面、青色重点和清晰的中英文字体。
测试输入用空心符号 0 / 实心符号 1 切换；颜色只作为辅助，低电平不是错误。
元件卡使用与画布相同的原理图符号，名称与位宽在右侧对齐。
手册初始开放 20 条基础知识，随原有关卡进度逐步开放全部 89 条。
当前任务需要的规格可以直接查阅；“查看后续知识”只显示尚未开放的标题与条件。
电平、二进制、分支/交叉、半加器和存储行为增加了图示与例子。

本版本使用 savegame_v1.json 和 hardware_workbenches_v1.json。八关版已移除；旧 demo_progress_v1.json 留在原处，不读取、不转换、不删除。
不要用“新游戏”或清档准备对照试玩。游戏只记录本地匿名事件，不上传数据。
已通过中英文各 461 项 Godot GUI 输入检查、20 套常规回归，并检查导出 EXE 画面。
Windows 锁屏阻止了本版完整的原生桌面试玩；此包为候选试玩版，不是已验收的正式发布版。
物理鼠标手感、High DPI、新手理解和节奏仍待真人试玩。
建议先玩教程和半加器，仅查看任务、检查器、H1/H2；再评估 CPU 的模块说明与反馈。

Von Neumann Bottleneck — Circuit visuals and learning guide
Build: polish-20260907T010358-76ef116

Extract and run Von-Neumann-Bottleneck.exe. No Godot installation is required.
The default chapter hub opens Hardware Foundations, both construction branches, CPU,
LOAD/STORE, Chapter 1 and Chapter 2. The eight-task comparison keeps separate progress.
Move/select components, branch existing wires, erase precisely, undo/redo and copy/paste.
Module names, direction arrows and bit widths are visible; wider strokes identify buses.
Hover a wire to inspect its network. Home focuses selection; Shift+Home shows the whole circuit.
Mission remains a floating window with specifications and a persistent reopenable goal.
Use section tabs for specifications or Start Building to return to the canvas at any point.
Half Adder input rows select 00/01/10/11 for debugging; full tests keep their original requirements.
Hints use a separate read-only canvas. H2 and H3 each require a request and confirmation.
Returning preserves the named design, topology, layout and colors; undo/redo and clipboard
are cleared under the original snapshot rule. Debug input, full tests and playback Hz remain distinct.
Completion previews the next capability; per-level feedback is available behind an optional button.
Compact outlined 0 / filled 1 symbols control test inputs. Color is a secondary cue.
The component catalogue aligns shared schematic symbols, names and bit widths.
The illustrated Handbook starts with 20 topics and opens all 89 through the original progression.
Current Mission specifications remain accessible; future topics show their availability condition.
Both save families are preserved. Do not clear player files for a comparison playtest.
Chinese and English GUI replays pass 461 checks each; all 20 conventional suites pass.
The exported EXE starts in Game and Test and its rendered original hub has been inspected.
Windows was locked during computer-use acceptance, so a full native desktop replay is pending.
This is a playtest candidate, not an accepted production release.
Physical mouse feel, high DPI, novice understanding and pacing still require human playtesting.

Noto Sans SC is bundled under SIL Open Font License 1.1; see OFL-NotoSansSC.txt.
Circuit art and illustrations are original code-drawn graphics. No Turing Complete assets are included.
