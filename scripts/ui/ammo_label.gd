extends Label


func _ready() -> void:
	GameManager.bananas_changed.connect(_on_bananas_changed)
	_on_bananas_changed(GameManager.bananas)


func _on_bananas_changed(new_amount: int) -> void:
	text = "Ammo: %d" % new_amount
