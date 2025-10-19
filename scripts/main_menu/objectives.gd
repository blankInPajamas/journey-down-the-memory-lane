extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(Global.previous_scene)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_pressed() -> void:
	if Global.previous_scene != "":
		get_tree().change_scene_to_file(Global.previous_scene)


func _on_save_game_pressed() -> void:
	Global.save_game_slot(Global.create_save_data())
	pass # Replace with function body.
