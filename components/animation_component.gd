class_name AnimationComponent extends Node

@export var hovered_scale := Vector2(1.1, 1.1)
@export var pressed_scale := Vector2(0.9, 0.9)
@export var duration := 0.25

@onready var button: Button = get_parent()

var tween: Tween = null
@export var min_rotation_speed: float = 1.0 # Minimum duration for one rotation (seconds)
@export var max_rotation_speed: float = 2.0 # Maximum duration for one rotation (seconds)
@export var max_rotation_angle: float = 5.0 # Max degrees to rotate (e.g., 15 degrees for a subtle wobble)


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
		AudioManager.play_sfx(AudioManager.Sfx.HOVER)


func _exited():
	if not button.disabled:
		create_tween().tween_property(button, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD)


func _pressed():
	AudioManager.play_sfx(AudioManager.Sfx.CLICK)


func _on_cancel_button_mouse_entered() -> void:
	pass # Replace with function body.


func start_random_rotation():
	# Kill any existing tween to avoid conflicts if this function is called repeatedly
	if tween:
		tween.kill()
		tween = null # Clear the reference

	# Create a new Tween
	tween = create_tween()

	# Define the easing function for smoothness (e.g., quad, sine, back)
	tween.set_trans(Tween.TRANS_SINE) # Smooth acceleration and deceleration
	tween.set_ease(Tween.EASE_IN_OUT) # Apply easing to both start and end

	# 1. Randomize the target rotation angle
	# We want a random angle between -max_rotation_angle and +max_rotation_angle
	var target_angle_degrees = randf_range(-max_rotation_angle, max_rotation_angle)
	var target_angle_radians = deg_to_rad(target_angle_degrees)

	# 2. Randomize the duration of the rotation
	var rotation_duration = randf_range(min_rotation_speed, max_rotation_speed)

	# Tween the 'rotation' property of this Button (self)
	# The 'rotation' property is in radians.
	tween.tween_property(button, "rotation", target_angle_radians, rotation_duration)

	# After the first rotation, add another tween to return to 0 or another random angle
	# This creates a back-and-forth wobble effect.
	# If you want it to just spin continuously, you'd calculate a random full rotation.

	# Option A: Rotate back to 0 degrees for a wobble effect
	# (This will follow the first random rotation)
	tween.tween_property(button, "rotation", deg_to_rad(0.0), rotation_duration)

	# Connect the 'finished' signal of the tween to loop the animation
	tween.finished.connect(start_random_rotation)
