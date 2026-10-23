extends Area2D

signal attack_started
signal attack_window_opened
signal attack_finished

@export var damage: int = 25
@export var windup_seconds: float = 0.045
@export var active_seconds: float = 0.15
@export var cooldown_seconds: float = 0.4
@export var reach: float = 17.0

var cooldown_remaining := 0.0
var phase_remaining := 0.0
var phase := 0  # 0=idle, 1=windup, 2=active
var already_hit: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = false


func request_attack(facing: float) -> bool:
	var player := get_parent()
	if get_tree().paused or bool(player.get("is_dead")):
		return false
	if cooldown_remaining > 0.0 or phase != 0:
		return false
	position = Vector2((-1.0 if facing < 0.0 else 1.0) * reach, -10.0)
	already_hit.clear()
	cooldown_remaining = cooldown_seconds
	phase_remaining = windup_seconds
	phase = 1
	attack_started.emit()
	return true


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if phase == 0:
		return
	var player := get_parent()
	if bool(player.get("is_dead")):
		_cancel_attack()
		return
	phase_remaining -= delta
	if phase == 1 and phase_remaining <= 0.0:
		phase = 2
		phase_remaining = active_seconds
		set_deferred("monitoring", true)
		attack_window_opened.emit()
	elif phase == 2:
		for body in get_overlapping_bodies():
			_damage_enemy(body)
		if phase_remaining <= 0.0:
			_cancel_attack()


func _damage_enemy(body: Node2D) -> void:
	if not is_instance_valid(body) or not body.is_in_group("enemies"):
		return
	var id := body.get_instance_id()
	if already_hit.has(id):
		return
	already_hit[id] = true
	var health := body.get_node_or_null("Health") as Health
	if health != null and not health.is_dead:
		health.take_damage(damage)


func _cancel_attack() -> void:
	if phase == 0:
		return
	phase = 0
	set_deferred("monitoring", false)
	attack_finished.emit()
