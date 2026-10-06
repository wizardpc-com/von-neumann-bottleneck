extends RefCounted
## Presentation of an existing journey_review snapshot only. No model or save access.

static func bridge(english: bool) -> Dictionary:
	return {
		"id":"bridge",
		"title":"从位置与时机，走向承载方式" if not english else "From place and timing to representation",
		"body":"前半程关注数据放在哪里、何时到达。接下来，试着改变它的承载方式：先付的准备成本、随后每次使用的成本，以及实际占用，都能在运行中看见。带着自己的方案继续。" if not english else "The core journey explores where data lives and when it arrives. Next, try changing how it is represented. Measure the preparation you pay first, the cost of later use, and the space it occupies. Keep building your own plans."
	}

static func pages(review: Dictionary, english: bool) -> Array[Dictionary]:
	var representation: Dictionary = _domain(review.get("representation"),5)
	var service: Dictionary = _domain(review.get("service"),3)
	var earned: bool = review.get("complete",false) == true and representation.status == "complete" and service.status == "complete"
	var unavailable: bool = representation.status == "unavailable" or service.status == "unavailable"
	var introduction: String = ("这份回顾只展示目前能确认的已保存成果。有阶段暂时无法确认，请先查看原阶段的恢复提示。草稿留在工作台，两个阶段分别展示自己的结果。" if not english else "This review shows only saved achievements that can currently be confirmed. A stage is unconfirmed; inspect its recovery notice. Drafts stay in the workbench, and each stage presents its own results.") if unavailable else ("这份回顾来自已保存并重新验收的方案。草稿留在工作台，成果留在这里。两个阶段分别展示自己的结果。" if not english else "This review comes from saved plans revalidated for their tasks. Drafts stay in the workbench; measured achievements appear here. Each stage presents its own results.")
	var result: Array[Dictionary] = [{
		"id":"saved_work",
		"title":"看看你留下了什么" if not english else "Look at what you made",
		"body":("表示：%s　持续状态与服务：%s" if not english else "Representation: %s   Persistent state and service: %s") % [_progress(representation,5,english),_progress(service,3,english)]+"\n\n"+introduction
	}]
	result.append(_representation_page(representation,english))
	result.append(_service_page(service,english))
	result.append({
		"id":"closure" if earned else "continue",
		"title":("这段旅程，由你完成" if not english else "You brought this journey here") if earned else ("从这里接着走" if not english else "Continue from here"),
		"body":("你为信息选择了承载方式，也为不断变化的历史安排了去处。上面的数字，是你的方案留下的结果。\n\n表示与服务的推荐旅程在这里收束。愿你记住的，是那个亲手让事情发生变化的时刻。\n\n随时回来看看，也可以继续优化或尝试追加委托。预测是独立的可选探索，进展仅保留在本次会话。\n\nA Thought Within the World" if not english else "You chose how information is carried and where changing history can remain. The numbers above are results of your plans.\n\nThe recommended Representation and Service journey closes here. Take with you the moment when your own changes made a difference.\n\nCome back whenever you like. You can keep refining your plans or try commissions. Prediction is a separate optional exploration; its progress lasts only for that session.\n\nA Thought Within the World") if earned else ("表示与服务的联合收束尚未成立。上面能确认的成果仍然属于你；回到相应阶段，继续未完成的任务，再保存并回顾。\n\n若某个阶段无法确认，请先查看它的恢复提示。这里不会把草稿或无法读取的记录当成完成。" if not english else "The combined Representation and Service closure is not earned yet. The achievements confirmed above are still yours. Return to the relevant stage, continue its unfinished tasks, then Save and review again.\n\nIf a stage cannot be confirmed, inspect its recovery notice first. Drafts and unreadable records do not count as completion.")
	})
	return result

static func _progress(item: Dictionary, count: int, english: bool) -> String:
	if item.status == "unavailable": return "待确认" if not english else "Unconfirmed"
	return "%d / %d" % [item.completed.size(),count]

static func _domain(value: Variant, count: int) -> Dictionary:
	# Refuse incomplete presentation inputs; only journey_review supplies acceptance.
	var unavailable := {"status":"unavailable","completed":[],"evidence":[],"error":"review_input"}
	if not value is Dictionary: return unavailable
	var item: Dictionary = value
	var status: String = str(item.get("status","unavailable"))
	if status not in ["empty","partial","complete","unavailable"]: return unavailable
	if status in ["empty","unavailable"]:
		return {"status":status,"completed":[],"evidence":[],"error":str(item.get("error",""))}
	if not item.get("completed") is Array or not item.get("evidence") is Array: return unavailable
	var completed: Array = item.completed
	var evidence: Array = item.evidence
	if completed.size() > count or completed.size() != evidence.size(): return unavailable
	var seen: Dictionary = {}
	for row: Variant in evidence:
		if not row is Dictionary or not row.get("task") is int: return unavailable
		var task: int = row.task
		if task < 0 or task >= count or task not in completed or seen.has(task): return unavailable
		seen[task] = true
		if count == 5:
			if not row.get("metrics") is Array or row.metrics.is_empty(): return unavailable
			for metrics: Variant in row.metrics:
				if not _numbers(metrics,["total_cycles","preparation_cycles","service_cycles","stored_bytes"]): return unavailable
		elif not _numbers(row.get("metrics"),["total_cycles","state_read_bytes","state_write_bytes","all_streams_first_cycle"]): return unavailable
	if status == "complete" and completed.size() != count: return unavailable
	return item

static func _numbers(value: Variant, keys: Array) -> bool:
	if not value is Dictionary: return false
	for key: String in keys:
		if not value.get(key) is int or value[key] < 0: return false
	return true

static func _boundary(item: Dictionary, english: bool) -> String:
	if item.status == "empty":
		return "尚无已保存的实测成果。进入这个阶段，运行自己的方案并保存；再回来看看它留下了什么。" if not english else "No saved measured achievements yet. Enter this stage, run your own plan and Save. Come back to see what it leaves behind."
	if item.status == "unavailable":
		return ("暂时无法确认这个阶段的成果（%s）。请在原阶段检查恢复提示；此处不恢复文件，也不宣告完成。" if not english else "This stage's achievements cannot be confirmed right now (%s). Inspect its recovery notice in the stage. This view does not recover files or declare completion.") % str(item.get("error","review_input"))
	if item.completed.is_empty():
		return "已保存的方案尚未通过任务验收。可以回到工作台继续修改和运行；未运行的草稿不算成果。" if not english else "The saved plans do not yet meet any task contracts. Continue editing and measuring in the workbench; unrun drafts are not achievements."
	return ""

static func _representation_page(item: Dictionary, english: bool) -> Dictionary:
	var lines: Array[String] = []
	var boundary: String = _boundary(item,english)
	if not boundary.is_empty(): lines.append(boundary)
	else:
		lines.append(("五份任务都有了你自己的达标方案。信息的承载改变了，准备、使用与占用的成本也变得可见。" if not english else "All five tasks have accepted plans of your own. Changing how information is carried made preparation, use and storage costs visible.") if item.status == "complete" else ("这些任务已有达标方案。准备、使用与占用，各自留下了真实的成本；其余任务可从工作台继续。" if not english else "These tasks have accepted plans. Preparation, use and storage each left a measured cost. Continue the remaining tasks in the workbench."))
		for row: Dictionary in item.evidence:
			var orders: Array[String] = []
			for order: int in row.metrics.size():
				var m: Dictionary = row.metrics[order]
				orders.append(("订单%d：准备%d＋服务%d＝%d周期，占用%dB" if not english else "Order %d: prepare %d + serve %d = %d cycles; stored %d B") % [order+1,m.preparation_cycles,m.service_cycles,m.total_cycles,m.stored_bytes])
			lines.append(("任务%d\n" if not english else "Task %d\n") % (int(row.task)+1)+"\n".join(orders))
	return {"id":"representation","title":("信息的承载 · " if not english else "How information is carried · ")+_progress(item,5,english),"body":"\n\n".join(lines)}

static func _service_page(item: Dictionary, english: bool) -> Dictionary:
	var lines: Array[String] = []
	var boundary: String = _boundary(item,english)
	if not boundary.is_empty(): lines.append(boundary)
	else:
		lines.append(("三份合同都得到了回答。你的方案安排了状态的存放、搬运与使用，也照顾了等待回应的请求。" if not english else "All three contracts have been met. Your plans arranged how state is stored, moved and used, while serving requests waiting for an answer.") if item.status == "complete" else ("这些合同已有达标方案。状态的存放与搬运、请求的回应时间，都可以从结果追溯；其余合同可继续。" if not english else "These contracts have accepted plans. Their results show state storage and traffic, and when requests received answers. The remaining contracts are open to continue."))
		for row: Dictionary in item.evidence:
			var m: Dictionary = row.metrics
			lines.append(("合同%d：%d周期，状态搬运%dB；全部流首响应到齐于%d周期" if not english else "Contract %d: %d cycles; state traffic %d B; all streams first answered by cycle %d") % [int(row.task)+1,m.total_cycles,int(m.state_read_bytes)+int(m.state_write_bytes),m.all_streams_first_cycle])
	return {"id":"service","title":("让历史继续服务 · " if not english else "Keeping history useful · ")+_progress(item,3,english),"body":"\n\n".join(lines)}
