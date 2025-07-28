class_name Asteroid extends Entity

@export var shatter: GPUParticles2D

var _died := false
var _random_scale := randf_range(1, 4)


func _ready():
	super ()
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


func _on_area_entered(area: Area2D) -> void:
	_die()


func _die() -> void:
	if _died:
		return
	_died = true
	audio_player.play()
	super ()
	await shatter.finished
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
