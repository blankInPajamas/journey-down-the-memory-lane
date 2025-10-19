extends Node2D

@onready var pause_screen = preload("res://scenes/main_menu_scenes/pause.tscn").instantiate()

@onready var camera = $Player/Camera2D
@onready var panel = $Panel
@onready var label_panel: Label = $UI_Layer/Panel/Label
@onready var ui_layer: CanvasLayer = $UI_Layer

var is_paused_screen_visible = false

func _ready() -> void:
	var current_scene_path = get_tree().current_scene.scene_file_path
	if Global.can_show_pause(current_scene_path):
		add_child(pause_screen)
		pause_screen.visible = false
	else:
		pause_screen = null  # disable if not needed

func _input(event):
	if Input.is_action_just_pressed("press_F"):
		ui_layer.visible = false
	
	if event.is_action_pressed("ui_cancel"):
		Global.previous_scene = get_tree().current_scene.scene_file_path
		get_tree().change_scene_to_file("res://scenes/main_menu_scenes/objectives.tscn")

	#if event.is_action_pressed("ui_accept"):
		#print("Coming here") # SPACE or mapped F
		#pause_screen.visible = false
		#get_tree().paused = false
		#is_paused_screen_visible = false
