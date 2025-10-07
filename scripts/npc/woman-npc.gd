extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var prompt: TextureRect = $InteractPrompt

var player_in_range: bool = false
var current_direction = "down"
var chat_window_scene = preload("res://scenes/chat_window.tscn")
var chat_window_instance: Node = null 

func _ready():
	# Connect the area signals
	detection_area.connect("body_entered", _on_body_entered)
	detection_area.connect("body_exited", _on_body_exited)


func _on_body_entered(body):
	if body.name == "player":  # Replace with your player node name if different
		print("Someone entered!")
		var dir = _get_direction_from_player(body)
		current_direction = dir
		_update_sprite(dir)
		player_in_range = true
		prompt.visible = true


func _on_body_exited(body):
	if body.name == "player":
		print("Someone left!")
		sprite.play("look_down")
		prompt.visible = false
		player_in_range = false


func _get_direction_from_player(player) -> String:
	var diff = player.global_position - global_position
	
	if abs(diff.x) > abs(diff.y):
		return "right" if diff.x > 0 else "left"
	else:
		return "down" if diff.y > 0 else "up"


func _update_sprite(dir: String):
	match dir:
		"left":
			sprite.play("look_left")
		"right":
			sprite.play("look_right")
		"up":
			sprite.play("look_up")
		"down":
			sprite.play("look_down")

func _open_chat_window():
	if chat_window_instance:
		return  # prevent multiple windows

	chat_window_instance = chat_window_scene.instantiate()

	# Add to the root viewport (always on top of the current scene)
	get_tree().root.add_child(chat_window_instance)

	# Optional: center it on screen
	if chat_window_instance is Control:
		chat_window_instance.set_anchors_preset(Control.PRESET_CENTER)
		chat_window_instance.position = get_viewport_rect().size / 2

	print("conversation start - chat window opened")

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_open_chat_window()
