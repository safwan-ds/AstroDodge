class_name Voltshot extends Entity
## Projectile fired by [Voltstar] enemies. Rotates toward the player[br]
## and self-destructs on contact or after a lifetime timeout.

@export var rotation_speed := 5.0

@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready():
	super ()
	rotation = randf() * TAU


func _on_area_entered(_area):
	_die()


func _on_lifetime_timeout() -> void:
	_die()


## Rotate toward player, then use default movement. Called by Entity._process via _move().
func _move(delta):
	if player:
		rotation = lerp_angle(rotation, (position - player.position).angle() - PI / 2.0, rotation_speed * delta)
	super (delta)
