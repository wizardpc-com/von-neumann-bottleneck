# 未达标证据与真实改进 · 验证及次日入口

## 当前门禁

阶段仍为 **ACTIVE**，完整目标也仍为 **ACTIVE**。新候选 SOURCE 为
`97516b21f459a7be9b557fdffc0d1e265b5a839d`，分支为 `codex/measured-growth-20261018`。
Root 管理 Git、引擎与实际包身份；后续证据文档提交不等于产品 SOURCE 变化。
Root已提交／推送97516并核对远端精确一致。它在2c上只补三份分发说明与四份文档，生产／测试／外QA不变；实际GUI仍分别属于69和2c。

- **69 原定向门禁 20/20 headless PASS。** 20 日志无 ERROR、20 自有进程自然退出0；输入复制收据714/714精确，独立复查713个非配置文件原SHA相同。仅私有生成的project配置含两条QA userdir注入及CRLF序列化；只处理此配置的这两项差异后原源SHA精确相同。174 canonical tests、零额外 QA test；完整 archive 的5761文件只作身份记录，5047个 docs 路径未物化，不称完整树已复制。
- **历史69三个 suite 的真实 renderer 技术断言通过，但观察站画面验收未接受。** 效率184、未达标证据169、观察站3442检查，三进程自然退出0、无ERROR；88原PNG与最终运行／作品文件SHA独立重算，其中58主viewport帧、24实际3D纹理、6离线现场。四条角色路径确实观察到F8接收／截图忙边界，旧失败不追改。
- **历史69观察站的旧画面仍未接受。** Root实看中文720系统近看帧发现旧教程面板遮挡；原真实教程host未释放，假根host中的观察站z60低于旧面板。该问题只修测试，改为正常退出后走实际Home懒加载入口；生产观察站未改。
- **历史2f只改观察站测试与四份文档，但新观察站门禁已因测试SCRIPT ERROR中止。** 实际`results.json`只有import／userdir两条正常PASS；第三个自有进程被严格监督器按script_error终止，exit1，没有正常App结果行，不能写成“三阶段正常完成”。真实Home的Locate已切到Map并释放旧host，测试324行仍读旧观察站visible。App实际GUI未执行；继续只修测试并重新固定来源。
- Root精确Git路径收据与本作者714个非docs输入复查一致：2f仅观察站测试不同，713项原SHA相同。69效率／未达标证据的渲染结果保持各自范围，不称2f三个suite全部重跑。新构建将注入自己的SOURCE／版本身份，不据此宣称EXE字节相同。
- **新2c观察站门禁三阶段全部正常PASS，suite3319检查通过；实际GUI3613通过且50原图获独立接受。** PID45184自然退出0、无ERROR，50图逐SHA核对：24主viewport帧、24实际3D纹理、2离线现场；最终runtime／作品文件亦重算匹配。真实Home释放旧host／外来面板和hover防护／真实定位Map字段／两角色反馈及非导航保护都已执行。Visual已实际view全部50图，新结果不覆盖旧69画面拒绝或2f脚本中止。
- **当前合成的已审渲染是69效率24图／Target14图，加2c观察站50图，共88图。** 不称97516全三suite重跑。97516的原完整Windows回归已终态 **175/175 PASS**；普通新包原父链 **128/128 PASS**、独立进程严格重启 **47/47 PASS**；正常克隆补充已 **FAIL**，阻止本阶段最终验收；测试者新包构建身份已通过，其原父138／收集器／严格重启47也已实际通过；新补充修复仍未运行，不能借完整回归替代新包结果。
- **97516原Windows headless完整回归175/175独立核验PASS。** 175条结果、全部175日志SHA与严格ERROR扫描、175自有进程自然退出0均已复核；174 canonical tests中执行173个，原GUI-only `test_recovery_game_input`按原verifier不在headless枚举，零额外QA。完整archive5763只作身份记录，排除5049个docs，只物化714项；固定输入714原字节相同、复制时714/714精确。终态project713项仍原SHA，唯原verifier生成的`project.godot`含两条隔离userdir与CRLF例外，精确移除后重建原SHA。外层TEMP／TMP同用独立空QA目录，APPDATA／LOCALAPPDATA仍由原verifier指向本次runtime并逐suite隔离。详细收据／源／日志哈希见checks；这不是导出包或OS验收。
- 本轮已有Root实际两角色观察站OS路线的限定通过，但没有native CPU／Targets／CPG、独立原生重启、新人、Mac或真人旧作品验收结果。原 c109 两包是已验恢复版本，见[旧交付入口](../20261018-creative-framework/README.md)，不能标成本轮覆盖。

Root实时核对97516的远端CI：`39084476085`的Python／Godot均SUCCESS（Godot结束于`2026-10-18T01:04:16Z`）；`39084473027`的Python／Godot均SUCCESS（Godot结束于`2026-10-18T01:07:11Z`）。这些状态不替代本地Windows完整回归或新包验收。

原结果与逐文件 SHA 见 [checks.json](checks.json)。本页不收录私人意见内容、运行账户路径或未经核验的包下载链接。

## 当前补充阻断与保留失败

**历史启动失败仍保留。** 普通克隆补充`measured-fd6f9bd3334c`实际FAIL：首错为教程成果绑定未满足，随后CPU空选项／受控pair和Layout任务契约错误，进程26784自然异常退出`0xC0000005`，不是监督器终止；没有成功补充raw或validation。原失败日志／摘要保留，不自动重跑。

已独立核seed、日志、进程和post-exit map：原父runtime的18文件＋36目录精确不变，该失败回合的父128／strict47收据、ZIP和当时三外QA也未变。源码定位两个启动合同冲突：实际`--capture-size`触发GlobalSave自动化分支而不调用load_game（磁盘教程完成仍真实存在；未记录runtime loaded_save值）；free_candidate明确拒绝`set_mode(test)`，QA却未检查返回，不能把后续未合法进入的Host当模型回归。异常退出底层机制仍未确认。这段为旧失败回合的诊断记录。最新wrapper b213已通过双独立静态审查，尚未执行；旧失败不改判。

**最新合法准备回合仍为整体FAIL。** 外QA `cb9e6aa`在普通新clone `measured-f32298c0a1b1`以原Host连线／官方验收／封装完成真实Hardware→assembly→CPU。引擎9812自然退出0、无ERROR，原GD147项全true，五张实际1280×720图已由Visual逐view并接受限定范围；normal Targets仍原锁定NOT_RUN。然而wrapper第302行因旧工作台typed保护拒绝而exit1，未生成validation。摘要`.godot/f4-normal-measured-legal-prep-FAIL-summary.json` SHA `eed1a4d26411856205fe9bcd5eba3f9390a3d965d80e1d468fda91546c317db0`绑定原raw／进程／五图，不能以GD或图审通过替代整体门禁。

旧tutorial/default精确只有11个同值类型差：snapshot.schema_version与四个组件端口宽度`int1→float1.0`，两条wire各color_index／from_port／to_port共六项`int0→float0.0`。其余键、数组顺序、值、类型和原布线／布局／元件身份均相同。原Store的JSON读取保留浮点表示，新任务保存会以full_precision重写整manifest，连未编辑tutorial快照一并重编码；原父／作品不变。新wrapper `b213d90b…`仅从旧expected副本为固定11指针构建同值float预期并记录转换，原float必须精确不变，其余仍严格；probe736与strict7b9未改。此窄修已获Narrative／Visual双独审通过（原比较块正反例仅纯内存），运行NOT_RUN，不回写旧失败成功收据。

五图的范围审计`.godot/night-package/measured-f32298c0a1b1/visual-independent-audit.json` SHA `b939bdfb592087eedc492805d18795570d874d856a5f5d4614e4dbb52cb1a432`只确认实际观察站与CPU原记录316→268／同程序同测试集及反馈画面。深层等待／计算文字与返回仍需原滚动；不是双语多窗矩阵、OS、新人或完整补充PASS。这五张raw不与展示索引已收录的五张素材混计。

## 限定原生观察站验收

Root使用官方Sky实际鼠标／键盘完成两角色：Home→观察站教程✓→近看／还原／F8与Esc→System○近看→Home→AltF4。普通System未开放且进入禁用；测试者允许测试入口仍无成果。进程17796／47144均自然退出0，19张原JPEG（9＋10，856×511）由Visual逐张view并独审接受；本证据作者另核19图／进程／trail哈希、原包和whole-parent全集不变（普通54文件／39目录、测试者75文件／48目录）。

本地QA档案仅主备保存时间戳／正常轮转变化，其typed payload精确等原strict／baseline，无新normalize；原作品／Session／空lease／硬件草稿／导航／成绩／显示偏好不变，其余只有日志及测试者一件本地现场的三个文件。未上传。accessibility返回null，只说明实见焦点轮廓，不宣称内部焦点身份。此为已知路线、明确seed的QA验收，非陌生玩家；没有native CPU／Targets／CPG、独立原生重启、长IME或Mac结论。它不关闭旧补充FAIL。

合法准备主路径及原三处guard窄修已获双独立静态审查，且在cb9e回合实际运行147GD通过；最新11指针codec边界也已双独审通过，仍待新运行：不再capture／TestMode，改用原Host真实连线、官方模型、封装与System合法前置；normal Targets仍按原锁定为NOT_RUN，tester沿固定权限。旧父controller与新补充controller分列，严格脚本原字节不变。当前wrapperb213尚未实际执行，cb9e回合整体仍FAIL，不能把局部运行或静态通过改写为新补充PASS。

## 本轮可观察变化

| 入口 | 最终候选行为 | 原权威边界 |
| --- | --- | --- |
| Layout 原结果／trace | 分别显示输出、周期、总 RAM 读写或空间申请的公开条件与实际差额；定位原事件／地址 | 不自动改方案、搬运数据或授予成果；bonus与主条件分开；陈旧／失配记录不可定位成当前问题 |
| Overlap 原结果／trace | 首个未达标 case 与下拉项、事件、周期一致；原运行错误可定位原代码行 | 原程序与 board 必须同时匹配；真实编辑禁旧定位；Buffer／Cache合法路线和阈值不变 |
| System CPU 原 History | 原受控 pair 旁可选展开计算／等待／总周期观察及候选壹片段；保留原同尺度图 | 数字只来自原记录副本；当前草稿不同会说明，持平／变慢不包装成改进；不伪造历史或物理节能 |
| Home／地图的可选观察站 | 硬件／系统的程序几何装置可近看、还原及切原视角 | 装置是成果隐喻；来源任务和合法完成状态仍由原目录给出，不是当前电路几何、信号或能耗测量 |

所有源改动经过作者之外的交叉审查。静态通过只覆盖源码合同，不替代真实 clip、F8、截图忙边界和实包验收。

## 历史检查点：失败保留，非当前门禁

| 固定来源 | 实际结果 | 结论与后续边界 |
| --- | --- | --- |
| 1d887c5 | 原20阶段18 PASS／2 FAIL | 观察站 exact Rect2 复合断言1项；Overlap 两语旧编辑测试各1项。效率54仅headless通过 |
| 040c198 | 原4阶段3 PASS／1 FAIL | 改为真实 CodeEdit 插入后 Target108通过，各语实际 text_changed=1且禁旧定位；观察站仅报警标记宽63→63.000030517578125，保留原失败 |
| e3e475d headless | 原20/20 PASS | 浮点矩形契约改为数值近似且占用像素包围盒精确；相机／装置仍精确，不移动基线或增加等待 |
| e3e475d renderer | 效率174检查、16条ERROR、24原帧，整suite FAIL | 两语720来源条件被裁；另14项是F8接收相位及随后测试自行切步造成的级联。后续面板／焦点／Esc／保护通过不能覆盖前错；其余两suite未执行 |
| fcad2 headless | 原3/3 PASS | 生产展开定位由整块body改为指标阅读区；完整来源、原图和16px正文保留 |
| fcad2 单GUI诊断 | 174检查、14条ERROR、24原帧，仍 FAIL | 新720来源／条件／步骤／数值经实际图审可读，clip缺口已闭合；F8相位失败保持。深层原生文字仍通过原滚动阅读，不称全部同屏 |
| 2f观察站新门禁 | 2条正常PASS结果；第三自有进程script_error终止 | 新真实Home定位已正常进入Map；测试继续读已释放观察站对象而错。原日志／中止回执保留，不把缺少App正常结果行当通过；GUI未执行 |
| 2c观察站修后 | 原3阶段正常PASS／suite3319；真实GUI3613技术PASS／50图 | 正常Locate后核新Map，再返回新Home；不读旧对象。旧69遮挡和2f脚本失败保留，当前独立图审另列 |

fcad2 四条真实相位一致：请求与原 pre_draw 在同帧，输入尚未接收，flag／busy为false、渐变正常前进约0.066；原测试此时自行切到step2。下一周期普通面板已开；测试者下一 pre_draw 为真实 busy／paused、面板尚未显示，再下一帧面板打开。这个结论限本次 installed4.7.1 的实际记录，不泛称所有引擎行为。

Visual的最终独立图审收据`.godot/f4-final-visual-audit.json` SHA `f0f06b8574b9a374b2b5d86a750074eea29d3a8a47f0e0f0801b60a9224d0889`绑定上述88图。接受范围仍有明确边界：深层原生文字、程序、几何和返回动作可能要用原滚动；69的英文1600／1920图中F8／导出浮条仍在旧720坐标，可盖住次要配置说明；独立源码与实图复核支持测试跨角色切换后未同步toolbar.visible的残留解释，不能据此认定固定角色生产System布局缺陷。未修改测试或认证修复，旧帧保留；不称零视觉局限或全文同屏。主要来源／步骤／指标及新观察站无遮挡范围已接受；不是OS或陌生玩家验收。

69 的最终测试据此只增加一次 process_frame 后进入原 pre_draw，在真实接收边界检查未完成渐变和 capture-busy。请求前 step／scroll 必须保持，随后禁止切步、冻结渐变／滚动、恢复精确焦点、逐层Esc及作品字节保护继续保留。无轮询、flush、睡眠、手设标志或共享生产输入修改；新真实 renderer 四角色路径均通过，原fcad诊断仍是FAIL。

## 保护、来源与输入等级

从 PR10 main `bf8f61647c03c8bba868cc833b3832e274bd4aee` 到当前97516，明确选定的146个核心文件 Git blob 原字节相同；本证据作者独立重算当前 raw Git-object hash，146/146相同，路径／blob映射与69完全一致。新收据`.godot/f4-protected-core-parity-97516b2.json`的SHA亦已独立核对。它覆盖指定模拟／保存／内容／候选 Session 及模型路径，明确排除六个 mixed UI host，**不表示所有任务 host 或所有判定代码没改**，也不代替完整回归。

TargetGuidance 用原 Session 真实 train→lossless transport→逐次 commit/reveal→generate→save 建立已有作品，再关闭 writer；定位／反馈保护真实 session、作品／配方、game／workbench、草稿、导航及空 lease／recovery lock。这是隔离控制器准备，不是自然旅程完成证据。效率 pair 也是测试模式真实官方模型运行，不将参考完成导入玩家历史；不允许以造字典或改完成位代替。

headless、真实 renderer 控制器、未修改导出包、OS 输入和陌生玩家是不同等级。截图若由合法滚动定位后取得，只证明该路径可达，不声称按钮默认首屏同屏。原检出 `tests/test_ui.gd` 的既有删除由Root确认未动，不是本轮为通过门禁删除测试。

## 固定新包与原链通过；修复补充待运行

预定普通 batch／profile 为 `MeasuredGrowthExperience20261018`／`MeasuredGrowth20261018`；测试者为 `MeasuredGrowthAccess20261018`／`OfflineTeammate-MeasuredGrowth20261018`。普通新包构建／身份已通过，旧Creative包／profile保留。下列普通artifact已通过原父链及严格重启；旧克隆Measured补充仍为失败；普通128＋47、测试者138＋原child＋47及限定两角色观察站OS路线均已分别通过，当前修复补充仍未运行。

- 普通：[MeasuredGrowthExperience Windows ZIP](../../../build/playtest-MeasuredGrowthExperience20261018-97516b21f459/Von-Neumann-Bottleneck-Windows-playtest-MeasuredGrowthExperience20261018-97516b21f459.zip)，57,559,429字节，SHA256 `c09d24093e233b1019903bf94d0c3256061e555cf6d71463e0e56ff7f995a82d`。SOURCE97516，profile `MeasuredGrowth20261018`。7个内部payload、EXE／嵌入PCK、manifest、三说明身份及原构建日志已独立重算一致；原父128与strict47已全true／failures空、无ERROR，严格进程PID44200自然退出0，normal不使用六坐标转换。旧补充已真实失败；测试者原链与限定native结果另列，不得把这些成功扩成新修复补充或整阶段全绿。

- 测试者：[MeasuredGrowthAccess Windows ZIP](../../../build/playtest-MeasuredGrowthAccess20261018-97516b21f459/Von-Neumann-Bottleneck-Windows-playtest-MeasuredGrowthAccess20261018-97516b21f459.zip)，57,571,481字节，SHA256 `e8c4e5e0707c9114aac0f86834e10e127d79730daad673de9c16aa4e895ab8c6`。SOURCE97516、profile `OfflineTeammate-MeasuredGrowth20261018`；10个payload与ZIP／EXE／PCK／manifest哈希已独立核验。原父138／strict47均全true／failures空、无ERROR，strict进程31764自然退出0。实际随包收集器原child覆盖60入口／真实CPG准备及最终独立ZIP的4case／2session／0capture errors／0ignored；仅保原六CPU坐标类型转换，不放宽其它类型。

普通原父128及严格重开47现已分别通过；测试者原父138、严格重开47及随包收集器60入口／真实CPG控制器准备／最终离线ZIP链也已实际分别通过。之后显式 `--measured-evidence-from` 才复制成功重启后实际 QA 档案至新根，四环境目录隔离、原父收据／runtime前后全文件和目录集合不变。补充进程才运行参考CPU pair、失败方案和近看／还原；不能改写原父成功收据掩盖新失败。

普通实际原作品`67f5602f…`与其原Session SHA `20f4c259ad9101722a926577da6d3c14a73b1ca37b4af658e49704c08c4025d2`已独立核对磁盘输出／配方。它来自私有QA档案中的原Session合法操作，不随ZIP预装，也不是普通玩家自然全旅程。严格重启raw的typed game_state与12项文件／空锁状态等其post-exit baseline，无normal数值转换。

原作品必须真实存在，整 Session SHA与原输出／配方受保护。运行内严格快照与正常退出后保存时间戳／备份轮转分列；不得把前者扩成退出后全部文件字节恒同。只保留既有已明确记录的六个测试者CPU坐标编码边界，不能扩大数字类型容差。

原成功父链仍绑定97516原外QA `9fb11c3d…`／`fab52639…`与strict `7b9f5ff7…`。现行probe `736743c1…`在cb9e回合147GD通过，wrapper `9a3c7393…`该回合最终保护FAIL；新wrapper `b213d90b…`的固定11指针codec窄修已双独审通过、实际运行NOT_RUN，strict仍为原字节`7b9f5ff7…`。修复改走真实加载、原硬件连线／官方验收／封装及System合法前置，全程game模式；普通Targets保持原锁定NOT_RUN，测试者只用固定原权限。没有TestMode旁路、直接通关位或产品改动；旧父controller与新supplement controller分别记SHA。

为导出空间，Root与Visual逐Git blob双审后仅清理本段七处已结束候选的可再生docs副本，恢复1,659,851,509字节（四处952,616,012＋另三处707,235,497，不重复计更早单份239,210,065）；另当前普通97516已完成构建的5049个可再生docs副本经Root／Narrative逐blob双审后清理240,035,362字节，单列收据不与前述七份混计。原日志、帧、运行档案、作品、包和profile均保留。收据SHA在checks，旧source树不再称当前完整物化。

## 展示材料

[五条实机镜头脚本](../../distribution/showcase-shots.md)与[可编辑架构SVG](../../distribution/showcase-architecture.svg)已独立核对源码关系、链接及五张原字节实图：CPU／Layout来自69，System近看来自2c；当前普通97516父链的开场与原作品Window另有两张。五图均实际view并核原字节／来源receipt，前四张1280×720、作品Window864×496；System夹具为49任务，不改写成60。脚本可供团队录屏，当前没有已录视频；测试模式记录、滚动后的可达现场不冒充自然玩家或新包OS验收。

## 次日最多五项试玩／审阅

待本页出现实际已验 ZIP 后，先核 SHA，解压运行 Windows EXE；普通按原解锁进程，测试者开放入口不代表已完成。没有真实作品时从原工作台亲手创作，不导入QA通关档。

1. 在 Layout 原结果中，能否直接区分输出、周期、流量与空间哪项未满足，并由定位找到同一原证据？这句说明是否给了明确下一步，而没有替玩家改方案？
2. 在 Overlap 后一个 workload 才未达标时，下拉项、名称、周期和事件是否一致？编辑程序或 board 后，旧行号会否仍误导当前操作？
3. 取得两个合法官方CPU记录后，能否分清计算／等待／总周期、持平或变慢，以及“当前草稿”与“当时记录”？候选壹回应是否帮助理解？
4. 观察站近看／还原能否保持来源任务和原装置，且不被误认为实时电路／能耗测量？F8和逐层Esc是否仍能找回原位置？
5. 下一候选先完善CPG模型→揭晓→保存片段，还是当前实机镜头／可编辑展示材料？最终人物、CG、声线、结局、新人、Mac和真人旧作品仍需真实材料与审阅，不被本阶段永久排除。

原可替换接口沿既有 Texture2D／程序回退和原生字幕；新效率片段也是可缺图的候选呈现，不定稿人物或文明史。完整目标继续 ACTIVE，下一范围由Root结合实测和实际授权统筹。
