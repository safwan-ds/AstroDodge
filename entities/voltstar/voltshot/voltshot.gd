class_name Voltshot extends EntityBase
## Projectile fired by [Voltstar] enemies. Rotates toward the player
## and self-destructs on contact or after a lifetime timeout.
## Death sequence inherited from [EntityBase].

@export var speed := 200.0
@export var rotation_speed := 5.0

@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	rotation = randf() * TAU


## Rotate toward player, then fly forward.
func _move(delta) -> void:
	if player:
		rotation = lerp_angle(rotation, (position - player.position).angle() - PI / 2.0, rotation_speed * delta)
	position += Vector2.UP.rotated(rotation) * speed * delta


func _on_area_entered(_area):
	_die()


func _on_lifetime_timeout() -> void:
	_die()
