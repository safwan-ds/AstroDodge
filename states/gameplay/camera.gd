extends Camera2D

@export_group("Zoom Out Transition")
@export var initial_zoom := 50.0
@export var transition_duration := 1.5
@export var transition_type := Tween.TRANS_QUART

@export_group("Camera Shake")
@export var noise := FastNoiseLite.new()
@export var min_noise_speed := 0.0
@export var max_noise_speed := 50.0
@export var base_shake_intensity := 50.0
@export var min_shake_intensity := 10.0
@export var shake_decay_rate := 4.0

@export_group("Camera Lookahead")
@export var lookahead_distance := 100.0
@export var lookahead_smoothness := 4.0
@export var lookahead_multiplier := 0.2

var _shake_intensity := min_shake_intensity
var _time := 0.0
var _noise_speed := max_noise_speed
var _target_offset := Vector2.ZERO
var _current_offset := Vector2.ZERO


func _ready() -> void:
	Global.trigger_camera_shake.connect(_trigger_shake)

	zoom = Vector2(initial_zoom, initial_zoom)
	var tween := create_tween()
	tween.tween_property(self, "zoom", Vector2(1.0, 1.0), transition_duration).set_trans(transition_type).set_ease(Tween.EASE_OUT)


func _process(delta) -> void:
	_time += delta
	_target_offset = clamp(
			(get_global_mouse_position() - global_position) * lookahead_multiplier,
			Vector2(-lookahead_distance, -lookahead_distance),
			Vector2(lookahead_distance, lookahead_distance)
		)
	_current_offset = lerp(_current_offset, _target_offset, lookahead_smoothness * delta)
	if _shake_intensity > min_shake_intensity:
		_shake_intensity = lerp(_shake_intensity, min_shake_intensity, shake_decay_rate * delta)
		_noise_speed = lerp(_noise_speed, min_noise_speed, shake_decay_rate * delta)
		offset = Vector2(
			_get_noise_from_seed(0) * _shake_intensity + _current_offset.x,
			_get_noise_from_seed(1) * _shake_intensity + _current_offset.y
		)
	else:
		offset = _current_offset


func _trigger_shake(intensity: int) -> void:
	_shake_intensity = max(intensity * base_shake_intensity, _shake_intensity)
	_noise_speed = max(max_noise_speed, _noise_speed)


func _get_noise_from_seed(_seed: int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(_time * _noise_speed)
