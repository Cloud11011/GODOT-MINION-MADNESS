extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	start_button.grab_focus()
	
func _on_start_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
	
func _on_quit_button_pressed() -> void:
	get_tree().quit() 
