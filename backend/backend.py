import os
from flask import Flask, request, jsonify
import google.generativeai as genai

# NEW: Import the LangChain libraries for RAG
from langchain_community.document_loaders import DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_google_genai import GoogleGenerativeAIEmbeddings

app = Flask(__name__)

# --- RAG Setup (This happens once when the server starts) ---
try:
    print("Setting up RAG knowledge base...")
    # 1. Load all .txt files from the 'lore' directory
    loader = DirectoryLoader('./lore/', glob="**/*.txt", show_progress=True)
    docs = loader.load()

    # 2. Split the documents into smaller chunks for better searching
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
    splits = text_splitter.split_documents(docs)

    # 3. Create a searchable vector store from the chunks
    # This uses a Gemini model to understand the meaning of your text
    embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
    vectorstore = Chroma.from_documents(documents=splits, embedding=embeddings)

    # 4. Create a "retriever" which is the tool we use to search the vector store
    retriever = vectorstore.as_retriever(search_kwargs={"k": 3}) # k=3 means it will find the 3 most relevant chunks
    print("RAG knowledge base setup complete.")
    RAG_ENABLED = True
except Exception as e:
    print(f"--- RAG SETUP FAILED: {e} ---")
    print("--- Running without RAG. Conversations will not be grounded in lore. ---")
    RAG_ENABLED = False

# --- Gemini API Configuration ---
try:
    genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
    model = genai.GenerativeModel('gemini-2.5-flash')
    print("Gemini API configured successfully.")
except Exception as e:
    print(f"--- FATAL ERROR: Could not configure Gemini. Is GOOGLE_API_KEY set? Details: {e} ---")
    model = None

# --- Flask Route ---
@app.route("/interact", methods=["POST"])
def interact():
    if not model:
        return jsonify({"error": "Gemini model is not configured on the server."}), 500

    data = request.json
    conversation_history = data.get("history", [])
    npc_persona = data.get("persona", "You are a helpful NPC.")

    # Get the player's most recent message to search the knowledge base
    player_last_message = ""
    if conversation_history and conversation_history[-1]["sender"] == "player":
        player_last_message = conversation_history[-1]["text"]

    # --- RAG: Find relevant context from your lore files ---
    context = ""
    if RAG_ENABLED and player_last_message:
        relevant_docs = retriever.invoke(player_last_message)
        # Combine the content of the found documents into a single context string
        context = "\n\nRelevant Information:\n" + "\n".join([doc.page_content for doc in relevant_docs])

    # --- Format the prompt for Gemini ---
    system_instruction = npc_persona + \
        "\n\nUse the 'Relevant Information' provided below to answer the user's questions. " + \
        "If the information isn't relevant to the question, ignore it and rely only on your persona. " + \
        "Do not mention the source of your information or that you are using a knowledge base."

    gemini_history = [{"role": "user", "parts": [system_instruction + context]}]
    gemini_history.append({"role": "model", "parts": ["Understood. I am ready to roleplay."]})

    # We are no longer limiting the history
    for message in conversation_history:
        if message["sender"] == "player":
            gemini_history.append({"role": "user", "parts": [message['text']]})
        else: # "npc"
            gemini_history.append({"role": "model", "parts": [message['text']]})

    # --- Non-streaming API call ---
    try:
        response = model.generate_content(gemini_history, stream=False)
        npc_response = response.text
        return jsonify({"npc_message": npc_response})

    except Exception as e:
        print(f"--- BACKEND ERROR: Gemini API call failed: {e} ---")
        return jsonify({"error": "The language model failed to respond."}), 500

if __name__ == "__main__":
    if not os.getenv("GOOGLE_API_KEY"):
        print("--- FATAL ERROR: The GOOGLE_API_KEY environment variable is not set. ---")
    else:
        app.run(host="0.0.0.0", port=5000)

