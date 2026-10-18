extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel

func _ready() -> void:
	high_score_label.text = "High Score: %d" %GameManager.high_score
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	start_button.grab_focus()
	
func _on_start_button_pressed() -> void:
	GameManager.start_new_game()
	
func _on_quit_button_pressed() -> void:
	get_tree().quit() 
