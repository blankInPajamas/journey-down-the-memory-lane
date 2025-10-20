# chat_window.gd
extends CanvasLayer

signal player_spoke(text_input)
signal conversation_ended

# Connections to the nodes in the scene
@onready var name_label = $NameLabel
@onready var portrait_rect = $Portrait
@onready var dialogue_text = $DialogueText
@onready var player_input = $PlayerInput
@onready var continue_indicator = $ContinueIndicator

# NOTE: The "OllamaRequest" HTTPRequest node must exist in your scene.

@onready var relationship_feedback_label = $RelationshipFeedbackLabel

# State variables to manage the flow
var is_typing = false
var is_waiting_for_player_input = false

func _ready():
	hide()
	player_input.hide()
	continue_indicator.hide()
	relationship_feedback_label.hide()

	# This connection is essential for submitting text
	player_input.text_submitted.connect(_on_player_text_submitted)

# --- PUBLIC FUNCTIONS ---

func display_relationship_change(change: int):
	if change > 0:
		relationship_feedback_label.text = "Relationship improved (+" + str(change) + ")"
		relationship_feedback_label.show()
	elif change < 0:
		relationship_feedback_label.text = "Relationship worsened (" + str(change) + ")"
		relationship_feedback_label.show()
	else:
		# If no change, keep it hidden
		relationship_feedback_label.hide()
		

func show_thinking_indicator():
	dialogue_text.text = "..."
	dialogue_text.visible_characters = 3 
	relationship_feedback_label.hide()
	continue_indicator.hide()
	player_input.hide()

func start_conversation(npc_data: Dictionary, initial_message: String):
	show()
	is_waiting_for_player_input = false
	name_label.text = npc_data.name
	portrait_rect.texture = npc_data.portrait
	_start_typewriter(initial_message)

func display_npc_message(message: String):
	is_waiting_for_player_input = false
	_start_typewriter(message)

# --- INTERNAL LOGIC ---

func _start_typewriter(message: String):
	dialogue_text.text = message
	dialogue_text.visible_characters = 0
	is_typing = true
	
	continue_indicator.hide()
	player_input.hide()
	
	while dialogue_text.visible_characters < len(message):
		dialogue_text.visible_characters += 1
		await get_tree().create_timer(0.04).timeout
		
	is_typing = false
	# NPC is done. Show the UP arrow.
	continue_indicator.play("point_up")
	continue_indicator.show()

func close_conversation():
	hide() 
	is_typing = false
	is_waiting_for_player_input = false
	relationship_feedback_label.hide()
	continue_indicator.stop()
	emit_signal("conversation_ended")
	
func _on_player_text_submitted(text: String):
	if text.strip_edges().is_empty():
		return
		
	player_input.hide()
	continue_indicator.hide()
	
	# --- FIX: This is the state reset you were missing ---
	# We are no longer waiting for player input,
	# we are now waiting for the backend response.
	is_waiting_for_player_input = false 
	
	emit_signal("player_spoke", text)
	player_input.text = ""

# This handles pressing the "continue" button (Enter/Space)
func _unhandled_input(event):
	if not is_visible():
		return

	if Input.is_action_just_pressed("ui_accept"):
		if is_typing:
			# Skip typewriter
			dialogue_text.visible_characters = len(dialogue_text.text)
			is_typing = false
			continue_indicator.play("point_up")
			continue_indicator.show()
		
		# This is the block that opens the text box
		elif not is_waiting_for_player_input:
			relationship_feedback_label.hide()
			is_waiting_for_player_input = true
			continue_indicator.play("point_down")
			continue_indicator.show() 
			player_input.show()
			player_input.grab_focus()
