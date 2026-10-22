extends SceneTree

# Run: godot --headless --path . --script res://tests/boss_combat_regression.gd
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)


func _frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame
	await process_frame


func _run() -> void:
	var manager = root.get_node("GameManager")
	manager.bananas = 0
	manager.has_checkpoint = true
	manager.checkpoint_position = Vector2(-9999, -9999)
	change_scene_to_file("res://scenes/bosses/boss_fight.tscn")
	await scene_changed
	var arena = current_scene
	var player = arena.get_node("Minions")
	var boss = arena.get_node("finalboss")
	boss.set_physics_process(false)
	player.hurtbox.grant_invulnerability(60.0)
	await _frames(10)
	_check(player.is_on_floor() and player.health.current_health == 100, "boss minion spawns safely on the arena floor")
	_check(not manager.has_checkpoint and player.global_position.x > 700.0, "old level checkpoint cannot move the boss player outside the arena")
	_check(boss.health.max_health == 300 and boss.health.current_health == 300, "boss starts with full health")
	_check(not root.get_node("MainTrack").playing and arena.get_node("Music").playing, "boss soundtrack replaces global music")
	_check(arena.has_node("PauseLayer/PauseMenu"), "boss arena provides the same Pause Menu")
	_check(InputMap.has_action("esc"), "existing Pause Menu input action is preserved")
	_check(InputMap.action_get_events("throw_banana").size() == 2, "keyboard and mouse throw controls are registered")
	var all_feet_grounded := true
	for animation in boss.animated_sprite.sprite_frames.get_animation_names():
		boss.animated_sprite.animation = animation
		for frame in range(boss.animated_sprite.sprite_frames.get_frame_count(animation)):
			boss.animated_sprite.frame = frame
			var texture: Texture2D = boss.animated_sprite.sprite_frames.get_frame_texture(animation, frame)
			var used := texture.get_image().get_used_rect()
			var feet_y: float = boss.animated_sprite.position.y + (used.end.y - texture.get_height() * 0.5) * boss.animated_sprite.scale.y
			all_feet_grounded = all_feet_grounded and absf(feet_y) < 0.01
	_check(all_feet_grounded, "every idle, punch, and slam frame places the visible feet on the ground")
	boss.animated_sprite.play("idle")

	_check(player.unlimited_bananas and not arena.has_node("Ammo"), "the boss arena has unlimited throws and no ammo pickups")
	_check("UNLIMITED" in arena.get_node("HUD/UI/PlayerStats/Ammo").text, "boss HUD clearly shows unlimited bananas")

	# Jump through a low platform, land, then hop up to the next tier.
	_check(arena.get_node("Platforms").get_child_count() == 4, "the arena has four added platforms")
	var lower_platform = arena.get_node("Platforms/RightLower")
	var upper_platform = arena.get_node("Platforms/RightUpper")
	player.global_position = Vector2(lower_platform.global_position.x, 428.0)
	player.velocity = Vector2(0.0, player.jump_velocity)
	await _frames(48)
	_check(player.is_on_floor() and absf(player.global_position.y - lower_platform.global_position.y) < 1.0, "the minion jumps through the lower platform and lands on top")
	player.velocity.y = player.jump_velocity
	Input.action_press("ui_left")
	await _frames(50)
	Input.action_release("ui_left")
	await _frames(2)
	_check(player.is_on_floor() and absf(player.global_position.y - upper_platform.global_position.y) < 1.0, "the minion can jump from the lower platform to the upper tier")

	# Throw a real projectile across open air and let physics deliver the hit.
	player.global_position = Vector2(850, 428)
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	boss.global_position = Vector2(450, 428)
	player.animated_sprite.flip_h = true
	manager.bananas = 0
	var score_before: int = manager.score
	_check(player.throw_banana(), "the boss minion throws with zero collected bananas")
	_check(manager.bananas == 0 and manager.score == score_before, "unlimited throws preserve the player's inventory and score")
	_check(not player.throw_banana() and get_nodes_in_group("banana_projectiles").size() == 1, "unlimited throws still respect the attack cooldown")
	await _frames(50)
	_check(boss.health.current_health == 280, "a ranged banana hits the boss once for 20 damage")
	_check(get_nodes_in_group("banana_projectiles").is_empty(), "a banana is removed after impact")
	player.throw_cooldown_left = 0.0
	manager.bananas = 0
	_check(player.throw_banana(), "the next banana is available without collecting any ammo")
	for banana in get_nodes_in_group("banana_projectiles"):
		banana.queue_free()
	await _frames(2)
	player.throw_cooldown_left = 0.0
	manager.bananas = 5
	_check(player.throw_banana() and manager.bananas == 5, "unlimited boss attacks do not spend previously collected bananas")
	for banana in get_nodes_in_group("banana_projectiles"):
		banana.queue_free()
	await _frames(2)
	player.throw_cooldown_left = 0.0
	player.is_dead = true
	_check(not player.throw_banana() and manager.bananas == 5, "dead players cannot throw, even with unlimited bananas")
	player.is_dead = false
	player.unlimited_bananas = false
	manager.bananas = 1
	_check(player.throw_banana() and manager.bananas == 0, "finite-ammo mode still consumes one collected banana")
	for banana in get_nodes_in_group("banana_projectiles"):
		banana.queue_free()
	await _frames(2)
	player.throw_cooldown_left = 0.0
	_check(not player.throw_banana(), "finite-ammo mode still requires collected bananas")
	player.unlimited_bananas = true
	manager.bananas = 5

	# Hit a player beyond the boss's body, where the visible fist reaches.
	player.global_position = Vector2(590, 428)
	player.velocity = Vector2.ZERO
	player.hurtbox.invincibility_left = 0.0
	boss.attack_area.position.x = 75.0
	boss.state = boss.State.CHARGE
	boss.state_time = 1.0
	boss.set_physics_process(true)
	await _frames(3)
	boss.set_physics_process(false)
	_check(player.health.current_health == 80, "the physical punch hitbox deals 20 damage beyond body-contact range")
	_check(boss.is_on_floor() and boss.global_position.y > 420.0, "the boss moves beneath one-way platforms without floating onto them")
	_check(player.velocity.x > 0.0 and player.velocity.y < 0.0, "a landed boss attack knocks the minion away")
	player.health.heal_full()
	player.velocity = Vector2.ZERO
	player.hurtbox.invincibility_left = 0.0
	boss.global_position = Vector2(450, 428)
	player.global_position = Vector2(590, 428)
	boss.state = boss.State.APPROACH
	boss.attack_kind = "SHOCKWAVE"
	boss._execute_attack()
	await create_timer(0.7).timeout
	_check(player.health.current_health == 80 and boss.slam_impacted, "slam damage occurs when its impact animation lands")
	player.health.heal_full()
	for projectile in get_nodes_in_group("boss_projectiles"):
		projectile.queue_free()
	await _frames(2)

	# The second half of the fight has one clear transition and stronger attacks.
	var rage_events := [0]
	boss.rage_started.connect(func(): rage_events[0] += 1)
	var normal_speed: float = boss.current_charge_speed()
	var normal_interval: float = boss.current_attack_interval()
	var normal_damage: int = boss.current_attack_damage()
	boss.receive_banana_hit(129)
	_check(boss.health.current_health == 151 and not boss.enraged, "rage stays off above half health")
	boss.receive_banana_hit(1)
	_check(boss.enraged and boss.state == boss.State.ROAR, "rage begins at exactly 50 percent health")
	_check(arena.get_node("HUD/UI/RageWarning").visible, "WARNING! RAGE MODE caution appears at the transition")
	_check(boss.current_charge_speed() > normal_speed and boss.current_attack_interval() < normal_interval and boss.current_attack_damage() > normal_damage, "rage increases charge speed, damage, and attack frequency")
	boss.receive_banana_hit(1)
	_check(rage_events[0] == 1, "rage warning triggers only once")

	# Check actual player damage, immunity, and physical shockwave collision.
	player.hurtbox.invincibility_left = 0.0
	boss.state = boss.State.CHARGE
	boss.handle_player_collision(player)
	boss.handle_player_collision(player)
	_check(player.health.current_health == 70, "rage charge deals 30 damage once during invincibility")
	player.hurtbox.invincibility_left = 0.0
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(750, 428)
	boss.global_position = Vector2(450, 428)
	boss._spawn_shockwaves()
	await _frames(50)
	_check(player.health.current_health == 40, "a ranged boss shockwave damages the player through actual physics")
	for wave in get_nodes_in_group("boss_projectiles"):
		wave.queue_free()
	await _frames(2)
	player.hurtbox.invincibility_left = 0.0
	player.global_position = Vector2(750, 396)
	player.velocity = Vector2.ZERO
	boss._spawn_shockwaves()
	await _frames(50)
	_check(player.health.current_health == 10, "the visible edge of a shockwave also damages the minion")
	player.hurtbox.grant_invulnerability(60.0)
	for wave in get_nodes_in_group("boss_projectiles"):
		wave.queue_free()
	await _frames(2)
	boss.attack_kind = "SHOCKWAVE"
	boss._execute_attack()
	await create_timer(0.75).timeout
	_check(get_nodes_in_group("boss_projectiles").size() == 4, "rage shockwave attack fires two pulses in both directions")
	player.hurtbox.grant_invulnerability(60.0)
	boss.receive_banana_hit(999)
	await _frames(2)
	_check(boss.health.is_dead and arena.victory, "zero boss health ends the fight and starts victory")
	_check(get_nodes_in_group("boss_projectiles").is_empty(), "boss defeat removes hostile projectiles")
	_check(arena.get_node("HUD/UI/Victory").visible and not arena.get_node("HUD/UI/RageWarning").visible, "victory replaces the rage warning")
	var saved_ammo: int = manager.bananas
	await create_timer(2.7).timeout
	_check(current_scene.scene_file_path == manager.WIN_SCENE, "boss defeat reaches the game's win screen")
	manager.back_to_menu()
	await scene_changed
	await _frames(3)
	_check(root.get_node("MainTrack").playing, "Fun, Fun, Fun plays again after returning to the menu")
	_check(manager.bananas == saved_ammo, "unspent bananas persist across scene changes")
	change_scene_to_file("res://scenes/levels/level_2.tscn")
	await scene_changed
	_check(current_scene.get_node("Minions").position == Vector2(8, 533), "Level 2 keeps the original player spawn")
	_check(not current_scene.get_node("Minions").unlimited_bananas, "unlimited ammo is restricted to the boss minion")
	_check(current_scene.has_node("Minions/Camera2D") and current_scene.get_node("Minions/Camera2D").zoom == Vector2(5, 5), "Level 2 retains the integrated follow camera")
	_check(current_scene.has_node("HUD/ScoreLabel") and current_scene.has_node("HUD/AmmoLabel"), "Level 2 retains the shared score and ammo HUD")
	_check(current_scene.has_node("CanvasLayer/PauseMenu"), "Level 2 retains the integrated Pause Menu")
	_check(not current_scene.has_node("LevelFinish"), "Level 2 finish cannot bypass the boss")
	current_scene.get_node("BossExit")._on_body_entered(current_scene.get_node("Minions"))
	await scene_changed
	_check(current_scene.scene_file_path == "res://scenes/bosses/boss_fight.tscn", "Level 2's exit enters the boss arena")
	print("Boss combat regression: %d/%d checks passed" % [checks - failures.size(), checks])
	unload_current_scene()
	await _frames(2)
	root.get_node("MainTrack").stop()
	await create_timer(0.15).timeout
	quit.call_deferred(0 if failures.is_empty() else 1)
