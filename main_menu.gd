extends Control

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
	
func _on_quit_button_pressed() -> void:
	get_tree().quit() 
