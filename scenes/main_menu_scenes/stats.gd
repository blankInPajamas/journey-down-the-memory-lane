# StatsUI.gd
extends MarginContainer

# --- Node References ---
@onready var empathy_label = $VBoxContainer/EmpathyLabel
@onready var risk_label = $VBoxContainer/RiskLabel
@onready var outlook_label = $VBoxContainer/OutlookLabel
@onready var social_label = $VBoxContainer/SocialLabel
@onready var temper_label = $VBoxContainer/TemperLabel

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 1. Fetch the traits dictionary from your singleton
	var current_traits = PlayerMetrics.traits
	
	# 2. Update the text for each label
	# We use %.2f to format the float to two decimal places
	empathy_label.text = "Empathy: %.2f" % current_traits.get("empathy", 0.0)
	risk_label.text = "Risk: %.2f" % current_traits.get("risk", 0.0)
	outlook_label.text = "Outlook: %.2f" % current_traits.get("outlook", 0.0)
	social_label.text = "Social: %.2f" % current_traits.get("social", 0.0)
	temper_label.text = "Temper: %.2f" % current_traits.get("temper", 0.0)
