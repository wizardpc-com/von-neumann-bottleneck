# 可选呈现的模态焦点边界 · 2026-10-18

本轮阶段 **ACTIVE_ENGINEERING_VALIDATION**，完整goal仍 **ACTIVE**。当前修复SOURCE为`bb5c817bcb7e0c770fc65b41b7407e2847149a74`；旧baseline源码`867ec81dc2718b4a1c8c636a246cd0788094e2f6`仅新增QA，其runtime等于F5产品d14，原FAIL保留。本目录唯一记录本轮证据，不回写F5冻结结论。

## 当前门禁

- 修后bb5原import／userdir／Efficiency三阶段实际3／3 PASS，3个自有进程自然exit0、零ERROR／WARNING／SCRIPT ERROR；headless为55检查。旧867编译3PASS另保原来源。
- 修后bb5单Efficiency真实renderer **245检查PASS**，PID21700在30.58秒自然exit0，无终止、零ERROR／WARNING／SCRIPT ERROR。实际正控制ZH0→42／EN0→110且source／step／metric在原clip内；同0起点模态负控制Scroll0／blend0／step1保持，Esc分项bodytrue／authoritytrue／mapfalse。六条原F8 accepted边界通过。完整回归实际176／176 PASS；新普通／测试者包均BUILD_IDENTITY_PASS；普通父流程原FAIL及新LOG-ONLY诊断FAIL_TIMEOUT分列，strict未启动；测试者父／child与新包图审待实际验收，不扩张为native或导出包模态通过。
- 旧867真实renderer **FAIL：239检查／4ERROR**、PID50104自然exit1，保留其两语fade与Host Esc组合断言失败，零WARNING／SCRIPT ERROR。
- 新旧两轮各24根帧＋2tester现场＝26原PNG，以及各自6artifact／39运行文件／41目录均已独立核SHA／集合；两轮各26图另依eb47／e1c6收据按原Scroll局限独立实view接受。两轮均零modal blocker图，不由图片认证fade／Esc。

摘要与原收据：

| 来源 | 原路径 | SHA256 |
| --- | --- | --- |
| 三阶段编译 | `.godot/f6-efficiency-compile-867ec81-summary.json` | `26e690114dc0d3d57bb3f4568986cdb56c87143ac6a911774f9d833ab41a0033` |
| 编译Root独审 | `.godot/f6-root-compile-audit-867ec81.json` | `d411399278754738520daac8109579393f25a14f942bb3a843e9aa662fd2d6e1` |
| baseline renderer | `.godot/f6-efficiency-baseline-867ec81-summary.json` | `3bf5eb96f4011b021fda6d65234b9fa89e3ddd818be1c393e32f72b62ef95ba9` |
| renderer原receipt | `.godot/f6-efficiency-rendered/2516362cb504/test_efficiency_fragment/receipt.json` | `dc9c57453a5a286bcbedccdac9c94d63678fe9941469569b7532ccf9675bfa3a` |
| renderer原log | `.godot/f6-efficiency-rendered/2516362cb504/test_efficiency_fragment/renderer.log` | `acf3820300b0cada5642610c3afd57ce4063bb7369d16066e3a0fa903a697ae7` |

## 历史baseline失败证明了什么

两语各有实际AcceptDialog／Other按钮持焦、列于root嵌入子窗名单的强前提；native root同时`has_focus=true`。不能把这解释为子窗没夺焦，也不能要求native root和embedded子窗焦点互斥。

| 实际值 | 中文 | 英文 |
| --- | --- | --- |
| unfinished blend | 0→1 | 0→1 |
| 原step | 1→1 | 1→1 |
| pending原Scroll | 125→125 | 148→148 |

因此已复现失焦期间呈现渐变仍继续。两次原Host直接Esc的“body仍可见且authority精确”组合断言也失败；后续完整authority检查通过，但没有单独记录post-Esc body值。源码collapse路由只能解释候选原因，不能替代缺少的单项实测。滚动本次没有变化，不把未复现滚动问题写成已证缺陷。该Esc调用是现有System Host handler边界，不是OS输入。

据此已实施本组件纯焦点判断与原Host展开fragment分支的窄修；实际修后范围见下。共享反馈、模型、保存、任务阈值与FirstLight未随之修改。

## 修后独立实测

修后三阶段摘要`.godot/f6-efficiency-compile-bb5c817-summary.json` SHA `8b0749a8060be2bfadae4bdb340cd354b6355015dcd5e35a3904a1d2df7e67a8`；真实renderer摘要`.godot/f6-efficiency-rendered-bb5c817-summary.json` SHA `b0fdf1edbb4333607775f5642dc1ee3e0baaf90293550f500e42aec5fea86c5f`。原receipt `ddabeeed…`与log `bc9158d3…`、全部26PNG／6artifact／39文件／41目录及716source／715非配置文件、finally原配置`af5380a6…`均已独立重核。

本次正控制不是旧125／148不变的重述：从原Scroll0主动展开确实移动42／110，随后同Scroll0在真实Other模态持焦时未移动且未完成渐变不推进。两语Esc实际分别打印body可见、权威未变、map未开；这些是本次新实测，不回填旧组合断言缺失值。两组模态均embedded，native OS失焦仍未验。

旧26图独审收据`.godot/f6-efficiency-baseline-visual-audit.json` SHA `eb47ae1bc53702d1b6ece4a448b362b9d0dc67f010ed786f31300e1a086f534b`仅图scope通过，未拍AcceptDialog，不能把图片说成模态复现或将旧FAIL改判；修后26图独立实view收据`.godot/f6-efficiency-repair-visual-audit.json` SHA `e1c6ba7d49b8468e84c5025a61077e4d4304e72166811668d1b0e2afa027ed2e`按原Scroll局限接受；24图与旧基线逐字节相同，两tester面板为时间戳差异，不是新美术／布局改进。仍无modal截图，fade／Esc结论来自实际controller日志。

## 最新完整回归与剩余范围

bb5原完整Windows回归实际 **176／176 PASS**（174原headless测试＋import／userdir），176条有序自有进程记录均自然exit0；实际169个不同PID，7个PID各复用两次。全部176原日志与命令／结果／SHA已独立核对：零ERROR／SCRIPT ERROR，原anchor WARNING共6条（desktop_conventions 4、feedback_presentation 2）。摘要`.godot/f6-full-bb5c817-summary.json` SHA `d480295a468bfe07984240706ce19fcde4a7ddf80e05217d1f5ff40b14208758`；results SHA `e734a963dbc6d9960f6df348b8024098ae2f05a3685cc53fa9f252c7d5fc5fd9`、owned SHA `9790071abca52702adeddd068bf3adc3db716444b12e975195058cfb9884fa8e`。

该次5783项完整Git归档身份逐blob核对，5067项docs不物化，716项固定输入及715项执行非配置文件精确；175个canonical测试完整，原verifier仅排除`test_recovery_game_input`，route与UID原字节存在。执行副本末`project.godot`只保留原verifier最后一项私有userdir配置与Windows EOL，SHA `a832035052e1bd78fa0d56b78f6b53b997bf1e114041b7754fe5c86c39046f8b`；不声称headless finally恢复。Root已live核[bb5 CI39097738231](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/39097738231) completed SUCCESS，CI不代包或OS验收。新双包构建身份见下；普通父流程实际FAIL，strict未启动；测试者父／collector／严格重启尚未执行。

剩余scope独立审计`.godot/f6-independent-remaining-scope-audit.md` SHA `30598937e3819af66f393ef7fcb1af276e3323be49c6a14bc1017afa558e43dc`未发现应另开功能实现的已证缺口；后续分列最新包与交接闭环、官方原生／异机Mac实测、真人理解与正式创作／赛事取材。现有真实图＋精确脚本可承载展示候选，不把未录视频自动升级为新CG或新系统任务；所有ideas并未因此正式定稿，完整goal继续ACTIVE。

## 新双包构建身份（尚非试玩验收）

两包均由原builder固定bb5生成，import／licenses／export-Windows三阶段及原identity检查实际通过，尚未由此确认父流程、严格重启、collector或导出模态通过。普通新父流程已实际FAIL，详见下节；测试者父流程、collector与strict尚未执行。20原PNG已核文件SHA，尚无全部新包独立图审；已观察的名为feedback帧并不能由文件名认证面板出现。

| 角色／独立profile | 当前构建ZIP | ZIP SHA256 |
| --- | --- | --- |
| 普通／`CreationLinks20261018` | [ModalFocusExperience20261018](../../../build/playtest-ModalFocusExperience20261018-bb5c817bcb7e/Von-Neumann-Bottleneck-Windows-playtest-ModalFocusExperience20261018-bb5c817bcb7e.zip) | `3bbefa7e0918ba333736fda61efd51e96746d68b1e2289ff3cd9cd687af640c4` |
| 测试者／`OfflineTeammate-CreationLinks20261018` | [ModalFocusAccess20261018](../../../build/playtest-ModalFocusAccess20261018-bb5c817bcb7e/Von-Neumann-Bottleneck-Windows-playtest-ModalFocusAccess20261018-bb5c817bcb7e.zip) | `dc8164dc0aa8b4cc693466a6e3af1219eb4156f681ba0dc06cda0fc8d3ace8c0` |

普通构建摘要`.godot/f6-normal-build-bb5c817-summary.json` SHA `ceb800c13418dc18de1516bb7bc6650173ce707c7ec562b158cc38c83954c20b`；测试者摘要`.godot/f6-tester-build-bb5c817-summary.json` SHA `c5995f0f6bbd0c0cd6b67bf17eeecb59f1d9023d16a0f344993db1846c3ae2cb`。两包全部ZIP成员／BUILD-MANIFEST／EXE／内嵌PCK及478资源哈希已独立核对；测试者仅含原collector `d0de7376…`。无端点、公网Release或QA存档注入；旧d14实际可用链仍保留恢复身份。

两份新生成candidate `project/docs` 各5067文件／242287926字节，逐bb5 Git原字节与完整目录集合双审后，仅这两份可重建副本由Root移除，共484575852字节；原仓库全部5067项docs存在，包、日志、runtime、PNG、存档与失败收据未删。清理收据为`.godot/f6-normal-docs-cleanup-bb5c817.json` SHA `5d6cf5e1db34977125defcb103d565e81d3a6a2a033611a66b786e477b6c21e3`及`.godot/f6-tester-docs-cleanup-bb5c817.json` SHA `54ca88fa70ccc73d53ca154cea823bf10741aecee89f9e402de4b27c5f20a3c9`；不再称这些已清理candidate源码树完整物化。

PR15正文已获用户明确授权，由Root更新并readback按行尾规范化完全一致，仍draft／OPEN且未合并或Release；记录`.godot/pr15-body-update-20261018.json` SHA `1ad5101f9b5aa36633c28b977f10af8924c40c05a0ab38c60c987a38d62ef822`。该事实不替代本轮bb5包验收。

## 新普通父流程实际失败（原收据保留）

实际work `.godot/night-package/d2f1b4c78ab1`，固定bb5产品／原probe40b／wrapperb213。父进程PID21788自然exit1，监视器未终止，0SCRIPT ERROR／WARNING；219项中216true、3false。首错“role F8 owns actual Host viewport and panel focus”，随后“second focused Escape collapses only optional review”及“Journey closes Host and returns to map”复合断言失败。没有成功父receipt，strict **NOT_RUN_PARENT_FAILED**；测试者链亦未执行。双包BUILD_IDENTITY_PASS、源245 GUI与176 full各保原范围，不被这次失败抹去，也不代父验收。

失败摘要`.godot/f6-normal-parent-strict-bb5c817-summary.json` SHA `a9466dccef734746a0de9f9968e4bcd4ef9f2ef8fbd93e1ba140be9c2d32cf43`；raw `embedded.json` SHA `beac7bcb42f3c4697fc1ccf1f0e18fff53107cee37547d3d450a0fb991508679`，log SHA `62a0b06ce37ffef8e28df79c2c0444527baad4963bb5280e40b19c9822ac30e9`。20根PNG／0incident及runtime文件集合已实际重hash；其中`cpg-connection-feedback.png`现场观察为G回顾、没有可见反馈面板，此图不证明F8各分项或原因。Visual四图独审收据`.godot/f6-normal-failed-focus-visual-audit.json` SHA `6cb61639c588b25bfb8d8f6f8bbb6377214730b31bf6e24f00cec4cb22d6767a`仅接受实际静图范围，不改三项FAIL。

首断言没有分项记录panel可见性、viewport与focus owner；后续两个复合断言也未分别打印body／focus、host有效性／current scene。首Esc焦点恢复、35项纯回看权威、退出lease释放／Session SHA等原检查为true；实际磁盘完整Session／单作品recipe/output／五supports与真实prepared_data严格typed一致，主备仅顶层保存时间戳／原轮转，其余typed payload等rawgame，包字节与原保护文件保持。以上不将整体验收转PASS，亦不据源CPG相同就断定QA、OS或Efficiency修复为原因。Root核准的同步LOG-ONLY诊断已另跑并timeout，见下；没有改动作／Input／await／断言或据此归因旧三错。

## 独立LOG-ONLY诊断：实际180秒超时

产品仍bb5原ZIP；外QA检查点`3ad86b5c0dde2de6c7df4a700f983aaca0968b27`仅probe `c73bc23d…`同步读日志与monitor新SHA pin，wrapperb213／strict2e1原字节。实际work `.godot/night-package/d573d9d52fd2`，PID25692被原180秒guard定向timeout终止、exit1，**不是自然退出**。0ERROR／SCRIPT ERROR／WARNING，但缺`embedded.json`和成功receipt，**本次219项计数不可得，不能写全通过**；strict为NOT_RUN_PARENT_TIMEOUT。

摘要`.godot/f6-normal-diagnostic-parent-strict-bb5c817-summary.json` SHA `333b19c61249bc9cad59cac8ad3a4bca4ecac37107315713729f1eb12e40413d`；原log SHA `aec145a28409b1fcc728a4230158f740846a8dc151b94d2cab7f17a0a26b291d`，owned SHA `12bab534bdb509a680ef390b625f5f40f47a0324d9e40a798804f14512eb4a51`。六同步JSON实际分项为：F8后面板可见／同root viewport／面板内owner／feedback flag均true；首Esc恢复step1，第二Esc折叠并归toggle焦点；leave前dirty与pending均false，leave后原Host已释放且场景为TaskTree。这些只属于本次快照，不回填或解释前次三项FAIL。

17根PNG／0incident、实际runtime与四env文件／目录集合均已独立重hash；saved-work文件存在不证明后续哪条await已完成。 Visual图审`.godot/f6-normal-timeout-visual-audit.json` SHA `90712e148421cdab6a22c670be96deb1e9859cf06e52825e453c1cd5a6f28748`核17文件header／hash、实际view4张；本run普通反馈Panel可见，Saved仅原快照／无生成事件，不借旧journal图，不由最后一图定位stall或认证全authority。实际Session897f／单作品／五supports与旧失败运行prepared_data全typed相同，lease均不存在，仅属跨run资料；本次最终全authority快照未落盘，不能借旧快照认证本次全部零写入。包身份仍原SHA，override finally已删。原probe此时尚在父进程Journal／saved-work回看，独立reopen尚未启动；根因未定，仅提出在原等待点前后同步print机械定位，不延长timeout、不改guards／Input／断言、不自行重试。

## 固定输入与现有交付

历史baseline867的716项固定输入逐SHA等于其实际Git blob；175个canonical测试无extra，原route与UID在archive／执行project原字节存在。该轮执行715项非配置文件精确，仅原verifier两条私有userdir与EOL例外，renderer finally恢复该轮headless前配置SHA`9d750ee9…`。本轮修后bb5另核其716项实际Git blob／715项执行非配置文件，同样仅原私有配置／EOL例外；finally恢复本轮headless前配置SHA`af5380a6…`。两者不混为同一配置，也不冒称恢复任意仓库默认值。原live未知删除不由本作者恢复、删除或暂存。修后bb5的同一716输入与私配置例外另有新实际核对。

原146固定core／contract路径经实际bb5 Git对象与main bf8原字节独审相同，收据`.godot/f6-protected-core-parity-bb5c817.json` SHA `e9c4e8ed0df939056175b30805d8b3a4915f51c68b4b6f3889c0ba6d7b9c0db5`；保留原六mixed UI host排除，SystemLab呈现／新文件也不在该固定集合，不能泛称所有src或判定代码未改。

[现有F5双ZIP与来源](../20261018-creation-connections/README.md)仍按原产品d14、独立profile、原176完整回归和双包父／child／严格重启范围使用；本轮新增边界不被旧PASS覆盖，亦不追改旧收据。F5原生为官方工具初始化阻断，零窗口观察／输入／截图；不能借旧F4原生或导出controller写本轮OS通过。

[60任务逐行源码盘点](../../development/night-journey-review.md)已在20c9515独立提交，60个唯一ID与133源码锚不等于60项实际解题或新人理解。[展示索引](../../distribution/showcase-shots.md)另行更新d14双包与五张实际包图，并区分六张源码代表图和旧F4；它不属于固定867运行输入，也不是已录视频。

所有精确来源、helper、检查数量和独审结论见[checks.json](checks.json)。本轮没有新原生、Mac、新人、正式美术／人设／声线／结局或成片验收，完整goal不因工程子阶段完成而关闭。
