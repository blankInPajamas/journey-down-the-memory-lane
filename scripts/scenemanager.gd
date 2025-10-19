# In SceneManager.gd
extends Node

const house1 = preload("res://scenes/interior_lvl/house_1.tscn")
const hut1 = preload("res://scenes/interior_lvl/hut_1.tscn")
const hut2 = preload("res://scenes/interior_lvl/hut_2.tscn")
const oldhouse = preload("res://scenes/interior_lvl/old_house.tscn")
const shed = preload("res://scenes/interior_lvl/shed.tscn")
const windmill = preload("res://scenes/interior_lvl/windmill.tscn")
const level1 = preload("res://scenes/main_level/level_1.tscn")

var spawn_door_tag 

signal on_trigger_player_spawn

func go_to_level(level_tag, destination_tag):
	var scene_to_load
	
	match level_tag:
		"house1":
			scene_to_load = house1
		"hut1":
			scene_to_load = hut1
		"hut2":
			scene_to_load = hut2
		"shed":
			scene_to_load = shed
		"windmill":
			scene_to_load = windmill
		"oldhouse":
			scene_to_load = oldhouse
		"level1":
			scene_to_load = level1	
	if scene_to_load != null:
		spawn_door_tag = destination_tag
		get_tree().change_scene_to_packed(scene_to_load)
	

func trigger_player_spawn(position: Vector2):
	on_trigger_player_spawn.emit(position)
