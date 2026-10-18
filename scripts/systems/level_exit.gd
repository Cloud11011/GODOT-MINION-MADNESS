
extends Area2D

@export var next_level: PackedScene

var triggered := false

func _ready() -> void:
	print("LevelExit is ready!")
	print("Monitoring: ", monitoring)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	print("Something entered LevelExit: ", body.name)

	if triggered:
		return

	if body.is_in_group("player"):
		print("Player detected!")

		if next_level == null:
			push_warning("Next level is not assigned!")
			return

		triggered = true
		get_tree().change_scene_to_packed(next_level)
