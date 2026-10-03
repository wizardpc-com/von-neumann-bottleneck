extends RefCounted
## Public assets, orders, machine costs and goals; never contains reference plans.
static func asset(kind: int = 0) -> Array[int]:
	var values: Array[int] = []
	for i: int in 64:
		var value: int = (i * 37 + 11) % 256
		match kind:
			0: value = 5 if i < 16 else (8 if i >= 48 else value)
			1: value = 9 if i < 24 else (3 if i >= 40 else value)
			2: value = 2 + i / 16
			3: value = 7
			4: value = 6 if i < 20 else (4 if i >= 44 else (i * 19 + 13) % 256)
			5: value = 2 if i < 18 else (11 if i >= 46 else (i * 29 + 7) % 256)
		values.append(value)
	return values

static func scan() -> Array[int]:
	var result: Array[int] = []
	for i: int in 64: result.append(i)
	return result

static func spec(name: String, kind: int, addresses: Array, cache: int = 64, online: bool = false, clients: int = 1) -> Dictionary:
	return {"name":name,"data":asset(kind),"addresses":addresses.duplicate(),"bandwidth":1,"decoder":8,"latency":4,"cache_bytes":cache,"scratch_limit":64,"online":online,"clients":clients,"encoder":8}

static func orders(task: int) -> Array[Dictionary]:
	match task:
		0: return [spec("Mixed scan",0,scan())]
		1: return [spec("Interior revisits",1,[20,43,20,43,20,43],32)]
		2: return [spec("Band scan",2,scan()),spec("Band endpoints",2,[0,63,0,63,0,63,0,63],32)]
		3: return [spec("Prepare + short read",3,[0],64,true),spec("Prepare + eight cold scans",3,scan(),64,true,8)]
		4: return [spec("Asset A scan",4,scan()),spec("Asset B revisits",5,[4,59,4,59,4,59],40)]
	return []

static func goals(task: int) -> Array[Dictionary]:
	match task:
		0: return [{"total_cycles":136,"stored_bytes":60}]
		1: return [{"total_cycles":38,"traffic_bytes":16,"stored_bytes":52}]
		2: return [{"total_cycles":128,"stored_bytes":36},{"total_cycles":38,"traffic_bytes":16,"stored_bytes":36}]
		3: return [{"total_cycles":105,"stored_bytes":80},{"total_cycles":930,"stored_bytes":80}]
		4: return [{"total_cycles":135,"stored_bytes":50},{"total_cycles":38,"traffic_bytes":18,"stored_bytes":50}]
	return []

static func title(task: int, en: bool = false) -> String:
	return (["1 · Mixed scan","2 · Interior hotspots","3 · Dense and sparse","4 · Prepare once, serve","5 · Two assets, one plan"] if en else ["1 · 混合扫描","2 · 内部热点","3 · 密集与稀疏","4 · 准备一次，再服务","5 · 两份资产，一个方案"])[task]

static func hint(task: int, en: bool = false) -> String:
	return (["Inspect real payload sizes and decode work for changing bytes versus runs.","Compare retained decoded ranges, restored-but-unrequested bytes, and whole-asset storage.","Each extra request has a cost. Compare a scan with repeated endpoint reads using the same partition.","Inspect preparation source reads and writes before judging a faster service. Eight clients share preparation, each starts with a cold cache.","Inspect both public assets. A boundary helps only if its measured cost works for both orders."] if en else ["比较变化字节与重复字节的实际载荷大小、解码工作。","比较缓存保留的区间、未请求却恢复的字节，以及整份资产存储。","每次额外请求都有成本；用同一划分比较扫描与端点复访。","先看准备阶段的源读取与写入，再判断服务加速。八位客户共用一次准备，各自从空缓存开始。","观察两份公开资产；一个边界只有同时满足两份订单的实测成本才有用。"])[task]
