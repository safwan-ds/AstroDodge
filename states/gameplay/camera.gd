extends Camera2D

@export var initial_zoom: float = 50.0
@export var transition_duration: float = 1.5
@export var transition_type: Tween.TransitionType = Tween.TRANS_QUART
# @export var normal_shake_strength: float = 10.0
@export var base_shake_strength: float = 50.0
@export var shake_decay_rate: float = 4.0

var _shake_strength: float = 0.0


func _ready():
	Global.trigger_camera_shake.connect(_trigger_shake)

	zoom = Vector2(initial_zoom, initial_zoom)
	var tween := create_tween()
	tween.tween_property(self, "zoom", Vector2(1, 1), transition_duration).set_trans(transition_type).set_ease(Tween.EASE_OUT)


func _process(delta):
	if _shake_strength > 0.0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_decay_rate * delta)
		offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)


func _trigger_shake(strength: int):
	_shake_strength = max(strength * base_shake_strength, _shake_strength)
