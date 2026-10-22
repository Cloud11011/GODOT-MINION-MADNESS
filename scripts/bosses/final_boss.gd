extends CharacterBody2D

signal rage_started
signal defeated
signal attack_telegraphed(attack_name: String)

const Shockwave := preload("res://scenes/projectiles/boss_shockwave.tscn")
enum State { APPROACH, WINDUP, CHARGE, SLAM, RECOVER, ROAR, DEFEATED }

@export var walk_speed := 75.0
@export var charge_speed := 230.0
@export var attack_interval := 1.8
@export var attack_damage := 20

var state := State.APPROACH
var state_time := 2.0
var enraged := false
var attack_count := 0
var attack_kind := ""
var attack_direction := 1.0
var target_player: Node2D
var hit_flash_left := 0.0
var slam_impacted := false
var frame_floor_offsets: Dictionary = {}

@onready var health: Health = $Health
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var contact_area: Area2D = $ContactArea
@onready var attack_area: Area2D = $AttackArea


func _ready() -> void:
	add_to_group("boss")
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	target_player = get_tree().get_first_node_in_group("player") as Node2D
	_cache_frame_floor_offsets()
	animated_sprite.frame_changed.connect(_on_sprite_frame_changed)
	animated_sprite.animation_changed.connect(_align_sprite_feet)
	animated_sprite.play("idle")
	_align_sprite_feet()


func _physics_process(delta: float) -> void:
	if state == State.DEFEATED:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = 0.0
	state_time -= delta
	hit_flash_left = maxf(hit_flash_left - delta, 0.0)
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(target_player) or target_player.get("is_dead"):
		move_and_slide()
		return
	var distance_x := target_player.global_position.x - global_position.x
	match state:
		State.APPROACH:
			animated_sprite.flip_h = distance_x < 0.0
			if absf(distance_x) > 190.0:
				velocity.x = signf(distance_x) * walk_speed * (1.5 if enraged else 1.0)
			if state_time <= 0.0:
				_begin_attack()
		State.WINDUP:
			if state_time <= 0.0:
				_execute_attack()
		State.CHARGE:
			velocity.x = attack_direction * current_charge_speed()
			if state_time <= 0.0 or is_on_wall():
				_recover()
		State.SLAM:
			if state_time <= 0.0:
				if not slam_impacted:
					_slam_impact()
				_recover()
		State.RECOVER, State.ROAR:
			if state_time <= 0.0:
				state = State.APPROACH
				state_time = current_attack_interval()
				animated_sprite.play("idle")
	# Keep the battle inside the flat central part of the existing arena.
	if (global_position.x <= 255.0 and velocity.x < 0.0) or (global_position.x >= 950.0 and velocity.x > 0.0):
		velocity.x = 0.0
		if state == State.CHARGE:
			_recover()
	move_and_slide()
	if state == State.CHARGE or (state == State.SLAM and slam_impacted):
		_apply_attack_damage()
	for body in contact_area.get_overlapping_bodies():
		handle_player_collision(body)
	_update_tint()


func current_charge_speed() -> float:
	return charge_speed * (1.55 if enraged else 1.0)


func current_attack_interval() -> float:
	return attack_interval * (0.55 if enraged else 1.0)


func current_attack_damage() -> int:
	return roundi(attack_damage * (1.5 if enraged else 1.0))


func _begin_attack() -> void:
	attack_count += 1
	attack_kind = "CHARGE" if attack_count % 2 == 1 else "SHOCKWAVE"
	attack_direction = 1.0 if target_player.global_position.x >= global_position.x else -1.0
	animated_sprite.flip_h = attack_direction < 0.0
	attack_area.position.x = 75.0 * attack_direction
	animated_sprite.play("punch" if attack_kind == "CHARGE" else "slam")
	# Hold the anticipation pose until the telegraph ends, then play the hit.
	animated_sprite.pause()
	animated_sprite.frame = 0
	state = State.WINDUP
	state_time = 0.45 if enraged else 0.8
	attack_telegraphed.emit(attack_kind)


func _execute_attack() -> void:
	animated_sprite.stop()
	if attack_kind == "CHARGE":
		state = State.CHARGE
		state_time = 0.85
		animated_sprite.play("punch")
	else:
		state = State.SLAM
		state_time = 0.5 if enraged else 0.8
		slam_impacted = false
		animated_sprite.play("slam")


func _slam_impact() -> void:
	if slam_impacted or state != State.SLAM:
		return
	slam_impacted = true
	_apply_attack_damage()
	_spawn_shockwaves()
	if enraged:
		var second_pulse := get_tree().create_timer(0.28)
		second_pulse.timeout.connect(_rage_second_pulse)


func _apply_attack_damage() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("receive_enemy_hit"):
			body.receive_enemy_hit(global_position, current_attack_damage())


func _cache_frame_floor_offsets() -> void:
	# Sprite-sheet frames have different transparent margins below the feet.
	# Align the visible feet, rather than the full padded frame, to the body.
	for animation in animated_sprite.sprite_frames.get_animation_names():
		var offsets := PackedFloat32Array()
		for frame in range(animated_sprite.sprite_frames.get_frame_count(animation)):
			var texture: Texture2D = animated_sprite.sprite_frames.get_frame_texture(animation, frame)
			var opaque_bounds := texture.get_image().get_used_rect()
			offsets.append(-(opaque_bounds.end.y - texture.get_height() * 0.5) * animated_sprite.scale.y)
		frame_floor_offsets[animation] = offsets


func _align_sprite_feet() -> void:
	var offsets: PackedFloat32Array = frame_floor_offsets.get(animated_sprite.animation, PackedFloat32Array())
	if animated_sprite.frame < offsets.size():
		animated_sprite.position.y = offsets[animated_sprite.frame]


func _on_sprite_frame_changed() -> void:
	_align_sprite_feet()
	var impact_frame := animated_sprite.sprite_frames.get_frame_count("slam") - 1
	if state == State.SLAM and animated_sprite.animation == &"slam" and animated_sprite.frame == impact_frame:
		_slam_impact()


func _rage_second_pulse() -> void:
	if is_inside_tree() and state != State.DEFEATED:
		_spawn_shockwaves()


func _spawn_shockwaves() -> void:
	for direction in [-1.0, 1.0]:
		var wave = Shockwave.instantiate()
		wave.position = get_tree().current_scene.to_local(global_position + Vector2(direction * 65.0, -18.0))
		wave.velocity = Vector2(direction * (350.0 if enraged else 230.0), 0.0)
		wave.damage = current_attack_damage()
		get_tree().current_scene.add_child(wave)


func _recover() -> void:
	state = State.RECOVER
	state_time = 0.55 if enraged else 0.9
	velocity.x = 0.0
	animated_sprite.play("idle")


func handle_player_collision(player: Node) -> void:
	if state == State.DEFEATED or state == State.ROAR or not player.is_in_group("player"):
		return
	if player.has_method("receive_enemy_hit"):
		var attack_active := state == State.CHARGE or (state == State.SLAM and slam_impacted)
		var damage := current_attack_damage() if attack_active else (18 if enraged else 12)
		player.receive_enemy_hit(global_position, damage)


func receive_banana_hit(amount: int) -> void:
	if amount <= 0 or state == State.DEFEATED:
		return
	hit_flash_left = 0.12
	health.take_damage(amount)


func _on_health_changed(current: int, maximum: int) -> void:
	if not enraged and current > 0 and current * 2 <= maximum:
		enraged = true
		state = State.ROAR
		state_time = 2.4
		velocity.x = 0.0
		animated_sprite.speed_scale = 1.6
		animated_sprite.play("slam")
		rage_started.emit()


func _update_tint() -> void:
	if hit_flash_left > 0.0:
		animated_sprite.modulate = Color(2.0, 2.0, 2.0)
	elif state == State.WINDUP:
		animated_sprite.modulate = Color(1.5, 0.8, 0.25)
	else:
		animated_sprite.modulate = Color(1.3, 0.42, 0.35) if enraged else Color.WHITE


func _on_died() -> void:
	state = State.DEFEATED
	velocity = Vector2.ZERO
	contact_area.set_deferred("monitoring", false)
	contact_area.set_deferred("monitorable", false)
	$CollisionShape2D.set_deferred("disabled", true)
	for projectile in get_tree().get_nodes_in_group("boss_projectiles"):
		projectile.queue_free()
	defeated.emit()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
	tween.tween_property(animated_sprite, "rotation", -0.35, 1.0)
