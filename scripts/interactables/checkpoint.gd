
extends Area2D

@onready var respawn_point: Marker2D = $RespawnPoint

var activated := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if activated:
		return

	if not body.is_in_group("player"):
		return

	activated = true
	GameManager.set_checkpoint(respawn_point.global_position)

	print("Checkpoint activated: ", GameManager.checkpoint_position)
