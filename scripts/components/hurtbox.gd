extends Area2D

signal hurt(source_position: Vector2, amount: int)

@export var health: Health
@export var invincibility_time: float = 1.0

var invincibility_left: float = 0.0


func _ready() -> void:
	if health == null:
		health = get_parent().get_node_or_null("Health") as Health
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	invincibility_left = maxf(invincibility_left - delta, 0.0)
	# Retry existing overlaps when protection ends.
	for area in get_overlapping_areas():
		_on_area_entered(area)


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemy_hitbox"):
		return
	var enemy := area.get_parent()
	if enemy.has_method("handle_player_collision"):
		enemy.handle_player_collision(get_parent())
	else:
		take_hit(area.global_position, 10)


func take_hit(source_position: Vector2, amount: int) -> bool:
	if amount <= 0 or health == null or health.is_dead or invincibility_left > 0.0:
		return false
	invincibility_left = invincibility_time
	health.take_damage(amount)
	hurt.emit(source_position, amount)
	return true


func grant_invulnerability(duration: float) -> void:
	invincibility_left = maxf(invincibility_left, duration)
