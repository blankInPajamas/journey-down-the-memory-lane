extends Control

@onready var title: Label = $Label
@onready var option_1: Button = $"HBoxContainer/Option 1"
@onready var option_2: Button = $"HBoxContainer/Option 2"

var current_question: int = 0
var change_scene: bool = false

# Five personality questions
var questions = [
	{
		"text": "You find a lost child crying on the road. You're late for an important meeting.",
		"a": {"text": "Help the child.", "trait": "empathy", "amount": +0.5},
		"b": {"text": "Report to someone and move on.", "trait": "empathy", "amount": -0.5}
	},
	{
		"text": "A stranger offers you a shortcut through the forest to your destination.",
		"a": {"text": "Try it — adventure awaits!", "trait": "risk", "amount": +0.5},
		"b": {"text": "Stick to the main road.", "trait": "risk", "amount": -0.5}
	},
	{
		"text": "After the accident, you feel...",
		"a": {"text": "Grateful to still be alive.", "trait": "outlook", "amount": +0.5},
		"b": {"text": "That life’s been unfair to you.", "trait": "outlook", "amount": -0.5}
	},
	{
		"text": "A friend insists on joining your search for answers.",
		"a": {"text": "Glad to have company.", "trait": "social", "amount": +0.5},
		"b": {"text": "Prefer to go alone.", "trait": "social", "amount": -0.5}
	},
	{
		"text": "When arguments arise, you usually...",
		"a": {"text": "Keep calm and think.", "trait": "temper", "amount": -0.5},
		"b": {"text": "Speak your mind instantly.", "trait": "temper", "amount": +0.5}
	}
]


func _ready() -> void:
	for btn in [option_1, option_2]:
		btn.custom_minimum_size.x = 380
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.size_flags_horizontal = Control.SIZE_FILL
	show_question()


func show_question() -> void:
	if current_question < questions.size():
		var q = questions[current_question]
		title.text = q["text"]
		option_1.text = q["a"]["text"]
		option_2.text = q["b"]["text"]
	else:
		# All questions completed
		change_scene = true
		print("All questions answered. Ready to change scene.")
		Globaltraits.print_traits()
		get_tree().change_scene_to_file("res://scenes/interior_lvl/house_1.tscn")


func _on_Option_1_pressed() -> void:
	pass


func _on_Option_2_pressed() -> void:
	pass # Replace with function body.
	

func _on_option_1_pressed() -> void:
	if current_question < questions.size():
		var q = questions[current_question]
		Globaltraits.adjust_trait(q["a"]["trait"], q["a"]["amount"])
		current_question += 1
		show_question()


func _on_option_2_pressed() -> void:
	if current_question < questions.size():
		var q = questions[current_question]
		Globaltraits.adjust_trait(q["b"]["trait"], q["b"]["amount"])
		current_question += 1
		show_question()
