extends Node

var pause_screen_scenes_list = [
	"res://scenes/interior_lvl/house_1.tscn",
    "res://scenes/interior_lvl/hut_1.tscn"
]

var previous_scene: String = ""

const SAVE_DIR = "res://save_file/"

func can_show_pause(scene_path: String) -> bool:
	return scene_path in pause_screen_scenes_list

func save_game_slot(save_data: Dictionary) -> bool:
	# Create save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var dir = DirAccess.open(SAVE_DIR.get_basename())
		if dir == null:
			push_error("Failed to create save directory")
			return false
	
	# Find next available slot starting from 02
	var slot_number = 2
	var save_path = ""
	
	while true:
		save_path = SAVE_DIR + "save_file%02d.json" % slot_number
		
		# If file doesn't exist, use this slot
		if not FileAccess.file_exists(save_path):
			break
		
		slot_number += 1
	
	# Write save data to file
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to save game: ", FileAccess.get_open_error())
		return false
	
	file.store_string(json_string)
	print("Game saved to: ", save_path)
	return true

func create_save_data() -> Dictionary:
	var save_data: Dictionary = {
		"previous_scene_path": get_tree().current_scene.scene_file_path,
		#"player_position": get_tree().current_scene.get_node("Player").global_position
	}
	return save_data
