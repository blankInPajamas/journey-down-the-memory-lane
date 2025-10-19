extends Node2D

func _ready():
	if scenemanager.spawn_door_tag != null and not scenemanager.spawn_door_tag.is_empty():
		_on_level_spawn(scenemanager.spawn_door_tag)

func _on_level_spawn(destination_tag: String):
	# THE FIX: We search the entire scene tree for a node with the name `destination_tag`.
	# The 'true, false' arguments mean we search recursively down the tree.
	var spawn_marker = get_tree().get_root().find_child(destination_tag, true, false)
	
	# Check if we actually found the marker
	if spawn_marker:
		# If we found it, we trigger the spawn using the marker's global position.
		# We are no longer looking for a ".spawn" child.
		scenemanager.trigger_player_spawn(spawn_marker.global_position)
	else:
		# If we can't find the marker, print a warning to the console.
		# The player will spawn at their default position for this scene.
		print("!!! LEVEL SCRIPT WARNING: Could not find spawn marker named: '", destination_tag, "' !!!")
