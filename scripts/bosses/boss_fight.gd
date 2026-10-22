extends Node2D

var victory := false
var global_music: AudioStreamPlayer2D
var global_music_position := 0.0
var global_music_was_playing := false

@onready var player = $Minions
@onready var boss = $finalboss
@onready var hud = $HUD


func _enter_tree() -> void:
	# Level checkpoints belong to the previous level, not the boss arena.
	GameManager.clear_checkpoint()


func _ready() -> void:
	hud.setup(player, boss)
	boss.defeated.connect(_on_boss_defeated)
	global_music = get_node_or_null("/root/MainTrack") as AudioStreamPlayer2D
	if is_instance_valid(global_music):
		global_music_was_playing = global_music.playing
		global_music_position = global_music.get_playback_position()
		global_music.stop()
	var soundtrack := $Music.stream.duplicate() as AudioStreamMP3
	soundtrack.loop = true
	$Music.stream = soundtrack
	$Music.play()
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)


func _physics_process(_delta: float) -> void:
	if victory:
		return
	if player.global_position.y > 730.0 and not player.is_dead:
		player.health.take_damage(player.health.current_health)




func _fit_camera() -> void:
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x / 1152.0, viewport_size.y / 648.0)
	$Camera2D.zoom = Vector2.ONE * fit


func _on_boss_defeated() -> void:
	if victory:
		return
	victory = true
	player.hurtbox.grant_invulnerability(5.0)
	player.ranged_attack_enabled = false
	hud.show_victory()
	await get_tree().create_timer(2.5).timeout
	GameManager.win_game()


func _exit_tree() -> void:
	if is_instance_valid(global_music) and global_music_was_playing:
		global_music.play(global_music_position)
