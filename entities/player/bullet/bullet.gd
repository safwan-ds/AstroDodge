class_name Bullet extends Area2D

@export var speed := 600.0
@export var trail: GPUParticles2D

@onready var _direction := Vector2.UP.rotated(rotation)


func _process(delta) -> void:
	position += _direction * speed * delta


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies"):
		return
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
