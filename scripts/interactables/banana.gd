extends Area2D

@onready var game_manager: Node = get_tree().current_scene.find_child("GameManager", true, false)
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
	animation_player.play("pickup")
	if is_instance_valid(game_manager) and game_manager.has_method("add_point"):
		game_manager.call("add_point")
	else:
		GameManager.add_score(1)
