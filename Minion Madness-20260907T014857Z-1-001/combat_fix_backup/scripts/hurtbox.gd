extends Area2D

@export var health: Node


func _on_area_entered(area):
	if area.is_in_group("enemy_hitbox"):
		health.take_damage(10)
