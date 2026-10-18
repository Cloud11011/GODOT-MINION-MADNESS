extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -300.0

var is_dead := false

@onready var health := get_node_or_null("Health") as Health


func _ready() -> void:
	if health:
		health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _on_health_died() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	get_tree().reload_current_scene()
