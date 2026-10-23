extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func _finish(exit_code: int) -> void:
	var main_track := root.get_node_or_null("MainTrack") as AudioStreamPlayer2D
	if main_track != null:
		main_track.stop()
	await create_timer(0.15).timeout
	quit.call_deferred(exit_code)


func _run() -> void:
	_check(InputMap.has_action("esc"), "Pause Menu control exists")
	_check(InputMap.has_action("throw_banana"), "banana attack control exists")
	var level1 := load("res://scenes/levels/level_1.tscn") as PackedScene
	var level2 := load("res://scenes/levels/level_2.tscn") as PackedScene
	var boss_scene := load("res://scenes/bosses/boss_fight.tscn") as PackedScene
	_check(level1 != null and level2 != null and boss_scene != null, "all campaign scenes load")
	if level1 == null or level2 == null or boss_scene == null:
		await _finish(1)
		return
	var one := level1.instantiate()
	var two := level2.instantiate()
	var boss := boss_scene.instantiate()
	_check(one.has_node("HUD/ScoreLabel"), "Level 1 preserves unified score")
	_check(one.has_node("HUD/AmmoLabel"), "Level 1 shows ammo separately")
	_check(one.has_node("CanvasLayer/PauseMenu"), "Level 1 preserves pause menu")
	_check(one.has_node("Checkpoint1") and one.has_node("Checkpoint2"), "Level 1 retains both checkpoints")
	_check(two.has_node("HUD/ScoreLabel") and two.has_node("HUD/AmmoLabel"), "Level 2 retains shared HUD")
	_check(two.has_node("Minions/Camera2D"), "Level 2 retains follow camera")
	_check(two.has_node("CanvasLayer/PauseMenu"), "Level 2 retains pause menu")
	_check(two.has_node("BossExit") and not two.has_node("LevelFinish"), "Level 2 gates boss instead of Win Screen")
	_check(boss.has_node("finalboss/Health") and boss.has_node("HUD/UI/BossStats/BossHealth"), "boss battle and health bar included")
	_check(boss.has_node("PauseLayer/PauseMenu"), "boss arena uses Pause Menu")
	_check(boss.has_node("Music"), "boss music included")
	_check(boss.has_node("Platforms") and boss.get_node("Platforms").get_child_count() == 4, "boss arena platform layout preserved")
	var manager := root.get_node("GameManager")
	var before_score: int = manager.score
	var before_ammo: int = manager.bananas
	manager.add_score(1)
	manager.add_bananas(1)
	_check(manager.score == before_score + 1 and manager.bananas == before_ammo + 1, "score and ammo increase independently")
	_check(manager.use_banana() and manager.score == before_score + 1 and manager.bananas == before_ammo, "spending ammo never spends score")
	one.free()
	two.free()
	boss.free()
	print("Boss integration structure: %d/%d checks passed" % [checks - failures, checks])
	await _finish(0 if failures == 0 else 1)
