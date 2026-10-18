
extends Label

func _ready() -> void:
	position = Vector2(16, 72)

	GameManager.lives_changed.connect(_on_lives_changed)

	_on_lives_changed(GameManager.lives)


func _on_lives_changed(new_lives: int) -> void:
	text = "Lives: %d" % new_lives
	print("Lives remaining: ", new_lives)
