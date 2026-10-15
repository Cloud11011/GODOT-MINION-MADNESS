extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	animation_player.play("RESET")
	hide()


func pause() -> void:
	if is_paused:
		return

	is_paused = true
	show()
	get_tree().paused = true
	animation_player.play("Blur")


func resume() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	animation_player.play_backwards("Blur")
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if is_paused:
			resume()
		else:
			pause()


func _on_resume_button_pressed() -> void:
	resume()


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
