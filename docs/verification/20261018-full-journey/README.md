# 全旅程续轮证据 · 2026-10-18

本轮实现60项任务语境、只读成长档案和真实3D观察站，保留原工作台、原完成权威及原导航。
这是持续开发中的证据入口，**active计划及完整goal均未关闭**。
需求与开放项见[覆盖账本](../../development/full-journey-coverage.md)，
执行与所有权见[active计划](../../exec-plans/active/full-journey-experience-20261018.md)。

总控核准基线为`cf89a76`，分支`codex/full-journey-experience-20261018`。
F1源码可恢复检查点已由总控提交为`c50492a`及`0aa1866`；它们不是最终包冻结，也不声明所有Gate通过。
基线CI运行`39061439011`已由总控核读为completed/SUCCESS；它不证明本轮新增代码。
[旧7c固定包及限定原生验收](../20261018-night-experience/README.md)保留原身份，
本轮尚无新固定包、原生或陌生玩家验收结论。未执行公网发布、账号/服务器修改或旧存档迁移。

## 已落盘的可观察变化

- 九个原工作台使用同一`MissionNarrativeCatalog.task_context()`：先显示Now/Verify，再按需展开
  壹的语境、卡点方向、承接与真实完成回顾；不替代原任务规格、手册和Hint，不改变验收。
- Home/map可选打开JourneyJournal。其目录取自真实`journey_tasks()`，原核心记录单独计数；
  展示历史成绩的已有case/model/build来源、原作品只读快照和明确标识的虚构候选片段。
  入口开放不算完成；临时/损坏/未来版本/只读证据不补造历史、不取得writer lease。
- Home/map可选打开真实3D观察站：SubViewport、Node3D、程序几何、三个固定视角与原生文字。
  灯和✓来源于同一合法完成判断，不能把测试者入口或地址预测临时记录当成果。
  灯是叙事映射，不是电路信号、能耗或文明测量；原任务树保留。

## 独立源审

| 作者范围 | 独立审查 | 结论及边界 |
| --- | --- | --- |
| Narrative：60context、ContextCard、完成overlay及9Host | Knowledge只读核对真实catalog、完成/历史/草稿、合法替代、切任务/撤销/语言、委托及临时探索 | 未发现生产阻断。测试中缺少必需reason参数已由作者修复；不代替运行/布局验收 |
| Knowledge：Journal及测试 | Narrative只读核对completed/session/只读、无写入/lease、导航失败保留、成绩来源及作品保护 | 无确定阻断；指出ThemeReflection/F8焦点栈缺口，新增真实渲染专用测试待跑 |
| Visual：观察站及Home/map入口、测试 | Knowledge只读核对完成与访问、坏档/session、浏览无写、实时门禁、3D及生命周期 | 无生产阻断；要求真实Host/F8/焦点链，已补测试，结果按各快照列示 |

测试前置和输入注入方式的问题单独保留，不把它们自动诊断成产品故障。

## 隔离快照与早期失败

Godot为`4.7.1.stable.official.a13da4feb`。原始日志留在本地忽略目录，
[脱敏摘要与原始结果SHA-256](checks.json)保留每次来源；未复制玩家内容或绝对用户目录。
目录名使用UTC，文档日期使用Asia/Shanghai。

| 来源 | 实际结果 | 适用范围与限制 |
| --- | --- | --- |
| `verification/20261017T192129Z-cbc56971` | import/userdir/旧地图通过；Hub 28/7483失败；新观察站测试编译/超时 | 24项旧固定按钮数量断言失效，另4项英文720p恢复提示实际越界；新测试过早preload引发autoload标识错误。保留失败 |
| `verification/20261017T192616Z-93ecc682` | 5/5阶段通过，Hub7507项通过 | dynamic-load测试、显式入口断言和首页间距修正后的早期copy；字体未缩小 |
| `night-render/ccba2cdd3da7` | 真实720p观察站12/454失败 | 3D/三视角已有实际PNG。F8轮询Input动作，而viewport-only注入未更新动作；后续改全Input注入，未删除断言 |
| `verification/20261017T192847Z-c6d957a2` / `night-render/17e7c6ccc3b0` | import/userdir/观察站通过；渲染仍2/454关闭链失败 | 首12→2可归因Input注入修正；剩余2项原因未确立，不能写成已定位产品bug |
| `verification/20261017T193052Z-12298ff6` | Narrative1/1128失败；Journal Nil运行错误并超时；观察站通过 | Synthesis双合法路线文本断言未满足；Journal未明确进入教程而访问空输入控件，后续改真实TaskNavigation进入并核对就绪。不是生产编译失败 |
| `verification/20261017T193442Z-fdd646fa` | import/userdir/观察站299项通过 | 仅此固定copy |
| `full-journey-visual-smoke/09b471c286b4` | 同fdd copy：Journal160项、Narrative1128项通过 | headless控制器/模型及只读保护，不是OS输入、完整关卡游玩或窗口渲染验收 |
| `night-render/56fea33b0d74` | 真实720p观察站454项通过；24张全帧/3D纹理 | 源摘要`1f1bfc7b43274e280c7ad9cba33492f4f8ea4a4c0145f33b05c42cf312e93096`；包含明确fixture灯亮/灭，不冒充玩家earned。旧2项关闭失败未在该fresh runtime重现，因果仍未建立 |
| `verification/20261017T193841Z-85535900` | import/userdir/观察站3/3阶段通过 | 最新coherent copy，包含后续marker、system topology/locale及Reflection测试；不与fdd源码混同 |
| `full-journey-narrative-runs/0388d903ab50` | 同855 copy：11/11套定向PASS/exit0，无超时终止子进程 | Journal160、全旅程Narrative1134、旧Narrative61、system guidance84、tester导航66、封装导航25、DirectKeep87、当前模型准备39，以及Overlap模拟/UI、Layout UI。Journal明确打印Reflection/F8窗口栈NOT_RUN |
| `full-journey-narrative-runs/574f3d275059` | 同855 copy：Narrative真实渲染及54帧通过；Journal渲染2项失败、exit1，无子进程超时终止 | Journal总174项；全user目录inventory变化、ThemeReflection上的tester首次Esc未仅关闭反馈。焦点窗口、反馈重挂popup、真实captured截图的前置断言均通过；不能据此前headless成功跳过修复 |
| `verification/20261017T194235Z-464601a8` / `verification/20261017T194755Z-be2664fe` | 464：import/userdir/Narrative3阶段通过；be：再含旧ThemeReflection共4阶段通过 | 字号/布局及ThemeReflection窄修后的新copy，不能沿用旧855的最终结论 |
| `full-journey-narrative-runs/05473520dca7` | be copy真实Journal诊断，exit1、181项，保留6项失败 | 唯一inventory变化确证为presentation.cfg；tester新Reflection全栈通过，ordinary Moments真实popup有5项失败。源摘要`e84171f0a5bf8e6250ef757b10cb427637176db22e7e022994beac3937880210` |

56fe晚于上述旧失败，**但早于**marker主题实际最小尺寸修正、system拓扑/语言刷新回归和
Journal→ThemeReflection→F8新栈。其成功不能认证这些后续差异。
视觉实现/素材替换接缝及失败细节见[观察站说明](../../development/full-journey-visual.md)。

## 当前等待的最终整合验证

唯一引擎持有人为Narrative，总控负责令牌与最终整合。当前最新copy为`85535900`，
活动序列输出在`.godot/full-journey-narrative-runs/0388d903ab50`，
源摘要`2dcdf09cc4812a81415e7507f015e16df48a7ae166a52fefe8cce96bf64bd752`。
11套headless定向已全部通过。真实GUI序列`574f3d275059`已完成：九Host×两语×三窗54帧通过，
Journal两项失败。首次Esc后的测试提前返回分支表明底层ThemeReflection已释放，须修正真实窗口栈。
另有源码线索：`WindowMode`在真实renderer每2秒保存`presentation.cfg`窗口几何，测试也主动改尺寸；
但当前失败回执没有前后文件差异清单，仍须精确诊断，不能把该线索当成已证明原因或放宽真实profile保护。
未据这次结果宣称最终布局/字体/全部可用性通过；后续窄修与新快照各自验证。

针对该失败的窄修已落盘但尚未验证：ThemeReflection禁用内建自动Esc关闭，由自己的Window
消费关闭事件，原反馈若挂在此popup中则先调用其现有关闭接口；不修改共享OfflineFeedback或模拟/存档。
Journal测试保留全inventory断言，只增relative path及前后SHA差异打印。先无capture参数复现并确证
实际变化，再决定是否沿已有`--capture-size`确定性渲染契约禁用测试主动resize引发的偏好写入；
不忽略未知文件、不删除真实profile/作品/lease/history字节保护，旧574f失败保持原状态。
普通渠道的新栈也必须通过既有PlaytestMoments：真实panel位于聚焦popup viewport、
键盘可操作、Esc仅退反馈并恢复回顾焦点，且不新增测试者离线incident。
仅证明“不打开OfflineFeedback”不算普通F8可用。该断言已加入，等待实际运行；
共享PlaytestMoments尚未据假设改造。

最新054735诊断已实际收窄：inventory仅`presentation.cfg`从absent变为
`b9149c226c1e6142ced388947878597c7ca34b8f47e2eb79e39669e5f755d050`，
测试主动改窗口而触发WindowMode已有周期偏好保存；其余所有被盘点文件保持相同。
后续沿已有`--capture-size=1280x720`确定性渲染契约重跑，保留完整inventory断言，不新增忽略。
tester真实popup首Esc窄修已在054735通过；ordinary的panel显示、viewport、内部焦点、Tab和首Esc五项
均实际失败。总控现已核准只对既有PlaytestMoments的窗口挂载/输入/焦点作最小修复，
保留原数据和渠道，销毁popup时归还共享layer；修复及root/popup两渠道实际复测仍待完成。
下列项不得提前标PASS：

- 三套新定向及上述受影响11套旧/新保护已有固定855来源通过；完整全仓回归、
  其余未涵盖的UI/规则/模型保护仍待后续结果，不将定向范围扩大为全量。
- 三尺寸两语的九Host实际内容、marker边界、普通/测试渠道及Home/map实际打开/复用/关闭。
- Journal原手册栈，以及真实ThemeReflection AcceptDialog→全Input F8→反馈Esc→回顾Esc→Journal Esc；
  精确焦点恢复和真实popup截图。headless明确输出该窗口栈NOT_RUN，不能据headless通过宣称完成。
- 新固定源码提交、完整回归、CI、新普通/测试者导出包的身份/开关/目录、真实解压启动、
  普通门禁、真实C→P→G/作品跨进程保护和最后ZIP反馈子链。
- 本轮限定原生观察、陌生玩家理解、异机/Mac、人设/CG/声线/剧情变体及团队正式素材审阅。

重跑由总控授令牌后执行，不在原profile运行。headless定向可用
`python -X utf8 scripts/verify-project.py --godot <Godot4.7.1> --suite test_journey_journal`
（其余suite重复`--suite`）。真实渲染在隔离copy中运行同一Journal脚本，不加`--headless`；
观察站渲染需`--observatory-capture --capture-size=1280x720 --candidate-journey --creation-journey`。
具体执行身份与结果以新回执为准，不以这段命令示例当作已执行证据。
