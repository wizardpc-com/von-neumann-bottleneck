# 全旅程需求与证据账本 · 2026-10-18

本账本继续[全旅程active计划](../exec-plans/active/full-journey-experience-20261018.md)。
首轮[固定包与验收](../verification/20261018-night-experience/README.md)证明其明确范围，
不表示手册的全部工作已经完成。启动基线为总控核准的`cf89a76`；本轮新增实现已落盘并经交叉源审，
已有早期定向成功，最新整合快照仍待验证。基线CI`39061439011`已由总控核对SUCCESS，不能认证新增代码。

状态用语：**已有**为当前源码/首轮证据；**待扩展**为本轮工作；**候选**为可替换呈现；
**待人审/待外部授权**不能写成技术通过；**未运行**不得以计划或目录存在替代。

## 手册完整要求与执行边界

| 需求 | 已有来源或明确证据 | 本轮状态、还须证明什么 |
| --- | --- | --- |
| PR10先合入、实际远端基线、隔离工作、可恢复检查点 | 首轮计划与PR10合并`bf8f616`；当前总控核准`cf89a76` | 既有交付保留；续轮新分支/提交由总控管控。PR11启动时Godot pending不算失败 |
| 首页→短语境→第一次操作→结果→回应→继续 | YiIntroduction、真实NOT五项操作；固定7c实包及限定原生观察 | 已有；扩展全旅程而非继续停在序章。新界面集成后重验跳过/回看/恢复 |
| 壹的语境、卡点帮助和任务后回应 | MissionNarrativeCatalog双语60任务、ContextCard、九Host与完成overlay；现有三级Hint | 已实现并经独立源审；早期Narrative1128项通过。最新拓扑/语言等改动待新快照，不冒充60项真人通关 |
| 全旅程逐关盘点玩家决定/前置知识/成功/困难类型 | [60项源码审阅](night-journey-review.md)列全ID与R/S/O | 已有目录审阅；本轮补逐任务结构语境及真实合同核对，不冒充60项真人通关 |
| NOT/AND/半加器可点输入、数字结果、真值表 | terminology_diagram；handbook/model/input checks和实包rules帧 | 已有代表交互，隔离玩家电路；后续术语按实际缺口扩展，不无差别重写 |
| 任务层次：现在做什么/成功条件/可查规则/深入 | Mission/ContextCard常驻Now/Verify、可展开语境；现有手册/Hint/第一章next action | 已实现全目录身份覆盖、独立合同源审；原判定保持。九Host最终实际布局与语言回归待证 |
| 失败指出不满足条件、合法替代方案保留 | 各域catalog/receipt/trace；第一章错误保留/合法reuse测试 | 待逐域抽查与补缺；记录规则/策略/操作区别，不能要求先失败才可通过 |
| 安静极简未来风格与深浅比较 | InstrumentTheme、TechnicalBackdrop、Typography；同数据深浅样张 | 深色为首轮候选默认；浅色仍独立样张，未成为全局设置/全UI验收 |
| 共用UI、窗口/缩放/Esc/焦点和中英长文 | 首轮三尺寸/两语renderer与原生限定路线 | 待新增界面的同尺寸复核；不把局部主题改动称全域美术完成 |
| 非单一颜色的信号、端口、数值与低动效 | SignalNotation、数字输出、既有减少动效 | 已有；新观察站/档案也须文字/符号区分完成、可进和未知 |
| 人工素材可替换、动态文字独立、来源许可 | [素材接缝](night-art-interfaces.md)、程序绘制新UI | 已有接缝；续轮补新增区域用途/状态，不擅用私人参考图、定稿人设或成员署名 |
| 即时结果、关卡收获与长期成长 | 原trace/完成层/ThemeReflection；新JourneyJournal动态目录、历史成绩来源及原作品只读 | 已实现并经独立源审；早期Journal160项通过。新增ThemeReflection/F8焦点栈尚待实际渲染，不造事件时间线 |
| 少量文明片段/外部空间原型 | 会议候选；现有ThemeReflection只作主题回顾 | 本轮档案和观察站为候选叙事映射；明确虚构/事后回看，按真实完成派生，不测量文明/能耗 |
| 奖励不重复、旧档不补造历史 | 原完成权威/作品支持；Journal原目录、磁盘inventory及坏/未来档只读测试 | 早期Journal160项通过且独立源审无阻断；最新测试版本须重跑。测试fixture/真实合法通关/历史作品来源分别披露 |
| 后续C/P/G可发现、区分可选地址预测 | TaskNavigation/CreationTasks、地图快捷入口；实包全60前景入口gate | 已有实际导出入口；续轮导航/观察站仍同一目录，不能把候选标作普通默认 |
| C→P→G当前模型准备、生成/作品保存/重启 | 创作合同；首轮tester实包C/P/G与作品跨进程证据 | 已有明确范围；新增展示只读原作品身份，不解除准备条件，不做AI审美通关 |
| 普通成长、测试全关访问、模型前提各自验证 | normal25/tester32实包gate及单独后续gate | 已有；本轮新增UI区分unlocked与completed，测试开放不点亮earned |
| F8现场/草稿/跨重启/最后ZIP/去重导入 | PR10离线系统与首轮4案例2会话最终ZIP验收 | 已有；新界面须F8兼容。原生长文/中文输入及旧意见GUI恢复未获首轮验证 |
| 统一试玩包、版本/开关/manifest/存档说明 | 固定7c普通/测试者包及SHA、独立夜间profile | 已有历史基准；续轮需新固定版本和实际解压启动，不覆盖旧包/旧profile |
| 实机3–5段展示素材及镜头路径 | 首轮截图/原生完成图/操作说明 | 待续轮变化证据；PPT/视频成片仍由既有队友负责，不以概念图冒充实机 |
| 每轮独立审查、定向/完整检查与可恢复交接 | 协作纪律；首轮四轮/交叉审查/CI记录 | 持续执行；新代码不得借用旧7c测试结论。每轮记成功/失败/未运行 |
| 次日≤5人审问题、素材与叙事接口 | 首轮handoff与art interfaces | 待续轮更新真实改动/开放决定，保留陌生玩家/异机/主观声音/最终美术边界 |
| 本地成绩、优化对照、社区/排行现状 | PersonalRecords.snapshot/view、layout_score、可选HTTP社区/排行榜；无endpoint时隐藏 | **已有候选功能，不是从未实现**。原本地记录不授进度；公网排行公平/服务接入/上传需原有门槛和授权，本轮不新增公网行为 |
| 3D地图、完整CG、最终人设、复活结局等 | 会议明确开放设想 | 仍为完整目标开放项；本阶段先验证真实3D候选（SubViewport/Node3D/程序几何、固定视角）。CG/形象/剧情变体的可替换实现、素材与人审分别待证；互相冲突的设想不能同时成为唯一正式结局，不擅自替团队定稿 |
| 真人理解、继续意愿、赛事/PPT正式规格 | 会议建议与团队安排 | 待真人/正式通知；不把开发者已知答案操作当新人、不重设成员任务或赛事截止 |

## 全目录覆盖与权威

实际内容由`TaskNavigation.journey_tasks()`及当前开关决定，完整候选为核心40、表示5、
服务3、可选地址预测3和创作9。核心40包含探索支线，不等于40个必经任务。
下表继承首轮完整ID审阅；Narrative已为每个ID落盘语境，Knowledge独立核对合同及合法替代；
技术完成仍由原领域权威产生，目录/文本覆盖不等于全关实机解题验证。

| 区域 | 目录与真实完成来源 | 续轮要求 |
| --- | --- | --- |
| 序章14项 | PrologueLevelCatalog/GlobalSave.game_player_content；自制模块与参考组件分开 | 任务语境、真实完成收获、档案来源；不以测试参考封装或授成就 |
| 系统7项 | SystemLevelCatalog/SystemChapter receipts/completion | 真实基线/比较/订单/诊断身份；不把未运行控件当证据 |
| 局部性7项 | LocalityLevelCatalog/LocalityChapter | Cache自动管理、观察/优化合同、目标与诊断分开 |
| 并行6项 | OverlapCatalog/OverlapChapter有效方案 | 请求/状态/周期、buffer或cache合法路线、额外目标独立 |
| 布局6项 | LayoutCatalog/LayoutChapter有效方案 | 复制准备成本、尾批/多单、空间和流量目标独立 |
| 表示5项 | SecondActTasks/JourneyReview重验保存方案 | 记录不可确认时不点亮；候选profile与合同身份可查 |
| 服务3项 | SecondActTasks/JourneyReview有效支持 | 测试者可进不算完成，不把表示/预测加为前置 |
| 地址预测3项 | SecondActTasks临时session任务 | 明确临时离开丢弃；不伪造持久成长或和内容预测混淆 |
| 压缩3/内容预测3/创造3 | CreationTasks/Session.decode/supports与受保护作品 | 当前模型准备、冻结检查、作品配方身份、未知/损坏支持保持未确认 |

## 现有系统复用与新增接缝

- ThemeReflection继续以真实里程碑派生主题回顾；Home的show_completion_story保留既有结尾。
- PersonalRecords保留本地成绩与可选社区入口；它默认只看原核心目录，跨域档案不将此旧统计误作全60总量。
- JourneyJournal只读`journey_tasks()`与现有保存作品，不建立独立解锁、事件时间线或奖励数据库。
  文明片段标明虚构候选/事后回顾；任务未完成时只见当前目标、成功条件和原导航。
- 所有者与任务语境接口见active计划；规则仍在现有手册、策略仍在Hint，档案只链接回看。

## 当前证据状态

本轮唯一证据入口为[20261018-full-journey](../verification/20261018-full-journey/README.md)，
保留早期失败、成功快照、源/日志哈希及最新待验差异。首轮7c包及原native记录保持原身份，
不认证新增界面。当前已有F1实现、独立源审、早期headless定向及720p真实3D渲染通过；
最新`85535900/0388d903ab50`已有3阶段与11套定向PASS/exit0（Journal160、Narrative1134），
其中Reflection窗口栈明确NOT_RUN。`574f3d275059`真实九Host两语三窗54帧通过，
Journal渲染仍有inventory与ThemeReflection首Esc两项失败；精确诊断/窄修/新快照仍待执行。
完整回归、新固定包与最终布局/字体验收继续待证。
后续be2664fe/054735已确证inventory仅presentation.cfg显示偏好变化，tester popup首Esc窄修通过；
普通Moments实际popup五项失败仍待最小修复及两渠道/root/popup重跑。总控源码检查点为
`c50492a`、`0aa1866`，不是最终包或完整goal完成。
后续e47c62a/79f12f3/580e/13e1f84检查点继续保留；普通popup链真实GUI194及Host1462已有各自
固定快照通过，但不能覆盖新tester销毁/等待capture测试、0aa远端Service布局FAIL或23a旧离线反馈headless失败。
完整CI/受影响回归/新固定包仍待；native官方工具初始化失败，明确NOT_RUN，旧7c限定原生身份不变。
次日≤5真人问题、两包manifest待填字段、5条待录镜头与作品/素材接口集中在新版证据入口，未虚构成片或最终人设。
完整goal与active计划保持active；未跑、多平台、人审、素材/剧情及外部授权开放项继续保留。

最新3ec固定copy的`f5842f09ab8c`真实Journal GUI222项及`c373e13a8281`旧6套反馈定向通过；
前者含最后tester销毁/await退出两暂停分支、真实普通/测试者F8/Esc/Tab及精确SHA保护。
原canonical离线反馈仍重复失败，`4a0d0062`已将发布失败定位为rename Error1/Failed；
源243字符存在、目标241字符不存在、两JSON有效且保留，生产Store未改。独立新scratch8个原生rename
有7成功、1个同形长路径MoveFileW即时Error5/Access denied；失败副本完整，无旧pending移动或重试。
这不证明具体OS根因，不关闭P0，不以私有runner/别名通过替代canonical闭合；完整回归与新包冻结继续等待。
一次系统TEMP对照准备子目录即WinError5、0次rename；正式工具require_escalated四个新workspace
独立case成功/error0。证据支持下一步核验正式权限canonical入口，不证明沙箱唯一因果；不改生产Store。
