extends Control

@onready var settings_panel: Panel = $Panel
@onready var button_container: VBoxContainer = $VBoxContainer
@onready var title_label: Label = $Title

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_panel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	settings_panel.visible = true
	title_label.visible = false
	button_container.visible = false
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	settings_panel.visible = false
	title_label.visible = true
	button_container.visible = true
