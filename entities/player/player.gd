class_name Player extends Entity
signal hit(hp: float)
signal healed(hp: float)
signal died

@export_group("Links to Nodes")
@export var bullet_scene: PackedScene
@export var gun: Marker2D
@export var animation_player: AnimationPlayer
@export var camera: Camera2D

@export_group("Movement")
@export var max_speed := 300.0
@export var acceleration := 300.0
@export var rotation_speed := 5.0
@export var friction := 2.0
@export var mouse_tracehold := 10.0

@export_group("Gameplay")
@export var invulnerability_time := 1.0
@export var shoot_cooldown := 0.5

var target_angle: float:
	get:
		return _target_angle

## The angle towards the mouse cursor.
var _target_angle := 0.0
## Indicates if the player is accelerating or decelerating.
var _forward := 0.0
var _distance_to_mouse := Vector2.ZERO
var _invulnerable := false
var _shoot_cooldown := 0.0:
	set(value):
		_shoot_cooldown = max(0.0, value)


func _process(delta) -> void:
	_distance_to_mouse = (get_global_mouse_position() - position)
	if _distance_to_mouse.length() >= mouse_tracehold:
		_target_angle = _distance_to_mouse.angle() + PI / 2
	rotation = lerp_angle(rotation, _target_angle, rotation_speed * delta)
	_direction = Vector2.UP.rotated(rotation)

	_forward = Input.get_axis("down", "up")
	if _forward:
		_velocity += _forward * acceleration * _direction * delta
	else:
		_velocity = lerp(_velocity, entity_stats.base_speed * _direction, friction * delta)

	_velocity = _velocity.limit_length(max_speed)
	position += _velocity * delta

	trail.set_deferred("amount_ratio", _velocity.length() / max_speed)
	audio_player.set_deferred("pitch_scale", 1.0 + (_velocity.length() - entity_stats.base_speed) / (2 * (max_speed - entity_stats.base_speed)))

	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= delta


func _input(event):
	if event.is_action_pressed("primary") and _shoot_cooldown <= 0.0:
		_shoot_cooldown = shoot_cooldown
		_shoot()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and not _invulnerable:
		_hit(10)


func _hit(damage: float) -> void:
	super (damage)
	hit.emit(_hp)
	_invulnerable = true
	set_deferred("monitoring", false)
	await get_tree().create_timer(invulnerability_time).timeout
	_invulnerable = false
	set_deferred("monitoring", true)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _die() -> void:
	camera.position = position
	remove_child(camera)
	Global.current_world.add_child(camera)
	died.emit()
	super ()


func _shoot() -> void:
	AudioManager.play_sfx(AudioManager.SFX.SHOOT, -1.0)
	var bullet: Bullet = bullet_scene.instantiate()
	bullet.position = gun.global_position
	bullet.rotation = _target_angle
	Global.current_world.add_child(bullet)
	Global.trigger_camera_shake.emit(1)
