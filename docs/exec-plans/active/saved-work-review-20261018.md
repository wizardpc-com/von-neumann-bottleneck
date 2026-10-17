# 从成长档案回看原作品 · 2026-10-18

状态：ACTIVE，实施基线`157e3ef8f844de5a797aa4c7e13f3c3c4503b14d`已推送；
新分支`codex/saved-work-review-20261018`。F2修后定向/真实渲染仍独立排队，最终包须两轮整合门禁通过。

## 玩家问题与结果

成长档案已能列出真实保存作品，但缺少从档案直接打开作品的入口。增加作品选择与“查看原快照”，
复用原WorkFocus展示已保存输出、配方与来源。关闭后返回档案并还原入口焦点。
此入口不运行生成模型、不建立Session或writer、不重放历史，不把只读恢复资料当作当前有效进度。

## 文件所有权

- Knowledge：`src/ui/journey_journal.gd`、新增`tests/test_journey_work_review.gd`。
- Narrative：独立源审；不得直接改作者文件。
- Visual：实际两语/三尺寸图审；素材接缝说明。
- Root：本计划、分支/提交、整合与验证排队。引擎令牌单独授予，不随文件授权取得。
- 仅当实际Window反馈/Esc复现证明需要时，另行核准`experiments/creation/work_focus.gd`的最小输入guard；
  不预先改动Session、Files、保存格式或共享反馈核心。

## 合同

1. 点击时以原`Files.read_session(CreationSession.launch_path(), CreationSession.decode)`重读，按原id重新选择。
   有效works和readonly_works明确区分；未知版本、损坏文件或失效id不伪造可用作品。
2. 直接`WorkFocus.new().configure(work.duplicate(true), english, {})`；不走工作台的重放入口。
   显式禁用fork，不连接fork处理器；空evidence禁用Locate，说明当前展示的是原快照而非生成回放证据。
3. 同一真实WorkFocus Window使用现有普通/离线反馈。反馈前停止播放；F8、Esc、关闭、销毁及拒存救援
   沿原有层级返回，无悬空Window、layer或暂停标志。不强制玩家观看或给作品作审美评分。
4. 精确保护game、workbench、candidate、transaction、works、lease与导航；浏览前后不写入完成、奖励或日期。
   测试保存目录独立，不接触真人档案；原未知格式和旧反馈保留。

## 实施与验收

1. F2固定检查点后开始最小实现；Root只提交约定allowlist，不混入未解释的原工作区改动。
2. 作者交冻结清单与差异；独立审查重读当前源码和原WorkFocus接口，阻断由作者修正。
3. 新suite使用真实生成并保存的作品，另覆盖只读、未来格式、损坏与未知id；验证无writer/lease/重放/fork。
   窗口层覆盖普通/测试者F8、逐层Esc、焦点恢复、关闭销毁和原拒存救援；保护字节与导航精确对比。
4. 固定新快照执行新suite与受影响Journal/WorkFocus/feedback回归；实际两语三尺寸渲染。
   共用Window若需修改，扩大至相关反馈和完整回归，不以F1/F2旧结果认证新行为。
5. 通过后保存/推送新分支检查点，使用实际导出包验证作品入口与独立重启。所有失败保留原身份，
   包身份、控制器输入、OS输入和真人理解分别记录。

## 开放项

完整CG、人物、声线、结局及最终色板仍须团队判断；此作品入口不替这些候选定稿。
完整开发目标继续active；此计划完成只关闭本入口的实现与已实际验证范围。
