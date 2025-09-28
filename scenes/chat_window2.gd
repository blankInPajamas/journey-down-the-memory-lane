extends CanvasLayer

# --- Node References ---
@onready var http_request: HTTPRequest = $LLMRequest
@onready var prompt_input: TextEdit = $PromptInput
@onready var response_label: RichTextLabel = $ResponseLabel

# --- LLM Configuration ---
# URL for Ollama's streaming chat endpoint.
# Adjust if you use a different server like LM Studio.
const LLM_API_URL = "http://localhost:11434/api/chat"

# To hold the full response text as it's built.
var full_response: String = ""


func _ready() -> void:
	# Connect signals.
	# This is the most important signal for streaming.
	http_request.body_chunk_received.connect(_on_body_chunk_received)
	# Good practice to also handle completion.
	http_request.request_completed.connect(_on_request_completed)
	# Connect the button to our function that starts the process.
	

func _on_send_button_pressed() -> void:
	# Clear previous response and disable button during request.
	response_label.clear()
	full_response = ""
	

	# --- Construct the Request ---
	var headers = [
        "Content-Type: application/json"
	]

	# This is a standard Ollama payload.
	# The key is "stream": true.
	var body = {
		"model": "llama3",  # Change to your desired model
		"prompt": prompt_input.text,
		"stream": true
	}

	# Convert the dictionary to a JSON string.
	var request_body_json = JSON.stringify(body)

	# Make the request.
	# The `true` for `use_threads` is important to not freeze the UI.
	var error = http_request.request(LLM_API_URL, headers, HTTPClient.METHOD_POST, request_body_json)
	
	if error != OK:
		print("Error starting the HTTP request.")
		
		
# This function is called every time a new data chunk arrives.
func _on_body_chunk_received(chunk: PackedByteArray) -> void:
	# Convert the binary chunk to a string.
	var chunk_text = chunk.get_string_from_utf8()

	# Ollama sends one JSON object per line.
	# We parse the line, get the content, and append it.
	var json = JSON.parse_string(chunk_text)
	
	if json and json.has("response"):
		var new_content = json["response"]
		full_response += new_content
		response_label.text = full_response
		
# Called when the entire response has been received.
func _on_request_completed(result, response_code, headers, body):
	print("Stream finished with response code: ", response_code)
	# Re-enable the button for the next prompt.
	
