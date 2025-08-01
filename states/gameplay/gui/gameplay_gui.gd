extends Control

@export_group("Links to Nodes")
@export var asteroids_label: Label
@export var score_label: Label
@export var hp_bar: TextureProgressBar
@export var speed_bar: TextureProgressBar
@export var pause_label: Label
@export var game_over_label: Label
@export var cooldown_bar: ProgressBar

@onready var gameplay := Global.current_world
@onready var player: Player = gameplay.player

var tween: Tween


func _ready() -> void:
	player.is_hurt.connect(_on_player_is_hurt)
	player.is_healed.connect(_on_player_is_healed)
	player.is_dead.connect(_on_player_is_dead)

	_set_values()
	hp_bar.value = player.hp

	game_over_label.hide()
	game_over_label.visible_ratio = 0.0

	cooldown_bar.max_value = player.shoot_cooldown
	cooldown_bar.value = player.shoot_cooldown


func _process(delta) -> void:
	_set_values()


func _input(event):
	if event.is_action_pressed("back"):
		if gameplay.paused or gameplay.game_over:
			gameplay.paused = false
			get_tree().paused = false
			Global.change_state.emit(Global.GameState.MAIN_MENU)
		else:
			gameplay.paused = true
			get_tree().paused = true
			pause_label.show()
	
	if event.is_action_pressed("up"):
		if gameplay.paused:
			gameplay.paused = false
			pause_label.hide()
			get_tree().paused = false


func _set_values() -> void:
	asteroids_label.text = "Asteroids: " + str(get_tree().get_node_count_in_group("asteroids"))
	if not gameplay.game_over:
		score_label.text = "Score: " + str(int(gameplay.score)) + "\n(x" + str(snapped(gameplay.score_multiplier, 0.01)) + ")"
		speed_bar.value = player.speed
		cooldown_bar.value = player.shoot_cooldown - player._shoot_cooldown


func _on_player_is_hurt(hp: float) -> void:
	if tween:
		tween.kill()
	hp_bar.tint_progress = Color(1, 0, 0)
	tween = create_tween().set_parallel()
	tween.tween_property(hp_bar, "value", hp, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hp_bar, "tint_progress", Color(1, 1, 1), 0.5).set_trans(Tween.TRANS_QUAD)


func _on_player_is_healed(hp: float) -> void:
	if tween:
		tween.kill()
	hp_bar.tint_progress = Color(0, 1, 0)
	tween = create_tween().set_parallel()
	tween.tween_property(hp_bar, "value", hp, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hp_bar, "tint_progress", Color(1, 1, 1), 0.5).set_trans(Tween.TRANS_QUAD)


func _on_player_is_dead() -> void:
	score_label.text = "Score: " + str(int(gameplay.score))
	pause_label.hide()
	game_over_label.show()
	create_tween().tween_property(game_over_label, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_QUAD)
