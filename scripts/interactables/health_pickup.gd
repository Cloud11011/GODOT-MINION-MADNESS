extends Area2D

@export_range(1, 100, 1) var heal_amount: int = 20

var collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return

	var health := body.get_node_or_null("Health") as Health
	if health == null:
		return

	if not health.heal(heal_amount):
		return

	collected = true
	queue_free()
