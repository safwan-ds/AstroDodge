class_name AnimationComponent extends Node
## Button animation helper: hover/press scaling, font swap, click SFX,[br]
## and idle rotation wobble. Attach as child of a [Button].

@export_group("Hovering Animation")
@export var hovered_scale := Vector2(1.1, 1.1)
@export var pressed_scale := Vector2(0.9, 0.9)
@export var duration := 0.25
@export var hover_font: Font

@export_group("Rotation")
## Minimum duration for one rotation (seconds).
@export var min_rotation_speed: float = 1.0
## Maximum duration for one rotation (seconds).
@export var max_rotation_speed: float = 2.0
## Max degrees to rotate (subtle wobble).
@export var max_rotation_angle: float = 5.0

var tween: Tween = null

@onready var button: Button = get_parent()


func _ready():
	button.mouse_entered.connect(_entered)
	button.mouse_exited.connect(_exited)
	button.pressed.connect(_pressed)

	call_deferred("_init_pivot")
	randomize()
	start_random_rotation()


func _init_pivot() -> void:
	button.pivot_offset = button.size / 2


func _entered():
	if not button.disabled:
		create_tween().tween_property(button, "scale", hovered_scale, duration).set_trans(Tween.TRANS_QUAD)
		AudioManager.play_sfx(AudioManager.SFX.HOVER)
		if hover_font:
			button.set_deferred("theme_override_fonts/font", hover_font)
			button.set_deferred("theme_override_font_sizes/font_size", 40.0)


func _exited():
	if not button.disabled:
		create_tween().tween_property(button, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD)
		if hover_font:
			button.set_deferred("theme_override_fonts/font", null)
			button.set_deferred("theme_override_font_sizes/font_size", null)


func _pressed():
	AudioManager.play_sfx(AudioManager.SFX.CLICK)


## Start a continuous random-wobble rotation tween that loops on finish.
func start_random_rotation():
	if tween:
		tween.kill()
		tween = null

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	var target_angle_degrees = randf_range(-max_rotation_angle, max_rotation_angle)
	var target_angle_radians = deg_to_rad(target_angle_degrees)
	var rotation_duration = randf_range(min_rotation_speed, max_rotation_speed)

	tween.tween_property(button, "rotation", target_angle_radians, rotation_duration)
	tween.tween_property(button, "rotation", deg_to_rad(0.0), rotation_duration)
	tween.finished.connect(start_random_rotation)
