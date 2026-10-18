# 当前候选展示材料与镜头索引

这份材料供团队制作PPT／实机短片时取材，不是最终PPT、成片、提交说明或赛事规则。
[可编辑架构SVG](showcase-architecture.svg)使用原生文字、形状与箭头；无外图、脚本或烘焙正文。
系统字体缺失时会回退，团队导出前需检查字形。旧[40任务展示稿](astra-challenge/showcase.md)
保留其历史产品／版本背景，不把其中Product Hunt建议移作本轮参赛决定。

## 图与源码

关系基线为`2c56fd48b14d105961f380211102512d19e544de`；
本图表达源码关系，不认证新运行结果。
目录由实际构建开关决定；60项候选为核心40、表示5、服务3、可选地址预测3、创作路线9。
测试者开放入口不授予完成；地址预测的临时探索不算永久成果。

| SVG原生组id | 实际来源／责任 |
| --- | --- |
| `task-navigation` | `src/campaign/task_navigation.gd:journey_tasks/enter`、`second_act_tasks.gd`、`creation_tasks.gd`；原目录与合法进入 |
| `original-workbenches` | 硬件、System、Locality、Overlap、Layout原Host与`experiments/creation/workbench.gd`；实际搭建、编辑、运行 |
| `deterministic-models` | `src/layout_chapter/layout_simulator.gd`、`src/overlap_chapter/overlap_simulator.gd`、`experiments/creation/{model,codec}.gd`等原模型；结果和成本 |
| `run-evidence` | `src/simulation/simulation_trace.gd`、`src/system_lab/system_run_receipt.gd`、`src/layout_chapter/layout_run.gd`；原运行来源 |
| `existing-save-authorities` | `src/save/global_save.gd`、原域状态、`experiments/creation/session.gd`与`candidate_session/files.gd`；保持分离的原保存权威 |
| `evidence-presentation` | Layout `_case_contract_feedback/_locate_case_issue`、Overlap `_select_run/_locate_recorded_issue`、System `_refresh_history`与`efficiency_fragment.gd`；只读解释和定位 |
| `derived-record-spaces` | `journey_journal.gd`、`journey_observatory.gd`、`theme_reflection.gd`与原`work_focus.gd`；原记录／作品的可选只读回看 |
| `offline-feedback` | `src/playtest/{offline_feedback,offline_store,offline_context}.gd`、`scripts/offline-playtests.py`；本地现场、原ZIP和随包工具 |

实线表示操作或原合法保存；虚线表示读取运行证据、原记录或真实前台现场。
图中没有第二套进度、物理能耗推算、角色系统或新的网络服务。

## 团队录屏脚本：五个镜头

这是可执行取材路线，不是已录成片。**当前尚无本轮实机操作视频**；
以下原图来自独立renderer/controller验证，不能称OS鼠标键盘、新人体验或自然完成全旅程。
本轮新包与原生范围以中央[验证记录](../verification/20261018-measured-growth/README.md)为准。

| 镜头 | 操作脚本与可替换素材 | 画面／旁白边界 | 当前可用材料 |
| --- | --- | --- | --- |
| A · 亲手构造 | 新档Home→原NOT教程；接两条线、切输入、运行、拆线／重接；完成后Journal→主题回顾，可跳过／返回。开场Texture、回顾Texture可独立替换，目标／字幕仍用原生文字。 | 输入1、输出0仍正确；回顾用生产milestones，不能用压力字幕冒充实际CPU通关。 | [A当前实包开场](../verification/20261018-measured-growth/images/source97516b21f459-work01ada45151aa-introduction.png)，仅开场帧；五操作证据见父收据，录屏PENDING。 |
| B · 看清未达标 | Layout `fields`原方案→运行→「运行与比较」→读128/上限64/超64B→「定位这单的未达标证据」；可回原Trace查看搬运。再录Overlap的首未达标／停止代码行时，修改后重跑。 | 输出正确与达标分开；定位不替玩家改方案。镜头需要原滚动／浮窗前置，不能称全部窗口默认同屏。UI与地址／代码原生呈现，不替换成伪统计画面。 | [B原帧](../verification/20261018-measured-growth/images/source69b785a11c72-workf648350bf08b-layout-unmet-zh-1280x720.png)；官方模型TestMode夹具。录屏PENDING。 |
| C · 看清比较 | 原 `cpu_speed` 完成实际造机／前置→同程序与测试集、只改CPU的两次合法运行→「历史」原图→「时间留在哪里 · 候选片段」→三步选择→原滚动看回应→回原图。可替换Texture；缺图保留程序几何与原生字幕。 | 原图316→268总周期、等待252→252不是“全部更快”；来源与同条件说明保留。意象是聚合记录候选，不是事件重演、能耗或新奖励。 | [C原帧](../verification/20261018-measured-growth/images/source69b785a11c72-workf648350bf08b-cpu-fragment-zh-1280x720.png)；官方模型TestMode受控pair。录屏PENDING。 |
| D · 完整路线与原作品 | 任务树区域／搜索→C1学习与无损复原→P1亲手commit/reveal→G1生成并明确保存→Journal查看原输出／配方／来源→返回。作品用原模型实际输出，不由展示图替代。 | 能进入不等于模型准备完毕；原保存快照不伪装生成事件回放。受控QA准备必须说清，不能冒充普通新玩家自然全流程。 | [D当前实包原作品](../verification/20261018-measured-growth/images/source97516b21f459-work01ada45151aa-saved-work.png)；实际Session控制器准备并保存的快照，非自然全旅程。录屏PENDING。 |
| E · 同一成果空间 | Home／Map→观察站→硬件／System任务→「近看所选装置」→三个原视角→「还原全景」→任务树定位／原工作台；插入F8→Esc逐层返回。程序几何与小型材质可替换，任务文字／状态不烘焙进图。 | ✓合法成果与○未完成／锁定分开。图中System未开放、灯暗、进入禁用，不能配成“玩家已完成该章”。可关回原列表，不加前置或第二份进度。 | [E原帧](../verification/20261018-measured-growth/images/source2c56fd48b14d-work7cbafa2f2785-system-inspect-zh-1280x720.png)；真实Home入口、原教程／作品准备后的只读观察。录屏PENDING。 |

### 五张原图的身份

A/B/C/E为1280×720、D为864×496 PNG；逐张实际查看、复制前后SHA256一致，未拼图、修图、转码或重绘。
B/C/E是源码renderer证据；A/D来自当前普通实包的实际导出程序控制器父验收。
**这些帧不代表原生OS输入、陌生玩家理解或自然完成全旅程**。源码88张独立图审覆盖两语三尺寸；
精选图不代替完整运行、重启、测试者链或包身份收据，完整范围仍查中央验证记录。

| 帧 | 产品SOURCE／测试脚本SHA256 | 原receipt与SHA256 | 原PNG SHA256 |
| --- | --- | --- | --- |
| A | `97516b21f459a7be9b557fdffc0d1e265b5a839d` / controller `9fb11c3d276816872b1fed655e646fc39b3e0b843ae42ee3d2adf0bd5e3a1a5f` | `.godot/night-package/01ada45151aa/receipt.json` / `4df0ecfe6d8a1e56c8fffc7a6bd6c13d367d7fdf61e9842fa17830acf70aed05` | `31f5eb0289da3f1ada8913c8e4b50b26c7b3aa57bae0e6a8eec700c0b399ff98` |
| B | `69b785a11c7261ddcdfbbdc02dec24d01abd0b3d` / `fdd4cc86fd45f9827244ed0cde46b49f20c8e277083fe82df12f0ad4e5f00e8f` | `.godot/f4-rendered/f648350bf08b/test_target_evidence_guidance/receipt.json` / `39d03fe0ba1782bdc7bfe75a25435d5ef749d3849681cf54b79c4cb610b09674` | `f22a909da01d1f73e8625b8005c698389b661f80b937b6e6659eab7968f99c63` |
| C | `69b785a11c7261ddcdfbbdc02dec24d01abd0b3d` / `35abfaa478cd799cfdbc1d0b730179e6a9c6489463d0fbeace4db0e6065c4492` | `.godot/f4-rendered/f648350bf08b/test_efficiency_fragment/receipt.json` / `16c87acf88298f2bfef08c33e1a14cfcf7c155c28cdfce1b1f8711601653d4f7` | `cd84e48d7533a39b40ae337224e1d4907e35907bb7f7dd0454fb14074c9ec52b` |
| D | `97516b21f459a7be9b557fdffc0d1e265b5a839d` / controller `9fb11c3d276816872b1fed655e646fc39b3e0b843ae42ee3d2adf0bd5e3a1a5f` | `.godot/night-package/01ada45151aa/receipt.json` / `4df0ecfe6d8a1e56c8fffc7a6bd6c13d367d7fdf61e9842fa17830acf70aed05` | `831bb1610cb5f2a089351b2c6097e363d8d9eeee51bfde54055fd236879f9e39` |
| E | `2c56fd48b14d105961f380211102512d19e544de` / `e8f0782fe31d3ae7bf2134d7c005ece9071781c6c28e4295dce766cf5977b611` | `.godot/f4-apparatus-rendered/7cbafa2f2785/test_observatory_apparatus/receipt.json` / `02c9e5ee4134276a4bd42dd809c4e2a91594a8f549767fe02796bae56c90ff87` | `038f45fcd82ff424e6502b1091622ac701c876282bad2180e7391e39971f0f82` |

A/D原图分别为 `.godot/night-package/01ada45151aa/intro.png` 与 `saved-work.png`；
其父收据128项全true、failures为空，profile为普通 `MeasuredGrowth20261018`。
物理根帧1280×720、逻辑1600×900；D另取实际作品Window纹理864×496，不把它标成整屏。
D由该embedded profile的原Session实际train→lossless transport→prediction commit/reveal→generate→save后关闭writer，
再经生产Journal查看；原作品id为 `67f5602f7e4f0b670f2b0c01424e27b1f3390797586f8ef3174422bcae67f8e3`，
Session SHA256为 `20f4c259ad9101722a926577da6d3c14a73b1ca37b4af658e49704c08c4025d2`。
这不是生成事件录像；图中也明确仅保存快照。仅据父趟取图，不另宣称完整包链或OS通过。

B原图在其receipt的 `target-guidance-captures/zh_CN-layout-traffic-1280x720.png`；
C在 `efficiency-fragment-captures/zh_CN-1280x720-expanded.png`，两者实际路径前缀为各suite的
`runtime/appdata/VonNeumannBottleneckChecks/F4Rendered-f648350bf08b/<suite>/`。
E原图为 `.godot/verification/20261018T004613Z-4c2fe966/project/.godot/observatory-apparatus-captures/zh_CN-1280x720-system_modules-inspect.png`。
这些隔离源码QA配置显示49项任务，最终全60候选需相应构建开关；不伪改截图计数。
720p深层说明／精确source key使用原滚动；图E任务标题、状态、门槛及所有原导航按钮同屏。

## 已有可审阅参考

以下是上一固定普通实包c109的原字节帧；它们**不是F4新包证据**，也不伪称同一新录像：

- [开场Texture与原生目标](../verification/20261018-creative-framework/images/sourcec109f0e97617-workfb44325711b2-introduction.png)：1280×720。
- [真实教程后生产回顾](../verification/20261018-creative-framework/images/sourcec109f0e97617-workfb44325711b2-first-light.png)：520×384，固定NOT1→0。
- [原作品只读快照](../verification/20261018-creative-framework/images/sourcec109f0e97617-workfb44325711b2-saved-work.png)：864×496，披露实际Session controller setup。

完整来源与SHA见[原集中证据](../verification/20261018-creative-framework/README.md)。
本轮F4实际包须按自己的提交、receipt和profile绑定；上表新renderer图与这些旧实包图互不代证。

## 新图与录像的接入规则

1. 等独立suite实际renderer收据成立，再按A–E选代表帧；保留失败原件与独立raw目录。
2. 逐图实际查看文字、必要按钮、数值和裁剪；记录原路径、SHA256、像素、产品SOURCE、
   外部QA源码／控制器、suite、locale、窗口、role／profile、setup、操作和证据等级。
3. 图若来自合成状态、字幕压力fixture、合法scroll后布局或私有CPG setup，逐条写明；
   不据一个帧声称全60解题、默认首屏、系统输入、跨机或新人验收。
4. 仅将批准的纯游戏画面原字节复制到本轮中央验证目录，填写真实可点击路径；
   PNG/JPEG按实际header标记，不转码、拼图或把旧图改名成新SOURCE。
5. 实机录像另录操作和解释；没有录像能力就交实图与本索引，明确“尚无实机视频”。
   不将截图串联或游戏内演出当作实际操作录像，不假设评审端会播放GIF。

当前交付为可编辑架构图及镜头索引。正式画面风格、人物、CG、声音、解说、成片、PPT版式、
公开发布和赛事格式均未由这两份材料决定。团队可据真实证据取舍，不增加游戏前置条件。
