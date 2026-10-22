extends Area2D

@export var heal_amount: int = 20

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.get_node("Health").heal(heal_amount)
		queue_free()
		
