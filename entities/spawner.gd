class_name Spawner extends Timer

@export var outside_viewport := true
@export var padding := 50.0
@export var entity: PackedScene
@export var entity_group: String

@export_subgroup("Spawn Count")
@export_range(1, 100) var spawn_count_min := 1
@export_range(1, 100) var spawn_count_max := 4
@export_range(1, 100) var max_count := 10

var camera: Camera2D
var viewport_size: Vector2
var spawn_count := 1


func _ready() -> void:
	timeout.connect(_on_timeout)
	camera = get_viewport().get_camera_2d()


func _on_timeout() -> void:
	var current_entity_count := get_tree().get_node_count_in_group(entity_group)
	if current_entity_count < max_count:
		spawn_count = randi_range(
			spawn_count_min, spawn_count_max if max_count - current_entity_count > spawn_count_max else max_count - current_entity_count
		)
		if not camera:
			camera = get_viewport().get_camera_2d()
		viewport_size = camera.get_viewport_rect().size / camera.zoom # Adjust for zoom
		_spawn_tick()


func _spawn_tick() -> void:
	var batch = min(spawn_count, 1)
	for i in range(batch):
		_spawn_entity()
		spawn_count -= 1
	if spawn_count > 0:
		await get_tree().process_frame
		_spawn_tick()


func _spawn_entity() -> void:
	if entity:
		var instance = entity.instantiate()
		var side = randi() % 4
		# Top-left corner of the camera's view in global coordinates
		var view_top_left_global = camera.get_screen_center_position() - (viewport_size / 2.0)
		# Bottom-right corner
		var view_bottom_right_global = camera.get_screen_center_position() + (viewport_size / 2.0)
		
		match side:
			0: # Top
				instance.position = Vector2(
					randf_range(view_top_left_global.x, view_bottom_right_global.x),
					view_top_left_global.y - padding
				)
			1: # Right
				instance.position = Vector2(
					view_bottom_right_global.x + padding,
					randf_range(view_top_left_global.y, view_bottom_right_global.y)
				)
			2: # Bottom
				instance.position = Vector2(
					randf_range(view_top_left_global.x, view_bottom_right_global.x),
					view_bottom_right_global.y + padding
				)
			3: # Left
				instance.position = Vector2(
					view_top_left_global.x - padding,
					randf_range(view_top_left_global.y, view_bottom_right_global.y)
				)

		add_child(instance)
