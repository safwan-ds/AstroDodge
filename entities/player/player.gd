class_name Player extends Area2D
signal hit(hp: float)
signal healed(hp: float)
signal died

const MAX_HP: float = 100.0

@export var sprite: AnimatedSprite2D
@export var trail: GPUParticles2D
@export var explosion: GPUParticles2D
@export var animation_player: AnimationPlayer
@export var engine_sound: AudioStreamPlayer2D

@export var min_speed := 50
@export var max_speed := 300
@export var acceleration := 300
@export var rotation_speed := 5
@export var friction := 2
@export var mouse_tracehold := 10
@export var invulnerability_time: float = 1.0

var velocity:
	get:
		return _velocity
var target_angle:
	get:
		return _target_angle
var hp:
	get:
		return _hp

var _velocity: Vector2 = Vector2(0.0, 0.0)
var _target_angle: float = 0.0
var _direction: Vector2 = Vector2.UP
var _forward: float = 0.0
var _distance_to_mouse: Vector2 = Vector2.ZERO
var _hp: float = MAX_HP:
	set(value):
		value = clamp(value, 0.0, MAX_HP)
		if value < _hp:
			emit_signal("hit", value)
		if value > _hp:
			emit_signal("healed", value)
		if value <= 0.0:
			_die()
		_hp = value
var _invulnerable: bool = false


func _process(delta) -> void:
	_distance_to_mouse = (get_global_mouse_position() - position)
	if _distance_to_mouse.length() >= mouse_tracehold:
		_target_angle = _distance_to_mouse.angle() + PI / 2
	rotation = lerp_angle(rotation, _target_angle, rotation_speed * delta)
	_direction = Vector2.UP.rotated(rotation)

	_forward = Input.get_axis("down", "up")
	if _forward:
		_velocity += _forward * acceleration * _direction * delta
	# elif _velocity.length() > min_speed + 0.1:
	# 	_velocity -= _velocity.normalized() * friction * (_velocity.length() - min_speed) * delta
	else:
		_velocity = lerp(_velocity, (_direction * min_speed), friction * delta)

	_velocity = _velocity.limit_length(max_speed)
	position += _velocity * delta

	trail.set_deferred("amount_ratio", _velocity.length() / max_speed)
	engine_sound.set_deferred("pitch_scale", 1.0 + (_velocity.length() - min_speed) / (2 * (max_speed - min_speed)))


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and not _invulnerable:
		_hit(10)


func _hit(damage: float) -> void:
	_hp -= damage
	_invulnerable = true
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	await get_tree().create_timer(invulnerability_time).timeout
	_invulnerable = false
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _die() -> void:
	emit_signal("died")
	Global.trigger_camera_shake.emit(5)
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	sprite.hide()
	trail.emitting = false
	explosion.emitting = true
	set_process(false)
	await explosion.finished
