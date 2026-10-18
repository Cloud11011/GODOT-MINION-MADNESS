extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DamagePopUpScene := preload("res://scenes/ui/damage_pop_up.tscn")

@export var speed: float = SPEED
@export var jump_velocity: float = JUMP_VELOCITY
@export var stomp_bounce_velocity: float = -230.0
@export var knockback_force: float = 220.0
@export var knockback_up: float = -180.0
@export var knockback_time: float = 0.25
@export var knockback_friction: float = 500.0
@export var move_left_action: StringName = &"ui_left"
@export var move_right_action: StringName = &"ui_right"
@export var jump_action: StringName = &"ui_accept"

var is_dead := false
var knockback_left: float = 0.0
var flash_tween: Tween
var original_sprite_modulate: Color

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: Health = get_node_or_null("Health") as Health
@onready var hurtbox = get_node_or_null("HurtBox")


func _ready() -> void:
	add_to_group("player")
	original_sprite_modulate = animated_sprite.modulate
	if health:
		health.died.connect(_on_health_died)
	if hurtbox:
		hurtbox.hurt.connect(_on_hurt)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction: float = 0.0
	if knockback_left > 0.0:
		knockback_left = maxf(knockback_left - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
	else:
		if Input.is_action_just_pressed(jump_action) and is_on_floor():
			velocity.y = jump_velocity
		direction = Input.get_axis(move_left_action, move_right_action)
		velocity.x = direction * speed if direction else move_toward(velocity.x, 0.0, speed)

	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
	_update_animation(direction)
	move_and_slide()


func _update_animation(direction: float) -> void:
	var animation: StringName = &"jump" if not is_on_floor() else (&"idle" if direction == 0.0 else &"run")
	if animated_sprite.sprite_frames.has_animation(animation):
		animated_sprite.play(animation)
	else:
		animated_sprite.play("idle")


func receive_enemy_hit(source_position: Vector2, amount: int) -> bool:
	if is_dead or hurtbox == null:
		return false
	return hurtbox.take_hit(source_position, amount)


func _on_hurt(source_position: Vector2, amount: int) -> void:
	_on_took_damage(amount)
	if is_dead:
		return
	var push := signf(global_position.x - source_position.x)
	if push == 0.0:
		push = 1.0
	velocity = Vector2(push * knockback_force, knockback_up)
	knockback_left = knockback_time
	_flash()


func bounce_after_stomp() -> void:
	if is_dead:
		return
	knockback_left = 0.0
	velocity.y = stomp_bounce_velocity
	if hurtbox:
		hurtbox.grant_invulnerability(0.15)
	_update_animation(0.0)


func _flash() -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	animated_sprite.modulate = original_sprite_modulate
	flash_tween = create_tween()
	for _blink in range(5):
		flash_tween.tween_property(animated_sprite, "modulate:a", original_sprite_modulate.a * 0.2, 0.1)
		flash_tween.tween_property(animated_sprite, "modulate:a", original_sprite_modulate.a, 0.1)


func _on_took_damage(amount: int) -> void:
	var popup := DamagePopUpScene.instantiate()
	var scene := get_tree().current_scene as Node2D
	popup.position = scene.to_local(global_position + Vector2(0.0, -30.0))
	popup.setup(amount)
	scene.add_child(popup)


func _on_health_died() -> void:
	if is_dead:
		return
	is_dead = true
	knockback_left = 0.0
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	get_tree().reload_current_scene()
