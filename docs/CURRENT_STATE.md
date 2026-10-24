## 2026-10-24 · Windows / macOS Alpha4 已公开

[v0.5.0-alpha.4](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.5.0-alpha.4) 已发布，固定游戏源码 `2c4a9d8bdf132bd20491f4ef2a2ba2f25d770e51`，包含两平台ZIP、SHA256SUMS与BUILD-INFO。完整60项旅程，默认Game、Test隔离，稳定CloudPlaytest渠道，不自动迁移旧试玩档。Windows实际导出EXE217项检查通过，普通GPU启动/终端/教程/正常退出已观察；macOS通用架构、资源、执行权限与哈希通过静态检查，Mac实机首启/存档/音画仍开放。已提交比赛包不变；后续main只更新发布记录与下载链接。[详细记录及初始核验脚本问题](verification/20261024-desktop-release/README.md)。

## 2026-10-24 · 双平台离线 Release 准备

用户授权将终端模式、试玩小修、Dot整合和赛后反馈改进提交并推送 main，并准备 Windows x86_64 与 macOS 通用直接游玩包，供用户上传 Release。使用同一固定提交、完整60项旅程、正常 Game 规则和稳定 CloudPlaytest 隔离渠道；无在线接收端。保留冻结比赛 ZIP。分发说明更新实验室入口、四段演出和平台边界，两包随附团队素材与 Natural Earth 来源声明。实际构建身份、哈希及平台验收随本地交付提供；Mac 原生首启/存档和声音仍需 Mac 实机确认。本轮不代替用户发布 GitHub Release。

## 2026-10-24 · 赛后调研即时改进

反馈页显示捕获版本/提交身份；无接收端时明确本地保存与导出路径并禁用发送，保留已配置端点的离线重试。地址预测英文补全完整运行才记录的条件；中英文下载入口明确10月17日固定版与当前开发源码的区别。没有新导出包或发布，比赛提交包保持冻结。四项相关检查最终通过，包含720p布局与GPU实机检查；[具体增量、未改项和边界](verification/20261024-postgame-research/README.md)。

# 最新状态 · 2026-10-24 Dot 成果整合与实机打磨

后期四工作台切换语言保留草稿、原始编辑文字、测量与已选事件；硬件写入失败时保留现场；已接线教程恢复后显示拆线重接指导；HalfAdder 重封装立即撤销失效的下游资格；RAM 路线可查 MUX；作品墙查看避免递归装饰并正确适配窗口。完整/部分候选包的 60/51/40 关配置与清单一致。

待封装结果明确显示「封装并继续」，半加器说明允许直接完整测试，F1 使用「打开分层提示」。创造开场指导可随语言更新，诊断信息保留；地图缩略标题不再重复编号，英文恢复标题完整显示。

24 套不同的相关回归分阶段通过，Windows 实际鼠标接线、保存/重启恢复、半加器正式测试与封装继续、创造语言切换和作品查看完成定向验证。详见[当前记录与实机画面](verification/20261024-dot-integration/README.md)。现有本地修复保留，比赛提交包哈希不变；源码未提交、推送或重新打包。完整新人通关、可听音画同步与跨设备验收未作声明。

---

# 历史状态 · 2026-10-23 地球仪发光与干净提交包

首关正式完成后，原地球仪本体更明亮，并显示柔和青绿色光晕；未完成时不显示，原地图纹理、模型、位置、完成条件及档案行为保留。本轮仅调整地球仪显示，以及测试模式的首关返回按钮文案；测试模式仅提示返回实验室，游戏模式保留查看发光地球仪的提示。

10套相关源码回归、6套返回文案补充验证与最终EXE169项相关检查通过；已核对真实导出画面的完成前后差异。新包沿用已确认的三份PDF，`THIRD-PARTY-NOTICES.txt` 与用户提供的文件逐字节一致。交付目录 `E:/VNB/deliveries/干净提交材料`；源码、可修改原件及核验记录单独保留，提交ZIP仅含运行包、必需许可证和三份PDF。未提交或推送。

---

# 历史状态 · 2026-10-23 三项试玩修复

普通测试模式可从旅程地图和服务工作台直接进入第六章 6-2、6-3，临时探索不写入游戏候选档；游戏前置与独立离线测试档的保存合同保留。首关正式完成后，实验室原地球仪点亮并保留纹理，返回入口、房间提示和第一束光档案对应这一成果；终端重排不清除新档案标记。全部引导步骤完成后仍可重播原操作演示，不改电路、判定或存档格式。

15 套相关回归已有通过记录，最终三项修复 GPU 17 项通过；实际导出 EXE 的三项修复 17、终端模式 97、模式访问 14、导航 39 项通过。当前更改仍为本地未提交修改；v3 提交包和证据保留在 `E:/VNB/deliveries/游戏提交材料-20261023-v3-试玩修复`。没有实体键鼠、新人、跨设备或可听音画同步验收。

---

# 历史状态 · 2026-10-23 终端模式选择

唤醒实验室终端后，“开始 / 继续”右侧直接显示游戏／测试模式选择和双语说明。游戏模式沿正常前置保留成果，测试模式提供隔离的临时元件与入口；当前选择同步原模式系统，切换不授予成果。房间、启动 CG、主按钮尺寸与底部导航保留，对话期间隐藏模式控件。

8 套相关无头回归通过；终端模式 97 项 GPU 自动检查通过，已检查中英文与 1280×720、1600×900、1280×800 实际画面。实际导出 EXE 另通过终端视口点击 97、模式 14、导航 39、四 CG 50 项检查。提交材料 v2 的运行说明已更新，导出与归档身份见本地交付记录。源码更新保留为本地未提交修改；未作实体键鼠、跨设备或可听音画同步验收。

---

# 历史状态 · 2026-10-23 手册、开场与结尾收尾

游戏内手册116条，新增19张双语图示和操作／功能速查；后期四工作台提供本关手册入口，关闭阅读保留草稿。开场以三步解释操作，保留叙事、NOT目标、跳过和返回。第十章最后一关成功保存作品后播放结尾CG，复用观看记录、跳过和暂停恢复。

17套相关无头测试最终通过；手册1604项、配图992项，真实GPU入口136项、开场278项、结尾保存与播放28项通过。38张实际截图与素材哈希见[本轮验收](verification/20261023-finale-handbook/README.md)。此前设置、反馈、空间、流程及第五章CG收尾保留。用户授权提交并推送main；未打新包，video未访问或修改，真人新手与可听音画同步仍待验收。

---

# 历史状态 · 2026-10-23 设置与反馈排版（工作区候选，未提交）

设置采用三类图标导航、分区卡片和固定底栏；普通反馈分开任务背景与填写操作，离线反馈并排显示真实截图、历史与备注。中英文、浅色实验室与深色浮层的标签、音量滑轨和主按钮保持可读，底部保存说明及状态在页面内。设置、草稿、分享同意、保存保护及导出行为保持。

17 套相关回归通过，最终布局无头140项、皮肤恢复96项、GPU160项通过，并检查20张实际截图。两项图形检查曾无诊断退出，单独复跑通过，原因未定位。见[设置与反馈验收](verification/20261023-settings-feedback/README.md)。本轮没有完整真人试玩、提交、推送或打包；`video` 未访问或修改，手册仍等用户材料。

---

# 历史状态 · 2026-10-23 操作流程与未提交内容保护（工作区候选，未提交）

修复设置退出绕过表示／服务／预测／创造工作台离开保护的问题；序章及第一、三、四章的设置层阻挡底层编辑快捷键、平移和卡片拖动，关闭后正常恢复。创造工作台离开前保护非法起始文字，取消保留文字并恢复焦点；中英文提示框采用紧凑换行布局。

已运行开工快照的 226 套全量测试；最终改动相关 38 套无头回归及 3 套 GPU 自动交互均有通过记录。4 项曾出现无诊断进程退出，停止并行后逐项重跑通过，原因未定位；原记录保留。最终文字保护无头 270 项、GPU 338 项，设置退出 105 项、跨章节输入 26 项通过。见[操作流程验收](verification/20261023-player-flow/README.md)。

保留既有 Claude 打磨、实验室／文字效果和第五章 CG；除 6 个运行脚本外，547 个运行文件、资源、本地化文件及工程设置与本轮开工快照一致。未提交、推送或打包，未访问或修改 `E:/VNB/video`。自动化与截图不等于真人完整通关；手册仍等待用户补充材料。

---

# 历史状态 · 2026-10-23 空间／文字收尾与第五章 CG（工作区候选，未提交）

实验室窄屏保持横向构图，档案架和旅程板完整可见；作品墙长名称按字体宽度省略而不修改原记录；壹的逐字文字增加轻微标点停顿，保留即时跳过、重读和减少动态效果。15 套相关回归及四种比例 GPU 截图通过核对，见[空间与文字收尾](verification/20261023-codex-closeout/README.md)。

用户新增影片接在第五章五份正式方案全部达标之后，复用已有 CG 播放、观看记录、跳过及音量规则；播放结束保留原结果和保存流程。12 套相关测试通过，三段影片完整自然解码通过，普通 GPU 模式实际触发／跳过／返回结果 35 项通过。影片源文件和前两段资产不变，见[第五章 CG 验证](verification/20261023-chapter5-cinematic/README.md)。

保留 Claude 已交接的全部修改，未提交、未推送、未打包。`E:/VNB/video` 为用户宣传片工作区，未访问或修改。手册等待用户补充材料；可听音画同步、原生输入和最终导出包仍待验收。

---

# 历史状态 · 2026-10-23 Claude 最终整体打磨（工作区候选，未提交）

在 `f830bcf` 上按[Claude 交接](development/CLAUDE_HANDOFF_20261023.md)与开发方向规划手册做最后一轮 UI 打磨。经用户授权，用短时开窗自动截图逐屏核对 23 个代表画面（实验室、终端、地图、序章到第十章）后修改：后期工作台壹的提示条不再遮挡第二行导航；旅程地图定位不再留半屏空白；第二章任务翻页固定在底部、节点读数不截断、英文顶栏不越界（既有失败）；序章底栏状态完整显示；地图／实验室入口统一叫法；实验室光照转暖以承接开场 CG，作品墙空状态显示未点亮光纹格；表示／服务／预测工作台正文不小于 13px。不改仿真、判定、任务 ID、端口、存档与作品合同。

之后按用户反馈再做两轮：房间里的终端玻璃直接显示下一项与进度；点开后的终端改为壹的话＋一张任务卡＋底部文字入口；设置、档案架收成居中阅读列；侧边旅程黑板与作品墙重排、突出当前章节；房间物件悬停改为角标框＋暖光；电路选中加光晕；修正地图首次 Esc 被悬停提示吞掉的既有问题。电平 0/1 按用户要求保留原表示。最终代码全量回归 227/227 通过；随后修正英文第十章标题截断，相关 44 套复跑通过。**接续入口：[Claude 最终打磨交接](development/CLAUDE_FINAL_POLISH_HANDOFF_20261023.md)**；前后对照截图与测试记录见[最终打磨验证](verification/20261023-claude-final-polish/README.md)。原生键鼠试玩、音画同步与导出包仍待人工验收；未提交、未打包。

---

# 最新状态 · 2026-10-23 收尾与 Claude 继续优化

收尾修复第四章悬停提示吞掉首次 Esc、自动保存失败与 CG 的暂停冲突，以及救援另存窗口的独占关系。28 套相关 Godot 测试与两项隔离检查的最新结果全部通过；导航 39 项、语言 65 项、CG／恢复 37 项通过。新增[Claude 正式交接](development/CLAUDE_HANDOFF_20261023.md)，说明当前 60 项游戏内容、已完成改动、代码入口和后续 UI／内容方向；[收尾证据与交付身份](verification/20261023-final-audit/README.md)。

保持无窗口检查；不宣称全量回归、全关人工通关或原生音画验收。此前已获授权的 main 同步与 Windows 分享包以收尾交付记录为准。以下各段是历史快照，原来的「未提交」「未打包」不代表当前交付状态。

最新分享包源码 `1479c45`，ZIP 位于 `E:/VNB/deliveries/20261023-FinalAudit/`（115,818,327 字节）。实际 release EXE 的模式 14 项、CG／恢复 37 项、导航 39 项通过；稳定存档渠道仍为 `ModeDebug20261023`。后续仅提交交付文档。用户下一步由 Claude 按最新交接继续 UI 与整体内容优化。

---

# 最新状态 · 2026-10-23 正常版本模式选择与分享调试

正常版本及导出包默认游戏模式，实验室「设置 → 模式」可自由切换游戏／测试；硬件和第一／二章顶部保留支持的即时切换。其他工作台经原保存／离开流程返回实验室后切换，避免草稿跨命名空间。测试临时元件、进度和正常玩家成果继续隔离；未开放额外开发捕获权限。

用户已明确授权整合此前元件、实验室及 CG 改动并推送 main、制作 Windows 分享 ZIP。相关无窗口回归、模式往返及玩家签名隔离通过，主页可见控件合同按当前要求更新后 7399 项通过；见[模式与调试包验证](verification/20261023-mode-debug/README.md)。打包使用固定提交、独立稳定 `ModeDebug20261023` 渠道及完整 60 项旅程，不捆绑 QA 存档，不发布公开 Release。实际交付身份以该记录及随包 manifest 为准。

运行代码提交 `597813e` 已生成 Windows ZIP（115,817,064 字节）；真实导出 EXE 的模式隔离 14 项及 CG 32 项通过，全部包清单／哈希通过。交付目录 `E:/VNB/deliveries/20261023-ModeDebug/`；后续提交仅保存交付证据，不改变游戏代码。仍未开游戏窗口，原生音画与操作体验留待分享调试。

---

# 最新状态 · 2026-10-23 双 CG 接入（工作区候选）

首次启动入口增加开场 CG；仅无历史玩家记录的新档展示，结束或跳过直接进入实验室。正式首次通过序章最终 LOAD/STORE 后展示第二段 CG，再接原通关结果。观看记录为独立 `user://cinematics.cfg`，重新开始游戏不重播；旧档、测试、自动截图和无窗口会话不补播。两段保留原尺寸、帧率与音轨，原 MP4 不修改；Esc／跳过、暂停恢复、窗口关闭保存失败和全局反馈快捷键均纳入检查。

实现、媒体哈希与验收范围见[CG 验证](verification/20261023-cinematics/README.md)。按用户要求未打开游戏窗口；原生画面、音量与音画同步待人工验收。未提交、推送或发布。

---

# 最新状态 · 2026-10-22 用户参考形状接入（工作区候选）

以用户确认的 `01_all_components.png` 为视觉目标：MUX／译码器相反梯形、ALU 八点凹口、切角模块、存储侧轨、中央短名称及单个功能符号；基础输入／输出、灯、常量和节点保留各自语义形状。CPU／RAM／Bus 分别显示结构分区、网格、横向通路。全部 26 类对象继续使用现有绘制；元件台／预览／画布共用完整节点，真实端口、位宽、模拟、来源绑定冻结记录和存档签名保留。

11 套相关无窗口测试及两项隔离检查 13/13 通过；参考几何 1228 项、基础符号 32 项、一致性 508 项通过。仍未打开游戏窗口；参考图不是当前截图，实际视觉／原生操作验收待做。见[参考目标、规则和证据](verification/20261022-component-reference-shapes/README.md)。未提交、推送或发布。

---

# 最新状态 · 2026-10-22 元件台与落地一致性修正（工作区候选）

全部 23 类逻辑对象的元件台和放置预览统一使用完整画布节点，不再使用改变比例与端口排布的模块缩略图。卡片按宽度等比缩放并保留完整高度；常量显示配置值，预览占位校准到实际 GraphNode 尺寸，路由节点保留紧凑边距。端口、模拟、存档签名和已有冻结记录保留。

新增一致性检查 508 项通过，覆盖实际布局后的 GraphEdit 节点、常量位宽／数值和两种冻结形状；9 套相关测试及两项隔离检查 11/11 通过。仍依要求未打开游戏窗口，当前版本画面与原生操作验收待做；未重新宣称全量回归通过。见[验证与源码身份](verification/20261022-palette-canvas-parity/README.md)。未提交、推送或发布。

---

# 最新状态 · 2026-10-22 实验室与放置优化（工作区候选）

退出确认复用原控件显示在房间终端玻璃上，支持真实屏幕拾取、默认取消焦点、Esc 取消及返回原入口；房间环境光调为中性暖色。修复页面关闭后遗留的 resize 回调，减少元件放置预览重绘和拖放落地的重复构造，保留关闭吸附时的小数落点。

依用户最新要求未打开游戏窗口。9 套无窗口测试及两项隔离检查 11/11 通过；原实验室 freed lambda 错误消失。较早扩大检查的两项既有跨场景失败保留，未宣称全量通过。画面、手感和 GPU 前后对照待实际验收。见[结果与边界](verification/20261022-lab-placement-polish/README.md)。所有改动仍未提交、推送或发布。

---

# 最新状态 · 2026-10-22 元件重构（工作区候选）

23 类逻辑元件与 CPU／RAM／Bus 复用共享绘制；模块标题连入主体，元件栏用真实接口的完整模块缩略图，正式封装页使用同一模块视图。成功封装按实际内部占位冻结 V2 外形，外部测试端子不参与；旧 V1 bands 原样读取，缺失或不符来源安全回退。端口、模型、验证、依赖、签名与正常玩家存档边界保留。

最终相关 9 套测试及两项隔离检查通过（11/11）。真实 Windows GPU 前后各 223 项检查、20 张 1280×720 图、零失败；两种正式封装均经独立 GlobalSave 重载，前后系统轨迹摘要和指标一致。全量 219 阶段为 216 通过、3 个实验室测试失败：两套基线亦失败；语言连续性在基线及最终源码单独重跑通过。详细失败点、源码哈希和正常玩家／QA 边界见[验证与真实前后对照](verification/20261022-component-refactor/README.md)。未提交 Git、推送、发布或导出新包；原生键鼠与新人视觉验收待做。

---

# 最新状态 · 2026-10-22 实验室过场与元件台（Claude，未提交）

在 main `9408519` 上工作区改动：实验室物件统一为“镜头转向并推近 → 页面 → 关闭后从同一物件拉回房间”；终端进入的关卡回来时从终端出来，旅程板进入的地图回来时从旅程板拉回；元件台卡片直接显示画布放置的同一元件视图；实验室、关卡状态栏、旅程地图与各功能页去掉多余副标签。见[交接](development/LAB_TRANSITIONS_HANDOFF_20261022.md)与[验证](verification/20261022-lab-transitions/README.md)。

---

## 2026-10-22 Windows 整合

代码基线 `bfb2ce4` 已推送并核对远端 main。用户接下来让 Claude 接手美术设计等优化；见[当前接手说明](development/CLAUDE_ART_HANDOFF_20261022.md)。Codex 已释放开发所有权。

恢复包 `fddfefc` 的元件视觉、操作演示和旅程关系，与本地停靠引导条、规格表及窗口设计已整合；布局采用本地 Claude 方案。演示指针为深色圆角箭头、柔白描边及淡蓝光晕，保持与玩家指针区分；展开演示不改变引导条高度。首关须接齐两条线才推进，引导端点跟随真实端口。

Windows 全量 215 套 Godot 测试及两项隔离检查已执行；两套旧接线夹具更新后相关五套复测通过。最后指针绘制变更的三套复测通过。中英文 GPU 回放各 112 项通过，最终指针中文回放亦为 112 项通过；14 项 Python 检查经本地回环复跑后通过。原生试玩范围及中断、逐轮日志、源码哈希见[Windows 整合验证](verification/20261022-windows-integration/README.md)。未导出新安装包。

以下为历史状态，以各段日期和范围为准。

---

# 最新状态 · 2026-10-22 上午迭代候选

基于 `a5965e3`，在 `codex/component-visual-v2-20261022` 独立开发。
上午功能提交 `f40bf89` 修复实际鼠标/键盘试玩发现的 F6 教学推进不一致、
关闭面板后演示无恢复提示；既有虚拟操作演示、分散式序章引导、
封装布局视觉记录和关卡树关系优化保留。

10:20 北京时间，全量 214 个 Godot 测试套件、导入与用户目录检查全部通过
（216/216 阶段），9 项 Python 检查通过。从同一通过快照重新导出 Windows
候选程序；导出不是 Windows 实机验收。真实 Linux 试玩已覆盖首关、半加器、
全加器、SR 锁存器、一位寄存器，以及新导出包内 ALU32用例、RAM5步、CPU7步
正式验证和封装；地图与终端显示8/60。这不是全60项任务通关。

GitHub 上传取消后的重新授权仍待收到，本地提交不能当作远端 main 更新。
详见 [迭代与试玩报告](development/GAME_ITERATION_REPORT_20261022.md)
及 [验证范围与证据](verification/20261022-overnight/README.md)。

以下为历史状态，以各段日期和范围为准。

---

# 最新状态 · 2026-10-21 关卡引导收敛

按《关卡界面与引导收敛方案》第 1、2 轮：关卡里同一时间只有一个引导声音。硬件序章的步骤卡改为画布上方停靠的引导条，求助在条内替换当前一步，完整说明是阅读层；半加器引导读取真实电路与运行结果，写出首个不符项并指向测试台对应行，不点名门电路。开场气泡不再重复已展开的任务卡，也不再盖住底部运行与回放按钮，设置、手册、结算等阻断层打开时直接离场。工作台顶栏改为单行轻量导航，第二章「现在」一行随未应用草稿与正式结果变化，机器图按真实尺寸取景。

随后重设计了工作台窗口：所有章节共用一个窗体（细边框、柔和投影、自绘窗口按钮、角落缩放、激活窗口提亮），工具行改为无框按钮、导航改为描边按钮、主操作保持实心，普通容器去掉投影。见[窗口重设计](verification/20261021-window-redesign/README.md)。

仿真、判定、任务 ID、存档与作品合同不变；未提交、未推送、未导出新包。表示／服务／创造的高密度界面、低频导航归入菜单和真人试玩仍待下一轮。详见[交接](development/GUIDE_CONVERGENCE_HANDOFF_20261021.md)与[验证](verification/20261021-guide-convergence/README.md)。

---

# 2026-10-21 关卡卡片精简

关卡提示去掉「壹 / Yi」署名，60 项卡片完成复读，章节展开说明更短；实验室人物及未确认故事边界保持原状。此前体验修正、测试与证据和本轮卡片优化一并纳入本地 main，无远端推送或公开发布。

本轮 11 个相关测试套件全部通过，GPU 叙事与求助输入检查通过，18 张关键画面见[卡片精简验证](verification/20261021-card-polish/README.md)。前轮全量及修复验证仍按下文的各自范围保留；不将自动检查视作真人理解或新安装包验收。

---

## 最新：叙事与玩家体验核验（2026-10-21）

60关文案与映射已审计，代表操作、真实反馈、可选章节回应和作品保存衔接已补查。
全量201个Godot套件发现并修复NOT反馈遗漏和延迟滚动问题，最终11项相关复测及两项隔离检查、七项Python检查通过。
三轮提交为7542b72、c70f900、f65b28c；后续补查保留为未提交工作树。未更新游戏包，未合并远端main或公开发布。
故事候选仍待主创确认；验证边界、关键画面和源码身份见[综合核验](verification/20261021-narrative-integrated/README.md)，视觉精修见[叙事交接](development/NARRATIVE_HANDOFF_20261021.md)。

以下历史记录保持原文。

---

# Current state — hint input correction (2026-10-21)

当前分支修复序章「提示」被浮动面板遮挡、F1 在搜索框或只读提示页失效的问题。
按钮与 F1 使用同一入口，后两层仍需确认；设置等模态界面阻止底层求助。
窗口 F11 首次退出与连续切换暂未复现异常，未修改窗口恢复逻辑。
本轮为源码修复，原 Windows ZIP 未更新；范围与验证见[提示输入检查](verification/20261021-hint-input/README.md)。

## Previous: terminal navigation and presentation closeout (2026-10-20)

当前开发分支为 `codex/navigation-closeout-20261020`，基于 Claude 第四轮终端优化。
导航修复 `e965632` 让实验室电脑显示的目标与实际入口一致，并补齐工作台 Esc；
本轮表现收尾让开场提示在玩家操作后及时收起，补齐实验室和提示卡对「减少动效」的响应。
验证与范围见[导航修复](verification/20261020-navigation-shortcuts/README.md)和
[表现收尾](verification/20261020-conservative-polish/README.md)。本轮没有合并主线或发布游戏包。

下方保留此前各轮的历史记录。第四轮已统一 8-1…10-3 命名，并按主创决定取消
「壹的痕迹最多三处」旧约束，详见[第四轮交接](development/TERMINAL_POLISH_HANDOFF_20261020.md)。

## Previous round 3 — unified style and story beats

第三轮：九个工作台统一标题栏框、章节/关卡命名（第五至七章、5-1…）、设置与「退出游戏」、终端信号场背景；
第一章起每关开头有壹的一句开场卡；第二、三、四章结尾在实验室终端上播放一段带选项的对话，结尾留下悬疑钩子
（候选文案仍待叙事审校；与旧「最多三处痕迹」约束的冲突已按第四轮主创决定解除）。
详见 [第三轮交接](development/UNIFIED_STYLE_HANDOFF_20261020.md) · [截图与验证](verification/20261020-unified-style/README.md)。

## Round 2 — art pass and two worlds (2026-10-20, uncommitted)

第二轮：实验室是最终页面，点「退出游戏」或按 Esc 都在终端屏幕上确认退出；
实验室（暖色日光、实体陈设）与终端内（冷色自发光信号场）在配色、光照和进出过渡上明确分开；
新增终端旁状态小屏、玻璃记录板与元件托盘（只显示真实进度）；设置面板分组重构。
详见 [第二轮交接](development/ART_TWO_WORLDS_HANDOFF_20261020.md) · [截图与验证](verification/20261020-two-worlds/README.md)。

## Round 1 — Yi's text and UI convergence (2026-10-20, uncommitted)

本轮在 `c99d720` 上按队友《UI 与表现修改建议》和《壹的文字尾随光标规范 v0.3》渐进修改：
壹的话逐字输出并以 1/I 型 SVG 光标跟随句末（终端、NOT 步骤卡、完成卡、非模态求助小卡）；
旅程统一为「序章 → 第一章 …」与 `序章·名称 / 1-1 名称 / 1-4-1 名称`；全屏只在设置、
工作台不再常驻反馈按钮（F8、完成卡、设置保留）、退出按钮强调、常用快捷键标注。
仿真、判定、任务 ID、存档与作品合同不变；未导出新包，未做人工试玩。
详见 [交接](development/UI_YI_HANDOFF_20261020.md) · [截图与验证](verification/20261020-ui-yi/README.md)。

## Previous: team engineering closeout (2026-10-19)

本轮交付入口：[中文试玩与开发交接](development/team-handoff.md) ·
[工程验证与固定包身份](verification/20261019-team-closeout/README.md) ·
[历史分支核对](verification/20261019-team-closeout/branch-audit.md)。

主线保留 Claude 已完成的实验室旅程、第一/二章停靠工具布局、早期关卡步骤卡、
关卡语境文字与实验室画面调整。历史候选源码已核对；真正遗漏的两个本地 Claude
提交按原顺序纳入审阅。此次源码修复限定于空白提示、拖动/右键删除的提示框生命周期
及 Windows UTF-8 打包。完整 60 项测试入口与实际完成判定、作品和存档合同保持一致。

Windows 团队包从合入后的固定 main 提交归档构建，使用独立
`OfflineTeammate-Team20261019` 渠道；不迁移或清空旧档。具体 SHA、ZIP 哈希与
导出后检查记录保存在随包 `manifest.json` 和交付验收文件中。
本轮不创建公开 Release；上方历史公开下载仍是 10 月 17 日旧版。

## Laboratory checkpoint — 8a8b03c

`main` now carries the laboratory journey from `claude/lab-journey-20261019`
(on top of the full journey candidate, PRs #11–#15). Source F5 opens the full
60-task journey with the laboratory home, terminal entry, focused first lesson,
earned lamp/board/archive/city responses and the creation work wall. Classic
surfaces remain behind `--classic-hub`, `--classic-tutorial` and `--core-journey`.
Team handoff, screenshots, open tasks and verification:
[LAB_JOURNEY_HANDOFF_20261019](development/LAB_JOURNEY_HANDOFF_20261019.md).
The laboratory art is a code-drawn placeholder with replaceable PNG layers.
At this checkpoint no new Windows package had been exported; the team closeout
above supersedes that packaging status.

The sections below describe the previous journey candidate and remain accurate
for its own scope; the "40 tasks on F5" and "candidate creation" notes are superseded.

## Previous: journey Windows candidate

**Owner review correction (2026-10-18):** direct F5 from this checkout's root
`project.godot` still selects the original40 tasks because candidate settings are
not enabled there. The60-task exported ZIP checks below do not establish source
F5 parity or discoverability. The owner also rejects the current3D display as
meeting the laboratory requirement; it is a read-only results/navigation prototype.
Engineering verification remains valid within its scope, while these product
requirements remain unmet. See [Claude development handoff](development/CLAUDE_HANDOFF_20261018.md)
and the isolated source launch instructions in [README](../README.md#从源码运行).
The small source-entry correction is committed at `caf9e2b`; five focused headless
stages pass. A separately configured ordinary source-preview project is prepared
and its actual autoload enumerates60 tasks with no preset completion. This confirms
configuration and Home identity, not manual F5 or a satisfactory3D laboratory.
[Exact preview path and scoped results](verification/20261018-journey-final/source-entry-correction.json).


Product source is `5bd3792b022ec053f62eaeca9f53a791e201bcd9` on
`codex/journey-final-candidate-20261018`. PR10 is merged into `main` at `bf8f616`;
this candidate remains a separate unpublished branch. It includes the 60-task
journey, bilingual context, earned journal, optional 3D observatory, interactive
rules and original-work review. Chapter2 now presents the actual run's cycles,
official target and margin with a read-only fetch-event entry. FirstLight uses a
replaceable temporary fictional scene image while retaining actual NOT output,
skip and feedback. Simulation, progression and saved-work contracts are preserved.

Current source passes seven focused Windows stages and the 518-check Locality
renderer. The earlier 6c source passes 177 full Windows stages; FirstLight's 197
rendered checks and independently reviewed images carry forward through exact
unchanged subsystem bytes. Current 5bd Linux CI 39120037891 passes both the full
Godot verifier and all 11 Python commands. Original failures remain in the
[final evidence](verification/20261018-journey-final/README.md).

The normal ZIP passes identity and all-content checks, 219 actual release-EXE
controller checks and 48 strict-reopen checks. Protected state and 21 exported
image files have independent review. Its original PCK separately passes the
canonical headless check and 518 rendered checks in the pinned official editor,
with twelve independently reviewed new frames. The tester ZIP also passes identity checks, 229 actual release-EXE checks,
142 capture and 19 reopen collector checks, and 48 strict-reopen checks. Its final
feedback ZIP contains four cases, four revisions and two sessions; independent
protected-state and image review both pass within their recorded scope.

The ordinary and tester builds use `CreationLinks20261018` and
`OfflineTeammate-CreationLinks20261018` respectively. Fully extract either ZIP and
run `Windows/Von-Neumann-Bottleneck.exe`; no separate Godot installation is needed.
Both are fixed to product 5bd; later documentation commits do not rebuild them.

| Role | Frozen candidate directory | ZIP SHA256 |
|---|---|---|
| Ordinary progression | `build/playtest-JourneyFinalExperience20261018-5bd3792b022e` | `bdd8c98dcaed288ab5adea47edba300a9481252a15a27b4da28b5cde1cb232be` |
| All-entrance tester | `build/playtest-JourneyFinalAccess20261018-5bd3792b022e` | `19bc44a43f580b96dec52f434f227277d8cf068329d450a79588671c78e83923` |

The engineering round is closed under the user's final convergence request.
The previous [c84 pair](verification/20261018-latch-rule-example/README.md) remains
an independently accepted recovery build.

[Current packages and change evidence](verification/20261018-journey-final/README.md) ·
[Next-day playtest and handoff](development/night-handoff-20261018.md) ·
[Coverage ledger](development/full-journey-coverage.md).

Source/controller, raw exported PCK in the editor, actual release-EXE controller,
native OS input and human acceptance have separate scopes. Native tooling remains
unavailable; Mac, newcomer understanding and final art/narrative choices are open.
Video is NOT_RECORDED; original screenshots and precise operation scripts are
available for the team's presentation. The older bb5 exported Efficiency positive
control remains an open observation; it does not create a new feature round.

[简体中文介绍](../README.md) · [English introduction](../README.en.md) · [更新说明 / Changelog](../CHANGELOG.md)

## Historical delivery records

The dated records below retain their original package identities, failures and
then-current plan status. Current engineering scope and external observations
are defined above and in the final handoff.

## Previous bb5 delivery and its open observations

The verified delivery checkpoint42401a3 is on `codex/narrative-modal-focus-20261018`.
Direct exported modal verification continues on `codex/exported-modal-validation-20261018`.
Its first ordinary attempt atd6bf9c5 exits1 on an English-fragment precondition.
Chinese modal/F8 observations are recorded, but no final raw result or complete
check count exists. The cause remains unknown and the tester supplement is unrun. The sixty-task
semantic review is complete at20c9515; it records source contracts, not sixty
fresh solutions or newcomer acceptance. Baseline867ec81 reproduces an efficiency
animation advancing while a focused embedded modal is open:239 checks, four
assertion errors and a natural exit1. Its Escape assertion is compound; its
unchanged scroll values do not establish a scroll defect. The bounded repair at
bb5c817 adds window ownership to efficiency animation, delayed reveal and the
Host's fragment Escape branch. Independent source review and three fixed-source
compile stages pass. Its actual renderer also passes245 checks with natural
exit0: real scroll-positive controls and same-origin modal-negative controls
pass in both languages, and direct Host Escape preserves the visible fragment,
authority and closed map. Complete Windows regression passes all176 stages with
natural exits and zero errors; six original anchor warnings remain recorded.
Remote CI39097738231 succeeds. Both new package builds and identities pass.
The current ordinary exported run passes219 controller and48 strict-reopen
checks with natural exits; its21 image files have independent review. Synchronous
wait telemetry records the actual focus, pause and rendering conditions. This
does not explain the first216/219 failure or the separate180-second timeout;
both retain their original evidence and unknown causes. The tester passes229
controller checks, its bundled collector's142 capture and19 reopen checks, and48
strict-reopen checks. Its45 image copies represent31 unique hashes and have
independent image review. A mixed-encoding stdout read failed in the outer
recorder after the tester parent and child succeeded; that original exit1 is
retained. Only the remaining original strict reopen was continued separately.
The [round evidence](verification/20261018-narrative-modal-focus/README.md)
contains the current dual Windows ZIPs, manifests, failed observations and five
next-day questions. Product source isbb5c817; external QA isea6be8d. Unzip the
ordinary Experience package and run `Windows/Von-Neumann-Bottleneck.exe` without
installing Godot; use Access for tester access. The verified d14 packages below
remain the recovery delivery. Native input, Mac, newcomer understanding and
formal creative choices remain open; the full development goal remains active.

## Creation-connections engineering candidate

The round starts from pushed4e643eb on `codex/creation-connections-20261018`.
Its [completed engineering plan](exec-plans/completed/creation-connections-20261018.md) adds optional
reflection using actual C→P→G evidence and saved-work identity, without changing
save formats or simulation behavior. Existing local feedback entrances now
suppress the duplicate tester footer while F8 and the no-local-entry fallback
remain available. Fixedd14be32 passes all17 focused Windows stages with natural
exits and zero errors or warnings. The same review entry uses the playback row when
collapsed and the visible evidence header when expanded; returning to the signal
folds the review and preserves its entry focus. Original Status, Signal, Verify,
playback controls and saved-work regressions pass. All three actual renderer
suites now pass with natural exits and zero errors or warnings;112 original PNGs
have separate independent image review with explicit scroll and clipping limits.
Six unchanged representative frames have source and hash manifests. The fragment checks focused embedded
windows before handling Escape or delayed reading scroll. Complete Windows
regression passes all176 stages with natural exits and no errors; six non-failing
anchor warnings are retained in the evidence. Its remote CI also succeeds.
Both new Windows packages are built from productd14be32 and independently match
their manifests and complete ZIP payloads. The ordinary package passes219 actual
controller checks and48 independent-reopen checks; its21 new exported frames have
independent review. The tester package passes229 controller checks and48 strict
reopen checks, including its original sixty-entrance, C/P/G, work-restart and
final-only feedback-ZIP import chain. Both exported chains have independent data
review. The tester's45 PNG files, including imported copies, also have independent
image review. Native input is not verified: the official tool failed to initialize
twice before any window observation or input. Only the owned ordinary QA process
was stopped; the tester was not launched natively.
The separately reviewed external package
controller adds only the two explicit CreationLinks profiles and a real Host
C/P/G/Keep route; its ordinary exported execution is verified within the stated
seeded QA scope. The
[source-bound evidence](verification/20261018-creation-connections/README.md)
preserves earlier failures and exact acceptance limits, with the current ordinary
and tester ZIPs and five next-day review questions. The measured-growth ZIPs below
remain separately verified recovery packages.

## Measured-growth candidate — 2026-10-18

The measured-growth stage continues from the pushed handoff2e488c3 on
`codex/measured-growth-20261018`. Its [versioned plan](exec-plans/completed/measured-growth-20261018.md)
adds actionable Layout/Overlap evidence, an optional CPU-comparison reflection
and distinct hardware/system observatory apparatus. Fixed sourcee3e475d passes all20 focused stages, including actual edit invalidation,
restored apparatus geometry and protected original works. Source69b785a passes20 focused stages and all three renderer suites
technically. Efficiency and target-evidence frames are independently accepted;
the apparatus now passes3319 focused checks and3613 rendered checks at source2c56fd4
through the actual Home entrance, including task-tree location and return. Its
fifty original images pass independent per-image review; the720p sidebar keeps
long source explanations in its original scroll area. The earlier incorrect QA-host
images and script-error receipt remain recorded. Fixed97516b passes all175 complete Windows regression stages with natural
process exits and no errors. The ordinary97516b package passes128 baseline checks and47 strict-reopen checks.
Its first F4 supplement failed on QA startup contracts; that failure is preserved.
The tester97516b package passes138 baseline checks and47 strict-reopen checks,
including sixty actual entries, real C→P→G, saved-work restart and the original
collector's final-only four-case/two-session ZIP import and deduplication.
Both roles also pass actual Windows Home→Observatory→near view→F8→Esc→Home
and normal exit in cloned QA profiles; nineteen original images and protected
post-exit state have independent review. This establishes the stated seeded QA
routes only. Supplementary legal hardware preparation and CPU/target checks use
a separately reviewed external QA controller at checkpoint8a9c43e. Fresh ordinary
and tester runs pass147 and193 checks respectively, with natural exit0 and exact
original-parent protection. Ordinary target chapters remain locked; the tester
exercises their original access contract. Eleven explicitly enumerated tutorial
number encodings from the original Store serializer are independently checked;
other typed values stay strict. The earlier startup and serializer-audit failures
retain their failed receipts. The strict-reopen validator and product ZIPs are
unchanged. New package images receive separate per-image review. The fixed tester
footer can cover secondary Handbook/bottom-dock controls; its foreground evidence
and Run-all action remain visible. This limitation is queued for a bounded fix.
The [measured-growth evidence](verification/20261018-measured-growth/README.md)
keeps exact source/package identities and the previous failed supplement.
The fixedc109 pair below remains the previous recovery baseline.

## Previous Creative candidate — 2026-10-18

PR10 is merged into `main` as `bf8f61647c03c8bba868cc833b3832e274bd4aee`.
The current candidate adds bilingual context for all sixty tasks, a journal of
actual earned records and saved works, an optional3D observatory, a skippable
introduction with replaceable media, and an optional fixed NOT1→0 retrospective.
The journal opens original saved-work snapshots and recipes without generating,
forking or reconstructing events. Feedback closes before the owning work window.
The light workbench remains a QA comparison rather than a global theme option.

Both fixed Windows ZIPs use product source
`c109f0e9761726645faaa8d86d83fafa590cdec4`: ordinary progression uses
`Creative20261018`; all-entrance inspection uses
`OfflineTeammate-Creative20261018`. Access alone never grants completion.
The ordinary package passes128 controller checks plus47 independent-reopen checks;
the tester passes138 plus47, including its original bundled collector's sixty
actual entries, real C→P→G, saved-work restart and final-only four-case/two-session
feedback ZIP import and deduplication. Work preparation uses actual Session actions
in private QA profiles; these are not unfamiliar players or natural full journeys.
The downloaded ZIPs contain no QA save profiles.

Separate actual Windows OS inputs cover both exported packages through
Home → Journal → original work → Play → F8 → three successive Esc layers → Home,
with observed focus restoration and normal exit0. The tester also displays and locally autosaves a
synthetic short Chinese note, independently confirmed in UTF-8. These use explicitly seeded private QA profiles;
native CPG, native independent restart, long/IME input and newcomer use are not
established. Exact disk-note and protected-state audit scope is in the evidence.

Exact product sourcec109 passes172/172 complete Windows regression stages and
both remote CI runs. The ordinary package controller remains8a07; the tester uses
QA-only checkpoint`0bc3ad7923413a414a22a147f1620f09aadb5ae5`/controller9d0a.
That one-line correction checks the feedback ancestor's effective visibility;
product code and both ZIPs are unchanged. The original tester QA failure is
retained separately. Strict protected-file comparison is scoped to the running
reopen receipt. Normal exit subsequently updates save timestamps and rotates the
backup; the complete payload and other protected state are independently checked,
with only the existing six tester coordinate-type conversions disclosed.

The [current evidence and next-day handoff](verification/20261018-creative-framework/README.md)
contains exact package paths and SHA256, five source-bound images, renderer and
OS-input scopes, failures, replacement interfaces and five human-review questions.
Draft PR14 continues the F2 branch; PR11–14 remain unmerged. No public Release,
new Mac package or public receiver is included. Earlier source8334 packages and
all player saves remain available as separate recovery checkpoints.

The full development goal remains active in the
[coverage ledger](development/full-journey-coverage.md). Formal art, characters,
voice, endings, newcomer understanding, Mac and real historical-player-work
acceptance remain open; completed engineering stages do not decide those items.

## Earlier October18 candidate — fixed7c snapshot

PR10 merged into `main` as `bf8f61647c03c8bba868cc833b3832e274bd4aee`.
The separate `codex/night-experience-20261018` candidate connects a skippable and
replayable Yi introduction to actual first construction, independent interactive
rule examples, reason-specific first-chapter evidence guidance and visible C/P/G
map shortcuts. Shared dark surfaces have clearer focus/selected/disabled states;
light surfaces remain a comparison fixture. Model, completion and save contracts
retain their existing authority. The sixty-task inventory is unchanged.

The ordinary profile `NightExperience20261018` and tester profile
`OfflineTeammate-Night20261018` are separate from the October17
`OfflineTeammate` channel. The latter's existing package and saves are retained.
This round has no public Release or new Mac export, server or domain operation.
Its fixed packages, executed checks and limitations are recorded in the
[night evidence](verification/20261018-night-experience/README.md), with the
[team handoff](development/night-handoff-20261018.md) and
[full-journey source review](development/night-journey-review.md).

Both Windows packages freeze `7c4f9b58e4229864ccf29aa066de85a183d33924`:
`playtest-NightExperience20261018-7c4f9b58e422` (ordinary progression) and
`playtest-NightAccess20261018-7c4f9b58e422` (all entrances). Actual extracted EXEs
pass25/25 and32/32 first-experience/configuration checks. The tester additionally
passes60 actual foreground entries, current-model C→P→G generation/protected save,
independent restart/byte parity/recipe replay and final-only4 feedback cases with
4 screenshots across2 sessions. Ordinary-package C/P/G restart was not repeated.
Local full regression remains164/165 plus its corrected affected8/8 rerun;
rendering15/15 and eleven Python gates pass. These controller checks do not
establish native OS input or unfamiliar-player understanding.
Exact frozen7c GitHub Linux CI also passes165/165 Godot stages and all11 Python
commands; [run identity and log hashes](verification/20261018-night-experience/ci.json).
Separate [native Windows observation](verification/20261018-night-experience/native-receipt.json)
passes16 scoped OS-input checks on the unchanged tester: actual tutorial wiring,
earned completion/F8, single-letter autosave, independent restart and two normal
exit0 results. Long/Chinese input, prior-note history GUI restoration, native C/P/G
and newcomer understanding remain unverified. Engineering handoff is complete;
human and broader platform acceptance remain open.

## Public download — 2026-10-17

The latest Windows teammate candidate is
`playtest-OfflineTeammate20261017-4df5bad46751`, frozen at `4df5bad46751`.
[Pre-release v0.5.0-alpha.3-offline.1](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/v0.5.0-alpha.3-offline.1)
was published with the owner's explicit authorization on2026-10-17. Its tag points
to the tested source; all three asset digests match. PR10 subsequently merged on2026-10-18.
It opens all sixty task entrances in the separate `OfflineTeammate` profile.
Global feedback saves a game screenshot and live context, autosaves notes and
exports all plays in one verified ZIP. The included Python tools consolidate
multiple testers' exports into a private searchable report and session analysis.
It requires no domain, VPS, account or network. Earned completion, legal models,
existing saves and the remote upload whitelist remain unchanged.

The unchanged Windows EXE passed all60 actual task entrances and an independent
two-play restart. The final ZIP alone imported4 cases/4 screenshots/2 sessions.
The final focused store/UI checks and10 Python importer tests passed. Windows
native F8/text input has also been observed. Native first-process normal exit,
independent second launch and a final-only
ZIP with two notes/screenshots/contexts and two sessions also passed. Fixed-source
GitHub Godot CI passed160/160, with its Python job green. It is suitable for
controlled teammate feedback and overall art refinement; new-player understanding
and artistic acceptance remain observations for the next stage.
[Candidate identity, native scope and verification limits](verification/20261017-offline-teammate/README.md).

## Private feedback and earlier Windows draft — 2026-10-17

Protected PR [#7](https://github.com/wizardpc-com/von-neumann-bottleneck/pull/7)
was squash-merged into `main` as `94b5bff`. Main now contains the complete
sixty-task journey; tag `archive/pre-release-20261012` retains the original
31-commit branch history. The already published `v0.5.0-alpha.1` download remains the earlier forty-task
release. PR [#8](https://github.com/wizardpc-com/von-neumann-bottleneck/pull/8)
integrates deletion-safe feedback operations and a Windows-only Release draft;
publication is explicitly deferred until the feedback domain is ready.

The separate VPS localhost receiver/proxy are finally pinned to `347e4262602e05e67520b69f85451ade6a9c2297`; the actual private EXE feedback receipt below retains its tested `beca837` identity.
Both services and the daily maintenance timer are enabled. Actual Windows EXE
private HTTPS feedback passed same-ID/task/build reporting, offline retry,
deduplication, deletion and an actually started tombstone-safe restored receiver
returning410. Restore held0 events/1 deletion tombstone. Private reports and triage
were cleared, original services/configuration and historical data hashes stayed
unchanged. Local backups are managed on a thirty-day schedule; anomalous copies
fail maintenance for private review. Offsite backup is deferred.

Full Windows isolated Godot regression passed156/156; the final privacy URL change
also passed its focused suite. Bilingual720p privacy choice/expanded-list rendering
and Python/VPS checks passed. The client requires renewed cloud consent while
retaining local drafts and deletion identity. The frozen Windows draft at347e426 has all60 tasks, an empty endpoint and stable CloudPlaytest profile. Native saved64-cell work, original local opinion, writable save and independent restart passed; both normal closes released QA leases. Four GitHub draft assets match SHA-256 and the draft remains unpublished. Source347e426 push/PR CI are both green. No public player endpoint is active.
[Exact current evidence](verification/20261017-feedback-release/README.md) ·
[Private operator procedure](distribution/feedback-operations.md).

The planned feedback domain is not purchased/resolved or verified for hosting/
filing. Keep localhost. Public DNS/ports/TLS and external-machine acceptance remain
future gates. Current Mac native, unfamiliar-player and artistic acceptance remain
open. [Acceptance gates](../RELEASE_BLOCKERS.md).

The sections below are dated evidence snapshots. Their earlier “unmerged” and
“NOT_RUN” statements record what was true at each freeze, not the present branch
or host state.

## Creative expression candidate — 2026-10-13 (historical freeze)

At this freeze, unmerged PR #7 added discovery-led P3, two-sided actual A/B rule/count comparison,
and saved-work source/phrase navigation with default-off short symbol tones.
The model, legal conditions and persisted recipes remain intact. Both full-sixty
packages freeze `f261310` as `playtest-CreationExpression20261013-f26131049877`,
keeping `CloudPlaytest` and offline feedback/export. Content identity is
`tasks-20261013-journey-v1`, with both prior manifests preserved.

Affected checks7/7, both bilingual Windows renderer suites and packaged identity/
hash checks passed. On2026-10-16 the unchanged Windows EXE passed native saved-work
phrase/step/play/pause/viewing-map controls, writable save and independent restart
in the existing private QA profile. The64-cell protected work, all session fields
and original local opinion ID remained intact; both normal exits released their
writer lease. Subjective listening, current Mac native and newcomer acceptance
remain unverified. Current content has not been deployed to private VPS staging.
Fixed-runtime and documented-head full CI passed154 Godot suites plus import/user
isolation156/156, with all nine Python commands. The candidate is ready for overall
art refinement and a controlled offline playtest.
[Concrete changes, captures and acceptance limits](verification/20261013-creation-expression/README.md).

## Whole-journey experience candidate — 2026-10-12/13 (historical freeze)

At this freeze, unmerged PR [#7](https://github.com/wizardpc-com/von-neumann-bottleneck/pull/7)
added three bounded experience improvements: readable chapter/search/relationship
navigation; actual-evidence Next actions and accurate C3/P1/G1 conditions; and
earned Representation/Service continuation with 720p evidence scrolling. Legal
solutions, model/completion authority and existing saves/works remain intact.

`playtest-ExperienceFinal20261013-8a919e24b1a3` freezes both platforms at
`8a919e2`, with all sixty tasks and the stable `CloudPlaytest` save channel.
Native Windows chapter/search navigation and actual generation/keeping were
observed in the identical UI runtime at `d34a61d`. Final8a919e2 native saved-work
viewing, writable save/restart and local opinion restoration passed; normal exit
released the owned writer lock. A dead private QA residual lock was archived
without changing saves; Windows automatic abandoned-lock recovery is unsupported.
Fixed runtime CI passed; final affected Windows checks passed13/13;
complete-run retained failures and corrected measurements remain attributed.
Final exported EXE localhost feedback retry/report/delete/restore passed.

Creative goals now have explicit content version `tasks-20261012-journey-v1`;
the receiver preserves the prior version and rejects mixed identities. Current
content/server identity has not been deployed to the stopped private VPS staging.
Player packages remain offline with local feedback/export. Art direction and a
small controlled offline playtest can proceed; newcomer comprehension, current
Mac native and final artistic acceptance remain external observations.
[Before/after, frozen hashes, evidence and handoff](verification/20261012-experience/README.md).

## Windows playtest freeze and private VPS feedback — 2026-10-12 (historical freeze)

Branch `codex/pre-release-20261012` starts from freshly verified main `cfdee8a`.
PR [#7](https://github.com/wizardpc-com/von-neumann-bottleneck/pull/7) remained
unmerged at that point. Main and player save/model contracts were unchanged.

`playtest-PreRelease20261012-61edc8063078` freezes Windows/macOS from one source
commit with the complete sixty-task journey and stable `CloudPlaytest` save
channel. Windows native tutorial editing/completion, two independent restarts
and local opinion recovery passed. The isolated Windows game audit passed
155/155 checks; actual exported Windows feedback passed both local HTTP and
private VPS HTTPS, including private same-ID report, retry, deletion and an
actual receiver restored with tombstones. Temporary staging is stopped; other
services and the historical feedback database are unchanged. Code CI38206327893
passed. Windows-specific SQLite handle, request-drain deadline, packaging and
literal UTF-8 path defects are repaired.

The distributable package remains offline: local opinions/export work, upload
defaults off, and an unconfigured send is clearly reported. Public ingress/domain
and production intake await explicit authorization. Current Mac native execution,
cross-machine/signing, full-route unfamiliar-player and artistic acceptance remain
open. [Exact evidence, package hashes and limits](verification/20261012-pre-release/README.md).

## Distributable journey and feedback integration — 2026-10-10

Creative PR3 merged normally into main as b90ae47; feedback PR4 merged as
fdfbd6fb851bf925463a51335e20da4a202a2706. Local main was fast-forwarded without
overwriting the shared checkout. Final PR4 CI38044771067 subsequently passed all
152 suites plus import/user isolation and seven Python commands. The round integrates
the existing sixty-task candidate and feedback from unfinished tasks, including
Representation, Service, optional address Prediction and C/P/G. The runtime
changes preserve simulation authority, authored tasks and player save contracts.
Feedback uses explicit single-opinion authorization; automatic statistics remain
separate. Private receiver reports preserve receipt ID/task/build and use an
independent local triage sidecar. No account or new chapter is introduced.

Runtime efda8b8 is frozen into `playtest-Round20261010-efda8b84ae6e` Mac/Windows
offline candidates and a separate localhost-only acceptance app. Full local152
suites +2 isolation gates PASS; final seven affected suites +2 gates and seven
Python commands PASS. Actual Mac binary/PCK checks and same-ID exported-package
HTTP→SQLite→private review→delete/restore PASS. The restart acceptance found and
fixed a real JSON numeric receipt-ID mismatch. No player model/save semantics change.

Remote staging and public player availability NOT_RUN. Deployment/access details
remain in the local private handoff. Windows native NOT_RUN;
native Mac input was blocked by locked screen (a renderer retry timed out). Packages
remain unnotarized candidates, not public release or newcomer acceptance.
[Exact manifests, receipts, retained failures and limits](verification/20261010-cloud-playtest/README.md),
[round plan](exec-plans/active/distributable-cloud-playtest.md),
[feedback contract](architecture/community-feedback.md).

## Main integration and creative studio — 2026-10-10

Protected PR1/PR2 passed fresh local and GitHub CI, then merged normally as
70fefdd/7e4facb. Main retains both main-only C/P/G and the mature8115b8e increment,
without rewriting published history. Original40, old valid profiles, legal
solutions and protected model/work recipes remain intact.

The codex/creation-studio-20261010 increment was integrated by PR3.
Runtime67334e3 lets the player edit an existing passage for a transient intention,
explicitly Learn, compare actual fixed-recipe A/B, keep and exhibit exact saved
output in four lanes. In the documented recipe,12/64 cells change, first at10;
B decreases16→10 and C increases10→16. This is measured output, without grading.
No model/codec/session/catalog/project-setting or persistent-format change.

Final149 suites +2 isolation gates,609-file executed-source identity, same-source
CI38029449312, bilingual113-check routes,20-check independent reopen per locale,
and240-check bilingual editor renderer all PASS. Actual visual and exported
verification repaired current-cell following after same-frame mapping/seek/resize;
composition187 checks, strict signature/archive identity,16 package checks and23
actual-binary creative checks PASS. Frozen Mac candidate free-alpha-67334e386aa6
is copied into the original checkout's ignored build/ with an explicit player route.
[Final evidence, PR receipts and precise boundaries](verification/20261010-creative-experience/README.md).
[Chinese route](verification/20261010-creative-experience/HOW-TO-PLAY.md).

Native OS, Windows, newcomer learning and independent artistic acceptance remain
separate. Intent notes are transient; newer optional design/check profiles need
current readers, because older binaries reject these extensions without deletion.
No production migration or public/notarized release. The collaborator documents
were integrated in the subsequent documentation PR; private original copies and the local coordination record remain preserved.

## Repository maintenance — 2026-10-11

Superseded task books, duplicate proposals, the removed eight-task fork's blueprint,
and obsolete active queues are removed. Current navigation is in [docs/README](README.md);
remaining external acceptance is consolidated in [RELEASE_BLOCKERS](../RELEASE_BLOCKERS.md).
Historical implementation and verification retain their build attribution; deleted
instructions remain recoverable from Git. Runtime, model/save contracts, constitution,
tests and frozen packages are unchanged by this documentation cleanup.
