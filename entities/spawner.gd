class_name Spawner extends Timer

@export var outside_viewport: bool = true
@export var padding: float = 50.0
@export var entity: PackedScene
@export var camera: Camera2D
@export_subgroup("Spawn Count")
@export_range(1, 100) var spawn_count_min: int = 1
@export_range(1, 100) var spawn_count_max: int = 4

var viewport_size: Vector2
var spawn_count: int = 1


func _ready():
	viewport_size = get_viewport().get_visible_rect().size


func _on_timeout() -> void:
	spawn_count = randi_range(spawn_count_min, spawn_count_max)
	for i in range(spawn_count):
		_spawn_entity()


func _spawn_entity() -> void:
	viewport_size = camera.get_viewport_rect().size / camera.zoom # Adjust for zoom

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
