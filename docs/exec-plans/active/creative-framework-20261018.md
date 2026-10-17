# 可替换创作呈现 · 2026-10-18

状态：ACTIVE。基线为已推送的`d6f594a843d5114fc4eb508916345eb0851e1015`，
开发分支`codex/creative-framework-20261018`。此前固定试玩包仍使用SOURCE8334，
不随本分支变化；其身份与验收见[全旅程证据](../../verification/20261018-full-journey/README.md)。
本阶段只关闭实际实现和验证的条目，完整目标与[覆盖账本](../../development/full-journey-coverage.md)保持开放。

## 目标与范围

让已有真实成果有可跳过、可回看的短呈现；为开场和成果各提供一个具体可替换图片位，
无正式素材时仍可读、可操作。用同一真实教程电路比较深色与浅色工作台，供团队判断。
完整人物形象、声线、正式CG和互相冲突的结局创意不在本阶段定稿。
不改变模型、合法解、导航门槛、保存格式或任何完成与奖励权威。

## 文件所有权

| 所有者 | 独占实现文件 | 合同 |
| --- | --- | --- |
| Knowledge | `src/ui/theme_reflection.gd`、新增`src/ui/first_light.gd`、`tests/test_first_light.gd` | 保持configure与milestones接口；只读真实tutorial完成，拒绝测试模式；约3秒程序几何、原生字幕、可选Texture2D、默认不自动播放、跳过/重播、低动效静态 |
| Narrative | `src/ui/yi_introduction.gd`、`assets/narrative/yi-learning-fragment.svg`、`tests/test_yi_introduction_media.gd` | 保持present/launch/skip/Esc/F8合同；一个静态Texture2D位；缺图文本可继续；原生抽象候选图不定义人物外貌或新历史 |
| Visual | `tests/test_workbench_palette_comparison.gd`、`docs/development/full-journey-visual.md` | QA局部深浅配色、同电路/数值/文字/几何/保存身份；两语三尺寸12帧；不是全局主题开关 |
| Root | 本计划、后续证据索引与当前状态入口 | 唯一Git写入者及引擎令牌调度者；不与作者重叠编辑 |

## 不变量与设计决定

- 真实完成只读`GlobalSave.game_player_content.completed_levels.tutorial`，不能由开放入口、
  `theme.entry`或演出自身推断；点击播放前再核对。旧成果可重播，不补造首次日期、奖励或事件历史。
- 灯映射已经完成的路径，不代表电路电能或输出必须为1。NOT输入1、输出0仍是正确结果。
- 沿用ThemeReflection同一Window和反馈层；新Control不截获F8/Esc，不抢拖线/反馈表单焦点。
  父节点always-process时显式暂停反馈可见、隐藏、失焦下的播放；中途开启低动效立即静止。
- 开场图片只是可选呈现，正文、Begin/Skip和原规则仍可达；不加载外部路径，不建立媒体管理器、
  音频后端或新持久状态。小窗不以缩小字体来容纳图片。
- 深浅对照仅在隔离QA中局部改变颜色；电路、trace、输入输出、任务、作品、导航和控件矩形保持一致。
  真实五操作与调色fixture分别披露，截图不冒称陌生玩家或系统输入。

## 实施与验证

1. 三位作者在基线与本计划提交后并行实现不同文件，完成静态检查并交出冻结文件清单。
2. 交叉独立审查：Visual审Narrative；Narrative审Knowledge；Knowledge审Visual。
   审查不得自行改作者文件；阻断由作者修复后再审。
3. Root保存可恢复源码检查点。只给一位执行者Godot令牌，从统一冻结快照执行原隔离验证：
   新定向suite、旧ThemeReflection/导入/首轮叙事及受影响反馈/Journal；实际renderer两语三尺寸，
   核布局、字幕、静态回退、播放/跳过/重播、反馈暂停和关闭销毁，无残留回调。
4. 核盘保护存档/作品SHA和导航状态；保存真实通过与失败来源。更改共享Window行为或发现回归时，
   在窄修与受影响复测后执行适当完整回归；不借此前8334包认证新代码。
5. 生产源码提交并推送新分支，实际构建固定普通/测试者包并验证解压、嵌入profile、成果/反馈和重启。
   新包与旧SOURCE8334分别记录。更新可审阅差异、素材替换接口及次日试玩问题。

## 进度与开放项

- 2026-10-18：F1双包、限定系统输入、原runtime168阶段及8334CI证据已推送至`d6f594a`；
  新分支从该点创建。三位作者已读合同并确认尚无源码改动；本计划先于实现。
- 三组源码已落盘：可选FirstLight、开场Texture2D位与QA工作台对照。独立源审发现并修复
  非null空Texture的回退，以及Begin/Skip测试共用旧导航导致第二情景不是新档的问题；
  原操作与未完成断言保留。三组运行验收均待统一固定源码快照，不预写成功。
- 实现检查点`a6c6ea3`已推送，新草稿PR13以F1分支为base。其固定归档5745/5745文件精确，
  170个常规test文件、无额外QA test。首轮15阶段实际13通过/2失败、exit1；
  开场媒体184项与相关旧回归通过，FirstLight91项中12项clip失败，palette61项中13项失败。
  原日志和身份保留于本轮证据，不追写旧FAIL为通过。
- 单窗口诊断实图证实Play后主要演出部分越出原scroll，Skip全在下方；字幕展开前的QA定位也
  过早。核准原Window内布局后自动定位、完整字幕从Play显示、短note及反馈capture忙等待暂停，
  不扩大窗口或缩字。独立复审已闭合，运行待证；一帧布局、rapidPlay/反馈抢先/销毁均须实测。
- 工作台诊断确认输入按钮位于原58px滚动区且部分裁剪，Pause可见；对照可在冻结数据前合法滚动
  定位，不能据此声称默认首屏全显示。EN720的一像素布局差异仍待不换色对照，不放宽精确断言。
- 修复检查点`9a2e724`的固定新快照实际5/5阶段通过（FirstLight91、Journal162、ThemeReflection、
  import/userdir），exit0且无提前终止，5745/5745原始字节精确。此为headless定向，
  自动揭示/实际Window/F8仍待真实渲染。工作台新前置保留61项原断言；v3仅EN720所选15项通过，
  旧13项失败与诊断ScriptError保留；完整矩阵待新检查点。
- 后续仍需处理Journal到已有只读作品演出的接缝及候选故事预览；正式美术/人设/语音/结局、
  陌生玩家理解、多平台和任何公网行为保留原有人工与授权边界。
