extends Label

@export var player_path: NodePath

var health: Health


func _ready() -> void:
	anchors_preset = PRESET_TOP_LEFT
	offset_left = 16
	offset_top = 16
	offset_right = 220
	offset_bottom = 40

	var target := get_node_or_null(player_path)
	if target is Health:
		health = target as Health
	elif target:
		health = target.get_node_or_null("Health") as Health

	if not health:
		push_warning("HealthLabel could not find a Health node.")
		return

	health.health_changed.connect(_on_health_changed)

	_on_health_changed(
		health.current_health,
		health.max_health
	)


func _on_health_changed(current_health: int, max_health: int) -> void:
	text = "Minion life: %d / %d" % [current_health, max_health]
