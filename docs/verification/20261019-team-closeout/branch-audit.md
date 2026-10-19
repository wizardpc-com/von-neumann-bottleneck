# 历史分支与本地工作保全核对 · 2026-10-19

## 结论

核对基准为已 fetch 的 `origin/main=8a8b03c939a7e67f10bbe17b6aa4d4cd4dc9a31c`。远端 `origin/claude/lab-journey-20261019` 当时与它相同，但本地 Claude 分支另有两次真正未合入的完成迭代。除此之外，现有历史分支未发现需要补回的独有运行源码。

本地 Claude 的两次提交已按原顺序保留在本次审阅分支：

| 原提交 | 本次保留提交 | 内容 |
|---|---|---|
| `da26513` | `35a6dce` | 第一、二章工作台停靠布局；半加器、全加器、SR 锁存器、寄存器三步引导；任务语境中文修订；主题调整与相关测试、截图 |
| `4f6a4bf` | `b752340` | 实验室已有画面的光照、桌面物品和随进度变化的仪器柜；交接文档与截图 |

这是保留用户已完成的 Claude 迭代。没有据此新增任务、修改模拟器或改写存档格式。两次原提交共 18 个文件，405 行新增、125 行删除；其导入不代表完整回归或 Windows 包已经验收，最终结果以本目录的总验收记录为准。

## 历史分支的证据

使用 `git merge-base --is-ancestor`、`git rev-list --left-right --count`、`git cherry`、`git diff` 和 Git tree 对象核对。仅靠 ahead 数量或 `git cherry` 的 `+` 不能判定遗漏：多提交汇总进入 main 后，单提交 patch-id 可能不同。

以下分支头均已是基准 main 的祖先，包含它们的提交历史，无需再次合并：

- `codex/compression-prediction-creation-20261008`（`e46f866`）
- `codex/night-experience-20261018`（`cf89a76`）
- `codex/full-journey-experience-20261018`（`d6f594a`）
- `codex/creative-framework-20261018`（`157e3ef`）
- `codex/saved-work-review-20261018`（`2e488c3`）
- `codex/measured-growth-20261018`（`4e643eb`）
- `codex/creation-connections-20261018`（`e410cbe`）
- `codex/narrative-modal-focus-20261018`（`42401a3`）
- `codex/exported-modal-validation-20261018`（`eb770a5`）
- `codex/latch-learning-sequence-20261018`（`b3fe651`）
- `codex/journey-final-candidate-20261018`（`ef9bf6b`）
- `origin/ray/representation-playloop-20261003`（`c5a2b0c`）
- `origin/release/v0.5.0-alpha.1`（`d247a4a`）

非祖先分支中，下列配对的整个 Git tree 完全一致；右列均已在基准 main 历史中。因此不再次合并它们：

| 历史分支头 / 提交 | main 中的等价提交 | 相同 tree |
|---|---|---|
| `codex/pre-release-20261012` / `510d244` | `94b5bff`（PR #7） | `2df72d980d415f32573a4f1ab223b08d3ea455a7` |
| `codex/public-feedback-20261017` / `d008229` | `daa3765`（PR #8） | `e9e78592fe1cfa95fa0b5735f67d6ee646b7a0de` |
| `codex/stable-draft-reference-20261017` / `a92a34c` | `5f855b6`（PR #9） | `3cb1e74cf5d317cf3fc485d2cf8ae7bdc39a4e09` |
| `feat/offline-teammate-playtest` / `78e8c98` | `bf8f616`（PR #10） | `cc75ea86525aedb947c68d0c8a1b195f9332e404` |
| `origin/codex/main-works-integration-20261010` / `1667a6c` | `7e4facb`（PR #2） | `bf461ec098f72a7400b0e92fef63fc2daf14ed40` |
| 汇总提交 `150aa3e` | `70fefdd`（PR #1） | `5be273cf0f18b19b7f210be23c74793f39d638ed` |

`origin/codex/mac-second-act-20261005=8115b8e` 虽有 43 个非祖先提交，但其 `src/`、`experiments/`、`tests/`、`scripts/` 与 `1667a6c` 差异为零；这部分源码已通过上述汇总进入 main。其历史验收记录仍保留在原分支，不能把旧 Mac 验收作为当前 Windows 包的验收。

本地 Claude 分支 `4f6a4bf4e8164e70e2a93e1326bd8e5faf7c67a0` 相对基准 main 为落后 0、领先 2，`git cherry` 返回两个 `+`；实际 diff 确认有独有源码。保留该分支原指针，不强推远端 Claude 分支。

## 工作目录与保全边界

审计开始时三个注册目录如下；下面的脏状态是当时快照，清理前须重新核对：

| 目录（工作区根目录下） | 身份 | 当时需保留内容 |
|---|---|---|
| `von-neumann-bottleneck` | common Git 主仓库；本地 `feat/offline-teammate-playtest=78e8c98` | `tests/test_second_act_navigation.gd` 的本地删除，以及 201 个未跟踪 `.gd.uid` |
| `night-experience-20261018` | Claude linked worktree；`4f6a4bf` | `tests/test_simulation.gd` 的本地删除，以及 12 个未跟踪 `.gd.uid`；还有忽略的 `.godot/`、`.qa/`、`build/` 等 |
| `team-closeout-20261019` | 本轮交付 linked worktree | 本轮改动、测试和构建证据；完成交付后方可回收 |

原主仓库本地 `main=5f855b6` 落后基准远端 108 个提交，这说明本地分支指针旧，不表示远端 main 缺失内容。完成审阅交付后应保全未提交工作，再让主要开发入口指向已验证的最终 main。

清理遵循以下顺序，实际操作及清理后目录见最终交接记录：

1. 保存旧 HEAD、分支、完整 `status`、二进制 diff 和删除清单；为仍有保留价值的提交保留引用。保全所有未跟踪文件；忽略目录里的历史 ZIP、原始日志和截图也须保全，不能统称缓存后删除。
2. 对旧 Claude linked worktree，可将整个目录安全移入工作区明确命名的本地保全目录，逐文件核对路径、长度和 SHA-256，随后解除失效的旧注册。归档中的 `.git` 指针另存为来源记录，使归档成为普通文件快照。该方式须记录新位置，不以删除原数据代替整理。
3. `git worktree move` 会更新注册；对它的目的地再执行 `git worktree remove --force` 仍会删除整份归档，不能将两者当作保全方案。若采用复制后删除原 worktree，则必须先完成包括 ignored 文件在内的完整字节验证。
4. 保留 `von-neumann-bottleneck/.git/` 对象库。它是所有 linked worktree 的共同依赖，不能按临时 worktree 清掉。原主仓库的本地删除和 UID 文件先独立备份、核对，再整理开发入口。
5. 本轮临时 worktree 只在源码已进入最终 main、远端 CI 成功、试玩 ZIP 和证据已移至明确交付位置后移除。保留历史分支与存档；不执行 `git clean -fdx`、强制重置或公开 Release。

本报告只记录 Git 与文件系统只读审计及已保留提交的身份；没有运行 Godot，也没有执行旧工作区清理或修改玩家存档。
