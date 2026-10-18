extends Control

@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var menu_button: Button = $VBoxContainer/MenuButton

func _ready() -> void:
	score_label.text = "Score: %d | Best: %d" % [
		GameManager.score,
		GameManager.high_score
	]

	menu_button.pressed.connect(GameManager.back_to_menu)
	menu_button.grab_focus()
