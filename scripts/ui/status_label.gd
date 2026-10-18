extends Label

@export var health_path: NodePath = NodePath("../../Minions/Health")

var health_component: Health


func _ready() -> void:
	text = ""
	anchors_preset = PRESET_TOP_LEFT
	offset_left = 16
	offset_top = 44
	offset_right = 260
	offset_bottom = 68

	health_component = get_node_or_null(health_path) as Health
	if not health_component:
		return

	health_component.health_changed.connect(_on_changed)


func _on_changed(current: int, max_health: int) -> void:
	var percent := float(current) / float(max_health)
	if current <= 0:
		text = ""
	elif percent <= 0.25:
		text = "CRITICAL HEALTH"
		modulate = Color.RED
	else:
		text = ""
	
