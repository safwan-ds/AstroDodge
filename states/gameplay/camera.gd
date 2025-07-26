extends Camera2D

# Camera zoom-out parameters
@export var initial_zoom := 50.0
@export var transition_duration := 1.5
@export var transition_type := Tween.TRANS_QUART

# Camera shake parameters
@export var noise := FastNoiseLite.new()
@export var max_noise_speed := 50.0
@export var min_noise_speed := 0.0
@export var min_shake_intensity := 10.0
@export var base_shake_intensity := 50.0
@export var shake_decay_rate := 4.0

var _shake_intensity := min_shake_intensity
var _time := 0.0
var _noise_speed := max_noise_speed


func _ready():
	Global.trigger_camera_shake.connect(_trigger_shake)

	zoom = Vector2(initial_zoom, initial_zoom)
	var tween := create_tween()
	tween.tween_property(self, "zoom", Vector2(1, 1), transition_duration).set_trans(transition_type).set_ease(Tween.EASE_OUT)


func _process(delta):
	_time += delta
	if _shake_intensity > min_shake_intensity:
		_shake_intensity = lerp(_shake_intensity, min_shake_intensity, shake_decay_rate * delta)
		_noise_speed = lerp(_noise_speed, 5.0, shake_decay_rate * delta)
		offset = Vector2(
			_get_noise_from_seed(0) * _shake_intensity,
			_get_noise_from_seed(1) * _shake_intensity
		)


func _trigger_shake(intensity: int):
	_shake_intensity = max(intensity * base_shake_intensity, _shake_intensity)
	_noise_speed = max(max_noise_speed, _noise_speed)


func _get_noise_from_seed(_seed: int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(_time * _noise_speed)