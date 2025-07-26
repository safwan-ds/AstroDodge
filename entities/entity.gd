## The base class for all moving entities in the game.
class_name Entity extends Area2D

@export var entity_stats: EntityStats
@export var sprite: AnimatedSprite2D
@export var trail: GPUParticles2D
@export var audio_player: AudioStreamPlayer2D

var hp: float:
	get:
		return _hp

@onready var _hp := entity_stats.max_health:
	set(value):
		value = clamp(value, 0.0, entity_stats.max_health)
		if value <= 0.0:
			_die()
		_hp = value
@onready var _speed := entity_stats.base_speed
var _direction := Vector2.ZERO


func _process(delta):
	_direction = Vector2.UP.rotated(rotation)
	position += _direction * _speed * delta


func _hit(damage: float) -> void:
	_hp -= damage
	if _hp <= 0:
		_die()
		return
	Global.trigger_camera_shake.emit(entity_stats.hit_shake_intensity)


func _die() -> void:
	Global.trigger_camera_shake.emit(entity_stats.death_shake_intensity)
