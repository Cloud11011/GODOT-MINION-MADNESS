extends CanvasLayer

var warning_tween: Tween

@onready var warning: PanelContainer = $UI/RageWarning


func setup(player: Node, boss: Node) -> void:
	player.health.health_changed.connect(_update_player_health)
	boss.health.health_changed.connect(_update_boss_health)
	boss.rage_started.connect(_show_rage_warning)
	boss.attack_telegraphed.connect(_show_attack)
	GameManager.lives_changed.connect(_update_lives)
	_update_player_health(player.health.current_health, player.health.max_health)
	_update_boss_health(boss.health.current_health, boss.health.max_health)
	_update_lives(GameManager.lives)


func _update_player_health(current: int, maximum: int) -> void:
	$UI/PlayerStats/Health.text = "MINION  %d / %d" % [current, maximum]


func _update_lives(amount: int) -> void:
	$UI/PlayerStats/Lives.text = "LIVES  %d" % amount


func _update_boss_health(current: int, maximum: int) -> void:
	$UI/BossStats/BossHealth.max_value = maximum
	$UI/BossStats/BossHealth.value = current
	$UI/BossStats/HealthText.text = "%d / %d" % [current, maximum]


func _show_attack(attack_name: String) -> void:
	$UI/AttackCue.text = "EL MACHO: " + attack_name + "!"
	var tween := create_tween()
	$UI/AttackCue.modulate.a = 1.0
	tween.tween_interval(0.8)
	tween.tween_property($UI/AttackCue, "modulate:a", 0.0, 0.3)


func _show_rage_warning() -> void:
	$UI/BossStats/Name.text = "EL MACHO  /  RAGE MODE"
	$UI/BossStats/Name.modulate = Color(1.0, 0.35, 0.2)
	warning.show()
	warning.modulate.a = 1.0
	warning_tween = create_tween()
	for _blink in range(4):
		warning_tween.tween_property(warning, "modulate:a", 0.4, 0.16)
		warning_tween.tween_property(warning, "modulate:a", 1.0, 0.16)
	warning_tween.tween_interval(0.8)
	warning_tween.tween_property(warning, "modulate:a", 0.0, 0.3)
	warning_tween.tween_callback(warning.hide)


func show_victory() -> void:
	if warning_tween and warning_tween.is_valid():
		warning_tween.kill()
	warning.hide()
	$UI/Victory.show()
	$UI/AttackCue.hide()
