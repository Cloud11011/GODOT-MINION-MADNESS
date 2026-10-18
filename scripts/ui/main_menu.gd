
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel

func _ready() -> void:
	high_score_label.text = "High Score: %d" % GameManager.high_score
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().paused = false
	GameManager.start_new_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
