# SRLatch五步规则示例：当前证据

当前已验源码为`c84cc9d67b25e6e37eebd19570a9c065f62088ae`。阶段ACTIVE，完整goal仍ACTIVE。
七阶段定向检查通过；修后真实源码renderer **336项、0失败、自然exit0**，36图按原滚动局限接受。
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
| [CI39106076014](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/39106076014) | Root实际查为SUCCESS | 仅Linux；本独审未取job日志计数，不代Windows或包验收 |

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
下一步导出包专项仅为只读提案，尚未运行；包、原生和新人验收分别记录，不借源码GUI通过认证。
既有可用双包及其独立profile见[bb5证据](../20261018-narrative-modal-focus/README.md)，不把旧包称为本功能的新包。
本功能尚无导出包／原生OS／Mac／陌生玩家验收，不以图或controller代验。
