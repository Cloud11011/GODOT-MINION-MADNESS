
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton

func _ready() -> void:
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	get_tree().paused = false
	GameManager.start_new_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
