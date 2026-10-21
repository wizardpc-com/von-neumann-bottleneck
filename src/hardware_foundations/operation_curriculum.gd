class_name OperationCurriculum
extends RefCounted
## One additional operation per prologue lesson. These are invitations, not gates.
## Existing simulation and official test requirements remain authoritative.
const LESSONS := {
	"tutorial": ["wire", "从端口拖到端口接线；右键划线可以拆线。先预测，再运行。", "Drag between ports to wire; sweep with the right button to remove a wire. Predict before running."],
	"half_adder": ["place", "从元件栏拖出元件；放错可撤销。SUM 是和，CARRY 是进位，两种输出都要检查。", "Drag a part from the palette; undo mistakes. SUM and CARRY have different roles; check both outputs."],
	"full_adder": ["reuse", "把上一关封装的半加器当作零件使用。悬停查看端口，不必重搭其内部。", "Reuse your sealed half adder. Hover to inspect its ports instead of rebuilding its internals."],
	"latch": ["state", "先改变输入，再运行，观察 Q 是否保留。状态与当前输入不是同一件事。", "Change the input, run, and observe whether Q is retained. State is not the same as the current input."],
	"register": ["debug", "每次只改变一个测试输入，对照数据、LOAD 与 Q。方案会自动保留；尝试另一种设计时，可新建独立方案。", "Change one input at a time; compare data, LOAD and Q. Plans are retained automatically; create a separate plan to try a different design."],
	"alu": ["control", "先读 OP0、OP1 对应的操作，再换输入测试。不要只验证一种运算。", "Read the operations selected by OP0 and OP1, then test different inputs. Verify more than one operation."],
	"ram": ["width", "先检查端口位宽：4 位数据是一条总线，不是四个针脚。再改变地址和读写输入，核对实际输出。", "Check port widths: 4-bit data uses one bus, not four pins. Then vary address and read/write inputs and check the output."],
	"cpu": ["compose", "逐个检查复用模块的接口，再联成机器。一次只验证一段连接，避免同时猜多个问题。", "Check each reused module's interface before composing the machine. Verify one connection at a time."],
	"load_store": ["trace", "先猜下一次会读还是写，再运行并沿回放核对。动效只解释这次真实结果。", "Predict the next read or write, then compare with playback. Animation explains the actual run."],
	"selector": ["undo", "放心尝试另一种连接。拆错或移动错时，用撤销恢复，不必重搭整张图。", "Try another connection. Undo an accidental removal or move rather than rebuilding the whole circuit."],
	"selector4": ["navigate", "电路变大后，缩放与平移工作台来检查端口；别把元件挤成一团。", "As the circuit grows, zoom and pan to inspect ports instead of squeezing parts together."],
	"parity": ["cases", "别只试一组输入。正式测试会覆盖多种情况；失败时先找期望与实际的差异。", "Do not rely on one input. Official tests cover several cases; compare expected and actual results when one fails."],
	"alarm": ["save", "方案菜单可新建或切换独立工作台；新方案从初始元件开始，原方案仍可回看。", "Use the plan menu to create or switch workbenches. A new plan starts with initial parts; the old one remains available."],
	"delay": ["help", "卡住时先查看任务说明，再按需打开分层提示。提示不代替你自己的测试。", "When stuck, revisit the task, then open a hint only as needed. Hints do not replace your own tests."]
}
static func lesson(level_id: StringName, english: bool = false) -> Dictionary:
	var entry: Array = LESSONS.get(String(level_id),[])
	return {} if entry.is_empty() else {"skill":entry[0],"text":entry[2 if english else 1]}
