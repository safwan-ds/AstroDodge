## The base class for all moving entities in the game.
class_name Entity extends Area2D

@export_group("Entity Stats")
@export var entity_stats: EntityStats

@export_group("Links to Scenes")
@export var j_unit: PackedScene

@export_group("Links to Nodes")
@export var sprite: AnimatedSprite2D
@export var trail: GPUParticles2D
@export var explosion: GPUParticles2D
@export var audio_player: AudioStreamPlayer2D

var hp: float:
	get:
		return _hp
var speed: float:
	get:
		return _velocity.length()

var _direction := Vector2.ZERO
var _velocity := Vector2.ZERO
@onready var _hp := entity_stats.max_health:
	set(value):
		value = clamp(value, 0.0, entity_stats.max_health)
		if value <= 0.0:
			_die()
		_hp = value


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta) -> void:
	_direction = Vector2.UP.rotated(rotation)
	_velocity = _direction * entity_stats.base_speed
	position += _velocity * delta

## This method should be overridden in subclasses to handle area interactions.
func _on_area_entered(area: Area2D) -> void:
	pass


## Defines the actions that will happen when the entity is hit.
func _be_hurt(damage: float) -> void:
	_hp -= damage
	if _hp <= 0:
		return
	Global.trigger_camera_shake.emit(entity_stats.hit_shake_intensity)


## Defines the actions that will happen when the entity dies.
func _die() -> void:
	Global.trigger_camera_shake.emit(entity_stats.death_shake_intensity)
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	sprite.hide()
	trail.emitting = false
	explosion.emitting = true
	set_process(false)
	set_process_input(false)
	await explosion.finished
	queue_free()


func _spawn_collectibles():
	for i in range(randi_range(5, 10)):
		var unit: Collectible = j_unit.instantiate()
		unit.position = position
		Global.current_world.add_child(unit)
