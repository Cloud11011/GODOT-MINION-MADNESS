class_name Health
extends Node

signal health_changed(current_health, max_health)
signal died

@export var max_health: int = 100

var current_health: int
var is_dead := false


func _ready() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	current_health = max(current_health, 0)

	print("Health:", current_health)

	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()


func heal_full() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit()
