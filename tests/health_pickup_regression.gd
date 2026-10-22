extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func _run() -> void:
	var player_scene := load("res://scenes/player/minions.tscn") as PackedScene
	var pickup_scene := load("res://scenes/interactables/health_pickup.tscn") as PackedScene
	var slime_scene := load("res://scenes/enemies/slime.tscn") as PackedScene

	check(player_scene != null and pickup_scene != null and slime_scene != null, "all test scenes load")
	if player_scene == null or pickup_scene == null or slime_scene == null:
		quit.call_deferred(1)
		return

	var level := Node2D.new()
	level.name = "HealthPickupTestLevel"
	root.add_child(level)
	current_scene = level

	var player := player_scene.instantiate() as CharacterBody2D
	level.add_child(player)
	player.position = Vector2(100.0, 100.0)
	await process_frame

	check(player.is_in_group("player"), "player group uses lowercase player")
	var health := player.get_node_or_null("Health") as Health
	check(health != null, "player has Health component")

	if health != null:
		var original := health.current_health
		health.take_damage(30)
		check(health.current_health == original - 30, "damage lowers health")

		var pickup := pickup_scene.instantiate() as Area2D
		level.add_child(pickup)
		pickup.position = Vector2(2000, 2000)
		await process_frame

		check(pickup.collision_layer == 0 and pickup.collision_mask == 2, "pickup detects player collision layer only")
		var shape := (pickup.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
		check(shape != null and shape.radius < 15.0, "pickup collision size is appropriate")

		pickup.body_entered.emit(player)
		await process_frame
		check(health.current_health == min(original, original - 30 + 20), "pickup heals 20")
		check(not is_instance_valid(pickup), "collected pickup is freed")

		check(not health.heal(0), "zero healing does nothing")
		check(health.heal(500), "valid positive heal is accepted")
		check(health.current_health == health.max_health, "healing clamps to maximum health")
		check(not health.heal(20), "healing at full health is rejected")

	var slime := slime_scene.instantiate() as CharacterBody2D
	level.add_child(slime)
	slime.position = Vector2(400.0, 500.0)
	await process_frame
	check(slime.has_node("DropOnDeath"), "Slime has DropOnDeath component")
	slime.die()
	await process_frame
	var found_drop := false
	for child in level.get_children():
		if child.name.begins_with("HealthPickup"):
			found_drop = true
			break
	check(found_drop, "Slime death spawns health pickup")

	level.queue_free()
	await process_frame
	var track := root.get_node_or_null("MainTrack")
	if track != null and track.has_method("stop"):
		track.stop()
	await create_timer(0.15).timeout
	print("Health pickup regression: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit.call_deferred(0 if failures == 0 else 1)
