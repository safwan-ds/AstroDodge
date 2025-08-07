class_name Voltshot extends Entity

@export var rotation_speed := 5.0

@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready():
	super ()
	rotation = randf() * TAU


func _process(delta):
	if player:
		rotation = lerp_angle(rotation, (position - player.position).angle() - PI / 2.0, rotation_speed * delta)
	super (delta)


func _on_area_entered(area):
	await _die()
	queue_free()


func _on_lifetime_timeout() -> void:
	await _die()
	queue_free()
