# 可选呈现的模态焦点边界 · 2026-10-18

本轮阶段 **ACTIVE_ENGINEERING_VALIDATION**，完整goal仍 **ACTIVE**。当前真实baseline源码`867ec81dc2718b4a1c8c636a246cd0788094e2f6`只增加有界QA，生产runtime仍逐字节等于F5产品`d14be32f81354eb062f38d39f860b16ff739921a`。本目录唯一记录本轮证据，不回写F5冻结结论。

## 当前门禁

- 原import／userdir／Efficiency三阶段实际3／3 PASS，3个自有进程自然exit0、零ERROR／WARNING／SCRIPT ERROR；headless为55检查，capture-only模态前提尚未在该次执行。
- 同源单Efficiency真实renderer **FAIL：239检查／4ERROR**，PID50104在29.99秒自然exit1，无终止、零WARNING／SCRIPT ERROR。六条原F8 accepted边界仍通过。修复、修复后renderer、完整回归及新包均未验。
- 24根帧＋2tester现场共26原PNG及6artifact、39运行文件、41目录已独立逐SHA／集合核对；这是数据审计，当前不宣称独立逐图接受。

摘要与原收据：

| 来源 | 原路径 | SHA256 |
| --- | --- | --- |
| 三阶段编译 | `.godot/f6-efficiency-compile-867ec81-summary.json` | `26e690114dc0d3d57bb3f4568986cdb56c87143ac6a911774f9d833ab41a0033` |
| 编译Root独审 | `.godot/f6-root-compile-audit-867ec81.json` | `d411399278754738520daac8109579393f25a14f942bb3a843e9aa662fd2d6e1` |
| baseline renderer | `.godot/f6-efficiency-baseline-867ec81-summary.json` | `3bf5eb96f4011b021fda6d65234b9fa89e3ddd818be1c393e32f72b62ef95ba9` |
| renderer原receipt | `.godot/f6-efficiency-rendered/2516362cb504/test_efficiency_fragment/receipt.json` | `dc9c57453a5a286bcbedccdac9c94d63678fe9941469569b7532ccf9675bfa3a` |
| renderer原log | `.godot/f6-efficiency-rendered/2516362cb504/test_efficiency_fragment/renderer.log` | `acf3820300b0cada5642610c3afd57ce4063bb7369d16066e3a0fa903a697ae7` |

## 实际失败证明了什么

两语各有实际AcceptDialog／Other按钮持焦、列于root嵌入子窗名单的强前提；native root同时`has_focus=true`。不能把这解释为子窗没夺焦，也不能要求native root和embedded子窗焦点互斥。

| 实际值 | 中文 | 英文 |
| --- | --- | --- |
| unfinished blend | 0→1 | 0→1 |
| 原step | 1→1 | 1→1 |
| pending原Scroll | 125→125 | 148→148 |

因此已复现失焦期间呈现渐变仍继续。两次原Host直接Esc的“body仍可见且authority精确”组合断言也失败；后续完整authority检查通过，但没有单独记录post-Esc body值。源码collapse路由只能解释候选原因，不能替代缺少的单项实测。滚动本次没有变化，不把未复现滚动问题写成已证缺陷。该Esc调用是现有System Host handler边界，不是OS输入。

当前证据支持小范围修复本组件的焦点判断，并以原强前提、原F8／capture busy、Scroll、退出／销毁和权威保护重新验证；不能据此改变共享反馈、模型、保存、任务阈值或顺带修改FirstLight。

## 固定输入与现有交付

716项固定输入逐SHA等于实际867 Git blob；175个canonical测试无extra，原route与UID在archive／执行project原字节存在。执行715项非配置文件精确；仅原verifier两条私有userdir与EOL例外。Renderer finally恢复原headless前配置SHA`9d750ee9…`，不冒称恢复任意仓库默认值。原live未知删除不由本作者恢复、删除或暂存。

[现有F5双ZIP与来源](../20261018-creation-connections/README.md)仍按原产品d14、独立profile、原176完整回归和双包父／child／严格重启范围使用；本轮新增边界不被旧PASS覆盖，亦不追改旧收据。F5原生为官方工具初始化阻断，零窗口观察／输入／截图；不能借旧F4原生或导出controller写本轮OS通过。

[60任务逐行源码盘点](../../development/night-journey-review.md)已在20c9515独立提交，60个唯一ID与133源码锚不等于60项实际解题或新人理解。[展示索引](../../distribution/showcase-shots.md)另行更新d14双包与五张实际包图，并区分六张源码代表图和旧F4；它不属于固定867运行输入，也不是已录视频。

所有精确来源、helper、检查数量和独审结论见[checks.json](checks.json)。本轮没有新原生、Mac、新人、正式美术／人设／声线／结局或成片验收，完整goal不因工程子阶段完成而关闭。
