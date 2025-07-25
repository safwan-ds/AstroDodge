extends Node2D

@export var player: Player
@export var star_field: GPUParticles2D
@export var direction_arrow: Polygon2D
@export var d_score: float = 1.0
@export var d2_score: float = 0.01

var score: float = 0.0
var score_multiplier: float = 1.0
var paused: bool = false
var game_over: bool = false


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
		Global.change_state.emit(Global.GameState.MAIN_MENU)
	
	if event.is_action_pressed("up") and game_over:
		Global.change_state.emit(Global.GameState.GAMEPLAY)


func _on_player_hit(hp: float) -> void:
	score_multiplier = 1.0


func _on_player_destroyed() -> void:
	game_over = true
	direction_arrow.queue_free()
