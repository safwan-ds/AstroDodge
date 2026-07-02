class_name EntityBase extends Area2D
## Base class for all gameplay entities. Runs [method _move] every frame via
## [method _process]. Provides shared death sequence: stop processing, disable
## collision, stop trail, play explosion, wait for particles, then free.
## Subclasses with extra death effects override [method _die] and call
## [code]super()[/code] for the common sequence.
## Subclasses override [method _move] for custom movement.

@export var sprite: AnimatedSprite2D
## Optional trail particle system. Stops emitting on death and waits for
## existing particles to finish before freeing.
@export var trail: GPUParticles2D
## Optional explosion particle system. Restarted on death; wait time is based
## on its lifetime. If both explosion and trail exist, explosion dictates the wait.
@export var explosion: GPUParticles2D

var _is_dying := false
## When true, [method _die] skips [method queue_free] at the end of the death
## sequence. Useful for nodes that must stay alive in the tree after death
## (e.g. the player keeps its Camera2D child for the game-over view).
var _skip_queue_free := false


## Runs every frame. Calls [method _move] unless dying.
func _process(delta) -> void:
	_move(delta)


## Virtual: override in subclasses for custom movement. Default is no-op.
func _move(_delta) -> void:
	pass


## Start the death sequence. Idempotent — re-entrancy guard prevents double-exec.[br]
## Override in subclasses to add effects (camera shake, sprite hide), then call[br]
## [code]super()[/code] for the common sequence: collision disable, trail stop,[br]
## explosion, wait for particles, and free.
func _die() -> void:
	if _is_dying:
		return
	_is_dying = true
	set_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if explosion:
		explosion.restart()
		explosion.emitting = true

	if trail:
		trail.emitting = false

	if sprite:
		sprite.hide()

	if explosion:
		await get_tree().create_timer(explosion.lifetime * 3.0).timeout
	elif trail:
		var wait: float = max(trail.lifetime, 0.5) * 1.5
		await get_tree().create_timer(wait).timeout

	if is_instance_valid(self) and not _skip_queue_free:
			queue_free()
