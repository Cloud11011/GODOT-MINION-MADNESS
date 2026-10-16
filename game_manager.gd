extends Node

const SAVE_PATH := "user://highcsore.save"
const MAX_LIVES := 3
const FIRST_LEVEL := "res://levels/level_1.tscn"
const GAME_OVER_SCENE := "res://game_over.tscn"
const WIN_SCENCE := "res://win_screen.tscn"
const MENU_SCENE := "res://main_menu/tscn"

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)

var score: int = 0
var lives: int = MAX_LIVES
var high_score: int = 0

#Checkpoint
var has_checkpoint: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	pass	
