class_name EntityStats extends Resource

const MAX_SHAKE_INTENSITY := 5

## Starting health of the entity. Also, entity's HP max value.
@export var max_health := 100.0
## The base moving speed of the entity.
@export var base_speed := 200.0

@export_group("Camera Shake")
## The camera shake intensity when the entity is hit.
@export_range(0, MAX_SHAKE_INTENSITY) var hit_shake_intensity := 0
## The camera shake intensity when the entity dies.
@export_range(0, MAX_SHAKE_INTENSITY) var death_shake_intensity := 1
