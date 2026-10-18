# 当前候选展示材料与镜头索引

这份材料供团队制作PPT／实机短片时取材，不是最终PPT、成片、提交说明或赛事规则。
[可编辑架构SVG](showcase-architecture.svg)使用原生文字、形状与箭头；无外图、脚本或烘焙正文。
系统字体缺失时会回退，团队导出前需检查字形。旧[40任务展示稿](astra-challenge/showcase.md)
保留其历史产品／版本背景，不把其中Product Hunt建议移作本轮参赛决定。

## 图与源码

关系基线为F4生产检查点`1d887c5c328780b34dc220f65fd55c5ecab8380c`；
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

## 五组候选镜头

下表是实际进入路线与取材合同，**全部新F4帧当前PENDING**。不把计划当录屏，
不将controller操作称作系统鼠标键盘或陌生玩家理解；不以全入口模式冒充自然进度。

| 组 | 进入与操作 | 让观众看到什么 | 新F4画面状态 |
| --- | --- | --- | --- |
| A · 首次构造 | Home → 原教程；两条真实连线、输入A、运行及五操作完成；可选Journal回顾 | NOT输入1、输出0仍正确；先做再看证据，回顾可跳 | PENDING；需要本轮实际包首段，不用压力字幕替代生产milestones |
| B · 看清未达标 | Layout `fields`原方案运行 → 契约差额 → 定位；另可选Overlap `backpressure`首未达标case或`buffers`真实停止事件 | 输出正确与流量／周期达标分别判断；原事件／地址／代码行对应，旧草稿不能沿用旧定位 | PENDING；标明隔离test-mode fixture、合法滚动后可达，不宣称默认按钮同屏 |
| C · 看清改进 | System `cpu_speed` → 同条件原受控pair → 原history chart → 主动展开效率片段 → 收起 | 真实周期／搬运差值与来源；持平或变慢也诚实表达，候选回应不是额外奖励 | PENDING；pair必须同程序／测试集并遵守原CPU替换对照规则；缺图仍可读 |
| D · 完整路线与作品 | 任务树区域列表／搜索 → C1、P1、G1；原Session真实学习、无损复原、commit/reveal、生成与明确保存 | 当前模型的准备条件与作品来路；能点入不等于准备完毕，保存不等于通用智能 | PENDING；需本轮实际包完整链，披露受控QA准备而非普通自然全旅程 |
| E · 成果空间与回看 | 可选观察站 → 硬件／System → 近看／还原；Journal → 查看原作品 → 返回 | 同一真实任务状态、章间装置差异、原输出／配方／来源；可返回高效任务树 | PENDING；成果灯只是映射，不是运行信号或物理测量；作品仅原快照，不补造生成事件 |

## 已有可审阅参考

以下是上一固定普通实包c109的原字节帧；它们**不是F4新包证据**，也不伪称同一新录像：

- [开场Texture与原生目标](../verification/20261018-creative-framework/images/sourcec109f0e97617-workfb44325711b2-introduction.png)：1280×720。
- [真实教程后生产回顾](../verification/20261018-creative-framework/images/sourcec109f0e97617-workfb44325711b2-first-light.png)：520×384，固定NOT1→0。
- [原作品只读快照](../verification/20261018-creative-framework/images/sourcec109f0e97617-workfb44325711b2-saved-work.png)：864×496，披露实际Session controller setup。

完整来源与SHA见[原集中证据](../verification/20261018-creative-framework/README.md)。
本轮F4最终门禁、实际包与新图须另按自己的提交、receipt和profile绑定，不能借上述旧结果代证。

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
