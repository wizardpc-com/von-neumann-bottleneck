# 最终默认视觉 · 2026-11-16

本轮用户授权整合负责人决定美术方向。默认方案确定为**日光般明亮的陶瓷白实验室，连接石墨蓝灰的计算终端**。它延续10月19日的温和未来文明与10月23日浅色3D空间，保留后续有用的实体入口、作品与真实进度呈现。此前“等待团队逐项选定”的记录是历史状态，不再作为默认方案悬案。

## 对照与取舍

实际查看了以下原始历史图片。日期只标识设计来源，不作为当前构建验收。

| 来源 | 保留 | 不采用 |
| --- | --- | --- |
| [10/19明亮概念实验室](../verification/20261019-lab-journey/lab-idle.png) | 白色大面、低饱和蓝灰、温润安静、计算终端为视觉中心 | 平面占位几何、以旧图替代当前空间 |
| [10/23浅色3D实验室](../verification/20261023-claude-final-polish/r3-after-room.png) | 连续柔光、陶瓷桌体、真实透视与留白 | 灰墙发闷与局部过亮的生硬分离 |
| [11/04暗墙版](../verification/20261104-l1-lab-home/r3-after-room.png) | 档案／手册／反馈／设置的物件入口，作品小幅陈列，实际章节指示灯 | 大面积深墙、黄光池与金色边框共同造成的夜间书房气氛 |
| [Claude木质／暖日光版，固定分支提交](https://github.com/wizardpc-com/von-neumann-bottleneck/blob/e53b94682cbd26ddc26f57c86dd489071d5d777f/docs/verification/20261108b-A1/after-room.png) | 中英文铭牌适配、没有作品时不画虚假的光纹内容 | 木色桌面、棕地板、金色铭牌、额外窗框与踢脚线；这些细节把空间带向普通生活环境 |

最终实现只修改现有房间材质、灯光与呈现。原模型、相机轨迹、物件位置、三角拾取、焦点与返回路径保留。房间共用 `lab_palette.gd` 的浅色令牌，终端继续使用同文件的深色令牌；浅色背景不侵入计算画布。白色桌面与银灰边框统一材质，局部阅读灯用柔和白光，保留实体物件的功能辨识。环境光抬高暗部，屏幕仍是最清楚的对比中心。漂浮微尘由12个减至4个，减少装饰占比，仍服从减少动效设置。

实体铭牌使用浅底深字，悬停为深青色，英文按现有牌面的真实宽度缩放，不施加全局字号下限。作品墙只画实际提供的输出单元；空框仍可进入作品页，不构造默认作品或完成记录。完成灯、章数、生成输出与进度仍来自原有只读展示输入。

## Claude分支整合边界

核对视觉分支 `e53b94682cbd26ddc26f57c86dd489071d5d777f` 与缩放研究 `0f00fe057699d8b37c88901337b3656941b1a37d`。视觉分支并非纯素材补丁，包含工作台布局、输入路径、按钮尺寸与测试预期变更，不能整体替换已完成11月13日操作修复的主线。房间只选择性借鉴上述两项呈现改善，不保留 `WARM_ROOM` 多方案开关。

地图章节图形／柔和强调色、较浅的仪表阴影和统一按钮层级具有参考价值，应由整合线程在当前主线上逐项判断和验证。新增网格、纸张横线、边框层数不作为“更完整”的必需条件。缩放研究仅是比较材料，本次不合并其全局缩放策略；已否决的0/1表示重做和破坏布局的统一字号方案均不恢复。

## 品牌与替换

品牌素材由同轮独立任务通过 `assets/branding/brand.cfg` 管理；最终图形与双语字标的验收以该任务记录为准。房间的真实待机玻璃在顶部读取 `BrandIdentity.symbol_texture()`，使用32px、无输入焦点的独立符号；缺少图形时自然省略，不影响待机内容与拾取。终端的字标由整合线程接入。两处均读取配置，不将某一临时图形画死在场景中，也不将旧首页标题槽误记作默认实验室接入。

## 验证记录

当前修改通过定向静态差异及空白检查。主线程在隔离工程
`.godot/verification/20261116T093554Z-c091f96c/project/` 生成原始GPU图片；
视觉子线程逐张独立打开中文／英文房间的1280×720、1280×800与1600×900画面，
以及中英文1280×720终端和档案。**最终亮白房间与深色终端方案可定稿**：
主体、实体入口、待机内容及品牌符号完整，16:10未裁切主要物件；终端字标与
主动作清楚，英文页脚自然分为两行但入口完整。白桌局部高光较强，未遮蔽
入口文字或影响本轮操作信息，不据此继续扩展美术改造。

首轮截图驱动在重新创建Hub时保留了已唤醒终端状态，导致三张带room名称的
图片实际是终端；这是证据命名／状态准备问题，不能算房间验收。主线程随后
通过真实 `leave_terminal()` 路线返回，并断言房间状态后重拍。旧图保留在
`before-room-driver-fix/`，最终图在 `final-product-previews/`；
`gpu-room-corrected/test_final_product_presentation.txt` 记录修正后的通过结果。
本次最终结论使用重拍图片，不用旧错误截图补足覆盖。

真实拾取、减少动效、导出包及原生输入另由主线程的对应操作检查负责，
上述独立静图审查不替代这些验收，也不据单台Mac画面推断跨平台性能。

## Shared terminal surfaces adopted by integration

Root selectively adopts Claude's quieter floating-panel shadow/border and visible
focus/disabled button treatment, plus chapter accent palette. Existing button
minimum sizes, task-node text/geometry and all current workbench operation fixes
are retained. Completion panel uses the same small-radius, reduced-shadow surface.
Archive keeps the current clean reader rather than adding ruled-paper decoration.
Full wordmarks are placed in the actual awake terminal; room glass uses the same
configured symbol. Final raw render evidence follows in the release receipt.
