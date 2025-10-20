# player.gd (FIXED VERSION)
extends CharacterBody2D

@export var speed: float = 100.0

# --- State Variables ---
var npc_in_range = null
var door_in_range = null
var is_chatting = false
var last_direction: Vector2 = Vector2(0, 1)

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# This will now work because ChatWindow is an Autoload scene
@onready var ollama_request = ChatWindow.get_node("OllamaRequest") 

# --- Godot Lifecycle Functions ---

func _ready():
	# Connect to the ChatWindow's custom signals
	ChatWindow.player_spoke.connect(_on_player_spoke)
	ChatWindow.conversation_ended.connect(_on_conversation_ended)
	
	# --- FIX ---
	# Connect to the CORRECT response function
	# This function handles the full JSON package from your backend
	ollama_request.request_completed.connect(_on_chat_response_received) 
	
	# Connect to the SceneManager's spawn signal
	scenemanager.on_trigger_player_spawn.connect(_on_spawn)

func _physics_process(delta: float):
	# --- FIX ---
	# Stop movement during chat
	if is_chatting:
		velocity = Vector2.ZERO
		play_idle_animation()
		return

	# Standard movement code
	var input_direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction.normalized() * speed
	move_and_slide()
	update_animation(input_direction)

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancelconvo"):
		ChatWindow.close_conversation()
		return
		
	# Handle "interact" button
	if Input.is_action_just_pressed("ui_accept"):
		# Check for NPC interaction
		if not ChatWindow.is_visible() and npc_in_range != null:
			_start_new_conversation(npc_in_range)
		# Check for door interaction
		elif not is_chatting and door_in_range != null:
			scenemanager.go_to_level(door_in_range.destination_level_tag, door_in_range.destination_door_tag)

# --- Conversation Management ---

func _start_new_conversation(npc_node):
	is_chatting = true
	npc_in_range = npc_node
	npc_in_range.hide_prompt()
	
	# Use the global PlayerMetrics history
	PlayerMetrics.clear_history()
	
	# Get NPC data
	var initial_greeting = npc_in_range.initial_greeting
	
	# Add the NPC's first line to the global history
	PlayerMetrics.add_to_history("npc", initial_greeting)
	
	# Prepare data for the ChatWindow UI
	var npc_data = {
		"name": npc_in_range.npc_name,
		"portrait": npc_in_range.portrait_texture
	}
	# Start the UI
	ChatWindow.start_conversation(npc_data, initial_greeting)

func _on_player_spoke(text: String):
	# Add the player's message to the global history
	PlayerMetrics.add_to_history("player", text)
	
	# Show the "..." indicator
	ChatWindow.show_thinking_indicator()
	
	# --- FIX ---
	# Create the FULL data payload that the backend expects
	var body = JSON.stringify({
		"history": PlayerMetrics.conversation_history,
		"persona": npc_in_range.persona,
		"relationship": PlayerMetrics.get_relationship(npc_in_range.npc_name),
		"player_traits": PlayerMetrics.traits
	})
	
	# Send the request
	var headers = ["Content-Type: application/json"]
	ollama_request.request("http://127.0.0.1:5000/interact", headers, HTTPClient.METHOD_POST, body)

# This is the function that correctly handles your backend's response
func _on_chat_response_received(result, response_code, headers, body):
	if response_code != 200:
		ChatWindow.display_npc_message("I... I can't think of what to say. (Error: %s)" % response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json:
		ChatWindow.display_npc_message("I... I'm speechless. (JSON parse error)")
		return

	# 1. Update Conversation History
	var npc_dialogue = json.get("dialogue", "...")
	PlayerMetrics.add_to_history("npc", npc_dialogue)
	
	# 2. Update Relationship Metric
	var rel_change = json.get("relationship_change", 0)
	PlayerMetrics.update_relationship(npc_in_range.npc_name, rel_change)
	
	ChatWindow.display_relationship_change(rel_change)
	
	# 3. Update Player Trait Metric
	var trait_shift = json.get("player_trait_shift", {})
	if not trait_shift.is_empty():
		var trait1 = trait_shift.get("trait", "")
		# 'shift' is the int from the JSON, e.g., 5 or -5
		var shift = trait_shift.get("shift", 0) 
		if not trait1.is_empty():
			# Convert int shift (e.g., 5) to float (e.g., 0.05)
			PlayerMetrics.adjust_trait(trait1.to_lower(), shift / 100.0)
			
	# 4. Handle New Objectives
	var new_objective = json.get("new_objective", {})
	if not new_objective.is_empty() and not new_objective.get("id", "").is_empty():
		ObjectiveManager.add_objective(
			new_objective.get("id"),
			new_objective.get("text"),
			new_objective.get("type")
		)
		
	# 5. Display the dialogue
	ChatWindow.display_npc_message(npc_dialogue)
	
	# 6. End the conversation if the LLM decides
	var is_over = json.get("conversation_over", false)
	if is_over:
		ChatWindow.call_deferred("close_conversation")

func _on_conversation_ended():
	is_chatting = false
	print("Conversation ended.")

# --- Spawning and Interaction ---

func _on_spawn(position: Vector2):
	global_position = position

func player_can_interact(npc_node):
	npc_in_range = npc_node
	npc_in_range.show_prompt()

func player_cannot_interact(npc_node):
	if npc_in_range == npc_node:
		npc_in_range.hide_prompt()
		npc_in_range = null

func can_interact_with_door(door_node):
	door_in_range = door_node
	door_in_range.show_prompt()

func cannot_interact_with_door(door_node):
	if door_in_range == door_node:
		door_in_range.hide_prompt()
		door_in_range = null

# --- Animation Functions ---

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		play_idle_animation()
	else:
		last_direction = direction
		play_walk_animation(direction)
	update_sprite_flip(direction)

func play_idle_animation() -> void:
	if last_direction.y > 0.5:
		animated_sprite.play("frontidle")
	elif last_direction.y < -0.5:
		animated_sprite.play("backidle")
	elif abs(last_direction.x) > 0.5:
		animated_sprite.play("rightidle")

func play_walk_animation(direction: Vector2) -> void:
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			animated_sprite.play("frontwalk")
		else:
			animated_sprite.play("backwalk")
	else:
		animated_sprite.play("rightwalk")

func update_sprite_flip(direction: Vector2) -> void:
	if direction.y != 0:
		return
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false
