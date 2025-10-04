# In ChatWindow.gd
extends CanvasLayer

# This signal will be emitted when the player submits their text.
# The Player script (or a game manager) will listen for this.
signal player_spoke(text_input)
signal conversation_ended

# Connections to the nodes in the scene (your variables are perfect)
@onready var name_label = $NameLabel
@onready var portrait_rect = $Portrait
@onready var dialogue_text = $DialogueText
@onready var player_input = $PlayerInput
@onready var continue_indicator = $ContinueIndicator

# A new Timer node for the typewriter effect
@onready var typewriter_timer = $TypewriterTimer # IMPORTANT: Add a Timer node named "TypewriterTimer" to your scene

# State variables to manage the flow
var is_typing = false
var is_waiting_for_player_input = false

func _ready():
	# Make sure everything is hidden at the start
	hide()
	player_input.hide()
	continue_indicator.hide()

	# Connectthe PlayerInput's signal to a function in this script
	player_input.text_submitted.connect(_on_player_text_submitted)

# --- PUBLIC FUNCTIONS ---

func show_thinking_indicator():
	# A simple way to show the game is waiting for the LLM.
	# It just displays "..." in the dialogue box.
	dialogue_text.text = "..."
	dialogue_text.visible_characters = 3 # Show all three dots immediately
	
	# Hide the other UI elements to keep it clean
	continue_indicator.hide()
	player_input.hide()
# This is the main function that the Player script will call
func start_conversation(npc_data: Dictionary, initial_message: String):
	show()
	is_waiting_for_player_input = false
	
	name_label.text = npc_data.name
	portrait_rect.texture = npc_data.portrait
	
	# Use the new argument here
	_start_typewriter(initial_message)

# A function to display the next line from the NPC
func display_npc_message(message: String):
	is_waiting_for_player_input = false
	_start_typewriter(message)

# --- INTERNAL LOGIC ---

func _start_typewriter(message: String):
	dialogue_text.text = message
	dialogue_text.visible_characters = 0
	is_typing = true
	
	# Hide all indicators while the NPC is "thinking" and typing
	continue_indicator.hide()
	player_input.hide()
	
	while dialogue_text.visible_characters < len(message):
		dialogue_text.visible_characters += 1
		await get_tree().create_timer(0.04).timeout
		
	is_typing = false
	# NEW: NPC is done talking. Show the UP arrow.
	continue_indicator.play("point_up")
	continue_indicator.show()

func close_conversation():
	hide() # Hide the entire UI
	# Reset all state variables to their default values
	is_typing = false
	is_waiting_for_player_input = false
	# Stop any active timers or animations if you have them
	# For example, stop the continue_indicator from animating
	continue_indicator.stop()
	# Emit the signal so the Player script knows it can move on
	emit_signal("conversation_ended")
	
# This function is called when the player hits Enter in the LineEdit
func _on_player_text_submitted(text: String):
	if text.strip_edges().is_empty():
		return
		
	player_input.hide()
	# NEW: Hide the indicator while we wait for the LLM response.
	continue_indicator.hide()
	
	emit_signal("player_spoke", text)
	player_input.text = ""

# This handles pressing the "continue" button (Enter/Space)
func _unhandled_input(event):
	if not is_visible():
		return

	if Input.is_action_just_pressed("ui_accept"):
		if is_typing:
			# Skip typewriter effect
			#dialogue_text.visible_characters = len(dialogue_text.text)
			is_typing = false
			# NEW: Show the UP arrow since we skipped to the end.
			continue_indicator.play("point_up")
			continue_indicator.show()
		elif not is_waiting_for_player_input:
			# NPC is done, and it's now the Player's turn to type.
			is_waiting_for_player_input = true
			
			# NEW: Show the DOWN arrow to point at the input box.
			continue_indicator.play("point_down")
			continue_indicator.show() # Make sure it's visible
			
			player_input.show()
			player_input.grab_focus()
