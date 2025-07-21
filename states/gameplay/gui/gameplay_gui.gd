extends Control

@export var velocity_label: Label
@export var asteroids_label: Label
@export var health_label: Label
@export var score_label: Label
@export var hp_bar: TextureProgressBar
@export var velocity_bar: TextureProgressBar

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var gameplay: Node2D = get_node("/root/Main/World2D/Gameplay")


func _process(_delta):
	asteroids_label.set_deferred("text", "Asteroids: " + str(get_tree().get_node_count_in_group("asteroids")))
	health_label.set_deferred("text", "Health: " + str(int(player.health)))
	score_label.set_deferred("text", "Score: " + str(int(gameplay.score)) + "\n(x" + str(snapped(gameplay.score_multiplier, 0.01)) + ")")
	hp_bar.set_deferred("value", player.health)
	velocity_bar.set_deferred("value", player._velocity.length())


func _on_update_interval_timeout() -> void:
	if player:
		velocity_label.set_deferred("text", "Velocity: " + str(snapped(player._velocity.length(), 0.1)))
