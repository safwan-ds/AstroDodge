class_name Bullet extends Entity


func _on_area_entered(_area):
	_die()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not _is_dying:
		queue_free()