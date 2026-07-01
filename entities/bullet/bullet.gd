class_name Bullet extends EntityBase
## Lightweight projectile. Flies forward and cleans up on enemy contact or
## when off-screen. Death sequence inherited from [EntityBase].

@export var speed := 600.0

@onready var _direction := Vector2.UP.rotated(rotation)


## Runs every frame. Calls [method _move] for custom movement.[br]
## Idempotent via [EntityBase._is_dying] guard — re-entrancy safe.
func _move(delta) -> void:
	position += _direction * speed * delta
func _on_area_entered(area: Area2D) -> void:
	if _is_dying or is_queued_for_deletion():
		return
	if not area.is_in_group("enemies"):
		return
	_die()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if _is_dying or is_queued_for_deletion():
		return
	_die()
