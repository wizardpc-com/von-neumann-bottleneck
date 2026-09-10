class_name TaskTreeLayout
extends RefCounted
## Presentation layout derived from prerequisite DAGs. No completion or save mutation.
const NODE_SIZE := Vector2(230,90)
const COLUMN: float = 315
const ROW: float = 140
static func build(tasks: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {"positions":{},"regions":{},"size":Vector2.ZERO,"errors":[]}
	var by_key: Dictionary = {}
	var members: Dictionary = {}
	for task: Dictionary in tasks:
		by_key[task.key]=task
		if not members.has(task.region): members[task.region]=[]
		members[task.region].append(task)
	var region_parents: Dictionary = {}
	for region: int in members:
		region_parents[region]=[]
		for task: Dictionary in members[region]:
			for dep: String in task.dependencies:
				if not by_key.has(dep): result.errors.append("Missing prerequisite: "+dep); continue
				var parent: int = by_key[dep].region
				if parent!=region and not region_parents[region].has(parent): region_parents[region].append(parent)
	var region_rank: Dictionary = _ranks(region_parents)
	if region_rank.size()!=members.size(): result.errors.append("Cyclic region dependencies"); return result
	var local_positions: Dictionary = {}
	var dimensions: Dictionary = {}
	for region: int in members:
		var parents: Dictionary = {}
		for task: Dictionary in members[region]:
			parents[task.key]=[]
			for dep: String in task.dependencies:
				if by_key.has(dep) and by_key[dep].region==region: parents[task.key].append(dep)
		var ranks: Dictionary = _ranks(parents)
		if ranks.size()!=parents.size(): result.errors.append("Cyclic task dependencies"); return result
		var layers: Dictionary = {}
		for key: String in ranks:
			if not layers.has(ranks[key]): layers[ranks[key]]=[]
			layers[ranks[key]].append(key)
		var max_members: int = 1
		for layer: Array in layers.values(): max_members=maxi(max_members,layer.size())
		var height: float = max_members*ROW+100
		var ys: Dictionary = {}
		for rank: int in range(layers.size()):
			var layer: Array = layers[rank]
			layer.sort_custom(func(a: String,b: String) -> bool:
				var left: float = _barycenter(parents[a],ys)
				var right: float = _barycenter(parents[b],ys)
				return a<b if is_equal_approx(left,right) else left<right)
			for index: int in range(layer.size()):
				var y: float = (height-NODE_SIZE.y)/2+(index-(layer.size()-1)/2.0)*ROW
				ys[layer[index]]=y
				local_positions[layer[index]]=Vector2(50+rank*COLUMN,y)
		dimensions[region]=Vector2((layers.size()-1)*COLUMN+NODE_SIZE.x+100,height)
	var rank_regions: Dictionary = {}
	for region: int in region_rank:
		if not rank_regions.has(region_rank[region]): rank_regions[region_rank[region]]=[]
		rank_regions[region_rank[region]].append(region)
	var widths: Dictionary = {}
	var world_width: float = 0
	for rank: int in rank_regions:
		var width: float = -100
		for region: int in rank_regions[rank]: width+=dimensions[region].x+100
		widths[rank]=width; world_width=maxf(world_width,width)
	var y: float = 60
	for rank: int in range(rank_regions.size()):
		var x: float = 60+(world_width-float(widths[rank]))/2
		var max_height: float = 0
		rank_regions[rank].sort()
		for region: int in rank_regions[rank]:
			var origin := Vector2(x,y)
			result.regions[region]=Rect2(origin,dimensions[region])
			for task: Dictionary in members[region]: result.positions[task.key]=origin+local_positions[task.key]
			x+=dimensions[region].x+100
			max_height=maxf(max_height,dimensions[region].y)
		y+=max_height+110
	result.size=Vector2(world_width+120,y)
	return result
static func _ranks(parents: Dictionary) -> Dictionary:
	var ranks: Dictionary = {}
	for pass_index: int in range(parents.size()+1):
		var changed: bool = false
		for key: Variant in parents:
			if ranks.has(key): continue
			var ready: bool = true
			var rank: int = 0
			for parent: Variant in parents[key]:
				if not ranks.has(parent): ready=false; break
				rank=maxi(rank,int(ranks[parent])+1)
			if ready: ranks[key]=rank; changed=true
		if not changed: break
	return ranks
static func _barycenter(parents: Array,positions: Dictionary) -> float:
	var sum: float = 0
	for parent: Variant in parents: sum+=float(positions.get(parent,0))
	return sum/maxi(1,parents.size())
