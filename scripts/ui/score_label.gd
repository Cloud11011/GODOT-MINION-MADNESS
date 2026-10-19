
extends Label


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	_on_score_changed(GameManager.score)


func _on_score_changed(new_score: int) -> void:
	text = "Bananas: %d" % new_score
