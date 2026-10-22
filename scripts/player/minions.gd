extends "res://scripts/player/player.gd"

signal out_of_bananas

const BananaProjectile := preload("res://scenes/projectiles/banana_projectile.tscn")

@export var ranged_attack_enabled := true
@export var unlimited_bananas := false
@export var throw_cooldown := 0.35
@export var throw_origin := Vector2(10.0, -12.0)

var throw_cooldown_left := 0.0

func _init() -> void:
	speed = 100.0


func _physics_process(delta: float) -> void:
	throw_cooldown_left = maxf(throw_cooldown_left - delta, 0.0)
	super._physics_process(delta)
	if ranged_attack_enabled and Input.is_action_just_pressed("throw_banana") and not get_tree().paused:
		throw_banana()


func throw_banana() -> bool:
	if not ranged_attack_enabled or is_dead or throw_cooldown_left > 0.0:
		return false
	if not unlimited_bananas and not GameManager.use_banana():
		out_of_bananas.emit()
		return false
	throw_cooldown_left = throw_cooldown
	var facing := -1.0 if animated_sprite.flip_h else 1.0
	var banana = BananaProjectile.instantiate()
	banana.position = get_tree().current_scene.to_local(
		global_position + Vector2(throw_origin.x * facing, throw_origin.y)
	)
	banana.velocity = Vector2(facing * 650.0, 0.0)
	get_tree().current_scene.add_child(banana)
	return true
