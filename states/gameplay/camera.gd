extends Camera2D
## Camera with zoom-in transition, Perlin-noise shake decay, and mouse lookahead offset.

@export_group("Zoom Out Transition")
## Zoom level at scene start (transitions to 1.0).
@export var initial_zoom := 50.0
## Seconds for the zoom-in transition.
@export var transition_duration := 1.5
@export var transition_type := Tween.TRANS_QUART

@export_group("Camera Shake")
@export var noise := FastNoiseLite.new()
@export var noise_speed := 50.0
## Intensity multiplier for shake trigger signal.
@export var base_shake_intensity := 50.0
## How fast shake intensity fades (higher = faster decay).
@export var shake_decay_rate := 4.0

@export_group("Camera Lookahead")
## Max pixel offset toward mouse cursor.
@export var lookahead_distance := 100.0
@export var lookahead_smoothness := 4.0
## Fraction of mouse-to-ship distance applied as offset.
@export var lookahead_multiplier := 0.2

var _shake_intensity := 0.0
var _time := 0.0
var _target_offset := Vector2.ZERO
var _current_offset := Vector2.ZERO


func _ready() -> void:
	Global.trigger_camera_shake.connect(_trigger_shake)

	zoom = Vector2(initial_zoom, initial_zoom)
	var tween := create_tween()
	tween.tween_property(self, "zoom", Vector2(1.0, 1.0), transition_duration)\
		.set_trans(transition_type)\
		.set_ease(Tween.EASE_OUT)


func _process(delta) -> void:
	_time += delta
	var mouse_world := get_global_mouse_position() + offset / zoom
	_target_offset = clamp(
		(mouse_world - global_position) * lookahead_multiplier,
		Vector2(-lookahead_distance, -lookahead_distance),
		Vector2(lookahead_distance, lookahead_distance),
	)
	_current_offset = lerp(_current_offset, _target_offset, 1.0 - exp(-lookahead_smoothness * delta))
	if _shake_intensity > 0.0:
		_shake_intensity = lerp(_shake_intensity, 0.0, 1.0 - exp(-shake_decay_rate * delta))
		offset = Vector2(
			_get_noise_from_seed(0) * _shake_intensity + _current_offset.x,
			_get_noise_from_seed(1) * _shake_intensity + _current_offset.y,
		)
	else:
		offset = _current_offset


## Set shake intensity. Uses max of new or current (accumulates).
func _trigger_shake(intensity: int) -> void:
	_shake_intensity = max(intensity * base_shake_intensity, _shake_intensity)


func _get_noise_from_seed(_seed: int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(_time * noise_speed)
