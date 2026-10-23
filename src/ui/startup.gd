extends Control

const Cinematic = preload("res://src/ui/cinematic_player.gd")
const HOME: String = "res://src/ui/prototype_hub.tscn"


func _ready() -> void:
	call_deferred("_begin")


func _begin() -> void:
	if not Cinematic.automated_launch():
		if bool(GlobalSave.game_player_content.completed_levels.get(&"load_store", false)):
			Cinematic.take_once(&"prologue_complete")
		var review: Dictionary = preload("res://src/campaign/second_act_tasks.gd").saved_review()
		if str(review.get("representation", {}).get("status", "")) == "complete":
			Cinematic.take_once(&"chapter5_complete")
		if Cinematic.new_player(GlobalSave.storage_path, GlobalSave.workbench_storage_path):
			var movie: CinematicPlayer = Cinematic.present_once(self, &"opening")
			if movie != null:
				await movie.finished
				movie.queue_free()
		else:
			Cinematic.take_once(&"opening")
	get_tree().call_deferred("change_scene_to_file", HOME)
