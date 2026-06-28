class_name Entity extends Area2D
## Base class for all moving entities (player, enemies, projectiles).[br]
## Provides hp, movement, death effects (explosion, camera shake),
## and collectible spawning. Subclasses override [method _on_area_entered]
## and may call [method _die] directly.

@export_group("Entity Stats")
## Stats resource defining hp, speed, shake intensities, and collectible drops.
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


## Play death effects (camera shake, explosion particles), then queue_free.[br]
## Idempotent — re-entrancy guard prevents double-execution.
func _die() -> void:
	if _is_dying:
		return
	_is_dying = true
	Global.trigger_camera_shake.emit(entity_stats.death_shake_intensity)
	Global.explosion_occurred.emit(global_position, scale.length())
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	sprite.hide()
	trail.emitting = false
	set_process(false)
	set_process_input(false)
	explosion.restart()
	explosion.emitting = true

	# Use SceneTree timer instead of awaiting explosion.finished.
	var finish_timer := get_tree().create_timer(explosion.lifetime * 3.0)
	await finish_timer.timeout

	if is_instance_valid(self):
		queue_free()


## Spawn [param min_count] to [param max_count] collectibles of [param collectible_type] near the entity.
func _spawn_collectibles(collectible_type: Global.CollectibleType, min_count: int, max_count: int):
	var collectible_scene := collectibles_map[collectible_type]
	for i in range(randi_range(min_count, max_count)):
		var collectible_node: Collectible = collectible_scene.instantiate()
		collectible_node.position = position
		add_sibling(collectible_node)
