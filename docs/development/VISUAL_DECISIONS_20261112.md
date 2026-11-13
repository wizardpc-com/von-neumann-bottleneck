# 视觉方案与 Logo 待审清单 · 2026-11-12

供主创与队友对照选择；本文不确定最终美术，也不恢复已否决方案。核对基线为 `main` `329a484`，实际资源引用以本次源码检查为准。截图都是各日期的历史证据，未重新运行 Godot，不能据此认证当前画面、任务数、性能或原生输入。

## 现在实际接入了什么

| 部分 | 当前源码事实 | 查证入口 |
| --- | --- | --- |
| 首页 | 默认走实验室；`--classic-hub` 是旧首页，`--flat-lab` 才保留平面实验室。默认房间加载 `assets/lab/laboratory.glb`，叠加终端、进度、作品等真实数据表现。 | [入口开关](../../src/lab/lab_features.gd)、[房间装配](../../src/lab/lab_home.gd)、[模型与绘制](../../src/lab/lab_room_3d.gd) |
| 实验室构图 | 11/04 的暗墙、暖台灯、实体铭牌、设备架、四件作品预览已在当前房间脚本中；该文件最近的提交为 `b65a0bd`。不是仍停在10/19占位图。 | [11/04三轮说明及前后图](../verification/20261104-l1-lab-home/README.md#round-3---composition-and-finishing) |
| 工作台与元件 | 终端内沿用深色场与共用框架；电路符号和系统设备都引用 `component_visual_style.gd`。元件参考外形、元件栏／预览／落地一致性已有历史几何与渲染证据，但不等于团队已认可最终美术。 | [共用样式](../../src/hardware_foundations/component_visual_style.gd)、[电路符号](../../src/hardware_foundations/circuit_component_symbol.gd)、[系统设备](../../src/system_lab/system_device_surface.gd)、[10/22参考形状](../verification/20261022-component-reference-shapes/README.md) |
| 品牌 | `brand.cfg` 仍为 `placeholder-1`：只有芯片与箭头的游戏图标；中英 Logo、独立 symbol、Windows/Mac 原生图标字段全空。 | [配置](../../assets/branding/brand.cfg)、[现用SVG](../../assets/branding/game-icon.svg)、[项目图标引用](../../project.godot) |

## 可以并排看的新旧方案

这些是已实现的迭代与候选证据，不是可直接在游戏中切换的完整皮肤包。历史版本应从 Git 取证，不另复制版本目录。

| 比较项 | 较早方案 | 后续方案 | 这次请团队判断 |
| --- | --- | --- | --- |
| 实验室整体明暗与空间感 | [10/19明亮平面占位](../verification/20261019-lab-journey/lab-idle.png) → [10/23浅灰暖光3D](../verification/20261023-claude-final-polish/r3-after-room.png) | [11/04最终暗墙与台灯](../verification/20261104-l1-lab-home/r3-after-room.png)，[同轮英文](../verification/20261104-l1-lab-home/r3-after-en-room.png) | 更偏明亮温润，还是暗背景聚焦桌面？[风格约束v0.1](../briefs/20261019-lab/美术风格约束_v0.1.md)强调外部明亮、宽广，11/04明显压暗；这处张力需审阅，不能自动视为新方案已取代全部旧约束。 |
| 房间物件与标识密度 | [11/04轮三之前](../verification/20261104-l1-lab-home/r3-before-room.png) | [轮三之后](../verification/20261104-l1-lab-home/r3-after-room.png)：手册、旋钮设置、信件反馈、架体与铭牌 | 是否更容易发现入口？实体牌是否过多、像标签堆叠？暖灯、灰桌和作品墙是否协调？ |
| 唤醒终端后的主入口 | [10/23之前](../verification/20261023-claude-final-polish/r3-before-terminal.png) | [10/23之后](../verification/20261023-claude-final-polish/r3-after-terminal.png)：下一项任务卡、底部轻量链接 | 保留任务卡为中心的层级，还是需要调整布局？这是当轮对照，不能当当前完整交互验收。 |
| 元件外观与可辨识性 | [10/22重构前半加器](../verification/20261022-component-refactor/before/before-half-adder-zoom-100.png) | [当轮重构后](../verification/20261022-component-refactor/after/after-half-adder-zoom-100.png)，随后还有[用户再次确认的目标参考](../verification/20261022-component-reference-shapes/target-reference.png) | 参考图是美术输入，不是游戏截图；较早重构后图也早于参考形状修正。应在当前密集电路、不同缩放中检查辨识度与端口／名字位置，不能仅选一张旧图。 |
| 工作台浅／深色 | [同数据深色QA图](../verification/20261018-creative-framework/images/source2db6a95a4be8-qa6328a84e7ea9-workbench-dark.png) | [同数据浅色QA候选](../verification/20261018-creative-framework/images/source2db6a95a4be8-qa6328a84e7ea9-workbench-light-candidate.png) | 浅色仅QA候选，灰画布中仍有深色信号按钮和缩略图；不是全游戏浅色模式。先判断方向，再另定完整适配范围。[限制](full-journey-visual.md) |

**已否决，不应误列为待选：** 10/23 指示灯位格／滑动开关／发光灯的0/1电平新表示已按用户要求回退；[原交接](CLAUDE_FINAL_POLISH_HANDOFF_20261023.md)与[历史图说明](../verification/20261023-claude-final-polish/README.md)均明确保留原表示。除非主创重新要求，不恢复该方案。

同一原交接还明确回退了创造工作台统一13px字号下限：该方案会把1280×720下的状态行和运行按钮挤出画面。不要将它恢复为通用字号规则；后续可读性调整须同时检查完整布局与操作可达性。

11/04房间图中可见 `0/57`，10/23图中是 `0/60`；这里只比较视觉。不能据历史画面改写当前README的60项旅程口径，也不能将它们包装为本次新截图。

## 尚待审核的取舍

1. **整体基调**：先在上述两张3D房间图之间说明偏好及需保留的元素，再明确风格约束是否更新。不要让后续AI只凭“优化美术”继续叠加暗色、光效和装饰。
2. **视觉与功能是否同时成立**：手册、设置、反馈、旅程、档案、作品的入口能否被新人发现；物件名牌、悬停胶囊与角标是否重复；终端文字在最小窗口、英文、非16:9下是否清楚。11/04证据没有授予真人审美与跨GPU验收。
3. **元件方案**：以最新参考形状及共享绘制链为基础验收；主创曾指出“元件台与落地不一样”“外形又退回”，见[10/23交接](CLAUDE_HANDOFF_20261023.md)。旧截图不能回答当前是否已满足。保留真实电平、端口和位宽，审外形不夹带玩法更改。
4. **壹与剧情的视觉身份**：[现行交接](UI_YI_HANDOFF_20261020.md)明确尾随SVG是打字光标，不能当头像或Logo；独立视觉标识未定。[章节对话](UNIFIED_STYLE_HANDOFF_20261020.md)及[后续叙事交接](NARRATIVE_HANDOFF_20261021.md)保留候选／主创审阅边界。不要因它已出现在屏幕上就认定人物、CG、故事或声线已定稿。
5. **音画衔接**：CG到房间的暖光、进出终端的节奏、音量与声音身份仍需听看；静图与无头测试不能决定。范围见[最终打磨未验证项](../verification/20261023-claude-final-polish/README.md#未验证)。

## Logo 的历史问题、现状与下一次决定

本地Git能确认：`c57c702`（2026-09-13）建立品牌配置和可选Logo槽，`6c5c59d`完善 symbol、同语言标题回退、维护与打包检查；之后 `brand.cfg` 没有改成正式品牌素材。**这证明接入机制已建，不证明正式Logo曾获批或已装入游戏。** 未发现可据以确认“某款最终Logo已被认可、后来丢失”的仓库记录；若团队有外部稿件，应补来源与版本再比较，本文不猜测历史故障。

| 问题 | 本次可确认的情况 | 仍需人工决定／验证 |
| --- | --- | --- |
| 没有正式Logo | 中英文Logo与symbol为空，现用图标是自有芯片／数据箭头SVG；不是正式中英字标交付。 | 芯片图标继续作占位、发展为最终符号，还是另选方案？需要中文／英文横版与小尺寸图标的对应关系。 |
| 旧Logo接口能否覆盖新首页 | `BrandIdentity.title_slot()` 当前只在 `prototype_hub.gd` 的旧首页标题区调用；`src/lab/` 未调用它。默认实验室已是另一条呈现路径。 | Logo放在哪里：启动／CG、实验室实体标记、终端、设置、外部展示？应先定位置；不能宣称只填配置就会自动出现在默认实验室。 |
| 语言回退 | `brand_identity.gd` 按当前语言取图，缺图回退该语言标题，不借另一语言Logo顶替。 | 最小窗口中中文、英文的实际字形、留白、清晰度和焦点／点击是否正常。 |
| 桌面与导出图标 | 配置里原生ICO／ICNS仍为空；项目默认图标存在。检查脚本允许可选字段为空，因此PASS不等于正式品牌齐全。 | 正式交付时检查Windows EXE／任务栏与Mac app／Dock的小尺寸、缓存和导出结果。保留应用名、bundle标识及存档目录。[维护流程](final-maintenance.md#replace-the-future-logo-and-icon) |

`final-maintenance.md` 已区分核心40项与完整60项旅程，并限定现有标题Logo槽适用于旧首页。正式Logo接入默认实验室若需新增展示位置，应单独小范围实现与验收。

## 对外展示与本次核验范围

当前 [README](../../README.md) 已注明实验室等配图来自10/21–23、公开Alpha4固定于较早源码；这些图片不展示11/04暗墙、实体入口与作品墙新布局。后续对外材料应先决定展示“公开下载包”还是“当前源码”，分别给版本与截图，不混配。本文未检查在线网站、未修改发布包或宣传页面。

本次只读检查了资源引用、品牌配置、相关Git历史及文档，并实际查看了10/19、10/23、11/04三张房间原图；其余对照图提供来源链接，未逐张授予视觉验收。交付前检查本文所有本地链接存在与 `git diff --check`；未运行Godot、未开游戏、未重新测性能，未做Git提交／推送。

建议下一次由主创与队友共同看：两版3D房间、终端卡片、当前密集电路及小尺寸Logo。记录“保留／调整／否决＋原因”，再形成小范围美术任务；不要把本清单变成默认全选的改造计划。
