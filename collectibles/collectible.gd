class_name Collectible extends Area2D

@export var collectible_type: Global.CollectibleType
@export var initial_speed := 500.0
@export var acceleration := 500.0

var _direction := Vector2.UP.rotated(TAU * randf())
var _velocity: Vector2

@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready():
	area_entered.connect(_on_area_entered)
	_velocity = initial_speed * _direction


func _process(delta):
	if player:
		_direction = (player.global_position - global_position).normalized()
		_velocity = _velocity.move_toward((global_position.distance_to(player.global_position) + 300.0) * _direction, acceleration * delta)
		position += _velocity * delta
	else:
		queue_free()


func _on_area_entered(area):
	var gameplay := Global.current_world
	gameplay.collectibles_counter_temp[collectible_type] += 1
	Global.data_save.collectibles_counter[collectible_type] += 1
	Global.data_save.save()
	Global.item_collected.emit()
	queue_free()
