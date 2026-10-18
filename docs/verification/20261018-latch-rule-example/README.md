# SRLatch五步规则示例：当前证据

当前已验源码为`c84cc9d67b25e6e37eebd19570a9c065f62088ae`。本工程交付按已验范围收口，完整goal仍ACTIVE。
七阶段定向与源码renderer336项通过；普通新包已完成实际PCK／同版editor原258→336专项，以及release EXE原父219＋冷重开48项验收。测试者PCK／同版editor原258→336专项也已通过，测试者release EXE父子链已通过，随后另授的strict-only 48项也自然通过；原strict资源中断失败独立保留。图像按原滚动局限接受。
原`e061518`的336项两失败完整保留；新通过不回填旧复合条件的缺失分项。
完整机器身份与本地收据见[checks.json](checks.json)。

## 实际行为与边界

原手册SRLatch复用前／后例按钮，选择Reset→Hold0→Set→Hold1→Reset。
五步数值来自隔离的原官方reference circuit及原模型序列，只缓存脱离玩家状态的输入／输出标量。
首步前态未指定；两个相同S=R=0分别承接Q=0与Q=1。S=R=1为常驻禁止规则和真实模型负例，不能当作合法存储输出。
Register原图与组合逻辑输入未改；没有新接线、自动演出、通关奖励或存档格式。

## 已验范围

| 门禁 | 实际结果 | 范围 |
| --- | --- | --- |
| 源码静审 | PASS_STATIC_SCOPE | 五文件语义、脱离副本、原Register／组合输入保留；不代编译或可见性 |
| 原import／user_directory＋五suite | 7／7自然exit0，0 ERROR／WARNING／SCRIPT | Latch258、Handbook1163、Rule391、Storage150；Localization仅报PASS，不编造计数 |
| 修后源码renderer | PASS_SCOPE：336项、0失败，PID28016自然exit0 | 36原PNG＝30步帧＋6规则帧；0 ERROR／SCRIPT／WARNING |
| 原e061 renderer | FAIL_SCOPE：336项、2失败，PID47332自然exit1 | 原36图视觉scope接受，不改输入失败 |
| 新guard | PASS_STATIC_SCOPE＋c84源码renderer通过 | 只让出已有反馈可见时的Handbook Esc；原断言、Input及等待不变 |
| [当前源码CI39111938887](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/39111938887) | SUCCESS：Python／Godot两job | c84源码Linux完整verifier；不编造日志计数，不代Windows或包验收 |

固定输入719项逐字节核验；执行副本718项非配置文件保持，只有原verifier两项私有user-directory配置例外。
176个canonical测试包含固定归档中的`completion_route`及原UID，没有因live未知删除少复制测试。
原e061七阶段摘要SHA：`b34e49e0eeb434b2bdd4ccd9c2828321cbbdf76cffb6de15bcd056189fa9d178`；Root独审SHA：`1a9da1658f653645190e5a57e0e7844c511b972691e5be90ff298e46fd5087bf`。

## 原GUI失败与最小修复

失败项为“首Esc只关反馈并保持所选规则”和“恢复原下一例按钮焦点”。
原检查为复合条件，没有分别保存panel／手册／所选状态或输入回调先后；本次实际哪一分项失败仍UNKNOWN。
原Hardware输入先调用Handbook.handle_escape；原Handbook没有反馈守卫，普通Moments也在input层处理Esc。
旧rule-practice固定测试者反馈并暂停Host，不能证明普通Moments层级正确；新Latch数值／绘图没有改这条输入路径。

候选只在Handbook原合法Esc校验后读取已有PlaytestData反馈标志；可见时返回false，不消费事件，让原反馈处理器关闭。
候选Handbook SHA为`60865204b645c74b98534d0ad1611f4a1832b66663b64275ec383e78a6e92ae6`，两行删除后精确恢复原文件。
原336项检查和动作没有软化。新c84七阶段7／7与GUI336／336实际通过，普通反馈首Esc／返回原按钮焦点均沿原断言通过。
修后七阶段摘要SHA：`dbb60957c021c4b26fb3583aaf347184314eba1a9290ef34d564536488fde238`；GUI摘要SHA：`fefa628d266aea1cbc66c432f240efcbb5c6818019d8537339b3a053bad9116d`。

原GUI摘要SHA：`2af897939c0d035c6488d50f78957fcfd8427fafd5d295f6495c0e303553b3e8`；正式独审SHA：`8a9ae860d0d448d8cc2d9df61c38aba231a9e995a27927d15ab36221cd4be3ab`。
源、runtime49文件、36PNG及settings finally均已核；主备仅去顶层保存时间戳后完整typed payload相同。
浏览前保护只在本进程断言，没有序列化前后快照；creation／Session目录为空，不称作真实旧CPG作品保护验收。

## 交接

修后36图独审SHA为`b2f146eab458f96575a30133c837a3f50baa99157be5105823cc58ed819306f7`：28张与此前已看原像素相同，8个新SHA已实际查看；原深层文字仍需Scroll，英文仅手册面板，0反馈截图，不靠图证明F8焦点。
原e061图审SHA为`23c0b8e029292adce879fa6b023cdc73ea7530bff408b1c5eac1e8fdb5b45075`；原FAIL及全部原图不改判。
普通当前包为[LatchRulesExperience ZIP](../../../build/playtest-LatchRulesExperience20261018-c84cc9d67b25/Von-Neumann-Bottleneck-Windows-playtest-LatchRulesExperience20261018-c84cc9d67b25.zip)，独立profile为`CreationLinks20261018`。解压后运行Windows内EXE；保留完整representation／service profile目录作备份，发行包没有预制QA进度。构建身份不替代试玩，实际链分列如下。

| 实际包门禁 | 结果与限定 |
| --- | --- |
| 原builder＋identity | PASS；ZIP SHA `5e2dc6ce62bab128693d10215e2963621cf58b03305c230dbb507789ee516114` |
| 原release EXE `--script`尝试 | 原180秒owned超时，0项可确认、无validation，GUI未跑。原失败保留；同EXE help未列该选项不能单独证明唯一超时原因 |
| 实际导出PCK／同版official editor | 原canonical未改：headless258→独立新data GUI336均自然0，36图／0extra。**不是release EXE专项或原生OS** |
| release EXE原父＋strict冷重开 | 本次219＋48全true、两个实际EXE自然0，0 ERROR／WARNING／SCRIPT；真实Host准备单作品与5supports，随后35字段纯回顾保护通过 |
| 测试者 | BUILD_IDENTITY、PCK原258→336、release父229／原子链142＋19项及另授strict-only 48项相继PASS。原资源中断attempt仍FAIL，不冒称原整次运行无中断 |

PCK摘要SHA `3cb95a0f8d1f673cf5cb6e775fa04722c019e77e4cf40dd2ba9934f1f7645f4d`；独立数据审`2ac19db69eb0891a2e6dda27a4a0d0fe0467452e9594f6db2b8620a778a13974`；图审`37d0872b375e6acecb133262bbcf2267a04aba8ce3bee68f3235d779245b79dd`。36图与已实际看过的c84源码像素相同，明确复用既看像素。

实际release父／strict摘要SHA `a2107d96b1c91bbe99b17984864c10e5757a2bbc0e8ca5c1cdc6492e5643a77b`；独立数据审`2b57e67e86a617a5acfc32a88775156491a599ee1a223c1d4fca4577f4b3d163`。实际Session／whole work及recipe／output精确保持，冷重开仅原Journal Saved定位，不恢复临时C／P／G历史；正常退出仅允许顶层时间戳和主备轮转，其余typed payload严格相等。该链21图独立图审按原滚动局限接受，SHA `37ce31e142a9ea36f9051d38724289b5d9250384e339c0290398c579d07e21aa`：16张原字节复用此前已看像素，5张新图实际查看；不靠图证明F8焦点或OS。

测试者PCK摘要SHA `79fe0b870393e2e753dccfdce632920ad18034438febc248121f8f5dee3861c3`；独立数据审`bea5e80e108a3957b483fa45453acc8722556fdec338c8c06793e2e9a1ab6dd4`；图审`a759e03bcfd84e694a5f9f5e35528ad8ce5bcc5c8dd838ff4ac36d8dbfac0c57`。36suite原像素与已看源码／普通PCK相同；唯一新图是手册第5步的预反馈现场，**没有反馈面板**。两phase各自fresh四env、typed主备与空creation范围通过，不称真实旧作品保护或release EXE验收。原builder退出时磁盘观察不代全程空间下限证明。

测试者实际父229全true、原子链60唯一入口及最终单ZIP的4现场／4修订／2session／0捕获错误通过；这不等于60任务解题。随后strict wrapper148936约3.5秒被原256MiB空间守卫定向停树，观测153239552B；EXE45288退出码未知，无strict raw／process／validation，48项计数不可得。该整体资源中断摘要SHA `a883490e50fc1bbc3d71a12e01018e8af1ae200881850bf02e13dcda1ad7d5c2`及独审`4386d2afb4d8604a8fdd33bf9035bf08d812226ef8d31fe0a4846ffbe647b3bc`保留失败。

中断后protected原字节、Session／单作品／5supports与租约精确保持。Root已原字节归档并移位唯一baseline／override，原runtime37文件／44目录和父收据不变；没有重跑父子链或改strict代码。归档独审SHA `0eba31414f533954d8b75a608c439ec320120bee6628975c5c2a71465064234f`。资源恢复后另授原代码strict-only，实际EXE141804自然exit0、48项全true，0 ERROR／WARNING／SCRIPT；父子链未重跑。新摘要SHA `5b234ee47a217bbc6e8796695d5a56ac4b1f4b73c8fe36f7e8187de0a918f992`，独立数据审`5550ef39a6d584d746be5e91c26948013cc13cd301d6ab88eb6b675645f3f948`。新baseline与归档旧baseline原字节相同；只原六处CPU坐标float→同值int后全canonical相等，退出主文件typed对应新reopen、备份typed对应baseline，仅去顶层保存时间戳。Session／whole work／5supports与其他保护不变，原finally移除override；本次导出图审SHA `da621c0445313fe3b61d94ef93aa7b83c7f22d76da80c8182f53eeb0c8bc6e77`接受原滚动局限：45文件／31不同SHA＝旧43＋新strict Saved重开图1＋预反馈现场1。34文件复用已看原字节、11新SHA实际查看；主CPG反馈图确有面板，7个parent incident均为预反馈现场，不能冒充面板图或OS焦点证明。

测试者当前[LatchRulesAccess ZIP](../../../build/playtest-LatchRulesAccess20261018-c84cc9d67b25/Von-Neumann-Bottleneck-Windows-playtest-LatchRulesAccess20261018-c84cc9d67b25.zip)供全入口审阅，独立profile为`OfflineTeammate-CreationLinks20261018`。它允许进入不等于授予完成或作品；不把QA准备档导入用户档。普通ZIP仍为默认试玩，普通新档保留原知识／模型／进度门槛。

两个相同00的原字节代表图：[承接Q=0](zh_CN-1280-step-2.png)、[承接Q=1](zh_CN-1280-step-4.png)，来源及完整SHA见[selected-images.json](selected-images.json)，等级仅为实际PCK／editor，不借作release或OS图证。

已验PCK和release父目录中的两个冗余EXE经双审回收；原ZIP可精确重建，原记录时清单／raw／runtime／全部图／PCK保留。旧`--script`超时和原e061两失败均不改判。

既有恢复双包及独立profile见[bb5证据](../20261018-narrative-modal-focus/README.md)。本功能原生OS／Mac／陌生玩家、普通新档自然全旅程仍未验；完整goal保持ACTIVE。
