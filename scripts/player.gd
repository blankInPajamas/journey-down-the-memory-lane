# Player.gd
extends CharacterBody2D

# Exporting the variable allows you to change the speed in the Inspector.
@export var speed: float = 100.0

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
