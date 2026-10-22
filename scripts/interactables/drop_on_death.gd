extends Node

@export var pickup_scene: PackedScene = preload("res://scenes/interactables/health_pickup.tscn")
@export_range(0.0, 1.0, 0.05) var drop_chance: float = 1.0
@export var spawn_offset := Vector2(0.0, -10.0)


func spawn_drop(world_position: Vector2) -> void:
	if pickup_scene == null or randf() > drop_chance:
		return

	# Wait until the physics engine finishes its collision queries.
	call_deferred("_create_pickup", world_position + spawn_offset)


func _create_pickup(spawn_position: Vector2) -> void:
	var current_level := get_tree().current_scene as Node2D
	if current_level == null:
		return

	var pickup := pickup_scene.instantiate() as Node2D
	if pickup == null:
		return

	current_level.add_child(pickup)
	pickup.global_position = spawn_position
