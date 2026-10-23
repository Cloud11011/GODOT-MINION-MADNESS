extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, name: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", name)
	else:
		failures += 1
		push_error("FAIL: " + name)


func _run() -> void:
	var mgr := root.get_node("GameManager")
	mgr.persistent_saves_enabled = false
	var level2 := load("res://scenes/levels/level_2.tscn") as PackedScene
	var player_scene := load("res://scenes/player/minions.tscn") as PackedScene
	var krazy_scene := load("res://scenes/enemies/krazyminion_enemy.tscn") as PackedScene
	var projectile_scene := load("res://scenes/projectiles/banana_projectile.tscn") as PackedScene
	check(level2 != null and player_scene != null and krazy_scene != null and projectile_scene != null, "all core remediation scenes load")
	if level2 == null or player_scene == null or krazy_scene == null or projectile_scene == null:
		quit.call_deferred(1)
		return
	var two := level2.instantiate()
	check(two.has_node("Checkpoint1/RespawnPoint"), "Level 2 has reachable checkpoint and spawn marker")
	two.free()
	check(InputMap.has_action("attack"), "independent J-key melee action exists")
	var level := Node2D.new()
	root.add_child(level)
	current_scene = level
	var player := player_scene.instantiate() as CharacterBody2D
	level.add_child(player)
	player.set_physics_process(false)
	player.global_position = Vector2(200, 200)
	var enemy := krazy_scene.instantiate() as CharacterBody2D
	level.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.global_position = Vector2(217, 200)
	await process_frame
	check(player.has_node("MeleeHitbox"), "melee independent of animation scene")
	check(enemy.has_node("Health") and enemy.has_node("DropOnDeath"), "Krazy has Health and drop component")
	var attack := player.get_node("MeleeHitbox")
	check(bool(attack.call("request_attack", 1.0)), "first melee attack succeeds")
	check(not bool(attack.call("request_attack", 1.0)), "cooldown blocks duplicate swing")
	for i in range(18):
		await physics_frame
	var enemy_health := enemy.get_node("Health") as Health
	check(enemy_health.current_health == 25, "melee hits Health once per swing")
	# Actual physics overlap, not a manually emitted body_entered signal.
	enemy.global_position = Vector2(600, 600)
	var health := player.get_node("Health") as Health
	health.take_damage(35)
	var hp_before := health.current_health
	var pickup_scene := load("res://scenes/interactables/health_pickup.tscn") as PackedScene
	var pickup := pickup_scene.instantiate() as Area2D
	level.add_child(pickup)
	pickup.global_position = player.global_position
	for i in range(6):
		await physics_frame
	check(health.current_health > hp_before and health.current_health <= health.max_health, "actual Area2D physics overlap heals player")
	check(not is_instance_valid(pickup), "real collision frees health pickup")
	# Test checkpoint inventory rollback and no duplicate reward for banked banana.
	mgr.score = 0
	mgr.bananas = 0
	mgr.clear_checkpoint()
	var banana_id := NodePath("/root/TestBananaOne")
	check(mgr.collect_banana(banana_id), "banana grants score and ammo")
	mgr.set_checkpoint(Vector2(150, 150))
	mgr.collect_banana(NodePath("/root/TestBananaTwo"))
	mgr.restore_checkpoint_inventory()
	check(mgr.score == 1 and mgr.bananas == 1, "death rolls score and ammo to checkpoint")
	check(not mgr.collect_banana(banana_id), "checkpoint banana cannot be farmed")
	check(mgr.collect_banana(NodePath("/root/TestBananaTwo")), "post-checkpoint banana returns on retry")
	mgr.clear_checkpoint()
	level.queue_free()
	await process_frame
	mgr.persistent_saves_enabled = true
	var music := root.get_node_or_null("MainTrack")
	if music != null:
		music.stop()
	await create_timer(0.15).timeout
	print("Core remediation: %d/%d checks passed" % [checks - failures, checks])
	quit.call_deferred(0 if failures == 0 else 1)
