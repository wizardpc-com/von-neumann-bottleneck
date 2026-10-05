extends RefCounted
## Reopenable operation/rule briefing. No strategy, progression or simulation authority.
static func pages(en: bool = false) -> Array[Dictionary]:
	if en:
		return [
			{
				"title": "1 · Continuing history",
				"body": "A–D each send six requests, numbered 0–5. All 24 are ready at cycle zero; every request must appear once, in order within its own client.\n\nEach client keeps eight state values. A request combines the previous state with its input (0.65 × history + 0.35 × input), then returns a score using fixed weights. History carries earlier inputs into later answers.\n\nState lives in automatic LRU resident slots or encoded backing records. Changed state is written back before eviction and at the end. Follow the recorded reads, reuse and writes to see where history goes."
			},
			{
				"title": "2 · Operations",
				"body": "Select a service group to join the next group, split it, or move the whole group by dragging or using the move controls. Execution goes from top to bottom. Each group reads all inputs, computes all its requests, then returns its results.\n\nClick A/B/C/D to cycle each client's storage representation. Set 1–4 automatic LRU slots; Undo/Redo lets you revise your draft. Run validates dependencies and capacity, then records measured costs, responses and quality.\n\nSelect a recording to inspect its own plan and events. Draft edits do not change old results; restore a recorded plan to vary it. Save in the candidate profile before returning Home; reopen that profile to continue. You can skip this introduction and reopen it later."
			},
			{
				"title": "3 · Public rules",
				"body": "Link: 4B/cycle; each input-group, weight or state transfer starts with 4 setup cycles. Inputs are 64B/request; weights are 64B loaded once. Each request computes for 24 cycles. Each 8B result costs 1 commit + 2 transfer cycles, without new setup.\n\nEvery decoded state uses 64B, even with 8-bit storage. Workspace reserves 64B weights + 72B/request in the largest group, plus resident states and codec temporary space. Capacity is 512B; preflight reserves worst-case encoded size. Actual peak and backing bytes are measured separately. State reads/writes include a 2B length entry; final dirty writes are charged.\n\nRAW64/RLE64 preserve values; RAW8/RLE8 round at initialization and every update. RLE can expand and costs codec work. Quality checks scores AND final state against the unrounded reference: ≤1e-9 in tasks 1–2, ≤0.02 in task 3. The mission lists each task's time, traffic, peak and response limits. These are model costs."
			}
		]
	return [
		{
			"title": "1 · 连续的历史",
			"body": "A–D各有六次请求，编号0–5。24份请求在周期0全部就绪；每份恰好执行一次，同一客户必须保序。\n\n每位客户保留八个状态值。请求将旧状态与本次输入结合（0.65×历史＋0.35×输入），再用固定权重算出分数。之前的输入由此影响之后的回答。\n\n状态留在自动LRU驻留槽，或编码保存在外存记录中。改过的状态在淘汰前和结束时写回。沿实测的读入、复用和写回事件，观察历史去了哪里。"
		},
		{
			"title": "2 · 操作与继续",
			"body": "选中服务组，可合并下一组、拆组；拖动或使用移动按钮调整整组位置。从上到下执行，每组先读取全部输入，算完整组，再逐项返回结果。\n\n点击A/B/C/D切换各客户的存储表示，选择1–4个自动LRU状态槽。撤销/重做可修改草稿。点击运行，先核验依赖和容量，再记录实测成本、响应与质量。\n\n选择旧记录，查看它自己的方案和事件。编辑草稿不会改变旧结果；可取回记录方案继续修改。在候选档中保存后返回首页，再进入同一候选档可继续。本说明可以跳过，也可再次打开。"
		},
		{
			"title": "3 · 公开规则",
			"body": "链路4B/周期；每次组输入、权重或状态搬运先付4周期启动。每请求输入64B，权重64B只读一次；每请求计算24周期。每项8B输出付1周期提交＋2周期搬运，不另收启动。\n\n解码状态始终64B/流，包括8位存储。工作区预留64B权重＋最大组每项72B，再计驻留状态和编码临时空间。硬容量512B；执行前按最坏编码尺寸预检，实测峰值与外存大小分别报告。状态读写包含2B长度目录，结束的脏状态写回也计费。\n\nRAW64/RLE64保留数值；RAW8/RLE8在初始化和每次更新时舍入。RLE可能变大，也消耗编解码工作。分数与最终状态均对照未舍入结果：任务1–2误差≤1e-9，任务3≤0.02。各任务的周期、流量、峰值及响应限制见任务规格。这些是模型成本。"
		}
	]
