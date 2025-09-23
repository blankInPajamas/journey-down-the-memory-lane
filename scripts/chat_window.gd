# In ChatWindow.gd
extends CanvasLayer

# This signal will be emitted when the player submits their text.
# The Player script (or a game manager) will listen for this.
signal player_spoke(text_input)

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

# This is the main function that the Player script will call
func start_conversation(npc_data: Dictionary):
	show()
	is_waiting_for_player_input = false # NPC is talking first
	
	# Set the static data
	name_label.text = npc_data.name
	portrait_rect.texture = npc_data.portrait
	
	# Start the typewriter with the NPC's greeting
	_start_typewriter(npc_data.greeting)

# A function to display the next line from the NPC
func display_npc_message(message: String):
	is_waiting_for_player_input = false
	_start_typewriter(message)

# --- INTERNAL LOGIC ---

func _start_typewriter(message: String):
	# Set up the typewriter effect
	dialogue_text.text = message
	dialogue_text.visible_characters = 0
	is_typing = true
	
	# Hide UI elements while typing
	continue_indicator.hide()
	player_input.hide()
	
	# Loop to reveal characters
	while dialogue_text.visible_characters < len(dialogue_text.text):
		dialogue_text.visible_characters += 1
		# Start the timer to wait before showing the next character
		await typewriter_timer.timeout
		
	# Typing is finished
	is_typing = false
	# Show the continue indicator to signal the NPC is done
	continue_indicator.show()

# This function is called when the player hits Enter in the LineEdit
func _on_player_text_submitted(text: String):
	# Don't accept empty messages
	if text.strip_edges().is_empty():
		return
		
	# Hide the input box
	player_input.hide()
	
	# Emit our custom signal with the player's text
	emit_signal("player_spoke", text)
	
	# Optional: Clear the input box for next time
	player_input.text = ""

# This handles pressing the "continue" button (Enter/Space)
func _unhandled_input(event):
	# Only handle input if the dialogue box is visible
	if not is_visible():
		return

	if Input.is_action_just_pressed("ui_accept"):
		if is_typing:
			# If the NPC is still typing, skip to the end of the text
			dialogue_text.visible_characters = len(dialogue_text.text)
		elif not is_waiting_for_player_input:
			# If the NPC is done talking, it's now the player's turn
			is_waiting_for_player_input = true
			continue_indicator.hide()
			player_input.show()
			player_input.grab_focus()
