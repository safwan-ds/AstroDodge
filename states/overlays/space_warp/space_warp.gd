extends ColorRect
## Full-screen shader overlay that creates a distortion ripple on explosions.[br]
## Listens to [signal Global.explosion_occurred].


@onready var _material: ShaderMaterial = material as ShaderMaterial
@onready var _current_intensity: float = 0.0

var _tween: Tween
var _explosion_world_pos: Vector2


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	Global.explosion_occurred.connect(_on_explosion_occurred)


func _on_explosion_occurred(world_position: Vector2) -> void:
	if not is_inside_tree():
		return

	_explosion_world_pos = world_position

	if _tween and _tween.is_valid():
		_tween.kill()

	_update_warp_origin()

	_tween = create_tween()
	_tween.tween_method(_set_intensity, 0.0, 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_method(_set_intensity, 1.0, 0.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func _set_intensity(value: float) -> void:
	_current_intensity = value
	_material.set_shader_parameter("warp_intensity", value)
	_update_warp_origin()


func _update_warp_origin() -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return

	var screen_pos: Vector2 = camera.get_canvas_transform() * _explosion_world_pos
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	_material.set_shader_parameter("warp_origin", screen_pos / viewport_size)
