extends SceneTree

# Run with: godot --headless --path <project> --script res://tests/combat_regression.gd
var failures: Array[String] = []
var checks: int = 0
var arena: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame
	await process_frame


func _new_arena(floor_width: float = 1600.0) -> void:
	if is_instance_valid(arena):
		arena.free()
	arena = Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(floor_width, 20.0)
	collision.shape = rectangle
	floor_body.add_child(collision)
	floor_body.position.y = 210.0
	arena.add_child(floor_body)


func _player(at: Vector2):
	var player = load("res://scenes/player/player.tscn").instantiate()
	player.position = at
	arena.add_child(player)
	player.set_physics_process(false)
	return player


func _enemy(at: Vector2, scene_path: String = "res://scenes/enemies/slime.tscn"):
	var enemy = load(scene_path).instantiate()
	enemy.position = at
	arena.add_child(enemy)
	return enemy


func _run() -> void:
	_new_arena()
	var player = _player(Vector2(30.0, 200.0))
	var slime = _enemy(Vector2(0.0, 200.0))
	slime.set_physics_process(false)
	await _frames(4)
	slime.handle_player_collision(player)
	_check(player.health.current_health == 90, "slime hit applies its contact damage")
	_check(player.velocity.x > 0.0 and player.velocity.y < 0.0, "right-side hit pushes right and upward")
	_check(player.knockback_left > 0.0, "hit starts control lock")
	slime.handle_player_collision(player)
	_check(player.health.current_health == 90, "duplicate collision does not apply duplicate damage")
	Input.action_press("ui_left")
	player._physics_process(1.0 / 60.0)
	Input.action_release("ui_left")
	_check(player.velocity.x > 0.0, "opposing movement input cannot cancel knockback")
	player.global_position = Vector2(-30.0, 200.0)
	player.hurtbox.invincibility_left = 0.0
	slime.handle_player_collision(player)
	_check(player.velocity.x < 0.0 and player.velocity.y < 0.0, "left-side hit pushes left and upward")
	player.hurtbox.invincibility_left = 0.0
	player.global_position.x = slime.global_position.x
	player.velocity.y = 0.0
	slime.handle_player_collision(player)
	_check(player.velocity.x != 0.0, "aligned hit still has horizontal knockback")
	player.hurtbox.set_physics_process(false)
	await create_timer(1.05).timeout
	_check(is_equal_approx(player.animated_sprite.modulate.a, 1.0), "hit flash restores sprite opacity")

	_new_arena()
	player = _player(Vector2(0.0, 200.0))
	slime = _enemy(Vector2(0.0, 200.0))
	slime.set_physics_process(false)
	await _frames(5)
	_check(player.health.current_health == 90, "real body and area overlap applies one hit")
	await create_timer(0.2).timeout
	_check(player.health.current_health == 90, "overlapping enemy cannot damage during protection")
	await create_timer(0.9).timeout
	_check(player.health.current_health == 80, "existing overlap damages again after protection expires")

	for scene_path in ["res://scenes/enemies/slime.tscn", "res://scenes/enemies/node_2d.tscn"]:
		_new_arena()
		player = _player(Vector2(0.0, 188.0))
		player.velocity.y = 120.0
		slime = _enemy(Vector2(0.0, 200.0), scene_path)
		slime.set_physics_process(false)
		await _frames(4)
		_check(slime.defeated and player.health.current_health == 100, scene_path + " real stomp defeats enemy without contact damage")
		_check(player.velocity.y == player.stomp_bounce_velocity, scene_path + " stomp bounces player")
		_check(slime.get_node("CollisionShape2D").disabled, scene_path + " dead enemy disables physical collision")
		slime.handle_player_collision(player)
		_check(player.health.current_health == 100, scene_path + " defeated enemy cannot damage player")
		await create_timer(0.3).timeout
		_check(not is_instance_valid(slime), scene_path + " death removes enemy")

	_new_arena()
	player = _player(Vector2(30.0, 200.0))
	slime = _enemy(Vector2(0.0, 200.0), "res://scenes/enemies/node_2d.tscn")
	slime.set_physics_process(false)
	await _frames(4)
	player.velocity.y = -100.0
	slime.handle_player_collision(player)
	_check(not slime.defeated and player.health.current_health == 75, "rising side contact retains Vector's 25 damage")

	_new_arena(160.0)
	player = _player(Vector2(500.0, 200.0))
	slime = _enemy(Vector2(0.0, 200.0))
	slime.patrol_distance = 500.0
	var stayed_on_platform := true
	var turned_at_edge := false
	for _frame in range(160):
		await _frames(1)
		stayed_on_platform = stayed_on_platform and absf(slime.position.x) < 80.0 and slime.position.y < 202.0
		turned_at_edge = turned_at_edge or slime.direction == -1
	_check(stayed_on_platform and turned_at_edge, "patrol turns at platform edge and remains grounded")
	_check(slime.target_player == null and absf(slime.velocity.x) == slime.speed, "player outside circle leaves enemy at original patrol speed")
	_check(slime.detection_zone.get_node("CollisionShape2D").shape.radius == 80.0, "detection uses reference's smaller 80-pixel circle")
	player.global_position = slime.global_position + Vector2(40.0, 0.0)
	await _frames(5)
	_check(slime.target_player == player and absf(slime.velocity.x) == slime.chase_speed, "entering circle starts faster pursuit")
	player.global_position = Vector2(500.0, 200.0)
	await _frames(5)
	_check(slime.target_player == null and absf(slime.velocity.x) == slime.speed, "leaving circle resumes patrol")

	_new_arena(160.0)
	player = _player(Vector2(120.0, 200.0))
	slime = _enemy(Vector2(65.0, 200.0))
	await _frames(30)
	_check(slime.global_position.x > 80.0 and slime.global_position.y > 205.0 and slime.velocity.y > 0.0, "aggro crosses platform edge and obeys gravity")

	_new_arena()
	var killzone = load("res://scenes/interactables/killzone.tscn").instantiate()
	var kill_shape := CollisionShape2D.new()
	var kill_rectangle := RectangleShape2D.new()
	kill_rectangle.size = Vector2(100.0, 40.0)
	kill_shape.shape = kill_rectangle
	killzone.add_child(kill_shape)
	killzone.position = Vector2(0.0, 1000.0)
	arena.add_child(killzone)
	slime = _enemy(Vector2(0.0, 990.0))
	await _frames(5)
	_check(slime.defeated, "fall killzone detects and defeats slime")
	await create_timer(0.3).timeout
	_check(not is_instance_valid(slime), "fallen slime is removed")

	# Validate the actual main level, including existing health UI and respawn.
	arena.free()
	arena = null
	var main_level = load("res://scenes/legacy/main_game.tscn").instantiate()
	root.add_child(main_level)
	current_scene = main_level
	await _frames(8)
	player = main_level.get_node("Minions")
	slime = main_level.get_node("vector")
	_check(player.health.current_health == 100 and player.speed == 100.0, "main level retains Minion health and movement speed")
	_check(slime.is_on_floor() and slime.global_position.y < -130.0, "main Vector stays on its original platform")
	var bottom_vector = main_level.get_node("vector_bottom")
	_check(bottom_vector.contact_damage == slime.contact_damage and bottom_vector.chase_speed == slime.chase_speed, "bottom Vector shares the original combat mechanics")
	var top_min_x: float = slime.global_position.x
	var top_max_x: float = slime.global_position.x
	var bottom_min_x: float = bottom_vector.global_position.x
	var bottom_max_x: float = bottom_vector.global_position.x
	var both_survived := true
	for _frame in range(120):
		await _frames(1)
		if not is_instance_valid(slime) or not is_instance_valid(bottom_vector):
			both_survived = false
			break
		top_min_x = minf(top_min_x, slime.global_position.x)
		top_max_x = maxf(top_max_x, slime.global_position.x)
		bottom_min_x = minf(bottom_min_x, bottom_vector.global_position.x)
		bottom_max_x = maxf(bottom_max_x, bottom_vector.global_position.x)
	_check(both_survived, "both Vectors survive normal patrol in the actual level")
	_check(top_max_x - top_min_x > 10.0, "original Vector visibly patrols its platform")
	_check(bottom_max_x - bottom_min_x > 10.0, "bottom Vector visibly patrols lower ground")
	if is_instance_valid(bottom_vector):
		_check(bottom_vector.is_on_floor() and bottom_vector.global_position.y > 180.0 and bottom_vector.global_position.y < 210.0, "bottom Vector stands on lower ground above the fall zone")
	player.receive_enemy_hit(player.global_position - Vector2(20.0, 0.0), 25)
	_check("75" in main_level.get_node("HUD/HealthLabel").text, "main health label updates after damage")
	player.health.take_damage(player.health.current_health)
	_check(player.is_dead and player.velocity == Vector2.ZERO, "zero health freezes player immediately")
	await create_timer(0.5).timeout
	_check(current_scene != main_level and current_scene.get_node("Minions/Health").current_health == 100, "existing death reload restores player health and enemies")
	_check(current_scene.has_node("vector") and current_scene.has_node("vector_bottom"), "respawn restores both Vector enemies")

	print("Combat regression: %d/%d checks passed" % [checks - failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
