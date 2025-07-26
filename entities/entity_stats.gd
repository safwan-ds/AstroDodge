class_name EntityStats extends Resource

const MAX_SHAKE_INTENSITY: int = 5

@export var max_health: float = 100.0
## The base speed of the entity.
@export var base_speed: float = 200.0
## The camera shake intensity when the entity is hit.
@export_range(1, MAX_SHAKE_INTENSITY) var hit_shake_intensity := 1
## The camera shake intensity when the entity dies.
@export_range(1, MAX_SHAKE_INTENSITY) var death_shake_intensity := 2
