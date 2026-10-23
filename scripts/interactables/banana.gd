
extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var collected := false


func _on_body_entered(body: Node2D) -> void:
	_collect(body)


func _on_body_shape_entered(
	_body_rid: RID,
	body: Node2D,
	_body_shape_index: int,
	_local_shape_index: int
) -> void:
	_collect(body)


func _collect(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	collected = true
	GameManager.collect_banana(get_path())
	animation_player.play("pickup")
