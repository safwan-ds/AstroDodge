class_name Voltstar extends Entity

@export var guns: Node2D
@export var voltshot_scene: PackedScene
@export var distance_to_player := 100.0

var _rotation_speed := randf_range(1.0, 5.0)
var _movement_direction = [1, -1].pick_random()

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var _speed := entity_stats.base_speed + randf_range(-20.0, 20.0)


func _process(delta) -> void:
	rotate(delta * _rotation_speed)
	if player:
		_direction = (position - player.position).normalized()
		position = lerp(position, (distance_to_player - (position - player.position).length()) * _direction + position, delta)
	_velocity = _speed * _direction.rotated(PI / 2.0 * _movement_direction)
	position += _velocity * delta


func _on_area_entered(area) -> void:
	if area.get_groups().any(func(x): return x in ["voltstars", "player", "bullets"]):
		if area.is_in_group("bullets"):
			_spawn_collectibles.call_deferred()
		audio_player.play()
		await _die()


func _on_shooting_timer_timeout() -> void:
	if is_processing():
		for gun in guns.get_children():
			var voltshot: Voltshot = voltshot_scene.instantiate()
			voltshot.position = gun.global_position
			Global.current_world.add_child(voltshot)
