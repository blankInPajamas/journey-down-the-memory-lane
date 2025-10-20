# ObjectiveManager.gd
extends Node

signal objectives_updated

var active_objectives = {} # Stores quests by ID, e.g., {"Q1_FIND_LOCKET": "Find the silver locket..."}

func add_objective(id: String, text: String, type: String):
	if not active_objectives.has(id):
		active_objectives[id] = {"text": text, "type": type}
		objectives_updated.emit()
		print("New objective added: ", id)

func complete_objective(id: String):
	if active_objectives.has(id):
		active_objectives.erase(id)
		objectives_updated.emit()
		print("Objective completed: ", id)
