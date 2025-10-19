extends Node2D

# EXPORTED VARIABLES: Set these in the Godot Inspector for each door
@export var destination_level_tag: String  # e.g., "res://scenes/interiors/old_woman_house.tscn"
@export var destination_door_tag: String   # A unique name for the entrance in the next scene

@onready var interaction_prompt = $InteractionPrompt
@onready var spawn=$Spawn
# This function is the same as the NPC's prompt logic
func show_prompt():
	interaction_prompt.show()

func hide_prompt():
	interaction_prompt.hide()

# Connect these signals to this script in the editor
func _on_body_entered(body):
	if body.is_in_group("Player"):
		# Tell the player they can interact with THIS door
		body.can_interact_with_door(self)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		body.cannot_interact_with_door(self)
