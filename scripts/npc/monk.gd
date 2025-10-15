extends StaticBody2D

# Get a reference to the prompt node
@export var npc_name: String = "Monk"
@export var portrait_texture: Texture2D
@export var initial_greeting: String = "Is it enlightenment you seek, dear boy?"
@export_multiline var persona: String = "You are a calm, sage, and preachy monk"

	
@onready var interaction_prompt = $InteractionPrompt

# This function will be called by the player
func show_prompt():
	interaction_prompt.show()

# This function will also be called by the player
func hide_prompt():
	interaction_prompt.hide()

# This is the signal function from before
func _on_chatdetection_body_entered(body):
	if body.is_in_group("Player"):
		body.player_can_interact(self)

# This is the other signal function from before
func _on_chatdetection_body_exited(body):
	if body.is_in_group("Player"):
		body.player_cannot_interact(self)
