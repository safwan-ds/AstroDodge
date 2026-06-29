extends Node2D
## Main gameplay world. Tracks score with multiplier, follows player with star field,[br]
## and handles game-over / menu transitions.

@export_group("Links to Nodes")
@export var player: Player
@export var star_field: GPUParticles2D
@export var direction_arrow: Polygon2D
@export var camera: Camera2D

@export_group("Score")
## Base score gained per second.
@export var d_score := 1.0
## Score multiplier growth per second.
@export var d2_score := 0.01
## Score multiplier decay when player is hurt.
@export var d3_score := 0.05

var score := 0.0
var score_multiplier := 1.0

var paused := false
var game_over := false

var collectibles_counter_temp: Array[int]


func _ready() -> void:
	collectibles_counter_temp.resize(Global.CollectibleType.size())
	collectibles_counter_temp.fill(0)


func _process(delta) -> void:
	if not player or game_over:
		return

	star_field.position = player.position

	direction_arrow.position = player.position
	direction_arrow.rotation = player.target_angle

	score_multiplier += d2_score * delta
	score += d_score * delta * score_multiplier


func _on_player_is_hurt(_hp: float) -> void:
	score_multiplier = max(1.0, score_multiplier - d3_score)


func _on_player_is_dead() -> void:
	game_over = true
	direction_arrow.hide()
