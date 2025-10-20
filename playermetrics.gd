# PlayerMetrics.gd
# This is a global singleton that stores all data that needs to persist
# between scene changes, acting as the player's "memory".
extends Node 

# --- Personality Traits ---
var traits := {
	"empathy": 0.0,  # -1 (Pragmatic) to +1 (Empathetic)
	"risk": 0.0,     # -1 (Cautious) to +1 (Daring)
	"outlook": 0.0,  # -1 (Cynical) to +1 (Optimistic)
	"social": 0.0,   # -1 (Independent) to +1 (Cooperative)
	"temper": 0.0    # -1 (Calm) to +1 (Hot-headed)
}

# --- Game State ---
var npc_relationships := {}
var collectibles := []
var conversation_history := []

# <--- NEW: List of NPCs required to trigger the end screen
# !!! EDIT THIS LIST with the exact 'npc_name' string from your NPC scenes
var required_npcs_to_meet := ["Kael, Alistair, Brenna, Maeve, Seraphina, Brother Theron, Silas, Finn"] # e.g., ["Ruksana", "Farhan", "Villager Boy"]

# --- Trait Management ---
func initialize_traits(initial_stats: Dictionary) -> void:
	traits = initial_stats 
	print("Initial player traits set: ", traits) 

func adjust_trait(trait_name: String, amount: float) -> void:
	if trait_name in traits:
		traits[trait_name] = clamp(traits[trait_name] + amount, -1.0, 1.0)
		("Trait '%s' adjusted by %s. New value: %s" % [trait_name, amount, traits[trait_name]])
	else:
		push_warning("Attempted to adjust unknown trait: %s" % trait_name) 

func print_traits() -> void:
	print("--- Current Player Traits ---")
	for key in traits.keys():
		print("%s: %.2f" % [key, traits[key]])

# --- Relationship Management ---
func update_relationship(npc_name: String, 
change: int) -> void:
	if not npc_relationships.has(npc_name):
		npc_relationships[npc_name] = 50 # Default starting relationship
	
	npc_relationships[npc_name] = clamp(npc_relationships[npc_name] + change, 0, 100)
	print("Relationship with '%s' is now: %s" % [npc_name, npc_relationships[npc_name]])

func get_relationship(npc_name: String) -> int:
	return npc_relationships.get(npc_name, 50) # Return 50 if not yet met

# --- Collectible Management ---
func add_collectible(item_id: String) -> void: 
	if not has_collectible(item_id):
		collectibles.append(item_id) 
		print("Player collected: ", item_id) 

func has_collectible(item_id: String) -> bool:
	return item_id in collectibles 

# --- Conversation History Management ---
func add_to_history(sender: String, text: String) -> void:
	conversation_history.append({"sender": sender, "text": text})

func clear_history() -> void:
	conversation_history.clear()
	print("Conversation history cleared.")

# <--- NEW: Function to check if all required NPCs have been met
func are_all_npcs_met() -> bool:
	if required_npcs_to_meet.is_empty():
		push_warning("required_npcs_to_meet list is 
empty in PlayerMetrics!")
		return false
		
	for npc_name in required_npcs_to_meet:
		# A relationship is added on the first conversation.
		# If one is missing, the player hasn't met them all.
		if not npc_relationships.has(npc_name):
			print("Endgame check: Player has not met ", npc_name)
			return false # Haven't met this one yet
	
	# If we get through the whole loop, all NPCs have been met
	print("Endgame check: All required NPCs have been met!")
	return true
