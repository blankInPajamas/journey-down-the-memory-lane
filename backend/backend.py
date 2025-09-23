# backend.py
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)
OLLAMA_URL = "http://localhost:11434/api/generate"

@app.route("/interact", methods=["POST"])
def interact():

    print("--- Received a request from Godot! ---")
    data = request.json
    # The backend now expects the full conversation history
    conversation_history = data.get("history", [])
    npc_persona = data.get("persona", "You are a mysterious old woman.")

    # We build a single, continuous prompt from the history
    full_prompt = npc_persona + "\n\n"
    for message in conversation_history:
        if message["sender"] == "player":
            full_prompt += f"Traveler: {message['text']}\n"
        else: # 'npc'
            full_prompt += f"Old Woman: {message['text']}\n"
    
    # Add the final prompt for the NPC to respond to
    full_prompt += "Old Woman:"

    # Data payload for Ollama
    payload = {
        "model": "phi3",
        "prompt": full_prompt,
        "stream": False
    }

    # Send request to Ollama
    response = requests.post(OLLAMA_URL, json=payload)
    response_data = response.json()
    npc_response = response_data.get("response", "I see...").strip()
    
    return jsonify({"npc_message": npc_response})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)