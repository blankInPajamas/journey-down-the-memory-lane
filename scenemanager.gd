# In SceneManager.gd
extends Node

var current_scene: Node
var next_spawn_name: String = ""

func _ready():
	# Keep track of the initially loaded scene
	current_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)

func switch_scene(new_scene_path: String, spawn_name: String):
	# Store where we want to spawn in the next scene
	next_spawn_name = spawn_name
	
	# Deferred call is safer for scene switching
	get_tree().call_deferred("change_scene_to_file", new_scene_path)
