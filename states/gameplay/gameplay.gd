extends Node2D

@export_group("Links to Nodes")
@export var player: Player
@export var star_field: GPUParticles2D
@export var direction_arrow: Polygon2D
@export var camera: Camera2D

@export_group("Score")
@export var d_score := 1.0
@export var d2_score := 0.01

var score := 0.0
var score_multiplier := 1.0

var paused := false
var game_over := false

@onready var collectibles_counter_temp := Global.data_save.collectibles_counter


func _process(delta) -> void:
	if not player or game_over:
		return

	star_field.position = player.position

	direction_arrow.position = player.position
	direction_arrow.rotation = player._target_angle

	score_multiplier += d2_score * delta
	score += d_score * delta * score_multiplier


func _input(event) -> void:
	if event.is_action_pressed("back"):
		if paused or game_over:
			Global.change_state.emit(Global.GameState.MAIN_MENU)

	if event.is_action_pressed("up"):
		if game_over:
			Global.change_state.emit(Global.GameState.GAMEPLAY)


func _on_player_is_hurt(hp: float) -> void:
	score_multiplier = 1.0


func _on_player_is_dead() -> void:
	game_over = true
	direction_arrow.hide()
