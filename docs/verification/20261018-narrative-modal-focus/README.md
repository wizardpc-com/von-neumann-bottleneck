# 可选呈现的模态焦点边界 · 2026-10-18

本轮阶段 **ACTIVE_ENGINEERING_VALIDATION**，完整goal仍 **ACTIVE**。当前修复SOURCE为`bb5c817bcb7e0c770fc65b41b7407e2847149a74`；旧baseline源码`867ec81dc2718b4a1c8c636a246cd0788094e2f6`仅新增QA，其runtime等于F5产品d14，原FAIL保留。本目录唯一记录本轮证据，不回写F5冻结结论。

## 当前门禁

- 修后bb5原import／userdir／Efficiency三阶段实际3／3 PASS，3个自有进程自然exit0、零ERROR／WARNING／SCRIPT ERROR；headless为55检查。旧867编译3PASS另保原来源。
- 修后bb5单Efficiency真实renderer **245检查PASS**，PID21700在30.58秒自然exit0，无终止、零ERROR／WARNING／SCRIPT ERROR。实际正控制ZH0→42／EN0→110且source／step／metric在原clip内；同0起点模态负控制Scroll0／blend0／step1保持，Esc分项bodytrue／authoritytrue／mapfalse。六条原F8 accepted边界通过。完整回归实际176／176 PASS；新包仍NOT_RUN，不扩张为native或导出包模态通过。
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

该次5783项完整Git归档身份逐blob核对，5067项docs不物化，716项固定输入及715项执行非配置文件精确；175个canonical测试完整，原verifier仅排除`test_recovery_game_input`，route与UID原字节存在。执行副本末`project.godot`只保留原verifier最后一项私有userdir配置与Windows EOL，SHA `a832035052e1bd78fa0d56b78f6b53b997bf1e114041b7754fe5c86c39046f8b`；不声称headless finally恢复。Root已live核[bb5 CI39097738231](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/39097738231) completed SUCCESS，CI不代包或OS验收。新双包构建／父链／collector／严格重启仍NOT_RUN。

剩余scope独立审计`.godot/f6-independent-remaining-scope-audit.md` SHA `30598937e3819af66f393ef7fcb1af276e3323be49c6a14bc1017afa558e43dc`未发现应另开功能实现的已证缺口；后续分列最新包与交接闭环、官方原生／异机Mac实测、真人理解与正式创作／赛事取材。现有真实图＋精确脚本可承载展示候选，不把未录视频自动升级为新CG或新系统任务；所有ideas并未因此正式定稿，完整goal继续ACTIVE。

## 固定输入与现有交付

历史baseline867的716项固定输入逐SHA等于其实际Git blob；175个canonical测试无extra，原route与UID在archive／执行project原字节存在。该轮执行715项非配置文件精确，仅原verifier两条私有userdir与EOL例外，renderer finally恢复该轮headless前配置SHA`9d750ee9…`。本轮修后bb5另核其716项实际Git blob／715项执行非配置文件，同样仅原私有配置／EOL例外；finally恢复本轮headless前配置SHA`af5380a6…`。两者不混为同一配置，也不冒称恢复任意仓库默认值。原live未知删除不由本作者恢复、删除或暂存。修后bb5的同一716输入与私配置例外另有新实际核对。

原146固定core／contract路径经实际bb5 Git对象与main bf8原字节独审相同，收据`.godot/f6-protected-core-parity-bb5c817.json` SHA `e9c4e8ed0df939056175b30805d8b3a4915f51c68b4b6f3889c0ba6d7b9c0db5`；保留原六mixed UI host排除，SystemLab呈现／新文件也不在该固定集合，不能泛称所有src或判定代码未改。

[现有F5双ZIP与来源](../20261018-creation-connections/README.md)仍按原产品d14、独立profile、原176完整回归和双包父／child／严格重启范围使用；本轮新增边界不被旧PASS覆盖，亦不追改旧收据。F5原生为官方工具初始化阻断，零窗口观察／输入／截图；不能借旧F4原生或导出controller写本轮OS通过。

[60任务逐行源码盘点](../../development/night-journey-review.md)已在20c9515独立提交，60个唯一ID与133源码锚不等于60项实际解题或新人理解。[展示索引](../../distribution/showcase-shots.md)另行更新d14双包与五张实际包图，并区分六张源码代表图和旧F4；它不属于固定867运行输入，也不是已录视频。

所有精确来源、helper、检查数量和独审结论见[checks.json](checks.json)。本轮没有新原生、Mac、新人、正式美术／人设／声线／结局或成片验收，完整goal不因工程子阶段完成而关闭。
