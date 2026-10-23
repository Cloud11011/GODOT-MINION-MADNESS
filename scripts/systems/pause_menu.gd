extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func resume() -> void:
	get_tree().paused = false
	hide()

func pause() -> void:
	show()
	get_tree().paused = true

func testEsc() -> void:
	if Input.is_action_just_pressed("esc"):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_button_pressed() -> void:
	resume()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_current_level()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _process(_delta: float) -> void:
	testEsc()
