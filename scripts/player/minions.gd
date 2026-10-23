extends "res://scripts/player/player.gd"

signal out_of_bananas

const BananaProjectile := preload("res://scenes/projectiles/banana_projectile.tscn")
const MeleeComponent := preload("res://scenes/combat/melee_hitbox.tscn")

@export var ranged_attack_enabled := true
@export var unlimited_bananas := false
@export var throw_cooldown := 0.35
@export var throw_origin := Vector2(10.0, -12.0)

var throw_cooldown_left := 0.0
var melee_component: Node

# Collaborators can connect to the melee component's attack_started,
# attack_window_opened and attack_finished signals when animations are ready.
func _ready() -> void:
	super._ready()
	melee_component = MeleeComponent.instantiate() as Area2D
	add_child(melee_component)

func _init() -> void:
	speed = 100.0


func _physics_process(delta: float) -> void:
	throw_cooldown_left = maxf(throw_cooldown_left - delta, 0.0)
	super._physics_process(delta)
	if Input.is_action_just_pressed("attack") and not is_dead and not get_tree().paused:
		melee_component.call("request_attack", -1.0 if animated_sprite.flip_h else 1.0)
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
