class_name Voltstar extends Entity
## Orbiting enemy that maintains a fixed distance from the player.[br]
## Fires [Voltshot] projectiles on a timer. Drops collectibles when destroyed.

@export var guns: Node2D
@export var voltshot_scene: PackedScene
@export var distance_to_player := 100.0
@export var orbit_correction_speed := 2.0
## Minimum distance between voltstars before repulsion kicks in (pixels).
@export var repel_threshold := 60.0
## Strength of the perpendicular repulsion push when voltstars overlap.
@export var repel_strength := 80.0

var _rotation_speed := randf_range(1.0, 5.0)
var _movement_direction = [1, -1].pick_random()

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var _speed := entity_stats.base_speed + randf_range(-20.0, 20.0)


func _ready() -> void:
	super()
	VoltstarRegistry.register(self)


func _exit_tree() -> void:
	if is_instance_valid(VoltstarRegistry):
		VoltstarRegistry.unregister(self)


func _on_area_entered(area) -> void:
	if area.is_in_group("player") or area.is_in_group("bullets"):
		if area.is_in_group("bullets"):
			_spawn_collectibles.call_deferred(Global.CollectibleType.J_UNIT, 2, 5)
		audio_player.play()
		_die()


## Orbit around the player. Called by Entity._process via _move().
func _move(delta) -> void:
	rotate(delta * _rotation_speed)
	if player:
		_direction = (position - player.position).normalized()
		var weight := 1.0 - exp(-orbit_correction_speed * delta)
		position = lerp(position, (distance_to_player - (position - player.position).length()) * _direction + position, weight)
	_velocity = _speed * _direction.rotated(PI / 2.0 * _movement_direction)
	position += _velocity * delta

	# Gentle perpendicular repulsion from nearby Voltstars.
	# Pushes them apart along the orbit tangent so they don't overlap.
	for v in VoltstarRegistry.voltstars:
		if v == self:
			continue
		var dist := global_position.distance_to(v.global_position)
		if dist < repel_threshold:
			var away: Vector2 = (global_position - v.global_position).normalized()
			var factor := 1.0 - dist / repel_threshold
			position += away * repel_strength * delta * factor


## Fire a [Voltshot] from each gun toward the player.
func _on_shooting_timer_timeout() -> void:
	if is_processing() and guns:
		for gun in guns.get_children():
			var voltshot: Voltshot = voltshot_scene.instantiate()
			voltshot.position = gun.global_position
			add_sibling(voltshot)
