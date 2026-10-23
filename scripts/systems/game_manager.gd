extends Node

const SAVE_PATH := "user://highscore.save"
const MAX_LIVES := 3
const FIRST_LEVEL := "res://scenes/levels/level_1.tscn"
const GAME_OVER_SCENE := "res://scripts/systems/game_over.tscn"
const WIN_SCENE := "res://scripts/systems/win_screen.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal bananas_changed(amount: int)

var score: int = 0
var lives: int = MAX_LIVES
var high_score: int = 0
var bananas: int = 0
# Tests can disable persistent saves to protect existing user://highscore.save.
var persistent_saves_enabled := true

# Ammunition is distinct from the lifetime collection score.
func add_bananas(amount: int = 1) -> void:
	if amount <= 0:
		return
	bananas += amount
	bananas_changed.emit(bananas)


func use_banana() -> bool:
	if bananas <= 0:
		return false
	bananas -= 1
	bananas_changed.emit(bananas)
	return true


# Checkpoint
var has_checkpoint: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_score: int = 0
var checkpoint_bananas: int = 0
# A pickup's stable scene path is its identity for the current level.
# Reloading after death makes bananas appear again but never grants a second reward
# for bananas already credited at the active checkpoint.
var credited_banana_ids: Dictionary = {}
var checkpoint_credited_banana_ids: Dictionary = {}


func collect_banana(pickup_path: NodePath) -> bool:
	var key := str(pickup_path)
	if credited_banana_ids.has(key):
		return false
	credited_banana_ids[key] = true
	add_score(1)
	add_bananas(1)
	return true


func restore_checkpoint_inventory() -> void:
	score = checkpoint_score if has_checkpoint else 0
	bananas = checkpoint_bananas if has_checkpoint else 0
	credited_banana_ids = checkpoint_credited_banana_ids.duplicate() if has_checkpoint else {}
	score_changed.emit(score)
	bananas_changed.emit(bananas)


func restart_current_level() -> void:
	get_tree().paused = false
	lives = MAX_LIVES
	score = 0
	bananas = 0
	clear_checkpoint()
	lives_changed.emit(lives)
	score_changed.emit(score)
	bananas_changed.emit(bananas)
	get_tree().reload_current_scene.call_deferred()


func _ready() -> void:
	load_high_score()


# SCORING
func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

	# Best score is banked at checkpoints or level completion, not by temporary
	# pickups that will be rolled back on death.


# LIVES
func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	restore_checkpoint_inventory()

	if lives <= 0:
		game_over()
	else:
		get_tree().reload_current_scene.call_deferred()


# START A NEW GAME
func start_new_game() -> void:
	score = 0
	lives = MAX_LIVES
	bananas = 0
	bananas_changed.emit(bananas)
	score_changed.emit(score)
	lives_changed.emit(lives)
	clear_checkpoint()

	get_tree().change_scene_to_file.call_deferred(FIRST_LEVEL)


# CHANGE LEVEL
func go_to_level(path: String) -> void:
	save_high_score()
	clear_checkpoint()
	get_tree().change_scene_to_file.call_deferred(path)


# GAME OVER
func game_over() -> void:
	save_high_score()
	get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCENE)


# WIN
func win_game() -> void:
	save_high_score()
	get_tree().change_scene_to_file.call_deferred(WIN_SCENE)


# RETURN TO MAIN MENU
func back_to_menu() -> void:
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)


# CHECKPOINTS
func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	has_checkpoint = true
	checkpoint_score = score
	checkpoint_bananas = bananas
	checkpoint_credited_banana_ids = credited_banana_ids.duplicate()
	save_high_score()


func clear_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
	checkpoint_score = 0
	checkpoint_bananas = 0
	checkpoint_credited_banana_ids.clear()
	credited_banana_ids.clear()


# SAVE HIGH SCORE
func save_high_score() -> void:
	if not persistent_saves_enabled:
		return
	if score > high_score:
		high_score = score
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file:
		file.store_32(high_score)


# LOAD HIGH SCORE
func load_high_score() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file:
		high_score = file.get_32()


# CAMERA SHAKE
func shake_camera(amount: float) -> void:
	var cam := get_viewport().get_camera_2d()

	if cam and cam.has_method("shake"):
		cam.shake(amount)


# HIT STOP
func hit_stop(duration: float = 0.08) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
