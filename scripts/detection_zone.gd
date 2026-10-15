@tool
extends Area2D


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or not collision.shape is CircleShape2D:
		return
	var circle := collision.shape as CircleShape2D
	draw_set_transform(collision.position, collision.rotation, collision.scale)
	draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 96, Color(1.0, 0.8, 0.25, 0.9), 1.5, true)
