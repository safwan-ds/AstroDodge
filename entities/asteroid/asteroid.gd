class_name Asteroid extends Entity
## Asteroid that drifts toward the player. Destroys itself on contact[br]
## or when off-screen. Overrides [method _die] to add shatter particles.


# var _died := false
var _random_scale := randi_range(2, 8) / 2.0


func _ready() -> void:
	super()
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		_direction = (player.position - position).normalized().rotated(randf_range(-PI / 4, PI / 4))
	else:
		_direction = (Global.current_world.get_node("Camera").position - position).normalized().rotated(randf_range(-PI / 4, PI / 4))
	rotation = _direction.angle() + PI / 2
	scale = Vector2(_random_scale, _random_scale)

	for emitter in [trail, explosion]:
		var mat: ParticleProcessMaterial = emitter.process_material
		mat.initial_velocity_min /= _random_scale
		mat.initial_velocity_max /= _random_scale

	for emitter in [trail, explosion]:
		emitter.amount *= _random_scale


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("bullets") and not area.is_in_group("player"):
		return
	_die()


## Free self if not already dying — avoids cutting the explosion short.
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not _is_dying:
		queue_free()


## Play audio, then run the base death sequence.[br]
func _die() -> void:
	if _is_dying:
		return
	audio_player.play()
	await super()
