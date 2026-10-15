extends Control

const MAIN_GAME_SCENE = "res://scenes/main_game.tscn"

func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)
	


func _on_quit_button_pressed() -> void:
	get_tree().quit() 
