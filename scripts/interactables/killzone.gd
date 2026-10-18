extends Area2D

@onready var timer = $Timer

func _on_body_entered(body: Node) -> void:
	var parent_node := get_parent()
	if parent_node and parent_node.has_method("handle_player_collision"):
		parent_node.handle_player_collision(body)
		return

	if body.is_in_group("enemies") and body.has_method("die"):
		body.die()
		return

	var health = body.get_node_or_null("Health")

	if health:
		health.take_damage(health.current_health)


func _on_timer_timeout() -> void:
	pass
