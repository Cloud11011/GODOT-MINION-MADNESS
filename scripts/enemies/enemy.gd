extends CharacterBody2D

const SPEED = 60.0

@export var speed: float = SPEED
@export var chase_speed: float = 110.0
@export var patrol_distance: float = 60.0
@export var contact_damage: int = 10
@export var stomp_height_tolerance: float = 6.0

var direction: int = 1
var start_x: float
var defeated := false
var target_player: Node2D

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_zone: Area2D = $DetectionZone


func _ready() -> void:
	add_to_group("enemies")
	start_x = global_position.x
	detection_zone.body_entered.connect(_on_detection_zone_body_entered)
	detection_zone.body_exited.connect(_on_detection_zone_body_exited)


func _physics_process(delta: float) -> void:
	if defeated:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	_update_detected_player()
	if is_instance_valid(target_player):
		_chase_player()
	else:
		_patrol()
	move_and_slide()



func _patrol() -> void:
	if direction > 0 and global_position.x >= start_x + patrol_distance:
		direction = -1
	elif direction < 0 and global_position.x <= start_x - patrol_distance:
		direction = 1

	var wall_ahead := ray_cast_right.is_colliding() if direction > 0 else ray_cast_left.is_colliding()

	if wall_ahead or (is_on_floor() and not _has_floor_ahead()):
		direction *= -1

	animated_sprite.flip_h = direction < 0
	velocity.x = direction * speed


func _chase_player() -> void:
	var distance_x := target_player.global_position.x - global_position.x

	if absf(distance_x) <= 2.0:
		velocity.x = 0.0
		return

	direction = 1 if distance_x > 0.0 else -1
	animated_sprite.flip_h = direction < 0

	if is_on_floor() and not _has_floor_ahead():
		velocity.x = 0.0
		return

	velocity.x = direction * chase_speed


func _has_floor_ahead() -> bool:
	ledge_check.position.x = absf(ledge_check.position.x) * direction
	ledge_check.force_raycast_update()
	return ledge_check.is_colliding()



func _can_detect_player(body: Node2D) -> bool:
	if defeated or not body.is_in_group("player"):
		return false
	var player_health := body.get_node_or_null("Health") as Health
	return player_health == null or not player_health.is_dead


func _update_detected_player() -> void:
	if is_instance_valid(target_player) and detection_zone.overlaps_body(target_player) and _can_detect_player(target_player):
		return
	target_player = null
	for body in detection_zone.get_overlapping_bodies():
		if _can_detect_player(body):
			target_player = body
			break


func _on_detection_zone_body_entered(body: Node2D) -> void:
	if _can_detect_player(body):
		target_player = body


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		start_x = global_position.x


func handle_player_collision(player: Node) -> void:
	if defeated or not player is CharacterBody2D or not player.is_in_group("player"):
		return
	var player_health := player.get_node_or_null("Health") as Health
	if player_health != null and player_health.is_dead:
		return
	if try_stomp(player):
		return
	if player.has_method("receive_enemy_hit"):
		player.receive_enemy_hit(global_position, contact_damage)


func can_be_stomped_by(player: Node2D) -> bool:
	if defeated or not player is CharacterBody2D:
		return false
	var player_body := player as CharacterBody2D
	return player_body.velocity.y > 0.0 and player.global_position.y <= global_position.y - stomp_height_tolerance


func try_stomp(player: Node2D) -> bool:
	if not can_be_stomped_by(player):
		return false
	if player.has_method("bounce_after_stomp"):
		player.bounce_after_stomp()
	die()
	return true


func die() -> void:
	if defeated:
		return
	defeated = true
	var drop_component := get_node_or_null("DropOnDeath")
	if drop_component != null and drop_component.has_method("spawn_drop"):
		drop_component.spawn_drop(global_position)
	target_player = null
	velocity = Vector2.ZERO
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	for child in get_children():
		if child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
			for shape in child.get_children():
				if shape is CollisionShape2D:
					shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(animated_sprite, "scale", animated_sprite.scale * Vector2(1.45, 0.35), 0.08)
	tween.tween_property(animated_sprite, "position:y", animated_sprite.position.y + 5.0, 0.08)
	tween.chain().tween_property(animated_sprite, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)
