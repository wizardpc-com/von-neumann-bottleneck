# 同学反馈修复核验

日期：2026-10-19。反馈来自 Windows 离线试玩 `c7fabe71ff4b`，引擎为 Godot 4.7.1 stable。本记录只保留问题摘要、文件指纹与工程证据，不收录原始反馈全文、截图中的个人信息或存档。

## 输入与有效报告

| 原始文件 | SHA-256 |
| --- | --- |
| `VNB-feedback-2026-10-18T16-27-24Z-b99f6ee3.zip` | `4E6170518AD46EBAA6735ADD16A42DE5A6A1741DB387FF39AA3535356A7B85F9` |
| `VNB-feedback-2026-10-18T16-44-08Z-75700db3.zip` | `EC36F65110B5D4813420FA092FEDAAFA796F2F0D8BC6B984C24BE27638A4AD5F` |

| ZIP 简称 | Case ID 前 8 位 | 状态与摘要 |
| --- | --- | --- |
| `b99f6ee3` | `46bf58fb` | reported：经过元件或连线后，空白画布出现空提示框。 |
| `b99f6ee3` | `db9f3311` | reported：提示框存在时按住右键擦除，报告出现卡住的提示框及崩溃。 |
| `75700db3` | `3d0861ad` | reported：拖动选中元件后，在远离元件的空白处停顿仍出现该元件提示。 |
| `b99f6ee3` | `4c18e4be` | draft：无文字说明，不另计为一个 Bug。 |

共 3 条有效报告。原始 ZIP 内的游戏日志为空，没有可用于定位崩溃的调用栈；本轮不能声称已复现同学机器上的原生崩溃。

## 确定根因与最终行为

1. 自定义 tooltip 回调在文字为空时仍创建面板，因此空白画布也会产生空框。现在为空字符串返回 `null`，保留正常的非空提示。此行为符合 [Godot Control 的自定义 tooltip 约定](https://docs.godotengine.org/en/4.6/classes/class_control.html#class-control-private-method-make-custom-tooltip)。
2. 右键擦除在全局 `_input` 中拦截事件，Viewport 无法正常取消原生提示。现在让擦除事件继续经过原生 GUI；开始擦除时清除连线提示，活动手势期间不请求连线提示。每个事件带有临时归属标记，避免同一事件在 `_input` 与 `_gui_input` 中重复命中。直接调用 `_gui_input` 的既有测试路径仍可使用。
3. 元件拖动结束时，全局输入处理吞掉左键释放，GraphNode 的原生鼠标捕获未清除。现在完成拖动后放行释放事件，空白画布停顿不再显示已拖动元件的提示。

正式变更限于以下 4 个文件：

| 文件 | 变更 |
| --- | --- |
| `src/hardware_foundations/circuit_graph_edit.gd` | 空提示抑制、手势期间的连线提示管理、原生 GUI 事件放行与每事件一次擦除。 |
| `src/hardware_foundations/hardware_foundations.gd` | 放行元件拖动的左键释放事件。 |
| `tests/test_wire_tooltip_lifecycle.gd` | 空框、定时提示、右键取消与恢复、近线单次命中、出画布与重入回归。 |
| `tests/test_hardware_foundations_ui.gd` | Viewport 分发的元件拖动、空白停顿无残留提示、一次撤销还原。 |

## 验证与负对照

使用官方 `4.7.1.stable.official.a13da4feb`。隔离副本与独立用户目录由 `scripts/verify-project.py` 建立，不使用玩家存档。

本地证据目录：`.godot/verification/20261019T075718Z-8abc6ce9/`。该目录是临时验证产物；以下结果摘要保留在本记录中，生成目录不要求随源码交付。

| 验证 | 结果与本地日志 |
| --- | --- |
| 隔离导入、用户目录探针 | 均通过；`import.txt`、`user_directory.txt`。 |
| 连线提示生命周期，headless | **37 checks 通过**；`test_wire_tooltip_lifecycle.txt`。 |
| 连线提示生命周期，Compatibility 渲染 | **37 checks 通过**；`test_wire_tooltip_rendered.txt`，退出码 0。 |
| Hardware UI | 通过；最终增加空白停顿断言后再次运行，见 `test_hardware_foundations_ui_final.txt`，退出码 0。 |
| Hardware Prologue UI | 通过；`test_hardware_prologue_ui.txt`。 |
| 暂时移除每事件一次擦除保护的负对照 | 预期失败，退出码 1：一次按下删除两条近线、离开画布未清除锚点、重入时重复命中，共 3 项；`test_wire_tooltip_double_dispatch_red.txt`。恢复修复后上述 37 checks 通过。 |
| 暂时恢复吞掉拖动释放事件的负对照 | 预期失败，退出码 1：空白处停顿后出现已拖动元件的提示；`test_body_drag_release_red.txt`。恢复修复后 Hardware UI 通过。 |

负对照只修改隔离副本，并在运行后恢复；正式源码保留修复。最终 4 个文件的 `git diff --check` 通过。

## 验收范围

headless 与渲染检查均使用 `Viewport.push_input` 注入事件，真实经过 GUI 输入分发、tooltip 定时器与弹窗生命周期。测试中的位置明确采用 Viewport 局部坐标，避免窗口伸缩变换重复作用。负对照证明回归断言能够捕捉重复擦除及空白区域残留提示。

这些结果不等于真人 OS 鼠标输入或最终 Windows ZIP 的完整试玩验收，也不构成原始崩溃的复现证明。最终包仍应人工检查：

- 悬停元件及连线，随后在空白处停顿，确认没有空框或残留提示。
- 提示出现后按住右键，扫过原提示位置，再释放，确认游戏正常响应且正常提示能够恢复。
- 拖动元件后在不同空白区域停顿，确认没有该元件提示；确认移动仍可一次撤销。
- 两条很近的连线处轻按一次右键，确认只删除最接近的一条；连续擦除仍按实际经过的路径工作。
