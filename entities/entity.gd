## The base class for all moving entities in the game.
class_name Entity extends Area2D

@export_group("Entity Stats")
@export var entity_stats: EntityStats

@export_group("Links to Collectible Scenes")
@export var j_unit: PackedScene
@export var c_unit: PackedScene
@export var ddx6_chip: PackedScene
@export var mx3_chip: PackedScene
@export var asm_unit: PackedScene

@export_group("Links to Nodes")
@export var sprite: AnimatedSprite2D
@export var trail: GPUParticles2D
@export var explosion: GPUParticles2D
@export var audio_player: AudioStreamPlayer2D

var hp: float:
	get:
		return _hp
var speed: float:
	get:
		return _velocity.length()

var _direction := Vector2.ZERO
var _velocity := Vector2.ZERO
var _is_dying := false

@onready var collectibles_map: Dictionary[Global.CollectibleType, PackedScene] = {
	Global.CollectibleType.J_UNIT: j_unit,
	Global.CollectibleType.C_UNIT: c_unit,
	Global.CollectibleType.DDX6_CHIP: ddx6_chip,
	Global.CollectibleType.MX3_CHIP: mx3_chip,
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
	_direction = Vector2.UP.rotated(rotation)
	_velocity = _direction * entity_stats.base_speed
	position += _velocity * delta

## This method should be overridden in subclasses to handle area interactions.
func _on_area_entered(_area: Area2D) -> void:
	pass


## Defines the actions that will happen when the entity is hit.
func _be_hurt(damage: float) -> void:
	_hp -= damage
	if _hp <= 0:
		return
	Global.trigger_camera_shake.emit(entity_stats.hit_shake_intensity)


## Defines the actions that will happen when the entity dies.
func _die() -> void:
	_is_dying = true
	Global.trigger_camera_shake.emit(entity_stats.death_shake_intensity)
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	sprite.hide()
	trail.emitting = false
	explosion.emitting = true
	set_process(false)
	set_process_input(false)
	await explosion.finished
	queue_free()


func _spawn_collectibles(collectible_type: Global.CollectibleType, min_count: int, max_count: int):
	var collectible_scene := collectibles_map[collectible_type]
	for i in range(randi_range(min_count, max_count)):
		var collectible_node: Collectible = collectible_scene.instantiate()
		collectible_node.position = position
		add_sibling(collectible_node)
