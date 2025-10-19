extends Node

var pause_screen_scenes_list = [
	"res://scenes/interior_lvl/house_1.tscn",
    "res://scenes/interior_lvl/hut_1.tscn"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func can_show_pause(scene_path: String) -> bool:
	return scene_path in pause_screen_scenes_list
