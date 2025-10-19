extends Control

var text: String = """Kuddus was travelling to his homeland in a car. But alas, he got into a car accident. The accident was pretty severe and caused him to lose this memory temporarily.
	
	It is your job to explore the land after Kuddus wakes up and recollect the memory that you have lost. Interact with your buddies, your relatives and others to gain insight of the person you were before the accident. 
"""

var text02: String = """But before that, you must take a personality test to determine your current personality. Answer these couple of questions before entering the game."""

@onready var next_step: Label = $NinePatchRect/Next_step

@onready var label: Label = $NinePatchRect/Label
@export var typing_speed: float = 0.03 # time between each character (seconds)

var char_index := 0
var typing := false
var current_step := 1  # 1 = first text, 2 = second text

func _ready() -> void:
	label.text = ""
	next_step.visible = false
	typing = true
	_type_text(text)


# ---- TYPEWRITER FUNCTION ----
func _type_text(target_text: String) -> void:
	char_index = 0
	label.text = ""
	typing = true
	_start_typing(target_text)


func _start_typing(target_text: String) -> void:
	if char_index < target_text.length():
		label.text += target_text[char_index]
		char_index += 1
		await get_tree().create_timer(typing_speed).timeout
		_start_typing(target_text)
	else:
		typing = false
		next_step.visible = true  # show "Press F to proceed"


# ---- INPUT HANDLER ----
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("press_F") and not typing:
		next_step.visible = false
		current_step += 1

		if current_step == 2:
			_type_text(text02)
		elif current_step == 3:
			# proceed to next scene (replace with actual scene transition)
			get_tree().change_scene_to_file("res://scenes/main_menu_scenes/personality_screen.tscn")
