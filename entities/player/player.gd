class_name Player extends Area2D

@export var sprite: AnimatedSprite2D

@export var max_speed: float = 300
@export var acceleration: float = 200.0
@export var friction: float = 100.0

var velocity: Vector2 = Vector2(0.0, 0.0)
var angle: float = 0.0
var direction: Vector2
var forward: float


func _process(delta):
	angle = lerp_angle(angle, (get_global_mouse_position() - position).angle(), 0.05)
	direction = Vector2.RIGHT.rotated(angle)

	forward = Input.get_axis("down", "up")
	if forward:
		velocity += forward * acceleration * direction * delta
	else:
		velocity -= velocity.normalized() * friction * delta

	velocity = velocity.limit_length(max_speed)
	position += velocity * delta

	rotation = angle + PI / 2
