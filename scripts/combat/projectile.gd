extends Node2D

@export var damage: int = 20
@export var targets_player := false
@export var lifetime := 2.0

var velocity := Vector2.ZERO
var spent := false
var shockwave_shape: CircleShape2D


func _ready() -> void:
	add_to_group("combat_projectiles")
	if targets_player:
		add_to_group("boss_projectiles")
		shockwave_shape = CircleShape2D.new()
		shockwave_shape.radius = 16.0
	else:
		add_to_group("banana_projectiles")


func _physics_process(delta: float) -> void:
	if spent:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var next_position := global_position + velocity * delta
	if targets_player:
		# Match the visible wave's width; a thin ray misses glancing impacts.
		var shape_query := PhysicsShapeQueryParameters2D.new()
		shape_query.shape = shockwave_shape
		shape_query.transform = Transform2D(0.0, next_position)
		shape_query.collision_mask = 2
		for collision in get_world_2d().direct_space_state.intersect_shape(shape_query, 4):
			var body: Object = collision["collider"]
			if body.has_method("receive_enemy_hit"):
				body.receive_enemy_hit(global_position, damage)
				spent = true
				queue_free()
				return
		global_position = next_position
		return
	# Sweep the entire movement so fast bananas cannot skip through the boss.
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 5)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target: Object = hit["collider"]
		if targets_player and target.has_method("receive_enemy_hit"):
			target.receive_enemy_hit(global_position, damage)
		elif not targets_player:
			if target.has_method("receive_banana_hit"):
				target.receive_banana_hit(damage)
			elif target is Node and target.is_in_group("enemies") and target.has_method("die"):
				target.die()
		spent = true
		queue_free()
		return
	global_position = next_position
	if not targets_player:
		$Sprite2D.rotation += delta * 12.0 * signf(velocity.x)


func _draw() -> void:
	if not targets_player:
		return
	draw_circle(Vector2.ZERO, 19.0, Color(1.0, 0.15, 0.02, 0.24))
	draw_arc(Vector2.ZERO, 15.0, PI, TAU, 16, Color(1.0, 0.38, 0.06), 6.0, true)
	draw_arc(Vector2.ZERO, 8.0, PI, TAU, 12, Color(1.0, 0.88, 0.3), 4.0, true)
