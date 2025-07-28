## The base class for all moving entities in the game.
class_name Entity extends Area2D

@export var entity_stats: EntityStats
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


func _on_area_entered(area: Area2D) -> void:
	pass # This method should be overridden in subclasses to handle area interactions.


func _hit(damage: float) -> void:
	_hp -= damage
	if _hp <= 0:
		return
	Global.trigger_camera_shake.emit(entity_stats.hit_shake_intensity)


func _die() -> void:
	Global.trigger_camera_shake.emit(entity_stats.death_shake_intensity)
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	sprite.hide()
	trail.emitting = false
	explosion.emitting = true
	set_process(false)
	await explosion.finished
