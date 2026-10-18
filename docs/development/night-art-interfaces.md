# 夜间视觉候选与素材接口

本轮默认候选为深色「安静工作台」：低饱和青灰、平面控件、稀疏定位点。
浅色「安静空间」以灰白纸面、深青文字表达同一份数据，供团队并列判断。
两者均为可替换候选，未认定为最终色板或真人验收结果。

## 稳定接缝

| 接口／资源 | 用途 | 尺寸／状态 | 来源与接入 |
| --- | --- | --- | --- |
| `src/ui/instrument_theme.gd` · `apply_to(theme, light = false)` | 共享按钮、输入、列表、弹窗、面板和滚动条 | 保持现有内边距与字号；正常、悬停、按下、禁用、键盘焦点；选中列表有加粗左边线 | Godot 原生 `StyleBoxFlat`，本仓库程序绘制；浅色参数用于独立比较，未新增用户设置 |
| `InstrumentTheme.primary(button, accent)` | 默认深色页面的主要行动 | 保持原调用签名；含独立禁用填色和深色焦点框 | 程序绘制；替换强调色时同时检查文字与焦点对比度；浅色比较使用普通按钮 |
| `src/ui/technical_backdrop.gd` · `light` | 静态、输入透明的底景 | 铺满所在 Control；任意窗口尺寸；无时间／仿真依赖 | 程序绘制，免外部素材；可替换为等尺寸非交互背景，勿叠在线路或端口上 |
| `src/ui/ui_typography.gd` 与 `assets/fonts/interface_*.tres` | 标题、正文、按钮层级 | 标题 26／34，正文与按钮 16，说明 14；控件高 42／44 | 保留现有随包字体及许可，未替换字体或缩小正文 |
| `tests/test_instrument_theme.gd` | 同数据深浅比较场景 | 运行、选中、焦点、禁用、输入、1 位／4 位列表；中文／英文；720p／1080p／16:10 | 真实 Godot 控件渲染的验证场景，不作为玩家页面，不代表完整关卡 |
| `src/ui/yi_introduction.gd` · `media_texture: Texture2D` | Yi导入的可替换档案图；原生Goal／操作文字和Begin／Skip独立保留 | 148×64逻辑预览，保持比例居中；null或0尺寸隐藏整列，文字继续显示；默认图须存在才load | 默认`assets/narrative/yi-learning-fragment.svg`为仓库程序矢量候选，无外部照片、正式人设或烘焙UI正文；替换资源需附作者／来源／许可／AI辅助说明 |
| `src/ui/first_light.gd` · `preview_texture: Texture2D` | ThemeReflection内可选「第一束光」虚构回顾 | 最小100逻辑像素高画布，按比例居中缩放；原图为3:1横幅；null或0尺寸采用程序三节点几何；字幕与Input1／NOT／Output0原生显示；图片静态，原约3秒回顾、低动效、跳过／重播保留 | 默认`assets/narrative/first-light-quiet-space.png`为原创AI辅助临时空间候选，仅初始化时尝试加载；缺资源或无法取得有效纹理时沿用几何。图片不表示电流／能耗或NOT输出；未定稿角色／历史，来源与生成提示见下 |
| `src/ui/efficiency_fragment.gd` · `media: Texture2D` | System原History有效CPU比较旁的可选插画；原chart、source、三步、metric与回应仍为独立原生控件 | 画区最小高72逻辑像素，按比例居中缩放；null或0尺寸回退为程序档案几何；不绘制历史事件、现实节能或新成果 | 默认无图片资源。实际宿主`src/system_lab/system_lab.gd:_build_history_instrument`创建并挂接`efficiency_fragment`后，可将已载入的Texture2D直接赋给`efficiency_fragment.media`；setter同步到`image.media`并重绘，无需改运行／比较／反馈交互。素材须附作者／来源／许可／AI辅助说明，不含烘焙正文或技术数值；有效Texture的实际像素正例尚未验证，不借缺图／零尺寸fallback结果认证 |
| `tests/test_workbench_palette_comparison.gd` | 同真实教程、同数据的完整工作台深浅比较 | 两语×三尺寸×两处理共12帧目标；冻结前原滚动定位输入、停车清理悬浮提示；精确矩形与状态必须相等 | 浅色为QA候选仪器表面；原线／端口几何保持，信号按钮和元件缩略图保持深色，实际候选画布中性灰；不是生产全局主题 |
| `experiments/creation/work_focus.gd` · `configure(saved_snapshot, english, {})` | Journal查看原保存输出、配方、来源；不是CG或生成重播 | 原窗口默认1080×620、最小640×420，沿原scroll看完整符号；A●／B■／C▲／D◇保留非颜色辨识；空evidence禁Locate，Journal禁fork | 原`work_canvas.gd`程序绘制真实保存格；不新增图片／角色资源，不替作品作审美评分；F3反馈输入链另验 |
| `experiments/creation/cpg_connection_fragment.gd` · `media: Texture2D` | 可选 C／P／G／已保存作品四步中的静态连接插画；不承载数据或操作文字 | 画区最小高58逻辑像素，按比例居中缩放；null或0尺寸回退为程序三结点几何；入口、步骤与定位按钮最小高36；scope／identity 14、summary／回应16、详情14，均为原生文字 | 默认无图片资源或外部素材；有效Texture只替换连接隐喻。交付图需保留作者／来源／许可／AI辅助说明与可编辑原件，不含烘焙正文、按键、技术数值或虚构成果 |

焦点以独立轮廓显示；按下／列表选中以左边线粗细显示，避免仅靠颜色区分。
底景不使用透视网格或移动粒子，不能被解释为电路距离、信号路线或延迟。
真实线路的线宽、插口形状、位宽徽章和连接几何保持原系统负责。

## 覆盖范围与素材交接

主题已接入现有首页、原章节共享工作台和术语手册的主题调用。
各宿主直接覆盖的专用卡片、章节强调色、端口、信号及创作领域专用主题继续由对应文件负责；
浅色比较不是整款游戏的浅色模式。不要批量替换所有青色，否则会混淆信号含义。

队友可交付背景、面板九宫格或按钮状态图；应分别给正常／悬停／按下／禁用／焦点的
透明素材及切片边距，并保留作者、来源、许可和 AI 辅助说明。素材尚未提供时沿用程序绘制。
新纹理不能改变最小点击面积、中文换行空间、焦点可见性或可读的技术数值。

## 复核入口

主线程在隔离 QA 副本中运行 `test_instrument_theme`，检查常规文字至少 4.5:1、焦点至少 3:1
及状态切换几何。真实渲染比较以该测试的 `-- --theme-capture --capture-locale=zh_CN
--capture-size=1280x720` 开启；英文为 `en`，另测 `1920x1080` 与 `1440x900`。
每次同一输入生成 `user://night-theme-{dark,light}-{locale}-{width}x{height}.png`。
正式验收记录由主线程写明命令、截图、退出码及未运行项；本接口文档不宣称已执行。

团队比较时先看数据、焦点和禁用状态是否清晰，再判断哪种空间更安心。
还需在首页、真实电路、手册和结果叠层检查硬编码颜色与新主题是否协调。

## F2素材与验证状态

以下ec3／157e／2db／241段按当时收据保留；当前普通包结果见本节末段，测试者与原生以最终验证记录为准。

两个Texture2D接缝已落源码，原生文字不由图片代替。替换图宜不含正文、按键或技术数值，
应提供透明边缘与原始可编辑文件；正式人物、CG、语音和结局演出尚无定稿，本表不授予
新增历史／成果或音频能力。缺图始终可继续原流程，不能添加素材前置。

固定`ec3aac94`当时通过61项headless检查，完整12帧渲染在该时点尚待；后续见本节末段。
同源`d76964080874/test_first_light`的12张实际popup帧已独立目视并逐hash核验：
650×480画面中，真实Play后自动定位的程序画布、完整原生字幕、Skip和固定返回可见。
这是两语三根窗口配置下的字幕压力fixture（`theme.entry`／`theme.build`），不证明CPU成果。
该旧suite随后在`window_lifecycle(host)`因已释放实参中止，该轮为FAIL，后半生命周期未执行；
这些帧不能代替整renderer通过。Yi媒体和完整工作台的后续独立渲染范围见下段，不能覆盖此FirstLight失败。

固定`157e3ef8`的`5bddc172f5ae`已独立检查Yi媒体／缺图12帧与工作台深／浅12帧，
全部原图SHA与各receipt匹配；两suite分别208／129项、自然退出0且无engine ERROR。
Yi的Goal、Begin／Skip及返回在两语三尺寸清楚，缺图继续纯文字原流程。
工作台是合法滚动后的同数据候选比较，实际灰画布与深色信号／元件岛如实保留。
该阶段浅色旧帧的手册入口有浅字白底缺口；当时局部QA修及4.5:1检查待新固定源，
不据旧矩形／状态通过宣称所有文字可读。该157e轮FirstLight `b29f5323941d`因Window fixture
engine ERROR，该旧轮严格判FAIL；当时包图、修后生命周期与人审未闭合，后续结果见末段。

随后固定`2db6a95a`：FirstLight `89ecc7b871b0`完整173项、自然0／无ERROR，
实际Play及静态原生字幕、Skip／返回可见，合法Window生命周期也已通过controller门禁；
仍是压力字幕fixture，不能替CPU完成、实际包或OS试玩。
工作台`6328a84e7ea9`完整135项、新12帧逐张目视／hash过；手册入口局部字体色已清楚，
六组正常态实际4.5:1通过，原状态／几何不变。此为QA候选修，原生产默认不变。
该2db轮F3六张图可见必要操作与来源，但首normal Esc门禁FAIL，后半未执行；
当时同Window窄桥源审后待实际验证；后续见末段，不将该图审当输入层验收。

F3随后固定`241751c4`的`905a46d13047`已完整172项controller GUI通过、自然0／无ERROR。
六张两语三根窗口配置的1080×620作品主图经独立目视及hash复核，与修前主图逐字节相同；
反馈／逐层Esc、焦点、销毁复用及拒存救援均已执行，旧139项失败仍保留。另四张为反馈前
现场采图，非面板或OS证据。该241时点整合full／新包与人审未闭合；当前c109结果见末段。

最终视觉精选现包含c109普通实包三张原字节帧：导入Texture（1280×720）、真实教程完成后
生产Journal主题回顾（520×384）、合法embedded controller setup的原作品（864×496）；
另两张为2db同数据QA深／浅工作台1280×720。均已实际查看，不修图、不冒作OS或新人证据。
普通c109 `fb44325711b2`父128与独立同profile重启47项全通过，ZIP／EXE／PCK／controller／
profile与不可变baseline链经独立核验；完整Windows headless另为172／172阶段通过。
浅色仍是候选比较；作品入口不赋予新创作权，固定NOT图不作物理测量。实际包popup按
1600×900逻辑画面到1280×720缩放，表中接缝尺寸是逻辑尺寸，截图像素另列。
精选图、完整SHA和tester／native最终范围见`docs/verification/20261018-creative-framework/`，
本接口表不将普通链结果推广到测试者或OS验收，亦不定稿人物／CG／声线或结局。

本次冻结范围：普通c109 128＋47已核通过；新测试者链再验中，原生待验。其最终结论
由验证README／checks维护，旧阶段失败和原始来源保留，不作当前失败状态或覆盖后来结果。

## F5连接片段的素材约束与画面范围

片段默认折叠，四步由玩家手动选择；普通与低动效设置均为静态，不自动推进或播放。
`scope_label`、`identity_label`、`summary_label`及回应／详情保留原生文字、换行与原滚动区；
纹理不能替代独立输入、旧记录／当前草稿差异、公开已揭晓P或原作品ID的来源说明。
三结点只表达连接隐喻，不是信号轨迹、成本动画、第二份进度或生成事件回放。
素材替换不新增音频、剧情、人物／文明历史，也不取得训练、揭晓、生成、保存或成果判定权。
Saved仅定位原作品列表及真实ID；原View另有配方核验语义，不能用插画补造旧C／P／G经历。

已目视与逐SHA核验的当前画面为SOURCE `d14be32f81354eb062f38d39f860b16ff739921a`，
`fa11874acaae`共42张：两语×1280×720／1920×1080／1600×1000的36张主帧、
4张反馈面板和2张测试者实际incident预覆盖图。默认入口、原Verify／Signal／Run／Status及
四步主要来源／摘要可读；720p深层说明仍用原滚动，英文C步禁用定位按钮的下缘在该帧部分裁出。
反馈面板也有原滚动位置，不能据这些图宣称全部正文或控件同屏。

该SOURCE的实际controller为660项通过、0 ERROR／WARN／SCRIPT，包含四组真实嵌入模态窗口
的焦点／逐层Esc边界；这些行为依据controller记录，不由静态图片推断。
原生OS失焦仍为NOT_RUN。片段源码SHA为`52bfe31608bbedd17d9286399f574c15d7e658f6121401f0783bb808f332954f`，
测试controller SHA为`a6f86e2ef44342a2988de0d438c9259d0a6bd11585591766e0de4a95c7cdcc89`。
完整原图审计见`.godot/f5-rendered/fa11874acaae/cpg-visual-independent-audit.json`
（SHA `d0b1f9ac1983ddb2bdf28db65fc1b1c6454a8dfc6373c386824904255541bac0`）。

六张原字节精选图及各自来源、尺寸和SHA见
[截图清单](../verification/20261018-creation-connections/screenshots/manifest.json)。
它们属于源码renderer证据，不代替实际导出包、OS操作或新人理解验收；历史失败记录保留于中央验证材料。

## 第一束光静态空间候选

`assets/narrative/first-light-quiet-space.png`为2172×724、3:1不透明PNG，1915564B，
SHA256 `e5e228b4dcd8e8370bbc06a6c94c2029d6389f24d8d8f17a7fe4cb1579817f10`。
2026-10-18使用OpenAI内建imagegen生成，无参考图片或第三方素材输入；原字节入库，
未裁切、转码或重压缩。AI辅助来源须随团队交付保留；正式采用及参赛披露由团队复核，
本条不是第三方素材许可或人物／CG／历史定稿声明。

图片只提供安静空间氛围。画面无人物、文字、数值、器件或线路；不记录玩家事件，
不表示真实计算、能耗或奖励。原生字幕说明它是已完成搭建的虚构回顾，
NOT输入1／输出0与灯灭仍由独立文字表达。现有画区不扩高，不替代操作按钮或成果条件。
外部调用仍可直接赋值`preview_texture`；初始化后明确赋null或零尺寸纹理不会重新加载默认图。
缺少默认资源或没有有效Texture时走原程序几何，加载／导入错误仍须如实检查，不能用回退掩盖。

当前候选SOURCE为`5bd3792b022ec053f62eaeca9f53a791e201bcd9`；FirstLight素材、组件与测试
沿用`6c145f0`已验证的原字节，本次后续变化仅第二章测试台默认高度。
`2f42550ffb53/test_first_light`的源码renderer实际197项通过，14张PNG为12张主图及2张预反馈现场，
不是14个不同画面：主图在两语、三个root尺寸下均为650×480子窗口，图片居中300×100逻辑像素。
两语字幕、NOT输入1／输出0、跳过和返回可见；正图／null／零尺寸及焦点行为依据controller断言，
不从静图推导。主图使用`theme.entry+theme.build`字幕压力夹具，不是实际CPU完成证明。
非作者图审见`.godot/journey-final-rendered/2f42550ffb53/first-light-nonauthor-visual-audit.json`
（SHA `b02639972fd6daef85d6fd2d7a1fee87cf4d86d7a12013d6492088e59192e559`）。

普通实际导出EXE的`f198fe6612cb`父链219项及独立重启48项已记录通过，SOURCE仍为5bd3792，
profile为`CreationLinks20261018`。该包真实教程五操作后经生产Journal里程碑进入回顾；
原图`first-light-playing.png`为520×384物理子窗口，横幅240×80物理像素，对应原300×100逻辑画区。
原生虚构说明、NOT输出0、跳过和返回完整可读；同次static图原字节相同，不据此宣称动画过程。
[本轮原图与来源清单](../verification/20261018-journey-final/image-manifest.json)分列源码前后、
普通实际PCK＋官方编辑器和实际EXE控制器证据；均不代替原生OS、新人理解或正式美术验收。

生成提示（内建工具，`transparent_background=false`）：

```text
Use case: stylized-concept.
Asset type: one ORIGINAL temporary raster atmosphere banner for a calm futuristic game's optional fictional First Light retrospective. This is decorative environment art, not a UI mockup or a scientific diagram.
Primary request: an extremely wide 3:1 horizontal panoramic illustration, ideally 3072 by 1024 pixels. A quiet, empty, minimalist future archive interior: a few broad matte blue-grey architectural planes, a spacious recessed alcove, and a soft warm diffuse opening in the distance. Simple elegant silhouette and restrained painterly material depth. The place feels safe, still and welcoming. No people, no character identity, no specific historical setting.
Composition/framing: wide, level panorama with all meaningful composition in broad masses, designed to remain legible when scaled to 300 by 100 pixels. Do not use tiny fine detail, a collage, a framed picture inside a bigger picture, or letterboxing. The entire canvas is the artwork. Keep the scene quiet rather than spectacular.
Lighting/mood: softly diffused light, muted dark teal and graphite-blue with a very small pale warm highlight; gentle contrast, no saturated neon, no dystopian debris or distressed retro surfaces.
Constraints: static fictional environmental mood ONLY. Absolutely no text, letters, numbers, glyphs, signs, logos, watermarks, people, faces, robots, circuit components, wires, indicator lamps, screens, dashboards, graphs, signal paths, diagrams, scientific mechanisms or implied energy measurements. No baked user-interface controls. Do not portray an electrical success lamp or an event timeline. Opaque background, no transparency.
Output: one finished clean horizontal panorama, 3:1 aspect ratio, no variations or multi-panel layout.
```
