extends Node2D

@export var player: Player
@export var star_field: GPUParticles2D
@export var direction_arrow: Polygon2D
@export var score_per_second: float = 1.0
@export var score_multiplier_per_second: float = 0.01

var score: float = 0.0
var score_multiplier: float = 1.0


func _process(delta) -> void:
	if not player:
		return

	star_field.position = player.position

	direction_arrow.position = player.position
	direction_arrow.rotation = player._target_angle

	score_multiplier += score_multiplier_per_second * delta
	score += score_per_second * delta * score_multiplier


func _input(event) -> void:
	if event.is_action_pressed("back"):
		Global.change_state(Global.GameState.MAIN_MENU)


func _on_player_hit() -> void:
	score_multiplier = 1.0
