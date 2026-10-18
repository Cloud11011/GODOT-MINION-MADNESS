extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

var collected := false


func _on_body_entered(_body: Node) -> void:
	_collect()


func _on_body_shape_entered(
	_body_rid: RID,
	_body: Node,
	_body_shape_index: int,
	_local_shape_index: int
) -> void:
	_collect()


func _collect() -> void:
	if collected:
		return

	collected = true
	game_manager.add_point()
	animation_player.play("pickup")
