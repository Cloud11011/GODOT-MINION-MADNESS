extends "res://scripts/enemies/slime.gd"

const DISTANCE = 200
const STOMP_BOUNCE_VELOCITY = -230.0


func _init() -> void:
	contact_damage = 25


func _is_stomp(player: CharacterBody2D) -> bool:
	return can_be_stomped_by(player)


func _defeat(player: CharacterBody2D) -> void:
	try_stomp(player)
