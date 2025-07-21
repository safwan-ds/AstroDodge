extends Camera2D

@export var initial_zoom: float = 50.0
@export var transition_duration: float = 1.5
@export var transition_type: Tween.TransitionType = Tween.TRANS_QUAD


func _ready():
	zoom = Vector2(initial_zoom, initial_zoom)
	var tween := create_tween()
	tween.tween_property(self, "zoom", Vector2(1, 1), transition_duration).set_trans(transition_type).set_ease(Tween.EASE_OUT)


func _process(delta):
	pass
