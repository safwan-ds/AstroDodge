class_name Entity extends EntityBase
## Base class for all moving entities (player, enemies, projectiles).[br]
## Provides hp, movement, death effects (camera shake),
## and collectible spawning. Subclasses override [method _on_area_entered]
## and may call [method _die] directly.

@export_group("Entity Stats")
## Stats resource defining hp, speed, shake intensities, and collectible drops.
@export var entity_stats: EntityStats

@export_group("Links to Collectible Scenes")
@export var j_unit: PackedScene
@export var cap_unit: PackedScene
@export var ddrx_chip: PackedScene
@export var m2_chip: PackedScene
@export var asm_unit: PackedScene

@export_group("Links to Nodes")
@export var audio_player: AudioStreamPlayer2D
@export var collision_shape: CollisionShape2D

var hp: float:
	get:
		return _hp
var speed: float:
	get:
		return _velocity.length()

var _direction := Vector2.ZERO
var _velocity := Vector2.ZERO

@onready var collectibles_map: Dictionary[Global.CollectibleType, PackedScene] = {
	Global.CollectibleType.J_UNIT: j_unit,
	Global.CollectibleType.CAP_UNIT: cap_unit,
	Global.CollectibleType.DDRX_CHIP: ddrx_chip,
	Global.CollectibleType.M2_CHIP: m2_chip,
	Global.CollectibleType.ASM_UNIT: asm_unit,
}
@onready var _hp := entity_stats.max_health:
	set(value):
		value = clamp(value, 0.0, entity_stats.max_health)
		if value <= 0.0:
			_die()
		_hp = value


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta) -> void:
	_move(delta)


func _on_area_entered(_area: Area2D) -> void:
	pass


## Virtual: override for custom movement. Default: straight at base_speed.
func _move(delta) -> void:
	_direction = Vector2.UP.rotated(rotation)
	_velocity = _direction * entity_stats.base_speed
	position += _velocity * delta


## Reduce hp by [param damage]. Triggers camera shake if entity survives.
func _be_hurt(damage: float) -> void:
	_hp -= damage
	if _hp <= 0:
		return
	Global.trigger_camera_shake.emit(entity_stats.hit_shake_intensity)


## Handles CircleShape2D, RectangleShape2D, and CapsuleShape2D — the
## three shape types used across all Entity subclasses.
func _get_death_radius() -> float:
	if not collision_shape or not collision_shape.shape:
		return scale.length()

	var s := collision_shape.shape
	if s is CircleShape2D:
		return s.radius / 5.0
	elif s is RectangleShape2D:
		return s.size.length() / 2.0 / 5.0
	elif s is CapsuleShape2D:
		return s.radius + s.height / 2.0 / 5.0

	return scale.length()


## Play death effects (camera shake, sprite hide), then delegate to[br]
## [EntityBase._die] for the common sequence (explosion, trail, wait, free).[br]
## Idempotent — re-entrancy guard prevents double-execution.
func _die() -> void:
	if _is_dying:
		return
	
	Global.trigger_camera_shake.emit(entity_stats.death_shake_intensity)
	Global.explosion_occurred.emit(global_position, _get_death_radius())

	set_process_input(false)
	super()


## Spawn [param min_count] to [param max_count] collectibles of [param collectible_type] near the entity.
func _spawn_collectibles(collectible_type: Global.CollectibleType, min_count: int, max_count: int):
	var collectible_scene := collectibles_map[collectible_type]
	for i in range(randi_range(min_count, max_count)):
		var collectible_node: Collectible = collectible_scene.instantiate()
		collectible_node.position = position
		add_sibling(collectible_node)
