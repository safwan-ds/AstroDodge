class_name EntitySpawner extends Timer
## Timer-based spawner that places entities just outside the camera viewport.[br]
## Respects a per-spawner max count and spreads batches across frames to avoid spikes.

@export var outside_viewport := true
@export var padding := 50.0
## Scene to instantiate for each spawn.
@export var entity: PackedScene
## Group assigned to spawned entities (for signal filtering, not counting).
@export var entity_group: String

@export_subgroup("Spawn Count")
@export_range(1, 100) var spawn_count_min := 1
@export_range(1, 100) var spawn_count_max := 4
## Maximum entities this spawner can have alive at once (counts its own children).
@export_range(1, 100) var max_count := 10
## When true, entities in a batch spawn from different sides (0→1→2→3) instead of random.
@export var spread_batch_sides := false

var camera: Camera2D
var viewport_size: Vector2
var spawn_count := 1
var _spread_side := -1


func _ready() -> void:
	timeout.connect(_on_timeout)
	camera = get_viewport().get_camera_2d()


## Check entity group count and spawn a batch if below [member max_count].
func _on_timeout() -> void:
	var current_entity_count := get_child_count()
	if current_entity_count < max_count:
		spawn_count = randi_range(
			spawn_count_min,
			spawn_count_max if max_count - current_entity_count > spawn_count_max \
				else max_count - current_entity_count,
		)
		if not camera:
			camera = get_viewport().get_camera_2d()
		viewport_size = camera.get_viewport_rect().size / camera.zoom
		_spawn_tick()


func _spawn_tick() -> void:
	if spread_batch_sides:
		_spread_side = randi() % 4

	while spawn_count > 0:
		_spawn_entity()
		spawn_count -= 1
		if spawn_count > 0:
			await get_tree().process_frame


## Instantiate [member entity] at a random position just outside the camera viewport.
func _spawn_entity() -> void:
	if entity:
		var instance = entity.instantiate()
		var side := randi() % 4
		if spread_batch_sides:
			side = _spread_side % 4
			_spread_side += 1
		_position_entity(instance, side)
		add_child(instance)


func _position_entity(instance: Node2D, side: int) -> void:
	var view_top_left_global := camera.get_screen_center_position() - (viewport_size / 2.0)
	var view_bottom_right_global := camera.get_screen_center_position() + (viewport_size / 2.0)

	match side:
		0:  # Top
			instance.position = Vector2(
				randf_range(view_top_left_global.x, view_bottom_right_global.x),
				view_top_left_global.y - padding,
			)
		1:  # Right
			instance.position = Vector2(
				view_bottom_right_global.x + padding,
				randf_range(view_top_left_global.y, view_bottom_right_global.y),
			)
		2:  # Bottom
			instance.position = Vector2(
				randf_range(view_top_left_global.x, view_bottom_right_global.x),
				view_bottom_right_global.y + padding,
			)
		3:  # Left
			instance.position = Vector2(
				view_top_left_global.x - padding,
				randf_range(view_top_left_global.y, view_bottom_right_global.y),
			)
