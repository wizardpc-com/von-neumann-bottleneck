# 开发文档

## 从这里开始

| 需要做什么 | 阅读入口 |
| --- | --- |
| 确认当前版本、进展和验证边界 | [当前状态](CURRENT_STATE.md) · [验收待办](../RELEASE_BLOCKERS.md) |
| 接手开发、分工或判断任务范围 | [项目规则](../AGENTS.md) · [协作](development/collaboration.md) · [Git 工作流](development/git-workflow.md) · [计划规则](../PLANS.md) · [执行队列](exec-plans/active/README.md) |
| 配置开发环境、运行回归 | [Mac 环境](development/mac-handoff.md) · [测试命令](development/testing.md) |
| 接手构建或反馈运维 | [候选包构建](distribution/free-alpha.md) · [反馈接入与回退](distribution/feedback-connectivity.md) · [接收器运维](../server/deploy/RUNBOOK.md) |

## 实现与内容

- [架构总览](../ARCHITECTURE.md) · [确定性仿真与 Trace](architecture/simulation.md) · [架构决策](decisions/)
- [内容与存档合同](architecture/content-system.md) · [任务矩阵](development/task-matrix.md) · [新增关卡](development/adding-tasks.md) · [本地化](architecture/localization.md)
- [重叠流水线](architecture/overlap-chapter.md) · [数据布局](architecture/layout-chapter.md) · [后半程框架](design/second-act-framework.md) · [创造工作台合同](../experiments/creation/CONTRACT.md)
- [反馈与同意](architecture/community-feedback.md) · [离线试玩反馈](architecture/offline-playtest.md) · [维护指南](development/final-maintenance.md) · [品牌替换](development/BRAND_20261116.md)

## 最近验收

- [独立 8443 限源反馈](verification/20261122-feedback-connectivity/README.md)
- [v0.6.0 Game / Test 四包](verification/20261116-final-product/README.md) · [最终视觉](development/FINAL_VISUAL_20261116.md)
- [全章节基本操作验收矩阵](development/BASIC_INTERACTION_ACCEPTANCE_20261113.md)
- [v0.5.0-alpha.4 公开试玩](verification/20261024-desktop-release/README.md)

较早的截图、回归和交付收据在 [历史验证](verification/)，实施记录在
[已完成计划](exec-plans/completed/)，各子系统交付记录在 [状态归档](status/)。
