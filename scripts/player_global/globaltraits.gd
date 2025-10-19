extends Node

# All traits stored in a single dictionary
var traits := {
	"empathy": 0.0,  # -1 (Pragmatic) to +1 (Empathetic)
	"risk": 0.0,     # -1 (Cautious) to +1 (Daring)
	"outlook": 0.0,  # -1 (Cynical) to +1 (Optimistic)
	"social": 0.0,   # -1 (Independent) to +1 (Cooperative)
	"temper": 0.0    # -1 (Calm) to +1 (Hot-headed)
}

# Adjust a specific trait safely
func adjust_trait(trait_name: String, amount: float) -> void:
	if trait_name in traits:
		traits[trait_name] = clamp(traits[trait_name] + amount, -1.0, 1.0)
	else:
		push_warning("Unknown trait: %s" % trait_name)

# Reset all traits to neutral (0.0)
func reset_traits() -> void:
	for key in traits.keys():
		traits[key] = 0.0

# Optional: get a copy of current traits
func get_traits() -> Dictionary:
	return traits.duplicate(true)

# Optional: for debugging
func print_traits() -> void:
	for key in traits.keys():
		print("%s: %.2f" % [key, traits[key]])
