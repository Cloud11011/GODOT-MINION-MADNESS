
extends Area2D

@export var next_level: PackedScene

var triggered := false


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if not body.is_in_group("player"):
		return

	if next_level == null:
		push_warning("Next level is not assigned!")
		return

	var scene_path := next_level.resource_path

	if scene_path.is_empty():
		push_error("Next level has no valid resource path.")
		return

	triggered = true
	GameManager.go_to_level(scene_path)
