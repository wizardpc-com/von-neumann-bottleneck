extends RefCounted
## Semantic visit reduction. Never a source of game completion or simulation input.
const COUNTERS := ["foreground_ms","background_ms","feedback_ms","connections","connection_rejections","branches","wire_deletes","component_deletes","incident_wire_removals","undo_count","redo_count","debug_runs","official_runs","max_hint_stage"]
const METRICS := ["cycles","cost","total_cycles","ram_read_bytes","ram_write_bytes","peak_extra_bytes","passed_cases","case_count"]
var visits: Dictionary = {}

func observe(event: Dictionary) -> Dictionary:
	var id: String = str(event.get("visit_id",""))
	var kind: String = str(event.get("event",""))
	var p: Dictionary = event.get("payload",{})
	if id.is_empty(): return {}
	if kind == "level_start":
		var summary: Dictionary = {"visit_id":id,"chapter_id":p.get("chapter_id",""),"level_id":p.get("level_id",""),"completed":bool(p.get("completed",false)),"duration_unknown":false,"strategy":"unknown"}
		for key: String in COUNTERS: summary[key]=0
		visits[id]=summary
	if not visits.has(id): return {}
	var s: Dictionary = visits[id]
	match kind:
		"visit_time":
			var key: String = str(p.get("kind",""))+"_ms"
			if key in ["foreground_ms","background_ms","feedback_ms"]: s[key]+=maxi(0,int(p.get("duration_ms",0)))
		"level_complete": s.completed=true
		"official_run":
			s.official_runs+=1
			var m: Dictionary = p.duplicate(); m.merge(p.get("metrics",{}),true)
			for key: String in METRICS:
				if m.has(key): s[key]=m[key]
			if p.get("strategy") in ["direct","full","batch","cache","buffer"]: s.strategy=p.strategy
		"hint_used": s.max_hint_stage=maxi(s.max_hint_stage,mini(3,int(p.get("stage",0))))
		"player_action":
			match str(p.get("action","")):
				"connection_rejected": s.connection_rejections+=1
				"undo": s.undo_count+=1
				"redo": s.redo_count+=1
				"debug_run","debug_run_request": s.debug_runs+=1
		"modification":
			var op: String = str(p.get("operation",""))
			if op in ["connect","waypoint","waypoint_to_input","branch","branch_waypoint","move_endpoint","move_endpoint_to_empty","move_endpoint_to_wire"]: s.connections+=1
			elif op == "board_edit" and int(p.get("added_wires",0))>0: s.connections+=1
			if op in ["branch","branch_waypoint"]: s.branches+=1
			s.wire_deletes+=int(p.get("explicit_wire_deletes",0))
			s.component_deletes+=int(p.get("removed_components",0))
			s.incident_wire_removals+=int(p.get("incident_wire_removals",0))
		"visit_summary": visits.erase(id)
		"level_exit":
			s.duration_unknown=bool(p.get("duration_unknown",false))
			s["reason"]=str(p.get("reason",""))
			visits.erase(id)
			return s.duplicate(true)
	return {}
