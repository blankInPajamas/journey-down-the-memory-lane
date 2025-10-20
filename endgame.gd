# end_screen.gd
extends Control

@onready var summary_label = $SummaryLabel
@onready var api_request = $ApiRequest

func _ready():
	summary_label.text = "Reflecting on your journey..."
	api_request.request_completed.connect(_on_api_request_completed)
	
	_generate_summary()

func _generate_summary():
	# 1. Fetch final stats from PlayerMetrics [cite: 19, 28]
	var final_traits = PlayerMetrics.traits
	var final_relationships = PlayerMetrics.npc_relationships
	
	# 2. Find dominant and lowest traits [cite: 20, 29]
	var dominant_trait = ""
	var highest_score = -1.0
	var lowest_trait = ""
	var lowest_score = 2.0 # Start high
	
	for trait1 in final_traits:
		var score = final_traits[trait1]
		if score > highest_score:
			highest_score = score
			dominant_trait = trait1
		if score < lowest_score:
			lowest_score = score
			lowest_trait = trait1
			
	# 3. Construct the final prompt [cite: 21]
	# This prompt combines the details from Sprint 5 and 6 [cite: 21, 29]
	var prompt_text = (
		"The player has finished their journey. "
		+ "Their final personality traits are: " + str(final_traits) + ". "
		+ "Their relationships with the characters are: " + str(final_relationships) + ". "
		+ "Their most dominant trait was '" + dominant_trait + "' "
		+ "and their least dominant was '" + lowest_trait + "'. "
		+ "Based on this data, write a one-paragraph summary describing the "
		+ "kind of person they were before they lost their memory. "
		+ "The summary should be reflective and conclusive, in the style "
		+ "of a personality test result."
	)
	
	# 4. Send to a *new* backend endpoint (e.g., /summarize)
	var body_data = {"prompt": prompt_text}
	var body = JSON.stringify(body_data)
	var headers = ["Content-Type: application/json"]
	
	# NOTE: Use a different endpoint for this, not /interact
	api_request.request("http://127.0.0.1:5000/summarize", headers, HTTPClient.METHOD_POST, body)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu_scenes/start_screen.tscn")
	
func _on_api_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		# Assumes backend returns {"summary": "..."}
		if json and json.has("summary"):
			
			# --- THIS IS THE MODIFICATION ---
			
			# 1. Get the AI summary
			var ai_summary = json.get("summary") 
			
			# 2. Get the raw stats again (they are still in scope from _generate_summary)
			var final_traits = PlayerMetrics.traits 
			var final_relationships = PlayerMetrics.npc_relationships 
			
			# 3. Build a final text string
			var stats_text = "\n\n--- Your Final Stats ---\n"
			stats_text += "Traits: " + str(final_traits) + "\n"
			stats_text += "Relationships: " + str(final_relationships)
			
			# 4. Set the label to show everything
			summary_label.text = ai_summary + stats_text
			
			# --- END OF MODIFICATION ---
			
	else:
		summary_label.text = "An error occurred while reflecting on your journey."
		print("Error %d: %s" % [response_code, body.get_string_from_utf8()])
