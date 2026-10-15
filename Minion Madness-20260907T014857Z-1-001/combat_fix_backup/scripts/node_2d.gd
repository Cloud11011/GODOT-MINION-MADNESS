extends Node2D

const SPEED = 60
const DISTANCE = 200
const STOMP_BOUNCE_VELOCITY = -230.0

var start_x: float
var direction = 1
var defeated := false

@export var contact_damage := 25


func _ready() -> void:
	start_x = position.x


func _process(delta: float) -> void:
	if defeated:
		return

	position.x += direction * SPEED * delta

	if position.x >= start_x + 60:
		direction = -1

	if position.x <= start_x - 60:
		direction = 1


func handle_player_collision(player: Node) -> void:
	if defeated or not player is CharacterBody2D:
		return

	if _is_stomp(player):
		_defeat(player)
		return

	var health = player.get_node_or_null("Health")
	if health:
		health.take_damage(contact_damage)


func _is_stomp(player: CharacterBody2D) -> bool:
	var player_is_falling := player.velocity.y > 0.0
	var player_is_above_vector := player.global_position.y < global_position.y - 6.0
	return player_is_falling and player_is_above_vector


func _defeat(player: CharacterBody2D) -> void:
	defeated = true
	player.velocity.y = STOMP_BOUNCE_VELOCITY
	queue_free()
