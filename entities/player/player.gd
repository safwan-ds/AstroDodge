## The class of Player's entity.
class_name Player extends Entity
signal is_hurt(hp: float)
signal is_healed(hp: float)
signal is_dead

@export_group("Links to Nodes")
@export var bullet_scene: PackedScene
@export var gun: Marker2D
@export var animation_player: AnimationPlayer
@export var camera: Camera2D
@export var cooldown_bar: ProgressBar

@export_group("Movement")
@export var rotation_speed := 5.0
@export var mouse_tracehold := 10.0
@export_subgroup("Engine")
@export var max_speed := 300.0
@export var acceleration := 300.0
@export var friction := 200.0

@export_group("Gameplay")
@export var invulnerability_time := 1.0
@export var shoot_cooldown := 0.5

var target_angle: float:
	get:
		return _target_angle
var current_shoot_cooldown: float:
	get:
		return _current_shoot_cooldown
var auto_fire: bool:
	get:
		return _auto_fire

## The angle towards the mouse cursor.
var _target_angle := 0.0
## Indicates if the player is accelerating or decelerating.
var _forward := 0.0
var _distance_to_mouse := Vector2.ZERO
var _invulnerable := false
var _current_shoot_cooldown := 0.0:
	set(value):
		_current_shoot_cooldown = max(0.0, value)
var _auto_fire := false
@onready var _auto_fire_tween: Tween


func _ready():
	cooldown_bar.max_value = shoot_cooldown
	cooldown_bar.value = current_shoot_cooldown


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
		_velocity = _velocity.move_toward(entity_stats.base_speed * _direction, friction * delta)

	_velocity = _velocity.limit_length(max_speed)
	position += _velocity * delta

	trail.set_deferred("amount_ratio", _velocity.length() / max_speed)
	audio_player.set_deferred("pitch_scale", 1.0 + (_velocity.length() - entity_stats.base_speed) / (2 * (max_speed - entity_stats.base_speed)))

	if _current_shoot_cooldown > 0.0:
		_current_shoot_cooldown -= delta
	cooldown_bar.value = move_toward(cooldown_bar.value, shoot_cooldown - current_shoot_cooldown, delta * 5.0)

	if _auto_fire:
		_shoot()


func _input(event):
	if event.is_action_pressed("primary"):
		_shoot()
	if event.is_action_pressed("secondary"):
		_auto_fire = not _auto_fire
		if _auto_fire_tween:
			_auto_fire_tween.kill()
		_auto_fire_tween = create_tween()
		_auto_fire_tween.tween_property(cooldown_bar, "modulate", Color.RED if _auto_fire else Color.WHITE, 0.1)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and not _invulnerable:
		_be_hurt(10)


func _be_hurt(damage: float) -> void:
	super (damage)
	is_hurt.emit(_hp)
	if not Global.current_world.game_over:
		_invulnerable = true
		# set_deferred("monitoring", false)
		sprite.modulate = Color.RED
		await get_tree().create_timer(invulnerability_time).timeout
		_invulnerable = false
		# set_deferred("monitoring", true)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _die() -> void:
	camera.position = position
	remove_child(camera)
	Global.current_world.add_child(camera)
	is_dead.emit()
	super ()


func _shoot() -> void:
	if _current_shoot_cooldown <= 0.0:
		_current_shoot_cooldown = shoot_cooldown
		AudioManager.play_sfx(AudioManager.SFX.SHOOT, -1.0)
		var bullet: Bullet = bullet_scene.instantiate()
		bullet.position = gun.global_position
		bullet.rotation = _target_angle + randf_range(-PI / 20.0, PI / 20.0)
		Global.current_world.add_child(bullet)
		Global.trigger_camera_shake.emit(1)
