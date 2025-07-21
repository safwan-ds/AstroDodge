class_name Player extends Area2D
signal hit
signal destroyed

@export var sprite: AnimatedSprite2D
@export var engine_smoke: GPUParticles2D
@export var animation_player: AnimationPlayer
@export var engine_sound: AudioStreamPlayer2D

@export var min_speed: int = 50
@export var max_speed: int = 300
@export var acceleration: int = 300
@export var rotation_speed: int = 5
@export var friction: int = 2
@export var mouse_tracehold: int = 10
@export var invulnerability_time: float = 1.0

var velocity:
	get:
		return _velocity
var target_angle:
	get:
		return _target_angle
var health:
	get:
		return _health

var _velocity: Vector2 = Vector2(0.0, 0.0)
var _target_angle: float = 0.0
var _angle: float = 0.0
var _direction: Vector2 = Vector2.UP
var _forward: float = 0.0
var _distance_to_mouse: Vector2 = Vector2.ZERO
var _health: float = 100.0:
	set(value):
		_health = max(0.0, value)
var _invulnerable: bool = false


func _process(delta):
	_distance_to_mouse = (get_global_mouse_position() - position)
	if _distance_to_mouse.length() >= mouse_tracehold:
		_target_angle = _distance_to_mouse.angle() + PI / 2
	_angle = lerp_angle(_angle, _target_angle, rotation_speed * delta)
	_direction = Vector2.UP.rotated(_angle)

	_forward = Input.get_axis("down", "up")
	if _forward:
		_velocity += _forward * acceleration * _direction * delta
	# elif _velocity.length() > min_speed + 0.1:
	# 	_velocity -= _velocity.normalized() * friction * (_velocity.length() - min_speed) * delta
	else:
		_velocity = lerp(_velocity, (_direction * min_speed), friction * delta)

	_velocity = _velocity.limit_length(max_speed)
	position += _velocity * delta

	rotation = _angle
	engine_smoke.set_deferred("amount_ratio", _velocity.length() / max_speed)
	engine_sound.set_deferred("pitch_scale", 1.0 + (_velocity.length() - min_speed) / (2 * (max_speed - min_speed)))


func _hit(damage: float) -> void:
	_health -= damage
	if _health <= 0:
		emit_signal("destroyed")
	else:
		emit_signal("hit")
		_invulnerable = true
		set_deferred("monitorable", false)
		set_deferred("monitoring", false)
		animation_player.play("hit")
		await get_tree().create_timer(invulnerability_time).timeout
		_invulnerable = false
		set_deferred("monitorable", true)
		set_deferred("monitoring", true)
		animation_player.stop(true)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and not _invulnerable:
		_hit(10)
