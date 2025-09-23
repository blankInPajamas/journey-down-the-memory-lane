# Player.gd
extends CharacterBody2D

# Exporting the variable allows you to change the speed in the Inspector.
@export var speed: float = 100.0
var conversation_history = [] # Stores the entire conversation
var npc_persona = "" # Stores the NPC's core personality prompt
var is_chatting = false
@onready var ollama_request = ChatWindow.get_node("OllamaRequest")

# --- This function starts a NEW conversation ---
func start_new_conversation(npc_node):
	is_chatting = true
	npc_in_range = npc_node # Keep track of who we are talking to
	npc_in_range.hide_prompt()
	
	# Clear any old conversation
	conversation_history.clear()
	
	# Get the NPC's persona and initial greeting
	# IMPORTANT: You'll need to add a `persona` export variable to your npc.gd
	npc_persona = npc_in_range.persona 
	var initial_greeting = npc_in_range.initial_greeting
	
	# Add the NPC's first line to the history
	conversation_history.append({"sender": "npc", "text": initial_greeting})
	
	# Display the first message
	var npc_data = {
		"name": npc_in_range.npc_name,
		"portrait": npc_in_range.portrait_texture
	}
	ChatWindow.start_conversation(npc_data, initial_greeting)
	
	

func _on_player_spoke(text: String):
	# Add the player's message to the history
	conversation_history.append({"sender": "player", "text": text})
	
	ChatWindow.show_thinking_indicator()
	print("Sending request to backend with history: ", conversation_history)
	
	# Create the data payload with the history and persona
	var body = JSON.stringify({
		"history": conversation_history,
		"persona": npc_persona
	})
	
	var headers = ["Content-Type: application/json"]
	ollama_request.request("http://127.0.0.1:5000/interact", headers, HTTPClient.METHOD_POST, body)

# --- This function receives the LLM's response ---
func _on_ollama_request_completed(result, response_code, headers, body):
	print("SUCCESS! The request_completed signal was received! Code: ", response_code)
	
	# Let's also see what the backend sent back
	print("Raw response body: ", body.get_string_from_utf8())
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var npc_message = json.get("npc_message", "...")
			# Add the NPC's new response to the history
			conversation_history.append({"sender": "npc", "text": npc_message})
			ChatWindow.display_npc_message(npc_message)
	else:
		# Handle error
		ChatWindow.display_npc_message("I... I can't think of what to say.")
		
# A reference to the AnimatedSprite2D node.
# The '@onready' keyword ensures the node is available when the variable is first used.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# This variable will store the last direction of movement to keep the correct
# idle animation when the player stops.
var last_direction: Vector2 = Vector2(0, 1) # Default to facing down

func _physics_process(delta: float) -> void:
	# --- 1. Get Player Input ---
	# This creates a directional vector from the input actions.
	# Input.get_axis() returns a value between -1.0 and 1.0, making it
	# perfect for smooth movement with gamepads or keyboards.
	var input_direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# --- 2. Set Velocity ---
	# We normalize the input_direction to ensure that diagonal movement isn't faster
	# than moving straight. Then we multiply by the desired speed.
	velocity = input_direction.normalized() * speed

	# --- 3. Move the Player ---
	# This is the core Godot function for moving a CharacterBody2D.
	# It moves the body along the velocity vector and handles collisions.
	move_and_slide()

	# --- 4. Update Animations ---
	update_animation(input_direction)

func _ready():
	# Connect to the ChatWindow's custom signal
	ChatWindow.player_spoke.connect(_on_player_spoke)
	ollama_request.request_completed.connect(_on_ollama_request_completed)


func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_accept"):
		if not ChatWindow.is_visible() and npc_in_range != null:
			start_new_conversation(npc_in_range)
	# The logic for closing the window should now be handled inside ChatWindow.gd
			
func update_animation(direction: Vector2) -> void:
	# If the player is not moving, play the idle animation.
	if direction == Vector2.ZERO:
		play_idle_animation()
	else:
		# Update last_direction only when there is movement.
		last_direction = direction
		play_walk_animation(direction)
	
	# Flip the sprite horizontally based on direction.
	update_sprite_flip(direction)

var npc_in_range = null # The variable we used before

# This function will be called by the NPC's script
func player_can_interact(npc_node):
	npc_in_range = npc_node
	# Tell the NPC to show its prompt
	npc_in_range.show_prompt()
	print("Can now interact with: ", npc_in_range.name)



# This function will also be called by the NPC's script
# This function is called by the NPC when you walk away
func player_cannot_interact(npc_node):
	if npc_in_range == npc_node:
		# Tell the NPC to hide its prompt
		npc_in_range.hide_prompt()
		npc_in_range = null
		print("Out of range.")
		
		
func play_idle_animation() -> void:
	# Check the vertical component of the last direction.
	if last_direction.y > 0.5:
		animated_sprite.play("frontidle")
	elif last_direction.y < -0.5:
		animated_sprite.play("backidle")
	# If not moving vertically, check the horizontal component.
	elif abs(last_direction.x) > 0.5:
		animated_sprite.play("rightidle")


func play_walk_animation(direction: Vector2) -> void:
	# Use absolute values to prioritize up/down animations over left/right
	# which is common in top-down RPGs.
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			animated_sprite.play("frontwalk")
		else:
			animated_sprite.play("backwalk")
	else:
		animated_sprite.play("rightwalk")


func update_sprite_flip(direction: Vector2) -> void:
	# Don't flip if the player is moving up or down.
	if direction.y != 0:
		return

	# Flip the sprite horizontally if moving left, and un-flip if moving right.
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false
