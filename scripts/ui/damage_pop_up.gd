extends Label
class_name DamagePopUp

func setup(amount: int) -> void:
	text = "-%d" % amount
	modulate = Color.RED
	
func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 40, 0.6)
	tween.chain().tween_callback(queue_free)	
