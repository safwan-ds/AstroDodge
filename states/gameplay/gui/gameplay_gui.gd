extends Control

@export var asteroids_label: Label
@export var score_label: Label
@export var hp_bar: TextureProgressBar
@export var velocity_bar: TextureProgressBar
@export var game_over_label: Label

@onready var gameplay: Node2D = Global.current_world
@onready var player: Player = gameplay.player

var tween: Tween


func _ready() -> void:
	player.connect("hit", _on_player_hit)
	player.connect("healed", _on_player_healed)
	player.connect("destroyed", _on_player_destroyed)

	_set_values()
	hp_bar.value = player.hp

	game_over_label.hide()
	game_over_label.visible_ratio = 0.0


func _process(delta) -> void:
	_set_values()


func _set_values() -> void:
	asteroids_label.set_deferred("text", "Asteroids: " + str(get_tree().get_node_count_in_group("asteroids")))
	if not gameplay.game_over:
		score_label.set_deferred("text", "Score: " + str(int(gameplay.score)) + "\n(x" + str(snapped(gameplay.score_multiplier, 0.01)) + ")")
		velocity_bar.set_deferred("value", player.velocity.length())


func _on_player_hit(hp: float) -> void:
	if tween:
		tween.kill()
	hp_bar.set_deferred("tint_progress", Color(1, 0, 0))
	tween = create_tween().set_parallel()
	tween.tween_property(hp_bar, "value", hp, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hp_bar, "tint_progress", Color(1, 1, 1), 0.5).set_trans(Tween.TRANS_QUAD)


func _on_player_healed(hp: float) -> void:
	if tween:
		tween.kill()
	hp_bar.set_deferred("tint_progress", Color(0, 1, 0))
	tween = create_tween().set_parallel()
	tween.tween_property(hp_bar, "value", hp, 0.5).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(hp_bar, "tint_progress", Color(1, 1, 1), 0.5).set_trans(Tween.TRANS_QUAD)


func _on_player_destroyed() -> void:
	score_label.set_deferred("text", "Score: " + str(int(gameplay.score)))
	game_over_label.show()
	create_tween().tween_property(game_over_label, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_QUAD)
