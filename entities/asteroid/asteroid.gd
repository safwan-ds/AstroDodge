class_name Asteroid extends Area2D

@export var sprite: AnimatedSprite2D
@export var trail: GPUParticles2D
@export var shatter: GPUParticles2D
@export var explosion: GPUParticles2D
@export var audio_player: AudioStreamPlayer2D

@export var speed: float = 100.0

var _direction: Vector2
var _destroyed: bool = false
var _random_scale: int = randi_range(1, 4)


func _ready():
	_direction = (get_tree().get_first_node_in_group("player").position - position).normalized().rotated(randf_range(-PI / 4, PI / 4))
	rotation = _direction.angle() + PI / 2
	scale = Vector2(_random_scale, _random_scale)

	var collapse_process_material: ShaderMaterial = shatter.process_material
	collapse_process_material.set_shader_parameter("initial_linear_velocity_min", collapse_process_material.get_shader_parameter("initial_linear_velocity_min") / _random_scale)
	collapse_process_material.set_shader_parameter("initial_linear_velocity_max", collapse_process_material.get_shader_parameter("initial_linear_velocity_max") / _random_scale)

	for emitter in [trail, explosion]:
		var trail_process_material: ParticleProcessMaterial = trail.process_material
		trail_process_material.initial_velocity_min /= _random_scale
		trail_process_material.initial_velocity_max /= _random_scale

	for emitter in [trail, shatter, explosion]:
		emitter.amount *= _random_scale

func _process(delta):
	position += _direction * speed * delta


func _on_area_entered(area: Area2D) -> void:
	_destroy()


func _destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	Global.trigger_camera_shake.emit(1)
	audio_player.play()
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	sprite.hide()
	trail.emitting = false
	shatter.emitting = true
	explosion.emitting = true
	set_process(false)
	await explosion.finished
	await shatter.finished
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
