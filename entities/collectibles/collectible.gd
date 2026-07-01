class_name Collectible extends Area2D
## Collectible resource that accelerates toward the player on pickup.[br]
## Updates score counters and persists collected counts to disk.

@export var collectible_type: Global.CollectibleType
@export var initial_speed := 500.0
@export var acceleration := 500.0

var _direction := Vector2.UP.rotated(TAU * randf())
var _velocity: Vector2

@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_velocity = initial_speed * _direction


func _process(delta):
	if is_queued_for_deletion():
		return
	if player:
		_direction = (player.global_position - global_position).normalized()
		var target_vel := (global_position.distance_to(player.global_position) + 300.0) * _direction
		_velocity = _velocity.move_toward(target_vel, acceleration * delta)
		position += _velocity * delta
	else:
		queue_free()


func _on_area_entered(_area):
	var gameplay := Global.current_world
	gameplay.collectibles_counter_temp[collectible_type] += 1
	Global.data_save.collectibles_counter[collectible_type] += 1
	Global.data_save.mark_dirty()
	AudioManager.play_sfx(AudioManager.SFX.PICKUP)
	Global.item_collected.emit()
	set_process(false)
	queue_free()
