import os
from flask import Flask, request, jsonify
import google.generativeai as genai
import json

# Import the LangChain libraries for RAG
from langchain_community.document_loaders import DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_google_genai import GoogleGenerativeAIEmbeddings

app = Flask(__name__)

# --- RAG Setup (This happens once when the server starts - no changes needed) ---
try:
    print("Setting up RAG knowledge base...")
    loader = DirectoryLoader('./lore/', glob="**/*.txt", show_progress=True)
    docs = loader.load()
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
    splits = text_splitter.split_documents(docs)
    embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
    vectorstore = Chroma.from_documents(documents=splits, embedding=embeddings)
    retriever = vectorstore.as_retriever(search_kwargs={"k": 3})
    print("RAG knowledge base setup complete.")
    RAG_ENABLED = True
except Exception as e:
    print(f"--- RAG SETUP FAILED: {e} ---")
    print("--- Running without RAG. Conversations will not be grounded in lore. ---")
    RAG_ENABLED = False

# --- Gemini API Configuration (No changes needed) ---
try:
    genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
    model = genai.GenerativeModel('gemini-2.5-flash')
    print("Gemini API configured successfully.")
except Exception as e:
    print(f"--- FATAL ERROR: Could not configure Gemini. Is GOOGLE_API_KEY set? Details: {e} ---")
    model = None

# --- Flask Route (This is where all the new logic goes) ---
@app.route("/interact", methods=["POST"])
def interact():
    if not model:
        return jsonify({"error": "Gemini model is not configured on the server."}), 500

    # --- 1. Receive Richer Data from Godot ---
    data = request.json
    conversation_history = data.get("history", [])
    npc_persona = data.get("persona", "You are a helpful NPC.")
    # NEW: Receive current game state from Godot
    relationship_score = data.get("relationship", 50)
    player_traits = data.get("player_traits", {})

    # --- 2. Define the JSON "Instruction Manual" for the LLM ---
    json_schema = """
    {
      "dialogue": "The text the NPC will say. This must be a string.",
      "relationship_change": "An integer representing how the player's last message affected your opinion of them (e.g., -5, 0, 10).",
      "player_trait_shift": {
        "trait": "Based on the player's last message, choose the SINGLE most relevant personality trait to change from this list: [empathy, risk, outlook, social, temper]. This must be a string.",
        "shift": "An integer from -5 to 5 representing how to shift that trait."
      },
      "new_objective": {
        "id": "A unique quest ID like 'Q1_FIND_LOCKET' or an empty string if no new objective is given.",
        "text": "The objective text for the player's UI, or an empty string.",
        "type": "The type of objective from this list: ['COLLECT', 'CONVINCE', 'RIDDLE', 'TALK'] or an empty string."
      },
      "conversation_over": "A boolean (true or false) indicating if you, the NPC, consider this conversation finished for now."
    }
    """

    # --- 3. Build the RAG Context (Same as before) ---
    player_last_message = ""
    if conversation_history and conversation_history[-1]["sender"] == "player":
        player_last_message = conversation_history[-1]["text"]

    context = ""
    if RAG_ENABLED and player_last_message:
        relevant_docs = retriever.invoke(player_last_message)
        context = "\n\nRelevant Information from the world's lore:\n" + "\n".join([doc.page_content for doc in relevant_docs])

    # --- 4. Construct the Master "Game Master" Prompt ---
    system_instruction = (
        f"You are a Game Master AI controlling an NPC. Your task is to respond to the player in a valid JSON format that follows this exact schema: {json_schema}\n\n"
        f"--- YOUR CURRENT NPC PERSONA ---\n{npc_persona}\n\n"
        f"--- CURRENT GAME STATE ---\n"
        f"Your current relationship with the player is {relationship_score} out of 100.\n"
        f"The player's current personality traits are: {player_traits}\n\n"
        f"--- INSTRUCTIONS ---\n"
        "1. Based on your persona, the game state, the conversation history, and the relevant information, decide what your NPC would say and do.\n"
        "2. Fill out every field in the JSON schema to reflect your decision.\n"
        "3. Your dialogue should naturally lead to riddles or objectives based on your persona's goals.\n"
        "4. The player's tone and choices should influence the 'relationship_change' and 'player_trait_shift'.\n"
        "5. Only provide a 'new_objective' when it makes sense in the conversation.\n"
        "6. Wrap your final, valid JSON response in ```json ``` tags."
    )

    gemini_history = [{"role": "user", "parts": [system_instruction + context]}]
    gemini_history.append({"role": "model", "parts": ["Understood. I will act as a Game Master and respond only in the specified JSON format."]})

    for message in conversation_history:
        role = "user" if message["sender"] == "player" else "model"
        gemini_history.append({"role": role, "parts": [message['text']]})

    # --- 5. Call the API and Parse the JSON Response ---
    try:
        response = model.generate_content(gemini_history, stream=False)

        # Clean up the response to find the JSON block
        response_text = response.text.strip().replace("```json", "").replace("```", "")
        json_response = json.loads(response_text)

        return jsonify(json_response)

    except Exception as e:
        print(f"--- BACKEND ERROR: Gemini API call or JSON parsing failed: {e} ---")
        # Return a default error JSON so Godot doesn't crash
        error_response = {
            "dialogue": "(The NPC seems lost in thought and doesn't respond.)",
            "relationship_change": 0, "player_trait_shift": {"trait": "", "shift": 0},
            "new_objective": {"id": "", "text": "", "type": ""}, "conversation_over": True
        }
        return jsonify(error_response), 500

# ==================================================================
# --- NEW ENDGAME SUMMARY ROUTE ---
# This is the new endpoint for your end_screen.gd script
# ==================================================================
@app.route("/summarize", methods=["POST"])
def summarize():
    if not model:
        return jsonify({"error": "Gemini model is not configured on the server."}), 500

    try:
        # 1. Get the prompt from Godot (sent by end_screen.gd)
        data = request.json
        prompt = data.get("prompt")

        if not prompt:
            return jsonify({"error": "No prompt was provided."}), 400

        # 2. Call Gemini in a simple, non-chat way
        # The prompt from Godot contains all instructions.
        response = model.generate_content(prompt)

        # 3. Send the summary text back to Godot
        return jsonify({"summary": response.text})

    except Exception as e:
        print(f"--- BACKEND ERROR (/summarize): {e} ---")
        return jsonify({"error": f"Failed to generate summary: {str(e)}"}), 500


# ==================================================================
# --- Server Start ---
# ==================================================================
if __name__ == "__main__":
    if not os.getenv("GOOGLE_API_KEY"):
        print("--- FATAL ERROR: The GOOGLE_API_KEY environment variable is not set. ---")
    else:
        app.run(host="0.0.0.0", port=5000)
